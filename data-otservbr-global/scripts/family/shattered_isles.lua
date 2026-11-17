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
