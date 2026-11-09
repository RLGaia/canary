-- FAMILY: Gaia Family server (ours, 2026-11-09): Jehan the Baker, the baker of Bounac (YSELDA: 10 breads; trades only with the Hero of Bounac).
-- The Order of the Lion Quest: dialogue in lib/others/family_order_of_the_lion.lua, placement (day and
-- night spots from TibiaWiki BR) in scripts/family/order_of_the_lion.lua. Upstream had no such NPC.
-- Outfit ours (the wikis do not give it); trade list from TibiaWiki EN.
local internalNpcName = "Jehan the Baker"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "Jehan the Baker"
npcConfig.description = "Jehan the Baker"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 128,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 57,
	lookFeet = 114,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.shop = {
	{ itemName = "bread", clientId = 3600, buy = 10, sell = 1 },
	{ itemName = "cake", clientId = 6277, buy = 50 },
	{ itemName = "cookie", clientId = 3598, buy = 2 },
	{ itemName = "egg", clientId = 3606, buy = 2 },
	{ itemName = "red apple", clientId = 3585, buy = 3 },
	{ itemName = "roll", clientId = 3601, buy = 8, sell = 1 },
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
	local text = player and FamilyLion and FamilyLion.greeting("jehan", player)
	npcHandler:setMessage(MESSAGE_GREET, text or "Hello, |PLAYERNAME|.")
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyLion then
		FamilyLion.onSay("jehan", npc, creature, player, message, npcHandler)
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
