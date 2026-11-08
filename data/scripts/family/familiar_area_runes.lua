-- Gaia Family server: area runes on your own familiar's square (2026-11-08).
-- Ours, not upstream. How it works: data/scripts/lib/family_familiar_runes.lua.
--
-- When a player's rune reaches its area check, the familiar flag that was
-- switched off for that rune is switched back on right away (instead of
-- waiting for the 1.5 s timer).

if not Family or not Family.areaRunesOnFamiliar then
	return
end

local callback = EventCallback("FamilyFamiliarAreaRunes")

function callback.creatureOnAreaCombat(creature, tile, isAggressive)
	if creature and next(FamilyFamiliarRunes.byPlayer) ~= nil and creature:isPlayer() then
		FamilyFamiliarRunes.restoreForPlayer(creature:getId())
	end
	return RETURNVALUE_NOERROR
end

callback:register()
