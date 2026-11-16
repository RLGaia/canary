-- Gaia Family server: The White Raven Monastery Quest check (2026-11-16): one character plays the
-- quest with Dalbrect and Costello (brooch, friendship, passage, Fugio, diary, reward), the states the
-- wikis do not show (no brooch, no diary, asking again, talking without a greeting), the quest log
-- and every {highlighted} word. NPC lines are TibiaWiki BR/EN unless marked as ours in the NPC files.
-- Run from the repository root:
--   luajit tools/family/npc_talk/white_raven.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
local check = T.check

Position = Position or function(x, y, z) return { x = x, y = y, z = z } end

local S = Storage.Quest.U7_24
local W = S.TheWhiteRavenMonastery
local dalbrect = T.load("data-otservbr-global/npc/dalbrect.lua")
local costello = T.load("data-otservbr-global/npc/costello.lua")

local function has(text, part)
	return (text or ""):find(part, 1, true) ~= nil
end

local p = T.player({ level = 20, money = 1000 })

-- Dalbrect: story (TibiaWiki BR/EN)
local a = dalbrect:say(p, "hi")
check("Dalbrect greets", has(a, "Be greeted, traveller") and has(a, "Welcome to my {hut}."), a)
check("job = hut line (BR/EN)", has(dalbrect:say(p, "job"), "humble fisher"))
check("legacy", has(dalbrect:say(p, "legacy"), "fate} turned against us"))
check("fate", has(dalbrect:say(p, "fate"), "put their fortune in that {project}"))
check("project", has(dalbrect:say(p, "project"), "If I only had something as a reminder"))
check("passage before friendship (BR/EN)", has(dalbrect:say(p, "passage"), "I dare not anger the monks"))

-- brooch without the brooch
check("brooch question", has(dalbrect:say(p, "brooch"), "You want me to examine a brooch?"))
check("yes without brooch (EN)", has(dalbrect:say(p, "yes"), "too poor to be interested in jewelry"))
dalbrect:say(p, "brooch")
check("no (BR/EN)", has(dalbrect:say(p, "no"), "Then stop being a fool"))
check("family brooch phrase still reaches the brooch talk", has(dalbrect:say(p, "family brooch"), "examine a brooch"))
dalbrect:say(p, "no")

-- brooch from the coffin
p.storage[S.FamilyBrooch.Brooch] = 1
p.items[3205] = 1
dalbrect:say(p, "brooch")
check("yes with brooch (BR/EN)", has(dalbrect:say(p, "yes"), "I recognise my family's arms"))
a = dalbrect:say(p, "yes")
check("brooch handed over (BR/EN)", has(a, "I shall consider you my friend"), a)
check("brooch removed", (p.items[3205] or 0) == 0)
check("Passage storage 1", p.storage[W.Passage] == 1)
check("quest log started", p.storage[W.QuestLog] == 1)
check("need (EN)", has(dalbrect:say(p, "need"), "a trip with my boat"))
a = dalbrect:say(p, "passage")
check("passage as friend (BR/EN)", has(a, "Since you are my friend now I will sail you to the isle of the kings for 10 gold. Is that okay for you?"), a)
a = dalbrect:say(p, "yes")
check("trip (BR/EN): Have a nice trip!", has(a, "Have a nice trip!"), a)
check("10 gold paid, landed on the Isle", p.money == 990 and p.teleported and p.teleported.x == 32190 and p.teleported.y == 31957 and p.teleported.z == 6, p.money)
dalbrect:say(p, "hi")
check("brooch again after friendship", has(dalbrect:say(p, "brooch"), "You have recovered my brooch"))
dalbrect:say(p, "bye")

-- Costello: no answers without a greeting
p.storage[S.FamilyBrooch.Brooch] = 1
a = costello:say(p, "fugio")
check("Costello ignores 'fugio' before hi", not has(a, "omen"), a)
a = costello:say(p, "hi")
check("Costello greets", has(a, "Feel free to tell me"), a)
check("fugio (BR/EN)", has(costello:say(p, "fugio"), "I fear the omen in my dreams may be true"))
check("yes: warded doors (BR/EN)", has(costello:say(p, "yes"), "you may open the warded doors"))
check("Diary 1, Door 1", p.storage[W.Diary] == 1 and p.storage[W.Door] == 1)
a = costello:say(p, "fugio")
check("fugio again does not ask again", not has(a, "willing to investigate"), a)
costello:say(p, "yes")
check("Diary still 1", p.storage[W.Diary] == 1)

-- diary without the book
costello:say(p, "diary")
a = costello:say(p, "yes")
check("diary yes without book", has(a, "as you wish"), a)
check("no ankh yet", (p.items[3214] or 0) == 0)

-- diary with the book
p.items[3212] = 1
check("diary (BR/EN)", has(costello:say(p, "diary"), "Do you want me to inspect a diary?"))
a = costello:say(p, "yes")
check("reward line (BR/EN)", has(a, "Take this blessed Ankh"), a)
check("blessed ankh given, diary taken", (p.items[3214] or 0) == 1 and (p.items[3212] or 0) == 0)
check("Diary 2", p.storage[W.Diary] == 2)
check("diary afterwards (BR)", has(costello:say(p, "diary"), "Thank you again for handing me that diary"))
costello:say(p, "fugio")
costello:say(p, "yes")
check("fugio + yes after the end keeps Diary 2", p.storage[W.Diary] == 2)
check("holy water outside Rest in Hallowed Ground (BR)", has(costello:say(p, "holy water"), "very special but no one knows why"))
check("bye (BR/EN)", has(costello:say(p, "bye"), "Good bye, "))

-- Quest log
local quest = dofile("data-otservbr-global/lib/core/quests/catalog/030_the_white_raven_monastery.lua")
local m1, m2 = quest.missions[1], quest.missions[2]
check("mission 1 done at Passage 1", p.storage[m1.storageId] >= m1.endValue and m1.states[p.storage[m1.storageId]] ~= nil)
check("mission 2 done at Diary 2", p.storage[m2.storageId] >= m2.endValue and m2.states[p.storage[m2.storageId]] ~= nil)

-- Highlighted words
T.checkHints(dalbrect, function()
	return T.player({ storage = { [W.Passage] = 1 } })
end)
T.checkHints(costello, function()
	return T.player({})
end)

T.finish()
