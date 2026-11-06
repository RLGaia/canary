-- The Rookie Guard Quest: every NPC conversation of missions 2-12 (2026-11-06).
-- Run from the repository root:
--   luajit tools/family/npc_talk/rookie_guard.lua [EN spoiler wikitext] [BR page text]
-- EN: api.php?action=parse&page=The_Rookie_Guard_Quest/Spoiler&prop=wikitext
-- BR: the TibiaWiki BR page saved as HTML and stripped to text.
--
-- One character plays the quest from Vascalir's first mission to the end.
-- The world steps (stones, rats, web, wolf den, vault, tunnel, crypt, wasp,
-- fortress) are done by setting the storages the item scripts set; those
-- scripts are checked on the server (self-test). Every NPC line of both wikis
-- must appear in what the NPCs said (compared without spaces, case and
-- {braces}); lines we chose to keep different are listed in KEPT.
local T = dofile("tools/family/npc_talk/npc_talk.lua")
local check = T.check
local RG = Storage.Quest.U9_1.TheRookieGuard
local NPC = "data-otservbr-global/npc/"

-- engine bits the Rookgaard NPCs use
IsRunningGlobalDatapack = IsRunningGlobalDatapack or function() return true end
Game.createItem = function(id, count)
	return { itemId = id, count = count or 1, getId = function(self) return self.itemId end }
end
Bank = Bank or {}
Bank.credit = function(p, n)
	p.bank = p.bank + n
	return true
end
MAPMARK_FLAG, MAPMARK_BAG, MAPMARK_GREENSOUTH, MAPMARK_GREENNORTH, MAPMARK_SKULL = 1, 2, 3, 4, 5
CONST_SLOT_WHEREEVER, CONST_SLOT_BACKPACK = 0, 3
PLAYERSEX_FEMALE = 0
isValidMoney = isValidMoney or function(n) return type(n) == "number" and n > 0 and n < 4294967296 end
getMoneyCount = getMoneyCount or function(s) return tonumber(s:match("%d+")) or -1 end
getMoneyWeight = getMoneyWeight or function() return 0 end

local said = {} -- everything the NPCs said, for the wiki line check
local function rookie(o)
	local p = T.player(o)
	p.exp = 0
	p.marks = 0
	rawset(p, "addItemEx", function(self, item)
		self:addItem(item.itemId, item.count)
		return true
	end)
	rawset(p, "addExperience", function(self, n) self.exp = self.exp + n end)
	rawset(p, "addMapMark", function(self) self.marks = self.marks + 1 end)
	rawset(p, "depositMoney", function(self, n)
		if self.money < n then return false end
		self.money = self.money - n
		self.bank = self.bank + n
		return true
	end)
	rawset(p, "getFreeCapacity", function() return 100000 end)
	return p
end

local loaded = {}
local function npc(name)
	if not loaded[name] then
		loaded[name] = T.load(NPC .. name .. ".lua")
	end
	return loaded[name]
end
local function say(name, p, text)
	local answer = npc(name):say(p, text)
	said[#said + 1] = answer
	return answer
end
local function has(answer, text)
	return answer:lower():gsub("[{}]", ""):find(text:lower(), 1, true) ~= nil
end
local function st(p, key) return p:getStorageValue(RG[key]) end

-- ------------------------------------------------------------ the walkthrough
local p = rookie({ level = 2, name = "Tester", items = {} })

-- Mission 2: Defence!
check("M2 greeting asks about the mission", has(say("vascalir", p, "hi"), "have you come to help in our mission"))
check("M2 mission explains Kraknaknork", has(say("vascalir", p, "mission"), "Sounds good?"))
local a = say("vascalir", p, "yes")
check("M2 yes gives the plan", has(a, "Have you understood all of that?") and st(p, "Mission02") == 1 and st(p, "Questline") == 1, a:sub(1, 60))
check("M2 'no' explains again", has(say("vascalir", p, "no"), "Let me explain again"))
check("M2 yes ends", has(say("vascalir", p, "yes"), "Off to work with you"))
-- while carrying stones
p.storage[RG.Mission02] = 2
a = say("vascalir", p, "hi")
check("M2 running: greeting", has(a, "Your task is still not done"))
a = say("vascalir", p, "no")
check("M2 running: 'no' explains the task again", has(a, "Let me explain again"), a:sub(1, 70))
a = say("vascalir", p, "yes")
check("M2 running: 'yes' answers", has(a, "off to work"), a:sub(1, 70))
say("vascalir", p, "bye")
-- two catapults loaded
p.storage[RG.Mission02] = 4
check("M2 done: greeting", has(say("vascalir", p, "hi"), "I've heard a loud rumbling from the roof"))
a = say("vascalir", p, "yes")
check("M2 reward studded shield", has(a, "Take this studded shield") and p.items[3426] == 1 and st(p, "Mission02") == 5)
check("M3 'no' refreshes the memory", has(say("vascalir", p, "no"), "No worries, let's refresh your memory"))
a = say("vascalir", p, "yes")
check("M3 rats explained", has(a, "please kill 5 rats") and has(a, "Are you ready to go?"))
a = say("vascalir", p, "yes")
check("M3 accepted", has(a, "I've marked two rat dungeons") and st(p, "Mission03") == 1 and st(p, "RatKills") == 0)
say("vascalir", p, "bye")

-- Mission 3: three rats, then five
p.storage[RG.RatKills] = 3
check("M3 greeting", has(say("vascalir", p, "hi"), "Are you done with the 5 rats"))
a = say("vascalir", p, "yes")
check("M3 2 rats missing", has(a, "2 more rats"), a)
a = say("vascalir", p, "no")
check("M3 'no' while missing rats", a ~= "" and not has(a, "LUA ERROR"), a)
say("vascalir", p, "bye")
p.storage[RG.RatKills] = 5
say("vascalir", p, "hi")
a = say("vascalir", p, "yes")
check("M3 reward sabre, 30 exp, Lily", has(a, "Find Lily south-west of here") and p.items[3273] == 1 and p.exp == 30 and st(p, "Mission04") == 1)
say("vascalir", p, "bye")
check("M4 Vascalir points to Lily", has(say("vascalir", p, "hi"), "Lily"))

-- Mission 4: Lily and Hyacinth
check("M4 Lily greeting", has(say("lily", p, "hi"), "Vascalir must have sent you to help me"))
check("M4 Lily mission", has(say("lily", p, "mission"), "Could you please deliver a bag of herbs to Hyacinth?"))
a = say("lily", p, "yes")
check("M4 Lily gives herbs", has(a, "Here you go, honey") and p.items[12671] == 1 and st(p, "Mission04") == 2)
say("lily", p, "bye")
check("M4 Lily asks back", has(say("lily", p, "hi"), "Have you delivered the herbs"))
check("M4 Lily lost herbs?", has(say("lily", p, "no"), "You didn't lose the herbs"))
check("M4 Lily honest", has(say("lily", p, "yes"), "another sack"))
say("lily", p, "yes")
check("M4 Lily second sack", p.items[12671] == 2)
say("lily", p, "bye")
check("M4 Hyacinth greeting", has(say("hyacinth", p, "hi"), "Do you have a sack of herbs for me?"))
a = say("hyacinth", p, "herbs")
check("M4 Hyacinth takes the herbs (EN: 'herbs')", has(a, "would you like to have a sample of my potions") and st(p, "Mission04") == 3)
a = say("hyacinth", p, "yes")
check("M4 two small health potions", has(a, "two small health potions") and p.items[7876] == 2)
a = say("hyacinth", p, "yes")
check("M4 star ring", has(a, "Take this star ring") and p.items[12669] == 1 and st(p, "Mission04") == 5)
say("hyacinth", p, "bye")
-- a second character without herbs at Hyacinth
local q = rookie({ storage = { [RG.Mission04] = 2 } })
say("hyacinth", q, "hi")
a = say("hyacinth", q, "yes")
check("M4 Hyacinth: yes without herbs answers", a ~= "" and not has(a, "LUA ERROR"), a:sub(1, 70))
say("hyacinth", q, "bye")

-- Mission 5: Web of Terror
say("vascalir", p, "bye")
check("M5 greeting asks for help", has(say("vascalir", p, "hi"), "I could use your help again"))
a = say("vascalir", p, "help")
check("M5 help explains the spider queen", has(a, "Do you dare sneak into the tarantula's lair"))
a = say("vascalir", p, "yes")
check("M5 accepted", has(a, "That's very courageous") and st(p, "Mission05") == 1)
say("vascalir", p, "bye")
p.storage[RG.Mission05] = 3
a = say("vascalir", p, "hi")
check("M5 web delivered", has(a, "Let me take that spider web sample from you") and p.exp == 80)
a = say("vascalir", p, "yes")
check("M5 studded armor, Tom", has(a, "Tom the Tanner") and p.items[3378] == 1 and st(p, "Mission06") == 1)

-- Mission 6: Tom
say("vascalir", p, "bye")
check("M6 Tom greeting", has(say("tom", p, "hi"), "Did Vascalir send you to me for a mission?"))
check("M6 Tom mission", has(say("tom", p, "mission"), "What do you say?"))
a = say("tom", p, "yes")
check("M6 Tom accepted", has(a, "I marked the wolf den on your map") and st(p, "Mission06") == 2)
say("tom", p, "hi")
say("tom", p, "bye")
p.storage[RG.Mission06] = 6
p.items[12740] = 1
check("M6 Tom finish greeting", has(say("tom", p, "hi"), "were you able to find some war wolf leather?"))
a = say("tom", p, "yes")
check("M6 leather boots", has(a, "unfortunately the skin is damaged too badly") and p.items[3552] == 1 and st(p, "Mission06") == 7)
say("tom", p, "bye")
-- a character who lost the skin after the run
q = rookie({ storage = { [RG.Mission06] = 6 } })
say("tom", q, "hi")
a = say("tom", q, "yes")
check("M6 Tom: lost skin does not get stuck", (q.items[3552] or 0) == 1 or st(q, "Mission06") ~= 6, a:sub(1, 80))
say("tom", q, "bye")

-- Mission 7: Attack!
say("vascalir", p, "bye")
check("M7 greeting", has(say("vascalir", p, "hi"), "Do you smell the fire?"))
check("M7 yes", has(say("vascalir", p, "yes"), "Are you ready"))
a = say("vascalir", p, "yes")
check("M7 accepted", has(a, "ask Cipfried in the temple") and st(p, "Mission07") == 1)
say("vascalir", p, "bye")
p.storage[RG.LibraryChest] = 1
p.items[12675] = 1
check("M7 book greeting", has(say("vascalir", p, "hi"), "Did you get the book?"))
a = say("vascalir", p, "yes")
check("M7 reward 100 gold and 100 exp", has(a, "Are you prepared for your next mission?") and p.items[3035] == 1 and p.exp == 180 and st(p, "Mission07") == 2)

-- Mission 8: Paulie
a = say("vascalir", p, "yes")
check("M8 accepted", has(a, "Go downstairs and talk to Paulie") and st(p, "Mission08") == 1)
p.money = 100
say("vascalir", p, "bye")
check("M8 Paulie greeting", has(say("paulie", p, "hi"), "Special newcomer offer"))
check("M8 deposit all", has(say("paulie", p, "deposit all"), "Would you really like to deposit 100 gold?"))
a = say("paulie", p, "yes")
check("M8 deposit + 50 bonus (EN: 'added the amount of 150 gold')", has(a, "added the amount of 150 gold") and p.bank == 150 and st(p, "Mission08") == 2, a)
say("paulie", p, "bye")
-- a character whose deposit fails gets no bonus
q = rookie({ money = 0, storage = { [RG.Mission08] = 1 } })
say("paulie", q, "hi")
say("paulie", q, "deposit 50")
say("paulie", q, "yes")
check("M8 no bonus without money", q.bank == 0 and st(q, "Mission08") == 1, "bank " .. q.bank)
say("paulie", q, "bye")

-- Mission 9: Rock 'n Troll
check("M9 greeting", has(say("vascalir", p, "hi"), "it's time to go after the trolls"))
a = say("vascalir", p, "yes")
check("M9 accepted", has(a, "find a way to make it collapse") and st(p, "Mission09") == 1)
say("vascalir", p, "bye")
p.storage[RG.Mission09] = 8
check("M9 done", has(say("vascalir", p, "hi"), "Here, want a helmet?") and p.exp == 230)
a = say("vascalir", p, "yes")
check("M9 brass helmet", has(a, "This brass helmet") and p.items[3354] == 1 and st(p, "Mission09") == 10)

-- Mission 10: Tomb Raiding
say("vascalir", p, "bye")
check("M10 greeting", has(say("vascalir", p, "hi"), "Are you ready for your next mission?"))
a = say("vascalir", p, "yes")
check("M10 garlic necklace", has(a, "Take this garlic necklace") and p.items[3083] == 1 and st(p, "Mission10") == 1)
say("vascalir", p, "bye")
p.storage[RG.Sarcophagus] = 1
p.items[12674] = 1
check("M10 bone greeting", has(say("vascalir", p, "hi"), "Did you find a nice, fleshy bone"))
a = say("vascalir", p, "yes")
check("M10 bone taken, 150 exp", has(a, "would you like to have this sword?") and p.items[12674] == 0 and p.exp == 380)
a = say("vascalir", p, "yes")
check("M10 sword", has(a, "This sword has helped me") and p.items[3264] == 1 and st(p, "Mission10") == 3)

-- Mission 11: Sweet Poison
say("vascalir", p, "bye")
check("M11 greeting", has(say("vascalir", p, "hi"), "I'm in a really good mood"))
check("M11 explained", has(say("vascalir", p, "yes"), "Are you prepared for that mission?"))
a = say("vascalir", p, "yes")
check("M11 flask and silver amulet", has(a, "Here is the empty flask") and p.items[12785] == 1 and p.items[3054] == 1 and st(p, "Mission11") == 1)
say("vascalir", p, "bye")
p.storage[RG.Mission11] = 3
p.items[12785] = 0
p.items[12784] = 1
check("M11 poison greeting", has(say("vascalir", p, "hi"), "Were you able to bring back some wasp poison?"))
a = say("vascalir", p, "yes")
check("M11 antidote, 150 exp", has(a, "Here, can you carry it?") and p.items[7644] == 1 and p.items[12784] == 0 and p.exp == 530)
a = say("vascalir", p, "yes")
check("M11 brass shield", has(a, "This brass shield") and p.items[3411] == 1 and st(p, "Mission11") == 5)

-- Mission 12: Into The Fortress
say("vascalir", p, "bye")
check("M12 greeting", has(say("vascalir", p, "hi"), "the time of our triumph has come"))
a = say("vascalir", p, "yes")
check("M12 plan", has(a, "take the items and go claim your victory") and st(p, "Mission12") == 1)
say("vascalir", p, "bye")
p.storage[RG.Mission12] = 14
check("M12 return greeting", has(say("vascalir", p, "hi"), "were you able to kill Kraknaknork?"))
a = say("vascalir", p, "yes")
check("M12 finished", has(a, "It's good to know you") and st(p, "Mission12") == 15 and st(p, "Questline") == 2)
say("vascalir", p, "bye")
check("after the quest", has(say("vascalir", p, "hi"), "the only thing left for you to do here"))

-- a character of level 8 or more is not told to reach level 8
q = rookie({ level = 9, storage = { [RG.Questline] = 1, [RG.Mission02] = 5, [RG.Mission03] = 2, [RG.Mission04] = 6, [RG.Mission05] = 6, [RG.Mission06] = 7, [RG.Mission07] = 2, [RG.Mission08] = 2, [RG.Mission09] = 10, [RG.Mission10] = 3, [RG.Mission11] = 5, [RG.Mission12] = 14 } })
say("vascalir", q, "hi")
a = say("vascalir", q, "yes")
check("M12 finished at level 9 without the level 8 line", has(a, "talk to the oracle") and not has(a, "reach level 8") and st(q, "Questline") == 2, a:sub(1, 60))
say("vascalir", q, "bye")

-- Level gates
q = rookie({ level = 60 })
check("level 60 can start (no level limit)", has(say("vascalir", q, "hi"), "have you come to help in our mission"))
say("vascalir", q, "mission")
check("level 60 starts Mission 2", has(say("vascalir", q, "yes"), "Have you understood all of that?") and st(q, "Mission02") == 1)
say("vascalir", q, "bye")
q = rookie({ level = 8, storage = { [RG.Questline] = 1, [RG.Mission02] = 5, [RG.Mission03] = 1, [RG.RatKills] = 2 } })
local greet = say("vascalir", q, "hi")
check("no level 8 warning", not has(greet, "small word of advice") and has(greet, "Are you done with the 5 rats"), greet:sub(1, 60))
say("vascalir", q, "bye")
Family.rookieGuardNoLevelLimit = false
q = rookie({ level = 6 })
check("switch off: too experienced at level 6 (upstream)", has(say("vascalir", q, "hi"), "already too experienced"))
q = rookie({ level = 8, storage = { [RG.Questline] = 1, [RG.Mission02] = 5, [RG.Mission03] = 1 } })
check("switch off: level 8 warning (upstream)", has(say("vascalir", q, "hi"), "small word of advice"))
check("switch off: continue", has(say("vascalir", q, "continue"), "heed my words"))
Family.rookieGuardNoLevelLimit = true

-- every {highlighted} word answers (quest words are checked in their steps above)
local QUEST_WORDS = { mission = true, help = true, herbs = true, continue = true, delete = true, yes = true, ["deposit all"] = true,
	-- Tom's general talk (not the quest), no source for his answers
	rookgaard = true, sewers = true, shovel = true }
for _, name in ipairs({ "vascalir", "lily", "hyacinth", "tom", "paulie" }) do
	T.checkHints(npc(name), function() return rookie({ level = 2 }) end, QUEST_WORDS)
end

-- ------------------------------------------------- wiki lines against answers
local function norm(s)
	return (s:lower():gsub("|playername|", "tester"):gsub("jogador", "tester"):gsub("player", "tester"):gsub("[{}]", ""):gsub("[%s%.']", ""))
end
local function norm0(s)
	return norm(s)
end
local KEPT = {
	-- lines we keep different on purpose (start of the wiki line, normalized -> why)
	[norm0("Carry one stone to each of the four catapults")] = "two of four are enough (BR text, EN spoiler); Norma's bar is north",
	[norm0("Use the stone on the catapult to load the catapult.")] = "asks for two catapults",
	[norm0("Greetings, Player. I've heard a loud rumbling")] = "asks for two catapults",
	[norm0("Greetings, Jogador. I've heard a loud rumbling")] = "asks for two catapults",
	[norm0("Well done! The villagers are much safer now that all catapults")] = "two catapults",
	[norm0("Ah, that came with confidence.")] = "'a sword': the wooden sword is gone since Dawnport (EN history)",
	[norm0("You can find rats in the sewers.")] = "'infestation' typo fixed",
	[norm0("Take this star ring.")] = "the star ring runs for a limited time here (items.xml), so the longer upstream text",
	[norm0("That's very courageous. I mark the spider lair")] = "'I'll mark' and a torch tip",
	[norm0("Are you ready go go?")] = "wiki typo",
	[norm0("Great job down there! You do deserve a reward")] = "names the platinum coin (100 gold, EN reward)",
	[norm0("It's probably safer to get used to depositing")] = "'on your bank account'",
	[norm0("This brass helmet will make sure")] = "'I probably should have'",
	[norm0("However, I can give you something for protection")] = "'as it usually would do'",
	[norm0("Here, let me take that old coat of yours.")] = "BR only; EN has the shorter line we use",
	[norm0("Would you really like to deposit x gold?")] = "BR placeholder (EN 100 gold is checked)",
	[norm0("Alright, we have added the amount of x+50 gold")] = "BR placeholder (EN 150 gold is checked)",
	[norm0("You have to reach level 8 by hunting some monsters, but that's something you should have grown accustomed to you")] = "EN typo 'to you' (BR line is checked)",
}
local all = norm(table.concat(said, " "))
local function readFile(path)
	local f = path and io.open(path)
	if not f then return nil end
	local s = f:read("*a")
	f:close()
	return s
end
local NAMES = { Vascalir = true, Lily = true, Hyacinth = true, Tom = true, Paulie = true }
local function lineCheck(source, who, text)
	text = text:gsub("<br%s*/?>", ""):gsub("'''", ""):gsub("''", ""):gsub("%[%[[^%]|]*|([^%]]*)%]%]", "%1"):gsub("%[%[([^%]]*)%]%]", "%1")
	text = text:gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("%s*%.%.%.%s*$", "")
	local n = norm(text)
	if #n < 8 then return end
	for prefix, why in pairs(KEPT) do
		if n:sub(1, #prefix) == prefix then
			check(source .. " " .. who .. " (kept: " .. why .. ")", true)
			return
		end
	end
	check(source .. " " .. who .. ": " .. text:sub(1, 60), all:find(n, 1, true) ~= nil)
end
local en = readFile(arg[1])
if en then
	for body in en:gmatch("{{Infobox Transcript|(.-)}}") do
		for line in body:gmatch("[^\n]+") do
			local who, what = line:match("^''(%a+)'':%s*(.+)$")
			if not who then who, what = line:match("^(%a+):%s*(.+)$") end
			if who and NAMES[who] then lineCheck("EN", who, what) end
		end
	end
end
local br = readFile(arg[2])
if br then
	for line in br:gmatch("[^\n]+") do
		local who, what = line:match("^%s*(%a+):%s*(.+)$")
		if who and NAMES[who] then lineCheck("BR", who, what) end
	end
end

T.finish()
