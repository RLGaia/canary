-- Gaia Family server: Dragon Slayer Outfits, the parts outside Big Ben
-- (2026-10-26). Ours, not upstream. Big Ben's dialogue and the requirements are
-- in lib/others/family_dragon_slayer.lua.
--
-- In Tibia two items of the outfit come from content our server lacks:
-- * Bottled dragon breath: only from the Nimmersatt's Lair invasion on Banor's
--   Eye (TibiaWiki BR), a group event every six months that is not on our map
--   or server. Here The First Dragon drops it (Rodrigo's choice): 11.1%, about
--   1 kill in 3 with loot x3.
-- * Albino dragon leather: from the Albino Dragon (13.21), a very rare creature
--   in five dragon lairs (TibiaWiki BR: Dragonblaze Peaks 33149,31270,5, Dragon
--   Lair Ankrahmun 33093,32594,5, Fenrock 32587,31375,15, Hellgorge
--   32090,32560,14, Pits of Inferno 32769,32311,12). Our server had no such
--   creature (monster/dragons/albino_dragon.lua is ours). Here one Albino
--   Dragon lives in each lair, at a random dragon spawn spot of that floor near
--   TibiaWiki's point; a new one appears 30 minutes after it dies (Rodrigo's
--   choice).
-- * The First Dragon quest (needed for Reason to Celebrate, Treasure Hunter and
--   the breath) starts only between January 14 and February 12 in Tibia
--   (Tamoril and the last teleport). Rodrigo chose all year
--   (Family.firstDragonAllYear, FAMILY edits in npc/tamoril.lua and
--   the_first_dragon/movements_last_teleport.lua).

Family = Family or {}
Family.dragonSlayerOutfits = true -- Big Ben's dialogue and the breath on The First Dragon
Family.albinoDragons = true
Family.firstDragonAllYear = true

FamilyAlbino = {
	name = "Albino Dragon",
	respawnMinutes = 30,
	breath = { id = 44179, chance = 11112 }, -- bottled dragon breath on The First Dragon
	-- { lair, z, { {x, y}, ... } }: dragon and dragon lord spawn spots of the
	-- lair's floor within 40 squares of TibiaWiki's point (otservbr-monster.xml).
	lairs = {
		{ "Dragonblaze Peaks", 5, { { 33149, 31270 }, { 33123, 31303 }, { 33133, 31293 }, { 33134, 31305 }, { 33137, 31255 }, { 33144, 31267 }, { 33144, 31309 }, { 33145, 31277 }, { 33147, 31299 }, { 33153, 31271 }, { 33154, 31288 }, { 33159, 31276 }, { 33162, 31264 }, { 33169, 31270 } } },
		{ "Dragon Lair (Ankrahmun)", 5, { { 33093, 32594 }, { 33082, 32593 }, { 33084, 32599 }, { 33088, 32583 }, { 33089, 32594 }, { 33092, 32586 }, { 33092, 32591 }, { 33094, 32595 }, { 33101, 32591 } } },
		{ "Dragon Lair (Fenrock)", 15, { { 32587, 31375 }, { 32555, 31376 }, { 32557, 31358 }, { 32558, 31346 }, { 32562, 31370 }, { 32564, 31379 }, { 32571, 31353 }, { 32574, 31349 }, { 32576, 31340 }, { 32582, 31375 }, { 32586, 31340 }, { 32588, 31362 }, { 32590, 31373 }, { 32592, 31356 }, { 32602, 31370 }, { 32603, 31346 }, { 32612, 31358 }, { 32612, 31377 }, { 32615, 31365 }, { 32618, 31393 }, { 32619, 31342 }, { 32621, 31387 } } },
		{ "Hellgorge", 14, { { 32090, 32560 }, { 32092, 32576 }, { 32102, 32565 } } },
		{ "Dragon Lair (Pits of Inferno)", 12, { { 32769, 32311 }, { 32740, 32347 }, { 32744, 32341 }, { 32745, 32332 }, { 32745, 32351 }, { 32748, 32346 }, { 32755, 32329 }, { 32764, 32330 }, { 32765, 32310 }, { 32767, 32305 }, { 32769, 32327 }, { 32770, 32333 }, { 32771, 32310 }, { 32776, 32336 }, { 32786, 32340 }, { 32788, 32333 }, { 32789, 32325 }, { 32790, 32320 }, { 32790, 32336 }, { 32793, 32306 }, { 32794, 32315 }, { 32796, 32308 }, { 32796, 32339 }, { 32797, 32312 }, { 32801, 32331 }, { 32805, 32345 }, { 32806, 32322 } } },
	},
	alive = {}, -- lair index -> creature id
	diedAt = {}, -- lair index -> os.time() when it was found gone
}

local A = FamilyAlbino

-- Creates the lair's Albino Dragon at a random spot. Returns the monster or nil.
function A.spawn(index)
	local lair = A.lairs[index]
	local spots = {}
	for i, spot in ipairs(lair[3]) do
		spots[i] = spot
	end
	for i = #spots, 2, -1 do
		local j = math.random(i)
		spots[i], spots[j] = spots[j], spots[i]
	end
	for _, spot in ipairs(spots) do
		local monster = Game.createMonster(A.name, Position(spot[1], spot[2], lair[2]), true, false)
		if monster then
			A.alive[index] = monster:getId()
			A.diedAt[index] = nil
			return monster
		end
	end
	logger.warn("[Family] albino dragons: no free spot in {}", lair[1])
	return nil
end

-- One check: notes deaths and spawns where the wait is over.
function A.check(now)
	now = now or os.time()
	for index = 1, #A.lairs do
		local id = A.alive[index]
		if id and not Creature(id) then
			A.alive[index] = nil
			A.diedAt[index] = now
		end
		if not A.alive[index] and now - (A.diedAt[index] or 0) >= A.respawnMinutes * 60 then
			A.spawn(index)
		end
	end
end

local startup = GlobalEvent("FamilyDragonSlayerStartup")

function startup.onStartup()
	if Family.dragonSlayerOutfits then
		-- Now, not in addEvent: the market bot reads the loot in its addEvent(0).
		local firstDragon = MonsterType("The First Dragon")
		if firstDragon then
			firstDragon:createLoot({ { id = A.breath.id, chance = A.breath.chance } })
		else
			logger.error("[Family] dragon slayer: The First Dragon not found, no bottled dragon breath")
		end
	end
	if Family.albinoDragons then
		A.check()
	end
	local alive = 0
	for _ in pairs(A.alive) do
		alive = alive + 1
	end
	logger.info("[Family] dragon slayer outfits: {}, breath on The First Dragon, albino dragons {} ({} of {} lairs), First Dragon all year {}", Family.dragonSlayerOutfits and "on" or "off", Family.albinoDragons and "on" or "off", alive, #A.lairs, Family.firstDragonAllYear and "on" or "off")
	return true
end

startup:register()

local watch = GlobalEvent("FamilyAlbinoDragons")

function watch.onThink(interval)
	if Family.albinoDragons then
		A.check()
	end
	return true
end

watch:interval(60000)
watch:register()
