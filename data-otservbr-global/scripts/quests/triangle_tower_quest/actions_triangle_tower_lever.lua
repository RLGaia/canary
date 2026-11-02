-- FAMILY: the lever now opens and closes the brick wall at the tower entrance
-- (32566,32119,7) as a clean toggle. Upstream recreated the wall as item 1025
-- ("earth", an old pre-Canary wall id) and, with the lever back on 2772 and no
-- brick wall 1270 found, only stacked more earth, so after one close the tower
-- stayed shut until the next server start (checked in a self-test 2026-11-02).
local WALL_ID = 1270 -- brick wall, as placed on the map
local wallPosition = Position(32566, 32119, 7)

local othersTriangle = Action()
function othersTriangle.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local tile = Tile(wallPosition)
	if not tile then
		return true
	end
	local wall = tile:getItemById(WALL_ID)
	if wall then
		wall:remove()
		item:transform(2773)
	else
		-- also clears leftovers of the upstream "earth" wall
		local earth = tile:getItemById(1025)
		while earth do
			earth:remove()
			earth = tile:getItemById(1025)
		end
		Game.createItem(WALL_ID, 1, wallPosition)
		item:transform(2772)
	end
	return true
end

othersTriangle:uid(30034)
othersTriangle:register()
