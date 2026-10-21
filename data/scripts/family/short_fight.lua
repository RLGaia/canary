-- Gaia Family server: the battle icon ends with the fight (2026-10-20). Ours,
-- not upstream.
--
-- Asked by Rodrigo. Upstream the battle icon (in fight) stays for pzLocked
-- (60 s) after the last hit, given or taken. Here it ends as soon as no enemy
-- is left near you: no hostile creature on your screen (same floor), and no
-- creature anywhere near that is attacking you. Kill the last monster and the
-- icon goes away within a second. A PZ lock (red, after attacking a player)
-- is not touched.
--
-- Matters for the adventurer's stone (it cannot be used during a fight) and
-- anything else the server refuses while the battle icon is shown.
--
-- Switch: Family.shortFight (false = upstream 60 s).

Family = Family or {}
Family.shortFight = true

local RANGE_X, RANGE_Y = 8, 6 -- the game screen around you

local function isEnemy(creature, player)
	local monster = creature:getMonster()
	if not monster then
		return false
	end
	local master = monster:getMaster()
	if master and master:getPlayer() then
		return false -- summons and familiars of players
	end
	local target = monster:getTarget()
	if target and target:getId() == player:getId() then
		return true
	end
	local mType = monster:getType()
	return mType and mType:isHostile() or false
end

function Family.enemyNearby(player)
	local spectators = Game.getSpectators(player:getPosition(), false, false, RANGE_X, RANGE_X, RANGE_Y, RANGE_Y)
	for _, creature in ipairs(spectators) do
		if isEnemy(creature, player) then
			return true
		end
	end
	return false
end

function Family.endFightIfClear(player)
	if not Family.shortFight or player:isPzLocked() then
		return false
	end
	if not player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT) then
		return false
	end
	if Family.enemyNearby(player) then
		return false
	end
	player:removeCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT)
	return true
end

local think = EventCallback("FamilyShortFightThink")

function think.playerOnThink(player, interval)
	Family.endFightIfClear(player)
end

think:register()

local report = GlobalEvent("FamilyShortFightReport")

function report.onStartup()
	logger.info("[Family] battle icon: {} (ends when no enemy is near; otherwise {} s)", Family.shortFight and "short" or "upstream", configManager.getNumber(configKeys.PZ_LOCKED) / 1000)
	return true
end

report:register()
