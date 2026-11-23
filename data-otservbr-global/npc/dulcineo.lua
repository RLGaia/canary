-- Gaia Family server (2026-11-22): Dulcineo, the Sugar Plum Fairy's faun (Sweet Dreams). Ours, not upstream (Canary has no Candia NPC); the
-- outfit is ours (the wikis give none). Talk: lib/others/family_sweet_dreams.lua (FamilySweetDreams).
local internalNpcName = "Dulcineo"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "Dulcineo"
npcConfig.description = "Dulcineo"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 980,
	lookHead = 86,
	lookBody = 79,
	lookLegs = 79,
	lookFeet = 86,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "It's like tilting at windmills." },
	{ text = "There must be a way to resolve these disagreements." },
	{ text = "Ah, the Candy Carnival ... one of the best festivities in Candia." },
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
	FamilySweetDreams.setupNpc("Dulcineo", npcHandler)
end

-- npcType registering the npcConfig table
npcType:register(npcConfig)
