-- Gaia Family server: point of interest generator for the Cyclopedia map discovery.
-- Ours, not upstream. Not loaded by the server: copy it to data/scripts/ for one start
-- of a test server (see README.md), then delete it.
--
-- Reads masks.lua (export_masks.py) and writes poi_candidates.lua: for every subarea the
-- real point of interest spots that can be walked to on our map ("real"), and up to 16
-- evenly spread reachable tiles on any floor below or above its shape ("poi").
--
-- 2026-10-21: a point was found inside a Stonehome house. Canary v3.6.1 has no
-- TILESTATE_HOUSE (the flag was nil, so houses were never skipped); houses are now found
-- with Tile:getHouse(). The walk also follows stairs, holes, ladders, rope spots, sewer
-- grates and teleports to the exact square the server sends a player to (it used to mark
-- every square within 2 of it, which could cross walls), and locked doors stay closed.
-- Temples are the start; NPC squares and the positions in NPC scripts (boat destinations,
-- quest teleports) only add the part of the map they lead to when it has at least
-- MIN_REGION squares, so the few squares behind a shop counter are not used.

local MASKS = "masks.lua" -- paths relative to the server folder; change if needed
local OUTPUT = "poi_candidates.lua"
local MIN_REGION = 100

local generator = GlobalEvent("FamilyPoiGenerator")

local function generate()
	local t0 = os.clock()
	local M = dofile(MASKS)
	local function key(x, y, z)
		return (z * 65536 + x) * 65536 + y
	end
	local function unkey(k)
		local y = k % 65536
		local xz = (k - y) / 65536
		local x = xz % 65536
		return x, y, (xz - x) / 65536
	end

	-- ordinary doors anyone can open (no action or unique id)
	local openDoors = {}
	for _, t in ipairs({ CustomDoorTable, KeyDoorTable }) do
		for _, d in ipairs(t) do
			if d.closedDoor then
				openDoors[d.closedDoor] = true
			end
		end
	end
	local ladders = {}
	for _, id in ipairs(Game.getLadderIds()) do
		ladders[id] = true
	end

	local passCache = {}
	local function passable(x, y, z)
		local k = key(x, y, z)
		local c = passCache[k]
		if c ~= nil then
			return c
		end
		local tile = Tile(x, y, z)
		local good = true
		if not tile or not tile:getGround() or tile:getHouse() then
			good = false
		elseif tile:hasProperty(CONST_PROP_BLOCKSOLID) or tile:hasProperty(CONST_PROP_IMMOVABLEBLOCKSOLID) then
			if ItemType(tile:getGround():getId()):isBlocking() then
				good = false
			else
				for _, item in ipairs(tile:getItems() or {}) do
					if ItemType(item:getId()):isBlocking() then
						if not openDoors[item:getId()] or item:hasAttribute(ITEM_ATTRIBUTE_ACTIONID) or item:hasAttribute(ITEM_ATTRIBUTE_UNIQUEID) then
							good = false
							break
						end
					end
				end
			end
		end
		passCache[k] = good
		return good
	end

	-- where stairs and holes take a player (Tile::queryDestination in the C++)
	local function stairsDest(tile, x, y, z)
		if tile:hasFlag(TILESTATE_FLOORCHANGE_DOWN) then
			local dx, dy, dz = x, y, z + 1
			local s = Tile(dx, dy - 1, dz)
			local e = Tile(dx - 1, dy, dz)
			if s and s:hasFlag(TILESTATE_FLOORCHANGE_SOUTH_ALT) then
				dy = dy - 2
			elseif e and e:hasFlag(TILESTATE_FLOORCHANGE_EAST_ALT) then
				dx = dx - 2
			else
				local d = Tile(dx, dy, dz)
				if not d then
					return nil
				end
				if d:hasFlag(TILESTATE_FLOORCHANGE_NORTH) then
					dy = dy + 1
				end
				if d:hasFlag(TILESTATE_FLOORCHANGE_SOUTH) then
					dy = dy - 1
				end
				if d:hasFlag(TILESTATE_FLOORCHANGE_SOUTH_ALT) then
					dy = dy - 2
				end
				if d:hasFlag(TILESTATE_FLOORCHANGE_EAST) then
					dx = dx - 1
				end
				if d:hasFlag(TILESTATE_FLOORCHANGE_EAST_ALT) then
					dx = dx - 2
				end
				if d:hasFlag(TILESTATE_FLOORCHANGE_WEST) then
					dx = dx + 1
				end
			end
			return dx, dy, dz
		end
		local dx, dy, dz = x, y, z - 1
		if tile:hasFlag(TILESTATE_FLOORCHANGE_NORTH) then
			dy = dy - 1
		end
		if tile:hasFlag(TILESTATE_FLOORCHANGE_SOUTH) then
			dy = dy + 1
		end
		if tile:hasFlag(TILESTATE_FLOORCHANGE_EAST) then
			dx = dx + 1
		end
		if tile:hasFlag(TILESTATE_FLOORCHANGE_WEST) then
			dx = dx - 1
		end
		if tile:hasFlag(TILESTATE_FLOORCHANGE_SOUTH_ALT) then
			dy = dy + 2
		end
		if tile:hasFlag(TILESTATE_FLOORCHANGE_EAST_ALT) then
			dx = dx + 2
		end
		return dx, dy, dz
	end

	-- where using a ladder, a rope spot or a sewer grate on this square takes a player
	local useCache = {}
	local function useDest(x, y, z)
		local k = key(x, y, z)
		local c = useCache[k]
		if c ~= nil then
			return c
		end
		c = false
		local tile = Tile(x, y, z)
		if tile and tile:getGround() then
			local up, down = tile:isRopeSpot(), false
			for _, item in ipairs(tile:getItems() or {}) do
				if ladders[item:getId()] then
					up = true
				elseif item:getId() == 435 then -- sewer grate (actions/items/ladder_up.lua)
					down = true
				end
			end
			if up then
				local p = Position(x, y, z):moveUpstairs()
				c = { p.x, p.y, p.z }
			elseif down then
				c = { x, y, z + 1 }
			end
		end
		useCache[k] = c
		return c
	end

	-- Walks from the seeds; squares already in `reached` are not walked again.
	-- Returns the list of new squares.
	local function walk(seeds, reached)
		local seen, queue, qh = {}, {}, 1
		local function arrive(x, y, z)
			if z < 0 or z > 15 then
				return
			end
			local k = key(x, y, z)
			if reached[k] or seen[k] ~= nil then
				return
			end
			local good = passable(x, y, z)
			seen[k] = good
			if good then
				queue[#queue + 1] = k
			end
		end
		for _, s in ipairs(seeds) do
			arrive(s[1], s[2], s[3])
		end
		while qh <= #queue do
			local k = queue[qh]
			qh = qh + 1
			local x, y, z = unkey(k)
			local tile = Tile(x, y, z)
			local moved = false
			if tile:hasFlag(TILESTATE_FLOORCHANGE) then
				local dx, dy, dz = stairsDest(tile, x, y, z)
				if dx then
					arrive(dx, dy, dz)
				end
				moved = true
			end
			if tile:hasFlag(TILESTATE_TELEPORT) then
				for _, item in ipairs(tile:getItems() or {}) do
					local ok, dest = pcall(function()
						return Teleport(item:getUniqueId()):getDestination()
					end)
					if ok and dest and dest.x > 0 then
						arrive(dest.x, dest.y, dest.z)
						moved = true
					end
				end
			end
			if not moved then
				for dx = -1, 1 do
					for dy = -1, 1 do
						if dx ~= 0 or dy ~= 0 then
							arrive(x + dx, y + dy, z)
						end
						local u = useDest(x + dx, y + dy, z)
						if u then
							arrive(u[1], u[2], u[3])
						end
					end
				end
			end
		end
		return queue
	end

	local reached, count = {}, 0
	local function accept(list)
		for _, k in ipairs(list) do
			reached[k] = true
		end
		count = count + #list
	end
	local temples = {}
	for _, town in pairs(Game.getTowns()) do
		local p = town:getTemplePosition()
		temples[#temples + 1] = { p.x, p.y, p.z }
	end
	accept(walk(temples, reached))
	local extra, kept, dropped = {}, 0, 0
	for _, p in ipairs(M.dests or {}) do
		extra[#extra + 1] = p
	end
	for _, n in ipairs(M.npcs) do
		extra[#extra + 1] = n
	end
	for _, s in ipairs(extra) do
		local list = walk({ s }, reached)
		if #list >= MIN_REGION then
			accept(list)
			kept = kept + 1
		elseif #list > 0 then
			dropped = dropped + 1
		end
	end
	logger.info("[PoiGenerator] {} reachable tiles ({} extra starts kept, {} small ones left out) in {}s", count, kept, dropped, os.clock() - t0)

	local function usable(x, y, z)
		if not reached[key(x, y, z)] then
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
		-- real spots (TibiaMaps.io markers), moved to the nearest usable tile within 2
		local real, taken = {}, {}
		for _, p in ipairs((M.real or {})[id] or {}) do
			local best
			for r = 0, 2 do
				for dx = -r, r do
					for dy = -r, r do
						if not best and math.max(math.abs(dx), math.abs(dy)) == r and usable(p[1] + dx, p[2] + dy, p[3]) then
							best = { p[1] + dx, p[2] + dy, p[3] }
						end
					end
				end
			end
			if best and not taken[key(best[1], best[2], best[3])] then
				taken[key(best[1], best[2], best[3])] = true
				real[#real + 1] = best
			end
		end
		-- every usable tile of the subarea, on every floor
		local tiles, total = {}, 0
		for _, sp in ipairs(s.spans) do
			for x = sp[2], sp[3] do
				total = total + 1
				for z = 0, 15 do
					if usable(x, sp[1], z) then
						tiles[#tiles + 1] = { x, sp[1], z }
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
		local realParts = {}
		for _, p in ipairs(real) do
			realParts[#realParts + 1] = string.format("{%d,%d,%d}", p[1], p[2], p[3])
		end
		out:write(string.format("[%d]={name=%q,area=%d,tiles=%d,reach=%d,real={%s},poi={%s}},\n", id, s.name, s.area, total, #tiles, table.concat(realParts, ","), table.concat(parts, ",")))
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
