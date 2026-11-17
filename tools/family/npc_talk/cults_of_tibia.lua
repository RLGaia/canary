-- Gaia Family server: Cults of Tibia Quest check (2026-11-17): Gerimor (lore words, every cult, the
-- final mission and the reward per vocation), Tigo, Jamesfrancis, Angelo (Life and Patron of the Arts,
-- before and after the Sandking), Noozer, Gareth, Iwar and the Denominator's quiz, with the quest's
-- storages set the way the world scripts set them. NPC lines are TibiaWiki BR/EN unless marked as ours
-- in the NPC files. Run from the repository root:
--   luajit tools/family/npc_talk/cults_of_tibia.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
local check = T.check

Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
VOCATION = VOCATION or { BASE_ID = { NONE = 0, SORCERER = 1, DRUID = 2, PALADIN = 3, KNIGHT = 4, MONK = 9 } }
VOCATION.BASE_ID.MONK = VOCATION.BASE_ID.MONK or 9
MESSAGE_EXPERIENCE = MESSAGE_EXPERIENCE or 1
MESSAGE_EVENT_ADVANCE = MESSAGE_EVENT_ADVANCE or 2

dofile("data-otservbr-global/lib/others/family_cults_of_tibia.lua")
local F = FamilyCults

local C = Storage.Quest.U11_40.CultsOfTibia

local function has(text, part)
	return (text or ""):find(part, 1, true) ~= nil
end

local function newPlayer(o)
	local p = T.player(o)
	rawset(p, "addExperience", function(self, n) self.exp = (self.exp or 0) + n end)
	rawset(p, "addAchievement", function(self, name) self.achievement = name end)
	return p
end

local gerimor = T.load("data-otservbr-global/npc/gerimor.lua")
local tigo = T.load("data-otservbr-global/npc/tigo.lua")
local james = T.load("data-otservbr-global/npc/jamesfrancis.lua")
local angelo = T.load("data-otservbr-global/npc/angelo.lua")
local noozer = T.load("data-otservbr-global/npc/noozer.lua")
local gareth = T.load("data-otservbr-global/npc/gareth.lua")
local iwar = T.load("data-otservbr-global/npc/iwar.lua")
local denominator = T.load("data-otservbr-global/npc/denominator.lua")

-- Gerimor ---------------------------------------------------------------------
local p = newPlayer({ level = 200 })
check("Gerimor greets (BR)", has(gerimor:say(p, "hi"), "I welcome you to this sacred {place}"))
local lore = {
	approach = "looking for heroes", threat = "spirits of nature are in disarray", abominable = "nurturing these nodes",
	something = "constantly {growing}", growing = "stabilizing them on purpose", events = "Ferumbras tried to attain godhood",
	intruder = "{devastating} for our world", devastating = "end of {existence}", existence = "sentient {power}",
	power = "fall of the Yalahari", fiend = "looked into that {matter}", matter = "taken a {foothold}", foothold = "more obscure powers",
	dawn = "our founder", guidance = "keepers of knowledge", cults = "root out each and any movement",
	works = "sever its {ties}", ties = "severing the ties",
}
for word, part in pairs(lore) do
	check("Gerimor " .. word .. " (BR/EN)", has(gerimor:say(p, word), part), part)
end
check("BR 'mission' lists the cults", has(gerimor:say(p, "mission"), "Cult of {Life}"))
check("EN 'missions' lists the cults", has(gerimor:say(p, "missions"), "Cult of the {Humans}"))
check("orcs offers the mission", has(gerimor:say(p, "orcs"), "Edron orcs"))
gerimor:say(p, "yes")
check("accepting starts the cult and the quest log", p:getStorageValue(C.Orcs.Mission) == 1 and p:getStorageValue(C.Questline) == 1)
gerimor:bye(p)

-- reports: each cult at its last step
local reports = {
	{ "minotaurs", C.Minotaurs.Mission, 5, 25000, "source of power" },
	{ "prosperity", C.MotA.Mission, 14, 50000, "Aurea Manus" },
	{ "barkless", C.Barkless.Mission, 6, 50000, "The Penitent" },
	{ "orcs", C.Orcs.Mission, 2, 25000, "That was no god" },
	{ "life", C.Life.Mission, 9, 50000, "Aeterna Exsistentia" },
	{ "misguided", C.Misguided.Mission, 4, 50000, "first-rate irony" },
	{ "humans", C.Humans.Mission, 2, 25000, "Zathroth wasn't behind this" },
}
local total = 0
for _, r in ipairs(reports) do
	p:setStorageValue(r[2], r[3])
	gerimor:say(p, "hi")
	gerimor:say(p, "mission")
	local a = gerimor:say(p, r[1])
	check("report " .. r[1], has(a, r[5]) and p:getStorageValue(r[2]) == r[3] + 1, a:sub(1, 60))
	total = total + r[4]
	gerimor:bye(p)
end
check("seven reports give 275,000 experience (BR: 325,000 with the final 50,000)", p.exp == 275000, p.exp)

gerimor:say(p, "hi")
local a = gerimor:say(p, "mission")
check("all cults done: the final mission (BR)", has(a, "weakened the worldly anchors"), a:sub(1, 60))
check("final door opens", p:getStorageValue(C.FinalBoss.AccessDoor) == 1 and p:getStorageValue(C.FinalBoss.Mission) == 1)
gerimor:bye(p)

local crowns = { [1] = 26190, [2] = 26187, [3] = 26189, [4] = 26188, [9] = 50313 }
for voc, crown in pairs(crowns) do
	local q = newPlayer({ level = 200, vocation = voc })
	q:setStorageValue(C.FinalBoss.Mission, 2)
	gerimor:say(q, "hi")
	check("vocation " .. voc .. ": reward question (EN 'missions')", has(gerimor:say(q, "missions"), "two free slots"))
	gerimor:say(q, "yes")
	check("vocation " .. voc .. ": crown " .. crown .. " + mystery box + achievement", (q.items[crown] or 0) == 1 and (q.items[26186] or 0) == 1 and q.achievement == "Corruption Contained" and q.exp == 50000)
	gerimor:bye(q)
end

-- Tigo ----------------------------------------------------------------------
p = newPlayer({ level = 200 })
check("Tigo greets (BR)", has(tigo:say(p, "hi"), "There, there initiate"))
check("Tigo trial straight away (BR: Hi - Trial)", has(tigo:say(p, "trial"), "The trial consists of three steps"))
check("trial opens the building and starts the cult", p:getStorageValue(C.Barkless.TrialAccessDoor) == 1 and p:getStorageValue(C.Barkless.Mission) == 1 and p:getStorageValue(C.Questline) == 1)
check("Tigo name (BR)", has(tigo:say(p, "name"), "Beacon of the Barkless"))
check("Tigo job (BR)", has(tigo:say(p, "job"), "material sacrifices"))
check("Tigo penitent (BR)", has(tigo:say(p, "penitent"), "first and truest of the Barkless"))
check("Tigo judge (BR)", has(tigo:say(p, "judge"), "free from vanity and fortune"))
check("Tigo pure (BR)", has(tigo:say(p, "pure"), "Purification is but one"))
check("Tigo barkless (BR)", has(tigo:say(p, "barkless"), "You are now one of us"))
check("Tigo farewell (BR)", has(tigo:say(p, "bye"), "Az'edail"))
p:setStorageValue(C.Barkless.Mission, 5)
tigo:say(p, "hi")
tigo:say(p, "barkless")
check("Tigo never sets the mission back", p:getStorageValue(C.Barkless.Mission) == 5)
tigo:bye(p)

-- Jamesfrancis -----------------------------------------------------------------
p = newPlayer({ level = 200 })
check("Jamesfrancis greets (BR)", has(james:say(p, "hi"), "Gerimor is right"))
check("mystery (BR)", has(james:say(p, "mystery"), "Could you do me a {favour}"))
check("favour (BR)", has(james:say(p, "favour"), "kill at least 50"))
james:say(p, "yes")
check("accepted: task 0/50, door, quest log", p:getStorageValue(C.Minotaurs.Mission) == 2 and p:getStorageValue(C.Minotaurs.JamesfrancisTask) == 0 and p:getStorageValue(C.Minotaurs.AccessDoor) == 1 and p:getStorageValue(C.Questline) == 1)
james:bye(p)
check("greeting while hunting (BR)", has(james:say(p, "hi"), "How is your {mission} going?"))
check("not enough minotaurs", has(james:say(p, "mission"), "Come back when"))
p:setStorageValue(C.Minotaurs.JamesfrancisTask, 50)
check("50 killed: key (BR)", has(james:say(p, "mission"), "Great job!") and p:getStorageValue(C.Minotaurs.Mission) == 3 and p:getStorageValue(C.Minotaurs.BossAccessDoor) == 1)
james:bye(p)
p:setStorageValue(C.Minotaurs.Mission, 6)
james:say(p, "hi")
james:say(p, "mission")
james:say(p, "mystery")
james:say(p, "favour")
james:say(p, "yes")
check("after Gerimor nothing goes back (upstream set 3 again)", p:getStorageValue(C.Minotaurs.Mission) == 6 and p:getStorageValue(C.Minotaurs.JamesfrancisTask) == 50)
james:bye(p)
p:setStorageValue(C.Minotaurs.Mission, 4)
check("after the False God: report with hi (BR/EN)", has(james:say(p, "hi"), "controlled by a very powerful boss") and p:getStorageValue(C.Minotaurs.Mission) == 5)
james:bye(p)

-- Angelo: Life ------------------------------------------------------------------
p = newPlayer({ level = 200 })
check("Angelo greets (EN)", has(angelo:say(p, "hi"), "He told you that a new {cave} appeared here?"))
check("project (EN)", has(angelo:say(p, "project"), "Sandy Cave Project"))
check("cave (EN)", has(angelo:say(p, "cave"), "exposed an entry via the {dark pyramid}"))
check("dark pyramid (EN)", has(angelo:say(p, "dark pyramid"), "history of this place has to be rewritten"))
check("results straight away (EN)", has(angelo:say(p, "results"), "Should I be {worried}?"))
check("worried (EN)", has(angelo:say(p, "worried"), "Would you like to go there and look for my workers?"))
check("yes (EN)", has(angelo:say(p, "yes"), "I've opened the door for you"))
check("Life started: door and quest log", p:getStorageValue(C.Life.Mission) == 2 and p:getStorageValue(C.Life.AccessDoor) == 1 and p:getStorageValue(C.Questline) == 1)
angelo:bye(p)

local q = newPlayer({ level = 200 })
q:setStorageValue(C.Life.Mission, 1)
angelo:say(q, "hi")
check("BR route: mission asks", has(angelo:say(q, "mission"), "look for my workers?"))
angelo:say(q, "yes")
check("BR route: yes starts", q:getStorageValue(C.Life.Mission) == 2)
angelo:bye(q)

p:setStorageValue(C.Life.Mission, 3)
check("after the oasis: greeting (EN)", has(angelo:say(p, "hi"), "How is your {mission} going?"))
check("mission (EN)", has(angelo:say(p, "mission"), "green-shining mummies"))
angelo:say(p, "yes")
check("tool for analyzing fluids", (p.items[25305] or 0) == 1 and p:getStorageValue(C.Life.Mission) == 4)
angelo:bye(p)
p:setStorageValue(C.Life.Mission, 5)
angelo:say(p, "hi")
check("sample (EN)", has(angelo:say(p, "mission"), "Do you have the sample"))
check("counteragent (EN)", has(angelo:say(p, "yes"), "I think you need this counteragent") and (p.items[25304] or 0) == 1 and p:getStorageValue(C.Life.Mission) == 6)
angelo:bye(p)
p:setStorageValue(C.Life.Mission, 7)
check("after the sandstorm: hi (EN)", has(angelo:say(p, "hi"), "destroyed by a sandstorm"))
angelo:bye(p)
p:setStorageValue(C.Life.Mission, 8)
check("after the Sandking: hi (EN)", has(angelo:say(p, "hi"), "Just get out of my way!") and p:getStorageValue(C.Life.Mission) == 9)
check("he does not talk any more", has(angelo:say(p, "project"), "Just get out of my way!"))

-- Angelo: Patron of the Arts
q = newPlayer({ level = 200 })
q:setStorageValue(C.MotA.Mission, 6)
angelo:say(q, "hi")
check("magnifier (BR)", has(angelo:say(q, "magnifier"), "You find one in the crate over there") and q:getStorageValue(C.MotA.Mission) == 7)
q:setStorageValue(C.MotA.Mission, 10)
check("artefact (BR)", has(angelo:say(q, "artefact"), "I don't trust you") and q:getStorageValue(C.MotA.Mission) == 11)
angelo:bye(q)
q = newPlayer({ level = 200 })
q:setStorageValue(C.Life.Mission, 10)
q:setStorageValue(C.MotA.Mission, 6)
angelo:say(q, "hi")
check("Sandking dead: trying to talk is enough for the loupe (BR)", q:getStorageValue(C.MotA.Mission) == 7)
angelo:bye(q)
q:setStorageValue(C.MotA.Mission, 10)
angelo:say(q, "hi")
check("Sandking dead: and for the artefact refusal (BR)", q:getStorageValue(C.MotA.Mission) == 11)
angelo:bye(q)

-- Noozer -------------------------------------------------------------------------
p = newPlayer({ level = 200 })
check("Noozer greets (BR/EN)", has(noozer:say(p, "hi"), "So, just passing through?"))
check("yes (EN)", has(noozer:say(p, "yes"), "DANGEROUS!"))
check("Misguided started with quest log", p:getStorageValue(C.Misguided.Mission) == 2 and p:getStorageValue(C.Misguided.AccessDoor) == 1 and p:getStorageValue(C.Questline) == 1)
noozer:bye(p)
q = newPlayer({ level = 200 })
noozer:say(q, "hi")
check("pass (BR)", has(noozer:say(q, "pass"), "angry as dung"))
noozer:bye(q)

-- Gareth and Iwar ------------------------------------------------------------------
p = newPlayer({ level = 200, money = 30000 })
check("Gareth greets (BR)", has(gareth:say(p, "hi"), "Museum of Tibian Arts"))
check("patrons (BR)", has(gareth:say(p, "patrons"), "The price is 10,000 gold"))
check("pay (BR)", has(gareth:say(p, "pay"), "investigate the crime scene of a theft which occurred") and p.money == 20000)
check("door, brush, quest log", p:getStorageValue(C.MotA.AccessDoorInvestigation) == 1 and (p.items[25689] or 0) == 1 and p:getStorageValue(C.Questline) == 1)
gareth:bye(p)
q = newPlayer({ level = 200, money = 30000 })
gareth:say(q, "hi")
gareth:say(q, "patron")
gareth:say(q, "yes")
check("EN route: patron, yes", q:getStorageValue(C.MotA.Mission) == 2 and q.money == 20000)
gareth:bye(q)
p:setStorageValue(C.MotA.Mission, 3)
gareth:say(p, "hi")
check("ransom note (BR)", has(gareth:say(p, "mission"), "Please go to Iwar in Kazordoon") and p:getStorageValue(C.MotA.Mission) == 4)
gareth:bye(p)
check("Iwar greets with the name (EN)", has(iwar:say(p, "hi"), "Hiho Tester!"))
check("code words without '?' (EN)", has(iwar:say(p, "has the cat got your tongue"), "Give me 10,000 gold"))
check("yes pays (BR)", has(iwar:say(p, "yes"), "as fast as possible") and p.money == 10000 and p:getStorageValue(C.MotA.Mission) == 5)
iwar:bye(p)
gareth:say(p, "hi")
check("picture back (BR)", has(gareth:say(p, "mission"), "Nice. I'm really happy") and p:getStorageValue(C.MotA.Mission) == 6)
gareth:bye(p)
p:setStorageValue(C.MotA.Mission, 9)
gareth:say(p, "hi")
check("fake picture (BR)", has(gareth:say(p, "mission"), "Please go to {Angelo}") and p:getStorageValue(C.MotA.Mission) == 10)
gareth:bye(p)
p:setStorageValue(C.MotA.Mission, 11)
gareth:say(p, "hi")
check("last floor (BR)", has(gareth:say(p, "mission"), "thanks for your efforts") and p:getStorageValue(C.MotA.AccessDoorGareth) == 1)
gareth:bye(p)
p:setStorageValue(C.MotA.Mission, 14)
check("after the Denominator (BR)", has(gareth:say(p, "hi"), "The cultists should have"))
gareth:bye(p)

-- The Denominator -----------------------------------------------------------------
check("prime 2, 3, 5, 101, 353", F.isPrime(2) and F.isPrime(3) and F.isPrime(5) and F.isPrime(101) and F.isPrime(353))
check("not prime 0, 1, 312, 333, 555", not F.isPrime(0) and not F.isPrime(1) and not F.isPrime(312) and not F.isPrime(333) and not F.isPrime(555))
check("twin primes 101 (103), 311 (313), 5", F.isTwinPrime(101) and F.isTwinPrime(311) and F.isTwinPrime(5))
check("not twin: 23 (21, 25), 312, 401 (399, 403)", not F.isTwinPrime(23) and not F.isTwinPrime(312) and not F.isTwinPrime(401))

local function answerFor(pl, index)
	local qn = F.question(index)
	local x, y, z = F.digits(pl)
	local r = qn.answer(x, y, z, x * 100 + y * 10 + z)
	if qn.kind == "yesno" then
		return r and "yes" or "no"
	end
	return tostring(r)
end

local function setNumber(pl, x, y, z)
	pl:setStorageValue(C.MotA.Stone1, x)
	pl:setStorageValue(C.MotA.Stone2, y)
	pl:setStorageValue(C.MotA.Stone3, z)
end

p = newPlayer({ level = 200 })
p:setStorageValue(C.MotA.Mission, 12)
check("before the lever (BR)", has(denominator:say(p, "hi"), "The number has not been set."))
denominator:bye(p)
p:setStorageValue(C.MotA.Mission, 13)
p:setStorageValue(C.MotA.QuestionId, 0)
setNumber(p, 3, 1, 2)
check("number set: questions", has(denominator:say(p, "hi"), "{questions}"))
check("ready to start", has(denominator:say(p, "questions"), "Ready to {start}?"))
local seen = {}
local q1 = denominator:say(p, "yes")
check("first question", q1 ~= "" and not has(q1, "LUA ERROR"), q1)
local ok = true
for i = 1, 5 do
	-- find which question was asked
	local asked
	for idx = 0, #F.questions do
		if has(denominator.npc.said[#denominator.npc.said], F.question(idx).text) then
			asked = idx
		end
	end
	if not asked then
		ok = false
		break
	end
	seen[asked] = true
	denominator:say(p, answerFor(p, asked))
end
check("five right answers open the door (EN/BR)", ok and p:getStorageValue(C.MotA.Mission) == 14 and p:getStorageValue(C.MotA.AccessDoorDenominator) == 1, denominator.npc.said[#denominator.npc.said])
check("last answer line", has(denominator.npc.said[#denominator.npc.said], "The lower door is now open"))
denominator:bye(p)

-- a wrong answer ends the talk, but you can start again in time
q = newPlayer({ level = 200 })
q:setStorageValue(C.MotA.Mission, 13)
setNumber(q, 5, 5, 5)
denominator:say(q, "hi")
denominator:say(q, "questions")
denominator:say(q, "start")
check("wrong answer: SHUT DOWN", has(denominator:say(q, "12345"), "SHUT DOWN"))
denominator:say(q, "hi")
denominator:say(q, "questions")
check("again in time", denominator:say(q, "start") ~= "")
denominator:bye(q)
q:setStorageValue(C.MotA.QuestionId, os.time() - 200)
check("after two minutes the number is gone (BR)", has(denominator:say(q, "hi"), "The number has not been set.") and q:getStorageValue(C.MotA.Mission) == 12)
denominator:bye(q)

-- many random quizzes with random numbers: the checks always agree with the questions
local agree = true
for n = 1, 300 do
	local r = newPlayer({ level = 200 })
	setNumber(r, math.random(0, 5), math.random(0, 5), math.random(0, 5))
	for _, idx in ipairs(F.pickQuestions()) do
		if not F.checkAnswer(r, F.question(idx), answerFor(r, idx)) then
			agree = false
		end
	end
	if not F.checkAnswer(r, F.question(0), tostring(F.number(r))) then
		agree = false
	end
end
check("300 random numbers: right answers always pass", agree)
local picked = F.pickQuestions()
local distinct = {}
for _, idx in ipairs(picked) do
	distinct[idx] = true
end
local count = 0
for _ in pairs(distinct) do
	count = count + 1
end
check("four different questions before the number", #picked == 4 and count == 4)

-- every highlighted word answers
T.checkHints(gerimor, function() return newPlayer({ level = 200 }) end, { life = true, prosperity = true, minotaurs = true, barkless = true, misguided = true, orcs = true, humans = true })
T.checkHints(tigo, function() return newPlayer({ level = 200 }) end)
T.checkHints(angelo, function() return newPlayer({ level = 200 }) end, { mission = true, gareth = false, magnifier = true, results = false })
T.checkHints(noozer, function() return newPlayer({ level = 200 }) end)

T.finish()
