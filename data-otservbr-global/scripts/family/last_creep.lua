-- Gaia Family server: Last Creep Standing, map objects and items (2026-11-25). Ours, not upstream.
-- Rules and sources: data-otservbr-global/lib/others/family_last_creep.lua.
--
-- * The shapechanger, the arena's 8 teleporters (action ids 48809-48816) and the prize room's way out
--   (48817), the magic tiles' speed, the prize chest, the reward box, the shapeshifter ring.
-- * Login inside the arena outside a round: back to Casper's room.
-- * Startup: the dummies and books in Casper's room, the magic tiles start changing.
--
-- Switch: Family.lastCreep (false = Casper only says his rhymes, nothing else works).

Family = Family or {}
Family.lastCreep = true

local L = FamilyLastCreep

local wand = Action()

function wand.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.lastCreep then
		return false
	end
	return L.useWand(player)
end

wand:id(L.wand)
wand:register()

for index in ipairs(L.forms) do
	local field = MoveEvent()
	function field.onStepIn(creature, item, position, fromPosition)
		local player = creature:getPlayer()
		if player and Family.lastCreep then
			L.enterTeleport(player, index)
		end
		return true
	end
	field:type("stepin")
	field:aid(L.firstTeleportAid + index - 1)
	field:register()
end

local prizeExit = MoveEvent()

function prizeExit.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player then
		player:teleportTo(L.casperRoom)
		L.casperRoom:sendMagicEffect(CONST_ME_TELEPORT)
	end
	return true
end

prizeExit:type("stepin")
prizeExit:aid(L.prizeExitAid)
prizeExit:register()

local tiles = MoveEvent()

function tiles.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player and Family.lastCreep and L.inBox(position, L.hall) then
		L.onTile(player, item.itemid)
	end
	return true
end

tiles:type("stepin")
for id in pairs(L.tileSpeed) do
	tiles:id(id)
end
tiles:register()

local chest = Action()

function chest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.lastCreep then
		return false
	end
	return L.usePrizeChest(player)
end

chest:position(L.prizeChest)
chest:register()

local box = Action()

function box.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.lastCreep then
		return false
	end
	return L.openRewardBox(player, item)
end

box:id(L.rewardBox)
box:register()

local ring = MoveEvent()

function ring.onEquip(player, item, slot, isCheck)
	if not isCheck and Family.lastCreep then
		L.wearRing(player, item)
	end
	return true
end

ring:type("equip")
ring:slot("ring")
ring:id(L.ring)
ring:register()

local ringOff = MoveEvent()

function ringOff.onDeEquip(player, item, slot, isCheck)
	return true
end

ringOff:type("deequip")
ringOff:slot("ring")
ringOff:id(L.ring)
ringOff:register()

local login = CreatureEvent("FamilyLastCreepLogin")

function login.onLogin(player)
	if Family.lastCreep then
		L.onLogin(player)
	end
	return true
end

login:register()

local startup = GlobalEvent("FamilyLastCreepStartup")

function startup.onStartup()
	if Family.lastCreep then
		L.setup()
	end
	return true
end

startup:register()
