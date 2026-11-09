-- FAMILY: The Order of the Lion Quest (ours, 2026-11-09): upstream has no quest log entry.
-- Story and texts: lib/others/family_order_of_the_lion.lua (the text of steps 2-3 is the BR screenshot,
-- the others are ours). Mission id 11255. Uses the upstream storage TheOrderOfTheLion.QuestLine (1-12).
local S = Storage.Quest.U12_40.TheOrderOfTheLion

local quest = {
	name = "The Order of the Lion",
	startStorageId = S.QuestLine,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "The Order of the Lion",
			storageId = S.QuestLine,
			missionId = 11255,
			startValue = 1,
			endValue = 12,
			description = function(player)
				if FamilyLion then
					return FamilyLion.describe(player)
				end
				return "Help the people of Bounac."
			end,
		},
	},
}

return quest
