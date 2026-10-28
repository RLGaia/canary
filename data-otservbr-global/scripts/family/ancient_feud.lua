-- Gaia Family server: Grimvale Quest, mission "An Ancient Feud": world
-- objects and events (2026-10-28). Ours, not upstream. Story, states and NPC
-- dialogue: lib/others/family_ancient_feud.lua (FamilyAncientFeud).
-- Replaces ancient_feud_access.lua (level 250 opened the Sanctum doors until
-- this mission existed).
--
-- Positions (TibiaWiki EN maps and our map):
--   * clues: pool of blood 33149,32433,11, skulls on a stonepile (the bone
--     shrine, strange bonepile at the dragon skeleton) 33193,32440,11,
--     blood-stained pagoda (painted stones) 33195,32392,10
--   * campfire for the hydra egg: any campfire in the Hyaena Lairs
--   * the north-eastern tile of the sun and moon mosaic 33097,32267,11
--   * lion column 33092,32314,11 <-> 33090,32279,12 (upstream shortcut
--     script, FAMILY edit: also with the lion ring worn)
--   * sandstone statue 33116,32307,12 ("Slightly Feline Statue" in Tibia);
--     the mosaic beside it (33120-33121,32310-32311,12) leads into
--     Heliodor's room, its mosaic (33129-33130,32320-32321,12) back out
--   * Domizian's door 33260,32470,6 is locked on our map: unlocked at startup
-- Sanctum doors (all action id GrimvaleQuest.AncientFeudDoors):
--   * 33124,32261,10 Sanctum entrance: from step 7 after saying the phrase
--     next to it ("The sun guides our hearts. The moon guards our dreams")
--   * 33123,32230,12 the beasts' door: from step 11 (the statue)
--   * 33159,32322,12 door to the Hyaena Lairs: after the mission
--   The upstream storage (set by Domizian at the end) opens all three.
-- Switch: Family.ancientFeud (lib/others/family_ancient_feud.lua).

local F = FamilyAncientFeud
local S = Storage.Quest.FamilyAncientFeud
local I = F.items

local function active()
	return Family.ancientFeud ~= false
end

local function msg(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

local function inBox(pos, x1, y1, x2, y2)
	return pos.x >= x1 and pos.x <= x2 and pos.y >= y1 and pos.y <= y2
end

local LAIRS = { 33100, 32330, 33250, 32560 } -- the Hyaena Lairs (all floors)

-- Sanctum doors -------------------------------------------------------------------

local PHRASE_DOOR = Position(33124, 32261, 10)
local DOORS = {
	{ pos = PHRASE_DOOR, open = function(player)
		local state = F.state(player)
		return state >= 14 or (state >= 7 and player:getStorageValue(S.Phrase) >= 1)
	end },
	{ pos = Position(33123, 32230, 12), open = function(player)
		return F.state(player) >= 11
	end },
	{ pos = Position(33159, 32322, 12), open = function(player)
		return F.state(player) >= 14
	end },
}

function F.canPassDoor(player, pos)
	if player:getStorageValue(Storage.Quest.U10_80.GrimvaleQuest.AncientFeudDoors) ~= -1 then
		return true
	end
	if not active() then
		return false
	end
	for _, door in ipairs(DOORS) do
		if door.pos == pos then
			return door.open(player)
		end
	end
	return false
end

local door = Action()
function door.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	for _, value in ipairs(QuestDoorTable) do
		if value.closedDoor == item.itemid then
			if F.canPassDoor(player, item:getPosition()) then
				item:transform(value.openDoor)
				item:getPosition():sendSingleSoundEffect(SOUND_EFFECT_TYPE_ACTION_OPEN_DOOR)
				player:teleportTo(toPosition, true)
			elseif item:getPosition() == PHRASE_DOOR and active() and F.state(player) >= 7 then
				msg(player, "The door seems to be sealed against unwanted intruders. Perhaps it opens for those who know the right phrase.") -- ours
			else
				msg(player, "The door seems to be sealed against unwanted intruders.")
			end
			return true
		end
	end
	-- an open door: leave it to the normal door handling
	return false
end
for _, entry in ipairs(DOORS) do
	door:position(entry.pos)
end
door:register()

-- the phrase at the Sanctum entrance: a talkaction on the first word that
-- never swallows the message (returns false, so it is spoken as usual)
local function normalize(text)
	return text:lower():gsub("[^a-z ]", ""):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
end
local PHRASE = normalize("The sun guides our hearts. The moon guards our dreams")

local phrase = TalkAction("The", "the", "THE")
function phrase.onSay(player, words, param, type)
	if not active() or normalize(words) ~= PHRASE then
		return false
	end
	local pos = player:getPosition()
	if pos.z ~= PHRASE_DOOR.z or math.abs(pos.x - PHRASE_DOOR.x) > 4 or math.abs(pos.y - PHRASE_DOOR.y) > 4 then
		return false
	end
	if F.state(player) >= 7 and player:getStorageValue(S.Phrase) < 1 then
		player:setStorageValue(S.Phrase, 1)
		PHRASE_DOOR:sendMagicEffect(CONST_ME_YELLOWENERGY)
		addEvent(function(id)
			local p = Player(id)
			if p then
				p:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to recognise the phrase. It will open for you now.") -- ours
			end
		end, 100, player:getId())
	end
	return false
end
phrase:separator(" ")
phrase:groupType("normal")
phrase:register()

-- Clues in the Hyaena Lairs ---------------------------------------------------------

local CLUES = {
	{ bit = 1, pos = Position(33149, 32433, 11), range = 6, text = "A large pool of blood. Bones float in it - the werehyaenas obviously don't only live off carrion." }, -- ours
	{ bit = 2, pos = Position(33193, 32440, 11), range = 3, text = "Skulls on a stonepile next to a dragon skeleton. The bones are painted with the same runes as the shamans' fur - this looks like a shrine of the undead." }, -- ours
	{ bit = 4, pos = Position(33195, 32392, 10), range = 3, text = "A blood-stained pagoda. Strange runes are scratched into it, runes of Drefia." }, -- ours
}

local clueEvent = GlobalEvent("FamilyAncientFeudClues")
function clueEvent.onThink(interval)
	if not active() then
		return true
	end
	for _, player in ipairs(Game.getPlayers()) do
		local p = player:getPosition()
		if inBox(p, LAIRS[1], LAIRS[2], LAIRS[3], LAIRS[4]) and F.state(player) == 2 then
			for _, clue in ipairs(CLUES) do
				if p.z == clue.pos.z and math.abs(p.x - clue.pos.x) <= clue.range and math.abs(p.y - clue.pos.y) <= clue.range then
					if F.addClue(player, clue.bit) then
						msg(player, clue.text)
					end
				end
			end
		end
	end
	return true
end
clueEvent:interval(1000)
clueEvent:register()

-- Rhargu's food --------------------------------------------------------------------

-- hydra egg on a campfire in the lairs
local egg = Action()
function egg.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() then
		return false
	end
	local name = ItemType(target:getId()):getName()
	if name ~= "campfire" or not inBox(toPosition, LAIRS[1], LAIRS[2], LAIRS[3], LAIRS[4]) then
		return false
	end
	if not active() or F.state(player) ~= 4 then
		return false
	end
	item:remove(1)
	player:addItem(I.boiledEgg, 1)
	toPosition:sendMagicEffect(CONST_ME_HITBYFIRE)
	msg(player, "You boil the hydra egg in the fire. It is hard-boiled now.") -- ours
	return true
end
egg:id(I.hydraEgg)
egg:register()

-- net on a cave rat: 20% chance to catch it (TibiaWiki EN)
F.netChance = 20
local net = Action()
function net.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isMonster or not target:isMonster() or target:getName():lower() ~= "cave rat" then
		return false
	end
	if not active() or F.state(player) ~= 4 then
		msg(player, "You don't need a cave rat right now.") -- ours
		return true
	end
	if math.random(100) > F.netChance then
		target:getPosition():sendMagicEffect(CONST_ME_POFF)
		msg(player, "The cave rat slips through the net.") -- ours
		return true
	end
	target:getPosition():sendMagicEffect(CONST_ME_BLOCKHIT)
	target:remove()
	player:addItem(33946, 1)
	msg(player, "You caught a cave rat.") -- ours
	return true
end
net:id(31489)
net:register()

-- salt on a cave rat
local salt = Action()
function salt.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() or target:getId() ~= 33946 then
		return false
	end
	item:remove(1)
	target:transform(33916)
	msg(player, "You salt the cave rat.") -- ours
	return true
end
salt:id(33930)
salt:register()

-- salted cave rats into Rhargu's cask: empty, 1, 2, 3, 4, 5 rats
local CASKS = { 33917, 33931, 33939, 33940, 33941, 33942 }
local salted = Action()
function salted.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() then
		return false
	end
	for i = 1, #CASKS - 1 do
		if target:getId() == CASKS[i] then
			item:remove(1)
			target:transform(CASKS[i + 1])
			msg(player, i + 1 == #CASKS and "The cask is full to the brim now." or "You put the salted cave rat into the cask.") -- ours
			return true
		end
	end
	if target:getId() == CASKS[#CASKS] then
		msg(player, "The cask is already full.") -- ours
		return true
	end
	return false
end
salted:id(33916)
salted:register()

-- The torch ---------------------------------------------------------------------------

local SHRINE = Position(33193, 32440, 11)
local ALTAR = Position(33097, 32267, 11) -- north-eastern tile of the sun and moon mosaic

-- a knife on a lion's mane flower: chopped petals. Called from
-- onUseKitchenKnife (kitchen knife, secret agent tools) and from the obsidian
-- knife (skinning.lua); cleaver and small axe below.
function F.onChop(player, item, target)
	if not target or not target.isItem or not target:isItem() or target:getId() ~= 21389 then
		return false
	end
	if not active() or F.state(player) ~= 7 then
		return false
	end
	target:transform(34077)
	msg(player, "You chop the petals of the lion's mane flower.") -- ours
	return true
end

local chop = Action()
function chop.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return F.onChop(player, item, target)
end
chop:id(3471, 3462) -- cleaver, small axe
chop:register()

local petals = Action()
function petals.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() or target:getId() ~= I.torch then
		return false
	end
	item:remove(1)
	if player:getPosition() ~= ALTAR then
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		msg(player, "You are in the wrong place. The petals burn in the flame without any effect.") -- ours
		return true
	end
	target:transform(I.blessedTorch)
	player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
	msg(player, "You sprinkle the chopped petals into the flame. The torch begins to sparkle.") -- ours
	return true
end
petals:id(34077)
petals:register()

local torch = Action()
function torch.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not target or not target.isItem or not target:isItem() or toPosition ~= SHRINE then
		return false
	end
	local state = F.state(player)
	if not active() or state < 5 or state > 7 then
		return false
	end
	if item:getId() == I.blessedTorch and state == 7 then
		item:remove(1)
		for dx = -1, 1 do
			for dy = -1, 1 do
				Position(SHRINE.x + dx, SHRINE.y + dy, SHRINE.z):sendMagicEffect(CONST_ME_FIREAREA)
			end
		end
		msg(player, "The blessed fire consumes the bone shrine. The pact between the werehyaenas and the undead is broken!") -- ours
		F.setState(player, 8)
		return true
	end
	SHRINE:sendMagicEffect(CONST_ME_POFF)
	msg(player, "You try to set the bone shrine on fire, but the flames die down at once. A dark force protects it.") -- ours
	if state == 5 then
		F.setState(player, 6)
	end
	return true
end
torch:id(I.torch, I.blessedTorch)
torch:register()

-- Lion column, statue and Heliodor -------------------------------------------------

local COLUMNS = { Position(33092, 32314, 11), Position(33090, 32279, 12) }

local function wearsRing(player)
	local ring = player:getSlotItem(CONST_SLOT_RING)
	return ring and ring:getId() == I.ring
end

-- used by the upstream shortcut script (actions_ancient_feud_entrances.lua)
function F.canUseColumn(player, pos)
	if not active() or F.state(player) < 10 then
		return false
	end
	for _, column in ipairs(COLUMNS) do
		if column == pos then
			return wearsRing(player)
		end
	end
	return false
end

local STATUE = Position(33116, 32307, 12)
local statue = Action()
function statue.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local state = F.state(player)
	if not active() or state < 10 then
		return false
	end
	if state == 10 then
		F.setState(player, 11)
		item:getPosition():sendMagicEffect(CONST_ME_YELLOWENERGY)
		msg(player, "The eyes of the statue seem to look right through you. A voice echoes in your head: 'Prove that you are worthy, human. Defeat the four beasts in the north and bring me their tokens.' The door to the north will open for you now.") -- ours
	elseif state == 11 then
		local missing = F.missingTokens(player)
		if #missing > 0 then
			msg(player, "The statue remains silent. You still need: " .. table.concat(missing, ", ") .. ".") -- ours
			return true
		end
		for _, token in ipairs(F.tokens) do
			player:removeItem(token.item, 1)
		end
		F.setState(player, 12)
		item:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
		msg(player, "The tokens vanish. The voice echoes again: 'You are worthy. Step on the mosaic, human, the king will see you.'") -- ours
	else
		msg(player, "The stony face has lion-like features.")
	end
	return true
end
statue:position(STATUE)
statue:register()

local ENTRY = { Position(33120, 32310, 12), Position(33121, 32310, 12), Position(33120, 32311, 12), Position(33121, 32311, 12) }
local EXIT = { Position(33129, 32320, 12), Position(33130, 32320, 12), Position(33129, 32321, 12), Position(33130, 32321, 12) }
local INSIDE = Position(33132, 32322, 12)
local OUTSIDE = Position(33118, 32308, 12)

local mosaic = MoveEvent()
function mosaic.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	for _, p in ipairs(ENTRY) do
		if p == position then
			if active() and F.state(player) >= 12 then
				player:teleportTo(INSIDE)
				INSIDE:sendMagicEffect(CONST_ME_TELEPORT)
			end
			return true
		end
	end
	for _, p in ipairs(EXIT) do
		if p == position then
			player:teleportTo(OUTSIDE)
			OUTSIDE:sendMagicEffect(CONST_ME_TELEPORT)
			return true
		end
	end
	return true
end
mosaic:type("stepin")
for _, p in ipairs(ENTRY) do
	mosaic:position(p)
end
for _, p in ipairs(EXIT) do
	mosaic:position(p)
end
mosaic:register()

-- Kills and the beasts' tokens -------------------------------------------------------

local hyaenaDeath = CreatureEvent("FamilyAncientFeudHyaena")
function hyaenaDeath.onDeath(creature)
	onDeathForDamagingPlayers(creature, function(_, player)
		local state = F.state(player)
		if active() and state >= 2 and state <= 9 then
			local kills = F.killCount(player)
			if kills < F.kills then
				player:setStorageValue(S.Kills, kills + 1)
			end
		end
	end)
	return true
end
hyaenaDeath:register()

-- the beasts drop their token for players on the mission (the loot chance of
-- about 4% stays for everyone else)
local beastDeath = CreatureEvent("FamilyAncientFeudBeast")
function beastDeath.onDeath(creature)
	local name = creature:getName():lower()
	for _, token in ipairs(F.tokens) do
		if token.boss:lower() == name then
			onDeathForDamagingPlayers(creature, function(_, player)
				if active() and F.state(player) == 11 and player:getItemCount(token.item) < 1 then
					player:addItem(token.item, 1)
					msg(player, string.format("You take %s from the slain beast.", ItemType(token.item):getName())) -- ours
				end
			end)
		end
	end
	return true
end
beastDeath:register()

-- Startup ------------------------------------------------------------------------------

local DOMIZIAN_DOOR = Position(33260, 32470, 6)

local startup = GlobalEvent("FamilyAncientFeudStartup")
function startup.onStartup()
	for _, name in ipairs({ "Werehyaena", "Werehyaena Shaman" }) do
		local mType = MonsterType(name)
		if mType then
			mType:registerEvent("FamilyAncientFeudHyaena")
		end
	end
	for _, token in ipairs(F.tokens) do
		local mType = MonsterType(token.boss)
		if mType then
			mType:registerEvent("FamilyAncientFeudBeast")
		end
	end
	local tile = Tile(DOMIZIAN_DOOR)
	local locked = tile and tile:getItemById(1668)
	if locked then
		locked:transform(1669)
	end
	logger.info("[Family] An Ancient Feud: Domizian's door {}", locked and "unlocked" or "not found")
	return true
end
startup:register()
