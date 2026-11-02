local FireWall = MoveEvent()

function FireWall.onStepIn(creature, item, position, fromPosition)
	if creature:isMonster() then
		return true
	end

	if fromPosition.y == 32691 then
		if creature:getStorageValue(Storage.Quest.U12_20.GraveDanger.FireWall) >= 1 then
			creature:teleportTo(Position(position.x, position.y + 2, position.z))
		else
			creature:teleportTo(fromPosition)
		end
	elseif fromPosition.y == 32693 then
		creature:teleportTo(Position(position.x, position.y - 2, position.z))
	elseif fromPosition.x == 33385 then
		-- FAMILY: one pass per Custodian kill (TibiaWiki BR/EN), and a refused player stays
		-- on his side (upstream teleported him through anyway); scripts/family/cobra_bastion_secrets.lua
		local family = Family and Family.cobraBastion
		local pass = Storage.Quest.FamilyCobraBastion.FirePass
		local allowed
		if family then
			allowed = creature:getStorageValue(pass) >= 1
		else
			allowed = creature:getStorageValue(Storage.Quest.U12_20.GraveDanger.CustodianKilled) >= 1
		end
		if allowed then
			if family then
				creature:setStorageValue(pass, 0)
			end
			creature:setStorageValue(Storage.Quest.U12_20.GraveDanger.FireWall, 1)
			creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You pass the fire without taking any damage. It's now or never...")
			creature:teleportTo(Position(position.x + 2, position.y, position.z))
		else
			creature:teleportTo(fromPosition, true)
			if family then
				creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The flames are too fierce. Only the Custodian's fall could quench them.") -- ours
			end
		end
	elseif fromPosition.x == 33387 then
		creature:teleportTo(Position(position.x - 2, position.y, position.z))
	end
	creature:getPosition():sendMagicEffect(CONST_ME_HITBYFIRE)

	return true
end

FireWall:aid(36568)
FireWall:register()
