-- Gaia Family server: The Shattered Isles Quest ("Meriana Quest") check (2026-11-17).
-- One character through the whole quest with the TibiaWiki BR backup's lines (Eleonore, Charlotta,
-- Captain Waverider, Raymond Striker, Marina, Ocelus, Ariella, Karl, Morgan, Eremo, Duncan, Chondur,
-- Sandra, Sebastian, Vulturenose, Klaus), the BR route that skips Ray and Marina, Duncan's egg
-- before and after the catapult, the lost letter and whisper beer, Chondur's "no" and the quest
-- log states. The map objects (plans, nests, turtle, mushrooms, catapult) are checked in the
-- self-test. Run from the repository root:
--   luajit tools/family/npc_talk/shattered_isles.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
dofile("data-otservbr-global/lib/others/family_shattered_isles.lua")
dofile("data-otservbr-global/lib/others/family_pilgrimage.lua") -- Eremo is a pilgrimage priest
string.titleCase = string.titleCase or function(s)
	return (s:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end))
end
local SI = Storage.Quest.U7_8.TheShatteredIsles

local function player(o)
	local p = T.player(o)
	p.achievements = {}
	rawset(p, "addAchievement", function(self, name) self.achievements[#self.achievements + 1] = name return true end)
	rawset(p, "hasOutfit", function() return false end)
	rawset(p, "addOutfit", function(self, id) self.outfits = (self.outfits or 0) + 1 end)
	return p
end

local function plain(text) return ((text or ""):gsub("[{}]", "")) end
local function has(text, s) return plain(text):find(s, 1, true) ~= nil end
local function rep(p) return p.storage[SI.ReputationInSabrehaven] or -1 end

local npcs = {}
for _, name in ipairs({ "eleonore", "charlotta", "captain_waverider", "raymond_striker", "marina", "ocelus", "ariella", "karl", "morgan", "eremo", "duncan", "chondur", "sandra", "sebastian", "vulturenose", "klaus" }) do
	npcs[name] = T.load("data-otservbr-global/npc/" .. name .. ".lua")
end

local function talk(p, name, lines)
	local out = {}
	for _, line in ipairs(lines) do
		out[#out + 1] = npcs[name]:say(p, line) or ""
	end
	npcs[name]:say(p, "bye")
	return out
end

-- Eleonore's Requests ---------------------------------------------------------------------------
local p = player({ money = 100000, level = 50 })
local e = talk(p, "eleonore", { "hi", "ring" })
T.check("Eleonore: ring story (BR)", has(e[2], "My ring was stolen by a parrot") and has(e[2], "you might need a rake"), e[2])
T.check("Governor's Daughter 1", p.storage[SI.TheGovernorDaughter] == 1)
p.storage[SI.TheGovernorDaughter] = 2 -- the rake on the parrot's tree (self-test)
p.items[6093] = 1
e = talk(p, "eleonore", { "hi", "ring", "yes", "yes", "yes" })
T.check("Eleonore: ring returned (BR)", has(e[2], "Have you found it and want to return it to me?") and has(e[3], "Take this gold as a reward"), e[3])
T.check("Eleonore: errand (BR)", has(e[5], "deliver these 200 gold pieces to the herbalist Charlotta"), e[5])
T.check("ring taken, errand 1", p.items[6093] == 0 and p.storage[SI.TheErrand] == 1)
local c = talk(p, "charlotta", { "hi", "gold", "yes" })
T.check("Charlotta: peg leg (BR)", has(c[3], "tell her the secret password: 'peg leg'"), c[3])
e = talk(p, "eleonore", { "hi", "errand", "peg leg", "yes" })
T.check("Eleonore: 5 gold (BR)", has(e[2], "here are your 5 gold pieces"), e[2])
T.check("Eleonore: Ray's story (BR)", has(e[4], "tell him the secret word 'peg leg'"), e[4])
T.check("Access to Meriana", p.storage[SI.AccessToMeriana] == 1)
local w = talk(p, "captain_waverider", { "hi", "peg leg", "yes" })
T.check("Waverider: you know where (BR)", has(w[2], "I sail you to") and p.teleported and p.teleported.x == 32346, w[2])

-- The Seawitch / A Djinn in Love ------------------------------------------------------------------
local r = talk(p, "raymond_striker", { "hi", "mission", "eleonore", "mermaid" })
T.check("Ray enchanted: silly missions", has(r[2], "Don't ask about silly missions"), r[2])
T.check("Ray: Eleonore vaguely (BR)", has(r[3], "Yes, I remember her... vaguely"), r[3])
T.check("Ray: mermaid (BR)", has(r[4], "The mermaid is the most beautiful creature"), r[4])
T.check("Poem for the Mermaid 1", p.storage[SI.APoemForTheMermaid] == 1)
r = talk(p, "raymond_striker", { "hi", "mermaid" })
T.check("Ray still enchanted after a second mermaid (no 'ashamed')", has(r[2], "most beautiful creature") and not has(r[2], "ashamed"), r[2])
local m = talk(p, "marina", { "hi", "raymond striker" })
T.check("Marina: crush (BR)", has(m[2], "I think he has a crush on me"), m[2])
T.check("Poem for the Mermaid 2", p.storage[SI.APoemForTheMermaid] == 2)
local o = talk(p, "ocelus", { "hi", "mermaid", "date", "yes" })
T.check("Ocelus: mermaid without eleonore first (BR route)", has(o[2], "I noticed that lovely mermaid"), o[2])
T.check("Ocelus: ask Marina (BR)", has(o[3], "Will you ask the mermaid Marina") and has(o[4], "a human granting a djinn a wish"), o[4])
T.check("Djinn in Love 1", p.storage[SI.ADjinnInLove] == 1)
m = talk(p, "marina", { "hi", "date" })
T.check("Marina: more poetic (BR)", has(m[2], "A true Djinn would have done something more poetic"), m[2])
o = talk(p, "ocelus", { "hi", "mermaid" })
T.check("Ocelus: love poem (BR)", has(o[2], "Please get me a love poem"), o[2])
p.items[6119] = 1
o = talk(p, "ocelus", { "hi", "love poem", "yes" })
T.check("Ocelus: recite spell (BR)", has(o[3], "recite the poem like a true elven poet"), o[3])
r = talk(p, "raymond_striker", { "hi", "mission" })
T.check("Ray still enchanted after the poem, before the date", has(r[2], "silly missions") and rep(p) < 1, r[2])
m = talk(p, "marina", { "hi", "date" })
T.check("Marina: date accepted, turtles (BR)", has(m[2], "This lovely, exotic Djinn is a true poet") and has(m[2], "ride my sea turtles"), m[2])
T.check("Laguna access + Matchmaker", p.storage[SI.AccessToLagunaIsland] == 1 and p.achievements[1] == "Matchmaker")
o = talk(p, "ocelus", { "hi", "marina", "raymond striker" })
T.check("Ocelus after the date (EN transcript)", has(o[2], "arranged a date already") and has(o[3], "I hope this human is forgotten soon"), o[3])

-- Meriana's friendship -----------------------------------------------------------------------------
r = talk(p, "raymond_striker", { "hi", "mermaid", "mission" })
T.check("Ray: ashamed after the date (BR)", has(r[2], "I am deeply ashamed"), r[2])
T.check("Ray: ask around (BR)", has(r[3], "Ask around in the settlement") and rep(p) == 1, r[3])
local a = talk(p, "ariella", { "hi", "mission" })
T.check("Ariella: 100 breads (BR)", has(a[2], "Bring me 100 breads") and rep(p) == 2, a[2])
p.items[3600] = 100
a = talk(p, "ariella", { "hi", "mission", "yes", "mission" })
T.check("Ariella: breads taken (BR)", has(a[3], "adequate supply is ensured") and p.items[3600] == 0, a[3])
T.check("Ariella: whisper beer (BR)", has(a[4], "Bring me a sample of the whisper beer") and rep(p) == 4, a[4])
local k = talk(p, "karl", { "hi", "whisper beer", "yes" })
T.check("Karl: whisper beer 80 gold (BR)", has(k[2], "finest whisper beer for 80 gold") and has(k[3], "Don't take it into the city") and p.items[6106] == 1 and rep(p) == 5, k[3])
p.items[6106] = 0 -- lost it
k = talk(p, "karl", { "hi", "whisper beer", "yes" })
T.check("Karl: another bottle when lost", p.items[6106] == 1 and rep(p) == 5, k[2])
k = talk(p, "karl", { "hi", "whisper beer" })
T.check("Karl: no second bottle while carrying one", not has(k[2], "80 gold"), k[2])
a = talk(p, "ariella", { "hi", "mission", "yes" })
T.check("Ariella: beer taken (BR)", has(a[3], "I will test this beauty in privacy") and rep(p) == 6, a[3])
local mo = talk(p, "morgan", { "hi", "mission", "yes" })
T.check("Morgan: letter (BR)", has(mo[2], "the old sage Eremo lives on the isle Cormaya") and has(mo[3], "take this letter") and p.items[3506] == 1 and rep(p) == 7, mo[3])
mo = talk(p, "morgan", { "hi", "mission" })
T.check("Morgan: reminder while carrying it (ours)", has(mo[2], "Please deliver my letter"), mo[2])
p.items[3506] = 0 -- lost
mo = talk(p, "morgan", { "hi", "mission", "yes" })
T.check("Morgan: new letter when lost (ours)", has(mo[2], "You lost my letter?") and p.items[3506] == 1 and rep(p) == 7, mo[2])
local er = talk(p, "eremo", { "hi", "letter" })
T.check("Eremo: letter (BR)", has(er[2], "A letter from that youngster Morgan?") and rep(p) == 8, er[2])
mo = talk(p, "morgan", { "hi", "mission" })
T.check("Morgan: thanks (BR)", has(mo[2], "Thank you for delivering my letter to Eremo") and rep(p) == 9, mo[2])
local d = talk(p, "duncan", { "hi", "mission" })
T.check("Duncan: atlas (BR)", has(d[2], "I need a new quality atlas") and rep(p) == 10, d[2])
p.items[6108] = 1
d = talk(p, "duncan", { "hi", "mission", "yes" })
T.check("Duncan: atlas taken (BR)", has(d[3], "what a fine work") and rep(p) == 11, d[3])
local ch = talk(p, "chondur", { "hi", "mission" })
T.check("Chondur: five dolls (BR)", has(ch[2], "I need at least five of their pirate voodoo dolls") and rep(p) == 12, ch[2])
p.items[5810] = 5
for i = 1, 4 do
	ch = talk(p, "chondur", { "hi", "mission", "yes" })
	T.check("Chondur: doll " .. i .. " (BR)", has(ch[2], "Did you bring one of the required pirate voodoo dolls?") and has(ch[3], "weaken that curse a bit") and p.items[5810] == 5 - i, ch[3])
end
ch = talk(p, "chondur", { "hi", "mission", "yes" })
T.check("Chondur: last doll (BR)", has(ch[2], "the last of the required voodoo dolls") and has(ch[3], "put an end to that curse") and p.items[5810] == 0, ch[3])
T.check("Friendly (14)", rep(p) == 14, rep(p))

-- Duncan's egg before the catapult ------------------------------------------------------------------
local se = talk(p, "sebastian", { "hi", "nargor" })
T.check("Sebastian: no Nargor before access", has(se[2], "I only sail there") and not has(se[2], "50"), se[2])
d = talk(p, "duncan", { "hi", "mission", "yes" })
T.check("Duncan: egg mission at Friendly (BR)", has(d[2], "start considering you as one of us") and has(d[3], "bring me at least one of them"), d[3])
T.check("egg mission gives Nargor access", p.storage[SI.AccessToNargor] == 1 and p.storage[SI.TortoiseEggNargorDoor] == 1)
se = talk(p, "sebastian", { "hi", "nargor" })
T.check("Sebastian: Nargor with access", has(se[2], "sail Nargor") and has(se[2], "50"), se[2])
p.items[6125] = 1
d = talk(p, "duncan", { "hi", "mission", "yes" })
T.check("Duncan: egg taken (BR)", has(d[3], "A real tortoise egg") and p.storage[SI.TortoiseEggNargorDoor] == 2 and rep(p) == 14, d[3])

-- Ray's missions -------------------------------------------------------------------------------------
r = talk(p, "raymond_striker", { "hi", "mission" })
T.check("Ray mission 1 (BR)", has(r[2], "substance called Fafnar's Fire") and p.storage[SI.RaysMission1] == 1, r[2])
local sa = talk(p, "sandra", { "hi", "fafnar's fire", "yes", "your continued existence is payment enough" })
T.check("Sandra: the stuff (BR)", has(sa[2], "So they have sent you to get... the stuff?") and has(sa[3], "all the crystal coins I demanded"), sa[3])
T.check("Sandra: enraged (BR)", has(sa[4], "How dare you?!") and p.storage[SI.RaysMission1] == 2, sa[4])
r = talk(p, "raymond_striker", { "hi", "mission", "mission" })
T.check("Ray: mission accomplished (BR)", has(r[2], "mission accomplished") and rep(p) == 15, r[2])
T.check("Ray mission 2 (BR)", has(r[3], "It is a sabotage mission") and p.storage[SI.RaysMission2] == 1, r[3])
-- the catapult (fire bug, self-test) sets mission 2 to 2 and the reputation to 16
p.storage[SI.RaysMission2] = 2
FamilyShatteredIsles.raiseReputation(p, 16)
r = talk(p, "raymond_striker", { "hi", "mission", "mission" })
T.check("Ray: you did it (BR) after the egg", has(r[2], "You did it! Excellent!") and rep(p) == 18, r[2])
T.check("Ray mission 3 (BR)", has(r[3], "infiltrate their base") and p.storage[SI.RaysMission3] == 1, r[3])
CONST_SLOT_HEAD, CONST_SLOT_ARMOR, CONST_SLOT_LEGS, CONST_SLOT_FEET = CONST_SLOT_HEAD or 1, CONST_SLOT_ARMOR or 4, CONST_SLOT_LEGS or 7, CONST_SLOT_FEET or 8
local slots = { [CONST_SLOT_HEAD] = 6096, [CONST_SLOT_ARMOR] = 6095, [CONST_SLOT_LEGS] = 5918, [CONST_SLOT_FEET] = 5461 }
local v = talk(p, "vulturenose", { "hi", "enter" })
T.check("Vulturenose: not a pirate without the set (upstream)", has(v[2], "YOU WILL NOT PASS"), v[2])
rawset(p, "getSlotItem", function(_, slot) return slots[slot] and { itemid = slots[slot] } or nil end)
v = talk(p, "vulturenose", { "hi", "enter" })
T.check("Vulturenose: dashing pirate (BR)", has(v[2], "dashing pirate") and p.storage[SI.YavernDoor] == 1, v[2])
r = talk(p, "raymond_striker", { "hi", "mission" })
T.check("Ray waits for the three plans", not has(r[2], "Well done"), r[2])
p.storage[SI.TavernMap1], p.storage[SI.TavernMap2], p.storage[SI.TavernMap3] = 1, 1, 1 -- self-test
r = talk(p, "raymond_striker", { "hi", "mission" })
T.check("Ray mission 4 (BR)", has(r[2], "Klaus, the owner of the tavern, wants me dead") and rep(p) == 20 and p.storage[SI.RaysMission4] == 1, r[2])
local kl = talk(p, "klaus", { "hi", "mission" })
T.check("Klaus: kill Striker (BR)", has(kl[1], "Ho matey") and has(kl[2], "bring me his lucky pillow") and p.storage[SI.RaysMission4] == 2, kl[2])
r = talk(p, "raymond_striker", { "hi", "mission" })
T.check("Ray: pillow (BR)", has(r[2], "My pillow??") and p.items[6105] == 1, r[2])
kl = talk(p, "klaus", { "hi", "mission", "yes" })
T.check("Klaus: party (BR)", has(kl[3], "lets have a PAAAAAARTY") and p.storage[SI.RaysMission4] == 4, kl[3])
r = talk(p, "raymond_striker", { "hi", "mission", "outfit" })
T.check("Ray: model ship (BR)", has(r[2], "So take this as your very own ship") and p.items[2994] == 1 and rep(p) == 21, r[2])
T.check("Ray: 'outfit' gives the Pirate Outfit (EN)", has(r[3], "The pirate outfit! Here you go") and p.outfits == 2, r[3])

-- Out of order and recovery cases ---------------------------------------------------------------------
-- BR route: Ocelus straight away, without Ray or Marina
local q = player({ storage = { [SI.AccessToMeriana] = 1 } })
o = talk(q, "ocelus", { "hi", "mermaid", "date", "yes" })
T.check("BR route: Ocelus first", has(o[4], "a human granting a djinn a wish") and q.storage[SI.ADjinnInLove] == 1 and q.storage[SI.DefaultStart] == 1 and q.storage[SI.APoemForTheMermaid] == 2, o[4])
o = talk(player({}), "ocelus", { "hi", "mermaid" })
T.check("Ocelus before Eleonore's peg leg: no date", not has(o[2], "lovely mermaid"), o[2])
-- catapult before the egg, egg after Cordial: reputation never drops
local z = player({ storage = { [SI.ADjinnInLove] = 5, [SI.ReputationInSabrehaven] = 15, [SI.RaysMission1] = 3, [SI.RaysMission2] = 2 } })
r = talk(z, "raymond_striker", { "hi", "mission" })
T.check("sabotage reported without the egg", has(r[2], "You did it! Excellent!") and rep(z) == 18, r[2])
z.items[6125] = 1
talk(z, "duncan", { "hi", "mission", "yes" })
talk(z, "duncan", { "hi", "mission", "yes" })
T.check("egg after Cordial keeps Cordial", z.storage[SI.TortoiseEggNargorDoor] == 2 and rep(z) == 18, rep(z))
-- upstream's old Friendly value 13
local u = player({ storage = { [SI.ADjinnInLove] = 5, [SI.ReputationInSabrehaven] = 13 } })
r = talk(u, "raymond_striker", { "hi", "mission" })
T.check("upstream's 13 still gets mission 1 and shows Friendly", has(r[2], "Fafnar's Fire") and rep(u) == 14, r[2])
-- Chondur: "no" to the counterspell question, then again
local low = player({ level = 34, storage = { [SI.DragahsSpellbook] = 1 } })
ch = talk(low, "chondur", { "hi", "counterspell" })
T.check("Chondur: no counterspell below level 35 (EN)", has(ch[2], "not strong enough") and (low.storage[SI.TheCounterspell] or -1) == -1, ch[2])
local cs = player({ level = 35, storage = { [SI.DragahsSpellbook] = 1 } })
ch = talk(cs, "chondur", { "hi", "counterspell", "no" })
ch = talk(cs, "chondur", { "hi", "counterspell", "yes", "yes" })
T.check("Chondur: counterspell after a 'no' (BR lines)", has(ch[2], "interested in a counterspell") and has(ch[4], "fresh dead black sheep, in that order") and cs.storage[SI.TheCounterspell] == 1, ch[2])
cs.items[6042] = 1 -- a fresh chicken (first 10 seconds)
cs.items[3994] = 1
cs.items[4095] = 1
ch = talk(cs, "chondur", { "hi", "counterspell", "yes", "counterspell", "yes", "counterspell", "yes" })
T.check("Chondur: chicken, rat, black sheep (BR)", has(ch[3], "Your soul shall be protected") and has(ch[5], "You shall face black magic without fear") and has(ch[7], "EVIL POWERS SHALL NOT KEEP YOU ANYMORE"), ch[7])
T.check("counterspell done", cs.storage[SI.TheCounterspell] == 4)

-- Jack Fate (Liberty Bay): Goroma for 500 gold after access (BR and EN)
local jf = T.load("data-otservbr-global/npc/jack_fate.lua")
local j0 = player({ money = 1000 })
local jr = jf:say(j0, "hi"); jr = jf:say(j0, "goroma")
T.check("Jack Fate: Goroma unknown before access (upstream)", has(jr, "Never heard about a place like this"), jr)
jf:say(j0, "bye")
local j1 = player({ money = 1000, storage = { [SI.AccessToGoroma] = 1 } })
jf:say(j1, "hi")
jr = jf:say(j1, "goroma")
T.check("Jack Fate: Goroma for 500 gold (BR/EN)", has(jr, "Goroma for 500 gold"), jr)
jf:say(j1, "bye")

-- Quest log -------------------------------------------------------------------------------------------
local catalog = dofile("data-otservbr-global/lib/core/quests/catalog/025_the_shattered_isles.lua")
local susp = catalog.missions[11]
T.check("log: 4 = whisper beer", susp.states[4]:find("whisper beer", 1, true) ~= nil)
T.check("log: 7 = Morgan", susp.states[7]:find("Morgan asked", 1, true) ~= nil)
T.check("log: 10 = Duncan", susp.states[10]:find("Duncan requested", 1, true) ~= nil)
T.check("log: 12 = Chondur", susp.states[12]:find("Chondur asked", 1, true) ~= nil)
T.check("log: 1 shown after Ray", susp.startValue == 1 and susp.states[1] ~= nil)
T.check("log: Friendly shows 14", catalog.missions[12].startValue == 14 and catalog.missions[12].states[14] ~= nil)

T.finish()
