-- Gaia Family server (2026-11-22): a roleplay NPC of Candia (Sweet Dreams). Ours, not upstream; place, greeting
-- and sounds from TibiaWiki BR (33351,32167,7); the look is the tainted soul that BR shows for it.
-- Talk: lib/others/family_sweet_dreams.lua (FamilySweetDreams).
local internalNpcName = "A Floating Sugar Ball"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "A Floating Sugar Ball"
npcConfig.description = "A Floating Sugar Ball"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 3000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 712,
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
	{ text = "*hummmm*" },
	{ text = "*buzzzz*" },
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
	FamilySweetDreams.setupNpc("A Floating Sugar Ball", npcHandler)
end

-- npcType registering the npcConfig table
npcType:register(npcConfig)
