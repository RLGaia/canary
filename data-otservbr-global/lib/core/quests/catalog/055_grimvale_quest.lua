-- FAMILY: Grimvale Quest (ours, 2026-10-28): upstream has no quest log entry.
-- Mission "The Curse Spreads": lib/others/family_grimvale.lua and
-- scripts/family/curse_spreads.lua; mission "An Ancient Feud" (starts after
-- The Curse Spreads): lib/others/family_ancient_feud.lua and
-- scripts/family/ancient_feud.lua; mission "The Curse of the Full Moon"
-- (Maeryn): lib/others/family_full_moon.lua and scripts/family/full_moon.lua.
-- Mission ids 11228, 11229 and 11230. The quest starts with any of them
-- (Storage.Quest.FamilyGrimvale.Questline).
local S = Storage.Quest.FamilyCurseSpreads

local quest = {
	name = "Grimvale Quest",
	startStorageId = Storage.Quest.FamilyGrimvale.Questline,
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
		[2] = {
			name = "An Ancient Feud",
			storageId = Storage.Quest.FamilyAncientFeud.Mission,
			missionId = 11229,
			startValue = 1,
			endValue = 14,
			description = function(player)
				if FamilyAncientFeud then
					return FamilyAncientFeud.describe(player)
				end
				return "Talk to Daniel Steelsoul in Edron about the lions."
			end,
		},
		[3] = {
			name = "The Curse of the Full Moon",
			storageId = Storage.Quest.FamilyFullMoon.Mission,
			missionId = 11230,
			startValue = 1,
			endValue = 3,
			description = function(player)
				if FamilyFullMoon then
					return FamilyFullMoon.describe(player)
				end
				return "Talk to Maeryn on Grimvale."
			end,
		},
	},
}

return quest
