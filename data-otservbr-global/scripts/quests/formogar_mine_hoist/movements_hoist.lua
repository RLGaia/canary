local hoist = MoveEvent()

function hoist.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	-- FAMILY: upstream wanted the map and a box storage that nothing set, so nobody could use the hoist.
	-- TibiaWiki EN/BR: the floor plan works the first floor (uid 3059), the instructions the second and
	-- third (3060, 3061); lib/others/family_ice_islands.lua (2026-11-16)
	local allowed
	if Family and Family.iceIslandsFixes then
		if item.uid == 3059 then
			allowed = FamilyIceIslands.hoistMap(player)
		else
			allowed = FamilyIceIslands.hoistInstructions(player)
		end
	else
		allowed = player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.FormorgarMinesHoistSkeleton) == 1 and player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.FormorgarMinesHoistChest) == 1
	end
	if not allowed then
		player:teleportTo(fromPosition)
		player:getPosition():sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You must first find the hoist instruction before using it.")
		return true
	end

	if table.contains({ 3059, 3061 }, item.uid) then
		player:teleportTo(Position(32157, 31125, 10))
	elseif item.uid == 3060 then
		if Tile(Position(32156, 31125, 10)):getItemById(2772) then
			player:teleportTo(Position(32157, 31125, 11))
		else
			player:teleportTo(Position(32157, 31125, 9))
		end
	end
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

hoist:type("stepin")
hoist:uid(3059, 3060, 3061)
hoist:register()
