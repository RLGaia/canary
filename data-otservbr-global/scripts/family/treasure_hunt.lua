-- Gaia Family server: the Treasure Hunt Quest, map objects (2026-11-24). Ours, not upstream.
-- Rules and sources: data-otservbr-global/lib/others/family_treasure_hunt.lua.
--
-- * The chest behind Wyrdin's door gives the old pirate poem once Wyrdin decrypted the text.
-- * The dworc cave below the dig spot (world/custom/family-treasure-hunt.otbm): the 4 levers roll
--   their dice, the teleporter lets through only who carries the voodoo doll whose number the dice
--   show (else back one square), the way out, the remains of a pirate.
-- * Startup: the 3 giant tree carvings, the sealed door's action id, the chest made immovable.
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

local startup = GlobalEvent("FamilyTreasureHuntStartup")

function startup.onStartup()
	if Family.treasureHunt then
		T.setup()
	end
	return true
end

startup:register()
