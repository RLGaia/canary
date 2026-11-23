-- Gaia Family server: Lesh the Seer (Adventures of Galthen, Galthen and the Lost Queen), 2026-11-23. Ours: upstream
-- had no such NPC. In his hut in the mountains of Bounac (TibiaWiki BR 32406,32471,6). Talk: lib/others/family_galthen.lua. Outfit ours (the wikis give none).
local internalNpcName = "Lesh the Seer"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 130,
	lookHead = 95,
	lookBody = 114,
	lookLegs = 95,
	lookFeet = 114,
	lookAddons = 1,
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

local function greetCallback(npc, creature)
	local player = Player(creature)
	local text = player and FamilyGalthen and FamilyGalthen.leshGreetingFor(player)
	if type(text) == "table" then
		-- a long greeting: the first line now, the rest right after
		npcHandler:setMessage(MESSAGE_GREET, text[1])
		local rest = {}
		for i = 2, #text do
			rest[#rest + 1] = text[i]
		end
		local npcId, playerId = npc:getId(), creature:getId()
		addEvent(function()
			local n, p = Npc(npcId), Player(playerId)
			if n and p then
				npcHandler:say(rest, n, p)
			end
		end, 1500)
	else
		npcHandler:setMessage(MESSAGE_GREET, text or "Greetings.")
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not player or not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyGalthen and FamilyGalthen.leshSay then
		return FamilyGalthen.leshSay(npc, creature, player, message, npcHandler)
	end
	return false
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "May your sight stay clear.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "May your sight stay clear.")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
