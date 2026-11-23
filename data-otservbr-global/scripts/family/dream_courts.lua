-- Gaia Family server: The Dream Courts Quest, world objects (2026-11-23). Ours, not upstream.
-- Andrew Lyze's chest room (world/custom/family-dream-courts.otbm), the eighth ward stone by hand, the
-- dream catcher pole in the Nightmare Beast's room (our map has none) and the beast's curse; the Haunted
-- Nexus portals, Key 3200 and the cathedral reward chest, the powerful Vibrancy unlock at login.
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

-- The three dimensional portals of the Haunted Nexus (ectoplasm travel).
local nexus = MoveEvent()
function nexus.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not D.enabled() then
		return true
	end
	D.nexusStep(player, position, fromPosition)
	return true
end
for _, n in ipairs(D.NEXUS) do
	nexus:position(n.pos)
end
nexus:register()

-- The graves of the buried cathedral (Key 3200).
local graves = Action()
function graves.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not D.enabled() then
		return false
	end
	return D.searchGrave(player)
end
for _, pos in ipairs(D.GRAVES) do
	graves:position(pos)
end
graves:register()

-- The reward chest behind the Key 3200 door.
local rewardChest = Action()
function rewardChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not D.enabled() then
		return false
	end
	return D.useRewardChest(player)
end
rewardChest:position(D.REWARD_CHEST)
rewardChest:register()

-- Characters who already finished the quest get the powerful Vibrancy imbuement.
local login = CreatureEvent("FamilyDreamCourtsLogin")
function login.onLogin(player)
	if D.enabled() and D.questDone(player) and (player:getStorageValue(D.S.Vibrancy) < 1 or player:getStorageValue(0) ~= 0) then
		D.unlockVibrancy(player)
	end
	return true
end
login:register()

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
	for i, n in ipairs(D.NEXUS) do
		D.nexusArrival[i] = D.findArrival(n.pos)
		if not D.nexusArrival[i] then
			logger.error("[FamilyDreamCourts] no free square next to the {} portal", n.name)
		end
	end
	local door = Tile(D.REWARD_DOOR) and Tile(D.REWARD_DOOR):getItemById(5124)
	if door then
		door:setActionId(D.KEY_AID) -- the door had no key number on our map
	else
		logger.error("[FamilyDreamCourts] Key 3200 door missing")
	end
	local room = Tile(D.ROOM.chest)
	if not room or not room:getItemById(D.ROOM_CHEST) then
		logger.error("[FamilyDreamCourts] chest room missing (world/custom/family-dream-courts.otbm)")
	end
	logger.info("[FamilyDreamCourts] arena champion of the day: {}", boss.name)
	return true
end
startup:register()
