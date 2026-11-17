local quest = {
	name = "Cults of Tibia",
	startStorageId = Storage.Quest.U11_40.CultsOfTibia.Questline,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "The Strengthening of the Minotaurs",
			storageId = Storage.Quest.U11_40.CultsOfTibia.Minotaurs.JamesfrancisTask,
			missionId = 10372,
			startValue = 0,
			endValue = 50,
			description = function(player)
				return ("James asked you to enter the cave for hunting 50 empowered minotaurs. \z
				Then he will be able to continue his research.\nMinotaurs killed: %d/50"):format(player:getStorageValue(Storage.Quest.U11_40.CultsOfTibia.Minotaurs.JamesfrancisTask))
			end,
		},
		[2] = {
			name = "The Strengthening of the Minotaurs",
			storageId = Storage.Quest.U11_40.CultsOfTibia.Minotaurs.Mission,
			missionId = 10373,
			startValue = 1,
			endValue = 6,
			states = {
				[1] = "Gerimor told you that the naturalist Jamesfrancis is an expert of minotaurs. \z
				Right now he is investigating a cave in Mintwallin. But this time something seems to be completely different.",
				[2] = "Jamesfrancis already entered the inner part of the cave weeks ago but had to flee when \z
				the minotaurs became too strong. He gave you the key to investigate this room as well.",
				[3] = "You found an entrance to the minotaur boss. You killed it and now you have to return to Jamesfrancis.",
				[4] = "Jamesfrancis sent you to talk with Gerimor about the minotaur cult.",
				[5] = "You have reported the Druid of Crunor about the minotaur cult.",
				[6] = "You have reported the Druid of Crunor about the minotaur cult.",
			},
		},
		[3] = {
			name = "Patron of the Arts",
			storageId = Storage.Quest.U11_40.CultsOfTibia.MotA.Mission,
			missionId = 10374,
			startValue = 1,
			endValue = 15,
			states = {
				[1] = "The Druid of Crunor gave you the hint that the Thais exhibition has expanded. \z
				The new section is called MOTA (Museum of Tibian Arts). It's really worth a visit.",
				[2] = "Gareth told you how to become a patron of the arts. To fulfil your duty you have to manage some tasks. \z
				First you have to investigate the crime scene of a theft in the museum.",
				[3] = "You found a ransom note, which requests you to pay some money for \z
				the stolen picture to a stooge in Kazordoon. His name is Iwar. Nevertheless you should talk to Gareth first.",
				[4] = "You told Gareth about the ransom note. \z
				He asked you to pay the money to Iwar to get the picture back. In his opinion, there is no alternative.",
				[5] = "You paid the money to the stooge in Kazordoon. \z
				You were told that the picture is delivered to Gareth himself.",
				[6] = "You have to go to Angelo and get a magnifier to investigate all small \z
				pictures in the entrance hall of the MOTA. One of them should be a fake.",
				[7] = "Angelo allowed you to take a magnifier from a crate next to the cave entrance.",
				[8] = "You've fetched the magnifier from Angelo's crate. You're ready for your job in the museum.",
				[9] = "Indeed! One of the investigated small pictures is fake. Report to Gareth!",
				[10] = "After you told Gareth about the fake painting, he asked you to go to Angelo to get a new picture.",
				[11] = "Angelo was not willing to give you a new picture. \z
				However, they haven't found any artefact in the sandy cave yet. Report to Gareth about your failure.",
				[12] = "Even though you weren't successful in getting a replacement for the fake picture, \z
				Gareth gave you access to the last floor of the museum. This area is for patrons only.",
				[13] = "You pulled the lever on the last floor and got your own number. Go back to the Denominator and answer his questions about it.", -- FAMILY (2026-11-17): ours
				[14] = "The Denominator opened the door for you after you answered his questions to the wanted number. \z
				In the end he mentioned the Druid of Crunor. Maybe you should pay him a visit.",
				[15] = "In the end you told the Druid of Crunor about your experiences in the MoTA.",
			},
		},
		[4] = {
			name = "Barkless",
			storageId = Storage.Quest.U11_40.CultsOfTibia.Barkless.Mission,
			missionId = 10375,
			startValue = 1,
			endValue = 7,
			states = {
				[1] = "The members of the Barkless follow a rigid path of hardship and sacrifice. \z
				Their cult is located somewhere beneath Ab'dendriel. \z
				Whatever happened to their leader, only a true Barkless can find out.",
				[2] = "You survived the sulphur and tar trial. You accepted the stigma of misfortune and vanity. \z
				The hardest part, however, is yet to come. Give your life to the ice... to become true and purified.",
				[3] = function(player)
					return ("You survived the Trial. Barkless now have the right to see the cult leader but a \z
					powerful relic is sealing the path. Barkless markings broken to reverse the power of the cult object: \z %d of 10"):format(math.max(player:getStorageValue(Storage.Quest.U11_40.CultsOfTibia.Barkless.Objects), 0))
				end,
				[4] = "You broke enough Barkless markings to now reverse the seal \z
				held up by the cult object in the ritual chamber. \z
				The power you gained feels unnatural and excessive but it seems there is no other way.",
				[5] = 'Something far more powerful than the belief of your Barkless brothers \z
				and sisters powered the seal to the leader. Whatever the case - find Leiden, \z
				or as he\'s known to his devotees: the "Penitent".',
				[6] = "The Leiden you confronted has strayed far from his own original vision of Barkless. \z
				What you encountered was more monster than elf and less virtuous than his devotees would have you believe.",
				[7] = "You returned to Gerimor after putting an end to the mischief of Leiden the Penitent. \z
				May the Barkless walk the true path again one day.",
			},
		},
		[5] = {
			name = "Misguided",
			storageId = Storage.Quest.U11_40.CultsOfTibia.Misguided.Mission,
			missionId = 10376,
			startValue = 1,
			endValue = 5,
			states = {
				[1] = "Gerimor told you about people going missing near the outlaw camp east of Thais and about lights in an abandoned ruin south-west of it.", -- FAMILY (2026-11-17): ours
				[2] = "Below a ruin in the vicinity of the outlaw camp east of Thais a strange figure in ragged clothes \z
				hinted at something weird going on in a cave. He seemed too confused to decide whether to stop you.",
				[3] = function(player)
					return ("While rubbish, the amulet you equip emits a strange aura of splendour. \z
					You feel an urge to fulfil the amulet's hunger for specific deaths... Exorcisms: %d/5 "):format(math.max(player:getStorageValue(Storage.Quest.U11_40.CultsOfTibia.Misguided.Exorcisms), 0))
				end,
				[4] = "You defeated the cult leader of Misguided by uncovering the true master to pull his strings \z
				and freeing this world from its malicious existence. Return to Gerimor to tell him about the victory.",
				[5] = "You have spoken to Gerimor about your victory.",
			},
		},
		[6] = {
			name = "The Orc Idol",
			storageId = Storage.Quest.U11_40.CultsOfTibia.Orcs.Mission,
			missionId = 10377,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = "Several Edron orcs have taken to a dangerous idol. Find their cult in the orc cave of Edron and stop them before it is too late.", -- FAMILY (2026-11-17): ours
				[2] = "You faced the being the orcs worshipped and destroyed it. Return to Gerimor in Feyrist.", -- FAMILY (2026-11-17): ours
				[3] = "You returned to Gerimor after facing the being the orcs worshipped. \z
				Whatever it was, it did not find the orcs by accident. \z
				A far more powerful force seems to have strategically placed it here.",
			},
		},
		[7] = {
			name = "The Secret of the Sandy Cave",
			storageId = Storage.Quest.U11_40.CultsOfTibia.Life.Mission,
			missionId = 10378,
			startValue = 1,
			endValue = 10,
			states = {
				[1] = "Gerimor told you about a cult worshipping eternal life. Its entrance can be found in the dark pyramid of Darashia.", -- FAMILY (2026-11-17): ours
				[2] = "Angelo, the head of the Sandy Cave Project, asked you to look for his missing workers in the new cave below the dark pyramid.", -- FAMILY (2026-11-17): ours
				[3] = "In the cave you haven't found one of the missing scientists. \z
				However, you have faced a lot of strange mummies and a green oasis at the end.",
				[4] = "After you informed Angelo about your experiences in the cave, \z
				he asked you to go back to analyse the water of the oasis. For that reason you got an analysis tool.",
				[5] = "You have analysed the water with the help of the analysis tool from Angelo.",
				[6] = "You informed Angelo about the analyzed water. \z
				He gave you a counteragent, which you have to apply to the oasis.",
				[7] = "You applied the counteragent to the oasis, just like Angelo had asked you to. \z
				But the effect was different from what you had expected. \z
				A sandstorm approached and caused great damage to the oasis.",
				[8] = "You killed the Sandking, the creature behind the cult. Angelo might want to know.", -- FAMILY (2026-11-17): ours
				[9] = "Angelo was furious that you killed this creature. Tell Gerimor what you have found.", -- FAMILY (2026-11-17): ours
				[10] = "You have told Gerimor about your stay in the sandy cave. \z
				He was not really surprised and felt vindicated that the rumors about a cult in the cave might be true.",
			},
		},
		[8] = {
			name = "Zathroth Remnants",
			storageId = Storage.Quest.U11_40.CultsOfTibia.Humans.Mission,
			missionId = 10379,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = function(player)
					return ("A remnant cult of Zathroth has formed in a forbidden temple beneath Carlin. \z
				Find out what's behind this and stop it in time.\nTemporarily vaporised souls:\n%d Decaying\n%d Withering"):format(math.max(player:getStorageValue(Storage.Quest.U11_40.CultsOfTibia.Humans.Decaying), 0), math.max(player:getStorageValue(Storage.Quest.U11_40.CultsOfTibia.Humans.Vaporized), 0)) -- FAMILY (2026-11-17): the real storages (upstream read 18551/18550)
				end,
				[2] = "You defeated the Essence of Malice in the deepest part of the forbidden temple. Return to Gerimor in Feyrist.", -- FAMILY (2026-11-17): ours
				[3] = "You returned to Gerimor after encounter with the remnants of Zathroth. On one hand it is \z
				fortunate that Zathroth indeed wasn't behind all this, but on the other... what is going on there?",
			},
		},
		-- FAMILY (2026-11-17): the final mission had no quest log entry (texts ours)
		[9] = {
			name = "The Source of Corruption",
			storageId = Storage.Quest.U11_40.CultsOfTibia.FinalBoss.Mission,
			missionId = 11273,
			startValue = 1,
			endValue = 3,
			states = {
				[1] = "Gerimor's circle has aimed a teleporter at the source that strengthens the cults. Use it in the tree behind him, with a group twice as great as before, and destroy the source.",
				[2] = "You destroyed the Source of Corruption. Return to Gerimor for your reward.",
				[3] = "You destroyed the Source of Corruption and bought the world some valuable time. Gerimor thanked you on behalf of the world.",
			},
		},
	},
}

return quest
