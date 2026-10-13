local config = {
	{
		fromPosition = Position(32677, 32089, 8),
		toPosition = Position(32671, 32071, 8),
		sacrificePosition = Position(32679, 32089, 8),
		sacrificeId = 3059,
		vocationId = VOCATION.BASE_ID.SORCERER,
	},
	{
		fromPosition = Position(32669, 32089, 8),
		toPosition = Position(32673, 32071, 8),
		sacrificePosition = Position(32667, 32089, 8),
		sacrificeId = 3585,
		vocationId = VOCATION.BASE_ID.DRUID,
	},
	{
		fromPosition = Position(32673, 32085, 8),
		toPosition = Position(32670, 32071, 8),
		sacrificePosition = Position(32673, 32083, 8),
		sacrificeId = 3349,
		vocationId = VOCATION.BASE_ID.PALADIN,
	},
	{
		fromPosition = Position(32673, 32093, 8),
		toPosition = Position(32672, 32071, 8),
		sacrificePosition = Position(32673, 32094, 8),
		sacrificeId = 3264,
		vocationId = VOCATION.BASE_ID.KNIGHT,
	},
}

local othersDesert = Action()
function othersDesert.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	item:transform(item.itemid == 2772 and 2773 or 2772)

	if item.itemid ~= 2772 then
		return true
	end

	local position = player:getPosition()

	-- FAMILY: 1 to 4 players of any vocation (upstream: exactly one of each
	-- vocation). All four sacrifices are still required on the altars.
	for i = 1, #config do
		if not Tile(config[i].sacrificePosition):getItemById(config[i].sacrificeId) then
			player:sendCancelMessage("A sacrifice is missing on one of the altars.")
			position:sendMagicEffect(CONST_ME_POFF)
			return true
		end
	end

	local travellers = {}
	for i = 1, #config do
		local creature = Tile(config[i].fromPosition):getTopCreature()
		if creature and creature:isPlayer() then
			travellers[#travellers + 1] = { player = creature, destination = config[i].toPosition }
		end
	end
	if #travellers == 0 then
		-- Nobody on the tiles: the player who pulled the lever goes alone.
		local destination = config[1].toPosition
		local vocationId = player:getVocation():getBaseId()
		for i = 1, #config do
			if config[i].vocationId == vocationId then
				destination = config[i].toPosition
			end
		end
		travellers[1] = { player = player, destination = destination }
	end

	for i = 1, #config do
		local sacrificeItem = Tile(config[i].sacrificePosition):getItemById(config[i].sacrificeId)
		if sacrificeItem then
			sacrificeItem:remove()
		end
	end

	for i = 1, #travellers do
		local traveller = travellers[i]
		traveller.player:getPosition():sendMagicEffect(CONST_ME_POFF)
		traveller.player:teleportTo(traveller.destination)
		traveller.destination:sendMagicEffect(CONST_ME_TELEPORT)
	end
	return true
end

othersDesert:uid(30030)
othersDesert:register()
