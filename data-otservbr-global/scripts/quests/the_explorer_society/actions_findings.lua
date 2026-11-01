local UniqueTable = {
	-- Chests uniques
	[14029] = {
		-- Uzgod's Family Brooch
		rewardItemId = 4834,
		storageMission = Storage.Quest.U7_6.ExplorerSociety.JoiningTheExplorers,
		storageMissionValue = 3,
		storageQuestlineValue = 3,
	},
	[14030] = {
		-- Wrinkled parchment
		rewardItemId = 173,
		storageMission = Storage.Quest.U7_6.ExplorerSociety.TheBonelordSecret,
		storageMissionValue = 31,
		storageQuestlineValue = 30,
	},
	[14031] = {
		-- Strange powder
		rewardItemId = 13974,
		storageMission = Storage.Quest.U7_6.ExplorerSociety.TheOrcPowder,
		storageMissionValue = 34,
		storageQuestlineValue = 33,
	},
	[14032] = {
		-- Elven poetry book
		rewardItemId = 4844,
		storageMission = Storage.Quest.U7_6.ExplorerSociety.TheElvenPoetry,
		storageMissionValue = 37,
		storageQuestlineValue = 36,
	},
	[14033] = {
		-- Memory stone
		rewardItemId = 4841,
		storageMission = Storage.Quest.U7_6.ExplorerSociety.TheMemoryStone,
		storageMissionValue = 40,
		storageQuestlineValue = 39,
	},
	[14034] = {
		-- Spectral dress
		rewardItemId = 4836,
		storageMission = Storage.Quest.U7_6.ExplorerSociety.TheSpectralDress,
		storageMissionValue = 49,
		storageQuestlineValue = 48,
	},
	[14035] = {
		-- Damage logbook (FAMILY: was 21378, the Dawnport "torn log book"; 6124 is the damaged logbook, 2026-11-01)
		rewardItemId = 6124,
		storageMission = Storage.Quest.U7_6.ExplorerSociety.CalassaQuest,
		storageMissionValue = 2,
		storageQuestlineValue = 0,
	},
	-- Others uniques
	[40041] = {
		-- Funeral urn
		rewardItemId = 4847,
		storageMission = Storage.Quest.U7_6.ExplorerSociety.TheLizardUrn,
		storageMissionValue = 28,
		storageQuestlineValue = 27,
	},
}

local explorerSocietyFindings = Action()
function explorerSocietyFindings.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local uniqueItem = UniqueTable[item.uid]
	if not uniqueItem then
		return true
	end
	-- FAMILY: "itemId" did not exist (Lua error on a second use); and the chest only opens while its
	-- mission runs (the step before storageMissionValue). Upstream also opened it before the mission and
	-- then set the mission storage and the QuestLine, which could move the quest back and stall it (2026-11-01).
	local emptyText = "The " .. ItemType(item.itemid):getName() .. " is empty."
	if player:getStorageValue(item.uid) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, emptyText)
		return true
	end
	if player:getStorageValue(uniqueItem.storageMission) ~= uniqueItem.storageMissionValue - 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, emptyText)
		return true
	end
	if player:getStorageValue(uniqueItem.storageMission) ~= uniqueItem.storageMissionValue then
		player:addItem(uniqueItem.rewardItemId, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a " .. getItemName(uniqueItem.rewardItemId) .. ".")
		player:setStorageValue(item.uid, 1)
		player:setStorageValue(uniqueItem.storageMission, uniqueItem.storageMissionValue)
		if uniqueItem.storageQuestlineValue > 0 then
			player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.QuestLine, uniqueItem.storageQuestlineValue)
		end
		return true
	end
end

for index, value in pairs(UniqueTable) do
	explorerSocietyFindings:uid(index)
end

explorerSocietyFindings:register()
