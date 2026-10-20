local internalNpcName = "Cranky Lizard Crone"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 339,
}

npcConfig.flags = {
	floorchange = false,
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

-- FAMILY: The Spirit Will Get You (2026-10-20). Upstream only traded the
-- Wayfarer addons ("first addon", "second addon"), with no quest. Now as on
-- TibiaWiki: "mission" starts the search for the three pages of a faded last
-- will (scripts/family/spirit_will_get_you.lua); bringing them back gives
-- 10,050 experience, and only then does she fix a "hat" (sedge hat, second
-- addon) or a "cape" (old cape, first addon). The addon storages are upstream's.

local function addonTrade(npc, creature, player, index)
	local item = index == 1 and 11701 or 11700 -- old cape, sedge hat
	local storage = index == 1 and Storage.WayfarerOutfit or Storage.WayfarerOutfit + 1
	if player:getStorageValue(storage) >= 1 then
		npcHandler:say("You already have zat. Don't you try to mock me!", npc, creature)
	elseif player:getItemCount(item) < 1 or not player:removeItem(item, 1) then
		npcHandler:say(index == 1 and "Where iz ze cape? Come back when you have it." or "Where iz ze hat? Come back when you have it.", npc, creature)
	else
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
		player:addOutfitAddon(366, index)
		player:addOutfitAddon(367, index)
		player:setStorageValue(storage, 1)
		npcHandler:say(index == 1 and "Zo, zere you go. Now finally leave me be." or "Here you are. Now begone.", npc, creature)
	end
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

	local F = FamilySpirit
	local state = F.state(player)
	local topic = npcHandler:getTopic(playerId)

	if MsgContains(message, "mission") or MsgContains(message, "help") then
		if state < 1 then
			npcHandler:say({
				"Help? Zo you want to make yourzelf uzeful? Fine. My late huzband wrote hiz lazt will, and ze wind and ze rats scattered ze pagez all over ze ruinz of thiz mountain. ...",
				"Zree pagez. Ze spiritz will get me if I go out zere myzelf. Will you find zem for me?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 1)
		elseif state == 1 then
			if player:getItemCount(F.page) >= 3 then
				npcHandler:say("Did you find all zree pagez of ze lazt will?", npc, creature)
				npcHandler:setTopic(playerId, 2)
			else
				npcHandler:say(string.format("You have not brought me all zree pagez yet (%d found). Zearch ze ruinz around my houze, above and below!", F.pagesFound(player)), npc, creature)
				npcHandler:setTopic(playerId, 0)
			end
		else
			npcHandler:say("You did what I azked. If you bring me an old {cape} or a zedge {hat}, I might fix zem for you. Uzeful for wayfarerz.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "hat") or MsgContains(message, "second addon") then
		if state < 2 then
			npcHandler:say("Why zhould I help YOU? Do zomething for me firzt!", npc, creature)
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say("You want me to fix a zedge hat for you?", npc, creature)
			npcHandler:setTopic(playerId, 3)
		end
	elseif MsgContains(message, "cape") or MsgContains(message, "first addon") then
		if state < 2 then
			npcHandler:say("Why zhould I help YOU? Do zomething for me firzt!", npc, creature)
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say("You want me to fix an old cape for you?", npc, creature)
			npcHandler:setTopic(playerId, 4)
		end
	elseif MsgContains(message, "addon") or MsgContains(message, "addons") or MsgContains(message, "outfit") then
		npcHandler:say("Addonz? Maybe, if you do zomething for me firzt. Then I can fix a {hat} or a {cape}.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "yes") then
		if topic == 1 then
			F.start(player)
			npcHandler:say("Good. Now go, and don't come back wizout ze zree pagez!", npc, creature)
		elseif topic == 2 then
			if F.finish(player) then
				npcHandler:say({
					"Give zem to me! ... <she reads the pages, her hands are shaking> ...",
					"Zo it iz true. He left everyzing to ze spiritz of thiz mountain. Everyzing! And now zey whisper at night, zey know I have read it. ...",
					"Ze spirit will get you too, you know. Here, take thiz for your trouble, and leave me alone. If you bring me an old {cape} or a zedge {hat}, I might fix zem.",
				}, npc, creature)
			else
				npcHandler:say("Liar! You do not have zem!", npc, creature)
			end
		elseif topic == 3 then
			addonTrade(npc, creature, player, 2)
		elseif topic == 4 then
			addonTrade(npc, creature, player, 1)
		end
		npcHandler:setTopic(playerId, 0)
	elseif MsgContains(message, "no") and topic > 0 then
		npcHandler:say("Zen go away.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	end
	return true
end

keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "Job? I am an old crone, and I want to be left alone!" })
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
