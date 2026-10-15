-- Gaia Family server: rare creatures come back often (2026-10-12).
--
-- This file is ours (not upstream). Three sources of rare creatures exist:
--
-- 1. Raids written in Lua (data-otservbr-global/scripts/raids): rare bosses
--    and creatures such as Midnight Panther, Draptor, Undead Cavebear, Yeti,
--    The Old Widow, Tyrn, White Pale... Upstream they need 2-3 active players
--    (so they never started here) and have about a 2% chance per day. Here
--    they take turns: one raid starts at a time, at least
--    Family.rareRaidGapMinutes after the previous one (any raid), picked at
--    random among those ready. A raid is ready with one player online,
--    Family.rareCreatureMinutes after its own last start, once the creatures
--    of its previous run are dead. (Until 2026-10-14 there was no shared gap,
--    so at every server start nearly all 19 began within about 10 minutes.)
-- 2. Classic XML raids (data-otservbr-global/raids/raids.xml): one raid at a
--    time; the "margin" there (minutes between raids) is capped at 30 (FAMILY:
--    edit in that file).
-- 3. Rare map spawns with very long respawn times: capped in
--    data-otservbr-global/world/otservbr-monster.xml (FAMILY: edit, see
--    FAMILY.md).

Family = Family or {}

-- Minutes between two runs of the same Lua raid. Set to false for upstream rules.
Family.rareCreatureMinutes = 30

-- Minutes between two rare raid starts, whichever raids they are (shared by
-- all of them; chosen by Rodrigo on 2026-10-14).
Family.rareRaidGapMinutes = 15

-- Once the shared gap has passed, each 1-minute check starts a raid with this
-- chance, so starts don't fall on an exact clock (about 1 minute extra on
-- average).
local START_CHANCE_PER_CHECK = 0.5

-- The last start is kept across restarts, so a restart doesn't skip the gap.
local queueKv = kv.scoped("family-rare-raids")

-- Raids that keep the upstream rules (none for now; add a raid name such as
-- ["thais.rats"] = true to exclude it).
local keepUpstream = {}

local function isFamilyRaid(raid)
	return Family.rareCreatureMinutes and not keepUpstream[raid.name] and Raid.registry[raid.name] == raid
end

-- Remember the creatures each raid spawns, so it does not start again while
-- they are still alive (no piles of bosses nobody fought).
local originalSpawnMonsters = Encounter.spawnMonsters
function Encounter:spawnMonsters(config)
	if not isFamilyRaid(self) then
		return originalSpawnMonsters(self, config)
	end
	local raid = self
	raid.familySpawned = raid.familySpawned or {}
	local tracked = {}
	for key, value in pairs(config) do
		tracked[key] = value
	end
	local originalSpawn = config.spawn
	tracked.spawn = function(monster)
		raid.familySpawned[monster:getId()] = true
		if originalSpawn then
			return originalSpawn(monster)
		end
	end
	return originalSpawnMonsters(self, tracked)
end

local function creaturesStillAlive(raid)
	if not raid.familySpawned then
		return false
	end
	local alive = false
	for id in pairs(raid.familySpawned) do
		if Monster(id) then
			alive = true
		else
			raid.familySpawned[id] = nil
		end
	end
	return alive
end

local originalCanStart = Raid.canStart
function Raid:canStart()
	if not isFamilyRaid(self) then
		return originalCanStart(self)
	end
	local lastOccurrence = self.kv:get("last-occurrence") or 0
	if os.time() - lastOccurrence < Family.rareCreatureMinutes * 60 then
		return false
	end
	if self.currentStage ~= Encounter.unstarted then
		if self.currentStage < #self.stages then
			return false -- still spawning its waves
		end
		-- Only the long wait of the last stage (often 24 h) is left: end it.
		self:reset()
	end
	if creaturesStillAlive(self) then
		return false
	end
	if self.allowedDays and not self:isAllowedDay() then
		return false
	end
	if self:getActivePlayerCount() < 1 then
		return false
	end
	-- Ready: join this minute's draw instead of starting at once. The draw
	-- below picks one of the ready raids after the check loop has run.
	Family.queueRareRaid(self)
	return false
end

local candidates = {}
local drawScheduled = false

local function draw()
	drawScheduled = false
	local ready = candidates
	candidates = {}
	if #ready == 0 then
		return
	end
	local last = queueKv:get("last-start") or 0
	if os.time() - last < Family.rareRaidGapMinutes * 60 then
		return
	end
	if math.random() >= START_CHANCE_PER_CHECK then
		return
	end
	local raid = ready[math.random(#ready)]
	queueKv:set("last-start", os.time())
	raid:tryStart(true)
end

function Family.queueRareRaid(raid)
	local last = queueKv:get("last-start") or 0
	if os.time() - last < Family.rareRaidGapMinutes * 60 then
		return
	end
	candidates[#candidates + 1] = raid
	if not drawScheduled then
		drawScheduled = true
		addEvent(draw, 0)
	end
end

local rareCreaturesReport = GlobalEvent("FamilyRareCreaturesReport")

function rareCreaturesReport.onStartup()
	local count = 0
	for _, raid in pairs(Raid.registry) do
		if isFamilyRaid(raid) then
			count = count + 1
		end
	end
	logger.info("[Family] rare creature raids: {}, one at a time, at least {} min apart (each again {} min after its last run, once its creatures are dead)", count, tostring(Family.rareRaidGapMinutes), tostring(Family.rareCreatureMinutes))
	return true
end

rareCreaturesReport:register()
