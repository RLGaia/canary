-- Gaia Family server (2026-11-22): Coco, the shopkeeper at the Candy Carnival (Sweet Dreams). Ours, not upstream;
-- place, goods and prices from TibiaWiki BR (33372,32179,7; EN 33372,32181). She sells for milk chocolate coins
-- and for dark chocolate coins, one list per coin (lib: SD.COCO). Greeting and look are ours (the wikis give no
-- line; outfit: a fae). Talk: lib/others/family_sweet_dreams.lua (FamilySweetDreams).
local internalNpcName = "Coco"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "Coco"
npcConfig.description = "Coco"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 982,
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
	{ text = "Candy furniture for your home!" },
	{ text = "Sweet gear for milk and dark chocolate coins!" },
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

-- The shop window (one list per coin) is opened by the lib; a purchase is checked there.
npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	if FamilySweetDreams then
		FamilySweetDreams.cocoBuy(npc, player, itemId, subType, amount, ignore, inBackpacks)
	end
end
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost) end
npcType.onCheckItem = function(npc, player, clientId, subType) end

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

if FamilySweetDreams then
	FamilySweetDreams.setupNpc("Coco", npcHandler, {
		onTrade = function(npc, player)
			npcHandler:say(FamilySweetDreams.COCO.trade, npc, player)
			return false
		end,
	})
end

-- npcType registering the npcConfig table
npcType:register(npcConfig)
