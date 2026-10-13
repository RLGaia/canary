local tilesPositions = {
	{ x = 33190, y = 31629, z = 13 },
	{ x = 33191, y = 31629, z = 13 },
}

local wallsPositions = {
	{ x = 33210, y = 31630, z = 13 },
	{ x = 33211, y = 31630, z = 13 },
	{ x = 33212, y = 31630, z = 13 },
}

-- FAMILY: one player is enough. Stepping on either tile opens the walls, and
-- they close again WALLS_OPEN_SECONDS after the last player leaves the tiles
-- (upstream: two players must stand on both tiles; the walls close at once).
local WALLS_OPEN_SECONDS = 90
local closeEventId = nil

local function playerOnTiles()
	for i = 1, #tilesPositions do
		local tileCreature = Tile(tilesPositions[i]):getTopCreature()
		if tileCreature and tileCreature:getPlayer() then
			return true
		end
	end
	return false
end

local function closeWalls()
	closeEventId = nil
	if playerOnTiles() then
		return
	end
	for i = 1, #wallsPositions do
		local wall = Tile(wallsPositions[i]):getItemById(1295)
		-- Check there is no walls before create new ones
		if not wall then
			Position(wallsPositions[i]):hasCreature({ x = 33211, y = 31631, z = 13 })
			Game.createItem(1295, 1, wallsPositions[i])
		end
	end
end

local walls = MoveEvent()
walls:type("stepin")

function walls.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if closeEventId then
		stopEvent(closeEventId)
		closeEventId = nil
	end
	for i = 1, #wallsPositions do
		local wall = Tile(wallsPositions[i]):getItemById(1295)
		-- Check there walls before delete them
		if wall then
			wall:remove()
		end
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The walls are open. They close " .. WALLS_OPEN_SECONDS .. " seconds after you leave this tile.")
	return true
end

for index, value in pairs(tilesPositions) do
	walls:position(value)
end

walls:register()

walls = MoveEvent()
walls:type("stepout")

function walls.onStepOut(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if closeEventId then
		stopEvent(closeEventId)
	end
	closeEventId = addEvent(closeWalls, WALLS_OPEN_SECONDS * 1000)
	return true
end

for index, value in pairs(tilesPositions) do
	walls:position(value)
end

walls:register()
