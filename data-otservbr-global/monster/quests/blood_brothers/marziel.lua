-- Gaia Family server: Blood Brothers Quest, Marziel (2026-11-02). Ours: upstream Canary v3.6.1
-- has no monster file for him. Hit points, experience, abilities, voices, loot and damage
-- modifiers from TibiaWiki EN (Marziel); loot chances from the wiki's rarity words, ours.
-- Spawned by data-otservbr-global/scripts/family/blood_brothers.lua.
local mType = Game.createMonsterType("Marziel")
local monster = {}

monster.description = "Marziel"
monster.experience = 3000
monster.outfit = {
	lookType = 287,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 481,
	bossRace = RARITY_BANE,
}

monster.health = 1900
monster.maxHealth = 1900
monster.race = "undead"
monster.corpse = 8109
monster.speed = 135
monster.manaCost = 0

monster.changeTarget = {
	interval = 5000,
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
	illusionable = false,
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
	{ text = "My brides will show you how to suffer beautifully.", yell = false },
	{ text = "I smell warm blood.", yell = false },
	{ text = "Why are you disturbing me and my brides?", yell = false },
	{ text = "You shouldn't have come.", yell = false },
	{ text = "You! You had no right to read my diary!", yell = false },
	{ text = "I... want... your... blood!", yell = false },
}

monster.loot = {
	{ name = "gold coin", chance = 100000, maxCount = 100 },
	{ name = "platinum coin", chance = 30000, maxCount = 7 },
	{ name = "strong health potion", chance = 25000 },
	{ id = 3098, chance = 30000 },
	{ name = "vampire shield", chance = 2000 },
	{ name = "dreaded cleaver", chance = 500 },
}

monster.attacks = {
	{ name = "combat", interval = 2000, chance = 100, type = COMBAT_LIFEDRAIN, minDamage = 0, maxDamage = -600, range = 1, effect = CONST_ME_DRAWBLOOD, target = true },
	{ name = "lersatio summon", interval = 2000, chance = 15 },
}

monster.defenses = {
	defense = 35,
	armor = 35,
	{ name = "combat", interval = 1000, chance = 12, type = COMBAT_HEALING, minDamage = 100, maxDamage = 200, effect = CONST_ME_MAGIC_BLUE, target = false },
	{ name = "invisible", interval = 3000, chance = 20, effect = CONST_ME_MAGIC_BLUE },
	{ name = "outfit", interval = 3000, chance = 10, effect = CONST_ME_GROUNDSHAKER, target = false, duration = 4000, outfitMonster = "bat" },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 43 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 20 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = 10 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = -5 },
	{ type = COMBAT_HOLYDAMAGE, percent = -5 },
	{ type = COMBAT_DEATHDAMAGE, percent = 100 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = false },
	{ type = "bleed", condition = false },
}

mType:register(monster)
