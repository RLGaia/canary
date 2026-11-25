-- Gaia Family server: a depot in the Adventurers' Guild (2026-11-24, asked by
-- Rodrigo's father). Ours, not Tibia: the real guild has no depot.
--
-- Two depot lockers stand in the guild's reward shrine room (floor 6, south of
-- the main hall), against the south wall, one on each side of the shrine. They
-- come from the custom map world/custom/family-guild-depot.otbm (built by
-- tools/family/otbm/guild_depot.py), because a locker needs its town number
-- from the map. They open the same depot as every other locker on our server
-- (boxes, inbox, stash, market).
--
-- Switch: Family.guildDepot (false = the lockers stay but do not open: "This
-- locker is closed."). Lua cannot take a map depot locker away (v3.6.1 refuses
-- to remove it, even after a transform); to remove them for good, delete
-- world/custom/family-guild-depot.otbm and its four side files.

Family = Family or {}
Family.guildDepot = true

local LOCKER = 3497
local SQUARES = { -- keep in step with tools/family/otbm/guild_depot.py
	Position(32198, 32306, 6),
	Position(32202, 32306, 6),
}
Family.guildDepotSquares = SQUARES

local startup = GlobalEvent("FamilyGuildDepot")

function startup.onStartup()
	for _, pos in ipairs(SQUARES) do
		local tile = Tile(pos)
		local locker = tile and tile:getItemById(LOCKER)
		if Family.guildDepot and not locker then
			logger.warn(string.format("[FamilyGuildDepot] no depot locker at %d,%d,%d (custom map family-guild-depot.otbm missing?)", pos.x, pos.y, pos.z))
		end
	end
	return true
end

startup:register()

-- Switch off: the lockers refuse to open. Switch on: return false, so the
-- locker opens as every depot locker does.
local closed = Action()

function closed.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if Family.guildDepot or item:getId() ~= LOCKER then
		return false
	end
	player:sendCancelMessage("This locker is closed.")
	return true
end

for _, pos in ipairs(SQUARES) do
	closed:position(pos)
end
closed:register()
