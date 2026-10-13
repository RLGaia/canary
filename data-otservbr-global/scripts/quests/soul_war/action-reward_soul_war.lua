local rewardSoulWar = Action()

function rewardSoulWar.onUse(creature, item, fromPosition, target, toPosition, isHotkey)
	local rewardItem = SoulWarQuest.finalRewards[math.random(1, #SoulWarQuest.finalRewards)]
	local player = creature:getPlayer()
	if not player then
		return false
	end

	local soulWarQuest = player:soulWarQuestKV()
	-- FAMILY: the chest opens again after each new Megalomania kill or once a day (data/scripts/family/solo_quests.lua)
	if soulWarQuest:get("final-reward") then
		local ready, secondsLeft = Family.soulWarChestReady(player)
		if not ready then
			local message = "You have already received your reward."
			if secondsLeft then
				message = string.format("%s Defeat Goshnar's Megalomania again, or come back in %d h %02d min.", message, math.floor(secondsLeft / 3600), math.floor((secondsLeft % 3600) / 60))
			end
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
			return true
		end
	end

	if not soulWarQuest:get("goshnar's-megalomania-killed") then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to defeat Goshnar's Megalomania to receive your reward.")
		return true
	end

	player:addItem(rewardItem.id, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a " .. rewardItem.name .. ".")
	soulWarQuest:set("final-reward", true)
	Family.soulWarChestOpened(player)
	return true
end

rewardSoulWar:position({ x = 33620, y = 31400, z = 10 })
rewardSoulWar:register()
