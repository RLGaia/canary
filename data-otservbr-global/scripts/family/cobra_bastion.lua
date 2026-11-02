-- Gaia Family server: The Order of the Cobra (Cobra Bastion), completed (2026-11-01).
--
-- Upstream had the Bastion on the map with the minibosses, the mirror fight
-- and the smoke wall, but most of the quest was not wired up. Sources:
-- TibiaWiki BR "The Order of the Cobra Quest" and "Cobra Bastion" (pages and
-- the lamp-oil screenshot sent by Rodrigo; tibiawiki.com.br itself is behind
-- Cloudflare for us) and TibiaWiki EN (Cobra Bastion, Brass-Shod Chest, Flask
-- with Lamp Oil, Key 0303, the Bastion books, the chess screenshot).
--
--   * Quest log: the mission "The Order of the Cobra" (storage
--     GraveDanger.Cobra) starts when you first enter the Bastion and is done
--     when Scarlett Etzel dies (creaturescripts_boss_kill.lua). It shows under
--     Grave Danger even before talking to Jack Springer.
--   * The 10 brass-shod chests of the Bastion (item ids 28827/28828 on our map;
--     EN: 10 chests, once every 24 hours, one of six rewards) give one reward
--     a day per character and no longer open empty.
--   * The box at 33392,32674,7 (BR screenshot) gives a flask with lamp oil,
--     which evaporates after 10 minutes (EN). Used on the tendril wall that
--     closes the chest at 33392,32637,5, the tendrils burn for 5 minutes, then
--     the way is open and Cobra Assassins come out; they grow back after
--     about 20 minutes (BR).
--   * The pile of bones in the treasure room (33396,32640,4) gives a bag with
--     Key 0303 and Greig's artefact ledger (note 3/4) (BR/EN). Key 0303 opens
--     the Bastion's locked doors; the door of the room south-east of the
--     treasure room (33402,32653,4) is locked as in Tibia (BR).
--   * The four chess notes (EN texts): kitchen book (2/4), the book in the
--     locked room (1/4), the ledger (3/4) and Gaffir's secret room (4/4).
--   * Gaffir's corpse dragged onto the fire bowl in his room, then a step on
--     the carpet beside it: teleport to the secret room (33302,31197,9), out
--     again after 3 minutes (EN). The Time Distort Almanac used there gives
--     the achievement Avid Spectral Reader (BR).
--   * The chess board (floor 2): the moves of the notes plus a cheesy figurine
--     on the empty queen square make a Roaring Lion appear, and everyone in
--     the room may pass Scarlett's metal wall (BR/EN; actions_scarlett.lua).
--     The board resets 2 minutes later; using the chess box resets it too
--     (ours). The rope down to the board needs Guard Captain Quaid (EN).
--   * The door to the Custodian (33366,32825,8) opens only after Gaffir.
-- Messages marked "ours" are not from Tibia.
--
-- Storages: Storage.Quest.FamilyCobraBastion (Chess, KeyBag); chest days in
-- the player's KV ("family-cobra-chests"). Switch: Family.cobraBastion.

Family = Family or {}
Family.cobraBastion = true

FamilyCobra = FamilyCobra or {}
local M = FamilyCobra

local function on()
	return Family.cobraBastion ~= false
end

local function msg(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

local function key(pos)
	return string.format("%d-%d-%d", pos.x, pos.y, pos.z)
end

local GD = Storage.Quest.U12_20.GraveDanger
local S = Storage.Quest.FamilyCobraBastion

-- Quest log -------------------------------------------------------------------

M.area = {
	{ Position(33355, 32612, 0), Position(33420, 32705, 7) }, -- the island, all floors
	{ Position(33350, 32675, 8), Position(33400, 32835, 8) }, -- basement (grave, Custodian, cart corridor)
}

function M.start(player)
	if player:getStorageValue(GD.Cobra) < 1 then
		player:setStorageValue(GD.Cobra, 1)
	end
end

local zone = Zone("family.cobra-bastion")
for _, a in ipairs(M.area) do
	zone:addArea(a[1], a[2])
end
local zoneEvent = ZoneEvent(zone)
function zoneEvent.afterEnter(_zone, creature)
	local player = creature:getPlayer()
	if player and on() then
		M.start(player)
	end
end
zoneEvent:register()

-- Grave Danger is listed once the Cobra mission started, even without Jack Springer.
local baseQuestIsStarted = Player.questIsStarted
local graveDangerId
function Player.questIsStarted(self, questId)
	if baseQuestIsStarted(self, questId) then
		return true
	end
	if not on() then
		return false
	end
	graveDangerId = graveDangerId or Game.getQuestIdByName("Grave Danger")
	return questId == graveDangerId and self:getStorageValue(GD.Cobra) >= 1
end

-- Quest log text of the Cobra mission (ours: TibiaWiki has no text for it).
function M.missionText(player)
	if player:getStorageValue(GD.ScarlettKilled) >= 1 then
		return "Scarlett Etzel once stood proud and righteous. The assassins she rallied around her under the Order of the Cobra, however, were of ill repute and had to be vanquished. And so did she, you prevailed."
	end
	local function mark(done)
		return done and "done" or "not yet"
	end
	return string.format(
		"You found the Cobra Bastion, stronghold of the Order of the Cobra and its leader Scarlett Etzel. Defeat her lieutenants, solve the chess riddle hidden in the notes of the Bastion and face Scarlett.\nGaffir: %s. Custodian: %s. Guard Captain Quaid: %s. Chess riddle: %s.",
		mark(player:getStorageValue(GD.GaffirKilled) >= 1),
		mark(player:getStorageValue(GD.CustodianKilled) >= 1),
		mark(player:getStorageValue(GD.QuaidKilled) >= 1),
		mark(player:getStorageValue(S.Chess) >= 1)
	)
end

-- Brass-shod chests -------------------------------------------------------------

M.chests = {
	Position(33392, 32637, 5),
	Position(33366, 32646, 7),
	Position(33399, 32644, 1),
	Position(33401, 32647, 4),
	Position(33394, 32654, 3),
	Position(33404, 32662, 7),
	Position(33392, 32664, 2),
	Position(33382, 32690, 6),
	Position(33379, 32692, 7),
	Position(33371, 32787, 8),
}
M.chestRewards = { -- TibiaWiki EN, Brass-Shod Chest (Cobra Bastion)
	{ id = 9083, count = 1 }, -- banana chocolate shake
	{ id = 31678, count = 1 }, -- cobra crest
	{ id = 9058, count = 1 }, -- gold ingot
	{ id = 6299, count = 1 }, -- death ring
	{ id = 3052, count = 1 }, -- life ring
	{ id = 3035, count = 8 }, -- platinum coins
}
M.chestWait = 24 * 60 * 60

local function isChest(pos)
	for _, p in ipairs(M.chests) do
		if p == pos then
			return true
		end
	end
	return false
end

function M.openChest(player, pos)
	local kv = player:kv():scoped("family-cobra-chests")
	local last = kv:get(key(pos)) or 0
	if os.time() < last + M.chestWait then
		msg(player, "The chest is empty.") -- ours
		return false
	end
	local reward = M.chestRewards[math.random(#M.chestRewards)]
	local it = ItemType(reward.id)
	local item = player:addItem(reward.id, reward.count)
	if not item then
		player:sendCancelMessage("You have no room or not enough capacity to take it.") -- ours
		return false
	end
	kv:set(key(pos), os.time())
	if reward.count > 1 then
		msg(player, string.format("You have found %d %s.", reward.count, it:getPluralName()))
	else
		msg(player, string.format("You have found %s %s.", it:getArticle(), it:getName()))
	end
	return true
end

local chest = Action()
function chest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not isChest(item:getPosition()) then
		return false
	end
	M.openChest(player, item:getPosition())
	return true
end
chest:id(28827, 28828)
chest:register()

-- Flask with lamp oil and the tendril wall ---------------------------------------

M.lampBox = Position(33392, 32674, 7)
M.lampOil = 31368
M.lampOilLife = 10 * 60 -- seconds (EN)
M.tendrils = {
	{ pos = Position(33391, 32636, 5), id = 6239 },
	{ pos = Position(33392, 32636, 5), id = 6241 },
	{ pos = Position(33391, 32637, 5), id = 6237 },
}
M.burnTime = 5 * 60 -- seconds (BR)
M.regrowTime = 20 * 60 -- seconds (BR)
M.guards = { Position(33391, 32636, 5), Position(33391, 32637, 5) }
M.tendrilState = "grown" -- grown, burning, open

local function evaporate(playerId)
	local player = Player(playerId)
	if player and player:getItemCount(M.lampOil) > 0 then
		player:removeItem(M.lampOil, 1)
		msg(player, "The lamp oil has evaporated.") -- ours
	end
end

local lampBox = Action()
function lampBox.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or item:getPosition() ~= M.lampBox then
		return false
	end
	if player:getItemCount(M.lampOil) > 0 then
		msg(player, "You already carry a flask with lamp oil.") -- ours
		return true
	end
	if not player:addItem(M.lampOil, 1) then
		player:sendCancelMessage("You have no room or not enough capacity to take it.") -- ours
		return true
	end
	msg(player, "You have found a flask with lamp oil.") -- BR screenshot
	addEvent(evaporate, M.lampOilLife * 1000, player:getId())
	return true
end
lampBox:position(M.lampBox)
lampBox:register()

local function tendrilAt(pos)
	local tile = Tile(pos)
	if not tile then
		return nil
	end
	for _, t in ipairs(M.tendrils) do
		local found = tile:getItemById(t.id)
		if found then
			return found
		end
	end
	return nil
end

function M.regrow()
	local waiting = false
	for _, t in ipairs(M.tendrils) do
		local tile = Tile(t.pos)
		if tile and not tile:getItemById(t.id) then
			if tile:getCreatureCount() > 0 then
				waiting = true
			else
				Game.createItem(t.id, 1, t.pos)
				t.pos:sendMagicEffect(CONST_ME_POFF)
			end
		end
	end
	if waiting then
		addEvent(M.regrow, 10 * 1000)
	else
		M.tendrilState = "grown"
	end
end

function M.openTendrils()
	for _, t in ipairs(M.tendrils) do
		local found = tendrilAt(t.pos)
		if found then
			found:remove()
		end
		t.pos:sendMagicEffect(CONST_ME_POFF)
	end
	for _, p in ipairs(M.guards) do
		Game.createMonster("Cobra Assassin", p, false, true)
	end
	M.tendrilState = "open"
	addEvent(M.regrow, M.regrowTime * 1000)
end

local function burnEffect(left)
	if M.tendrilState ~= "burning" then
		return
	end
	for _, t in ipairs(M.tendrils) do
		t.pos:sendMagicEffect(CONST_ME_FIREAREA)
	end
	if left > 0 then
		addEvent(burnEffect, 2000, left - 2)
	end
end

function M.burn(player)
	if M.tendrilState ~= "grown" then
		msg(player, "The tendrils are already burning.") -- ours
		return false
	end
	M.tendrilState = "burning"
	burnEffect(M.burnTime)
	addEvent(M.openTendrils, M.burnTime * 1000)
	msg(player, "The lamp oil sets the tendrils on fire. It will take a while until the fire dies down.") -- ours
	return true
end

local flask = Action()
function flask.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not target or type(target) ~= "userdata" or not target.isItem or not target:isItem() then
		return false
	end
	local pos = target:getPosition()
	for _, t in ipairs(M.tendrils) do
		if t.pos == pos and target:getId() == t.id then
			if M.burn(player) then
				item:remove(1)
			end
			return true
		end
	end
	return false
end
flask:id(M.lampOil)
flask:register()

-- Treasure room: bag with Key 0303 and Greig's ledger -----------------------------

M.bones = Position(33396, 32640, 4)
M.keyId = 2972 -- golden key
M.keyAid = 303
M.ledgerAid = 48759

M.texts = {}
M.texts.ledger = [[Artefact Ledger of Greig, treasurer of the Order of the Cobra

(A scribbled note right on top of the list that says:)

I was trying to put a new artefact into the vault, you know, one of those Scarlett has deemed harmless and "righteous"... which means it's sellable now. Anyway, it was basically just an empty chest. Came in from the last expedition. I am sure there was nothing in it when I first layed eyes on it. However, when I later checked it in the vault, it had a few coins it it. When I returned with other things, the chest had been removed. Placed right outside the vault. Just to see if everything was alright, I checked the chest. And the coins were gone! I brought it back, together with other valuable stuff. It appeared to me that it would probably be a good idea to just place some of the stuff in the empty chest. But when I opened it, the coins were back, and it seems the thief added even more coins to make up for his mistake, who said there is no honour among thieves?

(A hastily scribbled note right below that says:)

After leaving, I found the chest right outside the vault and it was empty once again! When I put it back, the coins had been replaced and once again additional coins had been put into the chest! Under my watch!! Who does something like that. I will position myself next to the chest and remain in the vault to find the culprit if it's the last thing I do. Furthermore, I swear I saw something a few moments ago. Like a shadow, a shape more than anything. If that's the thief, he will answer to me right here.

Artefacts list VI:
(none of the artefacts in this list are readable)

Artefacts list VII:
1x Staff of Ignorance
1x Black Pocket Portal
1x Bright Arrow of Dark Vengeance
1x Brush of Dullness
1x Eye of the Blind
1x The Orb
1x Accursed Chest of Perplexion

(another small note has been scribbled below the text:)

Nb1-c3 (3/4)]]

M.texts.knightly = [[Knightly Successor Orders of Tibia, loose pages III

According to the last official records of the whereabouts of several old orders, Kesar Etzel may have been a driving force behind the falling out of several old orders with King Xenom. Reportedly he not only had a dispute with the King, he also fell out with the leader of the Order of the Falcon, Oberon, over how to guide the now exiled orders into a righteous future. While Kesar wanted to protect the known world from dark forces, Oberon was determined to explore foreign lands and discover more of the world, the knights swore to give their lives for. Traveling into the unknown and uncovering evil whereever its roots may be, was a prime goal for Oberon and the Order of the Falcon. Oberon was stubborn and impossible to control, even for his elder brother. Their sister Scarlett would not have any of this and neglected both her brothers ways. She had confidence in her knights, especially her strategist and loyal companion Galthen and wanted to go her own way after leaving Edron. Yet even she would have liked to see Kesar and Oberon to burry their differences and instead join in their endeavours. A consent was never reached, Kesar was the first to leave Edron and King Xenom behind. He avoided Oberon but remained in contact with Scarlett for a few years.

(someone has scribbled a small note under the text:)

e2-e4, d7-d6 (1/4)]]

M.texts.chef = [[Chef Luc Venin's Exquisite Cuisine with Poison

Introduction

In order to keep your warriors healthy, fed and, in addition to that, their poison resistence at a maximum - you have to add poison to your food.

(The book goes on about the manifold benefits of poisoned nutrition.)

Chapter 3 - Dosage is the Key

Adding just a pinch of the poison from the fangs of our great matron's domesticated cobras will significantly harden your organism. Not only against the bite of the glorious cobra, but all kinds of poisons. The potence of this poison is so high, that it can paralyse a grown man within the first 10 seconds of it entering the body. Death will follow in under two minute, so you will probably kick the proverbial bucket before even regaining the ability to move. Just a hint of the poison in a <this part has been completely redacted> will be enough for <again a redacted part> for a whole garrison of warriors. Even an already sensitised organism will not be able to process more than <again a redacted part> which will result in severe stomach aches and... well, if a whole crew of assassins has to deal with the runs at the same time, you will probably wish yourself away to a different place. Prevent situations like this and be careful with the dosage.

(someone scribbled a small note under the text:)

d2-d4, Ng8-f6 (2/4)]]

M.texts.zao = [[Dealings of the Knightly Orders in Zao

(This text consists of voluptuous descriptions of knights in shining armour, discovering the largely unexplored continent of Zao. With a focus on the disappearance of the Order of the Falcon and the quest for a lost almanac.)

(a small note has been scribbled below the text:)

Nb8-d7 (4/4)]]

local function hasKey(player)
	for slot = CONST_SLOT_FIRST, CONST_SLOT_LAST do
		local item = player:getSlotItem(slot)
		if item then
			if item:getId() == M.keyId and item:getActionId() == M.keyAid then
				return true
			end
			if item:isContainer() then
				for _, inner in ipairs(item:getItems(true)) do
					if inner:getId() == M.keyId and inner:getActionId() == M.keyAid then
						return true
					end
				end
			end
		end
	end
	return false
end
M.hasKey = hasKey

function M.takeBag(player)
	if player:getStorageValue(S.KeyBag) >= 1 and hasKey(player) then
		msg(player, "The pile of bones is empty.")
		return false
	end
	local bag = player:addItem(2853, 1)
	if not bag then
		player:sendCancelMessage("You have no room or not enough capacity to take it.") -- ours
		return false
	end
	local keyItem = bag:addItem(M.keyId, 1)
	if keyItem then
		keyItem:setActionId(M.keyAid)
	end
	local ledger = bag:addItem(2819, 1)
	if ledger then
		ledger:setActionId(M.ledgerAid)
		ledger:setAttribute(ITEM_ATTRIBUTE_TEXT, M.texts.ledger)
	end
	player:setStorageValue(S.KeyBag, 1)
	msg(player, "You have found a bag.")
	return true
end

local bones = Action()
function bones.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or item:getPosition() ~= M.bones then
		return false
	end
	M.takeBag(player)
	return true
end
bones:position(M.bones)
bones:register()

-- The ledger is longer than a parchment can hold: show it as a book.
local ledger = Action()
function ledger.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	player:showTextDialog(item, M.texts.ledger, false, #M.texts.ledger)
	return true
end
ledger:aid(M.ledgerAid)
ledger:register()

-- The other notes on the map --------------------------------------------------------

M.notes = {
	{ pos = Position(33401, 32660, 5), text = "chef" }, -- kitchen book, next to the cauldron (BR)
	{ pos = Position(33405, 32648, 4), text = "knightly" }, -- book in the locked room (BR)
	{ pos = Position(33300, 31196, 9), text = "zao" }, -- Gaffir's secret room: almanac on the stand, the book on the left (BR)
}

local notes = Action()
function notes.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	local pos = item:getPosition()
	for _, n in ipairs(M.notes) do
		if n.pos == pos then
			local text = M.texts[n.text]
			player:showTextDialog(item:getId(), text, false, #text)
			return true
		end
	end
	return false
end
for _, n in ipairs(M.notes) do
	notes:position(n.pos)
end
notes:register()

-- Gaffir's secret room ------------------------------------------------------------

M.fireBowl = Position(33394, 32669, 4)
M.gaffirCorpses = { 31307, 31308, 31309, 31310 }
M.carpet = {
	Position(33393, 32670, 4),
	Position(33394, 32670, 4),
	Position(33395, 32670, 4),
	Position(33393, 32671, 4),
	Position(33394, 32671, 4),
	Position(33395, 32671, 4),
}
M.secretRoom = { from = Position(33296, 31190, 9), to = Position(33308, 31202, 9) }
M.secretArrival = Position(33302, 31197, 9)
M.secretExit = Position(33394, 32670, 4) -- the fire portal's destination
M.secretTime = 3 * 60 -- seconds (EN)
M.timeDistortAlmanac = 31908

function M.corpseInBowl()
	local tile = Tile(M.fireBowl)
	if not tile then
		return false
	end
	for _, id in ipairs(M.gaffirCorpses) do
		if tile:getItemById(id) then
			return true
		end
	end
	return false
end

local function kickOut(playerId)
	local player = Player(playerId)
	if player and player:getPosition():isInRange(M.secretRoom.from, M.secretRoom.to) then
		player:teleportTo(M.secretExit)
		M.secretExit:sendMagicEffect(CONST_ME_TELEPORT)
		msg(player, "The room spits you out again.") -- ours
	end
end

local carpet = MoveEvent()
function carpet.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not on() then
		return true
	end
	-- only a step from the room itself; arriving through the fire portal does not count
	if fromPosition.z ~= position.z or position:getDistance(fromPosition) > 1 then
		return true
	end
	if not M.corpseInBowl() then
		return true
	end
	player:teleportTo(M.secretArrival)
	M.secretArrival:sendMagicEffect(CONST_ME_TELEPORT)
	addEvent(kickOut, M.secretTime * 1000, player:getId())
	return true
end
carpet:type("stepin")
for _, p in ipairs(M.carpet) do
	carpet:position(p)
end
carpet:register()

local almanac = Action()
function almanac.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not player:getPosition():isInRange(M.secretRoom.from, M.secretRoom.to) then
		return false
	end
	player:getPosition():sendMagicEffect(CONST_ME_PURPLEENERGY)
	player:addAchievement("Avid Spectral Reader")
	return true
end
almanac:id(M.timeDistortAlmanac)
almanac:register()

-- Chess -----------------------------------------------------------------------------

M.board = { x1 = 33397, y1 = 32640, x2 = 33404, y2 = 32647, z = 2 }
M.room = { from = Position(33393, 32639, 2), to = Position(33406, 32649, 2) }
M.chessBox = Position(33402, 32648, 2)
M.figurine = 17818
M.figurineSpawn = Position(33395, 32657, 2) -- Scarlett's room (BR)
M.lionPos = Position(33400, 32643, 2)
M.resetTime = 2 * 60 -- seconds (ours)

-- piece ids: jade (light, south, white) and obsidian (dark, north, black)
local J = { king = 31271, bishop = 31272, knight = 31273, rook = 31274, pawn = 31275 }
local O = { queen = 31276, king = 31277, bishop = 31278, knight = 31279, rook = 31280, pawn = 31281 }
M.pieceIds = { 31271, 31272, 31273, 31274, 31275, 31276, 31277, 31278, 31279, 31280, 31281 }

-- the board as it is on our map (x 33397..33404, y 32640..32647)
local function startLayout()
	local l = {}
	local back = { O.rook, O.knight, O.bishop, O.king, O.queen, O.bishop, O.knight, O.rook }
	local jade = { J.rook, J.knight, J.bishop, J.king, false, J.bishop, J.knight, J.rook }
	for i = 0, 7 do
		local x = 33397 + i
		l[key(Position(x, 32640, 2))] = back[i + 1]
		l[key(Position(x, 32641, 2))] = O.pawn
		l[key(Position(x, 32646, 2))] = J.pawn
		l[key(Position(x, 32647, 2))] = jade[i + 1] or nil
	end
	return l
end

-- e2-e4 d7-d6 d2-d4 Ng8-f6 Nb1-c3 Nb8-d7 with jade as white (TibiaWiki EN screenshot),
-- files a..h = x 33397..33404, rank r = y 32648 - r; cheesy figurine on the queen's square
local function goalLayout()
	local l = startLayout()
	local function move(fx, fy, tx, ty)
		local from, to = key(Position(fx, fy, 2)), key(Position(tx, ty, 2))
		l[to] = l[from]
		l[from] = nil
	end
	move(33401, 32646, 33401, 32644) -- e2-e4
	move(33400, 32641, 33400, 32642) -- d7-d6
	move(33400, 32646, 33400, 32644) -- d2-d4
	move(33403, 32640, 33402, 32642) -- Ng8-f6
	move(33398, 32647, 33399, 32645) -- Nb1-c3
	move(33398, 32640, 33400, 32641) -- Nb8-d7
	l[key(Position(33401, 32647, 2))] = M.figurine
	return l
end
M.startLayout = startLayout()
M.goalLayout = goalLayout()

-- every chess piece and cheesy figurine on one square
local function squareThings(pos)
	local things = {}
	local tile = Tile(pos)
	if not tile then
		return things
	end
	for _, item in ipairs(tile:getItems() or {}) do
		local id = item:getId()
		if id == M.figurine or table.contains(M.pieceIds, id) then
			for _ = 1, math.max(1, item:getCount()) do
				things[#things + 1] = id
			end
		end
	end
	return things
end

function M.isSolved()
	for x = M.board.x1, M.board.x2 do
		for y = M.board.y1, M.board.y2 do
			local pos = Position(x, y, M.board.z)
			local want = M.goalLayout[key(pos)]
			local things = squareThings(pos)
			if want then
				if #things ~= 1 or things[1] ~= want then
					return false
				end
			elseif #things > 0 then
				return false
			end
		end
	end
	return true
end

M.solving = false

function M.resetBoard()
	-- remove every piece and figurine in the room, then set the board up again
	for x = M.room.from.x, M.room.to.x do
		for y = M.room.from.y, M.room.to.y do
			local tile = Tile(Position(x, y, M.board.z))
			if tile then
				for _, id in ipairs(M.pieceIds) do
					local it = tile:getItemById(id)
					while it do
						it:remove()
						it = tile:getItemById(id)
					end
				end
				local fig = tile:getItemById(M.figurine)
				while fig do
					fig:remove()
					fig = tile:getItemById(M.figurine)
				end
			end
		end
	end
	for x = M.board.x1, M.board.x2 do
		for y = M.board.y1, M.board.y2 do
			local p = Position(x, y, M.board.z)
			local id = M.startLayout[key(p)]
			if id then
				Game.createItem(id, 1, p)
			end
		end
	end
	local spawnTile = Tile(M.figurineSpawn)
	if spawnTile and not spawnTile:getItemById(M.figurine) then
		Game.createItem(M.figurine, 1, M.figurineSpawn)
	end
	M.solving = false
end

function M.solve()
	if M.solving or not M.isSolved() then
		return false
	end
	M.solving = true
	for x = M.board.x1, M.board.x2 do
		for y = M.board.y1, M.board.y2 do
			Position(x, y, M.board.z):sendMagicEffect(CONST_ME_ENERGYAREA)
		end
	end
	Game.createMonster("Roaring Lion", M.lionPos, false, true)
	for _, spec in ipairs(Game.getSpectators(M.lionPos, false, true, 7, 7, 6, 6)) do
		local player = spec:getPlayer()
		if player and player:getPosition():isInRange(M.room.from, M.room.to) then
			player:setStorageValue(S.Chess, 1)
			msg(player, "The pieces are in place. Somewhere below, a metal wall moves with a grinding sound.") -- ours
		end
	end
	addEvent(M.resetBoard, M.resetTime * 1000)
	return true
end

local chessMove = MoveEvent()
function chessMove.onAddItem(moveitem, tileitem, position)
	if not on() then
		return true
	end
	addEvent(M.solve, 100)
	return true
end
chessMove:type("additem")
for x = M.board.x1, M.board.x2 do
	for y = M.board.y1, M.board.y2 do
		chessMove:position(Position(x, y, M.board.z))
	end
end
chessMove:register()

local chessBox = Action()
function chessBox.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or item:getPosition() ~= M.chessBox then
		return false
	end
	if M.solving then
		return true
	end
	M.resetBoard()
	msg(player, "You put the chess pieces back in their starting places.") -- ours
	return true
end
chessBox:position(M.chessBox)
chessBox:register()

-- Startup: key doors, the locked room and the Custodian's door ---------------------

M.keyDoors = {
	{ pos = Position(33402, 32653, 4), lock = 30772 }, -- room south-east of the treasure room (closed on our map)
	{ pos = Position(33389, 32653, 4) },
	{ pos = Position(33402, 32653, 3) },
	{ pos = Position(33383, 32674, 6) },
	{ pos = Position(33398, 32643, 1) },
	{ pos = Position(33398, 32662, 1) },
}
M.custodianDoor = Position(33366, 32825, 8)
local CUSTODIAN_DOOR_AID = 36569 -- actions_custodian_door.lua

M.doorIds = { 30772, 30773, 30774, 30775, 30776, 30777, 5733, 5736 }

function M.doorAt(pos)
	local tile = Tile(pos)
	if not tile then
		return nil
	end
	for _, id in ipairs(M.doorIds) do
		local door = tile:getItemById(id)
		if door then
			return door
		end
	end
	return nil
end

function M.setupMap()
	local done = 0
	for _, d in ipairs(M.keyDoors) do
		local door = M.doorAt(d.pos)
		if door then
			if d.lock and door:getId() ~= d.lock then
				door:transform(d.lock)
				door = Tile(d.pos):getItemById(d.lock)
			end
			if door then
				door:setActionId(M.keyAid)
				done = done + 1
			end
		end
	end
	local door = M.doorAt(M.custodianDoor)
	if door then
		door:setActionId(CUSTODIAN_DOOR_AID)
		done = done + 1
	end
	return done
end

local startup = GlobalEvent("FamilyCobraBastionStartup")
function startup.onStartup()
	if not on() then
		return true
	end
	local done = M.setupMap()
	logger.info("[Family] Cobra Bastion: {} doors set up", done)
	return true
end
startup:register()
