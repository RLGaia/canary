local internalNpcName = "Iriana"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 264,
	lookHead = 78,
	lookBody = 116,
	lookLegs = 95,
	lookFeet = 121,
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

-- FAMILY: Top of the City Quest (2026-10-25; scripts/family/top_of_the_city.lua).
-- Lines from TibiaWiki's transcripts: "I went inside my house just for a
-- second.", "Ask me for a quest if you are willing to help me.", the lost-track
-- greeting, the "notes" answer and "You're my hero!". The rest is ours.
local function greetCallback(npc, creature)
	local player = Player(creature)
	local state = FamilyTopOfTheCity and FamilyTopOfTheCity.state(player) or -1
	if state == 1 then
		npcHandler:setMessage(MESSAGE_GREET, "What happened?! Did you lose track of him? I'm sure he'll come back, he always does. Try to track him down from here once more.")
	elseif state == 3 then
		npcHandler:setMessage(MESSAGE_GREET, "You're back! Did you get my {chest}? Tell me about the {quest}!")
	else
		npcHandler:setMessage(MESSAGE_GREET, "Hello |PLAYERNAME|. Ask me for a {quest} if you are willing to help me. Or do you want to {trade}?")
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not player then
		return false
	end
	local playerId = player:getId()
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	local F = FamilyTopOfTheCity
	if not F or not Family.topOfTheCity then
		return false
	end
	local state = F.state(player)
	local topic = npcHandler:getTopic(playerId)

	if MsgContains(message, "quest") or MsgContains(message, "mission") or MsgContains(message, "chest") then
		if state < 1 then
			npcHandler:say({
				"I went inside my house just for a second. When I came back, my chest with the whole day's earnings was gone! ...",
				"A masked man ran up to my roof and off over the rooftops. He is quick, but he always shows himself for a moment, as if he wanted to be followed. ...",
				"Will you go after him and bring my chest back?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 1)
		elseif state == 1 or state == 2 then
			npcHandler:say("I've seen you writing down what needs to be done. Take a look at your notes instead of bothering me.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		elseif state == 3 then
			if F.finish(player) then
				npcHandler:say({
					"You're my hero! ...",
					"My chest, and nothing missing! I have no gold to spare, but take these heaven blossoms from my garden. They are worth more than they look.",
				}, npc, creature)
			else
				npcHandler:say("Where is my chest? Jimmy gave it to you, didn't he? Bring it to me.", npc, creature)
			end
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say("Thanks to you I have my earnings back. I will keep my door locked from now on!", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "yes") and topic == 1 then
		F.setState(player, 1)
		npcHandler:say("Oh, thank you! Go through my house and up the stairs to the roof. Keep your eyes open, he went west. If you lose him, start again from my roof.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "no") and topic == 1 then
		npcHandler:say("Then my money is gone for good, I guess.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "jimmy") then
		npcHandler:say("Jimmy? So that's the name of the scoundrel.", npc, creature)
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {
	{ itemName = "backpack", clientId = 2854, buy = 10 },
	{ itemName = "bag", clientId = 2853, buy = 4 },
	{ itemName = "fishing rod", clientId = 3483, buy = 150 },
	{ itemName = "worm", clientId = 3492, buy = 1 },
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
