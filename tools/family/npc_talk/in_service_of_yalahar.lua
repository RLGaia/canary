-- In Service of Yalahar check (2026-11-02): the whole quest from Palimuth's first mission to the
-- reward, on Palimuth's side, on Azerus' side and mixed, with the NPC lines of TibiaWiki BR/EN.
-- Run from the repository root:  luajit tools/family/npc_talk/in_service_of_yalahar.lua
-- World steps (crowbar spots, kills, chests, ghost charm, matrix) are set as storages/items the
-- way the real scripts set them; those scripts are checked on the test server.
local T = dofile("tools/family/npc_talk/npc_talk.lua")
local check = T.check
Position = Position or function(x, y, z)
	return { x = x, y = y, z = z, sendMagicEffect = function() end }
end
Tile = Tile or function()
	return nil
end
CONST_ME_MAGIC_BLUE = CONST_ME_MAGIC_BLUE or 13
dofile("data-otservbr-global/lib/others/family_in_service_of_yalahar.lua")

local Q = Storage.Quest.U8_4.InServiceOfYalahar
local F = Storage.Quest.FamilyInServiceOfYalahar
local NPC = "data-otservbr-global/npc/"
local npcs = {}
local function npc(file)
	npcs[file] = npcs[file] or T.load(NPC .. file .. ".lua")
	return npcs[file]
end

local function norm(s)
	return (s:lower():gsub("[{}]", ""):gsub("%s+", ""))
end

local function newPlayer()
	local p = T.player({ level = 120 })
	p.achievements, p.outfits = {}, {}
	p.addAchievement = function(self, name)
		self.achievements[name] = true
	end
	p.addOutfit = function(self, id)
		self.outfits[id] = true
	end
	p.addMapMark = function() end
	return p
end

-- says each line to the NPC (hi first); every expected text must be in the last answer
local function talk(p, file, steps)
	local t = npc(file)
	t:say(p, "hi")
	local all = ""
	for _, s in ipairs(steps) do
		local answer = t:say(p, s[1])
		all = all .. " | " .. answer
		if s[2] then
			check(file .. " '" .. s[1] .. "': " .. s[2]:sub(1, 50), norm(answer):find(norm(s[2]), 1, true) ~= nil, "got: " .. answer:sub(1, 140))
		end
	end
	t:bye(p)
	return all
end

local function q(p)
	return p.storage[Q.Questline] or -1
end

-- Missions 01-02 and the first half of 03, the same on both sides
local function start(p)
	check("Palimuth answers job", talk(p, "palimuth", { { "job", "I'm an Augur of the city of Yalahar" } }) ~= "")
	talk(p, "palimuth", {
		{ "mission", "Would you like to assist us in re-establishing order in our city?" },
		{ "yes", "If you are willing to work for the city of Yalahar, you can ask me for a mission any time, be it night or day." },
		{ "mission", "We were able to locate the 4 worst spots in the sewers." },
	})
	for _, k in ipairs({ Q.SewerPipe01, Q.SewerPipe02, Q.SewerPipe03, Q.SewerPipe04 }) do
		p.storage[k] = 1
	end
	talk(p, "palimuth", {
		{ "mission", "So are you done with your work?" },
		{ "yes", "Thank you very much. You have no idea how hard it was to find someone volunteering for that job." },
		{ "mission", "Are you willing to do that?" },
		{ "yes", "You'll find our seven guards at the gates of each quarter." },
	})
	local accept = norm(npc("palimuth").npc.said[#npc("palimuth").npc.said - 2] or "")
	check("Mission 02: warning first, then the guards (BR/EN)", accept:find(norm("I must warn you"), 1, true) == 1, accept:sub(1, 60))
	-- guards in the order of a start in the Magician Quarter (EN): Reed first
	for i, g in ipairs({ "reed", "bruce", "hal", "tony", "barry", "oliver", "peter" }) do
		local answer = talk(p, g, { { "report" } })
		check("Mission 02: " .. g .. " reports as guard " .. i, q(p) == 7 + i and answer:find("<", 1, true) ~= nil, "Questline " .. q(p))
		check("Mission 02: quest log counts " .. i, p.storage[Q.Mission02] == 1 + i, p.storage[Q.Mission02])
		local again = talk(p, g, { { "report" } })
		check("Mission 02: " .. g .. " does not report twice", q(p) == 7 + i, again)
	end
	talk(p, "palimuth", {
		{ "mission", "Did you get all the reports my superiors asked for?" },
		{ "yes", "Excellent! My superiors will be pleased to get these reports." },
		{ "mission", "I left some notes in the small room there." },
		{ "mission", "Get the notes in the small room there and read them." },
	})
	check("Mission 03: Palimuth waits for the notes", q(p) == 16)
	p.storage[Q.NotesPalimuth] = 2 -- quest_system2 chest 14037 (formerValue 1 -> 2)
	talk(p, "palimuth", { { "mission", "Now leave and talk to my superior Azerus in the city centre to get your next mission." } })
	local hi = npc("yalahari"):say(p, "hi")
	check("Azerus greets 'Greetings.' (BR/EN)", hi == "Greetings.", hi)
	npc("yalahari"):bye(p)
	talk(p, "yalahari", {
		{ "mission", "So we have written a manifesto." },
		{ "mission", "Grab a copy from the room behind me." },
	})
	check("Mission 03: Azerus waits for the manifesto", q(p) == 18)
	p.storage[Q.NotesAzerus] = 2 -- chest 14038
	talk(p, "yalahari", {
		{ "mission", "I'm mildly impressed by your previous deeds in our service." },
		{ "mission", "We must stop it before other quarters are afflicted." },
	})
	talk(p, "palimuth", { { "mission", "I beg you to destroy these notes." } })
	check("Mission 03 started (Questline 21)", q(p) == 21, q(p))
	p.storage[Q.AlchemistFormula] = 1 -- trio dead, formula taken from chest 14039
end

local function good3(p)
	p.storage[Q.GoodSide] = 0 -- actions_formula: burnt in an oven
	talk(p, "yalahari", { { "mission", "Have you also retrieved the research papers?" }, { "no", "Hm, no sign of any notes you say?" } })
end
local function bad3(p)
	p.items[8818] = 1
	talk(p, "yalahari", { { "mission", "Have you also retrieved the research papers?" }, { "yes", "Impressive indeed!" } })
end

local function m4(p, good)
	talk(p, "yalahari", { { "mission", "Talk to him after killing some of his henchmen." } })
	talk(p, "palimuth", { { "mission", "Mr. West is not a bad man." } })
	p.storage[Q.MrWestDoor] = good and 1 or 2 -- sewer door / door above him
	if good then
		talk(p, "mr._west", { { "friend", "I guess you are here on a mission." }, { "mission", "Indeed, I can see the benefits of a mutual agreement." } })
		talk(p, "palimuth", { { "mission", "You did quite well in gaining a new friend who will work together with us." } })
		talk(p, "yalahari", { { "mission", "So he has been too uncooperative for you?" } })
	else
		talk(p, "mr._west", { { "mission", "Yes, for the sake of my life I'll accept those terms." } })
		talk(p, "yalahari", { { "mission", "I hope you gave this criminal a real scare!" } })
	end
end

local function m5(p, good)
	talk(p, "yalahari", { { "mission", "One of the residents is an ancient druid that rather cares for animals than for people." } })
	talk(p, "palimuth", { { "mission", "they also mean starvation and death for the poor." } })
	local hi = npc("tamerin"):say(p, "hi")
	check("Tamerin greets as in the wikis", hi == "Hello, what brings you here?", hi)
	npc("tamerin"):say(p, "mission")
	npc("tamerin"):say(p, "yes")
	npc("tamerin"):bye(p)
	p.items[8819] = 1
	talk(p, "tamerin", { { "animal cure", "Thank you very much. As I said, as soon as you have helped me to solve both of my problems, we will talk about your mission." } })
	p.items[8820] = 1
	talk(p, "tamerin", {
		{ "morik", "So he finally got what he deserved." },
		{ "mission", "What kind of animals shall I raise? Warbeasts or cattle?" },
		{ good and "cattle" or "warbeasts", "So be it!" },
	})
	if good then
		talk(p, "palimuth", { { "mission", "These are great news indeed." } })
		talk(p, "yalahari", { { "mission", "This druid dares to affront us?" } })
	else
		talk(p, "palimuth", { { "mission", "Rumours travel fast in Yalahar." } })
		talk(p, "yalahari", { { "mission", "So have you won us a new ally? Excellent." } })
	end
end

local function m6(p, good)
	talk(p, "yalahari", { { "mission", "Take this ghost charm and place it on the strange carving in the cemetery." } })
	check("Mission 06: Azerus gives the ghost charm", (p.items[8822] or 0) == 1)
	talk(p, "palimuth", { { "mission", "What a sick idea to misuse tortured souls to power some device!" } })
	-- lost charm: Azerus gives another one (ours)
	p.items[8822] = 0
	talk(p, "yalahari", { { "mission", "You lost the ghost charm?" } })
	check("Mission 06: a lost charm is replaced", (p.items[8822] or 0) == 1 and q(p) == 36, q(p))
	-- actions_ghost: charged on the carving and picked up
	p.items[8822] = 0
	p.items[8827] = 1
	p.storage[Q.Questline] = 37
	if good then
		talk(p, "palimuth", { { "mission", "Tell the Yalahari that the charm was destroyed by the energy it contained." } })
		talk(p, "yalahari", { { "mission", "Destroyed you say? That's impossible!" } })
	else
		talk(p, "yalahari", { { "mission", "I'm considering to introduce you to my ma.. to my direct superior one day." } })
	end
end

local function m7(p, good)
	talk(p, "yalahari", { { "mission", "We believe that there are three leaders in this area." } })
	talk(p, "palimuth", { { "mission", "It would be much more useful to find out what the quara are so upset about." } })
	if good then
		talk(p, "maritima", { { "quara", "The quara in this area are a strange race that seeks inner perfection rather than a physical one." } })
		talk(p, "palimuth", { { "mission", "Oh no! So that's the reason for the quara attacks!" } })
		talk(p, "yalahari", { { "mission", "Those cowards have evaded your efforts?" } })
	else
		for _, k in ipairs({ Q.QuaraInky, Q.QuaraSharptooth, Q.QuaraSplasher }) do
			p.storage[k] = 1
		end
		p.storage[Q.QuaraState] = 2 -- quara_leader_kill
		talk(p, "yalahari", { { "mission", "This will teach these fishmen who is the ruler of that area." } })
	end
end

local function m8to10(p, good8, chooseGood)
	talk(p, "yalahari", { { "mission", "look for a pattern crystal used for weapon production" } })
	talk(p, "palimuth", { { "mission", "Somewhere in the factory you might find an old pattern crystal for the production of food." } })
	p.storage[Q.MatrixState] = good8 and 1 or 2 -- actions_matrix (fixed: weapon = 2)
	p.storage[Q.Questline] = 46
	if good8 then
		talk(p, "palimuth", { { "mission", "You can be proud of your decision, my friend." } })
		talk(p, "yalahari", { { "mission", "Your failure is an outrage!" }, { "mission", "I'm quite aware of your connection to this manipulative Palimuth." } })
	else
		talk(p, "yalahari", { { "mission", "Excellent! This weapons are vital for our cause!" }, { "mission", "Come back if you have decided to which side you want to belong." } })
	end
	local good, bad = FamilyYalahar.sideCounts(p)
	talk(p, "palimuth", { { "mission", good >= bad and "Well, what can I say? You have to make a decision." or "Listen, I know you have worked for Azerus and his friends" } })
	if chooseGood then
		talk(p, "palimuth", { { "mission", "So do you want to side with me?" }, { "yes", "You have no idea how much I hoped to hear that, my friend!" }, { "mission", "Be prepared for a HARD battle!" } })
	else
		talk(p, "yalahari", { { "mission", "So do you want to side with me" }, { "yes", "I knew that you were smart enough to make the right decision!" }, { "mission", "For your noble deeds, we would like to invite you to a special celebration ceremony." } })
	end
	check("Mission 10 started (Questline 51)", q(p) == 51, q(p))
	p.storage[Q.Questline] = 52 -- movements_morik (the last square)
	talk(p, "palimuth", { { "mission", "What really troubles me is that none of those false Yalahari had the personality of a great leader." } })
	check("Mission 10: outfits and reward room", p.outfits[324] and p.outfits[325] and q(p) == 53, q(p))
end

local function side(p, m)
	return p.storage[({ F.Side03, F.Side04, F.Side05, F.Side06, F.Side07, F.Side08 })[m - 2]]
end

-- Palimuth's side all the way
do
	local p = newPlayer()
	start(p)
	good3(p)
	m4(p, true)
	m5(p, true)
	m6(p, true)
	m7(p, true)
	m8to10(p, true, true)
	for m = 3, 8 do
		check("Palimuth's side recorded for mission " .. m, side(p, m) == 1, side(p, m))
	end
	check("Follower of Palimuth", p.achievements["Follower of Palimuth"] and not p.achievements["Turncoat"])
end

-- Azerus' side all the way
do
	local p = newPlayer()
	start(p)
	bad3(p)
	m4(p, false)
	m5(p, false)
	m6(p, false)
	m7(p, false)
	m8to10(p, false, false)
	for m = 3, 8 do
		check("Azerus' side recorded for mission " .. m, side(p, m) == 2, side(p, m))
	end
	check("Follower of Azerus", p.achievements["Follower of Azerus"] and not p.achievements["Turncoat"])
end

-- mixed: Turncoat; one side all the way but the other one chosen: no achievement
do
	local p = newPlayer()
	start(p)
	good3(p)
	m4(p, false)
	m5(p, true)
	m6(p, false)
	m7(p, true)
	m8to10(p, true, true)
	check("Turncoat", p.achievements["Turncoat"] and not p.achievements["Follower of Palimuth"])
	local p2 = newPlayer()
	start(p2)
	good3(p2)
	m4(p2, true)
	m5(p2, true)
	m6(p2, true)
	m7(p2, true)
	m8to10(p2, true, false)
	check("all for Palimuth but Azerus chosen: no achievement", next(p2.achievements) == nil)
end

T.checkHints(npc("palimuth"), newPlayer, {})
T.checkHints(npc("mr._west"), newPlayer, { mission = true })
T.finish()
