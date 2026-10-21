-- Gaia Family server: adventurer's stone from temple NPCs (2026-10-17). Ours,
-- not upstream.
--
-- As in Tibia, every temple NPC (Quentin, Alia, Isimov, Rahkem, Kasmir and 15
-- more) hands out an adventurer's stone: hi, adventurer's stone, yes. Two
-- upstream problems are fixed without changing the NPC files:
--   1. The NPCs only understood "adventurer stone". Now "adventurer's stone",
--      "adventurers stone" and "adventurers' stone" work too.
--   2. The free stone was free only once per NPC, forever. Now, as in Tibia,
--      the first stone of each day is free (from any temple NPC) and further
--      ones cost 30 gold (bank or backpack). The day starts at the server save
--      time (globalServerSaveTime, 06:00).
-- Unchanged: an NPC answers "Keep your adventurer's stone well." while you
-- carry one.
--
-- Switch: Family.dailyFreeAdventurerStone (false = upstream: once per NPC).

Family = Family or {}
Family.dailyFreeAdventurerStone = true
-- (2026-10-20) The stone works anywhere, not only in temples: not during a
-- fight, not where logging out is not allowed, not in boss or encounter zones
-- (FAMILY: in actions/adventurers_guild/adventurers_stone.lua). The guild's
-- exit portal always leads to the home temple (FAMILY: in
-- movements/teleport/adventurers_guild.lua). false = upstream for each.
Family.adventurerStoneAnywhere = true
Family.adventurerGuildExitHome = true

local KV_SCOPE = "family-adventurer-stone"

-- "adventurer's stone" and its variants as the NPCs' keyword.
function Family.normalizeStoneMessage(message)
	if type(message) ~= "string" then
		return message
	end
	return (message:gsub("([Aa][Dd][Vv][Ee][Nn][Tt][Uu][Rr][Ee][Rr])'?[Ss]?'?(%s+[Ss][Tt][Oo][Nn][Ee])", "%1%2"))
end

local freeStoneKeys = {}

local function buildKeys()
	local list = Storage and Storage.Quest and Storage.Quest.U9_80 and Storage.Quest.U9_80.AdventurersGuild and Storage.Quest.U9_80.AdventurersGuild.FreeStone
	for _, key in pairs(list or {}) do
		if type(key) == "number" then
			freeStoneKeys[key] = true
		end
	end
end

buildKeys()

-- The game day: it changes at the server save time.
function Family.stoneDay(now)
	now = now or os.time()
	local hour = 6
	if configManager and configKeys and configKeys.GLOBAL_SERVER_SAVE_TIME then
		local text = configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME) or ""
		hour = tonumber(text:match("^(%d+)")) or 6
	end
	return os.date("%Y-%m-%d", now - hour * 3600)
end

local function usedToday(player)
	return player:kv():scoped(KV_SCOPE):get("free-day") == Family.stoneDay()
end

-- Sets the NPCs' "free stone taken" storages from today's state.
function Family.syncFreeStone(player)
	if not Family.dailyFreeAdventurerStone then
		return
	end
	local value = usedToday(player) and 1 or -1
	for key in pairs(freeStoneKeys) do
		if player:getStorageValue(key) ~= value then
			player:setStorageValue(key, value)
		end
	end
end

-- The NPCs mark the free stone as taken by writing 1 to their storage.
local originalSetStorageValue = Player.setStorageValue
function Player.setStorageValue(self, key, value, ...)
	if Family.dailyFreeAdventurerStone and freeStoneKeys[key] and value == 1 then
		self:kv():scoped(KV_SCOPE):set("free-day", Family.stoneDay())
	end
	return originalSetStorageValue(self, key, value, ...)
end

-- The NPC library is loaded after these scripts, so the hook is installed at
-- startup (before anyone can log in).
local function installHook()
	if not KeywordHandler then
		return false
	end
	if KeywordHandler.familyAdventurerStone then
		return true
	end
	local originalProcessMessage = KeywordHandler.processMessage
	function KeywordHandler:processMessage(npc, player, message)
		message = Family.normalizeStoneMessage(message)
		if Family.dailyFreeAdventurerStone and type(message) == "string" then
			local lower = message:lower()
			if lower:find("adventurer stone", 1, true) or lower:find("yes", 1, true) then
				local p = Player(player)
				if p then
					Family.syncFreeStone(p)
				end
			end
		end
		return originalProcessMessage(self, npc, player, message)
	end
	KeywordHandler.familyAdventurerStone = true
	return true
end

local report = GlobalEvent("FamilyAdventurerStoneReport")

function report.onStartup()
	if not installHook() then
		logger.warn("[Family] adventurer's stone: NPC library not found, upstream dialogue applies")
		return true
	end
	local count = 0
	for _ in pairs(freeStoneKeys) do
		count = count + 1
	end
	logger.info("[Family] adventurer's stone: \"adventurer's stone\" understood, first stone of the day free: {} ({} NPC storages)", tostring(Family.dailyFreeAdventurerStone), count)
	return true
end

report:register()
