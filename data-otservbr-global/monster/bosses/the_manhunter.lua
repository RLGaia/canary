-- Gaia Family server: The Manhunter, Hive Outpost boss (nemesis) (2026-11-16). Ours: not in Canary v3.6.1.
-- Sources: TibiaWiki BR "The Manhunter" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "The Manhunter" (race id, sounds, abilities) and "Loot Statistics:The Manhunter" (10 kills:
-- chance = times dropped / kills, maxCount = the most seen). Experience: no wiki has it (ours). Takes full earth damage (BR 100%).
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (Hive Outpost bottom floor, sometimes after a kill there).
local mType = Game.createMonsterType("The Manhunter")
local monster = {}

monster.description = "The Manhunter"
monster.experience = 4000
monster.outfit = {
	lookType = 457,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 1126,
	bossRace = RARITY_NEMESIS,
}

monster.health = 4500
monster.maxHealth = 4500
monster.race = "venom"
monster.corpse = 13870
monster.speed = 195
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
	{ id = 3031, chance = 100000, maxCount = 168 }, -- gold coin
	{ id = 3035, chance = 80000, maxCount = 4 }, -- platinum coin
	{ id = 3030, chance = 60000, maxCount = 4 }, -- small ruby
	{ id = 14083, chance = 50000 }, -- compound eye
	{ id = 238, chance = 40000, maxCount = 2 }, -- great mana potion
	{ id = 14082, chance = 20000 }, -- spidris mandible
	{ id = 7643, chance = 20000 }, -- ultimate health potion
	{ id = 6299, chance = 10000 }, -- death ring
	{ id = 281, chance = 10000 }, -- giant shimmering pearl
	{ id = 14089, chance = 10000 }, -- hive scythe
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -300 },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_EARTHDAMAGE, minDamage = 0, maxDamage = -300, range = 7, radius = 2, shootEffect = CONST_ANI_POISONARROW, effect = CONST_ME_GREEN_RINGS, target = true },
}

monster.defenses = {
	defense = 30,
	armor = 53,
	mitigation = 1.62,
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_HEALING, minDamage = 200, maxDamage = 260, effect = CONST_ME_MAGIC_BLUE, target = false },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 0 },
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
