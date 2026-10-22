local internalNpcName = "Ambassador Manop"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1816,
	lookHead = 40,
	lookBody = 9,
	lookLegs = 63,
	lookFeet = 63,
	lookAddons = 1,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{
		text = "Harmony. Enlightenment. Power.",
	},
}

local function addMainItems(player)
	local firstItems = {
		slots = {
			[CONST_SLOT_NECKLACE] = Game.createItem(50195),
			[CONST_SLOT_LEFT] = Game.createItem(50171),
			[CONST_SLOT_ARMOR] = Game.createItem(50257),
			[CONST_SLOT_LEGS] = Game.createItem(3559),
			[CONST_SLOT_FEET] = Game.createItem(3552),
		},
	}
	for slot, item in pairs(firstItems.slots) do
		local ret = player:addItemEx(item, false, slot)
		if not ret then
			player:addItemEx(item, false, INDEX_WHEREEVER, 0)
		end
	end
end

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

-- Basic keywords
keywordHandler:addKeyword({ "three-fold path" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Let me know if you are still looking for answers, {seeker}.",
})

keywordHandler:addKeyword({ "pilgrimage" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "The pilgrimage is the sacred {Three-Fold Path} every monk must go. Are you familiar with the {Merudri} ways of the {monks}?",
})

keywordHandler:addKeyword({ "blue valley" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "The Blue Valley is our ancestral home and heart of the {Merudri} culture, or what is left of it. Our ancestors from the Valley have long been separated from the true home of the Merudri.",
})

keywordHandler:addKeyword({ "serenity" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Harmony, enlightenment and power are the keys and control is the door to true serenity.",
})

-- FAMILY: "monk" (his own {monk} link after "yes") answered nothing; only "monks" existed.
local monksText = {
		"The warrior monk combines harmony of the soul, enlightenment of the mind and the power of the body. Honing all these skills with focus and following the Merudri ways with dedication will allow a monk to reach true {serenity} of their spirit. ...",
		"A warrior monk is a weapon in itself, trained, dynamic and deadly. Make no mistake, we are using our skills to preserve, defend and protect our legacy. Violence is a means to a terrible end and we'll refrain from using it unless the utmost necessity. ...",
		"Given a monk has to utilise such measures, however, direct opposition will be eradicated.",
}
keywordHandler:addKeyword({ "monks" }, StdModule.say, { npcHandler = npcHandler, text = monksText })
keywordHandler:addKeyword({ "monk" }, StdModule.say, { npcHandler = npcHandler, text = monksText })

-- FAMILY: {purpose}, legacy and role are offered after "invitation" but had no answer.
-- TibiaWiki gives no reply for them, so these lines are ours and lead to "seeker".
keywordHandler:addKeyword({ "purpose" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Our purpose is to guide those who chose the way of the {monk}. A pilgrim walks the {Three-Fold Path} from shrine to shrine, starting here on Dawnport. If you wish to join us, tell me that you are a {seeker}.",
})
keywordHandler:addKeyword({ "legacy" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Our legacy is the {Blue Valley} and the ways of the {Merudri}, kept alive by every monk who walks the {pilgrimage}.",
})
keywordHandler:addKeyword({ "role" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "Your role, {seeker}, is to walk the {Three-Fold Path}. Visit one of our shrines here on Dawnport, grow to level 8 and ask me again as a seeker.",
})

keywordHandler:addKeyword({ "merudri" }, StdModule.say, {
	npcHandler = npcHandler,
	text = "We are Merudri, warrior monks. Honing {serenity}, preserving our legacy, defending the {Blue Valley} and beyond.",
})

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	local hasQuestLine = player:getStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.QuestLine) > 0
	local hasAtLeastOneShrine = player:getStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.DawnportFirstShrine) > 0 or player:getStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.DawnportSecondShrine) > 0 or player:getStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.DawnportThirdShrine) > 0 or player:getStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.DawnportFourthShrine) > 0

	-- FAMILY: no silent answers (Rodrigo got none after "yes" once the quest line had
	-- started). A started quest line, a wrong vocation or a missing shrine now get a
	-- reply that says what to do; going to the Blue Valley again (a monk who came back
	-- to Dawnport) does not hand out the starting gear a second time.
	local isMonk = player:getVocation():getBaseId() == VOCATION.BASE_ID.MONK
	local topic = npcHandler:getTopic(playerId)

	if MsgContains(message, "invitation") and topic == 0 then
		npcHandler:say("Your path has led you to an ambassador of the {Merudri}. I am Manop and will do my best to explain to you our {purpose}, legacy and your role in it. Shall I continue?", npc, creature)
		npcHandler:setTopic(playerId, 1)
	elseif MsgContains(message, "yes") and topic == 1 then
		npcHandler:setTopic(playerId, 0)
		if not isMonk then
			npcHandler:say("Only those who chose the way of the {monk} can join us here. Should you ever walk that way, come back to me.", npc, creature)
		elseif not hasQuestLine then
			npcHandler:say("I am glad to make your acquaintance, {seeker}. You must have a lot of questions for which I would gladly provide answers. If you are interested in joining us as a true warrior {monk}, just ask.", npc, creature)
			player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.QuestLine, 1)
			player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.Missions.TreeFoldPath, 1)
			player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.DawnportFirstShrine, 0)
			player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.DawnportSecondShrine, 0)
			player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.DawnportThirdShrine, 0)
			player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.DawnportFourthShrine, 0)
		else
			npcHandler:say("We have met before, {seeker}. If you wish to join us as a true warrior {monk} and begin the {pilgrimage}, just ask me as a seeker.", npc, creature)
		end
	elseif MsgContains(message, "yes") and topic == 2 then
		npcHandler:setTopic(playerId, 0)
		if not isMonk or not hasAtLeastOneShrine then
			npcHandler:say("You are not ready yet, {seeker}.", npc, creature)
			return true
		end
		local firstTime = player:getStorageValue(Storage.Dawnport.Mainland) ~= 1
		if firstTime then
			removeMainlandSmugglingItems(player)
			player:setTown(Town(TOWNS_LIST.THAIS))
		end
		player:teleportTo(Position(33614, 31494, 7)) -- Teleport to Blue Valley
		if firstTime then
			addMainItems(player)
		end
		player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		player:setStorageValue(Storage.Dawnport.Mainland, 1)
		if player:getStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.Missions.TreeFoldPath) < 2 then
			player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.Missions.TreeFoldPath, 2)
		end
		-- FAMILY: was Missions.ShrinesCount (nil key: the pilgrimage never started and
		-- no Blue Valley shrine could be used). Only set when not started yet, so going
		-- through this again cannot reset the shrines (upstream #4063).
		if player:getStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.ShrinesCount) < 1 then
			player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.ShrinesCount, 1)
		end
		npcHandler:say("You are now a pilgrim on the Three-Fold Path. Welcome to the Blue Valley, seeker. Enpa-Deia Pema will guide you to the next shrine.", npc, creature)
	elseif MsgContains(message, "no") and (topic == 1 or topic == 2) then
		npcHandler:setTopic(playerId, 0)
		npcHandler:say("As you wish. Harmony. Enlightenment. Power.", npc, creature)
	elseif MsgContains(message, "seeker") then
		npcHandler:setTopic(playerId, 0)
		if not isMonk then
			npcHandler:say("Only those who chose the way of the {monk} can join our pilgrimage from here.", npc, creature)
		elseif not hasQuestLine then
			npcHandler:say("Let me first extend my {invitation} to you, traveller.", npc, creature)
		elseif player:getLevel() < 8 then
			npcHandler:say("Congratulations, you are one step closer to becoming a true warrior monk. Once you have reached level 8, talk to me again and we will see if you are ready to join us on our pilgrimage.", npc, creature)
		elseif not hasAtLeastOneShrine then
			npcHandler:say("If you want to join our pilgrimage and take on the Three-Fold Path, you should visit at least one of our shrines here in the area. When you are experienced enough, return to me.", npc, creature)
		else
			npcHandler:say("Like an orphan, fate has put your soul gently on the doorstep of a new world. You will view this reality with different eyes...", npc, creature)
			npcHandler:say("You will change your ways and adapt as you follow the Three-Fold Path. It has guided the most powerful warriors across countless planes of existence to a higher state of consciousness. ...", npc, creature, 1000)
			npcHandler:say("If you accept, I will send you our temple in the Blue Valley as a MONK. Once you walk this arduous path, there will be NO TURNING BACK. Will you accept this gift and burden like generations of Merudri before you?", npc, creature, 1000)
			npcHandler:setTopic(playerId, 2)
		end
	end
	return true
end

local function greetCallback(npc, creature)
	local player = Player(creature)
	local playerId = player:getId()
	npcHandler:setMessage(MESSAGE_GREET, "I welcome you, traveller of fate's unsearchable roads. On behalf of the Merudri, let this be an {invitation} from a humble guide along the way of enlightenment.")
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)

npcHandler:setMessage(MESSAGE_FAREWELL, "Safe passage, traveller.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Harmony. Enlightenment. Power.")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
