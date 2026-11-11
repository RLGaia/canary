-- FAMILY: Gaia Family server, A Pirate's Tail stealth mission (2026-11-11; scripts/family/rascacoon_stealth.lua).
-- TibiaWiki EN Pirat Patrol (BR has no page): kicks you out of the room if you get close to it, moves
-- back and forth in a small area, not pushable, sees invisible, no damage. HP, experience, armor and
-- speed are "?" on the wiki: ours. Base speed 0 so that it never wanders off on its own; the script
-- walks it along its path (and gives it speed while it walks, so the client shows the steps). Look:
-- the same pirat outfit and colours as the Pirat Guard (the EN pictures are identical).
local mType = Game.createMonsterType("Pirat Patrol")
local monster = {}

monster.name = "Pirat Patrol"
monster.description = "a pirat patrol"
monster.experience = 0
monster.outfit = {
	lookType = 1346,
	lookHead = 18,
	lookBody = 94,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.health = 1000
monster.maxHealth = 1000
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
	{ type = "bleed", condition = true },
}

mType:register(monster)
