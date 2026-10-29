-- Gaia Family server: Grimvale Quest, mission "The Curse Spreads": world
-- objects and events (2026-10-28). Ours, not upstream. Story, states and NPC
-- dialogue: lib/others/family_grimvale.lua (FamilyCurseSpreads).
--
-- Placed at startup (missing on our map; positions from TibiaWiki EN):
--   * wooden grinder 33262,31824,5 (academy NW tower, two floors below Milos)
--   * box with Milos' scribbled note 33266,31849,8 (next to Puffels)
--   * dark stone totems at Krailos 33680,31630,7, Banuta 32809,32587,7 and
--     Vengoth 32949,31489,6 (the sources of the ley lines)
-- Already on the map: the library bookcases (central tower, floors +3/+4), the shadow bite
-- plants, the gold/silver nuggets in the Corym mines, Sinclair's apparatus,
-- the lever puzzle in the Grimvale ruins, the Last Sanctum basin and the two
-- death portals (Edron 33064,31977,9 and Last Sanctum 33429,32083,9).
-- Quest items lost on the way can be bought from Black Bert, as in Tibia.
-- Switch: Family.curseSpreads (lib/others/family_grimvale.lua).

local C = FamilyCurseSpreads
local S = Storage.Quest.FamilyCurseSpreads
local I = C.items

local BOX_AID = 48743

local GRINDER = { id = 21573, pos = Position(33262, 31824, 5) }
local BOX = { id = 2469, pos = Position(33266, 31849, 8) }
local TOTEM_ID = 27323

local function active()
	return Family.curseSpreads ~= false
end

local function msg(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

-- Milos' notes ---------------------------------------------------------------

-- The library in the central tower of the academy (TibiaWiki EN: gold
-- parchment on floor +4, silver and shadow bite parchments on floor +3;
-- TibiaWiki BR: "two on the third floor, one on the fourth"). The wiki text
-- we could read names no bookcase, so the first bookcase a player on the
-- mission uses on that floor gives that floor's notes; every other use
-- opens the bookcase as usual.
local LIBRARY = { x1 = 33262, y1 = 31829, x2 = 33274, y2 = 31840 }
local LIBRARY_NOTES = {
	[3] = { C.notes[1] }, -- floor +4: gold
	[4] = { C.notes[2], C.notes[3] }, -- floor +3: silver, shadow bite
}
local BOOKCASE_IDS = { 2435, 2436, 2437, 2438, 2439, 2440 }

local function giveNote(player, note, where)
	player:addItem(note.item, 1)
	C.addBit(player, S.Notes, note.bit)
	msg(player, string.format("You find %s %s %s", ItemType(note.item):getArticle(), ItemType(note.item):getName(), where)) -- ours
end

function C.inLibrary(pos)
	return LIBRARY_NOTES[pos.z] ~= nil and pos.x >= LIBRARY.x1 and pos.x <= LIBRARY.x2 and pos.y >= LIBRARY.y1 and pos.y <= LIBRARY.y2
end

-- Bookcases are containers (books inside): a bookcase only answers when it
-- has a note for this player; otherwise it opens as usual (2026-10-28, after
-- Rodrigo found the library's bookcases would no longer open).
local bookcase = Action()
function bookcase.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local pos = item:getPosition()
	if not active() or not C.inLibrary(pos) or C.state(player) ~= 2 then
		return false
	end
	for _, note in ipairs(LIBRARY_NOTES[pos.z]) do
		if player:getItemCount(note.item) < 1 then
			giveNote(player, note, "between the books.")
			return true
		end
	end
	return false
end
bookcase:id(unpack(BOOKCASE_IDS))
bookcase:register()

local box = Action()
function box.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if active() and C.state(player) == 2 and player:getItemCount(C.notes[4].item) < 1 then
		giveNote(player, C.notes[4], "in the box.")
		return true
	end
	msg(player, "The box is empty.") -- ours
	return true
end
box:aid(BOX_AID)
box:register()

-- Ingredients ----------------------------------------------------------------

-- shadow bite berries from the shadow bite plants underneath Edron
local plant = Action()
function plant.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not active() or C.state(player) ~= 3 then
		return false
	end
	if player:getItemCount(I.berries) > 0 then
		msg(player, "You already have some shadow bite berries.") -- ours
		return true
	end
	player:addItem(I.berries, 1)
	item:getPosition():sendMagicEffect(CONST_ME_GREEN_RINGS)
	msg(player, "You harvest some shadow bite berries.") -- ours
	return true
end
plant:id(27459)
plant:register()

-- gold and silver nuggets in the Corym mines: called from onUsePick
-- (scripts/lib/register_actions.lua)
local NUGGETS = {
	[27488] = { nuggets = I.goldNuggets, dust = I.goldDust, name = "gold" },
	[27489] = { nuggets = I.silverNuggets, dust = I.silverDust, name = "silver" },
}

function C.onPick(player, target, toPosition)
	local entry = target and target.isItem and target:isItem() and NUGGETS[target:getId()]
	if not entry or not active() or C.state(player) ~= 3 then
		return false
	end
	if player:getItemCount(entry.nuggets) > 0 or player:getItemCount(entry.dust) > 0 then
		msg(player, string.format("You already have enough %s.", entry.name == "gold" and "gold" or "silver")) -- ours
		return true
	end
	player:addItem(entry.nuggets, 1)
	toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
	msg(player, string.format("You mine some %s nuggets.", entry.name)) -- ours
	return true
end

-- the wooden grinder: nuggets to dust
local grind = Action()
function grind.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() or target:getId() ~= GRINDER.id then
		return false
	end
	local dust = item:getId() == I.goldNuggets and I.goldDust or I.silverDust
	local name = ItemType(item:getId()):getName()
	item:remove(1)
	player:addItem(dust, 1)
	toPosition:sendMagicEffect(CONST_ME_GREENSMOKE)
	msg(player, string.format("You grind the %s into fine %s.", name, ItemType(dust):getName())) -- ours
	return true
end
grind:id(I.goldNuggets, I.silverNuggets)
grind:register()

-- the apparatus in Sinclair's laboratory: blossoms, silver dust, gold dust,
-- shadow bite berries (TibiaWiki EN), each used on it in this order
local APPARATUS = { [8974] = true, [8975] = true }
local ORDER = { I.blossoms, I.silverDust, I.goldDust, I.berries }

local brew = Action()
function brew.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() or not APPARATUS[target:getId()] then
		return false
	end
	local pos = target:getPosition()
	if pos.z ~= 2 or pos.x < 33265 or pos.x > 33275 or pos.y < 31830 or pos.y > 31840 then
		return false
	end
	if not active() or C.state(player) ~= 3 then
		msg(player, "Nothing happens.") -- ours
		return true
	end
	local step = math.max(0, player:getStorageValue(S.Brew))
	if item:getId() ~= ORDER[step + 1] then
		msg(player, "This doesn't seem to be the right order. Better follow Milos' notes.") -- ours
		return true
	end
	item:remove(1)
	if step + 1 < #ORDER then
		player:setStorageValue(S.Brew, step + 1)
		pos:sendMagicEffect(CONST_ME_MAGIC_GREEN)
		msg(player, string.format("You put the %s into the apparatus.", ItemType(ORDER[step + 1]):getName())) -- ours
		return true
	end
	player:setStorageValue(S.Brew, 0)
	player:addItem(I.distillate, 1)
	pos:sendMagicEffect(CONST_ME_MAGIC_RED)
	msg(player, "The apparatus bubbles and hisses. Finally a few drops of a dark liquid drip out: you obtain a nightshade distillate.") -- ours
	return true
end
brew:id(I.blossoms, I.silverDust, I.goldDust, I.berries)
brew:register()

-- The ritual in the Grimvale ruins ----------------------------------------------
-- 5 levers (33446-33450,31573,11) above a 5x5 field (rows 31574-31578). A
-- pull moves the white tile of that column one row south (back to the top
-- after the last row). With the tiles forming a V (rows 0,1,2,1,0) any pull
-- makes the *click*, the ritual counts for that player and the tiles go back
-- to the top row (TibiaWiki EN).

local RITUAL = { x1 = 33446, y = 31573, z = 11, rows = 5, white = 463 }
local V_SHAPE = { 0, 1, 2, 1, 0 }
local plainGround = nil

local function whiteRow(x)
	for row = 0, RITUAL.rows - 1 do
		local tile = Tile(x, RITUAL.y + 1 + row, RITUAL.z)
		local ground = tile and tile:getGround()
		if ground and ground:getId() == RITUAL.white then
			return row
		end
	end
	return 0
end

local function setWhite(x, row)
	for r = 0, RITUAL.rows - 1 do
		local tile = Tile(x, RITUAL.y + 1 + r, RITUAL.z)
		local ground = tile and tile:getGround()
		if ground then
			local want = r == row and RITUAL.white or plainGround
			if want and ground:getId() ~= want then
				ground:transform(want)
			end
		end
	end
end

function C.ritualRows()
	local rows = {}
	for i = 1, 5 do
		rows[i] = whiteRow(RITUAL.x1 + i - 1)
	end
	return rows
end

function C.resetRitual()
	for i = 1, 5 do
		setWhite(RITUAL.x1 + i - 1, 0)
	end
end

local lever = Action()
function lever.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local pos = item:getPosition()
	if item:getId() == 9125 or item:getId() == 9126 then
		item:transform(item:getId() == 9125 and 9126 or 9125)
	end
	if not plainGround then
		return true
	end
	local rows = C.ritualRows()
	local formed = true
	for i = 1, 5 do
		if rows[i] ~= V_SHAPE[i] then
			formed = false
		end
	end
	if formed then
		player:say("*click*", TALKTYPE_MONSTER_SAY, false, nil, pos)
		for i = 1, 5 do
			Position(RITUAL.x1 + i - 1, RITUAL.y + 1 + V_SHAPE[i], RITUAL.z):sendMagicEffect(CONST_ME_HOLYAREA)
		end
		C.resetRitual()
		if active() and player:getStorageValue(S.Ritual) < 1 then
			player:setStorageValue(S.Ritual, 1)
			msg(player, "An array of light shoots down from the roof. Something has changed in the depths of Cormaya.") -- ours
		end
		return true
	end
	local x = pos.x
	setWhite(x, (whiteRow(x) + 1) % RITUAL.rows)
	return true
end
for i = 0, 4 do
	lever:position(Position(RITUAL.x1 + i, RITUAL.y, RITUAL.z))
end
lever:register()

-- Dark stone totems: the golden symbol of Suon -----------------------------------

local symbol = Action()
function symbol.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() or target:getId() ~= TOTEM_ID then
		return false
	end
	local pos = target:getPosition()
	for _, totem in ipairs(C.totems) do
		if totem.pos == pos then
			if not active() or C.state(player) ~= 8 then
				msg(player, "Nothing happens.") -- ours
			elseif C.addBit(player, S.Totems, totem.bit) then
				pos:sendMagicEffect(CONST_ME_HOLYAREA)
				msg(player, "You remove the curse that was put on this statue.")
			else
				msg(player, "You already removed the curse from this statue.") -- ours
			end
			return true
		end
	end
	return false
end
symbol:id(I.symbol)
symbol:register()

-- The Last Sanctum basin ---------------------------------------------------------

local BASIN = { x1 = 33338, y1 = 32055, x2 = 33360, y2 = 32075, z = 10 }
local hinted = {}

local basin = GlobalEvent("FamilyCurseSpreadsBasin")
function basin.onThink(interval)
	if not active() then
		return true
	end
	for _, player in ipairs(Game.getPlayers()) do
		local p = player:getPosition()
		if p.z == BASIN.z and p.x >= BASIN.x1 and p.x <= BASIN.x2 and p.y >= BASIN.y1 and p.y <= BASIN.y2 then
			local state = C.state(player)
			if state == 5 then
				if player:getStorageValue(S.Ritual) >= 1 then
					C.setState(player, 6)
					msg(player, "The clean water changes as soon as it flows into the basin. Obviously this is the spot where Cormaya's water gets tainted.")
				elseif (hinted[player:getId()] or 0) < os.time() then
					hinted[player:getId()] = os.time() + 300
					msg(player, "The water flowing into the basin looks strange, but you cannot tell why. Perhaps the ancient ritual in the ruins underneath Grimvale would reveal more.") -- ours
				end
			elseif state == 8 and C.allTotems(player) then
				C.setState(player, 9)
				msg(player, "The water that flows into the basin stays fresh and clean now. Obviously the curse is lifted.")
			end
		end
	end
	return true
end
basin:interval(1000)
basin:register()

-- Death portals between Edron and the Last Sanctum ---------------------------------

local PORTALS = {
	{ pos = Position(33064, 31977, 9), dest = Position(33429, 32082, 9) }, -- Edron cave -> Last Sanctum
	{ pos = Position(33429, 32083, 9), dest = Position(33065, 31977, 9) }, -- Last Sanctum -> Edron cave
}

local portal = MoveEvent()
function portal.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	for _, entry in ipairs(PORTALS) do
		if entry.pos == position then
			if active() and C.state(player) < 12 then
				player:teleportTo(fromPosition, true)
				fromPosition:sendMagicEffect(CONST_ME_MORTAREA)
				msg(player, "The death portal does not let you pass.") -- ours
				return true
			end
			player:teleportTo(entry.dest)
			entry.dest:sendMagicEffect(CONST_ME_MORTAREA)
			return true
		end
	end
	return true
end
portal:type("stepin")
for _, entry in ipairs(PORTALS) do
	portal:position(entry.pos)
end
portal:register()

-- The were-beast leaders ------------------------------------------------------------

local leaderDeath = CreatureEvent("FamilyCurseLeaderDeath")
function leaderDeath.onDeath(creature)
	local name = creature:getName():lower()
	for _, leader in ipairs(C.leaders) do
		if leader.name:lower() == name then
			onDeathForDamagingPlayers(creature, function(_, player)
				if active() and C.state(player) == 11 then
					C.addBit(player, S.Leaders, leader.bit)
				end
			end)
		end
	end
	return true
end
leaderDeath:register()

-- Startup ----------------------------------------------------------------------------

local function placeOnce(id, pos, aid)
	local tile = Tile(pos)
	if not tile then
		logger.error("[Family] The Curse Spreads: no tile at {},{},{}", pos.x, pos.y, pos.z)
		return
	end
	local found = tile:getItemById(id)
	if not found then
		found = Game.createItem(id, 1, pos)
	end
	if found and aid then
		found:setActionId(aid)
	end
end

local startup = GlobalEvent("FamilyCurseSpreadsStartup")
function startup.onStartup()
	placeOnce(GRINDER.id, GRINDER.pos)
	placeOnce(BOX.id, BOX.pos, BOX_AID)
	for _, totem in ipairs(C.totems) do
		placeOnce(TOTEM_ID, totem.pos)
	end
	for _, leader in ipairs(C.leaders) do
		local mType = MonsterType(leader.name)
		if mType then
			mType:registerEvent("FamilyCurseLeaderDeath")
		end
	end
	-- the plain ground of the ritual field: the first non-white ground below the levers
	for r = 1, RITUAL.rows - 1 do
		local tile = Tile(RITUAL.x1, RITUAL.y + 1 + r, RITUAL.z)
		local ground = tile and tile:getGround()
		if ground and ground:getId() ~= RITUAL.white then
			plainGround = ground:getId()
			break
		end
	end
	logger.info("[Family] The Curse Spreads: grinder, box and totems placed, ritual field ground {}", tostring(plainGround))
	return true
end
startup:register()
