-- Gaia Family server: Coin Brokers (2026-10-13).
--
-- Ours, not upstream. Tibia Coins are no longer free: a Coin Broker stands
-- near the temple of each port city and sells transferable Tibia Coins for
-- gold, taken from the backpack first and then from the bank. Transferable
-- coins work for every store offer and can be sent to the other player.
-- Brokers only sell; they never buy coins back.
--
-- Talk: hi -> coins -> an amount (25, 50, 100, 250, 500, 1000 or any number)
-- -> yes.
--
-- At the first start with this file, every account's coin balance (regular
-- and transferable) is set to FamilyCoinBroker.startCoins, once (marked in the
-- server_config table as family_<resetKey>).

FamilyCoinBroker = {
	enabled = true,
	goldPerCoin = 5000,
	maxPerPurchase = 10000,
	startCoins = 0,
	-- Changing this key runs the balance reset again at the next start.
	resetKey = "coin-reset-2026-10-13",
}

local cfg = FamilyCoinBroker
if not cfg.enabled then
	return
end

local function formatGold(value)
	local text = tostring(math.floor(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function brokerName(cityName)
	return cityName .. " Coin Broker"
end

local function createBrokerType(cityName)
	local name = brokerName(cityName)
	local npcType = Game.createNpcType(name)
	local npcConfig = {
		name = name,
		description = name,
		health = 100,
		maxHealth = 100,
		walkInterval = 4000,
		walkRadius = 2,
		outfit = { lookType = 132, lookHead = 79, lookBody = 114, lookLegs = 79, lookFeet = 114, lookAddons = 3 },
		flags = { floorchange = false },
		speechBubble = SPEECHBUBBLE_NORMAL,
		voices = {
			interval = 20000,
			chance = 30,
			{ text = "Tibia Coins for gold! Fair rates!" },
			{ text = "Mounts, outfits, wildcards... it all starts with coins." },
		},
	}

	local keywordHandler = KeywordHandler:new()
	local npcHandler = NpcHandler:new(keywordHandler)
	local pending = {}

	npcType.onThink = function(npc, interval)
		npcHandler:onThink(npc, interval)
	end
	npcType.onAppear = function(npc, creature)
		npcHandler:onAppear(npc, creature)
	end
	npcType.onDisappear = function(npc, creature)
		npcHandler:onDisappear(npc, creature)
	end
	npcType.onMove = function(npc, creature, fromPosition, toPosition)
		npcHandler:onMove(npc, creature, fromPosition, toPosition)
	end
	npcType.onSay = function(npc, creature, type, message)
		npcHandler:onSay(npc, creature, type, message)
	end
	npcType.onCloseChannel = function(npc, creature)
		npcHandler:onCloseChannel(npc, creature)
	end

	local function offerAmounts()
		return string.format("How many coins? {25}, {50}, {100}, {250}, {500} or {1000}, or any number up to %s. Each coin costs %s gold.", formatGold(cfg.maxPerPurchase), formatGold(cfg.goldPerCoin))
	end

	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not player or not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		local playerId = player:getId()
		local topic = npcHandler:getTopic(playerId)

		if topic == 2 then
			if MsgContains(message, "yes") then
				local amount = pending[playerId] or 0
				local price = amount * cfg.goldPerCoin
				if amount > 0 and player:removeMoneyBank(price) then
					player:addTransferableCoins(amount)
					local total = (player:getTibiaCoins() or 0) + (player:getTransferableCoins() or 0)
					npcHandler:say(string.format("Done! %s Tibia Coins are yours. You now have %s coins for the Store.", formatGold(amount), formatGold(total)), npc, creature)
					player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
				else
					npcHandler:say(string.format("You need %s gold in your backpack or in the bank for that.", formatGold(price)), npc, creature)
				end
			else
				npcHandler:say("Maybe another time. Ask me about {coins} whenever you like.", npc, creature)
			end
			pending[playerId] = nil
			npcHandler:setTopic(playerId, 0)
			return true
		end

		if topic == 1 then
			local amount = tonumber(message:match("%d+"))
			if amount and amount >= 1 and amount <= cfg.maxPerPurchase then
				pending[playerId] = amount
				npcHandler:say(string.format("%s Tibia Coins for %s gold. Deal?", formatGold(amount), formatGold(amount * cfg.goldPerCoin)), npc, creature)
				npcHandler:setTopic(playerId, 2)
				return true
			end
			if not MsgContains(message, "coin") then
				npcHandler:say("Tell me a number of coins, for example {100}.", npc, creature)
				return true
			end
		end

		if MsgContains(message, "coin") or MsgContains(message, "buy") or MsgContains(message, "trade") or MsgContains(message, "exchange") then
			npcHandler:say(offerAmounts(), npc, creature)
			npcHandler:setTopic(playerId, 1)
		elseif MsgContains(message, "price") or MsgContains(message, "rate") then
			npcHandler:say(string.format("One coin costs %s gold. I only sell coins; I don't buy them back.", formatGold(cfg.goldPerCoin)), npc, creature)
		elseif MsgContains(message, "job") then
			npcHandler:say("I exchange gold for Tibia Coins, the currency of the Store. Ask me about {coins}.", npc, creature)
		elseif MsgContains(message, "name") then
			npcHandler:say("Names don't matter, gold does. Ask me about {coins}.", npc, creature)
		end
		return true
	end)

	npcHandler:setMessage(MESSAGE_GREET, "Welcome, |PLAYERNAME|! I sell Tibia Coins for gold. Ask me about {coins}.")
	npcHandler:setMessage(MESSAGE_FAREWELL, "Spend them wisely, |PLAYERNAME|!")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "Come back when you need coins.")
	npcHandler:addModule(FocusModule:new(), name, true, true, false)

	npcType:register(npcConfig)
end

local cities = (FamilyCityLife and FamilyCityLife.cities) or {}
for _, city in ipairs(cities) do
	createBrokerType(city.name)
end

local coinBroker = GlobalEvent("FamilyCoinBroker")

function coinBroker.onStartup()
	-- One-time reset of the free coins handed out before 2026-10-13. The
	-- "done" mark is written to the server_config table at once, so the reset
	-- never runs twice, even if the server stops without saving.
	local configKey = db.escapeString("family_" .. cfg.resetKey)
	local done = db.storeQuery("SELECT `value` FROM `server_config` WHERE `config` = " .. configKey)
	if done then
		Result.free(done)
	else
		db.query(string.format("UPDATE `accounts` SET `coins` = %d, `coins_transferable` = 0", cfg.startCoins))
		db.query("INSERT INTO `server_config` (`config`, `value`) VALUES (" .. configKey .. ", '1')")
		logger.info("[Family] Tibia Coin balances of all accounts set to {} (one-time reset '{}')", cfg.startCoins, cfg.resetKey)
	end

	local placed = 0
	for _, city in ipairs(cities) do
		local npc = Game.createNpc(brokerName(city.name), city.center, true)
		if npc then
			npc:setMasterPos(npc:getPosition())
			placed = placed + 1
		else
			logger.warn("[Family] Coin Broker: no free tile near the center of {}", city.name)
		end
	end
	logger.info("[Family] Coin Brokers: {} cities, {} gold per Tibia Coin (buy only)", placed, formatGold(cfg.goldPerCoin))
	return true
end

coinBroker:register()
