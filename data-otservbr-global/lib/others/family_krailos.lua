-- Gaia Family server: Krailos Quest (2026-11-22, asked by Rodrigo after a review: upstream had none
-- of the seven Krailos missions; the NPCs only greeted or traded, the quest items did nothing, Larek's
-- depot grille let everybody in and Ghorza and Mugruu traded with anyone).
--
-- Sources: TibiaWiki BR "Krailos Quest" (our backup, saved 2026-11-08, with its screenshots) and
-- TibiaWiki EN "Krailos Quest/Spoiler" (method, transcripts, messages) and the NPC transcript pages
-- (lore words: lib/others/family_krailos_lore.lua). Lines marked "ours" are on neither wiki.
--
-- Missions (quest log "Krailos Quest"):
--   Hungry New World (Larek): skull orchid, ancient map, ancient amulet; reward: the depot below
--   his tent ("You don't have Larek's permission to go down there!" before).
--
-- Player storages: Storage.Quest.U10_90.Krailos (45273-45298, the update's own block).
-- World objects: scripts/family/krailos.lua; the empty botanist's container is the Explorer
-- Society's item (scripts/quests/the_explorer_society/actions_botanist.lua calls useOrchid).
-- NPC files that call this: larek, ghorza, vuzrog, grubokk, nibble, an_imprisoned_goblin,
-- a_goblin_exile, a_runaway_goblin (ours), mugruu.
-- Switch: Family.krailos (false = the NPCs, objects and grille as upstream).

Family = Family or {}
Family.krailos = true

FamilyKrailos = FamilyKrailos or {}
local K = FamilyKrailos
local S = Storage.Quest.U10_90.Krailos
K.S = S

function K.enabled()
	return Family.krailos == true
end

-- Items
K.CONTAINER_EMPTY = 4867 -- botanist's container (shared with The Explorer Society)
K.CONTAINER_ORCHID = 22704 -- botanist's container with a skull orchid
K.SKULL_ORCHID = 22645
K.ANCIENT_MAP = 22705
K.ANCIENT_AMULET = 22746

-- Places
K.SARCOPHAGUS = { Position(33538, 31621, 8), Position(33538, 31622, 8) } -- the Nightmare room (EN: north-west)
K.BIRD_NEST = Position(33648, 31741, 7) -- south of the village (EN 33648,31740; the nest on our map)
K.GRILLE = Position(33657, 31657, 7) -- Larek's tent, action id 19049
K.GRILLE_BACK = Position(33658, 31657, 7) -- where a refused player stands (ours)

function K.get(player, key)
	local v = player:getStorageValue(key)
	return v < 0 and 0 or v
end

function K.set(player, key, value)
	player:setStorageValue(key, value)
end

function K.startLog(player)
	if K.get(player, S.Questline) < 1 then
		K.set(player, S.Questline, 1)
	end
end

local function has(player, id)
	return player:getItemCount(id) > 0
end

-- ---------------------------------------------------------------------------
-- NPC talk: quest words first (each NPC's handler), then the lore words of the
-- EN transcripts (longest keyword first, whole words).
-- ---------------------------------------------------------------------------

K.handlers = {}
K.npcs = {
	["Larek"] = { greet = "Greetings!", farewell = "Farewell." },
	["Ghorza"] = { greet = "Hello, scraggy human.", farewell = "Take care of evil spirits." },
	["Vuzrog"] = { greet = "Hello, tasty little snack.", farewell = "Push off!" },
	["Grubokk"] = { greet = "Huh! Talking food! Hello!", farewell = "Hur! <belch>" },
	["Nibble"] = { greet = "Hello, hu-man. <sniff> <sniff> Vile smell about you. Remind me of ogre Grubokk. Hmmm. Or maybe it is ogre soup.", farewell = "<sigh> Poor goblin always left behind." },
	["An Imprisoned Goblin"] = { greet = "What want with starving goblin, hu-man?", farewell = "All go away." },
	["A Goblin Exile"] = { greet = "Hello, hu-man! Away put your weapon, I am meaning no harm.", farewell = "Goodbye, hu-man. Don't let ogres bite you." },
	["A Runaway Goblin"] = { greet = "Hu-man! Strange guest! What want? Say!", farewell = "Yes, please go!" },
	["Mugruu"] = { greet = "Hello tasty!", farewell = "Back off!" },
}

function K.contains(message, words)
	for _, w in ipairs(words) do
		if MsgContains(message, w) then
			return true
		end
	end
	return false
end

-- The lore answer for a message, or nil.
function K.lore(name, message)
	local list = FamilyKrailosLore and FamilyKrailosLore[name]
	if not list then
		return nil
	end
	local best, bestLen
	for _, entry in ipairs(list) do
		for _, word in ipairs(entry[1]) do
			if (not bestLen or #word > bestLen) and MsgContains(message, word) then
				best, bestLen = entry[2], #word
			end
		end
	end
	return best
end

function K.talk(name, npc, creature, message, npcHandler)
	local player = Player(creature)
	if not player then
		return true
	end
	local handler = K.handlers[name]
	if handler and handler(npc, player, message, npcHandler) then
		return true
	end
	local text = K.lore(name, message)
	if text then
		npcHandler:say(text, npc, creature)
		npcHandler:setTopic(player:getId(), 0)
	end
	return true
end

-- Called by each NPC file after its own callbacks.
function K.setupNpc(name, npcHandler)
	local info = K.npcs[name]
	if not info or not K.enabled() then
		return
	end
	npcHandler:setMessage(MESSAGE_GREET, info.greet)
	npcHandler:setMessage(MESSAGE_FAREWELL, info.farewell)
	npcHandler:setMessage(MESSAGE_WALKAWAY, info.farewell)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		if not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		return K.talk(name, npc, creature, message, npcHandler)
	end)
	if K.tradeRule[name] then
		npcHandler:setCallback(CALLBACK_ON_TRADE_REQUEST, function(npc, creature)
			local player = Player(creature)
			local refusal = player and K.tradeRule[name](player)
			if refusal then
				npcHandler:say(refusal, npc, creature)
				return false
			end
			return true
		end)
	end
end

-- name -> function(player) returning the refusal line, or nil when the NPC trades.
K.tradeRule = {}

-- ---------------------------------------------------------------------------
-- Hungry New World (Larek)
-- ---------------------------------------------------------------------------

local HNW = S.HungryNewWorld
local LAREK_OFFER, LAREK_ASK_ORCHID, LAREK_NEXT_MAP, LAREK_ASK_MAP, LAREK_NEXT_AMULET, LAREK_ASK_AMULET = 1, 2, 3, 4, 5, 6

local larek = {
	offer = {
		"Indeed there is something. As I may have mentioned I am a discoverer and explorer. I want to learn as much as possible about {Krailos} to write it down in a book. ...",
		"I already wrote an essay about the {ogres}, but I want to publish something more comprehensive. The problem is that I also have to play the role of a merchant here. ...",
		"If I don't provide the ogres with enough sweets like cookies and candy, the {chieftain}, {Vuzrog}, no longer will see my benefit for this village and eat me up. So I can't leave the village for too long. ...",
		"But you could. Would you go out and search something for me?",
	},
	orchid = {
		"That's wonderful! What you are looking for is a rare plant I call the skull orchid. The ogres told me about it. It supposedly has odd blooms that look like tiny skulls. ...",
		"I don't know where exactly you could find one, but according to {Ghorza} it only grows in dry and very secluded places. Take this container and if you find such a skull orchid, please store a sample of it inside and bring it back to me.",
	},
	askOrchid = "Have you found a sample of the skull orchid?",
	orchidDone = "Oh, brilliant! You made a very important contribution to botany and scientific taxonomy. Say, are you interested in another mission?",
	nextMap = "Say, are you interested in another mission?", -- ours (the end of the EN line)
	map = {
		"I'm glad you're so eager to bring forth not only botany but also archaeology! Well, I possibly told you that hundreds of years ago, Krailos was populated by a highly developed human culture. ...",
		"Its ruins are still visible at some places in the steppe, and underneath there are surprisingly well-preserved architectural complexes. I visited the place and took some interesting notes. ...",
		"But there has to be more. I'm sure I overlooked something. I suspect that somewhere down there is a secret room which might contain something of great interest. Perhaps it is accessible only by water.",
	},
	askMap = "Have you found the secret room in the ruins? Was there something of interest inside?",
	mapDone = {
		"What an ancient map! It must be hundreds of years old. Let me see, please. This is a map of Krailos and the surrouding ocean. Oh, that's incredible! They charted many nowadays completely unknown sea routes on this map! ...",
		"The lost culture must have been a seafaring nation, too. That's an entirely new insight for me. Oh, but there is still one thing. Would you help me one last time?",
	},
	nextAmulet = "Oh, but there is still one thing. Would you help me one last time?", -- the end of the EN line
	amulet = {
		"Thank you so much! Listen: When I was searching the northern ruins for the secret room, I already found something there. An ancient amulet, forged with remarkable artisanship. ...",
		"Bringing back such a precious artefact to the Explorer Society would be important for my reputation. Unfortunately a thieving steppe bird has stolen the amulet, probably because of the sparkling, colourful gems. ...",
		"It flew southward and I assume the thief brought the amulet to its nest. I know, finding the right tree in this vast grassland is like trying to find a needle in a haystack. But I'm sure you'll succeed.",
	},
	askAmulet = "Have you found the lost amulet?",
	amuletDone = "Well done! Thank you very much! You really brought forth my studies about Krailos! In return let me offer you a little convenience. You may use the depot I established here. Just use the entrance in my tent.",
	done = "You really brought forth my studies about Krailos! Remember, you may use the depot below my tent whenever you like.", -- ours
	notFound = "Hm, I don't see it. Please come back when you have it.", -- ours
	keepLooking = "Then please keep looking. I'm sure you'll succeed.", -- ours
	declined = "Pity. Perhaps another time, then.", -- ours
	lostContainer = "Oh, you lost the botanist's container? Here, take another one and store a sample of the skull orchid inside.", -- ours
}
K.larekLines = larek

function K.hungryDone(player)
	return K.get(player, HNW) >= 6
end

local function larekQuest(npc, player, npcHandler)
	local id = player:getId()
	local state = K.get(player, HNW)
	if state == 0 then
		npcHandler:say(larek.offer, npc, player)
		npcHandler:setTopic(id, LAREK_OFFER)
	elseif state == 1 then
		if not has(player, K.CONTAINER_ORCHID) and not has(player, K.CONTAINER_EMPTY) then
			player:addItem(K.CONTAINER_EMPTY, 1)
			npcHandler:say(larek.lostContainer, npc, player)
			npcHandler:setTopic(id, 0)
			return
		end
		npcHandler:say(larek.askOrchid, npc, player)
		npcHandler:setTopic(id, LAREK_ASK_ORCHID)
	elseif state == 2 then
		npcHandler:say(larek.nextMap, npc, player)
		npcHandler:setTopic(id, LAREK_NEXT_MAP)
	elseif state == 3 then
		npcHandler:say(larek.askMap, npc, player)
		npcHandler:setTopic(id, LAREK_ASK_MAP)
	elseif state == 4 then
		npcHandler:say(larek.nextAmulet, npc, player)
		npcHandler:setTopic(id, LAREK_NEXT_AMULET)
	elseif state == 5 then
		npcHandler:say(larek.askAmulet, npc, player)
		npcHandler:setTopic(id, LAREK_ASK_AMULET)
	else
		npcHandler:say(larek.done, npc, player)
		npcHandler:setTopic(id, 0)
	end
end

local function larekYes(npc, player, npcHandler, topic)
	local id = player:getId()
	npcHandler:setTopic(id, 0)
	if topic == LAREK_OFFER and K.get(player, HNW) == 0 then
		player:addItem(K.CONTAINER_EMPTY, 1)
		K.set(player, HNW, 1)
		K.startLog(player)
		npcHandler:say(larek.orchid, npc, player)
	elseif topic == LAREK_ASK_ORCHID and K.get(player, HNW) == 1 then
		if not player:removeItem(K.CONTAINER_ORCHID, 1) then
			npcHandler:say(larek.notFound, npc, player)
			return
		end
		K.set(player, HNW, 2)
		npcHandler:say(larek.orchidDone, npc, player)
		npcHandler:setTopic(id, LAREK_NEXT_MAP)
	elseif topic == LAREK_NEXT_MAP and K.get(player, HNW) == 2 then
		K.set(player, HNW, 3)
		npcHandler:say(larek.map, npc, player)
	elseif topic == LAREK_ASK_MAP and K.get(player, HNW) == 3 then
		if not player:removeItem(K.ANCIENT_MAP, 1) then
			npcHandler:say(larek.notFound, npc, player)
			return
		end
		K.set(player, HNW, 4)
		npcHandler:say(larek.mapDone, npc, player)
		npcHandler:setTopic(id, LAREK_NEXT_AMULET)
	elseif topic == LAREK_NEXT_AMULET and K.get(player, HNW) == 4 then
		K.set(player, HNW, 5)
		npcHandler:say(larek.amulet, npc, player)
	elseif topic == LAREK_ASK_AMULET and K.get(player, HNW) == 5 then
		if not player:removeItem(K.ANCIENT_AMULET, 1) then
			npcHandler:say(larek.notFound, npc, player)
			return
		end
		K.set(player, HNW, 6)
		npcHandler:say(larek.amuletDone, npc, player)
		K.checkCallOfTheWild(player)
	end
end

K.handlers["Larek"] = function(npc, player, message, npcHandler)
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	if K.contains(message, { "quest", "mission" }) then
		larekQuest(npc, player, npcHandler)
		return true
	end
	if K.larekWater and MsgContains(message, "water") then
		return K.larekWater(npc, player, npcHandler)
	end
	if topic ~= 0 and MsgContains(message, "yes") then
		larekYes(npc, player, npcHandler, topic)
		return true
	end
	if topic ~= 0 and MsgContains(message, "no") then
		if topic == LAREK_ASK_ORCHID or topic == LAREK_ASK_MAP or topic == LAREK_ASK_AMULET then
			npcHandler:say(larek.keepLooking, npc, player)
		else
			npcHandler:say(larek.declined, npc, player)
		end
		npcHandler:setTopic(id, 0)
		return true
	end
	return false
end

-- World objects (scripts/family/krailos.lua and the Explorer Society's botanist's container)

-- The empty botanist's container on a skull orchid. True when handled.
function K.useOrchid(player, container, toPosition)
	if not K.enabled() or K.get(player, HNW) ~= 1 then
		return false
	end
	container:transform(K.CONTAINER_ORCHID)
	toPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You carefully pick the skull orchid and put it into the botanist's container.") -- BR screenshot
	return true
end

function K.useSarcophagus(player)
	if not K.enabled() or K.get(player, HNW) ~= 3 or has(player, K.ANCIENT_MAP) then
		return false
	end
	player:addItem(K.ANCIENT_MAP, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found an ancient map.") -- ours
	return true
end

function K.useBirdNest(player)
	if not K.enabled() or K.get(player, HNW) ~= 5 or has(player, K.ANCIENT_AMULET) then
		return false
	end
	player:addItem(K.ANCIENT_AMULET, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You see something glittering between the eggs and pull an ancient amulet out of the bird nest.") -- EN, BR screenshot
	return true
end

-- Larek's grille: nil when the player may go down, else the refusal (EN Grille page).
function K.grilleRefusal(player)
	if not K.enabled() or K.hungryDone(player) then
		return nil
	end
	return "You don't have Larek's permission to go down there!"
end

-- ---------------------------------------------------------------------------
-- The Call of the Wild: all seven missions done (EN: at the same time in the quest log).
-- ---------------------------------------------------------------------------

K.finishedChecks = {
	function(player)
		return K.hungryDone(player)
	end,
}

function K.checkCallOfTheWild(player)
	if #K.finishedChecks < 7 then
		return -- the other missions are added by the later parts of the quest
	end
	for _, done in ipairs(K.finishedChecks) do
		if not done(player) then
			return
		end
	end
	player:addAchievement("The Call of the Wild")
end

-- ---------------------------------------------------------------------------
-- Quest log (lib/core/quests/catalog/062_krailos.lua)
-- ---------------------------------------------------------------------------

K.log = {
	hungry = {
		[1] = "Larek, the human merchant in the ogre village of Krailos, wants a sample of the rare skull orchid. Its blooms look like tiny skulls and it grows in dry and very secluded places. Use his botanist's container on one and bring it back to him.",
		[2] = "You brought Larek a sample of the skull orchid. Ask him for another mission.",
		[3] = "Larek suspects a secret room in the ruins of a lost human culture in the north-west of Krailos, perhaps only reachable by water. Take diving equipment, search the flooded ruins and bring him what you find there.",
		[4] = "You found an ancient map in the secret room and brought it to Larek. Ask him for his last mission.",
		[5] = "A thieving steppe bird stole Larek's ancient amulet and flew southward with it. Find its nest in a tree south of the village and bring the amulet back to him.",
		[6] = "You brought back Larek's ancient amulet. In return he lets you use the depot below his tent.",
	},
}
