local rewards = {
	[1300] = 8062,
	[1301] = 8090,
	[1302] = 8053,
	[1303] = 8060,
	[1304] = 8023,
	[1305] = 8096,
	[1306] = 8100,
	[1307] = 8102,
	[1308] = 8026,
}

-- FAMILY: Tibia's monk reward (merudri nanbando). Our map has no chest for it:
-- data/scripts/family/monk_gear.lua puts one in the east corner of the room.
local MONK_CHEST_KEY = 1309
local MONK_REWARD = 50261
InquisitionMonkChestPosition = Position(32330, 32248, 9)

local inquisitionRewards = Action()
function inquisitionRewards.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: every reward chest can be opened once (data/scripts/family/solo_quests.lua)
	local alreadyRewarded = player:getStorageValue(Storage.Quest.U8_2.TheInquisitionQuest.Reward) >= 1
	local key, reward = item.uid, rewards[item.uid]
	if not reward and item:getPosition() == InquisitionMonkChestPosition then
		key, reward = MONK_CHEST_KEY, MONK_REWARD
	end
	if not reward then
		return false
	end
	if Family.canOpenChoiceChest(player, key, alreadyRewarded) then
		player:setStorageValue(Storage.Quest.U8_2.TheInquisitionQuest.Reward, 1)
		player:setStorageValue(Storage.Quest.U8_2.TheInquisitionQuest.Questline, 25)
		player:setStorageValue(Storage.Quest.U8_2.TheInquisitionQuest.Mission07, 5) -- The Inquisition Questlog- "Mission 7: The Shadow Nexus"
		player:addItem(reward, 1)
		local article = ItemType(reward):getArticle()
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. (article ~= "" and (article .. " ") or "") .. ItemType(reward):getName() .. ".")
		player:addAchievement("Master of the Nexus")
		player:addOutfitAddon(288, 2)
		player:addOutfitAddon(288, 1)
		player:addOutfitAddon(289, 1)
		player:addOutfitAddon(289, 2)
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
	end
	return true
end

for uniqueId, info in pairs(rewards) do
	inquisitionRewards:uid(uniqueId)
end

inquisitionRewards:position(InquisitionMonkChestPosition)

inquisitionRewards:register()
