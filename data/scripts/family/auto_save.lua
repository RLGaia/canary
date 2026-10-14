-- Gaia Family server: automatic save every 30 minutes (2026-10-13).
--
-- Ours, not upstream. Upstream's interval save (save_interval.lua) only saves
-- in the minute before globalServerSaveTime and expects "HH:MM", so with our
-- "06:00:00" it never saved: progress was only written at logout and at the
-- 06:00 shutdown. This saves players, houses and the map every
-- Family.autoSaveMinutes, and never cleans the map (items on the ground stay).
-- toggleSaveInterval is false in family/config.family.lua, so upstream's
-- version stays off. /save saves at once (open to every character).

Family = Family or {}
Family.autoSaveMinutes = 30

local autoSave = GlobalEvent("FamilyAutoSave")

function autoSave.onThink(interval)
	saveServer()
	if SaveHirelings then
		SaveHirelings()
	end
	logger.info("[Family] automatic save done; next in {} minutes", Family.autoSaveMinutes)
	for _, player in ipairs(Game.getPlayers()) do
		player:sendTextMessage(MESSAGE_STATUS, "Game saved.")
	end
	return true
end

autoSave:interval(Family.autoSaveMinutes * 60 * 1000)
autoSave:register()

local autoSaveReport = GlobalEvent("FamilyAutoSaveReport")

function autoSaveReport.onStartup()
	logger.info("[Family] automatic save every {} minutes (map is not cleaned); /save open to every character", Family.autoSaveMinutes)
	return true
end

autoSaveReport:register()
