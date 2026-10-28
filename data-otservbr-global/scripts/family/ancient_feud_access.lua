-- Gaia Family server: Lion Sanctum doors for level 250+ (2026-10-28). Ours,
-- not upstream.
--
-- The four Lion Sanctum bosses (Katex Blood Tongue, Srezz Yellow Eyes, Utua
-- Stone Sting, Yirkas Blue Scales) belong to the Grimvale Quest mission "An
-- Ancient Feud", which upstream never implemented: the three quest doors with
-- action id Storage...GrimvaleQuest.AncientFeudDoors (startup/tables/
-- door_quest.lua) opened for nobody, so the bosses could not be reached.
-- Map walk (tools/family/reach) from Darashia: with these doors open the
-- Sanctum (floors 10-11, from inside Lion's Rock after the Lion's Tests) and
-- the boss floor (floor 12, also from the Hyaena Lairs) are reachable; only
-- Heliodor's room is not (its entrance is part of the mission).
--
-- Until the mission exists (Rodrigo's choice on 2026-10-27, "option 2"): a
-- character of level Family.ancientFeudDoorLevel or more passes the doors as
-- if they had the quest storage. The boss slabs keep their own level 250 and
-- the boss cooldown rules.
--   * 33124,32261,10  Sanctum entrance (in Tibia: the werelions' phrase)
--   * 33123,32230,12  boss room door (in Tibia: after the Slightly Feline Statue)
--   * 33159,32322,12  door between the Sanctum and the Hyaena Lairs
-- Switch: Family.ancientFeudDoorLevel (false = only the quest storage).

Family = Family or {}
Family.ancientFeudDoorLevel = 250

local DOORS = {
	Position(33124, 32261, 10),
	Position(33123, 32230, 12),
	Position(33159, 32322, 12),
}

local function questOpen(player)
	local key = Storage.Quest.U10_80.GrimvaleQuest.AncientFeudDoors
	return player:getStorageValue(key) ~= -1
end

function Family.canPassAncientFeudDoor(player)
	if questOpen(player) then
		return true
	end
	local level = Family.ancientFeudDoorLevel
	return level and player:getLevel() >= level or false
end

local door = Action()

function door.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for _, value in ipairs(QuestDoorTable) do
		if value.closedDoor == item.itemid then
			if Family.canPassAncientFeudDoor(player) then
				item:transform(value.openDoor)
				item:getPosition():sendSingleSoundEffect(SOUND_EFFECT_TYPE_ACTION_OPEN_DOOR)
				player:teleportTo(toPosition, true)
			elseif Family.ancientFeudDoorLevel then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("The door seems to be sealed against unwanted intruders. Only adventurers of level %d or higher may pass.", Family.ancientFeudDoorLevel))
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to be sealed against unwanted intruders.")
			end
			return true
		end
	end
	-- an open door: leave it to the normal door handling (closing, walking through)
	if Creature.checkCreatureInsideDoor(player, toPosition) then
		return true
	end
	return true
end

for _, pos in ipairs(DOORS) do
	door:position(pos)
end
door:register()
