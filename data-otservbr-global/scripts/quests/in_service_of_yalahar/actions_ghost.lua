-- FAMILY: three ghost residues charge the charm and the third one calls no more ghosts
-- (TibiaWiki BR/EN: "three times", "Once it is filled, ghosts will not be attracted any longer");
-- upstream needed four (8825 -> 8859 -> 8827) and the last one still called two ghosts.
local config = {
	[8823] = 8824,
	[8824] = 8825,
	[8825] = 8827,
	[8859] = 8827,
}

local inServiceYalaharGhost = Action()
function inServiceYalaharGhost.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local transformId = config[target.itemid]
	if not transformId then
		return true
	end

	if transformId ~= 8827 then -- FAMILY
		for i = 1, 2 do
			Game.createMonster("Tormented Ghost", fromPosition)
		end
	end

	local charmItem = Tile(Position(32776, 31062, 7)):getItemById(target.itemid)
	if charmItem then
		charmItem:transform(transformId)
	end

	toPosition:sendMagicEffect(CONST_ME_ENERGYHIT)
	item:remove()
	player:say(transformId == 8827 and "The ghost charm is charged." or "The ghost charm is charging.", TALKTYPE_MONSTER_SAY) -- FAMILY: "charged" line ours

	if transformId == 8827 then -- FAMILY (upstream: target.itemid == 8859)
		player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Questline, 37)
		player:setStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Mission06, 3) -- StorageValue for Questlog "Mission 06: Frightening Fuel"
		player:removeItem(8822, 1)
	end
	return true
end

inServiceYalaharGhost:id(8826)
inServiceYalaharGhost:register()
