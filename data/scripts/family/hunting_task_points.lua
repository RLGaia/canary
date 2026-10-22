-- Gaia Family server: more Hunting Task Points (2026-10-21). Ours, not upstream.
--
-- Hunting tasks (Prey window) pay 10 to 912 Hunting Task Points (C++ IOPrey:
-- easy/medium/hard creature, stars, bigger kill count), while Walter Jaeger in
-- Thais sells the Falconer outfit for 100,000 and the Antelope for 145,000. Real
-- Tibia adds Weekly Tasks as a second source, which Canary does not have.
-- Chosen by Rodrigo: claimed points x10, and no 20-hour wait before the slot
-- takes a new creature (taskHuntingLimitedTasksExhaust = 0 in config.family.lua).
--
-- The points are added in C++ when the task is claimed, with no Lua event, so
-- the recvbyte module data/modules/scripts/family/hunting_tasks.lua (packet 0xBA,
-- every Hunting Task action) calls Family.boostHuntingTaskClaim: it notes the
-- points and, a moment later, adds (multiplier - 1) x what the claim gave. Only
-- a claim raises the points, so any other action changes nothing. The Hunting
-- Task window still shows the C++ amounts; the server message says the total.
--
-- Slot ready again (2026-10-21, reported by Rodrigo): after a claim the C++ sets
-- the slot to "inactive" (the client shows Exhausted, every button disabled) and
-- only makes it selectable again at the next login once the wait is over; with
-- no wait, it stayed Exhausted for the whole session. The server does accept a
-- list reroll on that slot (IOPrey ListReroll checks only the wait), so right
-- after a successful claim the client is told the slot is selecting with an empty
-- list: the Free reroll and full-list buttons are enabled, and the first click
-- gives a new list as usual. Relogging also fixes the slot.
--
-- Switches: Family.huntingTaskPointsMultiplier (1 = upstream amounts),
-- Family.huntingTaskSlotReadyAfterClaim (false = upstream Exhausted slot).

Family = Family or {}
Family.huntingTaskPointsMultiplier = 10
Family.huntingTaskSlotReadyAfterClaim = true

local ACTION_CLAIM = 5 -- PreyTaskAction_Claim
local STATE_SELECTION = 2 -- PreyTaskDataState_Selection
local SERVER_TASK_DATA = 0xBB

-- Tells the client the slot is choosing a creature (empty list, free reroll).
function Family.sendHuntingTaskSlotReady(player, slot)
	local msg = NetworkMessage()
	msg:addByte(SERVER_TASK_DATA)
	msg:addByte(slot)
	msg:addByte(STATE_SELECTION)
	msg:addU16(0) -- no creatures listed until the reroll
	msg:addU32(0) -- free reroll available now
	msg:sendToPlayer(player)
	msg:delete()
end

local DELAY = 300 -- ms; the server handles the packet right after the module

local function checkClaim(playerId, before, slot)
	local player = Player(playerId)
	if not player then
		return
	end
	local gained = player:getTaskHuntingPoints() - before
	if gained <= 0 then
		return -- not a claim, or the claim was refused
	end
	local multiplier = Family.huntingTaskPointsMultiplier or 1
	if multiplier > 1 then
		local bonus = math.floor(gained * (multiplier - 1))
		player:addTaskHuntingPoints(bonus)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Hunting task bonus (x%d): +%d Hunting Task Points, %d in total for this task. You now have %d.", multiplier, bonus, gained + bonus, player:getTaskHuntingPoints()))
	end
	if slot and Family.huntingTaskSlotReadyAfterClaim and configManager.getNumber(configKeys.TASK_HUNTING_LIMIT_EXHAUST) == 0 then
		Family.sendHuntingTaskSlotReady(player, slot)
	end
end

-- Called by the recvbyte module with the packet right after its 0xBA byte:
-- slot (u8), action (u8), upgrade (u8), race id (u16). The position is put back,
-- so the server reads the packet as usual.
function Family.boostHuntingTaskClaim(player, msg)
	if not player then
		return
	end
	local slot, action
	if msg and msg:getUnreadBytes() >= 5 then
		slot = msg:getByte()
		action = msg:getByte()
		msg:skipBytes(-2)
	end
	if action ~= nil and action ~= ACTION_CLAIM then
		return
	end
	if (Family.huntingTaskPointsMultiplier or 1) <= 1 and not Family.huntingTaskSlotReadyAfterClaim then
		return
	end
	addEvent(checkClaim, DELAY, player:getId(), player:getTaskHuntingPoints(), slot)
end

local startup = GlobalEvent("FamilyHuntingTaskPoints")

function startup.onStartup()
	logger.info("[Family] hunting task points x{}, wait after claiming {} s", Family.huntingTaskPointsMultiplier, configManager.getNumber(configKeys.TASK_HUNTING_LIMIT_EXHAUST))
	return true
end

startup:register()
