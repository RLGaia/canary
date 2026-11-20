-- Gaia Family server: The Thieves Guild Quest check (2026-11-20). One character plays the
-- quest's NPC side from joining Dorian to Black Bert (world steps set as storages or items), with
-- the lines of the TibiaWiki EN spoiler transcripts and the TibiaWiki BR page. Run from the
-- repository root:
--   luajit tools/family/npc_talk/thieves_guild.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z, sendMagicEffect = function() end } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
dofile("data-otservbr-global/lib/others/family_thieves_guild.lua")
local FT = FamilyThieves
local S = Storage.Quest.U8_2.TheThievesGuildQuest
local POST = Storage.Quest.U7_24.ThePostmanMissions
PLAYERSEX_FEMALE = PLAYERSEX_FEMALE or 0
PLAYERSEX_MALE = PLAYERSEX_MALE or 1

local function player(o)
	local p = T.player(o)
	p.achievements = {}
	p.xp = 0
	rawset(p, "addAchievement", function(self, name) self.achievements[#self.achievements + 1] = name return true end)
	rawset(p, "hasAchievement", function(self, name)
		for _, a in ipairs(self.achievements) do
			if a == name then return true end
		end
		return false
	end)
	rawset(p, "addExperience", function(self, n) self.xp = self.xp + n end)
	rawset(p, "getSlotItem", function(self, slot) return self.head and { itemid = self.head } or nil end)
	rawset(p, "getOutfit", function(self) return { lookType = self.look or 128 } end)
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

local dorian = T.load("data-otservbr-global/npc/dorian.lua")
local oswald = T.load("data-otservbr-global/npc/oswald.lua")
local snake = T.load("data-otservbr-global/npc/snake_eye.lua")
local ahmet = T.load("data-otservbr-global/npc/ahmet.lua")
local percy = T.load("data-otservbr-global/npc/percybald.lua")
local nurik = T.load("data-otservbr-global/npc/nurik.lua")
local chantalle = T.load("data-otservbr-global/npc/chantalle.lua")
local herbert = T.load("data-otservbr-global/npc/herbert.lua")
local carina = T.load("data-otservbr-global/npc/carina.lua")
local bertram = T.load("data-otservbr-global/npc/bertram.lua")
local bert = T.load("data-otservbr-global/npc/black_bert.lua")

local p = player({ money = 100000 })

-- Black Bert before the quest
bert:say(p, "hi")
local tr = bert:say(p, "trade")
T.check("Black Bert refuses before the quest (both wikis)", not rawget(p, "shopOpened") and has(tr, FT.blackBertRefusal), tr)
bert:say(p, "bye")

-- Mission 1
local g = dorian:say(p, "hi")
T.check("Dorian greeting (BR)", has(g, "Greetings, Tester!"), g)
local j = dorian:say(p, "thieves")
T.check("join question (EN)", has(j, "Do you want to join the thieves guild, Tester?"), j)
local y = dorian:say(p, "yes")
T.check("joined (EN)", has(y, "You'll learn this trade from scratch.") and p.storage[S.Questline] == 1, y)
local m = dorian:say(p, "mission")
T.check("mission 1 (EN)", has(m, "Collect 10 elephant tusks and bring them to me.") and p.storage[S.Mission01] == 1, m)
p.items[3044] = 10
dorian:say(p, "mission")
local r = dorian:say(p, "yes")
T.check("tusks delivered (EN)", has(r, "What a fine material.") and p.storage[S.Mission01] == 2 and p.items[3044] == 0, r)

-- Mission 2 (the chest itself is in the server test)
m = dorian:say(p, "mission")
T.check("mission 2 (EN)", has(m, "Sarina, the proprietor of Carlin's general store.") and p.storage[S.Mission02] == 1, m)
T.check("lock pick line (EN)", has(dorian:say(p, "lock pick"), "Yes, I sell lock picks. Ask me for a trade."))
p.storage[S.Mission02] = 2
p.items[FT.VASE] = 1
dorian:say(p, "mission")
r = dorian:say(p, "yes")
T.check("valuable vase delivered (EN)", has(r, "What an ugly vase.") and p.storage[S.Mission02] == 3 and p.items[FT.VASE] == 0, r)

-- Mission 3
m = dorian:say(p, "mission")
T.check("mission 3 (EN)", has(m, "Oswald to give out invitations") and p.storage[S.Mission03] == 1, m)
dorian:say(p, "bye")
oswald:say(p, "hi")
local i1 = oswald:say(p, "invitation")
T.check("Oswald invitation (EN)", has(i1, "It's not as if you were someone important, are you?"), i1)
local g1 = oswald:say(p, "gold")
T.check("Oswald gold (EN)", has(g1, "Not that I am bribeable but I doubt that you own 1000 gold pieces. Or do you?"), g1)
local y1 = oswald:say(p, "yes")
T.check("Oswald donation after gold (EN; upstream went nowhere)", has(y1, "If you donate 1000 gold to a fund I oversee"), y1)
local y2 = oswald:say(p, "yes")
T.check("invitation given (EN)", has(y2, "Excellent! Here is your invitation!") and given(p, 7933) == 1 and p.storage[S.Mission03] == 2, y2)
oswald:say(p, "bye")
local p2 = player({ money = 5000 })
p2.storage[S.Mission03] = 1
oswald:say(p2, "hi")
oswald:say(p2, "invitation")
oswald:say(p2, "yes")
T.check("Oswald BR path (invitation, yes, yes)", has(oswald:say(p2, "yes"), "Here is your invitation!") and p2.storage[S.Mission03] == 2)
dorian:say(p, "hi")
dorian:say(p, "mission")
r = dorian:say(p, "yes")
T.check("invitation delivered (EN)", has(r, "Ah, the key to untold riches.") and p.storage[S.Mission03] == 3, r)

-- Mission 4
m = dorian:say(p, "mission")
T.check("mission 4 (EN)", has(m, "Trade the false documents for the famous painting of Mina Losa") and p.storage[S.Mission04] == 1, m)
dorian:say(p, "bye")
snake:say(p, "hi")
local d = snake:say(p, "documents")
T.check("Snake Eye (EN)", has(d, "The best forger is old Ahmet in Ankrahmun.") and p.storage[S.Mission04] == 2, d)
snake:say(p, "bye")
local ga = ahmet:say(p, "hi")
T.check("Ahmet greeting (BR/EN start)", has(ga, "Be mourned pilgrim in flesh. I'm selling general goods."), ga)
local mi = ahmet:say(p, "mission")
T.check("Ahmet robbed (BR)", has(mi, "Want to earn some quick money?"), mi)
local ya = ahmet:say(p, "yes")
T.check("Ahmet job accepted, 100 experience (BR)", has(ya, "Maybe they hide at the oasis.") and p.xp == 100 and p.storage[S.StealFromThieves] == 1, ya)
d = ahmet:say(p, "documents")
T.check("Ahmet asks for a nomad (BR/EN)", has(d, "Go and kill at least one of them") and p.storage[S.Mission04] == 3, d)
T.check("no documents before the kill", ahmet:say(p, "documents") == "")
p.storage[S.Mission04] = 4 -- a nomad killed (creaturescripts_nomad_kill.lua)
d = ahmet:say(p, "documents")
T.check("documents after a nomad, without the bag (both wikis)", has(d, "The slayer of my enemies is my friend! For a mere 1000 gold"), d)
local yd = ahmet:say(p, "yes")
T.check("documents given (EN)", has(yd, "And here they are! Now forget where you got them from.") and given(p, 7866) == 1 and p.storage[S.Mission04] == 5, yd)
p.items[235] = 1
ahmet:say(p, "mission")
local rb = ahmet:say(p, "yes")
T.check("Ahmet's bag reward (BR: 100 gold, 100 brown mushrooms)", has(rb, "Here is the reward I promised you.") and given(p, 3031) == 100 and given(p, 3725) == 100, rb)
ahmet:say(p, "mission")
T.check("job experience only once", p.xp == 100)
ahmet:say(p, "bye")

percy:say(p, "hi")
local dg = percy:say(p, "disguise")
T.check("Percybald disguise (EN)", has(dg, "Grab a copy of a script from the prop room at the theatre cellar."), dg)
local lines = {
	{ "test", "I hope you learnt your role!" },
	{ "yes", "How dare you? Are you mad?" },
	{ "I don't think so, dear doctor!", "You've got this one right!" },
	{ "yes", "Too late puny knight." },
	{ "Watch out! It's a trap!", "You've got this one right!" },
	{ "yes", "What's this? Behind the doctor?" },
	{ "Look! It's Lucky, the wonder dog!", "You've got this one right!" },
	{ "yes", "how about hers!?" },
	{ "Oh no! Look! It's Princess Buttercup! He's holding her hostage!", "You've got this one right!" },
	{ "yes", "Grrr!" },
	{ "Ahhhhhh!", "You've got this one right!" },
	{ "yes", "You're such a monster!" },
	{ "Hahaha! Now drop your weapons or else...", "You've got this one right!" },
	{ "yes", "Here is your disguise kit!" },
}
local allOk = true
for _, l in ipairs(lines) do
	local a = percy:say(p, l[1])
	if not has(a, l[2]) then
		allOk = false
		T.check("Percybald test line '" .. l[1] .. "'", false, a)
	end
end
T.check("Percybald test passed (EN/BR lines)", allOk and given(p, FT.KIT) == 1 and p.storage[S.Mission04] == 6)
T.check("Amateur Actor (BR)", p:hasAchievement("Amateur Actor"))
p.items[FT.KIT] = 0 -- used up before meeting Nurik
local nk = percy:say(p, "test")
T.check("a new kit when the first was used up (ours)", given(p, FT.KIT) == 2 and has(nk, "Here is another one"), nk)
T.check("no second kit while carrying one", percy:say(p, "test") == "" and given(p, FT.KIT) == 2)
percy:say(p, "bye")

local gn = nurik:say(p, "hi")
T.check("Nurik waits without the disguise", has(gn, "I'm waiting for someone important!"), gn)
gn = nurik:say(p, "dwarven bridge")
T.check("no deal without the disguise (upstream: the refused greeting still talked)", has(gn, "I'm waiting for someone important!") and given(p, 7871) == 0, gn)
p.look = 66
gn = nurik:say(p, "hi")
T.check("Nurik greets the disguised ambassador (EN)", has(gn, "It's .. It's YOU! At last!!"), gn)
nurik:say(p, "dwarven bridge")
nurik:say(p, "yes")
nurik:say(p, "yes")
nurik:say(p, "yes")
local deal = nurik:say(p, "yes")
T.check("painting for the deed (EN)", has(deal, "Here is the painting you requested.") and given(p, 7871) == 1 and p.storage[S.Mission04] == 7, deal)
nurik:say(p, "bye")
p.look = nil
dorian:say(p, "hi")
dorian:say(p, "mission")
r = dorian:say(p, "yes")
T.check("painting delivered (EN)", has(r, "Excellent, that serves this fool right.") and p.storage[S.Mission04] == 8, r)

-- Mission 5
m = dorian:say(p, "mission")
T.check("mission 5 (EN)", has(m, "There is a hidden smugglers cave, north of town.") and p.storage[S.Mission05] == 1, m)
p.items[FT.GOBLET] = 1
p.storage[S.GoldenGoblet] = 1
dorian:say(p, "mission")
r = dorian:say(p, "yes")
T.check("stolen golden goblet delivered (EN)", has(r, "That goblet is hardly worth all this trouble") and p.storage[S.Mission05] == 2 and p.items[FT.GOBLET] == 0, r)

-- Mission 6
m = dorian:say(p, "mission")
T.check("mission 6 (EN)", has(m, "you won't crack this expensive masterpiece of a lock") and p.storage[S.Mission06] == 1, m)
dorian:say(p, "bye")
local gc = chantalle:say(p, "hi")
T.check("Chantalle greeting (BR/EN)", gc == "Hello.", gc)
local k = chantalle:say(p, "key")
T.check("Chantalle refuses (EN)", has(k, "Are you insane?! I'd never misuse the trust placed upon me") and has(k, "despite his handsome uniform."), k)
chantalle:say(p, "bye")
local gh = herbert:say(p, "hi")
T.check("Herbert greeting (EN)", has(gh, "At last! The audience arrives!"), gh)
local l1 = herbert:say(p, "letter")
T.check("Herbert letter (EN)", has(l1, "The trust in a postman is of more value than gold, you know?"), l1)
local l2 = herbert:say(p, "gold")
T.check("Herbert gold (EN)", has(l2, "About 1000?"), l2)
local money = p.money
local l3 = herbert:say(p, "yes")
T.check("letter bought (EN)", has(l3, "now let me count my glittering gold.") and given(p, 7940) == 1 and money - p.money == 1000, l3)
herbert:say(p, "bye")
carina:say(p, "hi")
local c1 = carina:say(p, "precious necklace")
T.check("Carina necklace (EN)", has(c1, "Oh, so you want to buy that rare and precious necklace for 5000 gold?"), c1)
local c2 = carina:say(p, "yes")
T.check("necklace bought (EN)", has(c2, "business is business.") and given(p, 7939) == 1 and p.items[7940] == 0, c2)
carina:say(p, "bye")
local carinaShop = false
for _, it in ipairs(carina.type.config.shop or {}) do
	if it.clientId == 7939 then carinaShop = true end
end
T.check("no precious necklace in Carina's trade window (BR)", not carinaShop)
chantalle:say(p, "hi")
k = chantalle:say(p, "key")
T.check("key for the necklace (EN)", has(k, "I know you want the key to the living room. There's our deal.") and given(p, FT.KEY) == 1 and p.storage[S.Mission06] == 2, k)
chantalle:say(p, "bye")

-- the uniform ways (archpostman, rank 5 or more)
local pm = player({})
pm.storage[S.Mission06] = 1
pm.storage[POST.Rank] = 5
pm.head = 3576
chantalle:say(pm, "hi")
k = chantalle:say(pm, "key")
T.check("archpostman gets the key from Chantalle (EN)", has(k, "You archpostmen are not only daring but also handsome.") and given(pm, FT.KEY) == 1, k)
local pf = player({ sex = 0 })
pf.storage[S.Mission06] = 1
pf.storage[POST.Rank] = 5
pf.head = 3576
local gb = bertram:say(pf, "hi")
T.check("Bertram greeting (BR)", has(gb, "Please don't interrupt me for too long!"), gb)
k = bertram:say(pf, "key")
T.check("archpostwoman gets the key from Bertram (EN)", has(k, "archpostwomen are not only daring but also beautiful") and given(pf, FT.KEY) == 1, k)
local pf2 = player({ sex = 0 })
pf2.storage[S.Mission06] = 1
bertram:say(pf2, "hi")
k = bertram:say(pf2, "key")
T.check("Bertram refuses without the uniform (BR)", has(k, "Are you insane?!") and given(pf2, FT.KEY) == 0, k)

-- (the door, the lock picks and the fish bowl are in the server test)
p.storage[S.Mission06] = 3
p.items[7936] = 1
dorian:say(p, "hi")
dorian:say(p, "mission")
r = dorian:say(p, "yes")
T.check("goldfish delivered (EN)", has(r, "This little goldfish will bring us a hefty ransom!") and p.storage[S.Mission06] == 4, r)

-- Mission 7
m = dorian:say(p, "mission")
T.check("mission 7 (EN)", has(m, "one of the Venore city guards") and p.storage[S.Mission07] == 1, m)
p.items[7935] = 1
dorian:say(p, "mission")
r = dorian:say(p, "yes")
T.check("letter delivered (EN)", has(r, "that little letter will do the trick for sure") and p.storage[S.Mission07] == 2, r)

-- Mission 8
m = dorian:say(p, "mission")
T.check("mission 8 and the note (EN)", has(m, "Place a message of our guild on the wall") and given(p, 7873) == 1 and p.storage[S.Mission08] == 1, m)
p.storage[S.Mission08] = 2
dorian:say(p, "mission")
r = dorian:say(p, "yes")
T.check("quest finished (EN)", has(r, "you can trade with old Black Bert") and p.storage[S.Mission08] == 3 and p.storage[S.Door] == 1, r)
T.check("Master Thief (both wikis)", p:hasAchievement("Master Thief"))
dorian:say(p, "bye")

bert:say(p, "hi")
bert:say(p, "trade")
T.check("Black Bert trades after the quest", rawget(p, "shopOpened") == true)

-- old items from before the fix
local po = player({})
po.storage[S.Questline] = 2
po.storage[S.Mission02] = 2
po.items[FT.OLD_VASE] = 1
dorian:say(po, "hi")
dorian:say(po, "mission")
dorian:say(po, "yes")
T.check("Dorian takes the fine vase of before", po.storage[S.Mission02] == 3)
po.storage[S.Questline] = 5
po.storage[S.Mission05] = 1
po.storage[S.GoldenGoblet] = 1
po.items[FT.OLD_GOBLET] = 1
dorian:say(po, "mission")
dorian:say(po, "yes")
T.check("Dorian takes the golden goblet of before", po.storage[S.Mission05] == 2)

T.finish()
