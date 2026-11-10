-- Gaia Family server: Rascacoon (A Pirate's Tail Quest, part 2, 2026-11-10). Ours, not upstream.
-- Rules and texts in lib/others/family_pirates_tail.lua; Tik'hi Tak'he and Om'Wake Naha in npc/.
--
-- Memory test (TibiaWiki BR quest page; EN spoiler and its Memory-shells picture): the sand room inside
-- the mountain (x 33742-33761, y 31294-31311). Eight fixed 3x3 patterns of spiral shells, pieces of a
-- shell and starfish lie around a walled island; four of them are on our map, the other four come from
-- the EN picture (checked: the four on the map match it). A few seconds after a player with Tik'hi's
-- mission enters, the room is locked (the water flows back into the entrance at x 33761-33763, which is
-- how our map has it) and ten rounds start: a pattern shows on the island, disappears, and the players
-- must stand at the same pattern (within 2 squares of its middle) when the round ends; right = 5 trust
-- points and the next round, wrong = out of the room (BR). Every 2 hours per character (BR/EN). The
-- shells are put back at every round (BR: the room's floor is reset). Timing ours: 5 s before the
-- start, the pattern 5 s on the island, 10 s to find it.
--
-- Ship teleport (33800,31358,7, EN/BR): only for trusted friends (Rascacoon state 2); it turns them into a
-- pirat for 15 minutes (BR/EN). The map's teleport goes nowhere now; the move event does the work.
-- Switch: Family.piratesTail.

local PT = FamilyPiratesTail
if not PT then
	return
end
local S = Storage.Quest.U12_60.APiratesTail

local M = {}
PT.memory = M

M.Z = 7
M.ROOM = { x1 = 33742, y1 = 31294, x2 = 33761, y2 = 31311 }
M.EXIT = Position(33765, 31297, 7)
M.LOCK = { x1 = 33761, y1 = 31295, x2 = 33763, y2 = 31299 } -- the entrance
M.LOCK_ITEMS = {}
for id = 35402, 35420 do
	M.LOCK_ITEMS[id] = true
end
M.WATER_GROUND = { [35698] = true, [35699] = true, [35700] = true, [35701] = true, [35702] = true, [35703] = true }
M.DRY_GROUND = 231 -- sand
M.SHELL = { C = 5680, W = 5682, S = 5416 } -- spiral shell, piece of a shell, starfish
M.SPARKLE = 1722
M.CENTER = { 33752, 31302 }
M.PATTERNS = {
	{ 33749, 31296, { "CWS", "SCW", "WSC" } },
	{ 33755, 31296, { "WSC", "SCW", "CWS" } },
	{ 33744, 31299, { "WCS", "CSW", "SWC" } },
	{ 33760, 31299, { "CWS", "WSC", "SCW" } },
	{ 33744, 31305, { "CSW", "WCS", "SWC" } },
	{ 33760, 31305, { "SWC", "CSW", "WCS" } },
	{ 33749, 31309, { "SCW", "WSC", "CWS" } },
	{ 33755, 31309, { "SWC", "WCS", "CSW" } },
}
M.ROUNDS = 10
M.POINTS = 5
M.COOLDOWN = 2 * 60 * 60
M.WAIT, M.SHOW, M.ANSWER, M.PAUSE = 5, 5, 10, 2
M.NEAR = 2

M.locked = false
M.saved = nil -- the entrance as the map has it
M.run = nil -- { participants = { [id] = true }, round, target, stage, timer }

local function enabled()
	return PT.enabled()
end

local function inRoom(pos)
	return pos.z == M.Z and pos.x >= M.ROOM.x1 and pos.x <= M.ROOM.x2 and pos.y >= M.ROOM.y1 and pos.y <= M.ROOM.y2
end
M.inRoom = inRoom

local function playersInRoom()
	local list = {}
	for _, player in ipairs(Game.getPlayers()) do
		if inRoom(player:getPosition()) then
			list[#list + 1] = player
		end
	end
	return list
end

-- The entrance: record it as the map has it (locked), then open it.
function M.saveEntrance()
	M.saved = {}
	for x = M.LOCK.x1, M.LOCK.x2 do
		for y = M.LOCK.y1, M.LOCK.y2 do
			local pos = Position(x, y, M.Z)
			local tile = Tile(pos)
			if tile then
				local entry = { pos = pos, items = {} }
				local ground = tile:getGround()
				if ground and M.WATER_GROUND[ground:getId()] and not tile:hasProperty(CONST_PROP_BLOCKSOLID) then
					entry.ground = ground:getId()
				end
				for _, item in ipairs(tile:getItems() or {}) do
					if M.LOCK_ITEMS[item:getId()] then
						entry.items[#entry.items + 1] = item:getId()
					end
				end
				if entry.ground or #entry.items > 0 then
					M.saved[#M.saved + 1] = entry
				end
			end
		end
	end
	M.locked = true
end

function M.unlock()
	for _, entry in ipairs(M.saved or {}) do
		local tile = Tile(entry.pos)
		if tile then
			for _, id in ipairs(entry.items) do
				local item = tile:getItemById(id)
				if item then
					item:remove()
				end
			end
			local ground = tile:getGround()
			if entry.ground and ground and ground:getId() == entry.ground then
				ground:transform(M.DRY_GROUND)
			end
		end
	end
	M.locked = false
end

function M.lock()
	for _, entry in ipairs(M.saved or {}) do
		local tile = Tile(entry.pos)
		if tile then
			for _, creature in ipairs(tile:getCreatures() or {}) do
				creature:teleportTo(M.EXIT)
			end
			local ground = tile:getGround()
			if entry.ground and ground and ground:getId() == M.DRY_GROUND then
				ground:transform(entry.ground)
			end
			for _, id in ipairs(entry.items) do
				if not tile:getItemById(id) then
					Game.createItem(id, 1, entry.pos)
				end
			end
			entry.pos:sendMagicEffect(CONST_ME_WATERSPLASH)
		end
	end
	M.locked = true
end

-- Shells ----------------------------------------------------------------------------------------------

local function clearShells(x1, y1, x2, y2)
	for x = x1, x2 do
		for y = y1, y2 do
			local tile = Tile(Position(x, y, M.Z))
			if tile then
				for _, item in ipairs(tile:getItems() or {}) do
					local id = item:getId()
					if id == M.SHELL.C or id == M.SHELL.W or id == M.SHELL.S or id == M.SPARKLE or id == 1723 then
						item:remove()
					end
				end
			end
		end
	end
end

local function placePattern(cx, cy, rows)
	for dy = -1, 1 do
		local row = rows[dy + 2]
		for dx = -1, 1 do
			local pos = Position(cx + dx, cy + dy, M.Z)
			Game.createItem(M.SPARKLE, 1, pos)
			Game.createItem(M.SHELL[row:sub(dx + 2, dx + 2)], 1, pos)
		end
	end
end

-- The eight patterns around the island, as they always are (the floor reset).
function M.resetFloor()
	clearShells(M.ROOM.x1, M.ROOM.y1, M.ROOM.x2, M.ROOM.y2)
	for _, p in ipairs(M.PATTERNS) do
		placePattern(p[1], p[2], p[3])
	end
end

function M.showCenter(index)
	clearShells(M.CENTER[1] - 1, M.CENTER[2] - 1, M.CENTER[1] + 1, M.CENTER[2] + 1)
	if index then
		placePattern(M.CENTER[1], M.CENTER[2], M.PATTERNS[index][3])
		Position(M.CENTER[1], M.CENTER[2], M.Z):sendMagicEffect(CONST_ME_LOSEENERGY)
	end
end

-- The pattern a player stands at (nil when not near one).
function M.patternAt(pos)
	if not inRoom(pos) then
		return nil
	end
	for i, p in ipairs(M.PATTERNS) do
		if math.max(math.abs(pos.x - p[1]), math.abs(pos.y - p[2])) <= M.NEAR then
			return i
		end
	end
	return nil
end

-- The test ---------------------------------------------------------------------------------------------

function M.eligible(player)
	return PT.rascacoon(player) >= 1 and player:getStorageValue(S.MemoryTime) <= os.time()
end

local function tell(run, text)
	for id in pairs(run.participants) do
		local player = Player(id)
		if player then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
		end
	end
end

local function sendOut(player, text)
	player:teleportTo(M.EXIT)
	M.EXIT:sendMagicEffect(CONST_ME_WATERSPLASH)
	if text then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	end
end

function M.finish()
	local run = M.run
	M.run = nil
	M.showCenter(nil)
	M.resetFloor()
	if run then
		for id in pairs(run.participants) do
			local player = Player(id)
			if player and inRoom(player:getPosition()) then
				sendOut(player, nil)
			end
		end
	end
	M.unlock()
end

-- Drop participants who left the room (logout, death); true when someone is still in.
local function stillIn(run)
	local any = false
	for id in pairs(run.participants) do
		local player = Player(id)
		if player and inRoom(player:getPosition()) then
			any = true
		else
			run.participants[id] = nil
		end
	end
	return any
end

function M.step(now)
	local run = M.run
	if not run then
		return
	end
	if not stillIn(run) and run.stage ~= "wait" then
		M.finish()
		return
	end
	if now < run.timer then
		return
	end
	if run.stage == "wait" then
		-- the room locks; who may not take the test now has to go
		for _, player in ipairs(playersInRoom()) do
			if M.eligible(player) then
				run.participants[player:getId()] = true
				player:setStorageValue(S.MemoryTime, now + M.COOLDOWN)
			else
				sendOut(player, "The room is closed while the memory test is running.") -- ours
			end
		end
		if not next(run.participants) then
			M.run = nil
			return
		end
		M.lock()
		run.round = 0
		run.stage = "pause"
		run.timer = now
	elseif run.stage == "pause" then
		run.round = run.round + 1
		M.resetFloor()
		run.target = math.random(#M.PATTERNS)
		M.showCenter(run.target)
		tell(run, string.format("Round %d of %d: remember this pattern!", run.round, M.ROUNDS)) -- ours
		run.stage = "show"
		run.timer = now + M.SHOW
	elseif run.stage == "show" then
		M.showCenter(nil)
		tell(run, string.format("Find the same pattern around the island! %d seconds.", M.ANSWER)) -- ours
		run.stage = "answer"
		run.timer = now + M.ANSWER
	elseif run.stage == "answer" then
		for id in pairs(run.participants) do
			local player = Player(id)
			if player then
				if M.patternAt(player:getPosition()) == run.target then
					PT.addTrust(player, M.POINTS)
					player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Right! You earned %d trust points (%d of %d rounds).", M.POINTS, run.round, M.ROUNDS)) -- ours
				else
					run.participants[id] = nil
					sendOut(player, "Wrong! You have to leave the room.") -- ours
				end
			end
		end
		if run.round >= M.ROUNDS then
			tell(run, "You remembered all ten patterns! Come back in two hours.") -- ours
			M.finish()
		elseif not next(run.participants) then
			M.finish()
		else
			run.stage = "pause"
			run.timer = now + M.PAUSE
		end
	end
end

M.notified = {}
function M.tick(now)
	now = now or os.time()
	if M.run then
		M.step(now)
		return
	end
	local starters = 0
	for _, player in ipairs(playersInRoom()) do
		if M.eligible(player) then
			starters = starters + 1
		elseif (M.notified[player:getId()] or 0) < now then
			M.notified[player:getId()] = now + 60
			if PT.rascacoon(player) < 1 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nothing happens. Maybe the Rascoohans know what this place is for.") -- ours
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You took the memory test not long ago. Come back later.") -- ours
			end
		end
	end
	if starters > 0 then
		M.run = { participants = {}, stage = "wait", timer = now + M.WAIT }
		for _, player in ipairs(playersInRoom()) do
			if M.eligible(player) then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("The memory test begins in %d seconds. Watch the island!", M.WAIT)) -- ours
			end
		end
	end
end

local clock = GlobalEvent("FamilyMemoryTest")
function clock.onThink(interval)
	if enabled() and M.saved then
		M.tick()
	end
	return true
end
clock:interval(1000)
clock:register()

-- Ship teleport ---------------------------------------------------------------------------------------

M.SHIP_TELEPORT = Position(33800, 31358, 7)
M.SHIP_DESTINATION = Position(33802, 31384, 7)
M.DISGUISE = "Pirat Cutthroat"
M.DISGUISE_TIME = 15 * 60 * 1000

local function shipStep(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not enabled() then
		return true
	end
	if PT.rascacoon(player) < 2 then
		player:teleportTo(fromPosition, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Only pirats may pass here. Tik'hi Tak'he might know a way.") -- ours
		return true
	end
	player:teleportTo(M.SHIP_DESTINATION)
	player:setMonsterOutfit(M.DISGUISE, M.DISGUISE_TIME)
	M.SHIP_DESTINATION:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end
local shipTeleport = MoveEvent()
shipTeleport.onStepIn = shipStep
M.shipStep = shipStep
shipTeleport:type("stepin")
shipTeleport:position(M.SHIP_TELEPORT)
shipTeleport:register()

local startup = GlobalEvent("FamilyRascacoon")
function startup.onStartup()
	if not enabled() then
		return true
	end
	M.saveEntrance()
	M.unlock()
	M.resetFloor()
	local tile = Tile(M.SHIP_TELEPORT)
	local teleport = tile and tile:getItemById(34111)
	if teleport and teleport.setDestination then
		teleport:setDestination(Position(0, 0, 0))
	end
	logger.info(string.format("[Family] Rascacoon: memory test entrance %d squares, 8 patterns, ship teleport %s", #M.saved, teleport and "on" or "MISSING"))
	return true
end
startup:register()
