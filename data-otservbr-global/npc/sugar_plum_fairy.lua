-- Gaia Family server (2026-11-22): Sugar Plum Fairy, regent of Candia (Sweet Dreams). Ours, not upstream (Canary has no Candia NPC); the
-- outfit is ours (the wikis give none). Talk: lib/others/family_sweet_dreams.lua (FamilySweetDreams).
local internalNpcName = "Sugar Plum Fairy"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "Sugar Plum Fairy"
npcConfig.description = "Sugar Plum Fairy"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1747,
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
	{ text = "Sweets for everyone!" },
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
	FamilySweetDreams.setupNpc("Sugar Plum Fairy", npcHandler)
end

-- npcType registering the npcConfig table
npcType:register(npcConfig)
