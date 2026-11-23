-- Gaia Family server (2026-11-22, Sweet Dreams): Gorga, the medusa boss on the top floor of the Medusa
-- Tower (update 13.34). Canary v3.6.1 has no Gorga. Health, experience, elements, abilities and loot from
-- TibiaWiki BR and EN; outfit (medusa), attacks and chances are the medusa's (ours). Spawn:
-- world/otservbr-monster.xml (EN: every 5-10 minutes). The nightsky cupcake for the Sugar Plum Fairy is
-- added by FamilySweetDreams.bossLoot.
local mType = Game.createMonsterType("Gorga")
local monster = {}

monster.description = "Gorga"
monster.experience = 13000
monster.outfit = {
	lookType = 330,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.raceId = 2561
monster.bosstiary = {
	bossRaceId = 2561,
	bossRace = RARITY_BANE,
}

monster.health = 15000
monster.maxHealth = 15000
monster.race = "blood"
monster.corpse = 9607
monster.speed = 125
monster.manaCost = 0

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
	staticAttackChance = 90,
	targetDistance = 1,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = false,
	canWalkOnFire = false,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.voices = {
	interval = 5000,
	chance = 10,
	{ text = "You will make sssuch a fine ssstatue!", yell = false },
	{ text = "There isss no chhhanccce of essscape", yell = false },
	{ text = "Are you tired or why are you moving thhat ssslow <chuckle>", yell = false },
	{ text = "Jussst look at me!", yell = false },
}

monster.loot = {
	{ name = "platinum coin", chance = 100000, maxCount = 20 },
	{ name = "strand of medusa hair", chance = 100000 },
	{ name = "great mana potion", chance = 30000, maxCount = 2 },
	{ name = "ultimate health potion", chance = 30000, maxCount = 2 },
	{ name = "small emerald", chance = 30000, maxCount = 4 },
	{ name = "medusa shield", chance = 10000 },
	{ name = "knight armor", chance = 10000 },
	{ name = "terra amulet", chance = 10000 },
	{ name = "titan axe", chance = 8000 },
	{ name = "sacred tree amulet", chance = 8000 },
	{ name = "terra mantle", chance = 8000 },
	{ name = "terra legs", chance = 8000 },
	{ id = 8896, chance = 5000 }, -- slightly rusted armor (EN)
} -- items from TibiaWiki EN/BR; chances ours (the wikis give none)

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -450, condition = { type = CONDITION_POISON, totalDamage = 840, interval = 4000 } },
	{ name = "combat", interval = 2000, chance = 20, type = COMBAT_LIFEDRAIN, minDamage = -21, maxDamage = -350, range = 7, shootEffect = CONST_ANI_EARTH, effect = CONST_ME_CARNIPHILA, target = true },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_EARTHDAMAGE, minDamage = -250, maxDamage = -500, length = 8, spread = 0, effect = CONST_ME_CARNIPHILA, target = false },
	{ name = "speed", interval = 2000, chance = 25, radius = 7, effect = CONST_ME_POFF, target = true },
	{ name = "outfit", interval = 2000, chance = 1, range = 7, target = true, duration = 3000, outfitMonster = "clay guardian" },
}

monster.defenses = {
	defense = 30,
	armor = 45,
	mitigation = 1.74,
	{ name = "combat", interval = 2000, chance = 25, type = COMBAT_HEALING, minDamage = 150, maxDamage = 300, effect = CONST_ME_MAGIC_BLUE, target = false },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = -10 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = -5 },
	{ type = COMBAT_LIFEDRAIN, percent = 100 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 100 },
	{ type = COMBAT_ICEDAMAGE, percent = 20 },
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
