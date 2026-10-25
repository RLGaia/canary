-- Gaia Family server: Top of the City Quest (2026-10-25). Ours, not upstream.
--
-- TibiaWiki ("Top of the City Quest", Tibia Tales): a masked man stole
-- Iriana's day's earnings in the Trade Quarter of Yalahar and fled over the
-- rooftops. The player follows a White Assassin who shows himself for a moment
-- and vanishes, from her roof (stairs next to her) along the roofs to the
-- south, up a ladder and over the bridges, down at the end, past two Bandits
-- and through a sealed door to Jimmy. The first time Jimmy is greeted he calls
-- three Assassins. He wants a crate of food from the cellar of Pugwah's tavern
-- (reached by digging the dirt spot in the sewer, then a rope up) and gives
-- Iriana's chest for it. Iriana pays 10 heaven blossoms.
--
-- Upstream had Iriana (shop only) and Jimmy's NPC file (not spawned), the map
-- (roofs, bridges, the dig spot with action id 101, the tunnel and the cellar)
-- but no quest. Built here:
--   * the White Assassin flashes for about 1.5 seconds at ten points along a
--     walkable roof route (checked on the map), each time a quest holder comes
--     near the previous point. Tibia's wrong-side-of-the-bridge dead ends are
--     not reproduced (no source says which squares do it): chosen by Rodrigo.
--   * Jimmy's pier door (quest door 5289, 32858,31374,6) gets the mission
--     storage as action id: only players who started the quest pass.
--   * a rope spot at the tunnel end under the cellar (no rope spot there on
--     our map), the cellar crates give one food crate during mission 2, and the
--     closed trapdoor in the cellar floor leads back down into the tunnel
--     (the tavern trapdoor upstairs opens into Pugwah's closed counter area).
-- Dialogue in npc/iriana.lua and npc/jimmy.lua. Jimmy spawns on the pier.

Family = Family or {}
Family.topOfTheCity = true

FamilyTopOfTheCity = {
	foodCrate = 8772,
	irianaChest = 8773,
	heavenBlossom = 5921, -- the one creatures drop
	rewardCount = 10,
	door = { id = 5289, pos = Position(32858, 31374, 6) },
	ropeSpot = { pos = Position(32811, 31250, 9), ground = 386 },
	crateActionId = 48732,
	crates = {
		Position(32807, 31250, 8),
		Position(32808, 31250, 8),
		Position(32807, 31251, 8),
		Position(32807, 31252, 8),
	},
	cellarTrapdoor = { id = 475, pos = Position(32810, 31253, 8), actionId = 48733, exit = Position(32811, 31251, 9) },
	assassinName = "White Assassin",
	assassinMs = 1500,
	nearRange = 3, -- squares from a trigger point (same floor)
	repeatSeconds = 20, -- per player and point
	-- trigger -> where he shows himself (about 7 squares further on the route)
	waypoints = {
		{ Position(32845, 31299, 6), Position(32838, 31305, 6) },
		{ Position(32838, 31305, 6), Position(32842, 31311, 6) },
		{ Position(32842, 31311, 6), Position(32851, 31313, 6) },
		{ Position(32851, 31313, 6), Position(32857, 31320, 6) },
		{ Position(32857, 31320, 6), Position(32853, 31328, 6) },
		{ Position(32853, 31328, 6), Position(32852, 31333, 6) }, -- at the ladder up
		{ Position(32854, 31332, 5), Position(32858, 31339, 5) },
		{ Position(32858, 31339, 5), Position(32858, 31347, 5) },
		{ Position(32858, 31347, 5), Position(32858, 31355, 5) },
		{ Position(32858, 31355, 5), Position(32855, 31362, 5) }, -- next to the trapdoor down
	},
	jimmyAssassins = 3,
	shown = {}, -- [playerId] = { [waypoint] = os.time() }
}

local F = FamilyTopOfTheCity
local S = Storage.Quest.FamilyTopOfTheCity

function F.state(player)
	return player:getStorageValue(S.Mission)
end

function F.setState(player, value)
	player:setStorageValue(S.Mission, value)
	if player:getStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart) < 1 then
		player:setStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart, 1) -- shows "Tibia Tales" in the quest log
	end
end

-- Mission 3 -> 4: takes the chest, pays the heaven blossoms. False without the chest.
function F.finish(player)
	if player:getItemCount(F.irianaChest) < 1 or not player:removeItem(F.irianaChest, 1) then
		return false
	end
	player:addItem(F.heavenBlossom, F.rewardCount)
	F.setState(player, 4)
	return true
end

-- Mission 2 -> 3: takes the food crate, gives Iriana's chest. False without the crate.
function F.tradeCrate(player)
	if player:getItemCount(F.foodCrate) < 1 or not player:removeItem(F.foodCrate, 1) then
		return false
	end
	player:addItem(F.irianaChest, 1)
	F.setState(player, 3)
	return true
end

-- Jimmy's three Assassins, the first time he is greeted.
function F.callAssassins(npc, player)
	if player:getStorageValue(S.AssassinsCalled) == 1 then
		return false
	end
	player:setStorageValue(S.AssassinsCalled, 1)
	local around = player:getPosition()
	for _ = 1, F.jimmyAssassins do
		local monster = Game.createMonster("Assassin", around, true, false)
		if monster then
			monster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		end
	end
	return true
end

-- The White Assassin shows himself at pos, then vanishes.
function F.flash(pos)
	local monster = Game.createMonster(F.assassinName, pos, false, true)
	if not monster then
		return false
	end
	local id = monster:getId()
	addEvent(function()
		local m = Monster(id)
		if m then
			m:getPosition():sendMagicEffect(CONST_ME_POFF)
			m:remove()
		end
	end, F.assassinMs)
	return true
end

-- One check: every quest holder near a trigger point sees the next flash.
function F.check(players, now)
	local count = 0
	for _, player in ipairs(players) do
		if F.state(player) == 1 then
			local pos = player:getPosition()
			local id = player:getId()
			F.shown[id] = F.shown[id] or {}
			for i, wp in ipairs(F.waypoints) do
				local t = wp[1]
				if pos.z == t.z and math.max(math.abs(pos.x - t.x), math.abs(pos.y - t.y)) <= F.nearRange then
					local last = F.shown[id][i]
					if not last or now - last >= F.repeatSeconds then
						F.shown[id][i] = now
						if F.flash(wp[2]) then
							count = count + 1
						end
					end
				end
			end
		end
	end
	return count
end

-- White Assassin: a harmless look-alike of the Assassin in white.
do
	local mType = Game.createMonsterType(F.assassinName)
	local monster = {}
	monster.description = "a white assassin"
	monster.experience = 0
	monster.outfit = { lookType = 152, lookHead = 0, lookBody = 0, lookLegs = 0, lookFeet = 0, lookAddons = 3, lookMount = 0 }
	monster.health = 10000
	monster.maxHealth = 10000
	monster.race = "blood"
	monster.corpse = 0
	monster.speed = 0
	monster.manaCost = 0
	monster.changeTarget = { interval = 4000, chance = 0 }
	monster.strategiesTarget = { nearest = 100 }
	monster.flags = {
		summonable = false,
		attackable = false,
		hostile = false,
		convinceable = false,
		pushable = false,
		rewardBoss = false,
		illusionable = false,
		canPushItems = false,
		canPushCreatures = false,
		staticAttackChance = 100,
		targetDistance = 1,
		runHealth = 0,
		healthHidden = true,
		isBlockable = false,
		canWalkOnEnergy = false,
		canWalkOnFire = false,
		canWalkOnPoison = false,
	}
	monster.light = { level = 0, color = 0 }
	monster.voices = { interval = 5000, chance = 0 }
	monster.loot = {}
	monster.attacks = {}
	monster.defenses = { defense = 0, armor = 0, mitigation = 0 }
	monster.elements = {}
	monster.immunities = {}
	mType:register(monster)
end

local startup = GlobalEvent("FamilyTopOfTheCityStartup")

function startup.onStartup()
	if not Family.topOfTheCity then
		return true
	end
	local done = {}
	local tile = Tile(F.door.pos)
	local door = tile and tile:getItemById(F.door.id)
	if door then
		door:setActionId(S.Mission)
		done[#done + 1] = "door"
	end
	tile = Tile(F.ropeSpot.pos)
	local ground = tile and tile:getGround()
	if ground then
		if ground:getId() ~= F.ropeSpot.ground then
			ground:transform(F.ropeSpot.ground)
		end
		done[#done + 1] = "rope spot"
	end
	local crates = 0
	for _, pos in ipairs(F.crates) do
		tile = Tile(pos)
		local crate = tile and tile:getItemById(8771)
		if crate then
			crate:setActionId(F.crateActionId)
			crates = crates + 1
		end
	end
	done[#done + 1] = crates .. " crates"
	tile = Tile(F.cellarTrapdoor.pos)
	local trapdoor = tile and tile:getItemById(F.cellarTrapdoor.id)
	if trapdoor then
		trapdoor:setActionId(F.cellarTrapdoor.actionId)
		done[#done + 1] = "cellar trapdoor"
	end
	logger.info("[Family] Top of the City: " .. table.concat(done, ", "))
	return true
end

startup:register()

local watcher = GlobalEvent("FamilyTopOfTheCityWatcher")

function watcher.onThink(interval)
	if Family.topOfTheCity then
		F.check(Game.getPlayers(), os.time())
	end
	return true
end

watcher:interval(500)
watcher:register()

local crateAction = Action()

function crateAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if F.state(player) ~= 2 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "These crates belong to Pugwah. You have no reason to touch them.")
		return true
	end
	if player:getItemCount(F.foodCrate) > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already carry a crate of food for Jimmy.")
		return true
	end
	local crate = player:addItem(F.foodCrate, 1)
	if not crate then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cannot carry the crate. It weighs 100 oz.")
		return true
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take a crate of food from Pugwah's stock.")
	return true
end

crateAction:aid(F.crateActionId)
crateAction:register()

local trapdoorAction = Action()

function trapdoorAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:teleportTo(F.cellarTrapdoor.exit)
	F.cellarTrapdoor.exit:sendMagicEffect(CONST_ME_POFF)
	return true
end

trapdoorAction:aid(F.cellarTrapdoor.actionId)
trapdoorAction:register()

local logout = CreatureEvent("FamilyTopOfTheCityLogout")

function logout.onLogout(player)
	F.shown[player:getId()] = nil
	return true
end

logout:register()
