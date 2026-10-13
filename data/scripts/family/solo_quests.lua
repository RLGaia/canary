-- Gaia Family server: quests for one or two players (batch 2, 2026-10-12).
--
-- This file is ours (not upstream). It defines the global `Family` table that
-- a few upstream quest/NPC files read; each of those edits is marked with a
-- "FAMILY:" comment and listed in FAMILY.md.
--
-- What it unlocks:
--   * Exclusive quest lines can all be completed: both Djinn factions
--     (Blue/Marid and Green/Efreet) and all three Secret Service agencies
--     (one after another).
--   * "Choose one reward" chests: every chest of the group can be opened once
--     (Annihilator, Pits of Inferno, Barbarian Arena, Thieves Guild, Wrath of
--     the Emperor, The Inquisition, The Demon Oak).

Family = Family or {}

-- Set to false to restore the upstream "pick one side / one reward" rules.
Family.unlockExclusiveQuests = true

-- ---------------------------------------------------------------------------
-- Chests from startup/tables/chest.lua whose group shares one storage
-- ("choose one"). Each chest of these groups can be opened once.
-- ---------------------------------------------------------------------------
local choiceChestStorages = {
	[Storage.Quest.U7_24.TheAnnihilator.Reward] = "Annihilator",
	[Storage.Quest.U7_9.ThePitsOfInferno.RewardChestStaffAvengerArbalest] = "Pits of Inferno",
	[Storage.Quest.U8_0.BarbarianArena.RewardGreenhornWeapons] = "Barbarian Arena (Greenhorn)",
	[Storage.Quest.U8_0.BarbarianArena.RewardScrapperWeapons] = "Barbarian Arena (Scrapper)",
	[Storage.Quest.U8_0.BarbarianArena.RewardWarlordWeapons] = "Barbarian Arena (Warlord)",
	[Storage.Quest.U8_2.TheThievesGuildQuest.RewardEnd] = "Thieves Guild",
	[Storage.Quest.U8_6.WrathOfTheEmperor.ChestItems] = "Wrath of the Emperor",
}

local function chestScope(player)
	return player:kv():scoped("family-chests")
end

-- True when this chest.lua entry belongs to a "choose one" group.
function Family.isChoiceChest(setting)
	return Family.unlockExclusiveQuests and setting and not setting.useKV and setting.storage ~= nil and choiceChestStorages[setting.storage] ~= nil
end

function Family.isChestTaken(player, uid)
	return chestScope(player):get("chest-" .. uid) == true
end

function Family.markChestTaken(player, uid)
	chestScope(player):set("chest-" .. uid, true)
end

-- For quests whose chests are scripted (not in chest.lua).
-- alreadyRewarded: the quest's own "reward taken" check.
-- Returns true when the chest may be opened, and then marks it as taken.
function Family.canOpenChoiceChest(player, uid, alreadyRewarded)
	if not Family.unlockExclusiveQuests then
		return not alreadyRewarded
	end
	if Family.isChestTaken(player, uid) then
		return false
	end
	Family.markChestTaken(player, uid)
	return true
end

-- Number of chests of a chest.lua "choose one" group this player has not opened yet.
function Family.choiceChestsLeft(player, groupStorage)
	if not Family.unlockExclusiveQuests or not ChestUnique then
		return 0
	end
	local left = 0
	for uid, setting in pairs(ChestUnique) do
		if setting.storage == groupStorage and not setting.useKV and not Family.isChestTaken(player, uid) then
			left = left + 1
		end
	end
	return left
end

-- ---------------------------------------------------------------------------
-- The Secret Service: after finishing one agency (TBI, CGB or AVIN), the
-- player may join another one and play its missions too.
-- ownMission01: the agency's first mission storage.
-- ---------------------------------------------------------------------------
local SecretService = Storage.Quest.U8_1.SecretService
local SECRET_SERVICE_DONE = 15 -- SecretService.Quest value after the last mission

function Family.secretServiceCanJoin(player, ownMission01)
	local progress = player:getStorageValue(SecretService.Quest)
	if progress < 1 then
		return true
	end
	return Family.unlockExclusiveQuests and progress >= SECRET_SERVICE_DONE and player:getStorageValue(ownMission01) < 1
end

-- ---------------------------------------------------------------------------
-- Startup report
-- ---------------------------------------------------------------------------
local familyQuestsReport = GlobalEvent("FamilyQuestsReport")

function familyQuestsReport.onStartup()
	local groups, chests = 0, 0
	if ChestUnique then
		local seen = {}
		for _, setting in pairs(ChestUnique) do
			if Family.isChoiceChest(setting) then
				chests = chests + 1
				if not seen[setting.storage] then
					seen[setting.storage] = true
					groups = groups + 1
				end
			end
		end
	end
	logger.info("[Family] exclusive quests unlocked={} (choose-one chest groups: {}, chests: {})", tostring(Family.unlockExclusiveQuests), groups, chests)
	return true
end

familyQuestsReport:register()
