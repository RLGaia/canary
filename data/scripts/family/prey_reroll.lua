-- Gaia Family server: daily free list reroll for Prey and Hunting Tasks
-- (2026-11-01, chosen by Rodrigo).
--
-- Ours, not upstream. Rerolling a Prey or Hunting Task creature list costs gold
-- again (Tibia: level x 200, bank included), but each slot gets one free
-- reroll per day, back at 00:00 on the server clock, like the boss cooldowns
-- (boss_cooldown.lua). Tibia gives the free reroll back 20 hours after it was
-- used instead. The first reroll after claiming a Hunting Task is free too
-- (the slot is made ready at once by hunting_task_points.lua; in Tibia the
-- new list after the wait costs nothing).
--
-- How: the C++ (IOPrey ListReroll) gives a free reroll when the slot's free
-- reroll time has passed and then sets it 24 hours ahead
-- (preyFreeRerollTime / taskHuntingFreeRerollTime = 86400 in
-- family/config.family.lua); otherwise it takes the price with removeMoney.
-- Lua cannot change that time in memory, so the recvbyte modules for 0xEB
-- (Prey) and 0xBA (Hunting Tasks) call Family.preyRerollAction before the
-- server handles the packet:
-- * our free reroll is due (not used since the last 00:00, or a claim was
--   just made) but the C++ would charge: the price is put in the bank first,
--   so the reroll costs nothing (the C++ takes carried gold first, so that
--   much goes from the bank back to the backpack afterwards); if the C++
--   used its own free reroll instead, the credit is taken back.
-- * our free reroll was used today but the C++ gave a free one (its 24 hours
--   ran out first): the price is taken afterwards (removeMoneyBank; if the
--   money is not there, that reroll stays free).
-- At every server start the saved C++ times are moved to the 00:00 after
-- the reroll that set them, so the window's countdown matches after a restart
-- (the server restarts at 06:00 every day). While the server runs, the window
-- may show a longer countdown after midnight; the reroll is still free, and a
-- message says what each reroll cost.
--
-- Switch: Family.dailyFreeReroll (false = the C++ rule of the config: one free
-- reroll 24 hours after the last, otherwise the price).

Family = Family or {}
Family.dailyFreeReroll = true

local PREY_LIST_REROLL = 0 -- PreyAction_ListReroll
local TASK_LIST_REROLL = 0 -- PreyTaskAction_ListReroll
local CHECK_DELAY = 50 -- ms; the server handles the packet right after the module

local claimFree = {} -- [playerId] = { [slot] = true } after a Hunting Task claim

-- Most recent 00:00 on the server clock (os.time, seconds).
function Family.lastMidnight(now)
	local t = os.date("*t", now or os.time())
	return os.time({ year = t.year, month = t.month, day = t.day, hour = 0, min = 0, sec = 0 })
end

-- The 00:00 after a moment (seconds).
function Family.nextMidnight(moment)
	local t = os.date("*t", moment)
	return os.time({ year = t.year, month = t.month, day = t.day + 1, hour = 0, min = 0, sec = 0 })
end

local function storeKey(kind, slot)
	return kind .. tostring(slot)
end

local function lastFree(player, kind, slot)
	return player:kv():scoped("family-free-reroll"):get(storeKey(kind, slot)) or 0
end

local function setLastFree(player, kind, slot, when)
	player:kv():scoped("family-free-reroll"):set(storeKey(kind, slot), when)
end

function Family.rerollPrice(player, kind)
	local key = kind == "task" and configKeys.TASK_HUNTING_REROLL_PRICE_LEVEL or configKeys.PREY_REROLL_PRICE_LEVEL
	return player:getLevel() * configManager.getNumber(key)
end

-- Called after a successful Hunting Task claim (hunting_task_points.lua).
function Family.markClaimFreeReroll(player, slot)
	local id = player:getId()
	claimFree[id] = claimFree[id] or {}
	claimFree[id][slot] = true
end

local function totalMoney(player)
	return player:getMoney() + player:getBankBalance()
end

local function formatGold(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function afterReroll(playerId, kind, slot, before, credit, ourFree, fromClaim, carriedBefore, bankBefore)
	local player = Player(playerId)
	if not player then
		return
	end
	local now = os.time()
	local price = Family.rerollPrice(player, kind)
	local total = totalMoney(player)
	local window = kind == "task" and "Hunting Task" or "Prey"
	if ourFree then
		if credit > 0 and total >= before + credit then
			-- the C++ used its own free reroll (or refused): take the credit back
			player:setBankBalance(math.max(0, player:getBankBalance() - credit))
		elseif credit > 0 then
			-- the C++ took the price from the carried gold first, so the credit is
			-- still in the bank: give that gold back to the backpack (what does
			-- not fit stays in the bank)
			local move = math.min(carriedBefore - player:getMoney(), player:getBankBalance() - bankBefore)
			if move > 0 then
				player:setBankBalance(player:getBankBalance() - move)
				local _, added = player:addMoney(move)
				added = added or 0
				if added < move then
					player:setBankBalance(player:getBankBalance() + (move - added))
				end
			end
		end
		if fromClaim then
			player:sendTextMessage(MESSAGE_STATUS, window .. " list reroll: free (new creatures after a claim).")
		else
			setLastFree(player, kind, slot, now)
			player:sendTextMessage(MESSAGE_STATUS, string.format("%s list reroll: free (once a day per slot). Until 00:00 each reroll costs %s gold.", window, formatGold(price)))
		end
		return
	end
	if total >= before then
		-- the C++ gave a free reroll although ours was used today: charge it
		if price > 0 and player:removeMoneyBank(price) then
			player:sendTextMessage(MESSAGE_STATUS, string.format("%s list reroll: %s gold. Your free reroll comes back at 00:00.", window, formatGold(price)))
		end
		return
	end
	player:sendTextMessage(MESSAGE_STATUS, string.format("%s list reroll: %s gold. Your free reroll comes back at 00:00.", window, formatGold(before - total)))
end

-- kind: "prey" (0xEB) or "task" (0xBA); msg: the packet right after its byte.
-- The read position is put back, so the server reads the packet as usual.
function Family.preyRerollAction(player, msg, kind)
	if not Family.dailyFreeReroll or not player or not msg or msg:getUnreadBytes() < 2 then
		return
	end
	local slot = msg:getByte()
	local action = msg:getByte()
	msg:skipBytes(-2)
	if action ~= (kind == "task" and TASK_LIST_REROLL or PREY_LIST_REROLL) then
		return
	end
	local id = player:getId()
	local fromClaim = kind == "task" and claimFree[id] and claimFree[id][slot] or false
	if fromClaim then
		claimFree[id][slot] = nil
	end
	local ourFree = fromClaim or lastFree(player, kind, slot) < Family.lastMidnight()
	local carriedBefore, bankBefore = player:getMoney(), player:getBankBalance()
	local credit = 0
	if ourFree then
		credit = Family.rerollPrice(player, kind)
		if credit > 0 then
			player:setBankBalance(player:getBankBalance() + credit)
		end
	end
	addEvent(afterReroll, CHECK_DELAY, id, kind, slot, carriedBefore + bankBefore, credit, ourFree, fromClaim, carriedBefore, bankBefore)
end

local logout = CreatureEvent("FamilyFreeRerollLogout")

function logout.onLogout(player)
	claimFree[player:getId()] = nil
	return true
end

logout:register()

local login = CreatureEvent("FamilyFreeRerollLogin")

function login.onLogin(player)
	player:registerEvent("FamilyFreeRerollLogout")
	return true
end

login:register()

-- Saved C++ free reroll times (ms) moved to the 00:00 after the reroll that set them.
local function capSaved(tableName, seconds)
	local nowMs = os.time() * 1000
	local result = db.storeQuery(string.format("SELECT `player_id`, `slot`, `free_reroll` FROM `%s` WHERE `free_reroll` > %.0f", tableName, nowMs))
	if not result then
		return 0
	end
	local changes = {}
	repeat
		local stamp = Result.getNumber(result, "free_reroll")
		local capped = Family.nextMidnight(math.floor(stamp / 1000) - seconds) * 1000
		if capped < stamp then
			changes[#changes + 1] = { Result.getNumber(result, "player_id"), Result.getNumber(result, "slot"), capped }
		end
	until not Result.next(result)
	Result.free(result)
	for _, c in ipairs(changes) do
		db.query(string.format("UPDATE `%s` SET `free_reroll` = %.0f WHERE `player_id` = %d AND `slot` = %d", tableName, c[3], c[1], c[2]))
	end
	return #changes
end

local startup = GlobalEvent("FamilyFreeReroll")

function startup.onStartup()
	if not Family.dailyFreeReroll then
		logger.info("[Family] daily free reroll: off")
		return true
	end
	local prey = capSaved("player_prey", configManager.getNumber(configKeys.PREY_FREE_REROLL_TIME))
	local tasks = capSaved("player_taskhunt", configManager.getNumber(configKeys.TASK_HUNTING_FREE_REROLL_TIME))
	logger.info("[Family] daily free reroll: on, list reroll price {} gold per level; saved timers moved to midnight: {} prey, {} hunting task slots", configManager.getNumber(configKeys.PREY_REROLL_PRICE_LEVEL), prey, tasks)
	return true
end

startup:register()
