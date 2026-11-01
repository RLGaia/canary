-- Dawnport conversations and the Dawnport Quest (2026-11-01).
-- Run from the repository root:  luajit tools/family/npc_talk/dawnport.lua [transcripts-dir]
-- transcripts-dir (optional) holds TibiaWiki EN wikitext files to replay
-- (Inigo_Transcripts.txt, Dawnport_Quest_Spoiler.txt): every "Player: x" line
-- must get an answer from that NPC.
local T = dofile("tools/family/npc_talk/npc_talk.lua")
local D = Storage.Quest.U10_55.Dawnport
local check = T.check
local transcriptsDir = arg and arg[1]

local NPC = "data-otservbr-global/npc/"
local function load(name) return T.load(NPC .. name .. ".lua") end
local function has(text, pattern) return text:lower():find(pattern:lower(), 1, true) ~= nil end

-- ------------------------------------------------------------------ Woblin
local woblin = load("woblin")
do
	-- TibiaWiki BR: Hi - Key - Reward
	local p = T.player({ storage = { [D.TheDormKey] = 1 } })
	woblin:say(p, "hi")
	check("Woblin key (state 1) opens the step", has(woblin:say(p, "key"), "provide Woblin with some {reward}"))
	check("Woblin reward gives the fish task", has(woblin:say(p, "reward"), "Old Nasty") and p.storage[D.TheDormKey] == 2)
	check("Woblin key (state 2) reminds", has(woblin:say(p, "key"), "Bring me {Old Nasty}"))
	check("Woblin Old Nasty asks", has(woblin:say(p, "old nasty"), "You bring me Old Nasty?"))
	check("Woblin no (EN line)", has(woblin:say(p, "no"), "No waste time of Woblin"))
	woblin:say(p, "old nasty")
	check("Woblin yes without the fish refuses", has(woblin:say(p, "yes"), "You have not Old Nasty") and p.storage[D.TheDormKey] == 2)
	p.storage[D.TheDormKey] = 3
	p.items[21402] = 1
	woblin:say(p, "old nasty")
	check("Woblin yes with the fish gives the key", has(woblin:say(p, "yes"), "Here take lousy key") and p.items[21392] == 1 and p.items[21402] == 0 and p.storage[D.TheDormKey] == 4)
	check("Woblin key afterwards (EN line)", has(woblin:say(p, "key"), "Lost what? Key?"))
	check("Woblin precious afterwards", has(woblin:say(p, "precious"), "keep lousy key"))
	check("Woblin Old Nasty afterwards", woblin:say(p, "old nasty") ~= "")
	check("Woblin reward afterwards", woblin:say(p, "reward") ~= "")
	-- TibiaWiki EN: precious - reward
	local e = T.player({ storage = { [D.TheDormKey] = 1 } })
	woblin:say(e, "hi")
	woblin:say(e, "precious")
	check("Woblin EN path precious - reward", has(woblin:say(e, "reward"), "Old Nasty") and e.storage[D.TheDormKey] == 2)
	-- reward without asking about the key first
	local r = T.player({ storage = { [D.TheDormKey] = 1 } })
	woblin:say(r, "hi")
	check("Woblin reward straight away", has(woblin:say(r, "reward"), "Old Nasty") and r.storage[D.TheDormKey] == 2)
	-- before Mr Morris' task
	local f = T.player({})
	woblin:say(f, "hi")
	for _, w in ipairs({ "key", "precious", "reward", "old nasty" }) do
		check("Woblin " .. w .. " before the task answers", woblin:say(f, w) ~= "")
	end
	check("Woblin before the task gives nothing", f.storage[D.TheDormKey] == nil and #f.added == 0)
end

-- --------------------------------------------------------------- Mr Morris
local morris = load("mr_morris")
do
	local p = T.player({})
	check("Morris greets", has(morris:say(p, "hi"), "{quest} or {mission}"))
	check("Morris mission", has(morris:say(p, "mission"), "{fetch}"))
	check("Morris fetch", has(morris:say(p, "fetch"), "{amulet}"))
	check("Morris kill", has(morris:say(p, "kill"), "{trolls}"))

	-- The Dorm Key (TibiaWiki BR: Hi - Mission - Key - Yes ... Hi - Key - Yes)
	check("Morris key offers", has(morris:say(p, "key"), "You in?"))
	check("Morris key yes", has(morris:say(p, "yes"), "Just chat with the guys") and p.storage[D.TheDormKey] == 1)
	for state = 1, 3 do
		p.storage[D.TheDormKey] = state
		check("Morris key in state " .. state .. " answers", has(morris:say(p, "key"), "Just chat with the guys"))
	end
	p.storage[D.TheDormKey] = 4
	check("Morris key report asks", has(morris:say(p, "key"), "any progress?"))
	check("Morris key yes without the key refuses", has(morris:say(p, "yes"), "don't seem to have the key") and p.storage[D.TheDormKey] == 4 and (p.items[3031] or 0) == 0)
	p.items[21392] = 1
	morris:say(p, "key")
	check("Morris key yes with the key pays", has(morris:say(p, "yes"), "real sleuth") and p.items[3031] == 50 and p.items[21392] == 0 and p.storage[D.TheDormKey] == 5)
	check("Morris key afterwards answers", morris:say(p, "key") ~= "")

	-- The Lost Amulet
	check("Morris amulet offers", has(morris:say(p, "amulet"), "errand?"))
	check("Morris amulet yes", has(morris:say(p, "yes"), "Dormovo") and p.storage[D.TheLostAmulet] == 1)
	check("Morris amulet in progress answers", morris:say(p, "amulet") ~= "")
	p.storage[D.TheLostAmulet] = 2
	check("Morris amulet found but not carried answers", morris:say(p, "amulet") ~= "" and p.storage[D.TheLostAmulet] == 2)
	p.items[21379] = 1
	check("Morris amulet report pays", has(morris:say(p, "amulet"), "Poor Dormovo") and p.items[3031] == 100 and p.storage[D.TheLostAmulet] == 3)
	check("Morris amulet afterwards answers", morris:say(p, "amulet") ~= "")

	-- The Stolen Log Book: chest opened BEFORE taking the task (upstream bug)
	local c = T.player({ storage = { [D.TornLogBook] = 1 }, items = { [21378] = 1 } })
	morris:say(c, "hi")
	check("Morris log book offers after the chest", has(morris:say(c, "log book"), "Would you go looking for it?"))
	morris:say(c, "yes")
	check("Morris log book reports after the chest", has(morris:say(c, "logbook"), "Torn and gnawed") and c.storage[D.TheStolenLogBook] == 2 and c.items[3031] == 50)
	check("Morris log book afterwards answers", morris:say(c, "log book") ~= "")
	-- a book from someone else (EN line)
	local o = T.player({ storage = { [D.TheStolenLogBook] = 1 }, items = { [21378] = 1 } })
	morris:say(o, "hi")
	check("Morris log book not from the chest (EN line)", has(morris:say(o, "log book"), "not readable at all") and o.storage[D.TheStolenLogBook] == 1)
	local n = T.player({ storage = { [D.TheStolenLogBook] = 1 } })
	morris:say(n, "hi")
	check("Morris log book in progress answers", morris:say(n, "log book") ~= "")

	-- The Rare Herb (singular too)
	local h = T.player({})
	morris:say(h, "hi")
	check("Morris herb offers", has(morris:say(h, "herb"), "Dawnfire"))
	morris:say(h, "yes")
	check("Morris herbs yes", h.storage[D.TheRareHerb] == 1)
	check("Morris herbs in progress reminds", has(morris:say(h, "herbs"), "yellow glowing"))
	h.storage[D.TheRareHerb] = 2
	check("Morris herbs report pays", has(morris:say(h, "herbs"), "Freshly cut") and h.items[3031] == 50 and h.storage[D.TheRareHerb] == 3)
	check("Morris herbs afterwards answers", morris:say(h, "herbs") ~= "")

	-- Kill tasks
	local k = T.player({})
	morris:say(k, "hi")
	check("Morris troll (singular, BR report word) offers", has(morris:say(k, "troll"), "kill 20 mountain trolls"))
	morris:say(k, "yes")
	check("Morris trolls accepted", k.storage[D.MorriskTroll] == 1 and k.storage[D.MorrisTrollCount] == 0)
	k.storage[D.MorrisTrollCount] = 7
	check("Morris trolls progress", has(morris:say(k, "trolls"), "slain 7"))
	k.storage[D.MorrisTrollCount] = 20
	check("Morris trolls report pays", has(morris:say(k, "trolls"), "very good job") and k.items[3031] == 50 and k.storage[D.MorriskTroll] == 2)
	check("Morris trolls afterwards answers", morris:say(k, "trolls") ~= "")
	check("Morris goblin offers", has(morris:say(k, "goblin"), "muglex clan footmen"))
	morris:say(k, "yes")
	k.storage[D.MorrisGoblinCount] = 20
	check("Morris goblins report pays", has(morris:say(k, "goblins"), "very good job") and k.storage[D.MorrisGoblin] == 2)
	check("Morris minotaur offers", has(morris:say(k, "minotaur"), "minotaur bruisers"))
	check("Morris no declines", morris:say(k, "no") ~= "" and k.storage[D.MorrisMinos] == nil)
	-- kills before talking keep their count when the task is accepted
	local early = T.player({ storage = { [D.MorrisMinos] = -1, [D.MorrisMinosCount] = 5 } })
	morris:say(early, "hi")
	morris:say(early, "minotaurs")
	morris:say(early, "yes")
	check("Morris accept keeps earlier kills", early.storage[D.MorrisMinosCount] == 5)
end

-- ----------------------------------------------- kill counting without talking
do
	local handlers = {}
	CreatureEvent = function(name)
		local o = { name = name }
		function o:register() handlers[self.name] = self end
		return o
	end
	onDeathForParty = function(creature, killer, fn) fn(creature, killer) end
	for _, f in ipairs({ "troll", "goblin", "minotaur" }) do
		dofile("data-otservbr-global/scripts/quests/dawnport/creaturescripts_" .. f .. "_kill.lua")
	end
	local cases = {
		{ "MorrisTrollDeath", D.MorriskTroll, D.MorrisTrollCount },
		{ "MorrisGoblinDeath", D.MorrisGoblin, D.MorrisGoblinCount },
		{ "MorrisMinotaurDeath", D.MorrisMinos, D.MorrisMinosCount },
	}
	for _, c in ipairs(cases) do
		local h = handlers[c[1]]
		check(c[1] .. " registered", h ~= nil)
		if h then
			local p = T.player({ town = 2 })
			for _ = 1, 25 do
				h.onDeath({}, nil, nil, p)
			end
			check(c[1] .. ": starts without talking and stops at 20", p.storage[c[2]] == 1 and p.storage[c[3]] == 20, tostring(p.storage[c[3]]))
			local m = T.player({ town = 8 })
			h.onDeath({}, nil, nil, m)
			check(c[1] .. ": a mainland character gets no task", m.storage[c[2]] == nil)
			local done = T.player({ town = 2, storage = { [c[2]] = 2, [c[3]] = 20 } })
			h.onDeath({}, nil, nil, done)
			check(c[1] .. ": a finished task stays finished", done.storage[c[2]] == 2 and done.storage[c[3]] == 20)
		end
	end
end

-- ------------------------------------------ the outpost NPCs answer "key"
local keyLines = {
	plunderpurse = "I'm a clerk now",
	garamond = "How should I know where that key",
	ser_tybald = "Mr Morris has much on his mind",
	hamish = "leaving the key here and there",
	richard = "key had been stolen",
	coltrayne = "key might have been stolen",
	oressa = "I believe it has been lost",
	inigo = "Woblin sneaking around",
}
local talks = { woblin = woblin, mr_morris = morris }
for name, line in pairs(keyLines) do
	talks[name] = talks[name] or load(name)
	local p = T.player({ storage = { [D.TheDormKey] = 1 } })
	talks[name]:say(p, "hi")
	check(name .. " key (EN line)", has(talks[name]:say(p, "key"), line))
end

-- ------------------------------------------------------------ Inigo fixes
local inigo = talks.inigo or load("inigo")
talks.inigo = inigo
do
	local p = T.player({ level = 5 })
	inigo:say(p, "hi")
	inigo:say(p, "sure")
	inigo:say(p, "leave")
	check("Inigo: 'sure' or 'leave' alone does not send to Rookgaard", p.teleported == nil and p.town == 2)
	local h1 = inigo:say(p, "hints")
	local h2 = inigo:say(p, "hint")
	check("Inigo hints: one at a time, in order", has(h1, "icon on the minimap") and has(h2, "look at or click on objects"))
	for _ = 3, 35 do inigo:say(p, "hints") end
	check("Inigo hints: start again after the last", has(inigo:say(p, "hints"), "icon on the minimap"))
	check("Inigo fighting answers", has(inigo:say(p, "fighting"), "open gates"))
	check("Inigo trade opens his shop", (inigo:say(p, "trade") ~= "") and rawget(p, "shopOpened") == true)
	check("Inigo buys 34 creature products", #inigo.type.config.shop == 34)
	local r = T.player({ level = 5, accountStorage = { [Storage.Dawnport.Mainland] = 1 } })
	inigo:say(r, "hi")
	inigo:say(r, "rookgaard")
	inigo:say(r, "yes")
	inigo:say(r, "sure")
	check("Inigo: rookgaard - yes - sure still goes to Rookgaard", r.town == TOWNS_LIST.ROOKGAARD)
end

-- ----------------------------------------------------------- Oressa fixes
local oressa = talks.oressa or load("oressa")
talks.oressa = oressa
do
	removeMainlandSmugglingItems = removeMainlandSmugglingItems or function() end
	for _, w in ipairs({ "heal", "healing", "help" }) do
		local hurt = T.player({ level = 12, health = 30, maxHealth = 200 })
		oressa:say(hurt, "hi")
		check("Oressa " .. w .. " heals a wounded level 12", has(oressa:say(hurt, w), "I will heal your wounds") and hurt.health == 200)
		local poisoned = T.player({ level = 3, health = 150, maxHealth = 150, conditions = { [CONDITION_POISON] = true } })
		oressa:say(poisoned, "hi")
		check("Oressa " .. w .. " cures poison at full health", has(oressa:say(poisoned, w), "I will heal your wounds") and not poisoned.conditions[CONDITION_POISON])
		local fine = T.player({ level = 3 })
		oressa:say(fine, "hi")
		check("Oressa " .. w .. " healthy: no healing needed", has(oressa:say(fine, w), "do not need any healing"))
	end
	local low = T.player({ level = 3 })
	oressa:say(low, "hi")
	oressa:say(low, "bow")
	oressa:say(low, "yes")
	check("Oressa: 'bow', 'yes' at level 3 does not make a paladin", low.vocation == 0)
	local function choose(lines, vocation, name)
		local p = T.player({ level = 8 })
		oressa:say(p, "hi")
		for _, l in ipairs(lines) do oressa:say(p, l) end
		check("Oressa choose: " .. table.concat(lines, " - ") .. " makes a " .. name, p.vocation == vocation, p.vocation)
	end
	choose({ "choosing", "distance", "bow", "yes" }, VOCATION.ID.PALADIN, "paladin")
	choose({ "choose", "distance", "magic", "heal", "yes" }, VOCATION.ID.DRUID, "druid")
	choose({ "choose", "distance", "magic", "death", "yes" }, VOCATION.ID.SORCERER, "sorcerer")
	choose({ "choose", "close", "yes" }, VOCATION.ID.KNIGHT, "knight")
	choose({ "decided", "knight", "yes" }, VOCATION.ID.KNIGHT, "knight")
	local no = T.player({ level = 8 })
	oressa:say(no, "hi")
	oressa:say(no, "choose")
	oressa:say(no, "close")
	check("Oressa: 'no' keeps the vocation", oressa:say(no, "no") ~= "" and no.vocation == 0)
end

-- --------------------------------- every highlighted {word} of every Dawnport NPC
for _, name in ipairs({ "inigo", "oressa", "mr_morris", "woblin", "coltrayne", "richard", "hamish", "garamond", "ser_tybald", "plunderpurse", "wentworth", "captain_dreadnought", "ambassador_manop" }) do
	talks[name] = talks[name] or load(name)
	-- words that only answer inside a step (checked above)
	local skip = {
		inigo = { leave = true, sure = true },
		oressa = { yes = true, close = true, distance = true, bow = true, spear = true, magic = true, death = true },
	}
	T.checkHints(talks[name], function() return T.player({ level = 10 }) end, skip[name] or {})
end

-- ------------------------------------------------ TibiaWiki EN transcripts
local function replay(file, speakers)
	local f = transcriptsDir and io.open(transcriptsDir .. "/" .. file)
	if not f then
		print("(skipped " .. file .. ": no transcripts dir)")
		return
	end
	local text = f:read("*a"):gsub("<br%s*/?>", "\n")
	f:close()
	for block in text:gmatch("{{Infobox Transcript|(.-)}}") do
		local current, p = nil, nil
		for line in block:gmatch("[^\n]+") do
			local who, said = line:match("^%s*'*([%w ]-)'*%s*:%s*(.+)$")
			if who then
				who = who:gsub("^%[%[", ""):gsub("%]%]$", "")
				said = said:gsub("'''", ""):gsub("%[%[([^|%]]-)|?([^%]]*)%]%]", function(a, b) return b ~= "" and b or a end)
				if who:lower() == "player" then
					-- "travel or ship" = either word; take the first
					current = said:gsub("^:%s*", ""):gsub("%s+or%s+.*$", "")
				elseif current and speakers[who] then
					local t = talks[speakers[who]]
					p = p or {}
					p[who] = p[who] or T.player({ level = 10, storage = { [D.TheDormKey] = 1 } })
					if not t.npc.interacting[p[who]:getId()] and current:lower() ~= "hi" then
						t:say(p[who], "hi")
					end
					local answer = t:say(p[who], current)
					check(file .. ": " .. who .. " answers '" .. current .. "'", answer ~= "" or current:lower() == "bye", answer:sub(1, 60))
					current = nil
				end
			end
		end
	end
end
replay("Inigo_Transcripts.txt", { Inigo = "inigo" })

T.finish()
