local UniqueTable = {
	[14001] = {
		name = "giant shimmering pearl",
		count = 1,
	},
	[14002] = {
		-- gold nugget,
		itemId = 3040,
		count = 2,
	},
	[14003] = {
		name = "blue crystal shard",
		count = 1,
	},
	[14004] = {
		name = "violet crystal shard",
		count = 1,
	},
	[14005] = {
		name = "green crystal splinter",
		count = 2,
	},
	[14006] = {
		-- red gem
		itemId = 3039,
		count = 1,
	},
	[14007] = {
		name = "onyx chip",
		count = 3,
	},
	[14008] = {
		name = "platinum coin",
		count = 3,
	},
	[14009] = {
		name = "red crystal fragment",
		count = 2,
	},
	[14010] = {
		name = "yellow gem",
		count = 1,
	},
	[14011] = {
		name = "talon",
		count = 3,
	},
	[14012] = {
		name = "white pearl",
		count = 2,
	},
	[14013] = {
		name = "gold ingot",
		count = 1,
	},
	[14014] = {
		name = "opal",
		count = 3,
	},
	[14015] = {
		name = "small diamond",
		count = 2,
	},
	[14016] = {
		name = "green crystal shard",
		count = 1,
	},
	[14017] = {
		name = "black pearl",
		count = 3,
	},
	[14018] = {
		name = "emerald bangle",
		count = 1,
	},
	[14019] = {
		name = "green gem",
		count = 1,
	},
	[14020] = {
		name = "giant shimmering pearl",
		count = 1,
	},
}

-- FAMILY: the Treasure counter is the number of chests opened (2026-10-18).
-- Upstream added 1 to the storage, which starts at -1: a chest opened before
-- talking to Tamoril was lost (the counter ended one short, so Kalyassa needed
-- an extra chest and the 20th chest gave no Treasure Hunter achievement).
-- Tamoril and a login check use the same count, which repairs old progress.
function TheFirstDragonChestsOpened(player)
	local opened = 0
	for uid in pairs(UniqueTable) do
		if player:getStorageValue(uid) > 0 then
			opened = opened + 1
		end
	end
	return opened
end

function TheFirstDragonSyncChests(player)
	local opened = TheFirstDragonChestsOpened(player)
	local counter = Storage.Quest.U11_02.TheFirstDragon.ChestCounter
	if opened > 0 and player:getStorageValue(counter) ~= opened then
		player:setStorageValue(counter, opened)
	end
	return opened
end

local treasureChest = Action()

function treasureChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local setting = UniqueTable[item.uid]
	if not setting then
		return false
	end

	local storageValue = player:getStorageValue(item.uid)
	if storageValue > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The " .. item:getName() .. " is empty.")
		return true
	end

	player:setStorageValue(item.uid, 1)
	local opened = TheFirstDragonSyncChests(player)
	if opened >= 20 then
		player:addAchievement("Treasure Hunter")
	end

	if setting.name then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found " .. setting.count .. " " .. setting.name .. ".")
		player:addItem(setting.name, setting.count, true)
	elseif setting.itemId then
		player:addItem(setting.itemId, setting.count, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found " .. setting.count .. " " .. getItemName(setting.itemId) .. ".")
	end
	return true
end

for index, value in pairs(UniqueTable) do
	treasureChest:uid(index)
end

treasureChest:register()

-- FAMILY: repair the Treasure counter of characters who opened chests before
-- this fix (counted one short).
local chestLogin = CreatureEvent("FamilyFirstDragonChests")
function chestLogin.onLogin(player)
	TheFirstDragonSyncChests(player)
	return true
end
chestLogin:register()
