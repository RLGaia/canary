-- Gaia Family server: the Tentugly's Head fight (A Pirate's Tail Quest, part 3a, 2026-11-11). Ours, not
-- upstream: Canary v3.6.1 only spawned the head. Sources: TibiaWiki BR quest page (from Rodrigo), TibiaWiki EN
-- quest spoiler and the Tentugly's Head, Tentacle and Servant of Tentugly pages.
--
-- The lever (upstream, actions_tentuglys_head.lua, level 250, 5 players) calls T.start: Tentugly's Head in
-- the middle of the ship (33722,31182,7) with Servants of Tentugly around the boat (BR/EN). When the head is
-- hurt enough it sinks (EN "temporarily retreats", BR "after a certain moment") and tentacles grab the ship
-- on both floors (BR/EN); each tentacle has a life for every square it sticks out, and each kill makes it
-- retreat one square (EN/BR). Anyone standing where a tentacle comes out is sent to the temple: "You had
-- to leave the area because of strange events." (EN). With every tentacle gone the head comes back and must
-- be killed (EN/BR): Release the Kraken, the Krakoloss mount, the cheesy key on the first victory (BR) and
-- The Wreckoning: everyone is taken there after a while, or through the teleport on the left of the ship
-- (BR). 8 minutes for the fight (EN; lever file). The ship's teleport (33706,31183,7) leads to The Wreckoning
-- for those who defeated Tentugly and back to Rascacoon for the others.
--
-- Ours (no source gives them): the head sinks at half health and comes back with what it had left; a
-- tentacle sticks out up to 3 squares (from the 14 places where the map shows tentacles grabbing the ship:
-- 9 below, 5 on the upper deck); 4 servants at the start and one more every 30 s up to 6; 60 s before the
-- trip to The Wreckoning; the messages.
-- Switch: Family.piratesTail.

local PT = FamilyPiratesTail
if not PT then
	return
end
local S = Storage.Quest.U12_60.APiratesTail

local T = {}
PT.tentugly = T

T.HEAD = "Tentugly's Head"
T.HEAD_POS = Position(33722, 31182, 7)
T.CENTER = { x = 33722, y = 31183 }
T.ZONE = { x1 = 33705, y1 = 31176, x2 = 33736, y2 = 31190, z1 = 6, z2 = 7 }
T.WRECKONING = Position(33839, 31222, 5) -- where Captain Jack Rat's safe route ends
T.RASCACOON = Position(33799, 31356, 7)
T.SHIP_TELEPORT = Position(33706, 31183, 7)
T.SINK_AT = 0.5
T.LENGTH = 3
T.SERVANTS, T.SERVANTS_MAX, T.SERVANT_EVERY = 4, 6, 30
T.TRIP_AFTER = 60
T.KEY = 35508
T.KRAKOLOSS = 175
-- where the map shows tentacles grabbing the ship (the sea or a hole in the deck)
T.GRIPS = {
	{ 33714, 31176, 7 }, { 33718, 31176, 7 }, { 33726, 31176, 7 }, { 33726, 31180, 7 }, { 33716, 31183, 7 },
	{ 33710, 31185, 7 }, { 33727, 31186, 7 }, { 33718, 31191, 7 }, { 33723, 31191, 7 },
	{ 33714, 31176, 6 }, { 33726, 31176, 6 }, { 33716, 31183, 6 }, { 33710, 31185, 6 }, { 33718, 31191, 6 },
}

T.phase = nil -- "head", "tentacles", "head2", "won"
T.headId, T.health = nil, nil
T.lines = {} -- { squares = { positions from the tip back to the grip }, k = current square, id = creature id }
T.servants = {}
T.nextServant = 0

function T.enabled()
	return PT.enabled()
end

local function inZone(pos)
	local z = T.ZONE
	return pos.z >= z.z1 and pos.z <= z.z2 and pos.x >= z.x1 and pos.x <= z.x2 and pos.y >= z.y1 and pos.y <= z.y2
end
T.inZone = inZone

local function walkable(pos)
	local tile = Tile(pos)
	return tile and tile:getGround() and not tile:hasFlag(TILESTATE_BLOCKSOLID) and not tile:hasFlag(TILESTATE_FLOORCHANGE) and true or false
end

local function zonePlayers()
	local list = {}
	for _, p in ipairs(Game.getPlayers()) do
		if inZone(p:getPosition()) then
			list[#list + 1] = p
		end
	end
	return list
end
T.zonePlayers = zonePlayers

local function tell(text)
	for _, p in ipairs(zonePlayers()) do
		p:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	end
end

-- The squares a tentacle sticks out from its grip, towards the middle of the ship, tip first.
function T.lineFor(grip)
	local best, bestScore = {}, nil
	local dx, dy = T.CENTER.x - grip[1], T.CENTER.y - grip[2]
	-- a straight way onto the deck (over the rail or out of the hole: up to 3 squares that cannot be walked
	-- are skipped first); the longest wins, then the one pointing most to the middle of the ship
	for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local squares, skipped = {}, 0
		for k = 1, T.LENGTH + 3 do
			local pos = Position(grip[1] + d[1] * k, grip[2] + d[2] * k, grip[3])
			if not inZone(pos) then
				break
			end
			if walkable(pos) then
				squares[#squares + 1] = pos
				if #squares == T.LENGTH then
					break
				end
			elseif #squares == 0 and skipped < 3 then
				skipped = skipped + 1
			else
				break
			end
		end
		local score = #squares * 1000 + (d[1] * dx + d[2] * dy)
		if #squares > 0 and (not bestScore or score > bestScore) then
			best, bestScore = squares, score
		end
	end
	local tipFirst = {}
	for k = #best, 1, -1 do
		tipFirst[#tipFirst + 1] = best[k]
	end
	return tipFirst
end

-- Anyone where a tentacle comes out has to go (EN).
local function clearSquare(pos)
	local tile = Tile(pos)
	if not tile then
		return
	end
	for _, c in ipairs(tile:getCreatures() or {}) do
		local p = c:getPlayer()
		if p then
			p:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You had to leave the area because of strange events.") -- EN
			local temple = p:getTown() and p:getTown():getTemplePosition()
			if temple then
				p:teleportTo(temple)
				temple:sendMagicEffect(CONST_ME_TELEPORT)
			end
		elseif c:isMonster() and c:getName() ~= "Tentacle" then
			-- a servant in the way is moved elsewhere on the deck
			local to = T.randomDeck(pos.z)
			if to then
				c:teleportTo(to, true)
			end
		end
	end
end

local function spawnTentacle(line)
	local pos = line.squares[line.k]
	clearSquare(pos)
	local m = Game.createMonster("Tentacle", pos, false, true)
	if not m then
		line.k = #line.squares + 1 -- could not come out: counts as gone, so the fight cannot get stuck
		return nil
	end
	line.id = m:getId()
	pos:sendMagicEffect(CONST_ME_WATERSPLASH)
	return m
end

local function removeAll()
	for _, line in ipairs(T.lines) do
		local c = line.id and Creature(line.id)
		if c then
			c:remove()
		end
	end
	for id in pairs(T.servants) do
		local c = Creature(id)
		if c then
			c:remove()
		end
	end
	local head = T.headId and Creature(T.headId)
	if head then
		head:remove()
	end
	T.lines, T.servants, T.headId = {}, {}, nil
end

function T.randomDeck(z)
	for _ = 1, 40 do
		local pos = Position(math.random(T.ZONE.x1, T.ZONE.x2), math.random(T.ZONE.y1, T.ZONE.y2), z or 7)
		local tile = Tile(pos)
		if walkable(pos) and not tile:getTopCreature() and pos:getDistance(T.HEAD_POS) >= 3 then
			return pos
		end
	end
	return nil
end

local function spawnServant()
	local pos = T.randomDeck(7)
	local m = pos and Game.createMonster("Servant of Tentugly", pos, false, true)
	if m then
		T.servants[m:getId()] = true
		pos:sendMagicEffect(CONST_ME_WATERSPLASH)
	end
	return m
end

local function countServants()
	local n = 0
	for id in pairs(T.servants) do
		if Creature(id) then
			n = n + 1
		else
			T.servants[id] = nil
		end
	end
	return n
end
T.countServants = countServants

-- Called by the lever before the players are moved in.
function T.start(now)
	removeAll()
	local head = Game.createMonster(T.HEAD, T.HEAD_POS, true, true)
	if not head then
		return false
	end
	T.headId = head:getId()
	T.health = nil
	T.phase = "head"
	for _ = 1, T.SERVANTS do
		spawnServant()
	end
	T.nextServant = (now or os.time()) + T.SERVANT_EVERY
	return true
end

function T.sink()
	local head = T.headId and Creature(T.headId)
	if not head then
		return
	end
	T.health = head:getHealth()
	T.HEAD_POS:sendMagicEffect(CONST_ME_WATERSPLASH)
	head:remove()
	T.headId = nil
	T.phase = "tentacles"
	T.lines = {}
	for _, grip in ipairs(T.GRIPS) do
		local squares = T.lineFor(grip)
		if #squares > 0 then
			local line = { squares = squares, k = 1 }
			T.lines[#T.lines + 1] = line
			spawnTentacle(line)
		end
	end
	tell("Tentugly's Head sinks into the sea. Its tentacles grab the ship!") -- ours
	return #T.lines
end

function T.rise()
	local head = Game.createMonster(T.HEAD, T.HEAD_POS, true, true)
	if not head then
		return false
	end
	if T.health then
		head:setHealth(T.health)
	end
	T.headId = head:getId()
	T.phase = "head2"
	tell("The tentacles let go of the ship. Tentugly's Head rises again!") -- ours
	return true
end

function T.tentaclesLeft()
	local n = 0
	for _, line in ipairs(T.lines) do
		if line.k <= #line.squares then
			n = n + 1
		end
	end
	return n
end

-- A tentacle died: it retreats one square, or lets go when it has no square left.
function T.onTentacleDeath(id)
	for _, line in ipairs(T.lines) do
		if line.id == id then
			line.id = nil
			line.k = line.k + 1
			if line.k <= #line.squares then
				addEvent(function()
					if T.phase == "tentacles" then
						spawnTentacle(line)
					end
				end, 1000)
			end
			return true
		end
	end
	return false
end

function T.reset()
	removeAll()
	T.phase, T.health = nil, nil
end

function T.tick(now)
	now = now or os.time()
	if not T.phase or T.phase == "won" then
		return
	end
	if #zonePlayers() == 0 then
		T.reset()
		return
	end
	if T.phase == "head" then
		local head = T.headId and Creature(T.headId)
		if head and head:getHealth() <= head:getMaxHealth() * T.SINK_AT then
			T.sink()
		end
	elseif T.phase == "tentacles" then
		if T.tentaclesLeft() == 0 then
			T.rise()
		end
	end
	if now >= T.nextServant then
		if countServants() < T.SERVANTS_MAX then
			spawnServant()
		end
		T.nextServant = now + T.SERVANT_EVERY
	end
end

function T.reward(player)
	player:setStorageValue(S.TentuglyKilled, 1) -- The Wreckoning
	player:addAchievement("Release the Kraken")
	if not player:hasMount(T.KRAKOLOSS) then
		player:addMount(T.KRAKOLOSS)
	end
	if player:getStorageValue(S.CheesyKey) < 1 then
		player:setStorageValue(S.CheesyKey, 1)
		player:addItem(T.KEY, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found a cheesy key in the wreckage. Keep it, you will need it.") -- ours
	end
end

function T.toWreckoning()
	for _, p in ipairs(zonePlayers()) do
		p:teleportTo(T.WRECKONING)
	end
	T.WRECKONING:sendMagicEffect(CONST_ME_TELEPORT)
	T.reset()
end

function T.won()
	T.phase = "won"
	for _, p in ipairs(zonePlayers()) do
		T.reward(p)
	end
	for id in pairs(T.servants) do
		local c = Creature(id)
		if c then
			c:remove()
		end
	end
	T.servants = {}
	local lever = BossLever and BossLever[T.HEAD:lower()]
	if lever and lever.timeoutEvent then
		stopEvent(lever.timeoutEvent)
		lever.timeoutEvent = nil
	end
	tell(string.format("You defeated Tentugly's Head! In %d seconds the ship takes you on to The Wreckoning, or use the teleport on the left.", T.TRIP_AFTER)) -- ours
	T.tripEvent = addEvent(T.toWreckoning, T.TRIP_AFTER * 1000)
end

local headDeath = CreatureEvent("FamilyTentuglyDeath")
function headDeath.onDeath(creature)
	if T.enabled() and creature:getId() == T.headId then
		T.headId = nil
		T.won()
	elseif T.enabled() then
		-- a head not made by the fight (a GOD's /m): reward the players around it
		for _, p in ipairs(zonePlayers()) do
			T.reward(p)
		end
	end
	return true
end
headDeath:register()

local tentacleDeath = CreatureEvent("FamilyTentacleDeath")
function tentacleDeath.onDeath(creature)
	if T.enabled() then
		T.onTentacleDeath(creature:getId())
	end
	return true
end
tentacleDeath:register()

local clock = GlobalEvent("FamilyTentuglyFight")
function clock.onThink(interval)
	if T.enabled() and T.phase then
		T.tick()
	end
	return true
end
clock:interval(1000)
clock:register()

-- The teleport on the left of the ship.
local function shipStep(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not T.enabled() then
		return true
	end
	local to = player:getStorageValue(S.TentuglyKilled) == 1 and T.WRECKONING or T.RASCACOON
	player:teleportTo(to)
	to:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end
T.shipStep = shipStep
local shipTeleport = MoveEvent()
shipTeleport.onStepIn = shipStep
shipTeleport:type("stepin")
shipTeleport:position(T.SHIP_TELEPORT)
shipTeleport:register()

local startup = GlobalEvent("FamilyTentuglyShip")
function startup.onStartup()
	if not T.enabled() then
		return true
	end
	local tile = Tile(T.SHIP_TELEPORT)
	local teleport = tile and tile:getItemById(34111)
	if teleport and teleport.setDestination then
		teleport:setDestination(Position(0, 0, 0))
	end
	local lines, squares = 0, 0
	for _, grip in ipairs(T.GRIPS) do
		local n = #T.lineFor(grip)
		if n > 0 then
			lines, squares = lines + 1, squares + n
		end
	end
	logger.info(string.format("[Family] Tentugly fight: %d tentacles, %d squares, ship teleport %s", lines, squares, teleport and "on" or "MISSING"))
	return true
end
startup:register()
