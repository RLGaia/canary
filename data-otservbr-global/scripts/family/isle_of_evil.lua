-- Gaia Family server: The Isle of Evil Quest, items and map objects (2026-11-27). Ours, not upstream.
-- Rules and sources: data-otservbr-global/lib/others/family_isle_of_evil.lua.
--
-- * The worm punisher on a glowing crucible, the heated punisher on the worms of Scutty's kennel.
-- * The six boss corpses in the castle of the Isle of Evil.
-- * The box with the paper west of Rapanaio.
-- * Startup: the door west of Rapanaio opens only once the quest started, the submarine's gate is level 35,
--   the hole near Northport is closed (dig it), the kennel's worms and crucibles start moving.
-- Rapanaio, his boat, Rapanaio on the island, Scutty, Mortimer, King Tibianus and the mechanical fishing rod
-- call FamilyIsleOfEvil from their own files.
--
-- Switch: Family.isleOfEvil (false = the NPCs and items act as upstream).

Family = Family or {}
Family.isleOfEvil = true

local E = FamilyIsleOfEvil

local punisher = Action()

function punisher.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.isleOfEvil or type(target) ~= "userdata" or not target.isItem or not target:isItem() then
		return false
	end
	if item.itemid == E.punisher then
		return E.heat(player, item, target)
	end
	return E.whack(player, item, target, toPosition)
end

punisher:id(E.punisher, E.heated)
punisher:register()

local corpse = Action()

function corpse.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return E.useCorpse(player, item, fromPosition)
end

for _, id in ipairs(E.corpseIds) do
	corpse:id(id)
end
corpse:register()

local box = Action()

function box.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.isleOfEvil then
		return false
	end
	return E.usePaperBox(player)
end

box:position(E.paperBox)
box:register()

local startup = GlobalEvent("FamilyIsleOfEvilStartup")

function startup.onStartup()
	if Family.isleOfEvil then
		E.setup()
	end
	return true
end

startup:register()
