local iceCure = Action()
function iceCure.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if target.itemid ~= 7106 then
		return false
	end

	-- FAMILY: only while Nilsor needs the water, by day, one ingredient every 5 minutes (TibiaWiki BR/EN;
	-- lib/others/family_ice_islands.lua, 2026-11-16)
	if Family and Family.iceIslandsFixes then
		return FamilyIceIslands.fillWaterskin(player, item, toPosition)
	end

	if player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) >= 21 then
		toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		player:say("You take some hot water from the geyser.", TALKTYPE_MONSTER_SAY)
		item:transform(7246)
	end
	return true
end

iceCure:id(7286)
iceCure:register()
