-- FAMILY: Gaia Family server (2026-11-24), ours: upstream had no Ghostly Apparition. It wakes in the hall
-- of the sleeping dead pirates on Treasure Hunt Island (Treasure Hunt Quest, lib/others/family_treasure_hunt.lua).
-- TibiaWiki EN "Ghostly Apparition": 150 health, 120 experience, distance life drain 4-6, keeps its
-- distance, sees invisible, cannot be killed, no loot; its sounds. The look is ours (the pirate ghost):
-- we could not tell which client outfit is the real one.
local mType = Game.createMonsterType("Ghostly Apparition")
local monster = {}

monster.description = "a ghostly apparition"
monster.experience = 120
monster.outfit = {
	lookType = 196,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 150
monster.maxHealth = 150
monster.race = "undead"
monster.corpse = 0
monster.speed = 110
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
	attackable = false,
	hostile = true,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	canPushItems = false,
	canPushCreatures = false,
	staticAttackChance = 90,
	targetDistance = 4,
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
	{ text = "Fresh life spirit.... aaahhh.... let me feeeeed...", yell = false },
	{ text = "Theeeese waaalls.... hold unholy secretsss....", yell = false },
	{ text = "Saaaaave ussss.....", yell = false },
	{ text = "Aaahhhh.....", yell = false },
	{ text = "Get out of this place before it's too laaaaate...", yell = false },
	{ text = "Go awaaaay....", yell = false },
}

monster.loot = {}

monster.attacks = {
	{ name = "combat", interval = 2000, chance = 100, type = COMBAT_LIFEDRAIN, minDamage = -4, maxDamage = -6, range = 7, effect = CONST_ME_MAGIC_RED, target = true },
}

monster.defenses = {
	defense = 0,
	armor = 0,
	mitigation = 0,
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
