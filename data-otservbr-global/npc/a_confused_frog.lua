local internalNpcName = "A Confused Frog"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 224,
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

-- FAMILY: The Scatterbrained Sorcerer Quest (lib/others/family_sorcerer.lua): he only croaks until the
-- counterspell; "ribbit" greets him; the kiss, the counterspell and "human" move the quest on.
local function familyQuestOff()
	return not (FamilySorcerer and FamilySorcerer.enabled())
end
local function familyFrogTalks(player)
	return not FamilySorcerer or FamilySorcerer.frogTalks(player)
end
if FamilySorcerer then
	FamilySorcerer.setGreeter(npcHandler, FamilySorcerer.confusedFrogGreeting, { "ribbit" })
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		if not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		FamilySorcerer.confusedFrogSay(npc, creature, message, npcHandler)
		return true
	end)
end

-- Dialogue keywords the NPC answers on the official server
keywordHandler:addKeyword({ "eeny meeny miny moe ribbit ribbit head to toe" }, StdModule.say, { npcHandler = npcHandler, text = "........ ... Ri..... ... Ritual didn't work. RIBBIT?! I can speak the human language again! Ribbit! Well, at least sometimes it seems. Ribbit. And who the heck are you??" }, familyQuestOff) -- FAMILY: the quest answers it
keywordHandler:addKeyword({ "assistant" }, StdModule.say, { npcHandler = npcHandler, text = "I don't want to be an assistant anymore. Ribbit. I just want my dream pond." }, familyFrogTalks) -- FAMILY: only after the counterspell
keywordHandler:addKeyword({ "eclesius" }, StdModule.say, { npcHandler = npcHandler, text = "That old fool! He should be locked up with his weird theories and ideas and forced to study some serious magic! Rrrribbit!" }, familyFrogTalks) -- FAMILY: only after the counterspell
keywordHandler:addKeyword({ "ribbit" }, StdModule.say, { npcHandler = npcHandler, text = "Ribbit?!" }, familyQuestOff) -- FAMILY: the quest answers it (the counterspell has "ribbit" in it)
keywordHandler:addKeyword({ "player" }, StdModule.say, { npcHandler = npcHandler, text = "Are you? I see. I saw you poking around here earlier. Ribbit. Well whatever you were trying to do, I'm not sure it was successful. Ribbit. What was that princess thing all about, anyway??" }, familyQuestOff) -- FAMILY: the quest answers it
keywordHandler:addKeyword({ "samael" }, StdModule.say, { npcHandler = npcHandler, text = "Yep, he told me one day that that was his name. In the tone of voice that makes your ears almost explode and singes your hair." }, familyFrogTalks) -- FAMILY: only after the counterspell
keywordHandler:addKeyword({ "human" }, StdModule.say, { npcHandler = npcHandler, text = "You know... being a frog isn't that bad. Ribbit. I don't want to be a human again. I just wish I could get out of this cage and live by a lovely little pond." }, familyQuestOff) -- FAMILY: the quest answers it
keywordHandler:addKeyword({ "magic" }, StdModule.say, { npcHandler = npcHandler, text = "Magic, pah. Ribbit. I don't need magic. I just want some flies, actually. Ribbit." }, familyFrogTalks) -- FAMILY: only after the counterspell
keywordHandler:addKeyword({ "demon" }, StdModule.say, { npcHandler = npcHandler, text = "That demon is called ribbit. Erm, no, I mean Samael. He is one REALLY annoyed demon overlord, but we get along okay. Not sure if I'd let him out of there though. Ribbit." }, familyFrogTalks) -- FAMILY: only after the counterspell
keywordHandler:addKeyword({ "kiss" }, StdModule.say, { npcHandler = npcHandler, text = "..... ..." }, familyQuestOff) -- FAMILY: the quest answers it
keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "Well... ribbit... my name is Turian. But that doesn't really matter anymore." }, familyFrogTalks) -- FAMILY: only after the counterspell
keywordHandler:addKeyword({ "frog" }, StdModule.say, { npcHandler = npcHandler, text = "You know... being a frog isn't that bad. Ribbit. I don't want to be a human again. I just wish I could get out of this cage and live by a lovely little pond." }, familyQuestOff) -- FAMILY: the quest answers it
keywordHandler:addKeyword({ "pond" }, StdModule.say, { npcHandler = npcHandler, text = "I like the pond north of Thais. It's a really cosy place. Not just for humans, but especially for frogs. Ribbit." }, familyFrogTalks) -- FAMILY: only after the counterspell
keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I used to be Eclesius' assistant! Argh! Then - ribbit - one of his crazy experimental spells backfired and hit me. That's when I lost my job I guess. Ribbit." }, familyFrogTalks) -- FAMILY: only after the counterspell

npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
