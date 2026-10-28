local feroxaTransform = CreatureEvent("FeroxaTransform")
function feroxaTransform.onThink(creature)
	if creature:getName():lower() ~= "feroxa" then
		return true
	end
	-- FAMILY: phases told apart by type, not by fixed health: the first form
	-- (Feroxa, in the Bosstiary) has half health here (rateBossHealth), so the
	-- old "max health 100000 / 50000" checks skipped the second phase. The
	-- first form changes at half its health (upstream 50000 of 100000).
	local inBosstiary = creature:getType():bossRace() ~= nil
	if inBosstiary then
		if creature:getHealth() <= creature:getMaxHealth() / 2 then
			creature:getPosition():sendMagicEffect(CONST_ME_POFF)
			Game.createMonster("feroxa2", creature:getPosition(), true, true)
			creature:remove()
		end
	end
	if not inBosstiary and creature:getMaxHealth() == 50000 then -- FAMILY: second form (Feroxa2) only
		if creature:getHealth() <= 25000 then
			creature:getPosition():sendMagicEffect(CONST_ME_POFF)
			local feroxas = {
				[1] = { name = "feroxa3" },
				[2] = { name = "feroxa4" },
			}
			Game.createMonster(feroxas[math.random(#feroxas)].name, creature:getPosition(), true, true)
			creature:remove()
		end
	end
end

feroxaTransform:register()

local feroxaDeath = CreatureEvent("FeroxaDeath")
function feroxaDeath.onDeath(creature, corpse, deathList)
	if creature and creature:getMonster() then
		local pool = Tile(creature:getPosition()):getItemById(2886)
		if pool then
			pool:remove()
		end
		Game.createMonster("Feroxa5", creature:getPosition(), true, true)
	end
end

feroxaDeath:register()
