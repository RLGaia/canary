local config = {
	treesBeaver = {
		Position(32515, 31927, 7), -- Tree 01
		Position(32474, 31947, 7), -- Tree 02
		Position(32458, 31997, 7), -- Tree 03
	},
}
local TheNewFrontier = Storage.Quest.U8_54.TheNewFrontier

local beaverTrees = Action()

-- FAMILY: The New Frontier review (2026-11-09). TibiaWiki BR/EN: 4 enraged
-- squirrels and 1 war wolf with 4 wolves (upstream 3 and 5); EN messages;
-- upstream let anyone mark the first two trees (missing brackets).
local function spawn(name, count, position)
	for i = 1, count do
		Game.createMonster(name, position, true)
	end
	position:sendMagicEffect(CONST_ME_TELEPORT)
end

function beaverTrees.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(TheNewFrontier.Questline) ~= 5 then
		return false
	end
	if toPosition == config.treesBeaver[1] and player:getStorageValue(TheNewFrontier.Mission02.Beaver1) < 1 then
		spawn("enraged squirrel", 4, toPosition)
		player:setStorageValue(TheNewFrontier.Mission02.Beaver1, 1)
		player:say("You have marked the tree but also angered the squirrel family who lived on it!", TALKTYPE_MONSTER_SAY)
	elseif toPosition == config.treesBeaver[2] and player:getStorageValue(TheNewFrontier.Mission02.Beaver2) < 1 then
		spawn("wolf", 4, toPosition)
		spawn("war wolf", 1, toPosition)
		player:setStorageValue(TheNewFrontier.Mission02.Beaver2, 1)
		player:say("You have marked the tree but it seems someone marked it already! He is not happy with your actions and he brought friends!", TALKTYPE_MONSTER_SAY)
	elseif toPosition == config.treesBeaver[3] and player:getStorageValue(TheNewFrontier.Mission02.Beaver3) < 1 then
		spawn("thieving squirrel", 1, toPosition)
		player:setStorageValue(TheNewFrontier.Mission02.Beaver3, 1)
		player:say("You have marked the tree but its former inhabitant has stolen your bait! Get it, before it runs away!", TALKTYPE_MONSTER_SAY)
		item:remove()
	else
		return false
	end
	return true
end

beaverTrees:id(9843)
beaverTrees:register()
