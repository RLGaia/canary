local internalNpcName = "Charos"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 133,
	lookHead = 60,
	lookBody = 94,
	lookLegs = 114,
	lookFeet = 115,
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

local config = {
	towns = {
		["venore"] = TOWNS_LIST.VENORE,
		["thais"] = TOWNS_LIST.THAIS,
		["kazordoon"] = TOWNS_LIST.KAZORDOON,
		["carlin"] = TOWNS_LIST.CARLIN,
		["ab'dendriel"] = TOWNS_LIST.AB_DENDRIEL,
		["liberty bay"] = TOWNS_LIST.LIBERTY_BAY,
		["port hope"] = TOWNS_LIST.PORT_HOPE,
		["ankrahmun"] = TOWNS_LIST.ANKRAHMUN,
		["darashia"] = TOWNS_LIST.DARASHIA,
		["edron"] = TOWNS_LIST.EDRON,
	},
}

-- FAMILY: as in Tibia since the Measuring Tibia quest, Charos talks about
-- discovering the world and gives the Discoverer outfit (data/scripts/family/
-- map_discovery.lua). His old city attunement is still there if asked for
-- ("attune"), with the upstream limit of 7.
local TOPIC_ATTUNE_YES, TOPIC_ATTUNE_CITY, TOPIC_OUTFIT_YES, TOPIC_OUTFIT_TIER = 1, 2, 10, 11

local function greetCallback(npc, creature)
	npcHandler:setMessage(MESSAGE_GREET, "Hello young friend! I no longer offer travelling services, but I can tell you about {discovering} the world of Tibia and about the Discoverer {outfit}.")
	return true
end

local function attunementsLeft(player)
	return 7 - math.max(player:getStorageValue(Storage.Quest.U9_80.AdventurersGuild.CharosTrav), 0)
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	local topic = npcHandler:getTopic(playerId)
	local D = FamilyDiscovery

	local lower = message:lower()
	if D and (lower:find("discover", 1, true) or lower:find("measuring", 1, true)) then
		npcHandler:say(string.format("The Adventurers' Guild wants to chart every corner of Tibia, and we need brave travellers to help! \z
			Points of interest are hidden all over the world: walk around a part of the map and they appear on your map when you come near them. \z
			Find seven of them and that part is discovered. Your Cyclopedia map shows your progress. \z
			So far you have fully discovered %d of %d areas. Fully discovered areas show you their creatures, warn you of raids and let you walk faster there.", D.completedAreas(player), D.countedTotal), npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif D and (lower:find("outfit", 1, true) or lower:find("addon", 1, true)) then
		npcHandler:say("Do you want to wear the outfit of a true discoverer?", npc, creature)
		npcHandler:setTopic(playerId, TOPIC_OUTFIT_YES)
	elseif topic == TOPIC_OUTFIT_YES and MsgContains(message, "yes") then
		npcHandler:say("For the outfit you need to fully discover ten areas of Tibia, for the first addon you have to discover fifteen and for the second addon twenty. \z
			How many areas have you discovered completely: {ten}, {fifteen} or {twenty}?", npc, creature)
		npcHandler:setTopic(playerId, TOPIC_OUTFIT_TIER)
	elseif topic == TOPIC_OUTFIT_TIER and (MsgContains(message, "ten") or MsgContains(message, "fifteen") or MsgContains(message, "twenty") or MsgContains(message, "10") or MsgContains(message, "15") or MsgContains(message, "20")) then
		local tier, needed, prize
		if MsgContains(message, "fifteen") or MsgContains(message, "15") then
			tier, needed, prize = "addon1", 15, "the first addon of the Discoverer outfit"
		elseif MsgContains(message, "twenty") or MsgContains(message, "20") then
			tier, needed, prize = "addon2", 20, "the second addon of the Discoverer outfit"
		else
			tier, needed, prize = "outfit", 10, "the Discoverer outfit"
		end
		local result, areas = D.giveOutfitTier(player, tier)
		if result == "given" then
			npcHandler:say(string.format("Splendid! You have fully discovered %d areas. Here is %s. Wear it with pride!", areas, prize), npc, creature)
		elseif result == "have" then
			npcHandler:say(string.format("You already have %s.", prize), npc, creature)
		elseif result == "missing" then
			npcHandler:say("You have to get the previous part of the outfit first.", npc, creature)
		else
			npcHandler:say(string.format("You have fully discovered only %d areas so far. Come back when you have discovered %d of them.", areas, needed), npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	elseif topic == TOPIC_OUTFIT_YES or topic == TOPIC_OUTFIT_TIER then
		npcHandler:say("Come back whenever you have discovered more of the world.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif lower:find("attune", 1, true) or MsgContains(message, "city") then
		if attunementsLeft(player) <= 0 then
			npcHandler:say("Sorry, you have traveled a lot. I cannot attune you anymore.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say("I can attune you to a city of your choice. If you step to the teleporter here you will not appear in the city you came from as usual, \z
				but in the city of your choice. Is it what you wish?", npc, creature)
			npcHandler:setTopic(playerId, TOPIC_ATTUNE_YES)
		end
	elseif topic == TOPIC_ATTUNE_YES and MsgContains(message, "yes") then
		npcHandler:say("Fine. You have " .. attunementsLeft(player) .. " attunements left. What is the new city of your choice? Thais, Carlin, Ab'Dendriel, Kazordoon, Venore, \z
			Ankrahmun, Edron, Darashia, Liberty Bay or Port Hope?", npc, creature)
		npcHandler:setTopic(playerId, TOPIC_ATTUNE_CITY)
	elseif topic == TOPIC_ATTUNE_YES then
		npcHandler:say("As you wish.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif topic == TOPIC_ATTUNE_CITY then
		local cityTable = config.towns[message:lower()]
		if cityTable then
			player:setStorageValue(Storage.Quest.U9_80.AdventurersGuild.CharosTrav, math.max(player:getStorageValue(Storage.Quest.U9_80.AdventurersGuild.CharosTrav), 0) + 1)
			player:setStorageValue(Storage.Quest.U9_80.AdventurersGuild.Stone, cityTable)
			npcHandler:say("Goodbye traveler!", npc, creature)
		else
			npcHandler:say("Sorry, I don't know about this place.", npc, creature)
		end
		npcHandler:setTopic(playerId, 0)
	end
	return true
end

npcHandler:setCallback(CALLBACK_SET_INTERACTION, onAddFocus)
npcHandler:setCallback(CALLBACK_REMOVE_INTERACTION, onReleaseFocus)
npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
