-- Gaia Family server: Shadowstalker, Hive boss (bane) (2026-11-16). Ours: not in Canary v3.6.1.
-- Sources: TibiaWiki BR "Shadowstalker" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "Shadowstalker" (race id, sounds, abilities) and "Loot Statistics:Shadowstalker" (85 kills:
-- chance = times dropped / kills, maxCount = the most seen). Speed, armor and mitigation as the Crawler.
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (the Hive underground, third stage only).
local mType = Game.createMonsterType("Shadowstalker")
local monster = {}

monster.description = "Shadowstalker"
monster.experience = 4200
monster.outfit = {
	lookType = 456,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 853,
	bossRace = RARITY_BANE,
}

monster.health = 6100
monster.maxHealth = 6100
monster.race = "venom"
monster.corpse = 13865
monster.speed = 125
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 10,
}

monster.strategiesTarget = {
	nearest = 70,
	health = 10,
	damage = 10,
	random = 10,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = true,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 90,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = false,
	canWalkOnFire = false,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.voices = {
	interval = 5000,
	chance = 10,
	{ text = "Chrssschrsss!", yell = false },
	{ text = "Sssschrchrsss!", yell = false },
}

monster.loot = {
	{ id = 14079, chance = 100000 }, -- crawler head plating
	{ id = 3031, chance = 100000, maxCount = 214 }, -- gold coin
	{ id = 3035, chance = 88235, maxCount = 5 }, -- platinum coin
	{ id = 14083, chance = 76471 }, -- compound eye
	{ id = 239, chance = 52941, maxCount = 2 }, -- great health potion
	{ id = 238, chance = 47059, maxCount = 2 }, -- great mana potion
	{ id = 9057, chance = 45882, maxCount = 2 }, -- small topaz
	{ id = 14753, chance = 44706, maxCount = 2 }, -- dung ball (quest)
	{ id = 3032, chance = 40000, maxCount = 2 }, -- small emerald
	{ id = 3037, chance = 14118 }, -- yellow gem
	{ id = 3279, chance = 3529 }, -- war hammer
	{ id = 8084, chance = 2353 }, -- springsprout rod
	{ id = 14087, chance = 1176 }, -- grasshopper legs
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -300, condition = { type = CONDITION_POISON, totalDamage = 80, interval = 4000 } },
}

monster.defenses = {
	defense = 30,
	armor = 38,
	mitigation = 1.26,
	{ name = "invisible", interval = 2000, chance = 10, effect = CONST_ME_MAGIC_BLUE, target = false, duration = 4000 },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = 0 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 0 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = 0 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
