-- Gaia Family server: Innkeeper Alphonse (Adventures of Galthen, Galthen and the Lost Queen), 2026-11-23. Ours: upstream
-- had no such NPC. In the Lionheart inn of Bounac (TibiaWiki EN 32417,32501,7). Talk: lib/others/family_galthen.lua. Outfit ours (the wikis give none).
local internalNpcName = "Innkeeper Alphonse"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 128,
	lookHead = 78,
	lookBody = 79,
	lookLegs = 76,
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

local function greetCallback(npc, creature)
	local player = Player(creature)
	local text = player and FamilyGalthen and FamilyGalthen.alphonseGreeting(player)
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
		npcHandler:setMessage(MESSAGE_GREET, text or "Welcome, customer! Enjoy a hot meal, fine cheese or a glass of wine!")
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not player or not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if FamilyGalthen and FamilyGalthen.alphonseSay then
		return FamilyGalthen.alphonseSay(npc, creature, player, message, npcHandler)
	end
	return false
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Come back soon!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Come back soon!")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
