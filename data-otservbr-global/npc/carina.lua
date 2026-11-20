local internalNpcName = "Carina"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 138,
	lookHead = 97,
	lookBody = 70,
	lookLegs = 94,
	lookFeet = 76,
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

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "precious necklace") then
		if player:getItemCount(7940) > 0 then
			-- FAMILY: TibiaWiki EN transcript lines
			if Family and Family.thievesGuild then
				npcHandler:say("Oh, so you want to buy that rare and precious necklace for 5000 gold?", npc, creature)
			else
				npcHandler:say("Would you like to buy my precious necklace for 5000 gold?", npc, creature)
			end
			npcHandler:setTopic(playerId, 1)
		end
	elseif MsgContains(message, "mouse") then
		npcHandler:say("Wha ... What??? Are you saying you've seen a mouse here??", npc, creature)
		npcHandler:setTopic(playerId, 2)
	elseif MsgContains(message, "yes") then
		if npcHandler:getTopic(playerId) == 1 then
			if player:removeMoneyBank(5000) then
				player:removeItem(7940, 1)
				player:addItem(7939, 1)
				if Family and Family.thievesGuild then
					npcHandler:say("Here it is. A friend of mine will be quite sad about that sale but business is business.", npc, creature)
				else
					npcHandler:say("Here you go kind sir.", npc, creature)
				end
				npcHandler:setTopic(playerId, 0)
			elseif Family and Family.thievesGuild then
				npcHandler:say("You don't have enough money.", npc, creature) -- ours
				npcHandler:setTopic(playerId, 0)
			end
		elseif npcHandler:getTopic(playerId) == 2 then
			if not player:removeItem(123, 1) then
				npcHandler:say("There is no mouse here! Stop talking foolish things about serious issues!", npc, creature)
				npcHandler:setTopic(playerId, 0)
				return true
			end

			player:setStorageValue(Storage.Quest.U8_1.WhatAFoolishQuest.ScaredCarina, 1)
			npcHandler:say("IIIEEEEEK!", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "no") then
		if npcHandler:getTopic(playerId) == 2 then
			npcHandler:say("Thank goodness!", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	end
	return true
end

-- FAMILY: greeting as in the TibiaWiki EN transcript ("I'm")
npcHandler:setMessage(MESSAGE_GREET, "Welcome, |PLAYERNAME|. I'm looking forward to trade with you.")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {
	{ itemName = "golden amulet", clientId = 3013, buy = 6600 },
	-- FAMILY: no precious necklace in her trade window (TibiaWiki BR list); she sells it in the quest dialogue
	{ itemName = "ruby necklace", clientId = 3016, buy = 3560 },
	{ itemName = "wedding ring", clientId = 3004, buy = 990, sell = 100 },
}
-- On buy npc shop message
npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end
-- On sell npc shop message
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost)
	player:sendTextMessage(MESSAGE_TRADE, string.format("Sold %ix %s for %i gold.", amount, name, totalCost))
end
-- On check npc shop message (look item)
npcType.onCheckItem = function(npc, player, clientId, subType) end

npcType:register(npcConfig)
