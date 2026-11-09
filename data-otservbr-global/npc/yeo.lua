-- Gaia Family server: Yeo, the fisherman of the Rathleton harbour (2026-11-08). Missing upstream;
-- he trades gloo for shrimp in The Gloud Ship (Oramond Quest) and takes an airtight cloth for
-- Publicity. Position from TibiaWiki EN (131.124|124.246|7); his lines are in
-- lib/others/family_oramond_tasks.lua (switch Family.oramondTasks).

local internalNpcName = "Yeo"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 128, -- ours: a citizen in fisherman colours (Yeo is missing upstream)
	lookHead = 78,
	lookBody = 86,
	lookLegs = 87,
	lookFeet = 114,
	lookAddons = 0,
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

if FamilyOramondTasks then
	FamilyOramondTasks.setupYeo(npcHandler)
end

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
