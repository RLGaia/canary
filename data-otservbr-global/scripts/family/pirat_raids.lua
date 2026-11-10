-- Gaia Family server: Pirat raids for Eustacio (A Pirate's Tail Quest, 2026-11-10). Ours, not
-- upstream (Canary v3.6.1 has no Pirat raids). Rules in lib/others/family_pirates_tail.lua.
--
-- As in Tibia (TibiaWiki BR quest page, EN spoiler): one raid at a time, at one of five places
-- (Krailos, Thais, Darashia, Port Hope, Liberty Bay) and of one of three kinds, both at random;
-- no announcement (ask Eustacio about the "location"); a raid lasts until it is beaten, and the
-- next one comes 30 minutes after. Ours: the first raid 10 minutes after the server starts, never
-- the same place twice in a row.
--   spyrats  spyrats wait in the water 2-4 squares from the shore; the magical water orb used on
--            the water next to you makes a platform (client objects 35367 + 35389) to reach them;
--            5 points per spyrat attacked; 60 killed end it ("The pirats used the big wave to flee!")
--   ship     a pirat ship (a copy of the ship at 32332,32615, lib/others/family_pirat_ship.lua)
--            anchors off the coast; two catapults (client objects 35482/35483) and grey stones
--            (35331-35335) on the shore: a pick on a stone gives a ballistic boulder, the boulder on
--            a catapult loads it, the greenish flintstone lights it, using the catapult fires it
--            (5 s between shots, EN); 2 points each step; 50 shots end it ("You fended off the
--            attack! The ship is gone.")
--   land     pirats (bombardier, cutthroat, mate, scoundrel) on the coast, 20 at a time (ours);
--            3 points per pirat attacked; 100 killed end it ("You pushed them back! The pirats ran
--            away.")
-- Then everyone near hears "The city is safe now." (BR). Points count once per creature and
-- player, at most 300 per raid (BR).
-- The loaded and lit catapult show client objects 35295 and 35484 (our choice of look).
-- GOD: /piratraid [start <spyrats|ship|land> <krailos|thais|darashia|porthope|libertybay> | stop]
-- Switch: Family.piratesTail.

local PT = FamilyPiratesTail
if not PT then
	return
end

local R = {}
PT.raid = R

R.FIRST_DELAY = 10 * 60
R.BREAK = 30 * 60
R.KINDS = { "spyrats", "ship", "land" }
R.LAND_TOTAL, R.LAND_ALIVE = 100, 20
R.SPYRAT_TOTAL, R.SPYRAT_ALIVE = 60, 12
R.SHOTS = 50
R.SHOT_COOLDOWN = 5
R.LAND_RADIUS = 8
R.WATER_RADIUS = 10
R.AREA = 16 -- who hears the end of the raid
R.PIRATS = { "Pirat Bombardier", "Pirat Cutthroat", "Pirat Mate", "Pirat Scoundrel" }
R.SPYRATS = { "Spyrat North", "Spyrat East", "Spyrat South", "Spyrat West" }
R.POINTS = { spyrat = 5, pirat = 3, catapult = 2 }
R.WATER = { [4654] = true, [4655] = true } -- the open sea (client "shallow water" grounds that block walking)
for id = 4597, 4602 do
	R.WATER[id] = true
end
for id = 4609, 4614 do
	R.WATER[id] = true
end
R.PLATFORM_GROUND = 35367
R.PLATFORM = 35389
R.BORDER_FROM, R.BORDER_TO = 4633, 4652 -- the water's edge on a land square (blocks walking)
R.CATAPULT_W, R.CATAPULT_E = 35482, 35483
R.LOADED, R.LIT = 35295, 35484
R.STONES = { 35331, 35332, 35333, 35334, 35335 }
R.END_TEXT = {
	spyrats = "The pirats used the big wave to flee!", -- EN
	ship = "You fended off the attack! The ship is gone.", -- EN
	land = "You pushed them back! The pirats ran away.", -- EN
}

R.next = nil -- os.time() of the next raid
R.raidMonsters = {} -- creature id -> true for every raid creature of this server run
R.lastPlace = nil

local function enabled()
	return PT.enabled()
end

local function posKey(p)
	return p.x .. ":" .. p.y .. ":" .. p.z
end

local function isWater(x, y, z)
	local tile = Tile(Position(x, y, z))
	local ground = tile and tile:getGround()
	return ground ~= nil and R.WATER[ground:getId()] == true
end

local function isLand(x, y, z)
	local tile = Tile(Position(x, y, z))
	local ground = tile and tile:getGround()
	return ground ~= nil and not R.WATER[ground:getId()] and ground:getId() ~= R.PLATFORM_GROUND
end

-- A square a creature or a catapult can stand on.
local function isFreeLand(x, y, z)
	local pos = Position(x, y, z)
	local tile = Tile(pos)
	if not tile or not isLand(x, y, z) then
		return false
	end
	if tile:hasProperty(CONST_PROP_BLOCKSOLID) or tile:hasProperty(CONST_PROP_BLOCKPATH) or tile:hasFlag(TILESTATE_PROTECTIONZONE) or tile:getHouse() then
		return false
	end
	if tile:hasFlag(TILESTATE_FLOORCHANGE) or tile:getTopCreature() then
		return false
	end
	return true
end

local function landDistance(x, y, z, max)
	for r = 1, max do
		for dx = -r, r do
			for dy = -r, r do
				if math.max(math.abs(dx), math.abs(dy)) == r and isLand(x + dx, y + dy, z) then
					return r
				end
			end
		end
	end
	return max + 1
end

function R.landSquares(place)
	local c, list = place.center, {}
	for x = c.x - R.LAND_RADIUS, c.x + R.LAND_RADIUS do
		for y = c.y - R.LAND_RADIUS, c.y + R.LAND_RADIUS do
			if isFreeLand(x, y, c.z) then
				list[#list + 1] = Position(x, y, c.z)
			end
		end
	end
	return list
end

-- Water squares 2 to 4 squares from the shore (out of reach without the orb).
function R.waterSquares(place)
	local c, list = place.center, {}
	for x = c.x - R.WATER_RADIUS, c.x + R.WATER_RADIUS do
		for y = c.y - R.WATER_RADIUS, c.y + R.WATER_RADIUS do
			if isWater(x, y, c.z) then
				local d = landDistance(x, y, c.z, 4)
				if d >= 2 and d <= 4 then
					list[#list + 1] = Position(x, y, c.z)
				end
			end
		end
	end
	return list
end

local function inArea(pos, place, radius)
	local c = place.center
	return pos.z == c.z and math.abs(pos.x - c.x) <= radius and math.abs(pos.y - c.y) <= radius
end

local function playersNear(place)
	local list = {}
	for _, player in ipairs(Game.getPlayers()) do
		if inArea(player:getPosition(), place, R.AREA) then
			list[#list + 1] = player
		end
	end
	return list
end

-- Raid creatures --------------------------------------------------------------------------------

local function spawnOne(raid)
	local squares = raid.squares
	if #squares == 0 then
		return nil
	end
	local name = raid.kind == "spyrats" and R.SPYRATS[math.random(#R.SPYRATS)] or R.PIRATS[math.random(#R.PIRATS)]
	for _ = 1, 25 do
		local pos = squares[math.random(#squares)]
		local tile = Tile(pos)
		if tile and not tile:getTopCreature() then
			local monster = Game.createMonster(name, pos, false, true)
			if monster then
				monster:registerEvent("FamilyPiratRaidHit")
				monster:registerEvent("FamilyPiratRaidDeath")
				R.raidMonsters[monster:getId()] = true
				raid.alive[monster:getId()] = true
				return monster
			end
		end
	end
	return nil
end

local function aliveCount(raid)
	local n = 0
	for id in pairs(raid.alive) do
		if Monster(id) then
			n = n + 1
		else
			raid.alive[id] = nil
		end
	end
	return n
end

local function topUp(raid)
	local total = raid.kind == "spyrats" and R.SPYRAT_TOTAL or R.LAND_TOTAL
	local target = raid.kind == "spyrats" and R.SPYRAT_ALIVE or R.LAND_ALIVE
	local want = math.min(target, total - raid.killed)
	local n = aliveCount(raid)
	while n < want do
		if not spawnOne(raid) then
			break
		end
		n = n + 1
	end
end

-- The ship --------------------------------------------------------------------------------------

local function shipFits(ox, oy, z)
	for _, e in ipairs(PT.shipTemplate) do
		local x, y, ez = ox + e[1], oy + e[2], e[3]
		if ez == z then
			if not isWater(x, y, z) then
				return false
			end
		else
			local tile = Tile(Position(x, y, ez))
			if tile and tile:getThingCount() > 0 then
				return false
			end
		end
	end
	-- one square of open sea around the hull (no land, nobody walks in)
	for dx = -1, 5 do
		for dy = -1, 13 do
			if not isWater(ox + dx, oy + dy, z) then
				return false
			end
		end
	end
	return true
end

function R.findShip(place)
	local ax, ay, z = place.ship[1], place.ship[2], place.center.z
	for r = 0, 8 do
		for dx = -r, r do
			for dy = -r, r do
				if math.max(math.abs(dx), math.abs(dy)) == r and shipFits(ax + dx, ay + dy, z) then
					return ax + dx, ay + dy
				end
			end
		end
	end
	return nil
end

function R.stampShip(raid, ox, oy)
	local ship = { added = {}, grounds = {}, deck = {} }
	raid.ship = ship
	for _, e in ipairs(PT.shipTemplate) do
		local pos = Position(ox + e[1], oy + e[2], e[3])
		local tile = Tile(pos)
		if not tile then
			tile = Game.createTile(pos)
		end
		if tile then
			if e[4] then
				local ground = tile:getGround()
				if ground then
					ship.grounds[#ship.grounds + 1] = { pos = pos, id = ground:getId(), to = e[4] }
					ground:transform(e[4])
				else
					Game.createItem(e[4], 1, pos)
					ship.added[#ship.added + 1] = { pos = pos, id = e[4] }
				end
			end
			for _, id in ipairs(e[5]) do
				if Game.createItem(id, 1, pos) then
					ship.added[#ship.added + 1] = { pos = pos, id = id }
				end
			end
		end
	end
	for _, e in ipairs(PT.shipTemplate) do
		if e[3] == 7 then
			ship.deck[#ship.deck + 1] = Position(ox + e[1], oy + e[2], e[3])
		end
	end
end

function R.removeShip(raid)
	local ship = raid.ship
	if not ship then
		return
	end
	for i = #ship.added, 1, -1 do
		local a = ship.added[i]
		local tile = Tile(a.pos)
		local item = tile and tile:getItemById(a.id)
		if item then
			item:remove()
		end
	end
	for _, g in ipairs(ship.grounds) do
		local tile = Tile(g.pos)
		local ground = tile and tile:getGround()
		if ground and ground:getId() == g.to then
			ground:transform(g.id)
		end
	end
	raid.ship = nil
end

-- Catapults -------------------------------------------------------------------------------------

local function findCatapultSpot(place, anchor, taken)
	local z = place.center.z
	for r = 0, 4 do
		for dx = -r, r do
			for dy = -r, r do
				if math.max(math.abs(dx), math.abs(dy)) == r then
					local x, y = anchor[1] + dx, anchor[2] + dy
					local key = x .. ":" .. y
					if not taken[key] and not taken[(x + 1) .. ":" .. y] and isFreeLand(x, y, z) and isFreeLand(x + 1, y, z) then
						return x, y
					end
				end
			end
		end
	end
	return nil
end

function R.placeCatapults(raid)
	raid.catapults, raid.stones = {}, {}
	local place, z, taken = raid.place, raid.place.center.z, {}
	for _, anchor in ipairs(place.catapults) do
		local x, y = findCatapultSpot(place, anchor, taken)
		if x then
			for dx = -1, 2 do
				for dy = -1, 1 do
					taken[(x + dx) .. ":" .. (y + dy)] = true
				end
			end
			local west, east = Position(x, y, z), Position(x + 1, y, z)
			Game.createItem(R.CATAPULT_W, 1, west)
			Game.createItem(R.CATAPULT_E, 1, east)
			local catapult = { west = west, east = east, state = 0, ready = 0 }
			raid.catapults[#raid.catapults + 1] = catapult
			-- two grey stones within two squares (BR: "pedras cinzas próximas das catapultas")
			local placed = 0
			for r = 2, 3 do
				for dx = -r, r + 1 do
					for dy = -r, r do
						if placed < 2 and (math.abs(dy) == r or dx == -r or dx == r + 1) then
							local sx, sy = x + dx, y + dy
							if not taken[sx .. ":" .. sy] and isFreeLand(sx, sy, z) then
								local spos = Position(sx, sy, z)
								local id = R.STONES[math.random(#R.STONES)]
								if Game.createItem(id, 1, spos) then
									raid.stones[#raid.stones + 1] = { pos = spos, id = id }
									taken[sx .. ":" .. sy] = true
									placed = placed + 1
								end
							end
						end
					end
				end
			end
		end
	end
end

local function removeIds(pos, ids)
	local tile = Tile(pos)
	if not tile then
		return
	end
	for _, id in ipairs(ids) do
		local item = tile:getItemById(id)
		while item do
			item:remove()
			item = tile:getItemById(id)
		end
	end
end

function R.removeCatapults(raid)
	for _, c in ipairs(raid.catapults or {}) do
		removeIds(c.west, { R.LOADED, R.LIT, R.CATAPULT_W })
		removeIds(c.east, { R.CATAPULT_E })
	end
	for _, s in ipairs(raid.stones or {}) do
		removeIds(s.pos, { s.id })
	end
	raid.catapults, raid.stones = {}, {}
end

function R.catapultAt(pos)
	local raid = PT.current
	if not raid or raid.kind ~= "ship" then
		return nil
	end
	for _, c in ipairs(raid.catapults or {}) do
		if c.west == pos or c.east == pos then
			return c, raid
		end
	end
	return nil
end

-- Platforms (magical water orb) -------------------------------------------------------------------

function R.removePlatforms(raid)
	for _, p in pairs(raid.platforms or {}) do
		local tile = Tile(p.pos)
		if tile then
			for _, creature in ipairs(tile:getCreatures() or {}) do
				if creature:isPlayer() then
					creature:teleportTo(raid.place.center)
					raid.place.center:sendMagicEffect(CONST_ME_WATERSPLASH)
				end
			end
			removeIds(p.pos, { R.PLATFORM })
			local ground = tile:getGround()
			if p.ground and ground and ground:getId() == R.PLATFORM_GROUND then
				ground:transform(p.ground)
			end
			for _, id in ipairs(p.borders or {}) do
				Game.createItem(id, 1, p.pos)
			end
			p.pos:sendMagicEffect(CONST_ME_WATERSPLASH)
		end
	end
	raid.platforms = {}
end

-- Start and end -----------------------------------------------------------------------------------

function R.start(kind, placeKey)
	if PT.current then
		return false, "a raid is running"
	end
	local place
	if placeKey then
		for _, p in ipairs(PT.places) do
			if p.key == placeKey then
				place = p
			end
		end
	else
		local choices = {}
		for _, p in ipairs(PT.places) do
			if p ~= R.lastPlace then
				choices[#choices + 1] = p
			end
		end
		place = choices[math.random(#choices)]
	end
	if not place then
		return false, "unknown place"
	end
	kind = kind or R.KINDS[math.random(#R.KINDS)]
	local raid = { place = place, kind = kind, serial = os.time(), killed = 0, alive = {}, hits = {}, platforms = {}, shots = 0 }
	if kind == "spyrats" then
		raid.squares = R.waterSquares(place)
	elseif kind == "land" then
		raid.squares = R.landSquares(place)
	elseif kind == "ship" then
		local ox, oy = R.findShip(place)
		if not ox then
			logger.warn("[Family] Pirat raid: no room for the ship at " .. place.key .. ", land raid instead")
			kind = "land"
			raid.kind = kind
			raid.squares = R.landSquares(place)
		else
			R.stampShip(raid, ox, oy)
			R.placeCatapults(raid)
			raid.shipOrigin = Position(ox, oy, place.center.z)
		end
	else
		return false, "unknown kind"
	end
	PT.current = raid
	R.lastPlace = place
	if raid.squares then
		topUp(raid)
	end
	logger.info("[Family] Pirat raid: " .. kind .. " at " .. place.key)
	return true
end

function R.finish(beaten)
	local raid = PT.current
	if not raid then
		return
	end
	PT.current = nil
	for id in pairs(raid.alive) do
		local monster = Monster(id)
		if monster then
			monster:getPosition():sendMagicEffect(CONST_ME_POFF)
			monster:remove()
		end
	end
	R.removePlatforms(raid)
	R.removeCatapults(raid)
	R.removeShip(raid)
	if beaten then
		for _, player in ipairs(playersNear(raid.place)) do
			player:say(R.END_TEXT[raid.kind], TALKTYPE_MONSTER_SAY, false, player, player:getPosition())
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The city is safe now.")
		end
	end
	R.next = os.time() + R.BREAK
	logger.info("[Family] Pirat raid at " .. raid.place.key .. " " .. (beaten and "beaten" or "stopped"))
end

function R.tick(now)
	now = now or os.time()
	if not R.next then
		R.next = now + R.FIRST_DELAY
	end
	local raid = PT.current
	if not raid then
		if now >= R.next then
			R.start()
		end
		return
	end
	if raid.squares then
		topUp(raid)
	end
end

local clock = GlobalEvent("FamilyPiratRaids")
function clock.onThink(interval)
	if enabled() then
		R.tick()
	end
	return true
end
clock:interval(5 * 1000)
clock:register()

-- Points for attacking raid creatures --------------------------------------------------------------

local function creditHit(raid, creature, attacker)
	if not attacker then
		return
	end
	local player = attacker:getPlayer()
	if not player and attacker:getMaster() then
		player = attacker:getMaster():getPlayer()
	end
	if not player then
		return
	end
	local cid = creature:getId()
	raid.hits[cid] = raid.hits[cid] or {}
	if raid.hits[cid][player:getId()] then
		return
	end
	raid.hits[cid][player:getId()] = true
	PT.addPoints(player, raid.kind == "spyrats" and R.POINTS.spyrat or R.POINTS.pirat, raid.serial)
end

local hit = CreatureEvent("FamilyPiratRaidHit")
function hit.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	local raid = PT.current
	if raid and raid.alive[creature:getId()] and primaryType ~= COMBAT_HEALING then
		creditHit(raid, creature, attacker)
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
hit:register()

local death = CreatureEvent("FamilyPiratRaidDeath")
function death.onDeath(creature, corpse, killer, mostDamageKiller)
	local raid = PT.current
	local id = creature:getId()
	if not raid or not raid.alive[id] then
		return true
	end
	raid.alive[id] = nil
	raid.killed = raid.killed + 1
	local total = raid.kind == "spyrats" and R.SPYRAT_TOTAL or R.LAND_TOTAL
	if raid.killed >= total then
		addEvent(R.finish, 100, true)
	end
	return true
end
death:register()

-- Pirats killed outside the raids (after Eustacio's secret, EN Pied Piper) --------------------------

local function isPirat(name)
	return name:find("^Pirat ") or name:find("^Elite Pirat") or name:find("^Spyrat")
end

local hunting = EventCallback("FamilyPiratHunting")
function hunting.monsterPostDropLoot(monster, corpse)
	if not enabled() or R.raidMonsters[monster:getId()] or not isPirat(monster:getName()) then
		return
	end
	for cid in pairs(monster:getDamageMap() or {}) do
		local player = Player(cid)
		if player and PT.questLine(player) >= 2 then
			PT.addPoints(player, R.POINTS.pirat, nil)
		end
	end
end
hunting:register()

-- Items -----------------------------------------------------------------------------------------

local orb = Action()
local function isBorder(id)
	return id >= R.BORDER_FROM and id <= R.BORDER_TO
end

local function useOrb(player, item, fromPosition, target, toPosition, isHotkey)
	local raid = PT.current
	if not enabled() or not raid or raid.kind ~= "spyrats" or not inArea(toPosition, raid.place, R.AREA) then
		player:sendCancelMessage("Nothing happens.") -- ours
		return true
	end
	local ppos = player:getPosition()
	if ppos.z ~= toPosition.z or math.max(math.abs(ppos.x - toPosition.x), math.abs(ppos.y - toPosition.y)) > 2 then
		player:sendCancelMessage("You have to stand closer to the water.") -- ours
		return true
	end
	local tile = Tile(toPosition)
	local ground = tile and tile:getGround()
	if not ground or tile:getTopCreature() or raid.platforms[posKey(toPosition)] then
		player:sendCancelMessage("Use it on the open water.") -- ours
		return true
	end
	local entry = { pos = Position(toPosition.x, toPosition.y, toPosition.z), borders = {} }
	if R.WATER[ground:getId()] then
		entry.ground = ground:getId()
		ground:transform(R.PLATFORM_GROUND)
	else
		-- the edge of the shore (BR: "utilize a Orb na borda da grama/areia"): the water border on
		-- the land square goes away while the raid lasts
		for _, it in ipairs(tile:getItems() or {}) do
			if isBorder(it:getId()) then
				entry.borders[#entry.borders + 1] = it:getId()
			end
		end
		if #entry.borders == 0 then
			player:sendCancelMessage("Use it on the open water.") -- ours
			return true
		end
		removeIds(toPosition, entry.borders)
	end
	raid.platforms[posKey(toPosition)] = entry
	Game.createItem(R.PLATFORM, 1, toPosition)
	toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
	return true
end
orb.onUse = useOrb
orb:id(PT.ORB)
orb:register()

-- the pick on a grey stone (called from onUsePick, scripts/lib/register_actions.lua)
function PT.onPick(player, target, toPosition)
	local raid = PT.current
	if not enabled() or not raid or raid.kind ~= "ship" or not target or not target.getId then
		return false
	end
	for _, s in ipairs(raid.stones or {}) do
		if s.pos == toPosition and target:getId() == s.id then
			if not player:addItem(PT.BOULDER, 1) then
				player:sendCancelMessage("You cannot carry the boulder.") -- ours
				return true
			end
			toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
			return true
		end
	end
	return false
end

local boulder = Action()
local function useBoulder(player, item, fromPosition, target, toPosition, isHotkey)
	local catapult, raid = R.catapultAt(toPosition)
	if not catapult then
		return false
	end
	if catapult.state > 0 then
		player:sendCancelMessage("The catapult is already loaded.") -- ours
		return true
	end
	item:remove(1)
	catapult.state = 1
	Game.createItem(R.LOADED, 1, catapult.west)
	catapult.west:sendMagicEffect(CONST_ME_BLOCKHIT)
	PT.addPoints(player, R.POINTS.catapult, raid.serial)
	return true
end
boulder.onUse = useBoulder
boulder:id(PT.BOULDER)
boulder:register()

local flint = Action()
local function useFlint(player, item, fromPosition, target, toPosition, isHotkey)
	local catapult, raid = R.catapultAt(toPosition)
	if not catapult then
		player:sendCancelMessage("Nothing happens.") -- ours
		return true
	end
	if catapult.state == 0 then
		player:sendCancelMessage("Load the catapult first.") -- ours
		return true
	elseif catapult.state == 2 then
		player:sendCancelMessage("The ammunition is already burning.") -- ours
		return true
	end
	catapult.state = 2
	Game.createItem(R.LIT, 1, catapult.west)
	catapult.west:sendMagicEffect(CONST_ME_HITBYFIRE)
	PT.addPoints(player, R.POINTS.catapult, raid.serial)
	return true
end
flint.onUse = useFlint
flint:id(PT.FLINTSTONE)
flint:register()

local fire = Action()
local function useCatapult(player, item, fromPosition, target, toPosition, isHotkey)
	local catapult, raid = R.catapultAt(item:getPosition())
	if not catapult then
		return false
	end
	if catapult.state < 2 then
		player:sendCancelMessage(catapult.state == 0 and "The catapult is not loaded." or "Light the ammunition first.") -- ours
		return true
	end
	if os.time() < catapult.ready then
		player:sendCancelMessage("The catapult is not ready yet.") -- ours
		return true
	end
	removeIds(catapult.west, { R.LOADED, R.LIT })
	catapult.state = 0
	catapult.ready = os.time() + R.SHOT_COOLDOWN
	local deck = raid.ship and raid.ship.deck or {}
	local targetPos = #deck > 0 and deck[math.random(#deck)] or raid.place.center
	catapult.west:sendDistanceEffect(targetPos, CONST_ANI_LARGEROCK)
	addEvent(function(x, y, z)
		local p = Position(x, y, z)
		p:sendMagicEffect(CONST_ME_EXPLOSIONHIT)
		Position(x, y, z - 1):sendMagicEffect(CONST_ME_FIREAREA)
	end, 400, targetPos.x, targetPos.y, targetPos.z)
	PT.addPoints(player, R.POINTS.catapult, raid.serial)
	raid.shots = raid.shots + 1
	if raid.shots >= R.SHOTS then
		addEvent(R.finish, 1000, true)
	end
	return true
end
fire.onUse = useCatapult
fire:id(R.CATAPULT_W, R.CATAPULT_E)
fire:register()

-- for the self-tests
R.onUseOrb, R.onUseBoulder, R.onUseFlint, R.onUseCatapult = useOrb, useBoulder, useFlint, useCatapult

-- GOD command -------------------------------------------------------------------------------------

local command = TalkAction("/piratraid")
function command.onSay(player, words, param)
	local args = param:split(" ")
	if args[1] == "start" then
		if PT.current then
			R.finish(false)
		end
		local ok, err = R.start(args[2], args[3])
		player:sendTextMessage(MESSAGE_LOOK, ok and "Pirat raid started." or ("Not started: " .. tostring(err)))
	elseif args[1] == "stop" then
		R.finish(false)
		player:sendTextMessage(MESSAGE_LOOK, "Pirat raid stopped.")
	else
		local raid = PT.current
		if raid then
			player:sendTextMessage(MESSAGE_LOOK, string.format("Pirat raid: %s at %s, killed %d, alive %d, shots %d.", raid.kind, raid.place.key, raid.killed, aliveCount(raid), raid.shots))
		else
			player:sendTextMessage(MESSAGE_LOOK, string.format("No Pirat raid; the next in %d minutes.", math.max(0, math.floor(((R.next or os.time()) - os.time()) / 60))))
		end
	end
	return false
end
command:separator(" ")
command:groupType("god")
command:register()
