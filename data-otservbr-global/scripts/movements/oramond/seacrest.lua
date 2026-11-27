local oramondSeacrest = MoveEvent()

function oramondSeacrest.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	-- FAMILY: Twenty Miles Beneath the Sea Quest (lib/others/family_twenty_miles.lua): no helmet needed (both wikis:
	-- drowning damage without one), to the Guardian, or to the seashell cave for the Sea Ear
	if FamilyTwentyMiles and Family.twentyMiles then
		return FamilyTwentyMiles.maelstrom(player)
	end

	local headItem = player:getSlotItem(CONST_SLOT_HEAD)
	if headItem and table.contains({ 5460, 11585, 13995 }, headItem.itemid) then
		player:teleportTo(Position(33552, 31775, 13))
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You enter the seacrest ground.")
	else
		player:teleportTo(Position(33544, 31861, 7))
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You must wear an underwater exploration helmet in order to dive.")
	end
	return true
end

oramondSeacrest:type("stepin")
oramondSeacrest:uid(1110)
oramondSeacrest:register()
