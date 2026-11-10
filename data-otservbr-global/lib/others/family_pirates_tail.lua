-- Gaia Family server: A Pirate's Tail Quest, part 1 - Eustacio and the Pirat raids (2026-11-10).
-- Ours, not upstream: Canary v3.6.1 has Eustacio without his mission, no Pirat raids, no
-- quest log. Sources: TibiaWiki BR quest page and Eustacio page (first), TibiaWiki EN spoiler
-- (raid places, points per action, end messages) and the Pied Piper page. Lines marked "ours"
-- are not from the wikis.
--
-- QuestLine (Storage.Quest.U12_60.APiratesTail.QuestLine):
--   1 Eustacio: "mission" accepted - fight the Pirat raids, 1500 points
--   2 Eustacio told the secret passage below Kilmaresh (status with 1500 points)
-- Points (RaidPoints): during a raid, each spyrat attacked 5, each pirat attacked 3 (EN), loading,
-- lighting and firing a catapult 2 each (EN); at most 300 per raid (BR "Pontuação máxima").
-- After the secret (QuestLine 2), pirats killed anywhere give 3 points too (EN Pied Piper: "hunt
-- Pirats under Rascacoon or on The Wreckoning after getting access"; 3 is ours, as in the raids).
-- Pied Piper: greeting Eustacio with 5000 points (EN; BR says 1000 pirats killed).
-- Raids: scripts/family/pirat_raids.lua.
-- Switch: Family.piratesTail (false = Eustacio as upstream, no raids).

Family = Family or {}
Family.piratesTail = true

FamilyPiratesTail = FamilyPiratesTail or {}
local PT = FamilyPiratesTail
local S = Storage.Quest.U12_60.APiratesTail

PT.S = S
PT.NEEDED = 1500
PT.PIED_PIPER = 5000
PT.RAID_CAP = 300
PT.ITEM_COOLDOWN = 30 * 60 -- BR: flintstone and orb every 30 minutes

PT.FLINTSTONE = 35337
PT.ORB = 35376
PT.BOULDER = 35336
PT.shipTemplate = dofile(DATA_DIRECTORY .. "/lib/others/family_pirat_ship.lua")

function PT.enabled()
	return Family.piratesTail == true
end

function PT.questLine(player)
	return math.max(0, player:getStorageValue(S.QuestLine))
end

function PT.points(player)
	return math.max(0, player:getStorageValue(S.RaidPoints))
end

-- Points from a raid (serial = the raid's start time) or, with raidSerial nil, from hunting.
function PT.addPoints(player, amount, raidSerial)
	if not PT.enabled() or amount <= 0 or PT.questLine(player) < 1 then
		return 0
	end
	if raidSerial then
		if player:getStorageValue(S.RaidSerial) ~= raidSerial then
			player:setStorageValue(S.RaidSerial, raidSerial)
			player:setStorageValue(S.RaidCredit, 0)
		end
		local credit = math.max(0, player:getStorageValue(S.RaidCredit))
		amount = math.min(amount, PT.RAID_CAP - credit)
		if amount <= 0 then
			return 0
		end
		player:setStorageValue(S.RaidCredit, credit + amount)
	elseif PT.questLine(player) < 2 then
		return 0
	end
	player:setStorageValue(S.RaidPoints, PT.points(player) + amount)
	return amount
end

-- Raid places (EN spoiler coordinates and descriptions). center = the EN spot; ship = where the
-- ship is looked for (top-left of its hull, searched nearby); catapults = where the two catapults
-- are looked for (the west square of each); the squares are checked when the raid starts.
PT.places = {
	{
		key = "krailos",
		name = "east of Krailos", -- EN
		center = Position(33715, 31707, 7),
		ship = { 33719, 31707 },
		catapults = { { 33708, 31711 }, { 33709, 31717 } },
	},
	{
		key = "thais",
		name = "east of Thais, just east of the Bloodhall", -- EN
		center = Position(32489, 32177, 7),
		ship = { 32482, 32183 },
		catapults = { { 32484, 32179 }, { 32489, 32181 } },
	},
	{
		key = "darashia",
		name = "east of Darashia", -- EN
		center = Position(33318, 32419, 7),
		ship = { 33325, 32412 },
		catapults = { { 33316, 32413 }, { 33317, 32419 } },
	},
	{
		key = "porthope",
		name = "north-west of Port Hope", -- EN
		center = Position(32535, 32731, 7),
		ship = { 32524, 32725 },
		catapults = { { 32535, 32727 }, { 32537, 32734 } },
	},
	{
		key = "libertybay",
		name = "north of Liberty Bay", -- EN
		center = Position(32224, 32695, 7),
		ship = { 32213, 32688 },
		catapults = { { 32228, 32690 }, { 32228, 32697 } },
	},
}

-- The raid that is running now (set by pirat_raids.lua): { place = <entry>, kind = "spyrats" | "ship" | "land", serial = n }
PT.current = nil

function PT.describe(player)
	local line = PT.questLine(player)
	local points = PT.points(player)
	if line >= 2 then
		return string.format("Eustacio told you about a secret passage below Kilmaresh. The entrance is on the coast next to the temple of Issavi: use a certain shell lying in the sand. Your score with Eustacio: %d points.", points) -- ours
	end
	return string.format("Eustacio in Venore wants to weaken the Pirats who attack the cities and coasts of Tibia. Ask him about the location of their raids and fight them. He will tell you more once you reach %d points. Your score: %d points.", PT.NEEDED, points) -- ours
end
