-- Gaia Family server: Blood Brothers Quest, Lersatio (2026-11-02). Ours: upstream Canary v3.6.1
-- has no monster file for him. Hit points, experience, abilities, voices, loot and damage
-- modifiers from TibiaWiki EN (Lersatio); loot chances from the wiki's rarity words, ours.
-- Spawned by data-otservbr-global/scripts/family/blood_brothers.lua.
local mType = Game.createMonsterType("Lersatio")
local monster = {}

monster.description = "Lersatio"
monster.experience = 2500
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
	bossRaceId = 482,
	bossRace = RARITY_BANE,
}

monster.health = 1645
monster.maxHealth = 1645
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
	{ text = "The monsters in the mirrors will come eat your dreams.", yell = false },
	{ text = "Your pitiful life has come to an end.", yell = false },
	{ text = "One day I will see my pretty face in a mirror again.", yell = false },
}

monster.loot = {
	{ name = "gold coin", chance = 100000, maxCount = 100 },
	{ name = "platinum coin", chance = 30000, maxCount = 5 },
	{ name = "strong health potion", chance = 25000 },
	{ name = "blood preservation", chance = 80000 },
	{ id = 3098, chance = 10000 },
	{ name = "vampire shield", chance = 2000 },
	{ name = "dreaded cleaver", chance = 2000 },
	{ name = "black pearl", chance = 2000 },
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -392 },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_PHYSICALDAMAGE, minDamage = 0, maxDamage = -258, range = 7, shootEffect = CONST_ANI_SNIPERARROW, target = true },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_LIFEDRAIN, minDamage = -80, maxDamage = -120, range = 7, shootEffect = CONST_ANI_DEATH, effect = CONST_ME_SMALLCLOUDS, target = true },
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
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 40 },
	{ type = COMBAT_EARTHDAMAGE, percent = 0 },
	{ type = COMBAT_FIREDAMAGE, percent = 0 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = 0 },
	{ type = COMBAT_HOLYDAMAGE, percent = 0 },
	{ type = COMBAT_DEATHDAMAGE, percent = 100 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = false },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = false },
}

mType:register(monster)
