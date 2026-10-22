-- Gaia Family server: Venore Daily Tasks, the parts outside the NPCs (2026-10-21).
-- Ours, not upstream. See data-otservbr-global/lib/others/family_venore_tasks.lua.
--
-- * The hidden mud hole (rock soil south of the ropespot at the southern production
--   site, 33029,32141,7) drops a character with the sabotage task into the closed
--   charlatan cave under it (as in Tibia, the cave has no other way in; the ropespot
--   inside leads back up). Others feel only firm ground.
-- * The can of oil lubricates the saws, cranes and wooden treadmills.
-- * Little Corym Charlatans killed count for the sabotage task (party kills too).
--
-- Switch: Family.venoreDailyTasks (false = no hole, oil or kill counting; the
-- NPCs still talk).

Family = Family or {}
Family.venoreDailyTasks = true

local V = FamilyVenoreTasks

local hole = MoveEvent()

function hole.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.venoreDailyTasks then
		return true
	end
	if V.state(player, "sabotage") ~= V.ACTIVE then
		return true
	end
	player:teleportTo(V.caveEntry)
	V.caveEntry:sendMagicEffect(CONST_ME_POFF)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The mud gives way and you slide down into a cave. Somewhere ahead you hear little charlatans giggling.")
	return true
end

hole:type("stepin")
hole:position(V.hole)
hole:register()

local oil = Action()

function oil.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.venoreDailyTasks then
		return false
	end
	if not target or type(target) ~= "userdata" or not target.isItem or not target:isItem() then
		return false
	end
	local text = V.lubricate(player, toPosition, target:getId())
	if not text then
		return false
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	toPosition:sendMagicEffect(CONST_ME_LOSEENERGY)
	return true
end

oil:id(V.items.oil)
oil:register()

local death = CreatureEvent("FamilyVenoreTaskDeath")

function death.onDeath(creature, corpse, lastHitKiller, mostDamageKiller)
	if not Family.venoreDailyTasks then
		return true
	end
	onDeathForParty(creature, mostDamageKiller, function(_, player)
		V.countKill(player)
	end)
	return true
end

death:register()

local startup = GlobalEvent("FamilyVenoreTaskStartup")

function startup.onStartup()
	local mType = MonsterType(V.creature)
	if mType then
		mType:registerEvent("FamilyVenoreTaskDeath")
	else
		logger.error("[Family] Venore daily tasks: unknown creature {}", V.creature)
	end
	logger.info("[Family] Venore daily tasks: {}", Family.venoreDailyTasks and "on" or "off")
	return true
end

startup:register()
