-- Hot Cuisine Quest: Jean Pierre without the yearly limit (2026-11-16).
-- Run from the repository root:
--   luajit tools/family/npc_talk/hot_cuisine.lua [EN spoiler wikitext] [BR page wikitext]
-- One character plays the whole course and menu (15 dishes), then cooks again at will. Checks the
-- states the wikis do not show (dish not taught yet, missing ingredients, wrong fluid, recooking,
-- older characters, Culinary Master, Cookbook II door, quest log) and, with the optional files,
-- replays every transcript of TibiaWiki EN (Hot_Cuisine_Quest/Spoiler) and of our TibiaWiki BR
-- backup (wiki/source/0_Principal/Hot_Cuisine_Quest~*.wikitext) line by line.
local T = dofile("tools/family/npc_talk/npc_talk.lua")
dofile("data-otservbr-global/lib/others/family_hot_cuisine.lua")
local H = FamilyHotCuisine
local S = Storage.Quest.U8_5.HotCuisineQuest
local check = T.check
local enFile, brFile = arg[1], arg[2]

local npc = T.load("data-otservbr-global/npc/jean_pierre.lua")

-- plural names from items.xml, as the server has them (npc_talk only adds an "s")
do
	local plural = {}
	local f = io.open("data/items/items.xml")
	for line in f:lines() do
		local id, pl = line:match('<item id="(%d+)"[^>]-plural="([^"]*)"')
		if id then
			plural[tonumber(id)] = pl
		end
	end
	f:close()
	local baseItemType = ItemType
	ItemType = function(id)
		local it = baseItemType(id)
		return setmetatable({}, { __index = function(_, k)
			if k == "getPluralName" then
				return function() return plural[id] or "" end
			end
			return it[k]
		end })
	end
end

local function norm(s)
	s = s:gsub("%[%[[^%]|]-|([^%]]-)%]%]", "%1"):gsub("%[%[([^%]]-)%]%]", "%1")
	s = s:lower():gsub("<br%s*/?>", " "):gsub("[{}'\"]", ""):gsub("tester", "player"):gsub("jogador", "player")
	s = s:gsub("voilr", "voilà"):gsub("voila,", "voilà,"):gsub("%s+", " ")
	return (s:gsub("^ ", ""):gsub(" $", ""))
end

-- a player whose items know fluids (vial id + fluid) and who can earn achievements
local function player(o)
	local p = T.player(o)
	p.achievements = {}
	local function key(id, sub)
		if sub and sub ~= -1 then
			return id * 1000 + sub
		end
		return id
	end
	p.getItemCount = function(self, id, sub) return self.items[key(id, sub)] or 0 end
	p.removeItem = function(self, id, count, sub)
		local k = key(id, sub)
		if (self.items[k] or 0) < count then
			return false
		end
		self.items[k] = self.items[k] - count
		self.removed[#self.removed + 1] = { id, count, sub }
		return true
	end
	p.hasAchievement = function(self, name) return self.achievements[name] == true end
	p.addAchievement = function(self, name) self.achievements[name] = true end
	return p
end

local function give(p, index, times)
	for _, ing in ipairs(H.dishes[index].ingredients) do
		local k = ing[3] and ing[1] * 1000 + ing[3] or ing[1]
		p.items[k] = (p.items[k] or 0) + ing[2] * (times or 1)
	end
end

local function cook(p, index, word)
	give(p, index)
	npc:say(p, "hi")
	local q = npc:say(p, word or H.dishes[index].words[1])
	local a = npc:say(p, "yes")
	npc:bye(p)
	return q, a
end

local function st(p, k) return p:getStorageValue(S[k]) end

-- ---------------------------------------------------------------- becoming an apprentice
do
	local young = player({ level = 20 })
	npc:say(young, "hi")
	npc:say(young, "cook")
	local a = npc:say(young, "apprentice")
	check("level 34 or less: still a little young (EN)", a:find("still a little young", 1, true), a)
	check("level 34 or less: not an apprentice", st(young, "QuestStart") == -1)
	npc:bye(young)
end

local p = player({ level = 100 })
local greet = npc:say(p, "hi")
check("greeting of a stranger (EN)", greet:find("What are you doing out here?", 1, true), greet)
local a = npc:say(p, "cook")
check("cook -> recipes", a:find("{recipes}", 1, true), a)
a = npc:say(p, "recipes")
check("'recipes' is understood (upstream wanted 'recipe')", a:find("{apprentice}", 1, true), a)
npc:say(p, "apprentice")
a = npc:say(p, "yes")
check("apprentice accepted", st(p, "QuestStart") == 1 and st(p, "CurrentDish") == 1 and st(p, "QuestLog") == 1, a)
npc:bye(p)

-- ---------------------------------------------------------------- course rules
do
	npc:say(p, "hi")
	local q = npc:say(p, "sweet mangonaise elixir")
	check("a dish not taught yet is refused (upstream skipped the course)", q:find("haven't taught you", 1, true), q)
	local m = npc:say(p, "menu")
	check("menu before the course ends sends to the recipes", m:find("{recipe}", 1, true), m)
	local r = npc:say(p, "recipe")
	check("recipe -> Rotworm Stew intro", r:find("Rotworm Stew", 1, true) and r:find("five ounces of flour", 1, true), r)
	npc:say(p, "rotworm stew")
	local miss = npc:say(p, "yes")
	check("missing ingredients are listed", miss:find("still missing", 1, true) and miss:find("2 vials of beer", 1, true) and miss:find("20 potatoes", 1, true), miss)
	check("nothing taken when something is missing", #p.removed == 0)
	-- wrong fluid: wine instead of beer
	give(p, 1)
	p.items[2874 * 1000 + 3] = 0
	p.items[2874 * 1000 + 2] = 2
	npc:say(p, "rotworm stew")
	miss = npc:say(p, "yes")
	check("vials of wine are not beer", miss:find("2 vials of beer", 1, true) and #p.removed == 0, miss)
	p.items[2874 * 1000 + 3] = 2
	npc:say(p, "rotworm stew")
	local done = npc:say(p, "no")
	check("no -> come back", done:find("come back when you are ready", 1, true), done)
	npc:say(p, "rotworm stew")
	done = npc:say(p, "yes")
	check("Rotworm Stew cooked", (p.items[9079] or 0) == 1 and done:find("Maryza", 1, true), done)
	check("course moves to dish 2", st(p, "CurrentDish") == 2 and st(p, "QuestLog") == 2)
	npc:bye(p)
end

-- dishes 2-10
local quests = { [10] = 11 }
for index = 2, 10 do
	npc:say(p, "hi")
	local intro = npc:say(p, "recipe")
	check(("recipe -> %s intro"):format(H.dishes[index].name), intro:find(H.dishes[index].name:sub(1, 8), 1, true), intro:sub(1, 80))
	npc:bye(p)
	local _, done = cook(p, index)
	check(("%s cooked"):format(H.dishes[index].name), (p.items[H.dishes[index].reward] or 0) >= 1, done:sub(1, 60))
	check(("quest log %d after dish %d"):format(index + 1, index), st(p, "QuestLog") == index + 1)
	if index == 10 then
		check("carrot cake, not a solstice tree (upstream gave id 10000)", (p.items[9087] or 0) == 1 and (p.items[10000] or 0) == 0)
		check("course end: cookbook upstairs and the menu", done:find("cookbook upstairs", 1, true) and done:find("{menu}", 1, true), done)
		check("Cookbook I door opens after dish 10", st(p, "CookbookDoor") == 1)
		check("Cookbook II door still closed after dish 10", st(p, "CookbookDoor2") == -1)
	end
end

-- recook at once, several times: no year limit, the course does not move back
do
	local before = p.items[9081] or 0
	for _ = 1, 3 do
		cook(p, 3, "roasted dragon wings")
	end
	check("Roasted Dragon Wings cooked 3 more times at once", (p.items[9081] or 0) == before + 3)
	check("recooking leaves the course where it is (upstream moved it back)", st(p, "CurrentDish") == 11 and st(p, "QuestLog") == 11)
	local _, again = cook(p, 10)
	check("recooked Carrot Cake: no course-end talk", not again:find("cookbook upstairs", 1, true), again:sub(-80))
end

-- menu 11-15
npc:say(p, "hi")
a = npc:say(p, "recipe")
check("after the course, recipe -> special treat and menu (BR, no yearly limit)", a:find("{menu}", 1, true) and a:find("whenever you like", 1, true) and not a:find("this year", 1, true), a)
a = npc:say(p, "menu")
check("menu -> Coconut Shrimp Bake intro", a:find("Coconut Shrimp Bake", 1, true), a:sub(1, 80))
check("quest log 12 once the menu is heard (upstream never set it)", st(p, "QuestLog") == 12)
npc:bye(p)
for index = 11, 15 do
	if index > 11 then
		npc:say(p, "hi")
		local intro = npc:say(p, "menu")
		check(("menu -> %s intro"):format(H.dishes[index].name), intro:find(H.dishes[index].name, 1, true), intro:sub(1, 80))
		npc:bye(p)
	end
	local word = index == 13 and "demonic candy balls" or nil
	local _, done = cook(p, index, word)
	check(("%s cooked"):format(H.dishes[index].name), (p.items[H.dishes[index].reward] or 0) >= 1, done:sub(1, 60))
	check(("quest log %d after dish %d"):format(index + 2, index), st(p, "QuestLog") == index + 2)
	if index == 13 then
		check("'demonic candy balls' understood and 5 balls given (BR)", (p.items[11587] or 0) == 5)
	elseif index == 14 then
		check("elixir: cookbook from upstairs (EN)", done:find("take the cookbook containing them from upstairs", 1, true), done:sub(-90))
		check("Cookbook II door opens after the elixir", st(p, "CookbookDoor2") == 1 and st(p, "QuestStart") == 2)
	elseif index == 15 then
		check("Zaoan Sauce: the taiyaki and young lich worm were taken", (p.items[48115] or 0) == 0 and (p.items[31590] or 0) == 0)
		check("all dishes learned", H.nextDish(p) == 16)
	end
end
npc:say(p, "hi")
a = npc:say(p, "menu")
check("menu after all: list of the 15 dishes", a:find("{Zaoan Sauce}", 1, true) and a:find("{Filled Jalapeno Peppers}", 1, true), a)
a = npc:say(p, "recipe")
check("recipe after all: any dish whenever you like", a:find("whenever you like", 1, true), a)
npc:bye(p)

-- every listed dish name works (the client sends the exact word)
for index, dish in ipairs(H.dishes) do
	npc:say(p, "hi")
	local q = npc:say(p, dish.listName or dish.name)
	check(("{%s} asks for the ingredients"):format(dish.listName or dish.name), q == dish.question, q)
	npc:bye(p)
end

-- Culinary Master: each of the 14 dishes twice
check("no Culinary Master yet", not p.achievements[H.achievement])
for index = 1, 14 do
	if H.cookedCount(p, index) < 2 then
		cook(p, index)
	end
	if index < 14 then
		check(("not yet after dish %d"):format(index), not p.achievements[H.achievement])
	end
end
check("Culinary Master after every dish twice (EN)", p.achievements[H.achievement])

-- ---------------------------------------------------------------- older characters
do
	local old = player({ level = 100, storage = { [S.QuestStart] = 2, [S.CurrentDish] = 15, [S.QuestLog] = 16, [S.CookbookDoor] = 1 } })
	local g = npc:say(old, "hi")
	check("old character: menu greeting (BR)", g:find("achoo", 1, true), g)
	check("old character after the elixir gets the Cookbook II door", st(old, "CookbookDoor2") == 1)
	a = npc:say(old, "menu")
	check("old character: menu -> Zaoan Sauce", a:find("Zaoan Sauce", 1, true), a:sub(1, 80))
	local q = npc:say(old, "rotworm stew")
	check("old character: recooks a learned dish", q == H.dishes[1].question, q)
	check("old character: learned dishes count once for Culinary Master", H.cookedCount(old, 14) == 1 and H.cookedCount(old, 15) == 0)
	npc:bye(old)
	local mid = player({ level = 100, storage = { [S.QuestStart] = 1, [S.CurrentDish] = 4, [S.QuestLog] = 4 } })
	npc:say(mid, "hi")
	a = npc:say(mid, "recipe")
	check("character in the course: next dish (Tropical Fried Terrorbird)", a:find("Tropical Fried Terrorbird", 1, true), a:sub(1, 80))
	npc:bye(mid)
end

-- ---------------------------------------------------------------- the yearly rule (switch off)
do
	Family.hotCuisineAnytime = false
	local realDate = os.date
	os.date = function(fmt, t)
		if fmt == "%m" then return "08" end
		if fmt == "%Y" then return "2026" end
		return realDate(fmt, t)
	end
	local y = player({ level = 100, storage = { [S.QuestStart] = 1, [S.CurrentDish] = 3, [S.QuestLog] = 3 } })
	local _, first = cook(y, 1)
	check("switch off: a learned dish once in August", (y.items[9079] or 0) == 1, first:sub(1, 40))
	local q = cook(y, 1)
	check("switch off: not twice the same year", q:find("next year in August", 1, true), q)
	os.date = function(fmt, t)
		if fmt == "%m" then return "11" end
		return realDate(fmt, t)
	end
	local g = npc:say(y, "hi")
	check("switch off: no talk outside August", not g:find("Hello there again", 1, true), g)
	npc:bye(y)
	os.date = realDate
	Family.hotCuisineAnytime = true
end

-- ---------------------------------------------------------------- {words}
npc.path = "data-otservbr-global/lib/others/family_hot_cuisine.lua"
T.checkHints(npc, function()
	local q = player({ level = 100, storage = { [S.QuestStart] = 2, [S.CurrentDish] = 16, [S.QuestLog] = 17 } })
	return q
end)

-- ---------------------------------------------------------------- wiki transcripts
local KNOWN = {
	-- the yearly limit is gone
	["i have a special treat for you this year"] = "BR: no 'this year' (yearly limit removed)",
	["we can also recook my own recipes, unless"] = "BR: 'whenever you like' (yearly limit removed)",
	["you can drop by and practice cooking those dishes, at least"] = "EN/BR: 'whenever you like' (yearly limit removed)",
	-- BR typos fixed in the NPC
	["well, if you area really that eager"] = "BR typo 'area'",
	["pleasing to the pallatel"] = "BR typo 'pallatel'",
	["but it tasted to great that"] = "BR typo 'to great' (EN: so great)",
	["one flask of demonic blood"] = "BR; EN and upstream: 'one concentrated demonic blood'",
}
local function known(line)
	for k, why in pairs(KNOWN) do
		if norm(line):find(norm(k), 1, true) then
			return why
		end
	end
end

local function replay(label, blocks)
	local q = player({ level = 100 })
	local tested, differ = 0, 0
	for _, block in ipairs(blocks) do
		local talker = q
		for _, l in ipairs(block) do
			if l.npc and l.text:find("still a little young", 1, true) then
				talker = player({ level = 20 })
			end
		end
		for index = 1, #H.dishes do
			give(talker, index)
		end
		-- blocks that start with his words: the greeting (BR dish 11) or a menu intro (EN dish 13)
		if block[1] and block[1].npc then
			local lower = block[1].text:lower()
			local word = (lower:find("hello there again", 1, true) or lower:find("greetings", 1, true)) and "hi" or "menu"
			table.insert(block, 1, { player = true, text = word })
		end
		-- blocks that start with "menu" or "apprentice": greet first
		local firstWord
		for _, l in ipairs(block) do
			if l.player then
				firstWord = l.text:lower()
				break
			end
		end
		if firstWord and not firstWord:match("^hi") and not firstWord:match("^hello") then
			npc:say(talker, "hi")
		end
		local answers = {}
		local current
		for _, l in ipairs(block) do
			if l.player then
				current = npc:say(talker, l.text)
				answers[#answers + 1] = current
			elseif l.npc then
				tested = tested + 1
				local all = norm(table.concat(answers, " | "))
				local want = norm(l.text)
				local ok = all:find(want, 1, true) ~= nil
				local why = not ok and known(l.text)
				if why then
					differ = differ + 1
					print("     kept different (" .. why .. "): " .. l.text:sub(1, 70))
				else
					check(label .. ": " .. l.text:sub(1, 60), ok, not ok and ("got: " .. all:sub(1, 160)) or nil)
				end
			end
		end
		npc:bye(talker)
	end
	check(label .. " transcripts read", tested > 50, tested .. " NPC lines, " .. differ .. " kept different")
end

if enFile then
	local f = assert(io.open(enFile))
	local src = f:read("*a")
	f:close()
	local blocks = {}
	for body in src:gmatch("{{Infobox Transcript|(.-)}}") do
		local b = {}
		for line in (body .. "\n"):gmatch("([^\n]*)\n") do
			local word = line:match("^''Player'': '''(.-)'''")
			local said = line:match("^Jean Pierre: (.*)$")
			if word then
				b[#b + 1] = { player = true, text = word }
			elseif said then
				b[#b + 1] = { npc = true, text = said }
			end
		end
		blocks[#blocks + 1] = b
	end
	replay("EN", blocks)
end

if brFile then
	local f = assert(io.open(brFile))
	local src = f:read("*a")
	f:close()
	local blocks = {}
	for body in src:gmatch("{{transcrições|npc=Jean Pierre|texto=(.-)}}") do
		local b, last = {}, nil
		for line in (body .. "\n"):gmatch("([^\n]*)\n") do
			local word = line:match("^''Jogador:'' (.-)<br>") or line:match("^''Jogador:'' (.*)$")
			if word then
				word = word:gsub("'''", "")
			end
			local said = line:match("^'''Jean Pierre:'''%s*(.*)$")
			if word then
				last = { player = true, text = word }
				b[#b + 1] = last
			elseif said then
				last = { npc = true, text = said }
				b[#b + 1] = last
			elseif last and last.npc and line:match("%S") then
				last.text = last.text .. " " .. line
			end
		end
		blocks[#blocks + 1] = b
	end
	replay("BR", blocks)
end

T.finish()
