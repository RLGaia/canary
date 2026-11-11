-- FAMILY: Gaia Family server, A Pirate's Tail supply mission (2026-11-10; scripts/family/rascacoon_supply.lua).
-- TibiaWiki BR: 300 HP, 0 XP, can be pushed, immune to paralysis and invisibility, no abilities.
-- Ours: the look (a cheese item; the real look was not found in client 15.11), not attackable by players
-- (the spy rats eat it through the script).
local mType = Game.createMonsterType("Mintwarella Cheese")
local monster = {}

monster.name = "Mintwarella Cheese"
monster.description = "a mintwarella cheese"
monster.experience = 0
monster.outfit = {
	lookTypeEx = 3607,
}

monster.health = 300
monster.maxHealth = 300
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
	pushable = true,
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
