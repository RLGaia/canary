-- Gaia Family server: paralysis only slows walking (2026-10-25). Ours, not upstream.
-- The work is in data/scripts/lib/family_paralyze.lua (loaded before the
-- spells and actions it wraps) and the module
-- data/modules/scripts/family/paralyze.lua. This file only reports the switch.

local report = GlobalEvent("FamilyParalyzeReport")

function report.onStartup()
	logger.info("[Family] paralysis only slows walking={}, spell and item callbacks wrapped={}", tostring(Family.paralyzeOnlySlows), tostring(FamilyParalyze and FamilyParalyze.wrappedonCastSpell and FamilyParalyze.wrappedonUse or false))
	return true
end

report:register()
