local internalNpcName = "Hjaern"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 154,
	lookHead = 0,
	lookBody = 94,
	lookLegs = 95,
	lookFeet = 114,
	lookAddons = 3,
}

npcConfig.flags = {
	floorchange = false,
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onMove = function(npc, creature, fromPosition, toPosition)
	npcHandler:onMove(npc, creature, fromPosition, toPosition)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "mission") then
		if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 3 then
			if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission02) < 1 then
				npcHandler:say({
					"We could indeed need some help. These are very cold times. The ice is growing and becoming thicker everywhere ...",
					"The problem is that the chakoyas may use the ice for a passage to the west and attack Svargrond ...",
					"We need you to get a pick and to destroy the ice at certain places to the east. You will quickly recognise those spots by their unstable look ...",
					"Use the pickaxe on at least three of these places and the chakoyas probably won't be able to pass the ice. Once you are done, return here and report about your mission.",
				}, npc, creature)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission02, 1) -- Questlog The Ice Islands Quest, Nibelor 1: Breaking the Ice
				npcHandler:setTopic(playerId, 0)
			elseif Family and Family.iceIslandsFixes then
				-- FAMILY: upstream said nothing while the mission ran (ours, from his EN lines)
				npcHandler:say("Use a pick on at least three of the unstable places in the ice to the east. Once you are done, return here and report about your mission.", npc, creature)
				npcHandler:setTopic(playerId, 0)
			end
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 4 then
			npcHandler:say("The spirits are at peace now. The threat of the chakoyas is averted for now. I thank you for your help. Perhaps you should ask Silfind if you can help her in some matters. ", npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 5)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission02, 5) -- Questlog The Ice Islands Quest, Nibelor 1: Breaking the Ice
			npcHandler:setTopic(playerId, 0)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 29 then
			npcHandler:say({
				"There is indeed an important mission. For a long time, the spirits have been worried and have called us for help. It seems that some of our dead have not reached the happy hunting grounds of after life ...",
				"Everything we were able to find out leads to a place where none of our people is allowed to go. Just like we would never allow a stranger to go to that place ...",
				"But you, you are different. You are not one of our people, yet you have proven worthy to be one us. You are special, the child of two worlds ...",
				"We will grant you permission to travel to that isle of Helheim. Our legends say that this is the entrance to the dark world. The dark world is the place where the evil and lost souls roam in eternal torment ...",
				"There you find for sure the cause for the unrest of the spirits. Find someone in Svargrond who can give you a passage to Helheim and seek for the cause. Are you willing to do that?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 1)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 31 then
			npcHandler:say({
				"There is no need to report about your mission. To be honest, Ive sent a divination spirit with you as well as a couple of destruction spirits that were unleashed when you approached the altar ...",
				"Forgive me my secrecy but you are not familiar with the spirits and you might have get frightened. The spirits are at work now, destroying the magic with that those evil creatures have polluted Helheim ...",
				"I cant thank you enough for what you have done for the spirits of my people. Still I have to ask: Would you do us another favour?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 2)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 38 then
			npcHandler:say({
				"These are alarming news and we have to act immediately. Take this spirit charm of cold. Travel to the mines and find four special obelisks to mark them with the charm ...",
				"I can feel their resonance in the spirits world but we cant reach them with our magic yet. They have to get into contact with us in a spiritual way first ...",
				"This will help us to concentrate all our frost magic on this place. I am sure this will prevent to melt any significant number of demons from the ice ...",
				"Report about your mission when you are done. Then we can begin with the great ritual of summoning the children of Chyll ...",
				"I will also inform Lurik about the events. Now go, fast!",
			}, npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 39)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission11, 2) -- Questlog The Ice Islands Quest, Formorgar Mines 3: The Secret
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission12, 1) -- Questlog The Ice Islands Quest, Formorgar Mines 4: Retaliation
			player:addItem(7289, 1)
			npcHandler:setTopic(playerId, 0)
		elseif Family and Family.iceIslandsFixes and FamilyIceIslands.hjaernReminder(npc, creature, npcHandler) then
			-- FAMILY: answers while a mission runs, a new frost charm if it was lost (2026-11-16)
			npcHandler:setTopic(playerId, 0)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 39 and player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Obelisk01) == 5 and player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Obelisk02) == 5 and player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Obelisk03) == 5 and player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Obelisk04) == 5 then
			-- FAMILY: a lost frost charm no longer blocks the report (upstream required it and gave no new one)
			if player:removeItem(7289, 1) or (Family and Family.iceIslandsFixes) then
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 40)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.yakchalDoor, 1)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission12, 6) -- Questlog The Ice Islands Quest, Formorgar Mines 4: Retaliation
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.NorsemanOutfit, 1) -- Questlog Norseman Outfit Quest
				player:setStorageValue(Storage.OutfitQuest.DefaultStart, 1) --this for default start of Outfit and Addon Quests
				player:addOutfit(251, 0)
				player:addOutfit(252, 0)
				player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
				npcHandler:say({
					"Yes, I can feel it! The spirits are in touch with the obelisks. We will begin to channel a spell of ice on the caves. That will prevent the melting of the ice there ...",
					"If you would like to help us, you can turn in frostheart shards from now on. We use them to fuel our spell with the power of ice. ...",
					"Oh, and before I forget it - since you have done a lot to help us and spent such a long time in this everlasting winter, I have a special present for you. ...",
					"Take this outfit to keep your warm during your travels in this frozen realm!",
				}, npc, creature)
			end
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say("I have now no mission for you.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif Family and Family.iceIslandsFixes and (MsgContains(message, "shard") or MsgContains(message, "shards") or MsgContains(message, "frostheart")) then
		-- FAMILY: Norseman addons as in TibiaWiki BR and EN: the addon comes with the shards, no extra
		-- "reward" step; Out in the Snowstorm with the second one (lib/others/family_ice_islands.lua)
		FamilyIceIslands.hjaernShards(npc, creature, npcHandler)
	elseif MsgContains(message, "shard") then
		if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 40 then
			npcHandler:say("Do you bring frostheart shards for our spell?", npc, creature)
			npcHandler:setTopic(playerId, 3)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 42 then
			npcHandler:say("Do you bring frostheart shards for our spell? ", npc, creature)
			npcHandler:setTopic(playerId, 4)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 44 then
			npcHandler:say("Do you want to sell all your shards for 2000 gold coins per each? ", npc, creature)
			npcHandler:setTopic(playerId, 5)
		end
	elseif MsgContains(message, "reward") then
		if Family and Family.iceIslandsFixes and FamilyIceIslands.hjaernReward(npc, creature, npcHandler) then
			-- FAMILY: see the shards above
			return true
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 41 then
			npcHandler:say("Take this. It might suit your Nordic outfit fine. ", npc, creature)
			player:addOutfitAddon(252, 1)
			player:addOutfitAddon(251, 1)
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 42)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.NorsemanOutfit, 2) -- Questlog Norseman Outfit Quest
			npcHandler:setTopic(playerId, 3)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 43 then
			player:addOutfitAddon(252, 2)
			player:addOutfitAddon(251, 2)
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			npcHandler:say("Take this. It might suit your Nordic outfit fine. From now on we only can give you 2000 gold pieces for each shard. ", npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 44)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.NorsemanOutfit, 3) -- Questlog Norseman Outfit Quest
			npcHandler:setTopic(playerId, 4)
		end
	elseif MsgContains(message, "tylaf") then
		if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 36 then
			npcHandler:say({
				"You encountered the restless ghost of my apprentice Tylaf in the old mines? We must find out what has happened to him. I enable you to talk to his spirit ...",
				"Talk to him and then report to me about your mission.",
			}, npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 37)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission10, 1) -- Questlog The Ice Islands Quest, Formorgar Mines 2: Ghostwhisperer
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "cookie") then
		if player:getStorageValue(Storage.Quest.U8_1.WhatAFoolishQuest.Questline) == 31 and player:getStorageValue(Storage.Quest.U8_1.WhatAFoolishQuest.CookieDelivery.Hjaern) ~= 1 then
			npcHandler:say("You want to sacrifice a cookie to the spirits?", npc, creature)
			npcHandler:setTopic(playerId, 6)
		end
	elseif MsgContains(message, "yes") then
		if Family and Family.iceIslandsFixes and FamilyIceIslands.hjaernShardsYes(npc, creature, npcHandler) then
			-- FAMILY: see the shards above
			return true
		elseif npcHandler:getTopic(playerId) == 1 then
			npcHandler:say("This is good news. As I explained, travel to Helheim, seek the reason for the unrest there and then report to me about your mission. ", npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 30)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission07, 2) -- Questlog The Ice Islands Quest, The Secret of Helheim
			npcHandler:setTopic(playerId, 0)
		elseif npcHandler:getTopic(playerId) == 2 then
			npcHandler:say({
				"Thank you my friend. The local representative of the explorers society has asked for our help ...",
				"You know their ways better than my people do and are probably best suited to represent us in this matter.",
				"Search for Lurik and talk to him about aprobable mission he might have for you.",
			}, npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 32)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission08, 1) -- Questlog The Ice Islands Quest, The Contact
			npcHandler:setTopic(playerId, 0)
		elseif npcHandler:getTopic(playerId) == 3 then
			if player:removeItem(7290, 5) then
				npcHandler:say("Excellent, you collected 5 of them. If you have collected 5 or more, talk to me about your {reward}. ", npc, creature)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 41)
				npcHandler:setTopic(playerId, 0)
			end
		elseif npcHandler:getTopic(playerId) == 4 then
			if player:removeItem(7290, 10) then
				npcHandler:say("Excellent, you collected 10 of them. If you have collected 15 or more, talk to me about your {reward}. ", npc, creature)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 43)
				npcHandler:setTopic(playerId, 0)
			end
		elseif npcHandler:getTopic(playerId) == 5 then
			if player:getItemCount(7290) > 0 then
				local count = player:getItemCount(7290)
				player:addMoney(count * 2000)
				player:removeItem(7290, count)
				npcHandler:say("Here your are. " .. count * 2000 .. " gold coins for " .. count .. " shards.", npc, creature)
				npcHandler:setTopic(playerId, 0)
			end
		elseif npcHandler:getTopic(playerId) == 6 then
			if not player:removeItem(130, 1) then
				npcHandler:say("You have no cookie that I'd like.", npc, creature)
				npcHandler:setTopic(playerId, 0)
				return true
			end

			player:setStorageValue(Storage.Quest.U8_1.WhatAFoolishQuest.CookieDelivery.Hjaern, 1)
			if player:getCookiesDelivered() == 10 then
				player:addAchievement("Allow Cookies?")
			end

			npc:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
			npcHandler:say("In the name of the spirits I accept this offer ... UHNGH ... The spirits are not amused!", npc, creature)
			npcHandler:removeInteraction(npc, creature)
			npcHandler:resetNpc(creature)
		end
	elseif MsgContains(message, "no") then
		if npcHandler:getTopic(playerId) == 6 then
			npcHandler:say("I see.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Be greeted, |PLAYERNAME|. The {spiritual} world looks upon you and your deeds.")

-- FAMILY: his words from the TibiaWiki EN transcript (2026-11-16; lib/others/family_ice_islands.lua).
-- Quest words (mission, shard, frostheart, reward, tylaf) stay in the callback above.
if Family and Family.iceIslandsAnswers then
	npcHandler:setMessage(MESSAGE_FAREWELL, "Good bye, |PLAYERNAME|.")
	local function line(words, text)
		keywordHandler:addKeyword(words, StdModule.say, { npcHandler = npcHandler, text = text })
	end
	line({ "spiritual" }, "I would not consider this as a job. But one of my responsibilities is the training of young shamans. Even druids can learn a few new tricks from me.")
	line({ "job" }, "I would not consider this as a job. But one of my responsibilities is the training of young shamans. Even druids can learn a few new tricks from me.")
	line({ "name" }, "The spirits call me by the name of Hjaern and that is how I shall be known.")
	line({ "shamans" }, "We try to figure out the will of the spirits and ways to appease them.")
	line({ "jarl" }, "Sven the younger is a good spokesperson for his people. He knows what to do in a case of urgency and this is what counts. This earns him the respect that is necessary to succeed as a leader.")
	line({ "leader" }, "Sven the younger is a good spokesperson for his people. He knows what to do in a case of urgency and this is what counts. This earns him the respect that is necessary to succeed as a leader.")
	line({ "king" }, "There should be no such thing like a human that is ruling over the lives of other humans.")
	line({ "queen" }, "There should be no such thing like a human that is ruling over the lives of other humans.")
	for _, city in ipairs({ "thais", "carlin", "venore" }) do
		line({ city }, "The far away cities of men, as famous as they might be, are nothing than distant echoes over here.")
	end
	line({ "edron" }, "The spirits don't talk about such far away places.")
	line({ "port hope" }, "The spirits don't talk about such far away places.")
	line({ "svargrond" }, "The city was a necessity. Just like the spirit needs a haven of safety and retreat, so does the body need it.")
	line({ "monsters" }, "Even the so-called monsters have their place in the world.")
	line({ "news" }, "The news I receive are from the spiritual world. They would be of little importance for you.")
	line({ "rumours" }, {
		"Months ago, many strange looking people passed Svargrond. The inhabitants tell stories about a cult they belong to. ...",
		"It is rumoured that they are trying to awake unholy spirits in the mountains. Maybe other people know more about that cult.",
	})
	for _, god in ipairs({ "gods", "uman", "zathroth", "banor" }) do
		line({ god }, "Your foreign gods are concepts we don't really understand.")
	end
	line({ "how are you" }, "My spirit and my body are in harmony with the environment.")
	line({ "druids" }, "Druids have much in common with us. We shared much knowledge with each other and both sides did prosper.")
	line({ "ferumbras" }, "He is of no importance here.")
	line({ "excalibug" }, "That's something I only heard about in curious questions of people like you.")
	line({ "enemies" }, "The true enemies are those that you can't see. There are more things in this world than you have ever dreamt of.")
	line({ "barbarians" }, {
		"The word barbarian is hard to translate into your language and I am aware it's used in your language with a different meaning. ...",
		"It could be roughly translated into 'those who truly are alive' but that does not represent all it stands for. ...",
		"To truly understand the meaning, you will have to look around and learn on your own.",
	})
	line({ "elf" }, "Elves are hardly known here.")
	line({ "dwarf" }, "The little people are a rare sight on Nibelor.")
	line({ "bonelord" }, "I don't know about such creatures.")
	line({ "yeti" }, "The yetis are real. They are elusive but dangerous. Some say they are rather residents of the spirits' world than ours. The spirits are silent about them which is an even greater enigma.")
	line({ "chakoya" }, "The chakoyas are like a force of nature. It would be wrong to try to exterminate them. On the other hand, we can't allow their carnivorous nature to threaten our lives.")
	line({ "cult" }, {
		"We had no contact with the people that passed Svargrond. Their arrival has caused some disturbance in the spirits' world though. ...",
		"Ancient spirits are restless. It seems that some things that should have been left alone, have awoken from their slumber. I can't tell more yet.",
	})
	line({ "mines" }, "The obsession of the foreigners with those mines is not understandable. Why bind onself to such elusive things like material possessions?")
	line({ "nibelor" }, {
		"At this place the spirits are strong, their voices are loud, and the border between the worlds is thin. Here we divine the will of the spirits and communicate with them. ...",
		"Our live is a constant learning from the spirits around us and this is the place where we come to learn more.",
	})
	line({ "camps" }, "The raiders have at least three camps to the south but raiding parties can be encountered almost everywhere.")
	line({ "raiders" }, "They were mislead by a traitorous shaman who lost herself to the dark side of the world of spirits.")
	line({ "join" }, "To become one of us is a long way. To reach an honour rank in our society, talk to Sven the Younger about the barbarian test.")
	line({ "chyll" }, {
		"Father north wind is the supreme ruler of the North. His ways are almost unpredictable to us humans since his thoughts span ages. ...",
		"We can only do our best to interpret his will correctly and act accordingly. One has to move with the wind after all, else it will destroy you. This is the way things are here in the North and the way of our people.",
	})
end
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
