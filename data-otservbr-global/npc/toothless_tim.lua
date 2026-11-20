local internalNpcName = "Toothless Tim"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 128,
	lookHead = 76,
	lookBody = 20,
	lookLegs = 116,
	lookFeet = 95,
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
	if FamilyKissing and FamilyKissing.onSay("tim", npcHandler, npc, creature, message, type) then
		return
	end
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

-- Dialogue keywords the NPC answers on the official server
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "Mhrm buchhh acha hnnn." })
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "Glgl nhhh mahmooo glll." })
keywordHandler:addKeyword({ "kiss" }, StdModule.say, { npcHandler = npcHandler, text = "Shmmm gahhh hnn uhhk hnm bahh." })
keywordHandler:addKeyword({ "day" }, StdModule.say, { npcHandler = npcHandler, text = "A splendid day for a fancy conversation." })

-- FAMILY: Kissing a Pig Quest: he is understood only by the drunk (TibiaWiki EN; three drinks); the
-- sober greeting is ours (lib/others/family_kissing_pig.lua)
npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
	local player = Player(creature)
	if player and FamilyKissing and Family.kissingPig then
		npcHandler:setMessage(MESSAGE_GREET, FamilyKissing.isDrunk(player) and FamilyKissing.timDrunkGreet or FamilyKissing.timSoberGreet)
	end
	return true
end)
if Family and Family.kissingPig and FamilyKissing then
	npcHandler:setMessage(MESSAGE_FAREWELL, FamilyKissing.timFarewell)
end

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
