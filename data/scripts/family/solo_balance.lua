-- Gaia Family server: solo / duo balance (chosen 2026-10-12).
--
-- This file is ours (not upstream), so Canary updates never conflict with it.
-- It lives in the core scripts folder, which loads before every quest script.
-- Simple settings (premium, loot, boss multipliers...) are in
-- family/config.family.lua; this file holds what config.lua cannot express.

local FAMILY_BOSS_COOLDOWN = 60 * 60 -- seconds; matches bossDefaultTimeToFightAgain

Family = Family or {}
-- Exercise weapons never lose charges (read by
-- data/scripts/actions/items/exercise_training_weapons.lua, FAMILY: edit).
Family.infiniteTrainingWeapons = true

-- ---------------------------------------------------------------------------
-- 1. Level curves ("medium"). Used because config sets rateUseStages = true.
--    These replace the upstream tables from data/stages.lua.
-- ---------------------------------------------------------------------------
-- Experience: by character level. Since 2026-10-14 (second change that day):
-- Rubinot's curve up to level 400, then a gentler taper so levels 400-800
-- take about 80 hours of hunting (Rubinot: about 120), and 5x from 801 on
-- (Rubinot keeps falling to 1.2x). Before: 10/8/6/4 (levels 1/51/101/201).
experienceStages = {
	{ minlevel = 1, maxlevel = 8, multiplier = 50 },
	{ minlevel = 9, maxlevel = 50, multiplier = 80 },
	{ minlevel = 51, maxlevel = 100, multiplier = 60 },
	{ minlevel = 101, maxlevel = 150, multiplier = 40 },
	{ minlevel = 151, maxlevel = 200, multiplier = 30 },
	{ minlevel = 201, maxlevel = 300, multiplier = 15 },
	{ minlevel = 301, maxlevel = 500, multiplier = 12 },
	{ minlevel = 501, maxlevel = 600, multiplier = 11 },
	{ minlevel = 601, maxlevel = 700, multiplier = 10 },
	{ minlevel = 701, maxlevel = 800, multiplier = 8 },
	{ minlevel = 801, multiplier = 5 },
}

-- Skills and magic level: by the level of that skill (not the character
-- level). Raised on 2026-10-13 from 10/7/5/3 to 12/9/7/4. The last stage
-- never drops below 4x (Rubinot falls to 2x after 120).
skillsStages = {
	{ minlevel = 0, maxlevel = 60, multiplier = 12 },
	{ minlevel = 61, maxlevel = 80, multiplier = 9 },
	{ minlevel = 81, maxlevel = 100, multiplier = 7 },
	{ minlevel = 101, multiplier = 4 },
}

magicLevelStages = {
	{ minlevel = 0, maxlevel = 30, multiplier = 12 },
	{ minlevel = 31, maxlevel = 60, multiplier = 9 },
	{ minlevel = 61, maxlevel = 90, multiplier = 7 },
	{ minlevel = 91, multiplier = 4 },
}

-- ---------------------------------------------------------------------------
-- 2. Boss levers: one player is always enough, and no lever keeps a cooldown
--    longer than FAMILY_BOSS_COOLDOWN. Every standard boss lever uses
--    BossLever (data/libs/functions/boss_lever.lua) and registers itself as
--    BossLever[<boss name>]. Some levers (Soul War) are created before this
--    file loads, so the registered levers are adjusted at startup, before
--    anyone can use them.
-- ---------------------------------------------------------------------------
local leversPatched = 0

local function patchBossLevers()
	if not BossLever then
		logger.warn("[Family] BossLever not found; boss levers keep their original party size and cooldown")
		return
	end
	for _, lever in pairs(BossLever) do
		if type(lever) == "table" and lever.playerPositions and lever.timeToFightAgain then
			lever.minPlayers = 1
			if lever.timeToFightAgain > FAMILY_BOSS_COOLDOWN then
				lever.timeToFightAgain = FAMILY_BOSS_COOLDOWN
			end
			leversPatched = leversPatched + 1
		end
	end
end

-- ---------------------------------------------------------------------------
-- 3. Tibia Coins are no longer free (changed 2026-10-13): they are bought
--    with gold from the Coin Brokers, see
--    data-otservbr-global/scripts/family/coin_broker.lua.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 4. Death without penalty. config.family.lua sets deathLosePercent = 0 (no
--    experience or skill loss) and gives everyone full blessings, so nothing
--    drops. Here, as a second guard, items never drop on death (also for
--    characters without a vocation), and the login blessing message is
--    replaced. Done at startup because several upstream scripts reload
--    data/libs/systems/blessing.lua while scripts are loading.
-- ---------------------------------------------------------------------------
local familyDeathRules = GlobalEvent("FamilyDeathRules")

function familyDeathRules.onStartup()
	if not Blessings then
		logger.warn("[Family] Blessings library not found; death item rules unchanged")
		return true
	end
	Blessings.PlayerDeath = function(player, corpse, killer)
		if not player:getSlotItem(CONST_SLOT_BACKPACK) then
			player:addItem(ITEM_BAG, 1, false, CONST_SLOT_BACKPACK)
		end
		return true
	end
	Blessings.doAdventurerBlessing = function(player)
		player:addMissingBless(true, true)
		return true
	end
	return true
end

familyDeathRules:register()

-- ---------------------------------------------------------------------------
-- 5. Startup report: confirms in the server log that the family settings
--    are active. Runs once, after every quest script has created its levers.
-- ---------------------------------------------------------------------------
local familyReport = GlobalEvent("FamilyBalanceReport")

-- "1-8 x50, 9-50 x80, ..., 801+ x5"
local function describeStages(stages)
	local parts = {}
	for _, stage in ipairs(stages) do
		local range = stage.maxlevel and string.format("%d-%d", stage.minlevel, stage.maxlevel) or string.format("%d+", stage.minlevel)
		parts[#parts + 1] = string.format("%s x%s", range, tostring(stage.multiplier))
	end
	return table.concat(parts, ", ")
end

function familyReport.onStartup()
	patchBossLevers()
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
		"[Family] death: lose {}% exp/skills, blessed below level {}; training x{} (weapons infinite={}); respawn x{}",
		configManager.getNumber(configKeys.DEATH_LOSE_PERCENT),
		configManager.getNumber(configKeys.ADVENTURERSBLESSING_LEVEL),
		float(configKeys.RATE_EXERCISE_TRAINING_SPEED),
		tostring(Family.infiniteTrainingWeapons),
		configManager.getNumber(configKeys.RATE_SPAWN)
	)
	logger.info("[Family] experience {}; boss levers set to 1 player: {}", describeStages(experienceStages), leversPatched)
	logger.info("[Family] skills {}; magic level {}", describeStages(skillsStages), describeStages(magicLevelStages))
	return true
end

familyReport:register()
