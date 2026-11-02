-- Gaia Family server: Blood Brothers Quest, the world side of missions 4-10 (2026-11-02).
-- Ours, not upstream (upstream Canary v3.6.1 has the castle on the map but nothing wired).
-- Dialogue and shared data: lib/others/family_blood_brothers.lua (FamilyBloodBrothers).
--
-- Every square here was matched with our map (tools/family/otbm) against TibiaWiki BR (points
-- and screenshots on the quest page) and TibiaWiki EN (Mapper Coords):
--   * Julius' map (8200): used inside one of the eight spot areas marks it (orange text, ours).
--   * Blood crystal: the chest behind the door in the cult hideout, floor -3 (32776,31105,10).
--   * Castle spots: the strange carving (32941,31510,7), BR's fourth point (32946,31499,6) and the
--     squares around the two tar squares with dry grass (32928,31460,7 and 32966,31498,6, BR).
--     Family rule: two players with charged crystals on two spots at once are teleported inside.
--   * The mystic flame of the castle gate (32953,31486,6) sends everyone in; until the castle
--     attuned you (Mission 05 step 4) you are put back outside (Julius: "a strong magic barrier").
--   * Boss rooms: the vampire lord statues at the top of four towers (z2) and the round rooms
--     below them (z1, each with its own mystic flame out):
--       Boreth   fire bug three times on the twines in front of 32940,31475,2 (EN)
--       Lersatio break two of the three wall mirrors around 32967,31457,2 (EN/BR)
--       Marziel  a pool of blood (vial of blood) in front of 32940,31457,2 and step on it:
--                two vampire brides; killing one opens the way (BR; no female needed here)
--       Arthei   use the ghost's tear twice on 32953,31440,2; ten minutes to kill him (EN)
--     A blessed wooden stake on the boss' remains gives the dust (message from both wikis).
--   * Diary pages, the torn diary and the blood goblet: the containers named in
--     FamilyBloodBrothers.pages / BOOK_POS / GOBLET_POS ("You have found ...").
--   * The courtyard door (32953,31451,4) opens after Julius' crest (BR).
--   * His True Face: on the second "alori mort" Armenius may show his true face
--     (FamilyBloodBrothers.TRUE_FACE_CHANCE, ours; EN: "very rarely") and you fight him in his
--     cellar under the tavern (32856-32861,31321-31326,8), teleported out when he dies (EN).
-- Lines marked "ours" are not in either wiki.

local B = FamilyBloodBrothers
if not B then
	return
end
local S = B.S
local BB = Storage.Quest.U8_4.BloodBrothers

B.TRUE_FACE_CHANCE = 10 -- percent (ours)
B.GOBLET_POS = Position(32953, 31474, 4)
B.GARDEN_DOOR = Position(32953, 31451, 4)
B.CASTLE_FLAME = Position(32953, 31486, 6)
B.CASTLE_OUTSIDE = Position(32953, 31488, 6)
B.CRYSTAL_CHEST = Position(32776, 31105, 10)
B.HALL = { Position(32952, 31481, 6), Position(32953, 31481, 6), Position(32952, 31482, 6), Position(32953, 31482, 6) }
B.ROOM_EXIT = Position(32967, 31480, 1) -- where the mystic flames of the boss rooms lead

-- The two tar squares cannot be walked on, so any square next to them counts (BR's 32927,31460,7
-- is one of them); the strange carving and BR's fourth point count exactly.
B.carvings = {
	{ pos = Position(32941, 31510, 7), spot = 2 },
	{ pos = Position(32946, 31499, 6), spot = 3 },
}
for _, c in ipairs({ { Position(32928, 31460, 7), 1 }, { Position(32966, 31498, 6), 4 } }) do
	for dx = -1, 1 do
		for dy = -1, 1 do
			if dx ~= 0 or dy ~= 0 then
				B.carvings[#B.carvings + 1] = { pos = Position(c[1].x + dx, c[1].y + dy, c[1].z), spot = c[2] }
			end
		end
	end
end

B.rooms = {
	boreth = {
		mission = S.Mission07,
		statue = Position(32940, 31475, 2),
		twines = { Position(32939, 31476, 2), Position(32940, 31476, 2), Position(32941, 31476, 2) },
		top = Position(32940, 31477, 2),
		dest = Position(32940, 31478, 1),
		boss = { "Boreth", Position(32940, 31476, 1) },
		adds = { { "Plaguethrower", Position(32938, 31476, 1) }, { "Plaguethrower", Position(32942, 31476, 1) } }, -- EN
		minutes = 20,
	},
	lersatio = {
		mission = S.Mission08,
		statue = Position(32967, 31457, 2),
		mirrors = { Position(32966, 31456, 2), Position(32968, 31456, 2), Position(32965, 31457, 2) },
		top = Position(32967, 31459, 2),
		dest = Position(32967, 31461, 1),
		boss = { "Lersatio", Position(32967, 31458, 1) },
		adds = { { "Vampire", Position(32966, 31458, 1) }, { "Vampire", Position(32968, 31458, 1) } }, -- EN
		minutes = 20,
	},
	marziel = {
		mission = S.Mission09,
		statue = Position(32940, 31457, 2),
		blood = Position(32940, 31458, 2),
		brides = { Position(32938, 31458, 2), Position(32942, 31458, 2) },
		top = Position(32940, 31459, 2),
		dest = Position(32940, 31461, 1),
		boss = { "Marziel", Position(32940, 31458, 1) },
		adds = { { "Vampire", Position(32941, 31458, 1) } }, -- EN
		minutes = 20,
	},
	arthei = {
		mission = S.Mission10,
		statue = Position(32953, 31440, 2),
		top = Position(32953, 31442, 2),
		dest = Position(32953, 31444, 1),
		boss = { "Arthei", Position(32953, 31441, 1) },
		adds = { { "Vampire", Position(32952, 31441, 1) }, { "Vampire", Position(32954, 31441, 1) } }, -- EN
		minutes = 10, -- EN: "You'll have 10 minutes to defeat him."
	},
}
for key, room in pairs(B.rooms) do
	room.key = key
end

B.cellar = {
	from = Position(32856, 31321, 8),
	to = Position(32861, 31326, 8),
	player = Position(32857, 31325, 8),
	monster = Position(32857, 31322, 8),
	out = Position(32857, 31328, 7),
	minutes = 5, -- ours
}

local function isPlayerOk(creature)
	return creature and creature:isPlayer()
end

local function playersNear(center, rx, ry)
	return Game.getSpectators(center, false, true, rx, rx, ry, ry)
end

local function statueAwake(pos, seconds)
	local tile = Tile(pos)
	local statue = tile and tile:getItemById(8325)
	if statue then
		statue:transform(8326) -- "it will change into a real Vampire Lord" (EN)
		pos:sendMagicEffect(CONST_ME_MORTAREA)
		addEvent(function()
			local t = Tile(pos)
			local lord = t and t:getItemById(8326)
			if lord then
				lord:transform(8325)
			end
		end, (seconds or 10) * 1000)
	end
end

local function shout(player, text, pos)
	player:say(text, TALKTYPE_MONSTER_YELL, false, nil, pos)
end

local function roomBusy(room)
	return room.bossId and Creature(room.bossId) ~= nil
end

local function clearRoom(room)
	local boss = room.bossId and Creature(room.bossId)
	if boss then
		boss:remove()
	end
	for _, id in ipairs(room.addIds or {}) do
		local add = Creature(id)
		if add then
			add:remove()
		end
	end
	room.bossId, room.addIds = nil, {}
end

-- teleports everyone in the statue room down to the boss room and starts the fight
local function startFight(room)
	clearRoom(room)
	for _, p in ipairs(playersNear(room.top, 4, 4)) do
		if p:getPosition().z == room.top.z then
			p:teleportTo(room.dest)
			room.dest:sendMagicEffect(CONST_ME_TELEPORT)
		end
	end
	local boss = Game.createMonster(room.boss[1], room.boss[2], false, true)
	if not boss then
		logger.warn("[FamilyBloodBrothers] could not create {}", room.boss[1])
		return
	end
	boss:registerEvent("FamilyBloodBrotherDeath")
	room.bossId = boss:getId()
	room.addIds = {}
	for _, add in ipairs(room.adds) do
		local m = Game.createMonster(add[1], add[2], false, true)
		if m then
			room.addIds[#room.addIds + 1] = m:getId()
		end
	end
	local bossId = room.bossId
	addEvent(function()
		if room.bossId ~= bossId or not Creature(bossId) then
			return
		end
		for _, p in ipairs(playersNear(room.dest, 5, 5)) do
			if p:getPosition().z == room.dest.z then
				p:teleportTo(B.ROOM_EXIT)
				p:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Time is up. " .. room.boss[1] .. " has vanished into the shadows.") -- ours
			end
		end
		clearRoom(room)
	end, room.minutes * 60 * 1000)
end
B.startFight = startFight

local function onMission(player, room)
	return Family.bloodBrothers and B.get(player, room.mission) == 1
end

-- ---------------------------------------------------------------------------
-- Julius' map
-- ---------------------------------------------------------------------------
local juliusMap = Action()

function juliusMap.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.bloodBrothers or B.get(player, BB.Mission04) < 1 then
		return false
	end
	local pos = player:getPosition()
	for i, spot in ipairs(B.spots) do
		if B.inBox(pos, spot.from, spot.to) then
			local bit = 2 ^ (i - 1)
			if math.floor(B.marks(player) / bit) % 2 == 1 then
				player:say("You have already marked the " .. spot.name .. " on Julius' map.", TALKTYPE_MONSTER_SAY) -- ours
			else
				player:setStorageValue(S.Marks, B.get(player, S.Marks) + bit)
				player:say("You mark the " .. spot.name .. " on Julius' map.", TALKTYPE_MONSTER_SAY) -- ours (BR: an orange message)
				pos:sendMagicEffect(CONST_ME_MAGIC_BLUE)
			end
			return true
		end
	end
	player:sendTextMessage(MESSAGE_FAILURE, "There is nothing remarkable here to mark on the map.") -- ours
	return true
end

juliusMap:id(B.JULIUS_MAP)
juliusMap:register()

-- ---------------------------------------------------------------------------
-- containers with quest items (position actions: false = the container opens as usual)
-- ---------------------------------------------------------------------------
local function giveFound(player, itemId, bit, text)
	local it = player:addItem(itemId, 1)
	if not it then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. ItemType(itemId):getArticle() .. " " .. ItemType(itemId):getName() .. ". It is too heavy for you or you have no room for it.")
		return true
	end
	if text then
		it:setAttribute(ITEM_ATTRIBUTE_TEXT, text)
	end
	B.setBit(player, S.Finds, bit)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. ItemType(itemId):getArticle() .. " " .. ItemType(itemId):getName() .. ".")
	return true
end

local crystalChest = Action()
function crystalChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.bloodBrothers or B.get(player, S.Mission05) < 1 or B.hasBit(player, S.Finds, B.F_CHEST) then
		return false
	end
	return giveFound(player, B.CRYSTAL, B.F_CHEST)
end
crystalChest:position(B.CRYSTAL_CHEST)
crystalChest:register()

local diaryBook = Action()
function diaryBook.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.bloodBrothers or B.get(player, S.Mission06) < 1 or B.hasBit(player, S.Finds, B.F_BOOK) then
		return false
	end
	return giveFound(player, B.TORN_BOOK, B.F_BOOK, B.BOOK_TEXT)
end
diaryBook:position(B.BOOK_POS)
diaryBook:register()

for i, page in ipairs(B.pages) do
	local action = Action()
	function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
		if not Family.bloodBrothers or B.get(player, S.Mission05) < 4 or B.hasBit(player, S.Finds, B.pageFoundBit(i)) then
			return false
		end
		return giveFound(player, page.id, B.pageFoundBit(i), page.text)
	end
	for _, pos in ipairs(page.pos) do
		action:position(pos)
	end
	action:register()
end

local goblet = Action()
function goblet.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.bloodBrothers or B.hasBit(player, S.Finds, B.F_GOBLET) then
		return false
	end
	giveFound(player, B.GOBLET, B.F_GOBLET)
	B.checkCastlemania(player)
	return true
end
goblet:position(B.GOBLET_POS)
goblet:register()

-- ---------------------------------------------------------------------------
-- the courtyard door (opens after the four brothers, BR)
-- ---------------------------------------------------------------------------
local function gardenAllowed(player)
	return not Family.bloodBrothers or B.hasBit(player, S.Finds, B.F_GARDEN) or player:getGroup():getId() >= GROUP_TYPE_GAMEMASTER
end

local gardenDoor = Action()
function gardenDoor.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid == 8262 then
		item:transform(8261)
		return true
	end
	if not gardenAllowed(player) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to be sealed against unwanted intruders.") -- Tibia's quest door line
		return true
	end
	item:transform(8262)
	player:teleportTo(toPosition, true)
	return true
end
gardenDoor:position(B.GARDEN_DOOR)
gardenDoor:register()

local gardenStep = MoveEvent()
function gardenStep.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player and not gardenAllowed(player) then
		player:teleportTo(fromPosition, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to be sealed against unwanted intruders.")
	end
	return true
end
gardenStep:type("stepin")
gardenStep:position(B.GARDEN_DOOR)
gardenStep:register()

local gardenOut = MoveEvent()
function gardenOut.onStepOut(creature, item, position, fromPosition)
	addEvent(function()
		local tile = Tile(B.GARDEN_DOOR)
		local door = tile and tile:getItemById(8262)
		if door and not tile:getTopCreature() then
			door:transform(8261)
		end
	end, 100)
	return true
end
gardenOut:type("stepout")
gardenOut:position(B.GARDEN_DOOR)
gardenOut:register()

-- ---------------------------------------------------------------------------
-- Mission 05: the castle spots and the barrier at the gate
-- ---------------------------------------------------------------------------
local function attuneReady(player)
	return player:getItemCount(B.CRYSTAL_CHARGED) > 0 and B.get(player, S.Mission05) >= 3
end

local carving = MoveEvent()
function carving.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.bloodBrothers or not attuneReady(player) then
		return true
	end
	position:sendMagicEffect(CONST_ME_MAGIC_RED)
	local found, spots = {}, {}
	for _, c in ipairs(B.carvings) do
		local tile = Tile(c.pos)
		local top = tile and tile:getTopCreature()
		local who = top and top:getPlayer()
		if who and not spots[c.spot] and attuneReady(who) then
			local dup = false
			for _, f in ipairs(found) do
				if f:getId() == who:getId() then
					dup = true
				end
			end
			if not dup then
				spots[c.spot] = true
				found[#found + 1] = who
			end
		end
	end
	if #found < 2 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your blood crystal glows, but its energy is not enough on its own. Someone else with a charged crystal has to stand on another of these symbols.") -- ours
		return true
	end
	for i, p in ipairs(found) do
		if B.get(p, S.Mission05) == 3 then
			p:setStorageValue(S.Mission05, 4)
		end
		local dest = B.HALL[(i - 1) % #B.HALL + 1]
		p:teleportTo(dest)
		dest:sendMagicEffect(CONST_ME_TELEPORT)
		p:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The dark energy of the castle flows into your crystal and through you. You are attuned to the castle.") -- ours
	end
	return true
end
carving:type("stepin")
for _, c in ipairs(B.carvings) do
	carving:position(c.pos)
end
carving:register()

local barrier = MoveEvent()
function barrier.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.bloodBrothers then
		return true
	end
	if B.get(player, S.Mission05) >= 4 or player:getGroup():getId() >= GROUP_TYPE_GAMEMASTER then
		return true
	end
	-- the mystic flame has already moved the player in (teleport before the step event)
	player:teleportTo(B.CASTLE_OUTSIDE)
	B.CASTLE_OUTSIDE:sendMagicEffect(CONST_ME_ENERGYAREA)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A strong magic barrier blocks the entrance to the castle.") -- ours, from Julius' words
	return true
end
barrier:type("stepin")
barrier:position(B.CASTLE_FLAME)
barrier:register()

-- ---------------------------------------------------------------------------
-- the four boss rooms
-- ---------------------------------------------------------------------------
-- Boreth: fire bug (5467) on the twines; called from scripts/quests/others/actions_fire_bug.lua
function B.onFireBug(player, item, target, toPosition)
	local room = B.rooms.boreth
	local onTwines = false
	for _, pos in ipairs(room.twines) do
		if toPosition == pos then
			onTwines = true
		end
	end
	if not onTwines or not onMission(player, room) then
		return false
	end
	toPosition:sendMagicEffect(CONST_ME_HITBYFIRE)
	if roomBusy(room) then
		return true
	end
	if not room.burnTime or os.time() - room.burnTime > 60 then
		room.burns = 0
	end
	room.burnTime = os.time()
	room.burns = room.burns + 1
	if room.burns == 1 then
		statueAwake(room.statue, 10)
		shout(player, "WHAT ARE YOU DOING TO MY PLANTS?!", room.statue) -- ours
	elseif room.burns >= 3 then
		room.burns = 0
		shout(player, "YOU WILL PAY FOR THIS!", room.statue) -- ours
		startFight(room)
	end
	return true
end

-- Lersatio: break two of the wall mirrors
local mirror = Action()
function mirror.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local room = B.rooms.lersatio
	if item.itemid ~= 8667 or not onMission(player, room) then
		return false
	end
	if roomBusy(room) then
		return true
	end
	local pos = item:getPosition()
	item:transform(8721)
	pos:sendMagicEffect(CONST_ME_POFF)
	addEvent(function()
		local tile = Tile(pos)
		local broken = tile and tile:getItemById(8721)
		if broken then
			broken:transform(8667)
		end
	end, 60 * 1000)
	if not room.mirrorTime or os.time() - room.mirrorTime > 60 then
		room.mirrorsBroken = 0
	end
	room.mirrorTime = os.time()
	room.mirrorsBroken = room.mirrorsBroken + 1
	if room.mirrorsBroken == 1 then
		statueAwake(room.statue, 10)
		shout(player, "STOP THAT! MY MIRRORS!", room.statue) -- ours
	else
		room.mirrorsBroken = 0
		shout(player, "YOU WILL REGRET THIS, WORM!", room.statue) -- ours
		startFight(room)
	end
	return true
end
for _, pos in ipairs(B.rooms.lersatio.mirrors) do
	mirror:position(pos)
end
mirror:register()

-- Marziel: step on a pool of blood in front of his statue
local bloodPool = MoveEvent()
function bloodPool.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	local room = B.rooms.marziel
	if not player or not onMission(player, room) or roomBusy(room) then
		return true
	end
	if room.bridesAt and os.time() - room.bridesAt < 120 then
		return true
	end
	local tile = Tile(room.blood)
	local pool = tile and tile:getItemById(2886)
	if not pool or pool:getFluidType() ~= 5 then -- 5 = blood
		return true
	end
	room.bridesAt = os.time()
	statueAwake(room.statue, 10)
	shout(player, "AAAAH... BLOOD... MY BRIDES, BRING ME MORE!", room.statue) -- ours
	for _, pos in ipairs(room.brides) do
		local bride = Game.createMonster("Vampire Bride", pos, false, true)
		if bride then
			bride:registerEvent("FamilyBloodBrothersBride")
		end
	end
	return true
end
bloodPool:type("stepin")
bloodPool:position(B.rooms.marziel.blood)
bloodPool:register()

local brideDeath = CreatureEvent("FamilyBloodBrothersBride")
function brideDeath.onDeath(creature)
	local room = B.rooms.marziel
	if not room.bridesAt or roomBusy(room) then
		return true
	end
	room.bridesAt = nil
	addEvent(startFight, 500, room)
	return true
end
brideDeath:register()

-- Arthei: the ghost's tear twice on his statue
local tear = Action()
function tear.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local room = B.rooms.arthei
	if not target or not target.getId or toPosition ~= room.statue or not onMission(player, room) then
		return false
	end
	if roomBusy(room) then
		return true
	end
	if not room.tearTime or os.time() - room.tearTime > 60 then
		room.tears = 0
	end
	room.tearTime = os.time()
	room.tears = room.tears + 1
	if room.tears == 1 then
		statueAwake(room.statue, 10)
		shout(player, "...KALA...?", room.statue) -- ours
	else
		room.tears = 0
		item:remove(1)
		shout(player, "KALA! NO... YOU WILL NOT TAKE HER FROM ME AGAIN!", room.statue) -- ours
		startFight(room)
	end
	return true
end
tear:id(B.GHOST_TEAR)
tear:register()

-- Arthei's shadows of his brothers (TibiaWiki EN: "rarely summons")
local shadows = Spell("instant")
function shadows.onCastSpell(creature, var)
	for _, s in ipairs(creature:getSummons()) do
		if s:getName():find("Shadow of", 1, true) then
			return false
		end
	end
	local names = { "Shadow of Boreth", "Shadow of Lersatio", "Shadow of Marziel" }
	local s = Game.createMonster(names[math.random(#names)], creature:getPosition(), true)
	if s then
		s:setMaster(creature)
		s:getPosition():sendMagicEffect(CONST_ME_MORTAREA)
		creature:say("Marziel! Lersatio! Boreth! Come join me in this fight!", TALKTYPE_MONSTER_SAY) -- his voice (EN)
	end
	return true
end
shadows:name("arthei shadows")
shadows:words("###48767")
shadows:blockWalls(true)
shadows:needLearn(true)
shadows:register()

-- the boss' remains: marked for the stake; Boreth's plaguethrowers go with him
local bossDeath = CreatureEvent("FamilyBloodBrotherDeath")
function bossDeath.onDeath(creature, corpse)
	for key, room in pairs(B.rooms) do
		if room.bossId == creature:getId() then
			if corpse and corpse.setCustomAttribute then
				corpse:setCustomAttribute("familyBloodBrother", key)
			end
			room.bossId = nil
			for _, id in ipairs(room.addIds or {}) do
				local add = Creature(id)
				if add and add:getName() == "Plaguethrower" then
					add:remove()
				end
			end
			room.addIds = {}
		end
	end
	return true
end
bossDeath:register()

-- the blessed wooden stake on the remains; called from scripts/actions/tools/skinning.lua
function B.onStake(player, item, target)
	if not Family.bloodBrothers or item.itemid ~= 5942 or not target or target.itemid ~= 8109 or not target.getCustomAttribute then
		return false
	end
	local key = target:getCustomAttribute("familyBloodBrother")
	local room = key and B.rooms[key]
	if not room then
		return false
	end
	local name = room.boss[1]
	if B.get(player, room.mission) ~= 1 then
		player:sendCancelMessage("You don't need this proof.") -- ours
		return true
	end
	if player:getItemCount(B.DUST[key]) > 0 then
		player:sendCancelMessage("You already have some of " .. name .. "'s dust.") -- ours
		return true
	end
	player:addItem(B.DUST[key], 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You got some ounces of " .. name .. "'s dust. This should be enough proof that you killed him.") -- both wikis
	target:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end

-- ---------------------------------------------------------------------------
-- His True Face (Armenius' cellar); called from npc/armenius.lua
-- ---------------------------------------------------------------------------
function B.trueFace(npc, player, npcHandler)
	if not Family.bloodBrothers or player:hasAchievement("His True Face") then
		return false
	end
	local cellar = B.cellar
	if cellar.monsterId and Creature(cellar.monsterId) then
		return false
	end
	if math.random(100) > B.TRUE_FACE_CHANCE then
		return false
	end
	npcHandler:say("You know what, I changed my mind. BRING IT!", npc, player) -- a sound of Armenius (Creature), EN
	local playerId = player:getId()
	addEvent(function()
		local p = Player(playerId)
		if not p then
			return
		end
		p:teleportTo(cellar.player)
		cellar.player:sendMagicEffect(CONST_ME_TELEPORT)
		local m = Game.createMonster("Armenius (Creature)", cellar.monster, false, true)
		if m then
			m:registerEvent("FamilyBloodBrothersArmenius")
			cellar.monsterId = m:getId()
			local id = cellar.monsterId
			addEvent(function()
				local left = Creature(id)
				if left then
					left:remove()
					B.leaveCellar()
				end
			end, cellar.minutes * 60 * 1000)
		end
		p:addAchievement("His True Face")
	end, 1000)
	return true
end

function B.leaveCellar()
	local c = B.cellar
	for _, p in ipairs(Game.getSpectators(Position(32858, 31323, 8), false, true, 4, 4, 4, 4)) do
		if B.inBox(p:getPosition(), c.from, c.to) then
			p:teleportTo(c.out)
			c.out:sendMagicEffect(CONST_ME_TELEPORT)
		end
	end
end

local armeniusDeath = CreatureEvent("FamilyBloodBrothersArmenius")
function armeniusDeath.onDeath(creature)
	B.cellar.monsterId = nil
	addEvent(B.leaveCellar, 1000) -- EN: "You get teleported out of Armenius room once you kill it"
	return true
end
armeniusDeath:register()

-- ---------------------------------------------------------------------------
-- login: out of the cellar if logged out there; Castlemania for those who finish the
-- Vampire Hunter Quest last
-- ---------------------------------------------------------------------------
local login = CreatureEvent("FamilyBloodBrothersLogin")
function login.onLogin(player)
	if not Family.bloodBrothers then
		return true
	end
	local c = B.cellar
	if B.inBox(player:getPosition(), c.from, c.to) and not (c.monsterId and Creature(c.monsterId)) then
		player:teleportTo(c.out)
	end
	if B.get(player, S.Mission10) >= 2 then
		B.checkCastlemania(player)
	end
	return true
end
login:register()

-- ---------------------------------------------------------------------------
-- startup: check that the map still has what the quest needs
-- ---------------------------------------------------------------------------
local check = GlobalEvent("FamilyBloodBrothersCheck")
function check.onStartup()
	if not Family.bloodBrothers then
		return true
	end
	local need = {
		{ B.rooms.boreth.statue, 8325 },
		{ B.rooms.lersatio.statue, 8325 },
		{ B.rooms.marziel.statue, 8325 },
		{ B.rooms.arthei.statue, 8325 },
		{ B.CASTLE_FLAME, 1959 },
		{ B.CRYSTAL_CHEST, 2472 },
		{ B.GARDEN_DOOR, 8261 },
		{ B.BOOK_POS, 2435 },
	}
	for _, pos in ipairs(B.rooms.lersatio.mirrors) do
		need[#need + 1] = { pos, 8667 }
	end
	for _, pos in ipairs(B.rooms.boreth.twines) do
		need[#need + 1] = { pos, 6219 }
	end
	local missing = 0
	for _, n in ipairs(need) do
		local tile = Tile(n[1])
		if not tile or not tile:getItemById(n[2]) then
			missing = missing + 1
			logger.warn("[FamilyBloodBrothers] item {} missing at {}", n[2], n[1]:toString())
		end
	end
	if missing == 0 then
		logger.info("[FamilyBloodBrothers] castle checked")
	end
	return true
end
check:register()
