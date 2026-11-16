local quest = {
	name = "The Ice Islands Quest",
	startStorageId = Storage.Quest.U8_0.TheIceIslands.Questline,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "Befriending the Musher",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission01,
			missionId = 10233,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = "Find Sniffler the husky of Iskan. He should be somewhere north west of the town. \z
					He is probably marking his territory so you should be able to find his trace. \z
					Call him sniffler and feed him with meat.",
				[2] = "Tell Iskan that you found and fed Sniffler.",
				[3] = "You are now a friend of Iskan and can ask him for a passage to Nibelor. \z
					You should ask Hjaern in Nibelor if you can help him.",
			},
		},
		[2] = {
			name = "Nibelor 1: Breaking the Ice",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission02,
			missionId = 10234,
			startValue = 1,
			endValue = 5,
			states = {
				[1] = "Chakoyas may use the ice for a passage to the west and attack Svargrond. Use a pick on at least three of the unstable places \z
					in the ice east of Nibelor and the chakoyas probably won't be able to pass the ice.",
				[2] = "You have broken 1 of 3 ice passages.",
				[3] = "You have broken 2 of 3 ice passages.",
				[4] = "You have broken 3 of 3 ice passages! Report to Hjaern about your mission.",
				[5] = "You should ask Silfind if you can help her in some matters.",
			},
		},
		[3] = {
			name = "Nibelor 2: Ecological Terrorism",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission03,
			missionId = 10235,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = "Siflind sent you to travel to a distant land to get ants from an Ant-Hill to \z
					perform ecological terrorism on some pirates on Tyrsung. Just use the jug on an anthill.",
				[2] = "Now head back to Svargrond and go to Buddel, the drunk sailor in southern Svargrond, \z
					and ask him to take you to Tyrsung. Now go all the way to the southern shores \z
					where you find an outpost. Go to the bottom deck and use the jug with the western mast",
				[3] = "Tell Siflind that you released the termites and ask her for another mission.",
			},
		},
		[4] = {
			name = "Nibelor 3: Artful Sabotage",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission04,
			missionId = 10236,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Siflind gave you a Vial of Paint to use on some Baby Seals. \z
					Go back to Tyrsung and follow the shore from Buddel south. Use the Vial of Paint on three of these seals.",
				[2] = "Tell Siflind that you painted the seals and ask her for another mission.",
			},
		},
		[5] = {
			name = "Nibelor 4: Berserk Brewery",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission05,
			missionId = 10237,
			startValue = 1,
			endValue = 6,
			states = {
				[1] = "The first things Siflind needs to brew a berserker elixir are 5 bat wings. Bring them to her!",
				[2] = "The next items Siflind needs are 4 bear paws. Bring them to her!",
				[3] = "The next items Siflind needs are 3 bonelord eyes. Bring them to her!",
				[4] = "The next items Siflind needs are 2 fish fins. Bring them to her!",
				[5] = "The last item Siflind needs is a green dragon scale. Bring it to her!",
				[6] = "You helped Siflind to defend Svargrond. Now Nilsor needs help, go and ask him for a mission.",
			},
		},
		[6] = {
			name = "Nibelor 5: Cure the Dogs",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission06,
			missionId = 10238,
			startValue = 1,
			endValue = 8,
			-- FAMILY: Nilsor takes the ingredients in any order (lib/others/family_ice_islands.lua);
			-- the state is 1 + the number he has (2026-11-16)
			states = {
				[1] = "Nilsor needs 7 ingredients to cure his dogs: a part of the sun adorer cactus, a vial of geyser water, \z
					fine sulphur of an inactive lava hole, a frostbite herb, a blossom of a purple kiss, a hydra tongue and \z
					spores of a giant glimmercap mushroom. Bring them in any order and talk to him about each one.",
				[2] = "You brought Nilsor 1 of the 7 ingredients for the medicine. Ask him about his mission to hear what is still missing.",
				[3] = "You brought Nilsor 2 of the 7 ingredients for the medicine. Ask him about his mission to hear what is still missing.",
				[4] = "You brought Nilsor 3 of the 7 ingredients for the medicine. Ask him about his mission to hear what is still missing.",
				[5] = "You brought Nilsor 4 of the 7 ingredients for the medicine. Ask him about his mission to hear what is still missing.",
				[6] = "You brought Nilsor 5 of the 7 ingredients for the medicine. Ask him about his mission to hear what is still missing.",
				[7] = "You brought Nilsor 6 of the 7 ingredients for the medicine. Ask him about his mission to hear what is still missing.",
				[8] = "You brought Nilsor all ingredients to cure his dogs. Talk to him about the medicine. \z
					You can now travel by dog sled to Inukaya.",
			},
		},
		[7] = {
			name = "The Secret of Helheim",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission07,
			missionId = 10239,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = "Hjaern might have a mission for you. So maybe you go and talk to him.",
				[2] = "Hjaern sent you to find someone in Svargrond who can give you a passage to Helheim and seek the reason for the unrest there.",
				[3] = "You discovered the necromantic altar and should report Hjaern about it.",
			},
		},
		[8] = {
			name = "The Contact",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission08,
			missionId = 10240,
			startValue = 1,
			endValue = 4,
			states = {
				[1] = "Get out of Nibelor and go to the Svargrond Explorer's Society. Ask Lurik for the mission.",
				[2] = "Get to the raider camp, then follow to the extreme south where you find lots of barbarians. \z
				Near the southern most coastline, try looking for the NPC Nor. Ask him about Memory Crystal.",
				[3] = "Go back to Lurik and deliver him the memory crystal.",
				[4] = "Give Lurik some time to evaluate the information (ca. 5min). \z
				Then talk to him again about your mission.",
			},
		},
		[9] = {
			name = "Formorgar Mines 1: The Mission",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission09,
			missionId = 10241,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Find the entrance of the Formorgar Mines. \z
				Find some hint or someone who is willing to talk about what is going on there.",
				[2] = "You found an old and tattered written paper in a skeleton next to a Restless Soul, \z
				you can only make out a signature: Tylaf, apprentice of Hjaern. Ask Hjaern about Tylaf.",
			},
		},
		[10] = {
			name = "Formorgar Mines 2: Ghostwhisperer",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission10,
			missionId = 10242,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Go back to the mine and ask the restless soul about his story.",
				[2] = "You have already listened to his story!",
			},
		},
		[11] = {
			name = "Formorgar Mines 3: The Secret",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission11,
			missionId = 10243,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "The cultists' plan is to create a new demon army for their master to conquer the world. \z
				Hjaern and the other shamans must learn about it! Hurry before its too late.",
				[2] = "The cultists' plan is to create a new demon army for their master to conquer the world. \z
				Hjaern and the other shamans are already informed!",
			},
		},
		[12] = {
			name = "Formorgar Mines 4: Retaliation",
			storageId = Storage.Quest.U8_0.TheIceIslands.Mission12,
			missionId = 10244,
			startValue = 1,
			endValue = 6,
			states = {
				[1] = "Hjaern gave you a spirit charm of cold. Travel to the mines and find four \z
				special obelisks to mark them with the charm.",
				[2] = "1 of 4 obelisks are marked.",
				[3] = "2 of 4 obelisks are marked.",
				[4] = "3 of 4 obelisks are marked.",
				[5] = "Once all 4 obelisks are marked report back to Hjaern.",
				[6] = "You got the Norseman outfit and you have access to the Yakchal room deep in the Formorgar Mines.",
			},
		},
		[13] = {
			name = "Barbarian Test 1: Barbarian Booze",
			storageId = Storage.Quest.U8_0.BarbarianTest.Mission01,
			missionId = 1055,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = "You participate in the drinking challenge. Now you can get the permission for a few sips of barbarian mead in exchange for some honey.",
				[2] = "Now drink from the bucket until you drink 10 sips in a row without passing out",
				[3] = "You have mastered the first task of the barbarian test. If you haven't done so yet, talk to Sven about it.",
			},
		},
		[14] = {
			name = "Barbarian Test 2: The Bear Hugging",
			storageId = Storage.Quest.U8_0.BarbarianTest.Mission02,
			missionId = 1056,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Somewhere north of Svargrond you will find a lonely bear which you have to hug. You wonder what you were thinking when accepting this quest...",
				[2] = "You passed the bear hugging test (and should take a bath). If you haven't done so yet, talk to Sven about it.",
			},
		},
		[15] = {
			name = "Barbarian Test 3: The Mammoth Pushing",
			storageId = Storage.Quest.U8_0.BarbarianTest.Mission03,
			missionId = 1057,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Find a mammoth north-west of Svargrond and knock it over. You wonder whether your mission is becoming a barbarian or rather commiting suicide.",
				[2] = "You have knocked over a mammoth - though you wonder what this crushing noise at your spine was. If you haven't done so yet, talk to Sven about the mammoth pushing.",
			},
		},
		[16] = {
			name = "The Honorary Barbarian",
			storageId = Storage.Quest.U8_0.BarbarianTest.Questline,
			missionId = 10099,
			startValue = 8,
			endValue = 8,
			states = {
				[8] = "You are now a honorary barbarian and can become a citizen of Svargrond. If you haven't done so yet, you should look for a barbarian in need of help in the north of the town.",
			},
		},
	},
}

return quest
