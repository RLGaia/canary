-- FAMILY: Adventures of Galthen, Galthen and the Lost Queen (ours, 2026-11-23): upstream had no quest log
-- for it. Texts ours (lib/others/family_galthen.lua, FamilyGalthen.describe, which loads after this file).
-- Mission id 11296.
local S = Storage.Quest.U12_70.AdventuresOfGalthen

return {
	name = "Adventures of Galthen",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = {
		{
			name = "Galthen and the Lost Queen",
			storageId = S.LostQueen,
			missionId = 11296,
			startValue = 0,
			endValue = 9,
			description = function(player)
				return FamilyGalthen and FamilyGalthen.describe(player) or "Ask Kesar the Younger in Bounac about Yselda."
			end,
		},
	},
}
