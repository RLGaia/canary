local sandking = MoveEvent()

function sandking.onStepIn(creature, item, position, fromPosition)
	if not creature:isMonster() then
		return true
	end

	if creature:getName():lower() == "the sandking" then
		item:remove()
		creature:addHealth(7500) -- FAMILY (2026-11-17): EN "it will heal for 7500 hitpoints" (BR: about 7,000); upstream 100-1000
	end
	return true
end

sandking:type("stepin")
sandking:aid(5595)
sandking:register()
