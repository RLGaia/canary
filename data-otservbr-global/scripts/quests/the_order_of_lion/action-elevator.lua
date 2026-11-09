local elevatorBounacAction = Action()
function elevatorBounacAction.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: the lift up to the castle works only after the Bounac Guard let you in once (The Order of the
	-- Lion, step 4+; BR: "vá até o elevador para liberar um acesso rápido"). Upstream it carried anyone.
	if FamilyLion and Family.orderOfTheLion and FamilyLion.state(player) < 4 and not FamilyLion.isHero(player) then
		player:sendCancelMessage("The lift does not move. Somebody up in the castle has to let you in first.") -- ours
		Position(32371, 32496, 7):sendMagicEffect(CONST_ME_POFF)
		return true
	end
	if player:getPosition() ~= Position(32371, 32496, 7) then
		Position(32371, 32496, 7):sendMagicEffect(CONST_ME_POFF)
	else
		player:teleportTo(Position(32374, 32497, 3))
		Position(32374, 32497, 3):sendMagicEffect(CONST_ME_POFF)
	end
	return true
end

elevatorBounacAction:aid(59604)
elevatorBounacAction:register()

local elevatorBounacMoveEvent = MoveEvent()
function elevatorBounacMoveEvent.onStepIn(creature, item, position, fromPosition)
	if creature:isPlayer() then
		creature:teleportTo(Position(32371, 32497, 7))
		Position(32371, 32497, 7):sendMagicEffect(CONST_ME_POFF)
	end
	return true
end

elevatorBounacMoveEvent:aid(59605)
elevatorBounacMoveEvent:register()
