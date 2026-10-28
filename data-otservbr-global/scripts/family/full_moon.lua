-- Gaia Family server: Grimvale Quest, mission "The Curse of the Full Moon":
-- world objects and events (2026-10-28). Ours, not upstream. Story, states
-- and Maeryn's dialogue: lib/others/family_full_moon.lua (FamilyFullMoon).
--
-- Placed at startup (missing on our map):
--   * 3 blooming purple nightshades at TibiaWiki EN's spots (moved to the
--     nearest free square against a wall): 33352,31688,8 / 33314,31638,9 /
--     33385,31635,9. Always blooming (Rodrigo's choice); each one can be
--     harvested by a character every 30 minutes (TibiaWiki EN).
--   * 6 silver veins on the walls of the dungeon's third floor (z10). A pick
--     on one: about 27% chance of a vial of liquid silver (TibiaWiki EN
--     statistics: 16 of 60), one try every 2 minutes. Called from onUsePick
--     (scripts/lib/register_actions.lua).
-- Feroxa's lair (33377-33405, 31525-31556, z11) has no way in on our map:
-- upstream's full-moon event (globalevents_grimvale_feroxa.lua, now off)
-- rebuilt the hall before it and turned its teleport into the entrance. The
-- raid scheduler spawns Feroxa in the lair; while she is there the hall's
-- teleport (33430,31537,11) takes players who finished Maeryn's part to
-- 33419,31539,10, the stairs room above the lair (way out: the teleport
-- there, as before). Otherwise it keeps its old destination.

local M = FamilyFullMoon
local S = Storage.Quest.FamilyFullMoon

local function active()
	return Family.curseOfTheFullMoon ~= false
end

local function msg(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

M.plants = { Position(33352, 31688, 8), Position(33314, 31638, 9), Position(33385, 31635, 9) }
M.veins = { Position(33438, 31625, 10), Position(33437, 31570, 10), Position(33397, 31588, 10), Position(33433, 31597, 10), Position(33417, 31617, 10), Position(33415, 31584, 10) }
M.plantWait = 30 * 60
M.veinWait = 2 * 60
M.veinChance = 27

local BLOOMING, VEIN = 22064, 22075

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
	if not active() or not target or not target.isItem or not target:isItem() or target:getId() ~= VEIN then
		return false
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
			if M.state(player) == 2 then
				M.setState(player, 3)
			end
			return true
		end
		msg(player, "Only those who helped Maeryn against the Curse of the Full Moon may face Feroxa.") -- ours
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
		if active() and M.state(player) == 1 then
			local kills = M.kills(player)
			if kills < M.killsNeeded then
				player:setStorageValue(S.Kills, kills + 1)
				M.checkDone(player)
			end
		end
	end)
	return true
end
death:register()

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
		if placeOnce(BLOOMING, p) then
			placed = placed + 1
		end
	end
	for _, p in ipairs(M.veins) do
		if placeOnce(VEIN, p) then
			placed = placed + 1
		end
	end
	local tile = Tile(M.hallTeleport)
	local teleport = tile and tile:getItemById(1949)
	if teleport and teleport.setDestination then
		teleport:setDestination(Position(0, 0, 0)) -- the MoveEvent above does the moving
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
