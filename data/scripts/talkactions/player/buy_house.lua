local buyHouse = TalkAction("!buyhouse")

function buyHouse.onSay(player, words, param)
	local housePrice = configManager.getNumber(configKeys.HOUSE_PRICE_PER_SQM)
	if housePrice == -1 then
		return true
	end

	if not player:isPremium() then
		player:sendCancelMessage("You need a premium account.")
		return true
	end

	local houseBuyLevel = configManager.getNumber(configKeys.HOUSE_BUY_LEVEL)
	if player:getLevel() < houseBuyLevel then
		player:sendCancelMessage("You need to be level " .. houseBuyLevel .. " to buy a house.")
		return true
	end

	local position = player:getPosition()
	position:getNextPosition(player:getDirection())

	local tile = Tile(position)
	local house = tile and tile:getHouse()
	local playerPos = player:getPosition()
	local houseEntry = house and house:getExitPosition()

	if not house or playerPos ~= houseEntry then
		player:sendCancelMessage("You have to be looking at the door of the house you would like to buy.")
		return true
	end

	if house:getOwnerGuid() > 0 then
		player:sendCancelMessage("This house already has an owner.")
		return true
	end

	-- FAMILY: no limit on how many houses a character owns.
	if not FAMILY_UNLIMITED_HOUSES and player:getHouse() then
		player:sendCancelMessage("You are already the owner of a house.")
		return true
	end

	if house:hasItemOnTile() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cannot buy this house, as there are items inside it. Please, contact an administrator.")
		return true
	end

	local price = house:getPrice()
	if not player:removeMoneyBank(price) then
		player:sendCancelMessage("You do not have enough money.")
		return true
	end
	metrics.addCounter("balance_decrease", price, { -- FAMILY: upstream passed an undefined variable
		player = player:getName(),
		context = "house_purchase",
	})

	house:setHouseOwner(player:getGuid())
	-- FAMILY: no rent on this server (houseRentPeriod = "never").
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You have successfully bought the house '%s' for %d gold. There is no rent: it is yours until you leave it. Type !house for help.", house:getName(), price))
	local houseSpells = { "House Door List", "House Guest List", "House Kick", "House Subowner List" }
	local learnedSpells = {}

	for i = 1, #houseSpells do
		local spellName = houseSpells[i]
		if not player:hasLearnedSpell(spellName) then
			player:learnSpell(spellName)
			table.insert(learnedSpells, spellName)
		end
	end
	return true
end

-- FAMILY: also available while Cyclopedia auctions are on (instant purchase).
if FAMILY_HOUSE_COMMANDS or not configManager.getBoolean(configKeys.CYCLOPEDIA_HOUSE_AUCTION) then
	buyHouse:setDescription("- look at a house door and buy it at once (same price as in Cyclopedia)")
	buyHouse:separator(" ")
	buyHouse:groupType("normal")
	buyHouse:register()
end
