-- Gaia Family server (2026-11-09): the Moohtant Wallbreaker, boss of the minotaur raid in the
-- Underground Glooth Factory (missing upstream). TibiaWiki BR "Invasões em Oramond" (health
-- 120000?, no experience, loot) and EN "Moohtant Wallbreaker" (abilities, resistances,
-- paralysis immune). It does not walk by itself: scripts/family/oramond_raids.lua moves it one
-- square west every 10 seconds (EN) until it reaches the plant wall.
local mType = Game.createMonsterType("Moohtant Wallbreaker")
local monster = {}

monster.description = "a moohtant wallbreaker"
monster.experience = 0
monster.outfit = {
	lookType = 607, -- a moohtant (ours: the wiki image shows a bigger one)
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 120000
monster.maxHealth = 120000
monster.race = "blood"
monster.corpse = 20996
monster.speed = 0
monster.manaCost = 0

monster.changeTarget = {
	interval = 2000,
	chance = 3,
}

monster.strategiesTarget = {
	nearest = 100,
}

monster.flags = {
	summonable = false,
	attackable = true,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	canPushItems = true,
	canPushCreatures = true,
	staticAttackChance = 100,
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
	{ text = "RRRAAAARRRGH!", yell = true },
	{ text = "GNAAARRRR!", yell = true },
	{ text = "RAAAWWWGH!", yell = true },
}

monster.loot = {
	{ id = 3031, chance = 100000, maxCount = 76 }, -- gold coin
	{ id = 3035, chance = 100000, maxCount = 30 }, -- platinum coin
	{ id = 239, chance = 60000, maxCount = 13 }, -- great health potion
	{ id = 238, chance = 60000, maxCount = 13 }, -- great mana potion
	{ id = 3577, chance = 50000, maxCount = 9 }, -- meat
	{ id = 21200, chance = 40000, maxCount = 2 }, -- moohtant horn
	{ id = 3028, chance = 40000, maxCount = 5 }, -- small diamond
	{ id = 3030, chance = 30000 }, -- small ruby
	{ id = 11472, chance = 30000 }, -- minotaur horn
	{ id = 3098, chance = 25000 }, -- ring of healing
	{ id = 21199, chance = 20000 }, -- giant pacifier
	{ id = 21173, chance = 10000 }, -- moohtant cudgel
	{ id = 21202, chance = 10000 }, -- mooh'tah shell
	{ id = 9058, chance = 10000 }, -- gold ingot
	{ id = 21898, chance = 5000 }, -- roll of covering
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -163 },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_PHYSICALDAMAGE, minDamage = -100, maxDamage = -200, radius = 3, effect = CONST_ME_GROUNDSHAKER, target = false }, -- Groundshaker
}

monster.defenses = {
	defense = 45,
	armor = 40,
	{ name = "combat", interval = 2000, chance = 10, type = COMBAT_HEALING, minDamage = 50, maxDamage = 150, effect = CONST_ME_MAGIC_BLUE, target = false },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 85 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 85 },
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
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
