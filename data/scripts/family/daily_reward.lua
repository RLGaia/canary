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
-- 3. After claiming, the Reward Wall said "expired" and "You did not claim
--    your daily reward in time. Too bad, you do not have enough Daily Reward
--    Jokers", although the reward had been given (2026-10-15). Upstream sends
--    the "cannot claim" state after a claim, which carries no time, and the
--    client shows that as expired. Here the wall gets the normal state, with
--    the time left to claim the next reward, so the Resting Area shows a
--    countdown instead.
-- 4. Item rewards go to the Store inbox, as in real Tibia; a message now says
--    so, because nothing arrives in the backpack.
--
-- Switches: Family.dailyRewardNeverExpires (false = upstream rules 1 and 2),
-- Family.dailyRewardWallCountdown (false = upstream wall after a claim).

Family = Family or {}
Family.dailyRewardNeverExpires = true
Family.dailyRewardWallCountdown = true

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

-- Since upstream #4146 (backported 2026-10-19) missed days are counted with a
-- server save counter that grows at every real 06:00 save, not with the last
-- server save time. Keeping the character's claimed window at most one behind
-- the counter means no window is ever missed, so no joker token is spent and
-- the streak stays.
function Family.keepDailyRewardWindow(player)
	if not Family.dailyRewardNeverExpires or not player.getDailyRewardClaimedServerSave or not GetDailyRewardServerSaveCount then
		return
	end
	local claimed = player:getDailyRewardClaimedServerSave()
	local current = GetDailyRewardServerSaveCount()
	if claimed and claimed < current - 1 then
		player:setDailyRewardClaimedServerSave(current - 1)
	end
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
			Family.keepDailyRewardWindow(player)
		end
		return originalInit(playerId)
	end

	-- 3. Reward Wall after a claim: normal state with a countdown, not "expired".
	local originalWall = Player.sendOpenRewardWall
	Player.sendOpenRewardWall = function(self, shrine)
		if not Family.dailyRewardWallCountdown or self:getClient().version < 1200 or not DailyReward.isRewardTaken(self:getId()) then
			return originalWall(self, shrine)
		end
		-- Same packet as upstream sends before a claim, except the first time:
		-- when the next reward unlocks (the next server save), as upstream sends
		-- after a claim. The deadline to keep the streak is one day after that.
		local nextReward = GetDailyRewardLastServerSave() + DailyReward.serverTimeThreshold
		local msg = NetworkMessage()
		msg:addByte(0xE2) -- OpenRewardWall (ServerPackets is local to the module)
		msg:addByte(shrine)
		msg:addU32(nextReward)
		msg:addByte(self:getDayStreak())
		msg:addByte(0) -- state: streak running (upstream sends 1 = cannot claim)
		msg:addByte(2)
		msg:addU32(nextReward + DAY) -- claim the next reward before this to keep the streak
		msg:addU16(self:getJokerTokens())
		msg:addU16(self:getStreakLevel())
		msg:sendToPlayer(self)
		return true
	end

	-- 4. Tell where item rewards went.
	local originalProcess = DailyReward.processReward
	DailyReward.processReward = function(playerId, target)
		local player = Player(playerId)
		local reward = player and DailyReward.rewards[player:getDayStreak() + 1]
		local result = originalProcess(playerId, target)
		if player and reward and reward.type == 1 then -- DAILY_REWARD_TYPE_ITEM
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your daily reward items are in your Store inbox.")
		end
		return result
	end

	local newDay = Family.catchUpDailyRewardDay()
	logger.info("[Family] daily reward: streak never expires={}, new day at {} even with the server off{}", tostring(Family.dailyRewardNeverExpires), configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME), newDay and " (new reward day started now)" or "")
	return true
end

familyDailyReward:register()
