-- Gaia Family server: stamina never goes down (2026-10-15). Ours, not upstream.
--
-- Upstream, every minute of hunting costs a minute of stamina: 42:00-39:00
-- gives the green +50% experience bonus (premium), 39:00-14:00 normal
-- experience, below 14:00 half, and 0:00 none. Here stamina is put back to
-- 42:00 at login and about once a second while playing, so the green bonus is
-- always on and orange/red stamina never happens.
--
-- The stamina system itself stays on (staminaSystem = true in config): turning
-- it off would remove the green bonus and also freeze Prey and Hunting Task
-- timers, which count down through it. Those still count down while hunting.
--
-- Switch: Family.staminaNeverDecreases (false = upstream stamina).

Family = Family or {}
Family.staminaNeverDecreases = true

local FULL_STAMINA = 42 * 60 -- minutes

function Family.refillStamina(player)
	if Family.staminaNeverDecreases and player:getStamina() < FULL_STAMINA then
		player:setStamina(FULL_STAMINA)
		return true
	end
	return false
end

local callback = EventCallback("FamilyStaminaFull")

function callback.playerOnThink(player, interval)
	Family.refillStamina(player)
end

callback:register()

local login = CreatureEvent("FamilyStaminaLogin")

function login.onLogin(player)
	Family.refillStamina(player)
	return true
end

login:register()

local report = GlobalEvent("FamilyStaminaReport")

function report.onStartup()
	logger.info("[Family] stamina: never decreases={} (always 42:00, green +50% experience bonus), staminaSystem={}", tostring(Family.staminaNeverDecreases), tostring(configManager.getBoolean(configKeys.STAMINA_SYSTEM)))
	return true
end

report:register()
