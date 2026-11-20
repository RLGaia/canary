-- Gaia Family server: Kissing a Pig Quest check (2026-11-20). One character learns all seven
-- kissing lessons (world steps set as storages or items) with the lines of the TibiaWiki BR page
-- and the TibiaWiki EN spoiler, kisses the pig after each lesson, and then gets Theodore Loveless'
-- key for a kiss (The Thieves Guild). Run from the repository root:
--   luajit tools/family/npc_talk/kissing_pig.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z, sendMagicEffect = function() end } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
PLAYERSEX_FEMALE = PLAYERSEX_FEMALE or 0
PLAYERSEX_MALE = PLAYERSEX_MALE or 1
CONDITION_DRUNK = CONDITION_DRUNK or 11
CONST_ME_HEARTS = CONST_ME_HEARTS or 49
CONST_ME_CRAPS = CONST_ME_CRAPS or 26
os.time = os.time
dofile("data-otservbr-global/lib/others/family_kissing_pig.lua")
local FK = FamilyKissing
local S = FK.S
local TG = Storage.Quest.U8_2.TheThievesGuildQuest

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
local function has(text, s) return (text:gsub("[{}]", "")):find(s, 1, true) ~= nil end
local function given(p, id)
	local n = 0
	for _, a in ipairs(p.added) do
		if a[1] == id then n = n + a[2] end
	end
	return n
end

local pig = T.load("data-otservbr-global/npc/pig.lua")
local hoggle = T.load("data-otservbr-global/npc/hoggle.lua")
local caramellia = T.load("data-otservbr-global/npc/caramellia.lua")
local elvith = T.load("data-otservbr-global/npc/elvith.lua")
local olrik = T.load("data-otservbr-global/npc/olrik.lua")
local lynda = T.load("data-otservbr-global/npc/lynda.lua")
local zebron = T.load("data-otservbr-global/npc/zebron.lua")
local budrik = T.load("data-otservbr-global/npc/budrik.lua")
local ghost = T.load("data-otservbr-global/npc/a_dwarven_ghost.lua")
local tim = T.load("data-otservbr-global/npc/toothless_tim.lua")
local bertram = T.load("data-otservbr-global/npc/bertram.lua")
local chantalle = T.load("data-otservbr-global/npc/chantalle.lua")

local p = player({ money = 10000, sex = PLAYERSEX_FEMALE })

local function kissPig(expect, name)
	pig:say(p, "hi")
	local k = pig:say(p, "kiss")
	local y = pig:say(p, "yes")
	pig:say(p, "bye")
	T.check(name, has(k, "Do you want to try to release me with a kiss?") and has(y, expect), y)
end

T.check("pig greeting (BR/EN)", pig:say(p, "hi") == "Oink.")
pig:say(p, "bye")
kissPig("You still have to learn everything about kissing.", "pig without a lesson (ours)")
T.check("quest log starts with the first kiss", p.storage[S.Questline] == 1)

-- 1 Hoggle and Caramellia
T.check("Hoggle greeting (BR/EN)", hoggle:say(p, "hi") == "Welcome to my humble home!")
local g = hoggle:say(p, "garden")
T.check("Hoggle's garden (EN)", has(g, "my back is aching like hell") and has(g, "I'll give you 5 shiny pieces of gold for this job. Is this a deal?"), g)
local y = hoggle:say(p, "yes")
T.check("garden job taken, gate opens (EN)", has(y, "rattle at the garden gate") and p.storage[S.Hoggle] == 1, y)
T.check("garden before mowing (ours)", has(hoggle:say(p, "garden"), "when you are finished"))
hoggle:say(p, "bye")
p.storage[S.Hoggle] = 2 -- the lawn-mowing square (server test)
hoggle:say(p, "hi")
local money = p.money
g = hoggle:say(p, "garden")
T.check("Hoggle pays 5 gold (EN)", has(g, "Don't spend it on alcohol or tobacco!") and p.money - money == 5 and p.storage[S.Hoggle] == 3, g)
hoggle:say(p, "bye")
T.check("Caramellia greeting (BR/EN)", caramellia:say(p, "hi") == "Hello.")
local w = caramellia:say(p, "winfred")
T.check("Caramellia about Winfred (BR)", has(w, "He was my one and only true love."), w)
local t = caramellia:say(p, "true love never dies")
T.check("true love never dies (BR/EN)", has(t, "Those were his words, weren't they?"), t)
y = caramellia:say(p, "yes")
T.check("Caramellia's lesson (BR/EN)", has(y, "Keep this in mind and your life will improve and so will your kisses.") and p.storage[S.Caramellia] == 1, y)
caramellia:say(p, "bye")
kissPig("But you are FAR from being the best kisser in the land.", "pig after 1 lesson (BR/EN)")

-- 2 Elvith
elvith:say(p, "hi")
local k = elvith:say(p, "kiss")
T.check("Elvith wants a poem (BR/EN)", has(k, "Write a good love poem and then show it to me") and has(k, "You can buy poetry parchment at the Thaian embassy.") and p.storage[S.Elvith] == 1, k)
elvith:say(p, "poem")
T.check("a ruined poem does not impress (ours)", has(elvith:say(p, "yes"), "Come back with a perfect one."))
elvith:say(p, "bye")
olrik:say(p, "hi")
olrik:say(p, "poetry parchment")
olrik:say(p, "yes")
T.check("Olrik sells a blank poetry parchment for 60 (BR)", given(p, FK.BLANK_POEM) == 1)
local shop = false
for _, it in ipairs(olrik.type.config.shop or {}) do
	if it.clientId == FK.BLANK_POEM and it.buy == 60 then shop = true end
end
T.check("blank poetry parchment in Olrik's trade window (EN)", shop)
olrik:say(p, "bye")
p.items[FK.POEM_DONE] = 1
elvith:say(p, "hi")
local po = elvith:say(p, "poem")
T.check("Elvith asks for the poem (BR/EN)", has(po, "Do you have a love poem that might impress me?"), po)
y = elvith:say(p, "yes")
T.check("Elvith's lesson (BR/EN)", has(y, "You are a pure genius!") and p.storage[S.Elvith] == 2 and p.items[FK.POEM_DONE] == 0, y)
T.check("'love poem' still sells his poem scroll", has(elvith:say(p, "love poem"), "Do you want to buy a poem scroll for 200 gold?"))
elvith:say(p, "bye")
kissPig("You definitely have some experience but you should improve your skill DRASTICALLY.", "pig after 2 lessons (BR/EN)")

-- 3 Lynda
lynda:say(p, "hi")
T.check("Lynda without ice cream (upstream line)", has(lynda:say(p, "ice cream"), "Ice cream?? What ... ice cream you are talking about?"))
p.items[FK.ICE_CREAM] = 1
local ic = lynda:say(p, "venorean ice cream")
T.check("Lynda sees the ice cream (BR/EN)", has(ic, "Are you saying you have ... some Venorean ice cream for me???"), ic)
y = lynda:say(p, "yes")
T.check("Lynda's lesson (BR/EN)", has(y, "To truly love is pure happiness of heart and soul.") and p.storage[S.Lynda] == 1, y)
lynda:say(p, "bye")
kissPig("Oh my, you have learnt a few tricks indeed.", "pig after 3 lessons (BR/EN)")

-- 4 Zebron
zebron:say(p, "hi")
k = zebron:say(p, "kiss")
T.check("Zebron about kissing (BR/EN)", has(k, "I might share them with someone worthy."), k)
local wo = zebron:say(p, "worthy")
T.check("Zebron's dice offer (BR/EN)", has(wo, "beat me 3 times in a row"), wo)
local rolls = { { 5, 2 }, { 2, 6 }, { 6, 1 }, { 4, 3 }, { 3, 2 } }
local r = 0
FK.forceDice = function() r = r + 1 return rolls[r][1], rolls[r][2] end
money = p.money
local g1 = zebron:say(p, "yes")
T.check("first win (BR/EN)", has(g1, "You win with 5 over 2. You'll keep your 25 gold this time. Are you ready for another game?"), g1)
local g2 = zebron:say(p, "yes")
T.check("a lost game costs 25 gold and the row (ours)", has(g2, "I win with 6 over 2.") and money - p.money == 25, g2)
zebron:say(p, "yes")
zebron:say(p, "yes")
local g5 = zebron:say(p, "yes")
T.check("three in a row: Zebron's lesson (BR/EN)", has(g5, "You've beaten me 3 times in a row, so what?") and p.storage[S.Zebron] == 1, g5)
FK.forceDice = nil
local bz = zebron:say(p, "bye")
T.check("Zebron's farewell (BR/EN)", has(bz, "Hey, you can't leave. Luck is smiling on you."), bz)
kissPig("Not bad, not bad at all! But you can still improve your skill a LOT.", "pig after 4 lessons (BR/EN)")

-- 5 Budrik and the dwarven ghost
budrik:say(p, "hi")
local pk = budrik:say(p, "pick")
T.check("Budrik asks for the picks (BR/EN)", has(pk, "You brought the picks?"), pk)
T.check("no picks, no tunnel (ours)", has(budrik:say(p, "yes"), "Bring me 5 picks") and p.storage[S.Grothmok] == nil)
p.items[FK.PICK] = 5
budrik:say(p, "pick")
y = budrik:say(p, "yes")
T.check("Grothmok permission for 5 picks (BR/EN)", has(y, "I grant you permission to enter the Grothmok tunnels.") and p.storage[S.Grothmok] == 1 and p.items[FK.PICK] == 0, y)
budrik:say(p, "bye")
local gg = ghost:say(p, "hi")
T.check("ghost greeting (BR/EN)", gg == "Do not disturb the dead for nothing, mortal.", gg)
k = ghost:say(p, "kiss")
T.check("ghost about kissing (BR/EN)", has(k, "One favour by you to gain a favour of me."), k)
local fv = ghost:say(p, "favour")
T.check("ghost's favour (BR/EN)", has(fv, "In my drawer you will find ... a false beard") and p.storage[S.DwarvenGhost] == 1, fv)
T.check("'favor' is not understood (EN)", ghost:say(p, "favor") == "")
T.check("beard not burnt yet (ours)", has(ghost:say(p, "beard"), "Burn it in the coal basin"))
local gb = ghost:say(p, "bye")
T.check("ghost farewell (BR/EN)", gb == "Death will find you, too.", gb)
p.storage[S.DwarvenGhost] = 2 -- burnt in the basin (server test)
ghost:say(p, "hi")
local bd = ghost:say(p, "beard")
T.check("ghost's lesson (BR/EN)", has(bd, "Now you know as much about kissing as I did during my lifetime.") and p.storage[S.DwarvenGhost] == 3, bd)
ghost:say(p, "bye")
kissPig("But you STILL lack the refinement of perfection.", "pig after 5 lessons (BR/EN)")

-- 6 Toothless Tim
local sober = tim:say(p, "hi")
T.check("Tim sober: mumbling (ours greeting)", sober == FK.timSoberGreet, sober)
T.check("Tim sober 'kiss' mumbles (upstream)", has(tim:say(p, "kiss"), "Shmmm gahhh"))
tim:say(p, "bye")
p.conditions[CONDITION_DRUNK] = true
FK.onDrink(p)
FK.onDrink(p)
tim:say(p, "hi")
T.check("two drinks are not enough", has(tim:say(p, "kiss"), "Shmmm gahhh"))
tim:say(p, "bye")
FK.onDrink(p)
local dg = tim:say(p, "hi")
T.check("Tim drunk greeting (BR/EN)", dg == FK.timDrunkGreet, dg)
k = tim:say(p, "kiss")
T.check("Tim about kissing (BR/EN)", has(k, "Would you like to learn more about kissing?"), k)
local y1 = tim:say(p, "yes")
T.check("Tim prepared? (BR/EN)", has(y1, "Are you prepared?"), y1)
local y2 = tim:say(p, "yes")
T.check("Tim kisses a lady (EN)", has(y2, "It's been a while since I kissed a lady.") and p.storage[S.ToothlessTim] == 1, y2)
local tb = tim:say(p, "bye")
T.check("Tim farewell (BR/EN)", tb == FK.timFarewell, tb)
p.conditions[CONDITION_DRUNK] = nil
local pm = player({ sex = PLAYERSEX_MALE })
pm.conditions[CONDITION_DRUNK] = true
FK.onDrink(pm) FK.onDrink(pm) FK.onDrink(pm)
tim:say(pm, "hi") tim:say(pm, "kiss") tim:say(pm, "yes")
T.check("Tim kisses a guy (BR/EN)", has(tim:say(pm, "yes"), "You don't kiss bad for a guy."))
kissPig("I fear there's still something to learn for you.", "pig after 6 lessons (BR/EN)")
T.check("not finished before the Queen's kiss", p.storage[S.Questline] == 1 and p.storage[S.FirlefanzDoor] == nil)

-- 7 The Queen of the Banshees (her kiss is the last seal of her quest)
p.storage[Storage.Quest.U7_2.TheQueenOfTheBanshees.LastSeal] = 1
pig:say(p, "hi")
pig:say(p, "kiss")
local fin = pig:say(p, "yes")
T.check("pig's confession (BR/EN)", has(fin, "There is no curse.") and has(fin, "You should find a chest there containing the mighty Firlefanz."), fin)
T.check("quest finished, basement door open", p.storage[S.Questline] == 2 and p.storage[S.FirlefanzDoor] == 1)
T.check("Passionate Kisser (BR/EN)", p:hasAchievement("Passionate Kisser"))
T.check("pig after the end (ours)", has(pig:say(p, "kiss"), "Look in the basement"))
pig:say(p, "bye")
local quest = dofile("data-otservbr-global/lib/core/quests/catalog/061_kissing_a_pig.lua")
T.check("quest log entry", quest.missions[1].states[2] ~= nil and quest.startStorageId == S.Questline)

-- The Thieves Guild, Mission 6, fourth way (BR)
p.storage[TG.Mission06] = 1
bertram:say(p, "hi")
k = bertram:say(p, "kiss")
T.check("Bertram: the queen of kisses (BR)", has(k, "Oh, I've heard you are the queen of kisses, is that true???"), k)
y1 = bertram:say(p, "yes")
T.check("Bertram's deal (BR)", has(y1, "I'd give you the key you are looking for in exchange for a kiss! Are you interested?"), y1)
y2 = bertram:say(p, "yes")
T.check("key for a kiss (BR)", has(y2, "Here is .. your key!") and given(p, 7934) == 1 and p.storage[TG.Mission06] == 2, y2)
bertram:say(p, "bye")
local m = player({ sex = PLAYERSEX_MALE })
m.storage[S.Questline] = 2
m.storage[TG.Mission06] = 1
chantalle:say(m, "hi")
k = chantalle:say(m, "kiss")
T.check("Chantalle: the king of kisses (ours)", has(k, "king of kisses"), k)
chantalle:say(m, "yes")
chantalle:say(m, "yes")
T.check("Chantalle gives the key for a kiss", given(m, 7934) == 1 and m.storage[TG.Mission06] == 2)
local nk = player({ sex = PLAYERSEX_FEMALE })
nk.storage[TG.Mission06] = 1
bertram:say(nk, "hi")
T.check("no key for a kiss before the pig", not has(bertram:say(nk, "kiss"), "queen of kisses"))

T.finish()
