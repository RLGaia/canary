local config = {
	{
		position = Position(33268, 31833, 10),
		itemid = 946,
		toPosition = Position(33268, 31833, 12),
		vocationId = VOCATION.BASE_ID.SORCERER,
	},
	{
		position = Position(33268, 31838, 10),
		itemid = 947,
		toPosition = Position(33267, 31838, 12),
		vocationId = VOCATION.BASE_ID.DRUID,
	},
	{
		position = Position(33266, 31835, 10),
		itemid = 948,
		toPosition = Position(33265, 31835, 12),
		vocationId = VOCATION.BASE_ID.KNIGHT,
	},
	{
		position = Position(33270, 31835, 10),
		itemid = 942,
		toPosition = Position(33270, 31835, 12),
		vocationId = VOCATION.BASE_ID.PALADIN,
	},
}

local elementalSpheresLever = Action()
function elementalSpheresLever.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid ~= 2772 then
		item:transform(2772)
		return true
	end

	if player:getPosition() ~= Position(33270, 31835, 10) then
		return false
	end

	local spectators = Game.getSpectators(Position(33268, 31836, 12), false, true, 30, 30, 30, 30)
	if #spectators > 0 or Game.getStorageValue(Storage.Quest.U8_2.ElementalSpheres.BossRoom) > 0 then
		player:say("Wait for the current team to exit.", TALKTYPE_MONSTER_SAY, false, 0, Position(33268, 31835, 10))
		return true
	end

	-- FAMILY: 1 to 4 players of any vocation (upstream: exactly one of each
	-- vocation). Every player on a tile must have finished the Elemental Spheres
	-- quest and carry any one of the four elemental rare items.
	local rareItems = { 946, 947, 948, 942 }
	local players = {}
	for i = 1, #config do
		local creature = Tile(config[i].position):getTopCreature()
		if creature and creature:isPlayer() then
			local hasRareItem = false
			for _, itemId in ipairs(rareItems) do
				if creature:getItemCount(itemId) > 0 then
					hasRareItem = true
				end
			end
			if not hasRareItem or creature:getStorageValue(Storage.Quest.U8_2.ElementalSpheres.QuestLine) < 1 then
				player:say("Every player on the tiles needs to have completed the Elemental Spheres quest and carry an elemental rare item.", TALKTYPE_MONSTER_SAY, false, 0, Position(33268, 31835, 10))
				return true
			end
			players[#players + 1] = { player = creature, from = config[i].position, to = config[i].toPosition }
		end
	end

	for i = 1, #players do
		players[i].player:teleportTo(players[i].to)
		players[i].from:sendMagicEffect(CONST_ME_TELEPORT)
		players[i].to:sendMagicEffect(CONST_ME_TELEPORT)
	end

	item:transform(item.itemid + 1)
	return true
end

elementalSpheresLever:uid(1010)
elementalSpheresLever:register()
