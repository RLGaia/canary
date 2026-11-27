-- FAMILY: Twenty Miles Beneath the Sea Quest (ours, 2026-11-27): upstream had no quest log for it. Texts ours
-- (lib/others/family_twenty_miles.lua, FamilyTwentyMiles.describe, which loads after this file). Mission id 11300.
local S = Storage.Quest.U10_70.TwentyMilesBeneathTheSea

return {
	name = "Twenty Miles Beneath the Sea",
	startStorageId = S.Mission,
	startStorageValue = 1,
	missions = {
		{
			name = "Twenty Miles Beneath the Sea",
			storageId = S.Mission,
			missionId = 11300,
			startValue = 1,
			endValue = 24,
			description = function(player)
				return FamilyTwentyMiles and FamilyTwentyMiles.describe(player) or "Ask Mr Brandon west of Rathleton how you can assist him."
			end,
		},
	},
}
