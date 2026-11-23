local config = {
	boss = {
		name = "Megasylvan Yselda",
		position = Position(32619, 32493, 12),
	},
	requiredLevel = 250,
	playerPositions = {
		{ pos = Position(32578, 32500, 12), teleport = Position(32619, 32498, 12) },
		{ pos = Position(32578, 32501, 12), teleport = Position(32619, 32498, 12) },
		{ pos = Position(32578, 32502, 12), teleport = Position(32619, 32498, 12) },
		{ pos = Position(32578, 32503, 12), teleport = Position(32619, 32498, 12) },
		{ pos = Position(32578, 32504, 12), teleport = Position(32619, 32498, 12) },
	},
	specPos = {
		from = Position(32601, 32486, 12),
		to = Position(32633, 32509, 12),
	},
	exit = Position(32580, 32480, 12),
	-- FAMILY: Galthen and the Lost Queen (lib/others/family_galthen.lua): her four Megasylvan Saplings in
	-- the corners (TibiaWiki EN; the map has the corner plants) and the soup kettle first (BR, EN)
	monsters = {
		{ name = "Megasylvan Sapling", pos = Position(32609, 32489, 12) },
		{ name = "Megasylvan Sapling", pos = Position(32628, 32488, 12) },
		{ name = "Megasylvan Sapling", pos = Position(32609, 32504, 12) },
		{ name = "Megasylvan Sapling", pos = Position(32629, 32506, 12) },
	},
	onUseExtra = function(player)
		if FamilyGalthen and Family.galthen and FamilyGalthen.state(player) < 6 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The sleeping carnisylvans do not let you pass yet. Prepare the soup in the kettle below first.") -- ours
			return false
		end
		return true
	end,
}

local lever = BossLever(config)
lever:position({ x = 32578, y = 32499, z = 12 })
lever:register()
