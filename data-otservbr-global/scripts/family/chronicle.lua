-- Gaia Family server: the adventurers' chronicle (2026-10-26).
--
-- Ours, not upstream. Records what each character achieved during a
-- newspaper day (06:00 to 06:00, like the Gaia Times) so the newspaper can
-- print the chronicle of the last day played (normally yesterday). Asked by
-- Rodrigo: only the last of each kind per character and day - the last level
-- reached, the last level of each skill, the last death - plus every
-- achievement, quest, bestiary entry and house of that day, and the last
-- bosstiary level reached with each boss.
--
-- Where each milestone comes from (no C++ change):
--   level, skills    CreatureEvent onAdvance (registered at login)
--   death            CreatureEvent onDeath (registered at login)
--   achievements     wrapper of Player.addAchievement (every achievement is
--                    granted through it; it returns false when already owned)
--   quests           EventCallback playerOnStorageUpdate: a quest counts when
--                    the quest log's completion rule (endStorage, or every
--                    mission at its end value) holds with the new value and did
--                    not hold with the old one
--   bestiary,        no engine event exists. At login the finished bestiary
--   bosstiary        entries and the bosstiary levels are noted; after a kill
--                    (playerOnGainExperience with a monster target, and
--                    monsterPostDropLoot) that creature type is checked again
--                    for every online player 200 ms later
--   houses           wrapper of House.setHouseOwner (Cyclopedia purchase,
--                    !buyhouse and /owner all go through it)
-- Characters of the GOD group are left out.
--
-- Storage: global KV scope "family-chronicle.<day>", one map per character
-- (key g<guid>). Days older than keepDays are removed at startup.

Family = Family or {}

FamilyChronicle = {
	enabled = true,
	keepDays = 14, -- days kept in the database
	lookBackDays = 7, -- the newspaper prints the last day with news within this many days
	maxPerList = 6, -- items per list in the newspaper, then "and n more"
	checkDelay = 200, -- ms after a kill before bestiary/bosstiary are read again
}

local cfg = FamilyChronicle
if not cfg.enabled then
	return
end

local SCOPE = "family-chronicle"
local DAY = 24 * 60 * 60

local SKILL_NAMES = {
	[SKILL_FIST] = "fist fighting",
	[SKILL_CLUB] = "club fighting",
	[SKILL_SWORD] = "sword fighting",
	[SKILL_AXE] = "axe fighting",
	[SKILL_DISTANCE] = "distance fighting",
	[SKILL_SHIELD] = "shielding",
	[SKILL_FISHING] = "fishing",
	[SKILL_MAGLEVEL] = "magic level",
}
local SKILL_ORDER = { "magic level", "fist fighting", "club fighting", "sword fighting", "axe fighting", "distance fighting", "shielding", "fishing" }
local BOSS_LEVELS = { "Prowess", "Expertise", "Mastery" }

-- ---------------------------------------------------------------------------
-- Days (same rule as the newspaper)
-- ---------------------------------------------------------------------------
local function dayStartHour()
	return (FamilyNewspaper and FamilyNewspaper.dayStartHour) or 6
end

function Family.newsDayKey(now)
	now = now or os.time()
	local t = os.date("*t", now)
	t.hour, t.min, t.sec = dayStartHour(), 0, 0
	local start = os.time(t)
	if start > now then
		start = start - DAY
	end
	return os.date("%Y-%m-%d", start)
end

-- The day key "count" days before key ("2026-10-26", 1 -> "2026-10-25").
function Family.newsDayBefore(key, count)
	local y, m, d = key:match("(%d+)-(%d+)-(%d+)")
	local stamp = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d) - (count or 1), hour = 12 })
	return os.date("%Y-%m-%d", stamp)
end

-- ---------------------------------------------------------------------------
-- Recording
-- ---------------------------------------------------------------------------
local function dayScope(key)
	return kv.scoped(SCOPE):scoped(key)
end

local function counts(player)
	if not player or not player:isPlayer() then
		return false
	end
	local group = player:getGroup()
	return not (group and group:getAccess())
end

-- Runs change(entry) on today's entry of the player and saves it.
local function update(player, change)
	if not counts(player) then
		return
	end
	local scope = dayScope(Family.newsDayKey())
	local key = "g" .. player:getGuid()
	local entry = scope:get(key) or {}
	entry.n = player:getName()
	change(entry)
	scope:set(key, entry)
end

local function addToList(entry, field, text)
	local list = entry[field]
	if type(list) ~= "table" then
		list = {}
	end
	for _, existing in ipairs(list) do
		if existing == text then
			return
		end
	end
	list[#list + 1] = text
	entry[field] = list
end

function Family.chronicleRecord(player, field, text)
	update(player, function(entry)
		addToList(entry, field, text)
	end)
end

-- Level and skills: only the last value of the day is kept.
local advance = CreatureEvent("FamilyChronicleAdvance")
function advance.onAdvance(player, skill, oldLevel, newLevel)
	if newLevel <= oldLevel then
		return true
	end
	if skill == SKILL_LEVEL then
		update(player, function(entry)
			entry.l = newLevel
		end)
	elseif SKILL_NAMES[skill] then
		update(player, function(entry)
			local skills = type(entry.s) == "table" and entry.s or {}
			skills[SKILL_NAMES[skill]] = newLevel
			entry.s = skills
		end)
	end
	return true
end
advance:register()
cfg.onAdvance = advance.onAdvance

-- Death: only the last one of the day.
local function killerText(killer)
	if not killer then
		return nil
	end
	if killer:isPlayer() then
		return killer:getName()
	end
	local master = killer:getMaster()
	if master and master:isPlayer() then
		return master:getName()
	end
	if killer:isMonster() then
		local mType = killer:getType()
		local description = mType and mType:nameDescription()
		if description and description ~= "" then
			return description:lower()
		end
	end
	return killer:getName():lower()
end

local death = CreatureEvent("FamilyChronicleDeath")
function death.onDeath(player, corpse, killer, mostDamageKiller, lastHitUnjustified, mostDamageUnjustified)
	local by = killerText(killer) or killerText(mostDamageKiller)
	local text = by and string.format("slain by %s at level %d", by, player:getLevel()) or string.format("died at level %d", player:getLevel())
	update(player, function(entry)
		entry.d = text
	end)
	return true
end
death:register()
cfg.onDeath = death.onDeath

-- Achievements.
local addAchievement = Player.addAchievement
function Player.addAchievement(self, achievement, ...)
	local success = addAchievement(self, achievement, ...)
	if success and Family.chronicleEnabled then
		local name = achievement
		if type(achievement) == "number" then
			local info = Game.getAchievementInfoById(achievement)
			name = info and info.name or nil
		end
		if name and name ~= "" then
			Family.chronicleRecord(self, "a", name)
		end
	end
	return success
end

-- Houses. (cfg.findPlayer can be replaced by a test.)
cfg.findPlayer = function(guid)
	return Player(guid)
end
local setHouseOwner = House.setHouseOwner
function House.setHouseOwner(self, guid, ...)
	local before = self:getOwnerGuid()
	local result = setHouseOwner(self, guid, ...)
	if Family.chronicleEnabled and guid and guid > 0 and guid ~= before then
		local owner = cfg.findPlayer(guid)
		if owner then
			local town = self:getTown()
			local text = self:getName()
			if town then
				text = string.format("%s (%s)", text, town:getName())
			end
			Family.chronicleRecord(owner, "h", text)
		end
	end
	return result
end

-- Quests.
local questsByKey

local function questKeys(quest)
	local keys = {}
	if quest.endStorageId and quest.endStorageValue then
		keys[#keys + 1] = quest.endStorageId
	elseif quest.missions and #quest.missions > 0 then
		for _, mission in ipairs(quest.missions) do
			if mission.storageId then
				keys[#keys + 1] = mission.storageId
			end
		end
	end
	return keys
end

local function buildQuestIndex()
	questsByKey = {}
	for questId in pairs(Quests or {}) do
		local quest = Game.getQuest(questId)
		if quest and quest.name then
			for _, key in ipairs(questKeys(quest)) do
				questsByKey[key] = questsByKey[key] or {}
				table.insert(questsByKey[key], questId)
			end
		end
	end
end

-- The quest log's completion rule (Player.questIsCompleted), with one storage
-- read as "value".
local function completedWith(player, quest, key, value)
	local function get(k)
		if k == key then
			return value
		end
		return player:getStorageValue(k)
	end
	if quest.endStorageId and quest.endStorageValue then
		local v = get(quest.endStorageId)
		return v ~= -1 and v >= quest.endStorageValue
	end
	if not quest.missions or #quest.missions == 0 then
		return false
	end
	for _, mission in ipairs(quest.missions) do
		local v = get(mission.storageId)
		if v == -1 or v < mission.endValue then
			return false
		end
	end
	return true
end

function Family.chronicleQuestCheck(player, key, value, oldValue)
	if not questsByKey then
		buildQuestIndex()
	end
	local ids = questsByKey[key]
	if not ids or value == oldValue then
		return
	end
	for _, questId in ipairs(ids) do
		local quest = Game.getQuest(questId)
		if quest and completedWith(player, quest, key, value) and not completedWith(player, quest, key, oldValue or -1) then
			Family.chronicleRecord(player, "q", quest.name)
		end
	end
end

local storageCallback = EventCallback("FamilyChronicleQuests")
function storageCallback.playerOnStorageUpdate(player, key, value, oldValue, currentFrameTime)
	if Family.chronicleEnabled then
		Family.chronicleQuestCheck(player, key, value, oldValue)
	end
end
storageCallback:register()

-- Bestiary and bosstiary.
local known = {} -- [guid] = { bestiary = {[raceId] = true}, boss = {[name] = level} }
local bestiaryRaces -- [raceId] = name
local bossNames -- list of bosstiary boss names

local function loadLists()
	if bestiaryRaces then
		return
	end
	bestiaryRaces = {}
	for _, raceId in ipairs(Game.getBestiaryList() or {}) do
		bestiaryRaces[raceId] = true
	end
	bossNames = {}
	for _, mType in pairs(Game.getMonsterTypes() or {}) do
		if mType:bossRace() ~= nil and mType:raceId() > 0 then
			bossNames[#bossNames + 1] = mType:name()
		end
	end
end

function Family.chronicleNoteProgress(player)
	loadLists()
	local state = { bestiary = {}, boss = {} }
	for raceId in pairs(bestiaryRaces) do
		if player:isMonsterBestiaryUnlocked(raceId) then
			state.bestiary[raceId] = true
		end
	end
	for _, name in ipairs(bossNames) do
		state.boss[name] = player:getBosstiaryLevel(name) or 0
	end
	known[player:getGuid()] = state
end

local pending = {}

function cfg.checkType(typeName, players)
	pending[typeName] = nil
	local mType = MonsterType(typeName)
	if not mType then
		return
	end
	local name = mType:name()
	local isBoss = mType:bossRace() ~= nil -- bosstiary class set (bossRaceId() is 0 for bane bosses)
	local raceId = mType:raceId()
	for _, player in ipairs(players or Game.getPlayers()) do
		local state = known[player:getGuid()]
		if state then
			if isBoss then
				if state.boss[name] ~= nil then
					local level = player:getBosstiaryLevel(name) or 0
					if level > state.boss[name] then
						state.boss[name] = level
						if BOSS_LEVELS[level] then
							-- only the last level reached with each boss
							local prefix = name .. " ("
							update(player, function(entry)
								local list = {}
								for _, text in ipairs(type(entry.x) == "table" and entry.x or {}) do
									if text:sub(1, #prefix) ~= prefix then
										list[#list + 1] = text
									end
								end
								list[#list + 1] = string.format("%s (%s)", name, BOSS_LEVELS[level])
								entry.x = list
							end)
						end
					end
				end
			elseif raceId > 0 and bestiaryRaces[raceId] and not state.bestiary[raceId] then
				if player:isMonsterBestiaryUnlocked(raceId) then
					state.bestiary[raceId] = true
					Family.chronicleRecord(player, "b", name)
				end
			end
		end
	end
end

function Family.chronicleKilled(mType)
	if not mType or not Family.chronicleEnabled then
		return
	end
	local typeName = mType:name()
	if pending[typeName] then
		return
	end
	pending[typeName] = true
	addEvent(cfg.checkType, cfg.checkDelay, typeName)
end

local killCallback = EventCallback("FamilyChronicleKillExp")
function killCallback.playerOnGainExperience(player, target, exp, rawExp)
	if target and target:isMonster() and not target:getMaster() then
		Family.chronicleKilled(target:getType())
	end
end
killCallback:register()

local lootCallback = EventCallback("FamilyChronicleKillLoot")
function lootCallback.monsterPostDropLoot(monster, corpse)
	Family.chronicleKilled(monster:getType())
end
lootCallback:register()

-- Login and logout.
local login = CreatureEvent("FamilyChronicleLogin")
function login.onLogin(player)
	player:registerEvent("FamilyChronicleAdvance")
	player:registerEvent("FamilyChronicleDeath")
	player:registerEvent("FamilyChronicleLogout")
	if counts(player) then
		Family.chronicleNoteProgress(player)
	end
	return true
end
login:register()

local logout = CreatureEvent("FamilyChronicleLogout")
function logout.onLogout(player)
	known[player:getGuid()] = nil
	return true
end
logout:register()

-- ---------------------------------------------------------------------------
-- Reading (used by the newspaper)
-- ---------------------------------------------------------------------------
local function entriesOf(key)
	local scope = dayScope(key)
	local entries = {}
	for _, k in ipairs(scope:keys() or {}) do
		local entry = scope:get(k)
		if type(entry) == "table" and entry.n then
			entries[#entries + 1] = entry
		end
	end
	table.sort(entries, function(a, b)
		return a.n < b.n
	end)
	return entries
end

local function listText(list)
	if type(list) ~= "table" or #list == 0 then
		return nil
	end
	local shown = {}
	for i = 1, math.min(#list, cfg.maxPerList) do
		shown[#shown + 1] = list[i]
	end
	local text = table.concat(shown, ", ")
	if #list > cfg.maxPerList then
		text = text .. string.format(" and %d more", #list - cfg.maxPerList)
	end
	return text
end

-- The day shown in the edition of "key": the last day before it with news.
-- Returns dayKey, lines (nil when no news within lookBackDays).
function Family.chronicleLines(key)
	for back = 1, cfg.lookBackDays do
		local day = Family.newsDayBefore(key, back)
		local entries = entriesOf(day)
		if #entries > 0 then
			local out = {}
			for _, entry in ipairs(entries) do
				out[#out + 1] = "  " .. entry.n
				if entry.l then
					out[#out + 1] = string.format("    Reached level %d.", entry.l)
				end
				if type(entry.s) == "table" then
					local skills = {}
					for _, skillName in ipairs(SKILL_ORDER) do
						if entry.s[skillName] then
							skills[#skills + 1] = string.format("%s %d", skillName, entry.s[skillName])
						end
					end
					if #skills > 0 then
						out[#out + 1] = "    Skills: " .. table.concat(skills, ", ") .. "."
					end
				end
				local lists = {
					{ "a", "Achievements: " },
					{ "q", "Quests completed: " },
					{ "b", "Bestiary completed: " },
					{ "x", "Bosstiary: " },
					{ "h", "New house: " },
				}
				for _, item in ipairs(lists) do
					local text = listText(entry[item[1]])
					if text then
						out[#out + 1] = "    " .. item[2] .. text .. "."
					end
				end
				if entry.d then
					out[#out + 1] = "    Last death: " .. entry.d .. "."
				end
			end
			return day, out
		end
	end
	return nil, nil
end

-- The changelog lines for the edition of "key": changes of the last
-- FamilyChangelogDays days up to that day, newest first.
function Family.changelogLines(key, maxLines)
	maxLines = maxLines or 10
	local first = Family.newsDayBefore(key, (FamilyChangelogDays or 7) - 1)
	local found = {}
	for i = #(FamilyChangelog or {}), 1, -1 do
		local change = FamilyChangelog[i]
		if change[1] <= key and change[1] >= first then
			found[#found + 1] = change
		end
	end
	local out = {}
	for i = 1, math.min(#found, maxLines) do
		local y, m, d = found[i][1]:match("(%d+)-(%d+)-(%d+)")
		local stamp = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
		out[#out + 1] = string.format("  %s %d: %s", os.date("%b", stamp), tonumber(d), found[i][2])
	end
	if #found > maxLines then
		out[#out + 1] = string.format("  ...and %d earlier changes this week.", #found - maxLines)
	end
	return out
end

-- Old days are removed at startup.
function cfg.cleanup()
	local oldest = Family.newsDayBefore(Family.newsDayKey(), cfg.keepDays)
	local removed = 0
	for _, k in ipairs(kv.keys(SCOPE .. ".") or {}) do
		local day = k:match("^(%d+%-%d+%-%d+)%.")
		if day and day < oldest then
			kv.remove(SCOPE .. "." .. k)
			removed = removed + 1
		end
	end
	return removed
end

local startup = GlobalEvent("FamilyChronicleStartup")
function startup.onStartup()
	local removed = cfg.cleanup()
	Family.chronicleEnabled = true
	logger.info("[Family] chronicle: on, changelog {} lines, {} old entries removed", #(FamilyChangelog or {}), removed)
	return true
end
startup:register()
