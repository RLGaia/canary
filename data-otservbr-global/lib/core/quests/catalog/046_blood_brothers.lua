-- FAMILY (2026-11-02): missions 5-10 added (lib/others/family_blood_brothers.lua), the empty
-- steps filled, Mission 04 now ends when Julius gets the map (upstream: done as soon as it
-- started), typo "vamires". Texts of the new steps and the filled ones are ours (the Tibia quest
-- log texts are not on either wiki); the rest is upstream.
local FBB = Storage.Quest.FamilyBloodBrothers

local quest = {
	name = "Blood Brothers",
	startStorageId = Storage.Quest.U8_4.BloodBrothers.QuestLine,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "Mission 01: Gaining Trust",
			storageId = Storage.Quest.U8_4.BloodBrothers.Mission01,
			missionId = 10433,
			startValue = 1,
			endValue = 4,
			states = {
				[1] = "Think of a way to earn Julius' trust and prove that you are not a vampire. Once you thought of something, talk to him again about your mission.",
				[2] = "The garlic necklace is not enough for Julius. He asked you whether you have ever baked garlic bread.",
				[3] = "Mix flour with holy water, use that dough on garlic and bake it in an oven. Then talk to Julius about your mission again and eat the garlic bread in front of him.",
				[4] = "You have Julius' trust.",
			},
		},
		[2] = {
			name = "Mission 02: Bad Eggs",
			storageId = Storage.Quest.U8_4.BloodBrothers.Mission02,
			missionId = 10434,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Bake garlic cookies by using the garlic dough on a baking tray before you put it on the oven. Hand out cookies to the citizens and watch their reactions. Report any suspicious people to Julius.",
				[2] = "You have reported five suspects - probably vampires - to Julius.",
			},
		},
		[3] = {
			name = "Mission 03: His True Face",
			storageId = Storage.Quest.U8_4.BloodBrothers.Mission03,
			missionId = 10435,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = "Use the magic words 'alori mort' in front of the suspicious citizens you discovered to hopefully reveal who among them is their leader.",
				[2] = "Armenius only laughed at the magic words. Tell Julius who the master vampire is.",
				[3] = "You reported the incident with Armenius to Julius.",
			},
		},
		[4] = {
			name = "Mission 04: The Dark Lands",
			storageId = Storage.Quest.U8_4.BloodBrothers.Mission04,
			missionId = 10436,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = function(player)
					local n = FamilyBloodBrothers and FamilyBloodBrothers.markCount(player) or 0
					return "Your task is to find someone to bring you to Vengoth. Explore the island and use Julius' map whenever you find an unusual spot to mark it. Mark at least 5 spots including the castle and report back. Spots marked: " .. n .. "/8"
				end,
				[2] = "You brought Julius a map of Vengoth with the castle and other remarkable places marked.",
			},
		},
		[5] = {
			name = "Mission 05: Into the Castle",
			storageId = FBB.Mission05,
			missionId = 11232,
			startValue = 1,
			endValue = 5,
			states = {
				[1] = "Julius needs a blood crystal, a rare stone that can store magic energy. Ask around in Yalahar where you could find one.",
				[2] = "Charge the blood crystal. Julius thinks that someone who lost something or someone dear to him or her emits enough energy for it.",
				[3] = "Stand on the spots with strange symbols around Vengoth castle holding a charged blood crystal, at the same time as someone else with a charged crystal, to get attuned to the castle's dark energy.",
				[4] = "You have been inside the castle. Tell Julius about it.",
				[5] = "You found a way into the castle of Vengoth.",
			},
		},
		[6] = {
			name = "Mission 06: A Black History",
			storageId = FBB.Mission06,
			missionId = 11233,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Find documents or books inside the castle that tell more about its master and how the place got so cursed. Old castles sometimes have hidden passages.",
				[2] = function(player)
					local n = FamilyBloodBrothers and FamilyBloodBrothers.deliveredPages(player) or 0
					return "You brought Julius Marziel's torn diary. The brothers Boreth, Lersatio, Marziel and Arthei have something to do with the castle. Julius would like to have its missing pages too. Pages brought to him: " .. n .. "/6"
				end,
			},
		},
		[7] = {
			name = "Mission 07: Boreth",
			storageId = FBB.Mission07,
			missionId = 11234,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Find another open door in the castle and the first of the brothers. Bring Julius proof of his death.",
				[2] = "You brought Julius the dust of Boreth.",
			},
		},
		[8] = {
			name = "Mission 08: Lersatio",
			storageId = FBB.Mission08,
			missionId = 11235,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Find the second brother in another tower of the castle and awaken him. Bring Julius proof of his death.",
				[2] = "You brought Julius the dust of Lersatio.",
			},
		},
		[9] = {
			name = "Mission 09: Marziel",
			storageId = FBB.Mission09,
			missionId = 11236,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Slip into another tower of the castle and climb up to the room of the third brother, Marziel. Bring Julius proof of his death.",
				[2] = "You brought Julius the dust of Marziel.",
			},
		},
		[10] = {
			name = "Mission 10: Arthei",
			storageId = FBB.Mission10,
			missionId = 11237,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Face Arthei, the master of the brothers, and break his evil power. Bring Julius his ashes as proof.",
				[2] = "You defeated all four brothers. Julius gave you a special crest.",
			},
		},
	},
}

return quest
