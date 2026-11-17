local internalNpcName = "Angelo"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 145,
	lookHead = 96,
	lookBody = 114,
	lookLegs = 120,
	lookFeet = 101,
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

-- FAMILY (2026-11-17): Angelo reviewed against the EN transcript (Cults of Tibia Quest/Spoiler, lines
-- marked EN) and TibiaWiki BR. "results" and "worried" work without asking about the project and MoTA
-- first (EN: "Ask him about results and then tell him he should be worried"), "mission" starts it too
-- (BR: "Hi - Mission - Yes"), his lines after the counteragent and after the Sandking come with "hi" (EN),
-- and once the Sandking is dead he does not talk any more (both wikis); the Patron of the Arts steps that
-- need him then go on by themselves (BR: "apenas tente falar com ele e em seguida colete a Lupa na caixa").
local LIFE = Storage.Quest.U11_40.CultsOfTibia.Life
local MOTA = Storage.Quest.U11_40.CultsOfTibia.MotA
local REFUSE = "Just get out of my way! You killed this beautiful creature. I have nothing more to say. Damn druid of Crunor!" -- EN

local function greetCallback(npc, creature)
	local player = Player(creature)
	local life = player:getStorageValue(LIFE.Mission)
	local mota = player:getStorageValue(MOTA.Mission)

	if life >= 8 then
		npcHandler:setMessage(MESSAGE_GREET, REFUSE)
		if life == 8 then
			player:setStorageValue(LIFE.Mission, 9)
		end
		if mota == 6 then
			player:setStorageValue(MOTA.Mission, 7)
		elseif mota == 10 then
			player:setStorageValue(MOTA.Mission, 11)
		end
	elseif life == 7 then
		npcHandler:setMessage(MESSAGE_GREET, "What has happened? You applied the counteragent to the oasis and then it was destroyed by a sandstorm? Keep on investigating the place.") -- EN
	elseif life >= 3 or (mota >= 6 and mota <= 11) then
		npcHandler:setMessage(MESSAGE_GREET, "How is your {mission} going?") -- EN
	else
		npcHandler:setMessage(MESSAGE_GREET, "The Druid of Crunor? He told you that a new {cave} appeared here? That's right. I'm the head of a {project} that tries to find out more about this new area.") -- EN
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	local life = player:getStorageValue(LIFE.Mission)
	local mota = player:getStorageValue(MOTA.Mission)

	if life >= 8 then
		npcHandler:say(REFUSE, npc, creature)
		npcHandler:removeInteraction(npc, creature)
		return true
	end

	if life == 3 and MsgContains(message, "mission") then
		npcHandler:say("The scientists are still missing? You just found some strange green-shining mummies and a big oasis? I give you this analysis tool for the water of the oasis. Maybe that's the key. Could you bring me a sample of this water?", npc, creature) -- EN
		npcHandler:setTopic(playerId, 15)
	elseif life == 3 and npcHandler:getTopic(playerId) == 15 and MsgContains(message, "yes") then
		npcHandler:say("Very good! Hopefully, analysing this sample will get us closer to the solution of this mystery.", npc, creature) -- EN
		player:addItem(25305, 1)
		player:setStorageValue(LIFE.Mission, 4)
		npcHandler:setTopic(playerId, 0)
	elseif life == 5 and MsgContains(message, "mission") then
		npcHandler:say("Do you have the sample I asked you for?", npc, creature) -- EN
		npcHandler:setTopic(playerId, 16)
	elseif life == 5 and npcHandler:getTopic(playerId) == 16 and MsgContains(message, "yes") then
		npcHandler:say("Thanks a lot. Let me check the result. Well, I think you need this counteragent. Please apply it to the oasis!", npc, creature) -- EN
		player:addItem(25304, 1)
		player:setStorageValue(LIFE.Mission, 6)
		npcHandler:setTopic(playerId, 0)
	elseif life == 7 and MsgContains(message, "mission") then
		npcHandler:say("What has happened? You applied the counteragent to the oasis and then it was destroyed by a sandstorm? Keep on investigating the place.", npc, creature) -- EN
		npcHandler:setTopic(playerId, 0)
	elseif mota == 6 and MsgContains(message, "magnifier") then
		npcHandler:say("{Gareth} told you that there are rumours about fake artefacts in the MoTA? And it is your task to check that with a magnifier? I see. I don't need one right now, so you can have one of mine. You find one in the crate over there.", npc, creature) -- BR
		player:setStorageValue(MOTA.Mission, 7)
		npcHandler:setTopic(playerId, 0)
	elseif mota == 10 and (MsgContains(message, "artefact") or MsgContains(message, "artifact")) then
		npcHandler:say("So you found out that one artefact in the MoTA is fake? And {Gareth} sent you to me to get a new artefact as a replacement? Sorry, I hardly know you, so I don't trust you. I won't help you with that!", npc, creature) -- BR
		player:setStorageValue(MOTA.Mission, 11)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "gareth") then
		npcHandler:say("Gareth is the curator of the {MoTA}. Our project sends him all new results.", npc, creature) -- ours
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "project") then
		npcHandler:say("The project is called 'Sandy Cave Project' and is funded by the {MoTA}. Its goal is the investigation of this {cave}.", npc, creature) -- EN
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "dark pyramid") then
		npcHandler:say("We don't know yet to which extent the cave and the dark pyramid belong together. This is what we try to find out. Maybe the history of this place has to be rewritten.", npc, creature) -- EN
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "cave") then
		npcHandler:say("We don't know exactly why this {cave} has now exposed an entry via the {dark pyramid}. It seems that the cave already existed for a long time, however, without a connection to our world. Maybe some smaller earth movements have changed the situation.", npc, creature) -- EN
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "mota") then
		npcHandler:say("MoTA is short for the recently founded Museum of Tibian Arts. We work together in close collaboration. New {results} are communicated to the museum instantly.", npc, creature) -- EN
		npcHandler:setTopic(playerId, 0)
	elseif life < 2 and MsgContains(message, "results") then
		npcHandler:say("We have no scientific results so far to reach our goal, because my workers aren't back yet. Should I be {worried}?", npc, creature) -- EN
		npcHandler:setTopic(playerId, 4)
	elseif life < 2 and (MsgContains(message, "worried") or MsgContains(message, "mission")) then
		npcHandler:say("Then I have to find out why they don't return. But I'm old and my back aches. Would you like to go there and look for my workers?", npc, creature) -- EN
		npcHandler:setTopic(playerId, 5)
	elseif life < 2 and npcHandler:getTopic(playerId) == 5 and MsgContains(message, "yes") then
		npcHandler:say("Fantastic! Go there and then tell me what you've seen. I've opened the door for you. Take care of yourself!", npc, creature) -- EN
		player:setStorageValue(LIFE.Mission, 2)
		player:setStorageValue(LIFE.AccessDoor, 1)
		FamilyCults.startQuestline(player)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "mission") then
		npcHandler:say("Go on with what you are doing and come back when you have news.", npc, creature) -- ours
		npcHandler:setTopic(playerId, 0)
	end

	return true
end

npcHandler:setMessage(MESSAGE_WALKAWAY, "Well, bye then.")

npcHandler:setCallback(CALLBACK_SET_INTERACTION, onAddFocus)
npcHandler:setCallback(CALLBACK_REMOVE_INTERACTION, onReleaseFocus)

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
