-- Gaia Family server: The Dream Courts Quest check (2026-11-23). One character talks to Myzzi, Vanys,
-- Undal, Andrew Lyze, Stricken Soul and the two arena elves with the lines of the TibiaWiki EN spoiler,
-- the EN transcripts and the TibiaWiki BR pages (world steps set as storages or items).
-- Run from the repository root:
--   luajit tools/family/npc_talk/dream_courts.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z, sendMagicEffect = function() end } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
CONST_ME_POFF = CONST_ME_POFF or 3
dofile("data-otservbr-global/lib/others/family_dream_courts.lua")
local D = FamilyDreamCourts
local DC = D.DC
local UR = DC.UnsafeRelease

local function player(o)
	local p = T.player(o)
	p.achievements, p.outfits, p.exp = {}, {}, 0
	rawset(p, "addAchievement", function(self, name) self.achievements[name] = true return true end)
	rawset(p, "addOutfit", function(self, lt) self.outfits[lt] = self.outfits[lt] or 0 end)
	rawset(p, "addOutfitAddon", function(self, lt, a) if self.outfits[lt] then self.outfits[lt] = bit.bor(self.outfits[lt], a) end end)
	rawset(p, "hasOutfit", function(self, lt, a)
		local have = self.outfits[lt]
		if not have then return false end
		return a == nil or a == 0 or bit.band(have, a) == a
	end)
	rawset(p, "addExperience", function(self, n) self.exp = self.exp + n end)
	rawset(p, "getItemById", function(self, id)
		if (self.items[id] or 0) < 1 then return nil end
		local pl = self
		return { itemid = id, transform = function(it, newId)
			pl.items[id] = pl.items[id] - 1
			pl.items[newId] = (pl.items[newId] or 0) + 1
			it.itemid = newId
		end }
	end)
	return p
end
local function plain(s) return ((s or ""):gsub("[{}]", "")) end
local function has(text, s) return text ~= nil and plain(text):find(plain(s), 1, true) ~= nil end

local p = player({ money = 0, bank = 500000, name = "Tester" })

-- ------------------------------------------------------------------ Myzzi
local myzzi = T.load("data-otservbr-global/npc/myzzi.lua")
T.check("Myzzi greeting (EN, BR)", plain(myzzi:say(p, "hi")) == "Hello adventurer. It is good to see you.")
local a = myzzi:say(p, "entrances")
T.check("'entrances' straight away (EN method)", plain(a) == "So, are you willing to help in this time of need?", a)
a = myzzi:say(p, "no")
T.check("'no' (BR)", plain(a) == "Oh no, oh no! What a pity! Please reconsider!", a)
a = myzzi:say(p, "threat")
T.check("'threat' (EN)", has(a, "I know only little and I forget so much.") and has(a, "They will be able to tell you more about the issue."), a)
a = myzzi:say(p, "courts")
T.check("'courts' (EN)", has(a, "There are entrances to the hidden Courts") and has(a, "Find Undal or Vanys and talk to them."), a)
myzzi:say(p, "entrances")
a = myzzi:say(p, "yes")
T.check("'yes' starts the quest (EN)", plain(a) == "You are a true hero! Here, take my enchantment and you will be able to pass the portals. Now hurry, my friends are waiting." and p.storage[DC.Main.Questline] == 1, a)
a = myzzi:say(p, "bye")
T.check("farewell (EN, BR)", plain(a) == "Goodbye, Tester.", a)
T.check("later greeting (EN, BR)", plain(myzzi:say(p, "hi")) == "Hello adventurer. I'm so happy that you agreed to help!")
myzzi:say(p, "bye")

-- ------------------------------------------------------------------ Vanys
local vanys = T.load("data-otservbr-global/npc/vanys.lua")
T.check("Vanys greeting (EN)", plain(vanys:say(p, "hi")) == "Greetings hero. I guess you came to talk.")
a = vanys:say(p, "task")
T.check("'task' straight away (EN transcript)", has(a, "You have to empower eight ward stones.") and has(a, "But you have to find out on yourself what to do with those stones.") and p.items[D.TALISMAN] == 1 and p.storage[DC.WardStones.Questline] == 1 and p.storage[DC.Main.TheSummerCourt] == 1, a)
p.items[D.TALISMAN] = 0
a = vanys:say(p, "lost")
T.check("'lost' gives a new talisman (EN)", p.items[D.TALISMAN] == 1, a)
a = vanys:say(p, "talk")
T.check("'talk' (EN)", plain(a) == "So do you want to learn the story behind of this or rather talk about the task at hand?", a)
a = vanys:say(p, "story")
T.check("'story' (EN)", plain(a) == "Do you prefer the long version or the short version?", a)
a = vanys:say(p, "long")
T.check("long story part 1 (EN)", has(a, "Though the dreamborn have many similarities") and has(a, "All that is known, is that he was a exceptional dreamweaver.") and has(a, "Do you wish me to continue?"), a)
local parts = { "It is unclear if he simply went away", "The greatest of their kind lost their lives", "Making its lair in the festering wound", "When they finally united to fight the threat", "The wounded beast was bound and trapped", "So they came up with a plan" }
for i, first in ipairs(parts) do
	a = vanys:say(p, "continue")
	T.check("long story part " .. (i + 1) .. " (EN)", has(a, first), a)
end
T.check("long story ends with the question (EN)", has(a, "So do you want me to tell you more about the story behind of this or rather talk about the task at hand?"), a)
a = vanys:say(p, "short")
T.check("'short' (EN, BR)", has(a, "You will have to re-empower several wardstones") and has(a, "There the nightmare beast can be challenged and defeated."), a)
p.storage[DC.WardStones.Count] = 5
a = vanys:say(p, "task")
T.check("stones missing (ours)", has(a, "You have empowered 5 of the eight ward stones so far."), a)
p.storage[DC.WardStones.Count] = 8
a = vanys:say(p, "task")
T.check("seven keys (EN)", has(a, "You empowered all eight ward stones. Well done!") and has(a, "Only then you will be able to enter the Nightmare Beast's lair.") and p.storage[DC.WardStones.Questline] == 2 and p.storage[DC.TheSevenKeys.Questline] == 1, a)
a = vanys:say(p, "keys")
T.check("'keys' (EN)", plain(a) == "They are not literally keys but rather puzzles you have to solve or a secret mechanism you have to discover in order to open the Dream Doors. A parchment in the chest here can tell you more about it.", a)
vanys:say(p, "bye")

-- Undal reports for a Summer Court character (EN: "report about your task to either Vanys or Undal").
local undal = T.load("data-otservbr-global/npc/undal.lua")
undal:say(p, "hi")
undal:say(p, "story")
a = undal:say(p, "long")
T.check("Undal's own words (EN transcript)", has(a, "All that is known is, that he was an exceptional dreamweaver."), a)
undal:say(p, "continue")
a = undal:say(p, "continue")
T.check("Undal 'there were no open hostilities' (EN)", has(a, "there were no open hostilities") and has(a, "and it was hungry for more"), a)
p.storage[DC.WardStones.Questline] = 3 -- the Nightmare Beast is slain (server test)
a = undal:say(p, "task")
T.check("reward (EN)", plain(a) == "The Nightmare Beast is slain. You have done well. The Courts of Summer and Winter will be forever grateful. For your efforts I want to reward you with our traditional dream warrior outfit. May it suit you well!" and p.outfits[1146] and p.outfits[1147] and p.achievements["Dream Catcher"] and p.storage[DC.WardStones.Questline] == 4, a)
a = undal:say(p, "task")
T.check("no second reward (ours)", plain(a) == "The Courts of Summer and Winter will be forever grateful." and p.storage[DC.WardStones.Questline] == 4, a)
a = undal:say(p, "addon")
T.check("'addon' (EN, BR)", plain(a) == "Are you interested in one or two addons to your dream warrior outfit?", a)
a = undal:say(p, "yes")
T.check("addon offer (EN, BR)", plain(a) == "I provide two addons. For the first one I need you to bring me five pomegranates. For the second addon you need an ice shield. Do you want one of these addons?", a)
a = undal:say(p, "yes")
T.check("which addon (EN, BR)", plain(a) == "What do you have for me: the pomegranates or the ice shield?", a)
a = undal:say(p, "pomegranate")
T.check("no pomegranates", plain(a) == "You do not have enough items.", a)
p.items[D.POMEGRANATE] = 5
undal:say(p, "addon") undal:say(p, "yes") undal:say(p, "yes")
a = undal:say(p, "pomegranate")
T.check("pomegranates = first addon (EN, BR)", plain(a) == "Very good! You gained the first addon to the dream warrior outfit." and p:hasOutfit(1146, 1) and not p:hasOutfit(1146, 2) and p.items[D.POMEGRANATE] == 0 and not p.achievements["Dream Warrior"], a)
p.items[D.ICE_SHIELD] = 1
undal:say(p, "addon") undal:say(p, "yes") undal:say(p, "yes")
a = undal:say(p, "ice shield")
T.check("ice shield = second addon and Dream Warrior (EN, BR)", plain(a) == "Very good! You gained the second addon to the dream warrior outfit." and p:hasOutfit(1146, 2) and p.achievements["Dream Warrior"], a)
undal:say(p, "bye")

-- ------------------------------------------------------------------ Andrew Lyze
local q = player({ money = 0, bank = 500000 })
local andrew = T.load("data-otservbr-global/npc/andrew_lyze.lua")
a = andrew:say(q, "hi")
T.check("Andrew greeting (EN)", plain(a) == "Hello, I am the warden of this monument. The sarcophagus in front of you was established to prevent people from going down there. But I doubt that this step is sufficient.", a)
a = andrew:say(q, "sarcophagus")
T.check("'sarcophagus' without 'deep' first (EN)", has(a, "This sarcophagus seals the entrance"), a)
a = andrew:say(q, "down")
T.check("'down' (EN)", has(a, "On first glance, this cave does not look very spectacular"), a)
a = andrew:say(q, "depths")
T.check("'depths' (EN)", plain(a) == "As far as I know it is a place of helish heat with bloodthirsty monsters of all kinds.", a)
a = andrew:say(q, "materials")
T.check("'materials' (EN)", has(a, "50 blue glas plates, 15 green glas plates and 5 violet glas plates.") and q.storage[UR.Questline] == 1, a)
andrew:say(q, "compass")
a = andrew:say(q, "sell")
T.check("'sell' (EN)", plain(a) == "Would you like to buy a broken compass for 10.000 gold?", a)
a = andrew:say(q, "yes")
T.check("broken compass bought (EN)", plain(a) == "Here's your broken compass!" and q.items[D.BROKEN_COMPASS] == 1 and q.bank == 490000, a)
andrew:say(q, "bye")
a = andrew:say(q, "hi")
T.check("greeting after 'materials' (EN)", plain(a) == "Well, let's see if your mission was successful. Just bring me all needed materials.", a)
q.items[D.GLASS.blue], q.items[D.GLASS.green] = 50, 15 -- no violet plates
andrew:say(q, "materials")
a = andrew:say(q, "yes")
T.check("every material is needed (upstream bug)", plain(a) == "You don't have the needed items yet." and q.storage[UR.Questline] == 1 and q.items[D.GLASS.blue] == 50, a)
q.items[D.GLASS.violet] = 5
a = andrew:say(q, "materials")
T.check("'materials' asks (EN)", plain(a) == "May I repair your compass if possible?", a)
a = andrew:say(q, "yes")
T.check("repair (EN)", has(a, "Alright, I put the glasses into the right pattern") and has(a, "Are you ready to do that?") and q.items[D.CHARGEABLE_COMPASS] == 1 and q.items[D.BROKEN_COMPASS] == 0 and q.items[D.GLASS.violet] == 0 and q.storage[UR.Questline] == 2, a)
a = andrew:say(q, "yes")
T.check("axe and bait (EN)", has(a, "take this golden axe") and has(a, "the effect won't last forever!") and q.items[D.GOLDEN_AXE] == 1 and D.baitActive(q), a)
a = andrew:say(q, "bait")
T.check("bait still active", plain(a) == "You're already with my bait!", a)
q.storage[D.S.BaitUntil] = os.time() - 1
a = andrew:say(q, "bait")
T.check("bait again for 5,000 gold (EN)", has(a, "for 5000 gold?"), a)
a = andrew:say(q, "yes")
T.check("bait paid", D.baitActive(q) and q.bank == 485000, a)
a = andrew:say(q, "unleash")
T.check("unleash without crystals", plain(a) == "You don't have the needed items yet." and q.storage[UR.Questline] == 2, a)
q.items[D.CRYSTAL[1]], q.items[D.CRYSTAL[2]], q.items[D.CRYSTAL[3]], q.items[D.POISON_GLAND] = 5, 3, 1, 1
a = andrew:say(q, "unleash")
T.check("unleash (EN)", has(a, "the compass is now pulsating in a warm, violet colour.") and q.items[D.COMPASS[3]] == 1 and q.items[D.CHARGEABLE_COMPASS] == 0 and q.storage[UR.Questline] == 3, a)
andrew:say(q, "bye")
q.storage[UR.Questline] = 4 -- the chest was opened (server test)
a = andrew:say(q, "hi")
T.check("report and 50,000 experience (BR)", has(a, "Nice to see that the charged compass works properly.") and q.exp == 50000 and q.storage[UR.Questline] == 5, a)
a = andrew:say(q, "charge")
T.check("'charge' (ours)", has(a, "blue, green or violet"), a)
a = andrew:say(q, "green")
T.check("green fee (EN, BR)", has(a, "a green crystal and 50000 gold"), a)
a = andrew:say(q, "yes")
T.check("no uncharged compass", has(a, "without a charge"), a)
q.items[D.COMPASS[3]], q.items[D.CHARGEABLE_COMPASS], q.items[D.CRYSTAL[2]] = 0, 1, 1
andrew:say(q, "charge") andrew:say(q, "green")
a = andrew:say(q, "yes")
T.check("green charge", q.items[D.COMPASS[2]] == 1 and q.items[D.CRYSTAL[2]] == 0 and q.bank == 435000, a)
andrew:say(q, "bye")

-- ------------------------------------------------------------------ Stricken Soul
local soul = T.load("data-otservbr-global/npc/stricken_soul.lua")
local r = player({ name = "Tester" })
a = soul:say(r, "hi")
T.check("Stricken Soul greeting (EN, BR)", has(a, "Do you believe me?"), a)
a = soul:say(r, "name")
T.check("'name' (BR)", plain(a) == "I am... I was... I... it was such a looooong time ago.", a)
a = soul:say(r, "job")
T.check("'job' (BR)", has(a, "I was a... traveller. Yeeeees. A scholar!"), a)
a = soul:say(r, "yes")
T.check("first yes (EN)", has(a, "Will you take care of the... ghosts?"), a)
a = soul:say(r, "yes")
T.check("second yes (EN)", has(a, "What was your... naaaaaame again, tell me?"), a)
a = soul:say(r, "yes")
T.check("'yes' is not a name (EN)", plain(a) == "That is noooooot your name... tell me your naaaaaame!", a)
a = soul:say(r, "Tester")
T.check("name (EN)", has(a, "Ah yeeeeees, Tester... I will remember you.") and has(a, "eliminate all remainders there if you must, Tester.") and r.storage[DC.HauntedHouse.Questline] == 1, a)
a = soul:say(r, "bye")
T.check("farewell (BR)", plain(a) == "Faaaaare thee well.", a)

-- ------------------------------------------------------------------ arena
local summer = T.load("data-otservbr-global/npc/shirtalis_of_the_summer_court.lua")
local winter = T.load("data-otservbr-global/npc/farhilorn_of_the_winter_court.lua")
local s = player()
summer:say(s, "hi")
a = summer:say(s, "fight")
T.check("arena needs the seven keys (ours)", has(a, "Only those who passed the Seven Dream Doors"), a)
s.storage[DC.TheSevenKeys.Questline] = 2
s.storage[DC.Main.TheWinterCourt] = 1 -- a Winter Court character fights for summer (EN, BR)
a = summer:say(s, "fight")
T.check("'fight' (upstream line)", has(a, "We allow able champions of all races"), a)
a = summer:say(s, "yes")
T.check("joins the Summer side", plain(a) == "You are now able to enter the teleport." and s.storage[DC.DreamScar.Permission] == 1 and s.storage[D.S.ArenaSide] == 1, a)
a = summer:say(s, "boss")
T.check("boss of the day (ours)", has(a, "Today's champion of the arena is " .. D.bossOfTheDay().name), a)
summer:say(s, "bye")
winter:say(s, "hi")
winter:say(s, "fight")
winter:say(s, "yes")
T.check("changes to the Winter side", s.storage[D.S.ArenaSide] == 2)
for _ = 1, 20 do D.arenaWin(s) end
T.check("Champion of Winter after 20 wins (EN)", s.achievements["Champion of Winter"] and not s.achievements["Champion of Summer"])
winter:say(s, "bye")

-- ------------------------------------------------------------------ boss of the day
local seen, order = {}, {}
local t0 = os.time({ year = 2026, month = 11, day = 23, hour = 12 })
for d = 0, 9 do
	local b = D.bossOfTheDay(t0 + d * 86400).name
	order[#order + 1] = b
end
local wiki = { "Plagueroot", "Malofur Mangrinder", "Maxxenius", "Alptramun", "Izcandar the Banished" }
local ok = true
local start
for i, n in ipairs(wiki) do if n == order[1] then start = i end end
for d = 1, 10 do
	if order[d] ~= wiki[(start + d - 2) % 5 + 1] then ok = false end
end
T.check("arena bosses in the wiki order, one per day", ok, table.concat(order, ", "))
T.check("the day starts at 06:00", D.bossOfTheDay(os.time({ year = 2026, month = 11, day = 24, hour = 5, min = 59 })).name == D.bossOfTheDay(os.time({ year = 2026, month = 11, day = 23, hour = 12 })).name
	and D.bossOfTheDay(os.time({ year = 2026, month = 11, day = 24, hour = 6, min = 1 })).name ~= D.bossOfTheDay(os.time({ year = 2026, month = 11, day = 23, hour = 12 })).name)

T.finish()
