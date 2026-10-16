-- Gaia Family server: the winter event, December only (2026-10-15).
--
-- Ours, not upstream. From December 1 to 31 (server clock):
--   1. Christmas tokens: every monster killed by a player has a small chance
--      to drop 1 christmas token (FamilyWinter.tokenChance per 100,000 kills,
--      multiplied by rateLoot; with rateLoot 3 that is 4.5%). Ruprecht on Vega
--      trades them all year (Nielson north of Carlin: hi, vega, yes).
--   2. Santa Claus stands in the Thais temple: hi, present. One present per
--      character per year (FAMILY: edit in data-otservbr-global/npc/santa_claus.lua).
--   3. Grynch Clan goblins steal presents in a random big city now and then:
--      harmless goblins that drop christmas present bags (Ruprecht gives 1
--      token for each) and snacks. One raid at a time, at least
--      FamilyWinter.grynchGapMinutes apart; leftovers leave after 30 minutes.
--   4. Percht Island opens: Captain Breezelda in Svargrond sails there
--      (hi, percht, yes). Perchts, Schiachs and bunnies live there; Frosty
--      trades the three Percht sleigh mounts for percht horns and broken bells
--      dropped by Perchts and Schiachs, and takes you back to Svargrond all
--      year (hi, svargrond, yes) (FAMILY: edits in captain_breezelda.lua and
--      frosty.lua). The Percht Queen fight is not implemented.
--   5. The newspaper tells about it.
--
-- Everything is checked against the current date while the server runs, so
-- the event starts and ends on its own, also without a restart.
--
-- Switches: FamilyWinter.enabled (whole event) and one per part below.

Family = Family or {}

FamilyWinter = {
	enabled = true,
	months = { [12] = true }, -- months the event runs (12 = December)

	tokens = true,
	tokenChance = 1500, -- per 100,000 kills, before rateLoot (1.5% x 3 = 4.5%)

	santa = true,
	santaPosition = Position(32366, 32240, 7), -- Thais temple

	grynch = true,
	grynchGapMinutes = 90, -- between two goblin raids
	grynchGoblins = 15, -- per raid, in three waves
	grynchStayMinutes = 30, -- goblins still alive then leave

	perchtIsland = true, -- boat from Svargrond (the way back is always open)
}

local cfg = FamilyWinter

local CHRISTMAS_TOKEN = 6526

function FamilyWinter.isActive()
	return cfg.enabled and cfg.months[os.date("*t").month] == true
end

local function partActive(part)
	return FamilyWinter.isActive() and cfg[part]
end

-- ---------------------------------------------------------------------------
-- 1. Christmas tokens
-- ---------------------------------------------------------------------------
-- Returns true when a token was put in the corpse.
function FamilyWinter.dropToken(monster, corpse)
	if not monster or not corpse or not partActive("tokens") then
		return false
	end
	local mType = monster:getType()
	if not mType or mType:isRewardBoss() then
		return false
	end
	local player = Player(corpse:getCorpseOwner())
	if not player or not player:canReceiveLoot() then
		return false
	end
	local chance = cfg.tokenChance * math.max(configManager.getNumber(configKeys.RATE_LOOT), 1)
	if math.random(100000) <= chance then
		return corpse:addItem(CHRISTMAS_TOKEN, 1) ~= nil
	end
	return false
end

local tokenDrop = EventCallback("FamilyWinterTokens")

function tokenDrop.monsterOnDropLoot(monster, corpse)
	FamilyWinter.dropToken(monster, corpse)
end

tokenDrop:register()

-- ---------------------------------------------------------------------------
-- 2. Santa Claus, 3. Grynch goblins (checked every minute)
-- ---------------------------------------------------------------------------
local santaId = nil

local function updateSanta()
	local santa = santaId and Npc(santaId)
	if partActive("santa") then
		if not santa then
			santa = Game.createNpc("Santa Claus", cfg.santaPosition, true, true)
			santaId = santa and santa:getId() or nil
			if not santa then
				logger.warn("[Family] winter: Santa Claus could not be placed at {}", cfg.santaPosition:toString())
			end
		end
	elseif santa then
		santa:getPosition():sendMagicEffect(CONST_ME_POFF)
		santa:remove()
		santaId = nil
	end
end

-- Big cities the goblins visit: an area around the temple (z 7). Goblins only
-- appear on open ground: never in protection zones or houses.
local GRYNCH_CITIES = {
	{ name = "Thais", from = Position(32325, 32185, 7), to = Position(32420, 32285, 7) },
	{ name = "Carlin", from = Position(32315, 31745, 7), to = Position(32400, 31830, 7) },
	{ name = "Venore", from = Position(32910, 32030, 7), to = Position(33000, 32120, 7) },
	{ name = "Ab'Dendriel", from = Position(32690, 31600, 7), to = Position(32780, 31690, 7) },
	{ name = "Edron", from = Position(33170, 31770, 7), to = Position(33260, 31850, 7) },
	{ name = "Kazordoon", from = Position(32610, 31890, 7), to = Position(32690, 31960, 7) },
}

local grynchKv = kv.scoped("family-winter")
local goblins = {} -- creature id -> true

local function goblinsAlive()
	local alive = 0
	for id in pairs(goblins) do
		if Monster(id) then
			alive = alive + 1
		else
			goblins[id] = nil
		end
	end
	return alive
end

local function freeSpot(city)
	for _ = 1, 60 do
		local position = Position(math.random(city.from.x, city.to.x), math.random(city.from.y, city.to.y), city.from.z)
		local tile = Tile(position)
		if tile and tile:getGround() and not tile:getHouse() and not tile:hasFlag(TILESTATE_PROTECTIONZONE) and tile:isWalkable(false, false, false, false, true) then
			return position
		end
	end
	return nil
end

local function spawnGoblins(cityIndex, amount)
	local city = GRYNCH_CITIES[cityIndex]
	local made = 0
	for _ = 1, amount do
		local position = freeSpot(city)
		local goblin = position and Game.createMonster("Grynch Clan Goblin", position)
		if goblin then
			goblins[goblin:getId()] = true
			position:sendMagicEffect(CONST_ME_TELEPORT)
			made = made + 1
		end
	end
	return made
end

local function goblinsLeave()
	for id in pairs(goblins) do
		local goblin = Monster(id)
		if goblin then
			goblin:getPosition():sendMagicEffect(CONST_ME_POFF)
			goblin:remove()
		end
		goblins[id] = nil
	end
end

function FamilyWinter.startGrynchRaid(cityIndex)
	cityIndex = cityIndex or math.random(#GRYNCH_CITIES)
	local city = GRYNCH_CITIES[cityIndex]
	grynchKv:set("grynch-last-start", os.time())
	Game.broadcastMessage("The Grynch Clan goblins are sneaking into " .. city.name .. " to steal the presents!", MESSAGE_EVENT_ADVANCE)
	local perWave = math.ceil(cfg.grynchGoblins / 3)
	local made = spawnGoblins(cityIndex, perWave)
	addEvent(spawnGoblins, 60 * 1000, cityIndex, perWave)
	addEvent(spawnGoblins, 120 * 1000, cityIndex, cfg.grynchGoblins - 2 * perWave)
	addEvent(goblinsLeave, cfg.grynchStayMinutes * 60 * 1000)
	return city.name, made
end

local function updateGrynch()
	if not partActive("grynch") then
		return
	end
	if goblinsAlive() > 0 or Game.getPlayerCount() < 1 then
		return
	end
	local last = grynchKv:get("grynch-last-start") or 0
	if os.time() - last < cfg.grynchGapMinutes * 60 then
		return
	end
	if math.random(100) <= 10 then -- about 10 minutes extra on average
		FamilyWinter.startGrynchRaid()
	end
end

local winterThink = GlobalEvent("FamilyWinterThink")

function winterThink.onThink(interval)
	updateSanta()
	updateGrynch()
	return true
end

winterThink:interval(60 * 1000)
winterThink:register()

local winterStartup = GlobalEvent("FamilyWinterStartup")

function winterStartup.onStartup()
	addEvent(updateSanta, 5000)
	logger.info("[Family] winter event: {} (December; tokens {}, Santa {}, Grynch goblins {}, Percht Island boat {}){}", cfg.enabled and "on" or "off", tostring(cfg.tokens), tostring(cfg.santa), tostring(cfg.grynch), tostring(cfg.perchtIsland), FamilyWinter.isActive() and " - ACTIVE NOW" or "")
	return true
end

winterStartup:register()

-- ---------------------------------------------------------------------------
-- 5. Newspaper lines (read by newspaper.lua)
-- ---------------------------------------------------------------------------
function FamilyWinter.newsLines()
	if not FamilyWinter.isActive() then
		return {}
	end
	local lines = { "  Winter event (all December):" }
	if cfg.tokens then
		lines[#lines + 1] = "   - Monsters drop christmas tokens; Ruprecht on Vega trades them."
	end
	if cfg.santa then
		lines[#lines + 1] = "   - Santa Claus waits in the Thais temple: one present a year."
	end
	if cfg.grynch then
		lines[#lines + 1] = "   - Grynch Clan goblins raid the big cities for presents."
	end
	if cfg.perchtIsland then
		lines[#lines + 1] = "   - Captain Breezelda (Svargrond) sails to Percht Island."
	end
	return lines
end
