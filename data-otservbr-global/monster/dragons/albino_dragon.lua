-- FAMILY: Albino Dragon (ours, 2026-10-26; not in Canary v3.6.1). Spawned by
-- data-otservbr-global/scripts/family/dragon_slayer.lua, one at a time in each
-- of TibiaWiki's five lairs.
--
-- From TibiaWiki BR (Albino Dragon): 5,000 HP, 2,250 experience, speed 105,
-- armor 35, mitigation 2.09%, immune to fire, earth 20% / energy 80% / ice 110%
-- damage taken, walks through fire, energy and poison fields, pushes objects,
-- not pushable, 50 charm points, bestiary Medium with 5 kills, occurrence very
-- rare, sounds, and the loot list. Race id 2416 and looktype 1683 from the
-- client 15.11 static data. Ours: the attacks, defense and the healing (copied
-- from the Dragon Lord, whose loot list it shares; TibiaWiki gives none), the
-- loot chances (the Dragon Lord's; platinum ours) and the albino dragon leather
-- chance (family rate chosen by Rodrigo: 8.33%, about 1 kill in 4 with loot x3).
-- No corpse of its own exists in the client data; the Dragon Lord's is used.
local mType = Game.createMonsterType("Albino Dragon")
local monster = {}

monster.description = "an albino dragon"
monster.experience = 2250
monster.outfit = {
	lookType = 1683,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.raceId = 2416
monster.Bestiary = {
	class = "Dragon",
	race = BESTY_RACE_DRAGON,
	toKill = 5,
	FirstUnlock = 2,
	SecondUnlock = 3,
	CharmsPoints = 50,
	Stars = 3,
	Occurrence = 3,
	Locations = "Dragonblaze Peaks, Dragon Lair (Ankrahmun), Dragon Lair (Fenrock), Hellgorge, Dragon Lair (Pits of Inferno).",
}

monster.health = 5000
monster.maxHealth = 5000
monster.race = "blood"
monster.corpse = 5984
monster.speed = 105
monster.manaCost = 0

monster.changeTarget = {
	interval = 4000,
	chance = 10,
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
	runHealth = 300,
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
	{ text = "FCHHHH!", yell = true },
	{ text = "GRRRRAAAWRR!", yell = true },
	{ text = "GNARRRRL!", yell = true },
}

monster.loot = {
	{ name = "gold coin", chance = 95300, maxCount = 237 },
	{ name = "platinum coin", chance = 50000, maxCount = 3 },
	{ name = "dragon ham", chance = 79790, maxCount = 2 },
	{ name = "green mushroom", chance = 12030 },
	{ id = 2842, chance = 9590 }, -- gemmed book
	{ name = "royal spear", chance = 9380, maxCount = 3 },
	{ name = "power bolt", chance = 5920, maxCount = 7 },
	{ name = "small sapphire", chance = 5590 },
	{ id = 3051, chance = 4550 }, -- energy ring
	{ name = "golden mug", chance = 3310 },
	{ id = 44157, chance = 8333 }, -- albino dragon leather
	{ name = "strong health potion", chance = 800 },
	{ name = "life crystal", chance = 650 },
	{ name = "strange helmet", chance = 520 },
	{ name = "tower shield", chance = 410 },
	{ name = "fire sword", chance = 350 },
	{ name = "royal helmet", chance = 260 },
	{ name = "dragon slayer", chance = 220 },
	{ name = "dragon scale mail", chance = 90 },
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -230 },
	{ name = "combat", interval = 2000, chance = 30, type = COMBAT_FIREDAMAGE, minDamage = -100, maxDamage = -220, range = 7, radius = 4, shootEffect = CONST_ANI_FIRE, effect = CONST_ME_FIREAREA, target = true },
	{ name = "firefield", interval = 2000, chance = 10, range = 7, radius = 4, shootEffect = CONST_ANI_FIRE, target = true },
	{ name = "combat", interval = 2000, chance = 22, type = COMBAT_FIREDAMAGE, minDamage = -150, maxDamage = -270, length = 8, spread = 3, effect = CONST_ME_FIREAREA, target = false },
}

monster.defenses = {
	defense = 35,
	armor = 35,
	mitigation = 2.09,
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_HEALING, minDamage = 57, maxDamage = 93, effect = CONST_ME_MAGIC_BLUE, target = false },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 20 },
	{ type = COMBAT_EARTHDAMAGE, percent = 80 },
	{ type = COMBAT_FIREDAMAGE, percent = 100 },
	{ type = COMBAT_LIFEDRAIN, percent = 0 },
	{ type = COMBAT_MANADRAIN, percent = 0 },
	{ type = COMBAT_DROWNDAMAGE, percent = 0 },
	{ type = COMBAT_ICEDAMAGE, percent = -10 },
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
