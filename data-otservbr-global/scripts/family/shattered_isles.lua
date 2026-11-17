-- Gaia Family server: The Shattered Isles Quest, Marina's sea turtle on Meriana (2026-11-17).
-- Upstream's turtles.lua has the entry for it (uid 3206: Laguna Islands, only after Marina's date),
-- but the turtle on our map (32340,32537,7) has no unique id, so stepping on it did nothing.
-- Same rule here, registered by position. Rules and switch: lib/others/family_shattered_isles.lua.
local S = FamilyShatteredIsles

local function pos(p)
	return Position(p.x, p.y, p.z)
end

local turtle = MoveEvent()

function turtle.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not S.enabled() then
		return true
	end

	local destination = pos(S.lagunaLanding)
	if player:getStorageValue(Storage.Quest.U7_8.TheShatteredIsles.AccessToLagunaIsland) ~= 1 then
		destination = pos(S.turtleRefused)
	end

	player:teleportTo(destination)
	position:sendMagicEffect(CONST_ME_TELEPORT)
	destination:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

turtle:type("stepin")
turtle:position(pos(S.merianaTurtle))
turtle:register()

-- Teleportation Hub of the Forbidden Islands: a right portal works once its island was reached the
-- long way and left through its left portal (EN). Rules: lib/others/family_shattered_isles.lua.
local hubSetup = GlobalEvent("FamilyShatteredIslesHub")

function hubSetup.onStartup()
	if not S.enabled() then
		return true
	end
	for _, portal in ipairs(S.hub) do
		local tile = Tile(pos(portal.pos))
		local item = tile and tile:getItemById(1949)
		if item then
			item:setActionId(portal.aid)
			item:setDestination(Position(0, 0, 0)) -- this script sends the player
		else
			logger.warn("[FamilyShatteredIsles] hub portal not found at " .. portal.pos.x .. "," .. portal.pos.y .. "," .. portal.pos.z)
		end
	end
	return true
end

hubSetup:register()

local hubPortal = MoveEvent()

function hubPortal.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local portal
	for _, p in ipairs(S.hub) do
		if p.aid == item:getActionId() then
			portal = p
			break
		end
	end
	if not portal then
		return true
	end

	if portal.needs and not S.hubUnlocked(player, portal.needs) then
		local back = fromPosition
		if back.x == position.x and back.y == position.y and back.z == position.z then
			back = Position(position.x, position.y + 1, position.z) -- logged in or sent onto the portal
		end
		player:teleportTo(back, true)
		position:sendMagicEffect(CONST_ME_ENERGYHIT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, S.hubLockedText)
		return true
	end
	if portal.unlocks then
		S.unlockHub(player, portal.unlocks)
	end

	local destination = pos(portal.to)
	player:teleportTo(destination)
	position:sendMagicEffect(CONST_ME_TELEPORT)
	destination:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

hubPortal:type("stepin")
for _, portal in ipairs(S.hub) do
	hubPortal:aid(portal.aid)
end
hubPortal:register()
