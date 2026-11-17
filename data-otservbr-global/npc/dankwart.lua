local internalNpcName = "Dankwart"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 128,
	lookHead = 39,
	lookBody = 58,
	lookLegs = 58,
	lookFeet = 115,
	lookAddons = 0,
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

-- FAMILY (2026-11-17): lore words from the TibiaWiki EN transcript (Dankwart/Transcripts, general
-- keywords); upstream had none of them. Quest words stay with the quest code.
keywordHandler:addKeyword({ "drink" }, StdModule.say, { npcHandler = npcHandler, text = "Are you looking for a drink? I have tea and hot mead. Our mead is a little less stronger than the original barbarian mead though, else we'd have a bunch of tourists pass out here each day." })
keywordHandler:addKeyword({ "mead" }, StdModule.say, { npcHandler = npcHandler, text = "Yes, just ask me for a trade." })
keywordHandler:addKeyword({ "news" }, StdModule.say, { npcHandler = npcHandler, text = "I assume our town gossip would only bore a traveller like you." })
keywordHandler:addKeyword({ "king" }, StdModule.say, { npcHandler = npcHandler, text = "The king probably laughs about Carlin's failure here." })
keywordHandler:addKeyword({ "queen" }, StdModule.say, { npcHandler = npcHandler, text = "The queen should really spend more resources on the Svargrond operations." })
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "I am Dankwart. A rather unusual name at this place but my ancestors came here from Carlin." })
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I am a tavern keeper. Well at least you would call it like that. Actually I am just responsible for the common hall." })
keywordHandler:addKeyword({ "gods" }, StdModule.say, { npcHandler = npcHandler, text = "I learned only little about the gods." })
keywordHandler:addKeyword({ "ferumbras" }, StdModule.say, { npcHandler = npcHandler, text = "Some regulars shared stories about this evil sorcerer. It is said that he resurfaced somewhere in the South." })
keywordHandler:addKeyword({ "excalibug" }, StdModule.say, { npcHandler = npcHandler, text = "That is some mighty weapon that got lost in a war or so." })
keywordHandler:addKeyword({ "offer" }, StdModule.say, { npcHandler = npcHandler, text = "I can offer you bread, cheese, ham, or meat as well as {drinks}. If you'd like to see my offers, ask me for a {trade}." })
keywordHandler:addKeyword({ "food" }, StdModule.say, { npcHandler = npcHandler, text = "Are you looking for food? I have bread, cheese, ham, and meat. Just ask me for a trade." })
keywordHandler:addKeyword({ "how are you" }, StdModule.say, { npcHandler = npcHandler, text = "I am fine, thank you.}}" })
keywordHandler:addKeyword({ "barbarians" }, StdModule.say, { npcHandler = npcHandler, text = "The barbarians are not as bad as foreigners might think. It is mainly the bad behaviour of the raiders that cause their bad reputation." })
keywordHandler:addKeyword({ "raiders" }, StdModule.say, { npcHandler = npcHandler, text = "They are nothing more than mislead people. It's a sad thing that they became that hostile to Svargrond." })
keywordHandler:addKeyword({ "cults" }, StdModule.say, { npcHandler = npcHandler, text = { "Several people passed our city. They were quite reclusive. It seemed as if others followed them even without passing our city at all ...", "I am not sure if they belonged to some sort of cult but they behaved more than suspiciously." } })
keywordHandler:addKeyword({ "druids" }, StdModule.say, { npcHandler = npcHandler, text = "The druids are still working on intensifying the bonds with the shamans." })
keywordHandler:addKeyword({ "shamans" }, StdModule.say, { npcHandler = npcHandler, text = "They are spiritual guides and seers." })
keywordHandler:addKeyword({ "jarl" }, StdModule.say, { npcHandler = npcHandler, text = "The jarl is a wise man." })
keywordHandler:addKeyword({ "mines" }, StdModule.say, { npcHandler = npcHandler, text = "The mines were lost many years ago. I doubt that we get them back any time soon." })
keywordHandler:addKeyword({ "chyll" }, StdModule.say, { npcHandler = npcHandler, text = "My family converted to the faith of the barbarians to some extent. If you live here long enough, you know from the north wind that there is some force at work here." })
keywordHandler:addKeyword({ "nibelor" }, StdModule.say, { npcHandler = npcHandler, text = "Most of the shamans live on the isle Nibelor." })
keywordHandler:addKeyword({ "everspring" }, StdModule.say, { npcHandler = npcHandler, text = "That is the place of afterlife. Shamans can tell you more about it." })
keywordHandler:addKeyword({ "years of serpents" }, StdModule.say, { npcHandler = npcHandler, text = "They were the reason that my people stranded here. However, my ancestors were not too sorry about it and adapted quite well.}}" })
keywordHandler:addKeyword({ "svargrond" }, StdModule.say, { npcHandler = npcHandler, text = "The town is somewhat rough but it has its charms." })
keywordHandler:addKeyword({ "edron" }, StdModule.say, { npcHandler = npcHandler, text = "Edron must be wonderful and idyllic." })
keywordHandler:addKeyword({ "carlin" }, StdModule.say, { npcHandler = npcHandler, text = "Carlin will probably put more efforts into improving relations with Svargrond soon." })
keywordHandler:addKeyword({ "venore" }, StdModule.say, { npcHandler = npcHandler, text = "Venore will surely try to hinder Carlin in any way." })
keywordHandler:addKeyword({ "thais" }, StdModule.say, { npcHandler = npcHandler, text = "Thais has little interest in this area.}}" })
keywordHandler:addKeyword({ "dragons" }, StdModule.say, { npcHandler = npcHandler, text = "There are travellers who will assure you that some dragons exist here in this cold climate. Some even claim that an own breed of ice dragons lives on these isles." })
keywordHandler:addKeyword({ "dwarfs" }, StdModule.say, { npcHandler = npcHandler, text = "The dwarfs that came here were able to drink like a true barbarian." })
keywordHandler:addKeyword({ "elf" }, StdModule.say, { npcHandler = npcHandler, text = "We rarely see an elf here." })
keywordHandler:addKeyword({ "chakoyas" }, StdModule.say, { npcHandler = npcHandler, text = "The chakoyas are a true threat. Luckily, they are not too many and they rarely dare to come close to Svargrond." })
keywordHandler:addKeyword({ "yeti" }, StdModule.say, { npcHandler = npcHandler, text = "I don't know if they are real or just some figure of tavern tales." })
npcHandler:setMessage(MESSAGE_GREET, "Hi there and welcome to my tavern. Have a drink.")

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {
	{ itemName = "bread", clientId = 3600, buy = 4 },
	{ itemName = "cheese", clientId = 3607, buy = 6 },
	{ itemName = "ham", clientId = 3582, buy = 8 },
	{ itemName = "meat", clientId = 3577, buy = 5 },
	{ itemName = "mug of mead", clientId = 2880, buy = 5, count = 16 },
	{ itemName = "mug of tea", clientId = 2880, buy = 3, count = 17 },
	{ itemName = "vial of mead", clientId = 2874, buy = 5, count = 1, subType = 16 },
}
-- On buy npc shop message
npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end
-- On sell npc shop message
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost)
	player:sendTextMessage(MESSAGE_TRADE, string.format("Sold %ix %s for %i gold.", amount, name, totalCost))
end
-- On check npc shop message (look item)
npcType.onCheckItem = function(npc, player, clientId, subType) end

npcType:register(npcConfig)
