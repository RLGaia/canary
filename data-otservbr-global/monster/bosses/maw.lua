-- Gaia Family server: Maw, Hive boss (bane) (2026-11-16). Ours: not in Canary v3.6.1.
-- Sources: TibiaWiki BR "Maw" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "Maw" (race id, sounds, abilities) and "Loot Statistics:Maw" (81 kills:
-- chance = times dropped / kills, maxCount = the most seen). Speed, armor and mitigation as the Hive Overseer.
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (the Hive underground, third stage only).
local mType = Game.createMonsterType("Maw")
local monster = {}

monster.description = "Maw"
monster.experience = 6500
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
	bossRaceId = 857,
	bossRace = RARITY_BANE,
}

monster.health = 8200
monster.maxHealth = 8200
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
	canWalkOnEnergy = true,
	canWalkOnFire = true,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.voices = {
	interval = 5000,
	chance = 10,
	{ text = "Kropp!", yell = false },
	{ text = "Zopp!", yell = false },
}

monster.loot = {
	{ id = 14083, chance = 100000 }, -- compound eye
	{ id = 3031, chance = 100000, maxCount = 196 }, -- gold coin
	{ id = 14077, chance = 100000 }, -- kollos shell
	{ id = 3035, chance = 83951, maxCount = 6 }, -- platinum coin
	{ id = 238, chance = 66667, maxCount = 2 }, -- great mana potion
	{ id = 14753, chance = 53086, maxCount = 2 }, -- dung ball (quest)
	{ id = 7643, chance = 33333 }, -- ultimate health potion
	{ id = 3027, chance = 30864, maxCount = 4 }, -- black pearl
	{ id = 3030, chance = 30864, maxCount = 4 }, -- small ruby
	{ id = 3039, chance = 23457 }, -- red gem
	{ id = 14172, chance = 18519, maxCount = 2 }, -- gooey mass
	{ id = 281, chance = 7407 }, -- giant shimmering pearl
	{ id = 9058, chance = 7407 }, -- gold ingot
	{ id = 14086, chance = 3704 }, -- calopteryx cape
	{ id = 14246, chance = 1235 }, -- hive bow
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -735 },
	{ name = "combat", interval = 2000, chance = 12, type = COMBAT_PHYSICALDAMAGE, minDamage = -500, maxDamage = -700, length = 4, spread = 0, effect = CONST_ME_GROUNDSHAKER, target = false },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_PHYSICALDAMAGE, minDamage = -175, maxDamage = -300, range = 7, shootEffect = CONST_ANI_LARGEROCK, effect = CONST_ME_EXPLOSIONHIT, target = true },
}

monster.defenses = {
	defense = 45,
	armor = 57,
	mitigation = 2.4,
	{ name = "combat", interval = 2000, chance = 50, type = COMBAT_HEALING, minDamage = 5, maxDamage = 15, effect = CONST_ME_MAGIC_BLUE, target = false },
	{ name = "combat", interval = 2000, chance = 8, type = COMBAT_HEALING, minDamage = 500, maxDamage = 600, effect = CONST_ME_MAGIC_BLUE, target = false },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 60 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 50 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = 50 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 50 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = 40 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
