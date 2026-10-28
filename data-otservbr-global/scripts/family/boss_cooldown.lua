-- Gaia Family server: boss cooldowns end at midnight (2026-10-28; from
-- 2026-10-17 to 2026-10-28 there was no boss cooldown at all). Ours, not
-- upstream.
--
-- Chosen by Rodrigo on 2026-10-28 (no cooldown could flood the economy, even
-- for two players): every boss wait ends at the next midnight (00:00 on the
-- server PC's clock), or earlier when the boss's own Tibia cooldown is
-- shorter. A boss killed at 23:00 can be fought again at 00:00; one killed at
-- 10:00 also at 00:00 (Tibia: 20 h later, 06:00 the next day). The Bosstiary
-- and the lever messages show the time left until then.
-- Three mechanisms are covered:
--   1. The general boss cooldown (Bosstiary, boss levers and most boss
--      rooms): bossDefaultTimeToFightAgain is Tibia's 20 h again
--      (family/config.family.lua), levers keep their own times
--      (data/scripts/family/solo_balance.lua no longer caps them), and
--      Player:setBossCooldown here moves any end time to the next midnight
--      at most.
--   2. Older quests that keep the wait in a character storage instead (Prince
--      Drazzak, Grave Danger, Forgotten Knowledge, the Dream Courts, Brokul,
--      the First Dragon): writing a future time to those storages stores the
--      next midnight at most. The Last Lore Keeper (14 days in Tibia) is
--      daily too.
--      Also the Secret Library bosses with their own 20 h timers (Raxias,
--      the three asura bosses, the Furious Scorpion) and Yakchal's
--      server-wide 24 h (added the same day: "every boss").
--   3. Daily tasks that read the boss default (Commander Stone's four
--      Bigfoot's Burden tasks, the Bigfoot mouthpiece, Rottin Wood and the
--      Married Men): the same midnight rule, so they do not jump from free to
--      20 h when the default went back to 20 h.
-- Boss rooms that are still occupied stay closed until the fight is over, as
-- upstream.
--
-- Switch: Family.bossCooldownMode = "midnight" (this), "tibia" (each boss's
-- own cooldown) or "none" (no wait, as from 2026-10-17 to 2026-10-28).

Family = Family or {}
Family.bossCooldownMode = "midnight"

-- The next 00:00 after `now` on the server's clock (os.time normalises
-- day 32 into the next month).
function Family.nextMidnight(now)
	local d = os.date("*t", now or os.time())
	return os.time({ year = d.year, month = d.month, day = d.day + 1, hour = 0, min = 0, sec = 0 })
end

-- The end time actually kept when a script asks for `value` (`now` only
-- for tests).
function Family.bossWaitEnd(value, now)
	if type(value) ~= "number" then
		return value
	end
	now = now or os.time()
	if value <= now then
		return value
	end
	if Family.bossCooldownMode == "none" then
		return now
	end
	if Family.bossCooldownMode == "midnight" then
		return math.min(value, Family.nextMidnight(now))
	end
	return value
end

-- 1. General boss cooldown -------------------------------------------------
local originalSetBossCooldown = Player.setBossCooldown
function Player:setBossCooldown(bossNameOrId, time)
	return originalSetBossCooldown(self, bossNameOrId, Family.bossWaitEnd(time))
end

-- 2. Storage-based boss waits ----------------------------------------------
-- Paths below Storage.Quest (resolved at startup; a missing one is skipped).
local TIMER_PATHS = {
	{ "PrinceDrazzakTime" },
	{ "Quest", "U12_20", "GraveDanger", "Bosses", "LordAzaram", "Timer" },
	{ "Quest", "U12_20", "GraveDanger", "Bosses", "EarlOsam", "Timer" },
	{ "Quest", "U12_20", "GraveDanger", "Bosses", "CountVlarkorth", "Timer" },
	{ "Quest", "U12_20", "GraveDanger", "Bosses", "BaelocNictros", "Timer" },
	{ "Quest", "U12_20", "GraveDanger", "Bosses", "DukeKrule", "Timer" },
	{ "Quest", "U12_20", "GraveDanger", "Bosses", "KingZelos", "Timer" },
	{ "Quest", "U11_02", "ForgottenKnowledge", "LadyTenebrisKilled" },
	{ "Quest", "U11_02", "ForgottenKnowledge", "ThornKnightKilled" },
	{ "Quest", "U11_02", "ForgottenKnowledge", "LloydKilled" },
	{ "Quest", "U11_02", "ForgottenKnowledge", "DragonkingKilled" },
	{ "Quest", "U11_02", "ForgottenKnowledge", "HorrorKilled" },
	{ "Quest", "U11_02", "ForgottenKnowledge", "TimeGuardianKilled" },
	{ "Quest", "U11_02", "ForgottenKnowledge", "LastLoreKilled" },
	{ "Quest", "U11_02", "TheFirstDragon", "FirstDragonTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "BurriedCatedralGlobal", "FacelessTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScar", "MaxxeniusTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScar", "AlptramunTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScar", "PlagueRootTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScar", "IzcandarTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScar", "MalofurTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScar", "NightmareTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScarGlobal", "MaxxeniusTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScarGlobal", "AlptramunTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScarGlobal", "PlagueRootTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScarGlobal", "IzcandarTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScarGlobal", "MalofurTimer" },
	{ "Quest", "U12_00", "TheDreamCourts", "DreamScarGlobal", "NightmareTimer" },
	{ "Quest", "U11_80", "TheSecretLibrary", "LiquidDeath", "BrokulTimer" },
	-- Secret Library bosses with their own 20 h timers (added 2026-10-28)
	{ "Quest", "U11_80", "TheSecretLibrary", "SmallIslands", "RaxiasTimer" },
	{ "Quest", "U11_80", "TheSecretLibrary", "Asuras", "DiamondTimer" },
	{ "Quest", "U11_80", "TheSecretLibrary", "Asuras", "DarkTimer" },
	{ "Quest", "U11_80", "TheSecretLibrary", "Asuras", "BlazingTimer" },
	{ "Quest", "U11_80", "TheSecretLibrary", "Darashia", "ScorpionTimer" },
	-- 3. daily tasks that use the boss default time
	{ "Quest", "U9_60", "BigfootsBurden", "CrystalKeeperTimout" },
	{ "Quest", "U9_60", "BigfootsBurden", "RaidersOfTheLostSparkTimeout" },
	{ "Quest", "U9_60", "BigfootsBurden", "ExterminatorsTimeout" },
	{ "Quest", "U9_60", "BigfootsBurden", "MushroomDiggerTimeout" },
	{ "Quest", "U9_60", "BigfootsBurden", "Mouthpiece" },
	{ "Quest", "U8_7", "RottinWoodAndTheMarriedMen", "Time" },
	-- Not here (fixed 2026-10-20): Dangerous Depths' TimerWarzoneIV/V/VI are not waits but
	-- the 8 hours of free entry after stopping a warzone's lava pumps. Clamping them to
	-- "now" made the pumps necessary again on every entry. The warzone bosses' own wait
	-- (setBossCooldown, 10 h) follows mechanism 1.
}

local timerKeys = {}
local timerCount = 0

local function resolve(path)
	local node = Storage
	for _, name in ipairs(path) do
		if type(node) ~= "table" then
			return nil
		end
		node = node[name]
	end
	return type(node) == "number" and node or nil
end

local function buildKeys()
	for _, path in ipairs(TIMER_PATHS) do
		local key = resolve(path)
		if key and not timerKeys[key] then
			timerKeys[key] = true
			timerCount = timerCount + 1
		end
	end
end

buildKeys()

function Family.isBossTimerStorage(key)
	return timerKeys[key] == true
end

-- The value actually stored when a script writes "value" to storage "key".
function Family.bossTimerValue(key, value)
	if timerKeys[key] then
		return Family.bossWaitEnd(value)
	end
	return value
end

-- Server-wide boss waits (one for everybody): Yakchal on the Ice Islands
-- (24 h after someone wakes her in Tibia; "try again tomorrow").
local GLOBAL_TIMER_KEYS = {}
if GlobalStorage and GlobalStorage.Yakchal then
	GLOBAL_TIMER_KEYS[GlobalStorage.Yakchal] = true
end

local originalGameSetStorageValue = Game.setStorageValue
function Game.setStorageValue(key, value, ...)
	if GLOBAL_TIMER_KEYS[key] then
		value = Family.bossWaitEnd(value)
	end
	return originalGameSetStorageValue(key, value, ...)
end

local originalSetStorageValue = Player.setStorageValue
function Player.setStorageValue(self, key, value, ...)
	return originalSetStorageValue(self, key, Family.bossTimerValue(key, value), ...)
end

-- Waits stored before (other rules) are cut the same way at login.
local login = CreatureEvent("FamilyNoBossCooldownLogin")

function login.onLogin(player)
	for key in pairs(timerKeys) do
		local value = player:getStorageValue(key)
		local kept = Family.bossWaitEnd(value)
		if kept ~= value then
			player:setStorageValue(key, kept)
		end
	end
	return true
end

login:register()

local report = GlobalEvent("FamilyNoBossCooldownReport")

function report.onStartup()
	logger.info("[Family] boss cooldown: {} (default {} s; {} quest timer storages)", Family.bossCooldownMode, configManager.getNumber(configKeys.BOSS_DEFAULT_TIME_TO_FIGHT_AGAIN), timerCount)
	return true
end

report:register()
