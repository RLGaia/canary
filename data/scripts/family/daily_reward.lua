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
-- 5. No Prey rerolls (2026-10-21, chosen by Rodrigo): every Prey reroll and
--    list choice is already free here, so days 3 and 5 gave nothing useful.
--    Day 3 is now an XP boost (+50%, 30 minutes like day 7) and day 5 is 25
--    Tibia Coins (picked on the wall, delivered to the Store inbox; using them
--    adds them to the coin balance). Upstream an XP boost claim only tops the
--    daily boost back up to its minutes (a second claim before using the first
--    one adds nothing); here every claim adds its full time.
-- 6. Day 6 mixed pick (2026-10-24, chosen by Rodrigo): training weapons never
--    run out here, so after the first ones day 6 gave nothing. Now day 6 lists
--    the 8 training weapons, the vocation's potions and runes (the same list
--    as days 1, 2 and 4) and an XP boost, 20 picks in any mix. Each XP boost
--    pick adds 3 minutes of +50% experience right away (20 picks = 1 hour, one
--    Store XP boost); nothing is delivered for it. The wall shows the XP boost
--    with the picture of a scroll of heroic deeds, the only way the client can
--    show a pick; that item is created in the Store inbox and removed again in
--    the same claim. Training weapons now come with their normal 50 charges
--    from items.xml (upstream gives every day 6 pick 50 charges, which would
--    have turned one potion pick into 50 potions).
--
-- Switches: Family.dailyRewardNeverExpires (false = upstream rules 1 and 2),
-- Family.dailyRewardWallCountdown (false = upstream wall after a claim),
-- Family.dailyRewardNoPrey (false = upstream days 3 and 5 and XP top-up),
-- Family.dailyRewardDay6Mix (false = upstream day 6: 2 training weapons).

Family = Family or {}
Family.dailyRewardNeverExpires = true
Family.dailyRewardWallCountdown = true
Family.dailyRewardNoPrey = true
Family.dailyRewardDay6Mix = true

-- upstream reward types (daily_reward.lua): 1 item pick, 3 prey reroll, 4 XP boost;
-- wall layouts: 1 item pick, 2 other
local REWARD_ITEM, REWARD_PREY, REWARD_XP = 1, 3, 4
local TIBIA_COIN = 22118
Family.dailyRewardPreyReplacements = {
	[3] = { type = REWARD_XP, systemType = 2, freeAccount = 10, premiumAccount = 30 },
	[5] = { type = REWARD_ITEM, systemType = 1, items = { TIBIA_COIN }, freeAccount = 10, premiumAccount = 25 },
}

-- Replaces the Prey reroll days and makes XP boost claims add their full time.
function Family.applyDailyRewardNoPrey()
	if not Family.dailyRewardNoPrey then
		return 0
	end
	local replaced = 0
	for day, reward in pairs(Family.dailyRewardPreyReplacements) do
		local current = DailyReward.rewards[day]
		if current and current.type == REWARD_PREY then
			DailyReward.rewards[day] = reward
			replaced = replaced + 1
		end
	end
	if not Family.originalSelectDailyReward then
		Family.originalSelectDailyReward = Player.selectDailyReward
		Player.selectDailyReward = function(self, msg)
			local reward = DailyReward.rewards[self:getDayStreak() + 1]
			if Family.dailyRewardNoPrey and reward and reward.type == REWARD_XP then
				-- upstream subtracts the daily boost minutes still left
				self:kv():remove("daily-reward-xp-boost")
			end
			return Family.originalSelectDailyReward(self, msg)
		end
	end
	return replaced
end

-- 6. Day 6 mixed pick.
local DAY6 = 6
Family.dailyRewardDay6 = {
	picksFree = 10,
	picksPremium = 20,
	xpIcon = 11510, -- scroll of heroic deeds: only its picture is used
	xpMinutesPerPick = 3,
	xpPercent = 50,
	trainingWeapons = { 28540, 28541, 28542, 28543, 28544, 28545, 44064, 50292 },
}
local XP_BOOST_MAX_SECONDS = 65535 -- the C++ keeps the boost time in 16 bits

-- Upstream keeps the vocation lists of days 1, 2 and 4 in a local table
-- (DailyRewardItems); read it from Player.readDailyReward so it stays upstream's.
local vocationItems
local function upstreamVocationItems()
	if vocationItems == nil then
		vocationItems = false
		local fn = Family.originalReadDailyReward or Player.readDailyReward
		for i = 1, 60 do
			local name, value = debug.getupvalue(fn, i)
			if not name then
				break
			end
			if name == "DailyRewardItems" and type(value) == "table" then
				vocationItems = value
				break
			end
		end
		if not vocationItems then
			logger.warn("[Family] daily reward day 6: vocation item lists not found, only training weapons and XP boost")
		end
	end
	return vocationItems or nil
end

-- Day 6 list for this character: training weapons, vocation supplies, XP boost.
function Family.dailyRewardDay6Items(player)
	local cfg = Family.dailyRewardDay6
	local list, seen = {}, {}
	local function add(id)
		if not seen[id] and #list < 255 then
			seen[id] = true
			list[#list + 1] = id
		end
	end
	for _, id in ipairs(cfg.trainingWeapons) do
		add(id)
	end
	local lists = upstreamVocationItems()
	if lists then
		local supplies = lists[player:getVocation():getBaseId()] or lists[0] or {}
		for _, id in ipairs(supplies) do
			add(id)
		end
	end
	add(cfg.xpIcon)
	return list
end

local function inboxCount(player, itemId)
	local inbox = player:getStoreInbox()
	local n = 0
	if inbox then
		for _, item in ipairs(inbox:getItems()) do
			if item:getId() == itemId then
				n = n + math.max(1, item:getCount())
			end
		end
	end
	return n
end

local function removeFromInbox(player, itemId, count)
	local inbox = player:getStoreInbox()
	if not inbox then
		return 0
	end
	local removed = 0
	for _, item in ipairs(inbox:getItems()) do
		if removed >= count then
			break
		end
		if item:getId() == itemId then
			local n = math.min(math.max(1, item:getCount()), count - removed)
			if item:remove(n) then
				removed = removed + n
			end
		end
	end
	return removed
end

-- Adds XP boost minutes (every claim adds its full time, as rule 5).
function Family.addDailyRewardXpBoost(player, minutes)
	local seconds = math.min(XP_BOOST_MAX_SECONDS, player:getXpBoostTime() + minutes * 60)
	player:setXpBoostTime(seconds)
	player:setXpBoostPercent(Family.dailyRewardDay6.xpPercent)
	return seconds
end

-- Reads the picks of an item claim without consuming them: XP boost picks, other picks.
local function peekPicks(msg, xpIcon)
	local unread = msg:getUnreadBytes()
	if unread < 2 then
		return 0, 0
	end
	msg:getByte() -- target (shrine / panel)
	local columns = msg:getByte()
	local read = 2
	local xp, other = 0, 0
	for _ = 1, columns do
		if unread < read + 3 then
			break
		end
		local itemId = msg:getU16()
		local count = msg:getByte()
		read = read + 3
		if itemId == xpIcon then
			xp = xp + count
		else
			other = other + count
		end
	end
	msg:skipBytes(-read)
	return xp, other
end

function Family.applyDailyRewardDay6Mix()
	if not Family.dailyRewardDay6Mix then
		return false
	end
	local cfg = Family.dailyRewardDay6
	local current = DailyReward.rewards[DAY6]
	-- only replace upstream's training weapon day (type 1 with charges)
	if not current or current.familyMix or current.type ~= REWARD_ITEM or not current.itemCharges then
		return current and current.familyMix or false
	end
	DailyReward.rewards[DAY6] = {
		type = REWARD_ITEM,
		systemType = 1,
		items = { 28540 }, -- set per character before every use
		freeAccount = cfg.picksFree,
		premiumAccount = cfg.picksPremium,
		familyMix = true,
	}

	-- Wall: same bytes as upstream for an item day, with the XP boost named as such.
	if not Family.originalReadDailyReward then
		Family.originalReadDailyReward = Player.readDailyReward
		Player.readDailyReward = function(self, msg, currentDay, state)
			local reward = DailyReward.rewards[currentDay]
			if not (reward and reward.familyMix) then
				return Family.originalReadDailyReward(self, msg, currentDay, state)
			end
			local items = Family.dailyRewardDay6Items(self)
			reward.items = items
			msg:addByte(reward.systemType)
			msg:addByte(state == 1 and reward.premiumAccount or reward.freeAccount) -- 1 = premium column
			msg:addByte(#items)
			for _, itemId in ipairs(items) do
				local itemType = ItemType(itemId)
				msg:addU16(itemId)
				if itemId == cfg.xpIcon then
					msg:addString(string.format("XP boost: %d minutes per pick", cfg.xpMinutesPerPick), "Family day 6 - XP boost")
					msg:addU32(0)
				else
					msg:addString(itemType:getArticle() .. " " .. itemType:getName(), "Family day 6 - item name")
					msg:addU32(itemType:getWeight())
				end
			end
		end
	end

	-- History line: the XP boost instead of "Nx scroll of heroic deeds".
	if not Family.originalInsertDailyRewardHistory then
		Family.originalInsertDailyRewardHistory = DailyReward.insertHistory
		DailyReward.insertHistory = function(guid, dayStreak, description)
			if Family.day6Claim and type(description) == "string" then
				local name = ItemType(cfg.xpIcon):getName():gsub("%p", "%%%0")
				description = description:gsub("(%d+)x " .. name, function(n)
					return string.format("XP boost for %d minutes", tonumber(n) * cfg.xpMinutesPerPick)
				end)
			end
			return Family.originalInsertDailyRewardHistory(guid, dayStreak, description)
		end
	end

	-- Claim: upstream checks and delivers every pick; the XP boost picks are
	-- then taken back out of the Store inbox and turned into boost time.
	if not Family.originalSelectDailyRewardDay6 then
		Family.originalSelectDailyRewardDay6 = Player.selectDailyReward
		Player.selectDailyReward = function(self, msg)
			local reward = DailyReward.rewards[self:getDayStreak() + 1]
			if not (Family.dailyRewardDay6Mix and reward and reward.familyMix) then
				return Family.originalSelectDailyRewardDay6(self, msg)
			end
			reward.items = Family.dailyRewardDay6Items(self)
			local xpPicks, otherPicks = peekPicks(msg, cfg.xpIcon)
			local before = inboxCount(self, cfg.xpIcon)
			Family.day6Claim = { xp = xpPicks, other = otherPicks }
			local ok, result = pcall(Family.originalSelectDailyRewardDay6, self, msg)
			Family.day6Claim = nil
			local delivered = inboxCount(self, cfg.xpIcon) - before
			if delivered > 0 then
				local removed = removeFromInbox(self, cfg.xpIcon, delivered)
				if removed > 0 then
					local minutes = removed * cfg.xpMinutesPerPick
					local total = Family.addDailyRewardXpBoost(self, minutes)
					self:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("XP boost +%d minutes: %d minutes of +%d%% experience left.", minutes, math.floor(total / 60), cfg.xpPercent))
				end
			end
			if not ok then
				error(result)
			end
			return result
		end
	end
	return true
end

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
		local day6 = Family.day6Claim
		if player and reward and reward.type == 1 and not (day6 and day6.other == 0) then -- DAILY_REWARD_TYPE_ITEM; day 6 with only XP boost picks delivers nothing
			if reward.items and reward.items[1] == TIBIA_COIN and #reward.items == 1 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your Tibia Coins are in your Store inbox. Use them to add them to your coin balance.")
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your daily reward items are in your Store inbox.")
			end
		end
		return result
	end

	local replaced = Family.applyDailyRewardNoPrey()
	if replaced > 0 then
		logger.info("[Family] daily reward: {} Prey reroll days replaced (day 3 XP boost, day 5 Tibia Coins)", replaced)
	end

	if Family.applyDailyRewardDay6Mix() then
		local cfg = Family.dailyRewardDay6
		logger.info("[Family] daily reward: day 6 is a mixed pick of " .. cfg.picksPremium .. " (training weapons, vocation supplies, XP boost " .. cfg.xpMinutesPerPick .. " minutes per pick)")
	end

	local newDay = Family.catchUpDailyRewardDay()
	logger.info("[Family] daily reward: streak never expires={}, new day at {} even with the server off{}", tostring(Family.dailyRewardNeverExpires), configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME), newDay and " (new reward day started now)" or "")
	return true
end

familyDailyReward:register()
