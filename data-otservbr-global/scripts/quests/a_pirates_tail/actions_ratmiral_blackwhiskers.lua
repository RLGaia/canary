local config = {
	boss = {
		name = "Ratmiral Blackwhiskers",
		position = Position(33904, 31351, 14),
		-- FAMILY: the fight in four stages (scripts/family/ratmiral_fight.lua); Ratmiral comes in stage 4
		createFunction = function()
			local R = FamilyPiratesTail and FamilyPiratesTail.ratmiral
			if R and R.enabled() then
				return R.start()
			end
			return Game.createMonster("Ratmiral Blackwhiskers", Position(33904, 31351, 14), true, true) ~= nil
		end,
	},
	requiredLevel = 250,
	-- FAMILY: the team starts in the cave south of the ship (stage 1), not on the upper deck
	playerPositions = {
		{ pos = Position(33893, 31388, 15), teleport = Position(33903, 31372, 15), effect = CONST_ME_TELEPORT },
		{ pos = Position(33894, 31388, 15), teleport = Position(33903, 31372, 15), effect = CONST_ME_TELEPORT },
		{ pos = Position(33895, 31388, 15), teleport = Position(33903, 31372, 15), effect = CONST_ME_TELEPORT },
		{ pos = Position(33896, 31388, 15), teleport = Position(33903, 31372, 15), effect = CONST_ME_TELEPORT },
		{ pos = Position(33897, 31388, 15), teleport = Position(33903, 31372, 15), effect = CONST_ME_TELEPORT },
	},
	specPos = {
		from = Position(33888, 31344, 14),
		to = Position(33920, 31376, 15),
	},
	exit = Position(33891, 31197, 7),
}

local lever = BossLever(config)
lever:position(Position(33892, 31388, 15))
lever:register()
