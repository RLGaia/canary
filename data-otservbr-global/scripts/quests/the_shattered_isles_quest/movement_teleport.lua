-- FAMILY: the mushroom portal to Talahu (aid 12585 at 31919,32600,10) checks the sacrifice
-- (2026-11-17). Upstream worked out whether the four mushrooms were right but never used it: the
-- portal always let players through, and its clean-up removed the four empty coal basins (2114)
-- instead of the mushrooms, so the room was ruined after the first use.
-- As in both wikis: white mushroom on the north-west basin, brown south-west, green north-east,
-- dark south-east; going through uses up the four mushrooms. A wrong or missing mushroom sends the
-- player back into the room (upstream's fail square) and leaves the mushrooms where they are.
local sacrifices = {
	{ itemId = 3723, position = Position(31918, 32598, 10) }, -- white mushroom, top left
	{ itemId = 3725, position = Position(31918, 32599, 10) }, -- brown mushroom, bottom left
	{ itemId = 3732, position = Position(31920, 32598, 10) }, -- green mushroom, top right
	{ itemId = 3728, position = Position(31920, 32599, 10) }, -- dark mushroom, bottom right
}

local failDestination = Position(31919, 32596, 10)
local successDestination = Position(31916, 32607, 10)

local teleport = MoveEvent()

function teleport.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local offered = {}
	for _, sacrifice in ipairs(sacrifices) do
		local tile = Tile(sacrifice.position)
		local mushroom = tile and tile:getItemById(sacrifice.itemId)
		if not mushroom then
			player:teleportTo(failDestination)
			position:sendMagicEffect(CONST_ME_ENERGYHIT)
			failDestination:sendMagicEffect(CONST_ME_ENERGYHIT)
			return true
		end
		offered[#offered + 1] = mushroom
	end

	for i, mushroom in ipairs(offered) do
		mushroom:remove(1)
		sacrifices[i].position:sendMagicEffect(CONST_ME_HITBYFIRE)
	end

	player:teleportTo(successDestination)
	position:sendMagicEffect(CONST_ME_HITBYFIRE)
	successDestination:sendMagicEffect(CONST_ME_HITBYFIRE)
	return true
end

teleport:type("stepin")
teleport:aid(12585)
teleport:register()
