-- Gaia Family server: Oramond Quest kill and delivery tasks check (2026-11-08): Terrence's five
-- hunts, Drystan Wildweed's Nature's Balance and Elbert's glooth capsules, kill counting and
-- the quest log texts; batches 2-4 (Doubleday, Dr Merlay, statues, Georgia, The Gloud Ship with
-- Zeronex, Nicholas, Yeo and Publicity, Tending Gloothworms with Wesley). Run from the repository root:
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
T.check("elbert first report: 2 batches, 4 votes, tainted line, asks for the warlock", has(a, "They are tainted.") and has(a, "I want you to find this person. Would you help me?") and e.storage[VP] == 4 and e.items[21814] == 5 and e.storage[S.Capsules] == 2, a)
elbert:bye(e)
T.check("elbert greets with the statues question", has(elbert:say(e, "hi"), "I don't believe that these thieves act on their own behalf"))
T.check("elbert statues yes", has(elbert:say(e, "yes"), "secret hideout") and e.storage[S.Statues] == 1)
T.check("elbert: capsules wait for the statues", has(elbert:say(e, "capsules") .. elbert:say(e, "yes"), "I'm very happy that you agreed"))
elbert:bye(e)
T.check("elbert asks about the culprit", has(elbert:say(e, "hi"), "Have you found out whether there is someone behind"))
T.check("elbert: not reasonable", has(elbert:say(e, "yes"), "That doesn't sound very reasonable"))
elbert:bye(e)
e.storage[S.Statues] = 3
local before = e.storage[VP]
T.check("elbert completes statues on greeting, 4 votes", has(elbert:say(e, "hi"), "Circle of the Black Sphinx") and e.storage[S.Statues] == 4 and e.storage[VP] == before + 4)
elbert:bye(e)
T.check("elbert asks for more", has(elbert:say(e, "hi"), "more stolen glooth supply capsules?"))
a = elbert:say(e, "yes")
T.check("elbert: not enough", has(a, "You don't have ten glooth capsules") and has(a, "Tainted ones"), a)
e.items[21814] = 10
T.check("elbert repeat report", has(elbert:say(e, "capsules") .. elbert:say(e, "yes"), "This will get you a certain voice") and e.storage[VP] == before + 6)
T.check("elbert job line", has(elbert:say(e, "job"), "glooth} pumping stations"))
T.check("elbert no tube before Georgia", has(elbert:say(e, "glass tube"), "What would you need that for"))
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


-- ================================================================ batch 3
-- statues
local st = player({ storage = { [R.Rank] = 3, [S.Statues] = 1 } })
local at = function(pos) st.position = pos rawset(st, "getPosition", function() return pos end) end
local P = OT.STATUE_POS
T.check("bless counts", OT.pleaseStatue(st, "bless") and has(st.messages[#st.messages], "spreads its wings"))
T.check("adorn counts", OT.pleaseStatue(st, "adorn"))
T.check("feed counts", OT.pleaseStatue(st, "feed"))
T.check("not all yet", not OT.statuesDone(st))
at(Position(P.entertain.x + 1, P.entertain.y, P.entertain.z))
OT.playLyre(st)
T.check("lyre near the king statue", OT.statuesDone(st) and has(st.messages[#st.messages], "kingly statue"))
OT.warlockKilled(st)
T.check("warlock killed after the statues", st.storage[S.Statues] == 2 and has(st.messages[#st.messages], "Isn't there a letter in the shelf?"))
local st2 = player({ storage = { [S.Statues] = 1 } })
OT.warlockKilled(st2)
T.check("warlock before the statues does nothing", st2.storage[S.Statues] == 1)
T.check("statues ignored before Elbert", not OT.pleaseStatue(player({}), "bless"))
T.check("quest log statues text", has(OT.missionTextBatch3(st, "Statues"), "Search the shelf"))

-- Georgia
local georgia = T.load("data-otservbr-global/npc/georgia_rainbird.lua")
local g = player({ storage = { [R.Rank] = 3 } })
T.check("georgia greeting", has(georgia:say(g, "hi"), "You don't have to shout"))
a = georgia:say(g, "mission")
T.check("georgia mission", has(a, "I need your eyes. Would you help me?"), a)
a = georgia:say(g, "yes")
T.check("georgia gives the device", has(a, "Do you know what you need for the repair?") and g.items[21759] == 1 and g.storage[S.Plague] == 1, a)
T.check("georgia lists components", has(georgia:say(g, "no"), "five special {gear wheels}"))
T.check("georgia: parts first", has(georgia:say(g, "mission"), "Mount the missing"))
georgia:bye(g)
-- elbert's tube
elbert:say(g, "hi")
T.check("elbert gives the glass tube", has(elbert:say(g, "glass tube"), "Did Georgia send you?") and g.items[21766] == 1)
elbert:bye(g)
-- assembly
local device = { id = 21759, getId = function(self) return self.id end, transform = function(self, id) self.id = id end }
local function part(id) return { getId = function() return id end } end
g.items[21755] = 4
OT.mountPart(g, part(21755), device)
T.check("four gear wheels are not enough", has(g.messages[#g.messages], "You need 5"))
g.items[21755] = 5
g.items[21758] = 1
g.items[21757] = 1
OT.mountPart(g, part(21755), device)
T.check("gears mounted", has(g.messages[#g.messages], "You mount the gear wheels on the broken device. But it doesn't seem complete yet.") and (g.items[21755] or 0) == 0)
OT.mountPart(g, part(21758), device)
OT.mountPart(g, part(21757), device)
OT.mountPart(g, part(21766), device)
T.check("converter complete", device.id == 21761 and has(g.messages[#g.messages], "Now it seems to work."))
g.items[21761] = 1
georgia:say(g, "hi")
T.check("georgia: antidote", has(georgia:say(g, "mission"), "crimson crest mushroom") and g.storage[S.Plague] == 2)
georgia:bye(g)
-- pools
g.items[21767] = 1
for i = 1, 7 do OT.convertPool(g, { x = 33712, y = 31850 + i, z = 12 }) end
T.check("same pool twice refused", OT.convertPool(g, { x = 33712, y = 31851, z = 12 }) == false)
T.check("quest log pools", has(OT.missionTextBatch3(g, "Plague"), "7 of 8"))
OT.convertPool(g, { x = 33713, y = 31860, z = 12 })
T.check("8 pools: parts back, report", g.storage[S.Plague] == 3 and g.items[21759] == 2 and g.items[21755] == 5 and (g.items[21767] or 0) == 0)
georgia:say(g, "hi")
local v0 = math.max(0, g.storage[VP] or 0)
T.check("georgia pays 5 votes", has(georgia:say(g, "mission"), "Eight pools") and g.storage[VP] == v0 + 5 and g.storage[S.Plague] == 1)
T.check("georgia lost device", has(georgia:say(g, "lost glooth converter"), "old frame") and g.items[21759] == 3)
georgia:bye(g)

-- ================================================================ batch 4
local function obj(p, id)
	local o = { id = id }
	function o:getId() return self.id end
	function o:remove(n) p.items[self.id] = (p.items[self.id] or 0) - (n or 1) return true end
	function o:transform(to) p.items[self.id] = (p.items[self.id] or 0) - 1 p.items[to] = (p.items[to] or 0) + 1 self.id = to return true end
	return o
end
local function last(p) return p.messages[#p.messages] or "" end
-- Zeronex: the mission
local zeronex = T.load("data-otservbr-global/npc/zeronex.lua")
local nicholas = T.load("data-otservbr-global/npc/nicholas.lua")
local yeo = T.load("data-otservbr-global/npc/yeo.lua")
local low = player({ storage = { [R.Rank] = 2 } })
zeronex:say(low, "hi")
T.check("zeronex: inhabitant refused", has(zeronex:say(low, "mission"), "a citizen of Rathleton"))
zeronex:bye(low)
local z = player({ storage = { [R.Rank] = 3 }, items = { [10279] = 20, [3581] = 10 } })
T.check("zeronex greeting", has(zeronex:say(z, "hi"), "very interesting {process}"))
T.check("zeronex gloud", has(zeronex:say(z, "gloud"), "'glooth' and 'cloud'"))
T.check("zeronex job", has(zeronex:say(z, "job"), "{dangerous} job"))
a = zeronex:say(z, "incident")
T.check("zeronex incident (EN)", has(a, "am I boring you?"), a)
a = zeronex:say(z, "yes")
T.check("zeronex starts the mission", has(a, "Nicholas Cavendish is his name") and z.storage[S.Gloud] == 1 and z.storage[QL] == 1, a)
T.check("zeronex reminder", has(zeronex:say(z, "mission"), "{very strong cloth}"))
zeronex:bye(z)
T.check("zeronex report greeting", has(zeronex:say(z, "hi"), "Any progress?"))
zeronex:bye(z)
-- BR start through "mission"
local zb = player({ storage = { [R.Rank] = 3 } })
zeronex:say(zb, "hi")
T.check("zeronex mission (BR)", has(zeronex:say(zb, "mission"), "Will you go on the necessary errands for me?"))
T.check("zeronex yes (BR)", has(zeronex:say(zb, "yes"), "Splendid!") and zb.storage[S.Gloud] == 1)
zeronex:bye(zb)
-- Nicholas
nicholas:say(z, "hi")
a = nicholas:say(z, "very strong cloth")
T.check("nicholas wants crocodile leather", has(a, "I want 20 pieces of crocodile leather"), a)
a = nicholas:say(z, "strong cloth")
T.check("nicholas takes the leather, gives the fork", has(a, "steel spider silk") and z.items[10279] == 0 and z.items[21877] == 1, a)
T.check("nicholas afterwards", has(nicholas:say(z, "strong cloth"), "That's all I will say"))
nicholas:bye(z)
local n0 = player({ storage = { [R.Rank] = 3 } })
nicholas:say(n0, "hi")
T.check("nicholas before Zeronex", has(nicholas:say(n0, "strong cloth"), "All my cloth is strong"))
nicholas:bye(n0)
-- silk, yarn, cloth
local spot = Position(33541, 31928, 7)
OT.milkSpider(z, spot)
T.check("spider milked", z.items[21819] == 1 and has(last(z), "With much care, you extracted some steel spider silk."))
OT.milkSpider(z, spot)
T.check("same spider: one minute", z.items[21819] == 1 and has(last(z), "Give it a minute"))
OT.windYarn(z)
T.check("winch needs 15 silk", has(last(z), "You need 15") and z.items[21819] == 1)
z.items[21819] = 15
OT.windYarn(z)
T.check("winch: spool", z.items[21820] == 1 and z.items[21819] == 0 and has(last(z), "You have spun the yarn on a spool."))
OT.weaveCloth(z, obj(z, 21820))
T.check("loom: strong cloth", z.items[21873] == 1 and z.items[21820] == 0 and has(last(z), "fine strong cloth"))
OT.milkSpider(player({ storage = { [S.Gloud] = 4 } }), spot)
zeronex:say(z, "hi")
a = zeronex:say(z, "mission")
T.check("zeronex takes the cloth", has(a, "Yeo, who might know more") and z.storage[S.Gloud] == 2 and z.items[21873] == 0, a)
zeronex:bye(z)
-- Yeo
T.check("yeo greeting with shrimp", has(yeo:say(z, "hi"), "lovely smell of shrimp"))
T.check("yeo strong glue", has(yeo:say(z, "strong glue"), "I can make you some {gloo}"))
T.check("yeo asks", has(yeo:say(z, "gloo"), "Did you bring me those 10 shrimp?"))
a = yeo:say(z, "yes")
T.check("yeo trades the gloo", has(a, "Here's your gloo, friend") and z.items[3581] == 0 and z.items[21803] == 1, a)
T.check("yeo: no second gloo", has(yeo:say(z, "gloo"), "You don't need any gloo now"))
yeo:bye(z)
local y0 = player({ storage = { [S.Gloud] = 2 } })
T.check("yeo greeting", has(yeo:say(y0, "hi"), "Hrm?"))
T.check("yeo hungry", has(yeo:say(y0, "gloo"), "I want shrimp, 10 fresh shrimp at least!"))
yeo:bye(y0)
-- pharmacy and cauldron
T.check("shelf gives farina", OT.searchShelf(z, Position(33614, 31939, 6)) and z.items[21841] == 1 and has(last(z), "You have found glooth farina."))
T.check("shelf: only one at a time", OT.searchShelf(z, Position(33614, 31939, 6)) == false)
OT.searchShelf(z, Position(33614, 31939, 5))
OT.searchShelf(z, Position(33616, 31939, 5))
T.check("shelves give essence and vinegar", z.items[21839] == 1 and z.items[21872] == 1)
T.check("other bookcase opens", OT.searchShelf(z, Position(33612, 31947, 7)) == false)
T.check("cauldron empty", OT.stirBrew(z) == false)
OT.startBrew(z, obj(z, 21803))
T.check("gloo in the cauldron", has(last(z), "<gloop> <gloop gloop>") and z.items[21803] == 0)
T.check("cauldron spots", OT.isCauldron(Position(33622, 31945, 7)) and OT.isCauldron(Position(33621, 31940, 6)) and not OT.isCauldron(Position(33620, 31945, 7)))
local needs, plasmas, stirs = 0, 0, 0
math.randomseed(7)
while (z.items[21876] or 0) == 0 and stirs < 200 do
	stirs = stirs + 1
	OT.stirBrew(z)
	local msg = last(z)
	for id, text in pairs(OT.BREW_NEEDS) do
		if msg == text then
			needs = needs + 1
			OT.addIngredient(z, obj(z, id == 21872 and 21841 or 21872)) -- wrong one first
			T.check("wrong ingredient refused " .. needs, has(last(z), "doesn't need that"))
			z.items[id] = (z.items[id] or 0) + 1
			OT.addIngredient(z, obj(z, id))
			T.check("ingredient accepted " .. needs, has(last(z), "bubbles contentedly"))
		end
	end
	if has(msg, "glooth plasma") then plasmas = plasmas + 1 end
end
T.check("airtight gloo cooked", (z.items[21876] or 0) == 1 and has(last(z), "You have retrieved some airtight gloo."), stirs .. " stirs")
z.items[21840] = 1
local pl = obj(z, 21840)
for _ = 1, 20 do if pl.id == 21840 then OT.shakePlasma(z, pl) end end
T.check("plasma decomposes", pl.id == 3109 and has(last(z), "The mix decomposes."))
zeronex:say(z, "hi")
a = zeronex:say(z, "airtight gloo")
T.check("zeronex takes the gloo, gives cloth and gas bag", has(a, "use this special gas bag at the centre machine") and z.items[21876] == 0 and z.items[21870] == 1 and z.items[21880] == 1 and z.storage[S.Gloud] == 3, a)
zeronex:bye(z)
-- laboratory
T.check("centre machine", OT.isLabCentre(Position(33395, 31981, 12)) and OT.isLabCentre(Position(33394, 31981, 12)))
local bag = obj(z, 21880)
OT.fillGasBag(z, bag)
T.check("gas bag needs calibration", bag.id == 21880 and has(last(z), "not calibrated yet"))
OT.useLabMachine(z, Position(33394, 31967, 12))
T.check("calibrating", has(last(z), "+++ 01 REPORT --- CALIBRATING"))
for _ = 1, 2 do OT.useLabMachine(z, Position(33394, 31967, 12)) end
T.check("machine 1 calibrated (EN message)", last(z) == "+++ 01 REPORT --- CALIBRATION COMPLETE --- VALUES IDEAL +++")
for _ = 1, 3 do OT.useLabMachine(z, Position(33384, 31968, 12)) OT.useLabMachine(z, Position(33381, 31979, 12)) end
T.check("all calibrated", OT.labCalibrated(z))
OT.fillGasBag(z, bag)
T.check("gas bag filled", bag.id == 21881 and z.items[21881] == 1 and last(z) == "You fill some of the gloud into the gas bag.")
T.check("calibration reset", not OT.labCalibrated(z))
T.check("lab machines ignored without the task", OT.useLabMachine(player({}), Position(33394, 31967, 12)) == false)
zeronex:say(z, "hi")
local v1 = math.max(0, z.storage[VP] or 0)
a = zeronex:say(z, "yes")
T.check("zeronex: 3 votes (EN)", has(a, "Finally a fresh gloud sample!") and z.storage[VP] == v1 + 3 and z.storage[S.Gloud] == 4 and z.items[21881] == 0, a)
T.check("zeronex tasks offered", has(zeronex:say(z, "mission"), "{harvesting}"))
-- tasks
a = zeronex:say(z, "retrieving")
T.check("retrieving task", has(a, "fill this gas bag") and z.storage[S.Gloud] == 7 and z.items[21880] == 1, a)
T.check("one task at a time", has(zeronex:say(z, "harvesting"), "Finish your current task first"))
z.items[21880] = 0
z.items[21881] = 1
v1 = z.storage[VP]
T.check("retrieving report: 1 vote", has(zeronex:say(z, "retrieving"), "one step closer") and z.storage[VP] == v1 + 1 and z.storage[S.Gloud] == 4)
a = zeronex:say(z, "concocting")
T.check("concocting task gives gloo and cloth", z.items[21803] == 1 and z.items[21870] == 2 and z.storage[S.Gloud] == 6, a)
z.items[21876] = 1
zeronex:say(z, "concocting")
T.check("concocting report", z.storage[S.Gloud] == 4 and z.storage[VP] == v1 + 2)
zeronex:say(z, "harvesting")
z.items[21819] = 19
T.check("harvesting: 20 needed", has(zeronex:say(z, "harvesting"), "I still need 20"))
z.items[21819] = 20
zeronex:say(z, "harvesting")
T.check("harvesting report", z.storage[S.Gloud] == 4 and z.storage[VP] == v1 + 3 and z.items[21819] == 0)
T.check("zeronex: another airtight cloth", has(zeronex:say(z, "airtight cloth"), "You still have a prototype"))
zeronex:bye(z)
T.check("quest log gloud", has(OT.missionTextBatch4(z, "Gloud"), "harvesting, concocting or retrieving"))
-- Publicity
local pubNpcs = {
	{ "yeo", yeo }, { "nicholas", nicholas }, { "barazbaz", T.load("data-otservbr-global/npc/barazbaz.lua") },
	{ "alaistar", T.load("data-otservbr-global/npc/alaistar.lua") }, { "fayla", T.load("data-otservbr-global/npc/fayla.lua") },
	{ "christine", T.load("data-otservbr-global/npc/christine.lua") },
}
z.items[21870] = 6
for i, entry in ipairs(pubNpcs) do
	entry[2]:say(z, "hi")
	a = entry[2]:say(z, "airtight cloth")
	T.check("publicity: " .. entry[1], z.items[21870] == 6 - i and a ~= "", a)
	entry[2]:bye(z)
end
T.check("Publicity achievement", z.achievements["Publicity"] == true)
pubNpcs[1][2]:say(z, "hi")
T.check("publicity: once per NPC", has(pubNpcs[1][2]:say(z, "airtight cloth"), "already"))
pubNpcs[1][2]:bye(z)

-- Wesley
local wesley = T.load("data-otservbr-global/npc/wesley.lua")
local w = player({ storage = { [R.Rank] = 3 } })
T.check("wesley first greeting (BR)", has(wesley:say(w, "hi"), "Are you the new assistant?"))
a = wesley:say(w, "mission")
T.check("wesley mission", has(a, "A daily routine implies at least three different tasks done.") and w.storage[S.Gloothworms] == 1, a)
T.check("wesley: read the machine first", has(wesley:say(w, "report"), "Please read the analysis code"))
wesley:bye(w)
local machine = OT.WORM_MACHINE
T.check("other data machine ignored", OT.readWormMachine(w, Position(33625, 31896, 12)) == false)
local seen = {}
for round = 1, 3 do
	OT.readWormMachine(w, Position(machine.x - 1, machine.y, machine.z))
	T.check("machine alert " .. round, last(w) == "--- ALERT --- 0001110010110011001 --- ALERT ---" and w.storage[S.Gloothworms] == 2)
	T.check("wesley report greeting " .. round, has(wesley:say(w, "hi"), "what is your {report}?"))
	a = wesley:say(w, "report")
	local task = OT.wormTask(w)
	T.check("task assigned " .. round, task ~= nil and not seen[task.key], a)
	seen[task.key] = true
	T.check("not done yet " .. round, has(wesley:say(w, "report"), "0 of " .. task.need))
	if task.key == "calibrate" then
		for _, f in ipairs(OT.FUNNELS) do OT.useFunnel(w, f, false) end
		T.check("funnels calibrated", has(w.messages[#w.messages - 1], "<squeak> <scrrt> The funnel is correctly calibrated."))
		T.check("funnel twice", OT.useFunnel(w, OT.FUNNELS[1], false) and has(last(w), "already calibrated"))
	elseif task.key == "water" then
		T.check("distil", OT.distilWater(w) and w.items[21838] == 1)
		for _, f in ipairs(OT.FUNNELS) do OT.useFunnel(w, f, true) end
		T.check("funnels watered", has(w.messages[#w.messages - 1], "You pour a measured amount of pure water down the funnel."))
	elseif task.key == "feed" then
		T.check("hoe given", w.items[3455] == 1)
		for _ = 1, 6 do OT.shredFungus(w) end
		T.check("5 doses", w.items[21837] == 5 and has(last(w), "enough fungus powder"))
		local i = 0
		for x = 33647, 33649 do for y = 31851, 31852 do
			i = i + 1
			if i <= 5 then OT.feedTube(w, obj(w, 21837), obj(w, 21826), Position(x, y, 12)) end
		end end
		T.check("tubes fed", (w.items[21837] or 0) == 0 and has(last(w), "last dose"))
	elseif task.key == "rake" then
		T.check("rake given", w.items[3452] == 1)
		T.check("rake outside the farm ignored", OT.rakeTube(w, obj(w, 21826), Position(33600, 31851, 12)) == false)
		for x = 33640, 33649 do OT.rakeTube(w, obj(w, 21827), Position(x, 31860, 12)) end
		T.check("rake: last floss (EN)", last(w) == "That's the last of the excrement floss you had to rake away. Return to Wesley to check the gloothworm data.")
		w.items[3452] = 0
		T.check("rake must come back", has(wesley:say(w, "report"), "buy a new one at {Maro}"))
		w.items[3452] = 1
	end
	local v = math.max(0, w.storage[VP] or 0)
	a = wesley:say(w, "report")
	if round < 3 then
		T.check("task reported " .. round, has(a, "find out what else needs doing") and w.storage[S.Gloothworms] == 1 and (w.items[3455] or 0) == 0 and (w.items[3452] or 0) == 0, a)
	else
		T.check("third task: reward (BR)", has(a, "Here's your reward!") and w.storage[VP] == v + 2 and w.storage[S.Gloothworms] == 7, a)
	end
	wesley:bye(w)
end
wesley:say(w, "hi")
T.check("done for today", has(wesley:say(w, "mission"), "come back tomorrow"))
wesley:bye(w)
T.check("quest log worms", has(OT.missionTextBatch4(w, "Gloothworms"), "three tasks"))
OT.kv(w):set("worm-day", "2000-01-01")
wesley:say(w, "hi")
T.check("next day", w.storage[S.Gloothworms] == 1 and has(wesley:say(w, "mission"), "You know what to do"))
wesley:bye(w)
local wl = player({ storage = { [R.Rank] = 2 } })
wesley:say(wl, "hi")
T.check("wesley: citizens only", has(wesley:say(wl, "mission"), "citizens of Rathleton"))
wesley:bye(wl)

T.finish()
