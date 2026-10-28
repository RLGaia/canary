-- FAMILY: Gaia Family server (ours, 2026-10-28): Heliodor, king of the werelions for the Grimvale Quest mission
-- An Ancient Feud (lib/others/family_ancient_feud.lua). Upstream had no such NPC.
-- Position from TibiaWiki EN (129.111,126.70,12 = 33135,32326,12); spawn in world/otservbr-npc.xml.
local internalNpcName = "Heliodor"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1301,
	lookHead = 58,
	lookBody = 2,
	lookLegs = 94,
	lookFeet = 10,
	lookAddons = 3,
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
		FamilyAncientFeud.onSay("heliodor", npc, creature, player, message, npcHandler)
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "A human, here? Speak quickly.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Leave this place.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Leave this place.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
