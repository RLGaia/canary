function Player.sendFakeDeathWindow(self)
	local msg = NetworkMessage()
	-- I found this in the function ProtocolGame::sendReLoginWindow
	msg:addByte(0x28)
	msg:addByte(0x00)
	msg:addByte(0x00)
	msg:addByte(0x00)
	msg:sendToPlayer(self)
	return true
end

local condition = Condition(CONDITION_OUTFIT)
condition:setTicks(-1)

local conditions = {
	CONDITION_POISON,
	CONDITION_FIRE,
	CONDITION_ENERGY,
	CONDITION_BLEEDING,
	CONDITION_HASTE,
	CONDITION_PARALYZE,
	CONDITION_INVISIBLE,
	CONDITION_LIGHT,
	CONDITION_MANASHIELD,
	CONDITION_INFIGHT,
	CONDITION_DRUNK,
	CONDITION_SOUL,
	CONDITION_DROWN,
	CONDITION_YELLTICKS,
	CONDITION_ATTRIBUTES,
	CONDITION_FREEZING,
	CONDITION_DAZZLED,
	CONDITION_CURSED,
	CONDITION_EXHAUST_COMBAT,
	CONDITION_EXHAUST_HEAL,
	CONDITION_SPELLCOOLDOWN,
	CONDITION_SPELLGROUPCOOLDOWN,
}

local iceDeath = MoveEvent()

function iceDeath.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if player:getStorageValue(Storage.Quest.U11_40.CultsOfTibia.Barkless.Ice) == 2 then
		player:setStorageValue(Storage.Quest.U11_40.CultsOfTibia.Barkless.Ice, 3)
		player:setStorageValue(Storage.Quest.U11_40.CultsOfTibia.Barkless.Death, 1)
		for _, conditionType in pairs(conditions) do
			if player:getCondition(conditionType) then
				player:removeCondition(conditionType)
			end
		end
		-- FAMILY (2026-11-17): no corpse outfit; the player comes back in the temple (FamilyCults.purificationDeath)
		if not (Family and Family.cultsOfTibia) then
			condition:setOutfit(player:getSex() == PLAYERSEX_FEMALE and 4247 or 4240)
			player:addCondition(condition)
		end
		local it = Game.createItem(player:getSex() == PLAYERSEX_FEMALE and 4247 or 4240, 1, player:getPosition())
		if it then
			it:decay()
		end
		if Family and Family.cultsOfTibia then
			FamilyCults.purificationDeath(player)
		else
			player:addHealth(-player:getHealth() + 1)
		end
		player:sendTextMessage(MESSAGE_BEYOND_LAST, "You were killed by something evil and others.")
		-- FAMILY (2026-11-17): the upstream line listed eight blessings whether you had them or not
		if not (Family and Family.cultsOfTibia) then
			player:sendTextMessage(MESSAGE_BEYOND_LAST, "You are still blessed with Wisdom of Solitude, Spark of the Phoenix, Fire of the Suns, Spiritual Shielding, Embrace of Tibia, Heart of the Mountain, Blood of the Mountain, and Twist of Fate.")
		end
		player:sendTextMessage(MESSAGE_BEYOND_LAST, "You lost 0 experience and 0.00% of all of your skills.")
		player:sendTextMessage(MESSAGE_BEYOND_LAST, "You did not lose any items.")
		player:setStorageValue(Storage.Quest.U11_40.CultsOfTibia.Barkless.Mission, 3)
		player:setStorageValue(Storage.Quest.U11_40.CultsOfTibia.Barkless.AccessDoor, 1)
		player:sendTextMessage(MESSAGE_BEYOND_LAST, "The cold has all but disappeared from your body and you're getting warmer. You need to renew all preparations for purification.")
		player:sendFakeDeathWindow()
	else
		player:teleportTo(fromPosition, true)
	end
	return true
end

iceDeath:type("stepin")
iceDeath:aid(5533)
iceDeath:register()
