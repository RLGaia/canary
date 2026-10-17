-- Gaia Family server: point of interest generator for the Cyclopedia map discovery.
-- Ours, not upstream. Not loaded by the server: copy it to data/scripts/ for one start
-- of a test server (see README.md), then delete it.
--
-- Reads masks.lua (export_masks.py) and writes poi_candidates.lua: for every subarea up
-- to 16 evenly spread tiles that can be walked to from a temple or an NPC, on the
-- ground floor when possible.

local MASKS = "masks.lua" -- paths relative to the server folder; change if needed
local OUTPUT = "poi_candidates.lua"

local generator = GlobalEvent("FamilyPoiGenerator")

local function generate()
	local t0 = os.clock()
	local M = dofile(MASKS)
	local function key(x, y, z)
		return (z * 65536 + x) * 65536 + y
	end
	local ladderIds, ropeIds, grateIds = {}, {}, {}
	local function classify(item)
		local id = item:getId()
		if ladderIds[id] == nil then
			local n = ItemType(id):getName():lower()
			ladderIds[id] = n:find("ladder") ~= nil
			ropeIds[id] = n:find("rope spot") ~= nil or n:find("hole") ~= nil and ItemType(id):isGroundTile() == false
			grateIds[id] = n:find("sewer grate") ~= nil or n:find("trapdoor") ~= nil
		end
		return ladderIds[id], ropeIds[id], grateIds[id]
	end
	local function passable(tile)
		if not tile or not tile:getGround() then
			return false
		end
		if tile:hasFlag(TILESTATE_HOUSE) then
			return false
		end
		if tile:hasProperty(CONST_PROP_BLOCKSOLID) or tile:hasProperty(CONST_PROP_IMMOVABLEBLOCKSOLID) then
			-- closed ordinary doors (no action/unique id) can be opened
			for _, item in ipairs(tile:getItems() or {}) do
				local it = ItemType(item:getId())
				if it:isBlocking() then
					if not it:isDoor() or item:hasAttribute(ITEM_ATTRIBUTE_ACTIONID) or item:hasAttribute(ITEM_ATTRIBUTE_UNIQUEID) then
						return false
					end
				end
			end
			if ItemType(tile:getGround():getId()):isBlocking() then
				return false
			end
		end
		return true
	end
	local seen, queue, qh = {}, {}, 1
	local function push(x, y, z)
		if z < 0 or z > 15 then
			return
		end
		local k = key(x, y, z)
		if seen[k] == nil then
			local good = passable(Tile(x, y, z))
			seen[k] = good
			if good then
				queue[#queue + 1] = k
			end
		end
	end
	local function pushArea(x, y, z, r)
		for dx = -r, r do
			for dy = -r, r do
				push(x + dx, y + dy, z)
			end
		end
	end
	for _, town in pairs(Game.getTowns()) do
		local p = town:getTemplePosition()
		push(p.x, p.y, p.z)
	end
	for _, n in ipairs(M.npcs) do
		pushArea(n[1], n[2], n[3], 1)
	end
	while qh <= #queue do
		local k = queue[qh]
		qh = qh + 1
		local y = k % 65536
		local xz = (k - y) / 65536
		local x = xz % 65536
		local z = (xz - x) / 65536
		local tile = Tile(x, y, z)
		if tile:hasFlag(TILESTATE_FLOORCHANGE) then
			if tile:hasFlag(TILESTATE_FLOORCHANGE_DOWN) then
				pushArea(x, y, z + 1, 2)
			else
				pushArea(x, y, z - 1, 2)
			end
		else
			push(x + 1, y, z)
			push(x - 1, y, z)
			push(x, y + 1, z)
			push(x, y - 1, z)
			push(x + 1, y + 1, z)
			push(x - 1, y - 1, z)
			push(x - 1, y + 1, z)
			push(x + 1, y - 1, z)
		end
		if tile:hasFlag(TILESTATE_TELEPORT) then
			for _, item in ipairs(tile:getItems() or {}) do
				local ok, dest = pcall(function()
					return Teleport(item:getUniqueId()):getDestination()
				end)
				if ok and dest and dest.x > 0 then
					pushArea(dest.x, dest.y, dest.z, 1)
				end
			end
		end
		for _, item in ipairs(tile:getItems() or {}) do
			local ladder, rope, grate = classify(item)
			if ladder or rope then
				pushArea(x, y + 1, z - 1, 1)
			end
			if grate then
				pushArea(x, y, z + 1, 1)
			end
		end
	end
	logger.info("[PoiGenerator] {} reachable tiles in {}s", #queue, os.clock() - t0)

	local function usable(x, y, z)
		if not seen[key(x, y, z)] then
			return false
		end
		local tile = Tile(x, y, z)
		return not tile:hasFlag(TILESTATE_FLOORCHANGE) and not tile:hasFlag(TILESTATE_TELEPORT) and not tile:hasProperty(CONST_PROP_BLOCKSOLID)
	end
	local out = io.open(OUTPUT, "w")
	out:write("return {\n")
	local ids = {}
	for id in pairs(M.subareas) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	math.randomseed(20261017)
	for _, id in ipairs(ids) do
		local s = M.subareas[id]
		local tiles, total = {}, 0
		for _, sp in ipairs(s.spans) do
			for x = sp[2], sp[3] do
				total = total + 1
				local found = usable(x, sp[1], 7) and 7 or nil
				if not found then
					for z = 6, 0, -1 do
						if seen[key(x, sp[1], z)] then
							if usable(x, sp[1], z) then
								found = z
							end
							break
						end
					end
				end
				if found then
					tiles[#tiles + 1] = { x, sp[1], found }
				end
			end
		end
		if #tiles == 0 then -- nothing on the surface: underground below it
			for _, sp in ipairs(s.spans) do
				for x = sp[2], sp[3] do
					for z = 8, 15 do
						if seen[key(x, sp[1], z)] then
							if usable(x, sp[1], z) then
								tiles[#tiles + 1] = { x, sp[1], z }
							end
							break
						end
					end
				end
			end
		end
		-- shuffle, then keep points at least r apart (r shrinks until 16 are found)
		for i = #tiles, 2, -1 do
			local j = math.random(i)
			tiles[i], tiles[j] = tiles[j], tiles[i]
		end
		local picks = {}
		local r = math.sqrt(#tiles / 16) * 1.2
		if r < 1 then
			r = 1
		end
		while #picks < 16 and r >= 0.9 do
			for _, p in ipairs(tiles) do
				if #picks >= 16 then
					break
				end
				local ok = true
				for _, q in ipairs(picks) do
					local dz = (p[3] ~= q[3]) and 4 or 0
					if math.max(math.abs(p[1] - q[1]), math.abs(p[2] - q[2])) + dz < r then
						ok = false
						break
					end
				end
				if ok then
					picks[#picks + 1] = p
				end
			end
			r = (r > 1 and r * 0.8 < 1) and 1 or r * 0.8
		end
		local parts = {}
		for _, p in ipairs(picks) do
			parts[#parts + 1] = string.format("{%d,%d,%d}", p[1], p[2], p[3])
		end
		out:write(string.format("[%d]={name=%q,area=%d,tiles=%d,reach=%d,poi={%s}},\n", id, s.name, s.area, total, #tiles, table.concat(parts, ",")))
	end
	out:write("}\n")
	out:close()
	logger.info("[PoiGenerator] wrote {} in {}s", OUTPUT, os.clock() - t0)
end

function generator.onStartup()
	addEvent(generate, 1000)
	return true
end

generator:register()
