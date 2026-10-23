-- Gaia Family server: a simplified Tibiadrome (2026-10-18). Ours, not
-- upstream. Our map has Tibia's Tibiadrome rooms (the lobby with Xodet and the
-- arena, reached through the demon trophies of Thais, Edron, Kazordoon,
-- Rathleton and Ankrahmun), but nothing happened in the arena. This adds the
-- fights. Phase 1: waves, Drome levels, infinite supplies. Rotations, points
-- and the reward exchange come in phase 2.
--
-- How it works
-- * Every demon trophy leads to the lobby in Thais; its exit leads back to the
--   trophy you came from.
-- * The two portals at the north wall of the lobby open the arena. Requirements:
--   level 50, no cooldown, arena free. A party goes in together: the leader
--   steps in and every member has to be in the lobby. The party size can be
--   anything; the level range of shared experience is the server's (our config
--   allows any levels).
-- * The party starts at the lowest Drome level among its members (the first
--   wave is that level + 1). Each wave has 2 minutes. Killing every creature
--   clears the wave: the Drome level of everyone still in the arena goes up
--   (if it is higher than their best) and the next wave starts after 5
--   seconds. When the time runs out, the run ends and everyone goes back to
--   the lobby.
-- * Creatures per wave: 4 for one player, 8 for two, 11 for three, 14 for four,
--   17 for five, 3 more for each further member. Four of the five Drome
--   creatures (tibiadrome_monsters.lua) in each wave.
-- * Strength: each wave 8% more hit points and damage than the first
--   (linear: wave 11 = +80%). Wave 1 is set for the party's average level:
--   level 100 = the values of tibiadrome_monsters.lua, level 300 = three times
--   them, level 50 or less = half. A living Domestikion makes the other Drome
--   creatures within 5 squares hit 15% harder.
-- * No death: a deadly hit heals the character fully and sends him to the
--   lobby; the run goes on for the others. The corner portals of the arena are
--   exits too.
-- * Party members cannot hurt each other in the arena (the map marks it as a
--   PvP zone).
-- * Supplies are infinite in the arena: the potions, runes and ammunition
--   (arrows, bolts, spears, throwing stars...) carried when entering are
--   refilled every second, up to the amount carried at the start.
-- * Cooldown: 10 minutes after leaving the arena (Tibia: 60; lowered on
--   2026-10-23 at Rodrigo's request). Players with access ignore it.
--
-- Switch: Family.tibiadrome (false = the teleports work as upstream and the
-- arena does nothing).

Family = Family or {}
Family.tibiadrome = true

local D = {
	waveSeconds = 120,
	pauseSeconds = 5,
	firstWaveDelay = 10,
	minLevel = 50,
	cooldown = 10 * 60,
	strengthPerWave = 0.08,
	referenceLevel = 100, -- party level that gets the base values of the creature files
	minLevelFactor = 0.5,
	domestikionBonus = 0.15,
	domestikionRange = 5,
	counts = { 4, 8, 11, 14, 17 },
	extraPerMember = 3,
	spawnDistance = 4, -- creatures appear at least this far from every player
	creatures = { "Domestikion", "Hoodinion", "Mearidion", "Murmillion", "Scissorion" },
	warnings = { 60, 30, 10 }, -- seconds left
}
Family.drome = D

local Z = 11
local LOBBY_ENTRY = Position(32251, 32205, Z) -- where the trophies lead
local LOBBY_RETURN = Position(32260, 32203, Z) -- where the arena exits lead
local ARENA_START = Position(32255, 32187, Z)
local LOBBY_PORTALS = { Position(32255, 32198, Z), Position(32256, 32198, Z) }
local LOBBY_EXIT = Position(32249, 32204, Z)
local ARENA_EXITS = { Position(32241, 32168, Z), Position(32269, 32168, Z), Position(32241, 32196, Z), Position(32269, 32196, Z) }
local LOBBY_RECT = { x1 = 32246, y1 = 32198, x2 = 32272, y2 = 32210 }
local ARENA_RECT = { x1 = 32240, y1 = 32168, x2 = 32270, y2 = 32196 }

-- Demon trophies (teleports) and where their lobby exit leads back to.
local TROPHIES = {
	thais = { trophy = Position(32352, 32221, 7), back = Position(32353, 32222, 7) },
	edron = { trophy = Position(33199, 31785, 7), back = Position(33199, 31787, 7) },
	kazordoon = { trophy = Position(32603, 31913, 8), back = Position(32603, 31915, 8) },
	rathleton = { trophy = Position(33602, 31888, 6), back = Position(33602, 31890, 6) },
	ankrahmun = { trophy = Position(33131, 32859, 7), back = Position(33131, 32857, 7) },
}

local POTIONS = {}
for _, id in ipairs({ 236, 237, 238, 239, 266, 268, 7642, 7643, 7644, 7876, 23373, 23374, 23375, 35563 }) do
	POTIONS[id] = true
end

local KV_SCOPE = "family-drome"

local function kv(player)
	return player:kv():scoped(KV_SCOPE)
end

local function inRect(pos, rect)
	return pos.z == Z and pos.x >= rect.x1 and pos.x <= rect.x2 and pos.y >= rect.y1 and pos.y <= rect.y2
end

function Family.inDromeArena(pos)
	return inRect(pos, ARENA_RECT)
end

-- Highest wave the character has cleared (his Drome level).
function Family.dromeLevel(player)
	local level = kv(player):get("level")
	return type(level) == "number" and level or 0
end

function Family.setDromeLevel(player, level)
	kv(player):set("level", level)
end

local function cooldownLeft(player)
	if player:getGroup():getAccess() then
		return 0
	end
	local untilTime = kv(player):get("cooldown")
	if type(untilTime) ~= "number" then
		return 0
	end
	return math.max(0, untilTime - os.time())
end

local function minutesText(seconds)
	local minutes = math.ceil(seconds / 60)
	return minutes == 1 and "1 minute" or (minutes .. " minutes")
end

-- ---------------------------------------------------------------------------
-- Arena tiles (found once)
-- ---------------------------------------------------------------------------
local arenaTiles

local function getArenaTiles()
	if arenaTiles then
		return arenaTiles
	end
	arenaTiles = {}
	for x = ARENA_RECT.x1, ARENA_RECT.x2 do
		for y = ARENA_RECT.y1, ARENA_RECT.y2 do
			local pos = Position(x, y, Z)
			local tile = Tile(pos)
			if tile and tile:getGround() and tile:hasFlag(TILESTATE_PVPZONE) and not tile:hasFlag(TILESTATE_TELEPORT) and not tile:hasProperty(CONST_PROP_BLOCKSOLID) then
				arenaTiles[#arenaTiles + 1] = pos
			end
		end
	end
	return arenaTiles
end

-- ---------------------------------------------------------------------------
-- Infinite supplies
-- ---------------------------------------------------------------------------
local function isSupply(itemId)
	if POTIONS[itemId] then
		return true
	end
	local itemType = ItemType(itemId)
	if not itemType or itemType:getId() == 0 then
		return false
	end
	if itemType:isRune() then
		return true
	end
	local weaponType = itemType:getWeaponType()
	return weaponType == WEAPON_AMMO or (weaponType == WEAPON_DISTANCE and itemType:isStackable())
end

local function supplySnapshot(player)
	local ids = {}
	local function visit(item)
		local id = item:getId()
		if isSupply(id) then
			ids[id] = true
		end
		if item:isContainer() then
			for _, inner in ipairs(item:getItems(true) or {}) do
				local innerId = inner:getId()
				if isSupply(innerId) then
					ids[innerId] = true
				end
			end
		end
	end
	for slot = CONST_SLOT_FIRST, CONST_SLOT_AMMO do
		local item = player:getSlotItem(slot)
		if item then
			visit(item)
		end
	end
	local snapshot = {}
	for id in pairs(ids) do
		snapshot[id] = player:getItemCount(id)
	end
	return snapshot
end

local function refillSupplies(player, snapshot)
	for id, wanted in pairs(snapshot or {}) do
		local missing = wanted - player:getItemCount(id)
		if missing > 0 then
			local stack = player:getItemById(id, true)
			if stack and ItemType(id):isStackable() then
				local add = math.min(missing, 100 - stack:getCount())
				if add > 0 then
					stack:transform(id, stack:getCount() + add)
					missing = missing - add
				end
			end
			if missing > 0 then
				player:addItem(id, missing)
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- The run
-- ---------------------------------------------------------------------------
local run -- nil when the arena is free

local function runPlayers()
	local list = {}
	if run then
		for id in pairs(run.players) do
			local player = Player(id)
			if player then
				list[#list + 1] = player
			end
		end
	end
	return list
end

local function tell(text, kind)
	for _, player in ipairs(runPlayers()) do
		player:sendTextMessage(kind or MESSAGE_EVENT_ADVANCE, text)
	end
end

local function creatureCount(members)
	if members <= #D.counts then
		return D.counts[members]
	end
	return D.counts[#D.counts] + (members - #D.counts) * D.extraPerMember
end

-- Strength of a wave: 1 = the values of the creature files.
local function waveStrength(wave)
	return run.levelFactor * (1 + D.strengthPerWave * (wave - 1))
end

local function removeMonsters()
	if not run then
		return
	end
	for id in pairs(run.monsters) do
		local monster = Monster(id)
		if monster then
			monster:getPosition():sendMagicEffect(CONST_ME_POFF)
			monster:remove()
		end
	end
	run.monsters = {}
end

local endRun

-- Takes a character out of the run and back to the lobby.
local function leaveRun(player, reason)
	if not run or not run.players[player:getId()] then
		return
	end
	local id = player:getId()
	refillSupplies(player, run.supplies[id])
	run.players[id] = nil
	run.supplies[id] = nil
	player:addHealth(player:getMaxHealth())
	player:addMana(player:getMaxMana())
	local cooldown = os.time() + D.cooldown
	kv(player):set("cooldown", cooldown)
	player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	player:teleportTo(LOBBY_RETURN)
	LOBBY_RETURN:sendMagicEffect(CONST_ME_TELEPORT)

	local reached = run.cleared > run.startLevel and string.format("You cleared up to wave %d.", run.cleared) or "No wave cleared this time."
	local text = string.format("%s %s Your Drome level is %d. You can enter the arena again in %s.", reason, reached, Family.dromeLevel(player), minutesText(D.cooldown))
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)

	if next(run.players) == nil then
		endRun()
	end
end

endRun = function(reason)
	if not run then
		return
	end
	for _, player in ipairs(runPlayers()) do
		leaveRun(player, reason or "The Tibiadrome run is over.")
	end
	removeMonsters()
	run = nil
end

local function freeSpawnPosition(players, used)
	local tiles = getArenaTiles()
	local fallback
	for _ = 1, 40 do
		local pos = tiles[math.random(#tiles)]
		local key = pos.x * 100000 + pos.y
		if not used[key] then
			fallback = fallback or pos
			local far = true
			for _, player in ipairs(players) do
				if player:getPosition():getDistance(pos) < D.spawnDistance then
					far = false
					break
				end
			end
			if far then
				used[key] = true
				return pos
			end
		end
	end
	return fallback or ARENA_START
end

local function spawnWave()
	if not run then
		return
	end
	local players = runPlayers()
	if #players == 0 then
		endRun()
		return
	end

	-- four of the five creatures, in a random order
	local kinds = {}
	for _, name in ipairs(D.creatures) do
		kinds[#kinds + 1] = name
	end
	table.remove(kinds, math.random(#kinds))
	for i = #kinds, 2, -1 do
		local j = math.random(i)
		kinds[i], kinds[j] = kinds[j], kinds[i]
	end

	local strength = waveStrength(run.wave)
	local count = creatureCount(run.members)
	local used = {}
	run.monsters = {}
	for i = 1, count do
		local name = kinds[(i - 1) % #kinds + 1]
		local pos = freeSpawnPosition(players, used)
		local monster = Game.createMonster(name, pos, false, true)
		if monster then
			local maxHealth = math.max(1, math.floor(monster:getMaxHealth() * strength + 0.5))
			monster:setMaxHealth(maxHealth)
			monster:setHealth(maxHealth)
			run.monsters[monster:getId()] = name
			pos:sendMagicEffect(CONST_ME_TELEPORT)
		end
	end
	run.deadline = os.time() + D.waveSeconds
	run.nextWaveAt = nil
	run.warned = {}
	tell(string.format("Wave %d! Defeat %d creatures within %s.", run.wave, count, minutesText(D.waveSeconds)))
end

local function waveCleared()
	run.cleared = run.wave
	for _, player in ipairs(runPlayers()) do
		if run.wave > Family.dromeLevel(player) then
			Family.setDromeLevel(player, run.wave)
		end
	end
	tell(string.format("Wave %d cleared! Drome level %d. The next wave starts in %d seconds.", run.wave, run.wave, D.pauseSeconds))
	run.wave = run.wave + 1
	run.deadline = nil
	run.nextWaveAt = os.time() + D.pauseSeconds
end

local function domestikionPulse()
	for id, name in pairs(run.monsters) do
		if name == "Domestikion" then
			local monster = Monster(id)
			if monster then
				monster:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
			end
		end
	end
end

local function tick(token)
	if not run or run.token ~= token then
		return
	end

	-- characters still in the arena; refill their supplies
	for id in pairs(run.players) do
		local player = Player(id)
		if not player then
			run.players[id] = nil
			run.supplies[id] = nil
		elseif not inRect(player:getPosition(), ARENA_RECT) then
			leaveRun(player, "You left the arena.")
			if not run then
				return
			end
		else
			refillSupplies(player, run.supplies[id])
		end
	end
	if next(run.players) == nil then
		endRun()
		return
	end

	local now = os.time()
	if run.nextWaveAt then
		if now >= run.nextWaveAt then
			spawnWave()
		end
	elseif run.deadline then
		local alive = 0
		for id in pairs(run.monsters) do
			local monster = Monster(id)
			if monster and monster:getHealth() > 0 then
				alive = alive + 1
			else
				run.monsters[id] = nil
			end
		end
		if alive == 0 then
			waveCleared()
		elseif now >= run.deadline then
			endRun("Time is up!")
			return
		else
			local left = run.deadline - now
			for _, warning in ipairs(D.warnings) do
				if left <= warning and not run.warned[warning] then
					run.warned[warning] = true
					tell(string.format("%d seconds left, %d creature%s to go.", warning, alive, alive == 1 and "" or "s"), MESSAGE_STATUS)
				end
			end
			if now % 3 == 0 then
				domestikionPulse()
			end
		end
	end

	addEvent(tick, 1000, token)
end

local function startRun(members)
	local lowest, levelSum = math.huge, 0
	for _, member in ipairs(members) do
		lowest = math.min(lowest, Family.dromeLevel(member))
		levelSum = levelSum + member:getLevel()
	end
	local averageLevel = levelSum / #members
	run = {
		token = os.time() * 1000 + math.random(999),
		players = {},
		supplies = {},
		monsters = {},
		members = #members,
		startLevel = lowest,
		cleared = lowest,
		wave = lowest + 1,
		levelFactor = math.max(D.minLevelFactor, averageLevel / D.referenceLevel),
		nextWaveAt = os.time() + D.firstWaveDelay,
		warned = {},
	}
	for _, member in ipairs(members) do
		run.players[member:getId()] = true
		run.supplies[member:getId()] = supplySnapshot(member)
		member:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		member:teleportTo(ARENA_START)
	end
	ARENA_START:sendMagicEffect(CONST_ME_TELEPORT)
	tell(string.format("Welcome to the Tibiadrome! Your %s at wave %d. The first wave comes in %d seconds.", #members > 1 and "party starts" or "run starts", run.wave, D.firstWaveDelay))
	addEvent(tick, 1000, run.token)
	logger.info("[Family] Tibiadrome: run started by {} ({} player(s), wave {}, level factor {})", members[1]:getName(), #members, run.wave, string.format("%.2f", run.levelFactor))
end

-- Checks of the lobby portals. Returns the members or nil and the reason.
local function checkEntry(player)
	if run then
		return nil, "The arena is busy. Wait until the current run is over."
	end
	local members = { player }
	local party = player:getParty()
	if party then
		local leader = party:getLeader()
		if not leader or leader:getId() ~= player:getId() then
			return nil, "Only the party leader can lead the party into the arena."
		end
		for _, member in ipairs(party:getMembers() or {}) do
			members[#members + 1] = member
		end
	end
	for _, member in ipairs(members) do
		local name = member:getId() == player:getId() and "You" or member:getName()
		if not inRect(member:getPosition(), LOBBY_RECT) then
			return nil, string.format("%s must be in the Tibiadrome lobby.", name)
		end
		if member:getLevel() < D.minLevel then
			return nil, string.format("%s must be level %d or higher.", name, D.minLevel)
		end
		local left = cooldownLeft(member)
		if left > 0 then
			return nil, string.format("%s can enter the arena again in %s.", name, minutesText(left))
		end
	end
	return members
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local function pushBack(player, position, fromPosition)
	local back = fromPosition
	if not back or (back.x == position.x and back.y == position.y and back.z == position.z) then
		back = LOBBY_RETURN
	end
	player:teleportTo(back, true)
end

local portals = MoveEvent()

function portals.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.tibiadrome then
		return true
	end
	local members, reason = checkEntry(player)
	if not members then
		pushBack(player, position, fromPosition)
		player:sendTextMessage(MESSAGE_FAILURE, reason)
		position:sendMagicEffect(CONST_ME_POFF)
		return true
	end
	startRun(members)
	return true
end

portals:type("stepin")
portals:position((table.unpack or unpack)(LOBBY_PORTALS))
portals:register()

local exits = MoveEvent()

function exits.onStepIn(creature, item, position, fromPosition)
	if not Family.tibiadrome then
		return true
	end
	local player = creature:getPlayer()
	if player and run and run.players[player:getId()] then
		leaveRun(player, "You left the arena.")
	elseif player then
		player:teleportTo(LOBBY_RETURN)
		LOBBY_RETURN:sendMagicEffect(CONST_ME_TELEPORT)
	else
		creature:teleportTo(ARENA_START)
	end
	return true
end

exits:type("stepin")
exits:position((table.unpack or unpack)(ARENA_EXITS))
exits:register()

local trophyPositions = {}
local trophyByKey = {}
for key, trophy in pairs(TROPHIES) do
	trophyPositions[#trophyPositions + 1] = trophy.trophy
	trophyByKey[trophy.trophy.x * 100000 + trophy.trophy.y] = key
end

local trophies = MoveEvent()

function trophies.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.tibiadrome then
		return true
	end
	local key = trophyByKey[position.x * 100000 + position.y] or "thais"
	kv(player):set("origin", key)
	player:teleportTo(LOBBY_ENTRY)
	LOBBY_ENTRY:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

trophies:type("stepin")
trophies:position((table.unpack or unpack)(trophyPositions))
trophies:register()

local lobbyExit = MoveEvent()

function lobbyExit.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not Family.tibiadrome then
		return true
	end
	local origin = TROPHIES[kv(player):get("origin") or "thais"] or TROPHIES.thais
	player:teleportTo(origin.back)
	origin.back:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

lobbyExit:type("stepin")
lobbyExit:position(LOBBY_EXIT)
lobbyExit:register()

-- No death in the arena.
local death = CreatureEvent("FamilyDromeDeath")

function death.onPrepareDeath(creature, killer)
	local player = creature:getPlayer()
	if not player or not run or not run.players[player:getId()] then
		return true
	end
	player:addHealth(player:getMaxHealth())
	local playerId = player:getId()
	addEvent(function()
		local p = Player(playerId)
		if p then
			leaveRun(p, "You were defeated!")
		end
	end, 0)
	return false
end

death:register()

local login = CreatureEvent("FamilyDromeLogin")

function login.onLogin(player)
	player:registerEvent("FamilyDromeDeath")
	-- left in the arena by a restart
	if inRect(player:getPosition(), ARENA_RECT) and not (run and run.players[player:getId()]) then
		player:teleportTo(LOBBY_RETURN)
	end
	return true
end

login:register()

-- Damage: Drome creatures by wave (and Domestikion); no damage between players.
local combat = EventCallback("FamilyDromeCombat")

function combat.creatureOnCombat(caster, target, damage)
	if not run or not caster or not target then
		return true
	end
	local casterId = caster:getId()
	local name = run.monsters[casterId]
	if name then
		local multiplier = waveStrength(run.wave)
		if name ~= "Domestikion" then
			local pos = caster:getPosition()
			for id, other in pairs(run.monsters) do
				if other == "Domestikion" then
					local domestikion = Monster(id)
					if domestikion and domestikion:getPosition():getDistance(pos) <= D.domestikionRange then
						multiplier = multiplier * (1 + D.domestikionBonus)
						break
					end
				end
			end
		end
		if damage.primary.type ~= COMBAT_HEALING then
			damage.primary.value = math.floor(damage.primary.value * multiplier)
		end
		if damage.secondary.type ~= COMBAT_HEALING then
			damage.secondary.value = math.floor(damage.secondary.value * multiplier)
		end
	elseif caster:isPlayer() and target:isPlayer() and run.players[target:getId()] then
		if damage.primary.type ~= COMBAT_HEALING then
			damage.primary.value = 0
		end
		if damage.secondary.type ~= COMBAT_HEALING then
			damage.secondary.value = 0
		end
	end
	return true
end

combat:register()

local startup = GlobalEvent("FamilyTibiadrome")

function startup.onStartup()
	-- The map's teleports go nowhere; the move events above do the work.
	local changed, problems = 0, {}
	local function silence(pos)
		local tile = Tile(pos)
		local teleport = tile and tile:getItemById(1959)
		if teleport and teleport.setDestination then
			teleport:setDestination(Position(0, 0, 0))
			changed = changed + 1
		else
			problems[#problems + 1] = string.format("%d,%d,%d", pos.x, pos.y, pos.z)
		end
	end
	if Family.tibiadrome then
		for _, pos in ipairs(LOBBY_PORTALS) do
			silence(pos)
		end
		for _, pos in ipairs(ARENA_EXITS) do
			silence(pos)
		end
		for _, pos in ipairs(trophyPositions) do
			silence(pos)
		end
		silence(LOBBY_EXIT)
	end
	logger.info("[Family] Tibiadrome: {} teleports taken over, {} arena squares{}", changed, #getArenaTiles(), #problems > 0 and (", NOT FOUND: " .. table.concat(problems, " ")) or "")
	return true
end

startup:register()
