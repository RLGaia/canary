-- FAMILY: Shadows of Yalahar Quest (2026-11-27): the Golem Servant of the Yalahari complex beneath Fenrock (TibiaWiki EN
-- position and transcript). Ours: upstream had no such NPC; the worker golem look is ours (Rodrigo agreed).
-- The repair talk is in lib/others/family_shadows_of_yalahar.lua (FamilyShadowsYalahar.servant).
local internalNpcName = "Golem Servant"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0

npcConfig.outfit = {
	lookType = 304,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.voices = {
	interval = 15000,
	chance = 30,
	{ text = "Failure is not an option!" }, -- TibiaWiki EN
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
	if FamilyShadowsYalahar and npcHandler:checkInteraction(npc, creature) and FamilyShadowsYalahar.servant(npc, creature, message, npcHandler) then
		return
	end
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

keywordHandler:addKeyword({ "here" }, StdModule.say, { npcHandler = npcHandler, text = "I am a servant and maintenance golem. I also operate the {lift}." })
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I am a servant and maintenance golem. I also operate the lift." })
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "I require no name." })

npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
	local player = Player(creature)
	if player and FamilyShadowsYalahar then
		npcHandler:setMessage(MESSAGE_GREET, FamilyShadowsYalahar.servantGreeting(player))
		if FamilyShadowsYalahar.get(player, "ServantItem") > 0 then
			npcHandler:setTopic(player:getId(), FamilyShadowsYalahar.TOPIC + 11)
		end
	end
	return true
end)
npcHandler:setMessage(MESSAGE_GREET, "Greetings! What brings you {here}?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Ending communication.") -- ours
npcHandler:setMessage(MESSAGE_WALKAWAY, "Ending communication.") -- ours
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
