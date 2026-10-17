-- Gaia Family server: Cyclopedia map discovery (2026-10-17). Ours, not upstream.
--
-- Canary never answers the client's Cyclopedia map discovery, so the
-- "Start Discovering" button stayed disabled. This brings it to life, as in
-- real Tibia:
--   1. Cyclopedia > Map: click a subarea (e.g. Ankrahmun City) and press
--      "Start Discovering". The server picks FamilyDiscovery.pointsGenerated
--      points of interest in that subarea. A point appears on the map when you
--      come near it (within the screen; FamilyDiscovery.revealAll shows them all
--      at once) and is discovered when you walk next to it.
--   2. Find FamilyDiscovery.pointsNeeded (7) of them and the subarea is
--      discovered for good. Starting another subarea resets the points of the
--      one in progress (the client warns about it).
--   3. An area's percentage is its discovered subareas. At 30% the client shows
--      the area's NPCs, at 70% its passages, and at 100% you get the area's
--      achievement (e.g. "Elven Woods" for Ab'Dendriel).
--   4. The Measuring Tibia quest follows it (quest log); Charos in the
--      Adventurers' Guild gives the Discoverer outfit for 10 fully discovered
--      areas, its first addon for 15 and the second for 20 (data-otservbr-global
--      npc/charos.lua). The titles Dedicated Entrepreneur and Globetrotter come
--      at 10 and 20 areas.
--
-- Only the subareas the client can draw on the map can be selected (189, all on
-- the surface); areas count as complete when those are discovered. The data
-- (areas, subareas, candidate points) is in data/scripts/lib/
-- family_map_discovery_data.lua. Donations for an improved respawn rate are not
-- implemented (respawn is already doubled everywhere).
--
-- Packets (client 15.11): the client sends 0xDB (byte action 0 = start
-- discovering + u16 subarea; 1 = donate + u16 area + u32 gold), read by
-- data/modules/scripts/family/map_discovery.lua. The server sends 0xDD with
-- type 1 (area progress: per area u16 id, byte state 0-3, byte percent; then
-- the discovered subareas and the subareas that can be started) and type 5
-- (points of interest: u16 subarea, byte points needed, byte count, then per
-- point a position and byte 0 = not yet reached / 1 = reached).
--
-- Switch: FamilyDiscovery.enabled (false = upstream: nothing is sent and the
-- button stays disabled; progress is kept).

FamilyDiscovery = FamilyDiscovery or {}
local D = FamilyDiscovery

D.enabled = true
D.pointsGenerated = 10 -- points placed in a subarea
D.pointsNeeded = 7 -- points to find (fewer when a subarea has fewer places)
D.revealAll = false -- true = all points show on the map at once
D.revealRangeX = 8 -- a point shows on the map within this many squares (same floor)
D.revealRangeY = 6
D.reachRange = 2 -- a point is discovered within this many squares (same floor)
D.outfitAreas = { outfit = 10, addon1 = 15, addon2 = 20 }

local DISCOVERER_MALE = 1094
local DISCOVERER_FEMALE = 1095
local TITLE_HALF = 73 -- Dedicated Entrepreneur
local TITLE_ALL = 74 -- Globetrotter

local OPCODE_MAP_DATA = 0xDD
local MAP_DATA_AREAS = 1
local MAP_DATA_POINTS = 5

local data = FamilyDiscoveryData or { areas = {}, subareas = {} }

-- Areas that count for the quest (the 20 areas of the client's map).
local countedTotal = 0
for _, area in pairs(data.areas) do
	if area.counted and #area.subareas > 0 then
		countedTotal = countedTotal + 1
	end
end
D.countedTotal = countedTotal

-- ---------------------------------------------------------------------------
-- Per-character state (kept in the character's KV, cached while online)
-- ---------------------------------------------------------------------------
local cache = {} -- player id -> state

local function kvOf(player)
	return player:kv():scoped("family-discovery")
end

local function parseDone(text)
	local done = {}
	for id in tostring(text or ""):gmatch("%d+") do
		done[tonumber(id)] = true
	end
	return done
end

local function parsePoints(text)
	local points = {}
	for x, y, z, s in tostring(text or ""):gmatch("(%d+),(%d+),(%d+),(%d+)") do
		points[#points + 1] = { x = tonumber(x), y = tonumber(y), z = tonumber(z), state = tonumber(s) }
	end
	return points
end

local function stateOf(player)
	local id = player:getId()
	local state = cache[id]
	if not state then
		local kv = kvOf(player)
		state = {
			done = parseDone(kv:get("done")),
			active = tonumber(kv:get("active") or 0) or 0,
			needed = tonumber(kv:get("needed") or 0) or 0,
			points = parsePoints(kv:get("points")),
		}
		cache[id] = state
	end
	return state
end

local function save(player, state)
	local ids = {}
	for id in pairs(state.done) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	local parts = {}
	for _, p in ipairs(state.points) do
		parts[#parts + 1] = string.format("%d,%d,%d,%d", p.x, p.y, p.z, p.state)
	end
	local kv = kvOf(player)
	kv:set("done", table.concat(ids, ","))
	kv:set("active", state.active)
	kv:set("needed", state.needed)
	kv:set("points", table.concat(parts, ";"))
end

-- Drops the cached state (it is read again from the KV).
function D.forget(player)
	cache[player:getId()] = nil
end

-- ---------------------------------------------------------------------------
-- Progress
-- ---------------------------------------------------------------------------
-- Returns percent (0-100) and the client's unlock state (0-3) of an area.
function D.areaProgress(done, areaId)
	local area = data.areas[areaId]
	if not area or #area.subareas == 0 then
		return nil, 0
	end
	local found = 0
	for _, sid in ipairs(area.subareas) do
		if done[sid] then
			found = found + 1
		end
	end
	local percent = math.floor(found * 100 / #area.subareas)
	local unlock = percent >= 100 and 3 or percent >= 70 and 2 or percent >= 30 and 1 or 0
	return percent, unlock
end

function D.completedAreas(player)
	local done = stateOf(player).done
	local count = 0
	for areaId, area in pairs(data.areas) do
		if area.counted and D.areaProgress(done, areaId) == 100 then
			count = count + 1
		end
	end
	return count
end

function D.discoveredSubareas(player)
	local count = 0
	for _ in pairs(stateOf(player).done) do
		count = count + 1
	end
	return count
end

-- ---------------------------------------------------------------------------
-- Packets
-- ---------------------------------------------------------------------------
function D.sendAreas(player)
	if not D.enabled then
		return
	end
	local state = stateOf(player)
	local msg = NetworkMessage()
	msg:addByte(OPCODE_MAP_DATA)
	msg:addByte(MAP_DATA_AREAS)
	local areaIds = {}
	for areaId in pairs(data.areas) do
		areaIds[#areaIds + 1] = areaId
	end
	table.sort(areaIds)
	msg:addU16(#areaIds)
	for _, areaId in ipairs(areaIds) do
		local percent, unlock = D.areaProgress(state.done, areaId)
		msg:addU16(areaId)
		msg:addByte(unlock)
		msg:addByte(percent or 255) -- more than 100% = "not explorable" in the client
	end
	local done, open = {}, {}
	for sid in pairs(data.subareas) do
		if state.done[sid] then
			done[#done + 1] = sid
		else
			open[#open + 1] = sid
		end
	end
	table.sort(done)
	table.sort(open)
	msg:addU16(#done)
	for _, sid in ipairs(done) do
		msg:addU16(sid)
	end
	msg:addU16(#open)
	for _, sid in ipairs(open) do
		msg:addU16(sid)
	end
	msg:sendToPlayer(player)
end

function D.sendPoints(player)
	if not D.enabled then
		return
	end
	local state = stateOf(player)
	local shown = {}
	if state.active ~= 0 then
		for _, p in ipairs(state.points) do
			if p.state > 0 then
				shown[#shown + 1] = p
			end
		end
	end
	local msg = NetworkMessage()
	msg:addByte(OPCODE_MAP_DATA)
	msg:addByte(MAP_DATA_POINTS)
	msg:addU16(state.active)
	msg:addByte(state.active ~= 0 and state.needed or 0)
	msg:addByte(#shown)
	for _, p in ipairs(shown) do
		msg:addPosition(Position(p.x, p.y, p.z))
		msg:addByte(p.state == 2 and 1 or 0)
	end
	msg:sendToPlayer(player)
end

function D.sendAll(player)
	D.sendAreas(player)
	D.sendPoints(player)
end

-- ---------------------------------------------------------------------------
-- Quest log (Measuring Tibia)
-- ---------------------------------------------------------------------------
local function questStorages()
	local quest = Storage.Quest and Storage.Quest.U11_80 and Storage.Quest.U11_80.MeasuringTibia
	return quest
end

local function updateQuest(player, subareaDone)
	local q = questStorages()
	if not q or not q.Questline then
		return
	end
	if player:getStorageValue(q.Questline) < 1 then
		player:setStorageValue(q.Questline, 1)
	end
	if player:getStorageValue(q.SpeckOfLand) < 1 then
		player:setStorageValue(q.SpeckOfLand, 1)
	end
	if subareaDone and player:getStorageValue(q.SpeckOfLand) < 2 then
		player:setStorageValue(q.SpeckOfLand, 2)
	end
	local areas = D.completedAreas(player)
	if player:getStorageValue(q.WideWorld) < areas then
		player:setStorageValue(q.WideWorld, areas)
	end
end

-- ---------------------------------------------------------------------------
-- Starting and finding points
-- ---------------------------------------------------------------------------
local function say(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

function D.start(player, subareaId)
	if not D.enabled then
		return false
	end
	local sub = data.subareas[subareaId]
	if not sub then
		say(player, "This part of the map cannot be discovered.")
		return false
	end
	local state = stateOf(player)
	if state.done[subareaId] then
		say(player, string.format("You have already discovered %s.", sub.name))
		return false
	end
	-- pick the points among the candidates
	local pool = {}
	for _, p in ipairs(sub.points) do
		pool[#pool + 1] = p
	end
	local points = {}
	while #pool > 0 and #points < D.pointsGenerated do
		local p = table.remove(pool, math.random(#pool))
		points[#points + 1] = { x = p[1], y = p[2], z = p[3], state = D.revealAll and 1 or 0 }
	end
	state.active = subareaId
	state.points = points
	state.needed = math.min(D.pointsNeeded, #points)
	save(player, state)
	updateQuest(player, false)
	D.check(player)
	D.sendPoints(player)
	say(player, string.format("You started discovering %s. Find %d points of interest there: they appear on your map when you come near them.", sub.name, state.needed))
	return true
end

local function finish(player, state)
	local subareaId = state.active
	local sub = data.subareas[subareaId]
	local areaId = sub and sub.area
	local before = areaId and D.areaProgress(state.done, areaId) or 0
	state.done[subareaId] = true
	state.active = 0
	state.points = {}
	state.needed = 0
	save(player, state)
	local after = areaId and D.areaProgress(state.done, areaId) or 0
	say(player, string.format("You have discovered %s!", sub and sub.name or "this subarea"))
	local area = areaId and data.areas[areaId]
	if area and before < 100 and after == 100 then
		say(player, string.format("You have fully discovered %s!", area.name))
		if area.achievement then
			player:addAchievement(area.achievement)
		end
	elseif area and after > before then
		say(player, string.format("%s: %d%% discovered.", area.name, after))
	end
	updateQuest(player, true)
	local areas = D.completedAreas(player)
	if areas >= math.ceil(countedTotal / 2) then
		player:addTitle(TITLE_HALF)
	end
	if countedTotal > 0 and areas >= countedTotal then
		player:addTitle(TITLE_ALL)
	end
	D.sendAll(player)
end

-- Called about once a second while the character is online.
function D.check(player)
	local state = stateOf(player)
	if state.active == 0 or #state.points == 0 then
		return
	end
	local pos = player:getPosition()
	local changed, reached = false, 0
	for _, p in ipairs(state.points) do
		if p.state < 2 and p.z == pos.z then
			local dx, dy = math.abs(p.x - pos.x), math.abs(p.y - pos.y)
			if math.max(dx, dy) <= D.reachRange then
				p.state = 2
				changed = true
				Position(p.x, p.y, p.z):sendMagicEffect(CONST_ME_TREASURE_MAP)
			elseif p.state == 0 and dx <= D.revealRangeX and dy <= D.revealRangeY then
				p.state = 1
				changed = true
			end
		end
		if p.state == 2 then
			reached = reached + 1
		end
	end
	if not changed then
		return
	end
	if reached >= state.needed then
		finish(player, state)
		return
	end
	save(player, state)
	D.sendPoints(player)
end

-- Client action (packet 0xDB), from data/modules/scripts/family/map_discovery.lua.
function D.onClientAction(player, action, id, amount)
	if not D.enabled then
		return
	end
	if action == 0 then
		D.start(player, id)
	elseif action == 1 then
		say(player, "Donations for an improved respawn rate are not available on this server: respawn is already faster everywhere.")
	end
end

-- ---------------------------------------------------------------------------
-- Rewards (used by Charos)
-- ---------------------------------------------------------------------------
-- Gives every Discoverer reward the character has earned. Returns a list of
-- what was given (empty when nothing new).
function D.giveOutfitRewards(player)
	local areas = D.completedAreas(player)
	local given = {}
	if areas >= D.outfitAreas.outfit and not player:hasOutfit(DISCOVERER_MALE) and not player:hasOutfit(DISCOVERER_FEMALE) then
		player:addOutfit(DISCOVERER_MALE)
		player:addOutfit(DISCOVERER_FEMALE)
		player:addAchievement("Widely Travelled")
		given[#given + 1] = "the Discoverer outfit"
	end
	if areas >= D.outfitAreas.addon1 and not player:hasOutfit(DISCOVERER_MALE, 1) and not player:hasOutfit(DISCOVERER_FEMALE, 1) then
		player:addOutfitAddon(DISCOVERER_MALE, 1)
		player:addOutfitAddon(DISCOVERER_FEMALE, 1)
		given[#given + 1] = "the first Discoverer addon"
	end
	if areas >= D.outfitAreas.addon2 and not player:hasOutfit(DISCOVERER_MALE, 2) and not player:hasOutfit(DISCOVERER_FEMALE, 2) then
		player:addOutfitAddon(DISCOVERER_MALE, 2)
		player:addOutfitAddon(DISCOVERER_FEMALE, 2)
		player:addAchievement("Measuring the World")
		given[#given + 1] = "the second Discoverer addon"
	end
	if #given > 0 then
		player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
	end
	return given, areas
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local login = CreatureEvent("FamilyMapDiscoveryLogin")

function login.onLogin(player)
	cache[player:getId()] = nil
	if D.enabled then
		local playerId = player:getId()
		addEvent(function()
			local p = Player(playerId)
			if p then
				D.sendAll(p)
			end
		end, 1000)
	end
	return true
end

login:register()

local logout = CreatureEvent("FamilyMapDiscoveryLogout")

function logout.onLogout(player)
	cache[player:getId()] = nil
	return true
end

logout:register()

local think = EventCallback("FamilyMapDiscoveryThink")

function think.playerOnThink(player, interval)
	if D.enabled then
		D.check(player)
	end
end

think:register()

local report = GlobalEvent("FamilyMapDiscoveryReport")

function report.onStartup()
	local subareas = 0
	for _ in pairs(data.subareas) do
		subareas = subareas + 1
	end
	logger.info("[Family] map discovery: {} ({} subareas, {} areas counted; {} of {} points needed, reveal all: {})", D.enabled and "on" or "off", subareas, countedTotal, D.pointsNeeded, D.pointsGenerated, tostring(D.revealAll))
	return true
end

report:register()
