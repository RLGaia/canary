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
--   * Bosses (2026-11-09): Flora stands at the voted boss (checked at startup and every 10
--     minutes); Bullwark's lever room (lever 33699,31849,7), his 15-minute fight and the
--     forcefield out of his room (33695,31820,7); Lisa in her lever hall (lever 33550,31905,8;
--     her boss room is not on our map), back to Flora a minute after her death. The Glooth
--     Fairy keeps upstream's lever.

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

-- Bosses (2026-11-09): Flora moves to the voted boss; Bullwark's and Lisa's levers, fights, exits.
local function inBox(box, fn)
	for x = box[1], box[3] do
		for y = box[2], box[4] do
			local tile = Tile(Position(x, y, box[5]))
			local creatures = tile and tile:getCreatures()
			if creatures then
				for _, creature in ipairs(creatures) do
					fn(creature)
				end
			end
		end
	end
end

local function placeFlora()
	if not R.on() then
		return
	end
	local flora = Npc("Flora")
	if not flora then
		return
	end
	local _, boss = R.activeBoss()
	local at = flora:getPosition()
	if at.x ~= boss.flora.x or at.y ~= boss.flora.y or at.z ~= boss.flora.z then
		flora:setMasterPos(boss.flora)
		flora:teleportTo(boss.flora)
		logger.info("[Family] Rathleton: Flora offers {}", boss.name)
	end
end

R.placeFlora = placeFlora

local floraStartup = GlobalEvent("FamilyRathletonFlora")
function floraStartup.onStartup()
	addEvent(placeFlora, 1000)
	return true
end
floraStartup:register()

-- The period may end while the server runs.
local floraCheck = GlobalEvent("FamilyRathletonFloraCheck")
function floraCheck.onThink(interval)
	placeFlora()
	return true
end
floraCheck:interval(10 * 60 * 1000)
floraCheck:register()

local fightCount = 0

local function endFight(key, fight)
	local boss = R.bosses[key]
	if fight ~= fightCount then
		return
	end
	inBox(boss.bossBox, function(creature)
		if creature:isMonster() then
			creature:remove()
		elseif creature:isPlayer() then
			creature:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your time in " .. boss.name .. "'s hideout is over.") -- ours
			creature:teleportTo(boss.out)
			boss.out:sendMagicEffect(CONST_ME_TELEPORT)
		end
	end)
end

local function startFight(key)
	local boss = R.bosses[key]
	fightCount = fightCount + 1
	local fight = fightCount
	inBox(boss.bossBox, function(creature)
		if creature:isMonster() then
			creature:remove()
		elseif creature:isPlayer() and not boss.arena then
			creature:teleportTo(boss.out)
		end
	end)
	if not boss.arena then
		inBox(boss.leverBox, function(creature)
			if creature:isPlayer() then
				creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				creature:teleportTo(boss.arrival)
				boss.arrival:sendMagicEffect(CONST_ME_TELEPORT)
			end
		end)
	end
	local monster = Game.createMonster(boss.name, boss.spawn, false, true)
	if monster and boss.arena then
		monster:registerEvent("FamilyRathletonArenaBoss")
	end
	addEvent(endFight, R.FIGHT_TIME * 1000, key, fight)
end

-- A boss fought in its lever hall (Lisa): everyone goes back to Flora one minute after its death.
local arenaDeath = CreatureEvent("FamilyRathletonArenaBoss")
function arenaDeath.onDeath(creature)
	for key, boss in pairs(R.bosses) do
		if boss.arena and boss.name == creature:getName() then
			local fight = fightCount
			inBox(boss.bossBox, function(player)
				if player:isPlayer() then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Flora will bring you back in one minute.") -- ours
				end
			end)
			addEvent(endFight, 60 * 1000, key, fight)
		end
	end
	return true
end
arenaDeath:register()

R.startBossFight, R.endBossFight = startFight, function(key)
	endFight(key, fightCount)
end

for key, boss in pairs(R.bosses) do
	if not boss.upstream then
		local lever = Action()
		function lever.onUse(player, item, fromPosition, target, toPosition, isHotkey)
			if not R.on() then
				return false
			end
			local wait = R.leverWait(key)
			if wait > 0 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You need to wait %d minute%s to use again.", math.ceil(wait / 60), wait > 60 and "s" or ""))
				return true
			end
			R.setLeverWait(key, R.leverRest(key))
			player:say("Everyone in this place will be teleported into " .. boss.name .. "'s hideout in one minute. No way back!!!", TALKTYPE_MONSTER_SAY)
			item:transform(8914)
			local where = Position(boss.lever.x, boss.lever.y, boss.lever.z)
			addEvent(function()
				local tile = Tile(where)
				local pulled = tile and tile:getItemById(8914)
				if pulled then
					pulled:transform(8913)
				end
			end, R.leverRest(key) * 1000)
			addEvent(startFight, 60 * 1000, key)
			return true
		end
		lever:position(boss.lever)
		lever:register()

		if boss.exit then
		local exit = MoveEvent()
		function exit.onStepIn(creature, item, position, fromPosition)
			local player = creature:getPlayer()
			if not player or not R.on() then
				return true
			end
			player:teleportTo(boss.out)
			boss.out:sendMagicEffect(CONST_ME_TELEPORT)
			return true
		end
		exit:type("stepin")
		exit:position(boss.exit)
		exit:register()
		end
	end
end
