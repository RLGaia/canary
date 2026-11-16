-- Gaia Family server: Chopper, Hive boss (bane) (2026-11-16). Ours: not in Canary v3.6.1.
-- Sources: TibiaWiki BR "Chopper" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "Chopper" (race id, sounds, abilities) and "Loot Statistics:Chopper" (89 kills:
-- chance = times dropped / kills, maxCount = the most seen). Speed, armor and mitigation as the Waspoid (no wiki has them).
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (the Hive underground, third stage only).
local mType = Game.createMonsterType("Chopper")
local monster = {}

monster.description = "Chopper"
monster.experience = 5400
monster.outfit = {
	lookType = 462,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 852,
	bossRace = RARITY_BANE,
}

monster.health = 7200
monster.maxHealth = 7200
monster.race = "venom"
monster.corpse = 13983
monster.speed = 155
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
	{ text = "Bzzzzzzzrrrrzzzzzzrrrrr!", yell = false },
	{ text = "Peeex!", yell = false },
}

monster.loot = {
	{ id = 3031, chance = 100000, maxCount = 208 }, -- gold coin
	{ id = 14080, chance = 100000 }, -- waspoid claw
	{ id = 3035, chance = 95506, maxCount = 4 }, -- platinum coin
	{ id = 14083, chance = 78652 }, -- compound eye
	{ id = 14081, chance = 76404 }, -- waspoid wing
	{ id = 9057, chance = 56180, maxCount = 2 }, -- small topaz
	{ id = 14753, chance = 55056, maxCount = 2 }, -- dung ball (quest)
	{ id = 239, chance = 46067, maxCount = 2 }, -- great health potion
	{ id = 238, chance = 34831, maxCount = 2 }, -- great mana potion
	{ id = 3027, chance = 30337 }, -- black pearl
	{ id = 3037, chance = 13483 }, -- yellow gem
	{ id = 3010, chance = 6742 }, -- emerald bangle
	{ id = 14087, chance = 2247 }, -- grasshopper legs
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -200, condition = { type = CONDITION_POISON, totalDamage = 200, interval = 4000 } },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_EARTHDAMAGE, minDamage = -100, maxDamage = -300, range = 7, radius = 3, shootEffect = CONST_ANI_POISON, effect = CONST_ME_POISONAREA, target = true },
}

monster.defenses = {
	defense = 25,
	armor = 36,
	mitigation = 1.54,
	{ name = "combat", interval = 2000, chance = 30, type = COMBAT_HEALING, minDamage = 5, maxDamage = 20, effect = CONST_ME_MAGIC_BLUE, target = false },
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
