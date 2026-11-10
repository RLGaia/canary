local internalNpcName = "Zurak"
local npcType = Game.createNpcType("Zurak (Arena)")
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 114,
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

local TheNewFrontier = Storage.Quest.U8_54.TheNewFrontier
local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	-- FAMILY: TibiaWiki BR, Zurak takes a winner back to the reward room of the
	-- arena while the armor or a chest is still waiting there; upstream had no
	-- way back (2026-11-09, data-otservbr-global/lib/others/family_new_frontier.lua)
	if MsgContains(message, "reward") and Family.newFrontierAnswers then
		if FamilyNewFrontier.rewardMissing(player) then
			npcHandler:say("Me can alzzo guide you to rewardroom if you did not collect your reward for fighting yet. You want?", npc, creature)
			npcHandler:setTopic(playerId, 2)
		else
			npcHandler:unGreet(npc, creature)
		end
		return true
	elseif MsgContains(message, "yes") and npcHandler:getTopic(playerId) == 2 then
		npcHandler:setTopic(playerId, 0)
		if FamilyNewFrontier.rewardMissing(player) then
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:teleportTo(FamilyNewFrontier.rewardRoom)
			FamilyNewFrontier.rewardRoom:sendMagicEffect(CONST_ME_TELEPORT)
		end
		return true
	end

	if MsgContains(message, "trip") or MsgContains(message, "passage") or MsgContains(message, "boat") then -- FAMILY: "boat" (EN transcript)
		if player:getStorageValue(TheNewFrontier.Questline) >= 24 then
			npcHandler:say("You want trip to Izzle of Zzao?", npc, creature)
			npcHandler:setTopic(playerId, 1)
		else
			npcHandler:say("You need permission to travel to.", npc, creature)
		end
	elseif MsgContains(message, "yes") then
		if npcHandler:getTopic(playerId) == 1 then
			npcHandler:say("It'zz done your travel to.", npc, creature)
			local destination = Position(33158, 31227, 7)
			player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
			player:teleportTo(destination)
			destination:sendMagicEffect(CONST_ME_TELEPORT)
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "no") then
		if npcHandler:getTopic(playerId) == 1 then
			npcHandler:say("Zzoftzzkinzz zzo full of fear.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "hurry") or MsgContains(message, "job") then
		npcHandler:say("Me zzimple ferryman. I arrange {trip} to Zzao.", npc, creature)
		npcHandler:setTopic(playerId, 0)
	end
	return true
end
-- FAMILY: TibiaWiki EN transcript keywords (upstream had none, 2026-11-10)
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "Me Zurak." })
keywordHandler:addKeyword({ "lizards" }, StdModule.say, { npcHandler = npcHandler, text = "Me people rule zzhe whole land. If you hurt me, all my people will come for you!" })
keywordHandler:addKeyword({ "lizard" }, StdModule.say, { npcHandler = npcHandler, text = "Me people rule zzhe whole land. If you hurt me, all my people will come for you!" })
keywordHandler:addKeyword({ "dragon" }, StdModule.say, { npcHandler = npcHandler, text = "Zzhe mighty dragonzz are our rulerzz. One dragon can wipe out all our people! Zzo obey when dragon or emizzary are talking! You obey or dead!" })
keywordHandler:addKeyword({ "dragons" }, StdModule.say, { npcHandler = npcHandler, text = "Zzhe mighty dragonzz are our rulerzz. One dragon can wipe out all our people! Zzo obey when dragon or emizzary are talking! You obey or dead!" })
keywordHandler:addKeyword({ "ztiss" }, StdModule.say, { npcHandler = npcHandler, text = "Ztiss high mighty emizzary of dragon kingzz! When Ztiss zzpeak all obey!" })
keywordHandler:addKeyword({ "tournament" }, StdModule.say, { npcHandler = npcHandler, text = "Tournament important izz. Many like you come to fight. Only bezzt of bezzt are allowed to fight. Many try. Zzhinking zzhem being bezzt. Mozzt end up dead! Tournament izz not for zzhe weak." })

-- FAMILY: EN transcript greeting and farewells (upstream used the default ones, 2026-11-09)
npcHandler:setMessage(MESSAGE_GREET, "{Hurry} before zzomeone will zee uzz.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Yezz, zztrange creature leave Zurak.")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Zurak allwayzz zzo much to do.")
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
