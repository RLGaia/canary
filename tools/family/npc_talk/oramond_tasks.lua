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

T.finish()
