local fruits = { 3584, 3585, 3586, 3587, 3588, 3589, 3590, 3591, 3592, 3593, 3595, 3596, 5096, 8011, 8012, 8013 }

local juiceSqueezer = Action()

function juiceSqueezer.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- The Dream Courts Quest
	if target.itemid == 29995 then
		target:transform(30003)
		return true
	end

	if table.contains(fruits, target.itemid) and player:removeItem(2874, 1, 0) then
		target:remove(1)
		-- FAMILY: coconut milk (fluid 15) from a coconut, fruit juice (14) from the other fruits, as in TibiaWiki BR/EN
		-- (2026-11-16; upstream gave fruit juice for a coconut and fluid 21 for the rest, so no coconut milk for Hot Cuisine)
		player:addItem(2874, target.itemid == 3589 and 15 or 14)
		return true
	end
end

juiceSqueezer:id(5865)
juiceSqueezer:register()
