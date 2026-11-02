-- The Ape City Quest: every wiki conversation, line by line (2026-11-02).
-- Run from the repository root:
--   luajit tools/family/npc_talk/ape_city.lua <EN spoiler wikitext> <BR page text> [EN Hairycles transcript]
-- EN spoiler wikitext: api.php?action=parse&page=The_Ape_City_Quest/Spoiler&prop=wikitext
-- BR page text: the TibiaWiki BR page saved as HTML and stripped to text
-- (one "Jogador: ..." / "Hairycles: ..." per line). Each transcript block is
-- replayed in order with one character; before a block the character gets
-- what the mission needs (item, storage). Every NPC line of the wiki must be
-- in the NPC's answer (compared without spaces, case and {braces}).
local T = dofile("tools/family/npc_talk/npc_talk.lua")
local check = T.check
local AC = Storage.Quest.U7_6.TheApeCity
local NPC = "data-otservbr-global/npc/"
Position = Position or function(x, y, z)
	return { x = x, y = y, z = z, sendMagicEffect = function() end }
end

local function norm(s)
	return (s:lower():gsub("[{}]", ""):gsub("%s+", ""))
end

local function readFile(path)
	local f = path and io.open(path)
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

local function cleanWiki(s)
	s = s:gsub("<br%s*/?>", ""):gsub("%[%[[^%]|]*|([^%]]*)%]%]", "%1"):gsub("%[%[([^%]]*)%]%]", "%1")
	s = s:gsub("'''", ""):gsub("''", ""):gsub("&lt;", "<"):gsub("&gt;", ">")
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- EN: {{Infobox Transcript| ... }} blocks; returns { {speaker=, text=}, ... } per block
local function parseEN(text)
	local blocks = {}
	for body in text:gmatch("{{Infobox[ _]Transcript|(.-)}}") do
		local block = {}
		for line in body:gmatch("[^\n]+") do
			local said = line:match("^''Player:?'':?%s*'''(.-)'''") or line:match("^Player:%s*(.-)<br")
			if said then
				block[#block + 1] = { speaker = "Player", text = cleanWiki(said) }
			else
				local who, what = line:match("^%[?%[?([%a ]-)%]?%]?:%s*(.+)$")
				if who and who ~= "" and not line:match("^''") then
					block[#block + 1] = { speaker = who, text = cleanWiki(what) }
				end
			end
		end
		if #block > 0 then
			blocks[#blocks + 1] = block
		end
	end
	return blocks
end

-- BR: plain text, a block starts at "Jogador: Hi"
local SPEAKERS = { Hairycles = true, Brewster = true, Ustan = true, Padreia = true, Dermot = true, ["The Blind Prophet"] = true }
local function parseBR(text)
	local blocks, block = {}, nil
	for line in text:gmatch("[^\n]+") do
		line = line:gsub("^%s+", ""):gsub("%s+$", "")
		local said = line:match("^Jogador:%s*(.+)$")
		if said then
			if said:lower() == "hi" or not block then
				block = {}
				blocks[#blocks + 1] = block
			end
			block[#block + 1] = { speaker = "Player", text = said }
		elseif block then
			local who, what = line:match("^([%a ]+):%s*(.+)$")
			if who and SPEAKERS[who] then
				block[#block + 1] = { speaker = who, text = (what:gsub("Jogador", "Tester")) }
			else
				block = nil
			end
		end
	end
	return blocks
end

local npcs = {}
local function npcFor(name)
	local file = name:lower():gsub(" ", "_") .. ".lua"
	if not npcs[file] then
		npcs[file] = T.load(NPC .. file)
	end
	return npcs[file]
end

-- what the character carries before each Hairycles block, by quest state
local function prepare(p)
	local q = p.storage[AC.Questline] or -1
	if q == 1 then
		p.storage[Storage.Quest.U7_6.WhisperMoss] = 1
		p.items[4827] = 1
	elseif q == 3 then
		p.items[4828] = 1
	elseif q == 5 then
		p.items[4831] = 1
	elseif q == 7 then
		p.storage[AC.ParchmentDecyphering] = 1
	elseif q == 9 then
		p.items[4839] = 1
	elseif q == 11 then
		p.items[4829] = 1
	elseif q == 13 then
		p.storage[AC.Casks] = 3
	elseif q == 15 then
		p.storage[AC.HolyApeHair] = 1
		p.items[4832] = 1
	elseif q == 17 then
		p.storage[AC.SnakeDestroyer] = 1
	end
end

local function replay(label, blocks)
	local p = T.player({ money = 1000, bank = 5000 })
	p.achievements, p.outfits = {}, {}
	p.addAchievement = function(self, name) self.achievements[name] = true end
	p.addOutfit = function(self, id) self.outfits[id] = true end
	local lines = 0
	for b, block in ipairs(blocks) do
		local name
		for _, l in ipairs(block) do
			if l.speaker ~= "Player" then
				name = l.speaker
				break
			end
		end
		if name then
			local talk = npcFor(name)
			if name == "Hairycles" then
				prepare(p)
			elseif name == "The Blind Prophet" then
				p.storage[AC.Questline] = math.max(p.storage[AC.Questline] or -1, 15)
			end
			local answer = ""
			local first = block[1]
			if first.speaker == "Player" and first.text:lower() ~= "hi" and not talk.npc:isInteractingWithPlayer(p) then
				talk:say(p, "hi")
			end
			for _, l in ipairs(block) do
				if l.speaker == "Player" then
					answer = talk:say(p, l.text)
				else
					lines = lines + 1
					check(label .. " block " .. b .. " " .. name .. ": " .. l.text:sub(1, 60), norm(answer):find(norm(l.text), 1, true) ~= nil, "got: " .. answer:sub(1, 160))
				end
			end
			talk:bye(p)
		end
	end
	check(label .. ": " .. lines .. " NPC lines replayed", lines > 30)
	check(label .. ": quest finished", p.storage[AC.Questline] == 18, p.storage[AC.Questline])
	check(label .. ": shaman outfits", p.outfits[154] and p.outfits[158])
	check(label .. ": achievement Friend of the Apes", p.achievements["Friend of the Apes"])
	check(label .. ": snake destroyer given", p.items[4835] == 1)
	return p
end

local en, br, enNpc = readFile(arg[1]), readFile(arg[2]), readFile(arg[3])
if en then
	replay("EN", parseEN(en))
else
	print("(no EN spoiler wikitext given)")
end
if br then
	replay("BR", parseBR(br))
else
	print("(no BR page text given)")
end

-- EN Hairycles transcript (small talk), as a character before mission 6 and after it
if enNpc then
	local talk = npcFor("Hairycles")
	for _, block in ipairs(parseEN(enNpc)) do
		local p = T.player({})
		local answer = ""
		for _, l in ipairs(block) do
			if l.speaker == "Player" then
				local words = l.text
				for word in words:gmatch("[^/]+") do
					answer = talk:say(p, word)
				end
			else
				check("EN transcript Hairycles: " .. l.text:sub(1, 60), norm(answer):find(norm(l.text:gsub("%.$", "")), 1, true) ~= nil, "got: " .. answer:sub(1, 160))
			end
		end
	end
end

-- states the wikis do not show
local hairycles = npcFor("Hairycles")
local function ask(storage, items, ...)
	local p = T.player({ storage = storage, items = items or {} })
	hairycles:say(p, "hi")
	local out
	for _, text in ipairs({ ... }) do
		out = hairycles:say(p, text)
	end
	return out, p
end
check("M1 without moss: told to hurry", ask({ [AC.Questline] = 1 }, nil, "mission"):find("hurry", 1, true))
local a, p = ask({ [AC.Questline] = 1, [Storage.Quest.U7_6.WhisperMoss] = 1 }, nil, "mission", "yes")
check("M1 moss lost: not accepted", p.storage[AC.Questline] == 1, a)
a, p = ask({ [AC.Questline] = 3 }, nil, "mission", "yes")
check("M2 without syrup: not accepted", p.storage[AC.Questline] == 3, a)
a, p = ask({ [AC.Questline] = 13, [AC.Casks] = 2 }, nil, "mission")
check("M7 two casks: not done", p.storage[AC.Questline] == 13, a)
a, p = ask({ [AC.Questline] = 17 }, nil, "mission")
check("M9 statue not broken: not done", p.storage[AC.Questline] == 17, a)
a, p = ask({ [AC.Questline] = 11 }, nil, "trade")
check("trade before mission 6 finished: his EN line", a:find("Me nothing have to offer you now", 1, true), a)
a, p = ask({ [AC.Questline] = 12 }, nil, "trade")
check("trade after mission 6: shop opens", rawget(p, "shopOpened"), a)
a, p = ask({ [AC.Questline] = 12, [AC.Started] = 1 }, nil, "shamanic powers")
check("outfit before the end: refused", a:find("not have finished", 1, true), a)
local shopItems = hairycles.type.config.shop
for _, s in ipairs(shopItems) do
	if s.itemName:find("monkey statue", 1, true) then
		check("statue kit " .. s.itemName .. " only after mission 9", s.storageKey == AC.Questline and s.storageValue == 18)
	end
end
T.checkHints(hairycles, function() return T.player({ storage = { [AC.Questline] = 18 } }) end, { mission = true, missions = true, trade = true, background = true })

T.finish()
