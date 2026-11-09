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
--   * the brass-shod chest on the rooftop (33377,31321,1) gave nothing; it gives the EN rewards
--     once a day like the other six
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

-- The rooftop chest ----------------------------------------------------------------------------
F.roofChest = Position(33377, 31321, 1)
F.chestRewards = { -- TibiaWiki EN, Brass-Shod Chest (Falcon Bastion); the same as upstream's six chests
	{ id = 9081, count = 1 }, -- roasted dragon wings
	{ id = 28821, count = 1 }, -- patch of fine cloth
	{ id = 28823, count = 1 }, -- falcon crest
	{ id = 9058, count = 1 }, -- gold ingot
	{ id = 6299, count = 1 }, -- death ring
	{ id = 3052, count = 1 }, -- life ring
	{ id = 3035, count = 10 }, -- platinum coins
}
F.chestWait = 24 * 60 * 60

function F.openRoofChest(player)
	local last = tonumber(kv(player):get("roof-chest")) or 0
	if os.time() < last + F.chestWait then
		msg(player, "The chest is empty.")
		return false
	end
	local reward = F.chestRewards[math.random(#F.chestRewards)]
	local it = ItemType(reward.id)
	if not player:addItem(reward.id, reward.count) then
		player:sendCancelMessage("You have no room or not enough capacity to take it.")
		return false
	end
	kv(player):set("roof-chest", os.time())
	if reward.count > 1 then
		msg(player, string.format("You have found %d %s.", reward.count, it:getPluralName()))
	else
		msg(player, string.format("You have found %s %s.", it:getArticle(), it:getName()))
	end
	return true
end

local roofChest = Action()
function roofChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	F.openRoofChest(player)
	return true
end
roofChest:position(F.roofChest)
roofChest:register()

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

-- Startup: the torn book on spot III -------------------------------------------------------------
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
	logger.info("[Family] Falcon Bastion: {} debate volumes, {} placed, rooftop chest", #F.books, placed)
	return true
end
startup:register()
