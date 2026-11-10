-- FAMILY: A Pirate's Tail Quest (ours, 2026-11-10): upstream has no quest log entry.
-- Texts: lib/others/family_pirates_tail.lua (ours). Mission id 11256. Uses the upstream storage
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
	},
}

return quest
