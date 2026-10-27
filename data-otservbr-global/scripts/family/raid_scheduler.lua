-- Gaia Family server: classic raids and rare bosses on timers counted in
-- hours of play (2026-10-27). Ours, not upstream.
--
-- Why: the classic XML raids (raids/raids.xml) are scheduled by the server
-- program, and in Canary v3.6.1 its chance formula is upside down
-- (src/lua/creature/raids.cpp, Raids::checkRaids: MAX_RAND_RANGE * interval /
-- 60 instead of MAX_RAND_RANGE * 60 / interval, and the product overflows).
-- Every raid wins its roll (Feroxa about half the time), so the raids ran in
-- the file's order, one about every 31 minutes, each once per server start.
-- With the 06:00 restart and a PC that is only on while playing, only the
-- first few (badgers, wolves, wasps, dragons...) ever happened: Orshabaal
-- needed 11 h of uptime, Morgaroth 15 h, Ghazbaran 25 h (impossible), and
-- Ferumbras is switched off upstream. The Ruthless Seven of the Pits of
-- Inferno came from a 13-hour timer (globalevents_pits_of_inferno_bosses.lua),
-- so they never came either.
--
-- Now (chosen by Rodrigo on 2026-10-27): this file starts the raids with
-- Game.startRaid. The built-in scheduler is kept idle by giving every raid in
-- raids.xml a margin of 71582 minutes (49.7 days, the largest value: the server
-- multiplies it by 60000 in 32 bits); the server restarts every day, so it
-- never reaches it. (disableLegacyRaids = true cannot be used: the server then
-- does not load the raids at all.)
-- * Bosses, in three groups by how rare they are in Tibia (community spawn
--   windows from kill statistics, TibiaDepot; TibiaWiki EN's Bosses Spawn
--   Frequency page for Gaz'haragoth, Ferumbras and the cavebear):
--     common    (Tibia 1-8 days)      about every 3 h of play
--     medium    (Tibia 1-4 weeks)     about every 8 h of play
--     legendary (Tibia ~5-6 months)   about every 20 h of play
--   Each wait is the group's hours +-25%, counted only in minutes with at
--   least one player online, and kept across restarts (KV), so a boss timer
--   keeps going from one session to the next. A boss does not come again
--   while the last one is still alive (nobody killed it).
-- * The other classic raids (creature invasions) in a random rotation: one
--   at a time, 30 minutes after the previous raid start, each again only
--   after 8 h of play.
-- The Lua raids (Midnight Panther, Tyrn, White Pale...) are not touched; see
-- rare_creatures.lua.
--
-- Switch: Family.raidScheduler (false = no classic raids at all, unless the
-- margins in raids.xml are set back to 30). GOD: /raidtimers shows the timers.

Family = Family or {}
Family.raidScheduler = true

FamilyRaids = FamilyRaids or {}
local R = FamilyRaids

-- Hours of play between two visits of a boss, per group.
R.groupHours = { common = 3, medium = 8, legendary = 20 }
-- Each wait is the group's hours times a random factor in 1 +- spread.
R.spread = 0.25
-- When a boss has no timer yet (first start with this file), its first wait
-- is this share of its group's hours up to the full hours, at random, so the
-- bosses do not all come together.
R.firstWaitShare = 0.1
-- Ordinary raids: one at a time, this many minutes of play after the
-- previous raid start (boss or not), each again after this many hours.
R.normalGapMinutes = 30
R.normalRepeatHours = 8
-- Two boss raids never start closer than this (minutes of play).
R.bossGapMinutes = 5
-- The newspaper names the bosses due within this many hours of play.
R.newsHours = 2

-- Classic raids by their raids.xml name; bosses = creatures whose being alive
-- keeps the raid from coming again. Groups for raids that the community
-- trackers do not list (Chayenne, Necropharus, The Horned Fox, Mad Mage)
-- follow their upstream interval: 1440 minutes = medium, less = common.
R.bossRaids = {
	-- legendary
	{ raid = "Orshabaal", group = "legendary", bosses = { "Orshabaal" } },
	{ raid = "Morgaroth", group = "legendary", bosses = { "Morgaroth" } },
	{ raid = "Ghazbaran", group = "legendary", bosses = { "Ghazbaran" } },
	{ raid = "Ferumbras", group = "legendary", bosses = { "Ferumbras" } },
	-- medium
	{ raid = "Chayenne", group = "medium", bosses = { "Chayenne" } },
	{ raid = "Necropharus", group = "medium", bosses = { "Necropharus" } },
	{ raid = "Feroxa", group = "medium", bosses = { "Feroxa" } },
	{ raid = "Zulazza the Corruptor", group = "medium", bosses = { "Zulazza the Corruptor", "Chizzoron the Distorter" } },
	{ raid = "Horned Fox", group = "medium", bosses = { "The Horned Fox" } },
	{ raid = "Gaz", group = "medium", bosses = { "Gaz'Haragoth" } },
	{ raid = "Omrafir", group = "medium", bosses = { "Omrafir" } },
	{ raid = "Ocyakao", group = "medium", bosses = { "Ocyakao" } },
	{ raid = "Zushuka", group = "medium", bosses = { "Zushuka" } },
	{ raid = "Fernfang", group = "medium", bosses = { "Fernfang" } },
	-- common
	{ raid = "Mad Mage", group = "common", bosses = { "Mad Mage" } },
	{ raid = "Zevelon Duskbringer", group = "common", bosses = { "Zevelon Duskbringer" } },
	{ raid = "Munster", group = "common", bosses = { "Munster" } },
	{ raid = "Rottie The Rotworm spidercave", group = "common", bosses = { "Rottie the Rotworm" } },
	{ raid = "Apprentice Sheng", group = "common", bosses = { "Apprentice Sheng" } },
	{ raid = "Teleskor", group = "common", bosses = { "Teleskor" } },
	{ raid = "Dharalion", group = "common", bosses = { "Dharalion" } },
}

-- The Ruthless Seven (Pits of Inferno, floor 15): no raid file, they just
-- appear (as in Tibia, no announcement). Positions from upstream's
-- globalevents_pits_of_inferno_bosses.lua, which is switched off while
-- Family.raidScheduler is on (FAMILY: edit there).
R.spawnBosses = {
	{ name = "Massacre", group = "medium", pos = Position(32876, 32270, 15) },
	{ name = "Dracola", group = "medium", pos = Position(32837, 32309, 15) },
	{ name = "The Imperor", group = "medium", pos = Position(32907, 32215, 15) },
	{ name = "Mr. Punish", group = "medium", pos = Position(32763, 32243, 15) },
	{ name = "Countess Sorrow", group = "medium", pos = Position(32802, 32333, 15) },
	{ name = "The Plasmother", group = "medium", pos = Position(32845, 32332, 15) },
	{ name = "The Handmaiden", group = "medium", pos = Position(32785, 32290, 15) },
}

local store = kv.scoped("family-raid-scheduler")

local entries = {} -- every boss (raid or spawn), with .key, .label, .group
local normalRaids = {} -- names of the other classic raids
local aliveIds = {} -- key -> { creature ids of its last visit }
local loaded = false

local function keyOf(text)
	return (text:lower():gsub("[^%w]+", "-"))
end

local function minutesOf(group)
	return (R.groupHours[group] or R.groupHours.medium) * 60
end

function R.uptime()
	return store:get("uptime") or 0
end

local function dataDir()
	return configManager.getString(configKeys.DATA_DIRECTORY)
end

local function readFile(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

-- Where and when a raid file puts each creature: name (lower case) ->
-- { pos, rangeX, rangeY, delay }.
local function readSpawns(file)
	local spawns = {}
	local content = readFile(dataDir() .. "/raids/" .. file)
	if not content then
		return spawns, 0
	end
	content = content:gsub("<!%-%-.-%-%->", "")
	local maxDelay = 0
	for attrs in content:gmatch("<singlespawn(.-)/>") do
		local name = attrs:match('name="([^"]+)"')
		local delay = tonumber(attrs:match('delay="(%d+)"')) or 0
		-- %s before x/y/z: 'delay="..."' ends in 'y="'.
		local x, y, z = tonumber(attrs:match('%sx="(%d+)"')), tonumber(attrs:match('%sy="(%d+)"')), tonumber(attrs:match('%sz="(%d+)"'))
		maxDelay = math.max(maxDelay, delay)
		if name and x then
			spawns[name:lower()] = { pos = Position(x, y, z), rangeX = 3, rangeY = 3, delay = delay }
		end
	end
	for attrs, body in content:gmatch("<areaspawn(.-)>(.-)</areaspawn>") do
		local delay = tonumber(attrs:match('delay="(%d+)"')) or 0
		local fx, fy, fz = tonumber(attrs:match('fromx="(%d+)"')), tonumber(attrs:match('fromy="(%d+)"')), tonumber(attrs:match('fromz="(%d+)"'))
		local tx, ty = tonumber(attrs:match('tox="(%d+)"')), tonumber(attrs:match('toy="(%d+)"'))
		maxDelay = math.max(maxDelay, delay)
		if fx and tx then
			for name in body:gmatch('<monster[^>]-name="([^"]+)"') do
				spawns[name:lower()] = {
					pos = Position(math.floor((fx + tx) / 2), math.floor((fy + ty) / 2), fz),
					rangeX = math.ceil((tx - fx) / 2) + 3,
					rangeY = math.ceil((ty - fy) / 2) + 3,
					delay = delay,
				}
			end
		end
	end
	return spawns, maxDelay
end

-- raids.xml entries that are not commented out: name -> file.
local function readRaidList()
	local list = {}
	local content = readFile(dataDir() .. "/raids/raids.xml")
	if not content then
		return list, {}
	end
	content = content:gsub("<!%-%-.-%-%->", "")
	local order = {}
	for attrs in content:gmatch("<raid%s(.-)/>") do
		local name, file = attrs:match('name="([^"]+)"'), attrs:match('file="([^"]+)"')
		if name and file then
			list[name] = file
			order[#order + 1] = name
		end
	end
	return list, order
end

local function load()
	entries, normalRaids = {}, {}
	local files, order = readRaidList()
	local isBoss = {}
	for _, def in ipairs(R.bossRaids) do
		isBoss[def.raid] = true
		if not files[def.raid] then
			logger.error("[Family] raid scheduler: raid {} is not in raids.xml", def.raid)
		else
			local spawns, maxDelay = readSpawns(files[def.raid])
			local where = {}
			for _, boss in ipairs(def.bosses) do
				if spawns[boss:lower()] then
					where[#where + 1] = { name = boss:lower(), spot = spawns[boss:lower()] }
				else
					logger.error("[Family] raid scheduler: {} is not spawned by {}", boss, files[def.raid])
				end
			end
			entries[#entries + 1] = {
				key = "raid-" .. keyOf(def.raid),
				raid = def.raid,
				label = def.bosses[1],
				group = def.group,
				where = where,
				maxDelay = maxDelay,
			}
		end
	end
	for _, def in ipairs(R.spawnBosses) do
		entries[#entries + 1] = { key = "spawn-" .. keyOf(def.name), spawn = def, label = def.name, group = def.group }
	end
	for _, name in ipairs(order) do
		if not isBoss[name] then
			normalRaids[#normalRaids + 1] = name
		end
	end
	loaded = true
end

local function ensureLoaded()
	if not loaded then
		load()
	end
end

local function nextDue(entry)
	return store:get("next." .. entry.key)
end

local function setNextDue(entry, first)
	local minutes = minutesOf(entry.group)
	local wait
	if first then
		wait = minutes * (R.firstWaitShare + math.random() * (1 - R.firstWaitShare))
	else
		wait = minutes * (1 - R.spread + math.random() * 2 * R.spread)
	end
	store:set("next." .. entry.key, R.uptime() + math.floor(wait + 0.5))
end

function R.isAlive(entry)
	for _, id in ipairs(aliveIds[entry.key] or {}) do
		local creature = Creature(id)
		if creature and not creature:isRemoved() and creature:getHealth() > 0 then
			return true
		end
	end
	return false
end

-- After a raid's last spawn, note its bosses (they are created by the server
-- program, so they are found by name around their spawn spot).
local function rememberRaidBosses(entry)
	local ids = {}
	for _, w in ipairs(entry.where) do
		local spectators = Game.getSpectators(w.spot.pos, false, false, w.spot.rangeX, w.spot.rangeX, w.spot.rangeY, w.spot.rangeY)
		for _, creature in ipairs(spectators) do
			if creature:isMonster() and not creature:getMaster() and creature:getName():lower() == w.name then
				ids[#ids + 1] = creature:getId()
			end
		end
	end
	aliveIds[entry.key] = ids
end

-- Starts a boss now. Returns true when it started.
function R.startEntry(entry)
	if entry.spawn then
		local monster = Game.createMonster(entry.spawn.name, entry.spawn.pos, true, true)
		if not monster then
			logger.error("[Family] raid scheduler: could not create {}", entry.spawn.name)
			return false
		end
		aliveIds[entry.key] = { monster:getId() }
		return true
	end
	-- Anything but RETURNVALUE_NOERROR means another raid is running (the raid
	-- itself was checked in raids.xml at load; the raid error codes are not
	-- exposed to Lua in v3.6.1).
	if Game.startRaid(entry.raid) ~= RETURNVALUE_NOERROR then
		return false
	end
	aliveIds[entry.key] = {}
	addEvent(rememberRaidBosses, entry.maxDelay + 3000, entry)
	return true
end

local function startNormal(name)
	return Game.startRaid(name) == RETURNVALUE_NOERROR
end

local function playersOnline()
	for _, player in ipairs(Game.getPlayers()) do
		if not player:getGroup():getAccess() then
			return true
		end
	end
	return false
end

-- One minute of play: count it and start what is due.
function R.tick()
	ensureLoaded()
	local uptime = R.uptime()
	for _, entry in ipairs(entries) do
		if not nextDue(entry) then
			setNextDue(entry, true)
		end
	end

	-- Bosses: the most overdue first.
	local lastBoss = store:get("last-boss-start") or -math.huge
	if uptime - lastBoss >= R.bossGapMinutes then
		local due = {}
		for _, entry in ipairs(entries) do
			if nextDue(entry) <= uptime and not R.isAlive(entry) then
				due[#due + 1] = entry
			end
		end
		table.sort(due, function(a, b)
			return nextDue(a) < nextDue(b)
		end)
		for _, entry in ipairs(due) do
			if R.startEntry(entry) then
				setNextDue(entry, false)
				store:set("last-boss-start", uptime)
				if entry.raid then
					store:set("last-start", uptime)
				end
				logger.info("[Family] raid scheduler: {} ({}) at {} min of play", entry.label, entry.group, uptime)
				return
			end
			if entry.raid then
				break -- another raid is running: try again next minute
			end
		end
	end

	-- Ordinary raids.
	local lastStart = store:get("last-start") or -math.huge
	if uptime - lastStart < R.normalGapMinutes then
		return
	end
	local ready = {}
	for _, name in ipairs(normalRaids) do
		local last = store:get("normal." .. keyOf(name))
		if not last or uptime - last >= R.normalRepeatHours * 60 then
			ready[#ready + 1] = name
		end
	end
	if #ready == 0 then
		return
	end
	local name = ready[math.random(#ready)]
	if startNormal(name) then
		store:set("normal." .. keyOf(name), uptime)
		store:set("last-start", uptime)
	end
end

-- For the newspaper: bosses due within R.newsHours of play, and bosses still
-- alive from their last visit.
function R.news()
	ensureLoaded()
	local soon, roaming = {}, {}
	local uptime = R.uptime()
	for _, entry in ipairs(entries) do
		local due = nextDue(entry)
		if R.isAlive(entry) then
			roaming[#roaming + 1] = entry.label
		elseif due and due - uptime <= R.newsHours * 60 then
			soon[#soon + 1] = entry.label
		end
	end
	table.sort(soon)
	table.sort(roaming)
	return soon, roaming
end

function R.entries()
	ensureLoaded()
	return entries
end

function R.normalRaids()
	ensureLoaded()
	return normalRaids
end

local minute = GlobalEvent("FamilyRaidScheduler")

function minute.onThink(interval)
	if not Family.raidScheduler then
		return true
	end
	if not playersOnline() then
		return true
	end
	store:set("uptime", R.uptime() + 1)
	R.tick()
	return true
end

minute:interval(60 * 1000)
minute:register()

local startup = GlobalEvent("FamilyRaidSchedulerStartup")

function startup.onStartup()
	load()
	if not Family.raidScheduler then
		logger.info("[Family] raid scheduler: off")
		return true
	end
	if configManager.getBoolean(configKeys.DISABLE_LEGACY_RAIDS) then
		logger.error("[Family] raid scheduler: disableLegacyRaids is true, so the server loaded no raids; set it to false")
	end
	local content = readFile(dataDir() .. "/raids/raids.xml") or ""
	content = content:gsub("<!%-%-.-%-%->", "")
	local short = 0
	for margin in content:gmatch('margin="(%d+)"') do
		if tonumber(margin) < 1440 then
			short = short + 1
		end
	end
	if short > 0 then
		logger.warn("[Family] raid scheduler: {} raids in raids.xml have a margin under 1440, so the server's own scheduler may start them too", short)
	end
	local counts = { common = 0, medium = 0, legendary = 0 }
	for _, entry in ipairs(entries) do
		counts[entry.group] = (counts[entry.group] or 0) + 1
	end
	logger.info(
		"[Family] raid scheduler: on, {} hours of play so far; bosses every {}/{}/{} h (common {}, medium {}, legendary {}); {} other raids, one every {} min",
		string.format("%.1f", R.uptime() / 60),
		R.groupHours.common,
		R.groupHours.medium,
		R.groupHours.legendary,
		counts.common,
		counts.medium,
		counts.legendary,
		#normalRaids,
		R.normalGapMinutes
	)
	return true
end

startup:register()

local status = TalkAction("/raidtimers")

function status.onSay(player, words, param)
	ensureLoaded()
	local uptime = R.uptime()
	local lines = { string.format("Raid scheduler %s. Hours of play: %.1f", Family.raidScheduler and "on" or "off", uptime / 60) }
	local sorted = {}
	for _, entry in ipairs(entries) do
		sorted[#sorted + 1] = entry
	end
	table.sort(sorted, function(a, b)
		return (nextDue(a) or 0) < (nextDue(b) or 0)
	end)
	for _, entry in ipairs(sorted) do
		local due = nextDue(entry)
		local text
		if R.isAlive(entry) then
			text = "alive"
		elseif not due then
			text = "no timer yet"
		elseif due <= uptime then
			text = "due"
		else
			text = string.format("in %.1f h of play", (due - uptime) / 60)
		end
		lines[#lines + 1] = string.format("%s (%s): %s", entry.label, entry.group, text)
	end
	player:showTextDialog(2821, table.concat(lines, "\n"))
	return false
end

status:separator(" ")
status:groupType("god")
status:register()
