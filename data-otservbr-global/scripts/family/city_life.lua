-- Gaia Family server: "city life" NPCs (2026-10-13).
--
-- Ours, not upstream. Walking NPCs that look like players live in the port
-- cities, chat, give quest tips and sometimes sail to another city. A few of
-- them are vendors with a random stock each server start.
--
-- Settings and texts: data-otservbr-global/scripts/lib/family_city_life_data.lua
-- Documentation: FAMILY.md, section "City life".
-- GOD command: /citylife (status report).
--
-- How it works:
--   * At startup each city's walkable street area is found by a flood fill
--     from its center (floor 7 only; houses, stairs, holes and teleports are
--     left out), so NPCs never enter houses or change floors.
--   * Walkers pick a random spot, walk there step by step (A* path inside
--     that area), wait, and repeat. They stop while a player talks to them.
--   * Travel: walk to the street tile next to the ship captain, vanish, and
--     appear at another city's harbour a few minutes later.

local cfg = FamilyCityLife
if not cfg or not cfg.enabled then
	return
end

local TICK_MS = 250
local STEP_TICKS = 3 -- one step every 750 ms
local NPC_SPEED = 220 -- matches the step time on normal ground
local MAX_PATH_NODES = 8000
local DOCK_MAX_DISTANCE = 15
local QUERY_FLAGS = FLAG_PATHFINDING + FLAG_IGNOREBLOCKCREATURE

local tick = 0
local walkers = {}
local cityStates = {}
local vendorsByKind = {}
local started = false

local function key(x, y)
	return x * 65536 + y
end

local function keyX(k)
	return math.floor(k / 65536)
end

local function keyY(k)
	return k % 65536
end

local function ticksFromSeconds(seconds)
	return math.max(1, math.floor(seconds * 1000 / TICK_MS))
end

local function randomRange(range)
	return math.random(range[1], range[2])
end

local function pick(list)
	return list[math.random(#list)]
end

-- ---------------------------------------------------------------------------
-- Walkable area of a city
-- ---------------------------------------------------------------------------
local DIRS = {
	{ dir = DIRECTION_NORTH, dx = 0, dy = -1 },
	{ dir = DIRECTION_EAST, dx = 1, dy = 0 },
	{ dir = DIRECTION_SOUTH, dx = 0, dy = 1 },
	{ dir = DIRECTION_WEST, dx = -1, dy = 0 },
}

local function isWalkable(probe, x, y, z)
	local tile = Tile(x, y, z)
	if not tile or not tile:getGround() then
		return false
	end
	if tile:getHouse() or tile:hasFlag(TILESTATE_FLOORCHANGE) or tile:hasFlag(TILESTATE_TELEPORT) then
		return false
	end
	return tile:queryAdd(probe, QUERY_FLAGS) == RETURNVALUE_NOERROR
end

local function flood(probe, seedX, seedY, z, city, floodRadius, set)
	local component = {}
	local queue, head = { key(seedX, seedY) }, 1
	set[queue[1]] = true
	while head <= #queue do
		local k = queue[head]
		head = head + 1
		component[#component + 1] = k
		local x, y = keyX(k), keyY(k)
		for _, d in ipairs(DIRS) do
			local nx, ny = x + d.dx, y + d.dy
			local nk = key(nx, ny)
			if not set[nk] and math.max(math.abs(nx - city.center.x), math.abs(ny - city.center.y)) <= floodRadius and isWalkable(probe, nx, ny, z) then
				set[nk] = true
				queue[#queue + 1] = nk
			end
		end
	end
	return component
end

local MIN_AREA_TILES = 40 -- smaller street pieces are ignored
local MAX_AREAS = 8

local function makeArea(city, z, tiles)
	local set, wander = {}, {}
	for _, k in ipairs(tiles) do
		set[k] = true
		if math.max(math.abs(keyX(k) - city.center.x), math.abs(keyY(k) - city.center.y)) <= city.radius then
			wander[#wander + 1] = k
		end
	end
	-- "Open" tiles (3+ walkable neighbours) are where walkers stop, so they
	-- never wait in a doorway or a narrow passage.
	local open = {}
	for _, k in ipairs(wander) do
		local x, y, n = keyX(k), keyY(k), 0
		for _, d in ipairs(DIRS) do
			if set[key(x + d.dx, y + d.dy)] then
				n = n + 1
			end
		end
		if n >= 3 then
			open[#open + 1] = k
		end
	end
	return { city = city, z = z, set = set, all = tiles, wander = wander, open = #open > 0 and open or wander }
end

-- Returns the city's street areas: connected pieces of walkable ground on
-- floor 7 (cities are cut into pieces by water, walls and closed doors).
-- Walkers stay inside their piece; the piece next to the ship captain is the
-- harbour piece, the only one travellers use.
local function buildCity(city, probe)
	local z = city.center.z
	local dockDistance = city.dock and math.max(math.abs(city.dock.x - city.center.x), math.abs(city.dock.y - city.center.y)) or 0
	local floodRadius = math.min(120, math.max(city.radius, dockDistance + DOCK_MAX_DISTANCE))

	local seen, components = {}, {}
	for dy = -city.radius, city.radius, 3 do
		for dx = -city.radius, city.radius, 3 do
			local x, y = city.center.x + dx, city.center.y + dy
			if not seen[key(x, y)] and isWalkable(probe, x, y, z) then
				components[#components + 1] = flood(probe, x, y, z, city, floodRadius, seen)
			end
		end
	end
	table.sort(components, function(a, b)
		return #a > #b
	end)
	local areas = {}
	for _, component in ipairs(components) do
		if #areas >= MAX_AREAS then
			break
		end
		local area = makeArea(city, z, component)
		if #area.wander >= MIN_AREA_TILES then
			areas[#areas + 1] = area
		end
	end

	-- Harbour: the street tile closest to the ship captain (the captain
	-- stands on the ship; the ship's own decks are not part of any area).
	local dockArea, dockGap
	if city.dock then
		for _, area in ipairs(areas) do
			for _, k in ipairs(area.all) do
				local dist = math.max(math.abs(keyX(k) - city.dock.x), math.abs(keyY(k) - city.dock.y))
				if not dockGap or dist < dockGap then
					dockGap, dockArea = dist, area
					area.candidateDock = k
				end
			end
		end
		if dockArea and dockGap <= DOCK_MAX_DISTANCE then
			dockArea.dockKey = dockArea.candidateDock
		else
			dockArea = nil
		end
	end

	local streetTiles = 0
	for _, area in ipairs(areas) do
		streetTiles = streetTiles + #area.wander
	end
	return { city = city, areas = areas, dockArea = dockArea, dockGap = dockGap, streetTiles = streetTiles }
end

-- Picks an area for a new walker, bigger areas more often.
local function pickArea(cityState)
	local total = 0
	for _, area in ipairs(cityState.areas) do
		total = total + #area.open
	end
	local roll = math.random(math.max(1, total))
	for _, area in ipairs(cityState.areas) do
		roll = roll - #area.open
		if roll <= 0 then
			return area
		end
	end
	return cityState.areas[1]
end

-- ---------------------------------------------------------------------------
-- A* path (4 directions) inside the city's walkable area
-- ---------------------------------------------------------------------------
local function findPath(state, sx, sy, tx, ty)
	local set = state.set
	local startKey, goalKey = key(sx, sy), key(tx, ty)
	if startKey == goalKey then
		return {}
	end
	if not set[goalKey] then
		return nil
	end

	local heap = { { f = 0, k = startKey } }
	local g = { [startKey] = 0 }
	local came = {}
	local closed = {}
	local expanded = 0

	local function push(node)
		heap[#heap + 1] = node
		local i = #heap
		while i > 1 do
			local parent = math.floor(i / 2)
			if heap[parent].f <= heap[i].f then
				break
			end
			heap[parent], heap[i] = heap[i], heap[parent]
			i = parent
		end
	end

	local function pop()
		local top = heap[1]
		local last = heap[#heap]
		heap[#heap] = nil
		if #heap > 0 then
			heap[1] = last
			local i = 1
			while true do
				local l, r, smallest = i * 2, i * 2 + 1, i
				if heap[l] and heap[l].f < heap[smallest].f then
					smallest = l
				end
				if heap[r] and heap[r].f < heap[smallest].f then
					smallest = r
				end
				if smallest == i then
					break
				end
				heap[smallest], heap[i] = heap[i], heap[smallest]
				i = smallest
			end
		end
		return top
	end

	while #heap > 0 do
		local node = pop()
		local k = node.k
		if k == goalKey then
			local dirs = {}
			while came[k] do
				local from = came[k]
				table.insert(dirs, 1, from.dir)
				k = from.k
			end
			return dirs
		end
		if not closed[k] then
			closed[k] = true
			expanded = expanded + 1
			if expanded > MAX_PATH_NODES then
				return nil
			end
			local x, y = keyX(k), keyY(k)
			for _, d in ipairs(DIRS) do
				local nk = key(x + d.dx, y + d.dy)
				if set[nk] and not closed[nk] then
					local ng = g[k] + 1
					if not g[nk] or ng < g[nk] then
						g[nk] = ng
						came[nk] = { k = k, dir = d.dir }
						push({ f = ng + math.abs(x + d.dx - tx) + math.abs(y + d.dy - ty), k = nk })
					end
				end
			end
		end
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- Conversation
-- ---------------------------------------------------------------------------
local function rashidToday()
	return cfg.rashidCity[os.date("*t").wday] or "somewhere"
end

local function tipFor(player)
	local level = player:getLevel()
	local candidates = {}
	for _, tip in ipairs(cfg.tips) do
		if level >= tip.minLevel then
			local ok, isStarted = pcall(tip.started, player)
			if ok and not isStarted then
				candidates[#candidates + 1] = tip
			end
		end
	end
	if #candidates == 0 or math.random(100) <= 20 then
		return pick(cfg.serverTips)
	end
	-- The tips closest to the player's level come first.
	table.sort(candidates, function(a, b)
		return a.minLevel > b.minLevel
	end)
	return candidates[math.random(math.min(3, #candidates))].text
end

local function newsLine(walker)
	local options = {
		"Rashid is in " .. rashidToday() .. " today. He buys almost everything.",
	}
	if FamilyYasirCity then
		options[#options + 1] = "Yasir, the oriental trader, docked his ship in " .. FamilyYasirCity .. " today. He buys rare creature products."
	end
	-- Vendors: one line about the vendors in this city, one about a random
	-- vendor elsewhere (so Rashid and Yasir are still mentioned often).
	local here, elsewhere = {}, {}
	for _, kind in ipairs(cfg.vendorKinds) do
		for _, vendor in ipairs(vendorsByKind[kind.key] or {}) do
			if vendor.city then
				if walker.city and vendor.city.name == walker.city.name then
					if vendor ~= walker then
						here[#here + 1] = string.format("%s the %s", vendor.name, kind.title)
					end
				else
					elsewhere[#elsewhere + 1] = string.format("%s the %s is in %s today.", vendor.name, kind.title, vendor.city.name)
				end
			end
		end
	end
	if #here > 0 then
		options[#options + 1] = "Here in " .. walker.city.name .. " today: " .. table.concat(here, ", ") .. "."
	end
	if #elsewhere > 0 then
		options[#options + 1] = pick(elsewhere)
	end
	local cityLines = walker.city and cfg.cityChatter[walker.city.name]
	if cityLines then
		options[#options + 1] = pick(cityLines)
	end
	return pick(options)
end

local function chatterLine(walker)
	local line = pick(cfg.chatter)
	if walker.city and math.random(100) <= 30 and cfg.cityChatter[walker.city.name] then
		line = pick(cfg.cityChatter[walker.city.name])
	end
	return (line:gsub("{city}", walker.city and walker.city.name or "town"))
end

-- ---------------------------------------------------------------------------
-- NPC types
-- ---------------------------------------------------------------------------
local function randomOutfit(female)
	return {
		lookType = pick(female and cfg.femaleOutfits or cfg.maleOutfits),
		lookHead = math.random(0, 132),
		lookBody = math.random(0, 132),
		lookLegs = math.random(0, 132),
		lookFeet = math.random(0, 132),
		lookAddons = math.random(0, 3),
	}
end

local function buildShop(kind)
	local shop = {}
	local function addRandom(list, count)
		local copy = {}
		for i, item in ipairs(list) do
			copy[i] = item
		end
		for i = #copy, 2, -1 do
			local j = math.random(i)
			copy[i], copy[j] = copy[j], copy[i]
		end
		for i = 1, math.min(count, #copy) do
			shop[#shop + 1] = copy[i]
		end
	end
	if kind.always then
		for _, item in ipairs(FamilyCityLifeStock[kind.always]) do
			shop[#shop + 1] = item
		end
		addRandom(FamilyCityLifeStock[kind.randomFrom], kind.randomCount)
	else
		addRandom(FamilyCityLifeStock[kind.stock], kind.randomCount)
	end
	table.sort(shop, function(a, b)
		return a.itemName < b.itemName
	end)
	return shop
end

local function createType(walker)
	local npcType = Game.createNpcType(walker.name)
	local npcConfig = {
		name = walker.name,
		description = walker.name,
		health = 100,
		maxHealth = 100,
		walkInterval = 0, -- the engine below moves them, not the built-in random walk
		walkRadius = 0,
		speed = NPC_SPEED,
		outfit = randomOutfit(walker.female),
		flags = { floorchange = false },
	}

	local keywordHandler = KeywordHandler:new()
	local npcHandler = NpcHandler:new(keywordHandler)

	if walker.kind then
		npcConfig.shop = buildShop(walker.kind)
		npcConfig.speechBubble = SPEECHBUBBLE_TRADE
		walker.shopSize = #npcConfig.shop
		npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
			npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
		end
		npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost)
			player:sendTextMessage(MESSAGE_TRADE, string.format("Sold %ix %s for %i gold.", amount, name, totalCost))
		end
		npcType.onCheckItem = function(npc, player, clientId, subType) end
	end

	npcType.onThink = function(npc, interval)
		npcHandler:onThink(npc, interval)
	end
	npcType.onAppear = function(npc, creature)
		npcHandler:onAppear(npc, creature)
	end
	npcType.onDisappear = function(npc, creature)
		npcHandler:onDisappear(npc, creature)
	end
	npcType.onMove = function(npc, creature, fromPosition, toPosition)
		npcHandler:onMove(npc, creature, fromPosition, toPosition)
	end
	npcType.onSay = function(npc, creature, type, message)
		npcHandler:onSay(npc, creature, type, message)
	end
	npcType.onCloseChannel = function(npc, creature)
		npcHandler:onCloseChannel(npc, creature)
	end

	-- Stand still while someone talks to us.
	npcHandler:setCallback(CALLBACK_SET_INTERACTION, function(npc, player)
		walker.talkers = walker.talkers + 1
		walker.talkUntil = tick + ticksFromSeconds(240)
		return true
	end)
	npcHandler:setCallback(CALLBACK_REMOVE_INTERACTION, function(npc, player)
		walker.talkers = math.max(0, walker.talkers - 1)
		return true
	end)

	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not player or not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		if MsgContains(message, "tip") or MsgContains(message, "quest") or MsgContains(message, "hint") or MsgContains(message, "adventure") then
			npcHandler:say(tipFor(player), npc, creature)
		elseif MsgContains(message, "news") or MsgContains(message, "rumour") or MsgContains(message, "rumor") or MsgContains(message, "gossip") then
			npcHandler:say(newsLine(walker), npc, creature)
		elseif MsgContains(message, "job") or MsgContains(message, "occupation") then
			if walker.kind then
				npcHandler:say("I'm a travelling " .. walker.kind.title .. ". Want to {trade}?", npc, creature)
			else
				npcHandler:say(walker.job, npc, creature)
			end
		elseif MsgContains(message, "name") then
			npcHandler:say("I'm " .. walker.name .. ". Nice to meet you!", npc, creature)
		end
		return true
	end)

	if walker.kind then
		npcHandler:setMessage(MESSAGE_GREET, "Hello, |PLAYERNAME|! " .. walker.kind.greeting)
		npcHandler:setMessage(MESSAGE_SENDTRADE, "Take a look. Today's stock, fresh from the ship!")
	else
		npcHandler:setMessage(MESSAGE_GREET, pick({
			"Hello, |PLAYERNAME|! Want a {tip} for an adventure, or the latest {news}?",
			"Oh, hi |PLAYERNAME|. Ask me for a {tip} or some {news}.",
			"Greetings, |PLAYERNAME|! I know a few stories. Ask for a {tip}!",
		}))
	end
	npcHandler:setMessage(MESSAGE_FAREWELL, "Good luck out there, |PLAYERNAME|!")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "Bye then!")
	npcHandler:addModule(FocusModule:new(), walker.name, true, true, true)

	npcType:register(npcConfig)
end

-- ---------------------------------------------------------------------------
-- Spawning and movement
-- ---------------------------------------------------------------------------
local function spawnAt(walker, k, state)
	local npc = Game.createNpc(walker.name, Position(keyX(k), keyY(k), state.z), true)
	if not npc then
		return false
	end
	walker.npcId = npc:getId()
	walker.state = "idle"
	walker.waitUntil = tick + ticksFromSeconds(math.random(1, 20))
	walker.path = nil
	return true
end

local function playerNearby(npc)
	return #Game.getSpectators(npc:getPosition(), false, true, 7, 7, 5, 5) > 0
end

local function startWalk(walker, npc, targetKey)
	local pos = npc:getPosition()
	local path = findPath(walker.state_city, pos.x, pos.y, keyX(targetKey), keyY(targetKey))
	if not path or #path == 0 then
		walker.state = "idle"
		walker.waitUntil = tick + ticksFromSeconds(3)
		return
	end
	walker.path = path
	walker.step = 1
	walker.blocked = 0
	walker.state = "walking"
	walker.nextStepAt = tick
end

local function chooseNext(walker, npc)
	local state = walker.state_city
	walker.sailAfter = false
	if walker.kind then
		local home = walker.home
		local candidates = {}
		for _ = 1, 20 do
			local k = pick(state.open)
			if math.max(math.abs(keyX(k) - keyX(home)), math.abs(keyY(k) - keyY(home))) <= 10 then
				candidates[#candidates + 1] = k
			end
		end
		return startWalk(walker, npc, #candidates > 0 and pick(candidates) or home)
	end
	if state.dockKey and math.random() < cfg.travelChance then
		local destinations = {}
		for _, other in ipairs(cityStates) do
			if other.dockArea and other.dockArea ~= state then
				destinations[#destinations + 1] = other.dockArea
			end
		end
		if #destinations > 0 then
			walker.sailAfter = true
			walker.sailTo = pick(destinations)
			return startWalk(walker, npc, state.dockKey)
		end
	end
	return startWalk(walker, npc, pick(state.open))
end

local function sail(walker, npc)
	local pos = npc:getPosition()
	pos:sendMagicEffect(CONST_ME_TELEPORT)
	npc:remove()
	walker.npcId = nil
	walker.state = "sailing"
	walker.arriveAt = tick + ticksFromSeconds(randomRange(cfg.travelMinutes) * 60)
	walker.state_city = walker.sailTo
	walker.city = walker.sailTo.city
	walker.travels = (walker.travels or 0) + 1
end

local function arrive(walker)
	local state = walker.state_city
	if spawnAt(walker, state.dockKey, state) then
		local npc = Npc(walker.npcId)
		if npc then
			npc:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		end
	else
		walker.arriveAt = tick + ticksFromSeconds(30)
	end
end

local function stepWalker(walker, npc)
	local dir = walker.path[walker.step]
	local before = npc:getPosition()
	npc:move(dir)
	local after = npc:getPosition()
	if after.x ~= before.x or after.y ~= before.y then
		walker.step = walker.step + 1
		walker.blocked = 0
		if walker.step > #walker.path then
			walker.path = nil
			if walker.sailAfter then
				walker.sailAfter = false
				return sail(walker, npc)
			end
			walker.state = "idle"
			walker.waitUntil = tick + ticksFromSeconds(randomRange(cfg.idleSeconds) * (walker.kind and 2 or 1))
		end
	else
		walker.blocked = walker.blocked + 1
		if walker.blocked >= 4 then
			-- Someone stands in the way: give up this spot and pick another soon.
			walker.path = nil
			walker.state = "idle"
			walker.waitUntil = tick + ticksFromSeconds(2)
		end
	end
	walker.nextStepAt = tick + STEP_TICKS
end

local function update()
	tick = tick + 1
	for _, walker in ipairs(walkers) do
		if walker.state == "sailing" then
			if tick >= walker.arriveAt then
				arrive(walker)
			end
		else
			local npc = walker.npcId and Npc(walker.npcId)
			if not npc then
				-- Removed by something else: come back somewhere in the city.
				spawnAt(walker, pick(walker.state_city.open), walker.state_city)
			elseif walker.talkers > 0 and tick < walker.talkUntil then
				-- talking: stand still
			else
				walker.talkers = 0
				if tick >= walker.nextChatter then
					walker.nextChatter = tick + ticksFromSeconds(randomRange(cfg.chatterSeconds))
					if playerNearby(npc) then
						npc:say(chatterLine(walker), TALKTYPE_SAY)
					end
				end
				if walker.state == "idle" then
					if tick >= walker.waitUntil then
						chooseNext(walker, npc)
					end
				elseif walker.state == "walking" and tick >= walker.nextStepAt then
					stepWalker(walker, npc)
				end
			end
		end
	end
end

local function loop()
	local ok, err = pcall(update)
	if not ok then
		logger.error("[Family] city life update failed: {}", tostring(err))
	end
	addEvent(loop, TICK_MS)
end

-- ---------------------------------------------------------------------------
-- Startup
-- ---------------------------------------------------------------------------
local function namePool()
	local pool = {}
	for _, n in ipairs(cfg.maleNames) do
		pool[#pool + 1] = { name = n, female = false }
	end
	for _, n in ipairs(cfg.femaleNames) do
		pool[#pool + 1] = { name = n, female = true }
	end
	for i = #pool, 2, -1 do
		local j = math.random(i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local index = 0
	return function()
		while index < #pool do
			index = index + 1
			local entry = pool[index]
			-- Skip names already used by a real NPC. NpcType(name) creates an
			-- empty type when the name is free; a real NPC already has an outfit.
			local existing = NpcType(entry.name)
			local outfit = existing and existing:outfit()
			if not outfit or ((outfit.lookType or 0) == 0 and (outfit.lookTypeEx or 0) == 0) then
				return entry
			end
		end
		return nil
	end
end

local function newWalker(entry, kind)
	return {
		name = entry.name,
		female = entry.female,
		kind = kind,
		job = pick(cfg.jobs),
		talkers = 0,
		talkUntil = 0,
		nextChatter = ticksFromSeconds(math.random(10, 120)),
	}
end

local cityLife = GlobalEvent("FamilyCityLife")

function cityLife.onStartup()
	local nextName = namePool()
	local total, travelPorts = 0, 0

	for _, city in ipairs(cfg.cities) do
		local entry = nextName()
		if not entry then
			break
		end
		local first = newWalker(entry, nil)
		createType(first)
		local probe = Game.createNpc(first.name, city.center, true)
		if not probe then
			logger.warn("[Family] city life: no free tile at the center of {}", city.name)
		else
			local cityState = buildCity(city, probe)
			if #cityState.areas == 0 then
				logger.warn("[Family] city life: no street area found around {}", city.name)
				probe:remove()
				goto continue
			end
			cityStates[#cityStates + 1] = cityState
			-- Move the first walker (it was used to test the tiles) into a street area.
			local firstArea = pickArea(cityState)
			local startKey = pick(firstArea.open)
			probe:teleportTo(Position(keyX(startKey), keyY(startKey), firstArea.z))
			first.npcId = probe:getId()
			first.city, first.state_city = city, firstArea
			first.state, first.waitUntil = "idle", ticksFromSeconds(5)
			walkers[#walkers + 1] = first
			total = total + 1
			for _ = 2, cfg.walkersPerCity do
				entry = nextName()
				if not entry then
					break
				end
				local walker = newWalker(entry, nil)
				local area = pickArea(cityState)
				walker.city, walker.state_city = city, area
				createType(walker)
				if spawnAt(walker, pick(area.open), area) then
					walkers[#walkers + 1] = walker
					total = total + 1
				end
			end
			if cityState.dockArea then
				travelPorts = travelPorts + 1
			end
			logger.info("[Family] city life: {} - {} street tiles in {} areas, harbour {} (closest street tile {} sqm from the captain)", city.name, cityState.streetTiles, #cityState.areas, cityState.dockArea and "yes" or "no", tostring(cityState.dockGap))
		end
		::continue::
	end

	-- Vendors: each in a random city, around a spot near the center. Vendors
	-- of one kind go to different cities, and the cities with the fewest
	-- vendors so far are filled first, so every city gets its share.
	local vendorCount = 0
	local vendorsInCity = {}
	for _, kind in ipairs(cfg.vendorKinds) do
		vendorsByKind[kind.key] = {}
		local cityOrder = {}
		for i, cityState in ipairs(cityStates) do
			cityOrder[i] = cityState
		end
		for i = #cityOrder, 2, -1 do
			local j = math.random(i)
			cityOrder[i], cityOrder[j] = cityOrder[j], cityOrder[i]
		end
		-- Stable after the shuffle: equal counts keep their random order.
		for i = 2, #cityOrder do
			local current, j = cityOrder[i], i - 1
			while j >= 1 and (vendorsInCity[cityOrder[j]] or 0) > (vendorsInCity[current] or 0) do
				cityOrder[j + 1] = cityOrder[j]
				j = j - 1
			end
			cityOrder[j + 1] = current
		end
		for n = 1, cfg.vendorsPerKind do
			local entry = nextName()
			local cityState = #cityOrder > 0 and cityOrder[(n - 1) % #cityOrder + 1]
			if cityState then
				vendorsInCity[cityState] = (vendorsInCity[cityState] or 0) + 1
			end
			local state = cityState and cityState.areas[1]
			if entry and state then
				local vendor = newWalker(entry, kind)
				vendor.city, vendor.state_city = state.city, state
				local near = {}
				for _, k in ipairs(state.open) do
					if math.max(math.abs(keyX(k) - state.city.center.x), math.abs(keyY(k) - state.city.center.y)) <= 15 then
						near[#near + 1] = k
					end
				end
				vendor.home = #near > 0 and pick(near) or pick(state.open)
				createType(vendor)
				if spawnAt(vendor, vendor.home, state) then
					walkers[#walkers + 1] = vendor
					table.insert(vendorsByKind[kind.key], vendor)
					vendorCount = vendorCount + 1
					logger.info("[Family] city life: {} the {} is in {} today ({} items)", vendor.name, kind.title, state.city.name, vendor.shopSize or 0)
				end
			end
		end
	end

	-- Extra plain walkers, one per city in turn (they took the place of the
	-- creature products traders on 2026-10-18).
	for n = 1, cfg.extraWalkers or 0 do
		local cityState = #cityStates > 0 and cityStates[(n - 1) % #cityStates + 1]
		local entry = cityState and nextName()
		if entry then
			local walker = newWalker(entry, nil)
			local area = pickArea(cityState)
			walker.city, walker.state_city = cityState.city, area
			createType(walker)
			if spawnAt(walker, pick(area.open), area) then
				walkers[#walkers + 1] = walker
				total = total + 1
			end
		end
	end

	logger.info("[Family] city life: {} walkers and {} vendors in {} cities ({} with ships)", total, vendorCount, #cityStates, travelPorts)
	if not started then
		started = true
		addEvent(loop, TICK_MS)
	end
	return true
end

cityLife:register()

-- For tests and the /citylife command.
cfg.internal = {
	walkers = walkers,
	cityStates = cityStates,
	tipFor = tipFor,
	newsLine = newsLine,
	getTick = function()
		return tick
	end,
}

-- ---------------------------------------------------------------------------
-- /citylife: status for the GOD account
-- ---------------------------------------------------------------------------
local cityLifeStatus = TalkAction("/citylife")

function cityLifeStatus.onSay(player, words, param)
	local perCity, sailing, talking = {}, 0, 0
	for _, walker in ipairs(walkers) do
		if walker.state == "sailing" then
			sailing = sailing + 1
		else
			perCity[walker.city.name] = (perCity[walker.city.name] or 0) + 1
		end
		if walker.talkers > 0 then
			talking = talking + 1
		end
	end
	local lines = { string.format("City life: %d NPCs, %d at sea, %d talking.", #walkers, sailing, talking) }
	for _, cityState in ipairs(cityStates) do
		lines[#lines + 1] = string.format("%s: %d here (%d street areas, ship: %s)", cityState.city.name, perCity[cityState.city.name] or 0, #cityState.areas, cityState.dockArea and "yes" or "no")
	end
	for _, kind in ipairs(cfg.vendorKinds) do
		for _, vendor in ipairs(vendorsByKind[kind.key] or {}) do
			lines[#lines + 1] = string.format("%s (%s) in %s", vendor.name, kind.title, vendor.city.name)
		end
	end
	player:showTextDialog(2817, table.concat(lines, "\n"))
	return true
end

cityLifeStatus:groupType("god")
cityLifeStatus:register()
