-- Gaia Family server: creatures that only come out at night (2026-10-21).
-- Ours, not upstream.
--
-- Reported by Rodrigo's father: on the Troll Sabotage path (north-east of
-- Edron, the mountain after the river vortex) werebadgers and a werefox were
-- there in the morning. TibiaWiki ("Troll Sabotage Quest"): the lycanthropes
-- there appear only at night; by day there are bats, wolves, bears and
-- skeletons. Our map spawned them all day. Canary can only make a whole
-- creature type night-only (respawnType), which would also change the
-- were-creatures of Grimvale and its caves, so these three spawns were taken
-- out of world/otservbr-monster.xml and are handled here: at night (Tibian
-- time 18:00 to 06:00, the same as the server's day/night light) each spot
-- gets its creature, again 90 s after it is killed (as the map's spawntime);
-- when day comes the ones still alive disappear.
--
-- Switch: Family.nightSpawns (false = no creatures at these spots at all).

Family = Family or {}
Family.nightSpawns = true

local RESPAWN = 90 -- seconds, as spawntime in the map's spawn file

local spots = {
	{ name = "Werebadger", pos = Position(33236, 31768, 3) },
	{ name = "Werebadger", pos = Position(33217, 31767, 4) },
	{ name = "Werefox", pos = Position(33237, 31775, 4) },
}

function Family.isNight()
	local minutes = getWorldTime()
	return minutes < 6 * 60 or minutes > 18 * 60
end

local function alive(spot)
	local creature = spot.id and Creature(spot.id)
	return creature and not creature:isRemoved() and creature:getHealth() > 0 and creature or nil
end

function Family.updateNightSpawns()
	if not Family.nightSpawns then
		return
	end
	local night, now = Family.isNight(), os.time()
	for _, spot in ipairs(spots) do
		local creature = alive(spot)
		if night then
			if not creature then
				if spot.id then
					spot.goneAt, spot.id = now, nil -- killed: wait for the respawn time
				end
				if not spot.goneAt or now - spot.goneAt >= RESPAWN then
					local monster = Game.createMonster(spot.name, spot.pos, true, false)
					if monster then
						spot.id, spot.goneAt = monster:getId(), nil
					end
				end
			end
		else
			if creature then
				creature:getPosition():sendMagicEffect(CONST_ME_POFF)
				creature:remove()
			end
			spot.id, spot.goneAt = nil, nil -- the first night creature comes at once
		end
	end
end

local think = GlobalEvent("FamilyNightSpawns")

function think.onThink(interval)
	Family.updateNightSpawns()
	return true
end

think:interval(10000)
think:register()

local startup = GlobalEvent("FamilyNightSpawnsStartup")

function startup.onStartup()
	logger.info("[Family] night spawns: {} ({} spots, Troll Sabotage path)", tostring(Family.nightSpawns), #spots)
	return true
end

startup:register()
