-- FAMILY: Rathleton Quest, the citizen status in the quest log (2026-11-08). Marvin adds it
-- when asked ("status", then "yes"; TibiaWiki BR "Rathleton Quest"). The text is ours and
-- follows the rank and votes kept by lib/others/family_rathleton.lua.
local S = Storage.Quest.FamilyRathleton

local quest = {
	name = "Rathleton",
	startStorageId = S.StatusLog,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "Citizen Status",
			storageId = S.StatusLog,
			missionId = 11238,
			startValue = 1,
			endValue = 2,
			description = function(player)
				if FamilyRathleton then
					return FamilyRathleton.statusText(player)
				end
				return "Ask Marvin in the Rathleton magistrate about your citizen status."
			end,
		},
	},
}

return quest
