local internalNpcName = "Enpa-Deia Pema"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 1817,
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
	chance = 0,
	{
		text = "",
	},
}

npcConfig.shop = { -- Sellable items
	{ itemName = "boots of enlightenment", clientId = 50267, buy = 8000, sell = 80 },
	{ itemName = "coned hat of enlightenment", clientId = 50274, buy = 70000, sell = 700 },
	{ itemName = "fists of enlightenment", clientId = 50271, buy = 20000, sell = 200 },
	{ itemName = "harmony amulet", clientId = 50195, buy = 1000 },
	{ itemName = "jo staff", clientId = 50171, buy = 500 },
	{ itemName = "legs of enlightenment", clientId = 50269, buy = 40000, sell = 400 },
	{ itemName = "nunchaku of enlightenment", clientId = 50273, buy = 50000, sell = 500 },
	{ itemName = "plain monk robe", clientId = 50257, buy = 450 },
	{ itemName = "simple jo staff", clientId = 50166, buy = 10 },
	{ itemName = "robe of enlightenment", clientId = 50268, buy = 150000, sell = 150 },
	{ itemName = "sais of enlightenment", clientId = 50272, buy = 100000, sell = 100 },
}

-- On sell npc shop message
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost)
	player:sendTextMessage(MESSAGE_TRADE, string.format("Sold %ix %s for %i gold.", amount, name, totalCost))
end

-- On check npc shop message (look item)
npcType.onCheckItem = function(npc, player, clientId, subType) end

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
local monkQuestTotalShrines = math.max(1, configManager.getNumber(configKeys.MONK_QUEST_TOTAL_SHRINES))

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

	-- FAMILY: Pema heals like the temple NPCs (data/scripts/family/temple_healing.lua),
	-- starts the pilgrimage for anyone who asks (upstream only Ambassador Manop did, for
	-- monks leaving Dawnport), says where the next shrine is and closes the quest.
	local lower = message:lower()
	if lower:find("heal") then
		if Family and Family.templeHeal and Family.templeHeal(player) then
			npcHandler:say("Harmony restores body and mind. You are healed.", npc, creature)
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		else
			npcHandler:say("You do not need any healing right now.", npc, creature)
		end
	elseif MsgContains(message, "pilgrimage") then
		local monkStorage = Storage.Quest.U14_15.TheWayOfTheMonk
		local shrinesCount = player:getStorageValue(monkStorage.ShrinesCount)
		-- FAMILY: no type() here: the callback's "type" argument hides it (upstream
		-- "pilgrimage" stopped with a Lua error).
		if not shrinesCount or shrinesCount < 0 then
			shrinesCount = 0
		end
		local isMonk = player:getVocation():getBaseId() == VOCATION.BASE_ID.MONK

		if shrinesCount < 1 then
			if player:getStorageValue(monkStorage.QuestLine) < 1 then
				player:setStorageValue(monkStorage.QuestLine, 1)
			end
			player:setStorageValue(monkStorage.Missions.TreeFoldPath, 2)
			player:setStorageValue(monkStorage.ShrinesCount, 1)
			shrinesCount = 1
			local firstShrine = TheWayOfTheMonkShrines[1]
			npcHandler:say(string.format("%s The Three-Fold Path leads to %d shrines of the Merudri, one after the other, each when you are experienced enough. ...", isMonk and "Then walk it, monk." or "The path is open to any who seek it, even if you are not one of us.", #TheWayOfTheMonkShrines), npc, creature)
			npcHandler:say(string.format("Your first step is to embrace '%s'. It will lead you %s.", firstShrine.name, firstShrine.hint), npc, creature, 1000)
		elseif shrinesCount >= monkQuestTotalShrines then
			if player:getStorageValue(monkStorage.Missions.TreeFoldPath) < 3 then
				player:setStorageValue(monkStorage.Missions.TreeFoldPath, 3)
			end
			player:addAchievement("Hope of the Merudri")
			if isMonk then
				npcHandler:say("You are a monk of the Merudri, enlightened and beyond the Three-Fold Path. You have visited all of our ancestral shrines and embraced eternity. The Enpa will see you now.", npc, creature)
			else
				npcHandler:say("You have visited all of our ancestral shrines and embraced eternity. You are not one of us, but you walked the Three-Fold Path like generations of Merudri before you. Harmony be with you.", npc, creature)
			end
		else
			local currentShrine = TheWayOfTheMonkShrines[shrinesCount - 1]
			local nextShrine = TheWayOfTheMonkShrines[shrinesCount]
			local ordinals = { "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth" }
			if currentShrine then
				npcHandler:say(string.format("You are an initiate of the Merudri, inducted and on the Three-Fold Path. You have visited the %s of the shrines and embraced '%s'. ...", ordinals[shrinesCount - 1] or tostring(shrinesCount - 1), currentShrine.name), npc, creature)
				local levelText = player:getLevel() < nextShrine.level and string.format(" Be at least level %d before you embrace it.", nextShrine.level) or ""
				npcHandler:say(string.format("The next step, embracing '%s', will lead you %s.%s", nextShrine.name, nextShrine.hint, levelText), npc, creature, 1000)
			else
				npcHandler:say(string.format("You are an initiate of the Merudri, ready to begin the Three-Fold Path. Your first step is to embrace '%s'. It will lead you %s.", nextShrine.name, nextShrine.hint), npc, creature)
			end
		end
	end
	return true
end

local function greetCallback(npc, creature)
	local player = Player(creature)
	local playerId = player:getId()
	npcHandler:setMessage(MESSAGE_GREET, "Harmony, friend. Allow me to welcome you in the {Blue Valley}. I offer guidance for the {pilgrimage} and can provide {healing}. Or can I help you otherwise?")
	return true
end

npcHandler:setCallback(CALLBACK_GREET, greetCallback)

npcHandler:setMessage(MESSAGE_FAREWELL, "Harmony and balance on your travels, friend.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Safe and insightful travels, friend.")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
