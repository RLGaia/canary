-- Gaia Family server (2026-11-22): Toffee, the cook at the Candy Carnival (Sweet Dreams). Ours, not upstream (Canary has no Candia NPC); the
-- outfit is ours (the wikis give none). Talk: lib/others/family_sweet_dreams.lua (FamilySweetDreams).
local internalNpcName = "Toffee"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "Toffee"
npcConfig.description = "Toffee"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1753,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "Buy fresh fruit for candying here!" },
	{ text = "Wafer paper flowers? Lime tart? Brigadeiros? Just bring them here, I have a use for them!" },
	{ text = "Freshly baked cakes and cookies!" },
}

npcConfig.shop = {
	{ itemName = "banana", clientId = 3587, buy = 2 },
	{ itemName = "blueberry", clientId = 3588, buy = 1 },
	{ itemName = "cake", clientId = 6277, buy = 50 },
	{ itemName = "cherry", clientId = 3590, buy = 1 },
	{ itemName = "cookie", clientId = 3598, buy = 2 },
	{ itemName = "grapes", clientId = 3592, buy = 3 },
	{ itemName = "moon melon slice", clientId = 48179, buy = 10 },
	{ itemName = "pear", clientId = 3584, buy = 4 },
	{ itemName = "plum", clientId = 8011, buy = 3 },
	{ itemName = "raspberry", clientId = 8012, buy = 1 },
	{ itemName = "red apple", clientId = 3585, buy = 3 },
	{ itemName = "strawberry", clientId = 3591, buy = 1 },
	{ itemName = "valentine's cake", clientId = 6392, buy = 30 },
	{ itemName = "beijinho", clientId = 48253, sell = 2780 },
	{ itemName = "brigadeiro", clientId = 48252, sell = 2640 },
	{ itemName = "churro heart", clientId = 48254, sell = 2680 },
	{ itemName = "lime tart", clientId = 48255, sell = 1870 },
	{ itemName = "pastry dragon", clientId = 48256, sell = 95000 },
	{ itemName = "taiyaki ice cream", clientId = 48273, sell = 6750 },
	{ itemName = "wad of fairy floss", clientId = 48544, sell = 2910 },
	{ itemName = "wafer paper flower", clientId = 48251, sell = 2350 },
} -- TibiaWiki BR

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

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

if FamilySweetDreams then
	FamilySweetDreams.setupNpc("Toffee", npcHandler)
end

-- npcType registering the npcConfig table
npcType:register(npcConfig)
