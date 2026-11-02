local internalNpcName = "A Fading Memory"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 138,
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
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

-- FAMILY: Blood Brothers Quest, Mission 10 (TibiaWiki EN transcript: hi, Kala, diary, yes, vampire,
-- free soul, awaken). Upstream had only the greeting and no spawn; she gives the ghost's tear.
local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not player then
		return false
	end
	local playerId = player:getId()
	local msg = message:lower()
	if MsgContains(msg, "kala") then
		npcHandler:say("... yes! That's my name... how come you know that?", npc, creature)
		npcHandler:setTopic(playerId, 1)
	elseif MsgContains(msg, "diary") then
		npcHandler:say("... you... read Marziel's diary and know our story...?", npc, creature)
		npcHandler:setTopic(playerId, 2)
	elseif MsgContains(msg, "yes") and npcHandler:getTopic(playerId) == 2 then
		npcHandler:say("... then... tell me... I'm so sad... was it my fault? Why did he leave me... Arthei..?", npc, creature)
		npcHandler:setTopic(playerId, 3)
	elseif MsgContains(msg, "vampire") then
		npcHandler:say("... so there is nothing I could have done...? He's a vampire now... what can we do...", npc, creature)
		npcHandler:setTopic(playerId, 4)
	elseif MsgContains(msg, "free") and MsgContains(msg, "soul") then
		npcHandler:say("... he can't be freed from his curse that easily... he must be awaken first...", npc, creature)
		npcHandler:setTopic(playerId, 5)
	elseif MsgContains(msg, "awaken") or MsgContains(msg, "awake") then
		local B = FamilyBloodBrothers
		local onMission = B and Family.bloodBrothers and B.get(player, B.S.Mission10) == 1
		if onMission and player:getItemCount(B.GHOST_TEAR) < 1 then
			npcHandler:say("... to awake him... I don't know but... he once truly loved me... maybe there is still something left... somewhere... here... take this from me....and thank you for listening...", npc, creature)
			player:addItem(B.GHOST_TEAR, 1)
			B.setBit(player, B.S.Finds, B.F_TEAR)
		else
			npcHandler:say("... to awake him... I don't know but... he once truly loved me... maybe there is still something left... somewhere... here...", npc, creature) -- the line without the tear (ours)
		end
		npcHandler:setTopic(playerId, 0)
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Ohh...") -- FAMILY: TibiaWiki BR/EN ("Oh..." upstream)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
