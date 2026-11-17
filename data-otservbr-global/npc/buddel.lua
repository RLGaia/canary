local internalNpcName = "Buddel"
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
	lookHead = 19,
	lookBody = 57,
	lookLegs = 22,
	lookFeet = 20,
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
	-- FAMILY: during the name game the answer is a name, before any keyword (a name like "Tester" would hit "test")
	if FamilyBuddelNameGame and FamilyBuddelNameGame(npc, creature, type, message) then
		return
	end
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

-- Travel
local function addTravelKeyword(keyword, text, destination, randomDestination, randomNumber, condition, ringCheck, ringRemove, helheimAccess)
	if condition then
		keywordHandler:addKeyword({ keyword }, StdModule.say, { npcHandler = npcHandler, text = "No, no, no, you even are no barb....barba...er.. one of us!!!! Talk to the Jarl first!" }, condition)
	end
	if helheimAccess then
		keywordHandler:addKeyword({ keyword }, StdModule.say, { npcHandler = npcHandler, text = text }, helheimAccess)
	end
	if ringCheck then
		local ring = keywordHandler:addKeyword({ keyword }, StdModule.say, { npcHandler = npcHandler, text = "Ohh, you got a nice ring there! Ya don't have to pay if you gimme the ring and I promise you I will bring you to the correct spot!*HICKS* Alright?" }, ringCheck)
		ring:addChildKeyword({ "yes" }, StdModule.travel, { npcHandler = npcHandler, premium = false, cost = 0, destination = destination }, ringRemove)
		local normalTravel = ring:addChildKeyword({ "no" }, StdModule.say, { npcHandler = npcHandler, text = "Give me 50 gold and I bring you to " .. keyword .. ". 'kay?" })
		normalTravel:addChildKeyword({ "no" }, StdModule.say, { npcHandler = npcHandler, text = "You shouldn't miss the experience.", reset = true })
		if randomNumber then
			normalTravel:addChildKeyword({ "yes" }, StdModule.travel, { npcHandler = npcHandler, premium = false, cost = 50, discount = "postman", destination = destination }, randomNumber)
		end
		normalTravel:addChildKeyword({ "yes" }, StdModule.travel, { npcHandler = npcHandler, premium = false, cost = 50, discount = "postman", destination = randomDestination }, randomNumber)
	end
	local travelKeyword = keywordHandler:addKeyword({ keyword }, StdModule.say, { npcHandler = npcHandler, text = text, cost = 50, discount = "postman" })
	travelKeyword:addChildKeyword({ "no" }, StdModule.say, { npcHandler = npcHandler, text = "You shouldn't miss the experience.", reset = true })
	if randomNumber then
		travelKeyword:addChildKeyword({ "yes" }, StdModule.travel, { npcHandler = npcHandler, premium = false, cost = 50, discount = "postman", destination = destination }, randomNumber)
	end
	travelKeyword:addChildKeyword({ "yes" }, StdModule.travel, { npcHandler = npcHandler, premium = false, cost = 50, discount = "postman", destination = randomDestination }, randomNumber)
end

local randomDestination = { Position(32225, 31381, 7), Position(32462, 31174, 7), Position(32333, 31227, 7), Position(32021, 31294, 7) }
addTravelKeyword("okolnir", "It's nice there. Except of the ice dragons which are not very companionable.", Position(32225, 31381, 7), function()
	return randomDestination[math.random(#randomDestination)]
end, function()
	return math.random(5) > 1
end, function(player)
	return player:getStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline) ~= 8
end, function(player)
	return player:getItemCount(3097) > 0
end, function(player)
	return player:removeItem(3097, 1)
end)
addTravelKeyword("helheim", "T'at is a small island to the east.", Position(32462, 31174, 7), function()
	return randomDestination[math.random(#randomDestination)]
end, function()
	return math.random(5) > 1
end, function(player)
	return player:getStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline) ~= 8
end, function(player)
	return player:getItemCount(3097) > 0
end, function(player)
	return player:removeItem(3097, 1)
end, function(player)
	return player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) < 30
end)
-- FAMILY (2026-11-17): Tyrsung only after Siflind's first mission (EN spoiler: "After talking with her,
-- you can now travel to Tyrsung via Buddel's boat"); upstream sailed every barbarian there. Line ours.
keywordHandler:addKeyword({ "tyrsung" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "*HICKS* Tyrsung? Nobody goes there wi'hout a reason. Ask Siflind on Nibelor what's goin' on there first.",
}, function(player)
	return player:getStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline) == 8 and player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) < 6
end)
addTravelKeyword("tyrsung", "*HICKS* Big, big island east of here. Venorian hunters settled there ..... I could bring you north of their camp.", Position(32333, 31227, 7), function()
	return randomDestination[math.random(#randomDestination)]
end, function()
	return math.random(5) > 1
end, function(player)
	return player:getStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline) ~= 8
end, function(player)
	return player:getItemCount(3097) > 0
end, function(player)
	return player:removeItem(3097, 1)
end)
addTravelKeyword("camp", "Both of you look like you could defend yourself! If you want to go there, ask me for a passage.", Position(32021, 31294, 7), function()
	return randomDestination[math.random(#randomDestination)]
end, function()
	return math.random(5) > 1
end, function(player)
	return player:getStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline) ~= 8
end, function(player)
	return player:getItemCount(3097) > 0
end, function(player)
	return player:removeItem(3097, 1)
end)
-- Kick
keywordHandler:addKeyword({ "kick" }, StdModule.kick, { npcHandler = npcHandler, text = "Get out o' here!*HICKS*", destination = { Position(32255, 31193, 7), Position(32256, 31193, 7), Position(32257, 31193, 7) } })

keywordHandler:addKeyword({ "passage" }, StdModule.say, { npcHandler = npcHandler, text = "Where are we at the moment? Is this Svargrond? Ahh yes!*HICKS* Where do you want to go?" })
keywordHandler:addAliasKeyword({ "trip" })
keywordHandler:addAliasKeyword({ "go" })
keywordHandler:addAliasKeyword({ "sail" })
keywordHandler:addAliasKeyword({ "ship" }) -- FAMILY (2026-11-17): EN "passage or ship or go"

-- FAMILY (2026-11-17): the name game of the EN transcript ("Scripted name keyword"): Buddel sees two of
-- you and asks both names; the same name as yours twice makes him laugh about your mother.
keywordHandler:addKeyword({ "name" }, function(npc, creature)
	npcHandler:say("There was a time I was called Bejorn. But everyone calls me Buddel. ..... and you are?", npc, creature)
	npcHandler:setTopic(creature:getId(), 91)
	return true
end)

function FamilyBuddelNameGame(npc, creature, type, message)
	local player = Player(creature)
	if not player or not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	local t = npcHandler:getTopic(player:getId())
	if t ~= 91 and t ~= 92 then
		return false
	end
	local playerId = player:getId()
	local topic = npcHandler:getTopic(playerId)
	local own = message:lower():gsub("^%s+", ""):gsub("%s+$", "") == player:getName():lower()
	if topic == 91 then
		if own then
			npcHandler:say("Ahh, " .. player:getName() .. ". And you?", npc, creature)
		else
			npcHandler:say("Aha! And you?", npc, creature)
		end
		npcHandler:setTopic(playerId, 92)
		return true
	elseif topic == 92 then
		if own then
			npcHandler:say({
				"You are also called " .. player:getName() .. "?!?!? Your mother was not very inventive *HICKS* but very convenient. ...",
				"She only needs to remember one name and when she calls one of you, both of you will come!!!",
			}, npc, creature)
		else
			npcHandler:say("Huhuhu,..... er..... shouldn't be offensive, but this is a funny name you have!", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
		return true
	end
	return false
end

npcHandler:setMessage(MESSAGE_GREET, "Hey big guys. You? {Here}? *HICKS*")

-- FAMILY (2026-11-17): lore words from the TibiaWiki EN transcript (Buddel/Transcripts, general
-- keywords); upstream had none of them. Quest words stay with the quest code.
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I am a fisher aaaaaaand maybe I can show you the other islands. Depends on how good I know you two. Just ask me for a passage!" })
keywordHandler:addKeyword({ "king" }, StdModule.say, { npcHandler = npcHandler, text = "I'M THE KING OF THIS SHIP AND ALL RUM FLASKS IN IT!!" })
keywordHandler:addKeyword({ "rum" }, StdModule.say, { npcHandler = npcHandler, text = "I don't know and I don't wanna know how that stuff is made but it tastes good! Good, good, *HICKS* very good! I have it from Breezelda." })
keywordHandler:addKeyword({ "druids" }, StdModule.say, { npcHandler = npcHandler, text = "Druids are strange. Are you two druids? Er, not that you look strange!! No, no, no! *HICKS*" })
keywordHandler:addKeyword({ "shamans" }, StdModule.say, { npcHandler = npcHandler, text = "CAN'T YOU SEE I'M TALKING TO THAT GENTLEMAN BESIDE YOU?!?!? Okay, what did you ask?" })
keywordHandler:addKeyword({ "ferumbras" }, StdModule.say, { npcHandler = npcHandler, text = { "Hey, who of you knows a story about that??? You or you? ...", "You are twins, aren't you?" } })
keywordHandler:addKeyword({ "excalibug" }, StdModule.say, { npcHandler = npcHandler, text = "Teeheehee, I don't know but you two are funny!" })
keywordHandler:addKeyword({ "news" }, StdModule.say, { npcHandler = npcHandler, text = "Breezelda brought rum from Port *HICKS* er Hope." })
keywordHandler:addKeyword({ "port hope" }, StdModule.say, { npcHandler = npcHandler, text = "I have to go there sometime to buy more rum!" })
keywordHandler:addKeyword({ "breezelda" }, StdModule.say, { npcHandler = npcHandler, text = "She is a suuuuu*HICKS*uuuch a good captain! Sold me all her rum and not even ve'y expensive. *HICKS*" })
keywordHandler:addKeyword({ "how are you" }, StdModule.say, { npcHandler = npcHandler, text = "Good, good, good! *HICKS*" })
keywordHandler:addKeyword({ "carlin" }, StdModule.say, { npcHandler = npcHandler, text = { "Hey, who of you knows a story about that??? You or you? ...", "You are twins, aren't you?" } })
keywordHandler:addKeyword({ "thais" }, StdModule.say, { npcHandler = npcHandler, text = { "Hey, who of you knows a story about that??? You or you? ...", "You are twins, aren't you?" } })
keywordHandler:addKeyword({ "edron" }, StdModule.say, { npcHandler = npcHandler, text = { "Hey, who of you knows a story about that??? You or you? ...", "You are twins, aren't you?" } })
keywordHandler:addKeyword({ "venore" }, StdModule.say, { npcHandler = npcHandler, text = { "Hey, who of you knows a story about that??? You or you? ...", "You are twins, aren't you?" } })
keywordHandler:addKeyword({ "dwarf" }, StdModule.say, { npcHandler = npcHandler, text = "They are the devil's dogsbodies! I heard they have rings which make you stone-cold sober when you wear them!" })
keywordHandler:addKeyword({ "dragon" }, StdModule.say, { npcHandler = npcHandler, text = "I saw one at the harbour! YES! It crawled up the bow of that battleship! *HICKS* Not very agile these beasts, it nearly didn't move at all." })
keywordHandler:addKeyword({ "husky" }, StdModule.say, { npcHandler = npcHandler, text = "I like them! Som'times when I fall asleep on my way home they warm me! Cute isn't it? *HICKS*" })
keywordHandler:addKeyword({ "yeti" }, StdModule.say, { npcHandler = npcHandler, text = "Nooooo, you are no yeti. They are not that ugly! *HICKS* And they only have two eyes! OH MY GOD.... YOU ARE THAT BEHOLDER AGAIN!!! AHHHHHHHH" })
keywordHandler:addKeyword({ "svargrond" }, StdModule.say, { npcHandler = npcHandler, text = { "You know a town nicer than this? NICER DICER! Apropos, don't play dice when you are drunk ...", "You wanna play a little bit? We three?? No? Ahhhhh, you are drunk! I see! *HICKS*" } })
keywordHandler:addKeyword({ "jarl" }, StdModule.say, { npcHandler = npcHandler, text = "Sven? She's old and called young, er he. Sure he is! Got me? No? *HICKS* Doesn't matter." })
keywordHandler:addKeyword({ "raiders" }, StdModule.say, { npcHandler = npcHandler, text = "They are fools. Other than us three, we are drunk er smart. *HICKS*" })
keywordHandler:addKeyword({ "chyll" }, StdModule.say, { npcHandler = npcHandler, text = "It is better to freeze a li'le than to paddle 'til your hands bri'le. That's what my gran' gran' gran' gran' pa' used to say all the time!" })
keywordHandler:addKeyword({ "nibelor" }, StdModule.say, { npcHandler = npcHandler, text = "The shamans respect me. They like fish! I like fish too. *HICKS* Stupid question! Otherwise I wouldn't be a fisherman!" })
keywordHandler:addKeyword({ "years of serpents" }, StdModule.say, { npcHandler = npcHandler, text = "The serpents were bad. Bad, bad, bad!! BAD SERPENTS! BAD!! I don't want the serpents back. No!" })
keywordHandler:addKeyword({ "test" }, StdModule.say, { npcHandler = npcHandler, text = { "I have a test for you! Go get me a flask of rum and both of you become barbaraba ... you know what I mean ...", "...and if you have it ask me for the test again!" } })
keywordHandler:addKeyword({ "mead" }, StdModule.say, { npcHandler = npcHandler, text = "Mead is good. Good, good, good ........ but that rum I bought from Breezelda is a nice va'iation! *HICKS*" })
keywordHandler:addKeyword({ "mine" }, StdModule.say, { npcHandler = npcHandler, text = "What is yours? Not that flask here that's mine!" })
keywordHandler:addKeyword({ "chakoya" }, StdModule.say, { npcHandler = npcHandler, text = "Chyll bless you!" })
keywordHandler:addKeyword({ "cult" }, StdModule.say, { npcHandler = npcHandler, text = "You wanna reestablish one?!?! Can I *HICKS* join?? Do we get enough to drink? Tell me if I can join!" })

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {
	{ itemName = "compass", clientId = 10302, sell = 45 },
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
