local spell = Spell("instant")
local spellId = 195

function spell.onCastSpell(player, variant)
	return player:CreateFamiliarSpell(spellId)
end

spell:group("support")
spell:id(spellId)
spell:name("Summon Paladin Familiar")
spell:words("utevo gran res sac")
spell:castSound(SOUND_EFFECT_TYPE_SPELL_SUMMON_PALADIN_FAMILIAR)
spell:level(200)
spell:mana(FamilyFamiliarSpellMana(spellId, 2000)) -- FAMILY: charged in data/scripts/family/familiar.lua
spell:cooldown(0) -- calculated in CreateFamiliarSpell
spell:groupCooldown(2 * 1000)

spell:isAggressive(false)
spell:vocation("paladin;true", "royal paladin;true")
spell:register()
