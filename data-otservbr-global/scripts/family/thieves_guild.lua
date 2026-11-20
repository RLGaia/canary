-- Gaia Family server: The Thieves Guild Quest, Mission 8 (2026-11-20). Ours, not upstream.
--
-- The teleport in the middle of the Dark Cathedral's second floor (32615,32484,9) has a
-- destination on our map, so it moved every player down before its script
-- (scripts/movements/teleport/dark_cathedral_teleports.lua, unique id 35021) could check the six
-- levers. Both wikis: pull all six levers, then the teleport works. Its destination is cleared at
-- startup so the script decides (all levers down: to the lowest floor; else back where you came
-- from). Details and the rest of the review: lib/others/family_thieves_guild.lua.

local TELEPORT_POS = Position(32615, 32484, 9)
local TELEPORT_ID = 1949

local startup = GlobalEvent("FamilyThievesGuildStartup")

function startup.onStartup()
	if not (Family and Family.thievesGuild) then
		return true
	end
	local tile = Tile(TELEPORT_POS)
	local teleport = tile and tile:getItemById(TELEPORT_ID)
	if teleport and teleport.setDestination then
		teleport:setDestination(Position(0, 0, 0))
	else
		logger.warn("[Family] Thieves Guild: Dark Cathedral teleport not found")
	end
	return true
end

startup:register()
