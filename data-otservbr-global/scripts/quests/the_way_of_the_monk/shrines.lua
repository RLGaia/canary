-- FAMILY: Empathy and Power are on floors 13 and 15 (were 1: their shrines could
-- not be used), as upstream #4063. "hint" (ours) says where the shrine is; Enpa-Deia
-- Pema and Enpa Rudra use it for the next step of the pilgrimage.
TheWayOfTheMonkShrines = {
	{ pos = Position(32454, 32292, 7), name = "Guidance", level = 6, rewards = { item = 50267 }, hint = "east of Thais, close to the crystal sphere that brings you to the Blue Valley" },
	{ pos = Position(32323, 32380, 6), name = "Tranquility", level = 20, rewards = { item = 50271, exp = 2500 }, hint = "to the south of Thais, away from the city, high up where only levitating (or a few parcels to climb on) gets you" },
	{ pos = Position(32410, 31272, 3), name = "Respect", level = 30, rewards = { exp = 5000, spell = "Mystic Repulse", attack = true }, hint = "to the island of Tyrsung in the far north, high up its mountain; Buddel of Svargrond sails there" },
	{ pos = Position(32610, 31634, 7), name = "Legacy", level = 40, rewards = { item = 50269, exp = 10000, attack = true }, hint = "to the forests north-east of the Elvenbane castle, near Ab'Dendriel" },
	{ pos = Position(32532, 31569, 13), name = "Empathy", level = 50, rewards = { item = 50273, exp = 15000, attack = true }, hint = "deep down into the Maze of the Lost Souls, the way to Demona north of Carlin" },
	{ pos = Position(32966, 32649, 8), name = "Harmony", level = 70, rewards = { item = 50274, exp = 30000, attack = true }, hint = "behind the Kha'zeel waterfalls in the jungle of Tiquanda, the way of the waterfall quest of Port Hope" },
	{ pos = Position(32890, 32352, 15), name = "Power", level = 100, rewards = { item = 50272, exp = 60000, attack = true }, hint = "down into the Pits of Inferno near Venore, as far as the lever rooms" },
	{ pos = Position(33369, 31155, 8), name = "Knowledge", level = 110, rewards = { exp = 75000, spell = "Forceful Uppercut" }, hint = "to the Black Serpent dungeon in Zao, which opens only to those who delivered eight tomes of knowledge" },
	{ pos = Position(32778, 31525, 9), name = "Serenity", level = 150, rewards = { item = 50268, exp = 150000 }, hint = "below the forests near Ab'Dendriel, into the trial grounds of the Barkless cult" },
	{ pos = Position(33842, 31622, 3), name = "Eternity", level = 275, rewards = { exp = 500000, spell = "Focus Harmony" }, hint = "high up into the mountains of Kilmaresh" },
}

local function parseRewards(player, rewardsTable)
	for type, reward in pairs(rewardsTable) do
		if type == "item" then
			player:addItem(reward)
		elseif type == "exp" then
			player:addExperience(reward, true)
		elseif type == "spell" then
			player:learnSpell(reward)
		elseif type == "attack" then
			local currentAttackBonus = player:kv():get("monk-basic-atk-bonus") or 0
			player:kv():set("monk-basic-atk-bonus", currentAttackBonus + 1)
		end
	end
	return true
end

local Shrines = Action()
function Shrines.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for index, shrine in ipairs(TheWayOfTheMonkShrines) do
		if fromPosition == shrine.pos then
			fromPosition:sendMagicEffect(37)
			item:transform(50244)

			addEvent(function()
				item:transform(50242)
			end, 30 * 1000)

			local shrinesStorage = Storage.Quest.U14_15.TheWayOfTheMonk.ShrinesCount
			if player:getStorageValue(shrinesStorage) ~= index or player:getLevel() < shrine.level then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The Three-Fold Path dictates the order of the shrines to visit and when to do this. This is either not the time for this shrine or you are not yet experienced enough to prepare yourself for the gifts of the Merudri.")
				return false
			end

			if player:getVocation():getId() >= 9 then
				parseRewards(player, shrine.rewards)
			else
				local exp = shrine.rewards.exp or 300
				player:addExperience(exp, true)
			end

			player:setStorageValue(shrinesStorage, index + 1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You honour the ways of the Merudri at the shrine of %s.", shrine.name))
			-- FAMILY: the last shrine ends the Three-Fold Path (quest log) and gives
			-- "Hope of the Merudri", as in Tibia (the title "Pensive Wanderer" needs a
			-- newer server binary).
			if index == #TheWayOfTheMonkShrines then
				player:setStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.Missions.TreeFoldPath, 3)
				player:addAchievement("Hope of the Merudri")
			end
		end
	end
	return true
end

for _, shrine in ipairs(TheWayOfTheMonkShrines) do
	Shrines:position(shrine.pos)
end
Shrines:register()
