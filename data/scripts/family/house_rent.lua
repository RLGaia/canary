-- Gaia Family server: monthly house rent (2026-11-02, asked by Rodrigo).
-- Ours, not upstream.
--
-- Rules (Rodrigo's choices, Tibia's own rules):
--   * every house (and guildhall) costs its rent every 30 days, taken from the
--     owner's bank; the rent is Tibia's (houseRentRate = 1.0 in
--     family/config.family.lua), the same amount Cyclopedia shows;
--   * buying still costs the price once, and that covers the first 30 days;
--     houses owned before this change also start with 30 free days;
--   * no money in the bank on the day: a warning every day (a letter in the
--     inbox and a message) for 7 days; after that the house is taken back at
--     the next server start and its items go to the owner's depot, as Canary
--     does for !leavehouse.
--
-- Why not Canary's own rent (houseRentPeriod = "monthly")? In v3.6.1 the
-- server never reads the saved "paid until" date: at every start it marks each
-- owned house as paid for another 30 days (IOMapSerialize::loadHouseInfo ->
-- House::setOwner), and this server restarts every day at 06:00, so Canary's
-- rent would never be charged. houseRentPeriod stays "never" and the rent is
-- kept here, in the global KV "family-house-rent" (per house: owner, paid
-- until, warnings, last warning day).
--
-- When it runs: at server start (the only time a house is taken back), every
-- 10 minutes and at login (so money put in the bank is taken soon). A day the
-- server is off does not count as a warning day. If the server was off for
-- longer than a month, only one month is charged: the next one is due 30 days
-- after the payment.
--
-- Switch: Family.houseRent (false = no rent, the house is paid once).

Family = Family or {}
Family.houseRent = true

local R = {
	period = 30 * 24 * 60 * 60, -- monthly, as in Tibia
	warningDays = 7, -- Tibia: seven warnings, then the house is lost
	letter = 3506, -- stamped letter
	checkMinutes = 10,
}
Family.houseRentRules = R

local store = kv.scoped("family-house-rent")

local function now()
	return os.time()
end

local function today()
	return os.date("%Y-%m-%d", now())
end

local function formatGold(value)
	local text = tostring(math.floor(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function formatDate(t)
	return os.date("%d %b %Y", t)
end

local function houseStore(house)
	return store:scoped(tostring(house:getId()))
end

local function onlineByGuid(guid)
	for _, player in ipairs(Game.getPlayers()) do
		if player:getGuid() == guid then
			return player
		end
	end
	return nil
end

-- The house's rent record. A house whose owner changed (bought, passed on,
-- or owned before rent existed) starts with 30 paid days.
function R.record(house)
	local owner = house:getOwnerGuid()
	local s = houseStore(house)
	if owner == 0 then
		if s:get("owner") then
			s:remove("owner")
			s:remove("paid")
			s:remove("warnings")
			s:remove("warnDay")
			s:remove("letterDay")
		end
		return nil
	end
	if s:get("owner") ~= owner then
		s:set("owner", owner)
		s:set("paid", now() + R.period)
		s:set("warnings", 0)
		s:remove("warnDay")
		s:remove("letterDay")
	end
	return {
		owner = owner,
		paid = s:get("paid") or 0,
		warnings = s:get("warnings") or 0,
		warnDay = s:get("warnDay"),
		store = s,
	}
end

-- Takes the rent from the owner's bank. Online: the character's balance;
-- offline: the database (offline characters cannot be changed through Lua).
function R.takeFromBank(guid, amount)
	local player = onlineByGuid(guid)
	if player then
		local balance = player:getBankBalance()
		if balance < amount then
			return false, player
		end
		player:setBankBalance(balance - amount)
		return true, player
	end
	local result = db.storeQuery("SELECT `balance` FROM `players` WHERE `id` = " .. guid)
	if not result then
		return false, nil
	end
	local balance = Result.getNumber(result, "balance")
	Result.free(result)
	if balance < amount then
		return false, nil
	end
	db.query("UPDATE `players` SET `balance` = `balance` - " .. amount .. " WHERE `id` = " .. guid .. " AND `balance` >= " .. amount)
	return true, nil
end

function R.ownerExists(guid)
	local result = db.storeQuery("SELECT `id` FROM `players` WHERE `id` = " .. guid)
	if not result then
		return false
	end
	Result.free(result)
	return true
end

local function warningText(house, daysLeft)
	-- the words of Canary's own rent letter (src/map/house/house.cpp)
	return string.format("Warning! \nThe monthly rent of %s gold for your house \"%s\" is payable. Have it within %d days or you will lose this house.", formatGold(house:getRent()), house:getName(), daysLeft)
end

local function sendWarning(player, house, rec)
	local daysLeft = math.max(1, R.warningDays - rec.warnings + 1)
	local text = warningText(house, daysLeft)
	local inbox = player:getInbox()
	if inbox then
		local letter = Game.createItem(R.letter, 1)
		if letter then
			letter:setAttribute(ITEM_ATTRIBUTE_TEXT, text)
			inbox:addItemEx(letter, INDEX_WHEREEVER, FLAG_NOLIMIT)
		end
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("The monthly rent of %s gold for your house '%s' is payable and your bank does not have it. Put it in the bank within %d days or you will lose this house (and its items go to your depot).", formatGold(house:getRent()), house:getName(), daysLeft))
end

local function lostMessage(house)
	local town = house:getTown()
	return string.format("You lost the house '%s': its rent was not paid. Its items are in your depot in %s.", house:getName(), town and town:getName() or "its town")
end

-- Takes the house back (server start only). Items go to the owner's depot.
function R.evict(house, rec)
	local owner = rec.owner
	house:setHouseOwner(0)
	R.record(house) -- clears the record
	store:scoped("lost"):set(tostring(owner), lostMessage(house))
	if Family.houseDecorate then
		Family.houseDecorate(house)
	end
	logger.info("[Family] house rent: '{}' taken back from player {} (rent not paid)", house:getName(), owner)
end

-- One house. atStartup: the only time a house can be taken back.
-- Returns "paid", "warned", "evicted" or nil.
function R.check(house, atStartup)
	if not Family.houseRent then
		return nil
	end
	local rec = R.record(house)
	if not rec then
		return nil
	end
	if atStartup and not R.ownerExists(rec.owner) then
		house:setHouseOwner(0)
		R.record(house)
		return "evicted"
	end
	if now() < rec.paid then
		return nil
	end
	local rent = house:getRent()
	local ok, player = true, onlineByGuid(rec.owner)
	if rent > 0 then
		ok, player = R.takeFromBank(rec.owner, rent)
	end
	if ok then
		-- the next month starts where this one ended, unless the server was off
		local paid = rec.paid + R.period
		if paid <= now() then
			paid = now() + R.period
		end
		rec.store:set("paid", paid)
		rec.store:set("warnings", 0)
		rec.store:remove("warnDay")
		rec.store:remove("letterDay")
		if player then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("The monthly rent of %s gold for your house '%s' was taken from your bank. Paid until %s.", formatGold(rent), house:getName(), formatDate(paid)))
		end
		return "paid"
	end
	-- not paid: one warning day per calendar day the server runs
	if rec.warnDay ~= today() then
		if rec.warnings >= R.warningDays then
			if atStartup then
				R.evict(house, rec)
				return "evicted"
			end
			return nil -- taken back at the next start
		end
		rec.warnings = rec.warnings + 1
		rec.store:set("warnings", rec.warnings)
		rec.store:set("warnDay", today())
		rec.warnDay = today()
		rec.store:remove("letterDay")
	end
	-- the owner hears about it once a day while online
	if player and rec.store:get("letterDay") ~= today() then
		rec.store:set("letterDay", today())
		sendWarning(player, house, rec)
		return "warned"
	end
	return nil
end

function R.checkAll(atStartup)
	local counts = { paid = 0, warned = 0, evicted = 0 }
	for _, house in ipairs(Game.getHouses()) do
		local result = R.check(house, atStartup)
		if result then
			counts[result] = counts[result] + 1
		end
	end
	return counts
end

-- For !house: one line per house the player owns.
function R.statusLine(house)
	local rec = R.record(house)
	if not Family.houseRent or not rec then
		return nil
	end
	local rent = formatGold(house:getRent())
	if now() < rec.paid then
		return string.format("rent %s gold, paid until %s", rent, formatDate(rec.paid))
	end
	return string.format("rent %s gold DUE: put it in your bank (%d of %d warnings)", rent, rec.warnings, R.warningDays)
end

local startup = GlobalEvent("FamilyHouseRentStartup")

function startup.onStartup()
	addEvent(function()
		if not Family.houseRent then
			logger.info("[Family] house rent: off")
			return
		end
		local c = R.checkAll(true)
		logger.info("[Family] house rent: monthly, {} paid, {} taken back", c.paid, c.evicted)
	end, 0)
	return true
end

startup:register()

local interval = GlobalEvent("FamilyHouseRent")

function interval.onThink(interval)
	R.checkAll(false)
	return true
end

interval:interval(R.checkMinutes * 60 * 1000)
interval:register()

local login = CreatureEvent("FamilyHouseRentLogin")

function login.onLogin(player)
	if not Family.houseRent then
		return true
	end
	local guid = player:getGuid()
	local playerId = player:getId()
	addEvent(function()
		local p = Player(playerId)
		if not p then
			return
		end
		local lost = store:scoped("lost")
		local message = lost:get(tostring(guid))
		if message then
			lost:remove(tostring(guid))
			p:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
		end
		for _, house in ipairs(Game.getHouses()) do
			if house:getOwnerGuid() == guid then
				R.check(house, false)
			end
		end
	end, 2000)
	return true
end

login:register()
