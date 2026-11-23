-- Gaia Family server: Threatened Dreams Quest, world objects (2026-11-22). Ours, not upstream.
-- The Fairy Treasure (drawers, beds, presents, fly agaric, old map, sun mosaic), the swans of Feyrist
-- (The Swan Feather Cloak), the happy sentient oaks and blessed acorns.
-- Talk and rules: lib/others/family_threatened_dreams.lua (FamilyThreatenedDreams).

local D = FamilyThreatenedDreams

-- The chests of drawers in the children's rooms: the milk tooth, otherwise they open as usual.
for child, room in pairs(D.CHILDREN) do
	local drawers = Action()
	function drawers.onUse(player, item, fromPosition, target, toPosition, isHotkey)
		if D.useDrawers(player, child) then
			return true
		end
		return false -- opens as usual
	end
	for _, pos in ipairs(room.drawers) do
		drawers:position(pos)
	end
	drawers:register()
end

-- The Tooth Fairy's presents on the children's beds.
local present = Action()
function present.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if D.usePresent(player, item, toPosition) then
		return true
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This present is meant for a child's pillow.") -- ours
	return true
end
present:id(D.PRESENT)
present:register()

-- The big fly agaric in the Fields of Glory hides the fourth map part.
local agaric = Action()
function agaric.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return D.useFlyAgaric(player)
end
agaric:position(D.FLY_AGARIC)
agaric:register()

-- The old map.
local oldMap = Action()
function oldMap.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not D.enabled() then
		return false
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, D.OLD_MAP_TEXT)
	return true
end
oldMap:id(D.OLD_MAP)
oldMap:register()

-- The small stones in the centre of the sun mosaic south of Thais.
local treasure = Action()
function treasure.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return D.useTreasure(player)
end
treasure:position(D.TREASURE)
treasure:register()

-- The squares around the eight swans of Feyrist (swan feathers by day).
local swans = MoveEvent()
function swans.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player then
		D.swanStep(player, position)
	end
	return true
end
for _, swanPos in ipairs(D.SWANS) do
	for dx = -D.SWAN_RANGE, D.SWAN_RANGE do
		for dy = -D.SWAN_RANGE, D.SWAN_RANGE do
			swans:position(Position(swanPos.x + dx, swanPos.y + dy, swanPos.z))
		end
	end
end
swans:register()

-- A watering can on a happy sentient oak gives a blessed acorn.
local wateringCan = Action()
function wateringCan.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return D.waterOak(player, target)
end
wateringCan:id(650)
wateringCan:register()

-- Blessed acorns heal.
local acorn = Action()
function acorn.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return D.eatAcorn(player, item)
end
acorn:id(D.BLESSED_ACORN)
acorn:register()
