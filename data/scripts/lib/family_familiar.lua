-- Gaia Family server: permanent familiars (2026-10-14). Ours, not upstream.
--
-- This file sits in data/scripts/lib so these values exist before the
-- familiar spells in data/scripts/spells/familiar load (each reads them once,
-- marked FAMILY:). The behaviour is in data/scripts/family/familiar.lua.

-- true: a familiar stays until its master says the spell again (or it dies);
-- no 15-minute limit and no cooldown. false = upstream rules.
FAMILY_PERMANENT_FAMILIAR = true

-- Mana cost of each familiar spell, by spell id (filled by the spell files).
FAMILY_FAMILIAR_MANA = {}

-- Called by each familiar spell file with its upstream mana cost. With
-- permanent familiars the spell itself costs nothing (so saying it again to
-- dismiss the familiar is free and works with any amount of mana); the cost is
-- charged by data/scripts/family/familiar.lua only when a familiar appears.
function FamilyFamiliarSpellMana(spellId, mana)
	FAMILY_FAMILIAR_MANA[spellId] = mana
	return FAMILY_PERMANENT_FAMILIAR and 0 or mana
end
