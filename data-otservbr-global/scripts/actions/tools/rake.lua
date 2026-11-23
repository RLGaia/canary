local rake = Action()

function rake.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: Tending Gloothworms, Rake Away (lib/others/family_oramond_tasks.lua)
	if FamilyOramondTasks and FamilyOramondTasks.rakeTube(player, target, toPosition) then
		return true
	end
	-- FAMILY: Threatened Dreams, The Fairy Treasure: scratch the sentient stones' backs (lib/others/family_threatened_dreams.lua)
	if FamilyThreatenedDreams and FamilyThreatenedDreams.rakeStone(player, target, toPosition) then
		return true
	end
	-- FAMILY: no Lua error when the rake is used on nothing or a creature
	if not target or type(target) ~= "userdata" or not target.getId then
		return false
	end
	-- Wrath of the Emperor Mission02
	if target.itemid == 11366 then
		player:addItem(11329, 1)
		player:say("You dig out a handful of ordinary clay.", TALKTYPE_MONSTER_SAY)
		-- The Shattered Isles Parrot ring
	elseif target.itemid == 6094 then
		if player:getStorageValue(Storage.Quest.U7_8.TheShatteredIsles.TheGovernorDaughter) == 1 then
			toPosition:sendMagicEffect(CONST_ME_POFF)
			-- FAMILY (2026-11-17): the ring goes into the backpack when the rake is carried (BR: "se você
			-- utilizar o Rake fora de sua mochila, o ring cairá no chão"); upstream always dropped it.
			local carrier = item:getTopParent()
			local carried = carrier and carrier.isPlayer and carrier:isPlayer() and carrier:getId() == player:getId()
			if not (FamilyShatteredIsles.enabled() and carried and player:addItem(6093, 1)) then
				Game.createItem(6093, 1, Position(32422, 32770, 1))
			end
			player:say("You have found a ring.", TALKTYPE_MONSTER_SAY)
			player:setStorageValue(Storage.Quest.U7_8.TheShatteredIsles.TheGovernorDaughter, 2)
		end
	end
	return true
end

rake:id(3452)
rake:register()
