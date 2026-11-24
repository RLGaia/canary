local voodooDoll = Action()

function voodooDoll.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: Treasure Hunt Quest: the doll in the dworc cave's pot gets its number (data-otservbr-global/lib/others/family_treasure_hunt.lua)
	if FamilyTreasureHunt and FamilyTreasureHunt.onVoodooDoll(player, item, target, toPosition) then
		return true
	end
	if target.itemid ~= 1 or not target:isPlayer() then
		return false
	end

	local text = ""
	if math.random(100) <= 5 then
		text = "You concentrate on your victim and hit the needle in the doll."
		player:addAchievement("Dark Voodoo Priest")
		toPosition:sendMagicEffect(CONST_ME_DRAWBLOOD, player)
	else
		text = "You concentrate on your victim, hit the needle in the doll.......but nothing happens."
	end

	player:say(text, TALKTYPE_MONSTER_SAY, false, player)
	return true
end

voodooDoll:id(3002)
voodooDoll:register()
