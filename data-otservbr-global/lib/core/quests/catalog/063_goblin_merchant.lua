-- FAMILY: Goblin Merchant Quest (ours, 2026-11-23): upstream had no tasks. Quest and mission
-- names as in Tibia (TibiaWiki BR screenshots: "Goblin Merchant", "Goblin Advertisement",
-- "Rattraction", "Business Opportunities", "Hungry Birds"); texts in
-- lib/others/family_goblin_merchant.lua (FamilyGoblinMerchant.describe, which loads after
-- this file). A mission shows once its task was taken; "(completed)" = reported, free
-- again 20 hours later. Mission ids 11286-11291.
local S = Storage.Quest.U9_80.GoblinMerchant

local function describe(task)
	return function(player)
		if not FamilyGoblinMerchant then
			return "Ask Rafzan in the Venore swamp for work."
		end
		return FamilyGoblinMerchant.describe(player, task)
	end
end

return {
	name = "Goblin Merchant",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = {
		{ name = "Goblin Advertisement", storageId = S.Advertising, missionId = 11286, startValue = 0, endValue = 3, description = describe("advertising") },
		{ name = "Rattraction", storageId = S.Perfume, missionId = 11287, startValue = 0, endValue = 3, description = describe("perfume") },
		{ name = "Guardian Angel - Kind Of", storageId = S.Guards, missionId = 11288, startValue = 0, endValue = 3, description = describe("guards") },
		{ name = "To Piss Off Some Rats", storageId = S.Busy, missionId = 11289, startValue = 0, endValue = 3, description = describe("busy") },
		{ name = "Business Opportunities", storageId = S.Destroy, missionId = 11290, startValue = 0, endValue = 3, description = describe("destroy") },
		{ name = "Hungry Birds", storageId = S.Kill, missionId = 11291, startValue = 0, endValue = 3, description = describe("kill") },
	},
}
