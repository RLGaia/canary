-- Gaia Family server: the Treasure Hunt Quest (2026-11-24). Ours: upstream had the items, Wyrdin,
-- Klaus, both Waveriders, Polly, Skip, the Skeleton Guard and Treasure Hunt Island on the map, but
-- no logic at all; the dworc cave of missions 1-2 and the carved giant trees were missing.
--
-- Sources: TibiaWiki BR backup ("Treasure Hunt Quest" with its screenshots Treasurehunt1-19 and
-- "Treasure Hunt Island" maps), TibiaWiki EN ("Treasure Hunt Quest/Spoiler" with its transcripts and
-- screenshots Th1, Dice Room, Treasure Map Part 1 Location; "Giant Tree (Carving)", the book and
-- item pages, loot statistics).
--
-- Part 1 (this file and scripts/family/treasure_hunt.lua):
--   * a fire bug on the very old piece of paper reveals the old encrypted text (BR screenshot);
--   * Wyrdin takes it ("encrypted text") and needs one real hour; then "decryption" opens the
--     sealed door next to him; the old pirate poem is in the chest behind it (both wikis);
--   * the poem points to the carved giant tree west of Chor (carving 32860,32774,7, EN); 17 squares
--     west of it a shovel opens a hole (both wikis) into a small dworc cave we built
--     (world/custom/family-treasure-hunt.otbm, tools/family/otbm/treasure_hunt_cave.py);
--   * in the cave: wooden bars to break with a melee weapon, the pot where a voodoo doll gets its
--     4-digit code, 4 dice rolled by their levers (north to south = the digits), a teleporter that
--     lets through only who carries the doll the dice show, and the remains of a pirate with the
--     top right part of a map (both wikis; the "KL..." line from the EN screenshot).
--   * After the map part the hole stays closed for that character (EN: "you'll lose access").
--   The other two carved trees are only scenery here: the wikis say their holes lead elsewhere
--   but describe no cave.
-- Part 2 (mission 3):
--   * Klaus in the Nargor tavern: "treasure map" with the top right part, "yes" for 5,000 gold: the
--     top left part, and his logbook in the chest behind him (EN screenshot Logbook Klaus: an alcove
--     north of him, 31982,32823,2; our map has only rock there, so the rock is removed at startup
--     and the chest opens once he sold you his part, instead of a sealed door). "logbook", then the
--     three other pirates (any order) for the other two parts; "map" with all four parts: the
--     pirate treasure map (EN transcripts).
--   * The lower left part in the bottom of Captain Nathaniel's boat (32964,32642,8, EN); the lower
--     right part at Mac Noodles: a crowbar opens the locked western door (32620,32004,7; it locks
--     again 2 minutes later), move the trough and use the floor below it (32621,32003,7). Message
--     "You have found a part of a map." (BR screenshot), also for the remains.
-- Part 3 (mission 4, Treasure Hunt Island):
--   * Captain Waverider on Treasure Island: "map" with the pirate treasure map, "yes": to the island
--     (EN/BR lines); after the treasure: "Your timing is really bad! ..." (EN).
--   * Our map has every island teleporter but none has a destination, and no wiki gives them:
--     the network below is ours (Rodrigo 2026-11-24), built from the map's layout and EN's route
--     ("go up the ramp, walk east, levitate down, go through the teleporter and then run east").
--   * First seal: rum (a container with rum, or a rum flask) on the empty coal basin of the snake
--     head (32033,32993,12): "The rum runs fast through my vein, ..." (BR screenshot); the bridge
--     teleporter between the pirate statues (32053,32970,8) lets you through within 25 s (EN),
--     "Your questlog has been updated." (BR). The statues' text from the BR screenshot.
--   * Second seal: the ship deck (32075-32085,32968-32973,11). The traps are upstream's
--     (data/scripts/movements/trap.lua: slits and spikes hurt); the spikes now go up and down. Who
--     gets hurt is thrown back to the gangway, "Get off my deck you bleeding meatbag!!", and
--     nobody may step on the deck while fresh blood lies there: "You have to wait until the worst
--     blood pools are gone." (BR screenshots).
--   * Third seal: the hall of the sleeping dead pirates (32101-32111,32969-32973,11). Only the
--     floorboards with coins in the BR screenshot are safe (one square we added to join them);
--     any other wakes a Ghostly Apparition ("KRAAAAAAK", BR screenshot). Who woke one is sent back
--     by the far teleporter; the near teleporter puts them to sleep again (EN).
--   * Fourth seal: Polly and Skip, a cookie each to start, then 1, 2, 3, 4, 1, 7 (EN transcript; a
--     wrong number ends the talk). The Skeleton Guard: "47" (EN); then the teleporter by him lets
--     you in, the stairs lead to the treasure room.
--   * The treasure room (floor 13): the bejeweled ship's telescope and 3 gold ingots in the
--     chests under the rubble (EN; which chest holds which is ours), and each day (the server
--     starts each morning) 3 small emeralds, 2 small amethysts, 1 small topaz and 162 gold coins
--     on the floor (EN; BR's Tibia Tales table says 108 gold, 2 amethysts, 3 emeralds, no topaz).
--     The teleporter by the guard takes you back to the island's dock and the treasure room is
--     closed to you after that (EN).
-- Ours where the wikis say nothing: Wyrdin's line while he is still busy, the chest's messages,
-- Klaus' lines for missing gold or parts, the quest log texts, the doll's message in the pot (none:
-- only the fire effect).
--
-- Loaded from lib/others/load.lua, before the NPCs.

FamilyTreasureHunt = {
	items = {
		paper = 9185,
		text = 9186,
		poem = 9204,
		doll = 3002,
		topRight = 9181, -- the remains of a pirate
		topLeft = 9182, -- Klaus
		lowerRight = 9183, -- Mac Noodles
		lowerLeft = 9184, -- the boat in the Waterfall Quest cave
		map = 9205,
		carving = 9590,
	},
	codes = { [9177] = "3613", [9178] = "2543", [9179] = "5261" }, -- items.xml (client 15.11)
	decryptTime = 60 * 60, -- both wikis: one hour
	holeTime = 50, -- the hole closes again (594 would decay to a stone pile after 60 s)
	poemText = "Set the sails to the carved tree\nthe head of a dragon south shall it be\n34 feet in the line to the west\nthe next one goes under arrest\nthe master's secret must be revealed\nto open the path that once were sealed",
	logbookText = "The book speaks about an incident 20 years ago. Klaus was in his best years and part of the crew of a pirate ship. They got hold of a big fish-a Venorean trader which was packed with gold, gems, finest cloth and the finest weapons and armor you can get in the whole lands of Tibia.\nPirates as they were everyone wanted the lion's share of the treasure and there was a mutiny. Klaus wrote in his diary about an unspeakable slaughtering which ended when only four of the whole crew were left. They knew they wouldn't be able to navigate the ship with less then 4 people so they made a agreement. They hid the treasure at a safe spot, made a map which was cut into four pieces. Everyone of them got one piece of the map and was told to secure the treasure with a trap...a riddle...that only he knows.\nThe names of the surviving pirates were: Nutty Jack, Rapp Scallion, Captain Nathaniel and of course, Klaus.",
	klausPrice = 5000, -- both wikis
	partFound = "You have found a part of a map.", -- BR screenshot (Mac Noodles)
	-- state (Storage ...TreasureHunt.State), the main line
	TOP_RIGHT = 4,
	BOUGHT = 5, -- Klaus sold his part
	NAMES = 6, -- Klaus told about the other pirates
	MAP = 7, -- the pirate treasure map
	ISLAND = 8, -- Waverider brought you to the island
	rumTime = 25, -- EN
	rumText = "The rum runs fast through my vein, hurry up or you need to feed me again!", -- BR screenshot
	statueText = "Feed some rum to the snake or you'll never pass the lake.", -- BR screenshot
	TOPIC_KLAUS = 4801,
}

local T = FamilyTreasureHunt
local it = T.items

T.carvings = { Position(32860, 32774, 7), Position(32887, 32669, 7), Position(32920, 32515, 7) } -- EN
T.dig = Position(32843, 32774, 7) -- 17 squares west of the first carving
T.digGround = 1020 -- earth (our map)
T.wyrdinDoor = Position(33271, 31838, 6)
T.poemChest = Position(33272, 31838, 6)
T.chestAid = 48791 -- only makes the chest immovable; the position action handles it
T.pot = Position(32853, 32769, 8)
T.levers = { Position(32859, 32772, 8), Position(32859, 32773, 8), Position(32859, 32777, 8), Position(32859, 32778, 8) }
T.dice = { Position(32862, 32772, 8), Position(32862, 32773, 8), Position(32862, 32777, 8), Position(32862, 32778, 8) }
T.gateAid = 48789
T.exitAid = 48790
T.gateBack = Position(32860, 32775, 8)
T.arrival = Position(32867, 32772, 8)
T.exitTo = Position(32858, 32775, 8)
T.remains = Position(32871, 32771, 8)
T.logbookChest = Position(31982, 32823, 2) -- the alcove north of Klaus
T.boat = Position(32964, 32642, 8)
T.noodlesDoor = Position(32620, 32004, 7)
T.noodlesFloor = Position(32621, 32003, 7)
T.relockTime = 120
-- island
T.islandDock = Position(32043, 32933, 7)
T.basin = Position(32033, 32993, 12)
T.bridgeGate = Position(32053, 32970, 8)
T.bridgeStatues = { Position(32053, 32969, 8), Position(32053, 32971, 8) }
T.bridgeEast = Position(32058, 32970, 8)
T.bridgeWest = Position(32051, 32970, 8)
T.deck = { x1 = 32075, x2 = 32085, y1 = 32968, y2 = 32973, z = 11 }
T.gangway = Position(32073, 32970, 11)
T.hall = { x1 = 32102, x2 = 32110, y1 = 32969, y2 = 32973, z = 11 }
T.hallSafe = {} -- BR screenshot Treasurehunt16 (coins); 32108,32972 ours
for _, xy in ipairs({ { 32102, 32971 }, { 32103, 32971 }, { 32104, 32971 }, { 32105, 32970 }, { 32106, 32969 }, { 32106, 32972 }, { 32107, 32970 }, { 32107, 32971 }, { 32108, 32972 }, { 32108, 32973 }, { 32109, 32972 }, { 32109, 32971 }, { 32110, 32970 } }) do
	T.hallSafe[xy[1] .. "," .. xy[2]] = true
end
T.hallStart = Position(32102, 32971, 11)
T.hallBack = Position(32097, 32971, 11)
T.parrotRoom = Position(32114, 32971, 11)
T.guardGateBack = Position(32127, 32971, 11)
T.guardRoom = Position(32132, 32972, 11)
T.telescopeChest = Position(32139, 32978, 13)
T.ingotChest = Position(32144, 32968, 13)
T.dailyLoot = { -- EN
	{ 3032, 3, Position(32141, 32972, 13) }, -- small emeralds
	{ 3033, 2, Position(32138, 32974, 13) }, -- small amethysts
	{ 9057, 1, Position(32143, 32975, 13) }, -- small topaz
	{ 3031, 100, Position(32140, 32970, 13) }, -- gold coins
	{ 3031, 62, Position(32142, 32977, 13) },
}
-- teleporters: map position -> where it goes (ours); the gates have their own rules
T.teleports = {
	{ from = Position(32050, 32977, 13), to = Position(32047, 32970, 8) }, -- the fast way back up, EN
	{ from = Position(32040, 32986, 10), to = Position(32030, 32990, 10) }, -- the "teleporter" way down
	{ from = Position(32028, 32991, 10), to = Position(32029, 32984, 10) },
	{ from = Position(32028, 32983, 10), to = Position(32028, 32995, 12) }, -- next to the snake head
	{ from = Position(32022, 32973, 11), to = Position(32031, 32968, 11) },
	{ from = Position(32032, 32968, 11), to = Position(32021, 32993, 12) },
	{ from = Position(32055, 33007, 11), to = Position(32028, 33012, 11) },
	{ from = Position(32027, 33013, 11), to = Position(32030, 33002, 12) },
	{ from = Position(32086, 32970, 11), to = Position(32090, 32970, 11), log = 10 }, -- end of the deck
	{ from = Position(32088, 32968, 11), to = Position(32058, 32970, 8) }, -- back to the bridge (EN)
	{ from = Position(32099, 32971, 11), to = Position(32102, 32971, 11), hall = "enter" },
	{ from = Position(32101, 32971, 11), to = Position(32097, 32971, 11), hall = "reset" },
	{ from = Position(32111, 32971, 11), to = Position(32114, 32971, 11), hall = "exit", log = 11 },
	{ from = Position(32113, 32971, 11), to = Position(32097, 32971, 11), hall = "reset" },
	{ from = Position(32129, 32971, 11), to = Position(32132, 32972, 11), guard = true },
	{ from = Position(32131, 32971, 11), to = Position(32043, 32933, 7), leave = true },
}
T.firstTeleportAid = 48792 -- 48792-48807, one per teleporter above
T.bridgeAid = 48808
T.ghosts = {}
T.woke = {}
T.parrots = {}
T.ages = { "1", "2", "3", "4", "1", "7" }
T.parrotLines = { -- EN transcript, in order: { who, text }
	{ { "polly", "Ish shree." }, { "skip", "..." }, { "skip", "too few!" } },
	{ { "skip", "..." }, { "polly", "Ish two." }, { "skip", "...and shame." } },
	{ { "polly", "Ish one." }, { "skip", "..." }, { "skip", "...and three." } },
	{ { "polly", "Ish number." }, { "skip", "..." }, { "skip", "...ONE!" } },
	{ { "polly", "Ish shix." }, { "skip", "..." }, { "skip", "...and one." } },
	{ { "skip", "..." }, { "polly", "Ish number. ..." }, { "skip", "...TWO! ..." }, { "polly", "Now get losht! CAAAW!" }, { "skip", "Get lofft! CAAAW!" } },
}

local function S()
	return Storage.Quest.U8_5.TreasureHunt
end
T.S = S

function T.get(player, key)
	return math.max(0, player:getStorageValue(S()[key]))
end

function T.set(player, key, value)
	player:setStorageValue(S()[key], value)
end

-- quest log (Tibia Tales, "Treasure Hunt"); never goes back
function T.log(player, value)
	if player:getStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart) < 1 then
		player:setStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart, 1)
	end
	if T.get(player, "Questline") < value then
		T.set(player, "Questline", value)
	end
end

-- a fire bug on the very old piece of paper; called from scripts/quests/others/actions_fire_bug.lua
function T.onFireBug(player, target)
	if not Family.treasureHunt or type(target) ~= "userdata" or not target.isItem or not target:isItem() then
		return false
	end
	if target.itemid ~= it.paper then
		return false
	end
	target:transform(it.text)
	player:say("As you used the firebug on the parchment some strange writings appeared on it.", TALKTYPE_MONSTER_SAY) -- BR screenshot
	return true
end

-- Wyrdin; called first in his creatureSayCallback
function T.wyrdin(npc, creature, message, npcHandler)
	if not Family.treasureHunt then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	if MsgContains(message, "encrypted text") then
		if T.get(player, "Decrypt") > 0 then
			npcHandler:say("I'm still working on your text. Ask me about the decryption a little later.", npc, creature) -- ours
			return true
		end
		if not player:removeItem(it.text, 1) then
			return false
		end
		T.set(player, "Decrypt", os.time())
		T.log(player, 1)
		npcHandler:say("What have we got here? Ohhh, very interesting. I haven't seen this kind of encryption for a long time. Give me about an hour and I'll have it {decrypted} for you.", npc, creature)
		return true
	end
	if MsgContains(message, "decryption") or MsgContains(message, "decrypted") then
		local given = T.get(player, "Decrypt")
		if given == 0 and T.get(player, "PoemDoor") < 1 then
			return false
		end
		if given > 0 and os.time() - given < T.decryptTime then
			npcHandler:say("I'm still working on your text. Ask me about the decryption a little later.", npc, creature) -- ours
			return true
		end
		T.set(player, "Decrypt", 0)
		T.set(player, "PoemDoor", 1)
		T.log(player, 2)
		npcHandler:say("Ohh, you again. The text you gave me. It wasn't very hard to decrypt. I put it in the chest over there. Just get it.", npc, creature)
		return true
	end
	return false
end

function T.usePoemChest(player)
	if T.get(player, "PoemDoor") < 1 or T.get(player, "Poem") > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
		return true
	end
	local poem = player:addItem(it.poem, 1)
	if not poem then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found an old pirate poem, but you have no room to take it.")
		return true
	end
	poem:setAttribute(ITEM_ATTRIBUTE_TEXT, T.poemText)
	T.set(player, "Poem", 1)
	T.log(player, 3)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found an old pirate poem.")
	return true
end

-- a shovel at the dig spot; called from onUseShovel (scripts/lib/register_actions.lua)
function T.onDig(player, toPosition)
	if not Family.treasureHunt or toPosition ~= T.dig then
		return false
	end
	if T.get(player, "State") >= T.TOP_RIGHT then
		return false
	end
	local ground = Tile(T.dig) and Tile(T.dig):getGround()
	if not ground then
		return false
	end
	if ground.itemid ~= T.digGround then
		return true -- already open
	end
	ground:transform(594) -- hole
	T.dig:sendMagicEffect(CONST_ME_POFF)
	addEvent(T.closeHole, T.holeTime * 1000)
	return true
end

function T.closeHole()
	local tile = Tile(T.dig)
	local ground = tile and tile:getGround()
	if ground and (ground.itemid == 594 or ground.itemid == 593) then
		ground:transform(T.digGround)
	end
end

-- the voodoo doll in the pot; called from data/scripts/actions/items/voodoo_doll.lua
function T.onVoodooDoll(player, item, target, toPosition)
	if not Family.treasureHunt or item.itemid ~= it.doll or toPosition ~= T.pot then
		return false
	end
	local ids = { 9177, 9178, 9179 }
	item:transform(ids[math.random(#ids)])
	T.pot:sendMagicEffect(CONST_ME_HITBYFIRE)
	return true
end

function T.diceValue(i)
	local tile = Tile(T.dice[i])
	if not tile then
		return nil
	end
	for value = 1, 6 do
		if tile:getItemById(5791 + value) then
			return value
		end
	end
	return nil
end

function T.pullLever(player, item, index)
	item:transform(item.itemid == 2772 and 2773 or 2772)
	local tile = Tile(T.dice[index])
	local die
	for id = 5792, 5797 do
		die = die or (tile and tile:getItemById(id))
	end
	if not die then
		return true
	end
	local value = math.random(1, 6)
	die:transform(5791 + value)
	T.dice[index]:sendMagicEffect(CONST_ME_CRAPS)
	player:say(player:getName() .. " rolled a " .. value .. ".", TALKTYPE_MONSTER_SAY, false, nil, T.dice[index]) -- as data/scripts/actions/items/die.lua
	return true
end

function T.diceCode()
	local code = ""
	for i = 1, #T.dice do
		local v = T.diceValue(i)
		if not v then
			return nil
		end
		code = code .. v
	end
	return code
end

-- does the player carry the doll the dice show?
function T.codeOpen(player)
	local code = T.diceCode()
	for id, c in pairs(T.codes) do
		if c == code and player:getItemCount(id) > 0 then
			return true
		end
	end
	return false
end

function T.useRemains(player)
	T.remains:sendMagicEffect(CONST_ME_POFF)
	player:say("Beside the skeleton you read 'KL....' in the dirt. Obviously this man was stabbed from behind.", TALKTYPE_MONSTER_SAY, false, player, T.remains) -- EN screenshot
	if T.get(player, "State") >= T.TOP_RIGHT then
		return true
	end
	if not T.givePart(player, it.topRight) then
		return true
	end
	T.set(player, "State", T.TOP_RIGHT)
	T.log(player, 4)
	return true
end

function T.givePart(player, id)
	if not player:addItem(id, 1) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a part of a map, but you have no room to take it.") -- ours
		return false
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, T.partFound)
	return true
end

local function hasAllParts(player)
	return player:getItemCount(it.topRight) > 0 and player:getItemCount(it.topLeft) > 0 and player:getItemCount(it.lowerRight) > 0 and player:getItemCount(it.lowerLeft) > 0
end

local PIRATES = {
	{ words = { "nutty jack", "jack" }, bit = 1, text = "Errrr.....yes....Nutty Jack, that crazy fish! He was......did I say 'was' I mean IS....errrr...Har har har....a very nice guy. I don't have a clue where he is living at the moment." },
	{ words = { "rapp scallion", "scallion" }, bit = 2, text = { "He was the worst sailor I have ever met in my whole life. Fortunately, he realised it and traded the sea for the land. Wanted to open up a tavern where you don't have to wait at all. ...", "He bought a house near the dwarf bridge but died before he could open his 'fast booze tavern'." } },
	{ words = { "captain nathaniel", "nathaniel" }, bit = 4, text = "Last thing I heared he was in command of a really huge ship. People say it was destroyed in a seafight between Darama and Tiquanda. Maybe you'll find what's left of the ship washed up in one of the smuggler caves in the mountains." },
}

-- Klaus; called first in his creatureSayCallback
function T.klaus(npc, creature, message, npcHandler)
	if not Family.treasureHunt then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local state = T.get(player, "State")
	if npcHandler:getTopic(id) == T.TOPIC_KLAUS then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			if state ~= T.TOP_RIGHT or player:getItemCount(it.topRight) < 1 then
				return true
			end
			if not player:removeMoneyBank(T.klausPrice) then
				npcHandler:say("Har har, without 5000 gold you won't get my part, matey.", npc, creature) -- ours
				return true
			end
			player:addItem(it.topLeft, 1)
			T.set(player, "State", T.BOUGHT)
			T.log(player, 5)
			npcHandler:say("Alright, here you go. See that door behind me? You'll find my old Logbook there. Get it and read it. If you have any questions, just ask me.", npc, creature)
			return true
		end
	end
	if MsgContains(message, "map") and state >= T.BOUGHT and state < T.MAP and hasAllParts(player) then
		for _, part in ipairs({ it.topRight, it.topLeft, it.lowerRight, it.lowerLeft }) do
			player:removeItem(part, 1)
		end
		player:addItem(it.map, 1)
		T.set(player, "State", T.MAP)
		T.log(player, 7)
		npcHandler:say("Not bad matey! You've got all four parts together. I'll stitch them together for you.....here you are.", npc, creature)
		return true
	end
	if MsgContains(message, "treasure map") and state == T.TOP_RIGHT and player:getItemCount(it.topRight) > 0 then
		npcHandler:say({
			"Ohhh, look what we got here! It's been a long long time since I last saw that map. Up for the big treasure, huh? I tell you what ...",
			"I'm also have a part of that treasure map. Sooooo if you are interested I'll sell it to you for 5000 gold. What d'ya say?",
		}, npc, creature)
		npcHandler:setTopic(id, T.TOPIC_KLAUS)
		return true
	end
	if MsgContains(message, "map") and state >= T.NAMES and state < T.MAP then
		npcHandler:say("Bring me all four parts of the map and I'll stitch them together for you, matey.", npc, creature) -- ours
		return true
	end
	if state < T.BOUGHT then
		return false
	end
	if MsgContains(message, "logbook") then
		npcHandler:say("Alright what do you want to know about the story?", npc, creature)
		return true
	end
	for _, pirate in ipairs(PIRATES) do
		for _, word in ipairs(pirate.words) do
			if MsgContains(message, word) then
				local bits = T.get(player, "Pirates")
				if bit.band(bits, pirate.bit) == 0 then
					bits = bit.bor(bits, pirate.bit)
					T.set(player, "Pirates", bits)
				end
				if bits == 7 and state == T.BOUGHT then
					T.set(player, "State", T.NAMES)
					T.log(player, 6)
				end
				npcHandler:say(pirate.text, npc, creature)
				return true
			end
		end
	end
	return false
end

function T.useLogbookChest(player)
	if T.get(player, "State") < T.BOUGHT then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "It is locked.") -- ours (a sealed door in Tibia)
		return true
	end
	if T.get(player, "Logbook") > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
		return true
	end
	local book = player:addItem(2826, 1)
	if not book then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a logbook, but you have no room to take it.")
		return true
	end
	book:setAttribute(ITEM_ATTRIBUTE_TEXT, T.logbookText)
	book:setAttribute(ITEM_ATTRIBUTE_WRITER, "Klaus")
	T.set(player, "Logbook", 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a logbook.")
	return true
end

function T.useBoat(player)
	if T.get(player, "BoatPart") > 0 then
		return false
	end
	if T.givePart(player, it.lowerLeft) then
		T.set(player, "BoatPart", 1)
	end
	return true
end

function T.useNoodlesFloor(player)
	local tile = Tile(T.noodlesFloor)
	if not tile or tile:getItemById(2524) or T.get(player, "NoodlesPart") > 0 then
		return false
	end
	if T.givePart(player, it.lowerRight) then
		T.set(player, "NoodlesPart", 1)
	end
	return true
end

-- a crowbar on Mac Noodles' western door; called from onUseCrowbar (scripts/lib/register_actions.lua)
function T.onCrowbar(player, toPosition)
	if not Family.treasureHunt or toPosition ~= T.noodlesDoor then
		return false
	end
	local door = Tile(T.noodlesDoor) and Tile(T.noodlesDoor):getItemById(1628)
	if not door then
		return false
	end
	door:transform(1629)
	T.noodlesDoor:sendMagicEffect(CONST_ME_POFF)
	addEvent(T.relockNoodles, T.relockTime * 1000)
	return true
end

function T.relockNoodles()
	local tile = Tile(T.noodlesDoor)
	if not tile then
		return
	end
	local closed = tile:getItemById(1629)
	if closed then
		closed:transform(1628)
	elseif tile:getItemById(1630) then
		addEvent(T.relockNoodles, 10 * 1000) -- still open: try again
	end
end

-- startup: carvings, Wyrdin's door and chest
function T.setup()
	for _, pos in ipairs(T.carvings) do
		local tile = Tile(pos)
		if tile and not tile:getItemById(it.carving) then
			Game.createItem(it.carving, 1, pos)
		end
	end
	local tile = Tile(T.wyrdinDoor)
	local door = tile and (tile:getItemById(1674) or tile:getItemById(1675))
	if door then
		door:setActionId(S().PoemDoor) -- data/scripts/actions/doors/quest_door.lua: opens with this storage set
	else
		logger.warn("[FamilyTreasureHunt] Wyrdin's door not found")
	end
	tile = Tile(T.poemChest)
	local chest = tile and tile:getItemById(2472)
	if chest then
		chest:setActionId(T.chestAid)
	else
		logger.warn("[FamilyTreasureHunt] Wyrdin's chest not found")
	end
	T.closeHole()
	tile = Tile(T.logbookChest)
	if tile then
		local rock = tile:getItemById(1086)
		if rock then
			rock:remove()
		end
		if not tile:getItemById(2472) then
			local box = Game.createItem(2472, 1, T.logbookChest)
			if box then
				box:setActionId(T.chestAid)
			end
		end
	end
	T.setupIsland()
end

-- ---------------------------------------------------------------------------
-- Part 3: Treasure Hunt Island
-- ---------------------------------------------------------------------------

-- Captain Waverider on Treasure Island; called from npc/captain_waverider_island.lua before his words
function T.setupWaverider(keywordHandler, npcHandler)
	local function hasQuest(player)
		return Family.treasureHunt and (player:getItemCount(it.map) > 0 or T.get(player, "Left") > 0) and T.get(player, "State") >= T.MAP
	end
	local node = keywordHandler:addKeyword({ "map" }, function(npc, creature, message, keywords, parameters, node)
		local player = Player(creature)
		if T.get(player, "Left") > 0 then
			npcHandler:say("Your timing is really bad! I have to stay here because I have been paid good money to wait for a passenger. Sorry.", npc, creature) -- EN
			npcHandler:resetNpc(creature)
			return true
		end
		npcHandler:say("This map seems to be very old, not like those fake maps that are all the rage nowadays. I know the spot on the map. It's not far from here. Do you want me to take you there?", npc, creature)
		return true
	end, nil, hasQuest)
	node:addChildKeyword({ "yes" }, function(npc, creature, message, keywords, parameters, node)
		local player = Player(creature)
		npcHandler:say("And there we go.", npc, creature) -- BR
		npcHandler:resetNpc(creature)
		if T.get(player, "State") < T.ISLAND then
			T.set(player, "State", T.ISLAND)
		end
		T.log(player, 8)
		player:teleportTo(T.islandDock)
		T.islandDock:sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end)
	node:addChildKeyword({ "" }, StdModule.say, { npcHandler = npcHandler, text = "As you wish.", reset = true }) -- ours
end

-- rum on the snake head's empty coal basin; called from scripts/actions/other/fluids.lua and for rum flasks
function T.onRum(player, item, target, toPosition)
	if not Family.treasureHunt or toPosition ~= T.basin then
		return false
	end
	if item.type ~= FLUID_RUM then
		return false
	end
	local tile = Tile(T.basin)
	local basin = tile and (tile:getItemById(2114) or tile:getItemById(2113))
	if not basin then
		return false
	end
	item:transform(item.itemid, 0)
	if basin.itemid == 2114 then
		basin:transform(2113)
		addEvent(function()
			local t = Tile(T.basin)
			local b = t and t:getItemById(2113)
			if b then
				b:transform(2114)
			end
		end, T.rumTime * 1000)
	end
	T.basin:sendMagicEffect(CONST_ME_HITBYFIRE)
	T.set(player, "RumTime", os.time())
	player:say(T.rumText, TALKTYPE_MONSTER_SAY, false, player, T.basin)
	return true
end

function T.rumFresh(player)
	return os.time() - T.get(player, "RumTime") <= T.rumTime
end

-- the bridge teleporter between the pirate statues
function T.crossBridge(player)
	if not T.rumFresh(player) and not player:getGroup():getAccess() then
		player:teleportTo(T.bridgeWest, true)
		T.bridgeWest:sendMagicEffect(CONST_ME_POFF)
		return false
	end
	T.set(player, "RumTime", 0)
	player:teleportTo(T.bridgeEast)
	T.bridgeEast:sendMagicEffect(CONST_ME_TELEPORT)
	if T.get(player, "Questline") < 9 then
		T.log(player, 9)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your questlog has been updated.") -- BR screenshot
	end
	return true
end

local function inBox(pos, box)
	return pos.z == box.z and pos.x >= box.x1 and pos.x <= box.x2 and pos.y >= box.y1 and pos.y <= box.y2
end
T.inBox = inBox

function T.freshBlood()
	for x = T.deck.x1, T.deck.x2 do
		for y = T.deck.y1, T.deck.y2 do
			local tile = Tile(Position(x, y, T.deck.z))
			if tile and tile:getItemById(2886) then
				return true
			end
		end
	end
	return false
end

-- a step on the deck; called from a position MoveEvent on every deck square
function T.onDeck(player, position, fromPosition)
	if not inBox(fromPosition, T.deck) and T.freshBlood() then
		player:teleportTo(fromPosition, true)
		player:say("You have to wait until the worst blood pools are gone.", TALKTYPE_MONSTER_SAY) -- BR screenshot
		return
	end
	local tile = Tile(position)
	if not tile or not (tile:getItemById(2145) or tile:getItemById(2146) or tile:getItemById(2148)) then
		return
	end
	-- upstream's trap.lua does the damage; we add the blood and throw them off
	local pool = Game.createItem(2886, FLUID_BLOOD, position)
	if pool then
		pool:decay()
	end
	addEvent(function(id)
		local p = Player(id)
		if p then
			p:teleportTo(T.gangway)
			p:say("Get off my deck you bleeding meatbag!!", TALKTYPE_MONSTER_SAY) -- BR screenshot
		end
	end, 100, player:getId())
end

function T.removeGhosts()
	for _, id in ipairs(T.ghosts) do
		local ghost = Creature(id)
		if ghost then
			ghost:getPosition():sendMagicEffect(CONST_ME_POFF)
			ghost:remove()
		end
	end
	T.ghosts = {}
end

-- a step in the hall of the sleeping dead pirates
function T.onHall(player, position)
	if T.hallSafe[position.x .. "," .. position.y] then
		return
	end
	T.woke[player:getId()] = true
	player:say("KRAAAAAAK", TALKTYPE_MONSTER_SAY) -- BR screenshot
	local spot = Position(position.x, position.y < 32971 and T.hall.y1 or T.hall.y2, position.z)
	local ghost = Game.createMonster("Ghostly Apparition", spot, false, true)
	if ghost then
		T.ghosts[#T.ghosts + 1] = ghost:getId()
		spot:sendMagicEffect(CONST_ME_MORTAREA)
		addEvent(function(id)
			local g = Creature(id)
			if g then
				g:remove()
			end
		end, 2 * 60 * 1000, ghost:getId())
	end
end

-- the island's magic forcefields (index into T.teleports)
function T.useTeleport(player, index)
	local tp = T.teleports[index]
	local id = player:getId()
	local to = tp.to
	if tp.hall == "reset" or tp.hall == "enter" then
		T.woke[id] = nil
		T.removeGhosts()
	elseif tp.hall == "exit" and T.woke[id] then
		T.woke[id] = nil
		T.removeGhosts()
		to = T.hallBack
		tp = { to = to }
	elseif tp.guard then
		if T.get(player, "Guard") < 1 or T.get(player, "Left") > 0 then
			player:teleportTo(T.guardGateBack, true)
			T.guardGateBack:sendMagicEffect(CONST_ME_POFF)
			return
		end
		T.log(player, 12)
	elseif tp.leave then
		T.set(player, "Left", 1)
	end
	player:teleportTo(to)
	to:sendMagicEffect(CONST_ME_TELEPORT)
	if tp.log then
		T.log(player, tp.log)
	end
end

-- Polly and Skip; called first in their npcType.onSay
function T.parrotSay(npc, creature, msgType, message, who)
	if not Family.treasureHunt then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player or npc:getPosition():getDistance(player:getPosition()) > 4 then
		return false
	end
	local id = player:getId()
	local s = T.parrots[id] or { fed = {}, step = 0 }
	T.parrots[id] = s
	local text = message:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if text == "hi" or text == "hello" then
		if player:removeItem(3598, 1) then
			s.fed[who] = true
			s.step = 0
			npc:say(who == "polly" and "<CRUNCH> GRAAAAA!" or "<CRUNCH> RAAAAAH!", TALKTYPE_SAY)
		else
			npc:say("CAAAW!", TALKTYPE_SAY) -- ours: no cookie, no talk
		end
		return true
	end
	if who ~= "polly" or not text:match("^%d+$") then
		return true
	end
	if not (s.fed.polly and s.fed.skip) then
		return true
	end
	if text ~= T.ages[s.step + 1] then
		T.parrots[id] = nil -- a wrong number ends the talk (EN)
		npc:say("GRAAAAA!", TALKTYPE_SAY) -- ours
		return true
	end
	s.step = s.step + 1
	local skip
	for _, c in ipairs(Game.getSpectators(npc:getPosition(), false, false, 8, 8, 4, 4)) do
		if c:isNpc() and c:getName() == "Skip" then
			skip = c:getId()
		end
	end
	local pollyId = npc:getId()
	for i, line in ipairs(T.parrotLines[s.step]) do
		addEvent(function()
			local speaker = Creature(line[1] == "polly" and pollyId or skip)
			if speaker then
				speaker:say(line[2], TALKTYPE_SAY)
			end
		end, (i - 1) * 1000)
	end
	if s.step == #T.ages then
		T.parrots[id] = nil
		T.set(player, "Parrots", 1)
	end
	return true
end

-- the Skeleton Guard; called from npc/skeleton_guard.lua
function T.setupGuard(keywordHandler, npcHandler)
	npcHandler:setMessage(MESSAGE_GREET, "How old is the Captain, mate?") -- EN
	keywordHandler:addKeyword({ "47" }, function(npc, creature)
		local player = Player(creature)
		npcHandler:say({ "Your answer iiiiiiisss ...", "RIGHT! Get in, mate!" }, npc, creature) -- EN
		if Family.treasureHunt and T.get(player, "State") >= T.ISLAND then
			T.set(player, "Guard", 1)
		end
		return true
	end)
end

function T.useTreasureChest(player, key, id, count, text)
	if T.get(player, key) > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
		return true
	end
	if not player:addItem(id, count) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have no room to take it.") -- ours
		return true
	end
	T.set(player, key, 1)
	T.log(player, 13)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text) -- BR screenshots
	return true
end

function T.setupIsland()
	for _, pos in ipairs(T.bridgeStatues) do
		local tile = Tile(pos)
		local statue = tile and (tile:getItemById(5673) or tile:getItemById(5671))
		if statue then
			statue:setAttribute(ITEM_ATTRIBUTE_TEXT, T.statueText)
		end
	end
	local function aid(pos, value)
		local tile = Tile(pos)
		local field = tile and tile:getItemById(1949)
		if field then
			field:setDestination(Position(0, 0, 0))
			field:setActionId(value)
			return true
		end
		logger.warn("[FamilyTreasureHunt] no magic forcefield at " .. pos:toString())
		return false
	end
	aid(T.bridgeGate, T.bridgeAid)
	for i, tp in ipairs(T.teleports) do
		aid(tp.from, T.firstTeleportAid + i - 1)
	end
	-- the spikes on the deck go up and down (items.xml: 4 s each)
	for x = T.deck.x1, T.deck.x2 do
		for y = T.deck.y1, T.deck.y2 do
			local tile = Tile(Position(x, y, T.deck.z))
			local spikes = tile and (tile:getItemById(2148) or tile:getItemById(2147))
			if spikes then
				spikes:decay()
			end
		end
	end
	for _, loot in ipairs(T.dailyLoot) do
		Game.createItem(loot[1], loot[2], loot[3])
	end
end
