-- Gaia Family server: Mindmasher, Hive boss (bane) (2026-11-16). Ours: not in Canary v3.6.1.
-- Sources: TibiaWiki BR "Mindmasher" (our backup) for health, experience, abilities and resistances;
-- TibiaWiki EN "Mindmasher" (race id, sounds, abilities) and "Loot Statistics:Mindmasher" (59 kills:
-- chance = times dropped / kills, maxCount = the most seen). Speed, armor and mitigation as the Insectoid Worker. The weak copies use the upstream spells "mindmasher summon" and "mindmasher drown" (monster "Mindmasher summon").
-- Spawned by data-otservbr-global/scripts/family/hive_bosses.lua (the Hive underground, third stage only).
local mType = Game.createMonsterType("Mindmasher")
local monster = {}

monster.description = "Mindmasher"
monster.experience = 6000
monster.outfit = {
	lookType = 403,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.bosstiary = {
	bossRaceId = 855,
	bossRace = RARITY_BANE,
}

monster.health = 9500
monster.maxHealth = 9500
monster.race = "venom"
monster.corpse = 12525
monster.speed = 120
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
	illusionable = true,
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
	{ text = "Chrrr! Chrr!", yell = false },
	{ text = "Klk! Klk!", yell = false },
}

monster.loot = {
	{ id = 14083, chance = 100000, maxCount = 2 }, -- compound eye
	{ id = 14753, chance = 100000, maxCount = 3 }, -- dung ball (quest)
	{ id = 3031, chance = 100000, maxCount = 233 }, -- gold coin
	{ id = 3035, chance = 76271, maxCount = 4 }, -- platinum coin
	{ id = 239, chance = 52542, maxCount = 2 }, -- great health potion
	{ id = 238, chance = 47458, maxCount = 2 }, -- great mana potion
	{ id = 3029, chance = 44068, maxCount = 2 }, -- small sapphire
	{ id = 3032, chance = 38983, maxCount = 2 }, -- small emerald
	{ id = 3346, chance = 33898 }, -- ripper lance
	{ id = 3097, chance = 23729 }, -- dwarven ring
	{ id = 3037, chance = 15254 }, -- yellow gem
	{ id = 10392, chance = 10169 }, -- twin hooks
	{ id = 3271, chance = 5085 }, -- spike sword
	{ id = 3326, chance = 3390 }, -- epee
	{ id = 14088, chance = 1695 }, -- carapace shield
	{ id = 281, chance = 1695 }, -- giant shimmering pearl
	{ id = 14087, chance = 1695 }, -- grasshopper legs
}

monster.attacks = {
	{ name = "melee", interval = 2000, chance = 100, minDamage = 0, maxDamage = -100 },
	{ name = "combat", interval = 2000, chance = 15, type = COMBAT_MANADRAIN, minDamage = -30, maxDamage = -650, range = 7, effect = CONST_ME_MAGIC_BLUE, target = true },
	{ name = "drunk", interval = 2000, chance = 10, range = 7, radius = 4, effect = CONST_ME_STUN, target = false, duration = 6000 },
	{ name = "mindmasher drown", interval = 2000, chance = 10, target = true },
	{ name = "mindmasher summon", interval = 2000, chance = 8, target = false },
}

monster.defenses = {
	defense = 15,
	armor = 30,
	mitigation = 0.91,
	{ name = "combat", interval = 2000, chance = 30, type = COMBAT_HEALING, minDamage = 5, maxDamage = 20, effect = CONST_ME_MAGIC_BLUE, target = false },
	{ name = "invisible", interval = 2000, chance = 8, effect = CONST_ME_MAGIC_BLUE, target = false, duration = 3000 },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 0 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 0 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
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
