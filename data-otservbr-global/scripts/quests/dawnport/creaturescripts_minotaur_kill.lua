local minotaurKill = CreatureEvent("MorrisMinotaurDeath")
function minotaurKill.onDeath(creature, _corpse, _lastHitKiller, mostDamageKiller)
	onDeathForParty(creature, mostDamageKiller, function(creature, player)
		-- FAMILY: the task starts with the first kill on Dawnport, without asking Mr Morris first
		-- (TibiaWiki BR and EN); upstream only counted after accepting it (2026-11-01).
		local town = player:getTown()
		if player:getStorageValue(Storage.Quest.U10_55.Dawnport.MorrisMinos) < 1 and town and town:getId() == TOWNS_LIST.DAWNPORT then
			player:setStorageValue(Storage.Quest.U10_55.Dawnport.MorrisMinos, 1)
			player:setStorageValue(Storage.Quest.U10_55.Dawnport.MorrisMinosCount, 0)
		end
		local killAmount = math.max(player:getStorageValue(Storage.Quest.U10_55.Dawnport.MorrisMinosCount), 0)
		if player:getStorageValue(Storage.Quest.U10_55.Dawnport.MorrisMinos) == 1 and killAmount < 20 then
			player:setStorageValue(Storage.Quest.U10_55.Dawnport.MorrisMinosCount, killAmount + 1)
		end
	end)
	return true
end

minotaurKill:register()
