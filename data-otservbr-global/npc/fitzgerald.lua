-- FAMILY: Gaia Family server (ours, 2026-11-09): Fitzgerald, Fitzmaurice's brother, bathing in the pool of the Cobra Bastion (gives Fitzwilliam's Special Reserve).
-- The Order of the Lion Quest: dialogue in lib/others/family_order_of_the_lion.lua, placement (day and
-- night spots from TibiaWiki BR) in scripts/family/order_of_the_lion.lua. Upstream had no such NPC.
-- Outfit ours (the wikis do not give it).
local internalNpcName = "Fitzgerald"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = "Fitzgerald"
npcConfig.description = "Fitzgerald"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0

npcConfig.outfit = {
	lookType = 128,
	lookHead = 78,
	lookBody = 94,
	lookLegs = 94,
	lookFeet = 95,
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
	local text = player and FamilyLion and FamilyLion.greeting("fitzgerald", player)
	npcHandler:setMessage(MESSAGE_GREET, text or "Hello, |PLAYERNAME|.")
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyLion then
		FamilyLion.onSay("fitzgerald", npc, creature, player, message, npcHandler)
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell, |PLAYERNAME|.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Farewell, |PLAYERNAME|.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
