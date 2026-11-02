-- Gaia Family server: Cobra Bastion secrets (2026-11-02). Ours, not upstream; same switch
-- as cobra_bastion.lua (Family.cobraBastion) and the same table (FamilyCobra).
--
-- Sources: TibiaWiki BR (The Order of the Cobra Quest, PDF from Rodrigo: the cart and the
-- fire walls) and TibiaWiki EN (Cobra Bastion, Cobra Bastion/Messages, Cart Packed with
-- Gold, Clutter, Wheel Oil, Strange Rat, Custodian). Messages marked "ours" are not from Tibia.
--
--   * Fire walls of the basement (they had no action id on our map, so anyone walked
--     through): the wall east of the Custodian (x 33386) lets you pass once per Custodian
--     kill (BR/EN "only once"); the wall at the north end of the corridor (y 32692) lets you
--     out north always and back south after passing the Custodian's wall
--     (movements_cobra_mini_bosses.lua, FAMILY).
--   * Cart Packed with Gold: appears at the south end of the corridor when the Custodian
--     dies (if no cart is on its way). It rolls north one square a second while a player
--     is within 2 squares (BR) and nothing stands in front of it; six Clutters block the
--     way and must be destroyed. On the way it drops gold coins and now and then a wheel
--     oil (20 seconds before it seeps away; it cannot be carried, BR); oil used on the cart
--     makes it jump up to 3 squares ahead (BR "pula alguns pisos"). At the end of the
--     corridor a message asks to destroy it (BR); only then its wreck holds the loot of
--     TibiaWiki EN (small diamonds, stone skin amulet, ultimate health potions, terra rod)
--     plus platinum (ours). Destroyed earlier, the wreck is empty.
--   * The Cobra's curse: every character is cursed until he tosses a gold, platinum or
--     crystal coin on the floor of the treasure room (+3 floor, EN 33396,32642,4): light
--     effects and "You made it whole again... the curse is lifted." (EN). While cursed,
--     several Strange Rats now and then appear on him inside the Bastion (EN).
--   * Scarlett's messages: when the fight against Scarlett Etzel starts, every player in
--     the Bastion gets a series of orange messages from her, one every 4 seconds, chosen by
--     what he has done (EN list), then The Cube Effect.
--
-- Storages: Storage.Quest.FamilyCobraBastion.CurseLifted, FirePass. KV "family-cobra"
-- (planegazer = 1 after a Last Planegazer kill, which has no Bosstiary entry).

Family = Family or {}
FamilyCobra = FamilyCobra or {}
local M = FamilyCobra

local function on()
	return Family.cobraBastion ~= false
end

local function msg(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

local S = Storage.Quest.FamilyCobraBastion
local GD = Storage.Quest.U12_20.GraveDanger

local function inArea(pos)
	for _, a in ipairs(M.area or {}) do
		if pos:isInRange(a[1], a[2]) then
			return true
		end
	end
	return false
end
M.inArea = inArea

local function bastionPlayers()
	local list = {}
	for _, player in ipairs(Game.getPlayers()) do
		if inArea(player:getPosition()) then
			list[#list + 1] = player
		end
	end
	return list
end
M.bastionPlayers = bastionPlayers

-- Fire walls -----------------------------------------------------------------------------

M.fireWallAid = 36568 -- movements_cobra_mini_bosses.lua
M.fireWallIds = { 32021, 5061, 5062, 5063, 5064, 5065, 5066, 5067 }
M.fireWalls = {}
for y = 32822, 32829 do
	M.fireWalls[#M.fireWalls + 1] = Position(33386, y, 8) -- east of the Custodian
end
for x = 33388, 33394 do
	M.fireWalls[#M.fireWalls + 1] = Position(x, 32692, 8) -- north end of the corridor
end

function M.setupFireWalls()
	local done = 0
	for _, pos in ipairs(M.fireWalls) do
		local tile = Tile(pos)
		if tile then
			for _, id in ipairs(M.fireWallIds) do
				local wall = tile:getItemById(id)
				if wall then
					wall:setActionId(M.fireWallAid)
					done = done + 1
					break
				end
			end
		end
	end
	return done
end

-- the Custodian's death: one pass through his fire wall for everyone who fought him, and a cart
function M.onCustodianDeath(players)
	if not on() then
		return
	end
	for _, player in ipairs(players) do
		player:setStorageValue(S.FirePass, 1)
	end
	M.spawnCart()
end

-- Cart Packed with Gold ----------------------------------------------------------------------

M.cartName = "Cart Packed with Gold"
M.path = {}
for y = 32828, 32694, -1 do
	M.path[#M.path + 1] = Position(33390, y, 8)
end
M.clutterSteps = { 16, 36, 56, 76, 96, 116 } -- path indexes
M.stepMs = 1000
M.nearRange = 2 -- BR: stay 2 squares from it
M.goldChance = 20 -- percent per step
M.oilChance = 5
M.oilId = 31264
M.oilLife = 20 -- seconds
M.jump = 3
M.staleCart = 10 * 60 -- a cart nobody moved for 10 minutes is replaced by the next one
M.cartLoot = { -- TibiaWiki EN; amounts and chances ours
	{ id = 3028, min = 1, max = 3, chance = 100 }, -- small diamond
	{ id = 3035, min = 5, max = 15, chance = 100 }, -- platinum coin
	{ id = 7643, min = 1, max = 5, chance = 60 }, -- ultimate health potion
	{ id = 3081, min = 1, max = 1, chance = 30 }, -- stone skin amulet
	{ id = 3065, min = 1, max = 1, chance = 20 }, -- terra rod
}

M.cart = nil -- { id, index, reached, lastMove }
M.clutters = {}

function M.getCart()
	if not M.cart then
		return nil
	end
	local c = Creature(M.cart.id)
	if not c then
		M.cart = nil
	end
	return c
end

local function removeClutters()
	for _, id in ipairs(M.clutters) do
		local c = Creature(id)
		if c then
			c:remove()
		end
	end
	M.clutters = {}
end

function M.spawnCart()
	local cart = M.getCart()
	if cart then
		if M.cart.reached or os.time() - M.cart.lastMove < M.staleCart then
			return cart
		end
		cart:remove()
		M.cart = nil
	end
	removeClutters()
	cart = Game.createMonster(M.cartName, M.path[1], false, true)
	if not cart then
		return nil
	end
	cart:registerEvent("FamilyCobraCartDeath")
	M.cart = { id = cart:getId(), index = 1, reached = false, lastMove = os.time() }
	for _, step in ipairs(M.clutterSteps) do
		local clutter = Game.createMonster("Clutter", M.path[step], false, true)
		if clutter then
			M.clutters[#M.clutters + 1] = clutter:getId()
		end
	end
	if not M.cartEvent then
		M.cartEvent = addEvent(M.cartThink, M.stepMs)
	end
	return cart
end

local function blocked(pos)
	local tile = Tile(pos)
	return not tile or tile:getCreatureCount() > 0
end

local function playerNear(pos)
	for _, spec in ipairs(Game.getSpectators(pos, false, true, M.nearRange, M.nearRange, M.nearRange, M.nearRange)) do
		local player = spec:getPlayer()
		if player and player:getGroup():getAccess() == false then
			return true
		end
	end
	return false
end
M.playerNear = playerNear

local function removeOil(pos)
	local tile = Tile(pos)
	local oil = tile and tile:getItemById(M.oilId)
	if oil then
		oil:remove()
		pos:sendMagicEffect(CONST_ME_POFF)
	end
end

local function dropOnTheWay(pos)
	if math.random(100) <= M.goldChance then
		Game.createItem(3031, math.random(5, 15), pos)
	end
	if math.random(100) <= M.oilChance then
		Game.createItem(M.oilId, 1, pos)
		addEvent(removeOil, M.oilLife * 1000, Position(pos.x, pos.y, pos.z))
	end
end

function M.reachEnd(cart)
	M.cart.reached = true
	for _, spec in ipairs(Game.getSpectators(cart:getPosition(), false, true, 8, 8, 6, 6)) do
		local player = spec:getPlayer()
		if player then
			msg(player, "The cart has reached the end of the tunnel. Destroy it to get at the gold it carries!") -- ours, BR: "um aviso irá aparecer para destruí-la"
		end
	end
	cart:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
end

-- move the cart to path index i (one step or a jump)
function M.moveCart(cart, i)
	local from = cart:getPosition()
	if not cart:teleportTo(M.path[i], true) then
		return false
	end
	M.cart.index = i
	M.cart.lastMove = os.time()
	dropOnTheWay(from)
	if i == #M.path then
		M.reachEnd(cart)
	end
	return true
end

-- one step forward when a player is close and the square ahead is free; true if it moved
function M.step()
	local cart = M.getCart()
	if not cart or M.cart.reached then
		return false
	end
	local nextIndex = M.cart.index + 1
	if nextIndex > #M.path then
		return false
	end
	if not M.playerNear(cart:getPosition()) or blocked(M.path[nextIndex]) then
		return false
	end
	return M.moveCart(cart, nextIndex)
end

function M.cartThink()
	M.cartEvent = nil
	if not on() or not M.getCart() then
		return
	end
	M.step()
	if M.getCart() and not M.cart.reached then
		M.cartEvent = addEvent(M.cartThink, M.stepMs)
	end
end

-- wheel oil: jump up to M.jump squares, over anything in between
function M.oilCart(cart)
	if not M.cart or M.cart.reached then
		return false
	end
	for k = M.jump, 1, -1 do
		local i = M.cart.index + k
		if i <= #M.path and not blocked(M.path[i]) then
			if not M.moveCart(cart, i) then
				return false
			end
			M.path[i]:sendMagicEffect(CONST_ME_POFF)
			return true
		end
	end
	return false
end

local oil = Action()
function oil.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	local cart = M.getCart()
	if not cart or type(target) ~= "userdata" or not target.getId or target:getId() ~= cart:getId() then
		player:sendCancelMessage("Ideal to oil large wheels.") -- ours
		return true
	end
	if M.oilCart(cart) then
		item:remove(1)
		msg(player, "You pour the wheel oil on the axles and the cart jolts forward.") -- ours
	else
		player:sendCancelMessage("The way ahead is blocked.") -- ours
	end
	return true
end
oil:id(M.oilId)
oil:register()

-- the leaky can cannot be carried (BR: "você não conseguirá jogar o wheel oil em sua backpack")
local carry = EventCallback("FamilyCobraWheelOil")
function carry.playerOnMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if on() and item:getId() == M.oilId and toPosition.x == CONTAINER_POSITION then
		player:sendCancelMessage("The can is too leaky to carry.") -- ours
		return false
	end
	return true
end
carry:register()

local cartDeath = CreatureEvent("FamilyCobraCartDeath")
function cartDeath.onDeath(creature, corpse, killer, mostDamageKiller)
	local reached = M.cart and M.cart.id == creature:getId() and M.cart.reached
	if M.cart and M.cart.id == creature:getId() then
		M.cart = nil
	end
	if reached and corpse and corpse:isContainer() then
		M.fillWreck(corpse)
	end
	return true
end
cartDeath:register()

function M.fillWreck(corpse)
	for _, l in ipairs(M.cartLoot) do
		if math.random(100) <= l.chance then
			corpse:addItem(l.id, math.random(l.min, l.max))
		end
	end
end

-- The Cobra's curse ---------------------------------------------------------------------

M.coins = { 3031, 3035, 3043 }
M.balcony = { from = Position(33386, 32639, 4), to = Position(33406, 32645, 4) } -- treasure room, +3 floor
M.ratCheck = 60 -- seconds
M.ratChance = 4 -- percent per check while cursed in the Bastion (about once in 25 minutes)
M.ratMin, M.ratMax = 3, 5

function M.isCursed(player)
	return player:getStorageValue(S.CurseLifted) < 1
end

function M.liftCurse(player, pos)
	player:setStorageValue(S.CurseLifted, 1)
	for _ = 1, 6 do
		local p = Position(pos.x + math.random(-3, 3), pos.y + math.random(-2, 2), pos.z)
		p:sendMagicEffect(CONST_ME_THUNDER) -- TibiaWiki EN "Light Effect", effect 73
	end
	msg(player, "You made it whole again... the curse is lifted.")
end

local toss = EventCallback("FamilyCobraCoinToss")
function toss.playerOnItemMoved(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if not on() or toPosition.x == CONTAINER_POSITION or not table.contains(M.coins, item:getId()) then
		return
	end
	if not toPosition:isInRange(M.balcony.from, M.balcony.to) or not M.isCursed(player) then
		return
	end
	local tile = Tile(toPosition)
	local coin = tile and tile:getItemById(item:getId())
	if coin then
		coin:remove(math.min(count, coin:getCount()))
	end
	M.liftCurse(player, toPosition)
end
toss:register()

function M.ratsOn(player)
	local pos = player:getPosition()
	local n = 0
	for _ = 1, math.random(M.ratMin, M.ratMax) do
		if Game.createMonster("Strange Rat", pos, true, true) then
			n = n + 1
		end
	end
	pos:sendMagicEffect(CONST_ME_POFF)
	return n
end

function M.ratRoll(player)
	if not M.isCursed(player) or player:getGroup():getAccess() then
		return false
	end
	local tile = Tile(player:getPosition())
	if not tile or tile:hasFlag(TILESTATE_PROTECTIONZONE) then
		return false
	end
	if math.random(100) > M.ratChance then
		return false
	end
	return M.ratsOn(player) > 0
end

local function ratLoop()
	if on() then
		for _, player in ipairs(bastionPlayers()) do
			M.ratRoll(player)
		end
	end
	addEvent(ratLoop, M.ratCheck * 1000)
end

-- Scarlett's messages -----------------------------------------------------------------

M.tauntDelay = 10 -- seconds after the fight starts
M.tauntGap = 4

local function hasAnyItem(player, ids)
	for _, id in ipairs(ids) do
		if player:getItemCount(id) > 0 then
			return true
		end
	end
	return false
end

function M.allChestsOpened(player)
	local kv = player:kv():scoped("family-cobra-chests")
	for _, pos in ipairs(M.chests or {}) do
		if not kv:get(string.format("%d-%d-%d", pos.x, pos.y, pos.z)) then
			return false
		end
	end
	return M.chests ~= nil
end

local function vocationName(player)
	local voc = player:getVocation()
	local base = voc and Vocation(voc:getBaseId())
	return ((base and base:getName()) or "adventurer"):lower()
end

-- TibiaWiki EN, Cobra Bastion/Messages: text and who receives it
function M.taunts(player)
	local list = { "I...see you." }
	local function add(cond, text)
		if cond then
			list[#list + 1] = text
		end
	end
	add(player:kv():scoped("family-cobra"):get("planegazer") == 1, "Planegazer.")
	add(M.allChestsOpened(player), "And you almost robbed me blind, " .. vocationName(player) .. ". Impressive.")
	add(getTibiaTimerDayOrNight() == "night", "The night will not shield you.")
	add(M.isCursed(player), "You are cursed")
	add((player:getBosstiaryKills("Grand Master Oberon") or 0) > 0, "Oberon was wrong, he should never have gone to Zao. You rightfully ended his reign.")
	add(player:hasMount(5), "I like that panther of yours...dark and mysterious like the middle of the night.")
	add(player:getStorageValue(Storage.Navigator) >= 1, "The navigator...you've been there. He tells only his side of story.")
	add(player:getStorageValue(Storage.Quest.U8_54.SeaOfLight.Mission3) >= 4 or player:getStorageValue(Storage.Quest.U8_7.JackFutureQuest.QuestLine) >= 11, "How nice of you to help out Spectulus, I once knew him in my youth. So he, too, is still around.")
	add(hasAnyItem(player, { 20182 }), "You tasted death and put your name on it.")
	add(hasAnyItem(player, { 3003, 646 }), "And you carry a rope, how handy and thoughtful. Reminds me of someone, always kept one with him, too...")
	return list
end

local function sendTaunt(scarlettId, playerId, list, i)
	local scarlett = Creature(scarlettId)
	local player = Player(playerId)
	if not scarlett or not player or not inArea(player:getPosition()) then
		return
	end
	if i > #list then
		player:getPosition():sendMagicEffect(CONST_ME_SUPREME_CUBE, player)
		return
	end
	scarlett:say(list[i], TALKTYPE_MONSTER_SAY, false, player, player:getPosition())
	addEvent(sendTaunt, M.tauntGap * 1000, scarlettId, playerId, list, i + 1)
end
M.sendTaunt = sendTaunt

function M.startTaunts(scarlett)
	if not on() or not scarlett then
		return
	end
	local id = scarlett:getId()
	addEvent(function()
		if not Creature(id) then
			return
		end
		for _, player in ipairs(bastionPlayers()) do
			sendTaunt(id, player:getId(), M.taunts(player), 1)
		end
	end, M.tauntDelay * 1000)
end

-- Last Planegazer has no Bosstiary entry: remember his killers for Scarlett's message
local planegazer = CreatureEvent("FamilyCobraPlanegazer")
function planegazer.onDeath(creature, corpse, killer, mostDamageKiller)
	for attackerId in pairs(creature:getDamageMap()) do
		local player = Player(attackerId)
		if player then
			player:kv():scoped("family-cobra"):set("planegazer", 1)
		end
	end
	return true
end
planegazer:register()

-- Startup ------------------------------------------------------------------------------

local startup = GlobalEvent("FamilyCobraSecretsStartup")
function startup.onStartup()
	if not on() then
		return true
	end
	local walls = M.setupFireWalls()
	local mType = MonsterType("Last Planegazer")
	if mType then
		mType:registerEvent("FamilyCobraPlanegazer")
	end
	addEvent(ratLoop, M.ratCheck * 1000)
	logger.info("[Family] Cobra Bastion secrets: {} fire wall squares, cart path {} squares, {} clutters", walls, #M.path, #M.clutterSteps)
	return true
end
startup:register()
