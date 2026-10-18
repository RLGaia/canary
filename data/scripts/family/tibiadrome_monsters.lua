-- Gaia Family server: the five Tibiadrome creatures (2026-10-18). Ours, not
-- upstream. Our server had the Tibiadrome rooms in the map but not its
-- creatures. Names and looks are Tibia's (TibiaWiki); hit points are Tibia's
-- for the first Drome level. The attacks are ours (TibiaWiki has no numbers),
-- following what each creature does in Tibia:
--
--   Domestikion  750 hp, earth and melee; makes nearby Drome creatures hit
--                harder (done in tibiadrome.lua).
--   Hoodinion    800 hp, fire and ice areas.
--   Mearidion    850 hp, keeps its distance and shoots death missiles.
--   Murmillion  1100 hp, strong melee, paralyses its target every 10 seconds.
--   Scissorion   950 hp, physical and earth, turns invisible.
--
-- The values below are for wave 1 of a level 100 party; tibiadrome.lua raises
-- hit points and damage with the wave and the party's level. No experience,
-- loot or corpse, as in Tibia.

local function register(name, def)
	local mType = Game.createMonsterType(name)
	local monster = {}
	monster.description = "a " .. name:lower()
	monster.experience = 0
	monster.outfit = { lookType = def.lookType, lookHead = 0, lookBody = 0, lookLegs = 0, lookFeet = 0, lookAddons = 0, lookMount = 0 }
	monster.health = def.health
	monster.maxHealth = def.health
	monster.race = def.race or "blood"
	monster.corpse = 0
	monster.speed = def.speed or 220
	monster.manaCost = 0
	monster.changeTarget = { interval = 4000, chance = 15 }
	monster.strategiesTarget = { nearest = 70, health = 15, damage = 15 }
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
		targetDistance = def.targetDistance or 1,
		runHealth = 0,
		healthHidden = false,
		isBlockable = false,
		canWalkOnEnergy = true,
		canWalkOnFire = true,
		canWalkOnPoison = true,
	}
	monster.light = { level = 0, color = 0 }
	monster.voices = { interval = 5000, chance = 10 }
	monster.loot = {}
	monster.attacks = def.attacks
	monster.defenses = def.defenses or { defense = 25, armor = 25, mitigation = 0.8 }
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
end

register("Domestikion", {
	lookType = 1426,
	health = 750,
	attacks = {
		{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -90 },
		{ name = "combat", interval = 2000, chance = 20, type = COMBAT_EARTHDAMAGE, minDamage = -40, maxDamage = -80, range = 5, radius = 2, shootEffect = CONST_ANI_EARTH, effect = CONST_ME_GREEN_RINGS, target = true },
	},
})

register("Hoodinion", {
	lookType = 1424,
	health = 800,
	targetDistance = 3,
	attacks = {
		{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -60 },
		{ name = "combat", interval = 2000, chance = 20, type = COMBAT_FIREDAMAGE, minDamage = -50, maxDamage = -100, range = 6, radius = 3, shootEffect = CONST_ANI_FIRE, effect = CONST_ME_FIREAREA, target = true },
		{ name = "combat", interval = 2000, chance = 15, type = COMBAT_ICEDAMAGE, minDamage = -60, maxDamage = -110, length = 5, spread = 0, effect = CONST_ME_ICEAREA, target = false },
	},
})

register("Mearidion", {
	lookType = 1425,
	health = 850,
	targetDistance = 4,
	attacks = {
		{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -40 },
		{ name = "combat", interval = 2000, chance = 40, type = COMBAT_DEATHDAMAGE, minDamage = -50, maxDamage = -110, range = 7, shootEffect = CONST_ANI_DEATH, effect = CONST_ME_MORTAREA, target = true },
	},
})

register("Murmillion", {
	lookType = 1422,
	health = 1100,
	speed = 230,
	attacks = {
		{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -130 },
		{ name = "speed", interval = 10000, chance = 100, speedChange = -400, range = 7, effect = CONST_ME_MAGIC_RED, target = true, duration = 3000 },
	},
	defenses = { defense = 35, armor = 35, mitigation = 1.2 },
})

register("Scissorion", {
	lookType = 1423,
	health = 950,
	speed = 240,
	attacks = {
		{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -110 },
		{ name = "combat", interval = 2000, chance = 15, type = COMBAT_EARTHDAMAGE, minDamage = -40, maxDamage = -90, range = 1, effect = CONST_ME_GREEN_RINGS, target = true },
	},
	defenses = {
		defense = 25,
		armor = 25,
		mitigation = 0.8,
		{ name = "invisible", interval = 2000, chance = 10, effect = CONST_ME_MAGIC_BLUE },
	},
})
