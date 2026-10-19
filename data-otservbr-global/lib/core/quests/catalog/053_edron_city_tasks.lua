-- FAMILY: Edron City Tasks (Daniel Steelsoul). Ours, not upstream: the tasks are
-- in data-otservbr-global/scripts/family/edron_tasks.lua. Each mission follows
-- the number of times a task was finished (0 = taken, not finished yet), so it
-- stays "(completed)" after the first time, also while the task is repeated.
-- The quest is completed when every mission is.
local S = Storage.Quest.FamilyEdronTasks

local function describe(index)
	return function(player)
		local T = FamilyEdronTasks
		local task = T and T.list[index]
		if not task then
			return "Ask Daniel Steelsoul in Edron for a task."
		end
		local times = T.times(player, task)
		local done = times > 0 and string.format(" You have finished this task %d time%s.", times, times == 1 and "" or "s") or ""
		if T.isActive(player, task) then
			local kills = T.kills(player, task)
			if kills >= task.kills then
				return string.format("You killed %d %s (%s). Report to Daniel Steelsoul in Edron for your reward.%s", task.kills, task.name, T.breakdown(player, task), done)
			end
			return string.format("Daniel Steelsoul asked you to kill %d %s %s. So far: %d of %d (%s).%s", task.kills, task.name, task.where, kills, task.kills, T.breakdown(player, task), done)
		end
		return string.format("You killed %d %s for Daniel Steelsoul.%s Ask him for this task again whenever you like.", task.kills, task.name, done)
	end
end

local names = {
	{ "Trolls", S.Times.Trolls },
	{ "Goblins", S.Times.Goblins },
	{ "Rotworms", S.Times.Rotworms },
	{ "Cyclopes", S.Times.Cyclopes },
	{ "Orcs", S.Times.Orcs },
	{ "Dwarves", S.Times.Dwarves },
	{ "Treelings", S.Times.Treelings },
	{ "Wyverns", S.Times.Wyverns },
	{ "Undead", S.Times.Undead },
	{ "Lycanthropes", S.Times.Lycanthropes },
	{ "Heroes", S.Times.Heroes },
	{ "Dragons", S.Times.Dragons },
	{ "Demons", S.Times.Demons },
}

local missions = {}
for index, entry in ipairs(names) do
	missions[index] = {
		name = "Edron City: " .. entry[1],
		storageId = entry[2],
		missionId = 11200 + index,
		startValue = 0,
		endValue = 1,
		ignoreendvalue = true,
		description = describe(index),
	}
end

local quest = {
	name = "Edron City Tasks",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = missions,
}

return quest
