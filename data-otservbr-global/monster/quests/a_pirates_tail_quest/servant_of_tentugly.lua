-- FAMILY: Gaia Family server, A Pirate's Tail, the Tentugly fight (2026-11-11; scripts/family/tentugly_fight.lua).
-- TibiaWiki EN Servant of Tentugly: looks and acts like a Quara Constrictor, melee 0-200, earth 120% (here
-- -20%), energy 80% (here +20%); HP and experience are "?" on the wiki and BR calls them "not very strong":
-- health, armor and the other attacks are the Quara Constrictor's, with 1000 HP (ours). No loot (EN).
local mType = Game.createMonsterType("Servant of Tentugly")
local monster = {}

monster.description = "a servant of tentugly"
monster.experience = 0
monster.outfit = {
	lookType = 46,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 1000
monster.maxHealth = 1000
monster.race = "blood"
monster.corpse = 6065
monster.speed = 190
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 10,
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
	canPushCreatures = false,
	staticAttackChance = 90,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = false,
	canWalkOnFire = false,
	canWalkOnPoison = false,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.loot = {}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -200, effect = CONST_ME_DRAWBLOOD },
	{ name = "combat", interval = 2000, chance = 10, type = COMBAT_LIFEDRAIN, minDamage = -50, maxDamage = -90, radius = 3, effect = CONST_ME_HITAREA, target = false },
	{ name = "combat", interval = 2000, chance = 10, type = COMBAT_ICEDAMAGE, minDamage = -40, maxDamage = -70, range = 7, radius = 4, effect = CONST_ME_ICEATTACK, target = false },
}

monster.defenses = {
	defense = 20,
	armor = 14,
	mitigation = 0.94,
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 20 },
	{ type = COMBAT_EARTHDAMAGE, percent = -20 },
	{ type = COMBAT_FIREDAMAGE, percent = 0 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 100 },
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
