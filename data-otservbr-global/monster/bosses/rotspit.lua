-- Gaia Family server: Rotspit, Hive boss (bane) (2026-11-16). Ours: not in Canary v3.6.1.
-- Sources: TibiaWiki BR "Rotspit" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "Rotspit" (race id, sounds, abilities) and "Loot Statistics:Rotspit" (61 kills:
-- chance = times dropped / kills, maxCount = the most seen). Speed, armor and mitigation as the Spitter.
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (the Hive underground, third stage only).
local mType = Game.createMonsterType("Rotspit")
local monster = {}

monster.description = "Rotspit"
monster.experience = 5800
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
	bossRaceId = 854,
	bossRace = RARITY_BANE,
}

monster.health = 6800
monster.maxHealth = 6800
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
	{ text = "Spotz!", yell = false },
	{ text = "Schlopfth!", yell = false },
}

monster.loot = {
	{ id = 3031, chance = 100000, maxCount = 192 }, -- gold coin
	{ id = 14078, chance = 100000 }, -- spitter nose
	{ id = 3035, chance = 85246, maxCount = 5 }, -- platinum coin
	{ id = 14083, chance = 77049 }, -- compound eye
	{ id = 14753, chance = 59016, maxCount = 2 }, -- dung ball (quest)
	{ id = 238, chance = 50820, maxCount = 2 }, -- great mana potion
	{ id = 3032, chance = 49180, maxCount = 2 }, -- small emerald
	{ id = 239, chance = 44262, maxCount = 2 }, -- great health potion
	{ id = 3033, chance = 44262, maxCount = 2 }, -- small amethyst
	{ id = 3725, chance = 42623, maxCount = 3 }, -- brown mushroom
	{ id = 7449, chance = 16393 }, -- crystal sword
	{ id = 281, chance = 3279 }, -- giant shimmering pearl
	{ id = 3053, chance = 3279 }, -- time ring
	{ id = 3391, chance = 1639 }, -- crusader helmet
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -200, condition = { type = CONDITION_POISON, totalDamage = 240, interval = 4000 } },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_EARTHDAMAGE, minDamage = -200, maxDamage = -500, range = 7, radius = 3, shootEffect = CONST_ANI_POISON, effect = CONST_ME_POISONAREA, target = true },
}

monster.defenses = {
	defense = 20,
	armor = 48,
	mitigation = 1.6,
	{ name = "combat", interval = 2000, chance = 30, type = COMBAT_HEALING, minDamage = 5, maxDamage = 20, effect = CONST_ME_MAGIC_BLUE, target = false },
	{ name = "speed", interval = 2000, chance = 15, speedChange = 400, effect = CONST_ME_MAGIC_RED, target = false, duration = 5000 },
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
