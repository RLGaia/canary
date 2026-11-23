local quest = {
	name = "The Dream Courts",
	startStorageId = Storage.Quest.U12_00.TheDreamCourts.Main.Questline,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "The Dream Courts",
			storageId = Storage.Quest.U12_00.TheDreamCourts.WardStones.Questline,
			missionId = 10457,
			startValue = 1,
			endValue = 4, -- FAMILY: 3 = the beast is slain, 4 = reported to Vanys or Undal (texts of 3: ours)
			states = {
				[1] = function(player)
					return string.format("You already got %d/8 energized ward stones.", math.max(player:getStorageValue(Storage.Quest.U12_00.TheDreamCourts.WardStones.Count), 0))
				end,
				[2] = "You must kill the Nightmare Beast.",
				[3] = "You have slain the Nightmare Beast. Report to Vanys in the Summer Court or Undal in the Winter Court.",
				[4] = "By defeating the dreadful Nightmare Beast you did the Winter Court and the Summer Court alike a great favor. From now on, the dream elves will regard you as a friend.",
			},
		},
		[2] = {
			name = "Unsafe Release",
			storageId = Storage.Quest.U12_00.TheDreamCourts.UnsafeRelease.Questline,
			missionId = 10458,
			startValue = 1,
			endValue = 5,
			-- FAMILY: the steps of Andrew Lyze (texts of 1-4 ours; upstream had "Part I", "Part II")
			states = {
				[1] = "Andrew Lyze, the warden of the sealed cave south-west of Banuta, can repair a broken compass. Bring him the broken compass, 50 blue, 15 green and 5 violet glass plates from the carnivors in the cave.",
				[2] = "Andrew Lyze repaired the compass. Mine 5 blue, 3 green and 1 violet crystal with his golden axe and bring him a poison gland of a lucifuga aranea, then ask him to unleash the power of the crystals.",
				[3] = "Your compass is charged with violet energy. Use it on the magic portal next to Andrew Lyze's sarcophagus and open the chest behind it.",
				[4] = "The compass worked. Report back to Andrew Lyze.",
				[5] = "Andrew was happy to hear that the compass works as intended. From now on it is possible that he will charge your compass again. It can be used to give access to mystical chests once a day.",
			},
		},
		[3] = {
			name = "Haunted House",
			storageId = Storage.Quest.U12_00.TheDreamCourts.HauntedHouse.Questline,
			missionId = 10459,
			startValue = 1,
			endValue = 6,
			states = {
				[1] = function(player)
					return string.format(
						"A tormented soul trusted you with the secret of this house: join the passages to the three dungeons it connects to reveal a hidden portal within!\n\nCellar %d/1\nTemple %d/1\nTomb %d/1",
						math.max(player:getStorageValue(Storage.Quest.U12_00.TheDreamCourts.HauntedHouse.Cellar), 0),
						math.max(player:getStorageValue(Storage.Quest.U12_00.TheDreamCourts.HauntedHouse.Temple), 0),
						math.max(player:getStorageValue(Storage.Quest.U12_00.TheDreamCourts.HauntedHouse.Tomb), 0)
					)
				end,
				-- FAMILY: texts of 2-5 ours (upstream: "Part I - burried catedral", "Part II - puzzle dos livros"...)
				[2] = function(player)
					return string.format("The nexus is restored and the portal in the cellar leads to the buried cathedral. Find the four words of the spell guarding the place. Spell words found: %d/4", math.max(player:getStorageValue(Storage.Quest.U12_00.TheDreamCourts.BurriedCatedral.WordCount), 0))
				end,
				[3] = "The book on the altar tells of a spell whose four parts have to be chanted in the right order. Use the four big books of the hall in that order.",
				[4] = "The chants sent you to the Faceless Bane. Defeat it.",
				[5] = "The Faceless Bane is defeated. Use the ward stone of the buried cathedral.",
				[6] = "Activating the ward stone after defeating the Faceless Bane has gained you acess to the deepest mysteries of the dream courts.",
			},
		},
		[4] = {
			name = "The Seven Keys",
			storageId = Storage.Quest.U12_00.TheDreamCourts.TheSevenKeys.Questline,
			missionId = 10460,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = function(player)
					return string.format("You already got %d/7 secret keys.", math.max(player:getStorageValue(Storage.Quest.U12_00.TheDreamCourts.TheSevenKeys.Count), 0))
				end,
				[2] = "You found the seven keys to unlock the Seven Dream Doors in the Labyrinth of Summer's and Winter's Dreams.",
			},
		},
	},
}

return quest
