local internalNpcName = "Mr Brandon"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 311,
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
	{ text = "<grumble> Maybe I should rearrange some warm currents to get rid of this horrible fog." },
	{ text = "All these treasures I cannot reach... what a pity." },
	-- FAMILY: TibiaWiki EN's other sounds (2026-11-27)
	{ text = "Urgh... the... THINGS. I can't forget their horrible sight." },
	{ text = "What am I to do? I can't go back." },
	{ text = "My ring! My wedding ring! <sigh>" },
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
	-- FAMILY: Twenty Miles Beneath the Sea Quest (lib/others/family_twenty_miles.lua)
	if FamilyTwentyMiles and npcHandler:checkInteraction(npc, creature) and FamilyTwentyMiles.brandon(npc, creature, message, npcHandler) then
		return
	end
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end
-- FAMILY: Twenty Miles Beneath the Sea Quest (2026-11-27): greeting per player (TibiaWiki BR/EN); upstream had none
npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
	local player = Player(creature)
	if player and FamilyTwentyMiles then
		npcHandler:setMessage(MESSAGE_GREET, FamilyTwentyMiles.brandonGreeting(player))
	end
	return true
end)
npcHandler:setMessage(MESSAGE_FAREWELL, "Take care down there.") -- ours
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
