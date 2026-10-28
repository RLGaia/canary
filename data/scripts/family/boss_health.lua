-- Gaia Family server: small bosses keep their full health (2026-10-27).
-- Ours, not upstream.
--
-- rateBossHealth = 0.5 (family/config.family.lua, since 2026-10-12) halves
-- the health of every Bosstiary boss, because most quest and lever bosses are
-- tuned for five players. Bosses made for one player (rare spawns, small quest
-- bosses: Hairman the Huge 600, Rotworm Queen, Willi Wasp, the pharaohs...)
-- became trivial at half health. Chosen by Rodrigo on 2026-10-27: bosses whose
-- monster file has Family.fullHealthBossMax (20,000) health or less keep their
-- full health; the bigger ones (141 of 247) stay at half.
--
-- How: the server multiplies a boss type's health by rateBossHealth when the
-- boss is created (monster.cpp), so at startup the type's health (and the
-- health at which it runs away) is divided by the rate; in game it is then
-- the file's value again. Bosses already placed by the map spawns at that
-- moment (map spawns start before the startup scripts) are found around
-- their spawn spots and given their full health too.
--
-- The file's health is kept in Family.bossFileHealth[typeName]; boss coins
-- (boss_coins.lua) use it, so this changes no reward.
--
-- Switch: Family.fullHealthSmallBosses (false = every boss at half health).

Family = Family or {}
Family.fullHealthSmallBosses = true
Family.fullHealthBossMax = 20000
Family.bossFileHealth = Family.bossFileHealth or {}

local restored = {} -- display name (lower) -> file health, for the map scan

-- Map spawns of the restored bosses: positions of their spawn points.
local function spawnSpots()
	local spots = {}
	local path = configManager.getString(configKeys.DATA_DIRECTORY) .. "/world/" .. configManager.getString(configKeys.MAP_NAME) .. "-monster.xml"
	local file = io.open(path, "r")
	if not file then
		return spots
	end
	local content = file:read("*a")
	file:close()
	for cx, cy, cz, body in content:gmatch('<monsters? centerx="(%d+)" centery="(%d+)" centerz="(%d+)"[^>]*>(.-)</monsters?>') do
		for name, x, y, z in body:gmatch('<monster name="([^"]+)" x="(%-?%d+)" y="(%-?%d+)" z="(%d+)"') do
			if restored[name:lower()] then
				spots[#spots + 1] = { name = name:lower(), pos = Position(tonumber(cx) + tonumber(x), tonumber(cy) + tonumber(y), tonumber(z)) }
			end
		end
	end
	return spots
end

local function fixPlaced()
	local fixed = 0
	for _, spot in ipairs(spawnSpots()) do
		for _, creature in ipairs(Game.getSpectators(spot.pos, false, false, 3, 3, 3, 3)) do
			local health = restored[spot.name]
			if creature:isMonster() and creature:getName():lower() == spot.name and creature:getMaxHealth() < health then
				creature:setMaxHealth(health)
				creature:addHealth(health)
				fixed = fixed + 1
			end
		end
	end
	return fixed
end

local startup = GlobalEvent("FamilyBossHealth")

function startup.onStartup()
	local rate = configManager.getFloat(configKeys.RATE_BOSS_HEALTH)
	if not Family.fullHealthSmallBosses or rate <= 0 or rate >= 1 then
		logger.info("[Family] small bosses at full health: off")
		return true
	end
	local count = 0
	for typeName, mType in pairs(Game.getMonsterTypes()) do
		local health = mType:maxHealth() or 0
		if mType:bossRace() ~= nil and health > 0 and health <= Family.fullHealthBossMax then
			Family.bossFileHealth[typeName] = health
			restored[mType:name():lower()] = health
			mType:maxHealth(math.floor(health / rate + 0.5))
			mType:health(math.floor(health / rate + 0.5))
			local run = mType:runHealth() or 0
			if run > 0 then
				mType:runHealth(math.floor(run / rate + 0.5))
			end
			count = count + 1
		end
	end
	local fixed = fixPlaced()
	logger.info("[Family] small bosses at full health: {} bosses with up to {} health ({} already on the map restored)", count, Family.fullHealthBossMax, fixed)
	return true
end

startup:register()
