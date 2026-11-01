-- Gaia Family server: talk to an NPC without a server (2026-11-01).
--
-- Loads one NPC file with the REAL NPC library (data/npclib), our keyword
-- rules (data/scripts/family/npc_keywords.lua) and the storages, and lets a
-- test talk to it as a fake player. Only the engine is faked (Npc, Player,
-- addEvent): the dialogue code is the one the server runs.
--
-- Use from a scenario file run with LuaJIT from the repository root:
--
--   local T = dofile("tools/family/npc_talk/npc_talk.lua")
--   local npc = T.load("data-otservbr-global/npc/woblin.lua")
--   local p = T.player({ level = 10, storage = { [Storage...TheDormKey] = 1 }, items = { [21402] = 1 } })
--   npc:say(p, "hi")                     -- returns everything the NPC answered (one string)
--   T.check("key opens the step", npc:say(p, "key"):find("reward"))
--   T.checkHints(npc, T.player({}))       -- every {word} the NPC highlights gets an answer
--   T.finish()                            -- prints the totals, exits 1 on a failure
--
-- Fake player: storage, items (id = count), money, level, vocation, sex,
-- town; unknown methods are logged once ("missing method") and return nil, so
-- a test shows what an NPC needs. p.log holds messages sent to the player,
-- p.added / p.removed the items, p.shopOpened the trade window.

local T = { passed = 0, failed = 0 }

-- ---------------------------------------------------------------- engine stubs
local clock = 0
local events, nextEvent = {}, 0
function addEvent(fn, delay, ...)
	nextEvent = nextEvent + 1
	events[nextEvent] = { fn = fn, at = clock + (delay or 0), args = { ... } }
	return nextEvent
end
function stopEvent(id)
	if id then
		events[id] = nil
	end
end
local function runEvents()
	for _ = 1, 50 do
		local due
		for id, e in pairs(events) do
			if not due or e.at < events[due].at or (e.at == events[due].at and id < due) then
				due = id
			end
		end
		if not due then
			return
		end
		local e = events[due]
		events[due] = nil
		clock = math.max(clock, e.at)
		e.fn(unpack(e.args))
	end
end

logger = {
	info = function() end,
	debug = function() end,
	warn = function(fmt, ...) print("[warn] " .. tostring(fmt)) end,
	error = function(fmt, ...) print("[error] " .. tostring(fmt)) end,
}
configManager = { getNumber = function() return 0 end, getBoolean = function() return false end, getString = function() return "" end }
configKeys = setmetatable({}, { __index = function(_, k) return k end })
CORE_DIRECTORY = "data"
DATA_DIRECTORY = "data-otservbr-global"
TALKTYPE_SAY, TALKTYPE_PRIVATE_NP, TALKTYPE_PRIVATE_PN = 1, 5, 6
MESSAGE_EVENT_ADVANCE, MESSAGE_INFO_DESCR, MESSAGE_LOOK, MESSAGE_FAILURE = 1, 2, 3, 4
CONST_ME_TELEPORT, CONST_ME_POFF, CONST_ME_MAGIC_BLUE, CONST_ME_HOLYAREA = 1, 2, 3, 4
TAG_TIME, TAG_BLESSCOST, TAG_PVPBLESSCOST = "|TIME|", "|BLESSCOST|", "|PVPBLESSCOST|"
SKILL_FIST, SKILL_CLUB, SKILL_SWORD, SKILL_AXE, SKILL_DISTANCE, SKILL_SHIELD, SKILL_FISHING, SKILL_MAGLEVEL, SKILL_LEVEL = 0, 1, 2, 3, 4, 5, 6, 7, 8
getFormattedWorldTime = function() return "12:00" end
IsTravelFree = function() return false end -- data/global.lua reads the config
getTibiaTimerDayOrNight = function() return "day" end
Blessings = { getBlessingCost = function() return 0 end, getPvpBlessingCost = function() return 0 end }
table.contains = table.contains or function(t, v)
	for _, x in pairs(t) do
		if x == v then
			return true
		end
	end
	return false
end
string.split = string.split or function(s, sep)
	local out = {}
	for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do
		out[#out + 1] = part
	end
	return out
end
string.trim = string.trim or function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
GlobalEvent = function()
	local o = {}
	function o:register() T.startups[#T.startups + 1] = self end
	return o
end
T.startups = {}

local items = {}
getItemName = function(id) return items[id] or ("item " .. tostring(id)) end
ItemType = function(id)
	return setmetatable({ id = id }, { __index = function(_, k)
		if k == "getId" then return function() return id end end
		if k == "getName" then return function() return items[id] or ("item " .. id) end end
		if k == "getArticle" then return function() return "a" end end
		if k == "getPluralName" then return function() return (items[id] or "item") .. "s" end end
		return function() return 0 end
	end })
end

-- players by id
local playersById = {}
-- Player(x) finds a fake player; Player.method(p, ...) calls p:method(...) (some scripts use that form).
Player = setmetatable({}, {
	__call = function(_, x)
		if type(x) == "table" then
			return x
		end
		return playersById[x]
	end,
	__index = function(_, k)
		return function(p, ...) return p[k](p, ...) end
	end,
})
Creature = Player

-- -------------------------------------------------------------------- fake NPC
local npcsById, npcType = {}, nil
-- Npc is a class (npc.lua adds methods such as Npc:talk) and a constructor.
Npc = setmetatable({}, { __call = function(_, x)
	if type(x) == "table" then
		return x
	end
	return npcsById[x]
end })
Town = setmetatable({}, { __call = function(_, id)
	return { getId = function() return id end, getName = function() return "Town " .. tostring(id) end, getTemplePosition = function() return { x = 0, y = 0, z = 7 } end }
end })
Game = Game or {}
Game.createNpcType = function(name)
	npcType = setmetatable({ name = name }, { __index = function() return function() end end })
	npcType.register = function(self, cfg) self.config = cfg end
	return npcType
end
Game.getStorageValue = function() return -1 end
Game.setStorageValue = function() end
Game.getPlayers = function() return {} end

local nextNpc = 0x80000000
local function newNpc(name, config)
	nextNpc = nextNpc + 1
	local npc = setmetatable({ name = name, said = {}, interacting = {}, config = config, id = nextNpc, uid = nextNpc }, { __index = Npc })
	npcsById[npc.id] = npc
	function npc:getName() return self.name end
	function npc:getId() return self.id end
	function npc:getPosition() return { x = 0, y = 0, z = 7 } end
	function npc:isInteractingWithPlayer(p) return self.interacting[p:getId()] == true end
	function npc:setPlayerInteraction(p) self.interacting[p:getId()] = true end
	function npc:removePlayerInteraction(p) self.interacting[p:getId()] = nil end
	function npc:isPlayerInteractingOnTopic() return false end
	function npc:turnToCreature() return true end
	function npc:isInTalkRange() return true end
	function npc:isMerchant() return self.config and self.config.shop ~= nil end
	function npc:openShopWindow(p) p.shopOpened = true end
	function npc:openShopWindowTable(p) p.shopOpened = true end
	function npc:closeShopWindow() end
	function npc:getSpeechBubble() return 0 end
	function npc:setSpeechBubble() end
	function npc:say(text) self.said[#self.said + 1] = text end
	return npc
end

-- ----------------------------------------------------------------- fake player
local nextPlayer = 0x10000000
local missing = {}
function T.player(o)
	o = o or {}
	nextPlayer = nextPlayer + 1
	local p = {
		id = nextPlayer,
		uid = nextPlayer,
		storage = o.storage or {},
		items = o.items or {},
		money = o.money or 0,
		bank = o.bank or 0,
		level = o.level or 8,
		vocation = o.vocation or 0,
		sex = o.sex or 1,
		town = o.town or 2,
		health = o.health or 150,
		maxHealth = o.maxHealth or 150,
		conditions = o.conditions or {},
		accountStorage = o.accountStorage or {},
		name = o.name or "Tester",
		log = {},
		added = {},
		removed = {},
		kv = {},
	}
	playersById[p.id] = p
	local m = {}
	function m:getId() return self.id end
	function m:getGuid() return self.id end
	function m:getName() return self.name end
	function m:getLevel() return self.level end
	function m:getSex() return self.sex end
	function m:getPosition() return { x = 0, y = 0, z = 7, sendMagicEffect = function() end } end
	function m:getStorageValue(k)
		assert(type(k) == "number", "storage key is a " .. type(k))
		return self.storage[k] or -1
	end
	function m:setStorageValue(k, v)
		assert(type(k) == "number", "storage key is a " .. type(k))
		self.storage[k] = v
	end
	function m:getItemCount(id) return self.items[id] or 0 end
	function m:removeItem(id, count)
		count = count or 1
		if (self.items[id] or 0) < count then
			return false
		end
		self.items[id] = self.items[id] - count
		self.removed[#self.removed + 1] = { id, count }
		return true
	end
	function m:addItem(id, count)
		count = count or 1
		self.items[id] = (self.items[id] or 0) + count
		self.added[#self.added + 1] = { id, count }
		local item = { id = id }
		function item:setActionId(aid) self.actionid = aid end
		function item:setAttribute() end
		function item:getId() return id end
		return item
	end
	function m:getHealth() return self.health end
	function m:getMaxHealth() return self.maxHealth end
	function m:addHealth(n) self.health = math.min(self.maxHealth, self.health + n) end
	function m:getCondition(t) return self.conditions[t] end
	function m:removeCondition(t) self.conditions[t] = nil end
	function m:getMana() return 0 end
	function m:getMaxMana() return 0 end
	function m:addMana() end
	function m:getAccountStorage(k) return self.accountStorage[k] or -1 end
	function m:changeVocation(v) self.vocation = v return true end
	function m:setVocation(v) self.vocation = v end
	function m:teleportTo(pos) self.teleported = pos end
	function m:setTown(t) self.town = t and t:getId() end
	function m:getSlotItem() return nil end
	function m:getMoney() return self.money end
	function m:getBankBalance() return self.bank end
	function m:removeMoney(n)
		if self.money < n then return false end
		self.money = self.money - n
		return true
	end
	function m:removeMoneyBank(n)
		if self.money + self.bank < n then return false end
		local fromHand = math.min(self.money, n)
		self.money = self.money - fromHand
		self.bank = self.bank - (n - fromHand)
		return true
	end
	function m:addMoney(n) self.money = self.money + n end
	function m:sendTextMessage(_, text) self.log[#self.log + 1] = text end
	function m:getVocation()
		local v = self.vocation
		return { getId = function() return v end, getBaseId = function() return v end, getName = function() return "vocation " .. v end }
	end
	function m:getTown()
		local t = self.town
		return { getId = function() return t end, getTemplePosition = function() return { x = 0, y = 0, z = 7 } end }
	end
	function m:isPremium() return true end
	function m:getGroup() return { getAccess = function() return false end } end
	function m:kv()
		local store = self.kv
		local scope
		scope = {
			get = function(_, k) return store[k] end,
			set = function(_, k, v) store[k] = v end,
			remove = function(_, k) store[k] = nil end,
			scoped = function() return scope end,
		}
		return scope
	end
	return setmetatable(p, { __index = function(_, k)
		if m[k] then
			return m[k]
		end
		if type(k) ~= "string" or not k:match("^[a-z]") or k:match("^[a-z]+$") and not k:match("^get") and not k:match("^set") and not k:match("^add") and not k:match("^remove") and not k:match("^is") and not k:match("^has") and not k:match("^send") and not k:match("^can") then
			return nil -- a field, not a method
		end
		if not missing[k] then
			missing[k] = true
			print("[npc_talk] missing player method: " .. tostring(k))
		end
		return function() return nil end
	end })
end

-- --------------------------------------------------------------- load library
local function loadLibrary()
	dofile("data-otservbr-global/lib/core/storages.lua")
	dofile("data-otservbr-global/lib/tables/town.lua")
	Vocation = Vocation or setmetatable({}, { __call = function(_, id)
		return setmetatable({ id = id }, { __index = function(_, k) return function() return 0 end end })
	end })
	dofile("data/libs/functions/vocation.lua")
	dofile("data/npclib/npc.lua")
	dofile("data/npclib/npc_system/npc_handler.lua")
	dofile("data/npclib/npc_system/keyword_handler.lua")
	dofile("data/npclib/npc_system/modules.lua")
	dofile("data/npclib/npc_system/custom_modules.lua")
	-- our NPC rules (installed on load and again at "startup")
	CONDITION_POISON, CONDITION_FIRE, CONDITION_ENERGY, CONDITION_BLEEDING = 3, 4, 5, 6
	CONDITION_FREEZING, CONDITION_DAZZLED, CONDITION_CURSED, CONDITION_DROWN = 7, 8, 9, 10
	CONST_ME_MAGIC_RED = 5
	dofile("data/scripts/family/npc_keywords.lua")
	dofile("data/scripts/family/temple_healing.lua")
	for _, s in ipairs(T.startups) do
		if s.onStartup then
			s.onStartup()
		end
	end
	-- items.xml names (for shop checks and messages)
	local f = io.open("data/items/items.xml")
	if f then
		for line in f:lines() do
			local id, name = line:match('<item id="(%d+)"[^>]-name="([^"]*)"')
			if id then
				items[tonumber(id)] = name
			end
		end
		f:close()
	end
end
loadLibrary()

-- ----------------------------------------------------------------- NPC object
local Talk = {}
Talk.__index = Talk

function T.load(path, globals)
	for k, v in pairs(globals or {}) do
		_G[k] = v
	end
	npcType = nil
	dofile(path)
	assert(npcType and npcType.config, "no npcType:register in " .. path)
	local self = setmetatable({ path = path, type = npcType }, Talk)
	self.npc = newNpc(npcType.config.name or npcType.name, npcType.config)
	return self
end

-- Says text to the NPC as player p; returns all the NPC's answers joined.
function Talk:say(p, text)
	local before = #self.npc.said
	local talkType = self.npc:isInteractingWithPlayer(p) and TALKTYPE_PRIVATE_PN or TALKTYPE_SAY
	local ok, err = pcall(self.type.onSay, self.npc, p, talkType, text)
	if ok then
		ok, err = pcall(runEvents)
	end
	if not ok then
		events = {}
		T.errors = (T.errors or 0) + 1
		self.npc.said[#self.npc.said + 1] = "LUA ERROR: " .. tostring(err)
		print("[npc_talk] Lua error in " .. self.npc.name .. " after '" .. text .. "': " .. tostring(err))
	end
	local out = {}
	for i = before + 1, #self.npc.said do
		out[#out + 1] = self.npc.said[i]
	end
	return table.concat(out, " | ")
end

-- Says hi, then each line; returns the answers per line.
function Talk:conversation(p, lines)
	local answers = {}
	for i, line in ipairs(lines) do
		answers[i] = self:say(p, line)
	end
	return answers
end

function Talk:bye(p)
	return self:say(p, "bye")
end

-- Every {word} the NPC can highlight, collected from the file's text.
function Talk:hintWords()
	local f = io.open(self.path)
	local src = f:read("*a")
	f:close()
	local words, seen = {}, {}
	-- only inside string literals: a {word} is letters, digits, spaces, ' - ! ? (no Lua tables)
	for w in src:gmatch("{([^{}\n]-)}") do
		local lw = w:lower()
		if not seen[lw] and w:match("^%a[%w '%-!%?]*$") and #lw < 40 then
			seen[lw] = true
			words[#words + 1] = w
		end
	end
	table.sort(words)
	return words
end

-- -------------------------------------------------------------------- checks
function T.check(name, ok, detail)
	if ok then
		T.passed = T.passed + 1
	else
		T.failed = T.failed + 1
	end
	print((ok and "ok   " or "FAIL ") .. name .. ((detail ~= nil and detail ~= "") and (" - " .. tostring(detail)) or ""))
	return ok
end

-- Every highlighted {word} gets some answer from a fresh player who greeted.
-- skip = words that only answer in a certain state (checked by the scenario).
function T.checkHints(talk, makePlayer, skip)
	skip = skip or {}
	for _, w in ipairs(talk:hintWords()) do
		if not skip[w:lower()] then
			local p = makePlayer()
			talk:say(p, "hi")
			local answer = talk:say(p, w)
			T.check(talk.npc.name .. ": {" .. w .. "} answers", (answer ~= "" and not answer:find("LUA ERROR", 1, true)) or rawget(p, "shopOpened"), answer:sub(1, 70))
			talk:bye(p)
		end
	end
end

function T.finish()
	if T.errors then
		T.check("no Lua errors in the NPC scripts", false, T.errors .. " errors")
	end
	print(string.format("%d passed, %d failed", T.passed, T.failed))
	os.exit(T.failed == 0 and 0 or 1)
end

return T
