-- Gaia Family server: Waterskin of Mead Quest (2026-10-20). Ours, not upstream.
--
-- TibiaWiki ("Waterskin of Mead Quest"): once you may enter the Formorgar
-- Mines (Ice Islands, Formorgar Mines 1: The Mission accepted), a barrel in
-- the mines holds a fur bag with a berserk potion, 82 gold coins and a
-- waterskin of mead. The reward was missing on our map. TibiaWiki shows the
-- barrel only on pictures; the only barrel in the mines is at 32202,31153,8.

local BARREL = { id = 2523, pos = Position(32202, 31153, 8) }
local ACTION_ID = 48711
local STORAGE = Storage.Quest.FamilyWaterskinOfMead.Reward

local startup = GlobalEvent("FamilyWaterskinOfMeadStartup")

function startup.onStartup()
	local tile = Tile(BARREL.pos)
	local barrel = tile and tile:getItemById(BARREL.id)
	if not barrel then
		logger.warn("[Family] Waterskin of Mead: barrel {} not found at {}", BARREL.id, BARREL.pos:toString())
		return true
	end
	barrel:setActionId(ACTION_ID)
	return true
end

startup:register()

local barrelAction = Action()

function barrelAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:getStorageValue(STORAGE) == 1 or player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission09) < 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The barrel is empty.")
		return true
	end

	local bag = Game.createItem(7343, 1) -- fur bag
	bag:addItem(7439, 1) -- berserk potion
	bag:addItem(3031, 82) -- gold coins
	bag:addItem(2901, 16) -- waterskin, filled with mead
	if player:addItemEx(bag) ~= RETURNVALUE_NOERROR then
		bag:remove()
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a fur bag, but you have no room or capacity to take it.")
		return true
	end
	player:setStorageValue(STORAGE, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a fur bag.")
	return true
end

barrelAction:aid(ACTION_ID)
barrelAction:register()
