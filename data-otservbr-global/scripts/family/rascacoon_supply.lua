-- Gaia Family server: Om'Wake Naha's supply mission (A Pirate's Tail Quest, part 2b, 2026-11-10). Ours,
-- not upstream. Sources: TibiaWiki BR quest page, Om'Wake Naha, Spy Rat, Mintwarella Cheese and Cheese
-- Thief pages (from Rodrigo), TibiaWiki EN spoiler and creature pages.
--
-- The lever room (lever 33956,31304,15, five squares 33957-33961,31304) takes up to five players who
-- helped Tik'hi Tak'he into the cheese cellar (x 33952-33978, y 31268-31294, z15). The chest by the
-- entrance (33977,31289) gives a Rascoohan Rat Revealer (BR). The team's score starts at 15 (BR) and
-- shows under every name. Mintwarella Cheeses stand in the cellar; pushed onto the open trapdoor in the
-- middle (33964,31288) they are saved (+3, ours); spy rats come out of the eight holes, walk to a cheese
-- and eat it (a cheese eaten = -5, BR); a spy rat cannot be hurt, but the revealer turns it into a Cheese
-- Thief that can be killed (BR/EN); a rat lured over a hole is sent to another hole (BR). After about
-- three minutes with the score above 5 the mission succeeds: 200 trust points, again after 20 hours
-- (BR/EN); at 0 the team is sent out (BR). Ours: 6 cheeses at a time, a new spy rat every 10 s up to 4,
-- a bite every second for 30 of the cheese's 300 health, the rats' speed (a step a second).
-- Switch: Family.piratesTail.

local PT = FamilyPiratesTail
if not PT then
	return
end
local S = Storage.Quest.U12_60.APiratesTail

local C = {}
PT.supply = C

C.Z = 15
C.BOX = { x1 = 33952, y1 = 31268, x2 = 33978, y2 = 31294 }
C.LEVER = Position(33956, 31304, 15)
C.SQUARES = {}
for x = 33957, 33961 do
	C.SQUARES[#C.SQUARES + 1] = Position(x, 31304, 15)
end
C.START = Position(33976, 31290, 15)
C.EXIT = Position(33741, 31333, 7)
C.CHEST = Position(33977, 31289, 15)
C.TRAPDOOR = Position(33964, 31288, 15)
C.HOLE = 35216
C.REVEALER = 35226
C.START_SCORE, C.SAVED, C.EATEN, C.NEEDED = 15, 3, 5, 5
C.TIME = 3 * 60
C.CHEESES, C.RATS, C.RAT_EVERY = 6, 4, 10
C.BITE = 30
C.TRUST = 200
C.COOLDOWN = 20 * 60 * 60
C.ICON = "family-supply"

C.run = nil -- { players = {[id]=true}, score, ends, cheeses = {[id]=true}, rats = {[id]=true}, nextRat }
C.holes = {}

local function enabled()
	return PT.enabled()
end

local function inCellar(pos)
	return pos.z == C.Z and pos.x >= C.BOX.x1 and pos.x <= C.BOX.x2 and pos.y >= C.BOX.y1 and pos.y <= C.BOX.y2
end
C.inCellar = inCellar

local function freeSquare(pos)
	local tile = Tile(pos)
	if not tile or not tile:getGround() or tile:getTopCreature() then
		return false
	end
	local g = tile:getGround():getId()
	if g == C.HOLE or pos == C.TRAPDOOR then
		return false
	end
	return not tile:hasProperty(CONST_PROP_BLOCKSOLID) and not tile:hasProperty(CONST_PROP_BLOCKPATH)
end

function C.findHoles()
	C.holes = {}
	for x = C.BOX.x1, C.BOX.x2 do
		for y = C.BOX.y1, C.BOX.y2 do
			local tile = Tile(Position(x, y, C.Z))
			local g = tile and tile:getGround()
			if g and g:getId() == C.HOLE then
				C.holes[#C.holes + 1] = Position(x, y, C.Z)
			end
		end
	end
	return #C.holes
end

local function showScore(run)
	for id in pairs(run.players) do
		local player = Player(id)
		if player then
			player:setIcon(C.ICON, CreatureIconCategory_Quests, CreatureIconQuests_GreenShield, math.max(0, run.score))
		end
	end
end

local function tell(run, text)
	for id in pairs(run.players) do
		local player = Player(id)
		if player then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
		end
	end
end

local function spawn(run, name, pos)
	local monster = Game.createMonster(name, pos, false, true)
	if monster then
		if name == "Mintwarella Cheese" then
			run.cheeses[monster:getId()] = true
		else
			run.rats[monster:getId()] = true
		end
	end
	return monster
end

local function randomFree(minFromTrapdoor)
	for _ = 1, 60 do
		local pos = Position(math.random(C.BOX.x1 + 1, C.BOX.x2 - 1), math.random(C.BOX.y1 + 1, C.BOX.y2 - 1), C.Z)
		if freeSquare(pos) and pos:getDistance(C.TRAPDOOR) >= (minFromTrapdoor or 0) then
			return pos
		end
	end
	return nil
end

local function count(set)
	local n = 0
	for id in pairs(set) do
		if Creature(id) then
			n = n + 1
		else
			set[id] = nil
		end
	end
	return n
end

local function clearRun(run)
	for _, set in ipairs({ run.cheeses, run.rats, run.thieves }) do
		for id in pairs(set) do
			local creature = Creature(id)
			if creature then
				creature:remove()
			end
		end
	end
end

function C.finish(success)
	local run = C.run
	if not run then
		return
	end
	C.run = nil
	clearRun(run)
	for id in pairs(run.players) do
		local player = Player(id)
		if player then
			player:removeIcon(C.ICON)
			if player:getItemCount(C.REVEALER) > 0 then
				player:removeItem(C.REVEALER, player:getItemCount(C.REVEALER))
			end
			if success then
				PT.addTrust(player, C.TRUST)
				player:setStorageValue(S.SupplyTime, os.time() + C.COOLDOWN)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("The cheese is safe! Om'Wake Naha's colony thanks you: %d trust points.", C.TRUST)) -- ours
			else
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The rats devoured too much cheese. You have to leave the cellar.") -- ours
			end
			if inCellar(player:getPosition()) then
				player:teleportTo(C.EXIT)
				C.EXIT:sendMagicEffect(CONST_ME_TELEPORT)
			end
		end
	end
end

function C.changeScore(delta)
	local run = C.run
	if not run then
		return
	end
	run.score = run.score + delta
	showScore(run)
	if run.score <= 0 then
		C.finish(false)
	end
end

-- The lever ----------------------------------------------------------------------------------------------

function C.eligible(player)
	return PT.rascacoon(player) >= 1 and player:getStorageValue(S.SupplyTime) <= os.time()
end

function C.start(players, now)
	now = now or os.time()
	local run = { players = {}, score = C.START_SCORE, ends = now + C.TIME, cheeses = {}, rats = {}, thieves = {}, nextRat = now + 3 }
	C.run = run
	for _, player in ipairs(players) do
		run.players[player:getId()] = true
		player:teleportTo(C.START)
	end
	C.START:sendMagicEffect(CONST_ME_TELEPORT)
	if #C.holes == 0 then
		C.findHoles()
	end
	for _ = 1, C.CHEESES do
		local pos = randomFree(3)
		if pos then
			spawn(run, "Mintwarella Cheese", pos)
		end
	end
	showScore(run)
	tell(run, "Push the cheese into the open trapdoor and keep the rats away from it! Take a rat revealer from the chest.") -- ours
	return run
end

local function useLever(player, item, fromPosition, target, toPosition, isHotkey)
	if not enabled() then
		return false
	end
	if C.run then
		player:sendCancelMessage("Someone is already defending the cheese cellar.") -- ours
		return true
	end
	local players, onSquares = {}, false
	for _, pos in ipairs(C.SQUARES) do
		local tile = Tile(pos)
		local creature = tile and tile:getTopCreature()
		local p = creature and creature:getPlayer()
		if p then
			if p:getId() == player:getId() then
				onSquares = true
			end
			if not C.eligible(p) then
				player:sendCancelMessage(PT.rascacoon(p) < 1 and (p:getName() .. " has not offered Tik'hi Tak'he any help yet.") or (p:getName() .. " has to wait before defending the cellar again.")) -- ours
				return true
			end
			players[#players + 1] = p
		end
	end
	if not onSquares then
		player:sendCancelMessage("Stand on one of the squares in front of the lever.") -- ours
		return true
	end
	item:transform(item:getId() == 8911 and 8912 or 8911)
	C.start(players)
	return true
end

-- Spy rats ----------------------------------------------------------------------------------------------

local function nearestCheese(run, pos)
	local best, bestDist
	for id in pairs(run.cheeses) do
		local cheese = Creature(id)
		if cheese then
			local d = pos:getDistance(cheese:getPosition())
			if not bestDist or d < bestDist then
				best, bestDist = cheese, d
			end
		end
	end
	return best, bestDist
end

local function ratThink(run, rat)
	local cheese, dist = nearestCheese(run, rat:getPosition())
	if not cheese then
		return
	end
	local cpos = cheese:getPosition()
	if dist <= 1 then
		cpos:sendMagicEffect(CONST_ME_DRAWBLOOD)
		-- the cheese cannot be attacked by anyone, so its health is kept here
		local left = cheese:getHealth() - C.BITE
		if left > 0 then
			cheese:setHealth(left)
		else
			run.cheeses[cheese:getId()] = nil
			cheese:remove()
			cpos:sendMagicEffect(CONST_ME_POFF)
			C.changeScore(-C.EATEN)
		end
		return
	end
	local path = rat:getPathTo(cpos, 0, 1, true, true, 30)
	if path and path[1] then
		rat:move(path[1])
	end
end

function C.tick(now)
	now = now or os.time()
	local run = C.run
	if not run then
		return
	end
	-- players who left
	local any = false
	for id in pairs(run.players) do
		local player = Player(id)
		if player and inCellar(player:getPosition()) then
			any = true
		else
			if player then
				player:removeIcon(C.ICON)
			end
			run.players[id] = nil
		end
	end
	if not any then
		C.finish(false)
		return
	end
	if now >= run.ends then
		C.finish(run.score > C.NEEDED)
		return
	end
	-- cheese
	if count(run.cheeses) < C.CHEESES then
		local pos = randomFree(3)
		if pos then
			spawn(run, "Mintwarella Cheese", pos)
		end
	end
	-- rats
	if now >= run.nextRat and count(run.rats) < C.RATS and #C.holes > 0 then
		local hole = C.holes[math.random(#C.holes)]
		local tile = Tile(hole)
		if tile and not tile:getTopCreature() then
			spawn(run, "Spy Rat", hole)
			hole:sendMagicEffect(CONST_ME_POFF)
		end
		run.nextRat = now + C.RAT_EVERY
	end
	for id in pairs(run.rats) do
		local rat = Monster(id)
		if rat then
			ratThink(run, rat)
		end
	end
end

local clock = GlobalEvent("FamilySupplyMission")
function clock.onThink(interval)
	if enabled() then
		C.tick()
	end
	return true
end
clock:interval(1000)
clock:register()


-- A cheese pushed onto the trapdoor; a rat over a hole goes to another hole.
local function stepCellar(creature, item, position, fromPosition)
	local run = C.run
	if not run or not creature:isMonster() then
		return true
	end
	local id = creature:getId()
	if position == C.TRAPDOOR and run.cheeses[id] then
		run.cheeses[id] = nil
		position:sendMagicEffect(CONST_ME_MAGIC_GREEN)
		creature:remove()
		C.changeScore(C.SAVED)
		return true
	end
	if item:getId() == C.HOLE and (run.rats[id] or run.thieves[id]) then
		local others = {}
		for _, h in ipairs(C.holes) do
			if h ~= position then
				others[#others + 1] = h
			end
		end
		if #others > 0 then
			local to = others[math.random(#others)]
			position:sendMagicEffect(CONST_ME_POFF)
			addEvent(function(cid, x, y, z) -- not inside the step itself (the engine refuses a teleport there)
				local c = Creature(cid)
				local dest = Position(x, y, z)
				if c then
					c:teleportTo(dest)
					dest:sendMagicEffect(CONST_ME_POFF)
				end
			end, 0, id, to.x, to.y, to.z)
		end
	end
	return true
end
C.stepCellar = stepCellar

local cellarStep = MoveEvent()
cellarStep.onStepIn = stepCellar
cellarStep:type("stepin")
cellarStep:id(C.HOLE, 35494)
cellarStep:register()

-- The chest and the revealer.
local function useChest(player, item, fromPosition, target, toPosition, isHotkey)
	local run = C.run
	if not enabled() or not run or not run.players[player:getId()] then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.") -- ours
		return true
	end
	if player:getItemCount(C.REVEALER) > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already have a rat revealer.") -- ours
		return true
	end
	player:addItem(C.REVEALER, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take a Rascoohan Rat Revealer.") -- ours
	return true
end
C.useChest = useChest

local function useRevealer(player, item, fromPosition, target, toPosition, isHotkey)
	local run = C.run
	local rat = target and target.isMonster and target:isMonster() and target or nil
	if not run or not rat or not run.rats[rat:getId()] then
		player:sendCancelMessage("Nothing happens.") -- ours
		return true
	end
	local pos = rat:getPosition()
	run.rats[rat:getId()] = nil
	rat:remove()
	local thief = Game.createMonster("Cheese Thief", pos, false, true)
	if thief then
		run.thieves[thief:getId()] = true
	end
	pos:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end
C.useRevealer = useRevealer

local lever = Action()
lever.onUse = useLever
C.useLever = useLever
lever:position(C.LEVER)
lever:register()

local chest = Action()
chest.onUse = useChest
chest:position(C.CHEST)
chest:register()

local revealer = Action()
revealer.onUse = useRevealer
revealer:id(C.REVEALER)
revealer:register()

local startup = GlobalEvent("FamilySupplyCellar")
function startup.onStartup()
	if enabled() then
		logger.info(string.format("[Family] Rascacoon supply mission: %d holes", C.findHoles()))
	end
	return true
end
startup:register()
