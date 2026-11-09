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

-- ==================================================================== batch 3 (2026-11-08)
-- Four Demanding Statues and The Mutated Glooth Plague (rules in lib/others/family_oramond_tasks.lua).

local FORCEFIELD = Position(33574, 32034, 12) -- teleport to the warlock room (33573,32036,11)
local WARLOCK_ROOM = Position(33573, 32036, 11)
local WARLOCK_BOX = { 33595, 32015, 33660, 32060, 11 }
local SHELF = Position(33636, 32035, 11)
local GAUGE_BOX = Position(33394, 31915, 12)
local GEORGIA_LAB = { 33578, 31895, 33600, 31912, 12 }
local FLORET_OBJECTS = { 21851, 21852 }
local FLORET, INTERWOVEN, GARLAND = 21853, 21857, 21856
local HEAP, DEAD_RAT = 21858, 21850
local SACRED_UNLIT, SACRED_LIT = 2062, 2063
local COBRA = 2051
local CRIMSON = 21806
local COPPER_VALVE_OBJECT = 21792
local PURPLE_SLIME = { 21772, 21773, 21774 }
local APPARATUS = { 8995, 8996 }

local function inBox(pos, box)
	return pos.z == box[5] and pos.x >= box[1] and pos.x <= box[3] and pos.y >= box[2] and pos.y <= box[4]
end

local function samePos(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

local batch3Startup = GlobalEvent("FamilyOramondTasksBatch3")
function batch3Startup.onStartup()
	if not T.on() then
		return true
	end
	local tile = Tile(FORCEFIELD)
	local field = tile and tile:getItemById(1949)
	if field and field.setDestination then
		field:setDestination(Position(0, 0, 0)) -- the move event below decides
	end
	local warlock = MonsterType("Warlock")
	if warlock then
		warlock:registerEvent("FamilyOramondWarlockDeath")
	end
	logger.info("[Family] Oramond tasks batch 3: statue forcefield {}, warlock watched {}", field and "set" or "missing", warlock and "yes" or "no")
	return true
end
batch3Startup:register()

local forcefield = MoveEvent()
function forcefield.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if not T.on() or T.statuesDone(player) or player:getStorageValue(T.S.Statues) >= 4 then
		player:teleportTo(WARLOCK_ROOM)
		WARLOCK_ROOM:sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
	player:teleportTo(samePos(fromPosition, position) and Position(33574, 32033, 12) or fromPosition, true)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The forcefield does not let you pass. The four statues still demand something.") -- ours
	return true
end
forcefield:type("stepin")
forcefield:position(FORCEFIELD)
forcefield:register()

local warlockDeath = CreatureEvent("FamilyOramondWarlockDeath")
function warlockDeath.onDeath(creature, corpse, lastHitKiller, mostDamageKiller)
	if not T.on() or not inBox(creature:getPosition(), WARLOCK_BOX) then
		return true
	end
	onDeathForDamagingPlayers(creature, function(_, player)
		T.warlockKilled(player)
	end)
	return true
end
warlockDeath:register()

local shelf = Action()
function shelf.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or player:getStorageValue(T.S.Statues) ~= 2 then
		return false
	end
	local letter = player:addItem(2819, 1)
	if letter then
		letter:setAttribute(ITEM_ATTRIBUTE_TEXT, T.WARLOCK_LETTER)
	end
	player:setStorageValue(T.S.Statues, 3)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found a letter in the shelf. Bring this proof to Elbert.") -- ours
	return true
end
shelf:position(SHELF)
shelf:register()

local floretObject = Action()
function floretObject.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	player:addItem(FLORET, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You pick a dinky moss floret.") -- ours
	return true
end
floretObject:id((table.unpack or unpack)(FLORET_OBJECTS))
floretObject:register()

local floret = Action()
function floret.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId then
		return false
	end
	local other = target:getId()
	if item:getId() == FLORET and other == FLORET and target ~= item then
		item:remove(1)
		target:remove(1)
		player:addItem(INTERWOVEN, 1)
		return true
	elseif (item:getId() == FLORET and other == INTERWOVEN) or (item:getId() == INTERWOVEN and other == FLORET) then
		item:remove(1)
		target:remove(1)
		player:addItem(GARLAND, 1)
		return true
	elseif item:getId() == FLORET and other == FLORET then
		if player:getItemCount(FLORET) >= 2 then
			player:removeItem(FLORET, 2)
			player:addItem(INTERWOVEN, 1)
			return true
		end
	end
	return false
end
floret:id(FLORET, INTERWOVEN)
floret:register()

local garland = Action()
function garland.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId or not samePos(toPosition, T.STATUE_POS.adorn) then
		return false
	end
	if target:getId() == SACRED_LIT then
		item:remove(1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The flame of the statue sets the garland on fire. It burns to ashes.") -- ours (EN: turn the flame off first)
		return true
	end
	if target:getId() == SACRED_UNLIT and T.pleaseStatue(player, "adorn") then
		item:remove(1)
	end
	return true
end
garland:id(GARLAND)
garland:register()

local heap = Action()
function heap.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or player:getStorageValue(T.S.Statues) < 1 then
		return false
	end
	if player:getItemCount(DEAD_RAT) > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You find nothing else of use in the rubbish.") -- ours
		return true
	end
	player:addItem(DEAD_RAT, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You find a dead rat in the rubbish.") -- ours
	return true
end
heap:id(HEAP)
heap:register()

local rat = Action()
function rat.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId or target:getId() ~= COBRA or not samePos(toPosition, T.STATUE_POS.feed) then
		return false
	end
	if T.pleaseStatue(player, "feed") then
		item:remove(1)
	end
	return true
end
rat:id(DEAD_RAT)
rat:register()

-- The Mutated Glooth Plague --------------------------------------------
local part = Action()
function part.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId or target:getId() ~= T.DEVICE then
		return false
	end
	return T.mountPart(player, item, target)
end
part:id(T.GEAR, T.VALVE, T.GAUGE, T.TUBE)
part:register()

local gaugeBox = Action()
function gaugeBox.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or player:getStorageValue(T.S.Plague) < 1 then
		return false
	end
	local kv = T.kv(player)
	if (kv:get("gauge-at") or 0) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The box is empty. Maybe later.") -- ours
		return true
	end
	kv:set("gauge-at", os.time() + 2 * 60) -- EN: every 2 minutes
	player:addItem(T.GAUGE, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You find a calibrated indicator gauge in the box.") -- ours
	return true
end
gaugeBox:position(GAUGE_BOX)
gaugeBox:register()

local valveObject = Action()
function valveObject.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local pos = item:getPosition()
	if not T.on() or pos.z ~= 12 or player:getStorageValue(T.S.Plague) < 1 then
		return false
	end
	player:addItem(T.VALVE, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You demount a copper valve from the pipe.") -- ours
	return true
end
valveObject:id(COPPER_VALVE_OBJECT)
valveObject:register()

local crimson = Action()
function crimson.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() then
		return false
	end
	local where = item:getPosition()
	item:remove()
	player:addItem(T.MUSHROOM, 1)
	addEvent(function()
		local tile = Tile(where)
		if tile and not tile:getItemById(CRIMSON) then
			Game.createItem(CRIMSON, 1, where)
		end
	end, 5 * 60 * 1000) -- EN: regrows after 5 minutes
	return true
end
crimson:id(CRIMSON)
crimson:register()

local mushroom = Action()
function mushroom.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId or not table.contains(APPARATUS, target:getId()) or not inBox(toPosition, GEORGIA_LAB) then
		return false
	end
	item:remove(1)
	player:addItem(T.DISTILLATE, 1)
	toPosition:sendMagicEffect(CONST_ME_MAGIC_RED)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You distil the mushroom into a vial of mushroom distillate.") -- ours
	return true
end
mushroom:id(T.MUSHROOM)
mushroom:register()

local distillate = Action()
function distillate.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId or target:getId() ~= T.CONVERTER then
		return false
	end
	item:remove(1)
	target:transform(T.FILLED)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You fill the distillate into the glooth converter.") -- ours
	return true
end
distillate:id(T.DISTILLATE)
distillate:register()

local filled = Action()
function filled.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not T.on() or not target or not target.getId then
		return false
	end
	if target:getId() == 21816 then -- tainted glooth capsule
		target:transform(21814)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The converter cleanses the tainted capsule.") -- ours
		return true
	end
	if not table.contains(PURPLE_SLIME, target:getId()) then
		return false
	end
	if T.convertPool(player, toPosition) then
		toPosition:sendMagicEffect(CONST_ME_GREEN_RINGS)
	end
	return true
end
filled:id(T.FILLED)
filled:register()
