-- The Ice Islands Quest: the whole quest, talk and items (2026-11-16).
-- Run from the repository root:  luajit tools/family/npc_talk/ice_islands.lua [EN transcripts folder]
-- One character plays the Barbarian Test talk and The Ice Islands Quest from Iskan to
-- the Norseman addons with Sven, Iskan, A Starving Dog, Hjaern, Siflind, Nilsor, Lurik,
-- Nor and A Restless Soul, and the real item scripts (termite jug, paint, frost charm,
-- the gathering of Nilsor's ingredients, the hoist rules). World steps that need the
-- map (cracks, Helheim altar, Tylaf's skeleton) are set as storages. Checks the
-- TibiaWiki EN/BR lines, the states the wikis do not show, and the bugs of the review.
-- With the optional folder (Sven_Transcripts.txt, Hjaern_..., Siflind_..., Nilsor_...,
-- Iskan_...; raw EN wikitext), every lore line of those transcripts is replayed.
local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z)
	return { x = x, y = y, z = z, sendMagicEffect = function() end }
end
TALKTYPE_MONSTER_SAY = TALKTYPE_MONSTER_SAY or 36
Tile = function() return { getItemById = function() return nil end } end
CONST_ME_MAGIC_GREEN, CONST_ME_GREEN_RINGS, CONST_ME_HITAREA, CONST_ME_GROUNDSHAKER = 15, 16, 17, 18
CONST_ME_FIREWORK_BLUE, CONST_ME_SLEEP, CONST_ME_STUN = 19, 20, 21
dofile("data-otservbr-global/lib/others/family_ice_islands.lua")
dofile("data-otservbr-global/lib/others/family_explorer_society.lua")
local S = Storage.Quest.U8_0.TheIceIslands
local B = Storage.Quest.U8_0.BarbarianTest
local F = FamilyIceIslands
local check = T.check
local NPC = "data-otservbr-global/npc/"
local transcripts = arg[1]

local function norm(s)
	return (s:lower():gsub("[{}]", ""):gsub("%s+", " "))
end
local function has(text, pattern)
	return norm(text):find(norm(pattern), 1, true) ~= nil
end

local function player(o)
	local p = T.player(o)
	p.achievements, p.outfits, p.said = {}, {}, {}
	p.addAchievement = function(self, name) self.achievements[name] = true end
	p.hasAchievement = function(self, name) return self.achievements[name] == true end
	p.addOutfit = function(self, id) self.outfits[id] = self.outfits[id] or 0 end
	p.addOutfitAddon = function(self, id, addon)
		self.outfits[id] = (self.outfits[id] or 0)
		if self.outfits[id] % (addon * 2) < addon then
			self.outfits[id] = self.outfits[id] + addon
		end
	end
	p.hasOutfit = function(self, id, addons)
		local have = self.outfits[id]
		return have ~= nil and (addons == nil or addons == 0 or have == 3 or have == addons)
	end
	p.say = function(self, text) self.said[#self.said + 1] = text end
	return p
end

-- item scripts, used like the server does
local actions = {}
Action = function()
	local a = { ids = {}, uids = {} }
	function a:id(...) for _, v in ipairs({ ... }) do self.ids[#self.ids + 1] = v end end
	function a:uid(...) for _, v in ipairs({ ... }) do self.uids[#self.uids + 1] = v end end
	function a:aid() end
	function a:position() end
	function a:register() actions[#actions + 1] = self end
	return a
end
local moves = {}
MoveEvent = function()
	local m = { uids = {} }
	function m:type() end
	function m:uid(...) for _, v in ipairs({ ... }) do self.uids[#self.uids + 1] = v end end
	function m:position() end
	function m:register() moves[#moves + 1] = self end
	return m
end
local function pos(x, y, z)
	return Position(x or 0, y or 0, z or 7)
end
local function useItem(p, itemId, target, toPosition)
	for _, a in ipairs(actions) do
		for _, id in ipairs(a.ids) do
			if id == itemId then
				local item = { itemid = itemId, uid = 0 }
				function item:transform(id2) p.items[itemId] = (p.items[itemId] or 1) - 1; p.items[id2] = (p.items[id2] or 0) + 1; self.itemid = id2 end
				function item:remove() p.items[self.itemid] = (p.items[self.itemid] or 1) - 1 end
				function item:getId() return self.itemid end
				target = target or {}
				target.transform = target.transform or function(t, id2) t.itemid = id2 end
				return a.onUse(p, item, pos(), target, toPosition or pos(), false)
			end
		end
	end
	error("no action for item " .. itemId)
end
dofile("data-otservbr-global/scripts/quests/the_ice_islands_quest/actions_anthill.lua")
dofile("data-otservbr-global/scripts/quests/the_ice_islands_quest/actions_paint.lua")
dofile("data-otservbr-global/scripts/quests/the_ice_islands_quest/actions_charm.lua")
dofile("data-otservbr-global/scripts/quests/formogar_mine_hoist/movements_hoist.lua")

local sven = T.load(NPC .. "sven.lua")
local iskan = T.load(NPC .. "iskan.lua")
local dog = T.load(NPC .. "a_starving_dog.lua")
local hjaern = T.load(NPC .. "hjaern.lua")
local siflind = T.load(NPC .. "siflind.lua")
local nilsor = T.load(NPC .. "nilsor.lua")
local lurik = T.load(NPC .. "lurik.lua")
local buddel = T.load(NPC .. "buddel.lua")
local dankwart = T.load(NPC .. "dankwart.lua")
local nor = T.load(NPC .. "nor.lua")
local soul = T.load(NPC .. "a_restless_soul.lua")
local duncan = T.load(NPC .. "duncan.lua")

local p = player({ name = "Rodrigo", level = 130, money = 100000 })
local function q()
	return p:getStorageValue(S.Questline)
end
local a

-- ------------------------------------------------------------------ Barbarian Test (talk)
a = sven:say(p, "hi")
check("Sven: greeting (EN/BR)", has(a, "Be greeted, Rodrigo! What brings you here?"), a)
a = sven:say(p, "barbarians")
check("Sven: 'barbarians' (EN word)", has(a, "A true barbarian is something special among our people."), a)
a = sven:say(p, "test")
check("Sven: test (EN/BR)", has(a, "All of our juveniles have to take the barbarian test") and has(a, "Are you willing to take the barbarian test?"), a)
a = sven:say(p, "yes")
check("Sven: test yes (EN/BR)", has(a, "That's the spirit!") and has(a, "Do you think you can do this?"), a)
a = sven:say(p, "yes")
check("Sven: test yes 2 starts both quests", has(a, "Therefore, you have to get your own honey.") and p:getStorageValue(B.Questline) == 1 and q() == 1, a)
p.items[5902] = 1
a = sven:say(p, "barbarian mead")
check("Sven: 'barbarian mead' asks for honey, not the barbarian line", has(a, "Do you have some honey with you?"), a)
a = sven:say(p, "yes")
check("Sven: honeycomb taken, 20 sips (EN/BR)", has(a, "Good, for this honeycomb I allow you 20 sips") and p.items[5902] == 0 and p:getStorageValue(B.Questline) == 2, a)
p:setStorageValue(B.Questline, 3) -- 10 sips in a row (bucket script)
a = sven:say(p, "mead")
check("Sven: mead horn (EN/BR)", has(a, "An impressive start. Here, take your own mead horn") and p.items[7140] == 1 and p:getStorageValue(B.Questline) == 4, a)
p:setStorageValue(B.Questline, 5) -- bear hugged
a = sven:say(p, "bear hugging")
check("Sven: 'bear hugging' (his own words) reports the bear", has(a, "Amazing. That was as clever and brave") and p:getStorageValue(B.Questline) == 6, a)
p:setStorageValue(B.Questline, 7) -- mammoth pushed
a = sven:say(p, "mammoth")
check("Sven: mammoth (EN/BR) and Honorary Barbarian", has(a, "As you have passed all three tests") and p:getStorageValue(B.Questline) == 8 and p.achievements["Honorary Barbarian"], a)
a = sven:say(p, "test")
check("Sven: test afterwards (EN)", has(a, "You have braved all three tests and are now an honorary barbarian."), a)
a = sven:say(p, "here")
check("Sven: {here} answers (EN)", has(a, "I am the jarl of my people."), a)
a = sven:say(p, "barbarian")
check("Sven: barbarian afterwards (EN)", has(a, "A true barbarian is something special"), a)
a = sven:bye(p)
check("Sven: farewell (EN)", has(a, "May wind and weather be with you, Rodrigo."), a)

-- ------------------------------------------------------------------ Befriending the Musher
a = iskan:say(p, "hi")
check("Iskan: greeting (EN)", has(a, "Greetings. What can I do for you?"), a)
a = iskan:say(p, "mission")
check("Iskan: mission (EN/BR)", has(a, "Well, one of the boys has run away.") and has(a, "Are you willing to do that?"), a)
a = iskan:say(p, "yes")
check("Iskan: accept (EN/BR)", has(a, "That's surprising. Take a piece of meat.") and p:getStorageValue(S.Mission01) == 1, a)
a = iskan:say(p, "mission")
check("Iskan: reminder while searching (ours)", has(a, "Did you find the boy?") and p:getStorageValue(S.Mission01) == 1, a)
iskan:bye(p)
p.items[3577] = 1
a = dog:say(p, "sniffler")
check("Dog: sniffler (EN/BR)", has(a, "<sniff>"), a)
a = dog:say(p, "meat")
check("Dog: meat (EN/BR)", has(a, "<munch>") and q() == 2 and p:getStorageValue(S.Mission01) == 2, a)
iskan:say(p, "hi")
a = iskan:say(p, "mission")
check("Iskan: report (EN/BR)", has(a, "You are a friend of mine and the boys now.") and q() == 3 and p:getStorageValue(S.Mission01) == 3, a)
a = iskan:say(p, "passage")
check("Iskan: passage", has(a, "do you want a passage to Nibelor"), a)
iskan:bye(p)

-- ------------------------------------------------------------------ Nibelor 1: Breaking the Ice
a = hjaern:say(p, "hi")
check("Hjaern: greeting (EN)", has(a, "Be greeted, Rodrigo. The spiritual world looks upon you and your deeds."), a)
a = hjaern:say(p, "mission")
check("Hjaern: mission 1 (EN/BR)", has(a, "We could indeed need some help.") and has(a, "Use the pickaxe on at least three of these places") and p:getStorageValue(S.Mission02) == 1, a)
a = hjaern:say(p, "mission")
check("Hjaern: reminder while breaking the ice (ours; upstream silent)", has(a, "Use a pick on at least three"), a)
p:setStorageValue(S.Questline, 4) -- three cracks (pick script)
p:setStorageValue(S.Mission02, 4)
a = hjaern:say(p, "mission")
check("Hjaern: report (EN/BR)", has(a, "The spirits are at peace now.") and q() == 5 and p:getStorageValue(S.Mission02) == 5, a)
a = hjaern:say(p, "spiritual")
check("Hjaern: {spiritual} answers (EN)", has(a, "I would not consider this as a job."), a)
a = hjaern:bye(p)
check("Hjaern: farewell (EN)", has(a, "Good bye, Rodrigo."), a)

-- ------------------------------------------------------------------ Nibelor 2: Ecological Terrorism
a = siflind:say(p, "hi")
check("Siflind: greeting (EN)", has(a, "If you are in need of potions or magical equipment, just ask me about my offers."), a)
a = siflind:say(p, "mission")
check("Siflind: mission 2 (EN/BR)", has(a, "I heard you have already helped our cause."), a)
a = siflind:say(p, "yes")
check("Siflind: jug given (EN/BR)", has(a, "Take this jug here and travel to the jungle of Tiquanda.") and p.items[7243] == 1 and q() == 6, a)
a = siflind:say(p, "mission")
check("Siflind: reminder with the jug (ours; upstream 'no mission')", has(a, "Use the jug on one of the termite hills"), a)
local antHill = { itemid = 1079 }
useItem(p, 7243, antHill)
check("Jug: filled at the ant-hill", p.items[7244] == 1 and p.items[7243] == 0 and p:getStorageValue(S.Mission03) == 2)
useItem(p, 7244, { itemid = 4940 }, pos(32360, 31365, 7))
check("Jug: termites released, the full jug is gone (upstream kept it)", q() == 7 and (p.items[7244] or 0) == 0 and p:getStorageValue(S.Mission03) == 3)

-- ------------------------------------------------------------------ Nibelor 3: Artful Sabotage
a = siflind:say(p, "mission")
check("Siflind: mission 3 (EN/BR)", has(a, "Well done. The termites caused just the distraction that we needed."), a)
siflind:say(p, "yes")
a = siflind:say(p, "yes")
check("Siflind: vial of paint (EN/BR)", has(a, "Take this vial of paint.") and p.items[7253] == 1 and q() == 8, a)
p.items[7253] = 0
a = siflind:say(p, "mission")
check("Siflind: a lost vial is replaced (ours)", has(a, "The paint ran dry?") and p.items[7253] == 1, a)
for _ = 1, 3 do
	useItem(p, 7253, { itemid = 7178 })
end
check("Paint: three seals end the mission", q() == 9 and p:getStorageValue(S.Mission04) == 2)
a = siflind:say(p, "mission")
check("Siflind: report (EN/BR)", has(a, "You saved the lives of many innocent animals.") and q() == 10, a)

-- ------------------------------------------------------------------ Nibelor 4: Berserk Brewery
a = siflind:say(p, "mission")
check("Siflind: mission 4 (EN/BR)", has(a, "The first things needed are 5 bat wings.") and q() == 11, a)
local brewery = {
	{ 5894, 5, "Do you have the 5 bat wings I requested?", "Thats just what I needed. The next items I need are 4 bear paws.", 13 },
	{ 5896, 4, "Do you have the 4 bear paws I requested?", "They are in a good condition. The next items I need are 3 bonelord eyes.", 15 },
	{ 5898, 3, "Do you have the 3 bonelord eyes I requested?", "You did a good job. The next items I need are 2 fish fins.", 17 },
	{ 5895, 2, "Do you have the 2 fish fins I requested?", "You did a good job. The last item I need is a green dragon scale.", 19 },
	{ 5920, 1, "Do you have the green dragon scale I requested?", "Thank you very much. This will help us to defend Svargrond. But I heard young Nilsor is in dire need of help.", 20 },
}
for i, step in ipairs(brewery) do
	a = siflind:say(p, "mission")
	check("Siflind: brewery ask " .. i .. " (EN/BR)", has(a, step[3]), a)
	a = siflind:say(p, "yes")
	check("Siflind: brewery without the items " .. i, has(a, "Come back when you do."), a)
	p.items[step[1]] = step[2]
	siflind:say(p, "mission")
	a = siflind:say(p, "yes")
	check("Siflind: brewery delivery " .. i .. " names the next (EN/BR)", has(a, step[4]) and q() == step[5] and p.items[step[1]] == 0 and p:getStorageValue(S.Mission05) == i + 1, a)
end
a = siflind:bye(p)
check("Siflind: farewell (EN)", has(a, "Good bye and take care, Rodrigo."), a)
-- an old character between two ingredients (upstream state 12) still goes on
do
	local old = player({ storage = { [S.Questline] = 12 } })
	siflind:say(old, "hi")
	a = siflind:say(old, "mission")
	check("Siflind: old state 12 still answers", has(a, "4 bear paws") and old:getStorageValue(S.Questline) == 13, a)
end

-- ------------------------------------------------------------------ Nibelor 5: Cure the Dogs
a = nilsor:say(p, "hi")
check("Nilsor: greeting (EN)", has(a, "Greetings, traveller Rodrigo. Is there anything I can do for you?"), a)
a = nilsor:say(p, "do for you")
check("Nilsor: {do for you} (EN)", has(a, "I see after the dogs."), a)
a = nilsor:say(p, "medicine")
check("Nilsor: 'medicine' starts the mission (EN)", has(a, "I am in dire need of help.") and has(a, "Are you willing to help me?"), a)
a = nilsor:say(p, "yes")
check("Nilsor: accept (EN/BR, no 'first bring the cactus')", has(a, "As soon as I obtained them all, talk to me about the medicine.") and not has(a, "First time") and q() == 21 and p:getStorageValue(S.Mission06) == 1, a)
a = nilsor:say(p, "waterskin")
nilsor:say(p, "yes")
check("Nilsor: waterskin sold for 25", p.items[7286] == 1)
-- any order: the spores first, the cactus last
local order = { 7, 3, 6, 2, 4, 5, 1 }
local askWords = { "part of the sun adorer cactus", "vial of geyser water", "sulphur of a lava hole", "frostbite herb", "blossom of a purple kiss", "hydra tongue", "spores of a giant glimmercap mushroom" }
for n, i in ipairs(order) do
	local ing = F.ingredients[i]
	a = nilsor:say(p, askWords[i])
	local first = type(ing.ask) == "table" and ing.ask[1] or ing.ask
	check("Nilsor: asks about " .. askWords[i] .. " (EN)", has(a, first), a)
	if n == 1 then
		a = nilsor:say(p, "yes")
		check("Nilsor: yes without it", has(a, "Come back when you have the ingredient."), a)
		nilsor:say(p, askWords[i])
	end
	p.items[ing.item] = 1
	a = nilsor:say(p, "yes")
	check("Nilsor: takes " .. askWords[i] .. " in any order (BR)", has(a, "Thank you for this ingredient.") and p.items[ing.item] == 0 and p:getStorageValue(S.Mission06) == 1 + n, a)
	if n == 1 then
		a = nilsor:say(p, askWords[i])
		check("Nilsor: an ingredient already given (ours)", has(a, "You already brought me"), a)
		a = nilsor:say(p, "mission")
		check("Nilsor: mission lists what is missing (ours)", has(a, "I still need a part of the sun adorer cactus") and not has(a, "spores"), a)
	end
end
check("Nilsor: all seven, ready to report", q() == 28 and p:getStorageValue(S.Mission06) == 8)
a = nilsor:say(p, "medicine")
check("Nilsor: report (EN/BR)", has(a, "Thank you. Now I have all necessary ingredients.") and q() == 29 and p:getStorageValue(S.Mission07) == 1, a)
a = nilsor:say(p, "passage")
nilsor:say(p, "no")
a = nilsor:say(p, "passage")
a = nilsor:say(p, "no")
check("Nilsor: no to the passage (EN)", has(a, "As you wish."), a)
a = nilsor:bye(p)
check("Nilsor: farewell (EN)", has(a, "Bye, Rodrigo."), a)
-- an old character in the middle of the fixed chain keeps what it gave
do
	local old = player({ storage = { [S.Questline] = 24 } })
	nilsor:say(old, "hi")
	a = nilsor:say(old, "sulphur")
	check("Nilsor: old chain at 24 already gave the sulphur", has(a, "You already brought me fine sulphur"), a)
	a = nilsor:say(old, "mission")
	check("Nilsor: old chain at 24 still needs four", has(a, "a frostbite herb") and has(a, "spores") and not has(a, "cactus"), a)
end

-- ------------------------------------------------------------------ gathering the ingredients
do
	local worldMinutes = 12 * 60
	getWorldTime = function() return worldMinutes end
	local g = player({ storage = { [S.Questline] = 21 } })
	local function target(id) return { itemid = id, getId = function() return id end, transform = function() end } end
	local function tool(id) return { itemid = id, getId = function() return id end } end
	local function said() return g.said[#g.said] or "" end
	local function wait() g:kv():scoped():set("gathered", os.time() - F.GATHER_WAIT) end
	check("Gather: spores with a spoon", F.gather(g, tool(3468), target(3920), pos()) and g.items[7251] == 1)
	check("Gather: no second spores while carrying them", F.gather(g, tool(3468), target(3920), pos()) and g.items[7251] == 1)
	g.items[7251] = 0
	check("Gather: lost spores again, but only after 5 minutes (EN message)", F.gather(g, tool(3468), target(3920), pos()) and (g.items[7251] or 0) == 0 and said() == "You might try again later.", said())
	wait()
	check("Gather: lost spores after the wait (upstream: once per character)", F.gather(g, tool(3468), target(3920), pos()) and g.items[7251] == 1)
	check("Gather: the wait is shared with the knife", F.gather(g, tool(3469), target(3753), pos()) and (g.items[7249] or 0) == 0 and said() == "You might try again later.", said())
	wait()
	check("Gather: sulphur with a spoon", F.gather(g, tool(3468), target(390), pos()) and g.items[7247] == 1)
	wait()
	check("Gather: cactus with the squeezing gear by day (BR)", F.gather(g, tool(9596), target(3647), pos()) and g.items[7245] == 1)
	wait()
	check("Gather: frostbite herb refused by day (BR/EN)", F.gather(g, tool(3469), target(7261), pos()) and (g.items[7248] or 0) == 0 and has(said(), "during the night"), said())
	worldMinutes = 22 * 60
	check("Gather: frostbite herb by night", F.gather(g, tool(3469), target(7261), pos()) and g.items[7248] == 1)
	wait()
	check("Gather: purple kiss refused by night (BR/EN)", F.gather(g, tool(9598), target(3753), pos()) and (g.items[7249] or 0) == 0 and has(said(), "during the day"), said())
	worldMinutes = 7 * 60
	check("Gather: blossom with the whacking driller (knife) by day", F.gather(g, tool(9598), target(3753), pos()) and g.items[7249] == 1)
	check("Gather: no spoon in the whacking driller (BR)", not F.gather(g, tool(9598), target(390), pos()))
	-- geyser water with the real script
	dofile("data-otservbr-global/scripts/quests/the_ice_islands_quest/actions_cure.lua")
	wait()
	worldMinutes = 3 * 60
	g.items[7286] = 1
	useItem(g, 7286, { itemid = 7106 })
	check("Geyser: refused by night (BR)", g.items[7286] == 1 and has(said(), "during the day"), said())
	worldMinutes = 13 * 60
	useItem(g, 7286, { itemid = 7106 })
	check("Geyser: water by day", g.items[7286] == 0 and g.items[7246] == 1)
	g.items[7286], g.items[7246] = 1, 0
	useItem(g, 7286, { itemid = 7106 })
	check("Geyser: the shared wait", g.items[7286] == 1 and said() == "You might try again later.", said())
	local done = player({ storage = { [S.Questline] = 29 } })
	check("Gather: lava hole after the mission goes on to What a Foolish Quest", not F.gather(done, tool(3468), target(390), pos()) and (done.items[7247] or 0) == 0)
	check("Gather: cactus after the mission goes on to other quests", not F.gather(done, tool(3469), target(3647), pos()))
	worldMinutes = 12 * 60
end

-- ------------------------------------------------------------------ The Secret of Helheim
hjaern:say(p, "hi")
a = hjaern:say(p, "mission")
check("Hjaern: Helheim (EN/BR)", has(a, "There is indeed an important mission.") and has(a, "Are you willing to do that?"), a)
a = hjaern:say(p, "yes")
check("Hjaern: Helheim accepted (EN/BR)", has(a, "This is good news.") and q() == 30, a)
a = hjaern:say(p, "mission")
check("Hjaern: Helheim reminder (EN line)", has(a, "travel to Helheim, seek the reason"), a)
p:setStorageValue(S.Questline, 31) -- the altar (movement script)
a = hjaern:say(p, "mission")
check("Hjaern: no need to report (EN/BR)", has(a, "There is no need to report about your mission.") and has(a, "Would you do us another favour?"), a)
a = hjaern:say(p, "yes")
check("Hjaern: Lurik (EN/BR)", has(a, "The local representative of the explorers society has asked for our help") and q() == 32, a)
a = hjaern:say(p, "mission")
check("Hjaern: Lurik reminder (EN line)", has(a, "Search for Lurik"), a)
hjaern:bye(p)

-- ------------------------------------------------------------------ The Contact
a = lurik:say(p, "hi")
a = lurik:say(p, "mission")
check("Lurik: contact mission (EN/BR)", has(a, "You are the one who became an honorary barbarian!") and has(a, "Do you think you can do this?"), a)
a = lurik:say(p, "yes")
check("Lurik: accepted (EN/BR)", has(a, "Excellent. Just report about your mission when you got the memory crystal.") and q() == 33, a)
lurik:bye(p)
a = nor:say(p, "hi")
check("Nor: greeting (EN/BR)", has(a, "Psst, not that loud."), a)
a = nor:say(p, "loud")
check("Nor: {loud} answers (ours)", has(a, "Psst!"), a)
a = nor:say(p, "memory crystal")
check("Nor: memory crystal (EN/BR)", has(a, "Here, take the memory crystal and leave immediately.") and p.items[7281] == 1, a)
nor:bye(p)
lurik:say(p, "hi")
a = lurik:say(p, "mission")
check("Lurik: asks for the crystal (EN/BR)", has(a, "Have you retrieved the memory crystal?"), a)
a = lurik:say(p, "yes")
check("Lurik: crystal taken (EN/BR)", has(a, "Ah, great. Please give me some time") and q() == 34 and p.items[7281] == 0, a)
a = lurik:say(p, "mission")
check("Lurik: still evaluating", has(a, "Give me some more time!"), a)
p:setStorageValue(S.MemoryCrystal, os.time() - 1)
a = lurik:say(p, "mission")
check("Lurik: mines (EN/BR)", has(a, "The information was quite useful.") and q() == 35 and p:getStorageValue(S.FormorgarMinesDoor) == 1, a)
a = lurik:say(p, "mission")
check("Lurik: mines reminder (ours)", has(a, "We need to investigate the old mines."), a)
lurik:bye(p)
-- an Explorer Society mission running no longer hides the Ice Islands steps
do
	local ES = Storage.Quest.U7_6.ExplorerSociety
	local e = player({ storage = { [S.Questline] = 32, [ES.QuestLine] = 57, [ES.TheIslandofDragons] = 57 } })
	lurik:say(e, "hi")
	a = lurik:say(e, "mission")
	check("Lurik: Ice Islands offer before the Island of Dragons reminder", has(a, "You are the one who became an honorary barbarian!"), a)
	lurik:say(e, "yes")
	a = lurik:say(e, "mission")
	check("Lurik: without the crystal the Explorer Society reminder comes", has(a, "Travel to Okolnir"), a)
	e.items[7281] = 1
	a = lurik:say(e, "mission")
	check("Lurik: with the crystal the report comes first", has(a, "Have you retrieved the memory crystal?"), a)
	e.items[7281] = 0
	a = lurik:say(e, "yes")
	check("Lurik: yes without the crystal answers (ours)", has(a, "You don't have it with you."), a)
end

-- ------------------------------------------------------------------ Formorgar Mines 1-3
p:setStorageValue(S.Questline, 36) -- Tylaf's skeleton
p:setStorageValue(S.Mission09, 2)
a = soul:say(p, "hi")
check("Restless Soul: cannot talk yet (Uhhhh...)", has(a, "Uhhhh..."), a)
a = soul:say(p, "story")
check("Restless Soul: no story yet", a == "" and q() == 36, a)
soul:bye(p)
hjaern:say(p, "hi")
a = hjaern:say(p, "mission")
check("Hjaern: hint at 36 (ours)", has(a, "You have been in the old mines?"), a)
a = hjaern:say(p, "tylaf")
check("Hjaern: Tylaf (EN/BR)", has(a, "You encountered the restless ghost of my apprentice Tylaf") and q() == 37, a)
hjaern:bye(p)
a = soul:say(p, "hi")
check("Restless Soul: greeting (EN/BR)", has(a, "Ahhhh! At last someone that can listen to my story!"), a)
a = soul:say(p, "story")
check("Restless Soul: story (EN/BR) and Ghostwhisperer (EN)", has(a, "I was captured and tortured to death by the cultists here.") and q() == 38 and p.achievements["Ghostwhisperer"], a)
soul:bye(p)
a = soul:say(p, "hi")
check("Restless Soul: greeting after the story (ours, was the last player's)", has(a, "Hurry before its too late."), a)
soul:bye(p)

-- ------------------------------------------------------------------ Formorgar Mines 4: Retaliation
hjaern:say(p, "hi")
a = hjaern:say(p, "mission")
check("Hjaern: frost charm (EN/BR)", has(a, "Take this spirit charm of cold.") and q() == 39 and p.items[7289] == 1, a)
p.items[7289] = 0
a = hjaern:say(p, "mission")
check("Hjaern: a lost charm is replaced (ours; upstream stuck)", has(a, "You lost the spirit charm of cold?") and p.items[7289] == 1, a)
local obelisks = { { 32138, 31113, 14 }, { 32119, 30992, 14 }, { 32180, 31069, 14 } }
for _, o in ipairs(obelisks) do
	useItem(p, 7289, { itemid = 1841 }, pos(o[1], o[2], o[3]))
end
a = hjaern:say(p, "mission")
check("Hjaern: three of four marked (ours)", has(a, "The spirits feel 3 of them so far.") and p:getStorageValue(S.Mission12) == 4, a)
useItem(p, 7289, { itemid = 1841 }, pos(32210, 31027, 14))
p.items[7289] = 0 -- lost after marking: the report still works
a = hjaern:say(p, "mission")
check("Hjaern: report without the charm (EN/BR)", has(a, "Yes, I can feel it! The spirits are in touch with the obelisks.") and q() == 40 and p.outfits[251] ~= nil and p.outfits[252] ~= nil and p:getStorageValue(S.Mission12) == 6, a)

-- ------------------------------------------------------------------ Norseman addons
a = hjaern:say(p, "frostheart shard")
check("Hjaern: shards asked (EN/BR)", has(a, "Do you bring frostheart shards for our spell?"), a)
a = hjaern:say(p, "yes")
check("Hjaern: no shards (ours)", has(a, "You need 5 frostheart shards."), a)
p.items[7290] = 5
hjaern:say(p, "frostheart shard")
a = hjaern:say(p, "yes")
check("Hjaern: 5 shards give the first addon at once (EN/BR)", has(a, "Excellent, you collected 5 frostheart shards. Take this. It might suit your Nordic outfit fine.") and p.outfits[251] == 1 and q() == 42, a)
a = hjaern:say(p, "reward")
check("Hjaern: reward before the second (EN)", has(a, "We need a few shards more, then you might receive another reward."), a)
p.items[7290] = 12
hjaern:say(p, "shards")
a = hjaern:say(p, "yes")
check("Hjaern: 10 shards give the second addon (EN/BR) and Out in the Snowstorm (BR)", has(a, "Excellent, you collected 15 frostheart shards.") and p.outfits[251] == 3 and q() == 44 and p.items[7290] == 2 and p.achievements["Out in the Snowstorm"], a)
hjaern:say(p, "shard")
local before = p.money
a = hjaern:say(p, "yes")
check("Hjaern: sells shards for 2000", p.money == before + 4000 and p.items[7290] == 0, a)
hjaern:bye(p)
-- old characters between steps (5 or 15 shards given, reward not taken)
do
	local old = player({ storage = { [S.Questline] = 41 } })
	hjaern:say(old, "hi")
	a = hjaern:say(old, "reward")
	check("Hjaern: old state 41 gets the first addon", has(a, "Take this. It might suit your Nordic outfit fine.") and old.outfits[251] == 1 and old:getStorageValue(S.Questline) == 42, a)
	local old2 = player({ storage = { [S.Questline] = 43 } })
	hjaern:say(old2, "hi")
	old2.outfits[251], old2.outfits[252] = 1, 1
	a = hjaern:say(old2, "shard")
	check("Hjaern: old state 43 gets the second addon", has(a, "From now on we only can give you 2000 gold pieces") and old2.outfits[251] == 3 and old2.achievements["Out in the Snowstorm"], a)
end

-- ------------------------------------------------------------------ hoist
do
	local hoist = moves[1]
	local function step(pl, uid)
		pl.teleported = nil
		local item = { uid = uid }
		hoist.onStepIn(pl, item, pos(), pos(1, 1, 7))
		return pl.teleported
	end
	Tile = function() return { getItemById = function() return nil end } end
	local h = player({})
	h.getPlayer = function(self) return self end
	local t = step(h, 3059)
	check("Hoist: refused without the floor plan", t and t.x == 1, t and t.z)
	h:setStorageValue(S.FormorgarMinesHoistSkeleton, 1)
	t = step(h, 3059)
	check("Hoist: floor plan works the first floor (EN)", t and t.z == 10)
	t = step(h, 3061)
	check("Hoist: third floor needs the instructions", t and t.x == 1)
	h:setStorageValue(S.FormorgarMinesHoistChest, 1)
	t = step(h, 3061)
	check("Hoist: instructions work the third floor (upstream: never)", t and t.z == 10)
	t = step(h, 3060)
	check("Hoist: second floor without the lever goes up", t and t.z == 9)
	local old = player({ storage = { [S.FormorgarGlacierChest] = 1 } })
	old.getPlayer = function(self) return self end
	t = step(old, 3060)
	check("Hoist: the old box storage also counts", t and t.z == 9)
end

-- ------------------------------------------------------------------ Duncan (Animal Activist)
do
	local d = player({ storage = { [Storage.Quest.U7_8.TheShatteredIsles.TortoiseEggNargorDoor] = 1, [S.Questline] = 40 }, items = { [6125] = 1 } })
	duncan:say(d, "hi")
	duncan.npc.said = duncan.npc.said
	local asked
	for _, w in ipairs({ "tortoise egg", "egg", "mission", "nargor" }) do
		local r = duncan:say(d, w)
		if r ~= "" then asked = r; break end
	end
	-- find the topic 8 question by brute force through the NPC's own words
	duncan.npc.interacting[d:getId()] = true
	a = ""
	for _, w in ipairs({ "tortoise", "eggs", "egg" }) do
		a = duncan:say(d, w)
		if has(a, "egg") then break end
	end
	a = duncan:say(d, "yes")
	check("Duncan: tortoise egg without a Lua error, Animal Activist", not has(a, "LUA ERROR") and d.achievements["Animal Activist"] and (d.items[6125] or 0) == 0, (asked or "") .. " / " .. a)
end

-- ------------------------------------------------------------------ every highlighted word
local function fresh()
	return player({ storage = { [B.Questline] = 8, [S.Questline] = 40 } })
end
T.checkHints(sven, fresh, { mead = true, test = true }) -- quest steps, checked above
T.checkHints(hjaern, fresh, { reward = true })
T.checkHints(siflind, fresh, { jug = true })
T.checkHints(nilsor, fresh, { cactus = true, water = true, sulphur = true, herb = true, blossom = true, ["hydra tongue"] = true, spores = true, mission = true, medicine = true })
T.checkHints(iskan, fresh)
T.checkHints(nor, fresh)

-- ------------------------------------------------------------------ Lurik, Buddel, Dankwart (2026-11-17)
do
	local pl = fresh()
	pl.name = "Tester"
	buddel:say(pl, "hi")
	local n1 = buddel:say(pl, "name")
	local n2 = buddel:say(pl, "Tester")
	local n3 = buddel:say(pl, "tester")
	check("Buddel: name game asks (EN)", has(n1, "everyone calls me Buddel") and has(n2, "Ahh, Tester. And you?"), n2)
	check("Buddel: same name twice (EN)", has(n3, "You are also called Tester?!?!?") and has(n3, "both of you will come"), n3)
	buddel:bye(pl)
	buddel:say(pl, "hi")
	buddel:say(pl, "name")
	local o1 = buddel:say(pl, "Bob")
	local o2 = buddel:say(pl, "Alice")
	check("Buddel: other names (EN)", has(o1, "Aha! And you?") and has(o2, "this is a funny name you have"), o2)
	buddel:bye(pl)
	local s0 = fresh()
	s0.storage[Storage.Quest.U8_0.BarbarianTest.Questline] = 8
	s0.storage[Storage.Quest.U8_0.TheIceIslands.Questline] = 5
	buddel:say(s0, "hi")
	local t0 = buddel:say(s0, "tyrsung")
	check("Buddel: no Tyrsung before Siflind's mission (EN)", has(t0, "Ask Siflind"), t0)
	buddel:bye(s0)
	s0.storage[Storage.Quest.U8_0.TheIceIslands.Questline] = 6
	buddel:say(s0, "hi")
	t0 = buddel:say(s0, "tyrsung")
	check("Buddel: Tyrsung after Siflind's mission", has(t0, "Big, big island east of here"), t0)
	buddel:bye(s0)
	local es = Storage.Quest.U7_6.ExplorerSociety
	local m = fresh()
	m.name = "Tester"
	m.storage[es.JoiningTheExplorers] = 5
	m.storage[es.QuestLine] = 5
	lurik:say(m, "hi")
	check("Lurik: join as member (EN)", has(lurik:say(m, "join"), "But you are already a member, Tester."))
	check("Lurik: rank novice (EN)", has(lurik:say(m, "rank"), "You are a novice of the explorer's society."))
	lurik:bye(m)
	local dk = fresh()
	check("Dankwart: greeting (EN)", has(dankwart:say(dk, "hi"), "Hi there and welcome to my tavern. Have a drink."))
	dankwart:bye(dk)
end

-- ------------------------------------------------------------------ EN transcripts, line by line
if transcripts then
	local npcs = { Sven = sven, Hjaern = hjaern, Siflind = siflind, Nilsor = nilsor, Iskan = iskan, Lurik = lurik, Buddel = buddel, Dankwart = dankwart }
	-- words that are quest steps or offers, checked above (or answered differently on purpose)
	local skip = {
		hi = true, bye = true, yes = true, no = true, mission = true, test = true, mead = true, hug = true,
		mammoth = true, barbarian = true, frostheart = true, passage = true, svargrond = true, ["mission or test or mammoths"] = true,
		wands = true, ["runes or offers"] = false,
	}
	for name, talk in pairs(npcs) do
		local f = io.open(transcripts .. "/" .. name .. "_Transcripts.txt")
		if f then
			local src = f:read("*a"):gsub("<br%s*/?>", "\n")
			f:close()
			local said, pending = nil, {}
			local pairsList = {}
			for line in src:gmatch("[^\n]+") do
				local pl = line:match("^''?Player''?:%s*(.+)$") or line:match("^Player:%s*(.+)$")
				local np = line:match("^%s*" .. name .. ":%s*(.+)$")
				if pl then
					said = pl:gsub("'''", ""):gsub("%[%[[^|%]]*|([^%]]*)%]%]", "%1"):gsub("[%[%]]", ""):gsub("%?", ""):gsub("^%s+", ""):gsub("%s+$", "")
				elseif np and said then
					pairsList[#pairsList + 1] = { said, np:gsub("''Player''", "Tester"):gsub("'''", ""):gsub("%[%[[^|%]]*|([^%]]*)%]%]", "%1"):gsub("[%[%]]", "") }
					said = nil
				end
			end
			local tested = 0
			for _, pr in ipairs(pairsList) do
				for word in (pr[1] .. " or "):gmatch("(.-)%s+or%s+") do
					word = word:lower():gsub("^%s+", ""):gsub("%s+$", "")
					if word ~= "" and not skip[word] and not word:find("''", 1, true) and not word:find("<", 1, true) then -- conditions and names: checked below
						local pl = fresh()
						pl.name = "Tester"
						talk:say(pl, "hi")
						local answer = talk:say(pl, word)
						local want = pr[2]:gsub("%s*%.%.%.%s*$", ""):sub(1, 60)
						check(name .. " (EN): '" .. word .. "'", has(answer, want), answer:sub(1, 80))
						talk:bye(pl)
						tested = tested + 1
					end
				end
			end
			check(name .. ": EN transcript read", tested > 0, tested .. " words")
		end
	end
end

T.finish()
