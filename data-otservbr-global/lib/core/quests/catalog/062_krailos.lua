-- FAMILY: Krailos Quest (ours, 2026-11-22): upstream had no quest. TibiaWiki EN says the quest has a
-- log with the seven missions; the texts are ours (lib/others/family_krailos.lua, FamilyKrailos.log,
-- which loads after this file). Mission ids from 11275.
local S = Storage.Quest.U10_90.Krailos

local function text(group, storage)
	return function(player)
		local log = FamilyKrailos and FamilyKrailos.log[group]
		if not log then
			return ""
		end
		local value = player:getStorageValue(storage)
		return log[value] or log.default or ""
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
	},
}
