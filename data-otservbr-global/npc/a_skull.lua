-- FAMILY: Gaia Family server (ours, 2026-10-28): a talking skull in the Hyaena Lairs for the Grimvale Quest mission
-- An Ancient Feud (lib/others/family_ancient_feud.lua). Upstream had no such NPC.
-- Position from TibiaWiki EN (129.141,126.236,11 = 33165,32492,11); spawn in world/otservbr-npc.xml.
local internalNpcName = "A Skull"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookTypeEx = 3132,
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

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyAncientFeud then
		FamilyAncientFeud.onSay("skull", npc, creature, player, message, npcHandler)
	end
	return true
end

-- a Skull talks only at night (TibiaWiki EN); by day it stays silent
npcHandler:setCallback(CALLBACK_GREET, function(npc, creature, message)
	return not FamilyAncientFeud or FamilyAncientFeud.isNight()
end)

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "Greetings, traveller!")
npcHandler:setMessage(MESSAGE_FAREWELL, "...")
npcHandler:setMessage(MESSAGE_WALKAWAY, "...")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
