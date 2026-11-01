-- Gaia Family server: no Dawnport level cap and no Dawnport skill caps (2026-10-30;
-- level cap removed 2026-11-01, it was 50).
--
-- Ours, not upstream. Tibia sends a character away from Dawnport at level 20
-- and stops magic level there at 20 (sorcerer, druid), 9 (paladin) and
-- 4 (knight). The Dawnport Quest was made for levels 2 to 20 at 1x experience;
-- with our 80x curve, Mr Morris' three hunts alone are worth more than level 20,
-- so the island could not be finished. Asked by Rodrigo:
--   - No "limit level": a character is never sent to the temple or kept off the
--     stairs to the shops because of its level (Tibia: level 20; ours was 50
--     from 2026-10-30 to 2026-11-01). It leaves when it chooses a vocation.
--     Read by the upstream files below.
--   - No skill or magic level cap while living on Dawnport.
--
-- Upstream files that read Family.dawnportLevelCap (marked FAMILY:):
--   data-otservbr-global/scripts/creaturescripts/others/dawnport.lua
--   data-otservbr-global/scripts/movements/others/dawnport_tiles.lua
--
-- Switches: Family.dawnportLevelCap (false = no limit, a number = that level,
--           nil = upstream 20),
--           Family.dawnportNoSkillCaps (false = upstream caps).

Family = Family or {}
Family.dawnportLevelCap = false
Family.dawnportNoSkillCaps = true

-- isSkillGrowthLimited (lib/others/dawnport.lua) reads this table at run time;
-- with no entry for a vocation nothing is limited.
local upstreamSkillsLimit = Dawnport and Dawnport.skillsLimit
if Family.dawnportNoSkillCaps and Dawnport then
	Dawnport.skillsLimit = {}
end

local report = GlobalEvent("FamilyDawnportLimitsReport")

function report.onStartup()
	logger.info("[Family] Dawnport: level cap {}; skill caps {}", Family.dawnportLevelCap == false and "off" or tostring(Family.dawnportLevelCap), (Dawnport and next(Dawnport.skillsLimit or {}) == nil) and "off" or "on")
	return true
end

report:register()

-- For tests: the upstream table before this file changed it.
Family.dawnportUpstreamSkillsLimit = upstreamSkillsLimit
