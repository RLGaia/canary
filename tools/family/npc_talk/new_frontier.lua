-- The New Frontier Quest: the NPC side of the whole quest (2026-11-09).
-- Run from the repository root:  luajit tools/family/npc_talk/new_frontier.lua
-- One character plays the quest from Ongulf's story to the last report with
-- Melfar, Lazaran, the six Mission 5 NPCs, Curos, Ztiss, Chrak and Zurak
-- (world steps such as the passage, the trees or the arena are set as
-- storages). Checks the TibiaWiki EN/BR lines, the states the wikis do not
-- show (wrong words, unrelated words, gifts, waiting stages) and the
-- regressions found in the review (Melfar setting the quest back).
local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z)
	return { x = x, y = y, z = z, sendMagicEffect = function() end }
end
dofile("data-otservbr-global/lib/others/family_new_frontier.lua")
dofile("data-otservbr-global/lib/others/family_explorer_society.lua")
local S = Storage.Quest.U8_54.TheNewFrontier
local F = FamilyNewFrontier
local check = T.check
local NPC = "data-otservbr-global/npc/"
CONST_ME_TELEPORT = CONST_ME_TELEPORT or 11
F.rewardRoom = Position(33062, 31029, 7)

local function norm(s)
	return (s:lower():gsub("[{}]", ""):gsub("%s+", " "))
end
local function has(text, pattern)
	return norm(text):find(norm(pattern), 1, true) ~= nil
end

local p = T.player({ name = "Rodrigo", level = 120 })
local function q()
	return p:getStorageValue(S.Questline)
end
local function setq(v)
	p:setStorageValue(S.Questline, v)
end

-- ------------------------------------------------------------------ Ongulf
local ongulf = T.load(NPC .. "ongulf.lua")
local floor = 14
ongulf.npc.getPosition = function()
	return { x = 33024, y = 31543, z = floor }
end
check("Ongulf: stage 1 greeting (EN/BR)", has(ongulf:say(p, "hi"), "Hello, Rodrigo. You've come at a good time for our project."))
local a = ongulf:say(p, "mission")
check("Ongulf: 'mission' before the story starts it (EN)", has(a, "So what would you like to hear, the long story or the short version?"), a)
a = ongulf:say(p, "long")
check("Ongulf: long story, EN wording", has(a, "the great underground rivers") and has(a, "On one hand") and has(a, "That's where you come into play") and has(a, "But where were we?"), a:sub(1, 60))
a = ongulf:say(p, "missions")
check("Ongulf: 'missions' (BR guide word) starts mission 1", q() == 1 and has(a, "Do not explore any further though."), a)
a = ongulf:say(p, "mission")
check("Ongulf: reminder while exploring (ours)", has(a, "find a passage leading out"), a)
ongulf:bye(p)

-- second character: project, short, missions
local p2 = T.player({ name = "Father" })
ongulf:say(p2, "hi")
ongulf:say(p2, "project")
a = ongulf:say(p2, "short")
check("Ongulf: short story (EN)", has(a, "<grumbles> Well, we have found this place here full of promising resources"), a)
a = ongulf:say(p2, "missions")
check("Ongulf: 'missions' after the short story starts the quest", p2:getStorageValue(S.Questline) == 1, a)
ongulf:bye(p2)

setq(2) -- found the passage (movement_wayout.lua)
ongulf:say(p, "hi")
a = ongulf:say(p, "mission")
check("Ongulf: report of mission 1 (EN)", q() == 3 and has(a, "it is always good to know something more about our surroundings"), a)
a = ongulf:say(p, "mission")
check("Ongulf: mission 2 (EN)", q() == 4 and has(a, "you'll find Melfar of the imperial mining guild"), a)
a = ongulf:say(p, "mission")
check("Ongulf: reminder for Melfar (ours)", has(a, "Melfar"), a)
ongulf:bye(p)

-- ------------------------------------------------------------------ Melfar
local melfar = T.load(NPC .. "melfar.lua", { config = nil })
check("Melfar: greeting (EN)", has(melfar:say(p, "hi"), "Just great, another disturbance. Just what I need."))
a = melfar:say(p, "mission")
check("Melfar: mission (EN)", has(a, "Does this sound like something you can handle?"), a)
a = melfar:say(p, "yes")
check("Melfar: beaver bait given (EN)", q() == 5 and p:getItemCount(9843) == 1 and has(a, "So take this beaver bait. It will work best on dwarf trees."), a)
a = melfar:say(p, "mission")
check("Melfar: trees not marked yet", q() == 5 and has(a, "If you place the beaver bait on trees"), a)
p:setStorageValue(S.Mission02.Beaver1, 1)
p:setStorageValue(S.Mission02.Beaver2, 1)
p:setStorageValue(S.Mission02.Beaver3, 1)
a = melfar:say(p, "mission")
check("Melfar: report (EN)", q() == 6 and has(a, "It has to be a legion of beavers!"), a)
melfar:bye(p)

ongulf:say(p, "hi")
a = ongulf:say(p, "mission")
check("Ongulf: report of mission 2 (EN)", q() == 7 and has(a, "That's good news for sure."), a)
a = ongulf:say(p, "mission")
check("Ongulf: mission 3 (EN)", q() == 8 and has(a, "Find these vines in this mountain"), a)
ongulf:bye(p)

-- regression: Melfar must not set a later quest back to his report
melfar:say(p, "hi")
a = melfar:say(p, "mission")
check("Melfar: no report again later (upstream set the quest back to 6)", q() == 8, "questline " .. q())
melfar:bye(p)

-- ----------------------------------------------------------------- Lazaran
local lazaran = T.load(NPC .. "lazaran.lua")
check("Lazaran: greeting (EN/BR)", has(lazaran:say(p, "hi"), "Me greet."))
a = lazaran:say(p, "mission")
check("Lazaran: mission (EN/BR)", has(a, "Me people wanting peace. No war with others. No war with little men. We few. We weak. Need help. We not wanting make war. No hurt."), a)
a = lazaran:say(p, "peace")
check("Lazaran: pipe of peace (EN)", q() == 8 and has(a, "You smoke pipes of peace with us?"), a)
a = lazaran:say(p, "yes")
check("Lazaran: peace made (EN)", q() == 9 and p:getStorageValue(S.Mission03) == 2 and has(a, "We brothers in peace now."), a)
for _, w in ipairs({ "name", "job", "tribe", "dwarf", "monster", "green ones", "horned ones", "dragon people", "war", "little men" }) do
	check("Lazaran: '" .. w .. "' answers (EN)", lazaran:say(p, w) ~= "")
end
lazaran:bye(p)

floor = 12
a = ongulf:say(p, "hi")
check("Ongulf: stage 2 greeting (BR)", has(a, "Hello. At last our project is progressing."), a)
a = ongulf:say(p, "project")
check("Ongulf: 'project' from the greeting works during the quest", q() == 10 and has(a, "Primitive humans you say?"), a)
a = ongulf:say(p, "mission")
check("Ongulf: mission 4 (EN)", q() == 11 and has(a, "Use the mining lift to reach mine A07."), a)
setq(12) -- Shard of Corruption killed
a = ongulf:say(p, "missions")
check("Ongulf: report of mission 4 (EN)", q() == 13 and has(a, "the others crumbled to dust and stone"), a)
a = ongulf:say(p, "missions") -- the clickable {missions} of that line
check("Ongulf: {missions} gives mission 5 (EN)", q() == 14 and has(a, "You may try to FLATTER, THREATEN, IMPRESS, BLUFF, PLEA or to REASON with them."), a:sub(1, 60))
a = ongulf:say(p, "mission")
check("Ongulf: mission 5 not done yet (ours)", q() == 14 and has(a, "Black Bert"), a)
ongulf:bye(p)

-- --------------------------------------------------------------- Mission 5
local talks = {
	{ key = "king", file = "king_tibianus.lua", greet = "hail king", state = "KingTibianus" },
	{ key = "leeland", file = "leeland.lua", greet = "hi", state = "Leeland" },
	{ key = "angus", file = "angus.lua", greet = "hi", state = "Angus" },
	{ key = "wyrdin", file = "wyrdin.lua", greet = "hi", state = "Wyrdin" },
	{ key = "telas", file = "telas.lua", greet = "hi", state = "Telas" },
	{ key = "humgolf", file = "humgolf.lua", greet = "hi", state = "Humgolf" },
}
local WORDS = { "flatter", "threaten", "impress", "bluff", "plea", "reason" }
local function lineOf(x)
	return type(x) == "table" and x[#x] or x
end

for _, t in ipairs(talks) do
	local npc = T.load(NPC .. t.file)
	local data = F.npcs[t.key]
	local st = S.Mission05[t.state]
	local name = npc.npc.name
	npc:say(p, t.greet)
	npc:say(p, "job")
	npc:say(p, "trade")
	check(name .. ": other words before 'farmine' do not fail the talk", p:getStorageValue(st) == 1)
	a = npc:say(p, "flatter")
	check(name .. ": a strategy word without 'farmine' does nothing", p:getStorageValue(st) == 1, a)
	a = npc:say(p, "farmine")
	check(name .. ": 'farmine' (EN)", has(a, data.intro), a)
	npc:say(p, "what")
	check(name .. ": an unrelated word after 'farmine' does not fail the talk", p:getStorageValue(st) == 1)
	local secret = F.secretWord(p, t.key)
	check(name .. ": the secret word is one that convinces him in the EN transcripts", data.success[secret] ~= nil, secret)
	local wrong
	for _, w in ipairs(WORDS) do
		if w ~= secret then
			wrong = w
			break
		end
	end
	a = npc:say(p, wrong)
	check(name .. ": wrong word '" .. wrong .. "' fails with his line", p:getStorageValue(st) == 2 and has(a, lineOf(data.fail[wrong] or data.other)), a)
	a = npc:say(p, "farmine")
	check(name .. ": asks for a present (EN)", has(a, data.apology), a)
	a = npc:say(p, "yes")
	check(name .. ": 'yes' without the present (ours)", p:getStorageValue(st) == 2 and has(a, "nothing with you"), a)
	p.items[data.gift] = 1
	npc:say(p, "farmine")
	a = npc:say(p, "yes")
	check(name .. ": takes Black Bert's item (EN)", p:getStorageValue(st) == 1 and p:getItemCount(data.gift) == 0 and has(a, lineOf(data.accepted)), a)
	a = npc:say(p, secret)
	check(name .. ": secret word '" .. secret .. "' convinces him (EN)", p:getStorageValue(st) == 3 and has(a, lineOf(data.success[secret])), a)
	a = npc:say(p, "farmine")
	check(name .. ": after agreeing (ours)", has(a, data.done) and p:getStorageValue(st) == 3, a)
	local src = io.open(NPC .. t.file):read("*a")
	check(name .. ": the upstream 'Wrong Word.' answer is gone", not src:find('say("Wrong Word', 1, true) and not src:find('say({ "Wrong Word', 1, true))
	npc:bye(p)
end

-- every word gives the matching line for every NPC (secret word = success)
for key, data in pairs(F.npcs) do
	for _, w in ipairs(WORDS) do
		check("lines: " .. key .. " has a line for '" .. w .. "'", data.success[w] or data.fail[w] or data.other)
	end
end

floor = 10
a = ongulf:say(p, "hi")
check("Ongulf: stage 3 greeting (EN/BR)", has(a, "Hello. Now that's what I'd call a project working ... more or less."), a)
a = ongulf:say(p, "mission")
check("Ongulf: report of mission 5 (EN)", q() == 15 and has(a, "You did an excellent job!"), a)
a = ongulf:say(p, "mission")
check("Ongulf: mission 6 (EN)", q() == 16 and has(a, "make them stop their attack plans"), a)
ongulf:bye(p)

-- ------------------------------------------------------------------- Curos
local curos = T.load(NPC .. "curos.lua")
check("Curos: greeting (EN/BR)", has(curos:say(p, "hi"), "Be greeted blank skin."))
a = curos:say(p, "mission")
check("Curos: mission (EN/BR)", has(a, "you'll have to prove it in a test of strength and courage"), a)
a = curos:say(p, "test")
check("Curos: test (EN/BR)", q() == 17 and has(a, "Face him in a battle and survive for two minutes."), a)
setq(18) -- survived the Mooh'Tah master
a = curos:say(p, "mission")
check("Curos: report (EN/BR)", q() == 19 and has(a, "this is a start at least"), a)
curos:bye(p)

ongulf:say(p, "hi")
a = ongulf:say(p, "mission")
check("Ongulf: report of mission 6 (EN)", q() == 20 and has(a, "Whatever the value of a minotaur's promise might be"), a)
a = ongulf:say(p, "mission")
check("Ongulf: mission 7 (EN)", q() == 21 and has(a, "somewhere in or behind those mountains in the north"), a)
a = ongulf:say(p, "mission")
check("Ongulf: reminder for the lizards (ours)", has(a, "lizards"), a)
ongulf:bye(p)

-- ------------------------------------------------------------------- Ztiss
setq(23) -- prison and secret door
local ztiss = T.load(NPC .. "ztiss.lua")
check("Ztiss: greeting (EN/BR)", has(ztiss:say(p, "hi"), "Be greeted my .. guezt"))
check("Ztiss: guezt", has(ztiss:say(p, "guezt"), "He haz an offer for you."))
check("Ztiss: offer", has(ztiss:say(p, "offer"), "if you agree to work for my mazter"))
check("Ztiss: work", has(ztiss:say(p, "work"), "Are you interezted in ziz deal?"))
check("Ztiss: yes", has(ztiss:say(p, "yes"), "Zo are you ready to drink ziz poizon here?"))
a = ztiss:say(p, "yes")
check("Ztiss: poison drunk (EN/BR)", q() == 24 and has(a, "Excellent! Now you may leave ziz area"), a)
ztiss:bye(p)

-- ------------------------------------------------------------------- Chrak
local chrak = T.load(NPC .. "chrak.lua")
check("Chrak: greeting (EN/BR)", has(chrak:say(p, "hi"), "Greetingz, competitor."))
check("Chrak: competitor (EN)", has(chrak:say(p, "competitor"), "I'm ze mazter of ze ceremony and ze gamez."))
check("Chrak: rulez explain the platforms and the lever (EN)", has(chrak:say(p, "rulez"), "Zen you have to ztand on ze platformz in ze back and one of you haz to pull ze lever."))
check("Chrak: mission (EN/BR)", has(chrak:say(p, "mission"), "If you know ze rulez, you might enter ze arena for ze battle."))
check("Chrak: battle (EN/BR)", has(chrak:say(p, "battle"), "you know ze rulez and zat zere will be no ozer option zan deaz or victory?"))
a = chrak:say(p, "yes")
check("Chrak: permission (EN/BR)", q() == 25 and p:getStorageValue(S.Mission09.ArenaDoor) == 1 and has(a, "Remember, you'll have to enter ze arena az a team of two."), a)
setq(26) -- Tirecz killed, left the reward room without the armor
a = chrak:say(p, "mission")
check("Chrak: armor not taken yet (ours)", q() == 26 and has(a, "ancient armor"), a)
chrak:bye(p)

-- ------------------------------------------------------------------- Zurak
for _, file in ipairs({ "zurak.lua", "zurak_arena.lua" }) do
	local zurak = T.load(NPC .. file)
	check(file .. ": greeting (EN)", has(zurak:say(p, "hi"), "Hurry before zzomeone will zee uzz."))
	a = zurak:say(p, "reward")
	check(file .. ": reward room offered (BR)", has(a, "Me can alzzo guide you to rewardroom if you did not collect your reward for fighting yet. You want?"), a)
	p.teleported = nil
	zurak:say(p, "yes")
	check(file .. ": takes the winner to the reward room (BR)", p.teleported and p.teleported.x == 33062 and p.teleported.y == 31029 and p.teleported.z == 7)
	zurak:bye(p)
end

setq(27) -- armor taken
p:setStorageValue(S.Reward.Potions, 1)
p:setStorageValue(S.Reward.GoldIngot, 1)
a = chrak:say(p, "hi") .. chrak:say(p, "mission")
check("Chrak: report (EN/BR)", q() == 28 and has(a, "You have done ze impozzible and beaten ze champion."), a)
chrak:bye(p)

local zurak = T.load(NPC .. "zurak.lua")
zurak:say(p, "hi")
a = zurak:say(p, "reward")
check("Zurak: piggy bank still in its chest, reward room offered (BR)", has(a, "You want?"), a)
zurak:bye(p)
p:setStorageValue(S.Reward.PigBank, 1)
zurak:say(p, "hi")
a = zurak:say(p, "reward")
check("Zurak: everything taken, he ends the talk (BR)", has(a, "Yezz, zztrange creature leave Zurak.") and not zurak.npc:isInteractingWithPlayer(p), a)
zurak:say(p, "hi")
a = zurak:say(p, "trip")
check("Zurak: trip still works", has(a, "You want trip to Izzle of Zztrife?"), a)
zurak:bye(p)

ongulf:say(p, "hi")
a = ongulf:say(p, "mission")
check("Ongulf: report of mission 10 (EN)", q() == 29 and p:getStorageValue(S.Mission10.MagicCarpetDoor) == 1 and has(a, "We convinced a carpet pilot to join us here."), a)
a = ongulf:say(p, "mission")
check("Ongulf: after the quest (ours)", has(a, "make your fortune"), a)
ongulf:bye(p)

-- every {word} the NPCs highlight answers
for _, file in ipairs({ "ongulf.lua", "lazaran.lua", "chrak.lua", "zurak.lua", "zurak_arena.lua" }) do
	local npc = T.load(NPC .. file)
	if file == "ongulf.lua" then
		npc.npc.getPosition = function()
			return { x = 33024, y = 31543, z = 14 }
		end
	end
	T.checkHints(npc, function()
		return T.player({ storage = { [S.Questline] = 24 } })
	end, { long = true, short = true, mission = true, missions = true, peace = true, help = true, battle = true, project = true })
end

T.finish()
