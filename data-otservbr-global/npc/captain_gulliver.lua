local internalNpcName = "Captain Gulliver"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 472,
	lookHead = 0,
	lookBody = 57,
	lookLegs = 20,
	lookFeet = 39,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
}

npcConfig.voices = {
	interval = 15000,
	chance = 50,
	{ text = "Passages to Thais! Visit the strange lands!" }, -- FAMILY: TibiaWiki EN sounds
	{ text = "Special passages to Edron, Venore, Port Hope or Krailos for citizens!" },
	{ text = "Passages to Kilmaresh! Visit the city of Issavi and its architectural wonders!" },
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

-- Travel
local function addTravelKeyword(keyword, cost, destination, action)
	local travelKeyword = keywordHandler:addKeyword({ keyword }, StdModule.say, { npcHandler = npcHandler, text = "Do you seek a passage to " .. keyword:titleCase() .. " for |TRAVELCOST|?", cost = cost, discount = "postman" })
	travelKeyword:addChildKeyword({ "yes" }, StdModule.travel, { npcHandler = npcHandler, premium = false, cost = cost, discount = "postman", destination = destination }, nil, action)
	travelKeyword:addChildKeyword({ "no" }, StdModule.say, { npcHandler = npcHandler, text = "We would like to serve you some time.", reset = true })
end

-- FAMILY: Edron, Venore, Port Hope and Krailos only for citizens of Rathleton, prices from
-- TibiaWiki EN Captain Gulliver (upstream: Krailos for everyone at 180, no Edron/Venore/Port Hope)
if FamilyRathleton and FamilyRathleton.on() then
	FamilyRathleton.addCitizenTravel(keywordHandler, npcHandler, "edron", 110, Position(33175, 31764, 6))
	FamilyRathleton.addCitizenTravel(keywordHandler, npcHandler, "venore", 130, Position(32954, 32022, 6))
	FamilyRathleton.addCitizenTravel(keywordHandler, npcHandler, "port hope", 200, Position(32527, 32784, 6))
	FamilyRathleton.addCitizenTravel(keywordHandler, npcHandler, "krailos", 60, Position(33493, 31712, 6))
else
	addTravelKeyword("krailos", 180, Position(33493, 31712, 6))
end
addTravelKeyword("thais", 150, Position(32311, 32210, 6))
addTravelKeyword("issavi", 130, Position(33902, 31462, 6))

-- Kick
keywordHandler:addKeyword({ "kick" }, StdModule.kick, { npcHandler = npcHandler, destination = { Position(33487, 31986, 7), Position(33486, 31984, 7) } })

-- Basic
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "Ah, you may not have heard of me. I am Captain Gulliver, the first Oramondian for a hundred years to have sailed through the mist to your strange lands." })
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I am the captain of the 'Sea Goddess', the splendid and beautiful ship you see over there." })
keywordHandler:addKeyword({ "captain" }, StdModule.say, { npcHandler = npcHandler, text = "I am the captain of the 'Sea Goddess', the splendid and beautiful ship you see over there." })
keywordHandler:addKeyword({ "ship" }, StdModule.say, { npcHandler = npcHandler, text = "The 'Sea Goddess' is the most beautiful in Oramond, a whole new model of ship, elegant, sure and swift. There's no weather she can't take!" })
keywordHandler:addKeyword({ "tibia" }, StdModule.say, { npcHandler = npcHandler, text = "Ah, your lands are quite a sight! I have only visited Thais so far, but I think of navigating to more cities, when the time - and public demand - comes." })
keywordHandler:addKeyword({ "good" }, StdModule.say, { npcHandler = npcHandler, text = "I will gladly take on board everything you wish to transport. No pets, though." })
keywordHandler:addKeyword({ "passenger" }, StdModule.say, { npcHandler = npcHandler, text = "<bows> I would be delighted to have you on board." })

keywordHandler:addKeyword({ "sail" }, StdModule.say, { npcHandler = npcHandler, text = "You would like to book a passage for {Thais} or {Issavi}? Citizens of Rathleton may also sail to {Edron}, {Venore}, {Port Hope} or {Krailos}." }) -- FAMILY
keywordHandler:addKeyword({ "route" }, StdModule.say, { npcHandler = npcHandler, text = "You would like to book a passage for {Thais} or {Issavi}? Citizens of Rathleton may also sail to {Edron}, {Venore}, {Port Hope} or {Krailos}." }) -- FAMILY
keywordHandler:addKeyword({ "trip" }, StdModule.say, { npcHandler = npcHandler, text = "You would like to book a passage for {Thais} or {Issavi}? Citizens of Rathleton may also sail to {Edron}, {Venore}, {Port Hope} or {Krailos}." }) -- FAMILY
keywordHandler:addKeyword({ "passage" }, StdModule.say, { npcHandler = npcHandler, text = "You would like to book a passage for {Thais} or {Issavi}? Citizens of Rathleton may also sail to {Edron}, {Venore}, {Port Hope} or {Krailos}." }) -- FAMILY
keywordHandler:addKeyword({ "town" }, StdModule.say, { npcHandler = npcHandler, text = "You would like to book a passage for {Thais} or {Issavi}? Citizens of Rathleton may also sail to {Edron}, {Venore}, {Port Hope} or {Krailos}." }) -- FAMILY
keywordHandler:addKeyword({ "destination" }, StdModule.say, { npcHandler = npcHandler, text = "You would like to book a passage for {Thais} or {Issavi}? Citizens of Rathleton may also sail to {Edron}, {Venore}, {Port Hope} or {Krailos}." }) -- FAMILY
keywordHandler:addKeyword({ "go" }, StdModule.say, { npcHandler = npcHandler, text = "You would like to book a passage for {Thais} or {Issavi}? Citizens of Rathleton may also sail to {Edron}, {Venore}, {Port Hope} or {Krailos}." }) -- FAMILY

keywordHandler:addKeyword({ "oramond" }, StdModule.say, { npcHandler = npcHandler, text = "This is the only safe landing place on Oramond. The cliffs surrounding the isle are too dangerous, you see." })

npcHandler:setMessage(MESSAGE_GREET, "Welcome on board, Sir |PLAYERNAME|. Where can I {sail} you today?")
npcHandler:setMessage(MESSAGE_FAREWELL, "Good bye. Recommend us if you were satisfied with our service.")

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
