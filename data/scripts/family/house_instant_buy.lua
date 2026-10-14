-- Gaia Family server: Cyclopedia "Bid" buys a house at once (2026-10-13).
--
-- Ours, not upstream. The client sends Cyclopedia house actions as packet
-- 0xAD. A Lua module (data/modules/scripts/family/cyclopedia_houses.lua, listed
-- in data/modules/modules.xml) sees every packet before the server handles it
-- and calls Family.cyclopediaInstantBuy below. For a bid on a free house it:
--   1. takes the price (the house's rent, already scaled by houseRentRate)
--      from the bank, as Cyclopedia does, and makes the player the owner;
--   2. tells the client the bid succeeded;
--   3. rewrites the packet into "show the houses of this town", so the
--      server, instead of starting an auction, refreshes the Cyclopedia list
--      and the house shows as yours.
-- Anything else (other actions, houses that are not free, not enough money,
-- no vocation) goes on to the normal server code untouched.
--
-- Switch: FAMILY_INSTANT_CYCLOPEDIA_HOUSES in data/scripts/lib/family_houses.lua.

Family = Family or {}

local PACKET_BID = 1
local BID_BYTES = 1 + 4 + 8 -- action, house client id, bid value
local houseSpells = { "House Door List", "House Guest List", "House Kick", "House Subowner List" }

local byClientId

-- Cyclopedia uses the houses' client ids; the house file maps them to ids.
local function houseByClientId(clientId)
	if not byClientId then
		byClientId = {}
		local path = string.format("%s/world/%s-house.xml", configManager.getString(configKeys.DATA_DIRECTORY), configManager.getString(configKeys.MAP_NAME))
		local file = io.open(path, "r")
		if not file then
			logger.warn("[Family] instant houses: could not read {}", path)
			return nil
		end
		local content = file:read("*a")
		file:close()
		for tag in content:gmatch("<house%s[^>]*>") do
			local id = tonumber(tag:match('houseid="(%d+)"'))
			local client = tonumber(tag:match('clientid="(%d+)"'))
			if id and client then
				byClientId[client] = id
			end
		end
	end
	local id = byClientId[clientId]
	return id and House(id)
end

local function formatGold(value)
	local text = tostring(math.floor(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function sendBidSuccess(player, clientId)
	local reply = NetworkMessage()
	reply:addByte(0xC3) -- house auction message
	reply:addU32(clientId)
	reply:addByte(PACKET_BID)
	reply:addByte(0x00)
	reply:addByte(0x00) -- success
	reply:sendToPlayer(player)
	reply:delete()
end

-- Called with the packet positioned just after its 0xAD byte. Leaves the
-- position there, so the server reads the (possibly rewritten) action next.
-- Returns true when the house was bought.
function Family.cyclopediaInstantBuy(player, msg)
	if not FAMILY_INSTANT_CYCLOPEDIA_HOUSES or not player then
		return false
	end
	if msg:getUnreadBytes() < BID_BYTES then
		return false
	end
	local action = msg:getByte()
	if action ~= PACKET_BID then
		msg:skipBytes(-1)
		return false
	end
	local clientId = msg:getU32()
	msg:getU64() -- the bid value is not used: the price is the house's rent
	msg:skipBytes(-BID_BYTES)

	local house = houseByClientId(clientId)
	if not house or house:getOwnerGuid() ~= 0 then
		return false
	end
	if player:getVocation():getId() == VOCATION_NONE or not player:isPremium() then
		return false
	end
	local price = house:getRent()
	if player:getBankBalance() < price then
		return false -- the server answers "not enough money"
	end

	player:setBankBalance(player:getBankBalance() - price)
	house:setHouseOwner(player:getGuid())
	for _, spellName in ipairs(houseSpells) do
		if not player:hasLearnedSpell(spellName) then
			player:learnSpell(spellName)
		end
	end
	sendBidSuccess(player, clientId)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You bought the house '%s' for %s gold from your bank. It is yours now: no rent, never lost. Say !house for help.", house:getName(), formatGold(price)))
	player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
	logger.info("[Family] {} bought the house '{}' in Cyclopedia for {} gold", player:getName(), house:getName(), price)

	-- Turn the bid into "list the houses of this town": the server then sends
	-- the updated list instead of starting an auction.
	local town = house:getTown()
	local townName = town and town:getName() or ""
	msg:addByte(0)
	msg:addString(townName)
	msg:skipBytes(-(1 + 2 + #townName))
	return true
end
