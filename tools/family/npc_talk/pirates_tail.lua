-- Gaia Family server: A Pirate's Tail check (2026-11-10), part 1: Eustacio's mission, status,
-- location, flintstone and orb, the lore words of the TibiaWiki BR Eustacio page, Pied Piper, the
-- shortcut and the points rules. Run from the repository root:
--   luajit tools/family/npc_talk/pirates_tail.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
dofile("data-otservbr-global/lib/others/family_pirates_tail.lua")
local PT = FamilyPiratesTail
local S = Storage.Quest.U12_60.APiratesTail

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
	return p
end

local npc = T.load("data-otservbr-global/npc/eustacio.lua")
local function has(text, s) return (text:gsub("[{}]", "")):find(s, 1, true) ~= nil end
local function plain(text) return (text:gsub("[{}]", "")) end
local function given(p, id)
	local n = 0
	for _, a in ipairs(p.added) do
		if a[1] == id then n = n + a[2] end
	end
	return n
end

-- before the mission
local p = player({})
local g = npc:say(p, "hi")
T.check("greeting before the mission (BR)", plain(g) == "Hello my friend. What a delight to see you, even on a busy day.", g)
local m = npc:say(p, "mission")
T.check("mission asks (BR)", has(m, "Yes, yes, reports of Pirats came in.") and has(m, "Can you help me defend the cities and coasts against them?"), m)
local y = npc:say(p, "yes")
T.check("yes accepts (BR lines)", has(y, "That lifts a burden off my shoulders.") and has(y, "You also might want to take a pick!") and has(y, "Find them, kill them and destroy their ship!"), y)
T.check("quest line 1", p.storage[S.QuestLine] == 1)
T.check("points 0", p.storage[S.RaidPoints] == 0)
npc:say(p, "bye")

-- during the mission
local g2 = npc:say(p, "hi")
T.check("greeting after accepting (BR)", has(g2, "You can check your status or ask me about the location of the ongoing raids."), g2)
local st = npc:say(p, "status")
T.check("status below 1500 (BR)", has(st, "you would have 0 points by now") and has(st, "if you gather 1500 points"), st)
T.check("location without a raid (BR)", npc:say(p, "location") == "My agents didn't see anything of use yet.")
PT.current = { place = PT.places[2], kind = "land", serial = 1 }
local loc = npc:say(p, "location")
T.check("location names the raid place", has(loc, "east of Thais"), loc)
PT.current = nil
local f = npc:say(p, "flintstone")
T.check("flintstone given", given(p, PT.FLINTSTONE) == 1, f)
local f2 = npc:say(p, "flintstone")
T.check("flintstone only every 30 minutes", given(p, PT.FLINTSTONE) == 1 and has(f2, "come back later"), f2)
npc:say(p, "orb")
T.check("orb given", given(p, PT.ORB) == 1)

-- points
T.check("raid points counted", PT.addPoints(p, 5, 100) == 5 and PT.points(p) == 5)
for _ = 1, 100 do PT.addPoints(p, 5, 100) end
T.check("at most 300 per raid", PT.points(p) == 300, PT.points(p))
PT.addPoints(p, 3, 200)
T.check("a new raid counts again", PT.points(p) == 303)
T.check("hunting does not count before the secret", PT.addPoints(p, 3, nil) == 0)
p.storage[S.RaidPoints] = 1500
local sec = npc:say(p, "status")
T.check("status with 1500 tells the secret (BR)", has(sec, "you reached a score of 1500") and has(sec, "secret passage below Kilmaresh") and has(sec, "use a certain shell lying in the sand"), sec)
T.check("quest line 2", p.storage[S.QuestLine] == 2)
T.check("hunting counts after the secret", PT.addPoints(p, 3, nil) == 3)
T.check("quest log text", has(PT.describe(p), "secret passage"))
npc:say(p, "bye")
p.storage[S.RaidPoints] = 5000
npc:say(p, "hi")
T.check("Pied Piper at 5000 (EN)", p:hasAchievement("Pied Piper"))
npc:say(p, "bye")

-- lore (BR Eustacio page)
local q = player({})
npc:say(q, "hi")
T.check("job (BR)", has(npc:say(q, "job"), "aspiring businessman, that thrives to climb the ladder"))
T.check("aspiring (BR)", has(npc:say(q, "aspiring"), "from the bottom to the top"))
T.check("ladder (BR)", has(npc:say(q, "ladder"), "Venorean trader union"))
T.check("ranks (BR)", has(npc:say(q, "ranks"), "lofty goal"))
T.check("accomplishments (BR)", has(npc:say(q, "accomplishments"), "new kind of pirates"))
T.check("opportunity (BR)", has(npc:say(q, "opportunity"), "still in denial"))
T.check("denial (BR)", has(npc:say(q, "denial"), "foot in the door"))
T.check("threat (BR)", has(npc:say(q, "threat"), "Corym clans that banded together"))
T.check("pirats (BR)", has(npc:say(q, "pirats"), "small armada of ships"))
T.check("armada (BR)", has(npc:say(q, "armada"), "dominate our ships"))
T.check("victory (BR)", has(npc:say(q, "victory"), "rout out their base"))
T.check("disrupt (BR)", has(npc:say(q, "disrupt"), "ruckus amongst them"))
T.check("operations (BR)", has(npc:say(q, "operations"), "one big ship with cannons"))
T.check("society (BR)", has(npc:say(q, "society"), "pool of sharks"))
T.check("sharks (BR)", has(npc:say(q, "sharks"), "not too fond of competition"))
T.check("venore (BR)", has(npc:say(q, "venore"), "ruled by business"))
T.check("name (BR)", npc:say(q, "name") == "I am Eustacio. At your service.")
T.check("time (BR)", npc:say(q, "time") == "It's just the time to make a fortune.")
T.check("flintstone needs the mission", has(npc:say(q, "flintstone"), "help me with my"))
T.check("bye (BR)", has(npc:say(q, "bye"), "Good bye"))

-- shortcut (set by Tik'hi Tak'he later)
local s = player({ storage = { [S.RascacoonShortcut] = 1, [S.QuestLine] = 2 } })
T.check("shortcut greeting (BR)", has(npc:say(s, "hi"), "I'm willing to lend you my boat"))
npc:say(s, "shortcut")
npc:say(s, "yes")
T.check("shortcut takes the player to Rascacoon", s.teleported ~= nil)

T.checkHints(npc, function() return player({ storage = { [S.QuestLine] = 1, [S.RaidPoints] = 0 } }) end, { yes = true, shortcut = true })

-- part 2: Tik'hi Tak'he (TibiaWiki BR NPC page and quest page)
local tik = T.load("data-otservbr-global/npc/tikhi_takhe.lua")
local r = player({})
T.check("Tik'hi greeting before (BR)", plain(tik:say(r, "hi")) == "Hail, visitor! Welcome!")
T.check("trust before the mission", has(tik:say(r, "trust points"), "help with our mission"))
T.check("mission asks (BR)", tik:say(r, "mission") == "Do you want to help our colony, to earn our trust and respect?")
T.check("yes (BR)", has(tik:say(r, "yes"), "Go ahead then. You will get what I like to call 'trust points' for different tasks."))
T.check("state 1, shortcut, quest log", r.storage[S.Rascacoon] == 1 and r.storage[S.RascacoonShortcut] == 1 and r.storage[S.QuestLine] == 1 and r.storage[S.TrustPoints] == 0)
T.check("trust points 0 (BR)", tik:say(r, "trust points") == "No, I don't trust you yet. You have 0 trust points right now.")
T.check("tasks (BR)", has(tik:say(r, "tasks"), "Even back in the Corym caves you might find something useful to do."))
tik:say(r, "bye")
T.check("greeting after (BR)", has(tik:say(r, "hi"), "You can ask me about your 'trust points'!"))
T.check("memory points count", PT.addTrust(r, 5) == 5 and PT.trust(r) == 5)
r.storage[S.TrustPoints] = 1250
local adv = tik:say(r, "trust points")
T.check("1200 offer (BR)", has(adv, "You held out for a long time.") and has(adv, "transforms you into a pirat for fifteen minutes") and has(adv, "Do you want to advance?"), adv)
T.check("advance (BR)", tik:say(r, "yes") == "I hereby name you trusted friend of the Rascoohan people!")
T.check("1200 spent, door, state 2", r.storage[S.TrustPoints] == 50 and r.storage[S.TentuglyDoor] == 1 and r.storage[S.Rascacoon] == 2)
T.check("quest log Rascacoon", has(PT.describeRascacoon(r), "trusted friend"))
T.check("wares before the hideout", has(tik:say(r, "accessories"), "who reached the pirats' hideout"))
r.storage[S.TentuglyKilled] = 1
T.check("accessories list (BR prices)", has(tik:say(r, "accessories"), "raccoon backpack for 15000"))
T.check("decorations list (BR prices)", has(tik:say(r, "wall decorations"), "golden shark trophy for 12000"))
T.check("too few trust points", has(tik:say(r, "shark jaws"), "6000 trust points") and has(tik:say(r, "yes"), "don't have enough"))
r.storage[S.TrustPoints] = 7000
tik:say(r, "shark jaws")
tik:say(r, "yes")
T.check("shark jaws bought", given(r, 35587) == 1 and r.storage[S.TrustPoints] == 1000)
T.check("wisdom (BR)", has(tik:say(r, "wisdom"), "shatter the perception of reality") and #tik:say(r, "yes") > 10)
for _, w in ipairs({ "job", "shaman", "rascacoon", "colony", "pirats", "washingstone", "changed", "ways", "adopted", "aggressive", "mold", "powder", "terrorize", "power", "stopped", "knowledge", "help", "raccoon", "creator", "creation", "unique", "loneliness", "image", "enjoyment", "king" }) do
	local a = tik:say(r, w)
	T.check("Tik'hi " .. w .. " (BR)", #a > 20, a)
end
T.check("bye (BR)", tik:say(r, "bye") == "Farewell!")

local om = T.load("data-otservbr-global/npc/om_wake_naha.lua")
local o = player({})
T.check("Om'Wake greeting (BR)", om:say(o, "hi") == "Hello, traveller! Be welcome!")
T.check("Om'Wake helping (BR)", has(om:say(o, "helping"), "transformation magic to enter my cheese cellar"))
T.check("Om'Wake cheese (BR)", has(om:say(o, "cheese"), "Push as many cheese as you can"))
for _, w in ipairs({ "name", "job", "supplies", "colony", "rascacoon", "ancestors", "settled", "day", "washingstone" }) do
	T.check("Om'Wake " .. w .. " (BR)", #om:say(o, w) > 20)
end
-- Part 2c: Eustacio's Spy Rat, every line of the TibiaWiki EN spoiler transcript in its order
local spy = T.load("data-otservbr-global/npc/eustacios_spy_rat.lua")
local sp = player({ storage = { [S.Rascacoon] = 1 } })
T.check("Spy Rat greeting (EN)", plain(spy:say(sp, "hi")) == "Psssht! Not that loud!")
local spyLines = {
	{ "loud", "Been seen with creatures like thee might cause me loosing my head or even my job. Wouldn't even do so now if ol' Eustacio hadn't sent word an' cheese. ...", "Good for ye', he just recently did. Ye probably made some good progress on his behalf." },
	{ "job", "I am a proud pirate. A hungry proud pirat that isn't treated too well and with a liking to people who pay with good cheese." },
	{ "people", "Eustacio pays me good cheese for my invaluable assistance." },
	{ "assistance", "I got ye entrance to the secret laboratory complex and placed the enchanted rat disguise at the entrance. ...", "So ye can sneak in and sabotage the newest mouldy powder production, which ye should find in some chest in the lab." },
	{ "disguise", "It looks convincing in the dark or from distance. It won't fool anyone from close up, not to mention that the guards get suspicious if they don't smell a rat. ...", "Keep in mind that the magic will run out with time, so don't be too tardy." },
	{ "convincing", "Just stay out of lit areas and keep yer distance from the guards. ...", "If ye are lucky, the glowing bugs that they use as illumination lose their shining for a few moments and ye can use that to yer advantage." },
	{ "advantage", "Ye'll have to be sneaky and resourceful. Use the terrain to yer advantage. Ye might even have to do some climbing. If ye are not agile enough, better bring some parcels." },
}
for _, l in ipairs(spyLines) do
	local a = plain(spy:say(sp, l[1]))
	local ok = true
	for k = 2, #l do
		ok = ok and a:find(l[k], 1, true) ~= nil
	end
	T.check("Spy Rat " .. l[1] .. " (EN)", ok, a)
end
T.check("Spy Rat bye (ours)", spy:say(sp, "bye") == "Off with ye, and quietly!")

T.checkHints(tik, function() return player({ storage = { [S.Rascacoon] = 1, [S.TrustPoints] = 0 } }) end, { yes = true })
T.checkHints(om, function() return player({}) end, {})
T.checkHints(spy, function() return player({}) end, {})
T.finish()
