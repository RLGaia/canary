local setting = {
	arenaPosition = Position(33154, 31415, 7),
	successPosition = Position(33145, 31419, 7),
}
local TheNewFrontier = Storage.Quest.U8_54.TheNewFrontier

-- FAMILY: The New Frontier review (2026-11-09). Upstream passed the test
-- after two minutes wherever the player was (also after dying in the ring),
-- and an older timer could end a second try early. Now the player must still
-- be in the ring, and only the timer of the latest entry counts.
local entries = {}

local function inRing(player)
	local pos = player:getPosition()
	return pos.z == setting.arenaPosition.z and math.abs(pos.x - setting.arenaPosition.x) <= 6 and math.abs(pos.y - setting.arenaPosition.y) <= 6
end

local function completeTest(cid, entry)
	local player = Player(cid)
	if not player or entries[cid] ~= entry then
		return false
	end
	entries[cid] = nil
	if not inRing(player) then
		return false
	end
	if player:getStorageValue(TheNewFrontier.Questline) == 17 then
		player:teleportTo(setting.successPosition)
		player:setStorageValue(TheNewFrontier.Questline, 18)
		player:setStorageValue(TheNewFrontier.Mission06, 3) --Questlog, The New Frontier Quest "Mission 06: Days Of Doom"
		player:say("You have braved the trial of the Mooh'tah master.", TALKTYPE_MONSTER_SAY)
	end
end

local minotaurBoss = MoveEvent()

function minotaurBoss.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return false
	end

	if roomIsOccupied(setting.arenaPosition, true, 6, 6) or player:getStorageValue(TheNewFrontier.Questline) ~= 17 then
		player:teleportTo(fromPosition)
		fromPosition:sendMagicEffect(CONST_ME_TELEPORT)
		return player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You don't have access to this area.")
	end

	local entry = os.time() .. ":" .. math.random(1, 1000000)
	entries[player:getId()] = entry
	addEvent(completeTest, 2 * 60 * 1000, player:getId(), entry)
	player:teleportTo(setting.arenaPosition)
	setting.arenaPosition:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

minotaurBoss:position(Position(33146, 31413, 6))
minotaurBoss:register()
