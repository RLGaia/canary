-- Gaia Family server: The Frozen Trench (The Explorer Society Quest), ours (2026-11-01).
--
-- Upstream had the trench on the map (under the ship south of Tyrsung, with a
-- forcefield back to the deck at 32367,31374,11 and the frozen human at
-- 32358,31392,12) but no way to dive, no mission and no creatures. Sources:
-- TibiaWiki BR (The Explorer Society Quest, "The Frozen Trench") and the
-- TibiaWiki EN spoiler and "Frozen Trench" page:
--   * wear a helmet of the deep and jump into the water from the planks on the
--     south side of the ship (EN: 32366,31372,6);
--   * head south to a cliff, levitate down, west and north to the frozen human;
--   * step in front of him: a message tells you to report to Lurik.
-- Lurik's mission and report: npc/lurik.lua. Quest log: catalog 028. Spawns:
-- world/otservbr-monster.xml (FAMILY block). Storage:
-- Storage.Quest.FamilyFrozenTrench.Mission (1 accepted, 2 found, 3 reported).
--
-- Switch: Family.frozenTrench (false = no dive, Lurik never offers it).

Family = Family or {}
Family.frozenTrench = true

local HELMETS = { 5460, 11585, 13995 } -- helmet of the deep (the same three as the Calassa dive)
local LANDING = Position(32366, 31372, 11)

local dive = MoveEvent()

function dive.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.frozenTrench then
		return true
	end
	local head = player:getSlotItem(CONST_SLOT_HEAD)
	if head and table.contains(HELMETS, head.itemid) then
		player:teleportTo(LANDING)
		LANDING:sendMagicEffect(CONST_ME_WATERSPLASH)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You dive into the icy water above the Frozen Trench.")
	else
		player:teleportTo(fromPosition, true)
		fromPosition:sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You must wear an underwater exploration helmet in order to dive.")
	end
	return true
end

dive:type("stepin")
dive:position(Position(32365, 31372, 6))
dive:position(Position(32366, 31372, 6))
dive:register()

-- the square in front of the frozen human (unique id 15032 on our map)
local found = MoveEvent()

function found.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.frozenTrench then
		return true
	end
	local S = Storage.Quest.FamilyFrozenTrench.Mission
	if player:getStorageValue(S) == 1 then
		player:setStorageValue(S, 2)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a frozen human. It must be the missing explorer. Report back to Lurik in Svargrond!")
		position:sendMagicEffect(CONST_ME_ICEAREA)
	end
	return true
end

found:type("stepin")
found:uid(15032)
found:register()
