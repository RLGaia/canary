local galthensTree = Action()
function galthensTree.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local hasExhaustion, message = player:kv():get("galthens-satchel") or 0, "Empty."
	if hasExhaustion < os.time() then
		local container = player:addItem(36813)
		container:addItem(36810, 1)
		-- FAMILY: the satchel also holds Galthen's notes (TibiaWiki BR/EN; upstream left them out)
		if FamilyGalthen then
			local notes = container:addItem(FamilyGalthen.items.parchment, 1)
			if notes then
				notes:setAttribute(ITEM_ATTRIBUTE_TEXT, FamilyGalthen.parchmentText)
				notes:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, "Ancient notes from the knight Galthen.")
			end
		end
		player:kv():set("galthens-satchel", os.time() + 30 * 24 * 60 * 60)
		message = "You have found a galthens satchel."
	end

	player:teleportTo(Position(32396, 32520, 7))
	player:getPosition():sendMagicEffect(CONST_ME_WATERSPLASH)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)

	return true
end

galthensTree:position(Position(32366, 32542, 8))
galthensTree:register()
