local internalNpcName = "Woblin"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 297,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "Stinky Old Nasty." },
	{ text = "Mine precious!" },
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

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	-- FAMILY: The Dorm Key reworked (2026-11-01, reported by Rodrigo's father: "key" did nothing).
	-- TibiaWiki BR: Hi - Key - Reward, then Old Nasty - Yes. Upstream only opened the step with
	-- "precious" (TibiaWiki EN) and its static "key" keyword ("Lost what? Key?") answered first.
	-- Now key and precious both work, every step answers in every state, and "no" answers as in
	-- the EN transcript. Lines marked "ours" are not in either wiki.
	local DORM_KEY = Storage.Quest.U10_55.Dawnport.TheDormKey
	local state = player:getStorageValue(DORM_KEY)
	local askedKey = MsgContains(message, "key")
	if askedKey or MsgContains(message, "precious") then
		if state < 1 then
			npcHandler:say("Me not give key! Key my precious now!", npc, creature)
			npcHandler:setTopic(playerId, 0)
		elseif state == 1 then
			npcHandler:say(
				"Me not give key! Key my precious now! \z
				By old goblin law all that one has in his pockets for two days is family heirloom! \z
				Me no part with my precious ... hm unless you provide Woblin with some {reward}!",
				npc,
				creature
			)
			npcHandler:setTopic(playerId, 1)
		elseif state == 2 or state == 3 then
			npcHandler:say("Me no part with my precious! Bring me {Old Nasty} and I'll give you key!", npc, creature) -- ours
			npcHandler:setTopic(playerId, 0)
		elseif askedKey then
			npcHandler:say("Lost what? Key?", npc, creature) -- TibiaWiki EN, after the key was handed over
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say("You can keep lousy key! Didn't like it anymore anyway.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "reward") then
		if state >= 1 and state <= 3 then
			-- also without asking about the key first, and again later as a reminder
			npcHandler:say(
				"Me good angler but one fish eludes me since many many weeks. I call fish ''Old Nasty''. \z
				You might catch him in this cave, in that pond there. Bring me {Old Nasty} and I'll give you key!",
				npc,
				creature
			)
			if state == 1 then
				player:setStorageValue(DORM_KEY, 2)
			end
		elseif state >= 4 then
			npcHandler:say("You got lousy key already! Woblin happy, Old Nasty gone!", npc, creature) -- ours
		else
			npcHandler:say("Reward? Woblin give reward when Woblin need something. Not now!", npc, creature) -- ours
		end
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "old nasty") or MsgContains(message, "nasty") then
		if state == 2 or state == 3 then
			npcHandler:say("You bring me Old Nasty?", npc, creature)
			npcHandler:setTopic(playerId, 2)
		elseif state >= 4 then
			npcHandler:say("Old Nasty gone! You did it! Woblin happy.", npc, creature) -- ours
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say("Stinky Old Nasty! Him my arch enemy. Him swim in pond there.", npc, creature) -- ours
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "yes") then
		if npcHandler:getTopic(playerId) == 2 then
			if player:getItemCount(21402) >= 1 and player:removeItem(21402, 1) then
				npcHandler:say("You did it! That's my old arch enemy! Here take lousy key. Didn't like it anymore anyway.", npc, creature)
				local TheDormKey = player:addItem(21392, 1)
				if TheDormKey then
					TheDormKey:setActionId(103)
				end
				player:setStorageValue(DORM_KEY, 4)
			else
				npcHandler:say("You have not Old Nasty! Odd, you stink just like him though!", npc, creature)
			end
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "no") then
		if npcHandler:getTopic(playerId) == 2 then
			npcHandler:say("No waste time of Woblin, foolish human!", npc, creature) -- TibiaWiki EN
			npcHandler:setTopic(playerId, 0)
		end
	end

	return true
end

keywordHandler:addKeyword({ "goblins" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "No part of clan. Me prefer company of {precious}. Or mirror image. Always nice to see pretty me!",
})
keywordHandler:addKeyword({ "minotaur" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Me not like minos either. Huge mean bullies! Woblin peaceful here.",
})
keywordHandler:addKeyword({ "troll" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Me not like trolls. Big furry stinky trolls!",
})
-- FAMILY: "dwarf" and "dwarves" were one keyword (both words needed); now each works
keywordHandler:addKeyword({ "dwarf" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Mean short people, make Woblin's clan do slave work for them.",
})
keywordHandler:addAliasKeyword({ "dwarves" })
keywordHandler:addKeyword({ "cyclops" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Ugly stomping giants, always busy hammering stone.",
})
keywordHandler:addKeyword({ "quest" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "What you on quest for? Go leave Woblin alone with {precious}.",
})
keywordHandler:addKeyword({ "help" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Fish good. Fish quiet and tasty. Woblin try to catch fishes, but... hm you could earn yourself {reward}!",
})
-- FAMILY: "trade" and "offer" were one keyword (both words needed); now each works
keywordHandler:addKeyword({ "trade" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Me not trade! Goods my precious now! By old goblin law all that one has in his pockets for two days is family heirloom! Me no part with my goods ... hm unless you provide Woblin with some {reward}!",
})
keywordHandler:addAliasKeyword({ "offer" })
-- FAMILY: the static "key" keyword ("Lost what? Key?") answered before the quest step; "key" is in the callback now

npcHandler:setMessage(MESSAGE_GREET, "Hi there human!")
npcHandler:setMessage(MESSAGE_FAREWELL, "Bye, bye!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Bye, bye!")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
