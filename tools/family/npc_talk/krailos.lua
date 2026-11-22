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

T.finish()
