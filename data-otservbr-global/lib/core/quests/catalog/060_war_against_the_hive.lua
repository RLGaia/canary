-- FAMILY: War Against the Hive Quest (Orockle). Ours, not upstream: the quest is in
-- data-otservbr-global/lib/others/family_hive.lua and scripts/family/war_against_the_hive.lua.
-- The first mission shows war experience, favour, the Hive stage and the pheromone (EN: "you can
-- check your war exp and favour by checking the quest log"); the others follow each mission and the
-- number of times it was done (0 = taken, not done yet). Mission ids 11265-11271.
local S = Storage.Quest.U9_4.WarAgainstTheHive

local missions = {
	{
		name = "The Hive War",
		storageId = S.Questline,
		missionId = 11265,
		startValue = 1,
		endValue = 2,
		ignoreendvalue = true,
		description = function(player)
			return FamilyHive and FamilyHive.describeWar(player) or "Orockle on Gray Beach fights the Hive Born."
		end,
	},
}

-- names and storages here (this file loads before lib/others/family_hive.lua)
local list = {
	{ "acid", "Chitin Dissolving", S.Times.Acid },
	{ "blind", "Antennae Blinding", S.Times.Blind },
	{ "digestion", "Hive Digestion", S.Times.Digestion },
	{ "disable", "Pore Stuffing", S.Times.Disable },
	{ "kill", "Guard Killing", S.Times.Kill },
	{ "break", "Crystal Destruction", S.Times.Break },
}
for index, entry in ipairs(list) do
	missions[#missions + 1] = {
		name = entry[2],
		storageId = entry[3],
		missionId = 11265 + index,
		startValue = 0,
		endValue = 1,
		ignoreendvalue = true,
		description = function(player)
			local m = FamilyHive and FamilyHive.byKey[entry[1]]
			return m and FamilyHive.describeMission(player, m) or "Ask Orockle on Gray Beach for this mission."
		end,
	}
end

local quest = {
	name = "War Against the Hive",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = missions,
}

return quest
