local npcName = "John"
local npcType = Game.createNpcType("John (Bounac)")
local npcConfig = {}

npcConfig.name = npcName
npcConfig.description = npcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1245,
	lookHead = 40,
	lookBody = 0,
	lookLegs = 99,
	lookFeet = 28,
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

-- FAMILY: Adventures of Galthen (lib/others/family_galthen.lua): his greeting by day and night, `yselda`
-- for the first Royal Bounacean Advisor addon (Kesar's permission), and the carpets only after it
-- (`fragments`; BR). Upstream sold them to anyone and had no talk.
npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
	npcHandler:setMessage(MESSAGE_GREET, FamilyGalthen and FamilyGalthen.johnGreeting() or "Hello.")
	return true
end)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
	local player = Player(creature)
	if not player or not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	return FamilyGalthen and FamilyGalthen.johnSay(npc, creature, player, message, npcHandler) or false
end)
npcHandler:setCallback(CALLBACK_ON_TRADE_REQUEST, function(npc, creature)
	local player = Player(creature)
	if player and FamilyGalthen and not FamilyGalthen.canTradeJohn(player) then
		npcHandler:say("I'm on vacation, I'm not selling anything right now.", npc, creature) -- ours
		return false
	end
	return true
end)
npcHandler:setMessage(MESSAGE_FAREWELL, "Good night.") -- ours
npcHandler:setMessage(MESSAGE_WALKAWAY, "Good night.") -- ours
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {
	{ clientId = 36951, buy = 10000 },
	{ clientId = 36952, buy = 10000 },
	{ clientId = 36953, buy = 10000 },
	{ clientId = 36954, buy = 10000 },
	{ clientId = 36955, buy = 10000 },
	{ clientId = 36956, buy = 10000 },
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
