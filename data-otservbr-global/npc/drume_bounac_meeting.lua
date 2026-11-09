-- FAMILY: Gaia Family server (ours, 2026-11-09): Drume at the meeting east of Bounac (The Order of the
-- Lion Quest). Created and removed by scripts/family/order_of_the_lion.lua for the meeting only; the lines
-- are said by that script. Outfit as the monster Drume.
local npcType = Game.createNpcType("Drume (Bounac Meeting)")
local npcConfig = {}

npcConfig.name = "Drume"
npcConfig.description = "Drume"

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 0
npcConfig.walkRadius = 0

npcConfig.outfit = {
	lookType = 1317,
	lookHead = 38,
	lookBody = 76,
	lookLegs = 57,
	lookFeet = 114,
	lookAddons = 2,
}

npcConfig.flags = {
	floorchange = false,
}

npcType:register(npcConfig)
