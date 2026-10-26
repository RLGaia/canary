local quest = {
	name = "Adventurers Guild",
	startStorageId = Storage.Quest.U9_80.AdventurersGuild.QuestLine,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "The Great Dragon Hunt",
			storageId = Storage.Quest.U10_80.TheGreatDragonHunt.WarriorSkeleton,
			missionId = 10388,
			startValue = 0,
			endValue = 2,
			description = function(player)
				return ("You are exploring the Kha'zeel Dragon Lairs. Others obviously found a terrible end here. \z
				But the dragon hoards might justify the risks. You killed %d/50 dragons and dragon lords."):format(math.max(player:getStorageValue(Storage.Quest.U10_80.TheGreatDragonHunt.DragonCounter), 0))
			end,
		},
		[2] = {
			name = "The Lost Brother",
			storageId = Storage.Quest.U10_80.TheLostBrotherQuest,
			missionId = 11000,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = "At the Kha'zeel Mountains you met the merchant Tarun. His brother has gone missing and was last seen following a beautiful woman into a palace. Tarun fears this woman might have been a demon.",
				[2] = "You found the remains of Tarun's brother containing a message. Go back to Tarun and report his brother's last words.",
				[3] = "You told Tarun about his brother's sad fate. He was very downhearted but gave you his sincere thanks. The beautiful asuri have taken a young man's life and the happiness of another one.",
			},
		},
		-- FAMILY: Cartography 101 (ours, 2026-10-26; scripts/family/cartography_101.lua)
		[3] = {
			name = "Cartography 101",
			storageId = Storage.Quest.FamilyCartography.Mission,
			missionId = 11226,
			startValue = 1,
			endValue = 2,
			description = function(player)
				if FamilyCartography then
					return FamilyCartography.describe(player)
				end
				return "The Adventurers' Guild need some help cartographing the Tibian lands."
			end,
		},
	},
}

return quest
