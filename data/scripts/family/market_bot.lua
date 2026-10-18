-- Gaia Family server: a market that always has offers (2026-10-18). Ours,
-- not upstream. Asked by Rodrigo: with two players there is no market, so
-- early equipment was hard to get.
--
-- A hidden character ("Family Market", account "familymarket" that cannot
-- log in) owns anonymous buy and sell offers for every item the client can
-- trade on the market. They are placed again at every server start.
--
-- Prices come from real Tibia worlds (tools/family/market: the median of 12
-- worlds' month averages from TibiaMarket, else NPC prices), generated into
-- market_bot_data.lua:
--   buy offer  = real price x (1 - spread) x priceScale, rounded down
--   sell offer = real price x (1 + spread) x priceScale, rounded up
-- and kept clear of our NPCs, so there is never a gold loop:
--   - a sell offer is always above the best price an NPC pays for the item;
--   - a buy offer always pays less than an NPC that sells the item;
--   - for stackable supplies (potions, runes, ammunition, food...) a sell
--     offer is never cheaper than an NPC that sells them: real worlds have
--     cheaper sources we lack (Minzy's potions cost 19 there) and supplies are
--     the main gold sink. Equipment can be cheaper than at the NPCs.
-- Sell offers only for items players can get again and again: creature loot
-- (all creatures, bosses included, loot added at startup counts) or an NPC
-- shop. Quest, event and store items only get buy offers. Currencies and
-- tokens are left out (in the data tool).
--
-- When a player sells to a buy offer the item goes to the market character's
-- inbox; that inbox, its market history and its bank balance are cleared at
-- every start.
--
-- Switch: Family.marketBot.enabled. priceScale 1.0 = real prices; lower it
-- (e.g. 0.7) if gold comes too easily.

Family = Family or {}
Family.marketBot = {
	enabled = true,
	spread = 0.10,
	priceScale = 1.0,
	amountStackable = 10000, -- per offer, refilled at every start
	amountSingle = 100,
	characterName = "Family Market",
	accountName = "familymarket",
}

local cfg = Family.marketBot
local SALE, BUY = 1, 0

-- Round to a "nice" step: 1 below 100, then 5, 10, 100, 1,000, 10,000.
local function step(v)
	if v < 100 then
		return 1
	elseif v < 1000 then
		return 5
	elseif v < 10000 then
		return 10
	elseif v < 100000 then
		return 100
	elseif v < 1000000 then
		return 1000
	end
	return 10000
end

local function roundDown(v)
	local s = step(v)
	return math.floor(v / s) * s
end

local function roundUp(v)
	local s = step(v)
	return math.ceil(v / s) * s
end

-- Offer prices for one item (nil = no offer of that kind).
function Family.marketBotPrices(ref, npcPays, npcCharges, canSell, stackable)
	local scaled = ref * cfg.priceScale
	local buy = roundDown(scaled * (1 - cfg.spread))
	local sell = roundUp(scaled * (1 + cfg.spread))
	if npcCharges > 0 then
		buy = math.min(buy, npcCharges - 1)
		if stackable then
			sell = math.max(sell, npcCharges)
		end
	end
	if npcPays > 0 then
		sell = math.max(sell, npcPays + 1)
	end
	if buy >= sell then
		buy = sell - 1
	end
	if buy < 1 then
		buy = nil
	end
	if not canSell then
		sell = nil
	end
	return buy, sell
end

local function collect(loot, into)
	for _, entry in ipairs(loot or {}) do
		if entry.itemId and entry.itemId > 0 then
			into[entry.itemId] = true
		end
		collect(entry.childLoot, into)
	end
end

local function droppedItems()
	local dropped = {}
	for _, mType in pairs(Game.getMonsterTypes()) do
		collect(mType:getLoot(), dropped)
	end
	return dropped
end

local function queryId(sql)
	local result = db.storeQuery(sql)
	if not result then
		return nil
	end
	local id = Result.getNumber(result, "id")
	Result.free(result)
	return id
end

-- The market character's player id, created when missing.
function Family.marketBotCharacter()
	local name = db.escapeString(cfg.characterName)
	local id = queryId("SELECT `id` FROM `players` WHERE `name` = " .. name)
	if id then
		return id
	end
	local account = db.escapeString(cfg.accountName)
	local accountId = queryId("SELECT `id` FROM `accounts` WHERE `name` = " .. account)
	if not accountId then
		-- "x" is no valid password hash, so nobody can log in to it.
		db.query("INSERT INTO `accounts` (`name`, `password`, `type`, `creation`) VALUES (" .. account .. ", 'x', 1, " .. os.time() .. ")")
		accountId = queryId("SELECT `id` FROM `accounts` WHERE `name` = " .. account)
	end
	if not accountId then
		return nil
	end
	db.query("INSERT INTO `players` (`name`, `account_id`, `conditions`, `level`, `vocation`, `town_id`) VALUES (" .. name .. ", " .. accountId .. ", '', 1, 0, 1)")
	return queryId("SELECT `id` FROM `players` WHERE `name` = " .. name)
end

local function refresh()
	local ok, data = pcall(dofile, CORE_DIRECTORY .. "/scripts/family/market_bot_data.lua")
	if not ok or type(data) ~= "table" then
		logger.error("[Family] market: price table not loaded: {}", tostring(data))
		return
	end
	local botId = Family.marketBotCharacter()
	if not botId then
		logger.error("[Family] market: could not create the market character")
		return
	end
	db.query("DELETE FROM `market_offers` WHERE `player_id` = " .. botId)
	db.query("DELETE FROM `player_inboxitems` WHERE `player_id` = " .. botId)
	db.query("DELETE FROM `market_history` WHERE `player_id` = " .. botId)
	db.query("UPDATE `players` SET `balance` = 0 WHERE `id` = " .. botId)

	local dropped = droppedItems()
	local now = os.time()
	local rows, buys, sells = {}, 0, 0
	local function flush()
		if #rows > 0 then
			db.query("INSERT INTO `market_offers` (`player_id`, `sale`, `itemtype`, `amount`, `created`, `anonymous`, `price`, `tier`) VALUES " .. table.concat(rows, ","))
			rows = {}
		end
	end
	local function add(sale, itemId, amount, price)
		rows[#rows + 1] = string.format("(%d,%d,%d,%d,%d,1,%d,0)", botId, sale, itemId, amount, now, price)
		if #rows >= 500 then
			flush()
		end
	end
	for itemId, entry in pairs(data) do
		local itemType = ItemType(itemId)
		if itemType and itemType:getId() == itemId then
			local ref, npcPays, npcCharges, npcSells = entry[1], entry[2], entry[3], entry[4]
			local canSell = npcSells == 1 or dropped[itemId] == true
			local stackable = itemType:isStackable()
			local buy, sell = Family.marketBotPrices(ref, npcPays, npcCharges, canSell, stackable)
			local amount = stackable and cfg.amountStackable or cfg.amountSingle
			if buy then
				add(BUY, itemId, amount, buy)
				buys = buys + 1
			end
			if sell then
				add(SALE, itemId, amount, sell)
				sells = sells + 1
			end
		end
	end
	flush()
	logger.info("[Family] market: {} buy offers, {} sell offers (price scale {})", buys, sells, cfg.priceScale)
end

local startup = GlobalEvent("FamilyMarketBot")

function startup.onStartup()
	if cfg.enabled then
		addEvent(refresh, 0) -- after the startup scripts that add loot
	end
	return true
end

startup:register()
