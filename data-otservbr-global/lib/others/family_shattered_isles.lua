-- Gaia Family server: The Shattered Isles Quest ("Meriana Quest") fixes (2026-11-17).
--
-- Asked by Rodrigo: "review Meriana Quest, all related items and dialogs". In our TibiaWiki BR
-- backup "Meriana Quest" redirects to "The Shattered Isles Quest" (Eleonore, Meriana's friendship
-- missions, Ray's missions 1-4 and the Pirate Outfit, Voodoo Master/Goroma, Forbidden Islands).
-- Upstream had every NPC, but on our map the quest could not be finished:
--   * the three plans in the Nargor tavern (Ray's Mission 3) are on the map without the unique ids
--     40001-40003 the script waited for: nobody could study them, so no Mission 4, Model Ship or
--     Pirate Outfit;
--   * the seven tortoise's nests behind the Nargor door lack uid 14024 (Duncan's egg);
--   * Marina's sea turtle on Meriana (32340,32537) lacks uid 3206: no ride to the Laguna Islands;
--   * Sebastian's travel keyword "nargor" answered before the quest check: anyone could sail;
--   * the mushroom portal to Talahu never checked the mushrooms and removed the coal basins;
--   * several dialogue dead ends (see FAMILY.md, 2026-11-17).
-- Sources: TibiaWiki BR backup (The Shattered Isles Quest, revid 431740, and its NPC pages),
-- TibiaWiki EN (The Shattered Isles Quest/Spoiler, Ocelus/Transcripts). NPC lines marked "ours"
-- in the NPC files are not in either wiki.
-- Switch: Family.shatteredIsles (false = the plans, nests and Meriana turtle stay dead as upstream,
-- no replacement letter or whisper beer, no ring into the backpack).

Family = Family or {}
Family.shatteredIsles = true

FamilyShatteredIsles = {}
local S = FamilyShatteredIsles

S.kvScope = "family-shattered-isles"

function S.enabled()
	return Family.shatteredIsles ~= false
end

-- Ray's Mission 3: the three plans (item 6118 "treasure map") on the tavern floor (z2).
-- Which one is A, B or C is ours (no wiki names them); the messages are upstream's.
S.plans = {
	{ pos = { x = 31978, y = 32828, z = 2 }, storage = Storage.Quest.U7_8.TheShatteredIsles.TavernMap1, message = "You have sucessfully read plan A." },
	{ pos = { x = 31982, y = 32844, z = 2 }, storage = Storage.Quest.U7_8.TheShatteredIsles.TavernMap2, message = "You have sucessfully read plan B." },
	{ pos = { x = 31992, y = 32847, z = 2 }, storage = Storage.Quest.U7_8.TheShatteredIsles.TavernMap3, message = "You have sucessfully read plan C." },
}

-- Duncan's egg: the tortoise's nests (item 5677) behind the quest door 31934,32838,7.
S.nests = {
	{ x = 31935, y = 32841, z = 7 },
	{ x = 31936, y = 32840, z = 7 },
	{ x = 31938, y = 32837, z = 7 },
	{ x = 31939, y = 32836, z = 7 },
	{ x = 31940, y = 32840, z = 7 },
	{ x = 31941, y = 32838, z = 7 },
	{ x = 31942, y = 32839, z = 7 },
}

-- Marina's sea turtle on Meriana (upstream's uid 3206 entry in turtles.lua).
S.merianaTurtle = { x = 32340, y = 32537, z = 7 }
S.lagunaLanding = { x = 32359, y = 32901, z = 7 }
S.turtleRefused = { x = 32340, y = 32540, z = 7 }

-- Chondur takes the pirate voodoo dolls one at a time (both wikis), five in all.
S.dollItem = 5810
S.dollsNeeded = 5

function S.dollsGiven(player)
	return player:kv():scoped(S.kvScope):get("voodoo-dolls") or 0
end

function S.setDollsGiven(player, count)
	player:kv():scoped(S.kvScope):set("voodoo-dolls", count)
end

-- Chondur's ritual: the 5-minute corpse (upstream) or the fresh one it decays from.
S.ritualCorpses = {
	[1] = { 4330, 6042 }, -- dead chicken
	[2] = { 3994, 5964 }, -- dead rat
	[3] = { 4095, 5994 }, -- dead black sheep
}

function S.takeCorpse(player, step)
	for _, itemId in ipairs(S.ritualCorpses[step]) do
		if player:getItemCount(itemId) > 0 and player:removeItem(itemId, 1) then
			return true
		end
	end
	return false
end

-- Reputation in Sabrehaven (storage ReputationInSabrehaven), as the NPCs use it:
-- 1 Ray sends you around, 2-3 Ariella's bread, 4-6 Ariella's whisper beer, 7-9 Morgan's letter,
-- 10-11 Duncan's atlas, 12 Chondur's dolls, 14 Friendly (13 = the same, upstream's old value),
-- 15 Fafnar's Fire done, 16 catapult burned, 18 Cordial (sabotage reported), 20 Loyal (plans
-- studied), 21 all missions done. Duncan's tortoise egg is a side mission (EN) and no longer
-- changes it (upstream set 16 and could lower it again).
function S.raiseReputation(player, value)
	local key = Storage.Quest.U7_8.TheShatteredIsles.ReputationInSabrehaven
	if player:getStorageValue(key) < value then
		player:setStorageValue(key, value)
	end
end
