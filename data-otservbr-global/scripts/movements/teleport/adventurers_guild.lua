local adventurersGuild = MoveEvent()

function adventurersGuild.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local townId = player:getStorageValue(Storage.Quest.U9_80.AdventurersGuild.Stone)
	local destination = townId ~= -1 and Town(townId):getTemplePosition() or player:getTown():getTemplePosition()
	-- FAMILY: always back to the home temple (2026-10-20, asked by Rodrigo; switch
	-- Family.adventurerGuildExitHome in data/scripts/family/adventurer_stone.lua)
	if Family and Family.adventurerGuildExitHome then
		destination = player:getTown():getTemplePosition()
	end

	player:setStorageValue(Storage.Quest.U9_80.AdventurersGuild.Stone, -1)
	player:teleportTo(destination)
	position:sendMagicEffect(CONST_ME_TELEPORT)
	destination:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

adventurersGuild:type("stepin")
adventurersGuild:aid(4253)
adventurersGuild:register()
