-- Gaia Family server: Last Creep Standing (2026-11-25). Ours: upstream had only Casper's room under
-- the north entrance of Darashia (floor 9, the coloured carpet); Casper, Kurik's arena, the dummies, the
-- Slime Puddles and the prize room were missing (arena: world/custom/family-last-creep-standing.otbm,
-- tools/family/otbm/last_creep_standing.py).
--
-- Sources: TibiaWiki BR "Last Creep Standing" and its book, TibiaWiki EN "Last Creep Standing/Spoiler",
-- "Casper/Transcripts", "Shapeshifter Ring", "Shapechanger", "Master Shapeshifter", "Slime Puddle".
--
-- * Casper (new NPC, EN position 33261,32364,9): his rhymes (EN), `change` gives the shapechanger once
--   (EN), `reward` gives a reward box after a round in which you reached at least 4 teleporters (BR),
--   else his "not yet impressed" rhyme (EN).
-- * Rodrigo 2026-11-24: any time instead of Tibia's monthly world event. `start` to Casper (ours) begins
--   a round 30 s later for everyone standing on the carpet (Tibia warns 15 minutes ahead).
-- * The round (both wikis): in the arena's middle use the shapechanger: you become one of 8 creatures and
--   must reach its teleporter in time (northwest Thalas, north Carniphila, northeast Quara Hydromancer,
--   west Nightstalker, east Lost Soul, southwest Zombie, south Mutated Rat, southeast Blightwalker).
--   The right one sends you to a small room, a wrong one or the end of the time puts you out (back to
--   Casper). 8 cycles, each shorter (20 s down to 11 s: ours, the wikis give no times); the magic tiles
--   change your speed (fast, normal, slow: ours) and the Slime Puddles paralyse. Winning all 8: the prize
--   room, its chest gives a Shapeshifter Ring.
-- * Master Shapeshifter (EN): once you have reached a teleporter in each of the 8 forms, over any rounds.
-- * The ring (Rodrigo 2026-11-24): always works for us (in Tibia only after the world won); worn, it
--   turns you into one of the 8 creatures; the look stays 60 minutes after taking it off (EN). No
--   respawn bonus.
-- * Reward box: 4-16 chameleon runes, a time ring or boots of haste (BR; EN names only the first two).
--
-- Loaded from lib/others/load.lua.

FamilyLastCreep = {
	carpet = { x1 = 33258, y1 = 32359, x2 = 33264, y2 = 32365, z = 9 },
	casperRoom = Position(33261, 32356, 9),
	center = Position(33073, 32273, 14),
	middle = { x1 = 33071, y1 = 32271, x2 = 33075, y2 = 32275, z = 14 }, -- where the shapechanger works
	hall = { x1 = 33063, y1 = 32263, x2 = 33083, y2 = 32283, z = 14 },
	area = { x1 = 33050, y1 = 32250, x2 = 33095, y2 = 32295, z = 14 },
	waitRoom = Position(33055, 32254, 14),
	prizeRoom = Position(33090, 32255, 14),
	prizeChest = Position(33090, 32252, 14),
	prizeExitAid = 48817,
	firstTeleportAid = 48809,
	forms = { -- ORDER of tools/family/otbm/last_creep_standing.py
		{ dir = "northwest", name = "Thalas", lookType = 89 },
		{ dir = "north", name = "Carniphila", lookType = 120 },
		{ dir = "northeast", name = "Quara Hydromancer", lookType = 47 },
		{ dir = "west", name = "Nightstalker", lookType = 320 },
		{ dir = "east", name = "Lost Soul", lookType = 232 },
		{ dir = "southwest", name = "Zombie", lookType = 311 },
		{ dir = "south", name = "Mutated Rat", lookType = 305 },
		{ dir = "southeast", name = "Blightwalker", lookType = 246 },
	},
	cycleTimes = { 20, 18, 16, 15, 14, 13, 12, 11 }, -- seconds, ours
	countdown = 30, -- ours
	pause = 5, -- seconds in the small room between cycles, ours
	wand = 12251,
	ring = 907,
	rewardBox = 12057,
	achievement = "Master Shapeshifter",
	bookText = "* The events starts each 4 hours. You will be notified 15 minutes in advance.\n* When the event starts, all participants will be teleported into the challenge area.\n* Use your wand of tricks while standing on the white ground floor. You should do this immediately after you have been teleported.\n* You will be turned into a certain animal and only have a few seconds to reach the corresponding teleporter.\n* If you do not manage to reach the teleporter, you have lost your chance on that occasion and are out.\n* If you have managed to reach the safety of a room, you will be teleported back to the central chamber where the procedure begins anew.\n* The next cycle works the same but will grant you less time to reach safety.\n* This will continue for a given time.\n* In the end, at least one participant has to reach safety.\n* If no participant is left before the event ends, the event fails.\n* A world needs a certain amount of successful events in order to succeed.\n* Avoid slimes as they will slow you down.\n* Take notice of the changing floor tiles which will change your movement rate drastically.",
	books = { Position(33255, 32354, 9), Position(33267, 32354, 9) }, -- ours (EN: two books in his room)
	dummies = { -- Casper's room (EN), places ours
		{ 12047, Position(33255, 32359, 9) }, { 12053, Position(33255, 32361, 9) }, { 12048, Position(33255, 32363, 9) }, { 12051, Position(33255, 32365, 9) },
		{ 12052, Position(33267, 32359, 9) }, { 12050, Position(33267, 32361, 9) }, { 12049, Position(33267, 32363, 9) }, { 12056, Position(33267, 32365, 9) },
	},
	round = nil,
}

local L = FamilyLastCreep

local function S()
	return Storage.Quest.U8_7.LastCreepStanding
end
L.S = S

function L.get(player, key)
	return math.max(0, player:getStorageValue(S()[key]))
end

function L.set(player, key, value)
	player:setStorageValue(S()[key], value)
end

local function inBox(pos, b)
	return pos.z == b.z and pos.x >= b.x1 and pos.x <= b.x2 and pos.y >= b.y1 and pos.y <= b.y2
end
L.inBox = inBox

function L.onCarpet()
	local list = {}
	local c = L.carpet
	for x = c.x1, c.x2 do
		for y = c.y1, c.y2 do
			local tile = Tile(Position(x, y, c.z))
			if tile then
				for _, creature in ipairs(tile:getCreatures() or {}) do
					if creature:isPlayer() then
						list[#list + 1] = creature
					end
				end
			end
		end
	end
	return list
end

local function centerSpot()
	local m = L.middle
	return Position(math.random(m.x1, m.x2), math.random(m.y1, m.y2), m.z)
end

local function sendOut(player, text)
	player:removeCondition(CONDITION_OUTFIT)
	player:teleportTo(L.casperRoom)
	L.casperRoom:sendMagicEffect(CONST_ME_TELEPORT)
	if text then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	end
end

local function each(fn)
	if not L.round then
		return
	end
	for id, st in pairs(L.round.players) do
		local player = Player(id)
		if player then
			fn(player, st)
		else
			L.round.players[id] = nil
		end
	end
end

local function finishRound()
	local round = L.round
	if not round then
		return
	end
	each(function(player, st)
		if st.reached >= 4 then
			L.set(player, "Reward", 1)
		end
	end)
	L.round = nil
end

-- Casper's `start`
function L.start(npc)
	if L.round then
		return "busy"
	end
	local players = L.onCarpet()
	if #players == 0 then
		return "empty"
	end
	L.round = { players = {}, cycle = 0, starting = true }
	for _, player in ipairs(players) do
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The darashian journey will begin in " .. L.countdown .. " seconds! Stay on the carpet.") -- ours (Tibia: 15 minutes)
	end
	addEvent(L.begin, L.countdown * 1000)
	return "ok"
end

function L.begin()
	if not L.round then
		return
	end
	for _, player in ipairs(L.onCarpet()) do
		L.round.players[player:getId()] = { alive = true, reached = 0 }
	end
	L.round.starting = false
	if next(L.round.players) == nil then
		L.round = nil
		return
	end
	L.nextCycle()
end

function L.nextCycle()
	local round = L.round
	if not round then
		return
	end
	round.cycle = round.cycle + 1
	local cycle = round.cycle
	local alive = 0
	each(function(player, st)
		if st.alive then
			alive = alive + 1
			st.form, st.done = nil, false
			local spot = centerSpot()
			player:teleportTo(spot)
			spot:sendMagicEffect(CONST_ME_TELEPORT)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Cycle %d of %d: use your shapechanger! You have %d seconds.", cycle, #L.cycleTimes, L.cycleTimes[cycle])) -- ours
		end
	end)
	if alive == 0 then
		finishRound()
		return
	end
	round.deadline = os.time() + L.cycleTimes[cycle]
	round.event = addEvent(L.endCycle, L.cycleTimes[cycle] * 1000, cycle)
end

function L.endCycle(cycle)
	local round = L.round
	if not round or round.cycle ~= cycle then
		return
	end
	local survivors = 0
	each(function(player, st)
		if st.alive and not st.done then
			st.alive = false
			sendOut(player, "You were too slow. You are out of this round.") -- ours
		elseif st.alive then
			survivors = survivors + 1
		end
	end)
	if survivors == 0 then
		finishRound()
		return
	end
	if cycle >= #L.cycleTimes then
		each(function(player, st)
			if st.alive then
				L.set(player, "Ring", 1)
				player:removeCondition(CONDITION_OUTFIT)
				player:teleportTo(L.prizeRoom)
				L.prizeRoom:sendMagicEffect(CONST_ME_TELEPORT)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have mastered Kurik's challenge! Open the chest.") -- ours
			end
		end)
		finishRound()
		return
	end
	addEvent(L.nextCycle, L.pause * 1000)
end

-- the shapechanger
function L.useWand(player)
	local round = L.round
	local st = round and round.players[player:getId()]
	if not st or not st.alive or st.done or not inBox(player:getPosition(), L.middle) then
		player:sendCancelMessage("It might do some funny things to you, but not here.") -- ours
		return true
	end
	if st.form then
		return true
	end
	st.form = math.random(#L.forms)
	local condition = Condition(CONDITION_OUTFIT)
	condition:setTicks(L.cycleTimes[round.cycle] * 1000 + 2000)
	condition:setOutfit({ lookType = L.forms[st.form].lookType })
	player:addCondition(condition)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end

-- a teleporter of the arena (index into L.forms)
function L.enterTeleport(player, index)
	local round = L.round
	local st = round and round.players[player:getId()]
	if not st or not st.alive or st.done then
		sendOut(player)
		return
	end
	if st.form ~= index then
		st.alive = false
		sendOut(player, "This was not your teleporter. You are out of this round.") -- ours
		return
	end
	st.done = true
	st.reached = st.reached + 1
	local forms = bit.bor(L.get(player, "Forms"), bit.lshift(1, index - 1))
	L.set(player, "Forms", forms)
	if forms == 255 and not player:hasAchievement(L.achievement) then
		player:addAchievement(L.achievement)
	end
	player:removeCondition(CONDITION_OUTFIT)
	player:teleportTo(L.waitRoom)
	L.waitRoom:sendMagicEffect(CONST_ME_TELEPORT)
end

-- the magic tiles: their colour decides your speed for a moment (ours)
L.tileSpeed = { [12285] = 1, [12286] = 1, [12287] = 1, [12288] = 0, [12289] = 0, [12290] = 0, [12291] = -1, [12292] = -1, [12293] = -1 }

function L.onTile(player, itemId)
	local effect = L.tileSpeed[itemId]
	if not effect or effect == 0 then
		return
	end
	local condition = Condition(effect > 0 and CONDITION_HASTE or CONDITION_PARALYZE)
	condition:setTicks(1500)
	condition:setParameter(CONDITION_PARAM_SPEED, effect > 0 and 150 or -150)
	player:addCondition(condition)
end

-- Casper
function L.casper(npc, creature, message, npcHandler)
	if not Family.lastCreep then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	if MsgContains(message, "change") then
		if L.get(player, "Wand") > 0 then
			npcHandler:say("You've got your wand. Now leave me be. I say farewell, away with thee.", npc, creature) -- EN
			return true
		end
		player:addItem(L.wand, 1)
		L.set(player, "Wand", 1)
		npcHandler:say("Since you asked that cute and nice, I offer you this strange device.", npc, creature) -- EN
		return true
	end
	if MsgContains(message, "reward") then
		if L.get(player, "Reward") < 1 then
			npcHandler:say("I'm not yet impressed and just for the rhyme ask me again but another time.", npc, creature) -- EN
			return true
		end
		player:addItem(L.rewardBox, 1)
		L.set(player, "Reward", 0)
		npcHandler:say("Thanks little hero for trying so hard. In the name of Lord Kurik here is your reward!", npc, creature) -- BR/EN
		return true
	end
	if MsgContains(message, "start") then
		local result = L.start(npc)
		if result == "busy" then
			npcHandler:say("A journey is under way, so wait for your turn another day. Or rather a minute or two.", npc, creature) -- ours
		elseif result == "empty" then
			npcHandler:say("On the carpet you must stand, before I send you to Kurik's land.", npc, creature) -- ours
		else
			npcHandler:say("In half a minute you will go. Stay on the carpet and you will know!", npc, creature) -- ours
		end
		return true
	end
	return false
end

-- the prize chest
function L.usePrizeChest(player)
	if L.get(player, "Ring") < 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
		return true
	end
	if not player:addItem(L.ring, 1) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a shapeshifter ring, but you have no room to take it.")
		return true
	end
	L.set(player, "Ring", 0)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a shapeshifter ring.")
	return true
end

-- the reward box: BR (EN names only runes and the time ring)
function L.openRewardBox(player, item)
	local roll = math.random(3)
	local pos = player:getPosition()
	if roll == 1 then
		player:addItem(3178, math.random(4, 16)) -- chameleon runes
	elseif roll == 2 then
		player:addItem(3053, 1) -- time ring
	else
		player:addItem(3079, 1) -- boots of haste
	end
	item:remove(1)
	pos:sendMagicEffect(CONST_ME_GIFT_WRAPS)
	return true
end

-- the shapeshifter ring, worn: one of the 8 creatures, for 60 more minutes after taking it off (EN)
function L.wearRing(player, item)
	local form = L.forms[math.random(#L.forms)]
	local condition = Condition(CONDITION_OUTFIT)
	condition:setTicks(60 * 60 * 1000)
	condition:setOutfit({ lookType = form.lookType })
	player:addCondition(condition)
	item:decay()
end

-- a player who logs in inside the arena (logged out during a round) goes back to Casper
function L.onLogin(player)
	if inBox(player:getPosition(), L.area) and not (L.round and L.round.players[player:getId()]) then
		player:teleportTo(L.casperRoom)
	end
end

-- startup: dummies and books in Casper's room, the magic tiles start changing
function L.setup()
	for _, d in ipairs(L.dummies) do
		local tile = Tile(d[2])
		if tile and not tile:getItemById(d[1]) then
			Game.createItem(d[1], 1, d[2])
		end
	end
	for _, pos in ipairs(L.books) do
		local tile = Tile(pos)
		if tile and not tile:getItemById(2821) then
			local book = Game.createItem(2821, 1, pos)
			if book then
				book:setAttribute(ITEM_ATTRIBUTE_TEXT, L.bookText)
			end
		end
	end
	local h = L.hall
	for x = h.x1, h.x2 do
		for y = h.y1, h.y2 do
			local tile = Tile(Position(x, y, h.z))
			local ground = tile and tile:getGround()
			if ground and L.tileSpeed[ground.itemid] then
				ground:decay()
			end
		end
	end
end
