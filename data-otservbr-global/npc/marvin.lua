local internalNpcName = "Marvin"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 132,
	lookHead = 38,
	lookBody = 109,
	lookLegs = 14,
	lookFeet = 57,
	lookAddons = 2,
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

-- FAMILY: greeting by state (Dark Trails funding vote, promotion, voting); Rathleton Quest lines
-- from TibiaWiki EN "Rathleton Quest/Spoiler" (lib/others/family_rathleton.lua).
local function greetCallback(npc, creature)
	local player = Player(creature)
	if FamilyRathleton and FamilyRathleton.on() then
		FamilyRathleton.marvinReset(player)
		if player:getStorageValue(Storage.Quest.U10_50.DarkTrails.Mission07) == 1 and player:getStorageValue(Storage.Quest.U10_50.DarkTrails.Mission08) < 1 then
			npcHandler:setMessage(MESSAGE_GREET, "Ah, you come just in time for the special voting about the most recent {funding} project. I guess you want to participate in it.")
		else
			npcHandler:setMessage(MESSAGE_GREET, FamilyRathleton.greeting(player))
		end
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	-- FAMILY: the Rathleton voting (topics, status, promotion); the funding vote below stays upstream's
	local fundingTopic = npcHandler:getTopic(playerId)
	local fundingStep = MsgContains(message, "funding") or (fundingTopic == 1 and MsgContains(message, "archives")) or (fundingTopic == 2 and MsgContains(message, "1")) or (fundingTopic == 3 and MsgContains(message, "yes"))
	if FamilyRathleton and FamilyRathleton.on() and not fundingStep then
		if FamilyRathleton.marvinSay(npc, player, message, npcHandler) then
			npcHandler:setTopic(playerId, 0)
			return true
		end
	end

	-- FAMILY: real numbers instead of "x" and "topic b" (TibiaWiki EN Dark Trails transcript)
	local votesLeft = math.max(0, player:getStorageValue(Storage.Quest.U10_50.OramondQuest.VotingPoints))
	if MsgContains(message, "funding") then
		if player:getStorageValue(Storage.Quest.U10_50.DarkTrails.Mission07) == 1 and player:getStorageValue(Storage.Quest.U10_50.OramondQuest.VotingPoints) >= 1 then
			npcHandler:say({
				"So far you earned " .. votesLeft .. " votes. Each single vote can be spent on a different topic, or you can also cast all your votes on one voting. ...",
				"Well, in topic B you have the possibility to vote for the {funding} of the {archives}, import of bug {milk} or street {repairs}.",
			}, npc, creature)
			npcHandler:setTopic(playerId, 1)
		else
			npcHandler:say("You can't vote yet.", npc, creature)
		end
	elseif MsgContains(message, "archives") then
		if npcHandler:getTopic(playerId) == 1 then
			npcHandler:say("How many of your " .. votesLeft .. " votes do you want to cast?", npc, creature)
			npcHandler:setTopic(playerId, 2)
		end
	elseif MsgContains(message, "1") then
		if npcHandler:getTopic(playerId) == 2 then
			npcHandler:say("Did I get that right: You want to cast 1 of your votes on funding the {archives}?", npc, creature)
			npcHandler:setTopic(playerId, 3)
		end
	elseif MsgContains(message, "yes") then
		if npcHandler:getTopic(playerId) == 3 then
			local currentVotes = player:getStorageValue(Storage.Quest.U10_50.OramondQuest.VotingPoints)
			if currentVotes > 0 then
				player:setStorageValue(Storage.Quest.U10_50.OramondQuest.VotingPoints, currentVotes - 1)
			end
			player:setStorageValue(Storage.Quest.U10_50.DarkTrails.Mission08, 1)
			if FamilyRathleton then
				FamilyRathleton.addVotesCast(player, 1) -- FAMILY: counts for the citizen ranks
			end
			npcHandler:say("Thanks, you successfully cast your vote. Feel free to continue gathering votes by helping the city! Farewell.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	end

	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Ah, you come just in time for the special voting about the most recent {funding} project. I guess you want to participate in it.")
npcHandler:setCallback(CALLBACK_GREET, greetCallback) -- FAMILY
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
