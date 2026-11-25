-- Gaia Family server: Casper, Kurik's jester (Last Creep Standing), 2026-11-25. Ours: upstream had no such NPC.
-- In his room under the north entrance of Darashia (TibiaWiki EN 33261,32364,9). Rhymes from the EN
-- transcripts; `change`, `reward` and `start` in lib/others/family_last_creep.lua. Outfit ours (a jester).
local internalNpcName = "Casper"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0

npcConfig.outfit = {
	lookType = 273,
	lookHead = 86,
	lookBody = 94,
	lookLegs = 79,
	lookFeet = 114,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

local function creatureSayCallback(npc, creature, type, message)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyLastCreep and FamilyLastCreep.casper(npc, creature, message, npcHandler) then
		return true
	end
	return true
end

-- EN transcripts
keywordHandler:addKeyword({ "meetings" }, StdModule.say, { npcHandler = npcHandler, text = "To guide you in this {challenge} I was sent, {Kurik} asked me to and so I went." })
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "To guide you in this {challenge} I was sent, {Kurik} asked me to and so I went." })
keywordHandler:addKeyword({ "challenge" }, StdModule.say, { npcHandler = npcHandler, text = "Down {below} awaits you a quest. Soon we will learn who is the {best}." })
keywordHandler:addKeyword({ "below" }, StdModule.say, { npcHandler = npcHandler, text = "Go down now and be attentive and quick. With the slow ones kicked out, only the {fastest} will stick." })
keywordHandler:addKeyword({ "fastest" }, StdModule.say, { npcHandler = npcHandler, text = "If you are cunning and act smart, you might be lucky and get a {reward}." })
keywordHandler:addKeyword({ "best" }, StdModule.say, { npcHandler = npcHandler, text = "{Change} you will and run around. Find your match or return to the ground." })
keywordHandler:addKeyword({ "kurik" }, StdModule.say, { npcHandler = npcHandler, text = "Kurik the genius, Kurik the mad. Is the world hollow or is the world flat?" })
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "I'm a jester, I'm a fool. I have no name, though it'd be cool." })
keywordHandler:addKeyword({ "rhyme" }, StdModule.say, { npcHandler = npcHandler, text = "A charming smile and a rhyme on my lips, I'll give the fools a few answers and tips." })

npcHandler:setMessage(MESSAGE_GREET, "Hello and greetings! How I love our {meetings}!")
npcHandler:setMessage(MESSAGE_FAREWELL, "Goodbye to you, our meeting was cool. I yet have to guess if you or me is the fool.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Goodbye to you, our meeting was cool. I yet have to guess if you or me is the fool.")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
