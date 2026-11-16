-- Gaia Family server: The Scatterbrained Sorcerer Quest check (2026-11-15).
-- One character plays the whole quest with the real NPC files: Eclesius (greeting by level,
-- the five tasks, missions 1-6, the laboratory Eclesius), Irmana, Amarie, Grodrik, Frodo,
-- Xodet, Queen Eloise, Bunny Bonecrusher, A Confused Frog and A Frog. Steps done with objects
-- (cauldron, skunk, broom, levers...) are set as storages here; the objects are checked by the
-- server self-test.
--   luajit tools/family/npc_talk/scatterbrained_sorcerer.lua
local T = dofile("tools/family/npc_talk/npc_talk.lua")
FLUID_BEER, FLUID_OIL = 3, 7
CONDITION_OUTFIT = 1
dofile("data-otservbr-global/lib/others/family_sorcerer.lua")
local FS = FamilySorcerer
local M = FS.M
local S = FS.S

local function load(file)
	local talk = T.load("data-otservbr-global/npc/" .. file .. ".lua")
	local npc = talk.npc
	local z = 7
	function npc:getPosition()
		return { x = 0, y = 0, z = z, sendMagicEffect = function() end }
	end
	talk.setZ = function(nz) z = nz end
	return talk
end

local eclesius = load("eclesius")
local irmana = load("irmana")
local amarie = load("amarie")
local grodrik = load("grodrik")
local frodo = load("frodo")
local xodet = load("xodet")
local eloise = load("queen_eloise")
local bunny = load("bunny_bonecrusher")
local confused = load("a_confused_frog")
local frog = load("a_frog")

local function has(answer, text)
	return answer:find(text, 1, true) ~= nil
end

local function check(name, answer, text)
	return T.check(name, has(answer, text), answer:sub(1, 120))
end

local function mission(p)
	return p.storage[S.Mission] or -1
end

-- ---------------------------------------------------------------- greeting
local young = T.player({ level = 8, name = "Kicasso" })
check("level 8: young and eager (the line Rodrigo expected)", eclesius:say(young, "hi"), "Hey, you! You look young and eager.")
T.check("no 'too experienced' greeting", not has(eclesius:say(young, "bye"), "too experienced"))
local old = T.player({ level = 45, name = "Saradoc Knight" })
local hi = eclesius:say(old, "hi")
check("level 45: a bit old but welcome (TibiaWiki EN)", hi, "Even though you already seem a bit old")
T.check("level 45 is not sent away", not has(hi, "too experienced"), hi)
check("no: our line", eclesius:say(old, "no"), "Your loss")
eclesius:bye(old)

local p = T.player({ level = 45, name = "Saradoc Knight", money = 0 })
eclesius:say(p, "hi")
check("yes: becomes the assistant", eclesius:say(p, "yes"), "Really? Err, I mean")
T.check("questline 1", p.storage[S.Questline] == 1)
check("tasks list", eclesius:say(p, "tasks"), "I have five tasks")
check("name", eclesius:say(p, "Saradoc Knight"), "Was that your name...? Saradoc Knight?")
eclesius:bye(p)
check("greeting as assistant", eclesius:say(p, "hi"), "Oh, welcome back, my most valued assistant!")

-- ---------------------------------------------------------------- tasks
for _, task in ipairs(FS.tasks) do
	check(task .. ": offer", eclesius:say(p, task), FS.taskOffers[task][1]:sub(1, 30))
	T.check(task .. ": taken", p.storage[FS.taskStorage[task]] == FS.ACTIVE)
	check(task .. ": asked again before done", eclesius:say(p, task), FS.taskQuestions[task]:sub(1, 25))
	check(task .. ": yes before done", eclesius:say(p, "yes"), FS.taskNotYet[task]:sub(1, 20))
	T.check(task .. ": still taken", p.storage[FS.taskStorage[task]] == FS.ACTIVE)
	p.storage[FS.taskStorage[task]] = FS.READY -- done with the objects
	eclesius:say(p, task)
	local before = p.money
	check(task .. ": reward line", eclesius:say(p, "yes"), FS.taskThanks[task]:sub(1, 25))
	T.check(task .. ": paid " .. FS.taskReward[task][1], p.money - before == FS.taskReward[task][1])
	if task == "feed" then
		check("feed: what did it say", eclesius:say(p, "blub"), "Hum, is that so")
	end
	check(task .. ": once a day", eclesius:say(p, task), "already did that today")
end
check("no 'prevent' upstream line in the way", eclesius:say(p, "hint"), "Hint? What kind of hint?")

-- magical oil
p.storage[S.Prevent] = FS.FREE
eclesius:say(p, "prevent")
check("magical oil: asks for ingredients", eclesius:say(p, "magical oil"), "Have you found the recipe")
check("magical oil: missing", eclesius:say(p, "yes"), "something's missing")
p.items[2874], p.items[3114], p.items[3585], p.items[5897] = 1, 1, 1, 1
eclesius:say(p, "magical oil")
check("magical oil: made", eclesius:say(p, "yes"), "Alakaz")
T.check("flask with magical oil given", p.items[9112] == 1)
check("key hint", eclesius:say(p, "magical key"), "somewhere in my lab")

-- next day
p.kvdata.day = "yesterday"
p.storage[S.Prevent] = FS.REPORTED
p.storage[S.Exterminate] = FS.FAILED
T.check("new day frees reported and failed tasks", FS.taskState(p, "prevent") == FS.FREE and FS.taskState(p, "exterminate") == FS.FREE)

-- ---------------------------------------------------------------- mission 1
check("M1 offer", eclesius:say(p, "mission"), "someone ruined my favourite hat")
eclesius:say(p, "yes")
T.check("M1 accepted", mission(p) == M.HAT_ASKED)
check("M1 without hat", eclesius:say(p, "mission"), "Maybe a tailor in Venore")
eclesius:bye(p)
irmana:say(p, "hi")
check("Irmana: hat models", irmana:say(p, "hat"), "A {dark hat}, a {pink hat} and a {wooden hat}")
check("Irmana: dark hat recipe", irmana:say(p, "dark hat"), "one piece of minotaur leather and two bat wings")
check("Irmana: no materials", irmana:say(p, "yes"), "you don't have the materials")
p.items[5878], p.items[5894] = 1, 2
irmana:say(p, "dark hat")
check("Irmana: dark hat made", irmana:say(p, "yes"), "A little stitch here")
T.check("dark hat 9127", p.items[9127] == 1 and p.items[5878] == 0 and p.items[5894] == 0)
p.items[5901], p.items[5880] = 1, 1
irmana:say(p, "wooden hat")
irmana:say(p, "yes")
irmana:bye(p)
eclesius:say(p, "hi")
check("M1 hat?", eclesius:say(p, "mission"), "Can I see it?")
local money = p.money
check("M1 done", eclesius:say(p, "yes"), "it's perfect even")
T.check("M1 reward 1000", p.money - money == 1000 and mission(p) == M.HAT_DONE)

-- ---------------------------------------------------------------- mission 2
check("M2 offer", eclesius:say(p, "mission"), "Those sandals I wear")
eclesius:say(p, "yes")
check("M2 sandals?", eclesius:say(p, "mission"), "Did you bring me a pair?")
check("M2 no sandals", eclesius:say(p, "yes"), "These are not sandals")
p.items[3551] = 1
eclesius:say(p, "mission")
check("M2 sandals given", eclesius:say(p, "yes"), "let me put my name on them")
T.check("Eclesius' sandals", p.items[9131] == 1 and mission(p) == M.SANDALS_GIVEN)
p.storage[S.Mission] = M.BOILED
check("M2 boiled", eclesius:say(p, "mission"), "You put sandals into my cauldron?")
T.check("M2 skunk asked", mission(p) == M.SKUNK_ASKED)
p.storage[S.Mission] = M.SKUNKED
check("M2 skunked", eclesius:say(p, "mission"), "Can you think of anything that smells really delicious?")
check("M2 not delicious", eclesius:say(p, "rotten meat"), "doesn't sound delicious")
check("M2 flower", eclesius:say(p, "flower"), "a white flower")
T.check("M2 fragrance flower", mission(p) == M.FRAGRANCE_CHOSEN and p.kvdata.fragrance == "flower")
p.storage[S.Mission] = M.FRAGRANT
eclesius:say(p, "mission")
money = p.money
check("M2 done", eclesius:say(p, "yes"), "very pleased indeed")
T.check("M2 reward 500, sandals taken", p.money - money == 500 and p.items[9131] == 0 and mission(p) == M.SANDALS_DONE)

-- ---------------------------------------------------------------- mission 3
check("M3 offer", eclesius:say(p, "mission"), "I plan on becoming a God!")
eclesius:say(p, "yes")
T.check("M3 accepted", mission(p) == M.DATING_ASKED)
eclesius:bye(p)

-- Amarie
check("Amarie greeting", amarie:say(p, "hi"), "I really have to {study}")
local chain = {
	{ "study", "Are you really interested?" },
	{ "yes", "social interaction of {milkbugs}" },
	{ "milkbugs", "They really {care}" },
	{ "care", "Sometimes I {dream}" },
	{ "dream", "In my favourite {book}" },
	{ "book", "{poetry} book" },
	{ "poetry", "recite some poetry" },
	{ "yes", "Will her light shine the brightest." },
	{ "yes", "a long, lonely life without {love}" },
	{ "love", "Love? Hah" },
	{ "dating", "You are a dating agent?" },
	{ "yes", "the most personal thing I have is this book" },
}
for _, step in ipairs(chain) do
	check("Amarie: " .. step[1], amarie:say(p, step[1]), step[2])
end
T.check("Amarie's favourite book", p.items[9143] == 1)
amarie:bye(p)

-- Grodrik
check("Grodrik greeting", grodrik:say(p, "hi"), "Got my own worries and {problems}")
check("Grodrik: problems", grodrik:say(p, "problems"), "Got a mug of beer for me?")
check("Grodrik: no beer", grodrik:say(p, "yes"), "Don't tease a thirsty dwarf")
p.items[2880] = 7
grodrik:say(p, "problems")
local beerChain = {
	{ "yes", "Hrrm. Appreciated." },
	{ "woman", "Sigh. I don't want to talk about all that." },
	{ "beer", "I like you better and better" },
	{ "woman", "I'm actually a bit shy" },
	{ "beer", "I like you better and better" },
	{ "woman", "I've never had a girlfriend" },
	{ "wishes", "You are going too far" },
	{ "lonely", "what do you know about loneliness" },
	{ "beer", "I like you better and better" },
	{ "lonely", "someone who respects your {wishes}" },
	{ "wishes", "You are going too far" },
	{ "beer", "I like you better and better" },
	{ "wishes", "A tall, strong woman with a blonde beard" },
	{ "woman", "I've never had a girlfriend" },
	{ "beer", "I like you better and better" },
	{ "dating", "maybe that's not such a bad idea after all" },
	{ "yes", "my favourite <hicks> axe" },
}
for i, step in ipairs(beerChain) do
	check("Grodrik " .. i .. ": " .. step[1], grodrik:say(p, step[1]), step[2])
end
T.check("Grodrik's favourite axe, 6 beers", p.items[9142] == 1 and p.items[2880] == 1)
grodrik:bye(p)

eclesius:say(p, "hi")
check("M3 found them?", eclesius:say(p, "mission"), "lonely dwarf and a lonely elf for our dating game?")
check("M3 items taken", eclesius:say(p, "yes"), "could the dwarf and elf in question get on with each other?")
check("M3 questionnaire", eclesius:say(p, "no"), "Go into my library")
T.check("M3 questionnaire state", mission(p) == M.QUESTIONNAIRE and p.items[9143] == 0 and p.items[9142] == 0)
-- force the "chocolate" answers (variant 2)
p.kvdata.variant = 2
check("M3 milk delivery", eclesius:say(p, "mission"), "The milk delivery! Right?")
eclesius:say(p, "no")
eclesius:say(p, "yes")
check("M3 not asked yet", eclesius:say(p, "they like chocolate"), "Did you really ask both of them?")
eclesius:bye(p)

check("Amarie questionnaire greeting", amarie:say(p, "hi"), "Any news from the... <blushes> dating... thing?")
check("Amarie: yes", amarie:say(p, "yes"), "I'll be honest")
check("Amarie: love (chocolate)", amarie:say(p, "Tell me something you love."), "chocolate")
check("Amarie: physical (face)", amarie:say(p, "What physical attribute should your ideal partner have?"), "handsome face")
check("Amarie: fear", amarie:say(p, "What's your greatest fear?"), "Ferumbras")
check("Amarie: dislike", amarie:say(p, "Tell me something you dislike."), "I don't like fire")
amarie:bye(p)
check("Grodrik questionnaire greeting", grodrik:say(p, "hi"), "Any news from the <whispers> dating service?")
grodrik:say(p, "yes")
check("Grodrik: love (chocolate)", grodrik:say(p, "Tell me something you love."), "Chocolate!")
check("Grodrik: colour", grodrik:say(p, "What's your favourite colour?"), "Red. Red like fire")
grodrik:bye(p)

eclesius:say(p, "hi")
eclesius:say(p, "mission")
eclesius:say(p, "no")
check("M3 what in common?", eclesius:say(p, "yes"), "what is it they both have in common?")
check("M3 wrong answer", eclesius:say(p, "they like blue eyes"), "I don't think that's something")
eclesius:say(p, "mission")
eclesius:say(p, "no")
eclesius:say(p, "yes")
check("M3 chocolate", eclesius:say(p, "they like chocolate"), "something we can easily build on")
T.check("M3 common found", mission(p) == M.COMMON_FOUND)
check("M3 potion offer", eclesius:say(p, "mission"), "Are you ready?")
check("M3 potions given", eclesius:say(p, "yes"), "remember to RUN")
T.check("two love potions", p.items[9173] == 2)
eclesius:bye(p)

check("Amarie potion greeting", amarie:say(p, "hi"), "Have you got anything interesting for me?")
check("Amarie: yes", amarie:say(p, "yes"), "So? What is it?")
check("Amarie: milkbug", amarie:say(p, "milkbug"), "bug milk")
check("Amarie: drinks", amarie:say(p, "yes"), "To love!")
amarie:bye(p)
check("Grodrik potion greeting", grodrik:say(p, "hi"), "What do you have for me today?")
check("Grodrik: beer", grodrik:say(p, "beer"), "Got a beer for me?")
check("Grodrik: drinks", grodrik:say(p, "yes"), "that's a strange beer")
grodrik:bye(p)
T.check("both drunk", mission(p) == M.BOTH_DRUNK and p.items[9173] == 0)

eclesius:say(p, "hi")
check("M3 who fell in love?", eclesius:say(p, "mission"), "Who fell in love with you??")
check("M3 both: Matchmaker", eclesius:say(p, "both"), "MUAHAHA! My plan worked!")
T.check("M3 bonus", mission(p) == M.BONUS)
check("M3 space-time offer", eclesius:say(p, "mission"), "Are you prepared?")
FS.startScene = function(player)
	FS.setMission(player, M.SCENE)
	return true
end
check("M3 here we come", eclesius:say(p, "yes"), "Space-time continuum, here we come!")
eclesius:bye(p)
-- the Eclesius of the laboratory
eclesius.setZ(8)
check("lab Eclesius: listening?", eclesius:say(p, "hi"), "Are you listening?")
check("lab Eclesius: levers", eclesius:say(p, "yes"), "Do you see these three levers?")
check("lab Eclesius: mission while levers", eclesius:say(p, "mission"), "Pull the levers")
p.storage[S.Mission] = M.RESULT
eclesius:bye(p)
check("lab Eclesius: the result?", eclesius:say(p, "hi"), "Is that... the result...?")
check("lab Eclesius: forget it", eclesius:say(p, "yes"), "Ready to go up?")
local ended
FS.endScene = function(player, up)
	ended = up
	FS.setMission(player, M.BACK)
end
check("lab Eclesius: let's go", eclesius:say(p, "yes"), "Let's go.")
T.check("scene ended, going up", ended == true and mission(p) == M.BACK)
eclesius.setZ(7)
eclesius:bye(p)
eclesius:say(p, "hi")
money = p.money
check("M3 done", eclesius:say(p, "mission"), "my memory is like a sieve")
T.check("M3 reward 750", p.money - money == 750 and mission(p) == M.DATING_DONE)

-- ---------------------------------------------------------------- mission 4
check("M4 intro", eclesius:say(p, "mission"), "let's do something for your brain")
T.check("M4 asked", mission(p) == M.BOOKS_ASKED)
local hint = eclesius:say(p, "hint")
local known = false
for _, h in ipairs(FS.hints) do
	if hint == h then
		known = true
	end
end
T.check("M4 hint is one of the six", known, hint)
check("M4 first question", eclesius:say(p, "mission"), "what colour is the 'Great Encyclopedia of the Magiverse'?")
check("M4 not a colour", eclesius:say(p, "purple"), "That's not one of the colours")
for _, c in ipairs({ "light blue", "light green", "brown", "red", "dark blue" }) do
	eclesius:say(p, c)
end
check("M4 last answer", eclesius:say(p, "light green"), "succeeded in the mission?")
check("M4 wrong", eclesius:say(p, "yes"), "I don't think that's right")
eclesius:say(p, "mission")
for _, c in ipairs({ "light blue", "light green", "brown", "red", "dark blue", "dark green" }) do
	eclesius:say(p, c)
end
check("M4 right", eclesius:say(p, "yes"), "You answered all the questions correctly")
T.check("M4 done", mission(p) == M.BOOKS_DONE)

-- ---------------------------------------------------------------- mission 5
check("M5 offer", eclesius:say(p, "mission"), "Frodo's tavern")
eclesius:say(p, "yes")
T.check("M5 accepted", mission(p) == M.MEMORY_ASKED)
eclesius:bye(p)
frodo:say(p, "hi")
check("Frodo: eclesius", frodo:say(p, "eclesius"), "He's a good customer")
check("Frodo: last night", frodo:say(p, "last night"), "he was here last evening")
check("Frodo: talked", frodo:say(p, "talked"), "Maybe just ask around for Eclesius.")
frodo:bye(p)
xodet:say(p, "hi")
local xodetChain = {
	{ "eclesius", "only vaguely" },
	{ "potion", "only the conventional ones" },
	{ "formula", "I'm not a magician" },
	{ "eclesius", "Just the usual chit-chat." },
	{ "chit chat", "That's none of your business!!" },
	{ "magician", "So who sent you?!" },
	{ "eclesius", "Go away, topic closed!" },
}
for _, step in ipairs(xodetChain) do
	check("Xodet: " .. step[1], xodet:say(p, step[1]), step[2])
end
T.check("M5 Xodet found", mission(p) == M.XODET_FOUND)
xodet:bye(p)
eclesius:say(p, "hi")
check("M5 who?", eclesius:say(p, "mission"), "Who did I talk to??")
check("M5 Xodet", eclesius:say(p, "xodet"), "That old fox!")
check("M5 wand", eclesius:say(p, "yes"), "I hope you find it!")
T.check("M5 wand asked", mission(p) == M.WAND_ASKED)
eclesius:bye(p)
p.items[9187] = 1 -- found in the box of his basement
check("Xodet: wand greeting", xodet:say(p, "hi"), "what's that in your hand?")
check("Xodet: your first wand", xodet:say(p, "your first wand"), "take the paper with the formula")
T.check("formula given", p.items[9188] == 1 and p.items[9187] == 0)
check("Xodet plain eclesius again", xodet:say(p, "eclesius"), "good old friend")
xodet:bye(p)
eclesius:say(p, "hi")
eclesius:say(p, "mission")
money = p.money
check("M5 done", eclesius:say(p, "yes"), "I will start to brew the potion immediately")
T.check("M5 reward 500", p.money - money == 500 and mission(p) == M.MEMORY_DONE)
eclesius:bye(p)

-- ---------------------------------------------------------------- mission 6
check("greeting with name after the memory potion", eclesius:say(p, "hi"), "Oh, welcome back, Saradoc Knight, my most appreciated assistant!")
check("M6 offer", eclesius:say(p, "mission"), "Queen Eloise was a princess once")
eclesius:say(p, "yes")
T.check("M6 accepted", mission(p) == M.FROG_ASKED)
eclesius:bye(p)
eloise:say(p, "hail queen")
check("Eloise: dress", eloise:say(p, "dress"), "General Bunny Bonecrusher")
eloise:bye(p)
bunny:say(p, "hi")
bunny:say(p, "hail general")
check("Bunny: dress", bunny:say(p, "dress"), "Are you looking for something?")
check("Bunny: yes", bunny:say(p, "yes"), "spit it out!")
check("Bunny: old rags", bunny:say(p, "old rags"), "we support the needy")
T.check("bundle of rags", p.items[9191] == 1 and mission(p) == M.RAGS)
bunny:bye(p)
eclesius:say(p, "hi")
check("M6 clothes?", eclesius:say(p, "mission"), "Queen Eloise's clothes?")
check("M6 kiss him", eclesius:say(p, "yes"), "kiss my assistant")
T.check("M6 kiss asked", mission(p) == M.KISS_ASKED)
eclesius:bye(p)

check("frog: hi before the counterspell", confused:say(p, "hi"), "Err... ribbit?")
check("frog: only croaks", confused:say(p, "job"), "Ribbit")
T.check("frog: no job answer yet", not has(confused:say(p, "name"), "Turian"))
check("frog: kiss without dress", confused:say(p, "kiss"), "..... ...")
confused:say(p, "kiss")
T.check("kiss without dress does nothing", mission(p) == M.KISS_ASKED)
p.kvdata.princessUntil = os.time() + 100
p.conditions[CONDITION_OUTFIT] = true
confused:say(p, "kiss")
check("frog: second kiss as princess", confused:say(p, "kiss"), "the frog looks at you with sad eyes")
T.check("M6 kissed", mission(p) == M.KISSED)
confused:bye(p)
eclesius:say(p, "hi")
check("M6 did it work?", eclesius:say(p, "mission"), "Did the kiss work?")
check("M6 no", eclesius:say(p, "no"), "Let's try something different, shall we?")
check("M6 ingredients", eclesius:say(p, "yes"), "A silver amulet, a dagger, a green tapestry, a blank rune and a dirty fur.")
eclesius:say(p, "yes")
check("M6 bring them", eclesius:say(p, "mission"), "do you have a silver amulet")
check("M6 missing", eclesius:say(p, "yes"), "all of them at the same time")
p.items[3054], p.items[3267], p.items[2647], p.items[3147], p.items[3105] = 1, 1, 1, 1, 1
eclesius:say(p, "mission")
check("M6 counterspell ingredients", eclesius:say(p, "yes"), "very potent counterspell")
T.check("ingredients taken", p.items[2647] == 0 and p.items[3105] == 0)
check("M6 counterspell", eclesius:say(p, "mission"), "Eeny, meeny, miny, moe - ribbit, ribbit head to toe!")
check("M6 good luck", eclesius:say(p, "yes"), "I have grown rather fond of you")
eclesius:bye(p)
confused:say(p, "ribbit")
check("frog: counterspell", confused:say(p, "Eeny, meeny, miny, moe - Ribbit, ribbit head to toe!"), "I can speak the human language again!")
check("frog: name", confused:say(p, "Saradoc Knight"), "I saw you poking around here earlier")
check("frog: eclesius", confused:say(p, "eclesius"), "That old fool!")
confused:bye(p)
eclesius:say(p, "hi")
check("M6 he speaks", eclesius:say(p, "mission"), "get his {human} form back")
eclesius:bye(p)
check("frog: hi after the counterspell", confused:say(p, "hi"), "Hi, Saradoc Knight.")
check("frog: human", confused:say(p, "human"), "I don't want to be a human again")
check("frog: pond", confused:say(p, "pond"), "the pond north of Thais")
confused:bye(p)
eclesius:say(p, "hi")
check("M6 body exchange", eclesius:say(p, "mission"), "I stay here and you will go!")
eclesius:say(p, "yes")
T.check("M6 pond asked", mission(p) == M.POND_ASKED)
eclesius:bye(p)
check("A Frog: ribbit greets", frog:say(p, "ribbit"), "Ribbit.")
check("A Frog: spell", frog:say(p, "Eeny, meeny, miny, moe - I stay here and you will go!"), "first time one of the old fool's spells")
T.check("M6 swapped", mission(p) == M.SWAPPED)
frog:bye(p)
eclesius:say(p, "hi")
money = p.money
check("M6 done", eclesius:say(p, "mission"), "Now I can sleep with a clear conscience again.")
T.check("M6 reward 750, quest done", p.money - money == 750 and mission(p) == M.FROG_DONE)
check("after the quest", eclesius:say(p, "mission"), "my {tasks} still need doing")

-- the other two common answers (TibiaWiki BR names them; lines ours)
for _, case in ipairs({
	{ variant = 3, question = "What's an important character trait for you?", amarie = "portion of tolerance", grodrik = "portion of tolerance", answer = "a portion of tolerance" },
	{ variant = 4, question = "What's your greatest fear?", amarie = "lonely forever", grodrik = "old and lonely", answer = "they are lonely" },
}) do
	local q = T.player({ level = 30, name = "Variant" .. case.variant })
	q.storage[S.Questline] = 1
	q.storage[S.Mission] = M.QUESTIONNAIRE
	q.kvdata.variant = case.variant
	amarie:say(q, "hi")
	amarie:say(q, "yes")
	check("variant " .. case.variant .. ": Amarie", amarie:say(q, case.question), case.amarie)
	check("variant " .. case.variant .. ": Amarie's blue eyes question is not common", amarie:say(q, "What physical attribute should your ideal partner have?"), "handsome face")
	amarie:bye(q)
	grodrik:say(q, "hi")
	grodrik:say(q, "yes")
	check("variant " .. case.variant .. ": Grodrik", grodrik:say(q, case.question), case.grodrik)
	check("variant " .. case.variant .. ": Grodrik's love is beer", grodrik:say(q, "Tell me something you love."), "Beer of course!")
	grodrik:bye(q)
	eclesius:say(q, "hi")
	eclesius:say(q, "mission")
	eclesius:say(q, "no")
	eclesius:say(q, "yes")
	check("variant " .. case.variant .. ": blue eyes refused", eclesius:say(q, "blue eyes"), "I don't think that's something")
	eclesius:say(q, "mission")
	eclesius:say(q, "no")
	eclesius:say(q, "yes")
	check("variant " .. case.variant .. ": accepted", eclesius:say(q, case.answer), "something we can easily build on")
	eclesius:bye(q)
end
local seen = {}
for _ = 1, 200 do
	local q = T.player({ level = 30, name = "Roll" })
	seen[FS.variant(q)] = true
end
T.check("all four variants are drawn", seen[1] and seen[2] and seen[3] and seen[4] and true)

-- quest log texts
T.check("quest log: tasks", has(FS.describeTasks(p), "Sweep the house"))
T.check("quest log: finished mission 1 keeps its text", has(FS.describeMission(p, 2), "dark hat"))

T.finish()
