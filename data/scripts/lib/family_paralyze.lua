-- Gaia Family server: paralysis only slows walking (2026-10-25). Ours, not upstream.
--
-- In Tibia, paralysis only lowers walking speed (TibiaWiki BR "Paralisia",
-- TibiaWiki EN "Slowed"). Canary v3.6.1 adds a "walk exhaust" in C++: while a
-- player is paralyzed, each step (and the paralysis itself, when it hits during
-- a step) blocks spells and runes/potions for the length of that step (three
-- times longer after a diagonal step). Spells are dropped silently; runes and
-- potions answer "You are exhausted." (Player::walkExhausted, checked in
-- Game::playerSaySpell, Game::playerUseItem/UseItemEx/UseWithCreature and
-- Actions::useItem/useItemEx). The check only looks at whether the player has
-- the paralysis condition, and the binary is pinned, so:
--
-- 1. A recvbyte module (data/modules/scripts/family/paralyze.lua, bytes 150 say
--    and 130/131/132 use item) runs just before the server handles a spoken
--    message or the use of a rune or potion. If the player is paralyzed, the
--    paralysis is taken off (copied first, removed with force so it ends at
--    once).
-- 2. The copy is put back as the first thing the spell or item script does
--    (every Spell onCastSpell and Action onUse callback is wrapped below, as
--    this file loads before data/scripts), so healing spells and runes still
--    cure it and haste spells still replace it, exactly as upstream. If no
--    script runs (not enough mana, a talkaction, plain talk), it is put back
--    in the next server cycle.
-- The copy keeps the speed change and the time left; the server sends the speed
-- twice in the same moment, which the client should not show.
--
-- Switch: Family.paralyzeOnlySlows (false = upstream rule).

Family = Family or {}
Family.paralyzeOnlySlows = true

FamilyParalyze = FamilyParalyze or {}
FamilyParalyze.pending = FamilyParalyze.pending or {}

local CONDITION_IDS = { CONDITIONID_COMBAT, CONDITIONID_DEFAULT }

-- Takes the paralysis off a creature for the action that is about to be
-- handled. Returns true when something was taken off.
function FamilyParalyze.lift(creature)
	if not Family.paralyzeOnlySlows or not creature or not creature:hasCondition(CONDITION_PARALYZE) then
		return false
	end
	local cid = creature:getId()
	if FamilyParalyze.pending[cid] then
		return false
	end

	local saved = {}
	for _, conditionId in ipairs(CONDITION_IDS) do
		local condition = creature:getCondition(CONDITION_PARALYZE, conditionId)
		if condition then
			saved[#saved + 1] = condition:clone()
			creature:removeCondition(CONDITION_PARALYZE, conditionId, 0, true)
		end
	end

	-- A paralysis under another id or sub id: give up and keep the upstream rule.
	if #saved == 0 or creature:hasCondition(CONDITION_PARALYZE) then
		for _, condition in ipairs(saved) do
			creature:addCondition(condition)
		end
		return false
	end

	FamilyParalyze.pending[cid] = saved
	addEvent(FamilyParalyze.restoreById, 0, cid)
	return true
end

-- Puts the paralysis back, unless something already gave a new one or a haste
-- (which ends paralysis) in between.
function FamilyParalyze.restore(creature)
	if not creature then
		return
	end
	local cid = creature:getId()
	local saved = FamilyParalyze.pending[cid]
	if not saved then
		return
	end
	FamilyParalyze.pending[cid] = nil
	if creature:hasCondition(CONDITION_PARALYZE) or creature:hasCondition(CONDITION_HASTE) then
		return
	end
	for _, condition in ipairs(saved) do
		creature:addCondition(condition)
	end
end

function FamilyParalyze.restoreById(cid)
	local creature = Creature(cid)
	if creature then
		FamilyParalyze.restore(creature)
	else
		FamilyParalyze.pending[cid] = nil
	end
end

-- Wraps a spell or action callback: the first argument is the caster or user.
function FamilyParalyze.wrapCallback(callback)
	return function(creature, ...)
		if next(FamilyParalyze.pending) ~= nil and creature and type(creature) == "userdata" then
			FamilyParalyze.restore(creature)
		end
		return callback(creature, ...)
	end
end

local function wrapMethod(class, method)
	local original = class and class[method]
	if not original or FamilyParalyze["wrapped" .. method] then
		return
	end
	FamilyParalyze["wrapped" .. method] = true
	class[method] = function(self, callback)
		if type(callback) == "function" then
			callback = FamilyParalyze.wrapCallback(callback)
		end
		return original(self, callback)
	end
end

wrapMethod(Spell, "onCastSpell")
wrapMethod(Action, "onUse")
