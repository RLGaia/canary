-- FAMILY: Eustacio's Spy Rat, the stealth mission of Rascacoon (A Pirate's Tail Quest, part 2c, 2026-11-11).
-- Ours, not upstream (Canary v3.6.1 has no such NPC). Lines from the TibiaWiki EN quest spoiler transcript
-- (kept word for word, Tibia's own spelling included); the farewell is ours. Look: the pirat outfit with
-- both addons in the colours of the EN picture (fitted on the client 15.11 sprites). The teleport next to
-- him (33855,31334,9, on the map) leads to the lever room; scripts/family/rascacoon_stealth.lua does the rest.
local internalNpcName = "Eustacio's Spy Rat"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0

npcConfig.outfit = {
	lookType = 1346,
	lookHead = 94,
	lookBody = 9,
	lookLegs = 87,
	lookFeet = 79,
	lookAddons = 3,
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

-- TibiaWiki EN, A Pirate's Tail Quest/Spoiler, transcript of the stealth mission
local lines = {
	{
		"loud",
		{
			"Been seen with creatures like thee might cause me loosing my head or even my {job}. Wouldn't even do so now if ol' Eustacio hadn't sent word an' cheese. ...",
			"Good for ye', he just recently did. Ye probably made some good progress on his behalf.",
		},
	},
	{ "job", "I am a proud pirate. A hungry proud pirat that isn't treated too well and with a liking to {people} who pay with good cheese." },
	{ "people", "Eustacio pays me good cheese for my invaluable {assistance}." },
	{
		"assistance",
		{
			"I got ye entrance to the secret laboratory complex and placed the enchanted rat {disguise} at the entrance. ...",
			"So ye can sneak in and sabotage the newest mouldy powder production, which ye should find in some chest in the lab.",
		},
	},
	{
		"disguise",
		{
			"It looks {convincing} in the dark or from distance. It won't fool anyone from close up, not to mention that the guards get suspicious if they don't smell a rat. ...",
			"Keep in mind that the magic will run out with time, so don't be too tardy.",
		},
	},
	{
		"convincing",
		{
			"Just stay out of lit areas and keep yer distance from the guards. ...",
			"If ye are lucky, the glowing bugs that they use as illumination lose their shining for a few moments and ye can use that to yer {advantage}.",
		},
	},
	{ "advantage", "Ye'll have to be sneaky and resourceful. Use the terrain to yer advantage. Ye might even have to do some climbing. If ye are not agile enough, better bring some parcels." },
}

local function creatureSayCallback(npc, creature, type, message)
	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	for _, entry in ipairs(lines) do
		if MsgContains(message, entry[1]) then
			npcHandler:say(entry[2], npc, creature)
			return true
		end
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Psssht! Not that {loud}!") -- EN
npcHandler:setMessage(MESSAGE_FAREWELL, "Off with ye, and quietly!") -- ours
npcHandler:setMessage(MESSAGE_WALKAWAY, "Off with ye, and quietly!") -- ours
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
