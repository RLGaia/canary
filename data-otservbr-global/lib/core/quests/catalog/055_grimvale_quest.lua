-- FAMILY: Grimvale Quest (ours, 2026-10-28): upstream has no quest log entry.
-- Mission "The Curse Spreads": lib/others/family_grimvale.lua and
-- scripts/family/curse_spreads.lua. Mission ids 11228 (The Curse Spreads);
-- 11229 is kept for An Ancient Feud.
local S = Storage.Quest.FamilyCurseSpreads

local quest = {
	name = "Grimvale Quest",
	startStorageId = S.Mission,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "The Curse Spreads",
			storageId = S.Mission,
			missionId = 11228,
			startValue = 1,
			endValue = 12,
			description = function(player)
				if FamilyCurseSpreads then
					return FamilyCurseSpreads.describe(player)
				end
				return "Talk to Daniel Steelsoul in Edron about the curse."
			end,
		},
	},
}

return quest
