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
-- Ours where the wikis say nothing: Wyrdin's line while he is still busy, the chest's messages,
-- the quest log texts, the doll's message in the pot (none: only the fire effect).
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
	-- state (Storage ...TreasureHunt.State), the main line
	TOP_RIGHT = 4,
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
	if not player:addItem(it.topRight, 1) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found the top right part of a map, but you have no room to take it.")
		return true
	end
	T.set(player, "State", T.TOP_RIGHT)
	T.log(player, 4)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found the top right part of a map.")
	return true
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
end
