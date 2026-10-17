-- Gaia Family server: offline training without limits (2026-10-17). Ours, not upstream.
--
-- Upstream, logging out on a training statue trains at most 12 hours, and
-- those hours come out of the "offline training time" (shown as 12:00 in the
-- client), which then needs as long again to refill. Here:
--   - the whole time away counts, up to 21 days, also while the server was off
--     (it is measured from the logout time to the next login);
--   - the offline training time is never used up: it is back at 12:00 after
--     every login.
-- Training still only happens when you log out on a training statue, and you
-- must stay away for at least 10 minutes. rateOfflineTrainingSpeed in
-- family/config.family.lua (2x) still applies.
--
-- The change itself is marked FAMILY: in
-- data/scripts/creaturescripts/player/offline_training.lua.
--
-- Switch: Family.offlineTrainingUnlimited (false = upstream).

Family = Family or {}
Family.offlineTrainingUnlimited = true

local FULL = 12 * 3600 * 1000

-- Keep the offline training time full for everyone who logs in.
local login = CreatureEvent("FamilyOfflineTrainingFull")

function login.onLogin(player)
	if Family.offlineTrainingUnlimited then
		player:addOfflineTrainingTime(FULL)
	end
	return true
end

login:register()

local report = GlobalEvent("FamilyOfflineTrainingReport")

function report.onStartup()
	logger.info("[Family] offline training: whole time away counts (up to 21 days) and the 12:00 never runs out: {} (speed x{})", tostring(Family.offlineTrainingUnlimited), configManager.getFloat(configKeys.RATE_OFFLINE_TRAINING_SPEED))
	return true
end

report:register()
