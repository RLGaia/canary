-- Gaia Family server: daily reward training weapons can be thrown away (2026-10-22).
--
-- Ours, not upstream. Asked by Rodrigo: the training weapons from the daily
-- reward (day 6) pile up and could not be thrown in a dustbin.
--
-- Why: the daily reward marks every item it delivers as a Store item
-- (ITEM_ATTRIBUTE_STORE). The C++ (Game::checkMoveItemToCylinder, pinned
-- binary) lets a Store item leave the backpack only onto a tile of a house the
-- player owns, so it can never reach a dustbin or the ground. The check runs
-- before any Lua move event, so the mark itself has to go.
--
-- What: the eight training weapons (50 charges; exercise weapons from the
-- Store or NPCs are not touched) lose the Store mark when they are claimed,
-- at login (inventory, backpacks, Store inbox) and when moved (for example
-- out of the depot). They then behave like any other item: they can be thrown
-- away, dropped, or put in the depot. Trading them to another player stays
-- blocked for the ids upstream lists in data/events/scripts/player.lua.
--
-- Training and exercise weapons train the same (7 skill tries or 600 mana per
-- hit; 1,200 mana since 2026-10-23, magic_training.lua; times the dummy's rate), and here they never lose charges
-- (Family.infiniteTrainingWeapons), so one per skill is enough.
--
-- Switch: Family.disposableTrainingWeapons (false = upstream Store items).

Family = Family or {}
Family.disposableTrainingWeapons = true

Family.trainingWeaponIds = {
	[28540] = true, -- training sword
	[28541] = true, -- training axe
	[28542] = true, -- training club
	[28543] = true, -- training bow
	[28544] = true, -- training rod
	[28545] = true, -- training wand
	[44064] = true, -- training shield
	[50292] = true, -- training wraps
}

local function clearItem(item)
	if item and Family.trainingWeaponIds[item:getId()] and item:hasAttribute(ITEM_ATTRIBUTE_STORE) then
		item:removeAttribute(ITEM_ATTRIBUTE_STORE)
		return 1
	end
	return 0
end

local function clearContainer(container)
	local n = 0
	if container and container:isContainer() then
		for _, item in ipairs(container:getItems(true)) do
			n = n + clearItem(item)
		end
	end
	return n
end

-- Returns how many training weapons lost the Store mark.
function Family.clearTrainingWeaponStoreMark(player)
	if not Family.disposableTrainingWeapons or not player then
		return 0
	end
	local n = 0
	for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
		local item = player:getSlotItem(slot)
		if item then
			n = n + clearItem(item) + clearContainer(item)
		end
	end
	n = n + clearContainer(player:getStoreInbox())
	return n
end

local login = CreatureEvent("FamilyTrainingWeaponsLogin")

function login.onLogin(player)
	Family.clearTrainingWeaponStoreMark(player)
	return true
end

login:register()

local moved = EventCallback("FamilyTrainingWeaponsMoved")

function moved.playerOnItemMoved(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if Family.disposableTrainingWeapons then
		clearItem(item)
		if item and item:isContainer() then
			clearContainer(item)
		end
	end
end

moved:register()

local startup = GlobalEvent("FamilyTrainingWeaponsStartup")

function startup.onStartup()
	if not Family.originalSelectDailyRewardForTraining then
		Family.originalSelectDailyRewardForTraining = Player.selectDailyReward
		Player.selectDailyReward = function(self, msg)
			local result = Family.originalSelectDailyRewardForTraining(self, msg)
			Family.clearTrainingWeaponStoreMark(self)
			return result
		end
	end
	logger.info("[Family] disposable daily reward training weapons: " .. tostring(Family.disposableTrainingWeapons))
	return true
end

startup:register()
