-- Gaia Family server: The Scatterbrained Sorcerer Quest - objects, doors, kills and the
-- laboratory scene (2026-11-15). Ours, not upstream. Story, dialogue and storages:
-- data-otservbr-global/lib/others/family_sorcerer.lua (FamilySorcerer).
--
-- Eclesius' house south of Thais (our map): ground floor 32284-32294,32289-32295,7 (his room in
-- the middle, the living room behind the sealed door to the west), bedroom and library on +1,
-- attic on +2 (bats and the white cat), laboratory on -1 and cellar on -2 (demon cage and the
-- frog). Object messages from TibiaWiki BR/EN screenshots and pages; "ours" where they have none.
-- Doors: the house's sealed doors (living room, library, laboratory, cellar) open for Eclesius'
-- assistants, the attic only during the Exterminate task, Xodet's basement only while looking
-- for his first wand; the two cage doors stay locked (upstream they could simply be opened).

local FS = FamilySorcerer
local M = FS.M
local I = FS.items

local function on()
	return Family.scatterbrainedSorcerer == true
end

local function pos(x, y, z)
	return Position(x, y, z)
end

local function samePos(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

local function inBox(p, x1, y1, x2, y2, z)
	return p.z == z and p.x >= x1 and p.x <= x2 and p.y >= y1 and p.y <= y2
end

local function monsterSay(player, text, position)
	player:say(text, TALKTYPE_MONSTER_SAY, false, nil, position)
end

FS.places = {
	oven = pos(32288, 32293, 8),
	cauldron = { pos(32288, 32294, 8), pos(32289, 32294, 8), pos(32288, 32295, 8), pos(32289, 32295, 8) },
	barrel = pos(32291, 32295, 8),
	blenderLever = pos(32293, 32292, 8),
	blenderBowl = pos(32293, 32293, 8),
	brooms = pos(32293, 32294, 8), -- the counter where Eclesius' broom lies
	crystalBall = pos(32291, 32294, 6),
	fishBowl = pos(32289, 32291, 6),
	demonDoor = pos(32290, 32290, 9),
	frogDoor = pos(32289, 32293, 9),
	frog = pos(32289, 32294, 9),
	drawers = { pos(32284, 32291, 6), pos(32286, 32289, 8) }, -- library (EN), laboratory (BR)
	xodetBoxes = { pos(32396, 32220, 8), pos(32397, 32220, 8), pos(32398, 32220, 8), pos(32399, 32220, 8), pos(32396, 32221, 8), pos(32396, 32223, 8) },
	planks = { pos(32290, 32291, 9), pos(32291, 32291, 9), pos(32292, 32291, 9), pos(32293, 32291, 9), pos(32294, 32291, 9) },
	fireBasins = { pos(32289, 32289, 7), pos(32284, 32291, 8), pos(32293, 32295, 8) },
}
local P = FS.places

-- furniture to sweep: one bit per piece (some pieces have two squares)
FS.furniture = {
	{ name = "couch", ids = { 2402, 2403 }, at = { pos(32286, 32289, 7), pos(32287, 32289, 7) } },
	{ name = "crystal column", ids = { 8877 }, at = { pos(32285, 32290, 7) } },
	{ name = "crystal column", ids = { 8874 }, at = { pos(32285, 32294, 7) } },
	{ name = "chair", ids = { 8520 }, at = { pos(32290, 32289, 7) } },
	{ name = "chair", ids = { 8519 }, at = { pos(32289, 32290, 7) } },
	{ name = "table", ids = { 2346 }, at = { pos(32290, 32290, 7) } },
	{ name = "wardrobe", ids = { 2429, 2430 }, at = { pos(32289, 32289, 6), pos(32289, 32290, 6) } },
	{ name = "paravent", ids = { 1416 }, at = { pos(32289, 32293, 6) } },
	{ name = "paravent", ids = { 1416 }, at = { pos(32290, 32293, 6) } },
	{ name = "paravent", ids = { 1416 }, at = { pos(32291, 32293, 6) } },
	{ name = "bed", ids = { 736, 737 }, at = { pos(32289, 32294, 6), pos(32290, 32294, 6) } },
	{ name = "drawers", ids = { 7162 }, at = { pos(32289, 32295, 6) } },
}

local function furnitureIndex(target, toPosition)
	if not target or not target.itemid then
		return nil
	end
	for index, piece in ipairs(FS.furniture) do
		if table.contains(piece.ids, target.itemid) then
			for _, at in ipairs(piece.at) do
				if samePos(at, toPosition) then
					return index
				end
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- notes pinned on the walls (TibiaWiki EN "Note Pinned on the Wall"; our map has them empty)
-- ---------------------------------------------------------------------------
FS.notes = {
	{ pos(32288, 32291, 6), 6122, "Recipe for fish food supporting linguistic development (prepare fresh daily)\n- 1 ounce of flour\n- 1 worm\n- 1 white mushroom\n- 1 egg\n- 1 sling herb\nBlend carefully and sprinkle into water. Repeat words which you want the fish to learn." },
	{ pos(32287, 32289, 6), 6121, "To Sort\n- \"Great Encyclopedia of the Magiverse\" by Fimon Fesork\n- \"Interesting Trivia about Grass Growth\" by Professor Will B. Boart\n- \"Collection of Counterspells against Counterspells\" by Isa Craven\n- \"Mathemagics for Dummies and Forgetful People\" by ...?\n- \"How to transmute gold into lead and other useful conversions\" by Richard Nevermore\n- \"Necromancing at its most romantic\" by Mistress of Darkness\n- \"Spellscroll of the Apocalypse\" (handle with great care)" },
	{ pos(32287, 32293, 8), 6122, "Reminder for special crystal ball polish recipe:\n- Melt a honeycomb on this magical oven until some wax is extracted\n- Use with a fresh grave flower for better consistency" },
	{ pos(32288, 32288, 8), 6121, "Magical Oil\nIngredients:\n- Vial of Oil\n- Skull\n- Red Apple\n- Wolf Paw" },
	{ pos(32289, 32288, 9), 6121, "Note to myself from myself:\nNEVER EVER open this door!\nKeep it oiled and locked, make sure the wooden barriers are stable, and maybe some music from a lyre...?" },
}
-- the labels above the pots (EN: blood "Slime", slime "Mud", water "Urine", beer "Water", urine "Blood")
-- (our map stores the pots with the old fluid numbers: 1 water, 2 blood, 3 beer, 4 slime, 5 urine)
local potLabels = { [2] = "Slime", [4] = "Mud", [1] = "Urine", [3] = "Water", [5] = "Blood" }

local function writeNotes()
	local written = 0
	for _, note in ipairs(FS.notes) do
		local tile = Tile(note[1])
		local item = tile and tile:getItemById(note[2])
		if item then
			item:setAttribute(ITEM_ATTRIBUTE_TEXT, note[3])
			written = written + 1
		else
			logger.warn("[FamilySorcerer] note {} missing at {}", note[2], note[1]:toString())
		end
	end
	for x = 32289, 32293 do
		local noteTile, potTile = Tile(pos(x, 32288, 8)), Tile(pos(x, 32289, 8))
		local note = noteTile and noteTile:getItemById(6121)
		local pot = potTile and potTile:getItemById(3465)
		local label = pot and potLabels[pot:getSubType()]
		if note and label then
			note:setAttribute(ITEM_ATTRIBUTE_TEXT, label)
			written = written + 1
		end
	end
	return written
end

-- Eclesius' broom (EN: "can be found as a daily spawn in Eclesius' house")
function FS.onSweepTaken()
	local tile = Tile(P.brooms)
	if tile and not tile:getItemById(I.broom) then
		Game.createItem(I.broom, 1, P.brooms)
	end
end

-- ---------------------------------------------------------------------------
-- doors
-- ---------------------------------------------------------------------------
local doors = {
	{ at = pos(32288, 32292, 7), closed = 6258, open = 6259, may = FS.isAssistant }, -- to the living room
	{ at = pos(32288, 32292, 6), closed = 5113, open = 5114, may = FS.isAssistant }, -- library
	{ at = pos(32287, 32292, 8), closed = 6258, open = 6259, may = FS.isAssistant }, -- laboratory
	{ at = pos(32287, 32292, 9), closed = 6258, open = 6259, may = FS.isAssistant }, -- cellar
	{
		at = pos(32290, 32292, 5), -- attic
		closed = 6907,
		open = 6908,
		may = function(player)
			local state = FS.taskState(player, "exterminate")
			return state == FS.ACTIVE or state == FS.READY
		end,
	},
	{
		at = pos(32399, 32224, 8), -- Xodet's basement, from the sewers
		closed = 1644,
		open = 1645,
		may = function(player)
			return FS.mission(player) == M.WAND_ASKED
		end,
	},
}

for _, door in ipairs(doors) do
	local action = Action()
	function action.onUse(player, item, fromPosition, target, toPosition, isHotkey)
		if item.itemid == door.open then
			if Tile(door.at):getTopCreature() then
				return true
			end
			item:transform(door.closed)
			return true
		end
		if item.itemid ~= door.closed then
			return false
		end
		if not on() or not door.may(player) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to be sealed against unwanted intruders.")
			return true
		end
		item:transform(door.open)
		item:getPosition():sendSingleSoundEffect(SOUND_EFFECT_TYPE_ACTION_OPEN_DOOR)
		player:teleportTo(door.at, true)
		return true
	end
	action:position(door.at)
	action:register()
end

-- the cage doors stay shut (upstream: plain closed doors that anyone could open)
local cageDoor = Action()
function cageDoor.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	player:sendCancelMessage("It is locked.")
	return true
end
cageDoor:position(P.demonDoor)
cageDoor:position(P.frogDoor)
cageDoor:register()

-- ---------------------------------------------------------------------------
-- daily tasks
-- ---------------------------------------------------------------------------
local function taskActive(player, task)
	return FS.taskState(player, task) == FS.ACTIVE
end

-- broom: sweep the furniture
local broom = Action()
function broom.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not target or not toPosition then
		return false
	end
	for _, basin in ipairs(P.fireBasins) do
		if samePos(basin, toPosition) and target.itemid == 8524 then
			toPosition:sendMagicEffect(CONST_ME_HITBYFIRE)
			item:remove(1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Oops! The broom caught fire and burnt to ashes.") -- ours
			return true
		end
	end
	local index = furnitureIndex(target, toPosition)
	if not index then
		return false
	end
	monsterSay(player, "<swoosh>", toPosition)
	toPosition:sendMagicEffect(CONST_ME_POFF)
	if taskActive(player, "sweep") then
		local mask = FS.kvNumber(player, "sweep")
		if not FS.hasBit(mask, index - 1) then
			mask = mask + 2 ^ (index - 1)
			FS.kv(player):set("sweep", mask)
		end
		local done = FS.bitCount(mask, #FS.furniture - 1)
		if done >= #FS.furniture then
			FS.setTask(player, "sweep", FS.READY)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Everything is dust-free now. Tell Eclesius.") -- ours
		end
	end
	return true
end
broom:id(I.broom)
broom:register()

-- special polish on the crystal ball
local polish = Action()
function polish.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not toPosition or not samePos(toPosition, P.crystalBall) then
		return false
	end
	if not taskActive(player, "polish") then
		player:sendCancelMessage("Eclesius didn't ask you to polish his crystal ball today.") -- ours
		return true
	end
	item:remove(1)
	FS.setTask(player, "polish", FS.READY)
	monsterSay(player, "<squeak squeak>", toPosition)
	toPosition:sendMagicEffect(CONST_ME_SPARKLING)
	return true
end
polish:id(I.polish)
polish:register()

-- fish flakes into the goldfish bowl
local flakes = Action()
function flakes.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not toPosition or not samePos(toPosition, P.fishBowl) then
		return false
	end
	if not taskActive(player, "feed") then
		player:sendCancelMessage("Eclesius didn't ask you to feed his fish today.") -- ours
		return true
	end
	item:remove(1)
	FS.setTask(player, "feed", FS.READY)
	monsterSay(player, "<crumble>", toPosition)
	toPosition:sendMagicEffect(CONST_ME_BUBBLES)
	return true
end
flakes:id(I.fishFlakes)
flakes:register()

-- the magical blending device: put the ingredients in the bowl, pull the lever
FS.fishFood = { [3603] = true, [3492] = true, [3723] = true, [3606] = true, [3738] = true } -- flour, worm, white mushroom, egg, sling herb
local blender = Action()
function blender.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	if item.itemid == 9110 then
		item:transform(9111)
	elseif item.itemid == 9111 then
		item:transform(9110)
	end
	local tile = Tile(P.blenderBowl)
	if not tile then
		return true
	end
	local found, extra, placed = {}, false, {}
	for _, thing in ipairs(tile:getItems() or {}) do
		local id = thing:getId()
		if id ~= 9108 and id ~= 2345 and ItemType(id):isMovable() then
			placed[#placed + 1] = thing
			if FS.fishFood[id] and not found[id] and thing:getCount() == 1 then
				found[id] = true
			else
				extra = true
			end
		end
	end
	if #placed == 0 then
		return true
	end
	local complete = not extra
	for id in pairs(FS.fishFood) do
		if not found[id] then
			complete = false
		end
	end
	for _, thing in ipairs(placed) do
		thing:remove()
	end
	if complete then
		Game.createItem(I.fishFlakes, 1, P.blenderBowl)
		P.blenderBowl:sendMagicEffect(CONST_ME_MAGIC_GREEN)
		monsterSay(player, "<whirrrrr>", P.blenderBowl) -- ours
	else
		-- EN: any other combination is deleted
		P.blenderBowl:sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The blender grinds everything into a useless mush. That was not the recipe.") -- ours
	end
	return true
end
blender:position(P.blenderLever)
blender:register()

-- honeycomb on the oven of the laboratory (called from the_cursed_crystal/actions_Misc.lua)
function FS.onHoneycomb(player, item, target, toPosition)
	if not on() or item.itemid ~= 5902 or not toPosition or not samePos(toPosition, P.oven) then
		return false
	end
	item:remove(1)
	player:addItem(I.moltenWax, 1)
	toPosition:sendMagicEffect(CONST_ME_HITBYFIRE)
	return true
end

-- molten wax on a grave flower (called from the_cursed_crystal/actions_MedusaOil.lua)
function FS.onMoltenWax(player, item, target, toPosition)
	if not on() or item.itemid ~= I.moltenWax or not target or not target.itemid or target.itemid ~= 3661 then
		return false
	end
	item:remove(1)
	target:remove(1)
	player:addItem(I.polish, 1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end

-- the magical key in the barrel (EN: every assistant can get it once a day)
local barrel = Action()
function barrel.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not taskActive(player, "prevent") then
		return false
	end
	local today = FS.day()
	if FS.kv(player):get("keyDay") == today and player:getItemCount(I.cageKey) > 0 then
		return false
	end
	FS.kv(player):set("keyDay", today)
	player:addItem(I.cageKey, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a magical key.")
	return true
end
barrel:position(P.barrel)
barrel:register()

local bitIndex = { [1] = 0, [2] = 1, [4] = 2, [8] = 3 }
local function preventStep(player, bit, text, position)
	local mask = FS.kvNumber(player, "prevent")
	if not FS.hasBit(mask, bitIndex[bit]) then
		mask = mask + bit
		FS.kv(player):set("prevent", mask)
	end
	if text then
		monsterSay(player, text, position)
	end
	if mask == FS.PREVENT_ALL then
		FS.setTask(player, "prevent", FS.READY)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The cage is oiled, locked and safe, and the demon is calm. Tell Eclesius.") -- ours
	end
end

local function onDemonDoor(toPosition)
	return toPosition and samePos(toPosition, P.demonDoor)
end

local oil = Action()
function oil.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not onDemonDoor(toPosition) then
		return false
	end
	if not taskActive(player, "prevent") then
		player:sendCancelMessage("Eclesius didn't ask you to take care of the cage today.") -- ours
		return true
	end
	item:remove(1)
	toPosition:sendMagicEffect(CONST_ME_YELLOW_RINGS)
	preventStep(player, FS.PREVENT_OIL, "<glub glub>", toPosition)
	return true
end
oil:id(I.magicalOil)
oil:register()

local cageKey = Action()
function cageKey.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not onDemonDoor(toPosition) then
		return false
	end
	if not taskActive(player, "prevent") then
		player:sendCancelMessage("The door is already locked.") -- ours
		return true
	end
	preventStep(player, FS.PREVENT_LOCK, "<klick>", toPosition)
	return true
end
cageKey:id(I.cageKey)
cageKey:register()

local hammer = Action()
function hammer.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not toPosition then
		return false
	end
	local index
	for i, at in ipairs(P.planks) do
		if samePos(at, toPosition) then
			index = i
		end
	end
	if not index then
		return false
	end
	monsterSay(player, "<tok tok tok>", toPosition)
	toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
	if taskActive(player, "prevent") then
		local planks = FS.kvNumber(player, "planks")
		if not FS.hasBit(planks, index - 1) then
			planks = planks + 2 ^ (index - 1)
			FS.kv(player):set("planks", planks)
		end
		if FS.bitCount(planks, #P.planks - 1) >= FS.PLANKS_NEEDED then
			preventStep(player, FS.PREVENT_PLANKS)
		end
	end
	return true
end
hammer:id(3459)
hammer:register()

-- the lyre in front of the cage (called from actions/other/music.lua)
function FS.onMusic(player, item)
	if not on() or (item.itemid ~= 2949 and item.itemid ~= 3260) then
		return false
	end
	local p = player:getPosition()
	if p.z ~= P.demonDoor.z or p:getDistance(P.demonDoor) > 2 then
		return false
	end
	p:sendMagicEffect(CONST_ME_SOUND_GREEN)
	monsterSay(player, "<pling plong>", p)
	if taskActive(player, "prevent") then
		player:say("Sleeeep... my little demon... tralala~", TALKTYPE_MONSTER_SAY)
		preventStep(player, FS.PREVENT_LYRE)
	end
	return true
end

-- bats and the white cat in the attic
local death = CreatureEvent("FamilySorcererDeath")
function death.onDeath(creature, corpse, lastHitKiller, mostDamageKiller)
	if not on() or not inBox(creature:getPosition(), 32283, 32289, 32293, 32296, 5) then
		return true
	end
	local name = creature:getName():lower()
	if name == "bat" then
		onDeathForParty(creature, mostDamageKiller, function(_, player)
			if taskActive(player, "exterminate") then
				local bats = FS.kvNumber(player, "bats") + 1
				FS.kv(player):set("bats", bats)
				if bats >= 3 then
					FS.setTask(player, "exterminate", FS.READY)
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Three bats less in Eclesius' attic. Tell him.") -- ours
				end
			end
		end)
	elseif name == "cat" then
		-- Tibia: 30 days without this task; here only that day (Rodrigo's choice)
		for playerId in pairs(creature:getDamageMap()) do
			local player = Player(playerId)
			if player and FS.isAssistant(player) then
				local state = FS.taskState(player, "exterminate")
				if state ~= FS.REPORTED then
					FS.setTask(player, "exterminate", FS.FAILED)
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You hurt Eclesius' little white cat! He won't let you do the Exterminate task again today.") -- ours
				end
			end
		end
	end
	return true
end
death:register()

-- ---------------------------------------------------------------------------
-- missions
-- ---------------------------------------------------------------------------

-- Eclesius' sandals: cauldron, dead skunk, something that smells good
local sandals = Action()
function sandals.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or not target or not target.itemid then
		return false
	end
	local m = FS.mission(player)
	if m == M.SANDALS_GIVEN then
		for _, at in ipairs(P.cauldron) do
			if toPosition and samePos(at, toPosition) then
				FS.setMission(player, M.BOILED)
				toPosition:sendMagicEffect(CONST_ME_BUBBLES)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You dip the sandals into the boiling water of the cauldron. They look much cleaner now.") -- ours
				return true
			end
		end
	elseif m == M.SKUNK_ASKED then
		if table.contains({ 6035, 4227, 4228 }, target.itemid) then
			FS.setMission(player, M.SKUNKED)
			player:getPosition():sendMagicEffect(CONST_ME_POISONAREA)
			player:say("Wow. That is a REALLY bad smell. You can't help but wonder if that's really going to work.", TALKTYPE_MONSTER_SAY)
			return true
		end
	elseif m == M.FRAGRANCE_CHOSEN then
		local f = FS.fragrances[FS.kv(player):get("fragrance") or ""]
		if f and table.contains(f.targets, target.itemid) then
			FS.setMission(player, M.FRAGRANT)
			player:getPosition():sendMagicEffect(CONST_ME_HEARTS)
			player:say(f.message, TALKTYPE_MONSTER_SAY)
			return true
		end
	end
	return false
end
sandals:id(I.eclesiusSandals)
sandals:register()

-- the questionnaire in the drawers
local function questionnaire(player)
	local item = player:addItem(I.parchment, 1)
	if item then
		item:setAttribute(ITEM_ATTRIBUTE_TEXT, "Questionaire\n\n1. What's most important in a relationship for you?\n2. What's your ideal date location?\n3. What physical attribute should your ideal partner have?\n4. Tell me something you love.\n5. Tell me something you dislike.\n6. What's an important character trait for you?\n7. What's your favourite colour?\n8. What's your greatest fear?")
		item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, "There's a questionaire for potential lovers on it.")
	end
	return item
end

local drawers = Action()
function drawers.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or FS.mission(player) ~= M.QUESTIONNAIRE then
		return false
	end
	if FS.kv(player):get("parchment") and player:getItemCount(I.parchment) > 0 then
		return false
	end
	if questionnaire(player) then
		FS.kv(player):set("parchment", 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a parchment.")
		return true
	end
	return false
end
for _, at in ipairs(P.drawers) do
	drawers:position(at)
end
drawers:register()

-- Xodet's first wand, in a box of his basement
local xodetBox = Action()
function xodetBox.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or FS.mission(player) ~= M.WAND_ASKED or player:getItemCount(I.wand) > 0 then
		return false
	end
	player:addItem(I.wand, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found Xodet's first wand.")
	return true
end
for _, at in ipairs(P.xodetBoxes) do
	xodetBox:position(at)
end
xodetBox:register()

-- the bundle of rags: dress up as a princess in front of the frog
local rags = Action()
function rags.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	local m = FS.mission(player)
	if m < M.KISS_ASKED then
		player:say("You should consult with Eclesius first.", TALKTYPE_MONSTER_SAY)
		return true
	elseif m > M.KISS_ASKED then
		player:say("This is not a good time to dress up like a princess.", TALKTYPE_MONSTER_SAY)
		return true
	end
	local p = player:getPosition()
	if p.z ~= P.frog.z or p:getDistance(P.frog) > 3 then
		player:say("This is not a good area to dress up like a princess. Better do it right in front of the frog, else a dragon may spot you.", TALKTYPE_MONSTER_SAY)
		return true
	end
	local condition = Condition(CONDITION_OUTFIT)
	condition:setTicks(3 * 60 * 1000)
	condition:setOutfit({ lookType = 140, lookHead = 0, lookBody = 0, lookLegs = 0, lookFeet = 0, lookAddons = 0 }) -- a white noblewoman (EN)
	player:addCondition(condition)
	FS.kv(player):set("princessUntil", os.time() + 3 * 60)
	p:sendMagicEffect(CONST_ME_HEARTS)
	player:say("You look like a beautiful princess... at least for a short time. Hurry up and kiss the frog!", TALKTYPE_MONSTER_SAY)
	return true
end
rags:id(I.rags)
rags:register()

-- ---------------------------------------------------------------------------
-- Mission 3: the laboratory scene (our map has no space-time continuum room)
-- ---------------------------------------------------------------------------
FS.scenePlaces = {
	levers = { left = pos(32289, 32291, 8), middle = pos(32290, 32291, 8), right = pos(32291, 32291, 8) },
	arrive = pos(32290, 32292, 8),
	grodrik = pos(32289, 32293, 8),
	amarie = pos(32291, 32293, 8),
	result = pos(32290, 32293, 8),
	eclesius = pos(32292, 32294, 8),
	back = pos(32290, 32292, 7),
}
local SP = FS.scenePlaces
local LEVER, LEVER_PULLED = 2772, 2773
FS.SCENE_SECONDS = 15 * 60
FS.sceneResults = { "Toad", "Gozzler", "Mutated Human" } -- TibiaWiki EN

local scene = nil -- { playerId, npcId, grodrikId, amarieId, resultId, event }

local function removeCreature(id)
	local creature = id and Creature(id)
	if creature then
		creature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		creature:remove()
	end
end

local function removeLevers()
	for _, at in pairs(SP.levers) do
		local tile = Tile(at)
		if tile then
			for _, id in ipairs({ LEVER, LEVER_PULLED }) do
				local lever = tile:getItemById(id)
				if lever then
					lever:remove()
				end
			end
		end
	end
end

-- takeUp: back upstairs at the end of the scene
function FS.endScene(player, takeUp)
	if not scene then
		return
	end
	local current = scene
	scene = nil
	if current.event then
		stopEvent(current.event)
	end
	local npc = current.npcId and Npc(current.npcId)
	if npc and current.npcHome then
		npc:teleportTo(current.npcHome)
		current.npcHome:sendMagicEffect(CONST_ME_TELEPORT)
	end
	removeCreature(current.grodrikId)
	removeCreature(current.amarieId)
	removeCreature(current.resultId)
	removeLevers()
	player = player or Player(current.playerId)
	if not player then
		return
	end
	local m = FS.mission(player)
	if takeUp or m == M.RESULT then
		if m == M.RESULT then
			FS.setMission(player, M.BACK)
		end
	elseif m == M.SCENE then
		FS.setMission(player, M.BONUS)
	end
	if inBox(player:getPosition(), 32284, 32289, 32294, 32296, 8) then
		player:teleportTo(SP.back)
		SP.back:sendMagicEffect(CONST_ME_TELEPORT)
	end
end

-- npc: the Eclesius the player talks to; he comes along to the laboratory and goes back home after
-- (a second Eclesius would take his name: Npc("Eclesius") found nobody after it was removed).
function FS.startScene(player, npc)
	if scene then
		local owner = Player(scene.playerId)
		if owner and owner:getId() ~= player:getId() then
			return false
		end
		FS.endScene(owner)
	end
	for _, at in pairs(SP.levers) do
		local tile = Tile(at)
		if not tile then
			logger.error("[FamilySorcerer] laboratory square {} missing", at:toString())
			return false
		end
		Game.createItem(LEVER, 1, at)
	end
	npc = npc or Npc("Eclesius")
	scene = { playerId = player:getId() }
	if npc then
		scene.npcId = npc:getId()
		scene.npcHome = npc:getPosition()
		npc:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		npc:teleportTo(SP.eclesius)
	end
	local playerId = player:getId()
	scene.event = addEvent(function()
		if scene and scene.playerId == playerId then
			FS.endScene(Player(playerId), false)
		end
	end, FS.SCENE_SECONDS * 1000)
	FS.kv(player):set("sceneListening", 0)
	FS.setMission(player, M.SCENE)
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:teleportTo(SP.arrive)
	SP.arrive:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

-- the scene's own creatures: Grodrik and Amarie as TibiaWiki EN shows them (harmless)
local function sceneCreature(name, description, outfit, voices)
	local mType = Game.createMonsterType(name)
	local monster = {}
	monster.description = description
	monster.experience = 0
	monster.outfit = outfit
	monster.health = 100
	monster.maxHealth = 100
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
	monster.voices = voices
	monster.loot = {}
	monster.attacks = {}
	monster.defenses = { defense = 0, armor = 0, mitigation = 0 }
	monster.elements = {}
	monster.immunities = {}
	mType:register(monster)
end

sceneCreature("Grodrik", "Grodrik", { lookType = 160, lookHead = 96, lookBody = 120, lookLegs = 60, lookFeet = 116, lookAddons = 0, lookMount = 0 }, {
	interval = 4000,
	chance = 30,
	{ text = "By the great mother of fire! What is this?", yell = false },
	{ text = "Can I at least have a beer??", yell = false },
	{ text = "I'll hail no one, not even Durin, until I am brought back to where I was just moments ago!", yell = false },
	{ text = "If I ever find out who is behind all that... GRR!", yell = false },
	{ text = "What the... where is this place?", yell = false },
})
sceneCreature("Amarie", "Amarie", { lookType = 159, lookHead = 128, lookBody = 34, lookLegs = 28, lookFeet = 116, lookAddons = 0, lookMount = 0 }, {
	interval = 4000,
	chance = 30,
	{ text = "Aaaaah! Let me out of here!!", yell = false },
	{ text = "Help! Where am I?", yell = false },
	{ text = "Noooo! What are you doing?", yell = false },
	{ text = "Ulathil beia Thratha!", yell = false },
	{ text = "What is this devilish scheme??", yell = false },
})

local function spawn(name, at)
	local creature = Game.createMonster(name, at, false, true)
	if creature then
		at:sendMagicEffect(CONST_ME_TELEPORT)
		return creature:getId(), creature
	end
end

local sceneLever = Action()
function sceneLever.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() or item.itemid ~= LEVER and item.itemid ~= LEVER_PULLED then
		return false
	end
	if not scene or scene.playerId ~= player:getId() or FS.mission(player) ~= M.SCENE then
		player:sendCancelMessage("Nothing happens.") -- ours
		return true
	end
	if FS.kvNumber(player, "sceneListening") ~= 1 then
		player:sendCancelMessage("Better listen to Eclesius first.") -- ours
		return true
	end
	local at = item:getPosition()
	if samePos(at, SP.levers.left) then
		if not (scene.grodrikId and Creature(scene.grodrikId)) then
			item:transform(LEVER_PULLED)
			local id, creature = spawn("Grodrik", SP.grodrik)
			scene.grodrikId = id
			if creature then
				creature:say("Ahhhhhhh", TALKTYPE_MONSTER_SAY)
			end
		end
	elseif samePos(at, SP.levers.right) then
		if not (scene.grodrikId and Creature(scene.grodrikId)) then
			player:sendCancelMessage("Eclesius said: first the left lever, then the right one.") -- ours
			return true
		end
		if not (scene.amarieId and Creature(scene.amarieId)) then
			item:transform(LEVER_PULLED)
			local id, creature = spawn("Amarie", SP.amarie)
			scene.amarieId = id
			if creature then
				creature:say("Uah?", TALKTYPE_MONSTER_SAY)
			end
		end
	elseif samePos(at, SP.levers.middle) then
		if not (scene.grodrikId and Creature(scene.grodrikId) and scene.amarieId and Creature(scene.amarieId)) then
			player:sendCancelMessage("Eclesius said: once both subjects are there, the lever in the middle.") -- ours
			return true
		end
		item:transform(LEVER_PULLED)
		removeCreature(scene.grodrikId)
		removeCreature(scene.amarieId)
		scene.grodrikId, scene.amarieId = nil, nil
		for _, p in ipairs({ SP.grodrik, SP.amarie, SP.result }) do
			p:sendMagicEffect(CONST_ME_HEARTS)
		end
		scene.resultId = spawn(FS.sceneResults[math.random(#FS.sceneResults)], SP.result)
		FS.setMission(player, M.RESULT)
		player:say("That doesn't look like anything Eclesius predicted it would look like.", TALKTYPE_MONSTER_SAY)
	end
	return true
end
for _, at in pairs(SP.levers) do
	sceneLever:position(at)
end
sceneLever:register()

local logout = CreatureEvent("FamilySorcererLogout")
function logout.onLogout(player)
	if scene and scene.playerId == player:getId() then
		FS.endScene(player, false)
	end
	return true
end
logout:register()

local login = CreatureEvent("FamilySorcererLogin")
function login.onLogin(player)
	player:registerEvent("FamilySorcererLogout")
	-- a scene left by a crash or restart
	local m = FS.mission(player)
	if (m == M.SCENE or m == M.RESULT) and not (scene and scene.playerId == player:getId()) then
		FS.setMission(player, m == M.RESULT and M.BACK or M.BONUS)
		if inBox(player:getPosition(), 32284, 32289, 32294, 32296, 8) then
			player:teleportTo(SP.back)
		end
	end
	return true
end
login:register()

-- ---------------------------------------------------------------------------
-- Samael, the demon in the cage (TibiaWiki EN): never seen, only heard from outside the
-- cellar, from a cave of the Thais sewers and from the Thais prison. EN puts him one square
-- east of the bars (32303,32290,9), which has no ground on our map, so he waits inside the cage.
-- An invisible creature of our own speaks his ten EN sounds to the players in those places.
-- ---------------------------------------------------------------------------
FS.samael = {
	at = pos(32301, 32290, 9),
	-- hearing places: x1, y1, x2, y2, z
	heard = {
		{ 32284, 32286, 32302, 32297, 9 }, -- outside his cellar (EN 32293,32293,9)
		{ 32297, 32253, 32311, 32267, 9 }, -- the cave in the Thais sewers (EN 32304,32260,9)
		{ 32320, 32267, 32334, 32281, 9 }, -- the Thais prison (EN 32327,32274,9)
	},
	minSeconds = 60,
	maxSeconds = 150, -- ours
	sounds = {
		"AAARRRRRRRR! YOU WILL PAY SO DEARLY FOR THIS!",
		"ARE YOU INSANE TRYING TO TRAP ME HERE?!",
		"I'M THE LORD OF ALL LORDS! LET ME OUT OF HERE!",
		"I HATE YOU ALL!",
		"JUST YOU WAIT FOR ME.",
		"RAHHHH!",
		"THIS PUNY PRISON WILL NEVER HOLD ME!",
		"WHEN I GET OUT OF HERE....",
		"YOU CALLED ME, NOW YOU WILL TAKE RESPONSIBILITY.",
		"YOU HAVE NO IDEA WHAT YOU'VE DONE.",
	},
}
local SA = FS.samael

do
	local mType = Game.createMonsterType("Samael")
	local monster = {}
	monster.description = "Samael"
	monster.experience = 0
	monster.outfit = { lookType = 0, lookTypeEx = 0 }
	monster.health = 1000000
	monster.maxHealth = 1000000
	monster.race = "fire"
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
	monster.loot = {}
	monster.attacks = {}
	monster.defenses = { defense = 0, armor = 0, mitigation = 0 }
	monster.elements = {}
	monster.immunities = {}
	mType:register(monster)
end

local samaelId, nextScream = nil, 0

local function samael()
	local creature = samaelId and Creature(samaelId)
	if creature then
		return creature
	end
	creature = Game.createMonster("Samael", SA.at, false, true)
	if not creature then
		return nil
	end
	local invisible = Condition(CONDITION_INVISIBLE)
	invisible:setTicks(-1)
	creature:addCondition(invisible)
	samaelId = creature:getId()
	return creature
end
FS.getSamael = samael

-- the players who hear him now
function FS.samaelListeners()
	local list = {}
	for _, player in ipairs(Game.getPlayers()) do
		local p = player:getPosition()
		for _, box in ipairs(SA.heard) do
			if inBox(p, box[1], box[2], box[3], box[4], box[5]) then
				list[#list + 1] = player
				break
			end
		end
	end
	return list
end

-- one scream to everyone who hears him; returns the text (nil when nobody is there)
function FS.samaelScream(text)
	local listeners = FS.samaelListeners()
	if #listeners == 0 then
		return nil
	end
	local creature = samael()
	if not creature then
		return nil
	end
	text = text or SA.sounds[math.random(#SA.sounds)]
	for _, player in ipairs(listeners) do
		creature:say(text, TALKTYPE_MONSTER_YELL, false, player, SA.at)
	end
	return text
end

local screams = GlobalEvent("FamilySorcererSamael")
function screams.onThink(interval)
	if not on() or os.time() < nextScream then
		return true
	end
	if FS.samaelScream() then
		nextScream = os.time() + math.random(SA.minSeconds, SA.maxSeconds)
	end
	return true
end
screams:interval(10000)
screams:register()

-- ---------------------------------------------------------------------------
-- startup
-- ---------------------------------------------------------------------------
local startup = GlobalEvent("FamilySorcererStartup")
function startup.onStartup()
	if not on() then
		logger.info("[FamilySorcerer] off")
		return true
	end
	for _, name in ipairs({ "Bat", "Cat" }) do
		local mType = MonsterType(name)
		if mType then
			mType:registerEvent("FamilySorcererDeath")
		end
	end
	local need = {
		{ P.oven, 2542 },
		{ P.barrel, 2523 },
		{ P.blenderLever, 9110 },
		{ P.blenderBowl, 9108 },
		{ P.crystalBall, 9105 },
		{ P.fishBowl, 7936 },
		{ P.demonDoor, 5736 },
		{ P.frogDoor, 5733 },
	}
	for _, at in ipairs(P.cauldron) do
		need[#need + 1] = { at, nil }
	end
	for _, door in ipairs(doors) do
		need[#need + 1] = { door.at, door.closed }
	end
	for _, piece in ipairs(FS.furniture) do
		for _, at in ipairs(piece.at) do
			need[#need + 1] = { at, piece.ids }
		end
	end
	for _, at in ipairs(P.drawers) do
		need[#need + 1] = { at, 2433 }
	end
	local missing = 0
	for _, n in ipairs(need) do
		local tile = Tile(n[1])
		local found = tile ~= nil
		if tile and n[2] then
			found = false
			for _, id in ipairs(type(n[2]) == "table" and n[2] or { n[2] }) do
				if tile:getItemById(id) then
					found = true
				end
			end
		end
		if not found then
			missing = missing + 1
			logger.warn("[FamilySorcerer] map item missing at {}", n[1]:toString())
		end
	end
	local notes = writeNotes()
	local hidden = samael()
	if not hidden then
		logger.warn("[FamilySorcerer] Samael could not be placed at {}", SA.at:toString())
	end
	addEvent(function()
		-- the bats and the cat that were already in the attic
		local spectators = Game.getSpectators(pos(32287, 32292, 5), false, false, 6, 6, 4, 4)
		for _, creature in ipairs(spectators) do
			if creature:isMonster() then
				creature:registerEvent("FamilySorcererDeath")
			end
		end
	end, 5000)
	logger.info("[FamilySorcerer] Eclesius' house checked ({} missing), {} notes written, Samael {}", missing, notes, hidden and "in his cage" or "missing")
	return true
end
startup:register()
