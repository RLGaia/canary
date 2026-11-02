local sacrificeTeleport = MoveEvent()

function sacrificeTeleport.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	-- FAMILY: also accept the KV the egg action sets, so players who offered an egg before the fix pass (2026-11-02)
	local teleportStorage = Storage.Quest.U10_55.SanctuaryOfTheLizardGod.LizardGodTeleport
	if player:getStorageValue(teleportStorage) ~= 1 and player:kv():scoped("lizard-god-teleport"):get("discovered") then
		player:setStorageValue(teleportStorage, 1)
	end
	if player:getStorageValue(teleportStorage) == 1 then
		player:teleportTo({ x = 32124, y = 31938, z = 8 })
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	else
		player:teleportTo(fromPosition, true)
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Offer the lives of the yet unborn to the lizard god if you want to enter the sanctuary.")
	end
	return true
end

sacrificeTeleport:uid(35010)
sacrificeTeleport:register()
