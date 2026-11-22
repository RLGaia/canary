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

T.finish()
