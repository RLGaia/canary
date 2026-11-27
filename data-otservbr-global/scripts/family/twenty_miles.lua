-- Gaia Family server: Twenty Miles Beneath the Sea Quest, items, map objects and portals (2026-11-27). Ours.
-- Rules and sources: data-otservbr-global/lib/others/family_twenty_miles.lua.
--
-- * The piles of bones, the drowned seaman's skull, the cursed gold, the three chests, the nacre slabs, the
--   large seashells of Brandon's cave and the Sea Ear (statues, sundial).
-- * Every portal of the Seacrest Grounds and the cave, from a MoveEvent on its square (their map
--   destinations are cleared at startup).
-- Mr Brandon, the Guardian of the Deep Seas and Yeo call FamilyTwentyMiles from their own files, the
-- maelstrom behind Brandon from scripts/movements/oramond/seacrest.lua.
--
-- Switch: Family.twentyMiles (false = upstream: no quest, the helmet maelstrom).

Family = Family or {}
Family.twentyMiles = true

local M = FamilyTwentyMiles

local bones = Action()

function bones.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.twentyMiles then
		return false
	end
	return M.useBones(player, fromPosition)
end

for _, p in ipairs(M.bones) do
	bones:position(p)
end
bones:register()

local chests = Action()

function chests.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.twentyMiles then
		return false
	end
	return M.useChest(player, fromPosition)
end

chests:position(M.ringChest)
chests:position(M.shipChest)
chests:position(M.shrineChest)
chests:register()

local shells = Action()

function shells.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.twentyMiles then
		return false
	end
	return M.useShell(player, item, fromPosition)
end

for _, p in ipairs(M.shells) do
	shells:position(p)
end
shells:register()

local items = Action()

function items.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.twentyMiles or type(target) ~= "userdata" or not target.isItem or not target:isItem() then
		return false
	end
	local id = item.itemid
	if id == M.skull then
		return M.laySkull(player, item, target)
	elseif id == M.gold then
		return M.useGold(player, item, target, toPosition)
	elseif id == M.seaEar then
		return M.useSeaEar(player, target, toPosition)
	end
	return M.useSlab(player, item, target, toPosition)
end

items:id(M.skull, M.gold, M.seaEar, M.blue, M.yellow, M.red)
items:register()

local portals = MoveEvent()

function portals.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.twentyMiles then
		return true
	end
	M.stepPortal(player, position, fromPosition)
	return true
end

portals:type("stepin")
for _, k in ipairs(M.portalPositions) do
	portals:position(M.toPosition(k))
end
portals:register()

local startup = GlobalEvent("FamilyTwentyMilesStartup")

function startup.onStartup()
	if Family.twentyMiles then
		M.setup()
	end
	return true
end

startup:register()
