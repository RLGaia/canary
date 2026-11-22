-- Gaia Family server: A Runaway Goblin (Krailos Quest, Revolt of the Goblins), 2026-11-22. Ours: upstream
-- had no such NPC. In his hideout below the hole west of the village (world/custom/family-krailos.otbm;
-- TibiaWiki BR 33526,31671,8, EN floor 8). Talk: lib/others/family_krailos.lua.
local internalNpcName = "A Runaway Goblin"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 61,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)
if FamilyKrailos then
	FamilyKrailos.setupNpc("A Runaway Goblin", npcHandler)
end

-- npcType registering the npcConfig table
npcType:register(npcConfig)
