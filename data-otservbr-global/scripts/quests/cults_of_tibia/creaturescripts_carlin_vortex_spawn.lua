-- FAMILY (2026-11-17): with Family.cultsOfTibia the remains are 25778 (decaying, green) / 25777
-- (withering, blue) and vanish after 20 seconds (EN: "You have 20 seconds to collect them"); upstream:
-- vortexes 32414/32415 for 1 minute.
local vortexCarlin = CreatureEvent("CarlinVortexDeath")
function vortexCarlin.onDeath(creature)
	local corpsePosition = creature:getPosition()
	local family = Family and Family.cultsOfTibia
	local rand = family and math.random(FamilyCults.witheringSoul, FamilyCults.decayingSoul) or math.random(32414, 32415)
	local seconds = family and FamilyCults.soulSeconds or 60
	Game.createItem(rand, 1, corpsePosition):setActionId(5580)
	addEvent(function()
		local teleport = Tile(corpsePosition):getItemById(rand)
		if teleport then
			teleport:remove(1)
		end
	end, seconds * 1000)
	return true
end

vortexCarlin:register()
