local internalNpcName = "Sinatuki"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 260,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
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

-- FAMILY: Sinatuki fixed (2026-10-20). Upstream needed 100 fish of ONE kind,
-- gave the 5 shards again every time and never gave the Jamjam achievement.
-- As in Tibia (TibiaWiki "Sinatuki", "Jamjam"): she eats green perches and
-- rainbow trouts, any mix; at the 100th fish she gives 5 shards and Jamjam,
-- once. Afterwards she wants nothing more. Her other Chakoya lines were added.
npcHandler:setMessage(MESSAGE_GREET, "Sajoq, |PLAYERNAME|!")
npcHandler:setMessage(MESSAGE_FAREWELL, "Gukaju, jinuma!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Gukaju, jinuma!")

keywordHandler:addKeyword({ "chuqua" }, StdModule.say, { npcHandler = npcHandler, text = "Chuqua jamjam!! Tiyopa Sinatuki?" })
keywordHandler:addKeyword({ "jinuma" }, StdModule.say, { npcHandler = npcHandler, text = "Su gura jinuma. Si gura chakoya." })
keywordHandler:addKeyword({ "sinatuki" }, StdModule.say, { npcHandler = npcHandler, text = "Nupi, si gura Sinatuki! Sinatuki jusipa! Jusipa!!" })
keywordHandler:addKeyword({ "jusipa" }, StdModule.say, { npcHandler = npcHandler, text = "Nupi, nupi!! Tiyopa Sinatuki chuqua! Chuqua, chuqua!!!!" })
keywordHandler:addKeyword({ "tiyopa" }, StdModule.say, { npcHandler = npcHandler, text = "Nupi, tiyopa chuqua pa Sinatuki!" })
keywordHandler:addKeyword({ "jamjam" }, StdModule.say, { npcHandler = npcHandler, text = "Nupi, nupi! Sinatuki gura jusipa! Jinuma ji chuqua pa Sinatuki??" })
keywordHandler:addKeyword({ "taluka" }, StdModule.say, { npcHandler = npcHandler, text = "Yuk taluka?? Chuqua? Ahhh!" })
keywordHandler:addKeyword({ "nguraka" }, StdModule.say, { npcHandler = npcHandler, text = "Kisavuta!" })
keywordHandler:addKeyword({ "kisavuta" }, StdModule.say, { npcHandler = npcHandler, text = "Nguraka!" })

local FISH_NEEDED = 100
local goodFish = { 7158, 7159 } -- rainbow trout, green perch
local otherFish = { 3578, 3579, 3580, 3581, 901 } -- fish, salmon, northern pike, shrimp, marlin (she spits them out)

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	if not player then
		return false
	end

	if MsgContains(message, "nupi") then
		-- Only someone who learned some Chakoya on the Ice Islands can understand her.
		if player:getStorageValue(Storage.Quest.U8_0.BarbarianTest.Questline) < 3 or player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) < 5 then
			npcHandler:say("Juk?? <looks at you, puzzled>", npc, creature)
			return true
		end

		local storage = Storage.Quest.FamilySinatuki.Fish
		local eaten = math.max(0, player:getStorageValue(storage))
		if eaten >= FISH_NEEDED then
			npcHandler:say("Nupi, nupi! Sinatuki gura jusipa! <she pats her belly, she needs nothing else>", npc, creature)
			return true
		end

		local have = 0
		for _, id in ipairs(goodFish) do
			have = have + player:getItemCount(id)
		end
		if have == 0 then
			for _, id in ipairs(otherFish) do
				if player:getItemCount(id) > 0 then
					npcHandler:say("Yuk pa chuqua?? Tiyopa taluka chuqua! <tries the fish and spits it out>", npc, creature)
					return true
				end
			end
			npcHandler:say("Juk?? Jinuma ji quata chuqua!", npc, creature)
			return true
		end

		local take = math.min(have, FISH_NEEDED - eaten)
		local left = take
		for _, id in ipairs(goodFish) do
			local count = math.min(left, player:getItemCount(id))
			if count > 0 and player:removeItem(id, count) then
				left = left - count
			end
		end
		eaten = eaten + (take - left)
		player:setStorageValue(storage, eaten)

		if eaten >= FISH_NEEDED then
			player:addItem(7290, 5)
			player:addAchievement("Jamjam")
			npcHandler:say("Jinuma, suvituka siq chuqua!! Nguraka, nguraka! <happily takes the food from you and gives you five glimmering crystals>", npc, creature)
		else
			npcHandler:say("Jinuma, suvituka siq chuqua!! Nguraka, nguraka! <happily takes the food from you>", npc, creature)
			player:sendTextMessage(MESSAGE_LOOK, string.format("Sinatuki has eaten %d of %d fish.", eaten, FISH_NEEDED))
		end
		return true
	end
	return true
end

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
