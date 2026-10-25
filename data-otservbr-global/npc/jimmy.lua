local internalNpcName = "Jimmy"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 152,
	lookHead = 0,
	lookBody = 19,
	lookLegs = 38,
	lookFeet = 0,
	lookAddons = 3,
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

-- FAMILY: Top of the City Quest (2026-10-25; scripts/family/top_of_the_city.lua).
-- Lines from TibiaWiki's transcripts: "Get him!!" (the first greeting, when
-- he calls three Assassins), "Get me a crate of food out of his stock and bring
-- it to me. Ask me about the {quest} when you have it.", "Watch your back",
-- "Hello my friend. What's up?" and the chest line. The rest is ours.
local function greetCallback(npc, creature)
	local player = Player(creature)
	local F = FamilyTopOfTheCity
	local state = F and F.state(player) or -1
	if F and Family.topOfTheCity and state == 1 and F.callAssassins(npc, player) then
		npcHandler:setMessage(MESSAGE_GREET, "Get him!!")
	elseif state >= 2 then
		npcHandler:setMessage(MESSAGE_GREET, "Hello my friend. What's up?")
	elseif state == 1 then
		npcHandler:setMessage(MESSAGE_GREET, "You again? You're tougher than you look. What do you want? If it's about {Iriana}, spit it out.")
	else
		npcHandler:setMessage(MESSAGE_GREET, "How did you get in here? Get lost before I lose my patience.")
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not player then
		return false
	end
	local playerId = player:getId()
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	local F = FamilyTopOfTheCity
	if not F or not Family.topOfTheCity then
		return false
	end
	local state = F.state(player)
	local topic = npcHandler:getTopic(playerId)

	if MsgContains(message, "iriana") or MsgContains(message, "chest") then
		if state == 1 then
			npcHandler:say({
				"Iriana? Hah, so she sent you after me. All right, you can have her chest back. But nothing in Yalahar is for free. ...",
				"Pugwah, the tavern keeper in the inner city, has been cheating me for years. He keeps his stock in the cellar below his tavern. Nobody comes in through the tavern, but the sewers south of it run right under that cellar, and the dirt down there is soft. ...",
				"Get me a crate of food out of his stock and bring it to me. Ask me about the {quest} when you have it. Deal?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 1)
		elseif state == 2 then
			npcHandler:say("First the crate of food from Pugwah's cellar, then the chest. Ask me about the {quest} when you have it.", npc, creature)
		else
			npcHandler:say("Iriana got her chest, didn't she? We're even.", npc, creature)
		end
	elseif MsgContains(message, "quest") or MsgContains(message, "mission") or MsgContains(message, "crate") then
		if state == 2 then
			if F.tradeCrate(player) then
				npcHandler:say("Good job my friend, and thank you for your help. Here, take Iriana's chest. Maybe we'll meet again |PLAYERNAME|.", npc, creature)
			else
				npcHandler:say("Where is the crate? Go to the sewers south of Pugwah's tavern, dig through the soft dirt, climb up into his cellar with a rope and take a crate of food.", npc, creature)
			end
		elseif state == 3 and player:getItemCount(F.irianaChest) < 1 then
			-- ours: a lost chest can be fetched again
			player:addItem(F.irianaChest, 1)
			npcHandler:say("Lost it already? Here, I kept it for you. Now go and bring it to her before I change my mind.", npc, creature)
		elseif state == 1 then
			npcHandler:say("Quest? You came here about {Iriana}, didn't you?", npc, creature)
		elseif state >= 3 then
			npcHandler:say("We're done, |PLAYERNAME|. Bring the chest to Iriana.", npc, creature)
		else
			npcHandler:say("I have no work for strangers.", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "yes") and topic == 1 then
		F.setState(player, 2)
		npcHandler:say("Watch your back, |PLAYERNAME|.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "no") and topic == 1 then
		npcHandler:say("Then she will never see her chest again.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "job") then
		npcHandler:say("I take what others don't watch well enough.", npc, creature)
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
