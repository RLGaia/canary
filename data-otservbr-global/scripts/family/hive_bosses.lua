-- Gaia Family server: the Hive bosses (2026-11-16, asked by Rodrigo after the War Against the Hive
-- build). Ours, not upstream: Canary v3.6.1 had only a Fleshslicer stub and no spawn for any of them.
--
-- The Hive underground (behind the hive gates 33484,31205,7 and 33506,31209,8, so the pheromone of
-- Orockle is needed): Chopper, Fleshslicer, Maw, Mindmasher, Rotspit and Shadowstalker appear only while
-- the Hive is in its third stage (TibiaWiki BR/EN), each on the square of its TibiaWiki BR map
-- ({{mapa}}); EN marks are a few squares away. Tibia does not say when they come back: here 2 hours
-- after the kill (Family.hiveBossRespawn, ours), also across restarts. When the Hive leaves stage 3
-- they disappear.
-- The Hive Outpost (Vandura, bottom floor, 32166,32865,9): The Hungerer, The Manhunter and The Mean
-- Masher share a spawn with the outpost creatures and come only now and then (BR: "you will need to
-- kill them countless times"). Our map has a Waspoid, a Spidris and a Kollos there (no Hive Overseer or
-- Spidris Elite): when one of those dies near the spot, one of the three bosses comes with a chance of
-- Family.hiveOutpostBossChance percent (5, ours), never two at a time.
-- Monster files: monster/bosses/chopper.lua ... the_mean_masher.lua, mindmasher_summon.lua.
-- Switch: Family.hiveBosses.

Family = Family or {}
Family.hiveBosses = true
Family.hiveBossRespawn = 2 * 60 * 60
Family.hiveOutpostBossChance = 5

FamilyHiveBosses = FamilyHiveBosses or {}
local B = FamilyHiveBosses

B.underground = {
	{ name = "Chopper", pos = Position(33524, 31265, 8) },
	{ name = "Fleshslicer", pos = Position(33420, 31269, 8) },
	{ name = "Maw", pos = Position(33507, 31248, 8) },
	{ name = "Mindmasher", pos = Position(33450, 31226, 8) },
	{ name = "Rotspit", pos = Position(33452, 31243, 8) },
	{ name = "Shadowstalker", pos = Position(33480, 31238, 8) },
}
B.outpost = { "The Hungerer", "The Manhunter", "The Mean Masher" }
B.OUTPOST_POS = Position(32166, 32865, 9)
B.OUTPOST_BOX = { x1 = 32150, y1 = 32845, x2 = 32185, y2 = 32880, z = 9 }
B.OUTPOST_SHARERS = { "Waspoid", "Spidris", "Kollos" }

local alive = {} -- boss name -> creature id
local outpostAlive = nil

local function store()
	return kv.scoped("family-hive-bosses")
end

local function key(name)
	return "next-" .. name:lower():gsub("%s", "-")
end

local function on()
	return Family.hiveBosses == true and FamilyHive ~= nil
end

local function isAlive(id)
	return id ~= nil and Creature(id) ~= nil
end

function B.isAlive(name)
	return isAlive(alive[name])
end

-- Checks the underground bosses: spawns the missing ones in stage 3, removes them outside it.
function B.check(now)
	if not on() then
		return
	end
	now = now or os.time()
	local stage = FamilyHive.stage()
	for _, boss in ipairs(B.underground) do
		local creature = alive[boss.name] and Creature(alive[boss.name])
		if stage < 3 then
			if creature then
				creature:getPosition():sendMagicEffect(CONST_ME_POFF)
				creature:remove()
			end
			alive[boss.name] = nil
		elseif not creature then
			alive[boss.name] = nil
			local nextAt = tonumber(store():get(key(boss.name))) or 0
			if now >= nextAt then
				local monster = Game.createMonster(boss.name, boss.pos, true, true)
				if monster then
					alive[boss.name] = monster:getId()
					monster:registerEvent("FamilyHiveBossDeath")
					logger.info("[Family] Hive boss {} appeared in the Hive underground", boss.name)
				else
					logger.warn("[Family] Hive boss {} could not appear", boss.name)
				end
			end
		end
	end
end

function B.outpostBossAlive()
	return isAlive(outpostAlive)
end

-- Called when a Waspoid, Spidris or Kollos dies; roll = 1..100 (tests pass it).
function B.onOutpostKill(pos, roll)
	if not on() then
		return false
	end
	local b = B.OUTPOST_BOX
	if pos.z ~= b.z or pos.x < b.x1 or pos.x > b.x2 or pos.y < b.y1 or pos.y > b.y2 then
		return false
	end
	if B.outpostBossAlive() then
		return false
	end
	roll = roll or math.random(1, 100)
	if roll > (tonumber(Family.hiveOutpostBossChance) or 5) then
		return false
	end
	local name = B.outpost[math.random(1, #B.outpost)]
	local monster = Game.createMonster(name, B.OUTPOST_POS, true, true)
	if monster then
		outpostAlive = monster:getId()
		monster:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		logger.info("[Family] Hive Outpost boss {} appeared", name)
		return name
	end
	return false
end

local death = CreatureEvent("FamilyHiveBossDeath")

function death.onDeath(creature)
	local name = creature:getName()
	for _, boss in ipairs(B.underground) do
		if boss.name == name then
			alive[name] = nil
			store():set(key(name), os.time() + (tonumber(Family.hiveBossRespawn) or 7200))
		end
	end
	return true
end

death:register()

local outpostDeath = CreatureEvent("FamilyHiveOutpostDeath")

function outpostDeath.onDeath(creature)
	if creature:getMaster() then
		return true
	end
	local pos = creature:getPosition()
	addEvent(function(p)
		B.onOutpostKill(p)
	end, 5000, Position(pos.x, pos.y, pos.z))
	return true
end

outpostDeath:register()

local think = GlobalEvent("FamilyHiveBossesThink")

function think.onThink(interval)
	B.check()
	return true
end

think:interval(60 * 1000)
think:register()

local startup = GlobalEvent("FamilyHiveBossesStartup")

function startup.onStartup()
	for _, name in ipairs(B.OUTPOST_SHARERS) do
		local mType = MonsterType(name)
		if mType then
			mType:registerEvent("FamilyHiveOutpostDeath")
		end
	end
	for _, boss in ipairs(B.underground) do
		if not MonsterType(boss.name) then
			logger.error("[Family] Hive boss {} has no monster file", boss.name)
		end
	end
	for _, name in ipairs(B.outpost) do
		if not MonsterType(name) then
			logger.error("[Family] Hive Outpost boss {} has no monster file", name)
		end
	end
	logger.info("[Family] Hive bosses: 6 in the Hive underground in stage 3 (back {} min after a kill), 3 in the Hive Outpost ({} percent)", math.floor((tonumber(Family.hiveBossRespawn) or 7200) / 60), Family.hiveOutpostBossChance)
	addEvent(B.check, 5000)
	return true
end

startup:register()
