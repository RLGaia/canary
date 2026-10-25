-- Gaia Family server: Citizen addons in the quest log (2026-10-25). Ours, not upstream.
--
-- Reported by Rodrigo: Lubo took the 100 minotaur leather, the server said
-- "Your questlog has been updated", but the quest log showed nothing. The
-- missions "Citizen Addon: Backpack" (Lubo/Amber) and "Citizen Addon: Feather
-- Hat" (Hanna/Norma) belong to the group "Outfit and Addon Quests", which only
-- shows once Storage.OutfitQuest.DefaultStart is 1, and neither Lubo nor Hanna
-- set it (other outfit NPCs do). Upstream also reset both missions to 0 when
-- the addon was handed over, which hid them again. Lubo and Hanna now set the
-- group (FAMILY: in npc/lubo.lua and npc/hanna.lua) and finish the missions at
-- 3 / 2 (catalog 012). This login check repairs characters that started or
-- finished either addon before the fix. Neither wiki documents a quest log
-- entry for this quest; the entry is Canary's own.
--
-- Switch: Family.citizenAddonQuestLog (false = no login repair).

Family = Family or {}
Family.citizenAddonQuestLog = true

local S = Storage.Quest.U7_8.CitizenOutfits

local function raise(player, key, value)
	if player:getStorageValue(key) < value then
		player:setStorageValue(key, value)
	end
end

function Family.repairCitizenAddonQuestLog(player)
	local backpack = player:getStorageValue(S.AddonBackpack)
	local hat = player:getStorageValue(S.AddonHat)
	if backpack < 1 and hat < 1 then
		return
	end
	raise(player, Storage.OutfitQuest.DefaultStart, 1)
	if backpack >= 1 then
		raise(player, S.MissionBackpack, math.min(backpack, 3)) -- 1 collecting, 2 being made, 3 received
	end
	if hat >= 1 then
		raise(player, S.MissionHat, math.min(hat, 2)) -- 1 collecting, 2 received
	end
end

local login = CreatureEvent("FamilyCitizenAddonLogin")

function login.onLogin(player)
	if Family.citizenAddonQuestLog then
		Family.repairCitizenAddonQuestLog(player)
	end
	return true
end

login:register()
