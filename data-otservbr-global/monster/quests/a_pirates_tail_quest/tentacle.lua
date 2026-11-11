-- FAMILY: Gaia Family server, A Pirate's Tail, the Tentugly fight (2026-11-11; scripts/family/tentugly_fight.lua).
-- TibiaWiki EN Tentacle: 2500 HP, 0 XP, melee 0-711, earth 60% (here 40% resistance), does not move, not
-- pushable, paralysis immune, sees invisible. Look: the tentacle object 35106 (matched to the EN picture on
-- the client 15.11 sprites). The script makes it retreat one square each time it dies (EN/BR).
local mType = Game.createMonsterType("Tentacle")
local monster = {}

monster.description = "a tentacle"
monster.experience = 0
monster.outfit = {
	lookTypeEx = 35106,
}

monster.health = 2500
monster.maxHealth = 2500
monster.race = "blood"
monster.corpse = 0
monster.speed = 0
monster.manaCost = 0

monster.events = {
	"FamilyTentacleDeath",
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
	canPushItems = false,
	canPushCreatures = false,
	staticAttackChance = 100,
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
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -711 },
}

monster.defenses = {
	defense = 30,
	armor = 30,
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 40 },
	{ type = COMBAT_FIREDAMAGE, percent = 0 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 100 },
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
