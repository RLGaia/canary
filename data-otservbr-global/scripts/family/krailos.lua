-- Gaia Family server: Krailos Quest, world objects (2026-11-22). Ours, not upstream.
-- Rules, messages and talk: lib/others/family_krailos.lua (FamilyKrailos).
-- Elsewhere: the skull orchid (Explorer Society botanist's container script) and Larek's grille
-- (scripts/quests/krailos/movements_access_depot.lua).

local K = FamilyKrailos

-- Hungry New World: the sarcophagus in the Nightmare room holds the ancient map. Other uses do
-- what they did before (return false).
local sarcophagus = Action()
function sarcophagus.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return K.useSarcophagus(player)
end
for _, pos in ipairs(K.SARCOPHAGUS) do
	sarcophagus:position(pos)
end
sarcophagus:register()

-- Hungry New World: the thieving steppe bird's nest south of the village.
local nest = Action()
function nest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return K.useBirdNest(player)
end
nest:position(K.BIRD_NEST)
nest:register()
