-- Gaia Family server: travel between the mainland and Rookgaard (2026-10-15).
--
-- Ours, not upstream. Upstream nobody sails to Rookgaard, and the Oracle only
-- lets characters without a vocation leave. Here:
--   - Captain Bluebear (Thais harbour) sails to Rookgaard for 100 gold (the fare
--     is in his file): hi -> rookgaard -> yes. You arrive at the Rookgaard temple.
--   - The Oracle (above the Rookgaard academy) sends a character that already
--     has a vocation back to the temple of its home town, free: hi -> yes.
--     Characters without a vocation still choose town and vocation as upstream.
-- Dying on Rookgaard also brings a mainland character back to its home town.
--
-- The NPC changes are marked FAMILY: in data-otservbr-global/npc/captain_bluebear.lua
-- and data-otservbr-global/npc/the_oracle.lua.
--
-- Switch: Family.rookgaardTravel (false = upstream: no ship, Oracle refuses).

Family = Family or {}
Family.rookgaardTravel = true

-- Temple a character with a vocation returns to from Rookgaard: its home town,
-- or Thais when the home town is on an island for beginners.
local BEGINNER_TOWNS = { [1] = true, [3] = true, [4] = true } -- Dawnport Tutorial, Rookgaard, Island of Destiny
local THAIS = 8

function Family.mainlandTemple(player)
	local town = player:getTown()
	if not town or BEGINNER_TOWNS[town:getId()] then
		town = Town(THAIS)
	end
	return town:getTemplePosition(), town:getName()
end

local report = GlobalEvent("FamilyRookgaardTravelReport")

function report.onStartup()
	logger.info("[Family] Rookgaard travel: {} (Captain Bluebear in Thais sails there; the Oracle sends characters with a vocation home)", Family.rookgaardTravel and "on" or "off")
	return true
end

report:register()
