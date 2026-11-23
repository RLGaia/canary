-- FAMILY (2026-11-22, Threatened Dreams review): the bush stands where TibiaWiki BR shows it
-- (33496,32197; EN 33495,32197; upstream 33497,32196), it is also there after a restart at night, and a
-- player gets one herb per night (BR: "apenas uma vez por ciclo"); upstream's wait was
-- os.time() + 60 * 30 * 1000 seconds, about 20 days. Family.threatenedDreams = false: upstream values.
local family = FamilyThreatenedDreams and FamilyThreatenedDreams.enabled()

local config = {
	bushId = 25783,
	createItem = LIGHT_STATE_NIGHT,
	removeItem = LIGHT_STATE_SUNRISE,
	pos = family and Position(33496, 32197, 7) or Position(33497, 32196, 7),
	herbId = 5953,
	herbWeight = 1,
	storage = Storage.Quest.U11_40.ThreatenedDreams.Mission03.RavenHerbTimer,
	wait = family and 30 * 60 or 60 * 30 * 1000, -- a Tibian night lasts 30 minutes
}

local function createBush()
	local pos = config.pos
	local tile = Tile(pos)
	if tile and not tile:getItemById(config.bushId) then
		if Game.createItem(config.bushId, 1, pos) then
			pos:sendMagicEffect(CONST_ME_BIGPLANTS)
		end
	end
end

local createRavenHerb = GlobalEvent("createRavenHerb")

function createRavenHerb.onPeriodChange(period, light)
	local pos = config.pos
	if config.createItem == period then
		createBush()
	elseif config.removeItem == period then
		local target = Tile(pos) and Tile(pos):getItemById(config.bushId)
		if target then
			pos:removeItem(config.bushId, CONST_ME_BIGPLANTS)
		end
	end
	return true
end

createRavenHerb:register()

if family then
	local ravenHerbStartup = GlobalEvent("FamilyRavenHerbStartup")
	function ravenHerbStartup.onStartup()
		if getTibiaTimerDayOrNight() == "night" then
			createBush()
		end
		return true
	end
	ravenHerbStartup:register()
end

local ravenHerb = Action()

function ravenHerb.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local message = "You have found a " .. getItemName(config.herbId) .. "."
	local backpack = player:getSlotItem(CONST_SLOT_BACKPACK)

	if not backpack or backpack:getEmptySlots(true) < 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message .. " But you have no room to take it.")
		return true
	end

	if (player:getFreeCapacity() / 100) < config.herbWeight then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message .. ". Weighing " .. config.herbWeight .. " oz, it is too heavy for you to carry.")
		return true
	end

	if player:getStorageValue(config.storage) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The raven herb cannot be collected right now.")
		return true
	end

	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
	player:setStorageValue(config.storage, os.time() + config.wait)
	player:addItem(config.herbId, 1)
	return true
end

ravenHerb:id(25783)
ravenHerb:register()
