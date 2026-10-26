-- Gaia Family server: Cartography 101 Quest (2026-10-26). Ours, not upstream.
--
-- TibiaWiki BR/EN ("Cartography 101 Quest", Adventurers' Guild): Rotem Valos
-- gives an adventurer's map (map, yes) and a list of uncharted places; the
-- player uses the map at each of them in any order, then tells Rotem (map) and
-- gets the achievement "Cartography 101". If the map is lost, Rotem gives
-- another one (lost). Upstream had the item, the achievement and Rotem's "work"
-- line, but no quest.
--
-- Tibia has 18 places. The Chakoya Iceberg exists only during its mini world
-- change, which our map and server do not have, so 17 are needed here (the
-- Vandura Hive Outpost, also a mini world change in Tibia, is on our map). Each
-- place is a box on one floor (or two), drawn on our map from TibiaWiki BR's
-- coordinates and both wikis' descriptions (floor, landmark: altar, fire
-- shrine, cauldron, lizard statue, blood pools, water source...). The boxes are
-- generous, so the map works anywhere in that room or level. Messages for using
-- the map are ours (TibiaWiki gives none).

Family = Family or {}
Family.cartography101 = true

FamilyCartography = {
	mapItem = 22107, -- adventurer's map
	achievement = "Cartography 101",
	-- { name, hint for Rotem's list, boxes {x0, y0, x1, y1, z} }
	places = {
		{ "the Desert Scarab Lair", "the altar hall at the bottom of the Daramian scarab lair north of Ankrahmun", { { 33212, 32505, 33285, 32545, 12 } } },
		{ "the Forbidden Sanctuary", "the second level below the Forbidden Temple east of Ankrahmun (dig the hole under the palm leaf)", { { 33305, 32668, 33350, 32703, 9 } } },
		{ "the Scarab Lair in the Mountains", "the scarab lair in the Kha'zeel Mountains, two or three levels down, near the stairs", { { 33070, 32526, 33092, 32541, 9 }, { 33060, 32519, 33100, 32540, 10 } } },
		{ "the Dryad Gardens", "the top of the hill in the Dryad Gardens, by the water source (the mysterious pond south-west of Cormaya leads there)", { { 33244, 32021, 33257, 32031, 9 } } },
		{ "the Lair of the Treeling Witch", "the cauldron under the great tree in the treeling dungeon north-east of Cormaya, one level down", { { 33315, 31939, 33329, 31953, 8 } } },
		{ "the Blood Shrine", "the chamber full of blood pools deep below the vampire crypts north-west of Edron", { { 33158, 31743, 33222, 31776, 12 } } },
		{ "Grimvale", "Grimvale itself (Cornell in Stonehome takes you there)", { { 33320, 31662, 33362, 31700, 7 } } },
		{ "the Old Fortress", "the ruins of the hero fortress north of Edron", { { 33207, 31649, 33231, 31673, 7 } } },
		{ "the Swamp of Lost Souls", "the centre of the cave below the Gloom Caverns in the Green Claw Swamp, one level down", { { 32698, 31918, 32728, 31942, 8 } } },
		{ "the Corym Black Market", "the fourth level below the slums of Liberty Bay, south-west of the stairs", { { 32259, 32807, 32275, 32823, 11 } } },
		{ "the Quara Grotto", "the first level of the Vandura quara caves south-west of Liberty Bay", { { 32193, 32878, 32220, 32899, 8 } } },
		{ "the Hive Outpost", "the entrance of the insect tower west of the quara grotto, south-west of Liberty Bay", { { 32158, 32828, 32175, 32845, 6 }, { 32158, 32828, 32175, 32845, 7 } } },
		{ "the Asura Palace", "the first floor of the Asura Palace north-east of Port Hope, up the stairs", { { 32932, 32673, 32965, 32692, 6 } } },
		{ "the Dragon Caves", "the fire shrine one floor up in the Kha'zeel dragon lairs north-east of the Asura Palace", { { 33062, 32648, 33080, 32664, 6 } } },
		{ "the Medusa Tower", "the ground floor inside the Medusa Tower in the south of Tiquanda (through the tunnel)", { { 32857, 32820, 32880, 32842, 7 } } },
		{ "the Spider Caves", "the room with the muddy water and the lizard statue in the Tiquanda spider caves", { { 32842, 32857, 32878, 32873, 8 } } },
		{ "the Water Elemental Caverns", "the first level of the water elemental caves south of Port Hope", { { 32660, 32962, 32700, 32990, 8 } } },
	},
}

local F = FamilyCartography
local S = Storage.Quest.FamilyCartography

function F.state(player)
	return player:getStorageValue(S.Mission)
end

function F.mask(player)
	return math.max(0, player:getStorageValue(S.Charted))
end

function F.isCharted(player, index)
	return math.floor(F.mask(player) / 2 ^ (index - 1)) % 2 == 1
end

function F.count(player)
	local n = 0
	for i = 1, #F.places do
		if F.isCharted(player, i) then
			n = n + 1
		end
	end
	return n
end

-- The place whose box holds pos, or nil.
function F.placeAt(pos)
	for i, place in ipairs(F.places) do
		for _, b in ipairs(place[3]) do
			if pos.z == b[5] and pos.x >= b[1] and pos.x <= b[3] and pos.y >= b[2] and pos.y <= b[4] then
				return i
			end
		end
	end
	return nil
end

function F.start(player)
	player:setStorageValue(S.Mission, 1)
	if player:getStorageValue(S.Charted) < 0 then
		player:setStorageValue(S.Charted, 0)
	end
	if player:getStorageValue(Storage.Quest.U9_80.AdventurersGuild.QuestLine) < 1 then
		player:setStorageValue(Storage.Quest.U9_80.AdventurersGuild.QuestLine, 1) -- shows "Adventurers Guild" in the quest log
	end
end

-- Names of the places still to chart.
function F.missing(player)
	local out = {}
	for i, place in ipairs(F.places) do
		if not F.isCharted(player, i) then
			out[#out + 1] = place
		end
	end
	return out
end

function F.describe(player)
	if F.state(player) >= 2 then
		return "You charted all the places on Rotem Valos' list and earned the title of a true cartographer."
	end
	local n = F.count(player)
	if n >= #F.places then
		return "You charted all the places on Rotem Valos' list. Show him your map in the Adventurers' Guild."
	end
	return string.format("Rotem Valos in the Adventurers' Guild gave you a map to chart unexplored places of Tibia. Use it at each place on his list. Charted: %d of %d.", n, #F.places)
end

-- Using the map. Returns the message shown (also for tests).
function F.use(player, pos)
	if F.state(player) < 1 then
		return "This map shows various locations of Tibia above and below sea level. The Adventurers' Guild might know what to do with it."
	end
	local index = F.placeAt(pos)
	if not index then
		return "Nothing here is missing on your map."
	end
	local name = F.places[index][1]
	if F.isCharted(player, index) then
		return string.format("You already charted %s.", name)
	end
	player:setStorageValue(S.Charted, F.mask(player) + 2 ^ (index - 1))
	pos:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	local n = F.count(player)
	if n >= #F.places then
		return string.format("You chart %s on your map. That was the last place on the list! Show your map to Rotem Valos in the Adventurers' Guild.", name)
	end
	return string.format("You chart %s on your map (%d of %d).", name, n, #F.places)
end

-- Rotem's reward. True when given now.
function F.finish(player)
	if F.state(player) ~= 1 or F.count(player) < #F.places then
		return false
	end
	player:setStorageValue(S.Mission, 2)
	player:addAchievement(F.achievement)
	return true
end

local mapAction = Action()

function mapAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.cartography101 then
		return false
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, F.use(player, player:getPosition()))
	return true
end

mapAction:id(F.mapItem)
mapAction:register()
