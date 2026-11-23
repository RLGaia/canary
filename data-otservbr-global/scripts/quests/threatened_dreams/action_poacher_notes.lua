local ThreatenedDreams = Storage.Quest.U11_40.ThreatenedDreams

local poacherNotes = Action()
function poacherNotes.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local state = player:getStorageValue(ThreatenedDreams.Mission01[1])
	-- FAMILY (2026-11-22): also before stepping on the tent squares (the pile of bones can be used
	-- from the side); the tent message then comes first
	if state == 6 and FamilyThreatenedDreams and FamilyThreatenedDreams.enabled() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You discover a sleeping wolf and a gnawed skeleton in this tent. Could it be the one you are searching for?")
		player:setStorageValue(ThreatenedDreams.Mission01[1], 7)
		state = 7
	end
	if state == 7 and player:getStorageValue(ThreatenedDreams.Mission01.PoacherNotes) < 1 then
		player:addItem(25242, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found notes of a poacher.")
		player:setStorageValue(ThreatenedDreams.Mission01.PoacherNotes, 1)
	else
		player:sendCancelMessage("It is empty.")
	end

	return true
end

poacherNotes:aid(20002)
poacherNotes:register()
