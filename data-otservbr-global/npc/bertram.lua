local internalNpcName = "Bertram"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 132,
	lookHead = 57,
	lookBody = 114,
	lookLegs = 0,
	lookFeet = 114,
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
	-- FAMILY: Kissing a Pig Quest lines first (lib/others/family_kissing_pig.lua)
	if FamilyKissing and FamilyKissing.onSay("bertram", npcHandler, npc, creature, message, type) then
		return
	end
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

	if MsgContains(message, "key") then
		-- FAMILY: archpostwoman or higher (Rank 5+); otherwise his refusal from TibiaWiki BR
		local familyRefuse = Family and Family.thievesGuild and player:getStorageValue(Storage.Quest.U8_2.TheThievesGuildQuest.Mission06) == 1
		local headItem = player:getSlotItem(CONST_SLOT_HEAD)
		local uniform = headItem and headItem.itemid == 3576 and player:getStorageValue(Storage.Quest.U7_24.ThePostmanMissions.Rank) >= 5
		if familyRefuse and not (uniform and player:getSex() == PLAYERSEX_FEMALE) then
			npcHandler:say("Are you insane?! I'd never misuse the trust place upon me and hand you Master Loveless's key! I'm not as bribable as Herbert, he is such a bad example of a postman!", npc, creature)
		elseif player:getStorageValue(Storage.Quest.U8_2.TheThievesGuildQuest.Mission06) == 1 and player:getSex() == PLAYERSEX_FEMALE then
			if uniform then
				player:addItem(7934, 1)
				player:setStorageValue(Storage.Quest.U8_2.TheThievesGuildQuest.Mission06, 2)
				npcHandler:say(
					"Oh my! You look so great in your uniform! \z
				You archpostwomen are not only daring but also beautiful. \z
				Here take it, that's the key you wanted. Just promise to visit me now and then!",
					npc,
					creature
				)
			end
		end
	end
	return true
end

-- FAMILY: greeting from TibiaWiki BR
if Family and Family.thievesGuild then
	npcHandler:setMessage(MESSAGE_GREET, "Hello. Please don't interrupt me for too long!")
end
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
