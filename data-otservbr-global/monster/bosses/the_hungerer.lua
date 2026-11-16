-- Gaia Family server: The Hungerer, Hive Outpost boss (nemesis) (2026-11-16). Ours: not in Canary v3.6.1.
-- Sources: TibiaWiki BR "The Hungerer" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "The Hungerer" (race id, sounds, abilities) and "Loot Statistics:The Hungerer" (11 kills:
-- chance = times dropped / kills, maxCount = the most seen). Experience: no wiki has it (ours). Abilities named by BR without numbers: Spitter numbers (ours).
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (Hive Outpost bottom floor, sometimes after a kill there).
local mType = Game.createMonsterType("The Hungerer")
local monster = {}

monster.description = "The Hungerer"
monster.experience = 2000
monster.outfit = {
	lookType = 461,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 1125,
	bossRace = RARITY_NEMESIS,
}

monster.health = 2000
monster.maxHealth = 2000
monster.race = "venom"
monster.corpse = 13979
monster.speed = 135
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
}

monster.loot = {
	{ id = 3031, chance = 100000, maxCount = 156 }, -- gold coin
	{ id = 3035, chance = 100000 }, -- platinum coin
	{ id = 3033, chance = 45455, maxCount = 2 }, -- small amethyst
	{ id = 14083, chance = 36364 }, -- compound eye
	{ id = 14078, chance = 27273 }, -- spitter nose
	{ id = 3725, chance = 18182, maxCount = 3 }, -- brown mushroom
	{ id = 7449, chance = 18182 }, -- crystal sword
	{ id = 239, chance = 18182 }, -- great health potion
	{ id = 238, chance = 18182 }, -- great mana potion
	{ id = 3391, chance = 9091 }, -- crusader helmet
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -180, condition = { type = CONDITION_POISON, totalDamage = 240, interval = 4000 } },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_EARTHDAMAGE, minDamage = -100, maxDamage = -200, range = 7, radius = 3, shootEffect = CONST_ANI_POISON, effect = CONST_ME_POISONAREA, target = true },
}

monster.defenses = {
	defense = 20,
	armor = 48,
	mitigation = 1.6,
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_HEALING, minDamage = 50, maxDamage = 100, effect = CONST_ME_MAGIC_BLUE, target = false },
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
