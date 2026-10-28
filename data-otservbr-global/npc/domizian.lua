-- FAMILY: Gaia Family server (ours, 2026-10-28): Domizian, an exiled werelion in human form for the Grimvale Quest mission
-- An Ancient Feud (lib/others/family_ancient_feud.lua). Upstream had no such NPC.
-- Position from TibiaWiki EN (129.238,126.207,6 = 33262,32463,6); spawn in world/otservbr-npc.xml.
local internalNpcName = "Domizian"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 146,
	lookHead = 78,
	lookBody = 79,
	lookLegs = 78,
	lookFeet = 114,
	lookAddons = 1,
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
		FamilyAncientFeud.onSay("domizian", npc, creature, player, message, npcHandler)
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "Greetings, |PLAYERNAME|. What brings you to my humble home?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Farewell, |PLAYERNAME|.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
