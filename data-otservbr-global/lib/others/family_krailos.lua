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
--   The Great Hunger (Ghorza, "mission"): gourd + shark teeth (floating green flask, once a day,
--   back at 00:00) + 5 onyx chips; paint (voodoo lily pollen + hatched dragon's nest shells, red
--   oil); shake the painted rattle at three ritual sites; catch the sleeping hyaena (its den and A
--   Runaway Goblin's hideout are missing on our map: world/custom/family-krailos.otbm); repair the
--   four protection runes. Reward: onyx pendant and Ghorza's shop ("No, Ghorza no trading with
--   humans." before, EN).
--   Quenching the Thirst (Ghorza and Larek, "water"): 5 water elemental essences per carafe, 6
--   carafes on the purple salt of the dry salt sea next to Ghorza fill it (dirty water, server
--   message); Larek's golden quartz powder (hoe on golden quartzes), 30 into the lake clean it.
--   Reward: shaggy ogre bag. Can only be started while the lake is dry (BR, EN). The lake and the
--   player's counters last one game day (06:00, the daily stop; EN: server save resets the
--   progress; Rodrigo 2026-11-22 "until 06:00", Tibia: a few days). Ours, so two players are not
--   blocked: when the lake already holds water (the other player filled it today), carafes and
--   powder still count for you.
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

-- fallback: the NPC file's own callback (Ghorza's shop categories), asked last and only when
-- the NPC trades with the player.
function K.talk(name, npc, creature, message, npcHandler, fallback)
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
		return true
	end
	if fallback then
		local refusal = K.tradeRule[name] and K.tradeRule[name](player)
		if refusal then
			if K.shopWords[name] and K.contains(message, K.shopWords[name]) then
				npcHandler:say(refusal, npc, creature)
			end
			return true
		end
		return fallback(npc, creature, nil, message)
	end
	return true
end

-- Words that open a part of an NPC's shop (answered with the refusal before the quest).
K.shopWords = { ["Ghorza"] = { "potions", "runes" } }

-- Called by each NPC file after its own callbacks. opts.fallback: see K.talk.
function K.setupNpc(name, npcHandler, opts)
	local info = K.npcs[name]
	if not info or not K.enabled() then
		return
	end
	opts = opts or {}
	npcHandler:setMessage(MESSAGE_GREET, info.greet)
	npcHandler:setMessage(MESSAGE_FAREWELL, info.farewell)
	npcHandler:setMessage(MESSAGE_WALKAWAY, info.farewell)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		if not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		return K.talk(name, npc, creature, message, npcHandler, opts.fallback)
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
-- Days: game day (server save 06:00) for the salt lake, next 00:00 for the daily waits
-- (Rodrigo 2026-11-22: like the boss cooldowns; Tibia: 20 hours).
-- ---------------------------------------------------------------------------

function K.gameDay(now)
	return tonumber(os.date("%Y%m%d", (now or os.time()) - 6 * 60 * 60))
end

function K.nextMidnight(now)
	local d = os.date("*t", now or os.time())
	return os.time({ year = d.year, month = d.month, day = d.day + 1, hour = 0, min = 0, sec = 0 })
end

-- ---------------------------------------------------------------------------
-- The Great Hunger (Ghorza)
-- ---------------------------------------------------------------------------

local GH = S.GreatHunger
K.GOURD = 22651
K.RATTLING_GOURD = 22650
K.PAINTED_RATTLE = 22190
K.SHARK_TEETH = 22649
K.ONYX_CHIP = 22193
K.RED_OIL = 22661
K.POLLEN = 22656
K.EGG_SHELLS = 22659
K.GREY_BLUE_POWDER = 22660
K.RED_PAINT = 22652
K.HYAENA_TRAP = 22662
K.TRAPPED_HYAENA = 22663
K.SLEEPING_HYAENA = 22664
K.ONYX_PENDANT = 22195
K.VOODOO_LILY = 22648
K.DRAGON_NEST = 22676 -- the hatched dragon's nests on Krailos (EN 33690,31782,6)
K.FLOATING_FLASK = 22658 -- in the water on the way to the water elementals (33516,31592,7)

-- Ritual sites for the painted gourd rattle (EN: stand next to the three skulls, near the banner
-- totem pole in the cactus forest, inside the dragon ribcage). Squares from our map.
K.SITES = {
	{ bit = 1, from = Position(33615, 31604, 7), to = Position(33617, 31606, 7) }, -- three skulls near the ruins
	{ bit = 2, from = Position(33709, 31632, 7), to = Position(33713, 31636, 7) }, -- large totem pole (banner)
	{ bit = 4, from = Position(33616, 31739, 7), to = Position(33621, 31740, 7) }, -- inside the dragon ribcage
}

-- Protection runes: the set that fits, the square it goes on (BR/EN) and the placed stones.
K.RUNES = {
	{ bit = 1, set = 22669, pos = Position(33633, 31635, 7) }, -- north: two stones (BR and EN)
	{ bit = 2, set = 22668, pos = Position(33670, 31671, 7) }, -- east: corner (BR; EN one square east)
	{ bit = 4, set = 22665, pos = Position(33645, 31695, 7) }, -- south: up (BR and EN)
	{ bit = 8, set = 22667, pos = Position(33599, 31663, 7) }, -- west: single stone (BR)
	{ bit = 16, set = 22666, pos = Position(33600, 31662, 7) }, -- west: right (EN)
}
K.RUNES_ALL = 31
K.SITES_ALL = 7

local function bitSet(value, bit)
	return value % (bit * 2) >= bit
end
K.bitSet = bitSet

local ghorza = {
	offer = {
		"Ghorza feels that spirits restless. If spirits troubled, {Great Hunger} upset, too. That dangerous. But Ghorza knows reason. Some shrines damaged. Being defiled now. Site must be purged to make spirits calm again. ...",
		"But Ghorza having to do many things here in village and shrines far away. Strewn about steppe. You helping Ghorza with upset spirits, little human? That would be decent reason not to eat you. You helping?",
	},
	gourd = {
		"You clever chap. Ghorza explaining what to do. Taking this gourd. Preparing it so it becomes shamanic rattle. Such rattles calming evil spirits if used in right place. Find {shark teeth} and {onyx chips}. ...",
		"Need as many chips as are fingers on one of your hands. Fill teeth and splinters into gourd. Then come back.",
	},
	paint = {
		"Ah, you made gourd rattle! Yes, sound good, will please upset spirits. But now, rattle has to be painted. You mixing shamanic paste. Gather pollen of a {voodoo lily} and some {dragon egg} shells. ...",
		"Mixing together and then mingling with this red oil. Painting on gourd runes you see in front of Ghorza's tent.",
	},
	sites = {
		"You paint rattle. Very good, tasty human. Now you go, purging defiled ritual sites. There are three. One is big dragon skeleton near high mountains. One is in cactus forests. Last is at salt sea near strange ruins. ...",
		"But know: If rattle is used at other place than ritual site, spirits might be upset. Be careful.",
	},
	hyaena = {
		"Yes, you purge defiled ritual sites! Ghorza feels, spirits calm again. If spirits quiet, Great Hunger also at ease. But ogres not sure yet. Ghorza must make ritual for Great Hunger. ...",
		"Problem: Ghorza lost totem animal. Totem is cuddly hyaena and ran away. Without totem animal Ghorza not making ritual. You finding hyaena and catch it. But use this net, hyaena savage.",
	},
	runes = {
		"Little human bringing back hyaena! Ghorza happy! Ghorza now preparing ritual. But one thing left to do. Protection runes around village not complete. Single stones missing, stolen by thievish steppe birds or naughty ogrelings. ...",
		"Ghorza preparing ritual and little human fixing runes. They on each side of village. You see complete runes here between tents on floor. Look at runes inside village so you know how fixing runes outside. Here, take stones.",
	},
	reward = {
		"Protection Runes fixed, Ghorza feels! Little human done things very well. Now Ghorza will make ritual and appeasing Great Hunger. Village will be safe. Ghorza thanks useful human! Take this. Will protect against evil spirits. ...",
		"And if need some shamanic brew for healing or magic or some runes, you ask Ghorza. Ghorza can {sell}.",
	},
	-- ours (not on the wikis)
	waitGourd = "Gourd not rattling yet. Fill shark teeth and five onyx chips into gourd, then come back.",
	waitPaint = "Rattle not painted yet. Mix voodoo lily pollen and dragon egg shells, mingle with red oil and paint rattle.",
	waitSites = "Spirits still upset. Purge all three ritual sites with painted rattle.",
	waitHyaena = "No hyaena with you. Find Ghorza's totem animal and catch it with net.",
	waitRunes = "Runes still broken. Fix protection runes on each side of village. If you lost stones, ask Ghorza for {lost runes}.",
	lostItem = "You lost it? Clumsy human. Here, take new one.",
	lostRunes = "Clumsy little human! Here, take stones again.",
	noLostRunes = "You having all stones Ghorza gave you.",
	done = "Great Hunger at ease now. Village safe. Ghorza thanks useful human.",
	declined = "Hmpf. Then go away, little human.",
	noTrade = "No, Ghorza no trading with humans.", -- EN
}
K.ghorzaLines = ghorza
local GH_OFFER = 11

function K.hungerDone(player)
	return K.get(player, GH) >= 6
end

local function giveIfLost(player, npc, npcHandler, id, alsoOk)
	for _, other in ipairs(alsoOk or {}) do
		if has(player, other) then
			return false
		end
	end
	if has(player, id) then
		return false
	end
	player:addItem(id, 1)
	npcHandler:say(ghorza.lostItem, npc, player)
	return true
end

local function ghorzaMission(npc, player, npcHandler)
	local id = player:getId()
	local state = K.get(player, GH)
	npcHandler:setTopic(id, 0)
	if state == 0 then
		npcHandler:say(ghorza.offer, npc, player)
		npcHandler:setTopic(id, GH_OFFER)
	elseif state == 1 then
		if has(player, K.RATTLING_GOURD) then
			player:addItem(K.RED_OIL, 1)
			K.set(player, GH, 2)
			npcHandler:say(ghorza.paint, npc, player)
		elseif not giveIfLost(player, npc, npcHandler, K.GOURD) then
			npcHandler:say(ghorza.waitGourd, npc, player)
		end
	elseif state == 2 then
		if has(player, K.PAINTED_RATTLE) then
			K.set(player, GH, 3)
			K.set(player, S.GreatHungerSites, 0)
			npcHandler:say(ghorza.sites, npc, player)
		elseif not has(player, K.RATTLING_GOURD) then
			if not giveIfLost(player, npc, npcHandler, K.GOURD) then
				npcHandler:say(ghorza.waitGourd, npc, player)
			end
			K.set(player, GH, 1)
		elseif not giveIfLost(player, npc, npcHandler, K.RED_OIL, { K.RED_PAINT }) then
			npcHandler:say(ghorza.waitPaint, npc, player)
		end
	elseif state == 3 then
		if K.get(player, S.GreatHungerSites) == K.SITES_ALL then
			player:addItem(K.HYAENA_TRAP, 1)
			K.set(player, GH, 4)
			npcHandler:say(ghorza.hyaena, npc, player)
		elseif not has(player, K.PAINTED_RATTLE) then
			player:addItem(K.PAINTED_RATTLE, 1)
			npcHandler:say(ghorza.lostItem, npc, player)
		else
			npcHandler:say(ghorza.waitSites, npc, player)
		end
	elseif state == 4 then
		if player:removeItem(K.TRAPPED_HYAENA, 1) then
			for _, r in ipairs(K.RUNES) do
				player:addItem(r.set, 1)
			end
			K.set(player, S.GreatHungerRunes, 0)
			K.set(player, GH, 5)
			npcHandler:say(ghorza.runes, npc, player)
		elseif not giveIfLost(player, npc, npcHandler, K.HYAENA_TRAP) then
			npcHandler:say(ghorza.waitHyaena, npc, player)
		end
	elseif state == 5 then
		if K.get(player, S.GreatHungerRunes) == K.RUNES_ALL then
			player:addItem(K.ONYX_PENDANT, 1)
			K.set(player, GH, 6)
			npcHandler:say(ghorza.reward, npc, player)
			K.checkCallOfTheWild(player)
		else
			npcHandler:say(ghorza.waitRunes, npc, player)
		end
	else
		npcHandler:say(ghorza.done, npc, player)
	end
end

local function ghorzaLostRunes(npc, player, npcHandler)
	if K.get(player, GH) ~= 5 then
		return false
	end
	local placed = K.get(player, S.GreatHungerRunes)
	local given = false
	for _, r in ipairs(K.RUNES) do
		if not bitSet(placed, r.bit) and not has(player, r.set) then
			player:addItem(r.set, 1)
			given = true
		end
	end
	npcHandler:say(given and ghorza.lostRunes or ghorza.noLostRunes, npc, player)
	return true
end

K.tradeRule["Ghorza"] = function(player)
	if K.enabled() and not K.hungerDone(player) then
		return ghorza.noTrade
	end
	return nil
end

-- World objects of The Great Hunger. Each returns true when handled.

function K.useFloatingFlask(player)
	if not K.enabled() then
		return false
	end
	if K.get(player, S.FlaskWait) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The flask is empty.") -- ours
		return true
	end
	player:addItem(K.SHARK_TEETH, 1)
	K.set(player, S.FlaskWait, K.nextMidnight())
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found shark teeth.") -- BR screenshot
	return true
end

-- Shark teeth or five onyx chips into the hollowed gourd (any order).
function K.fillGourd(player, item, target)
	if not K.enabled() or not target or target.itemid ~= K.GOURD or K.get(player, GH) ~= 1 then
		return false
	end
	local fill = K.get(player, S.GourdFill)
	if item.itemid == K.SHARK_TEETH then
		if bitSet(fill, 1) then
			return false
		end
		item:remove(1)
		fill = fill + 1
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You put the shark teeth into the hollowed gourd.") -- EN
	elseif item.itemid == K.ONYX_CHIP then
		if bitSet(fill, 2) then
			return false
		end
		if player:getItemCount(K.ONYX_CHIP) < 5 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need five onyx chips for the gourd.") -- ours
			return true
		end
		player:removeItem(K.ONYX_CHIP, 5)
		fill = fill + 2
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You put the onyx chips into the hollowed gourd.") -- EN, BR screenshot
	else
		return false
	end
	K.set(player, S.GourdFill, fill)
	if fill == 3 then
		target:transform(K.RATTLING_GOURD)
	end
	return true
end

function K.useVoodooLily(player, toPosition)
	if not K.enabled() or K.get(player, GH) ~= 2 or has(player, K.POLLEN) then
		return false
	end
	player:addItem(K.POLLEN, 1)
	toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You gather some blue-violet pollen from the voodoo lily.") -- EN
	return true
end

function K.useDragonNest(player)
	if not K.enabled() or K.get(player, GH) ~= 2 or has(player, K.EGG_SHELLS) then
		return false
	end
	player:addItem(K.EGG_SHELLS, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You gather some grey, blue-spotted egg shell pieces from the hatched dragon's nest.") -- EN
	return true
end

-- pollen + shells -> grey-blue powder; powder + red oil -> red paint; paint + rattling gourd -> painted rattle
local mixes = {
	{ a = K.POLLEN, b = K.EGG_SHELLS, result = K.GREY_BLUE_POWDER, text = "You are mixing together the voodoo lily pollen and the hackled dragon egg shells." },
	{ a = K.GREY_BLUE_POWDER, b = K.RED_OIL, result = K.RED_PAINT, text = "You are mixing a sticky red mush." },
	{ a = K.RED_PAINT, b = K.RATTLING_GOURD, result = K.PAINTED_RATTLE, text = "You paint the gourd with some weird ogre runes.", keepTarget = true },
}
K.mixIds = { K.POLLEN, K.EGG_SHELLS, K.GREY_BLUE_POWDER, K.RED_OIL, K.RED_PAINT }

function K.mix(player, item, target)
	if not K.enabled() or not target or not target.itemid then
		return false
	end
	for _, m in ipairs(mixes) do
		local first, second
		if item.itemid == m.a and target.itemid == m.b then
			first, second = item, target
		elseif not m.keepTarget and item.itemid == m.b and target.itemid == m.a then
			first, second = item, target
		end
		if first then
			if m.keepTarget then
				-- the paint goes on the gourd: the gourd becomes the painted rattle
				first:remove(1)
				second:transform(m.result)
			else
				first:remove(1)
				if second:getCount() > 1 then
					second:remove(1)
					player:addItem(m.result, 1)
				else
					second:transform(m.result)
				end
			end
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, m.text) -- EN
			return true
		end
	end
	return false
end

local function within(pos, from, to)
	return pos.z == from.z and pos.x >= from.x and pos.x <= to.x and pos.y >= from.y and pos.y <= to.y
end

function K.shakeRattle(player)
	if not K.enabled() then
		return false
	end
	local pos = player:getPosition()
	if K.get(player, GH) == 3 then
		for _, site in ipairs(K.SITES) do
			if within(pos, site.from, site.to) then
				local done = K.get(player, S.GreatHungerSites)
				if not bitSet(done, site.bit) then
					K.set(player, S.GreatHungerSites, done + site.bit)
				end
				pos:sendMagicEffect(CONST_ME_SOUND_RED)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You're shaking the gourd rattle and bless the sacred site anew.") -- EN
				return true
			end
		end
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You're shaking the gourd rattle. It clatters, yet nothing else happens.") -- EN
	return true
end

function K.trapHyaena(player, item, target)
	if not K.enabled() or not target or target.itemid ~= K.SLEEPING_HYAENA or K.get(player, GH) ~= 4 then
		return false
	end
	item:transform(K.TRAPPED_HYAENA)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Carefully you capture the sleeping hyaena with the trap net.") -- EN, BR screenshot
	return true
end

-- A rune stone set used on the ground: true when handled.
function K.placeRunes(player, item, toPosition)
	if not K.enabled() or K.get(player, GH) ~= 5 or not toPosition then
		return false
	end
	local near
	for _, r in ipairs(K.RUNES) do
		if toPosition.z == r.pos.z and math.abs(toPosition.x - r.pos.x) <= 1 and math.abs(toPosition.y - r.pos.y) <= 1 then
			near = near or r
			if r.set == item.itemid then
				local done = K.get(player, S.GreatHungerRunes)
				if not bitSet(done, r.bit) then
					K.set(player, S.GreatHungerRunes, done + r.bit)
				end
				item:remove(1)
				local tile = Tile(r.pos)
				local placed = r.set + 5 -- the placed ogre rune stone (22670-22674)
				if tile and not tile:getItemById(placed) then
					Game.createItem(placed, 1, r.pos)
				end
				r.pos:sendMagicEffect(CONST_ME_MAGIC_GREEN)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You put the ogre rune stones in the fitting place.") -- EN, BR screenshot
				return true
			end
		end
	end
	if near then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "These stones don't fit in here.") -- ours
		return true
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Quenching the Thirst (Ghorza and Larek, keyword "water")
-- ---------------------------------------------------------------------------

local QT = S.Thirst
K.CARAFE = 22692
K.QUARTZ_POWDER = 22708
K.GOLDEN_QUARTZES = 22361
K.HOE = 3455
K.SHAGGY_BAG = 22763
K.WATER_ELEMENTAL_CORPSE = 9582
K.SOULS, K.POURS, K.POWDER = 5, 6, 30 -- per carafe, carafes, powder (BR and EN)

-- The dried salt sea north-east of Ghorza's tent (BR 33643,31647; EN 33641,31645).
K.LAKE = { from = Position(33636, 31641, 7), to = Position(33650, 31649, 7) }
K.SALT_FIRST, K.SALT_LAST = 22410, 22421 -- salt-incrusted floor
K.SALT_PURPLE = 22418 -- EN Salt-Incrusted Floor (Purple)
K.SALT_TOP_FIRST, K.SALT_TOP_LAST = 22422, 22445 -- salt-incrusted floor pieces lying on the ground
K.DIRTY_WATER = 12558
K.CLEAN_WATER = 629 -- shallow water (as in Krailos' caves)
K.LAKE_DRY, K.LAKE_DIRTY, K.LAKE_CLEAN = 0, 1, 2

local LAKE_FILLED_TEXT = "One of the dried salt seas in Krailos carries water again. Yet it is still toxic because of the salty sediments." -- BR, BR screenshot
local LAKE_CLEAN_TEXT = "One of the toxic salt seas in Krailos carries fresh and clean water again. The ogres' water supply is ensured for now." -- BR, BR screenshot

function K.inLake(pos)
	return pos and within(pos, K.LAKE.from, K.LAKE.to)
end

-- World state (game KV, so a restart on the same game day keeps the water)
local function lakeStore()
	return kv.scoped("family-krailos")
end

function K.lakeState()
	if K.lakeOverride then
		return K.lakeOverride.state
	end
	local saved = lakeStore():get("lake")
	if type(saved) ~= "table" or saved.day ~= K.gameDay() then
		return K.LAKE_DRY
	end
	return saved.state or K.LAKE_DRY
end

local lakeSaved = {} -- squares changed (ground and salt pieces), to dry the lake again

function K.showLake(state)
	-- back to the map's own salt first
	for _, saved in ipairs(lakeSaved) do
		local tile = Tile(saved.pos)
		local ground = tile and tile:getGround()
		if ground then
			ground:transform(saved.ground)
			for _, id in ipairs(saved.items) do
				Game.createItem(id, 1, saved.pos)
			end
		end
	end
	lakeSaved = {}
	if state == K.LAKE_DRY then
		return
	end
	local water = state == K.LAKE_CLEAN and K.CLEAN_WATER or K.DIRTY_WATER
	for x = K.LAKE.from.x, K.LAKE.to.x do
		for y = K.LAKE.from.y, K.LAKE.to.y do
			local pos = Position(x, y, K.LAKE.from.z)
			local tile = Tile(pos)
			local ground = tile and tile:getGround()
			if ground and ground:getId() >= K.SALT_FIRST and ground:getId() <= K.SALT_LAST then
				local saved = { pos = pos, ground = ground:getId(), items = {} }
				for _, it in ipairs(tile:getItems() or {}) do
					local itemId = it:getId()
					if itemId >= K.SALT_TOP_FIRST and itemId <= K.SALT_TOP_LAST then
						saved.items[#saved.items + 1] = itemId
						it:remove()
					end
				end
				ground:transform(water)
				lakeSaved[#lakeSaved + 1] = saved
			end
		end
	end
end

function K.setLake(state)
	lakeStore():set("lake", { day = K.gameDay(), state = state })
	K.showLake(state)
end

-- The player's counters belong to one game day (EN: the server save resets the progress).
function K.thirstCounters(player)
	local today = K.gameDay()
	if K.get(player, S.ThirstDay) ~= today then
		K.set(player, S.ThirstDay, today)
		K.set(player, S.ThirstSouls, 0)
		K.set(player, S.ThirstPours, 0)
		K.set(player, S.ThirstPowder, 0)
	end
	return K.get(player, S.ThirstSouls), K.get(player, S.ThirstPours), K.get(player, S.ThirstPowder)
end

function K.thirstDone(player)
	return K.get(player, QT) >= 5
end

local thirst = {
	offer = {
		"Water great problem in {Krailos}. Not enough water, not anymore. Seas and rivers drying up, become salty holes. So new powerful spirit arose. Younger than {Great Hunger} but even more dangerous. We calling {Dreadful Thirst}. ...",
		"We feeding Great Hunger with meat. Always enough meat in Krailos. Dreadful Thirst wants water, but drying up all water sources. So not enough water to calm Dreadful Thirst. Not even enough for ogres to drink. ...",
		"Spirits of fathers and mothers telling Ghorza that in past more water been here. Krailos been more green and lush. Now water fading. Only bigger waterhole left is here in village. Many battles against other ogres because of water. ...",
		"Ogres needing more water. You helping?",
	},
	accept = {
		"Very good! Ghorza having idea how to solve problem. Listen: There dried salt sea near village. Right beside Ghorza's tent. If we fill with water again, ogres having enough water, no more problems. ...",
		"You ask how. Hah, Ghorza asked spirits same question! Spirits said: Take jar or jug and enchant with shamanic spells. Spirits told Ghorza what to do. Ghorza found pretty shimmering jar in shipwrecks and made jar that can take in water spirits. ...",
		"If you finding some you catching their souls and pouring them into dried sea. But only pour on purple salt. Spirits said so. Yellow and orange salt absorbing water spirit souls too fast. Here, take enchanted jar.",
	},
	filled = {
		"Salt sea filled with water now. But water still poisonous because of salt. Must make water clean so ogres can drink it. Ghorza not knowing how. ...",
		"But human merchant {Larek} told he knowing way to remove poison from water. Ask him. Oh, brought back enchanted jug, too. Ghorza taking back.",
	},
	reward = {
		"Sea filled with fresh water now! Now {Dreadful Thirst} not threatening ogres anymore. Ogres of {Bloody Skull} Tribe having enough water. Ogres making party now. You see? Hanging up old banners and colourful snips found in wreckage. ...",
		"Larek told us that humans hanging up such things when reveling. Ghorza thought that funny idea, so ogres hanging up some shreds, too. A bit boring yet, so ogres added some skeletons. Looking better now. ...",
		"You done well, little human. You not snack, you fellow. Take this, perhaps something of use inside.",
	},
	larek = {
		"Yes, I noticed that the salt sea near the village is filled with water again. But it still looks poisonous. I assume the salty sediments are the reason for this. ...",
		"I'm not completely sure, but some of my petrology studies seem to indicate that a mineral found in the steppe of Krailos is able to serve as an antitoxin. ...",
		"Look out for golden shimmering {quartzes} and grind them into a powder. I could {sell} you a hoe, if you need one. Then scatter it into the poisonous water.",
	},
	-- ours (not on the wikis)
	notDry = "Salt sea not dry now. Dreadful Thirst calm for some time. Come back when salt sea dry again.",
	waitSouls = "Salt sea still dry. Catch souls of water spirits with enchanted jar and pour them on purple salt.",
	dryAgain = "Salt sea dried up again! Dreadful Thirst too strong. You catching water spirits again. Here, take enchanted jar.",
	waitClean = "Water still poisonous. Ask human merchant {Larek} how to make water clean.",
	waitPowder = "Water still poisonous. Scatter golden powder into water like Larek said.",
	lostCarafe = "You lost enchanted jar? Clumsy human. Here, take new one.",
	done = "Ogres having fresh water now. Ghorza thanks useful human.",
	declined = "Hmpf. Then ogres staying thirsty.",
	larekNoWater = "Water is a precious thing in Krailos. If you want to help the ogres, ask {Ghorza} about it.",
	larekDry = "The salt sea near the village is still dry. Ghorza knows more about it.",
	larekPowder = "Look out for golden shimmering {quartzes}, grind them into a powder with a hoe and scatter it into the poisonous water.",
	larekClean = "The water is clean again? Splendid! Ghorza will be delighted. Go and tell her.",
	larekDone = "Thanks to you the ogres have fresh water again. That will make my life here a lot easier.",
}
K.thirstLines = thirst
local QT_OFFER = 21

local function ghorzaWater(npc, player, npcHandler)
	local id = player:getId()
	local state = K.get(player, QT)
	local _, pours, powder = K.thirstCounters(player)
	local lake = K.lakeState()
	npcHandler:setTopic(id, 0)
	if state == 0 then
		if lake ~= K.LAKE_DRY then
			npcHandler:say(thirst.notDry, npc, player)
			return
		end
		npcHandler:say(thirst.offer, npc, player)
		npcHandler:setTopic(id, QT_OFFER)
	elseif state == 1 then
		if pours >= K.POURS then
			player:removeItem(K.CARAFE, 1)
			K.set(player, QT, 2)
			npcHandler:say(thirst.filled, npc, player)
		elseif not has(player, K.CARAFE) then
			player:addItem(K.CARAFE, 1)
			npcHandler:say(thirst.lostCarafe, npc, player)
		else
			npcHandler:say(thirst.waitSouls, npc, player)
		end
	elseif state == 2 or state == 3 then
		if lake == K.LAKE_DRY and powder < K.POWDER then
			K.set(player, QT, 1)
			K.set(player, S.ThirstSouls, 0)
			K.set(player, S.ThirstPours, 0)
			if not has(player, K.CARAFE) then
				player:addItem(K.CARAFE, 1)
			end
			npcHandler:say(thirst.dryAgain, npc, player)
		else
			npcHandler:say(state == 2 and thirst.waitClean or thirst.waitPowder, npc, player)
		end
	elseif state == 4 then
		player:addItem(K.SHAGGY_BAG, 1)
		K.set(player, QT, 5)
		npcHandler:say(thirst.reward, npc, player)
		K.checkCallOfTheWild(player)
	else
		npcHandler:say(thirst.done, npc, player)
	end
end

function K.larekWater(npc, player, npcHandler)
	local state = K.get(player, QT)
	npcHandler:setTopic(player:getId(), 0)
	if state == 2 then
		K.set(player, QT, 3)
		npcHandler:say(thirst.larek, npc, player)
	elseif state == 3 then
		npcHandler:say(thirst.larekPowder, npc, player)
	elseif state == 4 then
		npcHandler:say(thirst.larekClean, npc, player)
	elseif state >= 5 then
		npcHandler:say(thirst.larekDone, npc, player)
	elseif state == 1 then
		npcHandler:say(thirst.larekDry, npc, player)
	else
		npcHandler:say(thirst.larekNoWater, npc, player)
	end
	return true
end

K.handlers["Ghorza"] = function(npc, player, message, npcHandler)
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	if K.contains(message, { "quest", "mission" }) then
		ghorzaMission(npc, player, npcHandler)
		return true
	end
	if MsgContains(message, "water") then
		ghorzaWater(npc, player, npcHandler)
		return true
	end
	if MsgContains(message, "lost runes") or MsgContains(message, "lost rune") then
		return ghorzaLostRunes(npc, player, npcHandler)
	end
	if topic ~= 0 and MsgContains(message, "yes") then
		npcHandler:setTopic(id, 0)
		if topic == GH_OFFER and K.get(player, GH) == 0 then
			player:addItem(K.GOURD, 1)
			K.set(player, GH, 1)
			K.set(player, S.GourdFill, 0)
			K.startLog(player)
			npcHandler:say(ghorza.gourd, npc, player)
		elseif topic == QT_OFFER and K.get(player, QT) == 0 and K.lakeState() == K.LAKE_DRY then
			player:addItem(K.CARAFE, 1)
			K.set(player, QT, 1)
			K.thirstCounters(player)
			K.set(player, S.ThirstSouls, 0)
			K.set(player, S.ThirstPours, 0)
			K.startLog(player)
			npcHandler:say(thirst.accept, npc, player)
		end
		return true
	end
	if topic ~= 0 and MsgContains(message, "no") then
		npcHandler:setTopic(id, 0)
		npcHandler:say(topic == QT_OFFER and thirst.declined or ghorza.declined, npc, player)
		return true
	end
	return false
end

-- World objects of Quenching the Thirst. Each returns true when handled.

-- The carafe on a fresh water elemental corpse, or on the salt sea.
function K.useCarafe(player, item, target, toPosition)
	if not K.enabled() or K.get(player, QT) ~= 1 then
		return false
	end
	local souls, pours = K.thirstCounters(player)
	if target and target.itemid == K.WATER_ELEMENTAL_CORPSE then
		if souls >= K.SOULS then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The enchanted carafe is full. Pour the essences into the dried salt sea.") -- ours
			return true
		end
		if target:getCustomAttribute("krailosEssence") then
			return false -- this corpse was already used (one essence per corpse)
		end
		target:setCustomAttribute("krailosEssence", 1)
		K.set(player, S.ThirstSouls, souls + 1)
		toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The water elemental's essence is absorbed by the enchanted carafe.") -- BR screenshot
		return true
	end
	if not K.inLake(toPosition) then
		return false
	end
	if souls < K.SOULS then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The enchanted carafe does not hold enough water elementals' essences yet.") -- ours
		return true
	end
	local tile = Tile(toPosition)
	local ground = tile and tile:getGround()
	local groundId = ground and ground:getId() or 0
	if K.lakeState() == K.LAKE_DRY and groundId ~= K.SALT_PURPLE then
		K.set(player, S.ThirstSouls, 0)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The salt absorbs the water elementals' essences at once. Only the purple salt holds them.") -- ours (BR, EN: only purple salt)
		return true
	end
	K.set(player, S.ThirstSouls, 0)
	pours = pours + 1
	K.set(player, S.ThirstPours, pours)
	toPosition:sendMagicEffect(CONST_ME_LOSEENERGY)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You pour the water elementals' essences into the dried salt sea.") -- BR screenshot
	if pours >= K.POURS and K.lakeState() == K.LAKE_DRY then
		K.setLake(K.LAKE_DIRTY)
		Game.broadcastMessage(LAKE_FILLED_TEXT, MESSAGE_EVENT_ADVANCE)
	end
	return true
end

function K.useHoe(player, target, toPosition)
	if not K.enabled() or not target or target.itemid ~= K.GOLDEN_QUARTZES or K.get(player, QT) ~= 3 then
		return false
	end
	player:addItem(K.QUARTZ_POWDER, 1)
	toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are grinding the golden quartzes into a fine powder.") -- EN
	return true
end

function K.usePowder(player, item, toPosition)
	if not K.enabled() or K.get(player, QT) ~= 3 or not K.inLake(toPosition) then
		return false
	end
	local _, _, powder = K.thirstCounters(player)
	local lake = K.lakeState()
	if lake == K.LAKE_DRY then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The salt sea is dry. There is no water to detoxify.") -- ours
		return true
	end
	item:remove(1)
	powder = powder + 1
	K.set(player, S.ThirstPowder, powder)
	toPosition:sendMagicEffect(CONST_ME_YELLOWENERGY)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You sprinkle the golden dust into the toxic water and it glitters softly.") -- EN, BR screenshot
	if powder >= K.POWDER then
		K.set(player, QT, 4)
		if lake == K.LAKE_DIRTY then
			K.setLake(K.LAKE_CLEAN)
			Game.broadcastMessage(LAKE_CLEAN_TEXT, MESSAGE_EVENT_ADVANCE)
		end
	end
	return true
end

-- ---------------------------------------------------------------------------
-- The Call of the Wild: all seven missions done (EN: at the same time in the quest log).
-- ---------------------------------------------------------------------------

K.finishedChecks = {
	function(player)
		return K.hungryDone(player)
	end,
	function(player)
		return K.hungerDone(player)
	end,
	function(player)
		return K.thirstDone(player)
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
	hunger = {
		[1] = "Ghorza, the shaman of the Bloody Skulls, says the spirits are restless because some shrines were defiled. Turn her gourd into a shamanic rattle: fill it with shark teeth and five onyx chips, then go back to her.",
		[2] = "Paint the gourd rattle with shamanic paste: mix the pollen of a voodoo lily with some dragon egg shells, mingle it with Ghorza's red oil and paint the rattle. Then go back to Ghorza.",
		[3] = function(player)
			local done = K.get(player, S.GreatHungerSites)
			local n = (bitSet(done, 1) and 1 or 0) + (bitSet(done, 2) and 1 or 0) + (bitSet(done, 4) and 1 or 0)
			return string.format("Shake the painted gourd rattle at the three defiled ritual sites: the big dragon skeleton near the high mountains, the cactus forest and the salt sea near the strange ruins (%d of 3 purged). Then go back to Ghorza.", n)
		end,
		[4] = "Ghorza's totem animal, a cuddly hyaena, ran away. Catch it with her trap net and bring it back to her.",
		[5] = function(player)
			local done = K.get(player, S.GreatHungerRunes)
			local n = 0
			for _, r in ipairs(K.RUNES) do
				n = n + (bitSet(done, r.bit) and 1 or 0)
			end
			return string.format("Repair the protection runes on each side of the village with Ghorza's ogre rune stones; the complete runes between the tents show what they must look like (%d of 5 sets placed). Then go back to Ghorza.", n)
		end,
		[6] = "You helped Ghorza to appease the Great Hunger. She gave you an onyx pendant and now sells you her shamanic brews and runes.",
	},
	thirst = {
		[1] = function(player)
			local souls, pours = K.thirstCounters(player)
			return string.format("Ghorza wants to fill the dried salt sea next to her tent. Catch the souls of water elementals (north-western underwater caves) with her enchanted carafe and pour them on the purple salt of the sea, five souls each time (carafe: %d of 5; poured: %d of 6 today). Progress is lost at the daily server save.", souls, math.min(pours, 6))
		end,
		[2] = "The salt sea carries water again, but it is poisonous. Ask Larek how to make it clean.",
		[3] = function(player)
			local _, _, powder = K.thirstCounters(player)
			return string.format("Larek says golden quartzes from the steppe are an antitoxin. Grind them into powder with a hoe and scatter it into the poisonous water of the salt sea (%d of 30 today).", math.min(powder, 30))
		end,
		[4] = "The water of the salt sea is fresh and clean. Tell Ghorza.",
		[5] = "The ogres have fresh water again. Ghorza gave you a shaggy ogre bag.",
	},
}
