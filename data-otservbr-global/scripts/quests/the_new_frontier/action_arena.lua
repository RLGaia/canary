local config = {
	bosses = {
		{ "Baron Brute", "The Axeorcist" },
		{ "Menace", "Fatality" },
		{ "Incineron", "Coldheart" },
		{ "Dreadwing", "Doomhowl" },
		{ "Haunter", "The Dreadorian" },
		{ "Rocko", "Tremorak" },
		{ "Tirecz" },
	},

	playerPos = {
		Position(33080, 31014, 2),
		Position(33081, 31014, 2),
	},

	teleportPositions = {
		Position(33059, 31032, 3),
		Position(33057, 31034, 3),
	},

	positions = {
		-- other bosses
		Position(33065, 31035, 3),
		Position(33068, 31034, 3),

		-- first 2 bosses
		Position(33065, 31033, 3),
		Position(33066, 31037, 3),
	},
}
local TheNewFrontier = Storage.Quest.U8_54.TheNewFrontier

-- FAMILY: The New Frontier review (2026-11-09). Upstream locked the arena
-- until Tirecz died: after a defeat (or leaving) it stayed "already in use"
-- until the server restarted, the waves went on spawning, and the 30-minute
-- clean-up of an old fight could throw out the fighters of a newer one. Now
-- every fight has its own number; when no fighter is left inside, the arena
-- is cleaned and opened again, and old timers do nothing.
FamilyNewFrontierArena = FamilyNewFrontierArena or { run = 0 }
local arena = FamilyNewFrontierArena
local arenaCenter = Position(33063, 31034, 3)

local function fightersInside()
	return #Game.getSpectators(arenaCenter, false, true, 10, 10, 10, 10) > 0
end

local function summonBoss(run, name, position)
	if run ~= arena.run then
		return
	end
	Game.createMonster(name, position)
	position:sendMagicEffect(CONST_ME_TELEPORT)
end

local function clearArena()
	local spectators = Game.getSpectators(arenaCenter, false, false, 10, 10, 10, 10)
	local exitPosition = Position(33049, 31017, 2)
	for i = 1, #spectators do
		local spectator = spectators[i]
		if spectator:isPlayer() then
			spectator:teleportTo(exitPosition)
			exitPosition:sendMagicEffect(CONST_ME_TELEPORT)
		else
			spectator:remove()
		end
	end
end

local function endFight(run)
	if run ~= arena.run then
		return
	end
	arena.run = arena.run + 1
	clearArena()
	Game.setStorageValue(TheNewFrontier.Mission09[1], -1)
end

local function watchFight(run)
	if run ~= arena.run then
		return
	end
	if not fightersInside() then
		endFight(run)
		return
	end
	addEvent(watchFight, 5 * 1000, run)
end

local theNewFrontierArena = Action()
function theNewFrontierArena.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: one or two players (upstream: exactly two)
	local fighters = {}
	for a = 1, #config.playerPos do
		local creature = Tile(config.playerPos[a]):getTopCreature()
		if creature and creature:isPlayer() then
			if creature:getStorageValue(TheNewFrontier.Questline) >= 26 then
				return player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already finished this battle.")
			end
			fighters[#fighters + 1] = { player = creature, destination = config.teleportPositions[a] }
		end
	end
	if #fighters == 0 then
		return false
	end

	if Game.getStorageValue(TheNewFrontier.Mission09[1]) == 1 then
		if fightersInside() then
			return player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The arena is already in use.")
		end
		endFight(arena.run) -- FAMILY: nobody left inside, open it again
	end

	Game.setStorageValue(TheNewFrontier.Mission09[1], 1)
	arena.run = arena.run + 1
	local run = arena.run
	addEvent(endFight, 30 * 60 * 1000, run)

	for b = 1, #fighters do
		local creature = fighters[b].player
		creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		creature:teleportTo(fighters[b].destination)
		creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	end

	for i = 1, #config.bosses do
		for j = 1, #config.bosses[i] do
			addEvent(summonBoss, (i - 1) * 90 * 1000, run, config.bosses[i][j], config.positions[j + (i == 1 and 2 or 0)])
		end
	end
	addEvent(watchFight, 10 * 1000, run)
	return true
end

theNewFrontierArena:aid(30003)
theNewFrontierArena:register()
