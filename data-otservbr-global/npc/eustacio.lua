local internalNpcName = "Eustacio"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 471,
	lookHead = 97,
	lookBody = 110,
	lookLegs = 71,
	lookFeet = 116,
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

-- FAMILY: A Pirate's Tail Quest, Eustacio's mission and the Pirat raids (2026-11-10;
-- lib/others/family_pirates_tail.lua, scripts/family/pirat_raids.lua). Lines from the TibiaWiki BR
-- quest page and Eustacio page; lines marked "ours" are not in the wikis. Switch Family.piratesTail.
local PT = FamilyPiratesTail
local S = Storage.Quest.U12_60.APiratesTail

local function familyOn()
	return PT and PT.enabled()
end

local lore = {
	-- TibiaWiki BR, Eustacio page
	aspiring = "I will make my own fortune and walk my way from the bottom to the top, even if it might take some decades.",
	ladder = { "As a newcomer to the Venorean trader union, it's my goal to rise in the {ranks} of the local traders ...", "and become a name to be reckoned with." },
	ranks = "To reach my lofty goal though, I need some {accomplishments} to attach to my name.",
	accomplishments = "Recently an {opportunity} has arisen. A new kind of pirates has shown up and is threatening our shipping routes.",
	opportunity = "Right now the other trade barons are still in {denial}, in fear to scare of potential investors.",
	denial = "That's were I can put my foot in the door by successfully fighting this new {threat}.",
	threat = "For all I know the new pirates are some Corym clans that banded together.",
	armada = { "They seem to employ new powerful magic to dominate our ships in sea battles. ...", "I doubt a {victory} on the seas can be acquired." },
	victory = "We have to rout out their base and strike them there, {disrupt} their supply lines and coordination.",
	disrupt = { "The first step in our fight is to disrupt their {operations}, in the hopes it causes enough ruckus amongst them, ...", "so my other agents might catch some vital new information about their hideouts and supply lines." },
	operations = { "Reports came in about their attacks. Spies, small ships and one big ship with cannons. ...", "I'm not too sure what to make of it but we need to stop them nevertheless. It's a {mission} for you!" },
	society = "Dealing with the trade barons can be like swimming in a pool of {sharks} from time to time.",
	sharks = { "They are the sharks of our society. If they notice you bleeding, you are as good as finished. ...", "Business is always a difficult and dangerous field of expertise, especially in Venore. The trade barons are not too fond of competition." },
	venore = "It's a beautiful town on the surface. But it is ruled by business and business is a constant war.",
}
local loreOrder = { "aspiring", "ladder", "ranks", "accomplishments", "opportunity", "denial", "threat", "armada", "victory", "disrupt", "operations", "society", "sharks", "venore" }

local function secretLines(points)
	return {
		string.format("I am surprised. Due to your tireless effort and because I like numbers, I can proudly tell you that you reached a score of %d. ...", points),
		"I know from my agents that there is a secret passage below Kilmaresh which leads you to their home. But they might not be what you expect. ...",
		"The entrance can be found on the coast next to the temple. You have to use a certain shell lying in the sand.",
	}
end

local function giveRaidItem(npc, creature, player, itemId, storage, text)
	local last = player:getStorageValue(storage)
	if last > 0 and os.time() - last < PT.ITEM_COOLDOWN then
		npcHandler:say("I gave you one not long ago. My supplies are limited, come back later.", npc, creature) -- ours
		return
	end
	local item = player:addItem(itemId, 1)
	if not item then
		npcHandler:say("You cannot carry it. Make some room first.", npc, creature) -- ours
		return
	end
	player:setStorageValue(storage, os.time())
	npcHandler:say(text, npc, creature)
end

local function greetCallback(npc, creature)
	local player = Player(creature)

	if player:getStorageValue(Storage.Quest.U12_60.APiratesTail.RascacoonShortcut) == 1 then
		npcHandler:setMessage(MESSAGE_GREET, {
			"Hello my friend. What a delight to see you, even on a {busy} day. I see you already talked to my agent. I'm willing to lend you my boat if you want to take a {shortcut}.", -- FAMILY: BR ends with "..."; the next line is not known
		})
	elseif familyOn() and PT.questLine(player) >= 1 then
		npcHandler:setMessage(MESSAGE_GREET, "Hello my friend. What a delight to see you, even on a {busy} day. You can check your {status} or ask me about the {location} of the ongoing raids.") -- FAMILY: BR text
	elseif familyOn() then
		npcHandler:setMessage(MESSAGE_GREET, "Hello my friend. What a delight to see you, even on a {busy} day.") -- FAMILY: BR text before the mission
	else
		npcHandler:setMessage(MESSAGE_GREET, "Hello my friend. What a delight to see you, even on a busy day. You can check your status or ask me about the location of ongoing raids.")
	end
	-- FAMILY: Pied Piper (EN: greeting Eustacio with 5000 points)
	if familyOn() and PT.points(player) >= PT.PIED_PIPER and not player:hasAchievement("Pied Piper") then
		player:addAchievement("Pied Piper")
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if familyOn() then
		local line = PT.questLine(player)
		if MsgContains(message, "mission") then
			if line < 1 then
				npcHandler:say({
					"Yes, yes, reports of Pirats came in. My goal is to weaken them significantly to get more information. ...",
					"Can you help me defend the cities and coasts against them? I will share all further details I gathered as soon as I can trust you!",
				}, npc, creature)
				npcHandler:setTopic(playerId, 2)
			elseif line == 1 then
				npcHandler:say("Find them, kill them and destroy their ship! Ask me about the {location} of the ongoing raids, about a {flintstone} and an {orb}, or check your {status}.", npc, creature) -- ours (first sentence BR)
			else
				npcHandler:say(secretLines(PT.points(player)), npc, creature)
			end
			return true
		elseif MsgContains(message, "yes") and npcHandler:getTopic(playerId) == 2 then
			npcHandler:setTopic(playerId, 0)
			if line < 1 then
				player:setStorageValue(S.QuestLine, 1)
				if player:getStorageValue(S.RaidPoints) < 0 then
					player:setStorageValue(S.RaidPoints, 0)
				end
				npcHandler:say({
					"That lifts a burden off my shoulders. Ask me about a {flintstone} and an {orb} then I will give them to you. ...",
					"They are supposed to help you to fend off the pirats. You also might want to take a pick! ...",
					"Check in with me any time if you want to know about your {status} or whether my agents have new information about the {location} of the occurring pirat attacks. ...",
					"Find them, kill them and destroy their ship!",
				}, npc, creature)
			end
			return true
		elseif MsgContains(message, "no") and npcHandler:getTopic(playerId) == 2 then
			npcHandler:setTopic(playerId, 0)
			npcHandler:say("What a pity. Come back when you change your mind.", npc, creature) -- ours
			return true
		elseif MsgContains(message, "status") or MsgContains(message, "points") then
			if line < 1 then
				npcHandler:say("You are not working for me yet. Ask me about my {mission}.", npc, creature) -- ours
			elseif line == 1 and PT.points(player) < PT.NEEDED then
				npcHandler:say({
					string.format("I have my eyes and ears everywhere. If I had to give you points, you would have %d points by now. ...", PT.points(player)),
					string.format("I might consider telling you my secrets if you gather %d points.", PT.NEEDED),
				}, npc, creature)
			else
				if line < 2 then
					player:setStorageValue(S.QuestLine, 2)
				end
				npcHandler:say(secretLines(PT.points(player)), npc, creature)
			end
			return true
		elseif MsgContains(message, "location") then
			local raid = PT.current
			if raid then
				npcHandler:say(string.format("My agents report a pirat attack %s! Find them, kill them and destroy their ship!", raid.place.name), npc, creature) -- ours
			else
				npcHandler:say("My agents didn't see anything of use yet.", npc, creature)
			end
			return true
		elseif MsgContains(message, "flintstone") then
			if line < 1 then
				npcHandler:say("I only give my equipment to those who help me with my {mission}.", npc, creature) -- ours
			else
				giveRaidItem(npc, creature, player, PT.FLINTSTONE, S.FlintstoneTime, "Here is a greenish flintstone. Use it to light the ammunition of a loaded catapult, then fire it at their ship.") -- ours
			end
			return true
		elseif MsgContains(message, "orb") then
			if line < 1 then
				npcHandler:say("I only give my equipment to those who help me with my {mission}.", npc, creature) -- ours
			else
				giveRaidItem(npc, creature, player, PT.ORB, S.OrbTime, "Here is a magical water orb. Use it on the water to make a path to the spyrats hiding in the sea.") -- ours
			end
			return true
		elseif MsgContains(message, "corym") or MsgContains(message, "pirats") or MsgContains(message, "pirates") then
			npcHandler:say({
				"I do not know much about these Corym clans Pirats! ...",
				"All I know is that they are launching attacks on our cities and coasts and that they tossed together some ship wrecks ...",
				"to create a small {armada} of ships.",
			}, npc, creature)
			return true
		end
		for _, word in ipairs(loreOrder) do
			if MsgContains(message, word) then
				npcHandler:say(lore[word], npc, creature)
				return true
			end
		end
	end
	if MsgContains(message, "name") then
		npcHandler:say("I am Eustacio. At your service.", npc, creature)
	elseif MsgContains(message, "time") then
		npcHandler:say("It's just the time to make a fortune.", npc, creature)
	elseif MsgContains(message, "busy") or MsgContains(message, "job") then
		npcHandler:say("I am an {aspiring} businessman, that thrives to climb the {ladder} of success in the Venorean {society}.", npc, creature) -- FAMILY: BR text (upstream: "who thrives")
	elseif MsgContains(message, "shortcut") then
		if player:getStorageValue(Storage.Quest.U12_60.APiratesTail.RascacoonShortcut) == 1 then
			npcHandler:say({
				"You are trustworthy enough to take my boat. My agent made sure it takes me to their island. Do you want to take it?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 1)
		end
	elseif MsgContains(message, "yes") then
		if npcHandler:getTopic(playerId) == 1 then
			npcHandler:setTopic(playerId, 0) -- FAMILY
			creature:teleportTo(Position(33774, 31347, 7))
			creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT) -- FAMILY
		end
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:setMessage(MESSAGE_FAREWELL, "Good bye, |PLAYERNAME|.") -- FAMILY: BR
npcHandler:setMessage(MESSAGE_WALKAWAY, "Good bye, |PLAYERNAME|.") -- FAMILY
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
