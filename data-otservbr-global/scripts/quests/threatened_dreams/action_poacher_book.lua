local ThreatenedDreams = Storage.Quest.U11_40.ThreatenedDreams

-- FAMILY (2026-11-22): the doctored book from Ahmet (25239, EN) on the table next to the dripping
-- candles in the poacher room; upstream took the original book (25235) on any such table and failed
-- with a Lua error when used on a creature or nothing.
local POACHER_ROOM = { from = Position(32784, 31970, 11), to = Position(32792, 31980, 11) }

local poacherBook = Action()
function poacherBook.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local family = FamilyThreatenedDreams and FamilyThreatenedDreams.enabled()
	if not target or type(target) ~= "userdata" or not target.getId then
		return false
	end
	if player:getStorageValue(ThreatenedDreams.Mission01[1]) == 2 then
		if (target.itemid == 12648 or target.itemid == 12649) and (not family or toPosition:isInRange(POACHER_ROOM.from, POACHER_ROOM.to)) then
			item:remove(1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are placing the book on the table, hopefully the poachers will discover it soon.")
			toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
			player:setStorageValue(ThreatenedDreams.Mission01[1], 3)
			return true
		end
		return false
	elseif not family then
		player:sendCancelMessage("You are not on that mission.")
	end
	return false
end

if FamilyThreatenedDreams and FamilyThreatenedDreams.enabled() then
	poacherBook:id(25239)
else
	poacherBook:id(25235)
end
poacherBook:register()
