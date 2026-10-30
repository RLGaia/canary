-- Gaia Family server: Dawnport level cap 50 and no Dawnport skill caps (2026-10-30).
--
-- Ours, not upstream. Tibia sends a character away from Dawnport at level 20
-- and stops magic level there at 20 (sorcerer, druid), 9 (paladin) and
-- 4 (knight). The Dawnport Quest was made for levels 2 to 20 at 1x experience;
-- with our 80x curve, Mr Morris' three hunts alone are worth more than level 20,
-- so the island could not be finished. Asked by Rodrigo:
--   - The "limit level" (5-minute teleport to the temple, stairs to the shops
--     closed) is level 50 instead of 20. Read by the upstream files below.
--   - No skill or magic level cap while living on Dawnport.
--
-- Upstream files that read Family.dawnportLevelCap (marked FAMILY:):
--   data-otservbr-global/scripts/creaturescripts/others/dawnport.lua
--   data-otservbr-global/scripts/movements/others/dawnport_tiles.lua
--
-- Switches: Family.dawnportLevelCap (20 = upstream),
--           Family.dawnportNoSkillCaps (false = upstream caps).

Family = Family or {}
Family.dawnportLevelCap = 50
Family.dawnportNoSkillCaps = true

-- isSkillGrowthLimited (lib/others/dawnport.lua) reads this table at run time;
-- with no entry for a vocation nothing is limited.
local upstreamSkillsLimit = Dawnport and Dawnport.skillsLimit
if Family.dawnportNoSkillCaps and Dawnport then
	Dawnport.skillsLimit = {}
end

local report = GlobalEvent("FamilyDawnportLimitsReport")

function report.onStartup()
	logger.info("[Family] Dawnport: leave at level {}; skill caps {}", Family.dawnportLevelCap, (Dawnport and next(Dawnport.skillsLimit or {}) == nil) and "off" or "on")
	return true
end

report:register()

-- For tests: the upstream table before this file changed it.
Family.dawnportUpstreamSkillsLimit = upstreamSkillsLimit
