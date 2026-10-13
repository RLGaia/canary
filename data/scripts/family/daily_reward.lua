-- Gaia Family server: daily reward without FOMO (2026-10-13).
--
-- Ours, not upstream. Two changes to the daily reward (reward shrine):
--
-- 1. The streak never expires. Upstream, missing a day costs a joker token
--    and, without tokens, resets the streak (and its bonuses: HP, mana and
--    stamina regeneration, double hunting and prey...). Here the streak, its
--    bonuses and the joker tokens are kept however long you stay away.
-- 2. A new reward day starts at every server save time (06:00), even if the
--    server was off at that moment. Upstream the day only advances while the
--    server is running at 06:00, which rarely happens on a PC that is only on
--    while playing, so the next reward would never unlock.
--
-- Switch: Family.dailyRewardNeverExpires (false = upstream rules).

Family = Family or {}
Family.dailyRewardNeverExpires = true

local DAY = 24 * 60 * 60

-- Unix time of the most recent server save time (e.g. today 06:00, or
-- yesterday 06:00 if it is not 06:00 yet).
local function lastScheduledServerSave()
	local hour, minute, second = configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME):match("(%d+):(%d+):?(%d*)")
	local now = os.time()
	local today = os.date("*t", now)
	today.hour, today.min, today.sec = tonumber(hour) or 6, tonumber(minute) or 0, tonumber(second) or 0
	local stamp = os.time(today)
	if stamp > now then
		stamp = stamp - DAY
	end
	return stamp
end

-- Moves the daily reward "last server save" forward to the last 06:00 when the
-- server missed it. Returns true when a new reward day was started.
function Family.catchUpDailyRewardDay()
	if not Family.dailyRewardNeverExpires then
		return false
	end
	local recorded = GetDailyRewardLastServerSave() or 0
	local scheduled = lastScheduledServerSave()
	if recorded < scheduled then
		UpdateDailyRewardGlobalStorage(DailyReward.storages.lastServerSave, scheduled)
		return true
	end
	return false
end

local familyDailyReward = GlobalEvent("FamilyDailyReward")

function familyDailyReward.onStartup()
	if not DailyReward or not DailyReward.init then
		logger.warn("[Family] daily reward: DailyReward.init not found, upstream rules apply")
		return true
	end

	local originalInit = DailyReward.init
	DailyReward.init = function(playerId)
		local player = Player(playerId)
		if player and Family.dailyRewardNeverExpires then
			Family.catchUpDailyRewardDay()
			-- Upstream resets the streak when the next reward time is older than
			-- the last server save; keeping it at least that recent keeps the
			-- streak and the joker tokens.
			local lastSave = GetDailyRewardLastServerSave()
			if player:getNextRewardTime() < lastSave then
				player:setNextRewardTime(lastSave)
			end
		end
		return originalInit(playerId)
	end

	local newDay = Family.catchUpDailyRewardDay()
	logger.info("[Family] daily reward: streak never expires={}, new day at {} even with the server off{}", tostring(Family.dailyRewardNeverExpires), configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME), newDay and " (new reward day started now)" or "")
	return true
end

familyDailyReward:register()
