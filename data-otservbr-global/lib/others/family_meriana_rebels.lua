-- Gaia Family server: Meriana Rebels (Ray's pirate task) and the Pirate Outfit addons (2026-11-17).
--
-- Asked by Rodrigo: review The Shattered Isles Quest with its items and dialogs; these two parts
-- were left from the first review. Sources: our TibiaWiki BR backup ("Meriana Rebels: Pirates
-- Quest", "Pirate Outfits Quest", "Invasões em Liberty Bay", the pirate leaders' pages) and
-- TibiaWiki EN (Killing in the Name of... Quest, Pirate Outfits Quest, Vandura Raids, Liberty Bay
-- Libraries, its talk page: "the door is sealed now").
--   * The sealed door in the Nargor tavern (31973,32847,2) was an ordinary door: anyone could walk
--     into the pirate leaders' hideout corridor. BR: Ray's report gives "permission to pass the
--     sealed door"; now it opens only while Ray's permission is unused or the hideout visit is not
--     yet reported (task states 1 and 2), and always from the hideout side, so nobody is shut in.
--     The refusal is the usual sealed-door message of quest doors.
--   * A quest chest in the leaders' boss room (31981,32893,0, action id 2000, uid 9283) gave every
--     character Ron the Ripper's sabre, Deadeye Devious' eye patch and Brutus Bloodbeard's hat; both
--     wikis: these come only as the leaders' loot. It now says the quest chests' "The chest is empty."
--   * Swashbuckler (BR: given on completing both pirate addons) was given by no script.
-- Switch: Family.merianaRebels (false = the door is an ordinary door again, the chest gives its
-- three items, no Swashbuckler).
-- The other fixes (boss teleporter, Duncan's lines, the Liberty Bay pirate raids) are in the
-- upstream files and raids.xml, marked FAMILY.

Family = Family or {}
Family.merianaRebels = true

FamilyMerianaRebels = {}
local M = FamilyMerianaRebels

function M.enabled()
	return Family.merianaRebels ~= false
end

M.hideoutDoor = { x = 31973, y = 32847, z = 2 }
-- The corridor to the hideout is west of the door (checked on our map: it has no other way out).
M.hideoutSideMaxX = 31972
M.closedDoor = 5281
M.openDoor = 5282
M.sealedText = "The door seems to be sealed against unwanted intruders."
M.bossRoomChest = { x = 31981, y = 32893, z = 0 }

-- Ray's task storage: 1 = report made, hideout open; 2 = went through the teleporter, not yet
-- reported (needed to walk out again after the fight).
function M.mayPass(player)
	local state = player:getStorageValue(Storage.Quest.U8_5.KillingInTheNameOf.PirateTask)
	return state == 1 or state == 2
end

function M.isInside(position)
	return position.x <= M.hideoutSideMaxX
end

-- Both pirate addons (sabre from Morgan, hat from Ariella): Swashbuckler (BR, EN).
function M.checkSwashbuckler(player)
	if not M.enabled() then
		return false
	end
	if player:hasOutfit(151, 3) or player:hasOutfit(155, 3) then
		player:addAchievement("Swashbuckler")
		return true
	end
	return false
end
