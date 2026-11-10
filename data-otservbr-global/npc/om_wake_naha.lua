-- FAMILY: Om'Wake Naha, supplies and trade of Rascacoon (A Pirate's Tail Quest, 2026-11-10). Ours, not
-- upstream (Canary v3.6.1 has no such NPC). Lines from the TibiaWiki BR NPC page and quest page; lines
-- marked "ours" are not in the wikis. Look ours (a rascoohan in orange and green, matched to the BR image).
-- The supply mission itself (the teleport next to him, the cheese cellar) is part 2b.
local internalNpcName = "Om'Wake Naha"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1371,
	lookHead = 0,
	lookBody = 78,
	lookLegs = 82,
	lookFeet = 82,
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

-- TibiaWiki BR NPC page
local lines = {
	{ "name", "My name is Om'Wake Naha, which translates into 'has many things' in your language." },
	{ "job", "I am responsible for {supplies} and trade of the {colony}." },
	{ "supplies", "Pesky ratmen are constantly raiding our cheese supplies. I could use a {helping} hand or two, to get rid of this problem." },
	{ "helping", "The pirats use transformation magic to enter my cheese cellar as rats and they devour and steal our precious {cheese}." },
	{ "cheese", "Push as many cheese as you can into the cheese larder in the center of the cellar. Use the staffs that our shaman supplied to dispel the disguise of the rats to fight the intruders." },
	{ "washingstone", "It's only an old story. Our tribe left that place generations ago." },
	{ "colony", "Our town, {Rascacoon}, is just a colony. Our {ancestors} came here from a place far away on a journey to see the all wonders the world has to offer." },
	{ "rascacoon", "We face many hardships and hazards but our people are resourceful and until the pirats showed up our colony was thriving." },
	{ "ancestors", "After several years of travel and hardships our ancestors {settled} here." },
	{ "settled", "One {day}, when our colony is huge and striving, some of the young ones will go on their own journey and after a long travel will build their own colony." },
	{ "day", "This day is still far away. There is still space enough and so much to be accomplished that no one gets bored." },
}

local function creatureSayCallback(npc, creature, type, message)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	for _, entry in ipairs(lines) do
		if MsgContains(message, entry[1]) then
			npcHandler:say(entry[2], npc, creature)
			return true
		end
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Hello, traveller! Be welcome!") -- BR
npcHandler:setMessage(MESSAGE_FAREWELL, "Good bye, traveller.") -- ours
npcHandler:setMessage(MESSAGE_WALKAWAY, "Good bye, traveller.") -- ours
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
