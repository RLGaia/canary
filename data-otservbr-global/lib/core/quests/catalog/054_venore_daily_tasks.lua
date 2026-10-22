-- FAMILY: Venore Daily Tasks (Norman the Foreman). Ours, not upstream: the tasks
-- are in data-otservbr-global/lib/others/family_venore_tasks.lua. A mission shows
-- once its task was taken; "(completed)" means reported today (free again after
-- the server save at 06:00).
local S = Storage.Quest.FamilyVenoreTasks

local function describe(task)
	return function(player)
		if not FamilyVenoreTasks then
			return "Ask Norman the Foreman in the Venore swamp for work."
		end
		return FamilyVenoreTasks.describe(player, task)
	end
end

return {
	name = "Venore Daily Tasks",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = {
		{ name = "Sabotage", storageId = S.Sabotage, missionId = 11222, startValue = 0, endValue = 3, description = describe("sabotage") },
		{ name = "Maintenance", storageId = S.Maintenance, missionId = 11223, startValue = 0, endValue = 3, description = describe("maintenance") },
		{ name = "Pathfinder", storageId = S.Pathfinder, missionId = 11224, startValue = 0, endValue = 3, description = describe("pathfinder") },
	},
}
