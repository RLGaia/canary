-- Gaia Family server: A Wandering Soul (2026-11-02). Ours: not in upstream Canary v3.6.1.
-- Blood Brothers Quest, Mission 05: he charges a blood crystal when you say "blood crystal"
-- (lines and sounds from TibiaWiki EN; the haunted ruin in north-western Vengoth). Like in Tibia,
-- only characters on that step of the mission can charge (also crystals for a friend, one per
-- "blood crystal"); the first charge gives the Ghostwhisperer achievement (TibiaWiki EN; BR says
-- there is a chance, ours: always).
local internalNpcName = "A Wandering Soul"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 48,
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
	{ text = "Ooooh... the sadness..." },
	{ text = "Leave me alone in my mourning..." },
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
	local B = FamilyBloodBrothers
	if B and B.hasBit(player, B.S.Finds, B.F_CHARGED) then
		npcHandler:setMessage(MESSAGE_GREET, "You... again... leave me finally alone in my mourning...") -- TibiaWiki EN
	else
		npcHandler:setMessage(MESSAGE_GREET, "I saw you... who are you... what do you want from me...?") -- TibiaWiki EN
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not player then
		return false
	end
	local B = FamilyBloodBrothers
	local msg = message:lower()
	if MsgContains(msg, "blood") and MsgContains(msg, "crystal") then
		local m5 = B and Family.bloodBrothers and B.get(player, B.S.Mission05) or 0
		if (m5 == 2 or m5 == 3) and player:getItemCount(B.CRYSTAL) > 0 then
			local crystal = player:getItemById(B.CRYSTAL, true)
			if crystal then
				crystal:transform(B.CRYSTAL_CHARGED)
				crystal:decay()
			end
			npcHandler:say("What the...? I don't know anything about that... still... the pain felt a little less intense for a second... relieving... but will never be gone.", npc, creature)
			B.setBit(player, B.S.Finds, B.F_CHARGED)
			player:addAchievement("Ghostwhisperer")
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
		else
			npcHandler:say("What the...? I don't know anything about that...", npc, creature) -- first part of his line (ours)
		end
		return true
	elseif MsgContains(msg, "mission") then
		npcHandler:say("... what do you want from me...?", npc, creature) -- ours
		return true
	end
	return true
end

keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "... I don't remember... leave me alone in my mourning..." }) -- ours

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Leave me alone in my mourning...")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Ooooh... the sadness...")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
