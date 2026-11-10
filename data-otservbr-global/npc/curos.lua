local internalNpcName = "Curos"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 29,
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

local TheNewFrontier = Storage.Quest.U8_54.TheNewFrontier
local AnUneasyAlliance = Storage.Quest.U8_54.AnUneasyAlliance
local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "mission") then
		if player:getStorageValue(TheNewFrontier.Questline) == 16 then
			npcHandler:say("You come here to ask us to spare your people? This land has no tolerance for the weak, we have it neither. If you want us to consider you as useful for us, you'll have to prove it in a {test} of strength and courage. ", npc, creature)
			npcHandler:setTopic(playerId, 1)
		elseif player:getStorageValue(TheNewFrontier.Questline) == 18 then
			npcHandler:say({
				"We have seen that you can fight and survive. Yet, it will also need cleverness and courage to survive in these lands. We might see later if you've got what it takes. ...",
				"However, I stand to my word - our hordes will spare your insignificant piece of rock for now. Time will tell if you are worthy living next to us. ...",
				"Still, it will take years until we might consider you as an ally, but this is a start at least.",
			}, npc, creature)
			player:setStorageValue(TheNewFrontier.Questline, 19)
			player:setStorageValue(TheNewFrontier.Mission06, 4) --Questlog, The New Frontier Quest "Mission 06: Days Of Doom"
		elseif player:getStorageValue(TheNewFrontier.Mission06) >= 5 and player:getStorageValue(AnUneasyAlliance.Questline) < 1 then --An Uneasy Alliance Quest
			npcHandler:say({
				"So you still think you can be of any use for us? Words are cheap and easy. Admittedly, you've passed our first test but even some resilient beast might have accomplished that. ...",
				"Your actions will tell if you are only yelping for attention like a puppy or if you have the teeth of a wolf. ...",
				"A first tiny step was taken. You survived the test and ensured the survival of your allies for a while. Now it is time to make the next step. ...",
				"So listen human: Our rule over the orcs is not unchallenged. Of course now and then someone shows up who thinks he can defeat us. Usually these fights end fast and bloody in the ring. ...",
				"Right now, some coward from our midst, who is too afraid to face us in single combat, has gathered a group of followers, hoping more will follow and change sides. ...",
				"With your help, his defeat will not only be deadly but also humiliating and so discourage others to follow his example. ...",
				"You will seek out this rebel commander in his hideout and kill him. We will show them that not even a Mooh'Tah master is needed to get rid of such wannabe leaders but that a mere human can handle them. ...",
				"Find him in the mountain north-west of here and kill him. If you find any loot, you can keep it.",
			}, npc, creature)
			player:setStorageValue(AnUneasyAlliance.Questline, 1)
			player:setStorageValue(AnUneasyAlliance.QuestDoor, 0)
		elseif player:getStorageValue(AnUneasyAlliance.Questline) == 1 and player:getStorageValue(AnUneasyAlliance.QuestDoor) == 1 then
			npcHandler:say("With the death of their leader, the rebels return to our camps one by one, deeply humiliated. It might be a wise decision to let a useful tool like you continue to exist.", npc, creature)
			player:setStorageValue(AnUneasyAlliance.Questline, 2)
		elseif player:getStorageValue(AnUneasyAlliance.Questline) == 2 then
			npcHandler:say({
				"We are aware that the lizards use magic to spy on us. In the Dragonblaze Mountains north of here, there is a tower which can only be entered through one of their underground fortresses. ...",
				"In this tower, there must be some accessory used for magical scrying. Some pond, a crystal ball, or a mirror maybe - it has to be something shiny. ...",
				"Usually we would send one of our youngsters on such a mission, but we are few and there is little new blood in our ranks. ...",
				"We can't send a Mooh'Tah master on such a trivial assignment, neither can we use orcs for an infiltration mission. ...",
				"This is your chance to show us your potential. Infiltrate this tower and destroy their scrying device. Once you have blinded our enemy, we might respect you somewhat more.",
			}, npc, creature)
			player:setStorageValue(AnUneasyAlliance.Questline, 3)
		elseif player:getStorageValue(AnUneasyAlliance.Questline) == 4 then
			npcHandler:say({
				"Finally, our enemy's vision is obscured. Now we can move in for some more daring raids until they replace their scrying device. You have proven yourself brave and useful so far. With that, you bought your allies some more days to live. ...",
				"Here is a reward. It's a strange tome that we've found in the lizard ruins. Maybe it is of some value for you or your allies.",
			}, npc, creature)
			player:setStorageValue(AnUneasyAlliance.Questline, 5)
			player:addItem(10217)
		end
	elseif MsgContains(message, "test") then
		if npcHandler:getTopic(playerId) == 1 then
			npcHandler:say({
				"First we will test your strength and endurance. You'll have to face one of the most experienced Mooh'Tah masters. As you don't stand a chance to beat such an opponent, your test will be simply to survive. ...",
				"Face him in a battle and survive for two minutes. If you do, we will be willing to assume that your are prepared for the life in these lands. Enter the ring of battle, close to my quarter. Return to me after you have passed this test.",
			}, npc, creature)
			npcHandler:setTopic(playerId, 0)
			player:setStorageValue(TheNewFrontier.Questline, 17)
			player:setStorageValue(TheNewFrontier.Mission06, 2) --Questlog, The New Frontier Quest "Mission 06: Days Of Doom"
		end
	end
	return true
end

-- FAMILY: TibiaWiki EN transcript keywords (upstream had none, 2026-11-10)
keywordHandler:addKeyword({ "greeted" }, StdModule.say, { npcHandler = npcHandler, text = "I am Curos of the minotaurs! {Leader} of the local orc tribes." })
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "I am Curos of the minotaurs! {Leader} of the local orc tribes." })
keywordHandler:addKeyword({ "leader" }, StdModule.say, { npcHandler = npcHandler, text = { "We minotaurs are proud people. It took us a long time to get rid of the shackles of the gods and even longer to overcome our rage. We are not numerous anymore and the life of every single minotaur is precious. Still, there is infighting and quarrels. ...", "This led to our great experiment. If we can prove that even the simpleminded {orcs} can overcome their bestial heritage with our leadership, we might inspire the whole minotaur nation." } })
keywordHandler:addKeyword({ "minotaurs" }, StdModule.say, { npcHandler = npcHandler, text = { "We minotaurs are proud people. It took us a long time to get rid of the shackles of the gods and even longer to overcome our rage. We are not numerous anymore and the life of every single minotaur is precious. Still, there is infighting and quarrels. ...", "This led to our great experiment. If we can prove that even the simpleminded {orcs} can overcome their bestial heritage with our leadership, we might inspire the whole minotaur nation." } })
keywordHandler:addKeyword({ "minotaur" }, StdModule.say, { npcHandler = npcHandler, text = { "We minotaurs are proud people. It took us a long time to get rid of the shackles of the gods and even longer to overcome our rage. We are not numerous anymore and the life of every single minotaur is precious. Still, there is infighting and quarrels. ...", "This led to our great experiment. If we can prove that even the simpleminded {orcs} can overcome their bestial heritage with our leadership, we might inspire the whole minotaur nation." } })
keywordHandler:addKeyword({ "orc" }, StdModule.say, { npcHandler = npcHandler, text = { "The orcs are savage and uncontrolled. Yet, they long for leadership, and it is astonishing how easy it is to convince entire tribes if you can convince certain key individuals. ...", "Of course convincing an orc is a violent matter and often involves fighting, killing and threats. But we were willing to adopt this kind of orcish 'diplomacy'. ...", "When their champions were killed and their leaders beaten by {Mooh'Tah} masters, who had come here to look for surviving minotaur communities, entire tribes bowed to their rule. ...", "It was very difficult in the beginning and only time taught the orcs not to challenge the power of the Mooh'Tah masters. ...", "They adapt slowly to our teachings but they adapt nonetheless. Little by little they change. It might take generations but the change is taking place. ...", "They have a hard time to understand even the most obvious teachings of the Mooh'Tah, and they are still full of rage. If they attack you in their rage, you are allowed to kill them. Those who can't control themselves do not deserve any better. ...", "An orc generation does not last long but its survivors have learnt some lesson. We hope this form of selection will eventually help us to create a new breed of orcs that is smarter, more capable and more open to our teachings." } })
keywordHandler:addKeyword({ "orcs" }, StdModule.say, { npcHandler = npcHandler, text = { "The orcs are savage and uncontrolled. Yet, they long for leadership, and it is astonishing how easy it is to convince entire tribes if you can convince certain key individuals. ...", "Of course convincing an orc is a violent matter and often involves fighting, killing and threats. But we were willing to adopt this kind of orcish 'diplomacy'. ...", "When their champions were killed and their leaders beaten by {Mooh'Tah} masters, who had come here to look for surviving minotaur communities, entire tribes bowed to their rule. ...", "It was very difficult in the beginning and only time taught the orcs not to challenge the power of the Mooh'Tah masters. ...", "They adapt slowly to our teachings but they adapt nonetheless. Little by little they change. It might take generations but the change is taking place. ...", "They have a hard time to understand even the most obvious teachings of the Mooh'Tah, and they are still full of rage. If they attack you in their rage, you are allowed to kill them. Those who can't control themselves do not deserve any better. ...", "An orc generation does not last long but its survivors have learnt some lesson. We hope this form of selection will eventually help us to create a new breed of orcs that is smarter, more capable and more open to our teachings." } })
keywordHandler:addKeyword({ "mooh'tah" }, StdModule.say, { npcHandler = npcHandler, text = { "You {humans} lack the spiritual energy of emotion and therefore cannot utilise this power. The Mooh'Tah teaches the taming of the inner beast. ...", "To conquer strong emotions like rage and fear is one goal, but there are other destructive but more subtle urges that need to be overcome. ...", "Greed, envy and the like are often more dangerous as they do not hit you with full force but steadily poison your thoughts." } })
keywordHandler:addKeyword({ "mooh tah" }, StdModule.say, { npcHandler = npcHandler, text = { "You {humans} lack the spiritual energy of emotion and therefore cannot utilise this power. The Mooh'Tah teaches the taming of the inner beast. ...", "To conquer strong emotions like rage and fear is one goal, but there are other destructive but more subtle urges that need to be overcome. ...", "Greed, envy and the like are often more dangerous as they do not hit you with full force but steadily poison your thoughts." } })
keywordHandler:addKeyword({ "moohtah" }, StdModule.say, { npcHandler = npcHandler, text = { "You {humans} lack the spiritual energy of emotion and therefore cannot utilise this power. The Mooh'Tah teaches the taming of the inner beast. ...", "To conquer strong emotions like rage and fear is one goal, but there are other destructive but more subtle urges that need to be overcome. ...", "Greed, envy and the like are often more dangerous as they do not hit you with full force but steadily poison your thoughts." } })
keywordHandler:addKeyword({ "humans" }, StdModule.say, { npcHandler = npcHandler, text = { "The humans of this land are pathetic and even worse than the {orcs}. Yet, we know of the heights that humans are capable of. This is a clear proof that our influence on the orcs can change them. ...", "When humans can fall that far, why shouldn't orcs be able to rise to unknown heights?" } })
keywordHandler:addKeyword({ "human" }, StdModule.say, { npcHandler = npcHandler, text = { "The humans of this land are pathetic and even worse than the {orcs}. Yet, we know of the heights that humans are capable of. This is a clear proof that our influence on the orcs can change them. ...", "When humans can fall that far, why shouldn't orcs be able to rise to unknown heights?" } })
keywordHandler:addKeyword({ "land" }, StdModule.say, { npcHandler = npcHandler, text = "The {lizard} men call this land {Zao}. The orcs did not bother to give the land a name, so we adopted the lizard term." })
keywordHandler:addKeyword({ "lizard" }, StdModule.say, { npcHandler = npcHandler, text = "This {land} used to be the land of the lizards. But they took the land by force, so whoever has the power to challenge them can take as much of the land as he is able to gain and to hold." })
keywordHandler:addKeyword({ "lizards" }, StdModule.say, { npcHandler = npcHandler, text = "This {land} used to be the land of the lizards. But they took the land by force, so whoever has the power to challenge them can take as much of the land as he is able to gain and to hold." })
keywordHandler:addKeyword({ "zao" }, StdModule.say, { npcHandler = npcHandler, text = "This {land} used to be the land of the lizards. But they took the land by force, so whoever has the power to challenge them can take as much of the land as he is able to gain and to hold." })
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell for now!")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "Be greeted blank skin.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
