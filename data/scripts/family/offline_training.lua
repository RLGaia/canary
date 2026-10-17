-- Gaia Family server: offline training without limits (2026-10-17). Ours, not upstream.
--
-- Upstream, logging out on a training statue trains at most 12 hours, and
-- those hours come out of the "offline training time" (shown as 12:00 in the
-- client), which then needs as long again to refill. Here:
--   - the whole time away counts, up to 21 days, also while the server was off
--     (it is measured from the logout time to the next login);
--   - the offline training time is never used up: it is back at 12:00 after
--     every login.
--   - no 10-minute minimum: every full minute away counts (since 2026-10-17).
-- Training still only happens when you log out on a training statue (a bed
-- only restores health, mana and soul, as upstream). The skill stages of
-- solo_balance.lua apply as for normal training, times rateOfflineTrainingSpeed
-- in family/config.family.lua (2x).
--
-- The change itself is marked FAMILY: in
-- data/scripts/creaturescripts/player/offline_training.lua.
--
-- House beds (2026-10-17): using a bed in a house (premium) opens the same
-- skill choice as upstream, and the training above applies the same way. Upstream
-- a bed also restores health and mana only while your food regeneration
-- lasts (a few points per 30 seconds) and 1 soul point per 15 minutes; here
-- you wake up with full health, mana and soul.
--
-- Switches: Family.offlineTrainingUnlimited (false = upstream training rules),
-- Family.bedFullRest (false = upstream bed regeneration).

Family = Family or {}
Family.offlineTrainingUnlimited = true
Family.bedFullRest = true

local FULL = 12 * 3600 * 1000

-- Keep the offline training time full for everyone who logs in.
local login = CreatureEvent("FamilyOfflineTrainingFull")

-- True when the player logged in on a bed, that is, slept in it (the login
-- position is where the player logged out; a bed can't be stood on otherwise).
local function wokeUpInBed(player)
	local tile = player:getTile()
	return tile ~= nil and tile:getItemByType(ITEM_TYPE_BED) ~= nil
end

function Family.bedRest(player)
	player:addHealth(player:getMaxHealth() - player:getHealth())
	player:addMana(player:getMaxMana() - player:getMana())
	player:addSoul(player:getMaxSoul() - player:getSoul())
end

function login.onLogin(player)
	if Family.offlineTrainingUnlimited then
		player:addOfflineTrainingTime(FULL)
	end
	if Family.bedFullRest and wokeUpInBed(player) then
		Family.bedRest(player)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You wake up fully rested.")
	end
	return true
end

login:register()

local report = GlobalEvent("FamilyOfflineTrainingReport")

function report.onStartup()
	logger.info("[Family] offline training: whole time away counts (up to 21 days) and the 12:00 never runs out: {} (speed x{}); full rest in house beds: {}", tostring(Family.offlineTrainingUnlimited), configManager.getFloat(configKeys.RATE_OFFLINE_TRAINING_SPEED), tostring(Family.bedFullRest))
	return true
end

report:register()
