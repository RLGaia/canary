local silveredTrap = MoveEvent()

function silveredTrap.onStepIn(creature, item, position, fromPosition)
	local monster = creature:getMonster()
	if not monster then
		return true
	end

	if monster:getName():lower() ~= "feroxa" then
		return true
	end
	-- FAMILY: only the second form (Feroxa2, not in the Bosstiary); the first
	-- form has 50000 health here too because of rateBossHealth.
	if monster:getType():bossRace() == nil and monster:getMaxHealth() == 50000 then
		doTargetCombatHealth(0, monster, COMBAT_UNDEFINEDDAMAGE, -1000, -1000, CONST_ME_DRAWBLOOD)
	end
	item:transform(22074)
	position:sendMagicEffect(CONST_ME_BLOCKHIT)
	return true
end

silveredTrap:type("stepin")
silveredTrap:id(22059)
silveredTrap:register()
