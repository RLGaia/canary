-- Gaia Family server: Oramond Quest kill and delivery tasks check (2026-11-08): Terrence's five
-- hunts, Drystan Wildweed's Nature's Balance and Elbert's glooth capsules, kill counting and
-- the quest log texts. Run from the repository root:
--   luajit tools/family/npc_talk/oramond_tasks.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")

Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
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
MESSAGE_EVENT_ADVANCE = MESSAGE_EVENT_ADVANCE or 19
MESSAGE_STATUS = MESSAGE_STATUS or 17
CONST_ME_REDSMOKE, CONST_ME_YELLOWSMOKE, CONST_ME_GREENSMOKE, CONST_ME_PURPLESMOKE = 167, 168, 169, 170

dofile("data-otservbr-global/lib/others/family_rathleton.lua")
dofile("data-otservbr-global/lib/others/family_oramond_tasks.lua")
local OT = FamilyOramondTasks
local S = Storage.Quest.FamilyOramondTasks
local R = Storage.Quest.FamilyRathleton
local VP = Storage.Quest.U10_50.OramondQuest.VotingPoints
local QL = Storage.Quest.U10_50.OramondQuest.QuestLine

local function player(o)
	local p = T.player(o)
	p.messages = {}
	rawset(p, "getStorageValue", function(self, k) return self.storage[k] or -1 end)
	rawset(p, "sendTextMessage", function(self, _, text) self.messages[#self.messages + 1] = text end)
	p.said = {}
	rawset(p, "say", function(self, text) self.said[#self.said + 1] = text end)
	p.achievements = {}
	rawset(p, "addAchievement", function(self, name) self.achievements[name] = true return true end)
	rawset(p, "hasAchievement", function(self, name) return self.achievements[name] == true end)
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
local function kill(p, name, n)
	for _ = 1, n do
		OT.countKill(p, name)
	end
end

-- ---------------------------------------------------------------- Terrence
local terrence = T.load("data-otservbr-global/npc/terrence.lua")
local p = player({})
terrence:say(p, "hi")
local a = terrence:say(p, "killing")
T.check("no rank: only rot listed", has(a, "help with {rot}.") and not has(a, "{minor}"), a)
T.check("minor refused without rank", has(terrence:say(p, "minor"), "rank of commoner"))
kill(p, "Rot Elemental", 3)
T.check("rot kills count before talking (BR)", p.storage[S.Rot] == 3 and p.storage[QL] == 1)
a = terrence:say(p, "rot")
T.check("rot progress", has(a, "You killed 3 of the 100 rot elementals or glooth blobs so far."), a)
kill(p, "Glooth Blob", 120)
T.check("rot capped at 100", p.storage[S.Rot] == 100)
T.check("message at 100", has(p.messages[#p.messages] or "", "Taking the Rot Out: you killed 100. Report to Terrence."))
a = terrence:say(p, "rot")
T.check("rot report gives 1 vote and resets", has(a, "One hundred!") and p.storage[VP] == 1 and p.storage[S.Rot] == 0, a)
kill(p, "Blood Beast", 5)
T.check("blood beasts not counted without rank", (p.storage[S.Beast] or -1) == -1)
T.check("other creatures ignored", (OT.countKill(p, "Rat") or true) and p.storage[S.Rot] == 0)
terrence:bye(p)

local c = player({ storage = { [R.Rank] = 1 } })
terrence:say(c, "hi")
a = terrence:say(c, "help")
T.check("commoner: rot, blood, minor", has(a, "{rot}, {blood} and {minor}"), a)
a = terrence:say(c, "blood")
T.check("beast offer starts it", has(a, "Blood beasts are horrible creatures") and c.storage[S.Beast] == 0, a)
kill(c, "Blood Beast", 100)
T.check("beast report", has(terrence:say(c, "beast"), "One hundred!") and c.storage[VP] == 1)
kill(c, "Minotaur Hunter", 40)
kill(c, "Worm Priestess", 30)
kill(c, "Mooh'Tah Warrior", 30)
T.check("minor taurs mixed", has(terrence:say(c, "minor taurs"), "One hundred!") and c.storage[VP] == 2)
T.check("gargoyles refused for commoner", has(terrence:say(c, "gargoyles"), "rank of inhabitant"))
terrence:bye(c)

local z = player({ storage = { [R.Rank] = 3 } })
terrence:say(z, "hi")
T.check("citizen: all five", has(terrence:say(z, "mission"), "{rot}, {blood}, {minor}, {gargoyles} and {major}"))
kill(z, "Execowtioner", 50)
kill(z, "Moohtant", 50)
T.check("major report", has(terrence:say(z, "dangerous"), "One hundred!") and z.storage[VP] == 1)
kill(z, "Metal Gargoyle", 100)
T.check("rust report", has(terrence:say(z, "rust"), "One hundred!") and z.storage[VP] == 2)
-- upstream Dark Trails path still works
z.storage[Storage.Quest.U10_50.DarkTrails.Mission16] = 1
T.check("manway still upstream", has(terrence:say(z, "manway"), "I'm not allowed to let just anyone pass"))
T.check("effort still upstream", has(terrence:say(z, "effort"), "I'll let you pass") and z.storage[Storage.Quest.U10_50.DarkTrails.Mission17] == 1)
terrence:bye(z)

-- ---------------------------------------------------------------- Drystan
local drystan = T.load("data-otservbr-global/npc/drystan_wildweed.lua")
local d = player({})
T.check("drystan greeting", has(drystan:say(d, "hi"), "annoying {thieves}"))
T.check("drystan refuses non-citizen", has(drystan:say(d, "thieves"), "only trust citizens"))
drystan:bye(d)
d.storage[R.Rank] = 3
drystan:say(d, "hi")
T.check("drystan offer", has(drystan:say(d, "thieves"), "Would you go and eliminate some for me?"))
T.check("drystan yes", has(drystan:say(d, "yes"), "Weed out two hundred") and d.storage[S.Bandits] == 0)
kill(d, "Glooth Bandit", 150)
T.check("drystan progress", has(drystan:say(d, "thieves"), "150 of the two hundred"))
kill(d, "Glooth Brigand", 80)
T.check("bandits capped at 200", d.storage[S.Bandits] == 200)
drystan:bye(d)
T.check("drystan asks at greeting", has(drystan:say(d, "hi"), "Have you eliminated the glooth bandits?"))
a = drystan:say(d, "yes")
T.check("drystan reward 2 votes, 200 taken", has(a, "certain voice in the city") and d.storage[VP] == 2 and d.storage[S.Bandits] == 0, a)
drystan:bye(d)

-- ---------------------------------------------------------------- Elbert
local elbert = T.load("data-otservbr-global/npc/elbert.lua")
local e = player({ storage = { [R.Rank] = 3 }, items = { [21814] = 25, [21816] = 3 } })
T.check("elbert greeting", has(elbert:say(e, "hi"), "some {trouble} here"))
a = elbert:say(e, "trouble")
T.check("elbert story", has(a, "Would you help me and try to bring them back?"), a)
T.check("elbert yes", has(elbert:say(e, "yes"), "If you have found ten glooth capsules") and e.storage[S.Capsules] == 1)
elbert:bye(e)
T.check("elbert asks at greeting", has(elbert:say(e, "hi"), "Do you bring back the stolen glooth supply capsules?"))
a = elbert:say(e, "yes")
T.check("elbert first report: 2 batches, 4 votes, tainted line", has(a, "They are tainted.") and e.storage[VP] == 4 and e.items[21814] == 5 and e.storage[S.Capsules] == 2, a)
elbert:bye(e)
T.check("elbert asks for more", has(elbert:say(e, "hi"), "more stolen glooth supply capsules?"))
a = elbert:say(e, "yes")
T.check("elbert: not enough", has(a, "You don't have ten glooth capsules") and has(a, "Tainted ones"), a)
e.items[21814] = 10
T.check("elbert repeat report", has(elbert:say(e, "capsules") .. elbert:say(e, "yes"), "This will get you a certain voice") and e.storage[VP] == 6)
elbert:bye(e)
local n = player({})
elbert:say(n, "hi")
T.check("elbert refuses non-citizen", has(elbert:say(n, "trouble"), "matter for citizens"))

-- ---------------------------------------------------------------- quest log texts
T.check("mission text progress", has(OT.missionText(c, OT.hunts[1]), "Kill 100 rot elementals or glooth blobs for Terrence"))
d.storage[S.Bandits] = 200
T.check("mission text done", has(OT.missionText(d, OT.bandits), "Report to Drystan Wildweed"))


-- ================================================================ batch 2
-- Terrence: supplies and sabotage
local s2 = player({})
terrence:say(s2, "hi")
T.check("help mentions supplies and sabotage", has(terrence:say(s2, "killing"), "{supplies}") )
T.check("supplies offer", has(terrence:say(s2, "supplies"), "Sink ten of those crates") and s2.storage[S.Turnips] == 0)
for _ = 1, 10 do OT.addTurnips(s2) end
T.check("11th crate refused", OT.canTakeCrate(s2) == false and has(s2.messages[#s2.messages], "thinned out these supplies"))
T.check("supplies report", has(terrence:say(s2, "supplies"), "Ten crates of turnips") and s2.storage[VP] == 1 and s2.storage[S.Turnips] == 0)
T.check("sabotage offer", has(terrence:say(s2, "sabotage"), "armor racks") and s2.storage[S.Sabotage] == 0)
for _ = 1, 10 do OT.addSabotage(s2) end
T.check("11th rack refused", OT.addSabotage(s2) == false and has(s2.messages[#s2.messages], "already sabotaged"))
T.check("sabotage progress word", has(terrence:say(s2, "sabotage"), "Excellent sabotage") and s2.storage[VP] == 2)
terrence:bye(s2)

-- Doubleday
local doubleday = T.load("data-otservbr-global/npc/doubleday.lua")
local db = player({})
doubleday:say(db, "hi")
T.check("exchange with nothing", has(doubleday:say(db, "exchange"), "haven't helped me"))
a = doubleday:say(db, "combinatorics")
T.check("combinatorics story", has(a, "So, are you in or not or what?"), a)
a = doubleday:say(db, "yes")
T.check("combinatorics order given", has(a, "First a ") and db.storage[S.Combinatorics] == 1, a)
local order = db:kv():get("combo-order")
local names = { g = "Glooth Golem", d = "Devourer", a = "Glooth Anemone" }
local function sequence(p, n)
	for _ = 1, n do
		for i = 1, 3 do OT.countKill(p, names[order:sub(i, i)]) end
	end
end
sequence(db, 3)
T.check("3 sequences: no chain yet", (db:kv():get("combo-chains") or 0) == 0 and db:kv():get("combo-sequences") == 3)
sequence(db, 2)
T.check("5 sequences: 2 chains", db:kv():get("combo-chains") == 2)
OT.countKill(db, names[order:sub(2, 2)])
T.check("wrong kill breaks the combo", db:kv():get("combo-chains") == 0 and db:kv():get("combo-sequences") == 0)
sequence(db, 13)
T.check("13 sequences: 10 chains and Combo Master", db:kv():get("combo-chains") == 10 and db.achievements["Combo Master"])
a = doubleday:say(db, "combinatorics")
T.check("combinatorics report asks", has(a, "10 consecutive chains"), a)
T.check("chains banked as favours", has(doubleday:say(db, "yes"), "10 consecutive chains!") and OT.favors(db) == 10 and db:kv():get("combo-chains") == 0)
-- communication
a = doubleday:say(db, "communication")
T.check("communication offer", has(a, "Will you fetch one?"), a)
T.check("communication yes", has(doubleday:say(db, "yes"), "valves") and db.storage[S.Communication] == 1)
T.check("communication waiting", has(doubleday:say(db, "communications"), "Did you get a vial"))
-- machine
local m = OT.machines[1]
for _ = 1, 3 do OT.useValve(db, Position(33614, 31931, 9)) end
local colours = db:kv():get("comm-colours")
T.check("three steam colours", colours and #colours == 3, colours)
local lever = function(key)
	return { getId = function() return OT.COLOURS[key].lever end }
end
OT.leverReady = {}
local created = 0
Game.createItem = function() created = created + 1 return {} end
Tile = function() return { getItemById = function() return nil end } end
Position = function(x, y, z) return { x = x, y = y, z = z, sendMagicEffect = function() end } end
for _, mm in ipairs(OT.machines) do
	mm.glooth.sendMagicEffect = function() end
end
addEvent = addEvent or function() end
local wrong = colours:sub(1, 1) == "r" and "y" or "r"
OT.pullLever(db, lever(wrong), Position(33618, 31927 + 0, 9))
T.check("wrong lever: nothing", created == 0 and has(db.messages[#db.messages], "coughs"))
for i = 1, 3 do
	OT.leverReady = {}
	OT.pullLever(db, lever(colours:sub(i, i)), Position(33618, 31928, 9))
end
T.check("right levers: glooth", created == 1 and has(db.messages[#db.messages], "Strangely coloured glooth"))
local gl = { removed = false, remove = function(self) self.removed = true end }
OT.takeGlooth(db, gl)
T.check("glooth fills a vial", gl.removed and db.items[21188] == 1 and db.storage[S.Communication] == 2)
T.check("communication report", has(doubleday:say(db, "communication"), "coloured glooth!") and OT.favors(db) == 11 and (db.items[21188] or 0) == 0)
-- exchange incl. an old probing report
db.storage[Storage.Quest.U10_50.OramondQuest.Probing.Mission] = 3
T.check("exchange counts probing", has(doubleday:say(db, "exchange"), "you helped me 12 times"))
T.check("too many", has(doubleday:say(db, "13"), "let's try to be reasonable"))
T.check("five", has(doubleday:say(db, "5"), "that's 5 vote(s)"))
T.check("exchange yes", has(doubleday:say(db, "yes"), "you just gained 5 genuine votes") and db.storage[VP] == 5 and OT.favors(db) == 7 and db.storage[Storage.Quest.U10_50.OramondQuest.Probing.Mission] == -1)
T.check("upstream experiment intact", has(doubleday:say(db, "experiment"), "Are you in?"))
doubleday:bye(db)

-- Dr Merlay's Misery
local roswitha = T.load("data-otservbr-global/npc/roswitha.lua")
local mr = player({ money = 100 })
roswitha:say(mr, "hi")
T.check("free pint", has(roswitha:say(mr, "pint"), "on the house") and mr.items[21137] == 1)
T.check("second pint refused", has(roswitha:say(mr, "pint"), "One free pint an hour"))
T.check("drink 10 gold", has(roswitha:say(mr, "drink"), "Cheers") and mr.items[21137] == 2)
roswitha:bye(mr)
local merlay = T.load("data-otservbr-global/npc/dr_merlay.lua")
T.check("merlay greeting", has(merlay:say(mr, "hi"), "I'm {hideous}!"))
T.check("merlay small talk", has(merlay:say(mr, "factory"), "nobody could construct metal golems"))
T.check("merlay help", has(merlay:say(mr, "help"), "Will you do it?"))
T.check("merlay letters", has(merlay:say(mr, "yes"), "Here are my letters") and mr.items[21141] == 1 and mr.storage[S.Merlay] == 1)
T.check("pill before all letters refused", (function() mr.items[21142] = 1 return has(merlay:say(mr, "pill"), "did you deliver all my letters") end)())
mr.items[21142] = nil
merlay:bye(mr)
local maro = T.load("data-otservbr-global/npc/maro.lua")
maro:say(mr, "hi")
T.check("maro message", has(maro:say(mr, "message"), "Thank you for bringing me his letter"))
T.check("maro yes", has(maro:say(mr, "yes"), "Azalea and Fyodor"))
maro:bye(mr)
local alaistar = T.load("data-otservbr-global/npc/alaistar.lua")
alaistar:say(mr, "hi")
T.check("alaistar message", has(alaistar:say(mr, "message"), "a {moment}"))
T.check("alaistar moment gives potion", has(alaistar:say(mr, "moment"), "This is fantastic!") and mr.items[21154] == 1)
T.check("alaistar lost", has(alaistar:say(mr, "lost"), "another glooth potion") and mr.items[21154] == 2)
alaistar:bye(mr)
local azalea = T.load("data-otservbr-global/npc/azalea.lua")
azalea:say(mr, "hi")
T.check("azalea letter gives bloom", has(azalea:say(mr, "letter"), "darling I nurtured") and mr.items[21213] == 1)
T.check("azalea lost waits an hour", has(azalea:say(mr, "lost"), "Come back in an hour"))
azalea:bye(mr)
local fyodor = T.load("data-otservbr-global/npc/fyodor.lua")
fyodor:say(mr, "hi")
T.check("fyodor friend", has(fyodor:say(mr, "friend"), "To whomever it concerns"))
fyodor:bye(mr)
local emily = T.load("data-otservbr-global/npc/emily.lua")
emily:say(mr, "hi")
T.check("emily message", has(emily:say(mr, "message"), "{Tell} me at once"))
T.check("emily tell", has(emily:say(mr, "tell"), "A letter from Henry!"))
emily:bye(mr)
T.check("quest log: all visited", has(OT.missionTextBatch2(mr, "Merlay"), "particle accelerator"))
T.check("merlay greets as friend", has(merlay:say(mr, "hi"), "my eagerly awaited friend"))
mr.items[21216] = 1
T.check("merlay mixture", has(merlay:say(mr, "cool gloothy mixture"), "use the particle accelerator") and mr.storage[S.Merlay] == 2)
mr.items[21216] = nil
mr.items[21142] = 1
T.check("merlay pill asks", has(merlay:say(mr, "ominously glowing pill"), "Yes or no?"))
local votesBefore = math.max(0, mr.storage[VP] or 0)
T.check("merlay cured", has(merlay:say(mr, "yes"), "I can feel it working already") and mr.storage[VP] == votesBefore + 1 and (mr.items[21142] or 0) == 0 and mr.storage[S.Merlay] == 0)
merlay:bye(mr)

T.finish()
