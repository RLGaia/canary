-- Gaia Family server: self-test template (2026-10-21). Copy it to a scratch
-- folder, fill in run(), then:  tools/family/selftest.sh my_test.lua
-- The runner copies it to data/scripts/zz_selftest.lua and deletes it again;
-- never commit that file.
--
-- Tips (learned the hard way):
-- * Fake players: plain tables with only the methods the code calls
--   (getStorageValue, setStorageValue, getItemCount, addItem, ...). Lua-side
--   Player helpers can be reached with setmetatable(mock, { __index = Player }).
--   Code that calls Player(id) can be fooled by replacing the global Player for
--   the length of the test (restore it before DONE).
-- * A script's local handlers (Action, MoveEvent, EventCallback, NPC
--   callbacks) can be captured by loading the file again with loadfile +
--   setfenv and a stub Action/MoveEvent/... that keeps self.onUse etc.
-- * NPCs: load the npc file with stubs for Game.createNpcType, NpcHandler and
--   FocusModule; use the real KeywordHandler to test keyword trees.
-- * logger uses {} placeholders: remove braces from logged text (log() below).
-- * Game.getOfflinePlayer("Knight Sample") gives a real offline player (no
--   money changes; may crash the server while stopping: harmless here).

local passed, failed = 0, 0

local function log(fmt, ...)
	logger.info((("[Selftest] " .. string.format(fmt, ...)):gsub("[{}]", "")))
end

local function check(name, ok, detail)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
	end
	log("%s %s%s", ok and "ok  " or "FAIL", name, detail and (" - " .. tostring(detail)) or "")
end

local function run()
	-- Example:
	-- check("Jamjam is registered", Game.getAchievementInfoByName("Jamjam") ~= nil)
	check("server is running", Game.getPlayerCount() >= 0)
end

local event = GlobalEvent("ZzSelftest")

function event.onStartup()
	addEvent(function()
		local ok, err = pcall(run)
		if not ok then
			check("run() without errors", false, err)
		end
		log("%d passed, %d failed", passed, failed)
		log("DONE")
	end, 2000)
	return true
end

event:register()
