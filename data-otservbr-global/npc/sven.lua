local internalNpcName = "Sven"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 143,
	lookHead = 76,
	lookBody = 57,
	lookLegs = 115,
	lookFeet = 40,
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

local function greetCallback(npc, player)
	if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.HuskyKillStatus) == 1 then
		npcHandler:setMessage(MESSAGE_GREET, "Iskan told me that you killed huskies here in Svargrond. I will be lenient towards you and won't ban you from Svargrond. But you have to pay me a compensation of 1500 gold for each husky you have killed. Are you willing to pay " .. player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.HuskyKill) * 1500 .. "?")
	else
		npcHandler:setMessage(MESSAGE_GREET, "Be greeted, |PLAYERNAME|! What brings you {here}?")
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	local questline = player:getStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline)
	local totalSips = player:getStorageValue(Storage.Quest.U8_0.BarbarianTest.MeadTotalSips)
	-- A honeycomb may only buy a new round when none is active: before the first
	-- round (questline 1) or once the 20 sips of the current one are used up.
	local canStartMeadRound = questline == 1 or (questline == 2 and totalSips >= 20)

	-- FAMILY: "barbarians" and "bear hugging"/"bearhugging" (the words of the EN transcripts) also work, and
	-- "barbarian" answers everyone as in EN (2026-11-16)
	local fixes = Family and Family.iceIslandsFixes
	if fixes and (MsgContains(message, "bearhugging") or MsgContains(message, "hugging")) then
		message = "hug"
	elseif fixes and MsgContains(message, "barbarians") then
		message = "barbarian"
	elseif fixes and MsgContains(message, "mammoths") then
		message = "mammoth"
	end
	local barbarianOnly = MsgContains(message, "barbarian") and not (fixes and (MsgContains(message, "test") or MsgContains(message, "mead")))
	if barbarianOnly and (questline < 1 or fixes) then
		npcHandler:say("A true barbarian is something special among our people. Everyone who wants to become a barbarian will have to pass the barbarian {test}.", npc, creature)
		npcHandler:setTopic(playerId, 1)
	elseif (MsgContains(message, "test") or MsgContains(message, "mission") or MsgContains(message, "mammoth")) and questline >= 8 then
		npcHandler:say("You have braved all three tests and are now an honorary barbarian.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "join") then
		npcHandler:say("You might become an honorary barbarian if you manage to pass the barbarian test.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "test") and questline < 1 then
		npcHandler:say({
			"All of our juveniles have to take the barbarian test to become a true member of our community. Foreigners who manage to master the test are granted the title of an honorary barbarian and the respect of our people ...",
			"Are you willing to take the barbarian test?",
		}, npc, creature)
		npcHandler:setTopic(playerId, 2)
	elseif MsgContains(message, "mead") and canStartMeadRound then
		npcHandler:say("Do you have some honey with you?", npc, creature)
		npcHandler:setTopic(playerId, 4)
	elseif MsgContains(message, "mead") and questline == 3 then
		npcHandler:say({
			"An impressive start. Here, take your own mead horn to fill it at the mead bucket as often as you like ...",
			"But there is much left to be done. Your next test will be to hug a bear ...",
			"You will find one in a cave north of the town. If you are lucky, it's still sleeping. If not ... well that might hurt ...",
			"Unless you feel that you hugged the bear, the test is not passed. Once you are done, talk to me about the bear hugging.",
		}, npc, creature)
		player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline, 4)
		player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Mission02, 1) -- Questlog Barbarian Test Quest Barbarian Test 2: The Bear Hugging
		player:addItem(7140, 1)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "hug") then
		if questline == 5 then
			npcHandler:say({
				"Amazing. That was as clever and brave as a barbarian is supposed to be. But a barbarian also has to be strong and fearless. To prove that you will have to knock over a mammoth ...",
				"Did your face just turn into the color of fresh snow? However, you will find a lonely mammoth north west of the town in the wilderness. Knock it over to prove to be a true barbarian ...",
				"Return to me and talk about the {mammoth} pushing when you are done.",
			}, npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline, 6)
			player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Mission03, 1) -- Questlog Barbarian Test Quest Barbarian Test 3: The Mammoth Pushing
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "mammoth") then
		if questline == 7 then
			npcHandler:say({
				"As you have passed all three tests, I welcome you in our town as an honorary barbarian. You can now become a citizen. Don't forget to talk to the people here. Some of them might need some help ...",
				"We usually solve our problems on our own but some of the people might have a mission for you. Old Iskan, on the ice in the northern part of the town had some trouble with his dogs lately.",
			}, npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline, 8)
			player:addAchievement("Honorary Barbarian")
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "yes") then
		if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.HuskyKillStatus) == 1 and questline == 8 then
			if player:removeMoneyBank(player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.HuskyKill) * 1500) then
				npcHandler:say("Alright, we are even!", npc, creature)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.HuskyKillStatus, 0)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.HuskyKill, 0)
				npcHandler:setTopic(playerId, 0)
			else
				npcHandler:say("You don't have enough. Bring me the money and I will forget about it.", npc, creature)
				npcHandler:setTopic(playerId, 0)
			end
		elseif npcHandler:getTopic(playerId) == 2 then
			npcHandler:say({
				"That's the spirit! The barbarian test consists of a few tasks you will have to fulfill. All are rather simple - for a barbarian that is...",
				"Your first task is to drink some barbarian mead. But be warned, it's a strong brew that could even knock out a bear. You need to make at least ten sips of mead in a row without passing out to pass the test ...",
				"Do you think you can do this?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 3)
		elseif npcHandler:getTopic(playerId) == 3 then
			npcHandler:say({
				"Good, but to make barbarian mead we need some honey which is rare here. I'd hate to waste mead just to learn you're not worth it ...",
				"Therefore, you have to get your own honey. You'll probably need more than one try so better get some extra honeycombs. Then talk to me again about barbarian {mead}.",
			}, npc, creature)
			npcHandler:setTopic(playerId, 0)
			-- Guard: the intro may only start the quest, never reset a player who already has progress.
			if questline < 1 then
				player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline, 1)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 1)
				player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Mission01, 1) -- Questlog Barbarian Test Quest Barbarian Test 1: Barbarian Booze
			end
		elseif npcHandler:getTopic(playerId) == 4 then
			if canStartMeadRound and player:removeItem(5902, 1) then
				npcHandler:say("Good, for this honeycomb I allow you 20 sips from the mead bucket over there. Talk to me again about barbarian mead if you have passed the test.", npc, creature)
				npcHandler:setTopic(playerId, 0)
				player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline, 2)
				player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Mission01, 2) -- Questlog Barbarian Test Quest Barbarian Test 1: Barbarian Booze
				player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.MeadTotalSips, 0)
				player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.MeadSuccessSips, 0)
			end
		end
	elseif MsgContains(message, "no") then
		if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.HuskyKillStatus) == 1 and npcHandler:getTopic(playerId) == 0 then
			npcHandler:say("I don't know if you realise the consequences. You won't be a member of our community anymore. I ask you for the last time: Are you willing to pay " .. player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.HuskyKill) * 1500 .. " gold as a compensation?", npc, creature)
			npcHandler:setTopic(playerId, 10)
		elseif npcHandler:getTopic(playerId) == 10 then
			npcHandler:say("Alright, it's your choice. If you regret your decision and want to be a barbarian again, talk to me about the {barbarian} test.", npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline, -1)
			player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Mission01, -1)
			player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Mission02, -1)
			player:setStorageValue(Storage.Quest.U8_0.BarbarianTest.Mission03, -1)
		end
	end
	return true
end

-- FAMILY: his words from the TibiaWiki EN transcript (2026-11-16; lib/others/family_ice_islands.lua).
-- Quest words (barbarian, test, mead, hug, mammoth, mission, join) stay in the callback above.
if Family and Family.iceIslandsAnswers then
	npcHandler:setMessage(MESSAGE_FAREWELL, "May wind and weather be with you, |PLAYERNAME|.")
	local function line(words, text)
		keywordHandler:addKeyword(words, StdModule.say, { npcHandler = npcHandler, text = text })
	end
	line({ "name" }, {
		"I am Sven the Younger. My father, Sven the Elder has been missing in the ice waste since I was young. But unless one of our people is buried properly, we assume that he is still in the realm of the living ...",
		"Therefore, I am still known as 'the Younger', even though I have grown old.",
	})
	line({ "here" }, "I am the {jarl} of my people. It's an honour and I am very proud of it.")
	line({ "job" }, "I am the {jarl} of my people. It's an honour and I am very proud of it.")
	line({ "people" }, "Our people are simple and honest. We don't like the scheming ways of the {city} dwellers that live on the main continent.")
	line({ "jarl" }, "I am more than just the spokesman and highest judge among my {people}. I don't raise taxes, and when the clans feel that it is necessary, I will be replaced by another jarl.")
	line({ "leader" }, "I am more than just the spokesman and highest judge among my {people}. I don't raise taxes, and when the clans feel that it is necessary, I will be replaced by another jarl.")
	line({ "king" }, "We don't need any kings and queens here. Being the jarl of my people, I see that the laws are followed.")
	line({ "queen" }, "We don't need any kings and queens here. Being the jarl of my people, I see that the laws are followed.")
	line({ "ferumbras" }, "Even here we heard about this powerful man. Travellers from the south only dare to whisper his name.")
	line({ "excalibug" }, {
		"On the campfire, there are numerous tales about this weapon. It's told that it has been missing since ages ...",
		"In my opinion, the power and fame of a weapon shouldn't exceed the power and fame of it's wielder. And I have not heard of any hero whose fame would surpass that of excalibug.",
	})
	line({ "honourary barbarian" }, "An honourary barbarian earns the right to become a citizen here. But to prove yourself worthy, you have to pass the barbarian test.")
	line({ "honorary barbarian" }, "An honourary barbarian earns the right to become a citizen here. But to prove yourself worthy, you have to pass the barbarian test.")
	line({ "news" }, "There is something evil going on. I have it in my {bones}.")
	line({ "how are you" }, {
		"There is something in the air that worries me. A great evil is threatening all of us ...",
		"I might not have the gift of dreams that foresee the future like my {mother} did, but I seem to have inherited some of her gift nonetheless. Sometimes I just feel that something is about to happen ...",
		"And this time it's something sinister and evil that threatens us all.",
	})
	line({ "bones" }, {
		"There is something in the air that worries me. A great evil is threatening all of us ...",
		"I might not have the gift of dreams that foresee the future like my {mother} did, but I seem to have inherited some of her gift nonetheless. Sometimes I just feel that something is about to happen ...",
		"And this time it's something sinister and evil that threatens us all.",
	})
	line({ "mother" }, {
		"My mother was that what my people call a witch. This is someone who has special magical abilities without any training on Nibelor ...",
		"She used her powers more instinctively to amplify her healing skills when herbs would not suffice. She also had the gift to foretell the future ...",
		"At first, the druids of Nibelor scorned her, but later they accepted her for her abilities and good intentions.",
	})
	line({ "rumours" }, {
		"It's an old tale but it persists in the minds of the Svargrondar. It is about my father. There are rumours that he is still alive. ...",
		"People regularly report about seeing him on top of the cliff right next to Svargrond. I myself would be glad if finally his corpse were found. Then I would be jarl 'Sven the Elder' ..... sounds much better.",
	})
	line({ "guards" }, {
		"We don't have an army and we don't need one. Even if the raiders call us weak, everyone of us knows how to fight ...",
		"All adults serve as guards for some days each month as a service for the community.",
	})
	line({ "army" }, {
		"We don't have an army and we don't need one. Even if the raiders call us weak, everyone of us knows how to fight ...",
		"All adults serve as guards for some days each month as a service for the community.",
	})
	line({ "monsters" }, "There are many dangerous creatures that roam our isles. But having seen what men can do to each other, I wouldn't call any of them a monster.")
	line({ "santa claus" }, "We heard that this mythical dwarf lives somewhere on the southern Ice Islands.")
	line({ "city" }, {
		"Our people lived as nomads some generations ago. The contact with Carlin taught us another way of living ...",
		"We did not like everything about it but we are not stupid. We have seen the many advantages ...",
		"If you cannot adapt to this land, you are dead and so we adapted to it and built this city. When the contact to Carlin got lost during the years of the serpents, we kept this city alive ...",
		"And we survived, even though the {raiders} did their best to make us fail.",
	})
	line({ "years of serpents" }, {
		"For more than two generations no ship had reached our shores because the giant sea serpents attacked and sank most ships that tried to travel here ...",
		"Not long ago the sea serpents disappeared as suddenly as they had come. Now ships visit us again on a regular base.",
	})
	line({ "raiders" }, {
		"In the past, all barbarian tribes roamed the lands of Chyll as nomads. When the Carliners came here and the trade flourished, we used the resources to build this permanent settlement ...",
		"Some of our people claimed that it was wrong to settle down and to abandon the ancient ways. A female {shaman} rose in the ranks of those who opposed the erection of a settlement ...",
		"She gathered all those who were not content, who did not want any foreign influence and who refused to learn ...",
		"They tried to destroy everything our ancestors had built, but with the help of the Carliners they were stopped and driven away. Now they still roam the land and attack everyone they see ...",
		"They became the raiders, our worst enemy. Nowadays, there are three larger tribes that often build {camps} in the South of our land ...",
		"And after all those years, surviving several generations, this female shaman is still their leader.",
	})
	line({ "camps" }, "The raiders' camps are mainly located in the south-western part of the isle. The camps are named after the major clans of the raiders: Ragnir, Bittermor and Grimhorn.")
	line({ "mines" }, {
		"A long time ago when the trade with Carlin was flourishing, people actually worked in the mines. ...",
		"During the years of the serpents, the mines had been abandoned. Later, the raiders took shelter there, although they blame us for living in a fortified city ...",
		"Now, the traders of Carlin are back but some other foreigners seem to have claimed the mines from the raiders ...",
		"It's neither our business nor would we have the manpower to help them to recapture the mines. Also, if they do not have the strength to get the mines back on their own, they don't deserve them anyway.",
	})
	line({ "gods" }, {
		"We know of father Chyll and his freezing breath. We care little for other gods. It is foolish to meddle with beings that are so powerful ...",
		"We leave it to the druids and shamans to handle such affairs.",
	})
	line({ "chyll" }, {
		"Father north wind is called Chyll by our people. He is an unforgiving hunter. He knows no mercy with the weak ...",
		"Chyll is a harsh god and the best you can do is to avoid his attention. Only the shamans and druids deal with him.",
	})
	line({ "druids" }, "Most shaman and druids of our people live on the sacred isle {Nibelor}. There, they divine the future, calm the wrath of father Chyll and prepare the dead for their last travel to the lands of {Everspring}.")
	line({ "shaman" }, "Most shaman and druids of our people live on the sacred isle {Nibelor}. There, they divine the future, calm the wrath of father Chyll and prepare the dead for their last travel to the lands of {Everspring}.")
	line({ "nibelor" }, "Nibelor has always been a sacred place for our people. The druids and shamans live there.")
	line({ "everspring" }, {
		"Everspring is the realm of the dead. It is a place of peace and harmony where those who boldly braved the challenges of life dwell for eternity and share stories at the campfires after a hunt ...",
		"Every true barbarian that is properly brought into afterlife will join the great hunt in Everspring where the animals are fat and have the thickest furs.",
	})
	line({ "cults" }, "I don't care what people who come here believe in. If they provoke father Chyll, he will take care of them on his own. If their gods prove to be more powerful than Chyll, they might deserve to live.")
	line({ "carlin" }, "We are friends of the Carliners. Still we don't allow their politics to influence our way to handle things here.")
	line({ "edron" }, "We have heard only little about this far away place.")
	line({ "port hope" }, "We have heard only little about this far away place.")
	line({ "thais" }, "We understand that our friends from Carlin are wary with the realm ruled by Thais but this is not of our concern.")
	line({ "venore" }, "We did not allow them to stay here. This had nothing to do with our friendship with Carlin but for the way they handled things and their harmful approach to go hunting.")
	line({ "enemies" }, {
		"Our enemies are numerous. Those of our people that we call the raiders are full of hate towards us. Then there are the voracious chakoyas that leave their icy homes to kill and slaughter from time to time ...",
		"Sometimes, the great ice dragons find their way here to wreak havoc, and there are many more hungry beasts of all kinds.",
	})
	line({ "chakoyas" }, {
		"The chakoyas are neither beast nor man. Yet, they share the worst and more dangerous traits of both of them. Their small and furry appearance can be very misleading at first glance ...",
		"But as soon as you've seen a pack of chakoyas literally shredding a mammoth into pieces with their claws and teeth, all misconceptions will be gone.",
	})
	line({ "ice dragons" }, {
		"The dragons on our isles have adapted to the climate as every creature here. Instead of being aligned to fire, they became creatures of the cold ...",
		"They are fierce and dangerous but, luckily, they only prey on beasts of the sea or those that wander the ice near their lairs.",
	})
	line({ "yeti" }, "The yetis are mythical beasts. Only few that encountered those creatures lived to tell the tale. The chakoyas worship them as divine beings, although they have no real relations to them as far as we can tell.")
	line({ "dwarfs" }, "I met some of those little people in the past. Considering our experience with the chakoyas, we don't underestimate someone just for its look. And those dwarfs proved indeed to be powerful, courageous and enduring.")
	line({ "elves" }, "Some time ago, a few elves came here but they could not stand the cold and so they left pretty soon. Most likely it was Nibelor in which they have been interested.")
	line({ "elfs" }, "Some time ago, a few elves came here but they could not stand the cold and so they left pretty soon. Most likely it was Nibelor in which they have been interested.")
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
