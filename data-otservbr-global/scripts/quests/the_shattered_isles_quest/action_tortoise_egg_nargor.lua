-- FAMILY: Duncan's tortoise egg comes from the seven tortoise's nests behind the Nargor quest door,
-- registered by position (2026-11-17). Upstream waited for unique id 14024, which no nest on our
-- map has, so the egg could never be found. Positions: lib/others/family_shattered_isles.lua.
-- One egg per character every 24 hours, as upstream. With Family.shatteredIsles = false the nests
-- stay as upstream left them (unused).
local S = FamilyShatteredIsles

local eggItem = 6125

local tortoiseEggNargor = Action()

function tortoiseEggNargor.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not S.enabled() then
		return false
	end

	if player:getStorageValue(Storage.Quest.U7_8.TheShatteredIsles.TortoiseEggNargorTime) < os.time() then
		local egg = player:addItem(eggItem, 1, true)
		if not egg then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a tortoise egg from Nargor, but you have no room or capacity to take it.")
			return true
		end
		player:setStorageValue(Storage.Quest.U7_8.TheShatteredIsles.TortoiseEggNargorTime, os.time() + 24 * 3600)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found 1 tortoise egg from Nargor.")
	else
		-- FAMILY: upstream said "The tortoise egg from Nargor is empty."
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The tortoise's nest is empty.")
	end
	return true
end

for _, nest in ipairs(S.nests) do
	tortoiseEggNargor:position(Position(nest.x, nest.y, nest.z))
end
tortoiseEggNargor:register()
