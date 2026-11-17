-- Gaia Family server: the sealed door to the pirate leaders' hideout on Nargor and the quest chest
-- in the leaders' boss room (2026-11-17).
-- See data-otservbr-global/lib/others/family_meriana_rebels.lua (switch Family.merianaRebels).
-- A position action wins over the ordinary door action, so this one opens and closes the door.

local M = FamilyMerianaRebels
local doorPos = Position(M.hideoutDoor.x, M.hideoutDoor.y, M.hideoutDoor.z)

local door = Action()

function door.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local id = item:getId()
	if id == M.closedDoor then
		if M.enabled() and not M.isInside(player:getPosition()) and not M.mayPass(player) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, M.sealedText)
			return true
		end
		item:transform(M.openDoor)
		item:getPosition():sendSingleSoundEffect(SOUND_EFFECT_TYPE_ACTION_OPEN_DOOR)
		if M.enabled() then
			-- like quest doors: step into the doorway, the door closes behind you
			player:teleportTo(doorPos, true)
		end
		return true
	elseif id == M.openDoor then
		if Creature.checkCreatureInsideDoor(player, toPosition) then
			return true
		end
		item:transform(M.closedDoor)
		item:getPosition():sendSingleSoundEffect(SOUND_EFFECT_TYPE_ACTION_CLOSE_DOOR)
		return true
	end
	return false
end

door:position(doorPos)
door:register()

local closeBehind = MoveEvent()
closeBehind:type("stepout")

function closeBehind.onStepOut(creature, item, position, fromPosition)
	if not M.enabled() then
		return true
	end
	local tile = Tile(doorPos)
	if not tile or tile:getTopCreature() then
		return true
	end
	local open = tile:getItemById(M.openDoor)
	if open then
		open:transform(M.closedDoor)
	end
	return true
end

closeBehind:position(doorPos)
closeBehind:register()

-- The boss room's quest chest: the leaders' items only as their loot (BR, EN).
local chest = Action()

function chest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The " .. ItemType(item:getId()):getName() .. " is empty.")
	return true
end

chest:position(Position(M.bossRoomChest.x, M.bossRoomChest.y, M.bossRoomChest.z))
if M.enabled() then -- off: the upstream quest chest (quest_system1.lua) answers again
	chest:register()
end
