-- Gaia Family server: Oramond Quest kill tasks, kill counting (2026-11-08).
-- Rules and NPC dialogue are in lib/others/family_oramond_tasks.lua (switch Family.oramondTasks).

local T = FamilyOramondTasks

local death = CreatureEvent("FamilyOramondTaskDeath")

function death.onDeath(creature, corpse, lastHitKiller, mostDamageKiller)
	local name = creature:getName()
	onDeathForParty(creature, mostDamageKiller, function(_, player)
		T.countKill(player, name)
	end)
	return true
end

death:register()

local startup = GlobalEvent("FamilyOramondTaskStartup")

function startup.onStartup()
	if not T.on() then
		return true
	end
	local registered = 0
	local names = {}
	for name in pairs(T.byCreature) do
		names[name] = true
	end
	for name in pairs(T.combo) do
		names[name] = true
	end
	for name in pairs(names) do
		local mType = MonsterType(name)
		if mType then
			mType:registerEvent("FamilyOramondTaskDeath")
			registered = registered + 1
		else
			logger.error("[Family] Oramond tasks: unknown creature {}", name)
		end
	end
	logger.info("[Family] Oramond tasks: kills of {} creatures counted for {} kill tasks and Combinatorics", registered, #T.hunts + 1)
	return true
end

startup:register()

-- ==================================================================== batch 2 (2026-11-08)
-- Map objects of Sabotage, Rathleton Turnip Party, Communication Breakdown and Dr Merlay's
-- Misery (positions read from our map; rules and texts in lib/others/family_oramond_tasks.lua).

local RACK, RACK_DESTROYED, NOZZLE, CUP = 21163, 21161, 21185, 21187
local CRATE_MAP, CRATE, FLOATING = 21153, 21155, 21159
local VALVES = { 21151, 21148 }
local LEVERS = { 21125, 21126, 21127, 21128 }
local GLOOTH = 21152
local PINT, PINT_GREEN, PINT_STALE = 21137, 21214, 21215
local STATUES = { 21134, 21135, 21136 }
local ACCELERATOR = 21147

-- Dr Merlay's lab (z11 statue row y 31891, x 33570-33588; lab below the north room, z12).
local STATUE_ROW, STATUE_Z, LAB_X1, LAB_X2 = 31891, 11, 33570, 33588
local SEWER_COVER = Position(33586, 31884, 10) -- EN: "descend into the sewer" here
local SOUTH_ROOM = Position(33586, 31892, 11)
local RUNGS = Position(33577, 31898, 11)
local RUNGS_UP = Position(33587, 31884, 10) -- next to the sewer cover

-- The armor racks are drawn on our map partly in their destroyed look.
local RACK_SPOTS = { Position(33710, 31960, 7), Position(33698, 31966, 7), Position(33692, 31972, 7) }

local batch2Startup = GlobalEvent("FamilyOramondTasksBatch2")
function batch2Startup.onStartup()
	if not T.on() then
		return true
	end
	local fixed = 0
	for _, pos in ipairs(RACK_SPOTS) do
		local tile = Tile(pos)
		local rack = tile and tile:getItemById(RACK_DESTROYED)
		if rack then
			rack:transform(RACK)
			fixed = fixed + 1
		end
	end
	logger.info("[Family] Oramond tasks batch 2: {} armor racks restored", fixed)
	return true
end
batch2Startup:register()

-- Sabotage ---------------------------------------------------------
local nozzle = Action()
function nozzle.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	if player:getItemCount(CUP) > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already carry a cup of cowcoa.") -- ours
		return true
	end
	player:addItem(CUP, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A nice fresh cup of cowcoa.")
	return true
end
nozzle:id(NOZZLE)
nozzle:register()

local cup = Action()
function cup.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId or target:getId() ~= RACK then
		return false
	end
	if not T.addSabotage(player) then
		return true
	end
	item:remove(1)
	T.destroyRack(target)
	toPosition:sendMagicEffect(CONST_ME_GREEN_RINGS)
	return true
end
cup:id(CUP)
cup:register()

-- Rathleton Turnip Party ---------------------------------------------
local crateMap = Action()
function crateMap.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	if not T.canTakeCrate(player) then
		return true
	end
	if player:getItemCount(CRATE) > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already carry a supply crate. Find a water source first.") -- ours
		return true
	end
	player:addItem(CRATE, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You feel as if being watched. Try to find a water source but don't throw the crate - put it in there gently and secretly.")
	return true
end
crateMap:id(CRATE_MAP)
crateMap:register()

local function isWater(target)
	if not target or not target.getName then
		return false
	end
	return target:getName():lower():find("water", 1, true) ~= nil
end

local crate = Action()
function crate.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not isWater(target) then
		return false
	end
	if not T.canTakeCrate(player) then
		return true
	end
	item:remove(1)
	local where = Position(toPosition.x, toPosition.y, toPosition.z)
	local floating = Game.createItem(FLOATING, 1, where)
	if floating then
		addEvent(function()
			local t = Tile(where)
			local f = t and t:getItemById(FLOATING)
			if f then
				f:remove()
			end
		end, 60 * 1000)
	end
	where:sendMagicEffect(CONST_ME_WATERSPLASH)
	T.addTurnips(player)
	return true
end
crate:id(CRATE, 21156)
crate:register()

-- Communication Breakdown ---------------------------------------------
local valve = Action()
function valve.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	return T.useValve(player, item:getPosition())
end
valve:id((table.unpack or unpack)(VALVES))
valve:register()

local lever = Action()
function lever.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	return T.pullLever(player, item, item:getPosition())
end
lever:id((table.unpack or unpack)(LEVERS))
lever:register()

local glooth = Action()
function glooth.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	return T.takeGlooth(player, item)
end
glooth:id(GLOOTH)
glooth:register()

-- Dr Merlay's Misery --------------------------------------------------
local pint = Action()
function pint.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or target ~= player then
		return false
	end
	local id = item:getId()
	item:remove(1)
	if id == PINT then
		player:setMonsterOutfit("Rot Elemental", 30 * 1000)
		T.kv(player):set("rot-until", os.time() + 30)
		player:getPosition():sendMagicEffect(CONST_ME_GREEN_RINGS)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The glooth bubbles through you - you feel rotten to the core. It won't last long.") -- ours
	elseif id == PINT_GREEN then
		player:getPosition():sendMagicEffect(CONST_ME_SOUND_YELLOW) -- EN: the green pint makes you sing
		player:say("La la laaa!", TALKTYPE_MONSTER_SAY) -- ours
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Bah, it's stale.") -- ours
	end
	return true
end
pint:id(PINT, PINT_GREEN, PINT_STALE)
pint:register()

local function walkableOnRow(x, y, z)
	for d = 0, 6 do
		for _, dx in ipairs({ d, -d }) do
			local tile = Tile(Position(x + dx, y, z))
			if tile and tile:getGround() and not tile:hasFlag(TILESTATE_BLOCKSOLID) and not tile:hasFlag(TILESTATE_FLOORCHANGE) then
				return Position(x + dx, y, z)
			end
		end
	end
end

local function passStatues(player, x, northward)
	local to = walkableOnRow(x, northward and STATUE_ROW - 1 or STATUE_ROW + 1, STATUE_Z)
	if not to then
		return false
	end
	if northward and not T.hasLabAccess(player) then
		T.kv(player):set("lab-access", true)
		if not player:hasAchievement("Elementary, My Dear") then
			player:addAchievement("Elementary, My Dear")
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The statues let the rot elemental pass. From now on you have access to Dr Merlay's laboratory.") -- ours (BR: a white message)
	end
	player:getPosition():sendMagicEffect(CONST_ME_POFF)
	player:teleportTo(to)
	to:sendMagicEffect(CONST_ME_GREEN_RINGS)
	return true
end

local statue = Action()
function statue.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local pos = item:getPosition()
	if not T.on() or pos.y ~= STATUE_ROW or pos.z ~= STATUE_Z or pos.x < LAB_X1 or pos.x > LAB_X2 then
		return false
	end
	local northward = player:getPosition().y > STATUE_ROW
	if northward and not T.isRotElemental(player) and not T.hasLabAccess(player) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The metal statues won't let a human pass. Something rotten might slip through, though.") -- ours
		return true
	end
	return passStatues(player, pos.x, northward)
end
statue:id((table.unpack or unpack)(STATUES))
statue:register()

-- A rot elemental walking up to the statues slips through (EN: "walk north through the statues").
local statueStep = MoveEvent()
function statueStep.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not T.on() or not T.isRotElemental(player) or fromPosition.y < position.y then
		return true
	end
	passStatues(player, position.x, true)
	return true
end
statueStep:type("stepin")
for x = LAB_X1, LAB_X2 do
	statueStep:position(Position(x, STATUE_ROW + 1, STATUE_Z))
end
statueStep:register()

local cover = Action()
function cover.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	player:teleportTo(SOUTH_ROOM)
	SOUTH_ROOM:sendMagicEffect(CONST_ME_POFF)
	return true
end
cover:position(SEWER_COVER)
cover:register()

local rungs = Action()
function rungs.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	player:teleportTo(RUNGS_UP)
	return true
end
rungs:position(RUNGS)
rungs:register()

local potion = Action()
function potion.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId then
		return false
	end
	local other = target:getId()
	if not ((item:getId() == T.POTION and other == T.BLOOM) or (item:getId() == T.BLOOM and other == T.POTION)) then
		return false
	end
	item:remove(1)
	target:remove(1)
	player:addItem(T.MIXTURE, 1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The soothe bloom dissolves in the potion. The mixture cools down and stops vibrating.") -- ours
	return true
end
potion:id(T.POTION, T.BLOOM)
potion:register()

local mixture = Action()
function mixture.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId or target:getId() ~= ACCELERATOR then
		return false
	end
	item:remove(1)
	player:addItem(T.PILL, 1)
	toPosition:sendMagicEffect(CONST_ME_ENERGYAREA)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The particle accelerator whirls and presses the mixture into an ominously glowing pill.") -- ours
	return true
end
mixture:id(T.MIXTURE)
mixture:register()
