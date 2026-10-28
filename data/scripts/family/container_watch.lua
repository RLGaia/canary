-- Gaia Family server: container watch, a diagnostic (2026-10-28). Ours, not upstream.
--
-- Why: sometimes, at login, the main backpack window shows "Missing Container"
-- and Manage Containers is back to the default (reported for the father's
-- knight). Both live on the backpack items and are saved with them:
--   - the main backpack is marked "open in window N" at every save, and the
--     server reopens it at login; when the mark is missing, the client keeps
--     its restored window empty ("Missing Container");
--   - every bag chosen in Manage Containers carries its own loot/obtain flags.
-- In the C++ (v3.6.1) one routine clears both at once: when the main backpack
-- is treated as having left the character (Player::checkLootContainers plus
-- closing its window). What triggers it here is not known yet.
--
-- What it does: nothing in the game. It only writes lines to
-- family/container_watch.log (repository folder, next to config.lua):
--   - at login: is the main backpack marked open, which bags are managed; a
--     WARN line when the mark is missing (the "Missing Container" case);
--   - at logout: the same, plus whether the window is open right now;
--   - during play (checked about once a second): any change of the managed
--     bags or of the main backpack window, with position, fight state, client
--     connected or not, and the last moves and events before it;
--   - every move of the main backpack itself, deaths, and the client going
--     away or coming back (closing the client with X keeps the character in
--     game while the battle icon lasts).
--
-- Switch: Family.containerWatch (false = off). Remove it once the cause is found.

Family = Family or {}
Family.containerWatch = true

local LOG_FILE = "family/container_watch.log"
local RECENT_MAX = 8
local INVENTORY_X = 0xFFFF

local state = {} -- by player guid

local function writeLine(player, text)
	local line = string.format("%s [%s] %s", os.date("%Y-%m-%d %H:%M:%S"), player and player:getName() or "-", text)
	local file = io.open(LOG_FILE, "a")
	if file then
		file:write(line, "\n")
		file:close()
	end
	if text:find("WARN", 1, true) or text:find("LOST", 1, true) then
		logger.warn(("[Family] container watch: " .. line):gsub("[{}]", ""))
	end
end

local function posText(pos)
	if not pos then
		return "?"
	end
	if pos.x == INVENTORY_X then
		if pos.y < 64 then
			return "slot " .. pos.y
		end
		return "container " .. (pos.y - 64) .. " slot " .. pos.z
	end
	return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

local function flagsOf(item, attribute)
	if item:hasAttribute(attribute) then
		return item:getAttribute(attribute) or 0
	end
	return 0
end

-- Main backpack state: open window, save mark, managed bags.
local function snapshot(player)
	local bp = player:getSlotItem(CONST_SLOT_BACKPACK)
	if not bp or not bp:isContainer() then
		return { exists = false, managed = "", managedCount = 0, window = -1, mark = 0, text = "no main backpack" }
	end

	local bags = { bp }
	for _, item in ipairs(bp:getItems(true)) do
		if item:isContainer() then
			bags[#bags + 1] = item
		end
	end

	local managed = {}
	for index, bag in ipairs(bags) do
		local loot = flagsOf(bag, ITEM_ATTRIBUTE_QUICKLOOTCONTAINER)
		local obtain = flagsOf(bag, ITEM_ATTRIBUTE_OBTAINCONTAINER)
		if loot ~= 0 or obtain ~= 0 then
			managed[#managed + 1] = string.format("%s%s(loot=%d obtain=%d)", index == 1 and "MAIN " or "", bag:getName(), loot, obtain)
		end
	end

	local window = player:getContainerId(bp) or -1
	local mark = flagsOf(bp, ITEM_ATTRIBUTE_OPENCONTAINER)
	local managedText = table.concat(managed, ", ")
	return {
		exists = true,
		managed = managedText,
		managedCount = #managed,
		window = window,
		mark = mark,
		text = string.format("main %s (id %d, %d items) window=%s saveMark=%d managed=[%s]", bp:getName(), bp:getId(), bp:getItemHoldingCount(), window >= 0 and tostring(window) or "closed", mark, managedText),
	}
end

Family.containerWatchSnapshot = snapshot -- for the self-test

local function context(player)
	local pos = player:getPosition()
	local tile = Tile(pos)
	return string.format("pos=%s pz=%s fight=%s client=%s", posText(pos), tostring(tile and tile:hasFlag(TILESTATE_PROTECTIONZONE) or false), tostring(player:getCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT) ~= nil), tostring(player:getIp() ~= 0))
end

local function remember(player, text)
	local s = state[player:getGuid()]
	if not s then
		return
	end
	s.recent[#s.recent + 1] = os.date("%H:%M:%S") .. " " .. text
	if #s.recent > RECENT_MAX then
		table.remove(s.recent, 1)
	end
end

local function recentText(s)
	if #s.recent == 0 then
		return "none"
	end
	return table.concat(s.recent, " | ")
end

function Family.containerWatchCheck(player)
	if not Family.containerWatch then
		return
	end
	local s = state[player:getGuid()]
	if not s then
		return
	end

	local now = snapshot(player)
	local connected = player:getIp() ~= 0
	if connected ~= s.connected then
		writeLine(player, string.format("client %s; %s", connected and "connected again" or "gone (character still in game)", now.text))
		remember(player, connected and "client back" or "client gone")
		s.connected = connected
	end

	local last = s.last
	if now.managed ~= last.managed then
		local lost = now.managedCount < last.managedCount
		writeLine(player, string.format("%s managed bags: [%s] -> [%s]; %s; recent: %s", lost and "LOST" or "changed", last.managed, now.managed, context(player), recentText(s)))
	end
	if (now.window >= 0) ~= (last.window >= 0) or now.exists ~= last.exists then
		writeLine(player, string.format("main backpack window %s -> %s; %s; recent: %s", last.window >= 0 and tostring(last.window) or "closed", now.window >= 0 and tostring(now.window) or "closed", context(player), recentText(s)))
	end
	s.last = now
end

local login = CreatureEvent("FamilyContainerWatchLogin")

function login.onLogin(player)
	if not Family.containerWatch then
		return true
	end
	local now = snapshot(player)
	state[player:getGuid()] = { last = now, recent = {}, connected = player:getIp() ~= 0 }
	writeLine(player, string.format("login (%s); %s; %s", player:getVocation():getName(), now.text, context(player)))
	if now.exists and now.mark == 0 then
		writeLine(player, "WARN main backpack not marked open in the save: the client shows Missing Container")
	end
	if now.exists and now.managedCount == 0 then
		writeLine(player, "WARN no managed bags at login (Manage Containers at default)")
	end
	player:registerEvent("FamilyContainerWatchDeath")
	return true
end

login:register()

local logout = CreatureEvent("FamilyContainerWatchLogout")

function logout.onLogout(player)
	if Family.containerWatch then
		Family.containerWatchCheck(player)
		local s = state[player:getGuid()]
		-- The state stays: a refused logout keeps watching (login replaces it).
		writeLine(player, string.format("logout; %s; %s; recent: %s", snapshot(player).text, context(player), s and recentText(s) or "none"))
	end
	return true
end

logout:register()

local death = CreatureEvent("FamilyContainerWatchDeath")

function death.onDeath(player, corpse, killer)
	if Family.containerWatch and player:isPlayer() then
		remember(player, "died at " .. posText(player:getPosition()))
		writeLine(player, string.format("died; %s; %s", snapshot(player).text, context(player)))
	end
	return true
end

death:register()

local think = EventCallback("FamilyContainerWatchThink")

function think.playerOnThink(player, interval)
	Family.containerWatchCheck(player)
end

think:register()

local moved = EventCallback("FamilyContainerWatchMoved")

function moved.playerOnItemMoved(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if not Family.containerWatch or not item then
		return
	end
	local text = string.format("moved %s from %s to %s", item:getName(), posText(fromPosition), posText(toPosition))
	remember(player, text)
	local fromMain = fromPosition and fromPosition.x == INVENTORY_X and fromPosition.y == CONST_SLOT_BACKPACK
	local toMain = toPosition and toPosition.x == INVENTORY_X and toPosition.y == CONST_SLOT_BACKPACK
	if item:isContainer() and (fromMain or toMain) then
		writeLine(player, string.format("main backpack slot: %s; %s", text, context(player)))
	end
end

moved:register()

local report = GlobalEvent("FamilyContainerWatchReport")

function report.onStartup()
	logger.info("[Family] container watch (diagnostic) {}: writes {}", Family.containerWatch and "on" or "off", LOG_FILE)
	return true
end

report:register()
