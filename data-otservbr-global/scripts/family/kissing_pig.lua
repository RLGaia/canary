-- Gaia Family server: Kissing a Pig Quest, world objects (2026-11-20). Ours, not upstream.
-- Doors, the Firlefanz chest, the dwarven ghost's beard box, the inkwell and the beard.
-- Talk and rules: lib/others/family_kissing_pig.lua (FamilyKissing).

local FK = FamilyKissing
local S = FK.S

-- Sealed doors: the quest door script opens them when the storage named by the action id is set.
local doors = {
	{ pos = FK.HOGGLE_GATE, id = 1642, aid = S.Hoggle }, -- Hoggle's garden gate
	{ pos = FK.BASEMENT_DOOR, id = 1644, aid = S.FirlefanzDoor }, -- the farm basement (Firlefanz)
	{ pos = FK.GROTHMOK_DOOR, id = 5113, aid = S.Grothmok }, -- Grothmok tunnel (Budrik)
}

local startup = GlobalEvent("FamilyKissingPigStartup")
function startup.onStartup()
	if not Family.kissingPig then
		return true
	end
	for _, d in ipairs(doors) do
		local tile = Tile(d.pos)
		local door = tile and tile:getItemById(d.id)
		if door then
			door:setActionId(d.aid)
		else
			logger.warn("[Family] Kissing a Pig: door {} not found at {}", d.id, d.pos:toString())
		end
	end
	return true
end
startup:register()

-- The Firlefanz chest in the farm basement.
local chest = Action()
function chest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.kissingPig then
		return false
	end
	if FK.get(player, S.FirlefanzChest) >= 1 or not FK.finished(player) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
		return true
	end
	local weight = ItemType(FK.FIRLEFANZ):getWeight()
	if player:getFreeCapacity() < weight then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a Firlefanz. Weighing " .. string.format("%.2f", weight / 100) .. " oz, it is too heavy for you to carry.")
		return true
	end
	local added = player:addItem(FK.FIRLEFANZ, 1)
	if not added then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a Firlefanz. But you have no room to take it.")
		return true
	end
	player:setStorageValue(S.FirlefanzChest, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a Firlefanz.")
	return true
end
chest:position(FK.FIRLEFANZ_CHEST)
chest:register()

-- The box in the dwarven ghost's quarters holds his fake beard while the favour is open.
local box = Action()
function box.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.kissingPig or item:getId() ~= 2469 then
		return false
	end
	if FK.get(player, S.DwarvenGhost) == 1 and player:getItemCount(FK.BEARD) == 0 then
		player:addItem(FK.BEARD, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a fake dwarven beard.")
		return true
	end
	return false -- opens as usual
end
box:position(FK.BEARD_BOX)
box:register()

-- The fake beard on the lit coal basin.
local beard = Action()
function beard.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.kissingPig or not target or not target.itemid then
		return false
	end
	if not FK.samePos(toPosition, FK.COAL_BASIN) then
		return false
	end
	if target.itemid == 2114 then
		player:sendTextMessage(MESSAGE_FAILURE, "The coal basin is not lit.") -- ours
		return true
	end
	if target.itemid < 2110 or target.itemid > 2113 then
		return false
	end
	item:remove(1)
	toPosition:sendMagicEffect(CONST_ME_FIREAREA)
	if FK.get(player, S.DwarvenGhost) == 1 then
		player:setStorageValue(S.DwarvenGhost, 2)
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The fake dwarven beard burns to ashes.") -- ours
	return true
end
beard:id(FK.BEARD)
beard:register()

-- Inkwell on a poetry parchment, only while Elvith waits for a poem (EN).
local inkwell = Action()
function inkwell.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.kissingPig or not target or not target.itemid then
		return false
	end
	local step = FK.POEM_STEPS[target.itemid]
	if not step or FK.get(player, S.Elvith) ~= 1 then
		return false
	end
	local success = target.itemid == FK.BLANK_POEM or math.random(100) <= FK.poemChance
	target:transform(success and step[1] or step[2])
	return true
end
inkwell:id(3509)
inkwell:register()
