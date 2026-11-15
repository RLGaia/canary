-- FAMILY: The Scatterbrained Sorcerer Quest (ours, 2026-11-15): upstream has no quest log entry.
-- Texts are ours (TibiaWiki has none): lib/others/family_sorcerer.lua (FamilySorcerer.describeTasks and
-- describeMission). Mission ids 11258-11264.
local S = Storage.Quest.U8_5.TheScatterbrainedSorcerer

local function tasks(player)
	if FamilySorcerer then
		return FamilySorcerer.describeTasks(player)
	end
	return "Eclesius south of Thais has some tasks for you."
end

local function step(name, missionId, startValue, endValue)
	local function description(player)
		if FamilySorcerer then
			return FamilySorcerer.describeMission(player, endValue)
		end
		return "Ask Eclesius about a mission."
	end
	return { name = name, storageId = S.Mission, missionId = missionId, startValue = startValue, endValue = endValue, ignoreendvalue = true, description = description }
end

return {
	name = "The Scatterbrained Sorcerer",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = {
		{ name = "Eclesius' Tasks", storageId = S.Questline, missionId = 11258, startValue = 1, endValue = 2, ignoreendvalue = true, description = tasks },
		step("Mission 1: A Hat for the Sane", 11259, 1, 2),
		step("Mission 2: Walking on Clouds", 11260, 3, 11),
		step("Mission 3: Love's a Wicked Game", 11261, 12, 21),
		step("Mission 4: Books of Many Colours", 11262, 22, 23),
		step("Mission 5: A Drink to Remember", 11263, 24, 28),
		step("Mission 6: The Unhappy Frog", 11264, 29, 41),
	},
}
