-- Gaia Family server: Isle of the Kings, the monastery's restricted floors (2026-11-16).
-- Key 3350 from Costello's bookcase, the locked door it opens, the trespasser mark.
-- Rules, sources and switch: data-otservbr-global/lib/others/family_white_raven.lua.

local W = FamilyWhiteRaven

local function pos(p)
	return Position(p.x, p.y, p.z)
end

-- The locked door to the monks' floors gets the key's number (upstream: none, so it never opened).
local doorSetup = GlobalEvent("FamilyWhiteRavenDoor")

function doorSetup.onStartup()
	local tile = Tile(pos(W.keyDoor))
	local door = tile and (tile:getItemById(1631) or tile:getItemById(1632) or tile:getItemById(1633))
	if not door then
		logger.warn("[FamilyWhiteRaven] locked door not found at 32178,31928,6")
		return true
	end
	door:setActionId(W.keyNumber)
	return true
end

doorSetup:register()

-- Costello's bookcase: once per character a bag with his note and Key 3350.
local bookcase = Action()

function bookcase.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local store = player:kv():scoped(W.kvScope)
	if store:get("key-found") then
		return false -- opens as a normal bookcase
	end
	local bag = Game.createItem(W.bagItem, 1)
	if not bag then
		return false
	end
	local note = bag:addItem(W.noteItem, 1)
	if note then
		note:setAttribute(ITEM_ATTRIBUTE_TEXT, W.noteText)
	end
	local key = bag:addItem(W.keyItem, 1)
	if key then
		key:setActionId(W.keyNumber)
	end
	if player:addItemEx(bag) ~= RETURNVALUE_NOERROR then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a bag, but you have no room or capacity to take it.")
		return true
	end
	store:set("key-found", true)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a bag.")
	return true
end

bookcase:position(pos(W.bookcase))
bookcase:register()

-- Behind the locked door: the stair room up to the monks' floors.
local trespass = MoveEvent()

function trespass.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.monasteryTrespass or player:getGroup():getAccess() then
		return true
	end
	if W.isTrespasser(player) then
		return true
	end
	W.setTrespasser(player, true)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, W.lines.entered)
	return true
end

trespass:type("stepin")
local r = W.restrictedRoom
for x = r.x1, r.x2 do
	for y = r.y1, r.y2 do
		trespass:position(Position(x, y, r.z))
	end
end
trespass:register()
