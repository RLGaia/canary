-- Gaia Family server: The Repenters Quest, the parts outside Ashari and Larfion (2026-11-23).
-- Ours, not upstream. Rules and sources: data-otservbr-global/lib/others/family_repenters.lua.
--
-- * The elven vial fills only at the cradle of tears, the brook square without roots just north
--   of the giant tree (32606,31672,13; EN "the tile without any tree roots ... on the north side
--   just behind the tree", the BR screenshot). The tears pour out after 20 minutes (items.xml).
-- * With the filled vial, the fallen leaves of the leaf cave (floor 12) wake groups of 3 Leaf
--   Golems, at most 5 groups per filling (EN), at least 10 squares apart (ours).
-- * The receptacle catches wild fury, nature, fire and water magic in that order; a wrong colour
--   empties it (EN). Messages EN.
-- * Furious Fire Elemental corpses take the firecatcher urn for 10 seconds, once per corpse; about
--   25% of the tries work (EN statistics: 34 of 138); 5 flames fill it. Messages EN.
-- * The fire cave (floor 14) makes you drunk after a minute inside (EN: "the fumes will start
--   intoxicating you"; times ours); a dwarven ring stops it (the ring's suppressdrunk).
-- * The trained fire bug on 5 different mushrooms of the crystal cave (floor 13); it is gone
--   after the fifth (BR). Messages EN.
-- * The shortcut east of Ashari (32794,31615,11) turns back anyone without passages (BR
--   screenshot message); each walk in uses one. The warning sign gets its text (BR screenshot).
--
-- Switch: Family.repenters (false = none of the above; Ashari and Larfion still talk).

Family = Family or {}
Family.repenters = true

local R = FamilyRepenters
local it = R.items

R.cradle = Position(32606, 31672, 13)
R.brook = 18838
R.leaves = { 19061, 19062 }
R.leafGolemGroups = 5
R.leafGolemGap = 10
R.fireCave = { fromX = 32634, toX = 32645, fromY = 31558, toY = 31569, z = 14 }
R.fireCaveSeconds = 60 -- ours
R.drunkSeconds = 10 -- ours
R.fireChance = 25 -- EN: 34 of 138
R.ashSeconds = 10 -- EN
R.mushroomIds = {}
for id = 15205, 15216 do
	R.mushroomIds[id] = true
end
R.crystalCave = { fromX = 32550, toX = 32600, fromY = 31575, toY = 31640, z = 13 }
R.shortcut = Position(32794, 31615, 11)
R.sign = Position(32792, 31614, 11)
R.signText = "Warning! Dangerous path ahead! Only Ashari personally may grant passage beyond!"

local function message(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

local function isItem(target)
	return target and type(target) == "userdata" and target.isItem and target:isItem()
end

local function inBox(pos, box)
	return pos.z == box.z and pos.x >= box.fromX and pos.x <= box.toX and pos.y >= box.fromY and pos.y <= box.toY
end
R.inBox = inBox

-- ---------------------------------------------------------------------------
-- Elven vial at the cradle of tears
-- ---------------------------------------------------------------------------
local vial = Action()

function vial.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.repenters or not toPosition then
		return false
	end
	local tile = Tile(toPosition)
	local ground = tile and tile:getGround()
	if not ground or ground:getId() ~= R.brook then
		return false
	end
	if toPosition.x ~= R.cradle.x or toPosition.y ~= R.cradle.y or toPosition.z ~= R.cradle.z then
		message(player, "The roots of the old tree have spoilt this water. Look for the unspoilt cradle of tears.") -- ours
		return true
	end
	item:transform(it.vialFull)
	item:decay()
	R.kv(player):set("golem-groups", 0)
	R.kv(player):remove("golem-at")
	toPosition:sendMagicEffect(CONST_ME_LOSEENERGY)
	message(player, "The water seems to develop a life of its own as it pours slowly into the vial.")
	return true
end

vial:id(it.vial)
vial:register()

-- ---------------------------------------------------------------------------
-- Leaf golems on the way back
-- ---------------------------------------------------------------------------
function R.wakeLeaves(player, position)
	if player:getItemCount(it.vialFull) < 1 then
		return false
	end
	local kv = R.kv(player)
	local groups = kv:get("golem-groups") or 0
	if groups >= R.leafGolemGroups then
		return false
	end
	local lx, ly, lz = (kv:get("golem-at") or ""):match("^(%d+),(%d+),(%d+)$")
	if lx and position.z == tonumber(lz) and math.max(math.abs(position.x - tonumber(lx)), math.abs(position.y - tonumber(ly))) < R.leafGolemGap then
		return false
	end
	kv:set("golem-groups", groups + 1)
	kv:set("golem-at", string.format("%d,%d,%d", position.x, position.y, position.z))
	local made = 0
	for _, offset in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 }, { 0, -2 }, { 0, 2 }, { -2, 0 }, { 2, 0 } }) do
		if made >= 3 then
			break
		end
		local monster = Game.createMonster("Leaf Golem", Position(position.x + offset[1], position.y + offset[2], position.z), false, false)
		if monster then
			made = made + 1
			monster:getPosition():sendMagicEffect(CONST_ME_GREEN_RINGS)
		end
	end
	message(player, "You get a strange feeling of great unrest unround you as the leaves themselves start to come alive.")
	return true
end

local leaves = MoveEvent()

function leaves.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player and Family.repenters then
		R.wakeLeaves(player, position)
	end
	return true
end

leaves:type("stepin")
for _, id in ipairs(R.leaves) do
	leaves:id(id)
end
leaves:register()

-- ---------------------------------------------------------------------------
-- Receptacle on the wild magic
-- ---------------------------------------------------------------------------
local receptacle = Action()

function receptacle.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.repenters or not target or type(target) ~= "userdata" or not target.isMonster or not target:isMonster() then
		return false
	end
	local name = target:getName():lower()
	local index
	for i, magic in ipairs(R.magicOrder) do
		if magic.name:lower() == name then
			index = i
		end
	end
	if not index then
		return false
	end
	local S = R.S()
	local stage = R.value(player, "MagicStage")
	if index ~= stage + 1 then
		player:setStorageValue(S.MagicStage, 0)
		target:getPosition():sendMagicEffect(CONST_ME_POFF)
		message(player, "The wild magic does not mix with what you gathered and everything vanishes from the receptacle. Start again with the red fury magic.") -- ours
		return true
	end
	target:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	message(player, R.magicOrder[index].text)
	if index == R.needed.magic then
		player:setStorageValue(S.MagicStage, index)
		item:transform(it.receptacleFull)
	else
		player:setStorageValue(S.MagicStage, index)
	end
	return true
end

receptacle:id(it.receptacle)
receptacle:allowFarUse(true) -- they float around
receptacle:register()

-- ---------------------------------------------------------------------------
-- Firecatcher urn on furious fire elemental ashes
-- ---------------------------------------------------------------------------
local ASH_KEY = "family-repenters-ash"
local TRIED_KEY = "family-repenters-urn"

-- Returns the text to show, or nil when the target is no fire elemental ash.
function R.catchFlame(player, item, corpse)
	local killed = corpse:getCustomAttribute(ASH_KEY)
	if not killed then
		return nil
	end
	if corpse:getCustomAttribute(TRIED_KEY) or os.time() - tonumber(killed) > R.ashSeconds then
		return "The ashes have already cooled down. There are no flames left to catch." -- ours
	end
	corpse:setCustomAttribute(TRIED_KEY, 1)
	if math.random(100) > R.fireChance then
		return "The flickering flames flinch from your grasp."
	end
	local S = R.S()
	local flames = R.value(player, "Flames") + 1
	player:setStorageValue(S.Flames, flames)
	if flames >= R.needed.flames then
		item:transform(it.urnHot)
		return "Finally, the urn is filled with flames. The urn is a lot hotter now but still cool enough to carry."
	end
	return "The flames of the elemental seem to be sucked into the urn."
end

local urn = Action()

function urn.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.repenters or not isItem(target) then
		return false
	end
	local text = R.catchFlame(player, item, target)
	if not text then
		return false
	end
	toPosition:sendMagicEffect(CONST_ME_HITBYFIRE)
	message(player, text)
	return true
end

urn:id(it.urn)
urn:register()

local fireDeath = CreatureEvent("FamilyRepentersFireDeath")

function fireDeath.onDeath(creature, corpse, lastHitKiller, mostDamageKiller)
	if corpse and corpse.setCustomAttribute then
		corpse:setCustomAttribute(ASH_KEY, os.time())
	end
	return true
end

fireDeath:register()

-- The fire cave's fumes: drunk after a minute inside, unless a dwarven ring stops it.
local fumes = GlobalEvent("FamilyRepentersFumes")

function fumes.onThink(interval)
	if not Family.repenters then
		return true
	end
	local box = R.fireCave
	local center = Position(math.floor((box.fromX + box.toX) / 2), math.floor((box.fromY + box.toY) / 2), box.z)
	local now = os.time()
	for _, player in ipairs(Game.getSpectators(center, false, true, 8, 8, 8, 8)) do
		if inBox(player:getPosition(), box) then
			local kv = R.kv(player)
			local since = kv:get("fumes-since")
			if not since or now - since > 30 then
				-- a fresh visit (no check for 30 s means the player was away)
				kv:set("fumes-since", now)
				since = now
			end
			kv:set("fumes-seen", now)
			if now - since >= R.fireCaveSeconds then
				local drunk = Condition(CONDITION_DRUNK)
				drunk:setParameter(CONDITION_PARAM_TICKS, R.drunkSeconds * 1000)
				player:addCondition(drunk)
				if not kv:get("fumes-told") or kv:get("fumes-told") < since then
					kv:set("fumes-told", now)
					message(player, "The fumes of the hot cave start to cloud your mind.") -- ours
				end
			end
		end
	end
	return true
end

fumes:interval(10000)
fumes:register()

-- ---------------------------------------------------------------------------
-- Trained fire bug on the mushrooms
-- ---------------------------------------------------------------------------
-- Returns the text, or nil when the target is not a crystal cave mushroom.
function R.sterilise(player, item, target, position)
	if not R.mushroomIds[target:getId()] or not inBox(position, R.crystalCave) then
		return nil
	end
	if R.state(player, "mushroom") ~= R.ACTIVE then
		return "Ashari did not ask you to burn anything." -- ours
	end
	local key = string.format("%d,%d,%d", position.x, position.y, position.z)
	local kv = R.kv(player)
	local done = kv:get("mushrooms") or ""
	if (";" .. done .. ";"):find(";" .. key .. ";", 1, true) then
		return "You already sterilised this mushroom." -- ours
	end
	kv:set("mushrooms", done == "" and key or (done .. ";" .. key))
	local S = R.S()
	local n = R.value(player, "Mushrooms") + 1
	player:setStorageValue(S.Mushrooms, n)
	if n >= R.needed.mushrooms then
		R.setState(player, "mushroom", R.READY)
		item:remove(1)
		return "The mushroom has been sterilised. You treated enough mushrooms to keep the spreading infection at bay."
	end
	return "The mushroom has been sterilised and is no longer infected."
end

local bug = Action()

function bug.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.repenters or not isItem(target) then
		return false
	end
	local text = R.sterilise(player, item, target, toPosition)
	if not text then
		return false
	end
	toPosition:sendMagicEffect(CONST_ME_FIREAREA)
	message(player, text)
	return true
end

bug:id(it.bug)
bug:register()

-- ---------------------------------------------------------------------------
-- The shortcut east of Ashari
-- ---------------------------------------------------------------------------
local shortcut = MoveEvent()

function shortcut.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.repenters or player:getGroup():getAccess() then
		return true
	end
	if fromPosition and fromPosition.x > position.x then
		return true -- coming back out of the passage
	end
	local S = R.S()
	local left = R.value(player, "Passages")
	if left < 1 then
		player:teleportTo(fromPosition, true)
		message(player, "Getting suspicious glances from bystanding elves and Ashari shouting something from the distance, you decide to back off.")
		return true
	end
	player:setStorageValue(S.Passages, left - 1)
	message(player, left - 1 == 0 and "Ashari lets you pass. That was the last passage he granted you." or string.format("Ashari lets you pass. Passages left: %d.", left - 1)) -- ours
	return true
end

shortcut:type("stepin")
shortcut:position(R.shortcut)
shortcut:register()

local startup = GlobalEvent("FamilyRepentersStartup")

function startup.onStartup()
	local tile = Tile(R.sign)
	local sign = tile and tile:getItemById(12782)
	if sign then
		sign:setAttribute(ITEM_ATTRIBUTE_TEXT, R.signText)
	else
		logger.error("[Family] The Repenters: warning sign not found")
	end
	logger.info("[Family] The Repenters: {}", Family.repenters and "on" or "off")
	return true
end

startup:register()
