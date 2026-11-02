-- Gaia Family server: In Service of Yalahar, the fourth reward chest (2026-11-02, asked by Rodrigo).
-- TibiaWiki EN lists four chests in the Yalaharian treasure room (from the north: armor, leg
-- piece, mask, footwraps). Our map (v3.6.1) has three (unique ids 3088-3090) and upstream's
-- actions_reward.lua already answers unique id 30091 with the Yalahari Footwraps, but no chest
-- had it. At every start the chest is placed south of the mask chest, where the map has a
-- statue, with a sign on the wall like the other three (sign text ours).
-- Switch: Family.inServiceOfYalahar (lib/others/family_in_service_of_yalahar.lua).

local CHEST_POS = Position(32776, 31209, 7)
local SIGN_POS = Position(32775, 31209, 7)
local CHEST_ID, STATUE_ID, SIGN_ID, UID = 2472, 8837, 2024, 30091
local SIGN_TEXT = "The Agility of the Yalahari\nOnly those who fight with fists and spirit can put it to proper use."

local footwrapsChest = GlobalEvent("FamilyYalahariFootwrapsChest")

function footwrapsChest.onStartup()
	if not Family.inServiceOfYalahar then
		return true
	end
	local tile = Tile(CHEST_POS)
	if not tile then
		logger.warn("[Family] In Service of Yalahar: no square for the footwraps chest")
		return true
	end
	if not tile:getItemById(CHEST_ID) then
		local statue = tile:getItemById(STATUE_ID)
		if statue then
			statue:remove()
		end
		local chest = Game.createItem(CHEST_ID, 1, CHEST_POS)
		if chest then
			chest:setAttribute(ITEM_ATTRIBUTE_UNIQUEID, UID)
		end
	end
	local signTile = Tile(SIGN_POS)
	if signTile and not signTile:getItemById(SIGN_ID) then
		local sign = Game.createItem(SIGN_ID, 1, SIGN_POS)
		if sign then
			sign:setAttribute(ITEM_ATTRIBUTE_TEXT, SIGN_TEXT)
		end
	end
	return true
end

footwrapsChest:register()
