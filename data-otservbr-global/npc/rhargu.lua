-- FAMILY: Gaia Family server (ours, 2026-10-28): Rhargu, the leader of the werehyaenas for the Grimvale Quest mission
-- An Ancient Feud (lib/others/family_ancient_feud.lua). Upstream had no such NPC.
-- Position from TibiaWiki EN (129.147,127.24,12 = 33171,32536,12); spawn in world/otservbr-npc.xml.
local internalNpcName = "Rhargu"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1300,
	lookHead = 57,
	lookBody = 77,
	lookLegs = 1,
	lookFeet = 1,
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

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyAncientFeud then
		FamilyAncientFeud.onSay("rhargu", npc, creature, player, message, npcHandler)
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "Grrr! A human! What do you want?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Grrr.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Grrr.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
