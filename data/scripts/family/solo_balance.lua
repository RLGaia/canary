-- Gaia Family server: solo / duo balance (chosen 2026-10-12).
--
-- This file is ours (not upstream), so Canary updates never conflict with it.
-- It lives in the core scripts folder, which loads before every quest script.
-- Simple settings (premium, loot, boss multipliers...) are in
-- family/config.family.lua; this file holds what config.lua cannot express.

local FAMILY_BOSS_COOLDOWN = 4 * 60 * 60 -- seconds; matches bossDefaultTimeToFightAgain
local FAMILY_COIN_FLOOR = 1000000 -- top up when the balance drops below this
local FAMILY_COIN_TARGET = 10000000 -- ...back to this

-- ---------------------------------------------------------------------------
-- 1. Level curves ("medium"). Used because config sets rateUseStages = true.
--    These replace the upstream tables from data/stages.lua.
-- ---------------------------------------------------------------------------
experienceStages = {
	{ minlevel = 1, maxlevel = 50, multiplier = 10 },
	{ minlevel = 51, maxlevel = 100, multiplier = 7 },
	{ minlevel = 101, maxlevel = 200, multiplier = 5 },
	{ minlevel = 201, multiplier = 3 },
}

skillsStages = {
	{ minlevel = 10, maxlevel = 60, multiplier = 10 },
	{ minlevel = 61, maxlevel = 80, multiplier = 7 },
	{ minlevel = 81, maxlevel = 100, multiplier = 5 },
	{ minlevel = 101, multiplier = 3 },
}

magicLevelStages = {
	{ minlevel = 0, maxlevel = 30, multiplier = 10 },
	{ minlevel = 31, maxlevel = 60, multiplier = 7 },
	{ minlevel = 61, maxlevel = 90, multiplier = 5 },
	{ minlevel = 91, multiplier = 3 },
}

-- ---------------------------------------------------------------------------
-- 2. Boss levers: one player is always enough, and no lever keeps a cooldown
--    longer than FAMILY_BOSS_COOLDOWN. Wraps the BossLever constructor from
--    data/libs/functions/boss_lever.lua, which every standard boss lever uses.
-- ---------------------------------------------------------------------------
local leversPatched = 0
local leverMeta = BossLever and getmetatable(BossLever)
if leverMeta and type(leverMeta.__call) == "function" then
	local originalNew = leverMeta.__call
	leverMeta.__call = function(self, config)
		if type(config) == "table" then
			config.minPlayers = 1
			if config.timeToFightAgain and config.timeToFightAgain > FAMILY_BOSS_COOLDOWN then
				config.timeToFightAgain = FAMILY_BOSS_COOLDOWN
			end
			leversPatched = leversPatched + 1
		end
		return originalNew(self, config)
	end
else
	logger.warn("[Family] BossLever not found; boss levers keep their original party size and cooldown")
end

-- ---------------------------------------------------------------------------
-- 3. Tibia Coin store: every account keeps a large coin balance, so all store
--    items are available. Topped up on login.
-- ---------------------------------------------------------------------------
local familyCoins = CreatureEvent("FamilyStoreCoins")

function familyCoins.onLogin(player)
	local coins = player:getTibiaCoins()
	if coins and coins < FAMILY_COIN_FLOOR then
		player:addTibiaCoins(FAMILY_COIN_TARGET - coins)
	end
	return true
end

familyCoins:register()

-- ---------------------------------------------------------------------------
-- 4. Startup report: confirms in the server log that the family settings
--    are active. Runs once, after every quest script has created its levers.
-- ---------------------------------------------------------------------------
local familyReport = GlobalEvent("FamilyBalanceReport")

function familyReport.onStartup()
	local function float(key)
		return string.format("%.2f", configManager.getFloat(key, false))
	end
	logger.info(
		"[Family] premium={} worldType={} stages={} loot={}x bossHP={} bossDamage={} bossCooldown={}h autoLoot={} autoBank={}",
		tostring(configManager.getBoolean(configKeys.FREE_PREMIUM)),
		configManager.getString(configKeys.WORLD_TYPE),
		tostring(configManager.getBoolean(configKeys.RATE_USE_STAGES)),
		configManager.getNumber(configKeys.RATE_LOOT),
		float(configKeys.RATE_BOSS_HEALTH),
		float(configKeys.RATE_BOSS_ATTACK),
		configManager.getNumber(configKeys.BOSS_DEFAULT_TIME_TO_FIGHT_AGAIN) / 3600,
		tostring(configManager.getBoolean(configKeys.AUTOLOOT)),
		tostring(configManager.getBoolean(configKeys.AUTOBANK))
	)
	logger.info(
		"[Family] experience x{}/x{}/x{}/x{} (levels 1/51/101/201); boss levers set to 1 player: {}",
		getRateFromTable(experienceStages, 1, 1),
		getRateFromTable(experienceStages, 51, 1),
		getRateFromTable(experienceStages, 101, 1),
		getRateFromTable(experienceStages, 201, 1),
		leversPatched
	)
	return true
end

familyReport:register()
