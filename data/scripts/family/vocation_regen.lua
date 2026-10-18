-- Gaia Family server: extra regeneration and critical chance by vocation
-- (2026-10-18). Ours, not upstream. Based on Rubinot's VIP bonuses.
--
-- Promoted vocations (Master Sorcerer, Elder Druid, Royal Paladin, Elite
-- Knight, Exalted Monk):
--   +10 hit points and +20 mana every 3 seconds, +3% critical hit chance.
-- Unpromoted vocations (Sorcerer, Druid, Paladin, Knight, Monk): half of it,
--   +5 hit points and +10 mana every 3 seconds, +1.5% critical hit chance.
-- Characters without a vocation get nothing.
--
-- The extra regeneration works only while the character is fed, like the
-- normal one (and, like it, not in protection zones unless the daily reward
-- streak allows it). It is a separate effect, like a ring of healing, so food,
-- the hunger icon and beds work as before. The critical chance is always on and
-- shows in the Skills window (Tibia's base is 5%, so 8% / 6.5%).
--
-- About once a second each character is checked (vocation, fed or not) and the
-- bonuses are added, changed or removed: this covers logging in, a promotion,
-- food running out and eating again.
--
-- Switches: Family.vocationRegen, Family.vocationCritical; values below.

Family = Family or {}
Family.vocationRegen = true
Family.vocationCritical = true

Family.vocationBonus = {
	promoted = { health = 10, mana = 20, ticks = 3000, critical = 300 }, -- critical in 1/100 %: 300 = 3%
	unpromotedShare = 0.5, -- unpromoted vocations get this share of the promoted values
}

local REGEN_SUBID = 7301
local CRITICAL_SUBID = 7302

-- "promoted", "unpromoted" or nil (no vocation)
function Family.vocationTier(player)
	local vocation = player:getVocation()
	if not vocation then
		return nil
	end
	local id, base = vocation:getId(), vocation:getBaseId()
	if base == 0 or id == 0 then
		return nil
	end
	return id ~= base and "promoted" or "unpromoted"
end

-- Values for a tier: health, mana, ticks, critical.
function Family.vocationBonusFor(tier)
	local p = Family.vocationBonus.promoted
	if tier == "promoted" then
		return p.health, p.mana, p.ticks, p.critical
	elseif tier == "unpromoted" then
		local share = Family.vocationBonus.unpromotedShare
		return math.floor(p.health * share + 0.5), math.floor(p.mana * share + 0.5), p.ticks, math.floor(p.critical * share + 0.5)
	end
	return 0, 0, 0, 0
end

local function isFed(player)
	-- the food regeneration (the one without a sub id)
	return player:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT) ~= nil
end

local applied = {} -- player id -> { regen = "key", critical = "key" }

local function setRegen(player, state, key, health, mana, ticks)
	if state.regen == key then
		return
	end
	player:removeCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT, REGEN_SUBID)
	if key ~= "none" then
		local condition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT, REGEN_SUBID)
		condition:setTicks(-1)
		condition:setParameter(CONDITION_PARAM_HEALTHGAIN, health)
		condition:setParameter(CONDITION_PARAM_HEALTHTICKS, ticks)
		condition:setParameter(CONDITION_PARAM_MANAGAIN, mana)
		condition:setParameter(CONDITION_PARAM_MANATICKS, ticks)
		player:addCondition(condition)
	end
	state.regen = key
end

local function setCritical(player, state, key, critical)
	if state.critical == key then
		return
	end
	player:removeCondition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT, CRITICAL_SUBID)
	if key ~= "none" then
		local condition = Condition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT, CRITICAL_SUBID)
		condition:setTicks(-1)
		condition:setParameter(CONDITION_PARAM_SKILL_CRITICAL_HIT_CHANCE, critical)
		player:addCondition(condition)
	end
	state.critical = key
end

function Family.updateVocationBonus(player)
	local id = player:getId()
	local state = applied[id]
	if not state then
		state = {}
		applied[id] = state
	end
	local tier = Family.vocationTier(player)
	local health, mana, ticks, critical = Family.vocationBonusFor(tier)

	local regenKey = "none"
	if Family.vocationRegen and tier and isFed(player) and (health > 0 or mana > 0) then
		regenKey = string.format("%d/%d/%d", health, mana, ticks)
	end
	setRegen(player, state, regenKey, health, mana, ticks)

	local critKey = "none"
	if Family.vocationCritical and tier and critical > 0 then
		critKey = tostring(critical)
	end
	setCritical(player, state, critKey, critical)
end

local think = EventCallback("FamilyVocationBonusThink")

function think.playerOnThink(player, interval)
	Family.updateVocationBonus(player)
end

think:register()

local logout = CreatureEvent("FamilyVocationBonusLogout")

function logout.onLogout(player)
	applied[player:getId()] = nil
	return true
end

logout:register()

local login = CreatureEvent("FamilyVocationBonusLogin")

function login.onLogin(player)
	-- a saved copy of the bonus (if the server kept one) is replaced at the
	-- first check
	applied[player:getId()] = { regen = "?", critical = "?" }
	return true
end

login:register()
