-- Gaia Family server: Vampire Hunter Quest check (2026-11-20). One character gives Storkus the
-- tokens rank by rank, with the lines of the TibiaWiki EN spoiler transcripts and the TibiaWiki BR
-- page (refusal of the last rank, job). Run from the repository root:
--   luajit tools/family/npc_talk/vampire_hunter.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
dofile("data-otservbr-global/lib/others/family_vampire_hunter.lua")
local V = FamilyVampire
local Q = Storage.Quest.U8_2.TheInquisitionQuest
local VH = Storage.Quest.U8_2.VampireHunterQuest

local castlemaniaChecks = 0
FamilyBloodBrothers = { checkCastlemania = function() castlemaniaChecks = castlemaniaChecks + 1 end }

local function player(o)
	local p = T.player(o)
	p.achievements = {}
	p.xp = 0
	rawset(p, "addAchievement", function(self, name) self.achievements[#self.achievements + 1] = name return true end)
	rawset(p, "addExperience", function(self, n) self.xp = self.xp + n end)
	return p
end
local function has(text, s) return (text:gsub("[{}]", "")):find(s, 1, true) ~= nil end
local function given(p, id)
	local n = 0
	for _, a in ipairs(rawget(p, "added")) do
		if a[1] == id then n = n + a[2] end
	end
	return n
end

local storkus = T.load("data-otservbr-global/npc/storkus.lua")

-- Before The Inquisition Mission 3 is reported: no token talk
local p = player({})
p.storage[Q.Questline] = 10
local g = storkus:say(p, "hi")
T.check("greeting (both wikis)", g == "Greetings, Tester!", g)
T.check("job (BR)", has(storkus:say(p, "job"), "I used to be a carpenter, but that was ages ago. Now I am a vampire hunter."))
local t = storkus:say(p, "vampire lord token")
T.check("no tokens before Mission 3 is reported", t == "", t)
local b = storkus:say(p, "bye")
T.check("farewell (both wikis)", b == "Good bye, Tester!", b)

-- Mission 3 reported: the six ranks
p.storage[Q.Questline] = 11
storkus:say(p, "hi")
local expected = { 1000, 5000, 10000, 20000, 50000, 100000 }
local total = 0
for rank, r in ipairs(V.ranks) do
	p.items[V.TOKEN] = r.tokens - 1
	local a = storkus:say(p, "vampire lord token")
	T.check("rank " .. rank .. " question (both wikis)", a == "Would ye' like to give me vampire tokens?", a)
	local no = storkus:say(p, "yes")
	T.check("rank " .. rank .. " refused with " .. (r.tokens - 1) .. " tokens", has(no, "which ye' don't have right now") and p.items[V.TOKEN] == r.tokens - 1 and math.max(p.storage[VH.Rank] or -1, 0) == rank - 1, no)
	p.items[V.TOKEN] = r.tokens + 2
	storkus:say(p, "Vampire Lord Token")
	local yes = storkus:say(p, "yes")
	total = total + expected[rank]
	T.check("rank " .. rank .. " " .. r.name .. " (EN transcript)", yes == r.line and p.storage[VH.Rank] == rank and p.items[V.TOKEN] == 2 and p.xp == total, yes .. " xp " .. p.xp)
	p.items[V.TOKEN] = 0
end
T.check("last refusal is BR's line", V.refusal(6) == "To promote ye' to the sixth and last vampire hunter rank I need fifty tokens from ye' - which ye' don't have right now. Please bring them all at once, it's a hassle to keep track of how many ye' brought and so on.")
T.check("vampire doll once", given(p, V.DOLL) == 1)
T.check("Vengoth door open", p.storage[VH.Door] == 1)
T.check("Razing! once", #p.achievements == 1 and p.achievements[1] == "Razing!", table.concat(p.achievements, ","))
T.check("Castlemania checked at the last rank", castlemaniaChecks == 1)
local done = storkus:say(p, "vampire lord token")
T.check("after the last rank (ours)", done == V.allDone, done)
T.check("total experience 186,000 (EN infobox)", p.xp == 186000, p.xp)

-- "no", and the topic does not swallow other words
local q = player({})
q.storage[Q.Questline] = 11
storkus:say(q, "hi")
storkus:say(q, "token")
local n = storkus:say(q, "no")
T.check("no: nothing given", n == "" and (q.storage[VH.Rank] or -1) == -1, n)
storkus:say(q, "token")
local m = storkus:say(q, "mission")
T.check("another word goes on to upstream (no answer at Questline 11)", m == "" and storkus:say(q, "yes") == "", m)

-- The Inquisition Mission 3 still works through Storkus (upstream lines)
local r = player({})
r.storage[Q.Questline] = 6
storkus:say(r, "hi")
local m3 = storkus:say(r, "mission")
T.check("Mission 3 start (upstream)", has(m3, "So they've sent another one?"), m3)

T.finish()
