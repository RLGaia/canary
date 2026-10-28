function onDeath(creature, corpse, lasthitkiller, mostdamagekiller, lasthitunjustified, mostdamageunjustified)
	local monster = Game.createMonster("Zamulosh3", creature:getPosition(), true, true)
	if not monster then
		return true
	end
	return true
end

local zamuloshClone = CreatureEvent("ZamuloshClone")
function zamuloshClone.onThink(creature)
	local spectators = Game.getSpectators(Position(33644, 32757, 11), false, false, 10, 10, 10, 10)
	for i = 1, #spectators do
		local master = spectators[i]
		-- FAMILY: the real Zamulosh is found by being the Bosstiary boss, not by
		-- 300000 max health (he has half that here because of rateBossHealth).
		if master:isMonster() and master:getType():bossRace() ~= nil and master:getName() == "Zamulosh" and not master:getMaster() then
			master:setSummon(creature)
		end
	end
end

zamuloshClone:register()
