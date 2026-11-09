-- FAMILY: Gaia Family server (ours, 2026-11-09): Evrard the Miller, the miller north of Bounac who starts The Order of the Lion (day only).
-- The Order of the Lion Quest: dialogue in lib/others/family_order_of_the_lion.lua, placement (day and
-- night spots from TibiaWiki BR) in scripts/family/order_of_the_lion.lua. Upstream had no such NPC.
-- Outfit ours (the wikis do not give it).
local internalNpcName = "Evrard the Miller"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "Evrard the Miller"
npcConfig.description = "Evrard the Miller"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 128,
	lookHead = 58,
	lookBody = 20,
	lookLegs = 39,
	lookFeet = 76,
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

local function greetCallback(npc, creature)
	local player = Player(creature)
	local text = player and FamilyLion and FamilyLion.greeting("evrard", player)
	npcHandler:setMessage(MESSAGE_GREET, text or "Hello, |PLAYERNAME|.")
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyLion then
		FamilyLion.onSay("evrard", npc, creature, player, message, npcHandler)
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Farewell, |PLAYERNAME|.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
