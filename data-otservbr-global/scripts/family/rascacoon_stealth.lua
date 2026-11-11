-- Gaia Family server: the stealth mission of Eustacio's Spy Rat (A Pirate's Tail Quest, part 2c, 2026-11-11).
-- Ours, not upstream. Sources: TibiaWiki EN quest spoiler (rules, transcript, the Stealth Map picture),
-- EN Pirat Guard and Pirat Patrol pages, TibiaMaps floor 14 and 15 (map shape), the client 15.11 sprites.
--
-- The teleport next to the Spy Rat (33855,31334,9, on the map) leads to the lever room. The lever
-- (33894,31311,15) takes up to three players standing on 33895-33897,31311 (BR) who helped Tik'hi Tak'he
-- and are not waiting (StealthTime) into the pirat laboratory maze (x 33891-33922, y 31269-31299). They
-- arrive disguised as rats with five minutes, shown as a countdown in seconds under the name (EN).
-- Pirat Guards stand still and Pirat Patrols walk back and forth; anyone on a square next to one of them
-- (same floor) is thrown out (EN). The glowing-bug wall lamps on the towers go dark for moments, blinking
-- before they change (EN); while a lamp is lit, the tower guard on top sees anyone on a square next to the
-- lamp. The End teleport (33901,31282-31283, on the map) leads into the lab; using the chest with the
-- mouldy powder (33903,31248) gives 200 trust points, again after 20 hours (BR/EN). Time out or caught =
-- out next to the Spy Rat without points.
--
-- Floor 14: real Tibia has two raised platforms, a rock block and a tower top above every lamp on floor
-- 14; our map has none of it (Rodrigo chose on 2026-11-11 to build it). The squares below are created at
-- startup, from the TibiaMaps floor 14 shape; ground and objects were picked square by square by matching
-- the EN Stealth Map picture (which shows floor 14 drawn one square up-left) against the client sprites.
-- Levitate (exani hur up/down) and parcels then work by the engine's own rules.
--
-- Ours (the wikis do not give them): the guard and patrol places from the EN map's health bars; the patrol
-- paths (one snapshot each in the EN picture, paths chosen so that the EN coin route works with timing);
-- which lamps have a tower guard (the 11 that EN marks with platinum coins; the lamps 33909,31270,
-- 33900,31278 and 33909,31290 stay lit and harmless); lamp timings; a patrol step a second; the messages.
-- Switch: Family.piratesTail.

local PT = FamilyPiratesTail
if not PT then
	return
end
local S = Storage.Quest.U12_60.APiratesTail

local C = {}
PT.stealth = C

C.LEVER = Position(33894, 31311, 15)
C.SQUARES = { Position(33895, 31311, 15), Position(33896, 31311, 15), Position(33897, 31311, 15) }
C.START = Position(33893, 31279, 15)
C.OUT = Position(33857, 31334, 9) -- next to the Spy Rat, where the map's exit teleports lead
C.CHEST = Position(33903, 31248, 15)
C.MAZE = { x1 = 33891, y1 = 31269, x2 = 33922, y2 = 31299, z1 = 14, z2 = 15 }
C.LAB = { x1 = 33895, y1 = 31247, x2 = 33910, y2 = 31258, z1 = 15, z2 = 15 }
C.TIME = 5 * 60
C.TRUST = 200
C.COOLDOWN = 20 * 60 * 60
C.ICON = "family-stealth"
C.RAT = 21
C.PATROL_STEP = 1000
C.PATROL_SPEED = 120 -- shown while walking (the base speed stays 0)

-- x, y, ground, blocking object (0 = a walkable square)
C.FLOOR14 = {
	{ 33909, 31270, 4567, 0 }, { 33897, 31273, 4560, 0 }, { 33898, 31273, 4560, 0 }, { 33920, 31273, 4568, 0 },
	{ 33921, 31273, 4560, 389 }, { 33897, 31274, 4561, 0 }, { 33898, 31274, 4567, 0 }, { 33895, 31275, 4563, 0 },
	{ 33896, 31275, 4563, 0 }, { 33897, 31275, 4562, 0 }, { 33898, 31275, 4561, 0 }, { 33895, 31276, 4564, 0 },
	{ 33896, 31276, 4564, 0 }, { 33897, 31276, 4562, 0 }, { 33898, 31276, 4562, 0 }, { 33899, 31276, 4561, 0 },
	{ 33900, 31276, 4561, 0 }, { 33901, 31276, 4567, 0 }, { 33897, 31277, 4561, 0 }, { 33898, 31277, 4560, 0 },
	{ 33899, 31277, 4559, 0 }, { 33900, 31277, 4565, 0 }, { 33901, 31277, 4562, 0 }, { 33905, 31277, 4568, 0 },
	{ 33897, 31278, 4560, 0 }, { 33898, 31278, 4563, 0 }, { 33899, 31278, 4563, 0 }, { 33900, 31278, 4564, 0 },
	{ 33901, 31278, 4562, 393 }, { 33903, 31282, 4565, 1884 }, { 33904, 31282, 4562, 1885 }, { 33905, 31282, 4562, 1852 },
	{ 33906, 31282, 4561, 388 }, { 33907, 31282, 4568, 393 }, { 33908, 31282, 4561, 5622 }, { 33909, 31282, 4562, 1876 },
	{ 33910, 31282, 4561, 389 }, { 33911, 31282, 4563, 1853 }, { 33920, 31282, 4568, 0 }, { 33903, 31283, 4567, 1886 },
	{ 33904, 31283, 4560, 1887 }, { 33905, 31283, 4561, 1847 }, { 33906, 31283, 4561, 1848 }, { 33907, 31283, 4562, 1851 },
	{ 33908, 31283, 4561, 5621 }, { 33909, 31283, 4564, 1872 }, { 33910, 31283, 4562, 1873 }, { 33911, 31283, 4567, 1791 },
	{ 33895, 31284, 4563, 0 }, { 33903, 31284, 4560, 392 }, { 33904, 31284, 4564, 393 }, { 33905, 31284, 4564, 1849 },
	{ 33906, 31284, 4559, 1850 }, { 33907, 31284, 4562, 1840 }, { 33908, 31284, 4564, 1878 }, { 33909, 31284, 4564, 1874 },
	{ 33910, 31284, 4564, 1891 }, { 33911, 31284, 4567, 393 }, { 33903, 31285, 4561, 1901 }, { 33904, 31285, 4563, 1902 },
	{ 33905, 31285, 4568, 1909 }, { 33906, 31285, 4561, 1888 }, { 33907, 31285, 4567, 1889 }, { 33908, 31285, 4565, 1861 },
	{ 33909, 31285, 4562, 1862 }, { 33910, 31285, 4561, 392 }, { 33911, 31285, 4561, 1910 }, { 33903, 31286, 4563, 393 },
	{ 33904, 31286, 4562, 389 }, { 33905, 31286, 4561, 393 }, { 33906, 31286, 4567, 1890 }, { 33907, 31286, 4561, 1891 },
	{ 33908, 31286, 4563, 1863 }, { 33909, 31286, 4565, 1864 }, { 33910, 31286, 4560, 1859 }, { 33911, 31286, 4560, 388 },
	{ 33921, 31287, 4568, 0 }, { 33904, 31290, 4567, 0 }, { 33905, 31290, 4563, 0 }, { 33906, 31290, 4561, 393 },
	{ 33907, 31290, 4561, 0 }, { 33908, 31290, 4561, 0 }, { 33909, 31290, 4561, 0 }, { 33900, 31291, 4562, 0 },
	{ 33904, 31291, 4561, 0 }, { 33905, 31291, 4562, 0 }, { 33906, 31291, 4568, 0 }, { 33907, 31291, 4561, 0 },
	{ 33908, 31291, 4561, 0 }, { 33909, 31291, 4561, 0 }, { 33904, 31292, 4560, 0 }, { 33905, 31292, 4559, 0 },
	{ 33906, 31292, 4559, 0 }, { 33907, 31292, 4561, 0 }, { 33921, 31292, 4568, 0 }, { 33906, 31293, 4559, 0 },
	{ 33907, 31293, 4561, 0 }, { 33914, 31293, 4566, 0 }, { 33906, 31294, 4567, 0 }, { 33907, 31294, 4561, 0 },
	{ 33918, 31294, 4568, 0 }, { 33900, 31295, 4563, 0 }, { 33918, 31297, 4568, 0 }, { 33918, 31298, 4562, 1912 },
}

-- Pirat Guards on floor 15 (EN Stealth Map)
C.GUARDS = {
	{ 33916, 31270 }, { 33898, 31271 }, { 33906, 31273 }, { 33893, 31274 }, { 33899, 31274 }, { 33914, 31274 }, { 33917, 31274 },
	{ 33910, 31276 }, { 33908, 31277 }, { 33898, 31279 }, { 33912, 31281 }, { 33892, 31283 }, { 33912, 31283 }, { 33916, 31285 },
	{ 33895, 31287 }, { 33914, 31287 }, { 33898, 31288 }, { 33906, 31288 }, { 33918, 31289 }, { 33892, 31290 }, { 33896, 31292 },
	{ 33909, 31294 }, { 33892, 31295 }, { 33905, 31295 }, { 33903, 31297 },
}

-- Towers: the lamp on floor 15, its tower guard on top (same x, y on floor 14)
C.TOWERS = {
	{ 33920, 31273 }, { 33905, 31277 }, { 33920, 31282 }, { 33895, 31284 }, { 33921, 31287 }, { 33900, 31291 },
	{ 33921, 31292 }, { 33914, 31293 }, { 33918, 31294 }, { 33900, 31295 }, { 33918, 31297 },
}
C.PLAIN_LAMPS = { { 33909, 31270 }, { 33900, 31278 }, { 33909, 31290 } }

-- Pirat Patrols: back and forth along the path (EN snapshot square in the middle of each)
C.PATROLS = {
	{ z = 14, from = { 33898, 31273 }, to = { 33898, 31275 } }, -- on the north-west platform
	{ z = 15, from = { 33902, 31270 }, to = { 33902, 31275 } },
	{ z = 15, from = { 33908, 31271 }, to = { 33914, 31271 } },
	{ z = 15, from = { 33913, 31279 }, to = { 33918, 31279 } },
}

-- Glowing bug lamps: off, lit, blinking (two looks each; the map uses both blinking ids)
C.LAMP_LOOKS = {
	{ off = 35018, lit = 35019, blink = 35020, ids = { [35018] = true, [35019] = true, [35020] = true, [35024] = true } },
	{ off = 35021, lit = 35022, blink = 35023, ids = { [35021] = true, [35022] = true, [35023] = true, [35025] = true } },
}
-- seconds (ours): lit, blinking before going dark (still seen), dark, blinking before lighting (not seen)
C.LIT, C.FADING, C.DARK, C.WAKING = { 8, 12 }, 2, { 6, 8 }, 2

C.runs = {} -- [player id] = os.time() when the disguise runs out
C.guards = {} -- creature ids
C.patrols = {} -- { id, path = { positions }, k, dir, z }
C.lamps = {} -- { pos, look, state, untilMs, tower = true/false }

local function enabled()
	return PT.enabled()
end

local function inside(box, pos)
	return pos.z >= box.z1 and pos.z <= box.z2 and pos.x >= box.x1 and pos.x <= box.x2 and pos.y >= box.y1 and pos.y <= box.y2
end
function C.inMission(pos)
	return inside(C.MAZE, pos) or inside(C.LAB, pos)
end

-- Floor 14 --------------------------------------------------------------------------------------------

function C.buildFloor14()
	local made = 0
	for _, s in ipairs(C.FLOOR14) do
		local pos = Position(s[1], s[2], 14)
		local tile = Tile(pos)
		if not tile then
			tile = Game.createTile(pos)
		end
		if tile and not tile:getGround() then
			Game.createItem(s[3], 1, pos)
			if s[4] ~= 0 then
				Game.createItem(s[4], 1, pos)
			end
			made = made + 1
		end
	end
	return made
end

-- Creatures -------------------------------------------------------------------------------------------

local function line(from, to)
	local path = {}
	local dx = to[1] > from[1] and 1 or (to[1] < from[1] and -1 or 0)
	local dy = to[2] > from[2] and 1 or (to[2] < from[2] and -1 or 0)
	local x, y = from[1], from[2]
	while true do
		path[#path + 1] = { x, y }
		if x == to[1] and y == to[2] then
			break
		end
		x, y = x + dx, y + dy
	end
	return path
end

local function spawn(name, pos)
	local monster = Game.createMonster(name, pos, false, true)
	if monster then
		monster:setDirection(DIRECTION_SOUTH)
	end
	return monster
end

function C.spawnAll()
	for _, id in ipairs(C.guards) do
		local c = Creature(id)
		if c then
			c:remove()
		end
	end
	for _, p in ipairs(C.patrols) do
		local c = Creature(p.id)
		if c then
			c:remove()
		end
	end
	C.guards, C.patrols = {}, {}
	for _, g in ipairs(C.GUARDS) do
		local m = spawn("Pirat Guard", Position(g[1], g[2], 15))
		if m then
			C.guards[#C.guards + 1] = m:getId()
		end
	end
	for _, t in ipairs(C.TOWERS) do
		local m = spawn("Pirat Guard", Position(t[1], t[2], 14))
		if m then
			C.guards[#C.guards + 1] = m:getId()
		end
	end
	for _, def in ipairs(C.PATROLS) do
		local path = line(def.from, def.to)
		local k = math.floor((#path + 1) / 2)
		local m = spawn("Pirat Patrol", Position(path[k][1], path[k][2], def.z))
		if m then
			m:changeSpeed(C.PATROL_SPEED)
			C.patrols[#C.patrols + 1] = { id = m:getId(), path = path, k = k, dir = 1, z = def.z }
		end
	end
	return #C.guards, #C.patrols
end

local DIRS = {
	[0] = { [-1] = DIRECTION_NORTH, [1] = DIRECTION_SOUTH },
	[-1] = { [0] = DIRECTION_WEST },
	[1] = { [0] = DIRECTION_EAST },
}

function C.stepPatrols()
	for _, p in ipairs(C.patrols) do
		local m = Creature(p.id)
		if m then
			local nk = p.k + p.dir
			if nk < 1 or nk > #p.path then
				p.dir = -p.dir
				nk = p.k + p.dir
			end
			local to = Position(p.path[nk][1], p.path[nk][2], p.z)
			local tile = Tile(to)
			-- the creature move ignores the base speed of 0 (a move in a direction would not)
			if tile and m:move(tile, 0) == RETURNVALUE_NOERROR then
				p.k = nk
				local d = DIRS[p.path[nk][1] - p.path[p.k - p.dir][1]]
				d = d and d[p.path[nk][2] - p.path[p.k - p.dir][2]]
				if d then
					m:setDirection(d)
				end
			end
		end
	end
end

-- Lamps -----------------------------------------------------------------------------------------------

local function lampItem(pos)
	local tile = Tile(pos)
	if not tile then
		return nil
	end
	for _, look in ipairs(C.LAMP_LOOKS) do
		for id in pairs(look.ids) do
			local item = tile:getItemById(id)
			if item then
				return item, look
			end
		end
	end
	return nil
end

local function setLook(lamp, key)
	local item = lampItem(lamp.pos)
	local id = lamp.look[key]
	if item and item:getId() ~= id then
		item:transform(id)
	end
end

local function rand(r)
	return type(r) == "table" and math.random(r[1], r[2]) or r
end

function C.setupLamps(now)
	now = now or systemTime()
	C.lamps = {}
	for _, list in ipairs({ { C.TOWERS, true }, { C.PLAIN_LAMPS, false } }) do
		for _, l in ipairs(list[1]) do
			local pos = Position(l[1], l[2], 15)
			local item, look = lampItem(pos)
			if item then
				local lamp = { pos = pos, look = look, state = "lit", untilMs = now + math.random(0, 10000), tower = list[2] }
				C.lamps[#C.lamps + 1] = lamp
				setLook(lamp, "lit")
			end
		end
	end
	return #C.lamps
end

local NEXT = { lit = "fading", fading = "dark", dark = "waking", waking = "lit" }
local LOOK = { lit = "lit", fading = "blink", dark = "off", waking = "blink" }
local LENGTH = { lit = "LIT", fading = "FADING", dark = "DARK", waking = "WAKING" }

function C.tickLamps(now)
	now = now or systemTime()
	for _, lamp in ipairs(C.lamps) do
		if lamp.tower then
			while now >= lamp.untilMs do
				lamp.state = NEXT[lamp.state]
				lamp.untilMs = lamp.untilMs + rand(C[LENGTH[lamp.state]]) * 1000
				if lamp.untilMs < now then
					lamp.untilMs = now + rand(C[LENGTH[lamp.state]]) * 1000
				end
				setLook(lamp, LOOK[lamp.state])
			end
		end
	end
end

-- a lit lamp (or one blinking before it goes dark) shows its tower guard the squares around it
function C.lampSees(lamp, pos)
	return lamp.tower and (lamp.state == "lit" or lamp.state == "fading") and pos.z == 15 and math.max(math.abs(pos.x - lamp.pos.x), math.abs(pos.y - lamp.pos.y)) <= 1
end

-- Players ---------------------------------------------------------------------------------------------

local function near(a, b)
	return a.z == b.z and math.max(math.abs(a.x - b.x), math.abs(a.y - b.y)) <= 1
end

-- what sees a player standing at pos: "guard", "patrol", "tower" or nil
function C.seenBy(pos)
	for _, id in ipairs(C.guards) do
		local g = Creature(id)
		if g and near(g:getPosition(), pos) then
			return "guard"
		end
	end
	for _, p in ipairs(C.patrols) do
		local g = Creature(p.id)
		if g and near(g:getPosition(), pos) then
			return "patrol"
		end
	end
	for _, lamp in ipairs(C.lamps) do
		if C.lampSees(lamp, pos) then
			return "tower"
		end
	end
	return nil
end

local function showTime(player, left)
	player:setIcon(C.ICON, CreatureIconCategory_Quests, CreatureIconQuests_ExclamationMark, math.max(0, left))
end

local function undisguise(player)
	player:removeIcon(C.ICON)
	player:removeCondition(CONDITION_OUTFIT)
end

-- reason: "success", "caught", "time", "left" (logged out or left the area)
function C.finish(player, reason)
	local id = player:getId()
	if not C.runs[id] then
		return
	end
	C.runs[id] = nil
	undisguise(player)
	if reason == "success" then
		PT.addTrust(player, C.TRUST)
		player:setStorageValue(S.StealthTime, os.time() + C.COOLDOWN)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You take a sample of the newest mouldy powder and spoil the rest. Tik'hi Tak'he will hear of it: %d trust points.", C.TRUST)) -- ours
		return
	end
	if reason == "caught" then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A pirat noticed you. You are thrown out of the laboratory!") -- ours
	elseif reason == "time" then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The magic of the rat disguise has run out. You are thrown out of the laboratory!") -- ours
	end
	if reason ~= "left" and C.inMission(player:getPosition()) then
		player:teleportTo(C.OUT)
		C.OUT:sendMagicEffect(CONST_ME_TELEPORT)
	end
end

function C.eligible(player)
	return PT.rascacoon(player) >= 1 and player:getStorageValue(S.StealthTime) <= os.time()
end

function C.busy()
	for id in pairs(C.runs) do
		local p = Player(id)
		if p and C.inMission(p:getPosition()) then
			return true
		end
		C.runs[id] = nil
	end
	return false
end

function C.start(players, now)
	now = now or os.time()
	for _, player in ipairs(players) do
		C.runs[player:getId()] = now + C.TIME
		player:teleportTo(C.START)
		local disguise = Condition(CONDITION_OUTFIT)
		disguise:setOutfit({ lookType = C.RAT })
		disguise:setTicks((C.TIME + 5) * 1000)
		player:addCondition(disguise)
		showTime(player, C.TIME)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are disguised as a rat. Sneak through to the laboratory and find the mouldy powder before the magic runs out!") -- ours
	end
	C.START:sendMagicEffect(CONST_ME_TELEPORT)
end

function C.tick(now)
	now = now or os.time()
	for id, ends in pairs(C.runs) do
		local player = Player(id)
		if not player then
			C.runs[id] = nil
		elseif not C.inMission(player:getPosition()) then
			C.finish(player, "left")
		elseif now >= ends then
			C.finish(player, "time")
		else
			showTime(player, ends - now)
			if inside(C.MAZE, player:getPosition()) and C.seenBy(player:getPosition()) then
				C.finish(player, "caught")
			end
		end
	end
end

-- The lever ---------------------------------------------------------------------------------------------

local function useLever(player, item, fromPosition, target, toPosition, isHotkey)
	if not enabled() then
		return false
	end
	if C.busy() then
		player:sendCancelMessage("Someone is already sneaking through the laboratory.") -- ours
		return true
	end
	local players, onSquares = {}, false
	for _, pos in ipairs(C.SQUARES) do
		local tile = Tile(pos)
		local creature = tile and tile:getTopCreature()
		local p = creature and creature:getPlayer()
		if p then
			if p:getId() == player:getId() then
				onSquares = true
			end
			if not C.eligible(p) then
				player:sendCancelMessage(PT.rascacoon(p) < 1 and (p:getName() .. " has not offered Tik'hi Tak'he any help yet.") or (p:getName() .. " has to wait before sneaking into the laboratory again.")) -- ours
				return true
			end
			players[#players + 1] = p
		end
	end
	if not onSquares then
		player:sendCancelMessage("Stand on one of the squares in front of the lever.") -- ours
		return true
	end
	item:transform(item:getId() == 8911 and 8912 or 8911)
	C.start(players)
	return true
end
C.useLever = useLever

-- The chest with the mouldy powder.
local function useChest(player, item, fromPosition, target, toPosition, isHotkey)
	if not enabled() or not C.runs[player:getId()] then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.") -- ours
		return true
	end
	C.finish(player, "success")
	C.CHEST:sendMagicEffect(CONST_ME_POFF)
	return true
end
C.useChest = useChest

local lever = Action()
lever.onUse = useLever
lever:position(C.LEVER)
lever:register()

local chest = Action()
chest.onUse = useChest
chest:position(C.CHEST)
chest:register()

-- Clocks ----------------------------------------------------------------------------------------------

local quick = GlobalEvent("FamilyStealthWatch")
function quick.onThink(interval)
	if enabled() and next(C.runs) then
		C.tickLamps()
		C.tick()
	end
	return true
end
quick:interval(250)
quick:register()

local walk = GlobalEvent("FamilyStealthPatrols")
function walk.onThink(interval)
	if enabled() then
		C.stepPatrols()
	end
	return true
end
walk:interval(C.PATROL_STEP)
walk:register()

-- Logging in inside without a running disguise (server restart, logout): out to the Spy Rat.
local login = CreatureEvent("FamilyStealthLogin")
function login.onLogin(player)
	if enabled() and not C.runs[player:getId()] and C.inMission(player:getPosition()) then
		undisguise(player)
		player:teleportTo(C.OUT)
	end
	return true
end
login:register()

local startup = GlobalEvent("FamilyStealthMission")
function startup.onStartup()
	if not enabled() then
		return true
	end
	local made = C.buildFloor14()
	local guards, patrols = C.spawnAll()
	local lamps = C.setupLamps()
	logger.info(string.format("[Family] Rascacoon stealth mission: floor 14 %d squares, %d pirat guards, %d patrols, %d lamps", made, guards, patrols, lamps))
	return true
end
startup:register()
