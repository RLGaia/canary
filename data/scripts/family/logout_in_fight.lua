-- Gaia Family server: logout during a fight (2026-10-15). Ours, not upstream.
--
-- The battle icon no longer blocks logging out: the logout request clears the
-- in-fight state just before the server handles it (module
-- data/modules/scripts/family/logout_in_fight.lua, byte 20 in
-- data/modules/modules.xml). No-logout tiles still apply. Closing the client
-- without logging out keeps the character in game while the icon lasts, as in
-- Tibia.
--
-- Switch: Family.logoutDuringFight (false = upstream rule).

Family = Family or {}
Family.logoutDuringFight = true

local report = GlobalEvent("FamilyLogoutInFightReport")

function report.onStartup()
	logger.info("[Family] logout during a fight allowed={}", tostring(Family.logoutDuringFight))
	return true
end

report:register()
