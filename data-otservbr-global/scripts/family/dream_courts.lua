-- Gaia Family server: The Dream Courts Quest, world objects (2026-11-23). Ours, not upstream.
-- Andrew Lyze's chest room (world/custom/family-dream-courts.otbm), the eighth ward stone by hand, the
-- dream catcher pole in the Nightmare Beast's room (our map has none) and the beast's curse.
-- Talk and rules: lib/others/family_dream_courts.lua (FamilyDreamCourts).

local D = FamilyDreamCourts

-- The brass-shod chest behind the magic portal.
local chest = Action()
function chest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not D.enabled() then
		return false
	end
	return D.useChest(player)
end
chest:position(D.ROOM.chest)
chest:register()

-- The blue magic forcefield back to Andrew Lyze.
local field = MoveEvent()
function field.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player then
		D.leaveChestRoom(player)
	end
	return true
end
field:aid(D.ROOM_FIELD_AID)
field:register()

-- The eighth ward stone (buried cathedral) is used by hand after the Faceless Bane (EN, BR).
local stone = Action()
function stone.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not D.enabled() then
		return false
	end
	return D.useCathedralStone(player, item)
end
stone:position(D.CATHEDRAL_STONE)
stone:register()

-- The Nightmare Beast's curse (registered in the beast's monster file).
local beastThink = CreatureEvent("familyNightmareThink")
function beastThink.onThink(creature, interval)
	if not D.enabled() or not creature:isMonster() then
		return true
	end
	if D.curse.beast ~= creature:getId() then
		D.resetCurse()
		D.curse.beast = creature:getId()
	end
	D.curseThink(creature)
	return true
end
beastThink:register()

local beastDeath = CreatureEvent("familyNightmareDeath")
function beastDeath.onDeath(creature, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	if D.enabled() then
		D.resetCurse()
		D.curse.beast = nil
		D.curse.nextAt = math.huge
	end
	return true
end
beastDeath:register()

-- At startup: the boss of the day, the dream catcher pole and a check of the chest room.
local startup = GlobalEvent("FamilyDreamCourtsStartup")
function startup.onStartup()
	if not D.enabled() then
		return true
	end
	local boss = D.pickBossOfTheDay()
	local tile = Tile(D.POLE_POS)
	if tile and not tile:getItemById(D.POLE) and not tile:getItemById(D.POLE_USED) then
		Game.createItem(D.POLE, 1, D.POLE_POS)
	elseif not tile then
		logger.error("[FamilyDreamCourts] no square for the dream catcher pole at {}", D.POLE_POS:toString())
	end
	local room = Tile(D.ROOM.chest)
	if not room or not room:getItemById(D.ROOM_CHEST) then
		logger.error("[FamilyDreamCourts] chest room missing (world/custom/family-dream-courts.otbm)")
	end
	logger.info("[FamilyDreamCourts] arena champion of the day: {}", boss.name)
	return true
end
startup:register()
