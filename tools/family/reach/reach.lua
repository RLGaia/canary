-- Gaia Family server: map walk helper for self-tests (2026-10-28). Ours, not
-- upstream; never loaded by the server on its own.
--
-- In a self-test (tools/family/selftest.sh), inside run():
--   local Reach = dofile("tools/family/reach/reach.lua")
--   local r = Reach.walk({ { x, y, z } }, { openAids = { [45150] = true } })
--   r.has(x, y, z)       -- true when that square can be walked to
--   r.count              -- squares reached
--   r.closed             -- closed doors met: { x, y, z, id, aid, uid }
--
-- What it follows (the same rules the server uses for a player, from the map
-- discovery generator, tools/family/map_discovery/poi_generator.lua): walking
-- in 8 directions, stairs and holes (Tile::queryDestination), ladders, rope
-- spots and sewer grates, holes a shovel opens (loose stone piles: the
-- `holes` list of data-otservbr-global/scripts/lib/register_actions.lua),
-- teleports with a destination. Ordinary doors open;
-- doors with an action or unique id count as closed unless their action id
-- is in opts.openAids (or opts.openAll). House squares are never entered.
-- opts.limit stops after that many squares (default 3,000,000).
-- opts.box = { x1, y1, x2, y2 } keeps the walk inside that rectangle (all
-- floors); a full-world walk takes several minutes, a city area seconds.

local Reach = {}

local function key(x, y, z)
	return (z * 65536 + x) * 65536 + y
end

local function unkey(k)
	local y = k % 65536
	local xz = (k - y) / 65536
	local x = xz % 65536
	return x, y, (xz - x) / 65536
end

Reach.key = key

-- loose stone piles and the like: a shovel opens a hole down
local SHOVEL_HOLES = { [593] = true, [606] = true, [608] = true, [867] = true, [21341] = true }

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

function Reach.walk(seeds, opts)
	opts = opts or {}
	local openAids = opts.openAids or {}
	local limit = opts.limit or 3000000
	local openDoors = {}
	for _, t in ipairs({ CustomDoorTable or {}, KeyDoorTable or {}, QuestDoorTable or {}, LevelDoorTable or {} }) do
		for _, d in ipairs(t) do
			if d.closedDoor then
				openDoors[d.closedDoor] = true
			end
		end
	end
	local ladders = {}
	for _, id in ipairs(Game.getLadderIds and Game.getLadderIds() or {}) do
		ladders[id] = true
	end

	local closed, closedSeen = {}, {}
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
						local aid = item:getActionId()
						local uid = item:getUniqueId()
						local special = (aid and aid > 0) or (uid and uid > 0 and uid < 65535)
						if openDoors[item:getId()] and (not special or opts.openAll or (aid and openAids[aid])) then
							-- a door that opens for this walk
						else
							good = false
							if openDoors[item:getId()] and not closedSeen[k] then
								closedSeen[k] = true
								closed[#closed + 1] = { x = x, y = y, z = z, id = item:getId(), aid = aid, uid = uid }
							end
							break
						end
					end
				end
			end
		end
		passCache[k] = good
		return good
	end

	local function useDest(x, y, z)
		local tile = Tile(x, y, z)
		if not tile or not tile:getGround() then
			return nil
		end
		local up, down = tile:isRopeSpot(), SHOVEL_HOLES[tile:getGround():getId()] == true
		for _, item in ipairs(tile:getItems() or {}) do
			if ladders[item:getId()] then
				up = true
			elseif item:getId() == 435 or SHOVEL_HOLES[item:getId()] then
				down = true
			end
		end
		if up then
			local p = Position(x, y, z):moveUpstairs()
			return p.x, p.y, p.z
		elseif down then
			return x, y, z + 1
		end
	end

	local seen, queue, qh = {}, {}, 1
	local box = opts.box
	local function arrive(x, y, z)
		if not x or z < 0 or z > 15 then
			return
		end
		if box and (x < box[1] or y < box[2] or x > box[3] or y > box[4]) then
			return
		end
		local k = key(x, y, z)
		if seen[k] ~= nil then
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
	while qh <= #queue and qh <= limit do
		local k = queue[qh]
		qh = qh + 1
		local x, y, z = unkey(k)
		local tile = Tile(x, y, z)
		local moved = false
		if tile:hasFlag(TILESTATE_FLOORCHANGE) then
			arrive(stairsDest(tile, x, y, z))
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
					arrive(useDest(x + dx, y + dy, z))
				end
			end
		end
	end

	local reached = {}
	for i = 1, #queue do
		reached[queue[i]] = true
	end
	return {
		count = #queue,
		closed = closed,
		has = function(x, y, z)
			return reached[key(x, y, z)] == true
		end,
		reached = reached,
		unkey = unkey,
	}
end

return Reach
