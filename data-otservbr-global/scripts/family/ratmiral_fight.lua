-- Gaia Family server: the Ratmiral Blackwhiskers fight in four stages (A Pirate's Tail Quest, part 3b,
-- 2026-11-11). Ours, not upstream: Canary v3.6.1 sent the team straight onto the upper deck with Ratmiral.
-- Sources: TibiaWiki BR quest page (from Rodrigo) and TibiaWiki EN quest spoiler and creature pages.
--
-- The lever (upstream, actions_ratmiral_blackwhiskers.lua, level 250, 5 players) calls R.start and now sends
-- the team into the cave south of the pirats' ship.
-- 1. Rateye Ric, Elite Pirats, Smelly Cheeses (damage around them) and Pirat Artillerists shooting life drain
--    (EN/BR). The Weak Spot is the gate north of the cave (33902,31363): drag the Rum Barrel (it waits in the
--    north-east) next to it; the barrel explodes when the artillerists' shots have hit it enough, or at once
--    when a summon or Rateye Ric touches it (BR/EN), and the gate breaks after two explosions (BR); the shots
--    also wear the gate down (EN). A new barrel comes after an explosion (EN).
-- 2. Mister Catkiller on the ship's lower deck; after about 30 seconds the ladder to the upper deck appears
--    (BR/EN).
-- 3. 1st Mate Ratticus on the upper deck leaves soon after the fight there begins (BR/EN).
-- 4. Ratmiral Blackwhiskers. The bath tub (33903,31345,14) gives each player 6 water charges against his fire
--    waves, but not while he is near it (BR/EN). At half health all three minibosses come back (BR/EN), and this
--    time they can die. Rateye Ric, Mister Catkiller and Ratticus leave before they die in stages 1-3 (BR/EN).
-- Victory: 100 trust points each time (BR/EN) and, once, the Rascoohan outfit from Tik'hi Tak'he (`mission`, BR).
--
-- Ours (no source gives them; Rodrigo: estimate like Tibia): the arrival square, the barrel's place and its 3
-- hits, a direct hit takes 10% of the gate, an explosion 50% (two break it, BR) and burns the squares around it
-- for 300-600 fire; artillery: each of the four artillerists shoots every 3 s at a random player in the fight
-- (great-fireball area, 200-400 life drain); 4 elite pirats at a time, one more every 20 s; the minibosses leave
-- at 20% health (stage 2 also after 30 s, stage 3 after 30 s on the upper deck), the tub works while Ratmiral is
-- more than 3 squares away; the places of the cheeses; the messages.
-- Switch: Family.piratesTail.

local PT = FamilyPiratesTail
if not PT then
	return
end
local S = Storage.Quest.U12_60.APiratesTail

local R = {}
PT.ratmiral = R

R.BOSS = "Ratmiral Blackwhiskers"
R.ZONE = { x1 = 33888, y1 = 31344, x2 = 33920, y2 = 31376, z1 = 14, z2 = 15 }
R.ARRIVAL = Position(33903, 31372, 15)
R.EXIT = Position(33891, 31197, 7)
R.GATE = Position(33902, 31363, 15)
R.BARREL = Position(33910, 31364, 15)
R.LADDER = Position(33902, 31348, 15)
R.LADDER_ID = 5542
R.TUB = Position(33903, 31345, 14)
R.BOSS_POS = Position(33904, 31351, 14)
R.SPAWN = {
	rateye = Position(33902, 31366, 15),
	catkiller = Position(33906, 31351, 15),
	ratticus = Position(33904, 31351, 14),
}
R.ARTILLERISTS = { Position(33896, 31367, 15), Position(33910, 31367, 15), Position(33899, 31372, 15), Position(33907, 31372, 15) }
R.CHEESES = {
	Position(33898, 31368, 15), Position(33906, 31368, 15), Position(33902, 31366, 15),
	Position(33903, 31347, 15), Position(33909, 31355, 15),
	Position(33899, 31354, 14), Position(33910, 31348, 14),
}
R.PIRAT_SPOTS = {
	[1] = { Position(33893, 31369, 15), Position(33912, 31369, 15), Position(33896, 31365, 15), Position(33908, 31365, 15) },
	[2] = { Position(33900, 31346, 15), Position(33910, 31346, 15), Position(33900, 31356, 15), Position(33910, 31356, 15) },
	[3] = { Position(33900, 31346, 14), Position(33910, 31346, 14), Position(33900, 31356, 14), Position(33910, 31356, 14) },
}
R.PIRAT_SPOTS[4] = R.PIRAT_SPOTS[3]
R.PIRATS, R.PIRAT_EVERY = 4, 20
R.SHOT_EVERY, R.SHOT_MIN, R.SHOT_MAX = 3, 200, 400
R.BARREL_HITS = 3
R.GATE_SHOT, R.GATE_BLAST = 10, 50
R.BLAST_MIN, R.BLAST_MAX = 300, 600
R.LEAVE_AT = 0.2
R.STAGE_TIME = 30
R.TUB_CHARGES, R.TUB_DISTANCE = 6, 3
R.TRUST = 100
R.ICON = "family-bath"

R.AREA = createCombatArea(AREA_CIRCLE3X3)

R.stage = nil
R.c = {} -- creature ids: gate, barrel, rateye, catkiller, ratticus, boss; lists: artillerists, cheeses, pirats
R.gate, R.barrelHits = 0, 0
R.final = {} -- minibosses that may die (back at Ratmiral's half health)
R.charges = {}

function R.enabled()
	return PT.enabled()
end

local function inZone(pos)
	local z = R.ZONE
	return pos.z >= z.z1 and pos.z <= z.z2 and pos.x >= z.x1 and pos.x <= z.x2 and pos.y >= z.y1 and pos.y <= z.y2
end
R.inZone = inZone

local function zonePlayers()
	local list = {}
	for _, p in ipairs(Game.getPlayers()) do
		if inZone(p:getPosition()) then
			list[#list + 1] = p
		end
	end
	return list
end
R.zonePlayers = zonePlayers

local function tell(text)
	for _, p in ipairs(zonePlayers()) do
		p:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	end
end

local function alive(id)
	return id and Creature(id) or nil
end

local function spawn(name, pos, force)
	local m = Game.createMonster(name, pos, true, force ~= false)
	return m
end

local function removeId(id)
	local c = alive(id)
	if c then
		c:remove()
	end
end

local function removeLadder()
	local tile = Tile(R.LADDER)
	local ladder = tile and tile:getItemById(R.LADDER_ID)
	if ladder then
		ladder:remove()
	end
end

local function placeLadder()
	local tile = Tile(R.LADDER)
	if tile and not tile:getItemById(R.LADDER_ID) then
		Game.createItem(R.LADDER_ID, 1, R.LADDER)
		R.LADDER:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	end
end

function R.reset()
	for _, key in ipairs({ "gate", "barrel", "rateye", "catkiller", "ratticus", "boss" }) do
		removeId(R.c[key])
	end
	for _, key in ipairs({ "artillerists", "cheeses", "pirats" }) do
		for _, id in ipairs(R.c[key] or {}) do
			removeId(id)
		end
	end
	for pid in pairs(R.charges) do
		local p = Player(pid)
		if p then
			p:removeIcon(R.ICON)
		end
	end
	R.c, R.final, R.charges = {}, {}, {}
	R.stage, R.gate, R.barrelHits, R.returned = nil, 0, 0, false
	placeLadder() -- the map has the ladder; outside a fight it stays
end

local function spawnBarrel()
	local m = spawn("Rum Barrel", R.BARREL)
	R.c.barrel = m and m:getId() or nil
	R.barrelHits = 0
	return m
end

-- Called by the lever before the team is moved in.
function R.start(now)
	now = now or os.time()
	R.reset()
	removeLadder()
	local gate = spawn("Weak Spot", R.GATE)
	if not gate then
		return false
	end
	R.c.gate = gate:getId()
	R.gate = 100
	spawnBarrel()
	local ric = spawn("Rateye Ric", R.SPAWN.rateye)
	R.c.rateye = ric and ric:getId() or nil
	R.c.artillerists, R.c.cheeses, R.c.pirats = {}, {}, {}
	for _, pos in ipairs(R.ARTILLERISTS) do
		local m = spawn("Pirat Artillerist", pos)
		if m then
			R.c.artillerists[#R.c.artillerists + 1] = m:getId()
		end
	end
	for _, pos in ipairs(R.CHEESES) do
		local m = spawn("Smelly Cheese", pos)
		if m then
			R.c.cheeses[#R.c.cheeses + 1] = m:getId()
		end
	end
	R.stage = 1
	R.nextShot = now + R.SHOT_EVERY
	R.nextPirat = now
	R.stageStart = now
	R.upperSince = nil
	return true
end

-- The barrel ------------------------------------------------------------------------------------------

function R.explode()
	local barrel = alive(R.c.barrel)
	if not barrel then
		return false
	end
	local pos = barrel:getPosition()
	barrel:remove()
	R.c.barrel = nil
	doAreaCombatHealth(0, COMBAT_FIREDAMAGE, pos, R.AREA, -R.BLAST_MIN, -R.BLAST_MAX, CONST_ME_FIREAREA)
	pos:sendMagicEffect(CONST_ME_EXPLOSIONHIT)
	if R.stage == 1 and pos:getDistance(R.GATE) <= 1 then
		R.hurtGate(R.GATE_BLAST)
	end
	addEvent(function()
		if R.stage == 1 then
			spawnBarrel()
		end
	end, 10000)
	return true
end

function R.hurtGate(percent)
	if R.stage ~= 1 or not alive(R.c.gate) then
		return
	end
	R.gate = R.gate - percent
	R.GATE:sendMagicEffect(CONST_ME_BLOCKHIT)
	if R.gate <= 0 then
		R.toStage2()
	end
end

-- Artillery: every artillerist shoots at someone in the fight.
function R.shoot()
	local players = zonePlayers()
	if #players == 0 then
		return
	end
	for _, id in ipairs(R.c.artillerists or {}) do
		local gun = alive(id)
		if gun then
			local target = players[math.random(#players)]:getPosition()
			gun:getPosition():sendDistanceEffect(target, CONST_ANI_BURSTARROW)
			doAreaCombatHealth(gun, COMBAT_LIFEDRAIN, target, R.AREA, -R.SHOT_MIN, -R.SHOT_MAX, CONST_ME_MAGIC_RED)
			R.shotAt(target)
		end
	end
end

-- What a shot does to the barrel and the gate (monsters cannot hurt each other here, so the script counts).
function R.shotAt(target)
	local barrel = alive(R.c.barrel)
	if barrel and barrel:getPosition():getDistance(target) <= 3 and barrel:getPosition().z == target.z then
		R.barrelHits = R.barrelHits + 1
		if R.barrelHits >= R.BARREL_HITS then
			R.explode()
		end
	end
	if R.stage == 1 and R.GATE.z == target.z and R.GATE:getDistance(target) <= 3 then
		R.hurtGate(R.GATE_SHOT)
	end
end

-- A summon or Rateye Ric touching the barrel destroys it (BR/EN).
local function barrelTouched()
	local barrel = alive(R.c.barrel)
	if not barrel then
		return false
	end
	local bpos = barrel:getPosition()
	local ric = alive(R.c.rateye)
	if ric and ric:getPosition():getDistance(bpos) <= 1 and ric:getPosition().z == bpos.z then
		return true
	end
	for _, c in ipairs(Game.getSpectators(bpos, false, false, 1, 1, 1, 1)) do
		if c:isMonster() and c:getMaster() and c:getMaster():isPlayer() then
			return true
		end
	end
	return false
end

-- Stages ----------------------------------------------------------------------------------------------

local function leave(key, text)
	local c = alive(R.c[key])
	if c then
		c:getPosition():sendMagicEffect(CONST_ME_POFF)
		c:remove()
		if text then
			tell(text)
		end
	end
	R.c[key] = nil
end

function R.toStage2(now)
	now = now or os.time()
	removeId(R.c.gate)
	R.c.gate = nil
	R.GATE:sendMagicEffect(CONST_ME_EXPLOSIONAREA)
	removeId(R.c.barrel)
	R.c.barrel = nil
	leave("rateye", "Rateye Ric flees to the ship.") -- ours
	local cat = spawn("Mister Catkiller", R.SPAWN.catkiller)
	R.c.catkiller = cat and cat:getId() or nil
	R.stage, R.stageStart = 2, now
	tell("The gate breaks! Board the pirats' ship!") -- ours
end

function R.toStage3(now)
	now = now or os.time()
	leave("catkiller", "Mister Catkiller runs off.") -- ours
	placeLadder()
	local rat = spawn("1st Mate Ratticus", R.SPAWN.ratticus)
	R.c.ratticus = rat and rat:getId() or nil
	R.stage, R.stageStart, R.upperSince = 3, now, nil
	tell("A ladder leads up to the upper deck.") -- ours
end

function R.toStage4(now)
	leave("ratticus", "1st Mate Ratticus runs to his captain.") -- ours
	local boss = spawn(R.BOSS, R.BOSS_POS)
	R.c.boss = boss and boss:getId() or nil
	R.stage, R.stageStart = 4, now or os.time()
	tell("Ratmiral Blackwhiskers himself comes on deck!") -- ours
end

function R.bringBack()
	R.returned = true
	for key, name in pairs({ rateye = "Rateye Ric", catkiller = "Mister Catkiller", ratticus = "1st Mate Ratticus" }) do
		if not alive(R.c[key]) then
			local m = spawn(name, R.BOSS_POS)
			if m then
				R.c[key] = m:getId()
				R.final[m:getId()] = true
			end
		else
			R.final[R.c[key]] = true
		end
	end
	tell("Ratmiral calls his officers back to his side!") -- ours
end

local function hurt(id)
	local c = alive(id)
	return c and c:getHealth() / c:getMaxHealth() or 1
end

local function countList(list)
	local n = 0
	for k = #list, 1, -1 do
		if alive(list[k]) then
			n = n + 1
		else
			table.remove(list, k)
		end
	end
	return n
end

function R.tick(now)
	now = now or os.time()
	if not R.stage or R.stage == "won" then
		return
	end
	local players = zonePlayers()
	if #players == 0 then
		R.reset()
		return
	end
	if now >= R.nextShot then
		R.shoot()
		R.nextShot = now + R.SHOT_EVERY
	end
	if R.stage == 1 and barrelTouched() then
		R.explode()
	end
	-- elite pirats
	if now >= R.nextPirat then
		if countList(R.c.pirats) < R.PIRATS then
			local spots = R.PIRAT_SPOTS[R.stage] or R.PIRAT_SPOTS[1]
			local m = spawn("Elite Pirat", spots[math.random(#spots)], false)
			if m then
				R.c.pirats[#R.c.pirats + 1] = m:getId()
			end
		end
		R.nextPirat = now + R.PIRAT_EVERY
	end
	-- minibosses leave before they die (stages 1-3)
	for _, key in ipairs({ "rateye", "catkiller", "ratticus" }) do
		local id = R.c[key]
		if id and not R.final[id] and alive(id) and hurt(id) <= R.LEAVE_AT then
			if key == "catkiller" and R.stage == 2 then
				R.toStage3(now)
			elseif key == "ratticus" and R.stage == 3 then
				R.toStage4(now)
			else
				leave(key)
			end
		end
	end
	if R.stage == 2 and now - R.stageStart >= R.STAGE_TIME then
		R.toStage3(now)
	elseif R.stage == 3 then
		if not R.upperSince then
			for _, p in ipairs(players) do
				if p:getPosition().z == 14 then
					R.upperSince = now
				end
			end
		elseif now - R.upperSince >= R.STAGE_TIME then
			R.toStage4(now)
		end
	elseif R.stage == 4 and not R.returned and alive(R.c.boss) and hurt(R.c.boss) <= 0.5 then
		R.bringBack()
	end
end

-- Victory ---------------------------------------------------------------------------------------------

function R.reward(player)
	PT.addTrust(player, R.TRUST)
	player:setStorageValue(S.RatmiralKilled, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Ratmiral Blackwhiskers is defeated! Tik'hi Tak'he will hear of it: %d trust points.", R.TRUST)) -- ours
end

function R.won()
	R.stage = "won"
	for _, p in ipairs(zonePlayers()) do
		R.reward(p)
	end
	local lever = BossLever and BossLever[R.BOSS:lower()]
	if lever and lever.timeoutEvent then
		stopEvent(lever.timeoutEvent)
		lever.timeoutEvent = nil
	end
	tell("You have 60 seconds before the pirats' ship takes you back to The Wreckoning.") -- ours
	addEvent(function()
		for _, p in ipairs(zonePlayers()) do
			p:teleportTo(R.EXIT)
		end
		R.EXIT:sendMagicEffect(CONST_ME_TELEPORT)
		R.reset()
	end, 60000)
end

local bossDeath = CreatureEvent("FamilyRatmiralDeath")
function bossDeath.onDeath(creature)
	if not R.enabled() then
		return true
	end
	if creature:getId() == R.c.boss then
		R.c.boss = nil
		R.won()
	elseif inZone(creature:getPosition()) then
		-- a Ratmiral not made by the fight (a GOD's /m): reward the players around
		for _, p in ipairs(zonePlayers()) do
			R.reward(p)
		end
	end
	return true
end
bossDeath:register()

-- Minibosses never die before stage 4 (they leave at 20%; this stops a last big hit from killing them).
local helper = CreatureEvent("FamilyRatmiralHelper")
function helper.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if primaryType ~= COMBAT_HEALING and not R.final[creature:getId()] then
		local floor = math.ceil(creature:getMaxHealth() * 0.1)
		local room = math.max(0, creature:getHealth() - floor)
		local dealt = math.abs(primaryDamage) + math.abs(secondaryDamage)
		if dealt > room then
			local sign = primaryDamage < 0 and -1 or 1
			return sign * room, primaryType, 0, secondaryType
		end
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
helper:register()

-- The bath tub ------------------------------------------------------------------------------------------

function R.useTub(player)
	if not R.enabled() or not R.stage or not inZone(player:getPosition()) then
		return false
	end
	local boss = alive(R.c.boss)
	if boss and boss:getPosition():getDistance(R.TUB) <= R.TUB_DISTANCE and boss:getPosition().z == R.TUB.z then
		player:sendCancelMessage("Ratmiral Blackwhiskers is too close to the tub.") -- ours
		return true
	end
	R.charges[player:getId()] = R.TUB_CHARGES
	player:registerEvent("FamilyRatmiralBath")
	player:setIcon(R.ICON, CreatureIconCategory_Quests, CreatureIconQuests_Water, R.TUB_CHARGES)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You are soaked: the water will protect you from fire %d times.", R.TUB_CHARGES)) -- ours
	player:getPosition():sendMagicEffect(CONST_ME_WATERSPLASH)
	return true
end

local tub = Action()
function tub.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return R.useTub(player)
end
tub:position(R.TUB)
tub:register()

-- Water charges take Ratmiral's fire.
function R.bath(creature, attacker, primaryDamage, primaryType)
	local id = creature:getId()
	local left = R.charges[id]
	if left and left > 0 and primaryType == COMBAT_FIREDAMAGE and attacker and attacker:getName() == R.BOSS then
		left = left - 1
		R.charges[id] = left
		creature:getPosition():sendMagicEffect(CONST_ME_WATERSPLASH)
		if left > 0 then
			creature:setIcon(R.ICON, CreatureIconCategory_Quests, CreatureIconQuests_Water, left)
		else
			creature:removeIcon(R.ICON)
		end
		return true
	end
	return false
end
local bath = CreatureEvent("FamilyRatmiralBath")
function bath.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if R.bath(creature, attacker, primaryDamage, primaryType) then
		return 0, primaryType, secondaryDamage, secondaryType
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
bath:register()

-- Clock ----------------------------------------------------------------------------------------------

local clock = GlobalEvent("FamilyRatmiralFight")
function clock.onThink(interval)
	if R.enabled() and R.stage then
		R.tick()
	end
	return true
end
clock:interval(1000)
clock:register()
