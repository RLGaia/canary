local door = Action()

function door.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: the door stays open while some reward chest is still unopened (solo_quests.lua)
	local chestsLeft = Family and Family.choiceChestsLeft(player, Storage.Quest.U7_24.TheAnnihilator.Reward) or 0
	if player:getStorageValue(Storage.Quest.U7_24.TheAnnihilator.Reward) == 1 and chestsLeft == 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to be sealed against unwanted intruders.")
		return true
	end

	if item.itemid == 5113 then
		player:teleportTo(toPosition, true)
		item:transform(item.itemid + 1)
	elseif item.itemid == 5114 then
		if Creature.checkCreatureInsideDoor(player, toPosition) then
			return true
		end
		if item.itemid == 5114 then
			item:transform(item.itemid - 1)
			return true
		end
	end
	return true
end

door:aid(10102)
door:register()
