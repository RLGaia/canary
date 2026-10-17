-- Gaia Family server: Cyclopedia map discovery (2026-10-17). Ours, not upstream.
--
-- Canary never answers the client's Cyclopedia map discovery, so the
-- "Start Discovering" button stayed disabled. This brings it to life, as in
-- Tibia (including the 2026 changes to the discovery system):
--   1. Every subarea is active by itself: when you walk into a subarea you have
--      not discovered, FamilyDiscovery.pointsGenerated points of interest are
--      placed there (FamilyDiscovery.automatic; without it you press "Start
--      Discovering" in Cyclopedia > Map first). Each subarea keeps its own
--      progress. A point appears on the map when you come near it (within the
--      screen; FamilyDiscovery.revealAll shows them all at once) and is found
--      when you walk next to it. The map shows the points of the subarea you are
--      in. "Start Discovering" / "Reset points of interest" in the Cyclopedia
--      places new points in the selected subarea.
--   2. Find FamilyDiscovery.pointsNeeded (7) and the subarea is discovered for
--      good.
--   3. An area's percentage is its discovered subareas. At 30% the client shows
--      the area's NPCs, at 70% its passages, and at 100% you get the area's
--      achievement (e.g. "Elven Woods"), see its creatures on the map (unknown
--      ones in the Bestiary as silhouettes), get warned of raids there and
--      walk faster there (100 speed for one fully discovered area, +5 for each
--      more, up to 195 with all 20).
--   4. The Measuring Tibia quest follows it (quest log); Charos in the
--      Adventurers' Guild gives the Discoverer outfit for 10 fully discovered
--      areas, its first addon for 15 and the second for 20 (data-otservbr-global
--      npc/charos.lua). The titles Dedicated Entrepreneur and Globetrotter come
--      at 10 and 20 areas.
--
-- A subarea is the shape the client draws on the map, on every floor above and
-- below it, so points can be in mountains, buildings or caves (only the 189
-- subareas with a shape can be selected; the client has no shape for a few old
-- underground ones). Points are the real Tibia spots players have mapped
-- (TibiaMaps.io), when they can be walked to on our map, plus generated ones
-- where those are few. The data (areas, subareas, points, where each subarea
-- is, creatures) is in data/scripts/lib/family_map_discovery_data.lua.
-- Raid warnings come from the rare creature raids (data/scripts/family/
-- rare_creatures.lua announces them FamilyDiscovery.raidWarningMinutes ahead).
-- Donations for an improved respawn rate are not implemented (respawn is
-- already doubled everywhere).
--
-- Packets (client 15.11, see tools/family/map_discovery/README.md): the client
-- sends 0xDB (read by data/modules/scripts/family/map_discovery.lua); the
-- server sends 0xDD types 1 (areas), 2 (active raid), 3/4 (raid soon in an
-- area/subarea), 5 (points of interest) and 7 (creatures of subareas).
--
-- Switch: FamilyDiscovery.enabled (false = upstream: nothing is sent and the
-- button stays disabled; progress is kept).

FamilyDiscovery = FamilyDiscovery or {}
local D = FamilyDiscovery

D.enabled = true
D.automatic = true -- subareas start by themselves when you walk into them
D.pointsGenerated = 10 -- points placed in a subarea
D.pointsNeeded = 7 -- points to find (fewer when a subarea has fewer places)
D.revealAll = false -- true = all points show on the map at once
D.revealRangeX = 8 -- a point shows on the map within this many squares (same floor)
D.revealRangeY = 6
D.reachRange = 2 -- a point is found within this many squares (same floor)
D.outfitAreas = { outfit = 10, addon1 = 15, addon2 = 20 }
D.speedBonus = true -- extra speed inside fully discovered areas
D.speedBase = 100 -- with one fully discovered area
D.speedPerArea = 5 -- for each further one
D.speedMax = 195
D.raidWarnings = true -- warnings and raid markers for fully discovered areas
D.raidWarningMinutes = 60 -- rare raids are announced this long before they start

local DISCOVERER_MALE = 1094
local DISCOVERER_FEMALE = 1095
local TITLE_HALF = 73 -- Dedicated Entrepreneur
local TITLE_ALL = 74 -- Globetrotter

local OPCODE_MAP_DATA = 0xDD
local MAP_DATA_AREAS = 1
local MAP_DATA_ACTIVE_RAID = 2
local MAP_DATA_RAID_SOON_AREA = 3
local MAP_DATA_RAID_SOON_SUBAREA = 4
local MAP_DATA_POINTS = 5
local MAP_DATA_CREATURES = 7

local data = FamilyDiscoveryData or { areas = {}, subareas = {}, grid = {}, block = 4, creatures = {} }

-- Areas that count for the quest (the 20 areas of the client's map).
local countedTotal = 0
for _, area in pairs(data.areas) do
	if area.counted and #area.subareas > 0 then
		countedTotal = countedTotal + 1
	end
end
D.countedTotal = countedTotal

-- ---------------------------------------------------------------------------
-- Where is a position?
-- ---------------------------------------------------------------------------
-- Subarea id at a position (any floor), or nil.
function D.subareaAt(pos)
	local block = data.block or 4
	local row = data.grid and data.grid[math.floor(pos.y / block)]
	if not row then
		return nil
	end
	local bx = math.floor(pos.x / block)
	for i = 1, #row, 3 do
		if bx >= row[i] and bx <= row[i + 1] then
			return row[i + 2]
		end
	end
	return nil
end

-- ---------------------------------------------------------------------------
-- Per-character state (kept in the character's KV, cached while online)
-- ---------------------------------------------------------------------------
local cache = {} -- player id -> state

local function kvOf(player)
	return player:kv():scoped("family-discovery")
end

local function parseIds(text)
	local ids = {}
	for id in tostring(text or ""):gmatch("%d+") do
		ids[tonumber(id)] = true
	end
	return ids
end

local function parsePoints(text)
	local points = {}
	for x, y, z, s in tostring(text or ""):gmatch("(%d+),(%d+),(%d+),(%d+)") do
		points[#points + 1] = { x = tonumber(x), y = tonumber(y), z = tonumber(z), state = tonumber(s) }
	end
	return points
end

local function pointsText(points)
	local parts = {}
	for _, p in ipairs(points) do
		parts[#parts + 1] = string.format("%d,%d,%d,%d", p.x, p.y, p.z, p.state)
	end
	return table.concat(parts, ";")
end

local function idsText(set)
	local ids = {}
	for id in pairs(set) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return table.concat(ids, ",")
end

local function stateOf(player)
	local id = player:getId()
	local state = cache[id]
	if state then
		return state
	end
	local kv = kvOf(player)
	state = { done = parseIds(kv:get("done")), subs = {}, shown = 0, current = nil, speed = 0, block = nil }
	for sid in pairs(parseIds(kv:get("progress"))) do
		local text = kv:get("sub-" .. sid)
		if text then
			local needed, pts = tostring(text):match("^(%d+)|(.*)$")
			if needed then
				state.subs[sid] = { needed = tonumber(needed), points = parsePoints(pts) }
			end
		end
	end
	-- the first version kept a single subarea in "active"
	local old = tonumber(kv:get("active") or 0) or 0
	if old ~= 0 and not state.subs[old] and not state.done[old] then
		state.subs[old] = { needed = tonumber(kv:get("needed") or 0) or 0, points = parsePoints(kv:get("points")) }
		kv:set("active", 0)
		kv:set("progress", idsText(state.subs))
		kv:set("sub-" .. old, string.format("%d|%s", state.subs[old].needed, pointsText(state.subs[old].points)))
	end
	cache[id] = state
	return state
end

local function saveSub(player, state, sid)
	local kv = kvOf(player)
	local sub = state.subs[sid]
	if sub then
		kv:set("sub-" .. sid, string.format("%d|%s", sub.needed, pointsText(sub.points)))
	else
		kv:remove("sub-" .. sid)
	end
	kv:set("progress", idsText(state.subs))
end

local function saveDone(player, state)
	kvOf(player):set("done", idsText(state.done))
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

local function areaComplete(done, areaId)
	return D.areaProgress(done, areaId) == 100
end

function D.completedAreas(player)
	local done = stateOf(player).done
	local count = 0
	for areaId, area in pairs(data.areas) do
		if area.counted and areaComplete(done, areaId) then
			count = count + 1
		end
	end
	return count
end

function D.isAreaComplete(player, areaId)
	return areaComplete(stateOf(player).done, areaId)
end

function D.discoveredSubareas(player)
	local count = 0
	for _ in pairs(stateOf(player).done) do
		count = count + 1
	end
	return count
end

function D.speedFor(completed)
	if completed < 1 then
		return 0
	end
	return math.min(D.speedMax, D.speedBase + D.speedPerArea * (completed - 1))
end

-- ---------------------------------------------------------------------------
-- Packets
-- ---------------------------------------------------------------------------
local function newMessage(kind)
	local msg = NetworkMessage()
	msg:addByte(OPCODE_MAP_DATA)
	msg:addByte(kind)
	return msg
end

function D.sendAreas(player)
	if not D.enabled then
		return
	end
	local state = stateOf(player)
	local msg = newMessage(MAP_DATA_AREAS)
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

-- Points of interest of one subarea (0 = none).
function D.sendPoints(player, sid)
	if not D.enabled then
		return
	end
	local state = stateOf(player)
	sid = sid or state.shown or 0
	local sub = sid ~= 0 and state.subs[sid] or nil
	local shown = {}
	if sub then
		for _, p in ipairs(sub.points) do
			if p.state > 0 then
				shown[#shown + 1] = p
			end
		end
	end
	local msg = newMessage(MAP_DATA_POINTS)
	msg:addU16(sub and sid or 0)
	msg:addByte(sub and sub.needed or 0)
	msg:addByte(#shown)
	for _, p in ipairs(shown) do
		msg:addPosition(Position(p.x, p.y, p.z))
		msg:addByte(p.state == 2 and 1 or 0)
	end
	msg:sendToPlayer(player)
	state.shown = sub and sid or 0
end

-- Race ids of the creature names in the data (resolved at startup).
local raceOf = {}

local function resolveRaces()
	for _, list in pairs(data.creatures or {}) do
		for name in pairs(list) do
			if raceOf[name] == nil then
				local mType = MonsterType(name)
				raceOf[name] = mType and mType:raceId() or 0
			end
		end
	end
end

-- Creatures of the subareas of fully discovered areas.
function D.sendCreatures(player)
	if not D.enabled then
		return
	end
	local state = stateOf(player)
	local entries = {}
	for areaId, area in pairs(data.areas) do
		if areaComplete(state.done, areaId) then
			for _, sid in ipairs(area.subareas) do
				local races, seen = {}, {}
				for name, occurrence in pairs((data.creatures or {})[sid] or {}) do
					local race = raceOf[name] or 0
					if race > 0 and not seen[race] and #races < 255 then
						seen[race] = true
						races[#races + 1] = { race = race, occurrence = occurrence }
					end
				end
				if #races > 0 and #entries < 255 then
					table.sort(races, function(a, b)
						return a.race < b.race
					end)
					entries[#entries + 1] = { sid = sid, races = races }
				end
			end
		end
	end
	if #entries == 0 then
		return
	end
	local msg = newMessage(MAP_DATA_CREATURES)
	msg:addByte(#entries)
	for _, entry in ipairs(entries) do
		msg:addU16(entry.sid)
		msg:addByte(#entry.races)
		for _, r in ipairs(entry.races) do
			msg:addU16(r.race)
			msg:addByte(player:isMonsterBestiaryUnlocked(r.race) and 1 or 0)
			msg:addByte(r.occurrence)
		end
	end
	msg:sendToPlayer(player)
end

-- ---------------------------------------------------------------------------
-- Raids in fully discovered areas
-- ---------------------------------------------------------------------------
D.raids = D.raids or {} -- name -> { pos, sid, area, phase = "soon" / "active" }

local function sendRaidSoon(player, raid, on)
	local msg = newMessage(MAP_DATA_RAID_SOON_AREA)
	msg:addU16(raid.area)
	msg:addByte(on and 1 or 0)
	msg:sendToPlayer(player)
	msg = newMessage(MAP_DATA_RAID_SOON_SUBAREA)
	msg:addU16(raid.sid)
	msg:addByte(on and 1 or 0)
	msg:sendToPlayer(player)
end

local function sendRaidMarker(player, raid, on)
	local msg = newMessage(MAP_DATA_ACTIVE_RAID)
	msg:addPosition(raid.pos)
	msg:addByte(on and 0 or 1) -- 0 = add, 1 = remove
	msg:sendToPlayer(player)
end

local function forPlayersWhoKnow(raid, fn)
	for _, player in ipairs(Game.getPlayers()) do
		if D.isAreaComplete(player, raid.area) then
			fn(player)
		end
	end
end

local function raidPlace(raid)
	local sub = data.subareas[raid.sid]
	local area = data.areas[raid.area]
	return string.format("%s (%s)", sub and sub.name or "?", area and area.name or "?")
end

-- A rare raid will start at pos in about `minutes` minutes.
function D.raidAnnounced(name, pos, minutes)
	if not D.enabled or not D.raidWarnings or not pos then
		return
	end
	local sid = D.subareaAt(pos)
	local sub = sid and data.subareas[sid]
	if not sub then
		return
	end
	local raid = { pos = Position(pos.x, pos.y, pos.z), sid = sid, area = sub.area, phase = "soon" }
	D.raids[name] = raid
	forPlayersWhoKnow(raid, function(player)
		sendRaidSoon(player, raid, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Raid warning: in about %d minutes creatures will raid %s.", minutes, raidPlace(raid)))
	end)
end

function D.raidStarted(name)
	local raid = D.raids[name]
	if not raid then
		return
	end
	raid.phase = "active"
	raid.startedAt = os.time()
	forPlayersWhoKnow(raid, function(player)
		sendRaidSoon(player, raid, false)
		sendRaidMarker(player, raid, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("A raid has begun in %s.", raidPlace(raid)))
	end)
end

function D.raidEnded(name)
	local raid = D.raids[name]
	if not raid then
		return
	end
	D.raids[name] = nil
	forPlayersWhoKnow(raid, function(player)
		sendRaidSoon(player, raid, false)
		sendRaidMarker(player, raid, false)
	end)
end

local function sendRaids(player)
	for _, raid in pairs(D.raids) do
		if D.isAreaComplete(player, raid.area) then
			if raid.phase == "soon" then
				sendRaidSoon(player, raid, true)
			else
				sendRaidMarker(player, raid, true)
			end
		end
	end
end

function D.sendAll(player)
	D.sendAreas(player)
	D.sendCreatures(player)
	D.sendPoints(player)
	sendRaids(player)
end

-- ---------------------------------------------------------------------------
-- Quest log (Measuring Tibia)
-- ---------------------------------------------------------------------------
local function questStorages()
	return Storage.Quest and Storage.Quest.U11_80 and Storage.Quest.U11_80.MeasuringTibia
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

local function foundCount(sub)
	local found = 0
	for _, p in ipairs(sub.points) do
		if p.state == 2 then
			found = found + 1
		end
	end
	return found
end

-- Text of "A Speck of Land": progress of the subareas being discovered.
function D.speckText(player)
	local state = stateOf(player)
	local lines = {}
	local current = state.current and state.subs[state.current] and state.current or state.shown
	local function line(sid)
		local sub = state.subs[sid]
		local info = data.subareas[sid]
		return string.format("%s: %d of %d points of interest found.", info and info.name or "?", foundCount(sub), sub.needed)
	end
	if current and current ~= 0 and state.subs[current] then
		lines[#lines + 1] = "You are discovering " .. line(current)
	end
	local others = 0
	for sid in pairs(state.subs) do
		if sid ~= current then
			others = others + 1
		end
	end
	if others > 0 then
		lines[#lines + 1] = string.format("%d more subareas are partly discovered.", others)
	end
	lines[#lines + 1] = string.format("You have discovered %d subareas so far. %s", D.discoveredSubareas(player), D.automatic and "Walk into a subarea and points of interest appear on your map when you come near them: find 7 to discover it." or "Select a subarea in the Cyclopedia map and press \"Start Discovering\", then find 7 points of interest there.")
	return table.concat(lines, " ")
end

-- ---------------------------------------------------------------------------
-- Starting and finding points
-- ---------------------------------------------------------------------------
local function say(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

-- Places new points in a subarea (also used to reset them). Returns true when done.
local function placePoints(player, state, sid)
	local info = data.subareas[sid]
	local pool = {}
	for _, p in ipairs(info.points) do
		pool[#pool + 1] = p
	end
	local points = {}
	while #pool > 0 and #points < D.pointsGenerated do
		local p = table.remove(pool, math.random(#pool))
		points[#points + 1] = { x = p[1], y = p[2], z = p[3], state = D.revealAll and 1 or 0 }
	end
	state.subs[sid] = { needed = math.min(D.pointsNeeded, #points), points = points }
	saveSub(player, state, sid)
	updateQuest(player, false)
end

function D.start(player, sid)
	if not D.enabled then
		return false
	end
	local info = data.subareas[sid]
	if not info then
		say(player, "This part of the map cannot be discovered.")
		return false
	end
	local state = stateOf(player)
	if state.done[sid] then
		say(player, string.format("You have already discovered %s.", info.name))
		return false
	end
	local reset = state.subs[sid] ~= nil
	placePoints(player, state, sid)
	D.check(player)
	D.sendPoints(player, sid)
	say(player, string.format("%s %s. Find %d points of interest there: they appear on your map when you come near them.", reset and "New points of interest were placed in" or "You started discovering", info.name, state.subs[sid] and state.subs[sid].needed or 0))
	return true
end

local function updateSpeed(player, state)
	local want = 0
	if D.speedBonus and state.current then
		local info = data.subareas[state.current]
		local area = info and data.areas[info.area]
		if area and area.counted and areaComplete(state.done, info.area) then
			want = D.speedFor(D.completedAreas(player))
		end
	end
	if want ~= state.speed then
		player:changeSpeed(want - state.speed)
		state.speed = want
	end
end

local function finish(player, state, sid)
	local info = data.subareas[sid]
	local areaId = info and info.area
	local before = areaId and D.areaProgress(state.done, areaId) or 0
	local areasBefore = D.completedAreas(player)
	state.done[sid] = true
	state.subs[sid] = nil
	saveDone(player, state)
	saveSub(player, state, sid)
	local after = areaId and D.areaProgress(state.done, areaId) or 0
	say(player, string.format("You have discovered %s!", info and info.name or "this subarea"))
	local area = areaId and data.areas[areaId]
	if area and before < 100 and after == 100 then
		say(player, string.format("You have fully discovered %s! Its creatures now show on your map, you are warned of raids there and you walk faster there.", area.name))
		if area.achievement then
			player:addAchievement(area.achievement)
		end
	elseif area and after > before then
		say(player, string.format("%s: %d%% discovered.", area.name, after))
	end
	updateQuest(player, true)
	local areas = D.completedAreas(player)
	if areas > areasBefore and (areas == D.outfitAreas.outfit or areas == D.outfitAreas.addon1 or areas == D.outfitAreas.addon2) then
		say(player, string.format("Awesome! You have already discovered %d areas completely! Go and find Charos.", areas))
	end
	if areas >= math.ceil(countedTotal / 2) then
		player:addTitle(TITLE_HALF)
	end
	if countedTotal > 0 and areas >= countedTotal then
		player:addTitle(TITLE_ALL)
	end
	state.shown = 0
	D.sendAreas(player)
	if after == 100 then
		D.sendCreatures(player)
	end
	D.sendPoints(player, 0)
	updateSpeed(player, state)
end

-- Checks the points of one subarea against the player's position.
local function checkPoints(player, state, sid, pos)
	local sub = state.subs[sid]
	if not sub then
		return
	end
	local changed, reached, justReached = false, 0, false
	for _, p in ipairs(sub.points) do
		if p.state < 2 and p.z == pos.z then
			local dx, dy = math.abs(p.x - pos.x), math.abs(p.y - pos.y)
			if math.max(dx, dy) <= D.reachRange then
				p.state = 2
				changed = true
				justReached = true
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
	if reached >= sub.needed then
		finish(player, state, sid)
		return
	end
	saveSub(player, state, sid)
	if state.shown == sid or justReached then
		D.sendPoints(player, sid)
	end
end

-- Called about once a second while the character is online.
function D.check(player)
	local state = stateOf(player)
	local pos = player:getPosition()
	local sid = D.subareaAt(pos)
	if sid and not data.subareas[sid] then
		sid = nil
	end
	if sid ~= state.current then
		state.current = sid
		updateSpeed(player, state)
		if sid and not state.done[sid] and not state.subs[sid] and D.automatic then
			placePoints(player, state, sid)
		end
		if sid and state.subs[sid] and state.shown ~= sid then
			D.sendPoints(player, sid)
		end
	end
	-- points of every subarea in progress (a point near a border can be found
	-- from the neighbouring subarea)
	local ids = {}
	for id in pairs(state.subs) do
		ids[#ids + 1] = id
	end
	for _, id in ipairs(ids) do
		checkPoints(player, state, id, pos)
	end
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
-- Gives the Discoverer reward of one tier ("outfit", "addon1", "addon2") when
-- earned. Returns "given", "have" (already has it), "missing" (needs the
-- previous tier) or "few" (not enough areas), and the number of areas.
function D.giveOutfitTier(player, tier)
	local areas = D.completedAreas(player)
	local hasOutfit = player:hasOutfit(DISCOVERER_MALE) or player:hasOutfit(DISCOVERER_FEMALE)
	local hasAddon1 = player:hasOutfit(DISCOVERER_MALE, 1) or player:hasOutfit(DISCOVERER_FEMALE, 1)
	local hasAddon2 = player:hasOutfit(DISCOVERER_MALE, 2) or player:hasOutfit(DISCOVERER_FEMALE, 2)
	if areas < D.outfitAreas[tier] then
		return "few", areas
	end
	if tier == "outfit" then
		if hasOutfit then
			return "have", areas
		end
		player:addOutfit(DISCOVERER_MALE)
		player:addOutfit(DISCOVERER_FEMALE)
		player:addAchievement("Widely Travelled")
	elseif tier == "addon1" then
		if hasAddon1 then
			return "have", areas
		end
		if not hasOutfit then
			return "missing", areas
		end
		player:addOutfitAddon(DISCOVERER_MALE, 1)
		player:addOutfitAddon(DISCOVERER_FEMALE, 1)
	elseif tier == "addon2" then
		if hasAddon2 then
			return "have", areas
		end
		if not hasAddon1 then
			return "missing", areas
		end
		player:addOutfitAddon(DISCOVERER_MALE, 2)
		player:addOutfitAddon(DISCOVERER_FEMALE, 2)
		player:addAchievement("Measuring the World")
	end
	player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
	return "given", areas
end

-- Gives every Discoverer reward earned so far (list of what was given).
function D.giveOutfitRewards(player)
	local given = {}
	local names = { outfit = "the Discoverer outfit", addon1 = "the first Discoverer addon", addon2 = "the second Discoverer addon" }
	local areas = 0
	for _, tier in ipairs({ "outfit", "addon1", "addon2" }) do
		local result
		result, areas = D.giveOutfitTier(player, tier)
		if result == "given" then
			given[#given + 1] = names[tier]
		end
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
				D.check(p)
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
	resolveRaces()
	local subareas, races = 0, 0
	for _ in pairs(data.subareas) do
		subareas = subareas + 1
	end
	for _, race in pairs(raceOf) do
		if race > 0 then
			races = races + 1
		end
	end
	logger.info("[Family] map discovery: {} ({} subareas, {} areas counted; automatic {}, {} of {} points needed, reveal all {}, speed bonus {}, raid warnings {} min ahead, {} creature races)", D.enabled and "on" or "off", subareas, countedTotal, tostring(D.automatic), D.pointsNeeded, D.pointsGenerated, tostring(D.revealAll), tostring(D.speedBonus), D.raidWarnings and D.raidWarningMinutes or 0, races)
	return true
end

report:register()
