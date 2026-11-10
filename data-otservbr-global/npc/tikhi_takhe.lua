-- FAMILY: Tik'hi Tak'he, the shaman of Rascacoon (A Pirate's Tail Quest, 2026-11-10). Ours, not upstream
-- (Canary v3.6.1 has no such NPC). Lines from the TibiaWiki BR quest page and NPC page and the EN spoiler;
-- lines marked "ours" are not in the wikis. Look ours (a rascoohan in red and gold, matched to the BR image).
-- Rules in lib/others/family_pirates_tail.lua.
local internalNpcName = "Tik'hi Tak'he"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1371,
	lookHead = 0,
	lookBody = 94,
	lookLegs = 79,
	lookFeet = 79,
	lookAddons = 1,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "May the great raccoon smile upon you!" }, -- EN
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

local PT = FamilyPiratesTail
local S = Storage.Quest.U12_60.APiratesTail

-- TibiaWiki BR NPC page
local lore = {
	job = "I am the {shaman} of {Rascacoon}.",
	shaman = "I'm the diviner of the will of the great {raccoon} and keeper of {wisdom}.",
	rascacoon = "This {colony} lived in peace for centuries, but this peace is now severely disrupted. The {pirats} became a constant threat and annoyance.",
	colony = "This colony is called Rascacoon. But our tribe originates from a far way rascoohan city with the name {Washingstone}.",
	pirats = "When they were still known as Corym, there were only occasional clashes over loot and flotsam. But one day things {changed}.",
	washingstone = "It's only a place of mystery and legend. We have no contact since generations and its location was lost in time.",
	changed = "Our spies found out that the Corym retrieved an ancient book from a trunk in a shipwreck. It taught them about the {ways} of the pirates.",
	ways = "Their leaders were convinced that this was a description of the old and forgotten ways of their people and they {adopted} it.",
	adopted = "They became the pirats that we know today. They became more organized and more {aggressive}.",
	aggressive = "Things escalated when they by chance discovered the explosiveness of the {mold} of one of their favourite cheeses.",
	mold = "They weaponized the mold and refined it to so called green {powder} to create devastating weapons.",
	powder = "For now they employ it to {terrorize} the seas and experiment with its {power}.",
	terrorize = "It's only a matter of time until they will come and use their weapons against us. Therefore they have to be {stopped}.",
	power = { "I fear they have yet to unleash the true destructive power of this weapon. For all what we know they keep experimenting and refining it, somewhere deep in their dens. ...", "To disrupt those experiments might prove helpful." },
	stopped = "We know many secrets and studied the pirats for a long time. Our {knowledge} will prove helpful in fighting them.",
	knowledge = "Before we share our knowledge you have to {help} us, to strengthen our position and secure our colony.",
	help = "When we feel safe enough from their retribution, we can approve a strike to the heart of the pirats. Until then it will be your {mission} to assist our colony.",
	raccoon = "He is our {creator} and guide.",
	creator = "The mother of all gave birth to the gods. The gods immediately begun with the {creation} of the world, as this was their only purpose.",
	creation = "Their greatest accomplishment was the creation of the great raccoon. Of all of the gods creations only he was perfect and therefore he was {unique}.",
	unique = "But the great raccoon immediately felt an enormous {loneliness}, because all of creation had their peers to bond but the unique raccoon hadn't.",
	loneliness = "So after the gods were done with creation, the great raccoon stole the secret of life out of their trashcan and created us Rascoohans in his {image}.",
	image = "The great raccoon looks over us and we live our life to his {enjoyment}.",
	enjoyment = "When the gods moved on to create other world, the great raccoon stood behind and kept watching over us.",
	king = "What king? We have no king or leader. We have to convince other to cooperate and don't order them.",
	tasks = "Look all over Rascacoon and the isle to find opportunities to help us out. Even back in the Corym caves you might find something useful to do.",
}
local loreOrder = { "job", "shaman", "washingstone", "rascacoon", "colony", "pirats", "changed", "ways", "adopted", "aggressive", "mold", "powder", "terrorize", "power", "stopped", "knowledge", "help", "raccoon", "creator", "creation", "unique", "loneliness", "image", "enjoyment", "king", "tasks" }
local proverbs = {
	"Fools rush in while the iron is still hot.",
	"It's better to be poor and healthy than to throw stones from inside a glasshouse.",
	"If a man fools you once, shame on him. But if you teach him how to fish, he'll probably won't bother you ever again.",
	"Never pass on a free snack or an unsecured trashcan - which is basically the same.",
	"Too many cooks are better than one.",
	"The early bird gets the worm. But the worm got up even more early and what good did it do him?",
}

local TOPIC_MISSION, TOPIC_ADVANCE, TOPIC_WISDOM, TOPIC_BUY = 1, 2, 3, 4
local chosen = {}

local function findWare(message)
	for _, list in pairs(PT.wares) do
		for _, ware in ipairs(list) do
			if MsgContains(message, ware.name) then
				return ware
			end
		end
	end
	return nil
end

local function listWares(list)
	local names = {}
	for _, ware in ipairs(list) do
		names[#names + 1] = string.format("{%s} for %d", ware.name, ware.price)
	end
	return table.concat(names, ", ")
end

local function greetCallback(npc, creature)
	local player = Player(creature)
	if PT.rascacoon(player) >= 1 then
		npcHandler:setMessage(MESSAGE_GREET, "Hail, visitor! Welcome! You can ask me about your '{trust points}'!") -- BR
	else
		npcHandler:setMessage(MESSAGE_GREET, "Hail, visitor! Welcome!") -- BR
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	local state = PT.rascacoon(player)
	local topic = npcHandler:getTopic(playerId)

	if topic == TOPIC_BUY and chosen[playerId] then
		local ware = chosen[playerId]
		chosen[playerId] = nil
		npcHandler:setTopic(playerId, 0)
		if MsgContains(message, "yes") then
			if PT.trust(player) < ware.price then
				npcHandler:say(string.format("You don't have enough trust points. You have %d trust points right now.", PT.trust(player)), npc, creature) -- ours
			elseif not player:addItem(ware.id, 1) then
				npcHandler:say("You cannot carry it. Make some room first.", npc, creature) -- ours
			else
				player:setStorageValue(S.TrustPoints, PT.trust(player) - ware.price)
				npcHandler:say(string.format("Here you are. May the great raccoon smile upon you! You have %d trust points left.", PT.trust(player)), npc, creature) -- ours
			end
		else
			npcHandler:say("Maybe another time.", npc, creature) -- ours
		end
		return true
	end

	if topic == TOPIC_WISDOM then
		npcHandler:setTopic(playerId, 0)
		if MsgContains(message, "yes") then
			npcHandler:say(proverbs[math.random(#proverbs)], npc, creature) -- BR
		else
			npcHandler:say("A wise choice for the weak.", npc, creature) -- ours
		end
		return true
	end

	if MsgContains(message, "mission") then
		if state < 1 then
			npcHandler:say("Do you want to help our colony, to earn our trust and respect?", npc, creature) -- BR
			npcHandler:setTopic(playerId, TOPIC_MISSION)
		elseif state == 1 then
			npcHandler:say("Help our colony with its {tasks} and ask me about your '{trust points}' from time to time.", npc, creature) -- ours
		else
			npcHandler:say("Go through the teleporter in the east of the island and find out what the pirats are up to.", npc, creature) -- ours
		end
		return true
	elseif MsgContains(message, "yes") and topic == TOPIC_MISSION then
		npcHandler:setTopic(playerId, 0)
		player:setStorageValue(S.Rascacoon, 1)
		if player:getStorageValue(S.TrustPoints) < 0 then
			player:setStorageValue(S.TrustPoints, 0)
		end
		player:setStorageValue(S.RascacoonShortcut, 1) -- EN: the shortcut between Venore and Rascacoon opens
		if player:getStorageValue(S.QuestLine) < 1 then
			player:setStorageValue(S.QuestLine, 1) -- the quest log shows the quest
		end
		npcHandler:say("Go ahead then. You will get what I like to call '{trust points}' for different {tasks}.", npc, creature) -- BR
		return true
	elseif MsgContains(message, "yes") and topic == TOPIC_ADVANCE then
		npcHandler:setTopic(playerId, 0)
		if state == 1 and PT.trust(player) >= PT.TRUST_NEEDED then
			player:setStorageValue(S.TrustPoints, PT.trust(player) - PT.TRUST_NEEDED)
			player:setStorageValue(S.Rascacoon, 2)
			player:setStorageValue(S.TentuglyDoor, 1)
			npcHandler:say("I hereby name you trusted friend of the Rascoohan people!", npc, creature) -- BR
		end
		return true
	elseif MsgContains(message, "no") and (topic == TOPIC_MISSION or topic == TOPIC_ADVANCE) then
		npcHandler:setTopic(playerId, 0)
		npcHandler:say("As you wish.", npc, creature) -- ours
		return true
	elseif MsgContains(message, "trust") or MsgContains(message, "points") then
		if state < 1 then
			npcHandler:say("We don't know you. Maybe you can help with our {mission} first.", npc, creature) -- ours
		elseif state == 1 and PT.trust(player) < PT.TRUST_NEEDED then
			npcHandler:say(string.format("No, I don't trust you yet. You have %d trust points right now.", PT.trust(player)), npc, creature) -- BR
		elseif state == 1 then
			npcHandler:say({
				"You held out for a long time. I think you earned our trust. ...",
				"Listen closely. There is a teleporter in the east of the island. It is used by pirats to go on board of their ship. ...",
				"If you really want to help against the pirats, go through it and find out what's going on. But there is one catch! ...",
				"You need to look like a pirat to go thorugh the teleporter. For 1200 trust points, I will cast a permanent entchantment on you that transforms you into a pirat for fifteen minutes every time you step through the teleporter. ...",
				"I will also grant you access to my special assortment of rascoohan wares after you reached the pirats hideout. Do you want to advance?",
			}, npc, creature) -- BR
			npcHandler:setTopic(playerId, TOPIC_ADVANCE)
		else
			npcHandler:say(string.format("You are a trusted friend of the Rascoohan people. You have %d trust points right now.", PT.trust(player)), npc, creature) -- ours
		end
		return true
	elseif MsgContains(message, "wisdom") then
		npcHandler:say("Are you sure that you want to listen to rascoohan wisdom? It might shatter the perception of reality for the weak.", npc, creature) -- BR
		npcHandler:setTopic(playerId, TOPIC_WISDOM)
		return true
	elseif MsgContains(message, "trade") or MsgContains(message, "wares") or MsgContains(message, "offer") or MsgContains(message, "accessories") or MsgContains(message, "decorations") then
		if state < 2 or not PT.reachedHideout(player) then
			npcHandler:say("My special assortment of rascoohan wares is only for trusted friends of our people who reached the pirats' hideout.", npc, creature) -- ours
		elseif MsgContains(message, "accessories") then
			npcHandler:say("Accessories, for trust points: " .. listWares(PT.wares.accessories) .. ".", npc, creature) -- ours (BR prices)
		elseif MsgContains(message, "decorations") then
			npcHandler:say("Wall decorations, for trust points: " .. listWares(PT.wares.decorations) .. ".", npc, creature) -- ours (BR prices)
		else
			npcHandler:say("I can offer you {accessories} and {wall decorations} for your trust points.", npc, creature) -- ours
		end
		return true
	end

	local ware = findWare(message)
	if ware then
		if state < 2 or not PT.reachedHideout(player) then
			npcHandler:say("My special assortment of rascoohan wares is only for trusted friends of our people who reached the pirats' hideout.", npc, creature) -- ours
		else
			chosen[playerId] = ware
			npcHandler:setTopic(playerId, TOPIC_BUY)
			npcHandler:say(string.format("Do you want a %s for %d trust points?", ware.name, ware.price), npc, creature) -- ours
		end
		return true
	end

	for _, word in ipairs(loreOrder) do
		if MsgContains(message, word) then
			npcHandler:say(lore[word], npc, creature)
			return true
		end
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_FAREWELL, "Farewell!") -- BR
npcHandler:setMessage(MESSAGE_WALKAWAY, "Farewell!")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
