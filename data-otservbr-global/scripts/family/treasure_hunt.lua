-- Gaia Family server: the Treasure Hunt Quest, map objects (2026-11-24). Ours, not upstream.
-- Rules and sources: data-otservbr-global/lib/others/family_treasure_hunt.lua.
--
-- * The chest behind Wyrdin's door gives the old pirate poem once Wyrdin decrypted the text.
-- * The dworc cave below the dig spot (world/custom/family-treasure-hunt.otbm): the 4 levers roll
--   their dice, the teleporter lets through only who carries the voodoo doll whose number the dice
--   show (else back one square), the way out, the remains of a pirate.
-- * Klaus' logbook chest (the rock of the alcove north of him removed, the chest placed), the
--   bottom of Captain Nathaniel's boat, the floor under Mac Noodles' trough.
-- * Treasure Hunt Island: the rum flask on the snake head, the bridge teleporter, the island's
--   magic forcefields (action ids 48792-48807, destinations ours), the deck and hall squares, the
--   two treasure chests.
-- * Startup: the 3 giant tree carvings, the sealed door's action id, the chests made immovable,
--   the island's teleporters and statues, the moving spikes and the treasure room's daily gems.
-- The fire bug, the shovel and the voodoo doll call FamilyTreasureHunt from their own scripts.
--
-- Switch: Family.treasureHunt (false = none of the above; Wyrdin and the items act as upstream).

Family = Family or {}
Family.treasureHunt = true

local T = FamilyTreasureHunt

local chest = Action()

function chest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.treasureHunt then
		return false
	end
	return T.usePoemChest(player)
end

chest:position(T.poemChest)
chest:register()

for index, pos in ipairs(T.levers) do
	local lever = Action()
	function lever.onUse(player, item, fromPosition, target, toPosition, isHotkey)
		if not Family.treasureHunt or (item.itemid ~= 2772 and item.itemid ~= 2773) then
			return false
		end
		return T.pullLever(player, item, index)
	end
	lever:position(pos)
	lever:register()
end

local remains = Action()

function remains.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.treasureHunt or item.itemid ~= 9180 then
		return false
	end
	return T.useRemains(player)
end

remains:position(T.remains)
remains:register()

local logbook = Action()

function logbook.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.treasureHunt then
		return false
	end
	return T.useLogbookChest(player)
end

logbook:position(T.logbookChest)
logbook:register()

local boat = Action()

function boat.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.treasureHunt or item.itemid ~= 1759 then
		return false
	end
	return T.useBoat(player)
end

boat:position(T.boat)
boat:register()

local noodles = Action()

function noodles.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.treasureHunt then
		return false
	end
	return T.useNoodlesFloor(player)
end

noodles:position(T.noodlesFloor)
noodles:register()

local gate = MoveEvent()

function gate.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if not T.codeOpen(player) and not player:getGroup():getAccess() then
		player:teleportTo(T.gateBack, true)
		T.gateBack:sendMagicEffect(CONST_ME_POFF)
		return true
	end
	player:teleportTo(T.arrival)
	T.arrival:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

gate:type("stepin")
gate:aid(T.gateAid)
gate:register()

local exit = MoveEvent()

function exit.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	player:teleportTo(T.exitTo)
	T.exitTo:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

exit:type("stepin")
exit:aid(T.exitAid)
exit:register()

-- Treasure Hunt Island ------------------------------------------------------

local rumFlask = Action()

function rumFlask.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.treasureHunt then
		return false
	end
	return T.onRum(player, item, target, toPosition)
end

rumFlask:id(5552)
rumFlask:register()

local bridge = MoveEvent()

function bridge.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player then
		T.crossBridge(player)
	end
	return true
end

bridge:type("stepin")
bridge:aid(T.bridgeAid)
bridge:register()

for index in ipairs(T.teleports) do
	local field = MoveEvent()
	function field.onStepIn(creature, item, position, fromPosition)
		local player = creature:getPlayer()
		if player then
			T.useTeleport(player, index)
		end
		return true
	end
	field:type("stepin")
	field:aid(T.firstTeleportAid + index - 1)
	field:register()
end

local deck = MoveEvent()

function deck.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player and Family.treasureHunt and not player:getGroup():getAccess() then
		T.onDeck(player, position, fromPosition)
	end
	return true
end

deck:type("stepin")
for x = T.deck.x1, T.deck.x2 do
	for y = T.deck.y1, T.deck.y2 do
		deck:position(Position(x, y, T.deck.z))
	end
end
deck:register()

local hall = MoveEvent()

function hall.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player and Family.treasureHunt and not player:getGroup():getAccess() then
		T.onHall(player, position)
	end
	return true
end

hall:type("stepin")
for x = T.hall.x1, T.hall.x2 do
	for y = T.hall.y1, T.hall.y2 do
		hall:position(Position(x, y, T.hall.z))
	end
end
hall:register()

local telescope = Action()

function telescope.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.treasureHunt then
		return false
	end
	return T.useTreasureChest(player, "Telescope", 9616, 1, "You have found a bejeweled ship's telescope.")
end

telescope:position(T.telescopeChest)
telescope:register()

local ingots = Action()

function ingots.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.treasureHunt then
		return false
	end
	return T.useTreasureChest(player, "Ingots", 9058, 3, "You have found 3 gold ingots.")
end

ingots:position(T.ingotChest)
ingots:register()

local startup = GlobalEvent("FamilyTreasureHuntStartup")

function startup.onStartup()
	if Family.treasureHunt then
		T.setup()
	end
	return true
end

startup:register()
