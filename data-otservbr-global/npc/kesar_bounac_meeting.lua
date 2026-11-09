-- FAMILY: Gaia Family server (ours, 2026-11-09): Kesar the Younger at the meeting east of Bounac (The Order of the
-- Lion Quest). Created and removed by scripts/family/order_of_the_lion.lua for the meeting only; the lines
-- are said by that script. Outfit as the monster Kesar.
local npcType = Game.createNpcType("Kesar (Bounac Meeting)")
local npcConfig = {}

npcConfig.name = "Kesar the Younger"
npcConfig.description = "Kesar the Younger"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0

npcConfig.outfit = {
	lookType = 1317,
	lookHead = 21,
	lookBody = 21,
	lookLegs = 21,
	lookFeet = 21,
	lookAddons = 2,
}

npcConfig.flags = {
	floorchange = false,
}

npcType:register(npcConfig)
