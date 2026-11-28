-- FAMILY: Shadows of Yalahar Quest (ours, 2026-11-27): upstream had no quest log for it. Texts ours
-- (lib/others/family_shadows_of_yalahar.lua, FamilyShadowsYalahar.describe). Mission id 11301.
local S = Storage.Quest.U8_5.ShadowsOfYalahar

return {
	name = "Shadows of Yalahar",
	startStorageId = S.Mission,
	startStorageValue = 1,
	missions = {
		{
			name = "Shadows of Yalahar",
			storageId = S.Mission,
			missionId = 11301,
			startValue = 1,
			endValue = 26,
			description = function(player)
				return FamilyShadowsYalahar and FamilyShadowsYalahar.describe(player) or "Ask Telas in Edron for a mission."
			end,
		},
	},
}
