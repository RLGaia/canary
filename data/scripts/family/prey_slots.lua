-- Gaia Family server: unlock the third Prey and Hunting Task slot of
-- existing characters (2026-10-13).
--
-- Ours, not upstream. preyFreeThirdSlot and taskHuntingFreeThirdSlot (in
-- family/config.family.lua) only apply when a character's slots are created,
-- at its first login. A character whose slots were saved as "Locked" earlier
-- keeps them locked. At every server start (before anyone can log in) this
-- opens those locked third slots with a free reroll:
--   Prey: Inactive, the same state as an empty slot (press the free reroll).
--   Hunting Tasks: Selection with an empty list (press the free reroll).
-- Slot ids: 0, 1, 2 = first, second, third.

local THIRD_SLOT = 2
local PREY_LOCKED, PREY_INACTIVE = 0, 1
local TASK_LOCKED, TASK_SELECTION = 0, 2

local function countLocked(tableName, lockedState)
	local result = db.storeQuery(string.format("SELECT COUNT(*) AS `n` FROM `%s` WHERE `slot` = %d AND `state` = %d", tableName, THIRD_SLOT, lockedState))
	if not result then
		return 0
	end
	local n = Result.getNumber(result, "n")
	Result.free(result)
	return n
end

local preySlots = GlobalEvent("FamilyPreySlots")

function preySlots.onStartup()
	local prey, tasks = 0, 0
	if configManager.getBoolean(configKeys.PREY_FREE_THIRD_SLOT) then
		prey = countLocked("player_prey", PREY_LOCKED)
		if prey > 0 then
			db.query(string.format("UPDATE `player_prey` SET `state` = %d, `free_reroll` = 0 WHERE `slot` = %d AND `state` = %d", PREY_INACTIVE, THIRD_SLOT, PREY_LOCKED))
		end
	end
	if configManager.getBoolean(configKeys.TASK_HUNTING_FREE_THIRD_SLOT) then
		tasks = countLocked("player_taskhunt", TASK_LOCKED)
		if tasks > 0 then
			db.query(string.format("UPDATE `player_taskhunt` SET `state` = %d, `free_reroll` = 0 WHERE `slot` = %d AND `state` = %d", TASK_SELECTION, THIRD_SLOT, TASK_LOCKED))
		end
	end
	logger.info("[Family] third Prey / Hunting Task slot free; unlocked now: {} prey, {} hunting task slots", prey, tasks)
	return true
end

preySlots:register()
