local condition = Condition(CONDITION_HASTE)
condition:setParameter(CONDITION_PARAM_TICKS, 22000)
-- FAMILY: old formula (speed + 0.7 x base - 56) written for the old engine; this Canary reads it as
-- new speed = 0.7 x (base - 40) - 56, which slowed the player. Same haste in the new form.
condition:setFormula(1.7, 12, 1.7, 12)

local strangelyGlowingMark = MoveEvent()

function strangelyGlowingMark.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	if item.itemid == 22076 then
		if player:getStorageValue(199990) >= os.time() then
			return true
		end
		player:addHealth(200, true, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The mythic fires beneath your feet heal you.")
		player:setStorageValue(199990, os.time() + 60)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	elseif item.itemid == 22077 then
		if player:getStorageValue(199991) >= os.time() then
			return true
		end
		player:addCondition(condition)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		player:setStorageValue(199991, os.time() + 60)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The mythic fires beneath your feet gave you speed.")
	end
	return true
end

strangelyGlowingMark:type("stepin")
strangelyGlowingMark:id(22076, 22077)
strangelyGlowingMark:register()
