local iceAntHill = Action()

function iceAntHill.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local mast = { x = 32360, y = 31365, z = 7 }

	if target.itemid == 1079 and item.itemid == 7243 then
		if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 6 then
			toPosition:sendMagicEffect(CONST_ME_GROUNDSHAKER)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission03, 2) -- Questlog The Ice Islands Quest, Nibelor 2: Ecological Terrorism
			player:say("You fill the jug with ants.", TALKTYPE_MONSTER_SAY)
			item:transform(7244)
		end
	elseif target.itemid == 4940 and item.itemid == 7244 and toPosition.x == mast.x and toPosition.y == mast.y and toPosition.z == mast.z then
		if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 6 then
			toPosition:sendMagicEffect(CONST_ME_HITAREA)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 7)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission03, 3) -- Questlog The Ice Islands Quest, Nibelor 2: Ecological Terrorism
			if Family and Family.iceIslandsFixes then
				-- FAMILY: upstream removed an empty jug (7243) and left the full one in the backpack (2026-11-16)
				player:say("You release the termites on the bottom of the mast.", TALKTYPE_MONSTER_SAY) -- ours
				item:remove(1)
			else
				player:say("You released ants on the hill.", TALKTYPE_MONSTER_SAY)
				player:removeItem(7243, 1)
			end
		end
	end

	return true
end

iceAntHill:id(7243, 7244)
iceAntHill:register()
