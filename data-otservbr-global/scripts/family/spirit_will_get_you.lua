-- Gaia Family server: The Spirit Will Get You Quest (2026-10-20). Ours, not
-- upstream.
--
-- TibiaWiki ("The Spirit Will Get You Quest"): the Cranky Lizard Crone in the
-- Spirittrails (north of Zao) wants three pages of a faded last will, hidden
-- in the ruins around her house. Returning them gives 10,050 experience, and
-- only then does she make the Wayfarer addons (old cape, sedge hat). Upstream
-- had only the addon trade. The pages lie at TibiaWiki's three spots; there is
-- no box or book there on our map, so they are found in the wagon or the
-- stones on those squares. Dialogue in npc/cranky_lizard_crone.lua.

FamilySpirit = {
	page = 11544, -- faded last will
	exp = 10050,
	spots = {
		{ id = 10051, pos = Position(33177, 31020, 5) }, -- wagon (TibiaWiki: a box)
		{ id = 10050, pos = Position(33162, 31056, 4) }, -- wagon (TibiaWiki: a book)
		{ id = 1858, pos = Position(33165, 31056, 6) }, -- stones
	},
	actionId = 48713,
}

local F = FamilySpirit
local S = Storage.Quest.FamilySpiritWillGetYou

function F.state(player)
	return player:getStorageValue(S.Mission)
end

function F.start(player)
	player:setStorageValue(S.Mission, 1)
	if player:getStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart) < 1 then
		player:setStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart, 1) -- shows "Tibia Tales" in the quest log
	end
end

function F.pagesFound(player)
	local found = 0
	for i = 1, #S.Pages do
		if player:getStorageValue(S.Pages[i]) == 1 then
			found = found + 1
		end
	end
	return found
end

-- Takes the three pages and finishes the mission; false if they are missing.
function F.finish(player)
	if player:getItemCount(F.page) < 3 or not player:removeItem(F.page, 3) then
		return false
	end
	player:addExperience(F.exp, true)
	player:setStorageValue(S.Mission, 2)
	return true
end

local startup = GlobalEvent("FamilySpiritWillGetYouStartup")

function startup.onStartup()
	for i, spot in ipairs(F.spots) do
		local tile = Tile(spot.pos)
		local item = tile and tile:getItemById(spot.id)
		if item then
			item:setActionId(F.actionId + i - 1)
		else
			logger.warn("[Family] The Spirit Will Get You: item {} not found at {}", spot.id, spot.pos:toString())
		end
	end
	return true
end

startup:register()

local search = Action()

function search.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local index = item:getActionId() - F.actionId + 1
	if F.state(player) ~= 1 or not S.Pages[index] then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You find nothing special.")
		return true
	end
	-- A page already found is given again only if it was lost.
	if player:getStorageValue(S.Pages[index]) == 1 and player:getItemCount(F.page) >= F.pagesFound(player) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already searched here.")
		return true
	end
	if not player:addItem(F.page, 1) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found a page of a last will, but you cannot carry it.")
		return true
	end
	player:setStorageValue(S.Pages[index], 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You found a page of a faded last will (%d of 3).", F.pagesFound(player)))
	return true
end

for i = 1, #F.spots do
	search:aid(F.actionId + i - 1)
end
search:register()
