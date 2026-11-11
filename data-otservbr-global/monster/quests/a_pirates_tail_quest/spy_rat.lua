-- FAMILY: Gaia Family server, A Pirate's Tail supply mission (2026-11-10; scripts/family/rascacoon_supply.lua).
-- TibiaWiki BR/EN: cannot be pushed, immune to paralysis and invisibility, no abilities, only eats the
-- cheese (EN), cannot be killed until a Rascoohan Rat Revealer turns it into a Cheese Thief (EN).
-- Look: a rat (BR picture). It walks through the script (speed here 0, the script moves it).
local mType = Game.createMonsterType("Spy Rat")
local monster = {}

monster.name = "Spy Rat"
monster.description = "a spy rat"
monster.experience = 0
monster.outfit = {
	lookType = 21,
}

monster.health = 100
monster.maxHealth = 100
monster.race = "blood"
monster.corpse = 0
monster.speed = 0
monster.manaCost = 0

monster.changeTarget = {
	interval = 0,
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
	canPushItems = true,
	canPushCreatures = false,
	staticAttackChance = 95,
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

monster.attacks = {}

monster.defenses = {
	defense = 0,
	armor = 0,
}

monster.elements = {}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
}

mType:register(monster)
