-- Gaia Family server: Megasylvan Sapling (2026-11-23). Ours, not upstream: Megasylvan Yselda's four
-- saplings, one in each corner of her room (TibiaWiki EN "Megasylvan Sapling (Creature)": 10,000 health,
-- no attacks, does not move). Players heal them (Ultimate Healing Rune, Mass Healing); they cannot be
-- attacked. While the fight runs they lose health (scripts/family/galthen.lua); if one dies, Kesar gives
-- no tulip. Look: the megasylvan sapling item (the sprite of the corner plants).
local mType = Game.createMonsterType("Megasylvan Sapling")
local monster = {}

monster.description = "a megasylvan sapling"
monster.experience = 0
monster.outfit = {
	lookTypeEx = 36811,
}

monster.health = 10000
monster.maxHealth = 10000
monster.race = "venom"
monster.corpse = 0
monster.speed = 0
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 0,
}

monster.flags = {
	summonable = false,
	attackable = false,
	hostile = false,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	canPushItems = false,
	canPushCreatures = false,
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

monster.loot = {}

monster.defenses = {
	defense = 0,
	armor = 0,
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
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = true },
}

monster.events = { "FamilyGalthenSaplingDeath" }

mType:register(monster)
