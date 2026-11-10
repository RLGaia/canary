-- FAMILY: A Pirate's Tail Quest (ours, 2026-11-10): upstream has no quest log entry.
-- Texts: lib/others/family_pirates_tail.lua (ours). Mission ids 11256 (Eustacio), 11257 (Rascacoon). Uses the upstream storage
-- APiratesTail.QuestLine (1 = raids for Eustacio, 2 = he told the secret passage).
local S = Storage.Quest.U12_60.APiratesTail

local quest = {
	name = "A Pirate's Tail",
	startStorageId = S.QuestLine,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "Eustacio's Pirat Raids",
			storageId = S.QuestLine,
			missionId = 11256,
			startValue = 1,
			endValue = 2,
			description = function(player)
				if FamilyPiratesTail then
					return FamilyPiratesTail.describe(player)
				end
				return "Help Eustacio in Venore against the Pirats."
			end,
		},
		[2] = {
			name = "Rascacoon",
			storageId = S.Rascacoon,
			missionId = 11257,
			startValue = 1,
			endValue = 2,
			description = function(player)
				if FamilyPiratesTail then
					return FamilyPiratesTail.describeRascacoon(player)
				end
				return "Help the colony of Rascacoon."
			end,
		},
	},
}

return quest
