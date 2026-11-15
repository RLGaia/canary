-- Gaia Family server: post office discount of The Postman Missions Quest (2026-11-15).
--
-- Ours, not upstream. Asked by Rodrigo after the Postman review. Kevin makes a
-- character Assistant Postman with "All Postofficers will charge you less money
-- from now on" (TibiaWiki EN/BR transcripts); the BR quest page lists "Desconto
-- em parcels e letters" for that rank, and the item pages give the prices:
-- letter 5 gp instead of 8, parcel 10 gp instead of 15 (TibiaWiki BR Letter and
-- Parcel, EN Letter and Parcel). Upstream never lowered them.
--
-- How: while the NPC files load, every shop that sells a letter or a parcel is
-- remembered (registerNpcType runs for each npcType:register). When such an NPC
-- opens its shop for a character of rank 1 or more, it opens a per-player copy
-- of the same list with the two lower prices (npc:openShopWindowTable). The
-- engine charges a purchase with the player's own list (Npc::getShopItemVector),
-- so the lower price is what is paid. NPCs that build their own shop windows
-- (the house hireling) keep the normal prices.
--
-- Switch: Family.postmanShopDiscount (false = upstream prices for everyone).

Family = Family or {}
Family.postmanShopDiscount = true

FamilyPostmanShop = FamilyPostmanShop or {}
local D = FamilyPostmanShop

D.minRank = 1 -- Assistant Postman
D.prices = {
	[3505] = 5, -- letter (normal 8)
	[3503] = 10, -- parcel (normal 15)
}
D.shops = D.shops or {} -- NPC name (lower case) -> list in openShopWindowTable form

local function entryFrom(shopItem)
	local clientId = shopItem.clientId or shopItem.clientid
	if not clientId then
		return nil
	end
	return {
		clientId = clientId,
		itemName = shopItem.itemName or shopItem.itemname,
		subType = shopItem.subType or shopItem.subtype or shopItem.count or 0,
		buy = shopItem.buy or 0,
		sell = shopItem.sell or 0,
		storageKey = shopItem.storageKey or shopItem.storagekey or 0,
		storageValue = shopItem.storageValue or shopItem.storagevalue or 0,
	}
end

function D.record(name, shop)
	if type(name) ~= "string" or type(shop) ~= "table" then
		return
	end
	local list, mail = {}, false
	for _, shopItem in pairs(shop) do
		local entry = entryFrom(shopItem)
		if entry then
			list[#list + 1] = entry
			if D.prices[entry.clientId] and entry.buy > D.prices[entry.clientId] then
				mail = true
			end
		end
	end
	if mail then
		D.shops[name:lower()] = list
	end
end

function D.applies(player)
	return Family.postmanShopDiscount and player and player:getStorageValue(Storage.Quest.U7_24.ThePostmanMissions.Rank) >= D.minRank
end

-- The list an NPC shows to this player, or nil for the normal shop.
function D.listFor(npcName, player)
	local base = D.shops[(npcName or ""):lower()]
	if not base or not D.applies(player) then
		return nil
	end
	local list = {}
	for i, entry in ipairs(base) do
		local copy = {}
		for k, v in pairs(entry) do
			copy[k] = v
		end
		local cheaper = D.prices[copy.clientId]
		if cheaper and copy.buy > cheaper then
			copy.buy = cheaper
		end
		list[i] = copy
	end
	return list
end

-- Remember the shops while the NPC files register (they load after this file).
registerNpcType.familyPostmanShop = function(npcType, mask)
	D.record(mask.name, mask.shop)
end

local openShopWindow = D.openShopWindow or Npc.openShopWindow
D.openShopWindow = openShopWindow
function Npc.openShopWindow(self, player, ...)
	local p = Player(player)
	local list = p and D.listFor(self:getName(), p)
	if list then
		return self:openShopWindowTable(p, list)
	end
	return openShopWindow(self, player, ...)
end

local startup = GlobalEvent("FamilyPostmanShopStartup")
function startup.onStartup()
	local n = 0
	for _ in pairs(D.shops) do
		n = n + 1
	end
	logger.info("[Family] postman shop discount: {} (letter 5, parcel 10 from Assistant Postman; {} post office shops)", Family.postmanShopDiscount and "on" or "off", n)
	return true
end
startup:register()
