-- Gaia Family server: Threatened Dreams Quest check (2026-11-22). One character plays Troubled
-- Animals, A Dream Come True and An Unlikely Couple with the lines of the TibiaWiki EN spoiler and
-- the TibiaWiki BR page (world steps set as storages or items), The Fairy Treasure and The Swan
-- Feather Cloak, and asks every lore word of the EN NPC transcripts (family_threatened_dreams_lore.lua).
-- Run from the repository root:
--   luajit tools/family/npc_talk/threatened_dreams.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z, sendMagicEffect = function() end } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
CONST_ME_GIFT_WRAPS = CONST_ME_GIFT_WRAPS or 28
CONST_ME_MAGIC_GREEN = CONST_ME_MAGIC_GREEN or 15
CONST_ME_LOSEENERGY = CONST_ME_LOSEENERGY or 2
dofile("data-otservbr-global/lib/others/family_threatened_dreams_lore.lua")
dofile("data-otservbr-global/lib/others/family_threatened_dreams.lua")
local D = FamilyThreatenedDreams
local S = D.S
local TD = D.TD
local M1, M2, M3 = TD.Mission01[1], TD.Mission02[1], TD.Mission03[1]

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
	rawset(p, "getFreeCapacity", function() return 1000000 end)
	rawset(p, "getItemById", function() return nil end)
	return p
end
local function plain(s) return (s:gsub("[{}]", "")) end
local function has(text, s) return text ~= nil and plain(text):find(plain(s), 1, true) ~= nil end
local function given(p, id)
	local n = 0
	for _, a in ipairs(p.added) do
		if a[1] == id then n = n + a[2] end
	end
	return n
end

-- Every lore word of an NPC answers its EN lines (first and last line checked).
local function checkLore(npcName, talk)
	local p = player()
	talk:say(p, "hi")
	for _, entry in ipairs(FamilyThreatenedDreamsLore[npcName]) do
		local lines = type(entry[2]) == "table" and entry[2] or { entry[2] }
		for _, word in ipairs(entry[1]) do
			local answer = talk:say(p, word)
			T.check(npcName .. " lore '" .. word .. "' (EN)", has(answer, lines[1]) and has(answer, lines[#lines]), answer)
		end
	end
	talk:say(p, "bye")
end

local p = player({ money = 0 })

-- ------------------------------------------------------------- Alkestios
local alk = T.load("data-otservbr-global/npc/alkestios.lua")
T.check("Alkestios greeting (BR)", alk:say(p, "hi") == "Nature's blessing, traveller! May you not be affected by any sinister force.")
local a = alk:say(p, "mission")
T.check("Alkestios offer at 'mission' (EN)", has(a, "I indeed have some troubles") and has(a, "Are you willing to help me?"), a)
a = alk:say(p, "yes")
T.check("Troubled Animals starts (EN)", has(a, "Your decision honours you.") and has(a, "stop them from hunting white deer.") and p.storage[M1] == 1 and p.storage[TD.QuestLine] == 1, a)
alk:say(p, "bye")
alk:say(p, "hi")
a = alk:say(p, "help")
T.check("'help' without the book (BR word)", has(a, "Please search it out"), a)
p.items[D.BOOK] = 1 -- the poacher chest
a = alk:say(p, "book")
T.check("Alkestios 'book' (EN)", has(a, "I see, you found a book that contains old myths") and has(a, "they might stop hunting me."), a)
alk:say(p, "bye")

-- ------------------------------------------------------------------ Ahmet
local ahmet = T.load("data-otservbr-global/npc/ahmet.lua")
local other = player()
other.items[D.BOOK] = 1
ahmet:say(other, "hi")
a = ahmet:say(other, "book")
T.check("Ahmet ignores 'book' off the mission (ours)", not has(a, "additional story"), a)
ahmet:say(other, "bye")
ahmet:say(p, "hi")
a = ahmet:say(p, "book")
T.check("Ahmet's offer (EN)", has(a, "It costs 5000 gold, however. Are you still interested?"), a)
a = ahmet:say(p, "yes")
T.check("not enough money (ours)", has(a, "You don't have enough money.") and p.storage[M1] == 1, a)
p.money = 5000
ahmet:say(p, "book")
a = ahmet:say(p, "yes")
T.check("doctored book (EN item 25239)", has(a, "Well then. Here, take the book") and has(a, "like very obviously on a table or something.") and p.items[D.BOOK] == 0 and p.items[D.BOOK_DOCTORED] == 1 and p.storage[M1] == 2 and p.money == 0, a)
ahmet:say(p, "bye")

alk:say(p, "hi")
a = alk:say(p, "mission")
T.check("still chasing (upstream)", has(a, "still chasing me"), a)
p.storage[M1] = 3 -- book placed on the table (server test)
a = alk:say(p, "mission")
T.check("success (EN)", has(a, "You succeeded!") and has(a, "Would you do that?"), a)
a = alk:say(p, "yes")
T.check("to Ikassis (EN)", has(a, "I heard there is a problem with a wolf mother") and has(a, "near a circle of standing stones.") and p.storage[M1] == 4, a)
alk:say(p, "bye")
checkLore("Alkestios", alk)

-- ------------------------------------------------------------------ Ikassis
local ika = T.load("data-otservbr-global/npc/ikassis.lua")
T.check("Ikassis greeting (EN)", ika:say(p, "hi") == "Nature's blessing, traveler!")
a = ika:say(p, "mission")
T.check("Ikassis offer (EN)", has(a, "One of my sisters, in the disguise of a nightingale") and has(a, "Will you help me?"), a)
a = ika:say(p, "yes")
T.check("fae talisman given (BR, EN)", has(a, "Take this talisman") and given(p, D.TALISMAN) == 1 and p.storage[M1] == 5, a)
T.check("Ikassis farewell (EN)", ika:say(p, "bye") == "May Mother Nature protect you.")
checkLore("Ikassis", ika)

-- ------------------------------------------------------------- Ghostly Wolf
local wolf = T.load("data-otservbr-global/npc/ghostly_wolf.lua")
a = wolf:say(p, "hi")
T.check("wolf greeting (EN)", has(a, "I'm not in the right mood for a chat."), a)
a = wolf:say(p, "mission")
T.check("wolf offer (EN)", has(a, "I'm heartbroken, traveler.") and has(a, "Will you help me?"), a)
a = wolf:say(p, "yes")
T.check("to Ulderek's Rock (EN)", has(a, "I guess he mentioned Ulderek's Rock.") and p.storage[M1] == 6, a)
p.storage[M1] = 8 -- notes found, fur bought from Irmana
a = wolf:say(p, "mission")
T.check("wolf after the fur (EN)", has(a, "So one of my babies died") and has(a, "place it in this stone's mouth."), a)
p.storage[M1] = 9 -- fur placed in the weeping stone
a = wolf:say(p, "whelp")
T.check("'whelp' (EN)", has(a, "You redeemed me.") and p.storage[M1] == 10, a)
T.check("wolf farewell (EN)", wolf:say(p, "bye") == "Farewell.")
checkLore("Ghostly Wolf", wolf)

ika:say(p, "hi")
a = ika:say(p, "mission")
T.check("Ikassis sends to the swan (EN)", has(a, "The wolf's ghost has found peace.") and p.storage[M1] == 11, a)
ika:say(p, "bye")

-- ------------------------------------------------------------------ A Swan
local swan = T.load("data-otservbr-global/npc/a_swan.lua")
T.check("swan greeting (EN)", swan:say(p, "hi") == "I salute you, mortal being.")
a = swan:say(p, "mission")
T.check("swan offer (EN)", has(a, "My sister Ikassis sent you?") and has(a, "bring back the cloak?"), a)
a = swan:say(p, "yes")
T.check("swan accept (BR)", has(a, "the thieving troll headed to the mountains east of here.") and p.storage[M1] == 12, a)
p.storage[M1] = 14 -- Tereban, the five feather spots
p.items[D.TATTERED_FEATHER] = 3
a = swan:say(p, "mission")
T.check("too few feathers (ours)", has(a, "Have you found my cloak?") and p.storage[M1] == 14, a)
p.items[D.TATTERED_FEATHER] = 5
a = swan:say(p, "mission")
T.check("feathers delivered (BR)", has(a, "This is everything that remained of my cloak?") and p.items[D.TATTERED_FEATHER] == 0 and p.storage[M1] == 15, a)
T.check("swan farewell (EN)", swan:say(p, "bye") == "May your path be always even.")
checkLore("A Swan", swan)

alk:say(p, "hi")
a = alk:say(p, "mission")
T.check("arcane fae seal (EN)", has(a, "I marked you with an arcane fae seal.") and has(a, "now that you bear the magical seal.") and p.storage[M1] == 16, a)
alk:say(p, "bye")

-- ----------------------------------------------------------------- Maelyrra
local mae = T.load("data-otservbr-global/npc/maelyrra.lua")
local stranger = player()
mae:say(stranger, "hi")
a = mae:say(stranger, "mission")
T.check("Maelyrra refuses a stranger (ours)", has(a, "Prove yourself to Alkestios first."), a)
mae:say(stranger, "bye")
T.check("Maelyrra greeting (BR)", mae:say(p, "hi") == "Nature's blessings! Welcome to the land of dreams.")
a = mae:say(p, "mission")
T.check("nightmare offer (BR)", has(a, "Would you go and fight them for me?"), a)
a = mae:say(p, "yes")
T.check("kill 200 (BR)", has(a, "Kill two hundred of them") and p.storage[M2] == 1, a)
mae:say(p, "mission")
a = mae:say(p, "yes")
T.check("not yet killed (BR fragment)", has(a, "Kill two hundred") and p.storage[M2] == 1, a)
p.storage[TD.Mission02.EnfeebledCount] = 120
p.storage[TD.Mission02.FrazzlemawsCount] = 80
p.storage[TD.Mission02.KroazurKill] = 1
mae:say(p, "mission")
a = mae:say(p, "yes")
T.check("kills reported (BR)", has(a, "You rendered a great favour") and p.storage[M2] == 2, a)
a = mae:say(p, "yes")
T.check("tainted fae (BR)", has(a, "Some of our siblings are tainted") and has(a, "hollow logs or trumps") and p.storage[M2] == 3, a)
p.storage[TD.Mission02.FairiesCounter] = 5
p.storage[TD.Mission02.DarkMoonMirror] = 1
mae:say(p, "mission")
a = mae:say(p, "yes")
T.check("mirror reported (BR)", has(a, "Please keep the mirror.") and p.storage[M2] == 4, a)
a = mae:say(p, "yes")
T.check("three vessels (BR)", has(a, "Ask the mermaid Aurita for the starlight vial and the faun Taegen") and p.storage[M2] == 5, a)
mae:say(p, "bye")

-- --------------------------------------- Aurita, the dancing fairy and Taegen
local aur = T.load("data-otservbr-global/npc/aurita.lua")
local fairy = T.load("data-otservbr-global/npc/dancing_fairy.lua")
local tae = T.load("data-otservbr-global/npc/taegen.lua")
T.check("Aurita greeting (BR)", aur:say(p, "hi") == "Greetings, traveller!")
a = aur:say(p, "mission")
T.check("Aurita offer (BR)", has(a, "I'm in love with Taegen") and has(a, "Would you help me?"), a)
a = aur:say(p, "yes")
T.check("Aurita accept (BR)", has(a, "transform my fishtail into legs") and p.storage[M3] == 1, a)
aur:say(p, "bye")
fairy:say(p, "hi")
a = fairy:say(p, "fishtail")
T.check("dancing fairy 'fishtail' (EN)", has(a, "So, you are searching for a way") and has(a, "a walk on the beach with Taegen.") and p.storage[TD.Mission03.UnlikelyCouple] == 2, a)
fairy:say(p, "bye")
-- the panpipes on the lake island
T.check("panpipes make the notes", D.playPanpipes(p) and p.items[D.MUSIC_NOTES] == 1 and p.storage[M3] == 2)
T.check("panpipes wait 20 h (BR)", not D.playPanpipes(p))
aur:say(p, "hi")
a = aur:say(p, "mission")
T.check("notes to Aurita (EN)", has(a, "The spell works!") and p.items[D.MUSIC_NOTES] == 0 and p.storage[TD.Mission03.UnlikelyCouple] == 4, a)
aur:say(p, "bye")
T.check("Taegen greeting (BR)", tae:say(p, "hi") == "Be greeted, mortal being!")
a = tae:say(p, "mission")
T.check("raven herb request (EN, BR)", has(a, "a very rare plant called raven herb") and p.storage[M3] == 3, a)
a = tae:say(p, "mission")
T.check("asks for the herb (EN)", has(a, "Have you found the raven herb?"), a)
a = tae:say(p, "yes")
T.check("no herb yet (BR fragment)", has(a, "Please find this plant for me.") and p.storage[M3] == 3, a)
p.items[D.RAVEN_HERB] = 1
tae:say(p, "sun catcher")
a = tae:say(p, "yes")
T.check("herb delivered (BR, EN)", has(a, "Now I can visit Aurita in her underwater grotto!") and p.storage[M3] == 4, a)
a = tae:say(p, "sun catcher")
T.check("sun catcher offer (BR)", has(a, "A sun catcher is similar to a dream catcher") and has(a, "Do you have gems?"), a)
a = tae:say(p, "yes")
T.check("no gems (ours)", has(a, "Two small enchanted amethysts") and given(p, D.SUN_DARK) == 0, a)
for _, id in ipairs({ 675, 676, 677, 678 }) do p.items[id] = 2 end
tae:say(p, "sun catcher")
a = tae:say(p, "yes")
T.check("sun catcher crafted (BR)", a == "Alright, I will craft a sun catcher for you." and given(p, D.SUN_DARK) == 1 and p.items[675] == 0, a)
tae:say(p, "bye")
-- panpipes after the mission do not set it back (upstream did)
p.storage[TD.Mission03.PanpipesTimer] = 0
D.playPanpipes(p)
T.check("panpipes after the mission keep An Unlikely Couple", p.storage[M3] == 4)
aur:say(p, "hi")
a = aur:say(p, "empty starlight vial")
T.check("starlight vial (BR)", has(a, "Please take the starlight vial.") and given(p, D.VIAL_EMPTY) == 1, a)
a = aur:say(p, "starlight vial")
T.check("only one vial (upstream)", has(a, "I already gave you the empty starlight vial."), a)
aur:say(p, "bye")

-- the BR way: notes straight to Taegen
local q = player()
q.storage[M3] = 2
q.storage[TD.Mission03.UnlikelyCouple] = 3
q.items[D.MUSIC_NOTES] = 1
tae:say(q, "hi")
a = tae:say(q, "sun catcher")
T.check("notes taken by Taegen at 'sun catcher' (BR)", has(a, "a very rare plant called raven herb") and q.items[D.MUSIC_NOTES] == 0 and q.storage[M3] == 3, a)
tae:say(q, "bye")

-- ----------------------------------------------------------------- Maelyrra again
p.items[D.MOON_DARK] = 1
p.items[D.SUN_DARK] = 0
mae:say(p, "hi")
mae:say(p, "mission")
a = mae:say(p, "yes")
T.check("vessels missing (EN fragment)", has(a, "Ask the mermaid Aurita") and p.storage[M2] == 5, a)
p.items[D.SUN_DARK] = 1
mae:say(p, "mission")
a = mae:say(p, "yes")
T.check("three lights (BR)", has(a, "Very good, mortal being!") and has(a, "Suon's light with the sun catcher.") and p.storage[M2] == 6, a)
p.items[D.MOON_LIT], p.items[D.VIAL_GLEAMING], p.items[D.SUN_SHINING] = 1, 1, 1
mae:say(p, "mission")
a = mae:say(p, "yes")
T.check("barrier (BR)", has(a, "That's wonderful!") and has(a, "Feyrist's protection will be ensured again.") and p.storage[M2] == 7, a)
p.storage[TD.Mission02.ChargedMoonMirror] = 0
p.storage[TD.Mission02.ChargedStarlightVial] = 0
p.storage[TD.Mission02.ChargedSunCatcher] = 0
mae:say(p, "mission")
a = mae:say(p, "yes")
T.check("blossom bag (BR)", has(a, "Take this blossom bag") and given(p, 25780) == 1 and p.storage[M2] == 8, a)
mae:say(p, "bye")

-- ----------------------------------------------------------------- Valindara
local val = T.load("data-otservbr-global/npc/valindara.lua")
val:say(stranger, "hi")
a = val:say(stranger, "cloak")
T.check("no cloak before A Dream Come True (ours)", has(a, "only for those who helped the fae"), a)
val:say(stranger, "bye")
T.check("Valindara greeting (BR, EN)", val:say(p, "hi") == "Greetings, mortal being!")
a = val:say(p, "cloak")
T.check("cloak offer (BR)", has(a, "Bring me one hundred swan feathers and I will make them into a beautiful robe.") and not has(a, "Do you have") and p.storage[S.SwanCloak] == 1, a)
a = val:say(p, "cloak")
T.check("cloak question (EN)", has(a, "Do you have enough feathers yet?"), a)
p.items[D.SWAN_FEATHER] = 99
a = val:say(p, "yes")
T.check("99 feathers are too few (ours)", has(a, "You don't have enough feathers yet.") and p.storage[S.SwanCloak] == 1, a)
p.items[D.SWAN_FEATHER] = 100
val:say(p, "cloak")
a = val:say(p, "yes")
T.check("cloak crafting (EN)", a == "Very good. I will craft the cloak for you. This will take some time, so return tomorrow please." and p.items[D.SWAN_FEATHER] == 0 and p.storage[S.SwanCloak] == 2, a)
a = val:say(p, "cloak")
T.check("cloak not ready (ours)", has(a, "still working on your cloak"), a)
p.storage[S.SwanCloakReady] = os.time() - 1
a = val:say(p, "cloak")
T.check("cloak ready (EN)", has(a, "You're returning just in time.") and given(p, D.SWAN_CLOAK) == 1 and p.storage[S.SwanCloak] == 3, a)
val:say(p, "bye")
T.check("quest log of the cloak (ours)", D.swanCloakLog[3] ~= nil)

-- ----------------------------------------------------------- The Fairy Treasure
local tooth = T.load("data-otservbr-global/npc/tooth_fairy.lua")
local f = player()
T.check("Tooth Fairy greeting (EN)", tooth:say(f, "hi") == "Greetings, human being.")
a = tooth:say(f, "mission")
T.check("Tooth Fairy offer (EN)", has(a, "You've got me, I really have a little problem here.") and has(a, "Would you help me?"), a)
a = tooth:say(f, "yes")
T.check("three presents (EN)", has(a, "Quero's daughter in Thais, Allen's son in Venore and Rowenna's daughter in Carlin") and f.items[D.PRESENT] == 3 and f.storage[S.ToothFairy] == 1 and f.storage[S.FairyTreasure] == 1 and f.storage[TD.QuestLine] == 1, a)
a = tooth:say(f, "mission")
T.check("waiting for the teeth (EN fragment)", has(a, "Come back with the milk teeth."), a)
a = tooth:say(f, "lost")
T.check("'lost' with all presents (ours)", has(a, "You still have all the presents"), a)
f.items[D.PRESENT] = 1 -- one placed, one lost
f.storage[S.Present.quero] = 1
a = tooth:say(f, "lost")
T.check("'lost' asks for a small ruby (BR)", has(a, "Give me a small ruby for each lost present"), a)
f.items[D.SMALL_RUBY] = 1
a = tooth:say(f, "yes")
T.check("a new present for a small ruby (BR)", has(a, "Here you are.") and f.items[D.PRESENT] == 2 and f.items[D.SMALL_RUBY] == 0, a)
-- the three rooms (server test): milk teeth and presents
for _, child in ipairs({ "quero", "allen", "rowenna" }) do
	f.storage[S.Tooth[child]] = 1
	f.storage[S.Present[child]] = 1
end
f.items[D.MILK_TOOTH] = 3
a = tooth:say(f, "mission")
T.check("milk teeth delivered (EN)", has(a, "You're bringing the milk teeth!") and has(a, "another cause you could help me with.") and given(f, D.MAP_UPPER_LEFT) == 1 and f.items[D.MILK_TOOTH] == 0 and f.storage[S.ToothFairy] == 2, a)
a = tooth:say(f, "parts")
T.check("'parts' (EN)", has(a, "Three of my siblings and I have hidden the treasure") and has(a, "They took over a group of trees"), a)
a = tooth:say(f, "cause")
T.check("'cause' (EN)", has(a, "I have a small collection.") and has(a, "or a werewolf fangs."), a)
a = tooth:say(f, "orc")
T.check("no orc tooth (ours)", has(a, "You don't have it with you"), a)
for _, t in ipairs(D.TEETH) do
	f.items[t.id] = 1
	a = tooth:say(f, t.word)
	T.check("tooth '" .. t.word .. "' (EN)", has(a, "Oh, I see! You really found " .. t.name .. " for me!") and f.items[t.id] == 0, a)
end
T.check("six white pearls (BR)", given(f, 3026) == 6)
T.check("Toothfairy Assistant (EN)", f:hasAchievement("Toothfairy Assistant"))
f.items[10196] = 1
a = tooth:say(f, "orc")
T.check("only one orc tooth (ours)", has(a, "I already have such a specimen") and f.items[10196] == 1, a)
tooth:say(f, "bye")

local tree = T.load("data-otservbr-global/npc/tired_tree.lua")
T.check("Tired Tree greeting (EN)", tree:say(f, "hi") == "*yawn* Nature's blessing.")
a = tree:say(f, "the seeds of life")
T.check("no story before the favour", not has(a, "what a beautiful story"), a)
a = tree:say(f, "map")
T.check("'map' (EN)", a == "I have a part of a certain map, yes. I would consider giving it to you if you do me a small favour. Would you do that?", a)
a = tree:say(f, "yes")
T.check("bedtime story (EN)", has(a, "We'd like to hear something about the dryads.") and f.storage[S.TiredTree] == 1, a)
a = tree:say(f, "map")
T.check("'map' again (EN)", has(a, "If you know a good bedtime story I will give you the map."), a)
a = tree:say(f, "mission")
T.check("'mission' (EN)", has(a, "Have you found a story that could help us to drift off to sleep?"), a)
a = tree:say(f, "The Seeds of Life")
T.check("The Seeds of Life (EN)", has(a, "Oh, what a beautiful story.") and has(a, "There are ... dwarves I guess.") and given(f, D.MAP_BOTTOM_LEFT) == 1 and f.storage[S.TiredTree] == 2, a)
a = tree:say(f, "name")
T.check("upstream words still answer", has(a, "fagus sylvatica"), a)
tree:say(f, "bye")

local stone = T.load("data-otservbr-global/npc/grumpy_stone.lua")
T.check("Grumpy Stone greeting (EN)", stone:say(f, "hi") == "Please don't bother me, human being. I have my own problems.")
a = stone:say(f, "mission")
T.check("Grumpy Stone offer (EN)", has(a, "As much as I dislike admitting it") and has(a, "to bring them some relief?"), a)
a = stone:say(f, "yes")
T.check("no metal (EN)", has(a, "Your hands are too smooth.") and f.storage[S.GrumpyStone] == 1, a)
a = stone:say(f, "mission")
T.check("stones still itching (ours)", has(a, "still lamenting"), a)
for _, key in ipairs(S.Stones) do f.storage[key] = 1 end -- raked (server test)
a = stone:say(f, "mission")
T.check("third map part (EN)", has(a, "Their lamentation lapsed into silence.") and has(a, "It's hidden in a big fly agaric.") and given(f, D.MAP_UPPER_RIGHT) == 1 and f.storage[S.GrumpyStone] == 2, a)
stone:say(f, "bye")

T.check("fly agaric joins the map (EN)", D.useFlyAgaric(f) and f.items[D.OLD_MAP] == 1 and f.items[D.MAP_UPPER_LEFT] == 0 and f.log[#f.log] == "You discover the fourth map part between the big fly agaric's gills.")
T.check("fly agaric only once", not D.useFlyAgaric(f))
T.check("treasure (EN)", D.useTreasure(f) and given(f, 25698) == 1 and given(f, 25737) == 5 and given(f, 24390) == 5 and f.storage[S.FairyTreasure] == 2 and f.log[#f.log] == "You discover something shiny that is hidden beneath the stones.")
T.check("treasure only once (ours)", D.useTreasure(f) and given(f, 25698) == 1)
T.check("fairy treasure log done (ours)", has(D.fairyTreasureLog(f), "beneath a stone sun mosaic"))

T.finish()
