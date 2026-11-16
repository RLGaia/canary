-- Gaia Family server: The Mean Masher, Hive Outpost boss (nemesis) (2026-11-16). Ours: not in Canary v3.6.1.
-- Sources: TibiaWiki BR "The Mean Masher" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "The Mean Masher" (race id, sounds, abilities) and "Loot Statistics:The Mean Masher" (9 kills:
-- chance = times dropped / kills, maxCount = the most seen). Experience: no wiki has it (ours). Paralysis: BR lists only invisibility as immunity, EN says paralysis too: BR used.
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (Hive Outpost bottom floor, sometimes after a kill there).
local mType = Game.createMonsterType("The Mean Masher")
local monster = {}

monster.description = "The Mean Masher"
monster.experience = 6000
monster.outfit = {
	lookType = 458,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 1127,
	bossRace = RARITY_NEMESIS,
}

monster.health = 8000
monster.maxHealth = 8000
monster.race = "venom"
monster.corpse = 13937
monster.speed = 115
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
	canWalkOnFire = true,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.summon = {
	maxSummons = 2,
	summons = {
		{ name = "Spidris Elite", chance = 10, interval = 2000, count = 2 },
	},
}

monster.voices = {
	interval = 5000,
	chance = 10,
}

monster.loot = {
	{ id = 3031, chance = 100000, maxCount = 131 }, -- gold coin
	{ id = 14077, chance = 88889 }, -- kollos shell
	{ id = 3035, chance = 77778, maxCount = 5 }, -- platinum coin
	{ id = 9058, chance = 66667 }, -- gold ingot
	{ id = 14083, chance = 33333 }, -- compound eye
	{ id = 238, chance = 33333 }, -- great mana potion
	{ id = 3030, chance = 33333, maxCount = 2 }, -- small ruby
	{ id = 7643, chance = 22222 }, -- ultimate health potion
	{ id = 14172, chance = 11111, maxCount = 2 }, -- gooey mass
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -450 },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_MANADRAIN, minDamage = -50, maxDamage = -250, range = 7, effect = CONST_ME_MAGIC_BLUE, target = true },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_EARTHDAMAGE, minDamage = -60, maxDamage = -250, radius = 4, effect = CONST_ME_POISONAREA, target = false },
}

monster.defenses = {
	defense = 45,
	armor = 57,
	mitigation = 2.4,
	{ name = "combat", interval = 2000, chance = 30, type = COMBAT_HEALING, minDamage = 50, maxDamage = 100, effect = CONST_ME_MAGIC_BLUE, target = false },
	{ name = "combat", interval = 2000, chance = 8, type = COMBAT_HEALING, minDamage = 300, maxDamage = 500, effect = CONST_ME_MAGIC_BLUE, target = false },
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
	{ type = "paralyze", condition = false },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
