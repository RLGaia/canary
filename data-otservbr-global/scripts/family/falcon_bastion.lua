-- Gaia Family server: The Order of the Falcon (The Secret Library Quest) fixes (2026-11-09).
-- Ours, not upstream. Reviewed against TibiaWiki BR (quest page as HTML from Rodrigo) and the
-- TibiaWiki EN spoiler, book and chest pages. Upstream had the route, the minibosses, the doors,
-- the boats and Grand Master Oberon's debate, but:
--   * the nine volumes of "The Grand Master of Verbal Debate" were not on our map, so upstream
--     gave Master Debater to every Oberon killer; now each volume is found where BR puts it (a
--     desk, a bench, bones, a chest...; one torn book is placed), once per character and again
--     if lost, and Master Debater needs all nine (BR/EN) - FAMILY edit in creaturescripts_kill.lua
--   * the quest log showed the mission only after asking Dedoras: entering the Bastion (FAMILY
--     edit in actions_entrance.lua), Oberon's death and a login repair now show it
--   (the brass-shod chest on the rooftop, 33377,31321,1, is upstream's Key 0909 chest, uid 5012 set
--    at startup: left alone; a first version of this file wrongly gave it daily rewards)
--   * Key 0808 and the Can of Grease had no source: see the section further down (switch
--     Family.falconKeys)
-- Oberon's answers (any punctuation and case), the miniboss message and the Zao boat are FAMILY
-- edits in the upstream files. Switch: Family.falconBastion.

Family = Family or {}
Family.falconBastion = true

FamilyFalcon = {}
local F = FamilyFalcon
local SL = Storage.Quest.U11_80.TheSecretLibrary

local function on()
	return Family.falconBastion
end

local function msg(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

-- The nine volumes ---------------------------------------------------------------------------
-- spots: the object at the BR coordinate (or the EN one when BR's square is empty); texts EN.
F.bookItem = 2821
F.books = {
	{ name = "The Grand Master of Verbal Debate I", spots = { Position(33369, 31348, 3) }, text = "Facing villainy of the utmost caliber, your riposte:\n\"Are you ever going to fight or do you prefer talking?\"" },
	{ name = "The Grand Master of Verbal Debate II", spots = { Position(33362, 31318, 3), Position(33362, 31319, 3) }, text = "Enduring a great deal of hubris, your riposte:\n\"Even before they smell your breath?\"" },
	{ name = "The Grand Master of Verbal Debate III", spots = { Position(33373, 31349, 6) }, place = 3121, text = "Having to endure a great threat, your riposte:\n\"Too bad you barely exist at all!\"" },
	{ name = "Fragment of The Grand Master of Verbal Debate IV", spots = { Position(33374, 31336, 3), Position(33373, 31336, 3), Position(33372, 31336, 3) }, text = "Knightly Successor Orders of Tibia, loose pages II, adendum\n\n(these pages have been copied in crude writing over pages from another book it seems)\n\nThe Grand Master of Verbal Debate IV\n\nA counter spell:\nSEHWO ASIMO, TOLIDO ESD\n\n(the book goes on to deal with the orders of the other two Etzels)" },
	{ name = "The Grand Master of Verbal Debate V", spots = { Position(33368, 31325, 6), Position(33365, 31323, 6) }, text = "Dealing with a forboding warning, your riposte:\n\"Excuse me but I still do not get the message!\"" },
	{ name = "The Grand Master of Verbal Debate VI", spots = { Position(33368, 31327, 6) }, text = "Boasting with strong words, you riposte:\n\"Then why are we fighting alone right now?\"" },
	{ name = "The Grand Master of Verbal Debate VII", spots = { Position(33387, 31285, 7) }, text = "Being confronted with vile accusations, your riposte:\n\"How appropriate, you look like something worms already got the better of!\"" },
	{ name = "The Grand Master of Verbal Debate VIII", spots = { Position(33373, 31350, 7) }, text = "Facing a profound threat, your riposte:\n\"Then let me show you the concept of mortality before it!\"" },
	{ name = "The Grand Master of Verbal Debate IX", spots = { Position(33369, 31343, 8) }, text = "Receiving a doubtful word of wisdom, your riposte:\n\"Dare strike up a Minnesang and you will receive your last accolade!\"" },
}
-- movable things on a book spot (crumpled paper, torn books) stay where they are
F.fixedIds = { [643] = true, [3121] = true }

local function kv(player)
	return player:kv():scoped("family-falcon")
end

function F.bookMask(player)
	return tonumber(kv(player):get("books")) or 0
end

local function hasBit(value, bit)
	return math.floor(value / bit) % 2 == 1
end

function F.hasBook(player, index)
	return hasBit(F.bookMask(player), 2 ^ (index - 1))
end

function F.allBooks(player)
	return F.bookMask(player) == 2 ^ #F.books - 1
end

function F.bookIndexAt(pos)
	for i, b in ipairs(F.books) do
		for _, s in ipairs(b.spots) do
			if s == pos then
				return i
			end
		end
	end
	return nil
end

local function carries(player, book)
	local want = book.name .. "."
	local function isBook(item)
		return item:getId() == F.bookItem and item:getAttribute(ITEM_ATTRIBUTE_DESCRIPTION) == want
	end
	for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
		local item = player:getSlotItem(slot)
		if item then
			if isBook(item) then
				return true
			end
			if item:isContainer() then
				for _, inner in ipairs(Container(item.uid):getItems(true) or {}) do
					if isBook(inner) then
						return true
					end
				end
			end
		end
	end
	return false
end

-- returns true when the player got the volume (the object's normal use is skipped)
function F.takeBook(player, index)
	local book = F.books[index]
	local had = F.hasBook(player, index)
	if had and carries(player, book) then
		return false
	end
	local item = player:addItem(F.bookItem, 1)
	if not item then
		player:sendCancelMessage("You have no room or not enough capacity to take it.")
		return true
	end
	item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, book.name .. ".")
	item:setAttribute(ITEM_ATTRIBUTE_TEXT, book.name .. "\n\n" .. book.text)
	if not had then
		kv(player):set("books", F.bookMask(player) + 2 ^ (index - 1))
	end
	local n = 0
	for i = 1, #F.books do
		if F.hasBook(player, i) then
			n = n + 1
		end
	end
	msg(player, string.format("You have found %s (%d of %d volumes).", book.name, n, #F.books)) -- ours
	return true
end

local bookAction = Action()
function bookAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	local index = F.bookIndexAt(item:getPosition())
	if not index then
		return false
	end
	return F.takeBook(player, index)
end
for _, b in ipairs(F.books) do
	for _, s in ipairs(b.spots) do
		bookAction:position(s)
	end
end
bookAction:register()

local fixed = EventCallback("FamilyFalconBooks")
function fixed.playerOnMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if on() and F.fixedIds[item:getId()] and fromPosition.x ~= CONTAINER_POSITION and F.bookIndexAt(fromPosition) then
		player:sendCancelMessage("You cannot move this object.")
		return false
	end
	return true
end
fixed:register()

-- Quest log ----------------------------------------------------------------------------------
function F.showMission(player, value)
	if player:getStorageValue(SL.Questlog) < 1 then
		player:setStorageValue(SL.Questlog, 1)
	end
	if player:getStorageValue(SL.FalconBastion.Questline) < value then
		player:setStorageValue(SL.FalconBastion.Questline, value)
	end
end

local login = CreatureEvent("FamilyFalconLogin")
function login.onLogin(player)
	if on() then
		local line = player:getStorageValue(SL.FalconBastion.Questline)
		if line >= 1 and player:getStorageValue(SL.Questlog) < 1 then
			player:setStorageValue(SL.Questlog, 1)
		elseif line < 1 and player:getStorageValue(SL.FalconBastion.KillingBosses) >= 1 then
			F.showMission(player, 1)
		end
	end
	return true
end
login:register()

-- Key 0808 and the Can of Grease (2026-11-09) ------------------------------------------------------
-- Upstream wires the Key 0808 door (33363,31360,3, door_key.lua) but nothing gave the key, and the
-- grease had no source and no gate. TibiaWiki EN: the key spawns on a table (130.77|122.125|5 =
-- 33357,31357,5; Rodrigo's screenshot shows it on that counter square), "more than once daily";
-- the can lies at 130.84|122.103|7 (33364,31335,7, a cell with racks), vanishes a few minutes after
-- it is found, and opens the gate at 130.89|122.84|3 (33369,31316,3). On our map that passage is
-- open, three squares wide (33368-33370), with the gate's mechanism (8615) beside it in the east
-- room (33372,31317,3); behind it a small courtyard with ramps and stairs (47 squares, nothing the
-- quest needs). Ours: iron bars (2185) as the closed gate, respawn 30 min, the can lasts 5 min
-- after it is picked up, the gate stays open 2 min, a way out from the courtyard side, all texts.
Family.falconKeys = true
F.key0808 = { id = 2972, aid = 808, spot = Position(33357, 31357, 5) }
F.grease = { id = 28855, spot = Position(33364, 31335, 7), life = 5 * 60 }
F.respawn = 30 * 60
F.gate = {
	bars = 2185,
	squares = { Position(33368, 31316, 3), Position(33369, 31316, 3), Position(33370, 31316, 3) },
	mechanism = Position(33372, 31317, 3),
	south = Position(33369, 31317, 3),
	openFor = 2 * 60,
}
F.state = F.state or { gone = {}, gateOpen = false }

local function keysOn()
	return Family.falconKeys
end

local function findOn(pos, id, check)
	local tile = Tile(pos)
	if not tile then
		return nil
	end
	for _, it in ipairs(tile:getItems() or {}) do
		if it:getId() == id and (not check or check(it)) then
			return it
		end
	end
	return nil
end

local function isSpotKey(it)
	return it:getActionId() == F.key0808.aid
end

local function isSpotGrease(it)
	return it:getCustomAttribute("familyGrease") ~= nil
end

function F.placeKey()
	local item = Game.createItem(F.key0808.id, 1, F.key0808.spot)
	if item then
		item:setActionId(F.key0808.aid)
	end
	return item
end

function F.placeGrease()
	local item = Game.createItem(F.grease.id, 1, F.grease.spot)
	if item then
		item:setCustomAttribute("familyGrease", 1)
	end
	return item
end

-- puts the key or the can back when it has been gone for F.respawn seconds
local function respawn(name, pos, id, check, place, now)
	if findOn(pos, id, check) then
		F.state.gone[name] = nil
		return
	end
	local gone = F.state.gone[name]
	if not gone then
		F.state.gone[name] = now
	elseif now - gone >= F.respawn then
		place()
		F.state.gone[name] = nil
	end
end

-- the can vanishes F.grease.life seconds after a player first carries it
function F.greaseExpired(item, now)
	if item:getCustomAttribute("familyGrease") == nil then
		return false
	end
	local untilTime = item:getCustomAttribute("familyGreaseUntil")
	if not untilTime then
		item:setCustomAttribute("familyGreaseUntil", now + F.grease.life)
		return false
	end
	return now >= untilTime
end

local function vanish(player, item)
	item:remove()
	msg(player, "The can of grease has vanished into thin air.") -- ours
end

function F.gateIsOpen()
	return F.state.gateOpen
end

local function gateFree()
	for _, pos in ipairs(F.gate.squares) do
		local tile = Tile(pos)
		if tile and tile:getTopCreature() then
			return false
		end
	end
	return true
end

function F.closeGate()
	if not gateFree() then
		F.state.closeEvent = addEvent(F.closeGate, 5000)
		return false
	end
	for _, pos in ipairs(F.gate.squares) do
		if not findOn(pos, F.gate.bars) then
			Game.createItem(F.gate.bars, 1, pos)
		end
	end
	F.state.gateOpen = false
	F.state.closeEvent = nil
	return true
end

function F.openGate()
	for _, pos in ipairs(F.gate.squares) do
		local bars = findOn(pos, F.gate.bars)
		if bars then
			bars:remove()
		end
		pos:sendMagicEffect(CONST_ME_POFF)
	end
	F.state.gateOpen = true
	if F.state.closeEvent then
		stopEvent(F.state.closeEvent)
	end
	F.state.closeEvent = addEvent(F.closeGate, F.gate.openFor * 1000)
end

local greaseAction = Action()
function F.useGrease(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not keysOn() then
		return false
	end
	if F.greaseExpired(item, os.time()) then
		vanish(player, item)
		return true
	end
	if toPosition ~= F.gate.mechanism then
		return false
	end
	if F.gateIsOpen() then
		player:sendCancelMessage("The gate is already open.") -- ours
		return true
	end
	F.openGate()
	toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
	msg(player, "You grease the mechanism. It turns with a loud creak and the gate rises.") -- ours
	return true
end
greaseAction.onUse = F.useGrease
greaseAction:id(F.grease.id)
greaseAction:register()

local mechanismAction = Action()
function F.useMechanism(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not keysOn() then
		return false
	end
	if F.gateIsOpen() then
		player:sendCancelMessage("The gate is open.") -- ours
	else
		player:sendCancelMessage("The mechanism is stuck with rust. Some grease would help.") -- ours
	end
	return true
end
mechanismAction.onUse = F.useMechanism
mechanismAction:position(F.gate.mechanism)
mechanismAction:register()

-- the courtyard behind the gate is a dead end: from that side the bars let a player through
local barsAction = Action()
function F.useBars(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not keysOn() or item:getId() ~= F.gate.bars then
		return false
	end
	if player:getPosition().y < F.gate.squares[1].y then
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:teleportTo(F.gate.south)
		F.gate.south:sendMagicEffect(CONST_ME_POFF)
		msg(player, "You squeeze through a gap beside the gate.") -- ours
	else
		player:sendCancelMessage("The gate is shut. Its mechanism must be close by.") -- ours
	end
	return true
end
barsAction.onUse = F.useBars
for _, pos in ipairs(F.gate.squares) do
	barsAction:position(pos)
end
barsAction:register()

local keysThink = GlobalEvent("FamilyFalconKeys")
function F.keysThink()
	if not on() or not keysOn() then
		return true
	end
	local now = os.time()
	respawn("key", F.key0808.spot, F.key0808.id, isSpotKey, F.placeKey, now)
	respawn("grease", F.grease.spot, F.grease.id, isSpotGrease, F.placeGrease, now)
	for _, player in ipairs(Game.getPlayers()) do
		local can = player:getItemById(F.grease.id, true)
		if can and F.greaseExpired(can, now) then
			vanish(player, can)
		end
	end
	return true
end
function keysThink.onThink(interval)
	return F.keysThink()
end
keysThink:interval(10000)
keysThink:register()

-- Startup: the torn book on spot III, Key 0808, the can and the closed gate -------------------
local startup = GlobalEvent("FamilyFalconStartup")
function startup.onStartup()
	local placed = 0
	for _, b in ipairs(F.books) do
		if b.place and on() then
			local tile = Tile(b.spots[1])
			if tile and not tile:getItemById(b.place) then
				if Game.createItem(b.place, 1, b.spots[1]) then
					placed = placed + 1
				end
			end
		end
	end
	logger.info("[Family] Falcon Bastion: {} debate volumes, {} placed", #F.books, placed)
	if on() and keysOn() then
		local key = findOn(F.key0808.spot, F.key0808.id, isSpotKey) or F.placeKey()
		local can = findOn(F.grease.spot, F.grease.id, isSpotGrease) or F.placeGrease()
		local closed = F.closeGate()
		logger.info("[Family] Falcon Bastion: Key 0808 {}, can of grease {}, gate {}", key and "placed" or "MISSING", can and "placed" or "MISSING", closed and "closed" or "busy")
	end
	return true
end
startup:register()
