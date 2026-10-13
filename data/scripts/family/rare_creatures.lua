-- Gaia Family server: rare creatures come back often (2026-10-12).
--
-- This file is ours (not upstream). Three sources of rare creatures exist:
--
-- 1. Raids written in Lua (data-otservbr-global/scripts/raids): rare bosses
--    and creatures such as Midnight Panther, Draptor, Undead Cavebear, Yeti,
--    The Old Widow, Tyrn, White Pale... Upstream they need 2-3 active players
--    (so they never started here) and have about a 2% chance per day. Here
--    each one may start again RARE_CREATURE_MINUTES after its last start,
--    once the creatures of its previous run are dead, with one player online.
-- 2. Classic XML raids (data-otservbr-global/raids/raids.xml): one raid at a
--    time; the "margin" there (minutes between raids) is capped at 30 (FAMILY:
--    edit in that file).
-- 3. Rare map spawns with very long respawn times: capped in
--    data-otservbr-global/world/otservbr-monster.xml (FAMILY: edit, see
--    FAMILY.md).

Family = Family or {}

-- Minutes between two runs of the same Lua raid. Set to false for upstream rules.
Family.rareCreatureMinutes = 30

-- After the wait, each 1-minute check starts the raid with this chance, so the
-- raids don't all start at the same minute (about 5 minutes extra on average).
local START_CHANCE_PER_CHECK = 0.2

-- Raids that are not rare creatures and keep the upstream rules.
local keepUpstream = {
	["thais.rats"] = true,
}

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
	return math.random() < START_CHANCE_PER_CHECK
end

local rareCreaturesReport = GlobalEvent("FamilyRareCreaturesReport")

function rareCreaturesReport.onStartup()
	local count = 0
	for _, raid in pairs(Raid.registry) do
		if isFamilyRaid(raid) then
			count = count + 1
		end
	end
	logger.info("[Family] rare creature raids: {} (every {} min after the last one, once its creatures are dead)", count, tostring(Family.rareCreatureMinutes))
	return true
end

rareCreaturesReport:register()
