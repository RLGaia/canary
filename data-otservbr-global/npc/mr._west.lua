local internalNpcName = "Mr. West"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 151,
	lookHead = 58,
	lookBody = 25,
	lookLegs = 29,
	lookFeet = 114,
	lookAddons = 0,
}

npcConfig.flags = {
	floorchange = false,
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
-- FAMILY: answers of the TibiaWiki EN transcripts
keywordHandler:addKeyword({ "friend" }, StdModule.say, { npcHandler = npcHandler, text = "I guess you are here on a {mission}." })
keywordHandler:addKeyword({ "here" }, StdModule.say, { npcHandler = npcHandler, text = "I guess you are here on a {mission}." })
keywordHandler:addKeyword({ "yalahar" }, StdModule.say, { npcHandler = npcHandler, text = "Yalahar is an oyster. Its treasure is waiting to be excavated by someone with the necessary determination." })
keywordHandler:addKeyword({ "thais" }, StdModule.say, { npcHandler = npcHandler, text = "The word is that Thais is a dangerous place which you better do not visit unprepared." })
keywordHandler:addKeyword({ "venore" }, StdModule.say, { npcHandler = npcHandler, text = "The trade barons know how to run a city, that's for sure. Unfortunately, they are greedier than it is good for them. I'm prepared to deal with their intrusion into my territory." })
keywordHandler:addKeyword({ "carlin" }, StdModule.say, { npcHandler = npcHandler, text = "The illusion of peace that this city is offering often distracts the attention from the dangers lurking there." })
keywordHandler:addKeyword({ "kazordoon" }, StdModule.say, { npcHandler = npcHandler, text = "Those dwarfs know how to fortify a city. Perhaps one day, when I've earned enough money and have grown too old for the trouble in Yalahar, I will retire there." })
keywordHandler:addKeyword({ "ab'dendriel" }, StdModule.say, { npcHandler = npcHandler, text = "I wouldn't trust a single elf, let alone a whole city of them." })

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

local function greetCallback(npc, creature)
	local player = Player(creature)
	local playerId = player:getId()

	if player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MrWestDoor) == 1 then
		npcHandler:setMessage(MESSAGE_GREET, { "Wh .. What? How did you get here? Where are all the guards? You .. you could have killed me but yet you chose to talk? What a relief! ...", "So what brings you here my friend, if I might call you like that?" })
	elseif player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MrWestDoor) == 2 then
		npcHandler:setMessage(MESSAGE_GREET, { "Murderer! But .. I give in, you won! ...", "Dictate me your conditions but please, I beg you, spare my life. What do you want?" })
	else
		npcHandler:setMessage(MESSAGE_GREET, "Hello. What brings you {here}?") -- FAMILY: TibiaWiki EN transcript
	end
	return true
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "mission") then
		if player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Questline) == 24 then
			if player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MrWestDoor) == 1 then
				npcHandler:say("Indeed, I can see the benefits of a mutual agreement. I will later read the details and send a letter to your superior.", npc, creature)
				player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Questline, 25)
				player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Mission04, 3) -- StorageValue for Questlog "Mission 04: Good to be Kingpin"
				player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MrWestStatus, 1)
				npcHandler:setTopic(playerId, 0)
			elseif player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MrWestDoor) == 2 then
				npcHandler:say("Yes, for the sake of my life I'll accept those terms. I know when I have lost. Tell your master I will comply with his orders.", npc, creature)
				player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Questline, 25)
				player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Mission04, 4) -- StorageValue for Questlog "Mission 04: Good to be Kingpin"
				player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MrWestStatus, 2)
				npcHandler:setTopic(playerId, 0)
			end
		end
	end
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
