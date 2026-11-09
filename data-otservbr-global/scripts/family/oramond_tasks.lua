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
	for name in pairs(T.byCreature) do
		local mType = MonsterType(name)
		if mType then
			mType:registerEvent("FamilyOramondTaskDeath")
			registered = registered + 1
		else
			logger.error("[Family] Oramond tasks: unknown creature {}", name)
		end
	end
	logger.info("[Family] Oramond tasks: kills of {} creatures counted for {} tasks", registered, #T.hunts + 1)
	return true
end

startup:register()
