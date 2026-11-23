-- Gaia Family server: Galthen and the Lost Queen, the parts outside the NPCs (2026-11-23). Ours, not
-- upstream. Rules and sources: data-otservbr-global/lib/others/family_galthen.lua.
--
-- * An Idol: using the floor in front of him (or the ritual notes next to him) shows the word VBOX
--   (BR: use the square in front of him; EN: use the ritual notes there). Message from both wikis.
-- * The soup kettle (32591,32484,13): its strange creature greets you when you come close (BR message);
--   carnisylvan fingers, barks and human teeth used on it, then the kettle itself (BR message).
-- * The crystal teleporter by the Sleeping Carnisylvans (32580,32481,12) takes you to Yselda's lever
--   room only after the soup (it had a plain destination; cleared at startup, action id 48788).
-- * Megasylvan Yselda takes no damage until the ritual words were said in her room; her death gives
--   every player in the room the kill and Woodcarver; a dead Megasylvan Sapling costs the tulip.
-- * The violet tulip used next to Yselda after a kill with her saplings alive (Bounacean Chivalry).
-- * Yselda (NPC) is created at startup next to the boss's square.
--
-- Switch: Family.galthen (false = none of the above; the NPCs still talk).

Family = Family or {}
Family.galthen = true

local G = FamilyGalthen

local function message(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

local VBOX = "Staring at the writing you begin to decipher a letter. Then another and another. The symbols seem to wriggle and move: VBOX"

-- An Idol's floor
local idolFloor = Action()

function idolFloor.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.galthen then
		return false
	end
	message(player, VBOX)
	return true
end

for _, pos in ipairs(G.idolFloor) do
	idolFloor:position(pos)
end
idolFloor:register()

-- The ritual notes used next to An Idol
local notes = Action()

function notes.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.galthen or not toPosition or toPosition.z ~= G.idolPos.z then
		return false
	end
	if math.max(math.abs(toPosition.x - G.idolPos.x), math.abs(toPosition.y - G.idolPos.y)) > 1 then
		return false
	end
	message(player, VBOX)
	return true
end

notes:id(G.items.notes)
notes:register()

-- The soup kettle: the creature's look when you come close
local kettleNear = MoveEvent()

function kettleNear.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player and Family.galthen and fromPosition and fromPosition:getDistance(G.kettlePos) > 1 then
		message(player, "A strange creature looks into your eyes. While it is clearly sentient, its mind seems to hide far away from this place.")
	end
	return true
end

kettleNear:type("stepin")
for dx = -1, 1 do
	for dy = -1, 1 do
		if dx ~= 0 or dy ~= 0 then
			kettleNear:position(Position(G.kettlePos.x + dx, G.kettlePos.y + dy, G.kettlePos.z))
		end
	end
end
kettleNear:register()

-- Ingredients into the kettle
local ingredient = Action()

function ingredient.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.galthen or not toPosition or toPosition.x ~= G.kettlePos.x or toPosition.y ~= G.kettlePos.y or toPosition.z ~= G.kettlePos.z then
		return false
	end
	local text = G.addIngredient(player, item)
	if not text then
		return false
	end
	G.kettlePos:sendMagicEffect(CONST_ME_BUBBLES)
	message(player, text)
	return true
end

ingredient:id(G.items.fingers, G.items.barks, G.items.teeth)
ingredient:register()

-- The kettle itself
local kettle = Action()

function kettle.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.galthen then
		return false
	end
	message(player, G.useKettle(player))
	G.kettlePos:sendMagicEffect(CONST_ME_POFF)
	return true
end

kettle:position(G.kettlePos)
kettle:register()

-- The crystal teleporter to the lever room
local gate = MoveEvent()

function gate.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	if Family.galthen and G.state(player) < 6 and not player:getGroup():getAccess() then
		player:teleportTo(fromPosition, true)
		message(player, "The sleeping carnisylvans do not stir. Something is still missing.") -- ours
		return true
	end
	player:teleportTo(G.leverRoom)
	G.leverRoom:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

gate:type("stepin")
gate:aid(G.gateAid)
gate:register()

-- Megasylvan Yselda: no damage before the words
local health = CreatureEvent("FamilyGalthenYseldaHealth")

function health.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not Family.galthen then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	if primaryType == COMBAT_HEALING then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	G.currentBoss()
	if not G.isVulnerable(creature) then
		creature:getPosition():sendMagicEffect(CONST_ME_BLOCKHIT)
		return 0, primaryType, 0, secondaryType
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

health:register()

local death = CreatureEvent("FamilyGalthenYseldaDeath")

function death.onDeath(creature, corpse, killer, mostDamageKiller)
	if not Family.galthen then
		return true
	end
	local players = {}
	for _, c in ipairs(Game.getSpectators(G.roomCenter, false, true, 17, 17, 12, 12)) do
		if G.inRoom(c:getPosition()) then
			players[#players + 1] = c
		end
	end
	local outcome = G.yseldaDied(players)
	for _, p in ipairs(players) do
		message(p, outcome >= 2 and "Megasylvan Yselda is defeated and her children live. Talk to Yselda." or "Megasylvan Yselda is defeated, but her children did not survive. Talk to Yselda.") -- ours
	end
	return true
end

death:register()

local saplingDeath = CreatureEvent("FamilyGalthenSaplingDeath")

function saplingDeath.onDeath(creature, corpse, killer, mostDamageKiller)
	if Family.galthen then
		G.saplingDied()
		for _, p in ipairs(Game.getSpectators(G.roomCenter, false, true, 17, 17, 12, 12)) do
			message(p, "A megasylvan sapling withers away.") -- ours
		end
	end
	return true
end

saplingDeath:register()

-- The violet tulip
local tulip = Action()

function tulip.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.galthen then
		return false
	end
	local text = G.useTulip(player)
	if not text then
		return false
	end
	message(player, text)
	return true
end

tulip:id(G.items.tulip)
tulip:register()

local startup = GlobalEvent("FamilyGalthenStartup")

function startup.onStartup()
	local tile = Tile(G.gatePos)
	local teleporter = tile and tile:getItemById(15320)
	if teleporter then
		teleporter:setDestination(Position(0, 0, 0))
		teleporter:setActionId(G.gateAid)
	else
		logger.error("[Family] Galthen: crystal teleporter not found")
	end
	local yselda = Game.createNpc("Yselda", G.yseldaNpcPos, false, true)
	if not yselda then
		logger.error("[Family] Galthen: Yselda could not be placed")
	end
	logger.info("[Family] Galthen and the Lost Queen: {}", Family.galthen and "on" or "off")
	return true
end

startup:register()
