-- FAMILY: Krailos Quest (ours, 2026-11-22): upstream had no quest. TibiaWiki EN says the quest has a
-- log with the seven missions; the texts are ours (lib/others/family_krailos.lua, FamilyKrailos.log,
-- which loads after this file). Mission ids 11275-11281.
local S = Storage.Quest.U10_90.Krailos

local function text(group, storage)
	return function(player)
		local log = FamilyKrailos and FamilyKrailos.log[group]
		if not log then
			return ""
		end
		local entry = log[player:getStorageValue(storage)]
		if type(entry) == "function" then
			return entry(player)
		end
		return entry or ""
	end
end

return {
	name = "Krailos Quest",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = {
		{
			name = "Hungry New World",
			storageId = S.HungryNewWorld,
			missionId = 11275,
			startValue = 1,
			endValue = 6,
			description = text("hungry", S.HungryNewWorld),
		},
		{
			name = "The Great Hunger",
			storageId = S.GreatHunger,
			missionId = 11276,
			startValue = 1,
			endValue = 6,
			description = text("hunger", S.GreatHunger),
		},
		{
			name = "Quenching the Thirst",
			storageId = S.Thirst,
			missionId = 11277,
			startValue = 1,
			endValue = 5,
			description = text("thirst", S.Thirst),
		},
		{
			name = "Survival of the Strongest",
			storageId = S.Survival,
			missionId = 11278,
			startValue = 1,
			endValue = 5,
			description = text("survival", S.Survival),
		},
		{
			name = "Revolt of the Goblins",
			storageId = S.Revolt,
			missionId = 11279,
			startValue = 1,
			endValue = 6,
			description = text("revolt", S.Revolt),
		},
		{
			name = "The Chieftain's Menu",
			storageId = S.Menu,
			missionId = 11280,
			startValue = 1,
			endValue = 2,
			ignoreendvalue = true,
			description = text("menu", S.Menu),
		},
		{
			name = "The Thunder Tusk Clan",
			storageId = S.ThunderTusk,
			missionId = 11281,
			startValue = 1,
			endValue = 2,
			description = text("tusk", S.ThunderTusk),
		},
	},
}
