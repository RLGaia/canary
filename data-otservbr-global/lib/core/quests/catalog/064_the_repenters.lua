-- FAMILY: The Repenters Quest (ours, 2026-11-23): upstream had no tasks. TibiaWiki EN says the
-- quest has a log; mission names are the wikis' task names, texts ours
-- (lib/others/family_repenters.lua, FamilyRepenters.describe, which loads after this file).
-- A mission shows once its task was taken; "(completed)" = reported, free again 20 hours later.
-- Mission ids 11292-11295.
local S = Storage.Quest.U10_10.TheRepenters

local function describe(task)
	return function(player)
		if not FamilyRepenters then
			return "Ask Ashari in Hellgate for work."
		end
		return FamilyRepenters.describe(player, task)
	end
end

return {
	name = "The Repenters",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = {
		{ name = "About Watering a Garden", storageId = S.Watering, missionId = 11292, startValue = 0, endValue = 3, description = describe("watering") },
		{ name = "Cultivated Magic", storageId = S.Magic, missionId = 11293, startValue = 0, endValue = 3, description = describe("magic") },
		{ name = "Catching Fire", storageId = S.Fire, missionId = 11294, startValue = 0, endValue = 3, description = describe("fire") },
		{ name = "Mushroom Soup", storageId = S.Mushroom, missionId = 11295, startValue = 0, endValue = 3, description = describe("mushroom") },
	},
}
