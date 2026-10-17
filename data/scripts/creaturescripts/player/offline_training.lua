-- FAMILY: with Family.offlineTrainingUnlimited (data/scripts/family/offline_training.lua)
-- the whole time away counts (up to 21 days, also days with the server off)
-- instead of at most 12 hours, and the offline training time is never used up.
local offlineTraining = CreatureEvent("OfflineTraining")

function offlineTraining.onLogin(player)
	local lastLogout = player:getLastLogout()
	local offlineTime = lastLogout ~= 0 and math.min(os.time() - lastLogout, 86400 * 21) or 0
	local offlineTrainingSkill = player:getOfflineTrainingSkill()
	if offlineTrainingSkill == SKILL_NONE then
		player:addOfflineTrainingTime(offlineTime * 1000)
		return true
	end

	player:setOfflineTrainingSkill(SKILL_NONE)

	if offlineTime < 600 then
		player:sendTextMessage(MESSAGE_OFFLINE_TRAINING, "You must be logged out for more than 10 minutes to start offline training.")
		return true
	end

	local trainingTime
	if Family and Family.offlineTrainingUnlimited then -- FAMILY
		trainingTime = offlineTime
		player:addOfflineTrainingTime(12 * 3600 * 1000) -- stays full (12:00)
	else
		trainingTime = math.max(0, math.min(offlineTime, math.min(43200, player:getOfflineTrainingTime() / 1000)))
		player:removeOfflineTrainingTime(trainingTime * 1000)

		local remainder = offlineTime - trainingTime
		if remainder > 0 then
			player:addOfflineTrainingTime(remainder * 1000)
		end
	end

	if trainingTime < 60 then
		return true
	end

	-- FAMILY: days, hours and minutes (more than a day is possible here).
	local parts = {}
	local function addPart(value, unit)
		if value > 0 then
			parts[#parts + 1] = string.format("%d %s%s", value, unit, value > 1 and "s" or "")
		end
	end
	addPart(math.floor(trainingTime / 86400), "day")
	addPart(math.floor((trainingTime % 86400) / 3600), "hour")
	addPart(math.floor((trainingTime % 3600) / 60), "minute")
	local text = "During your absence you trained for " .. parts[#parts]
	if #parts > 1 then
		text = "During your absence you trained for " .. table.concat(parts, ", ", 1, #parts - 1) .. " and " .. parts[#parts]
	end
	text = string.format("%s.", text)
	player:sendTextMessage(MESSAGE_OFFLINE_TRAINING, text)

	local vocation = player:getVocation()
	local promotion = vocation:getPromotion()
	local topVocation = not promotion and vocation or promotion

	local tries = nil
	if table.contains({ SKILL_CLUB, SKILL_SWORD, SKILL_AXE, SKILL_DISTANCE, SKILL_FIST }, offlineTrainingSkill) then
		local modifier = topVocation:getBaseAttackSpeed() / 1000
		tries = (trainingTime / modifier) / (offlineTrainingSkill == SKILL_DISTANCE and 4 or 2)
	elseif offlineTrainingSkill == SKILL_MAGLEVEL then
		local gainTicks = topVocation:getManaGainTicks() / 1000
		if gainTicks == 0 then
			gainTicks = 1
		end

		tries = trainingTime * (vocation:getManaGainAmount() / gainTicks)
	end

	local updateSkills = false
	if tries then
		updateSkills = player:addOfflineTrainingTries(offlineTrainingSkill, tries * configManager.getFloat(configKeys.RATE_OFFLINE_TRAINING_SPEED))
	end

	if updateSkills then
		player:addOfflineTrainingTries(SKILL_SHIELD, trainingTime / 4)
	end
	return true
end

offlineTraining:register()
