-- FAMILY: Gaia Family server (ours, 2026-11-09): Dal the Huntress, the huntress of Bounac (YSELDA: 20 deer; trades only with the Hero of Bounac).
-- The Order of the Lion Quest: dialogue in lib/others/family_order_of_the_lion.lua, placement (day and
-- night spots from TibiaWiki BR) in scripts/family/order_of_the_lion.lua. Upstream had no such NPC.
-- Outfit ours (the wikis do not give it); trade list from TibiaWiki EN.
local internalNpcName = "Dal the Huntress"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "Dal the Huntress"
npcConfig.description = "Dal the Huntress"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 137,
	lookHead = 78,
	lookBody = 101,
	lookLegs = 120,
	lookFeet = 114,
	lookAddons = 3,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.shop = {
	{ itemName = "ape fur", clientId = 5883, sell = 120 },
	{ itemName = "badger fur", clientId = 10299, sell = 15 },
	{ itemName = "black wool", clientId = 11448, sell = 300 },
	{ itemName = "blue piece of cloth", clientId = 5912, sell = 200 },
	{ itemName = "brown piece of cloth", clientId = 5913, sell = 100 },
	{ itemName = "bunch of troll hair", clientId = 9689, sell = 30 },
	{ itemName = "downy feather", clientId = 11684, sell = 20 },
	{ itemName = "earflap", clientId = 17819, sell = 40 },
	{ itemName = "frost giant pelt", clientId = 9658, sell = 160 },
	{ itemName = "ghostly tissue", clientId = 9690, sell = 90 },
	{ itemName = "gloom wolf fur", clientId = 22007, sell = 70 },
	{ itemName = "green dragon leather", clientId = 5877, sell = 100 },
	{ itemName = "green piece of cloth", clientId = 5910, sell = 200 },
	{ itemName = "lion's mane", clientId = 9691, sell = 60 },
	{ itemName = "lizard leather", clientId = 5876, sell = 150 },
	{ itemName = "minotaur leather", clientId = 5878, sell = 80 },
	{ itemName = "piece of crocodile leather", clientId = 10279, sell = 15 },
	{ itemName = "red dragon leather", clientId = 5948, sell = 200 },
	{ itemName = "red piece of cloth", clientId = 5911, sell = 300 },
	{ itemName = "shaggy tail", clientId = 10407, sell = 25 },
	{ itemName = "silky fur", clientId = 10292, sell = 35 },
	{ itemName = "skunk tail", clientId = 10274, sell = 50 },
	{ itemName = "snake skin", clientId = 9694, sell = 400 },
	{ itemName = "spool of yarn", clientId = 5886, sell = 1000 },
	{ itemName = "striped fur", clientId = 10293, sell = 50 },
	{ itemName = "thick fur", clientId = 10307, sell = 150 },
	{ itemName = "warwolf fur", clientId = 10318, sell = 30 },
	{ itemName = "werewolf fur", clientId = 10317, sell = 380 },
	{ itemName = "white piece of cloth", clientId = 5909, sell = 100 },
	{ itemName = "winter wolf fur", clientId = 10295, sell = 20 },
	{ itemName = "wool", clientId = 10319, sell = 15 },
	{ itemName = "yellow piece of cloth", clientId = 5914, sell = 150 },
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

local function greetCallback(npc, creature)
	local player = Player(creature)
	local text = player and FamilyLion and FamilyLion.greeting("dal", player)
	npcHandler:setMessage(MESSAGE_GREET, text or "Hello, |PLAYERNAME|.")
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyLion then
		FamilyLion.onSay("dal", npc, creature, player, message, npcHandler)
	end
	return true
end

-- trades only with the Hero of Bounac (TibiaWiki BR/EN)
local function onTradeRequest(npc, creature)
	local player = Player(creature)
	if player and FamilyLion and not FamilyLion.canTrade(player) then
		FamilyLion.tradeRefused(npc, creature, npcHandler)
		return false
	end
	return true
end
npcHandler:setCallback(CALLBACK_ON_TRADE_REQUEST, onTradeRequest)
npcHandler:setMessage(MESSAGE_SENDTRADE, "Have a look.")

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Farewell, |PLAYERNAME|.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
