-- The Rookie Guard Quest - Mission 06: Run Like a Wolf

local missionTiles = {
	[50329] = {
		state = 2,
		message = "Follow the north-eastern path into the forest. Beware of wolves!",
		arrowPosition = { x = 32109, y = 32166, z = 7 },
	},
	[50330] = {
		state = 2,
		message = "This is not the way into the wolf forest. Stay on the southern path leading to the north-east!",
	},
	[50331] = {
		state = 2,
		message = "This is not the way into the wolf forest. Stay on the southern path leading to the north-east!",
	},
	[50332] = {
		state = 2,
		message = "This hole leads into the wolves' den. Only enter if you have full health and food - this might be dangerous.",
		arrowPosition = { x = 32138, y = 32132, z = 7 },
	},
	[50333] = {
		state = 3,
		message = "It seems plans changed. It's up to you now to find a dead war wolf and use the skinning knife on it to get some leather.",
	},
}

-- Mission tutorial tiles

local missionGuide = MoveEvent()

function missionGuide.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local missionState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06)
	-- Skip if not was started or finished
	if missionState == -1 or missionState >= 4 then
		return true
	end
	local tile = missionTiles[item.actionid]
	-- Check if the tile is active
	if missionState == tile.state then
		-- Check delayed notifications (message/arrow)
		if not isTutorialNotificationDelayed(player) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, tile.message)
			if tile.arrowPosition then
				Position(tile.arrowPosition):sendMagicEffect(CONST_ME_TUTORIALARROW)
			end
		end
	end
	return true
end

for index, value in pairs(missionTiles) do
	missionGuide:aid(index)
end
missionGuide:register()

-- War wolf den hole

local warWolfDenHole = MoveEvent()

function warWolfDenHole.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local missionState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06)
	if missionState == -1 or missionState >= 4 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have no business down there.")
		player:teleportTo(fromPosition, true)
	end
	return true
end

warWolfDenHole:uid(25024)
warWolfDenHole:register()

local specialMissionTiles = {
	[25025] = {
		state = 2,
		message = "Well.. that seems to be the poacher. Dead. Check his body - maybe he still has something that you can use.",
		arrowPosition = { x = 32135, y = 32133, z = 8 },
		newState = 3,
	},
	[25026] = {
		state = 3,
		message = "There is a dead war wolf! Use the knife, and then use it on its body to get some leather - but quickly!",
		arrowPosition = { x = 32108, y = 32132, z = 11 },
	},
	[25027] = {
		state = 5,
		message = "You reached the exit in time! Phew.. back to Tom.",
		newState = 6,
	},
}

-- War wolf den special tiles

local warWolfDenTiles = MoveEvent()

function warWolfDenTiles.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local missionState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06)
	if missionState == -1 then
		return true
	end
	local missionTile = specialMissionTiles[item.uid]
	-- Check if the tile is active
	if missionState == missionTile.state then
		-- Check delayed notifications (message/arrow)
		if not isTutorialNotificationDelayed(player) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, missionTile.message)
			if missionTile.arrowPosition then
				Position(missionTile.arrowPosition):sendMagicEffect(CONST_ME_TUTORIALARROW)
			end
		end
		if missionTile.newState then
			player:setStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06, missionTile.newState)
		end
	end
	return true
end

for index, value in pairs(specialMissionTiles) do
	warWolfDenTiles:uid(index)
end
warWolfDenTiles:register()

-- War wolf den boost tiles

-- FAMILY: the den's floors below the hole; the 25 s check only pulls back a player still in it
-- (one who left with an adventurer's stone was taken back into the den)
local function inWolfDen(position)
	return position.x >= 32095 and position.x <= 32160 and position.y >= 32110 and position.y <= 32150 and position.z >= 8 and position.z <= 11
end

local function teleportBack(uid)
	local player = Player(uid)
	if player and player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06) == 5 and inWolfDen(player:getPosition()) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Oh no... you were too slow and the wolves caught up with you. You may try again.")
		player:setStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06, 4)
		player:teleportTo({ x = 32109, y = 32131, z = 11 })
	end
end

local warWolfDenBoostTiles = MoveEvent()

function warWolfDenBoostTiles.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local missionState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06)
	if missionState == 4 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "RUUUUUUUUUUUUUUUUUN!")
		player:setStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06, 5)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		-- FAMILY: "hasted by 90 levels" (TibiaWiki EN) = +180 speed. Upstream used the old formula
		-- setFormula(0.3, -24, ...), which this Canary reads as new speed = 0.3 x (base - 40) - 24:
		-- it slowed the player to almost nothing (below zero at low levels), an "invisible wall"
		-- in every direction. A fixed +180 like the haste spells give.
		local conditionHaste = Condition(CONDITION_HASTE)
		conditionHaste:setParameter(CONDITION_PARAM_TICKS, 25000)
		conditionHaste:setParameter(CONDITION_PARAM_SPEED, 180)
		player:addCondition(conditionHaste)
		addEvent(teleportBack, 25000, player:getId())
	end
	return true
end

warWolfDenBoostTiles:aid(50334)
warWolfDenBoostTiles:register()

-- Poacher corpse (gather skinning knife)

local poacherCorpse = Action()

function poacherCorpse.onUse(player, item, frompos, itemEx, topos)
	local missionState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06)
	-- Skip if not was started
	if missionState == -1 then
		return true
	end
	-- FAMILY: the landing square under the den hole (uid 25025) already sets state 3
	-- ("The poacher ... is dead" in the quest log), so upstream's check for state 2
	-- made the body do nothing. Accept 2 and 3; at 3 a lost knife can be taken again (ours).
	if missionState == 2 or missionState == 3 then
		local corpseState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.PoacherCorpse)
		if corpseState == -1 or (missionState == 3 and player:getItemCount(12672) == 0) then
			local reward = Game.createItem(12672, 1)
			local article = reward:getArticle() ~= "" and reward:getArticle() or "a" -- FAMILY: the knife has no article in items.xml
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. article .. " " .. reward:getName() .. ".")
			player:setStorageValue(Storage.Quest.U9_1.TheRookieGuard.PoacherCorpse, 1)
			player:setStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06, 3)
			player:addItemEx(reward, true, CONST_SLOT_WHEREEVER)
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The " .. item:getName() .. " is empty.")
		end
	end
	return true
end

poacherCorpse:uid(40044)
poacherCorpse:register()

-- Skinning knife (skinning dead war wolf)

local skinningKnife = Action()

function skinningKnife.onUse(player, item, frompos, itemEx, topos)
	local missionState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06)
	if missionState == 3 and itemEx.uid == 40045 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You got the war wolf leather - but you hear a scary howl behind you. Time to get out of here - FAST!")
		player:setStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06, 4)
		player:addExperience(50, true)
		player:removeItem(12672, 1)
		player:addItemEx(Game.createItem(12740, 1), true, CONST_SLOT_WHEREEVER)
	end
	return true
end

skinningKnife:id(12672)
skinningKnife:register()

-- War wolf den chest (Small health potion)

local warWolfDenChest = Action()

function warWolfDenChest.onUse(player, item, frompos, itemEx, topos)
	local missionState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.Mission06)
	-- Skip if not was started
	if missionState == -1 then
		return true
	end
	local chestState = player:getStorageValue(Storage.Quest.U9_1.TheRookieGuard.WarWolfDenChest)
	if chestState == -1 then
		local reward = Game.createItem(7876, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. reward:getArticle() .. " " .. reward:getName() .. ".")
		player:setStorageValue(Storage.Quest.U9_1.TheRookieGuard.WarWolfDenChest, 1)
		player:addItemEx(reward, true, CONST_SLOT_WHEREEVER)
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The " .. item:getName() .. " is empty.")
	end
	return true
end

warWolfDenChest:uid(40076)
warWolfDenChest:register()
