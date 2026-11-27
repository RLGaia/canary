local internalNpcName = "Guardian of the Deep Seas"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 383,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
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
	-- FAMILY: Twenty Miles Beneath the Sea Quest (lib/others/family_twenty_miles.lua)
	if FamilyTwentyMiles and npcHandler:checkInteraction(npc, creature) and FamilyTwentyMiles.guardian(npc, creature, message, npcHandler) then
		return
	end
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

-- FAMILY: Twenty Miles Beneath the Sea Quest (2026-11-27): greeting (TibiaWiki BR/EN); the job line is ours
npcHandler:setMessage(MESSAGE_GREET, "Who goes there? What do you disturb the quiet of the abyss for?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Tread lightly.") -- ours
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I guard the deep seas and the dreams of the Fire-Feathered Serpent." }) -- ours
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
