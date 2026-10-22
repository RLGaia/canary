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
-- Switch: Family.huntingTaskPointsMultiplier (1 = upstream amounts).

Family = Family or {}
Family.huntingTaskPointsMultiplier = 10

local DELAY = 300 -- ms; the server handles the packet right after the module

local function checkClaim(playerId, before)
	local player = Player(playerId)
	if not player then
		return
	end
	local gained = player:getTaskHuntingPoints() - before
	local multiplier = Family.huntingTaskPointsMultiplier or 1
	if gained <= 0 or multiplier <= 1 then
		return
	end
	local bonus = math.floor(gained * (multiplier - 1))
	player:addTaskHuntingPoints(bonus)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Hunting task bonus (x%d): +%d Hunting Task Points, %d in total for this task. You now have %d.", multiplier, bonus, gained + bonus, player:getTaskHuntingPoints()))
end

function Family.boostHuntingTaskClaim(player)
	if not player or (Family.huntingTaskPointsMultiplier or 1) <= 1 then
		return
	end
	addEvent(checkClaim, DELAY, player:getId(), player:getTaskHuntingPoints())
end

local startup = GlobalEvent("FamilyHuntingTaskPoints")

function startup.onStartup()
	logger.info("[Family] hunting task points x{}, wait after claiming {} s", Family.huntingTaskPointsMultiplier, configManager.getNumber(configKeys.TASK_HUNTING_LIMIT_EXHAUST))
	return true
end

startup:register()
