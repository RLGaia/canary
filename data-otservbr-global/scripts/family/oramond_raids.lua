-- Gaia Family server: Oramond factory raids (2026-11-09)
-- The raid voted at Marvin (topic "raid", lib/others/family_rathleton.lua) comes every hour on the
-- second floor of the Underground Glooth Factory (z13), on top of the normal spawns there
-- (Rodrigo kept them as hunting places). Sources: TibiaWiki BR "Invasões em Oramond" (raid areas,
-- creatures, no announcement), EN "Oramond Factory Raids" (every hour from server save, waves for
-- 45 minutes, the creatures disappear some time afterwards, bosses stay until killed) and the
-- creature pages (mechanics). Ours where the wikis are silent: a wave every 5 minutes of 8
-- creatures, the leftovers removed 10 minutes after the last wave, the number of totems,
-- batteries, towers and tunnels, the bosses' paths on our map, 1% silver raid token.
--
--   * Minotaurs (east, BR 33587,31951,13): minotaur waves, Glooth Powered Minotaurs (95%
--     resistant, upstream file) become Depowered Minotaurs on a glooth extractor (EN), Minotaur
--     Totems heal every creature within 3 squares for 500-1000 every 2 seconds (EN), and the
--     Moohtant Wallbreaker (new monster file) moves one square west every 10 seconds (EN), pushing
--     players, until the plant wall (33571,31951), where it explodes for 1000 damage around it.
--   * Mechanical creatures (south, BR 33553,31979,13): golem waves, Glooth Batteries and Control
--     Towers (stationary), and the Glooth Bomb, which goes north leaving fire fields and pushing
--     players 2 squares (EN) until the northern plant wall (33548,31969), where it explodes.
--   * Wild life (west, BR 33527,31951,13): waves with many glooth anemones, Unstable Tunnels (new
--     monster file, summon drillworms and anemones) and the Tremor Worm, which vanishes and
--     reappears every 10 seconds at one of its four spots (EN).
-- Switch: Family.oramondRaids (false = no raids; the vote still shows at Marvin).

Family = Family or {}
Family.oramondRaids = true

FamilyOramondRaids = FamilyOramondRaids or {}
local OR = FamilyOramondRaids

OR.Z = 13
OR.WAVE_EVERY = 5 * 60
OR.WAVE_SIZE = 8
OR.RAID_TIME = 45 * 60
OR.CLEANUP_AFTER = 55 * 60
OR.STEP_EVERY = 10 -- seconds per square of the Wallbreaker and the Bomb, and per Tremor Worm jump (EN)
OR.EXPLOSION = 1000
OR.TOKEN, OR.TOKEN_CHANCE = 19083, 1
OR.EXTRACTOR = 21817

OR.raids = {
	["minotaurs"] = {
		center = Position(33587, 31951, 13),
		box = { 33569, 31925, 33690, 31975 },
		creatures = { "Minotaur Invader", "Worm Priestess", "Minotaur Hunter", "Mooh'Tah Warrior", "Minotaur Amazon", "Execowtioner", "Moohtant" },
		atStart = { ["Minotaur Totem"] = 2 },
		perWave = { ["Minotaur Totem"] = 1, ["Glooth Powered Minotaur"] = 1 },
		boss = "Moohtant Wallbreaker",
		march = { from = Position(33662, 31951, 13), goal = Position(33571, 31951, 13), push = 1 },
	},
	["mechanical creatures"] = {
		center = Position(33553, 31979, 13),
		box = { 33530, 31968, 33590, 32106 },
		creatures = { "Worker Golem", "Glooth Golem", "Rustheap Golem", "Metal Gargoyle", "War Golem", "Walker", "High Voltage Elemental" },
		atStart = { ["Glooth Battery"] = 4, ["Control Tower"] = 3 },
		perWave = {},
		boss = "Glooth Bomb",
		march = { from = Position(33558, 32100, 13), goal = Position(33548, 31969, 13), push = 2, fire = 2118 },
	},
	["wild life"] = {
		center = Position(33527, 31951, 13),
		box = { 33395, 31915, 33539, 31995 },
		creatures = { "Glooth Anemone", "Glooth Anemone", "Glooth Anemone", "Behemoth", "Blood Beast", "Devourer", "Drillworm", "Elder Wyrm", "Wyrm" },
		atStart = { ["Unstable Tunnel"] = 3 },
		perWave = {},
		boss = "Tremor Worm",
		jumps = { -- EN Mapper Coords
			Position(33518, 31963, 13),
			Position(33510, 31944, 13),
			Position(33470, 31952, 13),
			Position(33419, 31949, 13),
		},
	},
}

local function enabled()
	return Family.oramondRaids
end

-- The raid voted for this period.
function OR.votedRaid()
	local key = FamilyRathleton and FamilyRathleton.on() and FamilyRathleton.result("raid") or "minotaurs"
	if not OR.raids[key] then
		key = "minotaurs"
	end
	return key
end

local function walkable(pos)
	local tile = Tile(pos)
	if not tile or not tile:getGround() then
		return false
	end
	if tile:hasFlag(TILESTATE_BLOCKSOLID) or tile:hasFlag(TILESTATE_FLOORCHANGE) or tile:hasFlag(TILESTATE_PROTECTIONZONE) then
		return false
	end
	return tile:getItemByType(ITEM_TYPE_TELEPORT) == nil
end
OR.walkable = walkable

local function key(x, y)
	return x * 100000 + y
end

-- The squares of a raid area: everything walkable reached from its centre inside its box.
function OR.squares(raidKey)
	local raid = OR.raids[raidKey]
	if raid.squares then
		return raid.squares
	end
	local b, list, seen = raid.box, {}, {}
	local stack = { { raid.center.x, raid.center.y } }
	seen[key(raid.center.x, raid.center.y)] = true
	while #stack > 0 do
		local p = table.remove(stack)
		list[#list + 1] = Position(p[1], p[2], OR.Z)
		for dx = -1, 1 do
			for dy = -1, 1 do
				local x, y = p[1] + dx, p[2] + dy
				if x >= b[1] and x <= b[3] and y >= b[2] and y <= b[4] and not seen[key(x, y)] and walkable(Position(x, y, OR.Z)) then
					seen[key(x, y)] = true
					stack[#stack + 1] = { x, y }
				end
			end
		end
	end
	raid.squares, raid.inArea = list, seen
	return list
end

-- Distance (in steps) of every square of the area to the march goal.
function OR.distances(raidKey)
	local raid = OR.raids[raidKey]
	if raid.dist then
		return raid.dist
	end
	OR.squares(raidKey)
	local goal = raid.march.goal
	local dist = { [key(goal.x, goal.y)] = 0 }
	local queue, head = { { goal.x, goal.y } }, 1
	while queue[head] do
		local p = queue[head]
		head = head + 1
		local d = dist[key(p[1], p[2])]
		for dx = -1, 1 do
			for dy = -1, 1 do
				local x, y = p[1] + dx, p[2] + dy
				local k = key(x, y)
				if raid.inArea[k] and not dist[k] then
					dist[k] = d + 1
					queue[#queue + 1] = { x, y }
				end
			end
		end
	end
	raid.dist = dist
	return dist
end

local function freeSquare(raidKey)
	local squares = OR.squares(raidKey)
	for _ = 1, 20 do
		local pos = squares[math.random(#squares)]
		local tile = Tile(pos)
		if tile and not tile:getTopCreature() then
			return pos
		end
	end
	return nil
end

-- Creatures of the running raid (removed after it, bosses excepted).
OR.spawned = {}
OR.bosses = {}
OR.state = nil -- { key, started, waves }

local function spawn(raidKey, name, pos)
	pos = pos or freeSquare(raidKey)
	if not pos then
		return nil
	end
	local monster = Game.createMonster(name, pos, false, true)
	if monster then
		monster:registerEvent("FamilyOramondRaidDeath")
		OR.spawned[#OR.spawned + 1] = monster:getId()
	end
	return monster
end

local function spawnCounts(raidKey, counts)
	for name, count in pairs(counts) do
		for _ = 1, count do
			spawn(raidKey, name)
		end
	end
end

function OR.wave(raidKey)
	local raid = OR.raids[raidKey]
	for _ = 1, OR.WAVE_SIZE do
		spawn(raidKey, raid.creatures[math.random(#raid.creatures)])
	end
	spawnCounts(raidKey, raid.perWave)
end

local function bossAlive(name)
	local id = OR.bosses[name]
	return id and Monster(id) ~= nil
end

-- ------------------------------------------------------------------ marching bosses

local function pushPlayers(pos, dx, dy, distance)
	local tile = Tile(pos)
	local creatures = tile and tile:getCreatures() or {}
	for _, creature in ipairs(creatures) do
		if creature:isPlayer() then
			local to
			for d = distance, 1, -1 do
				local candidate = Position(pos.x + dx * d, pos.y + dy * d, pos.z)
				if walkable(candidate) then
					to = candidate
					break
				end
			end
			if not to then
				for ddx = -1, 1 do
					for ddy = -1, 1 do
						local candidate = Position(pos.x + ddx, pos.y + ddy, pos.z)
						if not to and (ddx ~= 0 or ddy ~= 0) and walkable(candidate) then
							to = candidate
						end
					end
				end
			end
			if to then
				creature:teleportTo(to, true)
			end
		end
	end
end

local function explode(monster, raid)
	local pos = monster:getPosition()
	for dx = -3, 3 do
		for dy = -3, 3 do
			local at = Position(pos.x + dx, pos.y + dy, pos.z)
			at:sendMagicEffect(CONST_ME_EXPLOSIONHIT)
			local tile = Tile(at)
			for _, creature in ipairs(tile and tile:getCreatures() or {}) do
				if creature:isPlayer() then
					doTargetCombatHealth(0, creature, COMBAT_PHYSICALDAMAGE, -OR.EXPLOSION, -OR.EXPLOSION, CONST_ME_EXPLOSIONAREA)
				end
			end
		end
	end
	monster:say("BOOOOOM!", TALKTYPE_MONSTER_YELL) -- ours
	monster:remove()
end

-- One step of a marching boss towards the plant wall; false when it is gone.
function OR.march(raidKey, id)
	local raid = OR.raids[raidKey]
	local monster = Monster(id)
	if not monster then
		return false
	end
	local dist = OR.distances(raidKey)
	local pos = monster:getPosition()
	local here = dist[key(pos.x, pos.y)]
	if here and here <= 1 then
		explode(monster, raid)
		return false
	end
	local best, bestD
	for dx = -1, 1 do
		for dy = -1, 1 do
			local d = dist[key(pos.x + dx, pos.y + dy)]
			-- straight moves first, like walking west/north
			if d and (not bestD or d < bestD or (d == bestD and (dx == 0 or dy == 0))) then
				best, bestD = { dx, dy }, d
			end
		end
	end
	if not best then
		return true
	end
	local to = Position(pos.x + best[1], pos.y + best[2], pos.z)
	pushPlayers(to, best[1], best[2], raid.march.push)
	if raid.march.fire then
		Game.createItem(raid.march.fire, 1, pos)
	end
	monster:teleportTo(to, true)
	return true
end

local function marchLoop(raidKey, id)
	if OR.march(raidKey, id) then
		addEvent(marchLoop, OR.STEP_EVERY * 1000, raidKey, id)
	end
end

-- The Tremor Worm vanishes and comes back at one of its spots.
function OR.jump(raidKey, id)
	local monster = Monster(id)
	if not monster then
		return false
	end
	local raid = OR.raids[raidKey]
	local to = raid.jumps[math.random(#raid.jumps)]
	monster:getPosition():sendMagicEffect(CONST_ME_POFF)
	monster:teleportTo(to)
	to:sendMagicEffect(CONST_ME_GROUNDSHAKER)
	return true
end

local function jumpLoop(raidKey, id)
	if OR.jump(raidKey, id) then
		addEvent(jumpLoop, OR.STEP_EVERY * 1000, raidKey, id)
	end
end

function OR.spawnBoss(raidKey)
	local raid = OR.raids[raidKey]
	if bossAlive(raid.boss) then
		return nil
	end
	local pos = raid.march and raid.march.from or raid.jumps[1]
	local monster = Game.createMonster(raid.boss, pos, false, true)
	if not monster then
		return nil
	end
	OR.bosses[raid.boss] = monster:getId()
	monster:registerEvent("FamilyOramondRaidDeath")
	if raid.march then
		monster:changeSpeed(-monster:getSpeed()) -- the script moves it
		addEvent(marchLoop, OR.STEP_EVERY * 1000, raidKey, monster:getId())
	elseif raid.jumps then
		addEvent(jumpLoop, OR.STEP_EVERY * 1000, raidKey, monster:getId())
	end
	return monster
end

-- ------------------------------------------------------------------ totems

local function totemLoop()
	local any = false
	for _, id in ipairs(OR.spawned) do
		local totem = Monster(id)
		if totem and totem:getName() == "Minotaur Totem" then
			any = true
			local pos = totem:getPosition()
			local around = Game.getSpectators(pos, false, false, 3, 3, 3, 3)
			for _, creature in ipairs(around) do
				if creature:isMonster() and creature:getId() ~= id and creature:getHealth() < creature:getMaxHealth() then
					creature:addHealth(math.random(500, 1000))
					creature:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
				end
			end
		end
	end
	if any then
		addEvent(totemLoop, 2000)
	else
		OR.totemsRunning = false
	end
end

local function startTotems()
	if not OR.totemsRunning then
		OR.totemsRunning = true
		addEvent(totemLoop, 2000)
	end
end

-- ------------------------------------------------------------------ the hourly raid

function OR.start(raidKey, now)
	local raid = OR.raids[raidKey]
	OR.cleanup()
	OR.state = { key = raidKey, started = now or os.time(), waves = 1 }
	spawnCounts(raidKey, raid.atStart)
	OR.spawnBoss(raidKey)
	OR.wave(raidKey)
	startTotems()
	logger.info("[Family] Oramond raid: {}", raidKey)
end

function OR.cleanup()
	for _, id in ipairs(OR.spawned) do
		local monster = Monster(id)
		if monster then
			monster:remove()
		end
	end
	OR.spawned = {}
	OR.state = nil
end

function OR.tick(now)
	now = now or os.time()
	local t = os.date("*t", now)
	local hour = os.date("%Y%m%d%H", now)
	if t.min == 0 and OR.lastHour ~= hour then
		OR.lastHour = hour
		OR.start(OR.votedRaid(), now)
		return
	end
	local state = OR.state
	if not state then
		return
	end
	local elapsed = now - state.started
	if elapsed >= OR.CLEANUP_AFTER then
		OR.cleanup()
	elseif elapsed < OR.RAID_TIME and elapsed >= state.waves * OR.WAVE_EVERY then
		state.waves = state.waves + 1
		OR.wave(state.key)
		startTotems()
	end
end

local raidClock = GlobalEvent("FamilyOramondRaids")
function raidClock.onThink(interval)
	if enabled() then
		OR.tick()
	end
	return true
end
raidClock:interval(20 * 1000)
raidClock:register()

-- Silver raid tokens (BR: "durante invasões") from the raid's creatures.
local raidDeath = CreatureEvent("FamilyOramondRaidDeath")
function raidDeath.onDeath(creature, corpse)
	if corpse and corpse.isContainer and corpse:isContainer() and math.random(100) <= OR.TOKEN_CHANCE then
		corpse:addItem(OR.TOKEN, 1)
	end
	return true
end
raidDeath:register()

-- A Glooth Powered Minotaur on a glooth extractor loses its power (EN).
function OR.depower(id)
	local powered = Monster(id)
	if not powered then
		return nil
	end
	local pos = powered:getPosition()
	powered:remove()
	pos:sendMagicEffect(CONST_ME_ENERGYHIT)
	local weak = Game.createMonster("Depowered Minotaur", pos, false, true)
	if weak then
		weak:say("I want my power back!", TALKTYPE_MONSTER_SAY)
	end
	return weak
end

local extractor = MoveEvent()
function extractor.onStepIn(creature, item, position, fromPosition)
	if not enabled() or not creature:isMonster() or creature:getName() ~= "Glooth Powered Minotaur" then
		return true
	end
	local id = creature:getId()
	addEvent(OR.depower, 0, id) -- not while it is still stepping
	return true
end
extractor:type("stepin")
extractor:id(OR.EXTRACTOR)
extractor:register()
