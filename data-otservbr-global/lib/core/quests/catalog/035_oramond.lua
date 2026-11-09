local quest = {
	name = "Oramond",
	startStorageId = Storage.Quest.U10_50.OramondQuest.QuestLine,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "To Take Roots",
			storageId = Storage.Quest.U10_50.OramondQuest.ToTakeRoots.Mission,
			missionId = 10360,
			startValue = 1,
			endValue = 3000,
			description = "Five Juicy roots from the outskirts of Rathleton may already help feed the poor. \z
			Try to find a city official to deliver them to or go to the Rathleton poor house.",
		},
		-- FAMILY: Oramond Quest kill and delivery tasks (lib/others/family_oramond_tasks.lua); texts ours
	},
}

-- (static list: this catalog loads before lib/others, so FamilyOramondTasks is read only when
-- a description is shown)
local familyTasks = {
	{ "Taking the Rot Out", "Rot" },
	{ "The Name of the Beast", "Beast" },
	{ "The Minor Taurs", "Minor" },
	{ "Rust in Peace", "Gargoyles" },
	{ "The Major Taurs", "Major" },
	{ "Nature's Balance", "Bandits" },
}
for i, entry in ipairs(familyTasks) do
	local name, key = entry[1], entry[2]
	quest.missions[#quest.missions + 1] = {
		name = name,
		storageId = Storage.Quest.FamilyOramondTasks[key],
		missionId = 11238 + i, -- 11239-11244
		startValue = 0,
		endValue = 1000000,
		description = function(player)
			local T = FamilyOramondTasks
			if not T then
				return name
			end
			for _, task in ipairs(T.hunts) do
				if task.name == name then
					return T.missionText(player, task)
				end
			end
			return T.missionText(player, T.bandits)
		end,
	}
end
quest.missions[#quest.missions + 1] = {
	name = "The Glooth Bandits",
	storageId = Storage.Quest.FamilyOramondTasks.Capsules,
	missionId = 11245,
	startValue = 1,
	endValue = 3,
	description = function(player)
		if player:getStorageValue(Storage.Quest.FamilyOramondTasks.Capsules) >= 2 then
			return "Elbert in the Underground Glooth Factory takes every ten glooth capsules you find for two voices in the magistrate."
		end
		return "Bring ten glooth capsules, stolen by the glooth bandits and brigands, back to Elbert in the Underground Glooth Factory."
	end,
}
-- FAMILY: batch 2 (2026-11-08): Sabotage, Rathleton Turnip Party, Communication Breakdown,
-- Combinatorics, Dr Merlay's Misery (texts ours)
local familyBatch2 = {
	{ "Sabotage", "Sabotage", 0 },
	{ "Rathleton Turnip Party", "Turnips", 0 },
	{ "Communication Breakdown", "Communication", 1 },
	{ "Combinatorics", "Combinatorics", 1 },
	{ "Dr Merlay's Misery", "Merlay", 0 },
}
for i, entry in ipairs(familyBatch2) do
	local name, key, start = entry[1], entry[2], entry[3]
	quest.missions[#quest.missions + 1] = {
		name = name,
		storageId = Storage.Quest.FamilyOramondTasks[key],
		missionId = 11245 + i, -- 11246-11250
		startValue = start,
		endValue = 1000000,
		description = function(player)
			if FamilyOramondTasks and FamilyOramondTasks.missionTextBatch2 then
				return FamilyOramondTasks.missionTextBatch2(player, key)
			end
			return name
		end,
	}
end

return quest
