-- Gaia Family server: The Scatterbrained Sorcerer Quest (2026-11-15). Ours, not upstream.
--
-- Canary v3.6.1 had only Eclesius' old greeting ("You seem too experienced to become my
-- assistant. Please leave.") and a few loose lines: no tasks, no missions, no quest log, no
-- object in his house did anything, Grodrik and A Frog were not placed. Here is the whole quest:
-- the five daily tasks (sweep, polish, feed, exterminate, prevent) and the six missions.
--
-- Sources: TibiaWiki BR quest page (our backup, 2026-11-12) first, TibiaWiki EN spoiler and
-- transcripts to complete it (NPC lines, object messages, note texts, item ids). Where they
-- differ: greeting by level (EN: under 20 "young and eager", from 20 "a bit old"; BR shows only
-- the first), Mission 4 reward (BR 500 experience, EN 1000: BR used), the elf and dwarf answers
-- (EN gives two answer sets per character: "blue eyes" or "chocolate" in common; the BR list of
-- other common answers - tolerance, lonely - has no lines, so not used). Lines marked "ours"
-- are not on either wiki.
--
-- Rodrigo's choices (2026-11-15): the space-time continuum room of Mission 3 is not on our
-- map, so Eclesius takes you to his laboratory (one floor down) where three levers appear for
-- the scene; killing the white cat in the attic costs only that day's Exterminate task
-- (Tibia: 30 days).
--
-- Daily tasks open again at the server save (06:00), like the Venore tasks.
-- Storages: Storage.Quest.U8_5.TheScatterbrainedSorcerer; details in player KV family-sorcerer.
-- Objects, doors, kills and the laboratory scene: scripts/family/scatterbrained_sorcerer.lua.
-- NPC files that call this: eclesius, amarie, grodrik, a_confused_frog, a_frog, irmana, xodet,
-- frodo, queen_eloise, bunny_bonecrusher.
-- Switch: Family.scatterbrainedSorcerer (false = the NPCs as upstream, objects do nothing).

Family = Family or {}
Family.scatterbrainedSorcerer = true

FamilySorcerer = FamilySorcerer or {}
local FS = FamilySorcerer
local S = Storage.Quest.U8_5.TheScatterbrainedSorcerer
FS.S = S

local KV_SCOPE = "family-sorcerer"

-- Mission storage values (S.Mission)
FS.M = {
	HAT_ASKED = 1,
	HAT_DONE = 2,
	SANDALS_ASKED = 3,
	SANDALS_GIVEN = 4, -- Eclesius' sandals: boil them in the cauldron
	BOILED = 5,
	SKUNK_ASKED = 6,
	SKUNKED = 7,
	FRAGRANCE_ASKED = 8,
	FRAGRANCE_CHOSEN = 9,
	FRAGRANT = 10,
	SANDALS_DONE = 11,
	DATING_ASKED = 12, -- find a lonely elf (Amarie) and dwarf (Grodrik)
	QUESTIONNAIRE = 13,
	COMMON_FOUND = 14,
	POTIONS = 15,
	BOTH_DRUNK = 16,
	BONUS = 17, -- "MUAHAHA! My plan worked!" (Matchmaker)
	SCENE = 18, -- in the laboratory with the levers
	RESULT = 19, -- the middle lever was pulled
	BACK = 20,
	DATING_DONE = 21,
	BOOKS_ASKED = 22,
	BOOKS_DONE = 23,
	MEMORY_ASKED = 24, -- find who Eclesius talked to (Xodet)
	XODET_FOUND = 25,
	WAND_ASKED = 26,
	FORMULA = 27,
	MEMORY_DONE = 28,
	FROG_ASKED = 29,
	RAGS = 30,
	KISS_ASKED = 31,
	KISSED = 32,
	INGREDIENTS_ASKED = 33,
	COUNTERSPELL = 34,
	SPELL_ASKED = 35,
	SPOKEN = 36,
	HUMAN_ASKED = 37,
	HUMAN_ANSWERED = 38,
	POND_ASKED = 39,
	SWAPPED = 40,
	FROG_DONE = 41,
}
local M = FS.M

-- task states
FS.FREE = 0
FS.ACTIVE = 1
FS.READY = 2
FS.REPORTED = 3
FS.FAILED = 4
FS.tasks = { "sweep", "polish", "feed", "exterminate", "prevent" }
FS.taskStorage = { sweep = S.Sweep, polish = S.Polish, feed = S.Feed, exterminate = S.Exterminate, prevent = S.Prevent }
FS.taskReward = {
	sweep = { 100, 150 },
	polish = { 150, 200 },
	feed = { 150, 250 },
	exterminate = { 200, 250 },
	prevent = { 250, 300 },
}

FS.items = {
	hatDark = 9127,
	hatPink = 9128,
	hatWooden = 9129,
	sandals = 3551,
	eclesiusSandals = 9131,
	grodrikAxe = 9142,
	amarieBook = 9143,
	parchment = 2819,
	lovePotion = 9173,
	wand = 9187,
	formula = 9188,
	rags = 9191,
	broom = 3454,
	moltenWax = 9106,
	polish = 9107,
	fishFlakes = 9109,
	magicalOil = 9112,
	cageKey = 9113,
	mug = 2880,
	vial = 2874,
}

-- Prevent the apocalypse: bit mask in KV "prevent"
FS.PREVENT_OIL = 1
FS.PREVENT_LOCK = 2
FS.PREVENT_PLANKS = 4
FS.PREVENT_LYRE = 8
FS.PREVENT_ALL = 15
FS.PLANKS_NEEDED = 4 -- EN: "There are four of them"

function FS.enabled()
	return Family.scatterbrainedSorcerer == true
end

function FS.kv(player)
	return player:kv():scoped(KV_SCOPE)
end

function FS.kvNumber(player, key)
	return tonumber(FS.kv(player):get(key)) or 0
end

function FS.mission(player)
	return math.max(0, player:getStorageValue(S.Mission))
end

function FS.setMission(player, value)
	player:setStorageValue(S.Mission, value)
end

function FS.isAssistant(player)
	return player:getStorageValue(S.Questline) >= 1
end

function FS.hasBit(mask, n)
	return math.floor(mask / 2 ^ n) % 2 == 1
end

function FS.bitCount(mask, upTo)
	local n = 0
	for i = 0, upTo do
		if FS.hasBit(mask, i) then
			n = n + 1
		end
	end
	return n
end

-- The game day changes at the server save time (as the Venore tasks and Family.stoneDay).
function FS.day(now)
	now = now or os.time()
	local hour = 6
	if configManager and configKeys and configKeys.GLOBAL_SERVER_SAVE_TIME then
		hour = tonumber((configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME) or ""):match("^(%d+)")) or 6
	end
	return os.date("%Y-%m-%d", now - hour * 3600)
end

-- A new game day frees the tasks reported (or failed) before it.
function FS.refresh(player)
	local kv = FS.kv(player)
	local today = FS.day()
	if kv:get("day") == today then
		return
	end
	kv:set("day", today)
	for _, task in ipairs(FS.tasks) do
		local value = player:getStorageValue(FS.taskStorage[task])
		if value == FS.REPORTED or value == FS.FAILED then
			player:setStorageValue(FS.taskStorage[task], FS.FREE)
		end
	end
end

function FS.taskState(player, task)
	FS.refresh(player)
	local value = player:getStorageValue(FS.taskStorage[task])
	return value < 0 and FS.FREE or value
end

function FS.setTask(player, task, value)
	player:setStorageValue(FS.taskStorage[task], value)
end

function FS.reward(player, gold, experience)
	if experience and experience > 0 then
		player:addExperience(experience, true)
	end
	if gold and gold > 0 then
		player:addMoney(gold)
	end
end

-- Lower case, punctuation as spaces, single spaces: for spells and answers.
function FS.normalize(message)
	return (" " .. message:lower():gsub("[^%w']", " "):gsub("%s+", " ") .. " ")
end

function FS.says(message, phrase)
	return FS.normalize(message):find(" " .. phrase .. " ", 1, true) ~= nil
end

-- ---------------------------------------------------------------------------
-- quest log
-- ---------------------------------------------------------------------------
local taskNames = {
	sweep = "Sweep the house",
	polish = "Polish the crystal ball",
	feed = "Feed the fish",
	exterminate = "Exterminate the bats",
	prevent = "Prevent the apocalypse",
}

-- ours
function FS.describeTasks(player)
	local lines = {}
	for _, task in ipairs(FS.tasks) do
		local state = FS.taskState(player, task)
		local text
		if state == FS.ACTIVE then
			text = "in progress"
		elseif state == FS.READY then
			text = "done, tell Eclesius"
		elseif state == FS.REPORTED then
			text = "done today"
		elseif state == FS.FAILED then
			text = "not today (you hurt the cat)"
		else
			text = "ask Eclesius"
		end
		lines[#lines + 1] = taskNames[task] .. ": " .. text .. "."
	end
	return "Eclesius, the scatterbrained sorcerer south of Thais, has five tasks that need to be done once a day. " .. table.concat(lines, " ")
end

-- ours (TibiaWiki has no quest log texts)
local missionTexts = {
	[M.HAT_ASKED] = "Someone ruined Eclesius' favourite hat. He wants a new one: stylish, manly, not pink and not too heavy. A tailor in the large clothing warehouse of Venore may help.",
	[M.HAT_DONE] = "You brought Eclesius a dark hat. He loves it.",
	[M.SANDALS_ASKED] = "Eclesius' sandals smell horribly. Bring him a new pair of sandals.",
	[M.SANDALS_GIVEN] = "Disinfect Eclesius' new sandals in the large cauldron of his laboratory.",
	[M.BOILED] = "The sandals were boiled in the cauldron. Tell Eclesius.",
	[M.SKUNK_ASKED] = "Use Eclesius' sandals on the fresh corpse of a skunk.",
	[M.SKUNKED] = "The sandals smell of dead skunk. Tell Eclesius.",
	[M.FRAGRANCE_ASKED] = "Tell Eclesius something that smells really delicious.",
	[M.FRAGRANCE_CHOSEN] = "Use the sandals on something that smells really good, as Eclesius said.",
	[M.FRAGRANT] = "The sandals smell delicious now. Bring them to Eclesius.",
	[M.SANDALS_DONE] = "Eclesius' new sandals are protected by an anti-smell-hex.",
	[M.DATING_ASKED] = "Become a dating agent: find a lonely elf in Ab'Dendriel and a lonely dwarf in Kazordoon and bring a personal item from each of them to Eclesius.",
	[M.QUESTIONNAIRE] = "Take the questionnaire from Eclesius' library, ask the elf Amarie and the dwarf Grodrik its questions and find out what they have in common.",
	[M.COMMON_FOUND] = "Eclesius knows what the elf and the dwarf have in common. Ask him about the mission.",
	[M.POTIONS] = "Get Amarie and Grodrik to drink one dose of Eclesius' love potion each, without telling them what it is.",
	[M.BOTH_DRUNK] = "Both love birds drank the potion. Report to Eclesius.",
	[M.BONUS] = "Eclesius' plan worked. Ask him how to go on.",
	[M.SCENE] = "Pull the levers in Eclesius' laboratory: first the left, then the right, then the middle one.",
	[M.RESULT] = "The experiment did not go as planned. Talk to Eclesius.",
	[M.BACK] = "Eclesius wants to forget the whole mess. Ask him for your reward.",
	[M.DATING_DONE] = "The dwarf and the elf hopefully don't remember anything.",
	[M.BOOKS_ASKED] = "Tell Eclesius the colour of each book in his library. He gives hints if you ask him.",
	[M.BOOKS_DONE] = "You told Eclesius the colours of his books.",
	[M.MEMORY_ASKED] = "Find out who Eclesius talked to last night in Frodo's tavern.",
	[M.XODET_FOUND] = "Xodet talked to Eclesius last night. Tell Eclesius.",
	[M.WAND_ASKED] = "Find Xodet's first wand, maybe somewhere in his house, and show it to him.",
	[M.FORMULA] = "Xodet gave you the formula for a memory potion. Bring it to Eclesius.",
	[M.MEMORY_DONE] = "Eclesius brews his memory potion.",
	[M.FROG_ASKED] = "Sneak into the castle of Carlin and find some of Queen Eloise's old princess clothes.",
	[M.RAGS] = "You have an old dress of Queen Eloise. Show it to Eclesius.",
	[M.KISS_ASKED] = "Go down into Eclesius' cellar, dress up as a princess and kiss the frog.",
	[M.KISSED] = "The kiss did not work. Tell Eclesius.",
	[M.INGREDIENTS_ASKED] = "Bring Eclesius a silver amulet, a dagger, a green tapestry, a blank rune and a dirty fur, all at once.",
	[M.COUNTERSPELL] = "Eclesius prepared a counterspell. Ask him about the mission.",
	[M.SPELL_ASKED] = "Say the counterspell in front of the frog: 'Eeny, meeny, miny, moe - ribbit, ribbit head to toe!'",
	[M.SPOKEN] = "The frog can speak again. Tell Eclesius.",
	[M.HUMAN_ASKED] = "Ask the frog how he could get his human form back.",
	[M.HUMAN_ANSWERED] = "The frog wants to stay a frog. Tell Eclesius.",
	[M.POND_ASKED] = "Find out at which pond the frog wants to live and say to a frog there: 'Eeny, meeny, miny, moe - I stay here and you will go!'",
	[M.SWAPPED] = "The frogs swapped their places. Report to Eclesius.",
	[M.FROG_DONE] = "Eclesius' former assistant lives happily at the pond north of Thais.",
}

-- endValue: the last value of the mission shown (a finished mission keeps its last text)
function FS.describeMission(player, endValue)
	local value = FS.mission(player)
	if endValue and value >= endValue then
		value = endValue
	end
	if value == M.FRAGRANCE_CHOSEN then
		local f = FS.fragrances[FS.kv(player):get("fragrance") or ""]
		return "Use Eclesius' sandals on " .. (f and f.what or "something that smells really good") .. " so they soak up the fragrance."
	end
	return missionTexts[value] or "Ask Eclesius about a mission."
end

-- ---------------------------------------------------------------------------
-- NPC helpers
-- ---------------------------------------------------------------------------

-- Greetings that depend on the quest: fn(npc, player) returns text[, topic] or nil (default
-- greeting). The topic is set after the handler resets it (CALLBACK_SET_INTERACTION).
function FS.setGreeter(npcHandler, fn, extraWords)
	local pendingTopic = {}
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature, message)
		local player = Player(creature)
		if not player or not FS.enabled() then
			return true
		end
		local text, topic = fn(npc, player, message)
		if not text then
			return true
		end
		pendingTopic[player:getId()] = topic
		npcHandler:say(npcHandler:parseMessage(text, { [TAG_PLAYERNAME] = player:getName() }), npc, creature)
		return false
	end)
	npcHandler:setCallback(CALLBACK_SET_INTERACTION, function(npc, creature)
		local player = Player(creature)
		if player then
			local topic = pendingTopic[player:getId()]
			pendingTopic[player:getId()] = nil
			if topic then
				npcHandler:setTopic(player:getId(), topic)
			end
		end
		return true
	end)
	if extraWords then
		-- extra greeting words (ashari, ribbit) behave like "hi"
		npcHandler.keywordHandler:addCustomGreetKeyword(extraWords, function(npc, creature, message)
			if npcHandler:checkInteraction(npc, creature) then
				return false -- already talking: the word goes to the NPC's other answers
			end
			npcHandler:onGreet(npc, creature, message)
			return true
		end, { npcHandler = npcHandler })
	end
end

local function say(npcHandler, npc, creature, text)
	if type(text) == "table" then
		local player = Player(creature)
		local parsed = {}
		for i, line in ipairs(text) do
			parsed[i] = npcHandler:parseMessage(line, { [TAG_PLAYERNAME] = player and player:getName() or "" })
		end
		npcHandler:say(parsed, npc, creature)
	else
		local player = Player(creature)
		npcHandler:say(npcHandler:parseMessage(text, { [TAG_PLAYERNAME] = player and player:getName() or "" }), npc, creature)
	end
end
FS.say = say

local function contains(message, ...)
	for _, word in ipairs({ ... }) do
		if MsgContains(message, word) then
			return true
		end
	end
	return false
end
FS.contains = contains

-- ---------------------------------------------------------------------------
-- Eclesius
-- ---------------------------------------------------------------------------
local T = {
	OFFER = 1,
	TASKS = 2,
	SWEEP = 3,
	POLISH = 4,
	FEED = 5,
	FEED_SAY = 6,
	EXTERMINATE = 7,
	PREVENT = 8,
	OIL = 9,
	MISSION = 10, -- a yes/no question of the current mission
	SMELL = 11,
	GET_ON = 12,
	MILK = 13,
	COMMON_Q = 14,
	COMMON = 15,
	WHO_LOVE = 16,
	QUIZ = 20, -- 21-26 the six books, 27 "succeeded?"
	QUIZ_END = 27,
	XODET_WHO = 30,
	KISS = 31,
	TRY = 32,
	GOT_IT = 33,
	SCENE_UP = 40,
}
FS.T = T

FS.taskOffers = {
	sweep = {
		"Yes. Good idea. Take a broom and... huh? No... I don't think I have one, well maybe I do. Or else you could just bring your own, I don't mind. ...",
		"So use that broom on every piece of furniture in my living room and bedroom. I want everything dustfree! No slacking! Come back once you have cleaned everything.",
	},
	polish = {
		"Yes, now that you mention it... it was kind of difficult to see anything in my crystal ball earlier on. I fear I'm out of polish for it though. ...",
		"You're going to have to make some yourself, but I can't remember the recipe... anyway, I'll grant you access to my lab. I think you might find what you need to know there. ...",
		"... if I was considerate enough to write it down somewhere... err, well, thanks in advance!",
	},
	feed = {
		"Aah! That stupid fish! Some days ago... well, maybe some weeks.. or longer ago... err, anyway, a travelling merchant sold it to me. ...",
		"He told me that it was a special fish who could learn to talk if fed the right food. I really want that fish to talk, but unfortunately I always forget to feed it. ...",
		"If you could do that for me, that'd be great. You need to create a certain food for it though. It was... uh... demonic essence? With fish fins? Or something? ...",
		"No... that can't be right. The recipe is very likely pinned to the wall above the fish bowl. You can use the magical blender in my lab to mix it. Much appreciated!",
	},
	exterminate = {
		"I think I have a bat problem in my attic. All that flapping drives me crazy! I can barely sleep anymore and it's not helping my mood either. ...",
		"I want you to help me exterminate the bats in my attic. I will let you enter the attic, but there is one thing you have to pay attention to. ...",
		"DO NOT, you hear me, DO NOT hurt the little white cat in my attic. She helps keep down the number of bats and is also very warm and cuddly when she sits on my lap. ...",
		"So be careful! Come back to me once you've killed three of those dratted bats.",
	},
	prevent = {
		"Well... this is a rather complicated matter. I... er... have a slight problem in my cellar. Some sort of a... vermin problem, yes. ...",
		"I recently conducted a small ritual to help my former assistant regain his human form, but... err... I must have made a small mistake. Could have happened to anyone, really. ...",
		"Erm... in short, there might be a goblin in my cellar. ...",
		"Okay, I admit it. It's a demon. A... demon uberoverlord. Erm. And... while it was still confused from switching worlds, I managed to lock it up in a cage and ran back up the stairs. ...",
		"I... haven't been down there since, but I do know that we really need to keep that cage locked and in good shape. This task is called 'prevent the apocalypse' for a reason. ...",
		"I think we should keep the door lock oiled in any case. I can create a very effective {magical oil} containing a hex if you bring me the proper ingredients. There's a list somewhere in my lab. ...",
		"Also, I have a magical key somewhere in my house. We should... err, you should use it on the lock to make sure it's shut tight. ...",
		"Let me think, what else. I think you should get a wooden hammer and use it on all the wooden barriers just in case a nail is loose. ...",
		"And, hmm, maybe some music would also help calm the demon. He gets quite angry at times, you know. And then I can't sleep because of his roaring. I'm thinking of a lyre. Play a lyre in front of his cage. ...",
		"So, you got all that, right? Get the recipe for the magical oil and bring the ingredients to me, find my key and lock the door, use a wooden hammer on the cage barriers and play a lyre. Ahem. Good luck!",
	},
}

FS.taskQuestions = {
	sweep = "Well, what are you waiting for? Sweep all the furniture in the house! Or are you done already?",
	polish = "Yes! I remember! You were supposed to polish my crystal ball, weren't you? Have you done it yet?",
	feed = "Feed my fish? Oh, right. <scratches head> So... have you fed it?",
	exterminate = "The bats? They have been quiet for a while now. Were you able to kill a few of the pests?",
	prevent = "Did you prevent the apocalypse, my brave assistant?",
}

FS.taskThanks = {
	sweep = "Yes, indeed. Everything looks clean. That was you!? Well, then, thanks for your hard work. I guess you deserve a little payment, but don't get greedy!",
	polish = "You cleaned my crystal ball? Why, that's awfully decent of you. Here's your payment, my hard-working assistant.",
	feed = "What were we just talking about...? Ah yes, the fish. Here's your well-deserved reward! By the way, was the linguistic training fruitful? What did it say?",
	exterminate = "Ah, fantastic. Thus the soothing silence. I can even focus a little right now. Here's your payment!",
	prevent = "Door oiled and locked, wood fixed, prisoner calmed. Very good, we can all live happily, at least for one more day. Here's your reward!",
}

-- ours: "yes" before the task is done
FS.taskNotYet = {
	sweep = "Really? I still see dust on some of my furniture. Sweep every piece in the living room, the room behind the sealed door and my bedroom!",
	polish = "Hm, really? The crystal ball still looks rather blurry to me. Melt some wax, make the polish and use it on the crystal ball in my bedroom.",
	feed = "Hm, the fish still looks rather hungry to me. The recipe is pinned to the wall above the fish bowl.",
	exterminate = "Then why do I still hear all that flapping? Three bats, my dear assistant, three!",
	prevent = "Hmm, I'm not so sure. Oil the lock, lock it with my magical key, fix all wooden barriers with a wooden hammer and play a lyre in front of the cage!",
}

FS.taskNo = {
	sweep = "Then off with you! The dust won't sweep itself.", -- ours
	polish = "Then what are you waiting for? My crystal ball needs you!", -- ours
	feed = "The poor fish! Hurry up, it might be learning to talk right now!", -- ours
	exterminate = "Then go up to the attic and do it! And mind the cat!", -- ours
	-- TibiaWiki: an Eclesius line (upstream's "prevent" keyword)
	prevent = "What's wrong? Are you afraid to go down there? There's absolutely no reason for that. Me? Erm... my knees, you know. Stairs are such a trial for me. Go on! Secure the cage and calm the demon!",
}

FS.hints = {
	"The book in the middle of the room is about counter spells.",
	"The book about conversions is not blue.",
	"The Great Encyclopedia is actually not a large book, nor is it green.",
	"The book near the broken bottle is not written by a professor.",
	"The light green book is written by a woman.",
	"The book about grass growth doesn't have the colour you'd guess.",
}

FS.books = {
	{ "the 'Great Encyclopedia of the Magiverse'", "light blue" },
	{ "'Necromancing at its Most Romantic'", "light green" },
	{ "the 'Collection of Counterspells against Counterspells'", "brown" },
	{ "'Interesting Trivia about Grass Growth'", "red" },
	{ "'Mathemagics for Dummies and Forgetful People'", "dark blue" },
	{ "'How to Transmute Gold into Lead and Other Useful Conversions'", "dark green" },
}
FS.colours = { "light blue", "dark blue", "light green", "dark green", "red", "brown" }

FS.fragrances = {
	blueberry = {
		what = "blueberries",
		words = { "blueberry", "blueberries" },
		lines = {
			"Fresh fruit! That's a delicious idea! My favourite fruits are blueberries. Can you use the sandals on blueberries for me? Be very careful not to mash them though. ...",
			"I don't want to have purple stains on my brand-new sandals, if possible. Shh, don't question my plan. It'll work out great!",
		},
		targets = { 3588, 3699 }, -- blueberries, blueberry bush with berries
		message = "The sweet smell of fresh blueberries fills the air. And hopefully also sticks to the shoes.", -- ours
	},
	bread = {
		what = "a loaf of fresh bread",
		words = { "bread" },
		lines = {
			"Mhh, the smell of fresh bread! What a splendid idea! Yes, let's do that. In fact, you do it. Use the sandals on a loaf of fresh bread so they can soak up the fragrance. ...",
			"And try not to leave any crumbs in my shoes, please. Shh, don't question my plan. It'll work out great!",
		},
		targets = { 3600 },
		message = "The smell of fresh bread fills the air. And hopefully also sticks to the shoes.", -- ours
	},
	flower = {
		what = "a white flower",
		words = { "flower", "flowers" },
		lines = {
			"Aha! Great minds think alike! And I'm thinking of... a white flower. Not to be confused with the dew kisser flowers near my house! They are white also, but I mean a white flower that's also simply called white flower. ...",
			"Unfortunately I've forgotten where they grow, but I think there are some not too far from here. Use the sandals on a white flower so they can soak up the fragrance. Shh, don't question my plan. It'll work out great!",
		},
		targets = { 102, 3656 },
		message = "The sweet fragrance of white flowers fills the air. And hopefully also sticks to the shoes.",
	},
	cookie = {
		what = "a cookie",
		words = { "cookie", "cookies" },
		lines = {
			-- ours (TibiaWiki BR: cookies work too, no line)
			"Cookies! Freshly baked cookies smell wonderful. Yes, let's do that. Use the sandals on a cookie so they can soak up the fragrance. ...",
			"And don't you dare eat it afterwards. Shh, don't question my plan. It'll work out great!",
		},
		targets = { 3598 },
		message = "The sweet smell of cookies fills the air. And hopefully also sticks to the shoes.", -- ours
	},
}
FS.fragranceOrder = { "blueberry", "bread", "flower", "cookie" }

function FS.greetEclesius(npc, player)
	FS.refresh(player)
	local m = FS.mission(player)
	if npc:getPosition().z ~= 7 then
		-- the Eclesius of the laboratory scene
		if m == M.SCENE then
			return "Ah, there you are. I hope your journey was safe and hasn't cost you any body parts. Now, muahaha, the best part of my plan! Are you listening?", T.MISSION
		elseif m == M.RESULT then
			return "Oh. OH. Is that... the result...?", T.MISSION
		end
		return "Err... what are you doing down here? Go back upstairs!" -- ours
	end
	if not FS.isAssistant(player) then
		if player:getLevel() >= 20 then
			return "Hey, you! Even though you already seem a bit old, I think I could use your help. Due to an... err... unfortunate incident I need a new assistant to do some ridiculously easy and tremendously well paid tasks for me. Are you interested?", T.OFFER
		end
		return "Hey, you! You look young and eager. Due to an... err... unfortunate incident I need a new assistant to do some ridiculously easy and tremendously well paid tasks for me. Are you interested?", T.OFFER
	end
	if m >= M.MEMORY_DONE then
		return "Oh, welcome back, |PLAYERNAME|, my most appreciated assistant! I hope you're here for your {task} or a {mission}."
	end
	return "Oh, welcome back, my most valued assistant! I have got some {tasks} for you, and maybe also a real {mission} or two! Uh... what was your name again?", T.TASKS
end

local function hasAll(player, list)
	for _, entry in ipairs(list) do
		local count = entry.subType and player:getItemCount(entry.id, entry.subType) or player:getItemCount(entry.id)
		if count < (entry.count or 1) then
			return false
		end
	end
	return true
end

local function removeAll(player, list)
	for _, entry in ipairs(list) do
		if entry.subType then
			player:removeItem(entry.id, entry.count or 1, entry.subType)
		else
			player:removeItem(entry.id, entry.count or 1)
		end
	end
end

FS.oilIngredients = {
	{ id = 2874, subType = FLUID_OIL }, -- vial of oil
	{ id = 3114 }, -- skull
	{ id = 3585 }, -- red apple
	{ id = 5897 }, -- wolf paw
}

-- green tapestry: the item (2647) or the two wall forms (2645-2646)
local function greenTapestry(player)
	for _, id in ipairs({ 2647, 2645, 2646 }) do
		if player:getItemCount(id) > 0 then
			return id
		end
	end
end

local function counterspellReady(player)
	return player:getItemCount(3054) > 0 and player:getItemCount(3267) > 0 and greenTapestry(player) and player:getItemCount(3147) > 0 and player:getItemCount(3105) > 0
end

local quizAnswers = {}

local function startTask(npc, creature, player, npcHandler, task)
	local state = FS.taskState(player, task)
	if state == FS.FREE then
		FS.setTask(player, task, FS.ACTIVE)
		local kv = FS.kv(player)
		if task == "sweep" then
			kv:set("sweep", 0)
			if FS.onSweepTaken then
				FS.onSweepTaken()
			end
		elseif task == "exterminate" then
			kv:set("bats", 0)
		elseif task == "prevent" then
			kv:set("prevent", 0)
			kv:set("planks", 0)
		end
		say(npcHandler, npc, creature, FS.taskOffers[task])
		npcHandler:setTopic(player:getId(), 0)
	elseif state == FS.REPORTED then
		say(npcHandler, npc, creature, "You already did that today, didn't you? Or was that yesterday? Anyway, come back tomorrow - if I still remember it then.") -- ours
		npcHandler:setTopic(player:getId(), 0)
	elseif state == FS.FAILED then
		say(npcHandler, npc, creature, "You... you hurt my little cat!! I won't let you near my attic again today. Shoo!") -- ours
		npcHandler:setTopic(player:getId(), 0)
	else
		say(npcHandler, npc, creature, FS.taskQuestions[task])
		npcHandler:setTopic(player:getId(), T[task:upper()])
	end
	return true
end

local function finishTask(npc, creature, player, npcHandler, task)
	if FS.taskState(player, task) ~= FS.READY then
		say(npcHandler, npc, creature, FS.taskNotYet[task])
		npcHandler:setTopic(player:getId(), 0)
		return true
	end
	FS.setTask(player, task, FS.REPORTED)
	local reward = FS.taskReward[task]
	FS.reward(player, reward[1], reward[2])
	say(npcHandler, npc, creature, FS.taskThanks[task])
	npcHandler:setTopic(player:getId(), task == "feed" and T.FEED_SAY or 0)
	return true
end

-- the laboratory scene (scripts/family/scatterbrained_sorcerer.lua sets these)
-- FS.startScene(player) -> true when the player was taken down
-- FS.endScene(player, takeUp)

local function missionOffer(npc, creature, player, npcHandler)
	local m = FS.mission(player)
	local id = player:getId()
	local function ask(text)
		say(npcHandler, npc, creature, text)
		npcHandler:setTopic(id, T.MISSION)
		return true
	end
	local function tell(text)
		say(npcHandler, npc, creature, text)
		npcHandler:setTopic(id, 0)
		return true
	end

	if m == 0 then
		return ask({
			"Well, now that you mention it, there is in fact something you could do for me apart from your usual tasks. It's all because of that fool! ...",
			"I can't remember who it was, but someone ruined my favourite hat which used to complete my favourite outfit. It's totally dented! Also there are some suspicious stains on it. It is out of the question for me to wear it in that state!! ...",
			"So I guess I need a new hat. And while we're at it, I want it to be kind of stylish. Also manly. Not pink! And, uh, not too heavy. But since you're my assistant, I'll leave all that up to you. Hehe. ...",
			"Unfortunately I'm not good at sewing, so you might need to find a tailor. I heard they have a large warehouse for clothing in {Venore}. Maybe you can find someone there who could help you with the hat. Will you take on this mission?",
		})
	elseif m == M.HAT_ASKED then
		local I = FS.items
		if player:getItemCount(I.hatDark) + player:getItemCount(I.hatPink) + player:getItemCount(I.hatWooden) > 0 then
			return ask("Oh wow. A hat, you say? You've actually brought me a new hat?! How did you know I wanted one? That's almost sweet of you <sniff>. Can I see it?")
		end
		return tell("A new hat... yes, that's what I need! Stylish, manly, not pink and not too heavy. Maybe a tailor in Venore can help you.") -- ours
	elseif m == M.HAT_DONE then
		return ask({
			"Just this morning I noticed a truly horrible smell. It's possible that I have already noticed it several times before and have forgotten it again, but this smell is really very persistent. ...",
			"Embarrassingly, it comes from... my own feet. <sigh> Those sandals I wear have seen their best days. I could really use a new pair. Impregnated with an anti-smelly-feet-hex. ...",
			"Could you get me a pair of sandals? I'm sure that, together, we can solve this problem. Do you have some time spare for this mission?",
		})
	elseif m == M.SANDALS_ASKED then
		return ask("I haven't forgotten a single word I told you. Sandals! Did you bring me a pair?")
	elseif m >= M.SANDALS_GIVEN and m <= M.FRAGRANT and player:getItemCount(FS.items.eclesiusSandals) == 0 then
		FS.setMission(player, M.SANDALS_ASKED)
		return tell("What? You lost my sandals?! Didn't I tell you not to lose them? Now we'll have to start over with everything. Bring me a new pair of sandals!") -- ours
	elseif m == M.SANDALS_GIVEN then
		return tell("Just use them on the cauldron and then come back. And don't {lose my sandals}! Or else we'll have to start over with everything.")
	elseif m == M.BOILED then
		FS.setMission(player, M.SKUNK_ASKED)
		return tell({
			"You did what?! You put sandals into my cauldron? Oh no! My soup!! I forgot that I was actually preparing dinner. But... oh well. I guess they are clean now. And tasty. Now, for the second step of the process. ...",
			"For the anti-smell-hex, we're going to confront those sandals with a worst-case-scenario. Hehe. I suggest you use them on the fresh corpse of a skunk.. ...",
			"Where can you find skunks, you say? Hum. I think some have made their home in the jungle near Port Hope. Or if you're scared of that, a summoned skunk would probably do the trick too. ...",
			"NO, I can't do the summoning! I don't want to have the smell anywhere near me. Now go, go!",
		})
	elseif m == M.SKUNK_ASKED then
		return tell("Use the sandals on the fresh corpse of a skunk! And keep that smell away from me, please.") -- ours
	elseif m == M.SKUNKED then
		FS.setMission(player, M.FRAGRANCE_ASKED)
		say(npcHandler, npc, creature, {
			"Eww! What's... what's that unbearable stench on you? Is that you?? Oh dear... you really should shower more often, you smell like dead skunk! Oh, now I remember! Ehem. ...",
			"Now that we have impregnated the sandals with a really bad smell, we should counter that with a really good smell. Hm. Just wondering what that might be. Can you think of anything that smells really delicious?",
		})
		npcHandler:setTopic(id, T.SMELL)
		return true
	elseif m == M.FRAGRANCE_ASKED then
		say(npcHandler, npc, creature, "We have to counter that stench with a really good smell. Can you think of anything that smells really delicious?") -- ours
		npcHandler:setTopic(id, T.SMELL)
		return true
	elseif m == M.FRAGRANCE_CHOSEN then
		local f = FS.fragrances[FS.kv(player):get("fragrance") or "flower"] or FS.fragrances.flower
		return tell("Use the sandals on " .. f.what .. " so they can soak up the fragrance. Shh, don't question my plan. It'll work out great!") -- ours
	elseif m == M.FRAGRANT then
		return ask("Mmmh... what's that infatuating smell? I can't tell exactly what it smells like, but really, it's delicious. Ahh yes, the anti-smell-hex, I remember! It seems to have worked! Can I have my sandals now, please?")
	elseif m == M.SANDALS_DONE then
		return ask({
			"It's time to involve you in my plan. Muahaha. I plan on becoming a God! ...",
			"Well, something similar. I want to create a whole new Tibian race! A race that will be both strong and lean, skilled and robust. And they will all serve me. ...",
			"So far my plan. I was thinking that the traits of elves and dwarfs combined would make a really superior being. Just imagine the possibilities! There's one slight problem though. ...",
			"Dwarfs and elves hate each other. There's probably no way they'd voluntarily... well, ehem, cooperate in the creation of this superior new race. So we have to work our magic! Well, you will have to work my magic on my behalf. Hehe. ...",
			"My idea is to turn you into a dating agent. You will have to travel to Kazordoon and Ab'Dendriel and find me a dwarf and an elf - of course of different gender - who seem to be interested in a relationship. ...",
			"Convince them to take part in a dating program and to hand you a personal item we can use for their partner search. Once you've done so, come back to me and we will continue our plan! Will you take on this mission?",
		})
	elseif m == M.DATING_ASKED then
		return ask("Yes, I remember my plan very well! I take it you have found a lonely dwarf and a lonely elf for our dating game?")
	elseif m == M.QUESTIONNAIRE then
		say(npcHandler, npc, creature, "Wait, wait, I know you. I also know what you wanted from me. Errrm... ah yes! The milk delivery! Right?")
		npcHandler:setTopic(id, T.MILK)
		return true
	elseif m == M.COMMON_FOUND then
		return ask({
			"You'll probably be flabbergasted to hear that I've already prepared the basic love potion while you were gone. You thought you would have to gather ingredients now, right? Hehehe. ...",
			"Sometimes I just love surprises! I'll give you two doses. Try to get each of our little, erm, love birds to drink it. And then run away very fast before the potion takes effect! ...",
			"Trust me, you don't want to be the first person they see, plus you'll ruin the experiment. Just come back to me once we're done and I'll take care of the rest. ...",
			"Are you ready?",
		})
	elseif m == M.POTIONS then
		local kv = FS.kv(player)
		local needed = (kv:get("amarieDrunk") and 0 or 1) + (kv:get("grodrikDrunk") and 0 or 1)
		local have = player:getItemCount(FS.items.lovePotion)
		if have < needed then
			player:addItem(FS.items.lovePotion, needed - have)
			return tell("You lost the love potion?! Good thing I made some more. Here, and be more careful this time!") -- ours
		end
		return tell("Did our little love birds drink the potion yet? Tell them it's something they like - and then RUN!") -- ours
	elseif m == M.BOTH_DRUNK then
		say(npcHandler, npc, creature, "WUAH! You ruined it! You blew it! I can see it in your eyes! Noooo! Who fell in love with you?? The dwarf, the elf, or even both??")
		npcHandler:setTopic(id, T.WHO_LOVE)
		return true
	elseif m == M.BONUS or m == M.SCENE then
		if m == M.SCENE then
			FS.setMission(player, M.BONUS)
		end
		return ask({
			"I have just noticed a very small flaw in my plan. Our subjects need to meet each other, and that rather fast. But a dwarf would never visit Ab'Dendriel, nor would an elf go to Kazordoon. ...",
			"So we need to get them here! I just happen to have a small crack in the space-time continuum under my house. Once you are ready, we will both go there and summon forth our subjects. Are you prepared?",
		})
	elseif m == M.RESULT then
		return tell("Oh. That... thing. Let's not talk about it. Go back down and talk to me there, I'll take care of it.") -- ours (the scene ended early)
	elseif m == M.BACK then
		FS.setMission(player, M.DATING_DONE)
		FS.reward(player, 750, 2500)
		return tell({
			"The dwarf and the elf will hopefully not remember what happened. And neither will I - hopefully - in a day or too. Sometimes I'm glad that my memory is like a sieve! ...",
			"Well anyhow, you deserve a reward for all that talking and convincing you did, so here you go.",
		})
	elseif m == M.DATING_DONE then
		FS.setMission(player, M.BOOKS_ASKED)
		return tell({
			"I thought that your legs could use a little break after having done all that travelling. So let's do something for your brain instead. ...",
			"See how much I care for my assistants? An almost altruistic task which will even make you a little smarter - maybe. I'm sure you've seen all those books lying around in my library. ...",
			"Your job is to tell me the colour of each book, one after another. I'll ask you for the colours. If you need {hints}, you can also ask me and I'll give you a random hint. ...",
			"Don't blame me if I repeat myself! There are six different hints in total. Once you are ready and have a vague idea of the answers, ask me about your {mission}.",
		})
	elseif m == M.BOOKS_ASKED then
		quizAnswers[id] = {}
		say(npcHandler, npc, creature, "There are the following colours: {red}, {brown}, {light blue}, {dark blue}, {light green} and {dark green}. So, what colour is " .. FS.books[1][1] .. "?")
		npcHandler:setTopic(id, T.QUIZ + 1)
		return true
	elseif m == M.BOOKS_DONE then
		return ask({
			"I feel depressed... sigh. Although I always try to see the positive side of not being able to remember things very well, there is a dark side to it as well. ...",
			"It might be comfortable to forget about accidents and sad incidents, but I also forget about the happy events. I can't even remember whether I got a present for my birthday and if I did, what it was. ...",
			"I have the most brilliant ideas - at least, I think I do - but the next day I have forgotten them completely. Last night, while I was sitting in Frodo's tavern, I think I had one of the best ideas ever. ...",
			"I had it all in my head - the formula for a potion which would stimulate my memory and keep it active! But - I can't remember it anymore. The only thing I vaguely remember is that I told it to someone. ...",
			"But I can't remember who that was either! That's the crux of the whole matter. I wish you could help me with this. ...",
			"Maybe you can find out who I talked to last night in Frodo's tavern, and maybe that person will remember the formula for the potion. Could you please try to figure that out for me?",
		})
	elseif m == M.MEMORY_ASKED then
		return tell("Have you found out who I talked to last night in Frodo's tavern? Maybe Frodo remembers. Or someone else does. I certainly don't.") -- ours
	elseif m == M.XODET_FOUND then
		say(npcHandler, npc, creature, "You look as if you have found something out. Have you? Who did I talk to??")
		npcHandler:setTopic(id, T.XODET_WHO)
		return true
	elseif m == M.WAND_ASKED then
		return tell("Did you find Xodet's first wand? Maybe it's somewhere in his house. Show it to him, I'm sure he'll remember what we shared.") -- ours
	elseif m == M.FORMULA then
		return ask("Oh! Were you successful and have you convinced Xodet to hand over the formula?")
	elseif m == M.MEMORY_DONE then
		return ask({
			"Aarghh! What have I done! My head is spinning! |PLAYERNAME|, I just drank a sip of my potion... and it works. I'm just not sure whether that is a good or a bad thing. ...",
			"Right now, my memory is very clear and I remember everything... oh dear... my poor assistant! ... No, not you, my previous assistant. Maybe you've seen the little frog in the cellar. ...",
			"Oh no, the cellar! I left him in the company of the demon! Aarghh! My poor poor assistant! We have to save him! ...",
			"I also remember there's something commonly used to turn frogs back into humans... you know what I mean? A kiss! We need a princess to kiss him, or something like that. ...",
			"The problem is you're far from being a princess. Oh, that's not an insult. Princesses are usually lazy, whiny and demand to be saved all the time while hiding in the last place you would think of looking for them. ...",
			"I guess Tibia is currently out of princesses though after the sad fate of Princess Lumelia... but! Queen Eloise was a princess once. I wonder if she still has some of her outfits from when she was a princess. ...",
			"You know what we are going to do? Err, I mean, what you are going to do? You are going to sneak into the castle of Carlin and see if you can find some of those clothes. Maybe a fake princess will do the trick. Agreed?",
		})
	elseif m == M.FROG_ASKED or m == M.RAGS then
		return ask("Have you got some of Queen Eloise's clothes?")
	elseif m == M.KISS_ASKED then
		return tell("Go down into the cellar, put on Queen Eloise's clothes and kiss my assistant! I'm very optimistic that this will work!") -- ours
	elseif m == M.KISSED then
		say(npcHandler, npc, creature, "You're back! Did the kiss work?")
		npcHandler:setTopic(id, T.KISS)
		return true
	elseif m == M.INGREDIENTS_ASKED then
		return ask("So, do you have a silver amulet, a dagger, a green tapestry, a blank rune and a dirty fur with you?")
	elseif m == M.COUNTERSPELL then
		return ask({
			"Tadaaaaa - the counterspell is ready. Actually you just need to pronounce it in front of my poor assistant and his shape should go back to normal. The spell goes as follows: ...",
			"'Eeny, meeny, miny, moe - ribbit, ribbit head to toe!' That's what you are going to say. I err... stay here. Not that it's necessary! But... just in case. Did you understand that?",
		})
	elseif m == M.SPELL_ASKED then
		return tell("Go down to my poor assistant and say: 'Eeny, meeny, miny, moe - ribbit, ribbit head to toe!' I'll... stay here. Just in case.") -- ours
	elseif m == M.SPOKEN then
		FS.setMission(player, M.HUMAN_ASKED)
		return tell("I see... so my assistant can communicate in the human language again? That's... interesting. I wonder if maybe you could ask him if he has an idea how to get his {human} form back.")
	elseif m == M.HUMAN_ASKED then
		return tell("Did you ask my poor assistant how he could get his human form back?") -- ours
	elseif m == M.HUMAN_ANSWERED then
		return ask({
			"Oh... that's a most interesting turn of events. He wants to stay a frog?! Well, usually I'd say, no problem and all that, but then we have to get him out of my cellar. ...",
			"You know that I'm a paranoid person and I wonder if he still holds a grudge against me... I can't just let him out of the cage and have him walk around my living room. ...",
			"But I have a better idea. Try to find out which pond he'd like to live in, and then go to that special pond and find a frog that is living there. ...",
			"We'll just do a body exchange, easy as that! I also happen to know a magic formula for that special task. It goes like this: ...",
			"'Eeny, meeny, miny, moe - I stay here and you will go!' As soon as you have found a frog at my ex-assistant's pond of preference, recite that spell to him. And hopefully... no, most likely! - it will work. ...",
			"Did you get all that?",
		})
	elseif m == M.POND_ASKED then
		return tell("Find out which pond my poor assistant likes and recite the spell to a frog there: 'Eeny, meeny, miny, moe - I stay here and you will go!'") -- ours
	elseif m == M.SWAPPED then
		FS.setMission(player, M.FROG_DONE)
		FS.reward(player, 750, 2000)
		return tell({
			"You did it! Thank you! Wow, who'd have thought that you'd have become such a useful and skilled assistant. Now I can sleep with a clear conscience again. ...",
			"Well, except for the demon. And the other frog who is now trapped in the cage. And some other stuff... but that shouldn't bother you. You've been a great help to me. Thanks again!",
		})
	elseif m >= M.FROG_DONE then
		return tell("You've already done so much for me, my dear assistant. But my {tasks} still need doing every day, you know!") -- ours
	end
	return tell("A mission? Hmm. Let me think about that later.") -- ours
end

-- "yes" to the current mission question
local function missionYes(npc, creature, player, npcHandler)
	local m = FS.mission(player)
	local id = player:getId()
	local I = FS.items
	npcHandler:setTopic(id, 0)
	local function tell(text)
		say(npcHandler, npc, creature, text)
		return true
	end

	if m == 0 then
		FS.setMission(player, M.HAT_ASKED)
		return tell("<claps hands> How splendid! ... What was it again? Uhm... I can't remember right now, but I feel happy anyway. Just surprise me with whatever you have planned. Hehe.")
	elseif m == M.HAT_ASKED then
		if player:getItemCount(I.hatDark) > 0 then
			player:removeItem(I.hatDark, 1)
			FS.setMission(player, M.HAT_DONE)
			FS.reward(player, 1000, 2000)
			return tell("Ooooh... it's wonderful... it's perfect even! I love it! Here's your reward! You are my number one favourite assistant! Until I forgot why, that is...")
		elseif player:getItemCount(I.hatPink) > 0 then
			return tell("PINK?! I said NOT PINK! What would the other sorcerers say? Take it away and bring me something manly!") -- ours
		elseif player:getItemCount(I.hatWooden) > 0 then
			return tell("A wooden hat? It's far too heavy! My poor neck. No, no, I want something stylish and light.") -- ours
		end
		return tell("Hm? Where is it? I don't see any hat.") -- ours
	elseif m == M.HAT_DONE then
		FS.setMission(player, M.SANDALS_ASKED)
		return tell("Okay, fine! Huh? Where to get sandals from? You could consider hunting elves. Or... just find a shoemaker somewhere. I'll wait for you here, It would be socially irresponsible of me to inflict this smell on the general public!")
	elseif m == M.SANDALS_ASKED then
		if player:getItemCount(I.sandals) == 0 then
			return tell("Hm? These are not sandals. I need a pair of sandals!") -- ours
		end
		player:removeItem(I.sandals, 1)
		player:addItem(I.eclesiusSandals, 1)
		FS.setMission(player, M.SANDALS_GIVEN)
		return tell({
			"Yes, that's good quality. Wait, let me put my name on them! There's still a few things to be done before I can wear them though. Remember, the anti-smelly-feet-hex I told you about? You probably don't, but that doesn't matter. I'm patient. ...",
			"The first thing we need to do is disinfect them in boiling water to get rid of all those germs. I suggest you use the large cauldron in my lab since the water there also contains some magical essences. ...",
			"Just use them on the cauldron and then come back. And don't {lose my sandals}! Or else we'll have to start over with everything.",
		})
	elseif m == M.FRAGRANT then
		if player:getItemCount(I.eclesiusSandals) == 0 then
			FS.setMission(player, M.SANDALS_ASKED)
			return tell("What? You lost my sandals?! Now we'll have to start over with everything. Bring me a new pair of sandals!") -- ours
		end
		player:removeItem(I.eclesiusSandals, 1)
		FS.setMission(player, M.SANDALS_DONE)
		FS.reward(player, 500, 2000)
		return tell("I'm very pleased, very pleased indeed. Thank you, my dear assistant. I'm sure we will suffer a lot less from now on. At least, as far as our olifactory senses are concerned. I mean of course, as regards the smell.")
	elseif m == M.SANDALS_DONE then
		FS.setMission(player, M.DATING_ASKED)
		return tell("Good. Don't forget, travel to Kazordoon and Ab'Dendriel and find me a lonely dwarf and a lonely elf. Talk them into taking part in the dating program! And bring something personal back from them!")
	elseif m == M.DATING_ASKED then
		local book, axe = player:getItemCount(I.amarieBook) > 0, player:getItemCount(I.grodrikAxe) > 0
		if not (book and axe) then
			-- ours
			if book then
				return tell("An elf, very good! But where is the dwarf? I need a personal item from both of them!")
			elseif axe then
				return tell("A dwarf, very good! But where is the elf? I need a personal item from both of them!")
			end
			return tell("Hm? But you haven't brought me anything personal from them! Travel to Kazordoon and Ab'Dendriel and talk them into our dating program!")
		end
		player:removeItem(I.amarieBook, 1)
		player:removeItem(I.grodrikAxe, 1)
		FS.setMission(player, M.QUESTIONNAIRE)
		local kv = FS.kv(player)
		kv:set("variant", math.random(1, FS.VARIANTS))
		kv:set("askedAmarie", 0)
		kv:set("askedGrodrik", 0)
		say(npcHandler, npc, creature, "And you've also brought a personal item from each of them. Very, very good, let me take them and put them here, yes. Hehe. What do you think, based on their personalities, could the dwarf and elf in question get on with each other?")
		npcHandler:setTopic(id, T.GET_ON)
		return true
	elseif m == M.COMMON_FOUND then
		player:addItem(I.lovePotion, 2)
		FS.setMission(player, M.POTIONS)
		local kv = FS.kv(player)
		kv:remove("amarieDrunk")
		kv:remove("grodrikDrunk")
		return tell("Be prepared to do some convincing, but don't use force. Teehee. And remember to RUN once they've drunk it!")
	elseif m == M.BONUS or m == M.SCENE then
		if npc:getPosition().z == 7 then
			if FS.startScene and FS.startScene(player, npc) then
				return tell("Space-time continuum, here we come!")
			end
			return tell("Hmm, the crack in the space-time continuum seems to be busy right now. Let's try again in a moment.") -- ours
		end
		-- the Eclesius of the laboratory: "Are you listening?"
		FS.setMission(player, M.SCENE)
		FS.kv(player):set("sceneListening", 1)
		return tell({
			"<goes on excitedly> Do you see these three levers? I have decided I don't want to leave our subjects' fate to coincidence. The left and the right lever summon our dwarf and elf. ...",
			"The lever in the middle will create the first specimen of the - tadaaa - Dwelves! Now, first pull the left lever, then the right lever, and once both subjects are there, the one in the middle. ...",
			"Don't mess this up! I... err.. will wait here at a safe distance.",
		})
	elseif m == M.RESULT then
		say(npcHandler, npc, creature, {
			"I think... we should forget about this whole mess posthaste. I'll... erm... clean up the memories of these subje-... erm... people and send them home. ...",
			"And we'll get out of here too. Ready to go up?",
		})
		npcHandler:setTopic(id, T.SCENE_UP)
		return true
	elseif m == M.BOOKS_DONE then
		FS.setMission(player, M.MEMORY_ASKED)
		return tell("You wouldn't believe how thankful I am. I might seem confused or egocentric sometimes, but really, I appreciate your help a lot. I hope you're successful!")
	elseif m == M.XODET_FOUND then
		FS.setMission(player, M.WAND_ASKED)
		return tell("Thank you. I hope you find it! I know it might be hard to get into his house, but I believe it's for the greater good. And for my good, of course.")
	elseif m == M.FORMULA then
		if player:getItemCount(I.formula) == 0 then
			return tell("Then where is it? Without the formula I can't brew anything!") -- ours
		end
		player:removeItem(I.formula, 1)
		FS.setMission(player, M.MEMORY_DONE)
		FS.reward(player, 500, 1000)
		return tell("Thank you! Really, I mean it. I will start to brew the potion immediately. This one is a little too important to be done by my assistant, I'm sure you understand. Thanks again!")
	elseif m == M.MEMORY_DONE then
		FS.setMission(player, M.FROG_ASKED)
		return tell("Fine, then off with you and good luck. Me and my poor assistant will be waiting.")
	elseif m == M.FROG_ASKED or m == M.RAGS then
		if player:getItemCount(I.rags) == 0 then
			return tell("Really? I don't see any clothes. Sneak into the castle of Carlin and find some!") -- ours
		end
		FS.setMission(player, M.KISS_ASKED)
		return tell("Great! Then I suggest we - err, you, go down into the cellar, put on these clothes and kiss my assistant. I'm very optimistic that this will work! Go right ahead!")
	elseif m == M.INGREDIENTS_ASKED then
		if not counterspellReady(player) then
			return tell("Hm, no. I need a silver amulet, a dagger, a green tapestry, a blank rune and a dirty fur - all of them at the same time!") -- ours
		end
		player:removeItem(3054, 1)
		player:removeItem(3267, 1)
		player:removeItem(greenTapestry(player), 1)
		player:removeItem(3147, 1)
		player:removeItem(3105, 1)
		FS.setMission(player, M.COUNTERSPELL)
		return tell("Ahh, thanks! With these I will develop a very potent counterspell. Give me just a short time and we can continue.")
	elseif m == M.COUNTERSPELL then
		FS.setMission(player, M.SPELL_ASKED)
		return tell("Then... good luck! And err, just in case, thank you very much for your great work so far, I have grown rather fond of you. And I'd miss you should anything happen. Which it won't. Of course.")
	elseif m == M.HUMAN_ANSWERED then
		FS.setMission(player, M.POND_ASKED)
		return tell("Okay, so... good luck again! Which you... of course... won't really need, because everything is planned well. Yes. No luck required.")
	end
	return tell("Yes? Yes what? I forgot what I asked.") -- ours
end

-- Eclesius' dialogue. Returns true when handled.
function FS.eclesiusSay(npc, creature, message, npcHandler)
	if not FS.enabled() then
		return false
	end
	local player = Player(creature)
	if not player then
		return false
	end
	FS.refresh(player)
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	local m = FS.mission(player)
	local msg = message:lower()

	-- not an assistant yet
	if not FS.isAssistant(player) then
		if contains(msg, "yes") then
			player:setStorageValue(S.Questline, 1)
			player:addExperience(100, true)
			FS.refresh(player)
			say(npcHandler, npc, creature, "Really? Err, I mean, of course no sane young adventurer could resist that offer! Good, good! You can drop by every day and do some easy {tasks} and {missions} for me. You can start right away!")
			npcHandler:setTopic(id, 0)
			return true
		elseif contains(msg, "no") and topic == T.OFFER then
			say(npcHandler, npc, creature, "Hmph. Your loss! Well, if you change your mind, just tell me.") -- ours
			npcHandler:setTopic(id, 0)
			return true
		elseif contains(msg, "task", "tasks", "mission", "missions", "assistant") then
			say(npcHandler, npc, creature, "First things first. Do you want to become my assistant? Ridiculously easy and tremendously well paid tasks, I promise!") -- ours
			npcHandler:setTopic(id, T.OFFER)
			return true
		end
		return false
	end

	-- the laboratory scene: "Ready to go up?"
	if topic == T.SCENE_UP then
		if contains(msg, "yes") then
			npcHandler:setTopic(id, 0)
			say(npcHandler, npc, creature, "Let's go.")
			if FS.endScene then
				FS.endScene(player, true)
			end
			return true
		end
	end

	-- answers to open questions
	if topic >= T.SWEEP and topic <= T.PREVENT and topic ~= T.FEED_SAY then
		local task = ({ [T.SWEEP] = "sweep", [T.POLISH] = "polish", [T.FEED] = "feed", [T.EXTERMINATE] = "exterminate", [T.PREVENT] = "prevent" })[topic]
		if contains(msg, "yes") then
			return finishTask(npc, creature, player, npcHandler, task)
		elseif contains(msg, "no") then
			say(npcHandler, npc, creature, FS.taskNo[task])
			npcHandler:setTopic(id, 0)
			return true
		end
	elseif topic == T.FEED_SAY then
		npcHandler:setTopic(id, 0)
		say(npcHandler, npc, creature, "Hum, is that so... well I guess we'll just feed it again later to enhance its wonderful ability.")
		return true
	elseif topic == T.OIL then
		npcHandler:setTopic(id, 0)
		if contains(msg, "yes") then
			if not hasAll(player, FS.oilIngredients) then
				say(npcHandler, npc, creature, "Hm, no, something's missing. The list of ingredients is in my lab, near the empty pot.") -- ours
				return true
			end
			removeAll(player, FS.oilIngredients)
			player:addItem(FS.items.magicalOil, 1)
			say(npcHandler, npc, creature, "Alakaz... erm... Kazordoon? Uhm... A-la-ka-<COUGH>! Here it is! Magical oil for the cage door.")
			return true
		elseif contains(msg, "no") then
			say(npcHandler, npc, creature, "Then go and find the recipe. It's somewhere in my lab, I think.") -- ours
			return true
		end
	elseif topic == T.MISSION then
		if contains(msg, "yes") then
			return missionYes(npc, creature, player, npcHandler)
		elseif contains(msg, "no") then
			npcHandler:setTopic(id, 0)
			say(npcHandler, npc, creature, "Hmm. Then maybe some other time.") -- ours
			return true
		end
	elseif topic == T.SMELL then
		for _, key in ipairs(FS.fragranceOrder) do
			local f = FS.fragrances[key]
			if contains(msg, unpack(f.words)) then
				FS.kv(player):set("fragrance", key)
				FS.setMission(player, M.FRAGRANCE_CHOSEN)
				say(npcHandler, npc, creature, f.lines)
				npcHandler:setTopic(id, 0)
				return true
			end
		end
		say(npcHandler, npc, creature, "Hmm, no, that doesn't sound delicious enough. Think of something that really smells good!") -- ours
		return true
	elseif topic == T.GET_ON then
		if contains(msg, "yes") then
			say(npcHandler, npc, creature, {
				"Really? How surprising. That should make things a lot easier for us. But just to make sure how highly concentrated our love potion - yes, we are going to brew one - has to be, let's do a small questionaire with them. ...",
				"Go into my library. I think... somewhere around there you should be able to find a parchment with some sample questions on it. Ask both the dwarf and the elf the questions and see if they have ANYTHING in common. That should give us a base to start from.",
			})
			npcHandler:setTopic(id, 0)
			return true
		elseif contains(msg, "no") then
			say(npcHandler, npc, creature, {
				"Well, that doesn't surprise me. But to find out how concentrated our love potion has to be, let's do a small questionaire with them. ...",
				"Go into my library. Somewhere around there you should find a parchment with some sample questions on it. Ask the dwarf and the elf the questions and see if they have ANYTHING in common. That should give us a starting point.",
			})
			npcHandler:setTopic(id, 0)
			return true
		end
	elseif topic == T.MILK then
		if contains(msg, "no") then
			say(npcHandler, npc, creature, "NO? It was about the... love potion, you say? Hm, I see. So... did you find anything which the dwarf and the elf have in common?")
			npcHandler:setTopic(id, T.COMMON_Q)
			return true
		elseif contains(msg, "yes") then
			say(npcHandler, npc, creature, "Then where is my milk? Hm... wait. I don't even like milk. Never mind!") -- ours
			npcHandler:setTopic(id, 0)
			return true
		end
	elseif topic == T.COMMON_Q then
		if contains(msg, "yes") then
			say(npcHandler, npc, creature, "Well, then what is it they both have in common?")
			npcHandler:setTopic(id, T.COMMON)
			return true
		elseif contains(msg, "no") then
			say(npcHandler, npc, creature, "Then ask them the questions on the parchment from my library. They must have SOMETHING in common!") -- ours
			npcHandler:setTopic(id, 0)
			return true
		end
	elseif topic == T.COMMON then
		npcHandler:setTopic(id, 0)
		local answer = FS.commonAnswer(player)
		if answer and msg:find(answer.word, 1, true) then
			if not FS.askedBoth(player, answer.question) then
				say(npcHandler, npc, creature, "Hm! Are you sure? Did you really ask both of them? Go and ask them first, I don't want to brew the wrong potion!") -- ours
				return true
			end
			FS.setMission(player, M.COMMON_FOUND)
			say(npcHandler, npc, creature, "Hm! That is something we can easily build on. Let me think for a small moment and then we can continue the mission.")
			return true
		end
		say(npcHandler, npc, creature, "Hm. No... I don't think that's something they really have in common. Ask them the questions again!") -- ours
		return true
	elseif topic == T.WHO_LOVE then
		npcHandler:setTopic(id, 0)
		FS.setMission(player, M.BONUS)
		player:addAchievement("Matchmaker")
		say(npcHandler, npc, creature, "MUAHAHA! My plan worked! You did well! I'll make sure you get an extra bonus for that. Now hmm, hmm, let me think for a moment before we go on with the mission.")
		return true
	elseif topic > T.QUIZ and topic <= T.QUIZ + #FS.books then
		local index = topic - T.QUIZ
		local colour
		for _, c in ipairs(FS.colours) do
			if msg:find(c, 1, true) then
				colour = c
				break
			end
		end
		if not colour then
			say(npcHandler, npc, creature, "That's not one of the colours: {red}, {brown}, {light blue}, {dark blue}, {light green} or {dark green}. So, what colour is " .. FS.books[index][1] .. "?") -- ours
			return true
		end
		quizAnswers[id] = quizAnswers[id] or {}
		quizAnswers[id][index] = colour
		if index < #FS.books then
			say(npcHandler, npc, creature, "I see. And what colour is " .. FS.books[index + 1][1] .. "?")
			npcHandler:setTopic(id, topic + 1)
		else
			say(npcHandler, npc, creature, "I see. That concludes my questioning. I guess now you'd like to know whether you succeeded in the mission?")
			npcHandler:setTopic(id, T.QUIZ_END + 1)
		end
		return true
	elseif topic == T.QUIZ_END + 1 then
		npcHandler:setTopic(id, 0)
		local answers = quizAnswers[id] or {}
		quizAnswers[id] = nil
		local right = true
		for i, book in ipairs(FS.books) do
			if answers[i] ~= book[2] then
				right = false
			end
		end
		if right and m == M.BOOKS_ASKED then
			FS.setMission(player, M.BOOKS_DONE)
			FS.reward(player, 0, 500)
			say(npcHandler, npc, creature, "You answered all the questions correctly - bravo - as far as I can remember my books. Congratulations! Well, since I actually did something for your intelligence, the reward is symbolic. But it's the thought that counts! Teehee.")
		else
			say(npcHandler, npc, creature, "Hmm... no, I don't think that's right. Or do I remember my books wrong? Have another look at them, ask me for {hints} and then ask me about the {mission} again.") -- ours
		end
		return true
	elseif topic == T.XODET_WHO then
		npcHandler:setTopic(id, 0)
		if contains(msg, "xodet") and m == M.XODET_FOUND then
			say(npcHandler, npc, creature, {
				"Xodet! That old fox! I should've guessed it! We were buddies in the old days, you know... but it's harsh to hear that he seems to value money more than our friendship. ...",
				"There must be a way to remind him that there are more important things in life. Hmmm... you know, it was me who gave Xodet his first wand and taught him the basics of magic. ...",
				"He was never a really good sorcerer and his spells went wrong most of the time, so he decided to become a trader for magical equipment instead. ...",
				"But I wonder whether he still has that first wand... maybe in his house somewhere? I think if you could find it, he might remember what we shared... right?",
			})
			npcHandler:setTopic(id, T.MISSION)
			return true
		end
		say(npcHandler, npc, creature, "Hm, no... I don't think so. That doesn't ring a bell.") -- ours
		return true
	elseif topic == T.KISS then
		if contains(msg, "no") then
			say(npcHandler, npc, creature, "Oh... I see. Wuaaaaaaaaaaah why do my plans never seem to work out? I'm not such a useless sorcerer! We need to find another way. Let's try something different, shall we?")
			npcHandler:setTopic(id, T.TRY)
			return true
		elseif contains(msg, "yes") then
			say(npcHandler, npc, creature, "Really? Then why is he still sitting down there in his cage, croaking? Be honest with me!") -- ours
			npcHandler:setTopic(id, T.KISS)
			return true
		end
	elseif topic == T.TRY then
		if contains(msg, "yes") then
			say(npcHandler, npc, creature, {
				"Okay, let's resort to some good old black magic for a counterspell. I really need your help with this one though, especially for the ingredients. ...",
				"You probably thought I wouldn't let you gather items anymore, right? But - I love surprises! Teehee. So please bring me the following items, all of them at the same time: ...",
				"A silver amulet, a dagger, a green tapestry, a blank rune and a dirty fur. Did you get that?",
			})
			npcHandler:setTopic(id, T.GOT_IT)
			return true
		elseif contains(msg, "no") then
			say(npcHandler, npc, creature, "But we can't just leave him like that! Come back when you're ready to try something else.") -- ours
			npcHandler:setTopic(id, 0)
			return true
		end
	elseif topic == T.GOT_IT then
		if contains(msg, "yes") then
			FS.setMission(player, M.INGREDIENTS_ASKED)
			say(npcHandler, npc, creature, "Great. I'll wait for you here and I'm positive I won't have forgotten about it when you come back.")
			npcHandler:setTopic(id, 0)
			return true
		elseif contains(msg, "no") then
			say(npcHandler, npc, creature, "A silver amulet, a dagger, a green tapestry, a blank rune and a dirty fur. Did you get that?") -- ours (repeat)
			return true
		end
	end

	-- the laboratory Eclesius: "Are you listening?" / "Is that the result?" also after a new greeting
	if npc:getPosition().z ~= 7 and (m == M.SCENE or m == M.RESULT) and contains(msg, "yes") then
		if m == M.SCENE and FS.kvNumber(player, "sceneListening") == 1 then
			say(npcHandler, npc, creature, "First the left lever, then the right lever, and once both subjects are there, the one in the middle. Go on!") -- ours
			return true
		end
		return missionYes(npc, creature, player, npcHandler)
	end

	-- keywords
	if contains(msg, "mission", "missions") then
		if npc:getPosition().z ~= 7 then
			say(npcHandler, npc, creature, "Not now! Pull the levers! First the left, then the right, then the middle one.") -- ours
			return true
		end
		return missionOffer(npc, creature, player, npcHandler)
	end
	if contains(msg, "task", "tasks") then
		say(npcHandler, npc, creature, {
			"I have five tasks which, ideally, need to be done once a day. {Sweep} the house, {polish} my crystal ball, {feed} my fish, {exterminate} bats and {prevent} the apocalypse. ...",
			"... wow, I remembered them all. Now if you remember to do them and I remember to pay you for it, I think we'll all be very happy! ...",
			"Just remind me of the task you wanted to do and go right ahead, uh... what's your name again?",
		})
		npcHandler:setTopic(id, T.TASKS)
		return true
	end
	for _, task in ipairs(FS.tasks) do
		if contains(msg, task) then
			return startTask(npc, creature, player, npcHandler, task)
		end
	end
	if contains(msg, "magical oil", "oil") then
		if FS.taskState(player, "prevent") ~= FS.ACTIVE then
			say(npcHandler, npc, creature, "Magical oil? What for? Oh, for the cage! Ask me about the task to {prevent} the apocalypse first.") -- ours
			return true
		end
		say(npcHandler, npc, creature, "Ah! Have you found the recipe and brought me the necessary ingredients?")
		npcHandler:setTopic(id, T.OIL)
		return true
	end
	if contains(msg, "hint", "hints") then
		say(npcHandler, npc, creature, m == M.BOOKS_ASKED and FS.hints[math.random(#FS.hints)] or "Hint? What kind of hint?")
		return true
	end
	if msg == player:getName():lower() or (topic == T.TASKS and contains(msg, player:getName():lower())) then
		say(npcHandler, npc, creature, "Was that your name...? |PLAYERNAME|? Really? <scratches head> Fine then... hello |PLAYERNAME|!")
		npcHandler:setTopic(id, 0)
		return true
	end
	if contains(msg, "lose my sandals", "lost my sandals") and m >= M.SANDALS_GIVEN and m <= M.FRAGRANT then
		if player:getItemCount(FS.items.eclesiusSandals) == 0 then
			return missionOffer(npc, creature, player, npcHandler)
		end
		say(npcHandler, npc, creature, "Good, good. You still have them. Keep it that way!") -- ours
		return true
	end
	return false
end

-- ---------------------------------------------------------------------------
-- questionnaire (Amarie and Grodrik)
-- ---------------------------------------------------------------------------
FS.questions = {
	{ words = { "most important", "relationship" } },
	{ words = { "date location", "ideal date", "location" } },
	{ words = { "physical attribute", "attribute", "partner" } },
	{ words = { "something you love" } },
	{ words = { "dislike" } },
	{ words = { "character trait", "trait" } },
	{ words = { "favourite colour", "favorite color", "colour", "color" } },
	{ words = { "greatest fear", "fear" } },
}

-- Answers by variant (FS.variant, one per character): 1 both like blue eyes (question 3),
-- 2 both like chocolate (question 4) - the two EN answer sets; 3 "a portion of tolerance"
-- (question 6) and 4 "lonely" (question 8), which TibiaWiki BR names as other common answers
-- without their lines: those lines are ours.
FS.answers = {
	amarie = {
		"You should always strive for harmony in a relationship to avoid arguments and fights. Harmony is important!",
		"A lush, green meadow in the middle of a forest... <dreams>",
		{ "There's more important things than a person's appearance. But if I had to choose, I'd say sparkling blue eyes, just like the ocean on a sunny day.", "Uhm... well, I look at a person's face first. A handsome face would be a definite plus." },
		{ "As you can see... I love books.", "<blushes> My secret addiction... is chocolate. Luckily it's so rare, or else I'd eat it all day." },
		-- (questions 3 and 4 with two entries: variants 3 and 4 use the first set without the common one, see FS.pick)
		"I don't like fire very much... it poses a threat to my beloved trees, the beautiful grass and my precious books. I've lost too many things due to fires.",
		{
			"I think I'd choose patience as an answer to this one. Patience promotes tolerance which prevents arguments and thus ensures harmony.",
			"I think I'd choose patience as an answer to this one. Patience promotes tolerance which prevents arguments and thus ensures harmony.",
			"A good portion of tolerance. Nobody is perfect, you know. Loving someone means accepting their little quirks... even if they leave crumbs in my books.", -- ours
			"I think I'd choose patience as an answer to this one. Patience promotes tolerance which prevents arguments and thus ensures harmony.",
		},
		"I love all colours! It's so hard to choose one! But I think... my favourite colour for today is green. Green like the trees, like balance and relaxation.",
		{
			"I try to stay in control of my fears. But if you ask me like that... it really makes me shiver when I hear the name of Ferumbras. <shudders>",
			"I try to stay in control of my fears. But if you ask me like that... it really makes me shiver when I hear the name of Ferumbras. <shudders>",
			"I try to stay in control of my fears. But if you ask me like that... it really makes me shiver when I hear the name of Ferumbras. <shudders>",
			"My greatest fear? <looks at her books> Growing old here, all alone, without anyone to share my poems with. Staying lonely forever... <shivers>", -- ours
		},
	},
	grodrik = {
		"The most important thing in a relationship is to always have a good supply of beer. Solves almost all problems!",
		"What do you mean, date location? I never had a date, so how should I know? I guess here would do. Right here in this tavern.",
		{ "Well, looks aren't everything, you know. But apart from the typical dwarvish attributes I'm also really fond of blue eyes.", "Of course... a pretty, long and well-combed beard! Also I have a weakness for tiny toes." },
		{ "Well, duh. Beer of course! I love beer! The only thing I love more than a pint of beer is two pints of beer!", "Hrmrhm. Let's think about this one strategically. I guess I'm going to be matched up with a woman. What do women always say? Chocolate! So... put chocolate there as an answer." },
		"I don't like the fact that some weapons get rusty. Rust is a curse for any smith.",
		{
			"I get angry when someone lies to me. Lies are bad. So put down honesty.",
			"I get angry when someone lies to me. Lies are bad. So put down honesty.",
			"A good portion of tolerance! My woman would have to put up with my snoring, my beer and my axe collection. Not everyone can do that.", -- ours
			"I get angry when someone lies to me. Lies are bad. So put down honesty.",
		},
		"Red. Red like fire, and red like my favourite kind of steel.",
		{
			"Dwarfs have no fear!! Well... for some reason, jesters give me the creeps.",
			"Dwarfs have no fear!! Well... for some reason, jesters give me the creeps.",
			"Dwarfs have no fear!! Well... for some reason, jesters give me the creeps.",
			"Dwarfs have no fear!! Well... <hicks> except maybe ending up old and lonely in this tavern, with nobody to brew beer for. Don't write that down! ...Alright, write it down.", -- ours
		},
	},
}

FS.VARIANTS = 4

function FS.variant(player)
	local v = FS.kvNumber(player, "variant")
	if v < 1 or v > FS.VARIANTS then
		v = math.random(1, FS.VARIANTS)
		FS.kv(player):set("variant", v)
	end
	return v
end

-- the answer of one variant: four entries = one per variant; two entries (questions 3 and 4) =
-- the common one for its own variant, else the other one
function FS.pick(answer, question, variant)
	if type(answer) ~= "table" then
		return answer
	end
	if #answer >= FS.VARIANTS then
		return answer[variant]
	end
	if (question == 3 and variant == 1) or (question == 4 and variant == 2) then
		return question == 3 and answer[1] or answer[2]
	end
	return question == 3 and answer[2] or answer[1]
end

FS.commonAnswers = {
	{ word = "blue eye", question = 3 },
	{ word = "chocolate", question = 4 },
	{ word = "tolerance", question = 6 },
	{ word = "lonel", question = 8 }, -- lonely, loneliness
}

function FS.commonAnswer(player)
	return FS.commonAnswers[FS.variant(player)]
end

function FS.askedBoth(player, question)
	return FS.hasBit(FS.kvNumber(player, "askedAmarie"), question - 1) and FS.hasBit(FS.kvNumber(player, "askedGrodrik"), question - 1)
end

-- Returns the answer to a questionnaire question, or nil.
function FS.answerQuestion(player, who, message)
	local msg = message:lower()
	for index, q in ipairs(FS.questions) do
		for _, word in ipairs(q.words) do
			if msg:find(word, 1, true) then
				local answer = FS.pick(FS.answers[who][index], index, FS.variant(player))
				local key = who == "amarie" and "askedAmarie" or "askedGrodrik"
				local mask = FS.kvNumber(player, key)
				if not FS.hasBit(mask, index - 1) then
					FS.kv(player):set(key, mask + 2 ^ (index - 1))
				end
				return answer
			end
		end
	end
end

local function checkBothDrunk(player)
	local kv = FS.kv(player)
	if kv:get("amarieDrunk") and kv:get("grodrikDrunk") and FS.mission(player) == M.POTIONS then
		FS.setMission(player, M.BOTH_DRUNK)
	end
end

-- ---------------------------------------------------------------------------
-- Amarie (Ab'Dendriel library)
-- ---------------------------------------------------------------------------
local amarieStep = {}
local A = { STUDY = 1, POEM = 2, LIKE = 3, REGISTER = 4, QUESTIONS = 5, ANYTHING = 6, DRINK = 7 }

function FS.setupAmarie(keywordHandler, npcHandler)
	FS.setGreeter(npcHandler, function(npc, player)
		amarieStep[player:getId()] = 0
		local m = FS.mission(player)
		local kv = FS.kv(player)
		if m == M.QUESTIONNAIRE then
			return "Oh! You're back! Any news from the... <blushes> dating... thing?", A.QUESTIONS
		elseif m == M.POTIONS and not kv:get("amarieDrunk") then
			return "Ashari, my friend. My heart is filled with gladness and hope. Have you got anything interesting for me?", A.ANYTHING
		end
		return "I really have to {study}, I'm sorry. Please leave me alone with my books."
	end, { "ashari" })

	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not player or not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		if not FS.enabled() then
			return true
		end
		local id = player:getId()
		local topic = npcHandler:getTopic(id)
		local m = FS.mission(player)
		local kv = FS.kv(player)
		local step = amarieStep[id] or 0
		local msg = message:lower()
		local function line(text, newTopic, newStep)
			say(npcHandler, npc, creature, text)
			npcHandler:setTopic(id, newTopic or 0)
			if newStep then
				amarieStep[id] = math.max(step, newStep)
			end
			return true
		end

		-- questionnaire
		if m == M.QUESTIONNAIRE then
			if topic == A.QUESTIONS and contains(msg, "yes") then
				return line("You want to ask me some questions? About myself? <blushes> Okay... I'll be honest as long as they aren't too personal. Go ahead.", A.QUESTIONS)
			end
			local answer = FS.answerQuestion(player, "amarie", msg)
			if answer then
				return line(answer, A.QUESTIONS)
			end
		end
		-- love potion
		if m == M.POTIONS and not kv:get("amarieDrunk") then
			if topic == A.ANYTHING and contains(msg, "yes") then
				return line("So? What is it?", A.ANYTHING)
			elseif contains(msg, "drink") then
				return line("A drink? What kind of drink? I'm very picky when it comes to food and drink.", A.ANYTHING)
			elseif contains(msg, "milkbug", "milkbugs", "bug milk", "milk") then
				return line("Oh, you brought us some bug milk? That's so nice of you! Let's drink it right away, shall we?", A.DRINK)
			elseif topic == A.DRINK and contains(msg, "yes") then
				if player:getItemCount(FS.items.lovePotion) == 0 then
					return line("Oh... but you don't have any bug milk with you.") -- ours
				end
				player:removeItem(FS.items.lovePotion, 1)
				kv:set("amarieDrunk", 1)
				checkBothDrunk(player)
				npc:getPosition():sendMagicEffect(CONST_ME_HEARTS)
				return line("<sips> To love! The most beautiful of all... uh... my tummy... feels so warm... and my heart is beating faster...")
			end
		end

		-- getting to know her
		if contains(msg, "study") then
			return line("Oh, you're interested in what I study? Really? <blushes> That's unusual. Well, it's about the... no wait. I don't want to bore you. Are you really interested?", A.STUDY)
		elseif topic == A.STUDY and contains(msg, "yes") then
			return line("Wow. Okay... it's about the... <blushes even more> well... social interaction of {milkbugs} in their m... mating season.", 0, 2)
		elseif topic == A.STUDY and contains(msg, "no") then
			return line("I knew it. Nobody is ever interested... <sighs>") -- ours
		elseif contains(msg, "milkbugs", "milkbug") then
			return line("Milkbugs are a very interesting species, actually. They really {care} for each other and help each other to raise their young.", 0, 3)
		elseif contains(msg, "care") then
			return line("Sigh... so caring, yes. <gets a dreamy look in her eyes> Sometimes I {dream} of.... ah .. forget what I said. <blushes>", 0, 4)
		elseif contains(msg, "dream", "dreams") then
			return line("What do I dream of? I think... no one has asked me that for a long time. In my favourite {book} it says... oh, but it isn't really interesting.", 0, 5)
		elseif contains(msg, "book", "books") then
			return line("My favourite book... is an erm... {poetry} book. Which I shouldn't waste my study time on, but... poetry can also be meaningful.", 0, 6)
		elseif contains(msg, "poetry", "poem") then
			return line("Would you like me to... re... recite some poetry? <blushes>", A.POEM)
		elseif topic == A.POEM and contains(msg, "yes") then
			return line({
				"Really... okay. I'll tell you my favourite. Maybe you'll like it too... <smiles shyly> It's an elven poem, but I'll translate it for you. Here goes: ...",
				"'Alas, her pale face up in the starry sky ...",
				"Flaunting a light that is not hers ...",
				"Lost in reverie to dance with the fervid sun ...",
				"Yet knowing that this day will never dawn ...",
				"For with the dawn she fades ...",
				"And only when darkness engulfs her ...",
				"Will her light shine the brightest.' ...",
				"<blushes> So... what do you think? Did you like the poem?",
			}, A.LIKE, 7)
		elseif topic == A.LIKE and contains(msg, "yes") then
			return line({
				"Oh, do you really mean it? That's so nice, finally someone who understands me. <smiles and claps her hands> Maybe you will understand my dreams as well. Or... I'm getting carried away. My dreams are a little confusing. ...",
				"And I don't think there's a chance that I'll ever find what I'm really looking for. <sighs> I guess I shall have to resign myself to a long, lonely life without {love}...",
			}, 0, 8)
		elseif (topic == A.LIKE or topic == A.POEM) and contains(msg, "no") then
			return line("Oh... <blushes> I see. Never mind, then.") -- ours
		elseif contains(msg, "love") and step >= 8 then
			return line("Love? Hah... you don't know me. I'm really not good at this stuff. Or what is it you're implying?", 0, 9)
		elseif contains(msg, "dating", "date") then
			if m == M.DATING_ASKED and step >= 9 and player:getItemCount(FS.items.amarieBook) == 0 and not kv:get("amarieBook") then
				return line({
					"<blushes> You are a dating agent? Oh dear, I never would've told you all this stuff had I known that earlier. Well... I guess... it's better than waiting all my life. ...",
					"Do you need anything from me for the registration?",
				}, A.REGISTER)
			end
			return line("D-dating? <blushes> I... I don't know what you mean. I really have to {study}.") -- ours
		elseif topic == A.REGISTER and contains(msg, "yes") then
			player:addItem(FS.items.amarieBook, 1)
			kv:set("amarieBook", 1)
			return line("A personal item, you say? Well... the most personal thing I have is this book of mine... with my favourite poem in it. I'll give it to you... maybe you'll find someone who also sees more in it. Thank you...")
		end
		return true
	end)
end

-- ---------------------------------------------------------------------------
-- Grodrik (Kazordoon, Jolly Axeman tavern)
-- ---------------------------------------------------------------------------
local grodrik = {}
local G = { BEER = 1, REGISTER = 2, QUESTIONS = 3, POTION = 4 }

local function takeBeer(player)
	if player:getItemCount(FS.items.mug, FLUID_BEER) > 0 then
		return player:removeItem(FS.items.mug, 1, FLUID_BEER)
	end
	return false
end
FS.takeBeer = takeBeer

function FS.setupGrodrik(keywordHandler, npcHandler)
	FS.setGreeter(npcHandler, function(npc, player)
		grodrik[player:getId()] = { beers = 0 }
		local m = FS.mission(player)
		if m == M.QUESTIONNAIRE then
			return "Hiho! It's you again! Any news from the <whispers> dating service?", G.QUESTIONS
		elseif m == M.POTIONS and not FS.kv(player):get("grodrikDrunk") then
			return "Hello, my friend. What do you have for me today?"
		end
		return "Leave me in peace. I don't want to chat with humans. Got my own worries and {problems}."
	end)

	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not player or not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		if not FS.enabled() then
			return true
		end
		local id = player:getId()
		local topic = npcHandler:getTopic(id)
		local m = FS.mission(player)
		local kv = FS.kv(player)
		local talk = grodrik[id] or { beers = 0 }
		grodrik[id] = talk
		local msg = message:lower()
		local function line(text, newTopic)
			say(npcHandler, npc, creature, text)
			npcHandler:setTopic(id, newTopic or 0)
			return true
		end
		local function drink()
			if not takeBeer(player) then
				return false
			end
			talk.beers = talk.beers + 1
			return true
		end
		local noBeer = "You don't even have a mug of beer with you! Don't tease a thirsty dwarf, stranger." -- ours

		-- questionnaire
		if m == M.QUESTIONNAIRE then
			if topic == G.QUESTIONS and contains(msg, "yes") then
				return line("I see, they want me to answer a questionaire? Sure, I can understand why. Just go right ahead with your questions!", G.QUESTIONS)
			end
			local answer = FS.answerQuestion(player, "grodrik", msg)
			if answer then
				return line(answer, G.QUESTIONS)
			end
		end
		-- love potion
		if m == M.POTIONS and not kv:get("grodrikDrunk") then
			if contains(msg, "beer", "drink") and topic ~= G.POTION then
				return line("Oh, sure. Let's have a drink first. Got a beer for me?", G.POTION)
			elseif topic == G.POTION and contains(msg, "yes") then
				if player:getItemCount(FS.items.lovePotion) == 0 then
					return line(noBeer)
				end
				player:removeItem(FS.items.lovePotion, 1)
				kv:set("grodrikDrunk", 1)
				checkBothDrunk(player)
				npc:getPosition():sendMagicEffect(CONST_ME_HEARTS)
				return line("<gulp gulp> Aa... erm... what the... that's a strange beer. It makes me feel... all warm and fuzzy... uuhhhnn...")
			end
		end

		if contains(msg, "problems", "problem") then
			return line("<sigh> My current problem is that my beer is empty. Got a mug of beer for me?", G.BEER)
		elseif topic == G.BEER and contains(msg, "yes") then
			if not drink() then
				return line(noBeer)
			end
			return line("Hrrm. Appreciated. <gulp gulp> You know, life without a {woman} just isn't as much fun. Someone who'll give you a foot {massage} when you come home from the tavern.")
		elseif topic == G.BEER and contains(msg, "no") then
			return line("Then leave me in peace.") -- ours
		elseif contains(msg, "beer") then
			if not drink() then
				return line(noBeer)
			end
			return line("Oh, thanks, stranger. I like you better and better. Hehehe. Now, did you want to say something?")
		elseif contains(msg, "woman", "women", "girlfriend", "wife") then
			if talk.beers <= 1 then
				return line("Sigh. I don't want to talk about all that. It's too embarassing. <swallows his beer down in one gulp>")
			elseif talk.beers == 2 then
				return line("I don't really want to talk about that... I think. I'm actually a bit shy, you know, especially towards strangers, although you've been rather nice to me with all that beer.")
			end
			talk.woman = true
			return line("Ah, whatever, why shouldn't I tell you. I've never had a girlfriend. <sigh> I wouldn't even demand much from her or have unrealistic {wishes}. I just feel so {lonely} sometimes. But oh well, that's not really any of your business. <swallows his beer down>")
		elseif contains(msg, "lonely", "loneliness") then
			if talk.woman and talk.beers >= 4 then
				talk.lonely = true
				return line("It's not just about having company or not. You also need someone who respects your {wishes} - <hicks> - and tolerates your habits. Such as drinking beer.")
			end
			return line("Ah, what do you know about loneliness. You look like you've got a lot of friends. I only have my beer. And that's almost empty.")
		elseif contains(msg, "wishes", "wish") then
			if talk.woman and talk.beers >= 5 then
				talk.wishes = true
				return line("My wishes... <hicks>... are humble. A tall, strong woman with a blonde beard, adventurous and able to brew beer. <hicks> Yes, that would be great. But I guess I won't ever find anyone like that. <hicks>")
			end
			return line("Whoah! You are going too far, stranger. My wishes are quite personal.")
		elseif contains(msg, "massage") then
			return line("Hrmph. Forget I said that. <hicks>") -- ours
		elseif contains(msg, "dating", "date") then
			if m == M.DATING_ASKED and talk.wishes and talk.lonely and talk.beers >= 6 and player:getItemCount(FS.items.grodrikAxe) == 0 and not kv:get("grodrikAxe") then
				return line("You know... <hicks> ... maybe that's not such a bad idea after all. <hicks> You took note of my wishes, right... <hicks> Is there anything you still need from me for the <hicks> registration?", G.REGISTER)
			end
			return line("Dating? Hrmph. I don't even know you, stranger. Maybe after another beer or two.") -- ours
		elseif topic == G.REGISTER and contains(msg, "yes") then
			player:addItem(FS.items.grodrikAxe, 1)
			kv:set("grodrikAxe", 1)
			return line("A personal <hicks> item, you say? Well, I can give you my favourite <hicks> axe. Here. Let me know when you find a girl for me. <hicks>")
		end
		return true
	end)
end

-- ---------------------------------------------------------------------------
-- A Confused Frog (Eclesius' cellar) and A Frog (pond north of Thais)
-- ---------------------------------------------------------------------------
FS.SPELL_HUMAN = "eeny meeny miny moe ribbit ribbit head to toe"
FS.SPELL_SWAP = "eeny meeny miny moe i stay here and you will go"
local kisses = {}

function FS.isPrincess(player)
	return FS.kvNumber(player, "princessUntil") > os.time() and player:getCondition(CONDITION_OUTFIT) ~= nil
end

-- A Confused Frog: returns true when handled.
function FS.confusedFrogSay(npc, creature, message, npcHandler)
	if not FS.enabled() then
		return false
	end
	local player = Player(creature)
	if not player then
		return false
	end
	local id = player:getId()
	local m = FS.mission(player)
	local norm = FS.normalize(message)
	local function line(text)
		say(npcHandler, npc, creature, text)
		return true
	end

	if norm:find(FS.SPELL_HUMAN, 1, true) then
		if m == M.SPELL_ASKED then
			FS.setMission(player, M.SPOKEN)
			npc:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
			return line({ "........ ...", "Ri..... ...", "Ritual didn't work. RIBBIT?! I can speak the human language again! Ribbit! Well, at least sometimes it seems. Ribbit. And who the heck are you??" })
		end
		return line("Ribbit?!") -- ours
	end
	if norm == " ribbit " then
		return line("Ribbit?!")
	end
	if FS.says(message, "kiss") then
		if m == M.KISS_ASKED and FS.isPrincess(player) then
			kisses[id] = (kisses[id] or 0) + 1
			if kisses[id] >= 2 then
				kisses[id] = 0
				FS.setMission(player, M.KISSED)
				npc:getPosition():sendMagicEffect(CONST_ME_HEARTS)
				return line(".... ribbit ... ribbitribbit. <the frog looks at you with sad eyes>")
			end
		end
		return line("..... ...")
	end
	if m >= M.SPOKEN then
		if FS.says(message, "human") or FS.says(message, "frog") then
			if m == M.SPOKEN or m == M.HUMAN_ASKED then
				FS.setMission(player, M.HUMAN_ANSWERED)
			end
			return line("You know... being a frog isn't that bad. Ribbit. I don't want to be a human again. I just wish I could get out of this cage and live by a lovely little pond.")
		end
		if message:lower() == player:getName():lower() then
			return line("Are you? I see. I saw you poking around here earlier. Ribbit. Well whatever you were trying to do, I'm not sure it was successful. Ribbit. What was that princess thing all about, anyway??")
		end
	else
		-- before the counterspell he only croaks
		local msg = message:lower()
		if not (msg == "bye" or msg == "farewell") then
			return line(m >= M.KISS_ASKED and "Ribbit?! <the frog stares at you>" or "Ribbit.") -- ours
		end
	end
	return false
end

function FS.confusedFrogGreeting(npc, player, message)
	if FS.mission(player) >= M.SPOKEN then
		return "Hi, |PLAYERNAME|."
	end
	if message and message:lower():find("ribbit", 1, true) then
		return "Ribbit?!"
	end
	return "Err... ribbit?"
end

-- the frog's other words (job, name, demon...) only after the counterspell
function FS.frogTalks(player)
	return not FS.enabled() or FS.mission(player) >= M.SPOKEN
end

-- A Frog at the pond: returns true when handled.
function FS.frogSay(npc, creature, message, npcHandler)
	if not FS.enabled() then
		return false
	end
	local player = Player(creature)
	if not player then
		return false
	end
	if FS.normalize(message):find(FS.SPELL_SWAP, 1, true) then
		if FS.mission(player) == M.POND_ASKED then
			FS.setMission(player, M.SWAPPED)
			npc:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			say(npcHandler, npc, creature, "Uhhhhhh... ribbit... wow, I don't believe it. That must be the first time one of the old fool's spells have actually worked! Ribbit! Thank you!")
			return true
		end
		say(npcHandler, npc, creature, "Ribbit? What kind of nonsense is that?") -- ours
		return true
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Irmana (Venore, Dress for Success): the hats. Returns true when handled.
-- ---------------------------------------------------------------------------
FS.hats = {
	["dark hat"] = {
		id = 9127,
		ask = "To create a dark hat, I need one piece of minotaur leather and two bat wings. Do you have those materials with you by coincidence?",
		needs = { { id = 5878, count = 1 }, { id = 5894, count = 2 } },
	},
	["pink hat"] = {
		id = 9128,
		-- ours, recipe from TibiaWiki EN (minotaur leather and heaven blossom)
		ask = "To create a pink hat, I need one piece of minotaur leather and a heaven blossom. Do you have those materials with you by coincidence?",
		needs = { { id = 5878, count = 1 }, { id = 5921, count = 1 } },
	},
	["wooden hat"] = {
		id = 9129,
		-- ours, recipe from TibiaWiki EN (wood and iron ore)
		ask = "To create a wooden hat, I need one piece of wood and one piece of iron ore. Do you have those materials with you by coincidence?",
		needs = { { id = 5901, count = 1 }, { id = 5880, count = 1 } },
	},
}
local irmanaHat = {}
local IRMANA_TOPIC = 70

function FS.irmanaSay(npc, creature, message, npcHandler)
	if not FS.enabled() then
		return false
	end
	local player = Player(creature)
	if not player or FS.mission(player) ~= M.HAT_ASKED then
		return false
	end
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	local msg = message:lower()
	for name, hat in pairs(FS.hats) do
		if msg:find(name, 1, true) then
			irmanaHat[id] = name
			say(npcHandler, npc, creature, hat.ask)
			npcHandler:setTopic(id, IRMANA_TOPIC)
			return true
		end
	end
	if topic == IRMANA_TOPIC then
		local hat = FS.hats[irmanaHat[id] or ""]
		npcHandler:setTopic(id, 0)
		if hat and contains(msg, "yes") then
			if not hasAll(player, hat.needs) then
				say(npcHandler, npc, creature, "Hm, I'm afraid you don't have the materials with you. Come back when you have them.") -- ours
				return true
			end
			removeAll(player, hat.needs)
			player:addItem(hat.id, 1)
			say(npcHandler, npc, creature, "A little stitch here and a little stitch there... perfect! Here you are. With the best wishes to your master.")
			return true
		elseif contains(msg, "no") then
			say(npcHandler, npc, creature, "Then come back when you have them.") -- ours
			return true
		end
	end
	if contains(msg, "hat") and (topic == 0 or topic == IRMANA_TOPIC) then
		say(npcHandler, npc, creature, "Yes, I can help you with fabricating a hat for your master. I have three different models available. A {dark hat}, a {pink hat} and a {wooden hat}. What do you think would he prefer?")
		return true
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Frodo and Xodet (Mission 5)
-- ---------------------------------------------------------------------------
function FS.onMemoryMission(player)
	local m = FS.mission(player)
	return m == M.MEMORY_ASKED
end

local xodetStep = {}
local xodetChain = {
	{ { "eclesius" }, "Huh? Erm... yes, I know him... but uhm... only vaguely. Yes. <chuckles nervously>" },
	{ { "potion", "potions" }, "Yes, ehem, I do sell potions. But... only the conventional ones. Really." },
	{ { "formula" }, "A new formula for a potion? Oh... no, no, of course not. I'm not a magician, you know." },
	{ { "eclesius" }, "Yes, we might have chatted a bit last night, but not about... important things. Just the usual chit-chat." },
	{ { "chit chat", "chit-chat", "chitchat" }, "We talked about... well... uhm... <gets a red face> That's none of your business!! Who are you anyway to think you have the right to pose me these questions??" },
	{ { "magician" }, "Well, how about - I don't care? Unless you're sent by someone important, let me do my business and leave me in peace. So who sent you?!" },
	{ { "eclesius" }, "You're Eclesius' assistant? Well... I see. So he remembers after all, does he? Well, I don't care! Go away, topic closed!" },
}

function FS.xodetGreeting(npc, player)
	xodetStep[player:getId()] = 0
	if FS.enabled() and FS.mission(player) == M.WAND_ASKED and player:getItemCount(FS.items.wand) > 0 then
		return "|PLAYERNAME|, how many times should I tell you to... w-wait, what's that in your hand?"
	end
end

-- Xodet: returns true when handled.
function FS.xodetSay(npc, creature, message, npcHandler)
	if not FS.enabled() then
		return false
	end
	local player = Player(creature)
	if not player then
		return false
	end
	local id = player:getId()
	local m = FS.mission(player)
	if m == M.WAND_ASKED and player:getItemCount(FS.items.wand) > 0 and contains(message, "first wand", "wand") then
		player:removeItem(FS.items.wand, 1)
		player:addItem(FS.items.formula, 1)
		FS.setMission(player, M.FORMULA)
		say(npcHandler, npc, creature, {
			"My first wand... I thought it was long gone... how strange to see it again after all those years. I remember well how I got it... and tried to become a great sorcerer. ...",
			"But my efforts were in vain... I've never become as good as Eclesius, Muriel or Trimegis... so I settled down with trading magical equipment. ...",
			"I thought that with the formula of Eclesius, I might be able to brew a new kind of potion and finally have a breakthrough... but I see now that was a mistake, although tempting. ...",
			"Here, take the paper with the formula and give it back to Eclesius. Tell him that I'm sorry and that I hope we'll still have a drink now and then. I'm not a bad person... just desperate sometimes.",
		})
		return true
	end
	if m ~= M.MEMORY_ASKED then
		return false
	end
	local step = (xodetStep[id] or 0) + 1
	local entry = xodetChain[step]
	if entry and contains(message, unpack(entry[1])) then
		xodetStep[id] = step
		say(npcHandler, npc, creature, entry[2])
		if step == #xodetChain then
			FS.setMission(player, M.XODET_FOUND)
			xodetStep[id] = 0
		end
		return true
	end
	if contains(message, "eclesius") then
		-- out of order: start again
		xodetStep[id] = 1
		say(npcHandler, npc, creature, xodetChain[1][2])
		return true
	end
	return false
end

-- Xodet's "eclesius" keyword answers only outside the mission (the chain above handles it).
function FS.xodetPlainEclesius(player)
	if not FS.enabled() then
		return true
	end
	local m = FS.mission(player)
	return m ~= M.MEMORY_ASKED
end

-- ---------------------------------------------------------------------------
-- Queen Eloise and Bunny Bonecrusher (Mission 6)
-- ---------------------------------------------------------------------------
function FS.wantsDress(player)
	if not FS.enabled() then
		return false
	end
	local m = FS.mission(player)
	return m == M.FROG_ASKED or m == M.RAGS or m == M.KISS_ASKED
end

local BUNNY = { LOOKING = 80, SPIT = 81 }
function FS.bunnySay(npc, creature, message, npcHandler)
	if not FS.enabled() then
		return false
	end
	local player = Player(creature)
	if not player or not FS.wantsDress(player) then
		return false
	end
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	if contains(message, "dress", "dresses", "clothes") then
		say(npcHandler, npc, creature, "What do you want here, sneaking around like a thief at night? Are you looking for something?")
		npcHandler:setTopic(id, BUNNY.LOOKING)
		return true
	elseif topic == BUNNY.LOOKING and contains(message, "yes") then
		say(npcHandler, npc, creature, "Well then spit it out! What are you sniffing around here for?")
		npcHandler:setTopic(id, BUNNY.SPIT)
		return true
	elseif topic == BUNNY.LOOKING and contains(message, "no") then
		say(npcHandler, npc, creature, "Then stop sneaking around, commoner!") -- ours
		npcHandler:setTopic(id, 0)
		return true
	elseif (topic == BUNNY.SPIT or topic == BUNNY.LOOKING) and contains(message, "old rags", "old rag", "rags", "rag") then
		npcHandler:setTopic(id, 0)
		if player:getItemCount(FS.items.rags) == 0 then
			player:addItem(FS.items.rags, 1)
		end
		if FS.mission(player) == M.FROG_ASKED then
			FS.setMission(player, M.RAGS)
		end
		say(npcHandler, npc, creature, "You need some old rags? Well, we support the needy. So I guess there's no harm in giving you these old clothes. And now please leave the castle, commoner.")
		return true
	end
	return false
end

logger.info("[Family] The Scatterbrained Sorcerer Quest: {}", Family.scatterbrainedSorcerer and "on" or "off")
