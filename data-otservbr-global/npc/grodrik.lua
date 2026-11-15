local internalNpcName = "Grodrik"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 160,
	lookHead = 96,
	lookBody = 120,
	lookLegs = 60,
	lookFeet = 116,
}

npcConfig.flags = {
	floorchange = false,
}

-- FAMILY: TibiaWiki EN sound
npcConfig.voices = {
	interval = 15000,
	chance = 30,
	{ text = "One more drink and then I'll go home to my woman. ... sigh... I forgot - I don't have a woman." },
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

-- FAMILY: The Scatterbrained Sorcerer Quest (lib/others/family_sorcerer.lua): beer, women, wishes, dating,
-- questionnaire and the "strange beer". Upstream he had no dialogue and was not placed on the map.
if FamilySorcerer then
	FamilySorcerer.setupGrodrik(keywordHandler, npcHandler)
end

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
