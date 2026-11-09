-- Gaia Family server: Rathleton Quest check (2026-11-08). Marvin's voting and ranks, the
-- Dark Trails funding vote, the quest log text, the period count, the citizen-only ships
-- (Gulliver, Fearless, Charles, Seahorse), the Ancient Sewers vote (Elliott, Jacob), Sholley
-- and Ezebeth. Run from the repository root:
--   luajit tools/family/npc_talk/rathleton.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")

-- engine bits the lib needs
Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
string.titleCase = string.titleCase or function(s)
	return (s:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end))
end
-- global KV (kv.scoped(name) in the engine)
local kvStore = {}
kv = {
	scoped = function(name)
		kvStore[name] = kvStore[name] or {}
		local data = kvStore[name]
		return {
			get = function(_, k) return data[k] end,
			set = function(_, k, v) data[k] = v end,
			remove = function(_, k) data[k] = nil end,
		}
	end,
}

dofile("data-otservbr-global/lib/others/family_rathleton.lua")
local R = FamilyRathleton
local S = Storage.Quest.FamilyRathleton
local VP = Storage.Quest.U10_50.OramondQuest.VotingPoints
local DT = Storage.Quest.U10_50.DarkTrails
local SEW = Storage.Quest.U10_50.OramondQuest.TheAncientSewers.Mission

local function player(o)
	local p = T.player(o)
	p.achievements = {}
	rawset(p, "addAchievement", function(self, name) self.achievements[#self.achievements + 1] = name return true end)
	rawset(p, "hasAchievement", function(self, name)
		for _, a in ipairs(self.achievements) do
			if a == name then return true end
		end
		return false
	end)
	rawset(p, "addOutfit", function(self, look, addon) self.outfits = (self.outfits or 0) + 1 end)
	rawset(p, "isPzLocked", function() return false end)
	-- the harness keeps the player KV in a field named kv, which hides the kv() method that
	-- StdModule.travel calls; give this player a working one
	local kvData = {}
	rawset(p, "kv", function()
		local scope
		scope = {
			get = function(_, k) return kvData[k] end,
			set = function(_, k, v) kvData[k] = v end,
			remove = function(_, k) kvData[k] = nil end,
			scoped = function() return scope end,
		}
		return scope
	end)
	rawset(p, "getStorageValue", function(self, k) return self.storage[k] or -1 end)
	return p
end

local function has(text, part)
	return text:find(part, 1, true) ~= nil
end

-- ---------------------------------------------------------------- Marvin
local marvin = T.load("data-otservbr-global/npc/marvin.lua")

local p = player({ storage = { [VP] = 30 } })
T.check("greeting: voting", has(marvin:say(p, "hi"), "I guess you are here for the {voting}"))
T.check("voting menu", has(marvin:say(p, "voting"), "{learn} more about the voting, your {amount}"))
T.check("topic, no rank: shortcut only", has(marvin:say(p, "topic"), "Today you might vote for a {shortcut}. If you are"))
T.check("dungeon refused without rank", has(marvin:say(p, "dungeon"), "higher citizen rank"))
local a = marvin:say(p, "shortcut")
T.check("shortcut: votes and options", has(a, "So far you earned 30 votes") and has(a, "{minotaurs}, {fungi} or {catacombs}"), a)
T.check("option asks amount", has(marvin:say(p, "fungi"), "How many of your 30 votes do you want to cast?"))
T.check("too many votes refused", has(marvin:say(p, "31"), "can't cast more votes"))
T.check("amount confirmation", has(marvin:say(p, "10"), "You want to cast 10 of your votes on the shortcut to the fungi?"))
T.check("cast", has(marvin:say(p, "yes"), "successfully cast your vote"))
T.check("votes left 20, cast 10", p.storage[VP] == 20 and p.storage[S.VotesCast] == 10)
T.check("fungi voted bit", R.hasVoted(p, R.topicByKey.shortcut.options[2]) and not R.hasVoted(p, R.topicByKey.shortcut.options[1]))
T.check("tally fungi 10", R.tally("shortcut", "fungi") == 10)
a = marvin:say(p, "status")
T.check("status: no rank, lacks 3, quest log question", has(a, "Currently, you have no citizen rank. You lack 3 successful voting casts") and has(a, "quest log, yes or no"), a)
T.check("status into quest log", has(marvin:say(p, "yes"), "from now on you can check the status") and p.storage[S.StatusLog] == 1)
T.check("quest log text", has(R.statusText(p), "cast 10 votes") and has(R.statusText(p), "3 more cast votes and Marvin can promote you to commoner"), R.statusText(p))
T.check("promotion refused", has(marvin:say(p, "promotion"), "You lack 3"))
-- cast the rest on catacombs, then minotaurs: 'all'
marvin:say(p, "shortcut")
marvin:say(p, "catacombs")
marvin:say(p, "all")
T.check("all votes cast", has(marvin:say(p, "yes"), "successfully") and p.storage[VP] == 0 and p.storage[S.VotesCast] == 30)
T.check("no votes left", has(marvin:say(p, "shortcut"), "no votes left"))
marvin:bye(p)
a = marvin:say(p, "hi")
T.check("greeting: promotion ready", has(a, "You gathered enough points to advance"), a)
a = marvin:say(p, "promotion")
T.check("promotion to commoner", has(a, "You cast 30 votes. I will promote your citizen rank to commoner. Congratulations, Tester!") and p.storage[S.Rank] == 1, a)
T.check("achievement Rathleton Commoner", p.achievements[1] == "Rathleton Commoner")
T.check("topic, commoner: shortcut or dungeon", has(marvin:say(p, "topic"), "a {shortcut} or {dungeon}."))
p.storage[VP] = 5
marvin:say(p, "dungeon")
a = marvin:say(p, "minotaurs")
T.check("minotaurs in dungeon topic", has(a, "How many of your 5"), a)
T.check("dungeon confirmation", has(marvin:say(p, "2"), "on the minotaurs?"))
T.check("no keeps votes", has(marvin:say(p, "no"), "Then not") and p.storage[VP] == 5)
T.check("boss refused for commoner", has(marvin:say(p, "bosses"), "higher citizen rank"))
p.storage[S.Rank] = 3
T.check("topic, citizen: all four", has(marvin:say(p, "topic"), "a {shortcut}, {dungeon}, {boss}es or {raid}s."))
marvin:say(p, "raids")
T.check("raid wild life", has(marvin:say(p, "wild life"), "How many"))
T.check("raid confirm", has(marvin:say(p, "1"), "on wild life?"))
marvin:say(p, "yes")
marvin:say(p, "boss")
marvin:say(p, "glooth fairy")
marvin:say(p, "1")
marvin:say(p, "yes")
T.check("boss vote counted", R.tally("boss", "glooth fairy") == 1 and p.storage[S.VotesCast] == 32)
T.check("amount", has(marvin:say(p, "amount"), "You can still cast 3 votes. So far you have cast 32."))
T.check("learn answers", marvin:say(p, "learn") ~= "")
T.check("background answers", has(marvin:say(p, "background"), "slime slide"))
T.check("results answer", has(marvin:say(p, "results"), "The citizens of Rathleton voted for the shortcut back from the catacombs."))
marvin:bye(p)

-- squire
local sq = player({ storage = { [S.Rank] = 3, [S.VotesCast] = 260 } })
marvin:say(sq, "hi")
T.check("promotion to squire", has(marvin:say(sq, "promotion"), "to squire. Congratulations, Tester! From now you can participate") and sq.storage[S.Rank] == 4)
T.check("no promotion after squire", has(marvin:say(sq, "promotion"), "highest citizen rank"))
T.check("status squire", has(marvin:say(sq, "status"), "Your current citizen rank is squire. This is the highest rank"))
marvin:bye(sq)

-- Dark Trails funding vote
local dt = player({ storage = { [VP] = 3, [DT.Mission07] = 1 } })
T.check("funding greeting", has(marvin:say(dt, "hi"), "special voting about the most recent {funding}"))
a = marvin:say(dt, "funding")
T.check("funding: real numbers", has(a, "So far you earned 3 votes") and has(a, "topic B"), a)
T.check("funding archives", has(marvin:say(dt, "archives"), "How many of your 3 votes"))
T.check("funding 1", has(marvin:say(dt, "1"), "funding the {archives}"))
T.check("funding yes", has(marvin:say(dt, "yes"), "successfully cast") and dt.storage[DT.Mission08] == 1 and dt.storage[VP] == 2 and dt.storage[S.VotesCast] == 1)
T.check("then normal voting", has(marvin:say(dt, "status"), "Currently, you have no citizen rank"))
marvin:bye(dt)

-- ---------------------------------------------------------------- periods
local start = R.periodStart
R.refresh(start - 3600) -- before the first count: period -1 stored
kvStore["family-rathleton"] = {}
R.refresh(start - 3600)
local db = kv.scoped("family-rathleton")
db:set("tally-shortcut-fungi", 10)
db:set("tally-shortcut-catacombs", 4)
db:set("tally-dungeon-golems", 2)
db:set("tally-dungeon-wrath", 2)
db:set("tally-boss-lisa", 1)
T.check("default results before a count", db:get("result-shortcut") == nil)
R.refresh(start + 60)
T.check("count: fungi wins", db:get("result-shortcut") == "fungi")
T.check("count: tie keeps previous (wrath default)", db:get("result-dungeon") == "wrath")
T.check("count: lisa", db:get("result-boss") == "lisa")
T.check("count: no raid votes keeps default", db:get("result-raid") == nil)
T.check("tallies reset", db:get("tally-shortcut-fungi") == nil)
R.refresh(start + 6 * 86400)
T.check("same period: no change", db:get("result-shortcut") == "fungi")
db:set("tally-shortcut-minotaurs", 1)
R.refresh(start + 7 * 86400 + 1)
T.check("next period: minotaurs", db:get("result-shortcut") == "minotaurs")
T.check("next count in 7 days", R.secondsToNextPeriod(start + 1) == 7 * 86400 - 1)

-- ---------------------------------------------------------------- ships
local function travelCheck(file, keyword, costText)
	local npc = T.load(file)
	local tourist = player({ money = 1000 })
	npc:say(tourist, "hi")
	local refused = npc:say(tourist, keyword)
	T.check(file:match("npc/(.-)%.lua") .. ": " .. keyword .. " refused without citizen rank", has(refused, "reserved for citizens of Rathleton"), refused)
	npc:bye(tourist)
	local citizen = player({ money = 1000, storage = { [S.Rank] = 3 } })
	npc:say(citizen, "hi")
	local offer = npc:say(citizen, keyword)
	T.check(file:match("npc/(.-)%.lua") .. ": " .. keyword .. " offered to citizens", has(offer, "Do you seek a passage to") and has(offer, costText), offer)
	npc:say(citizen, "yes")
	T.check(file:match("npc/(.-)%.lua") .. ": " .. keyword .. " sails", citizen.teleported ~= nil)
end
travelCheck("data-otservbr-global/npc/captain_gulliver.lua", "edron", "110")
travelCheck("data-otservbr-global/npc/captain_gulliver.lua", "venore", "130")
travelCheck("data-otservbr-global/npc/captain_gulliver.lua", "port hope", "200")
travelCheck("data-otservbr-global/npc/captain_gulliver.lua", "krailos", "60")
travelCheck("data-otservbr-global/npc/captain_fearless.lua", "oramond", "130")
travelCheck("data-otservbr-global/npc/charles.lua", "oramond", "200")
travelCheck("data-otservbr-global/npc/captain_seahorse.lua", "oramond", "110")
do
	local gulliver = T.load("data-otservbr-global/npc/captain_gulliver.lua")
	local tourist = player({ money = 1000 })
	gulliver:say(tourist, "hi")
	T.check("gulliver: thais open", has(gulliver:say(tourist, "thais"), "Do you seek a passage to Thais"))
	gulliver:say(tourist, "no")
	T.check("gulliver: sail text", has(gulliver:say(tourist, "sail"), "{Edron}, {Venore}, {Port Hope} or {Krailos}"))
end

-- ---------------------------------------------------------------- Ancient Sewers
for _, file in ipairs({ "data-otservbr-global/npc/elliott.lua", "data-otservbr-global/npc/jacob.lua" }) do
	local npc = T.load(file)
	local w = player({})
	npc:say(w, "hi")
	npc:say(w, "mission")
	npc:say(w, "yes")
	T.check(file .. ": job taken", w.storage[SEW] == 1)
	a = npc:say(w, "mission")
	T.check(file .. ": no vote before repairs", has(a, "You fixed 0 of the twenty") and (w.storage[VP] or -1) < 1, a)
	npc:say(w, "ok")
	T.check(file .. ": ok gives nothing", (w.storage[VP] or -1) < 1)
	w.storage[SEW] = 21
	T.check(file .. ": done asks ok", has(npc:say(w, "mission"), "Let me check, {ok}?"))
	npc:say(w, "ok")
	T.check(file .. ": vote after 20 repairs", w.storage[VP] == 1 and w.storage[SEW] == 22)
end

-- ---------------------------------------------------------------- Sholley
do
	local sholley = T.load("data-otservbr-global/npc/sholley.lua")
	local x = player({ storage = { [DT.Mission12] = 1, [VP] = 100 } })
	sholley:say(x, "hi")
	sholley:say(x, "friend")
	T.check("sholley: 100 unspent votes but no rank: no", (x.storage[DT.Mission13] or -1) < 1)
	local y = player({ storage = { [DT.Mission12] = 1, [S.Rank] = 1 } })
	sholley:say(y, "hi")
	sholley:say(y, "friend")
	T.check("sholley: commoner passes", y.storage[DT.Mission13] == 1)
end

-- ---------------------------------------------------------------- Ezebeth
do
	local ezebeth = T.load("data-otservbr-global/npc/ezebeth.lua")
	local z = player({ storage = { [DT.Outfit] = 1, [VP] = 50 } })
	ezebeth:say(z, "hi")
	T.check("ezebeth: unspent votes give nothing", has(ezebeth:say(z, "addon"), "voted for each of the available shortcuts"))
	z.storage[S.Voted] = 63 -- bits 0-5: every shortcut and dungeon
	T.check("ezebeth: first addon", has(ezebeth:say(z, "addon"), "first addon") and z.storage[Storage.Quest.U10_50.GloothEngineerOutfits.Addon1] == 1)
	T.check("ezebeth: second needs bosses", has(ezebeth:say(z, "addon"), "each bossfight"))
	z.storage[S.Voted] = 511
	T.check("ezebeth: second addon", has(ezebeth:say(z, "addon"), "second addon"))
	T.check("ezebeth: Glooth Engineer", z.achievements[1] == "Glooth Engineer")
end

-- ---------------------------------------------------------------- Flora and the bosses (2026-11-09)
do
	for _, boss in pairs(R.bosses) do
		for _, field in pairs(boss) do
			if type(field) == "table" and field.x and not field.sendMagicEffect then
				field.sendMagicEffect = function() end
			end
		end
	end
	local flora = T.load("data-otservbr-global/npc/flora.lua")
	local db = kv.scoped("family-rathleton")
	db:set("result-boss", "glooth fairy")
	local cm = player({ storage = { [VP] = 2, [S.Rank] = 1 } })
	flora:say(cm, "hi")
	flora:say(cm, "fight")
	T.check("flora: commoner refused (BR: second rank)", has(flora:say(cm, "yes"), "Only inhabitants") and cm.storage[VP] == 2)
	flora:bye(cm)
	local f = player({ storage = { [VP] = 2, [S.Rank] = 2 } })
	T.check("flora: glooth fairy greeting (EN)", has(flora:say(f, "hi"), "voted for the {Glooth Fairy}!"))
	T.check("flora: fight question", has(flora:say(f, "fight"), "Do you really want to enter the Glooth Fairy's hideout."))
	T.check("flora: one voting right charged", has(flora:say(f, "yes"), "Here you go!") and f.storage[VP] == 1 and f.teleported and f.teleported.x == 33660)
	flora:bye(f)
	db:set("result-boss", "bullwark")
	T.check("flora: bullwark greeting (EN)", has(flora:say(f, "hi"), "voted for {Bullwark}!"))
	T.check("flora: bullwark (EN)", has(flora:say(f, "bullwark"), "lump of meat and muscles"))
	flora:say(f, "fight")
	f.teleported = nil
	T.check("flora: into Bullwark's lever room", has(flora:say(f, "yes"), "Here you go!") and f.storage[VP] == 0 and f.teleported.x == 33700 and f.teleported.y == 31847)
	T.check("flora: Bullwark spot from BR", R.bosses.bullwark.flora.x == 33702)
	flora:say(f, "fight")
	T.check("flora: no voting right left", has(flora:say(f, "yes"), "no voting right left"))
	flora:bye(f)
	R.setLeverWait("bullwark", R.LEVER_REST)
	local g = player({ storage = { [VP] = 5, [S.Rank] = 2 } })
	flora:say(g, "hi")
	flora:say(g, "fight")
	T.check("flora: lever resting", has(flora:say(g, "yes"), "still resting") and g.storage[VP] == 5)
	flora:bye(g)
	R.setLeverWait("bullwark", -1)
	db:set("result-boss", "lisa")
	local l = player({ storage = { [VP] = 1, [S.Rank] = 3 } })
	T.check("flora: lisa greeting", has(flora:say(l, "hi"), "voted for {Lisa}!"))
	flora:say(l, "fight")
	T.check("flora: into Lisa's hall", has(flora:say(l, "yes"), "Here you go!") and l.teleported.x == 33565 and l.teleported.z == 8)
	flora:bye(l)
	T.check("lisa lever rests 15 minutes (BR)", R.leverRest("lisa") == 900 and R.leverRest("bullwark") == 1000)
	db:set("result-boss", nil)
	-- Hero of Rathleton
	local pipe = T.load("data-otservbr-global/npc/strange_pipe.lua")
	local AD = Storage.HeroRathleton.AccessDoor
	local c = player({ storage = { [S.Rank] = 3 } })
	pipe:say(c, "hi")
	T.check("strange pipe: citizen refused", (c.storage[AD] or -1) < 1)
	local q = player({ storage = { [S.Rank] = 4 } })
	pipe:say(q, "hi")
	T.check("strange pipe: squire gets access", q.storage[AD] == 1)
end

T.finish()
