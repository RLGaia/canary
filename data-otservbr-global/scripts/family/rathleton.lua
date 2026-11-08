-- Gaia Family server: Rathleton Quest, the voting results in the world (2026-11-08).
-- Rules and texts are in lib/others/family_rathleton.lua (switch Family.rathletonRanks).
--
--   * The three temporary shortcuts back to the city centre (TibiaWiki BR Slime Slide):
--     minotaurs (33701,31948,5, Oramond Minotaur Camp +2: not on our map, placed here at
--     startup), fungi (33664,31937,11, the only slide in the Fungi Sewers; BR shows
--     33666,31948,11) and catacombs (33392,32086,10, aid 13407, upstream always open). Only the
--     one the citizens voted for works; the others say so (our text).
--   * The voting results board in the magistrate (21331, 33670,31882,5) prints the results in
--     the server log (TibiaWiki BR/EN The Voting Results).

local R = FamilyRathleton
local CITY = Position(33626, 31897, 6) -- where upstream's catacombs shortcut led
local SLIDE = 21046

local shortcuts = {
	minotaurs = { position = Position(33701, 31948, 5), back = Position(33701, 31949, 5), place = true },
	fungi = { position = Position(33664, 31937, 11), back = Position(33664, 31938, 11) },
	catacombs = { position = Position(33392, 32086, 10), back = Position(33392, 32087, 10), aid = 13407 },
}

local function stepOnShortcut(key, player, position, fromPosition)
	if not R.on() or R.result("shortcut") == key then
		fromPosition:sendMagicEffect(CONST_ME_TELEPORT)
		player:teleportTo(CITY)
		player:say("Slrrp!", TALKTYPE_MONSTER_SAY)
		CITY:sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
	local back = fromPosition
	if back.x == position.x and back.y == position.y and back.z == position.z then
		back = shortcuts[key].back
	end
	player:teleportTo(back, true)
	local text = "This slime slide is dry. " .. R.resultLines()[1]
	player:sendCancelMessage(text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	return true
end

for key, shortcut in pairs(shortcuts) do
	local move = MoveEvent()
	function move.onStepIn(creature, item, position, fromPosition)
		local player = creature:getPlayer()
		if not player then
			return true
		end
		return stepOnShortcut(key, player, position, fromPosition)
	end
	move:type("stepin")
	if shortcut.aid then
		move:aid(shortcut.aid)
	else
		move:position(shortcut.position)
	end
	move:register()
end

-- The minotaur shortcut is missing on our map.
local placeSlide = GlobalEvent("FamilyRathletonSlides")
function placeSlide.onStartup()
	if not R.on() then
		return true
	end
	for key, shortcut in pairs(shortcuts) do
		if shortcut.place then
			local tile = Tile(shortcut.position)
			if tile and not tile:getItemById(SLIDE) then
				Game.createItem(SLIDE, 1, shortcut.position)
			end
		end
	end
	R.refresh()
	logger.info("[Family] Rathleton: shortcut {}, dungeon {}, boss {}, raid {} (next count in {} h)", R.result("shortcut"), R.result("dungeon"), R.result("boss"), R.result("raid"), math.floor(R.secondsToNextPeriod() / 3600))
	return true
end
placeSlide:register()

-- The Voting Results board.
local board = Action()
function board.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not R.on() then
		return false
	end
	for _, line in ipairs(R.resultLines()) do
		player:sendTextMessage(MESSAGE_LOOK, line)
	end
	local days = math.ceil(R.secondsToNextPeriod() / 86400)
	player:sendTextMessage(MESSAGE_LOOK, string.format("The next count of the votes is in %d day%s.", days, days == 1 and "" or "s")) -- ours
	return true
end
board:id(21331, 21332)
board:register()
