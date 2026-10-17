-- Gaia Family server: no boss cooldown (2026-10-17). Ours, not upstream.
--
-- Bosses can be fought again right away. Three mechanisms are covered:
--   1. The general boss cooldown (Bosstiary, boss levers and most boss
--      rooms): bossDefaultTimeToFightAgain = 0 in family/config.family.lua,
--      levers capped to 0 in data/scripts/family/solo_balance.lua, and here
--      Player:getBossCooldown always answers "no cooldown", which also clears
--      cooldowns set before this change or by scripts with their own hours
--      (Grimvale and Feaster of Souls portals, Cults of Tibia...).
--   2. Older quests that keep the wait in a character storage instead (Prince
--      Drazzak, Grave Danger, Forgotten Knowledge, the Dream Courts, Brokul,
--      the First Dragon, the Dangerous Depths warzones): writing a future time
--      to those storages stores "now" instead, and leftover waits are cleared
--      at login.
-- Boss rooms that are still occupied stay closed until the fight is over, as
-- upstream.
--
-- Switch: Family.noBossCooldown (false = the 1-hour family cooldown for
-- mechanism 1 needs bossDefaultTimeToFightAgain and FAMILY_BOSS_COOLDOWN put
-- back too; mechanism 2 returns to the quests' own times).

Family = Family or {}
Family.noBossCooldown = true

-- 1. General boss cooldown -------------------------------------------------
local originalGetBossCooldown = Player.getBossCooldown
function Player:getBossCooldown(bossNameOrId)
	if Family.noBossCooldown then
		return 0
	end
	return originalGetBossCooldown(self, bossNameOrId)
end

local originalSetBossCooldown = Player.setBossCooldown
function Player:setBossCooldown(bossNameOrId, time)
	if Family.noBossCooldown and type(time) == "number" and time > os.time() then
		time = os.time()
	end
	return originalSetBossCooldown(self, bossNameOrId, time)
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
	{ "Quest", "U11_50", "DangerousDepths", "Access", "TimerWarzoneIV" },
	{ "Quest", "U11_50", "DangerousDepths", "Access", "TimerWarzoneV" },
	{ "Quest", "U11_50", "DangerousDepths", "Access", "TimerWarzoneVI" },
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
	if Family.noBossCooldown and timerKeys[key] and type(value) == "number" and value > os.time() then
		return os.time()
	end
	return value
end

local originalSetStorageValue = Player.setStorageValue
function Player.setStorageValue(self, key, value, ...)
	return originalSetStorageValue(self, key, Family.bossTimerValue(key, value), ...)
end

local login = CreatureEvent("FamilyNoBossCooldownLogin")

function login.onLogin(player)
	if Family.noBossCooldown then
		local now = os.time()
		for key in pairs(timerKeys) do
			if player:getStorageValue(key) > now then
				player:setStorageValue(key, now)
			end
		end
	end
	return true
end

login:register()

local report = GlobalEvent("FamilyNoBossCooldownReport")

function report.onStartup()
	logger.info("[Family] boss cooldown: none={} (default {} s; {} quest timer storages)", tostring(Family.noBossCooldown), configManager.getNumber(configKeys.BOSS_DEFAULT_TIME_TO_FIGHT_AGAIN), timerCount)
	return true
end

report:register()
