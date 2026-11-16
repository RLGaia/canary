-- FAMILY: rewritten for the War Against the Hive bosses. Gaia Family server: Fleshslicer, Hive boss (bane) (2026-11-16). Rewritten: upstream had a stub (no loot, 99 melee).
-- Sources: TibiaWiki BR "Fleshslicer" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "Fleshslicer" (race id, sounds, abilities) and "Loot Statistics:Fleshslicer" (41 kills:
-- chance = times dropped / kills, maxCount = the most seen). Speed, armor and mitigation as the Spidris. BR melee 0-520, EN 0-300?: BR used.
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (the Hive underground, third stage only).
local mType = Game.createMonsterType("Fleshslicer")
local monster = {}

monster.description = "Fleshslicer"
monster.experience = 5500
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
	bossRaceId = 858,
	bossRace = RARITY_BANE,
}

monster.health = 5700
monster.maxHealth = 5700
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
	{ text = "Eeeeeeyyyyh!", yell = false },
}

monster.loot = {
	{ id = 14083, chance = 100000, maxCount = 2 }, -- compound eye
	{ id = 3031, chance = 100000, maxCount = 234 }, -- gold coin
	{ id = 3035, chance = 100000, maxCount = 5 }, -- platinum coin
	{ id = 14082, chance = 100000 }, -- spidris mandible
	{ id = 238, chance = 68293, maxCount = 2 }, -- great mana potion
	{ id = 14753, chance = 56098, maxCount = 2 }, -- dung ball (quest)
	{ id = 3030, chance = 46341, maxCount = 5 }, -- small ruby
	{ id = 3346, chance = 31707 }, -- ripper lance
	{ id = 7643, chance = 31707 }, -- ultimate health potion
	{ id = 3026, chance = 21951, maxCount = 5 }, -- white pearl
	{ id = 3039, chance = 17073 }, -- red gem
	{ id = 7413, chance = 9756 }, -- titan axe
	{ id = 3036, chance = 9756 }, -- violet gem
	{ id = 6299, chance = 4878 }, -- death ring
	{ id = 281, chance = 4878 }, -- giant shimmering pearl
	{ id = 14246, chance = 2439 }, -- hive bow
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -520 },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_EARTHDAMAGE, minDamage = -250, maxDamage = -400, length = 5, spread = 3, effect = CONST_ME_DRAWBLOOD, target = false },
	{ name = "condition", type = CONDITION_BLEEDING, interval = 2000, chance = 10, minDamage = -100, maxDamage = -200, length = 5, spread = 3, effect = CONST_ME_DRAWBLOOD, target = false },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_EARTHDAMAGE, minDamage = -200, maxDamage = -500, range = 7, shootEffect = CONST_ANI_POISON, effect = CONST_ME_GREEN_RINGS, target = true },
}

monster.defenses = {
	defense = 30,
	armor = 53,
	mitigation = 1.62,
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_HEALING, minDamage = 50, maxDamage = 150, effect = CONST_ME_MAGIC_BLUE, target = false },
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
