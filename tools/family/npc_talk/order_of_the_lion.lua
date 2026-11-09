-- Gaia Family server: The Order of the Lion Quest check (2026-11-09): one character plays the quest with
-- Evrard, the five residents (YSELDA), the Bounac Guard, Kesar the Younger (every step, day and night,
-- the Falcon/Cobra check), the trade rule of the Bounac merchants and Augustin, Fitzmaurice and
-- Fitzgerald (Malefitz), the quest log texts, every {highlighted} word and every NPC line of the
-- TibiaWiki BR page (give it the page as text). Run from the repository root:
--   luajit tools/family/npc_talk/order_of_the_lion.lua [br.txt]

local T = dofile("tools/family/npc_talk/npc_talk.lua")

Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
MESSAGE_EVENT_ADVANCE = MESSAGE_EVENT_ADVANCE or 19
MESSAGE_STATUS = MESSAGE_STATUS or 17
CONST_ME_POFF, CONST_ME_TELEPORT = 3, 11
CALLBACK_ON_TRADE_REQUEST = CALLBACK_ON_TRADE_REQUEST or 20

dofile("data-otservbr-global/lib/others/family_order_of_the_lion.lua")
local L = FamilyLion
local Q = Storage.Quest.U12_40.TheOrderOfTheLion
local night = false
getTibiaTimerDayOrNight = function() return night and "night" or "day" end
L.letIn = function(p) p.letIn = true end
L.startMeeting = function(p) p.meeting = true end

local function player(o)
	local p = T.player(o)
	p.achievements, p.titles = {}, {}
	rawset(p, "addAchievement", function(self, name) self.achievements[name] = true return true end)
	rawset(p, "addTitle", function(self, id) self.titles[id] = true return true end)
	rawset(p, "teleportTo", function(self, pos) self.teleported = pos end)
	-- player KV (the harness keeps its own store in a field named kv)
	local data = {}
	rawset(p, "kv", function()
		local scope
		scope = {
			get = function(_, k) return data[k] end,
			set = function(_, k, v) data[k] = v end,
			remove = function(_, k) data[k] = nil end,
			scoped = function() return scope end,
		}
		return scope
	end)
	return p
end
local function has(text, part)
	return text:find(part, 1, true) ~= nil
end
local function state(p)
	return L.state(p)
end

local evrard = T.load("data-otservbr-global/npc/evrard_the_miller.lua")
local fral = T.load("data-otservbr-global/npc/fral_the_butcher.lua")
local dal = T.load("data-otservbr-global/npc/dal_the_huntress.lua")
local jehan = T.load("data-otservbr-global/npc/jehan_the_baker.lua")
local onfroi = T.load("data-otservbr-global/npc/onfroi.lua")
local wes = T.load("data-otservbr-global/npc/wes_the_blacksmith.lua")
local guard = T.load("data-otservbr-global/npc/bounac_guard.lua")
local kesar = T.load("data-otservbr-global/npc/kesar_the_younger.lua")
local fitzmaurice = T.load("data-otservbr-global/npc/fitzmaurice.lua")
local fitzgerald = T.load("data-otservbr-global/npc/fitzgerald.lua")
local augustin = T.load("data-otservbr-global/npc/augustin.lua")

local p = player({ level = 300 })

-- Evrard the Miller ---------------------------------------------------------------
T.check("Evrard greets a stranger (BR)", has(evrard:say(p, "hi"), "Greetings. Can I help you, traveller?"))
local a = evrard:say(p, "yes")
T.check("Evrard: the ledger and the map, BE QUIET", has(a, "They have a ledger and a map there") and has(a, "Got that?"))
a = evrard:say(p, "yes")
T.check("Evrard: summer breeze, state 1, east door", has(a, "light summer breeze") and state(p) == 1 and p.storage[Q.AccessEastSide] == 1)
evrard:bye(p)
T.check("Evrard: second greeting asks for news", has(evrard:say(p, "hi"), "any {news}?"))
T.check("Evrard: news asks for the stuff", has(evrard:say(p, "news"), "Did you get the stuff?"))
T.check("Evrard: without both items", has(evrard:say(p, "yes"), "AND the map"))
L.set(p, "ledger", 1)
evrard:say(p, "news")
T.check("Evrard: still without the map", has(evrard:say(p, "yes"), "AND the map") and state(p) == 1)
L.set(p, "map", 1)
evrard:say(p, "news")
a = evrard:say(p, "yes")
T.check("Evrard: keep them, quiet?", has(a, "keep them") and has(a, "Have you been quiet as I asked you?"))
a = evrard:say(p, "yes")
T.check("Evrard: YSELDA, state 2, south door", has(a, "There's a passphrase: YSELDA") and has(a, "screams of battle, fear and loathing") and state(p) == 2 and p.storage[Q.AccessSouthernSide] == 1)
T.check("Evrard: news afterwards", has(evrard:say(p, "news"), "YSELDA"))
evrard:bye(p)

-- the five residents ------------------------------------------------------------------
local q = player({ level = 300, storage = { [Q.QuestLine] = 1 } })
fral:say(q, "hi")
T.check("Yselda before Evrard's passphrase", has(fral:say(q, "yselda"), "don't know what you are talking about"))
fral:bye(q)

T.check("Fral greets (BR)", has(fral:say(p, "hi"), "Hello, customer! I got meat."))
a = fral:say(p, "Yselda")
T.check("Fral: the intro (BR)", has(a, "Oh, yes uhm. You came to the right place, I guess.") and has(a, "Just ask any of us the passphrase"))
T.check("Fral: 20 hams (BR)", has(fral:say(p, "yselda"), "about 20 chunks if you can"))
T.check("Fral: no hams yet", has(fral:say(p, "yselda"), "can't smell"))
p.items[L.items.ham] = 20
a = fral:say(p, "yselda")
T.check("Fral: smells the ham, hand over?", has(a, "I can smell about 20 pieces of raw ham") and has(a, "Will you hand those over to me?"))
T.check("Fral: no keeps the ham", has(fral:say(p, "no"), "made up your mind") and p.items[L.items.ham] == 20)
fral:say(p, "yselda")
a = fral:say(p, "yes")
T.check("Fral: trust earned, 20 hams taken", has(a, "Consider my trust... earned.") and p.items[L.items.ham] == 0 and L.get(p, "task_fral") == 2)
T.check("Fral: trust again", has(fral:say(p, "yselda"), "already have my trust"))
fral:bye(p)

T.check("Dal greets (BR)", has(dal:say(p, "hi"), "I am out of stock currently"))
a = dal:say(p, "yselda")
T.check("Dal: 20 deer (BR)", has(a, "Hunt 20 deer for me") and not has(a, "right place"))
T.check("Dal: count so far", has(dal:say(p, "yselda"), "0 of the 20 deer"))
L.set(p, "deer", 20)
T.check("Dal: trust (BR)", has(dal:say(p, "yselda"), "Impressive, for a semi-professional!") and L.get(p, "task_dal") == 2)
dal:bye(p)

T.check("Jehan greets by day (EN)", has(jehan:say(p, "hi"), "we're all out of bread"))
jehan:bye(p)
night = true
T.check("Jehan greets at night (BR)", has(jehan:say(p, "hi"), "it's already closing time. This is my home!"))
night = false
T.check("Jehan: ten loafs (BR)", has(jehan:say(p, "yselda"), "organise about ten loafs of bread"))
p.items[L.items.bread] = 9
T.check("Jehan: nine are not enough", has(jehan:say(p, "yselda"), "Ten loafs of bread, that's all"))
p.items[L.items.bread] = 12
T.check("Jehan: hand over? (BR)", has(jehan:say(p, "yselda"), "Colour me impressed. Will you hand those over to me?"))
T.check("Jehan: trust (BR)", has(jehan:say(p, "yes"), "most certainly earned my trust") and p.items[L.items.bread] == 2)
jehan:bye(p)

T.check("Onfroi greets (BR)", has(onfroi:say(p, "hi"), "Is it tea you're looking"))
a = onfroi:say(p, "yselda")
T.check("Onfroi: the crypt (BR)", has(a, "There is a crypt down below the town. It is old") and has(a, "I'd be in your debt."))
L.set(p, "crypt", 19)
T.check("Onfroi: 19 are not enough", has(onfroi:say(p, "yselda"), "19 of the 20"))
L.set(p, "crypt", 20)
T.check("Onfroi: trust (BR)", has(onfroi:say(p, "yselda"), "That took a load of my mind. And you've earned my trust!"))
onfroi:bye(p)

T.check("Wes greets (BR)", has(wes:say(p, "hi"), "Welcome to Wes and son, blacksmith (and teacher)."))
T.check("Wes: 20 broken longbows (BR)", has(wes:say(p, "yselda"), "Bring me about 20 broken longbows from fallen usurpers"))
p.items[L.items.longbow] = 20
a = wes:say(p, "yselda")
T.check("Wes: hand over? (BR)", has(a, "this is exactly what I need to fulfill my next order from the king") and has(a, "Are you willing to hand them over to me?"))
T.check("Wes: trust, state 3", has(wes:say(p, "yes"), "You have earned my trust, traveller. Good luck!") and state(p) == 3 and p.items[L.items.longbow] == 0)
wes:bye(p)

-- quest log ------------------------------------------------------------------------
local log = L.describe(p)
T.check("quest log: BR text and counters", has(log, "To help break the siege you need to earn the trust of the locals and reach their ruler Kesar.") and has(log, "Miller 1/1") and has(log, "Huntress 1/1") and has(log, "Butcher 1/1"))
local r = player({ storage = { [Q.QuestLine] = 2 } })
L.set(r, "task_wes", 2)
log = L.describe(r)
T.check("quest log: partly trusted", has(log, "Blacksmith 1/1") and has(log, "Baker 0/1"))
for s = 1, 12 do
	local x = player({ storage = { [Q.QuestLine] = s } })
	T.check("quest log text for state " .. s, L.describe(x) ~= "")
end

-- Bounac Guard ---------------------------------------------------------------------
local g = player({ storage = { [Q.QuestLine] = 2 } })
T.check("Guard greets (BR)", has(guard:say(g, "hi"), "YOU CANNOT PASS, TRAVELLER. THE CASTLE OF BOUNAC IS UNDER SIEGE."))
T.check("Guard: pass (BR)", has(guard:say(g, "pass"), "YOU WANT PASSAGE, TRAVELLER?"))
T.check("Guard: not trusted yet", has(guard:say(g, "yes"), "NOBODY PASSES") and not rawget(g, "letIn"))
guard:bye(g)
guard:say(p, "hi")
guard:say(p, "pass")
a = guard:say(p, "yes")
T.check("Guard: lets the trusted in (BR), state 4", has(a, "LOWER YOUR VOICE STRANGER, I'M NOT DEAF!") and has(a, "You can enter the castle. Good luck!") and state(p) == 4 and rawget(p, "letIn") == true)

-- Kesar the Younger ---------------------------------------------------------------
night = true
kesar:say(p, "hi")
T.check("Kesar at night", has(kesar:say(p, "siege"), "It is late") and state(p) == 4)
kesar:bye(p)
night = false
T.check("Kesar greets (BR)", has(kesar:say(p, "hi"), "Hail, traveller. What brings you here during these dire times under siege?"))
a = kesar:say(p, "siege")
T.check("Kesar: take a seat (BR), state 5", has(a, "You will have to wait until I have time") and has(a, "somehow I doubt you will, either.") and state(p) == 5)
T.check("Kesar: asking too early starts the wait again (EN)", has(kesar:say(p, "siege"), "take a seat") and L.get(p, "kesarWait") > os.time() + 500)
L.set(p, "kesarWait", os.time() - 1)
a = kesar:say(p, "siege")
T.check("Kesar: interested in a plan? (BR)", has(a, "Sources are telling me that you helped our small community") and has(a, "are you interested in a plan?"))
a = kesar:say(p, "yes")
T.check("Kesar: the plan (BR), state 6, one Tibian day", has(a, "Either Fugue, Drume or both will appear here soon.") and has(a, "we shall not think of that now.") and state(p) == 6 and L.get(p, "fugueAfter") >= os.time() + 3500)
T.check("Kesar: waiting for Fugue", has(kesar:say(p, "siege"), "Be patient"))
L.setState(p, 7) -- Fugue defeated (scripts/family/order_of_the_lion.lua)
a = kesar:say(p, "siege")
T.check("Kesar: other orders first (EN)", has(a, "find out what you can about the order of the Falcon") and state(p) == 7)
p.storage[Storage.Quest.U11_80.TheSecretLibrary.FalconBastion.Questline] = 3
T.check("Kesar: Falcon alone is not enough", has(kesar:say(p, "siege"), "order of the Falcon"))
p.storage[Storage.Quest.U12_20.GraveDanger.Cobra] = 2
a = kesar:say(p, "siege")
T.check("Kesar: Fugue punished, escort? (BR)", has(a, "Fugue... he attacked right away and had to be punished.") and has(a, "Will you escort me to the camp of the usurpers?"))
a = kesar:say(p, "yes")
T.check("Kesar: skirmishes (BR), state 8", has(a, "we have to wait until the recent skirmishes along the coast have settled down.") and state(p) == 8)
T.check("Kesar: escort again (BR)", has(kesar:say(p, "siege"), "Will you escort me to the camp of the usurpers?"))
T.check("Kesar: still too early", has(kesar:say(p, "yes"), "skirmishes") and not rawget(p, "meeting"))
L.set(p, "escortAfter", os.time() - 1)
kesar:say(p, "siege")
T.check("Kesar: let us go (BR), the meeting starts", has(kesar:say(p, "yes"), "Alright, let us go then. And thank you.") and rawget(p, "meeting") == true)
kesar:say(p, "hi")
L.setState(p, 9) -- the meeting watched
a = kesar:say(p, "siege")
T.check("Kesar: the battlefield (BR), state 10", has(a, "What news from the orders of the Falcon") and has(a, "We will meet him in battle near the eastern coast of Bounac.") and state(p) == 10)
T.check("Kesar: before Drume", has(kesar:say(p, "siege"), "Drume awaits us"))
L.setState(p, 11) -- Drume defeated
a = kesar:say(p, "siege")
T.check("Kesar: Hero of Bounac (BR)", has(a, "I will therefore announce you the 'Hero of Bounac'.") and has(a, "Thank you for your service to Bounac, Hero."))
T.check("Hero: state 12, storage, Lionheart, title 89", state(p) == 12 and p.storage[L.heroStorage] == 1 and p.achievements["Lionheart"] and p.titles[89])
T.check("Kesar afterwards", has(kesar:say(p, "siege"), "Hero"))
kesar:bye(p)

-- trade ----------------------------------------------------------------------------------
for _, n in ipairs({ fral, dal, jehan, onfroi, wes, augustin }) do
	local s = player({ level = 300 })
	n:say(s, "hi")
	local refused = n:say(s, "trade")
	T.check(n.npc.name .. " does not trade with strangers", has(refused, "only trade with the citizens of Bounac") and not rawget(s, "shopOpened"))
	n:bye(s)
	local h = player({ level = 300, storage = { [L.heroStorage] = 1 } })
	n:say(h, "hi")
	n:say(h, "trade")
	T.check(n.npc.name .. " trades with the Hero of Bounac", rawget(h, "shopOpened") == true)
	n:bye(h)
end

-- Malefitz ------------------------------------------------------------------------------
local f = player({ level = 300 })
T.check("Fitzmaurice greets (BR)", has(fitzmaurice:say(f, "hi"), "Oh, hello there!"))
a = fitzmaurice:say(f, "wine")
T.check("Fitzmaurice: watered wine (BR)", has(a, "they seem to stretch it with water") and has(a, "Fitzwilliam, is a keen gourmet of wine"))
fitzmaurice:bye(f)
fitzgerald:say(f, "hi")
fitzgerald:say(f, "wine")
T.check("Fitzgerald gives the bottle", (f.items[L.items.wine] or 0) == 1)
T.check("Fitzgerald: only one bottle", not has(fitzgerald:say(f, "wine"), "Here, take") and f.items[L.items.wine] == 1)
fitzgerald:bye(f)
fitzmaurice:say(f, "hi")
a = fitzmaurice:say(f, "wine")
T.check("Fitzmaurice: that's WINE (BR), Malefitz", has(a, "Now that's what I call WINE, thank you very much!") and f.items[L.items.wine] == 0 and f.achievements["Malefitz"])
local g2 = player({})
fitzgerald:say(g2, "hi")
fitzgerald:say(g2, "wine")
T.check("Fitzgerald: no bottle without Fitzmaurice", (g2.items[L.items.wine] or 0) == 0)

-- switch off ------------------------------------------------------------------------------
Family.orderOfTheLion = false
local o = player({})
evrard:say(o, "hi")
T.check("switch off: Evrard says nothing about the errand", evrard:say(o, "yes") == "" and state(o) == 0)
local o2 = player({})
fral:say(o2, "hi")
fral:say(o2, "trade")
T.check("switch off: Fral trades with anyone", rawget(o2, "shopOpened") == true)
Family.orderOfTheLion = true

-- {highlighted} words ---------------------------------------------------------------------
for _, n in ipairs({ evrard, fral, dal, jehan, onfroi, wes, guard, kesar, fitzmaurice, fitzgerald }) do
	T.checkHints(n, function() return player({ level = 300, storage = { [Q.QuestLine] = 1 } }) end)
end

-- every NPC line of the TibiaWiki BR page ------------------------------------------------
local brFile = arg and arg[1]
if brFile then
	local fh = io.open(brFile)
	local br = fh:read("*a")
	fh:close()
	local srcFh = io.open("data-otservbr-global/lib/others/family_order_of_the_lion.lua")
	local src = srcFh:read("*a")
	srcFh:close()
	local function norm(s)
		return (s:gsub("[{}]", ""):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", ""))
	end
	local nsrc = norm(src)
	-- lines kept different on purpose (with the reason)
	local differ = {
		["Wes The Blacksmith: Hail, customer! Welcome to Wes and son, blacksmith (and teacher). Can I do something for you?"] = true, -- his greeting, checked above
		["Jehan The Baker: Welcome to the Bread & Butter! Do you... hey, it's already closing time. This is my home!"] = true, -- night greeting, checked above
		["Jehan The Baker: Welcome to the Bread & Butter! Do you want to buy pastries or butter? Because we're all out of bread."] = true,
	}
	local n, missing = 0, 0
	for name, text in br:gmatch("\n(%u[%a ]-): ([^\n]+)") do
		if name ~= "Jogador" and name ~= "Obs" and name ~= "Task" and name ~= "Recompensa" and #text > 12 then
			local line = name .. ": " .. text
			n = n + 1
			local body = norm(text):gsub(" %.%.%.$", "")
			if not differ[line] and not nsrc:find(body, 1, true) then
				missing = missing + 1
				T.check("BR line: " .. line:sub(1, 90), false)
			end
		end
	end
	T.check(string.format("BR NPC lines found (%d lines, %d missing)", n, missing), n > 40 and missing == 0)
end

T.finish()
