local internalNpcName = "Serafin"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 129,
	lookHead = 96,
	lookBody = 123,
	lookLegs = 86,
	lookFeet = 98,
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

local BloodBrothers = Storage.Quest.U8_4.BloodBrothers
local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if message == "cookie" then
		if player:getStorageValue(Storage.Quest.U8_4.BloodBrothers.Mission02) == 1 and player:getItemCount(8199) > 0 and player:getStorageValue(Storage.Quest.U8_4.BloodBrothers.Cookies.Serafin) < 0 then
			npcHandler:say("Oh, no I don't sell cookies. Or, do you mean you'd like to give me one?", npc, creature)
			npcHandler:setTopic(playerId, 1)
		else
			-- FAMILY: TibiaWiki EN transcript for a player who did not give him a cookie (upstream: always the angry line)
			if player:getStorageValue(Storage.Quest.U8_4.BloodBrothers.Cookies.Serafin) >= 1 then
				npcHandler:say("It'd be better for you to leave now.", npc, creature)
			else
				npcHandler:say("Oh, no I don't sell cookies.", npc, creature)
			end
		end
	elseif message == "yes" then
		if npcHandler:getTopic(playerId) == 1 and player:removeItem(8199, 1) then -- garlic cookie
			npcHandler:say("COUGH?! What kind of a mean trick is that? Get out of my shop!", npc, creature)
			player:setStorageValue(Storage.Quest.U8_4.BloodBrothers.Cookies.Serafin, 1)
			npcHandler:setTopic(playerId, 0)
		end
	end
end
--Basic
-- FAMILY: TibiaWiki EN transcript (upstream had only "alori mort")
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "I'm Serafin, pleased to meet you." })
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "Oh, I'm selling fruits and veggies as you can see. If you want to have a closer look, ask me for a {trade}." })
keywordHandler:addKeyword({ "quest" }, StdModule.say, { npcHandler = npcHandler, text = "Sorry, but I already have a delivery boy." })
keywordHandler:addKeyword({ "mission" }, StdModule.say, { npcHandler = npcHandler, text = "Sorry, but I already have a delivery boy." })
keywordHandler:addKeyword({ "quarter" }, StdModule.say, { npcHandler = npcHandler, text = "Well, actually this is not a quarter but the city centre." })
keywordHandler:addKeyword({ "blood" }, StdModule.say, { npcHandler = npcHandler, text = "This is a fruit store. No slaughterhouse." })
keywordHandler:addKeyword({ "garlic" }, StdModule.say, { npcHandler = npcHandler, text = "I'm so sorry, but I don't sell garlic." })
keywordHandler:addKeyword({ "vampire" }, StdModule.say, { npcHandler = npcHandler, text = "I don't know what you're talking about." })
keywordHandler:addKeyword({ "augur" }, StdModule.say, { npcHandler = npcHandler, text = "They are desperately trying to get the city under control. I don't envy them." })
keywordHandler:addKeyword({ "armenius" }, StdModule.say, { npcHandler = npcHandler, text = "I think he runs a bar in the former trade quarter." })
keywordHandler:addKeyword({ "julius" }, StdModule.say, { npcHandler = npcHandler, text = "I think that poor guy has serious trust issues... must be hard if you are obsessed with the idea that everyone is your enemy or a monster." })
keywordHandler:addKeyword({ "lisander" }, StdModule.say, { npcHandler = npcHandler, text = "Oh yes, I see him often. Nice guy." })
keywordHandler:addKeyword({ "maris" }, StdModule.say, { npcHandler = npcHandler, text = "A man of the seas." })
keywordHandler:addKeyword({ "ortheus" }, StdModule.say, { npcHandler = npcHandler, text = "I like him, but unfortunately I don't have much time to chat with him anymore." })
keywordHandler:addKeyword({ "yalahar" }, StdModule.say, { npcHandler = npcHandler, text = "Oh, this lovely city is a great place to live and to do business." })
npcHandler:setMessage(MESSAGE_FAREWELL, "Good bye, my dear customer.")
keywordHandler:addKeyword({ "alori mort" }, StdModule.say, { npcHandler = npcHandler, text = "There's something about these words which makes me feel awkward. Or maybe it's you who causes that feeling. You better get lost." }, function(player)
	return player:getStorageValue(Storage.Quest.U8_4.BloodBrothers.Mission03) == 1
end)

npcHandler:setMessage(MESSAGE_GREET, "Welcome to my fruit and vegetable store, |PLAYERNAME|! Ask me for a {trade} if you'd like to see my wares.")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {
	{ itemName = "aubergine", clientId = 11460, buy = 8 },
	{ itemName = "banana", clientId = 3587, buy = 5 },
	{ itemName = "blueberry", clientId = 3588, buy = 1 },
	{ itemName = "carrot", clientId = 3595, buy = 3 },
	{ itemName = "cherry", clientId = 3590, buy = 1 },
	{ itemName = "corncob", clientId = 3597, buy = 3 },
	{ itemName = "grapes", clientId = 3592, buy = 3 },
	{ itemName = "juice squeezer", clientId = 5865, buy = 100 },
	{ itemName = "lemon", clientId = 8013, buy = 3 },
	{ itemName = "mango", clientId = 5096, buy = 10 },
	{ itemName = "melon", clientId = 3593, buy = 10 },
	{ itemName = "orange", clientId = 3586, buy = 10 },
	{ itemName = "potato", clientId = 8010, buy = 4 },
	{ itemName = "pumpkin", clientId = 3594, buy = 10 },
	{ itemName = "strawberry", clientId = 3591, buy = 2 },
	{ itemName = "white mushroom", clientId = 3723, buy = 10 },
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
