local inServiceYalaharMorik = Action()
function inServiceYalaharMorik.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.uid == 1015 then
		-- FAMILY: Morik comes again when he is gone (died elsewhere, left behind, server restart) and
		-- you have no helmet; upstream called him only once, so a failed fight left you stuck (ours)
		local again = false
		if Family.inServiceOfYalahar and player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MorikSummon) == 1 and player:getItemCount(8820) == 0 then
			again = true
			for _, spectator in ipairs(Game.getSpectators(fromPosition, false, false, 10, 10, 10, 10)) do
				if spectator:isMonster() and spectator:getName():lower() == "morik the gladiator" then
					again = false
				end
			end
		end
		if player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Questline) == 31 and (player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MorikSummon) < 1 or again) then
			local ret = Game.createMonster("Morik the Gladiator", fromPosition)
			if ret then
				ret:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.MorikSummon, 1)
			end
		end
	end
	return true
end

inServiceYalaharMorik:uid(1015)
inServiceYalaharMorik:register()
