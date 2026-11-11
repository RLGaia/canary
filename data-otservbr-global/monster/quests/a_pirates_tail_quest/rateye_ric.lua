-- FAMILY: Gaia Family server, A Pirate's Tail, the Ratmiral fight (2026-11-11; scripts/family/ratmiral_fight.lua).
-- TibiaWiki EN Rateye Ric: the miniboss of the first stage; not pushable, paralysis immune, sees invisible, every
-- number "?"; he attacks from a distance (EN spoiler) and destroys the rum barrel by touching it (BR). Health,
-- damage and speed ours (Rodrigo: estimated like Tibia); he leaves before he dies (script); 0 XP like 1st Mate
-- Ratticus (EN). Look: the pirat outfit, colours
-- fitted on the EN picture (the EN picture shows extras the outfit does not have: the closest we have).
local mType = Game.createMonsterType("Rateye Ric")
local monster = {}

monster.description = "Rateye Ric"
monster.experience = 0
monster.outfit = {
	lookType = 1346,
	lookHead = 18,
	lookBody = 130,
	lookLegs = 114,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 30000
monster.maxHealth = 30000
monster.race = "blood"
monster.corpse = 0
monster.speed = 200
monster.manaCost = 0

monster.events = {
	"FamilyRatmiralHelper",
}

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

monster.loot = {}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -300 },
	{ name = "combat", interval = 2000, chance = 60, type = COMBAT_PHYSICALDAMAGE, minDamage = -150, maxDamage = -500, range = 7, shootEffect = CONST_ANI_ARROW, target = true },
}

monster.defenses = {
	defense = 40,
	armor = 45,
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
	{ type = "bleed", condition = false },
}

mType:register(monster)
