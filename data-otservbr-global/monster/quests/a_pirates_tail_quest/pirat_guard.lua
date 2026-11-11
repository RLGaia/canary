-- FAMILY: Gaia Family server, A Pirate's Tail stealth mission (2026-11-11; scripts/family/rascacoon_stealth.lua).
-- TibiaWiki EN Pirat Guard (BR has no page): kicks you out of the room if you get close to it, does not
-- move, not pushable, sees invisible, no damage. HP, experience and armor are "?" on the wiki: ours.
-- Speed: EN says 40; here 0, because a monster with speed walks around when players are near, and the
-- guards must stand still. Look: the pirat outfit in the colours of the EN picture (fitted on the client
-- 15.11 sprites). Not attackable (the wiki gives no health); the script throws out anyone next to it.
local mType = Game.createMonsterType("Pirat Guard")
local monster = {}

monster.name = "Pirat Guard"
monster.description = "a pirat guard"
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
