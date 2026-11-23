-- Gaia Family server (2026-11-22): a roleplay NPC of Candia (Sweet Dreams). Ours, not upstream; place, greeting
-- and sounds from TibiaWiki BR (33355,32170,7); the look is the sugar cube worker's (EN's picture).
-- Talk: lib/others/family_sweet_dreams.lua (FamilySweetDreams).
local internalNpcName = "A Stressed Sugar Cube Worker"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "A Stressed Sugar Cube Worker"
npcConfig.description = "A Stressed Sugar Cube Worker"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 3000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 1756,
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
	{ text = "No ... no no no, won't work." },
	{ text = "Like this? No, this will cause the mechanism to jam." },
	{ text = "This has to work ... somehow." },
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

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

if FamilySweetDreams then
	FamilySweetDreams.setupNpc("A Stressed Sugar Cube Worker", npcHandler)
end

-- npcType registering the npcConfig table
npcType:register(npcConfig)
