-- Gaia Family server: the Machinery of War Quest, map objects (2026-11-24). Ours, not upstream.
-- Rules and sources: data-otservbr-global/lib/others/family_machinery_of_war.lua.
--
-- * The chalk board with the orcs' war plans (orc fortress, floor 8).
-- * Startup: finds the broken walls and war machines on the map.
-- Baxter, the bricklayers' kit and the fire bug call FamilyMachineryOfWar from their own scripts.
--
-- Switch: Family.machineryOfWar (false = none of it; Baxter, the kit and the fire bug act as upstream).

Family = Family or {}
Family.machineryOfWar = true

local M = FamilyMachineryOfWar

local chalkBoard = Action()

function chalkBoard.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.machineryOfWar or (item.itemid ~= 8070 and item.itemid ~= 8071) then
		return false
	end
	return M.useChalkBoard(player)
end

for _, pos in ipairs(M.chalkBoard) do
	chalkBoard:position(pos)
end
chalkBoard:register()

local startup = GlobalEvent("FamilyMachineryOfWarStartup")

function startup.onStartup()
	if Family.machineryOfWar then
		M.setup()
	end
	return true
end

startup:register()
