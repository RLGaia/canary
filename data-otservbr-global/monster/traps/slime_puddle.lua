-- FAMILY: Gaia Family server (2026-11-25), ours: upstream had no Slime Puddle. A trap in Kurik's arena of
-- Last Creep Standing (lib/others/family_last_creep.lua). TibiaWiki EN "Slime Puddle": stays where it is,
-- paralysing berserk; its health, look and the strength of the paralysis are not given, so these are ours
-- (the slime look; it cannot be attacked and does no damage: "nothing can harm you during the challenge").
local mType = Game.createMonsterType("Slime Puddle")
local monster = {}

monster.description = "a slime puddle"
monster.experience = 0
monster.outfit = {
	lookType = 19,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 1000
monster.maxHealth = 1000
monster.race = "venom"
monster.corpse = 0
monster.speed = 0
monster.manaCost = 0

monster.changeTarget = {
	interval = 2000,
	chance = 0,
}

monster.strategiesTarget = {
	nearest = 100,
}

monster.flags = {
	summonable = false,
	attackable = false,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	canPushItems = false,
	canPushCreatures = false,
	staticAttackChance = 100,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = true,
	isBlockable = false,
	canWalkOnEnergy = false,
	canWalkOnFire = false,
	canWalkOnPoison = false,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.voices = {}

monster.loot = {}

monster.attacks = {
	{ name = "speed", interval = 1000, chance = 100, speedChange = -600, radius = 1, effect = CONST_ME_POISONAREA, target = false, duration = 3000 },
}

monster.defenses = {
	defense = 0,
	armor = 0,
	mitigation = 0,
}

monster.elements = {}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = true },
}

mType:register(monster)
