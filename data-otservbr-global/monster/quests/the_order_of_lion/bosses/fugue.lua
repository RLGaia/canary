-- FAMILY: Gaia Family server (ours, 2026-11-09): Fugue, the usurper leader who attacks Kesar's throne room
-- at night in The Order of the Lion Quest (scripts/family/order_of_the_lion.lua). Upstream had no Fugue.
-- TibiaWiki EN: 32,000 hit points, 23,000 experience, melee 0-1,444, ice 0-1,500, death 0-800, sees
-- invisible, voices below, no loot (CipSoft removed it in August 2020), Bosstiary race 1958. Attack
-- shapes, defences and outfit (as Drume's, other colours) are ours.
local mType = Game.createMonsterType("Fugue")
local monster = {}

monster.description = "Fugue"
monster.experience = 23000
monster.outfit = {
	lookType = 1317,
	lookHead = 95,
	lookBody = 94,
	lookLegs = 114,
	lookFeet = 95,
	lookAddons = 1,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 1958,
	bossRace = RARITY_ARCHFOE,
}

monster.health = 32000
monster.maxHealth = 32000
monster.race = "blood"
monster.corpse = 33973
monster.speed = 130
monster.manaCost = 0

monster.faction = FACTION_LIONUSURPERS
monster.enemyFactions = { FACTION_LION, FACTION_PLAYER }

monster.changeTarget = {
	interval = 4000,
	chance = 20,
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
	staticAttackChance = 80,
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

monster.voices = {
	interval = 5000,
	chance = 10,
	{ text = "Who are you? Well too bad, you weren't our target!", yell = false },
	{ text = "You don't deserve this!", yell = false },
	{ text = "Kesar does not belong here!", yell = false },
}

monster.loot = {}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -1444 },
	{ name = "combat", interval = 2500, chance = 20, type = COMBAT_ICEDAMAGE, minDamage = -700, maxDamage = -1500, length = 5, spread = 0, effect = CONST_ME_ICEATTACK, target = false },
	{ name = "combat", interval = 3000, chance = 18, type = COMBAT_ICEDAMAGE, minDamage = -500, maxDamage = -1100, range = 7, shootEffect = CONST_ANI_SMALLICE, effect = CONST_ME_ICEAREA, target = true },
	{ name = "combat", interval = 3300, chance = 20, type = COMBAT_DEATHDAMAGE, minDamage = -400, maxDamage = -800, radius = 3, effect = CONST_ME_MORTAREA, target = false },
}

monster.defenses = {
	defense = 55,
	armor = 78,
	{ name = "combat", interval = 4000, chance = 25, type = COMBAT_HEALING, minDamage = 250, maxDamage = 600, effect = CONST_ME_MAGIC_BLUE, target = false },
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
