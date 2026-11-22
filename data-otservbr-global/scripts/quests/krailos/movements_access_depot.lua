local setting = {
	[19049] = { position = Position(33657, 31658, 8) }, --Entrance
}

local accessDepot = MoveEvent()

function accessDepot.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	-- FAMILY: only after Larek's Hungry New World (TibiaWiki BR and EN); upstream let everybody down
	-- (lib/others/family_krailos.lua)
	local refusal = FamilyKrailos and FamilyKrailos.grilleRefusal(player)
	if refusal then
		local back = fromPosition
		if back == position or back.z ~= position.z then
			back = FamilyKrailos.GRILLE_BACK
		end
		player:teleportTo(back, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, refusal)
		return true
	end

	local portal = setting[item.actionid]
	if portal then
		player:teleportTo(portal.position)
	end
	return true
end

accessDepot:type("stepin")
accessDepot:aid(19049)
accessDepot:register()
