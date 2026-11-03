-- Gaia Family server: Grimvale Quest, mission "The Curse of the Full Moon":
-- world objects and events (2026-10-28). Ours, not upstream. Story, states
-- and Maeryn's dialogue: lib/others/family_full_moon.lua (FamilyFullMoon).
--
-- Placed at startup (missing on our map):
--   * 3 purple nightshades at TibiaWiki EN's spots (moved to the nearest free
--     square against a wall): 33352,31688,8 / 33314,31638,9 / 33385,31635,9.
--     They bloom (22063 -> 22064) only under the full moon, on Saturdays;
--     each one can be harvested by a character every 30 minutes.
--   * 6 silver veins in the mountain walls of the dungeon's third floor (z10).
--     The silver vein (22075) is the same wall piece as mountain 4464 (same
--     sprite layout and size) with silver in it, so a vein is made by turning
--     a 4464 into 22075 in place: it then looks complete and is the thing a
--     pick hits. Each one has floor south of it that players can walk to
--     from the dungeon entrance. Until 2026-11-02 the veins were added on top
--     of other wall pieces (and two on earth and a ruin wall): they looked
--     broken and the pick hit the stone ("Sorry, not possible."), reported by
--     Rodrigo. A pick on one: about 27% chance of a vial of liquid silver
--     (TibiaWiki EN statistics: 16 of 60), one try every 2 minutes. Called
--     from onUsePick (scripts/lib/register_actions.lua).
-- The full moon, every Saturday (M.isFullMoon, lib/others/family_full_moon.lua;
-- Rodrigo's choice 2026-11-03): six were-creatures walk the Grimvale surface
-- (Tibia had 16 there; 90 s respawn, gone when Saturday ends), the
-- nightshades bloom, the veins can be mined, and Feroxa comes once, after
-- M.feroxaAfterMinutes minutes of play that Saturday (the raid scheduler no
-- longer starts her). Silver veins outside the full moon: TibiaWiki EN message.
-- Feroxa's lair (33377-33405, 31525-31556, z11) has no way in on our map:
-- upstream's full-moon event (globalevents_grimvale_feroxa.lua, now off)
-- rebuilt the hall before it and turned its teleport into the entrance. The
-- raid scheduler spawns Feroxa in the lair; while she is there the hall's
-- teleport (33430,31537,11) takes players who did the Were-Creatures and
-- Moonshadow tasks (TibiaWiki BR) to 33419,31539,10, the stairs room above
-- the lair (way out: the teleport there, as before). Otherwise it keeps its
-- old destination. Feroxa's last form (Feroxa5) completes the mission for
-- the players who hurt her and uses both tasks up.

local M = FamilyFullMoon
local S = Storage.Quest.FamilyFullMoon

local function active()
	return Family.curseOfTheFullMoon ~= false
end

local function msg(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

M.plants = { Position(33352, 31688, 8), Position(33314, 31638, 9), Position(33385, 31635, 9) }
-- walls with mountain piece 4464 and reachable floor to the south (map walk
-- from the Grimvale village); spread over the cave
M.veins = { Position(33397, 31584, 10), Position(33420, 31583, 10), Position(33444, 31590, 10), Position(33412, 31597, 10), Position(33440, 31604, 10), Position(33406, 31608, 10) }
M.plantWait = 30 * 60
M.veinWait = 2 * 60
M.veinChance = 27

local BLOOMING, WILTED, VEIN, VEIN_WALL = 22064, 22063, 22075, 4464

-- Blooming purple nightshades ------------------------------------------------------

local plant = Action()
function plant.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not active() then
		return false
	end
	local pos = item:getPosition()
	for i, p in ipairs(M.plants) do
		if p == pos then
			if player:getStorageValue(S.PlantWait[i]) > os.time() then
				msg(player, "You already harvested this purple nightshade. New blossoms will grow soon.") -- ours
				return true
			end
			player:setStorageValue(S.PlantWait[i], os.time() + M.plantWait)
			player:addItem(M.blossom, 1)
			pos:sendMagicEffect(CONST_ME_MAGIC_BLUE)
			msg(player, "You pick the large blooming blossom from the stem of this purple nightshade.")
			return true
		end
	end
	return false
end
plant:id(BLOOMING)
plant:register()

-- Silver veins: called from onUsePick
function M.onPick(player, target, toPosition)
	if not active() or not toPosition then
		return false
	end
	-- the vein itself, or anything lying on its square (withered plants)
	local isVein = target and target.isItem and target:isItem() and target:getId() == VEIN
	if not isVein then
		local tile = Tile(toPosition)
		if not tile or not tile:getItemById(VEIN) then
			return false
		end
	end
	if not M.isFullMoon() then
		msg(player, "Only in the light of the full moon, these strange veins of unique silver will liquify and be soft enough to be mined.")
		return true
	end
	if player:getStorageValue(S.VeinWait) > os.time() then
		msg(player, "You are still exhausted from earlier attempts. Getting liquid silver out of the mountain needs concentration and a steady hand.")
		return true
	end
	player:setStorageValue(S.VeinWait, os.time() + M.veinWait)
	if math.random(100) > M.veinChance then
		toPosition:sendMagicEffect(CONST_ME_POFF)
		msg(player, "Even after a thorough and frustrating search you could not find enough liquified silver in this vein to fill a flask.")
		return true
	end
	player:addItem(M.vial, 1)
	toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	msg(player, "Carefully you gather some of the liquified silver from this vein in a small flask. You now feel strangely affected to the moon.")
	return true
end

-- Feroxa's lair -------------------------------------------------------------------

M.lairCenter = Position(33391, 31540, 11)
M.hallTeleport = Position(33430, 31537, 11)
M.hallExit = Position(33457, 31531, 11) -- the teleport's own destination on the map
M.lairEntry = Position(33419, 31539, 10)

function M.feroxaPresent()
	for _, c in ipairs(Game.getSpectators(M.lairCenter, false, false, 16, 16, 16, 16)) do
		if c:isMonster() and c:getName():lower() == "feroxa" then
			return true
		end
	end
	return false
end

local hall = MoveEvent()
function hall.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		creature:teleportTo(M.hallExit)
		return true
	end
	if active() and M.feroxaPresent() then
		if M.canEnterLair(player) then
			player:teleportTo(M.lairEntry)
			M.lairEntry:sendMagicEffect(CONST_ME_TELEPORT)
			return true
		end
		msg(player, "Only those who slew fifty were-creatures and performed the ritual in the Moonshadow Temple may face Feroxa.") -- ours
	end
	player:teleportTo(M.hallExit)
	M.hallExit:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end
hall:type("stepin")
hall:position(M.hallTeleport)
hall:register()

-- Were-creature kills ----------------------------------------------------------------

local death = CreatureEvent("FamilyFullMoonKill")
function death.onDeath(creature)
	onDeathForDamagingPlayers(creature, function(_, player)
		-- TibiaWiki BR: no NPC needed, the first kill starts the mission;
		-- after Feroxa, Maeryn has to be asked again first
		if active() and M.state(player) ~= 3 then
			local kills = M.kills(player)
			if kills < M.killsNeeded then
				M.begin(player)
				player:setStorageValue(S.Kills, kills + 1)
				M.checkReady(player)
			end
		end
	end)
	return true
end
death:register()

-- Feroxa's last form
local feroxa = CreatureEvent("FamilyFullMoonFeroxa")
function feroxa.onDeath(creature)
	onDeathForDamagingPlayers(creature, function(_, player)
		if active() then
			M.onFeroxaDefeated(player)
		end
	end)
	return true
end
feroxa:register()

-- Login: the Grimvale Quest entry for characters who started a mission before
-- the shared start storage existed
local login = CreatureEvent("FamilyGrimvaleQuestlineLogin")
function login.onLogin(player)
	local Q = Storage.Quest
	if player:getStorageValue(Q.FamilyGrimvale.Questline) < 1 then
		if player:getStorageValue(Q.FamilyCurseSpreads.Mission) >= 1 or player:getStorageValue(Q.FamilyAncientFeud.Mission) >= 1 or player:getStorageValue(S.Mission) >= 1 then
			FamilyGrimvaleStart(player)
		end
	end
	return true
end
login:register()

-- The Saturday full moon -----------------------------------------------------------

-- the surface creatures: three wereboars and three werebadgers, at six of the
-- old (removed) spawn squares, spread over the island
M.surface = {
	{ name = "Wereboar", pos = Position(33335, 31670, 7) },
	{ name = "Werebadger", pos = Position(33351, 31669, 7) },
	{ name = "Werebadger", pos = Position(33344, 31677, 7) },
	{ name = "Wereboar", pos = Position(33338, 31678, 7) },
	{ name = "Werebadger", pos = Position(33337, 31683, 7) },
	{ name = "Wereboar", pos = Position(33327, 31689, 7) },
}
M.surfaceRespawn = 90 -- seconds, as the old spawns

local moonStore = kv.scoped("family-full-moon")
local wasFullMoon = nil

local function today()
	return os.date("%Y-%m-%d")
end

local function playersOnline()
	for _, player in ipairs(Game.getPlayers()) do
		if not player:getGroup():getAccess() then
			return true
		end
	end
	return false
end

local function alive(spot)
	local creature = spot.id and Creature(spot.id)
	return creature and not creature:isRemoved() and creature:getHealth() > 0 and creature or nil
end

local function setPlants(fullMoon)
	local from, to = fullMoon and WILTED or BLOOMING, fullMoon and BLOOMING or WILTED
	for _, p in ipairs(M.plants) do
		local tile = Tile(p)
		local plantItem = tile and tile:getItemById(from)
		if plantItem then
			plantItem:transform(to)
		end
	end
end

function M.updateSurface(fullMoon)
	local now = os.time()
	for _, spot in ipairs(M.surface) do
		local creature = alive(spot)
		if fullMoon and active() then
			if not creature then
				if spot.id then
					spot.goneAt, spot.id = now, nil -- killed: wait for the respawn
				end
				if not spot.goneAt or now - spot.goneAt >= M.surfaceRespawn then
					local monster = Game.createMonster(spot.name, spot.pos, true, false)
					if monster then
						spot.id, spot.goneAt = monster:getId(), nil
					end
				end
			end
		else
			if creature then
				creature:getPosition():sendMagicEffect(CONST_ME_POFF)
				creature:remove()
			end
			spot.id, spot.goneAt = nil, nil
		end
	end
end

-- once per Saturday, after M.feroxaAfterMinutes minutes with a player online
function M.feroxaTick(fullMoon)
	if not fullMoon or not active() or not playersOnline() then
		return
	end
	local day = today()
	if moonStore:get("feroxa-day") == day then
		return
	end
	if moonStore:get("play-day") ~= day then
		moonStore:set("play-day", day)
		moonStore:set("play-minutes", 0)
	end
	local minutes = (moonStore:get("play-minutes") or 0) + 1
	moonStore:set("play-minutes", minutes)
	if minutes < M.feroxaAfterMinutes or M.feroxaPresent() then
		return
	end
	-- anything but NOERROR: another raid is running; try again next minute
	if Game.startRaid("Feroxa") == RETURNVALUE_NOERROR then
		moonStore:set("feroxa-day", day)
		logger.info("[Family] Full moon: Feroxa raid started")
	end
end

function M.moonTick()
	local fullMoon = M.isFullMoon()
	if fullMoon ~= wasFullMoon then
		setPlants(fullMoon)
		if fullMoon and wasFullMoon ~= nil and active() then
			Game.broadcastMessage("The full moon rises over Grimvale. Were-creatures roam the island, the purple nightshades bloom and the silver veins soften.", MESSAGE_EVENT_ADVANCE) -- ours
		end
		wasFullMoon = fullMoon
	end
	M.updateSurface(fullMoon)
end

local moonThink = GlobalEvent("FamilyFullMoonThink")
function moonThink.onThink(interval)
	M.moonTick()
	return true
end
moonThink:interval(10000)
moonThink:register()

local feroxaMinute = GlobalEvent("FamilyFullMoonFeroxaMinute")
function feroxaMinute.onThink(interval)
	M.feroxaTick(M.isFullMoon())
	return true
end
feroxaMinute:interval(60000)
feroxaMinute:register()

local moonCommand = TalkAction("/fullmoon")
function moonCommand.onSay(player, words, param)
	param = (param or ""):lower():gsub("%s", "")
	if param == "on" then
		Family.fullMoonForced = true
	elseif param == "off" then
		Family.fullMoonForced = false
	elseif param == "auto" then
		Family.fullMoonForced = nil
	elseif param == "feroxa" then -- Feroxa at the next minute (if it is full moon)
		moonStore:set("play-day", today())
		moonStore:set("play-minutes", M.feroxaAfterMinutes)
	end
	M.moonTick()
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Full moon: %s (%s). Play minutes today: %d of %d. Feroxa this Saturday: %s.",
		M.isFullMoon() and "yes" or "no", Family.fullMoonForced == nil and "by weekday, Saturday" or "forced",
		moonStore:get("play-day") == today() and (moonStore:get("play-minutes") or 0) or 0, M.feroxaAfterMinutes,
		moonStore:get("feroxa-day") == today() and "came" or "not yet"))
	return false
end
moonCommand:separator(" ")
moonCommand:groupType("god")
moonCommand:register()

-- Startup ----------------------------------------------------------------------------

local function placeOnce(id, pos)
	local tile = Tile(pos)
	if not tile then
		logger.error("[Family] Full Moon: no tile at {},{},{}", pos.x, pos.y, pos.z)
		return false
	end
	if not tile:getItemById(id) then
		return Game.createItem(id, 1, pos) ~= nil
	end
	return true
end

local startup = GlobalEvent("FamilyFullMoonStartup")
function startup.onStartup()
	local placed = 0
	for _, p in ipairs(M.plants) do
		if placeOnce(M.isFullMoon() and BLOOMING or WILTED, p) then
			placed = placed + 1
		end
	end
	for _, p in ipairs(M.veins) do
		local tile = Tile(p)
		local wall = tile and (tile:getItemById(VEIN) or tile:getItemById(VEIN_WALL))
		if wall then
			if wall:getId() ~= VEIN then
				wall:transform(VEIN)
			end
			placed = placed + 1
		else
			logger.error("[Family] Full Moon: no mountain wall for a silver vein at {},{},{}", p.x, p.y, p.z)
		end
	end
	local tile = Tile(M.hallTeleport)
	local teleport = tile and tile:getItemById(1949)
	if teleport and teleport.setDestination then
		teleport:setDestination(Position(0, 0, 0)) -- the MoveEvent above does the moving
	end
	local lastForm = MonsterType("Feroxa5")
	if lastForm then
		lastForm:registerEvent("FamilyFullMoonFeroxa")
	else
		logger.error("[Family] Full Moon: no monster type Feroxa5")
	end
	for _, name in ipairs(M.wereCreatures) do
		local mType = MonsterType(name)
		if mType then
			mType:registerEvent("FamilyFullMoonKill")
		else
			logger.error("[Family] Full Moon: unknown creature {}", name)
		end
	end
	logger.info("[Family] Curse of the Full Moon: {} nightshades and veins placed, lair teleport {}", placed, teleport and "taken over" or "NOT FOUND")
	return true
end
startup:register()
