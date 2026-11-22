-- Gaia Family server: Krailos Quest check (2026-11-22). One character plays the missions with the
-- lines of the TibiaWiki EN spoiler transcripts (world steps set as storages or items), every lore
-- word of the EN NPC transcripts (family_krailos_lore.lua) and the states the wikis do not show.
-- Run from the repository root:
--   luajit tools/family/npc_talk/krailos.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z, sendMagicEffect = function() end } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
MESSAGE_EVENT_ADVANCE = MESSAGE_EVENT_ADVANCE or 19
CONST_ME_MAGIC_GREEN = CONST_ME_MAGIC_GREEN or 15
dofile("data-otservbr-global/lib/others/family_krailos_lore.lua")
dofile("data-otservbr-global/lib/others/family_krailos.lua")
local K = FamilyKrailos
local S = K.S

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
local function has(text, s) return text ~= nil and (text:gsub("[{}]", "")):find(s, 1, true) ~= nil end
local function given(p, id)
	local n = 0
	for _, a in ipairs(p.added) do
		if a[1] == id then n = n + a[2] end
	end
	return n
end
local function plain(s) return (s:gsub("[{}]", "")) end

-- Every lore word of an NPC answers its EN lines (first and last line checked).
local function checkLore(npcName, talk, makePlayer)
	local p = makePlayer()
	talk:say(p, "hi")
	for _, entry in ipairs(FamilyKrailosLore[npcName]) do
		local lines = type(entry[2]) == "table" and entry[2] or { entry[2] }
		for _, word in ipairs(entry[1]) do
			local answer = talk:say(p, word)
			T.check(npcName .. " lore '" .. word .. "' (EN)", has(answer, plain(lines[1])) and has(answer, plain(lines[#lines])), answer)
		end
	end
	talk:say(p, "bye")
end

-- ------------------------------------------------------------------ Larek
local larek = T.load("data-otservbr-global/npc/larek.lua")
local p = player()

T.check("Larek greeting (EN)", larek:say(p, "hi") == "Greetings!")
local q = larek:say(p, "quest")
T.check("Larek's offer (EN)", has(q, "Indeed there is something.") and has(q, "Would you go out and search something for me?"), q)
local y = larek:say(p, "yes")
T.check("skull orchid mission (EN)", has(y, "rare plant I call the skull orchid") and has(y, "bring it back to me.") and given(p, K.CONTAINER_EMPTY) == 1 and p.storage[S.HungryNewWorld] == 1 and p.storage[S.Questline] == 1, y)
q = larek:say(p, "mission")
T.check("asks for the orchid (EN)", q == "Have you found a sample of the skull orchid?", q)
y = larek:say(p, "yes")
T.check("no orchid yet (ours)", has(y, "I don't see it") and p.storage[S.HungryNewWorld] == 1, y)
-- lost container: a new one (ours)
p.items[K.CONTAINER_EMPTY] = 0
q = larek:say(p, "quest")
T.check("lost container replaced (ours)", has(q, "you lost the botanist's container") and p.items[K.CONTAINER_EMPTY] == 1, q)
p.items[K.CONTAINER_EMPTY] = 0
p.items[K.CONTAINER_ORCHID] = 1 -- used on a skull orchid (server test)
larek:say(p, "quest")
y = larek:say(p, "yes")
T.check("orchid delivered (EN)", has(y, "Oh, brilliant!") and has(y, "are you interested in another mission?") and p.items[K.CONTAINER_ORCHID] == 0 and p.storage[S.HungryNewWorld] == 2, y)
y = larek:say(p, "no")
T.check("declines the next mission (ours)", has(y, "Perhaps another time") and p.storage[S.HungryNewWorld] == 2, y)
q = larek:say(p, "quest")
T.check("offers the map mission again (EN line end)", q == "Say, are you interested in another mission?", q)
y = larek:say(p, "yes")
T.check("ancient map mission (EN)", has(y, "bring forth not only botany but also archaeology!") and has(y, "Perhaps it is accessible only by water.") and p.storage[S.HungryNewWorld] == 3, y)
q = larek:say(p, "quest")
T.check("asks for the secret room (EN)", q == "Have you found the secret room in the ruins? Was there something of interest inside?", q)
y = larek:say(p, "no")
T.check("keep looking (ours)", has(y, "keep looking"), y)
p.items[K.ANCIENT_MAP] = 1 -- from the sarcophagus (server test)
larek:say(p, "quest")
y = larek:say(p, "yes")
T.check("map delivered (EN)", has(y, "What an ancient map!") and has(y, "Would you help me one last time?") and p.items[K.ANCIENT_MAP] == 0 and p.storage[S.HungryNewWorld] == 4, y)
y = larek:say(p, "yes")
T.check("ancient amulet mission (EN)", has(y, "An ancient amulet, forged with remarkable artisanship.") and has(y, "But I'm sure you'll succeed.") and p.storage[S.HungryNewWorld] == 5, y)
q = larek:say(p, "quest")
T.check("asks for the amulet (EN)", q == "Have you found the lost amulet?", q)
T.check("grille still closed", K.grilleRefusal(p) == "You don't have Larek's permission to go down there!")
p.items[K.ANCIENT_AMULET] = 1 -- from the bird nest (server test)
y = larek:say(p, "yes")
T.check("amulet delivered, depot (EN)", has(y, "You may use the depot I established here. Just use the entrance in my tent.") and p.items[K.ANCIENT_AMULET] == 0 and p.storage[S.HungryNewWorld] == 6, y)
T.check("grille open", K.grilleRefusal(p) == nil)
q = larek:say(p, "quest")
T.check("after the missions (ours)", has(q, "depot below my tent"), q)
T.check("Larek farewell (EN)", larek:say(p, "bye") == "Farewell.")
T.check("Larek trade (EN)", (function()
	local p2 = player()
	larek:say(p2, "hi")
	return has(larek:say(p2, "trade"), "Of course, just browse through my wares.")
end)())
checkLore("Larek", larek, player)

-- Quest log texts
T.check("log text for every Hungry New World state", (function()
	for i = 1, 6 do
		if not K.log.hungry[i] then return false end
	end
	return true
end)())

-- ------------------------------------------------------------------ Ghorza: The Great Hunger
local ghorza = T.load("data-otservbr-global/npc/ghorza.lua")
K.lakeOverride = { state = K.LAKE_DRY }
local g = player()
T.check("Ghorza greeting (EN)", ghorza:say(g, "hi") == "Hello, scraggy human.")
local tr = ghorza:say(g, "trade")
T.check("Ghorza no trade before The Great Hunger (EN)", has(tr, "No, Ghorza no trading with humans."), tr)
local po = ghorza:say(g, "potions")
T.check("no potions category before (ours)", has(po, "No, Ghorza no trading with humans."), po)
q = ghorza:say(g, "mission")
T.check("Great Hunger offer (EN)", has(q, "Ghorza feels that spirits restless.") and has(q, "You helping?"), q)
y = ghorza:say(g, "yes")
T.check("gourd (EN)", has(y, "Taking this gourd.") and has(y, "Fill teeth and splinters into gourd. Then come back.") and given(g, K.GOURD) == 1 and g.storage[S.GreatHunger] == 1 and g.storage[S.Questline] == 1, y)
q = ghorza:say(g, "mission")
T.check("gourd not rattling yet (ours)", has(q, "Gourd not rattling yet"), q)
g.items[K.GOURD] = 0
g.items[K.RATTLING_GOURD] = 1 -- teeth and chips filled in (server test)
q = ghorza:say(g, "mission")
T.check("painting the gourd (EN)", has(q, "Ah, you made gourd rattle!") and has(q, "Painting on gourd runes you see in front of Ghorza's tent.") and given(g, K.RED_OIL) == 1 and g.storage[S.GreatHunger] == 2, q)
q = ghorza:say(g, "mission")
T.check("rattle not painted yet (ours)", has(q, "Rattle not painted yet"), q)
g.items[K.RATTLING_GOURD] = 0
g.items[K.RED_OIL] = 0
g.items[K.PAINTED_RATTLE] = 1 -- painted (server test)
q = ghorza:say(g, "mission")
T.check("ritual sites (EN)", has(q, "You paint rattle. Very good, tasty human.") and has(q, "If rattle is used at other place than ritual site, spirits might be upset. Be careful.") and g.storage[S.GreatHunger] == 3, q)
g.storage[S.GreatHungerSites] = 3
q = ghorza:say(g, "mission")
T.check("two of three sites (ours)", has(q, "Spirits still upset"), q)
g.storage[S.GreatHungerSites] = 7
q = ghorza:say(g, "mission")
T.check("hyaena (EN)", has(q, "Yes, you purge defiled ritual sites!") and has(q, "But use this net, hyaena savage.") and given(g, K.HYAENA_TRAP) == 1 and g.storage[S.GreatHunger] == 4, q)
q = ghorza:say(g, "mission")
T.check("no hyaena yet (ours)", has(q, "No hyaena with you"), q)
g.items[K.HYAENA_TRAP] = 0
g.items[K.TRAPPED_HYAENA] = 1
q = ghorza:say(g, "mission")
local sets = 0
for _, r in ipairs(K.RUNES) do sets = sets + given(g, r.set) end
T.check("runes (EN)", has(q, "Little human bringing back hyaena! Ghorza happy!") and has(q, "Here, take stones.") and sets == 5 and g.items[K.TRAPPED_HYAENA] == 0 and g.storage[S.GreatHunger] == 5, q)
g.items[K.RUNES[1].set] = 0
g.storage[S.GreatHungerRunes] = 2 -- the east one placed, the north one lost
g.items[K.RUNES[2].set] = 0
local lr = ghorza:say(g, "lost runes")
T.check("lost runes (BR keyword, line ours)", has(lr, "take stones again") and g.items[K.RUNES[1].set] == 1 and g.items[K.RUNES[2].set] == 0, lr)
q = ghorza:say(g, "mission")
T.check("runes still broken (ours)", has(q, "Runes still broken"), q)
g.storage[S.GreatHungerRunes] = K.RUNES_ALL
q = ghorza:say(g, "mission")
T.check("onyx pendant (EN)", has(q, "Protection Runes fixed, Ghorza feels!") and has(q, "Ghorza can sell.") and given(g, K.ONYX_PENDANT) == 1 and g.storage[S.GreatHunger] == 6, q)
tr = ghorza:say(g, "trade")
T.check("Ghorza trades after The Great Hunger (EN)", not has(tr, "No, Ghorza no trading"), tr)
ghorza:say(g, "bye")

-- ------------------------------------------------------------------ Quenching the Thirst
local w = player()
ghorza:say(w, "hi")
K.lakeOverride = { state = K.LAKE_DIRTY }
q = ghorza:say(w, "water")
T.check("no start while the lake has water (BR/EN, line ours)", has(q, "Salt sea not dry now") and w.storage[S.Thirst] == nil, q)
K.lakeOverride = { state = K.LAKE_DRY }
q = ghorza:say(w, "water")
T.check("Thirst offer (EN)", has(q, "Water great problem in Krailos.") and has(q, "Ogres needing more water. You helping?"), q)
y = ghorza:say(w, "yes")
T.check("enchanted jar (EN)", has(y, "Ghorza having idea how to solve problem.") and has(y, "Here, take enchanted jar.") and given(w, K.CARAFE) == 1 and w.storage[S.Thirst] == 1, y)
q = ghorza:say(w, "water")
T.check("lake still dry (ours)", has(q, "Salt sea still dry"), q)
w.storage[S.ThirstPours] = 6 -- six carafes poured today (server test)
K.lakeOverride = { state = K.LAKE_DIRTY }
q = ghorza:say(w, "water")
T.check("lake filled, ask Larek (EN)", has(q, "Salt sea filled with water now.") and has(q, "Ghorza taking back.") and w.items[K.CARAFE] == 0 and w.storage[S.Thirst] == 2, q)
q = ghorza:say(w, "water")
T.check("ask Larek reminder (ours)", has(q, "Ask human merchant Larek"), q)
ghorza:say(w, "bye")
larek:say(w, "hi")
q = larek:say(w, "water")
T.check("Larek's golden quartzes (EN)", has(q, "I noticed that the salt sea near the village is filled with water again.") and has(q, "Then scatter it into the poisonous water.") and w.storage[S.Thirst] == 3, q)
q = larek:say(w, "water")
T.check("Larek repeats the hint (ours)", has(q, "golden shimmering quartzes"), q)
larek:say(w, "bye")
-- the lake dried at 06:00 before the water was clean: catch the spirits again (EN note; lines ours)
K.lakeOverride = { state = K.LAKE_DRY }
w.storage[S.ThirstPowder] = 4
ghorza:say(w, "hi")
q = ghorza:say(w, "water")
T.check("lake dried again: carafe again (ours)", has(q, "Salt sea dried up again!") and w.storage[S.Thirst] == 1 and w.items[K.CARAFE] == 1, q)
w.storage[S.ThirstPours] = 6
K.lakeOverride = { state = K.LAKE_DIRTY }
ghorza:say(w, "water")
w.storage[S.Thirst] = 4 -- 30 powders scattered (server test)
K.lakeOverride = { state = K.LAKE_CLEAN }
q = ghorza:say(w, "water")
T.check("shaggy ogre bag (EN)", has(q, "Sea filled with fresh water now!") and has(q, "Take this, perhaps something of use inside.") and given(w, K.SHAGGY_BAG) == 1 and w.storage[S.Thirst] == 5, q)
q = ghorza:say(w, "water")
T.check("after the mission (ours)", has(q, "Ogres having fresh water now"), q)
ghorza:say(w, "bye")
T.check("Ghorza farewell (EN)", (function()
	local p3 = player()
	ghorza:say(p3, "hi")
	return ghorza:say(p3, "bye") == "Take care of evil spirits."
end)())
checkLore("Ghorza", ghorza, player)
T.check("log texts for The Great Hunger and Quenching the Thirst", (function()
	for i = 1, 6 do if not K.log.hunger[i] then return false end end
	for i = 1, 5 do if not K.log.thirst[i] then return false end end
	return type(K.log.thirst[1](w)) == "string" and type(K.log.hunger[5](g)) == "string"
end)())

-- ------------------------------------------------------------------ Survival of the Strongest
local grubokkNpc = T.load("data-otservbr-global/npc/grubokk.lua")
local nibbleNpc = T.load("data-otservbr-global/npc/nibble.lua")
local prisoner = T.load("data-otservbr-global/npc/an_imprisoned_goblin.lua")
local exile = T.load("data-otservbr-global/npc/a_goblin_exile.lua")
local runawayNpc = T.load("data-otservbr-global/npc/a_runaway_goblin.lua")
local vuzrogNpc = T.load("data-otservbr-global/npc/vuzrog.lua")
local mugruu = T.load("data-otservbr-global/npc/mugruu.lua")

local s1 = player()
-- the goblins' mission first: Grubokk's task clears it (BR, EN)
nibbleNpc:say(s1, "hi")
nibbleNpc:say(s1, "mission")
nibbleNpc:say(s1, "yes")
nibbleNpc:say(s1, "bye")
T.check("goblins' mission taken first", s1.storage[S.Revolt] == 1)
T.check("Grubokk greeting (EN)", grubokkNpc:say(s1, "hi") == "Huh! Talking food! Hello!")
q = grubokkNpc:say(s1, "quest")
T.check("Grubokk's offer (EN)", q == "Arr harr! Pesky goblins up to no good? You wanna teach lesson? Me reward you!", q)
y = grubokkNpc:say(s1, "yes")
T.check("the promise (EN)", has(y, "You SURE no help goblin?? Say it!"), y)
local wrong = grubokkNpc:say(s1, "yes")
T.check("only the promise counts (ours)", has(wrong, "Say no help goblin!") and (s1.storage[S.Survival] or 0) == 0, wrong)
grubokkNpc:say(s1, "mission")
grubokkNpc:say(s1, "yes")
y = grubokkNpc:say(s1, "no help goblin")
T.check("Survival of the Strongest (EN)", has(y, "That will show uppity goblins!") and has(y, "HAHAHAH!") and s1.storage[S.Survival] == 1, y)
T.check("the goblins' mission left the quest log (BR, EN)", s1.storage[S.Revolt] == 0)
q = grubokkNpc:say(s1, "mission")
T.check("what did you do? (EN)", q == "Yes? You finished task? What you do? {Sabotage} water wheels, {poison} wells or {flood} tunnels?", q)
local nd = grubokkNpc:say(s1, "sabotage")
T.check("not done yet (ours)", has(nd, "You not done that yet!"), nd)
s1.storage[S.SurvivalWheels] = 10
y = grubokkNpc:say(s1, "sabotage")
T.check("wheels sabotaged (EN)", has(y, "Ah! Ten wheels damaged, good, good.") and has(y, "All's well, harrharr! Good joke!") and s1.storage[S.Survival] == 2, y)
T.check("flood before poison does nothing (ours)", has(grubokkNpc:say(s1, "flood"), "You not done that yet!") and s1.storage[S.Survival] == 2)
s1.storage[S.SurvivalSalt] = 1 + 2 + 8 + 16
y = grubokkNpc:say(s1, "poison")
T.check("wells poisoned (EN)", has(y, "Hah! Only two wells!") and has(y, "And be quick or be drowned, human!") and s1.storage[S.Survival] == 3, y)
s1.storage[S.SurvivalTreadmills] = 7
s1.storage[S.FloodTime] = os.time() + 100
T.check("flood not yet over (ours)", has(grubokkNpc:say(s1, "flood"), "You not done that yet!"))
s1.storage[S.Survival] = 4 -- got out in time (server test)
y = grubokkNpc:say(s1, "flood")
T.check("tunnels flooded, reward (EN)", has(y, "Good job, have eaten well!") and has(y, "Tasty sauce. Took it off goblin, you keep!") and given(s1, K.OPAL) == 5 and given(s1, K.RUST_REMOVER) == 2 and s1.storage[S.Survival] == 5, y)
q = grubokkNpc:say(s1, "mission")
T.check("again only after 00:00 (ours)", has(q, "Come back tomorrow") and s1.storage[S.GoblinsWait] > os.time(), q)
grubokkNpc:say(s1, "bye")
-- the goblins the same day (BR: Grubokk first, then the goblins)
nibbleNpc:say(s1, "hi")
q = nibbleNpc:say(s1, "mission")
T.check("goblins wait for the next day as well (ours)", has(q, "Come back tomorrow"), q)
nibbleNpc:say(s1, "bye")
s1.storage[S.GoblinsWait] = os.time() - 1
-- Grubokk's task running: the goblins refuse
local s2 = player()
grubokkNpc:say(s2, "hi") grubokkNpc:say(s2, "mission") grubokkNpc:say(s2, "yes") grubokkNpc:say(s2, "no help goblin") grubokkNpc:say(s2, "bye")
nibbleNpc:say(s2, "hi")
q = nibbleNpc:say(s2, "mission")
T.check("Nibble refuses Grubokk's helper (EN: not both at once; line ours)", has(q, "You smell of Grubokk!"), q)
nibbleNpc:say(s2, "bye")

-- ------------------------------------------------------------------ Revolt of the Goblins
local r = player()
T.check("Nibble greeting (EN)", has(nibbleNpc:say(r, "hi"), "Vile smell about you."))
q = nibbleNpc:say(r, "mission")
T.check("Nibble's offer (EN)", q == "Shshsh! Not so loud! ... You help? Be goblin champion?", q)
y = nibbleNpc:say(r, "yes")
T.check("holy bog frogs (EN)", has(y, "Food most urgent!") and has(y, "Bring twenty to poor imprisoned goblins before they dead!") and r.storage[S.Revolt] == 1, y)
nibbleNpc:say(r, "bye")
T.check("Imprisoned Goblin greeting (EN)", prisoner:say(r, "hi") == "What want with starving goblin, hu-man?")
q = prisoner:say(r, "frog god")
T.check("asks who sent you (EN)", q == "You help? You come from Golozo Taku Narkat Kash Bartak Har-Alhad?", q)
y = prisoner:say(r, "yes")
T.check("no frogs yet (ours)", has(y, "You no have twenty holy frogs!"), y)
r.items[K.DEAD_FROG] = 20
prisoner:say(r, "mission")
y = prisoner:say(r, "yes")
T.check("frogs delivered (EN)", has(y, "You bring holy food to starved goblins!") and has(y, "Will be right back.") and r.items[K.DEAD_FROG] == 0 and r.storage[S.Revolt] == 2, y)
q = prisoner:say(r, "mission")
T.check("weapon mission (EN)", has(q, "You want to help goblin cause?") and has(q, "You will remember password if I tell?"), q)
y = prisoner:say(r, "yes")
local pwIndex = r.storage[S.RevoltPassword]
local pw = K.PASSWORDS[pwIndex]
T.check("password (EN)", pw ~= nil and y == "I will tell you. Password for you to make goblins trust is '" .. pw.name .. "'. You not forget that! No further hint!" and r.storage[S.Revolt] == 3, y)
q = prisoner:say(r, "new password")
T.check("new password (EN)", q == "You forgot password! Oh no! Me give you new one, yes?", q)
y = prisoner:say(r, "yes")
local newIndex = r.storage[S.RevoltPassword]
T.check("a different password", newIndex ~= pwIndex and has(y, K.PASSWORDS[newIndex].name), y)
pw = K.PASSWORDS[newIndex]
prisoner:say(r, "bye")
local wrongPw = K.PASSWORDS[newIndex % 3 + 1]
local eg = exile:say(r, "hi")
T.check("exile's quest greeting (EN)", eg == "A hu-man! Golden eyes brought strange guest! Who sent you?", eg)
local lie = exile:say(r, wrongPw.word)
T.check("wrong password (EN)", lie == "No! You lie! That not true. Golden eyes averted from you!" and r.storage[wrongPw.storage] ~= 1, lie)
local ok = exile:say(r, pw.word)
T.check("right password opens the door (EN for Swordfish)", has(ok, "I trust you.") and r.storage[pw.storage] == 1 and (pw.word ~= "swordfish" or ok == pw.exile), ok)
exile:say(r, "bye")
T.check("Runaway Goblin greeting (EN)", runawayNpc:say(r, "hi") == "Hu-man! Strange guest! What want? Say!")
T.check("runaway hushes about missions (EN)", runawayNpc:say(r, "mission") == "<puts finger to his lips>")
T.check("runaway knows nothing about weapons (EN)", runawayNpc:say(r, "lance") == "Me not know anything!")
T.check("runaway: wrong password (EN)", runawayNpc:say(r, wrongPw.word) == "No talk! Get new password from friend in mines! Then we talk!")
q = runawayNpc:say(r, pw.word)
T.check("runaway: right password (EN)", has(q, "Correct! You friend from friends in mines!") and has(q, "You have holy weapon?"), q)
y = runawayNpc:say(r, "yes")
T.check("no weapon yet (ours)", has(y, "No holy weapon with you!"), y)
r.items[pw.weapon] = 1 -- from the greasy stone in its cave (server test)
runawayNpc:say(r, pw.word)
y = runawayNpc:say(r, "yes")
T.check("weapon given (EN for the crossbow)", y == pw.runaway and r.items[pw.weapon] == 0 and r.storage[S.Revolt] == 4 and r.storage[pw.storage] == -1, y)
runawayNpc:say(r, "bye")
prisoner:say(r, "hi")
q = prisoner:say(r, "mission")
T.check("water wheels (EN)", has(q, "You found holy weapon, you say?") and has(q, "Ten wheels must function if goblins to survive!") and r.storage[S.Revolt] == 5, q)
q = prisoner:say(r, "mission")
T.check("wheels still clogged (ours)", has(q, "Wheels still clogged!"), q)
r.storage[S.RevoltWheels] = 10
q = prisoner:say(r, "mission")
T.check("goblins' reward (EN)", q == "I hear sound of water wheels turning! Good job, hu-man! Here, take reward from me! Belonged to trusted friend, may be of use to you now he dead!" and given(r, K.ONYX_CHIP) == 5 and given(r, K.RUSTED_HELMET) == 1 and given(r, K.RUSTED_SHIELD) == 1 and r.storage[S.Revolt] == 6, q)
prisoner:say(r, "bye")
T.check("exile's normal greeting outside the mission (EN)", exile:say(r, "hi") == "Hello, hu-man! Away put your weapon, I am meaning no harm.")
exile:say(r, "bye")

-- ------------------------------------------------------------------ Vuzrog
local v = player({ vocation = 4 })
T.check("Vuzrog greeting (EN)", vuzrogNpc:say(v, "hi") == "Hello, tasty little snack.")
q = vuzrogNpc:say(v, "mission")
T.check("Vuzrog's menu (EN)", has(q, "Vuzrog hungry! Vuzrog needs food, very much food!") and has(q, "You find food for Vuzrog, yummy titch?"), q)
y = vuzrogNpc:say(v, "yes")
T.check("the menu (EN)", has(y, "Not raw but roasted.") and has(y, "Bring some bottles for dessert.") and v.storage[S.Menu] == 1, y)
q = vuzrogNpc:say(v, "mission")
T.check("asks for the food (EN)", q == "You bringing food for Vuzrog?", q)
y = vuzrogNpc:say(v, "yes")
T.check("food missing (ours)", has(y, "Not enough food!") and has(y, "10 roasted meat"), y)
local function food(p)
	for _, f in ipairs(K.FOOD) do p.items[f.id] = (p.items[f.id] or 0) + f.count end
end
food(v)
vuzrogNpc:say(v, "mission")
y = vuzrogNpc:say(v, "yes")
T.check("meal eaten (EN)", has(y, "Yum! That great meal!") and has(y, "You want little reward?") and v.storage[S.Menu] == 3 and v.items[22187] == 0, y)
y = vuzrogNpc:say(v, "yes")
T.check("pretty stones and the next task (EN)", has(y, "You taking this. Pretty stones.") and has(y, "You want do other thing for Vuzrog?") and given(v, K.OPAL) == 5 and v.storage[S.Menu] == 2 and v.storage[S.MenuTimes] == 1, y)
y = vuzrogNpc:say(v, "yes")
T.check("The Thunder Tusk Clan (EN)", has(y, "Other tribe is Thunder Tusk Clan.") and has(y, "Then come back and Vuzrog be grateful!") and v.storage[S.ThunderTusk] == 1, y)
q = vuzrogNpc:say(v, "mission")
T.check("asks about the kills (EN)", q == "You killed stupid riffraff?", q)
y = vuzrogNpc:say(v, "yes")
T.check("not enough kills (ours)", has(y, "Not enough!"), y)
v.storage[S.ThunderTuskKills] = 200
vuzrogNpc:say(v, "mission")
y = vuzrogNpc:say(v, "yes")
T.check("Thunder Tusk reward: 10 great health potions for a knight (EN)", has(y, "Chieftain now allows Mugruu trade with human.") and has(y, "you can bring more food, useful titch.") and given(v, 239) == 10 and v.storage[S.ThunderTusk] == 2, y)
q = vuzrogNpc:say(v, "mission")
T.check("not hungry until 00:00 (ours)", has(q, "Vuzrog not hungry now"), q)
v.storage[S.MenuWait] = os.time() - 1
q = vuzrogNpc:say(v, "mission")
T.check("more food? (EN)", q == "You will bring more food for Vuzrog?", q)
y = vuzrogNpc:say(v, "yes")
T.check("the short menu (EN)", y == "Very good! Bring roasted meat, beer, cookies, cake and prickly pear juice!" and v.storage[S.Menu] == 1, y)
food(v)
q = vuzrogNpc:say(v, "mission")
T.check("food again? (EN)", q == "You bringing food for Vuzrog again?", q)
y = vuzrogNpc:say(v, "yes")
T.check("meal again (EN)", y == "Yum! That great meal! Vuzrog very pleased. Want more pretty stones?", y)
y = vuzrogNpc:say(v, "yes")
T.check("stones again (EN)", y == "Here, taking pretty shimmering stones. Bring more food tomorrow!" and given(v, K.OPAL) == 10 and v.storage[S.MenuTimes] == 2, y)
v.storage[S.MenuWait] = os.time() - 1
vuzrogNpc:say(v, "mission") vuzrogNpc:say(v, "yes")
food(v)
vuzrogNpc:say(v, "mission") vuzrogNpc:say(v, "yes") vuzrogNpc:say(v, "yes")
T.check("Ogre Chef after three meals (EN)", v:hasAchievement("Ogre Chef") and v.storage[S.MenuTimes] == 3)
T.check("Vuzrog farewell (EN)", vuzrogNpc:say(v, "bye") == "Push off!")
local m = player({ vocation = 1 })
local mg = vuzrogNpc
m.storage[S.Menu] = 2 m.storage[S.MenuTimes] = 1 m.storage[S.ThunderTusk] = 1 m.storage[S.ThunderTuskKills] = 200
mg:say(m, "hi") mg:say(m, "mission") mg:say(m, "yes")
T.check("great mana potions for a sorcerer (EN)", given(m, 238) == 10)
mg:say(m, "bye")

-- ------------------------------------------------------------------ Mugruu
T.check("Mugruu greeting (EN)", mugruu:say(r, "hi") == "Hello tasty!")
T.check("Mugruu missions (EN)", mugruu:say(r, "mission") == "Ask {Ghorza} or {Vuzrog}. Or perhaps ask {Grubokk}, too.")
local mt = mugruu:say(r, "trade")
T.check("Mugruu refuses before Thunder Tusk (EN)", has(mt, "Mugruu not trading with human. Only if chieftain says yes. Back off!"), mt)
mugruu:say(r, "bye")
mugruu:say(v, "hi")
mt = mugruu:say(v, "trade")
T.check("Mugruu trades after Thunder Tusk", not has(mt, "Mugruu not trading"), mt)
mugruu:say(v, "bye")

-- ------------------------------------------------------------------ The Call of the Wild
local c = player()
c.storage[S.HungryNewWorld] = 6
c.storage[S.GreatHunger] = 6
c.storage[S.Thirst] = 5
c.storage[S.Survival] = 5
c.storage[S.Revolt] = 6
c.storage[S.Menu] = 2
c.storage[S.ThunderTusk] = 1
c.storage[S.ThunderTuskKills] = 200
vuzrogNpc:say(c, "hi") vuzrogNpc:say(c, "mission") vuzrogNpc:say(c, "yes")
T.check("The Call of the Wild with all seven (EN)", c:hasAchievement("The Call of the Wild"))
local c2 = player()
c2.storage[S.HungryNewWorld] = 6 c2.storage[S.GreatHunger] = 6 c2.storage[S.Thirst] = 5 c2.storage[S.Survival] = 5
c2.storage[S.Revolt] = 0 c2.storage[S.Menu] = 2 c2.storage[S.ThunderTusk] = 1 c2.storage[S.ThunderTuskKills] = 200
vuzrogNpc:say(c2, "hi") vuzrogNpc:say(c2, "mission") vuzrogNpc:say(c2, "yes")
T.check("not without the goblins' mission (EN)", not c2:hasAchievement("The Call of the Wild"))

for _, name in ipairs({ "Vuzrog", "Grubokk", "Nibble", "An Imprisoned Goblin", "A Goblin Exile", "A Runaway Goblin", "Mugruu" }) do
	local talk = ({ ["Vuzrog"] = vuzrogNpc, ["Grubokk"] = grubokkNpc, ["Nibble"] = nibbleNpc, ["An Imprisoned Goblin"] = prisoner, ["A Goblin Exile"] = exile, ["A Runaway Goblin"] = runawayNpc, ["Mugruu"] = mugruu })[name]
	checkLore(name, talk, player)
end
T.check("log texts for the four goblin and ogre missions", (function()
	for i = 1, 5 do if not K.log.survival[i] then return false end end
	for i = 1, 6 do if not K.log.revolt[i] then return false end end
	return K.log.menu[1] and K.log.menu[3] and K.log.tusk[2] and type(K.log.tusk[1](v)) == "string" and type(K.log.menu[2](v)) == "string"
end)())

T.finish()
