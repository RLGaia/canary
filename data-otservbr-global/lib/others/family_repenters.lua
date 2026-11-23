-- Gaia Family server: The Repenters Quest, Ashari's four daily tasks in Hellgate (2026-11-23).
-- Ours: upstream had Ashari with a greeting, Larfion with nothing, the items and the map, but no
-- task, no dialogue and no item script.
--
-- Sources: TibiaWiki BR backup ("The Repenters Quest" with its screenshots, "Larfion The Shaman",
-- "Repenter (Achievement)"), TibiaWiki EN ("The Repenters Quest/Spoiler", "Ashari/Transcripts",
-- the item and creature pages).
--   watering  elven vial at the cradle of tears (32606,31672,13)          2,000 exp
--   magic     receptacle on wild fury, nature, fire, water magic; Larfion  2,300 exp
--   fire      firecatcher urn on 5 furious fire elemental ashes           2,200 exp
--   mushroom  trained fire bug on 5 mushrooms of the crystal cave          2,100 exp
--   bonus     all four reported: 2,000 exp, Repenter, sometimes a Pannier Backpack, 5 shortcut
--             passages. 10,600 experience in all (both wikis); no gold (EN: removed in 2014).
-- All four can run at once; each again 20 hours after its report (EN; BR: daily). The bonus once
-- per round of four, as Norman's (Venore Daily Tasks). Shortcut: each bonus sets 5 passages (BR;
-- EN says 5 per character for life: the wikis disagree, Rodrigo 2026-11-23 took the suggested BR).
-- Ashari's and Larfion's lines are the wiki transcripts (EN for Ashari's tasks and lore, BR for
-- Larfion's lore); lines for a task still running, one done recently, a lost item and the quest
-- log texts are ours. Our numbers where the wikis give none: Pannier Backpack 10% ("rare"), a lost
-- item replaced once every 10 minutes (BR: "only every so often").
--
-- Ashari's and Larfion's files call FamilyRepenters.setupAshari / setupLarfion; the items, the
-- leaf golems, the fire cave and the shortcut are in data-otservbr-global/scripts/family/repenters.lua.
-- Loaded from lib/others/load.lua, before the NPCs.

FamilyRepenters = {
	FREE = 0,
	ACTIVE = 1,
	READY = 2,
	REPORTED = 3,
	order = { "watering", "magic", "fire", "mushroom" },
	cooldown = 20 * 3600, -- EN
	lostWait = 10 * 60, -- ours
	pannierChance = 10, -- ours, "rare"
	passages = 5, -- BR and EN
	bonusExperience = 2000,
	items = {
		vial = 18991,
		vialFull = 18992,
		receptacle = 19108,
		receptacleFull = 19109,
		urn = 19107,
		urnHot = 19149,
		bug = 19124,
		pannier = 19159,
	},
	tasks = {
		watering = { storage = "Watering", experience = 2000 },
		magic = { storage = "Magic", experience = 2300 },
		fire = { storage = "Fire", experience = 2200 },
		mushroom = { storage = "Mushroom", experience = 2100 },
	},
	needed = { flames = 5, mushrooms = 5, magic = 4 },
}

local R = FamilyRepenters
local KV_SCOPE = "family-repenters"

function R.S()
	return Storage.Quest.U10_10.TheRepenters
end
local S = R.S

function R.kv(player)
	return player:kv():scoped(KV_SCOPE)
end

function R.storage(task)
	return S()[R.tasks[task].storage]
end

function R.value(player, key)
	return math.max(0, player:getStorageValue(S()[key]))
end

function R.refresh(player)
	local kv = R.kv(player)
	local now = os.time()
	for _, task in ipairs(R.order) do
		if player:getStorageValue(R.storage(task)) == R.REPORTED then
			local at = kv:get("reported-" .. task)
			if not at or now >= at + R.cooldown then
				player:setStorageValue(R.storage(task), R.FREE)
			end
		end
	end
end

function R.waitLeft(player, task)
	local at = R.kv(player):get("reported-" .. task) or 0
	return math.max(0, at + R.cooldown - os.time())
end

function R.hoursText(seconds)
	local hours = math.ceil(seconds / 3600)
	return hours <= 1 and "about an hour" or ("about " .. hours .. " hours")
end

-- Done when the filled item is carried (vial, receptacle, hot urn) or the mushrooms are counted.
function R.state(player, task)
	R.refresh(player)
	local value = player:getStorageValue(R.storage(task))
	if value < 0 then
		return R.FREE
	end
	if value == R.ACTIVE then
		local it = R.items
		if (task == "watering" and player:getItemCount(it.vialFull) > 0)
			or (task == "magic" and player:getItemCount(it.receptacleFull) > 0)
			or (task == "fire" and player:getItemCount(it.urnHot) > 0) then
			return R.READY
		end
	end
	return value
end

local function setState(player, task, value)
	player:setStorageValue(R.storage(task), value)
	if value == R.ACTIVE and player:getStorageValue(S().Questline) < 1 then
		player:setStorageValue(S().Questline, 1)
	end
end
R.setState = setState

local function giveItem(player, task)
	local it = R.items
	if task == "watering" then
		player:addItem(it.vial, 1)
	elseif task == "magic" then
		player:setStorageValue(S().MagicStage, 0)
		player:addItem(it.receptacle, 1)
	elseif task == "fire" then
		player:setStorageValue(S().Flames, 0)
		player:addItem(it.urn, 1)
	elseif task == "mushroom" then
		player:setStorageValue(S().Mushrooms, 0)
		R.kv(player):set("mushrooms", "")
		player:addItem(it.bug, 1)
	end
end

function R.start(player, task)
	if R.state(player, task) ~= R.FREE then
		return false
	end
	setState(player, task, R.ACTIVE)
	giveItem(player, task)
	return true
end

local function carries(player, task)
	local it = R.items
	local ids = ({
		watering = { it.vial, it.vialFull },
		magic = { it.receptacle, it.receptacleFull },
		fire = { it.urn, it.urnHot },
		mushroom = { it.bug },
	})[task]
	for _, id in ipairs(ids) do
		if player:getItemCount(id) > 0 then
			return true
		end
	end
	return false
end

-- A lost task item: "given", "has" (still carried), "wait" (asked too soon), "none" (no task).
function R.replace(player, task)
	if R.state(player, task) ~= R.ACTIVE then
		return "none"
	end
	if task == "mushroom" and R.value(player, "Mushrooms") >= R.needed.mushrooms then
		return "none"
	end
	if carries(player, task) then
		return "has"
	end
	local kv = R.kv(player)
	local at = kv:get("lost-at") or 0
	if os.time() < at + R.lostWait then
		return "wait"
	end
	kv:set("lost-at", os.time())
	giveItem(player, task)
	return "given"
end

-- Pays one task that is done. Returns true when paid.
function R.report(player, task)
	if R.state(player, task) ~= R.READY then
		return false
	end
	local it = R.items
	local take = ({ watering = it.vialFull, magic = it.receptacleFull, fire = it.urnHot })[task]
	if take and not player:removeItem(take, 1) then
		return false
	end
	setState(player, task, R.REPORTED)
	R.kv(player):set("reported-" .. task, os.time())
	player:addExperience(R.tasks[task].experience, true)
	return true
end

function R.allReported(player)
	for _, task in ipairs(R.order) do
		if R.state(player, task) ~= R.REPORTED then
			return false
		end
	end
	return true
end

-- The bonus counts once per round of four: claimed after the first report of the round.
function R.bonusTaken(player)
	local kv = R.kv(player)
	local first
	for _, task in ipairs(R.order) do
		local at = kv:get("reported-" .. task) or 0
		first = first and math.min(first, at) or at
	end
	return (kv:get("bonus-at") or 0) >= (first or 0)
end

-- Returns "paid" (+ true when a Pannier Backpack came with it), "taken" or "missing".
function R.claimBonus(player)
	if not R.allReported(player) then
		return "missing"
	end
	if R.bonusTaken(player) then
		return "taken"
	end
	R.kv(player):set("bonus-at", os.time())
	player:setStorageValue(S().Bonus, 1)
	player:addExperience(R.bonusExperience, true)
	player:addAchievement("Repenter")
	player:setStorageValue(S().Passages, R.passages)
	local pannier = math.random(100) <= R.pannierChance
	if pannier then
		player:addItem(R.items.pannier, 1)
	end
	return "paid", pannier
end

-- The wild magic order: fury (red), nature (green), fire (yellow), water (blue).
R.magicOrder = {
	{ name = "Wild Fury Magic", text = "You catch a sparkle of wild fury magic and capture it inside the receptacle." },
	{ name = "Wild Nature Magic", text = "You cut off a chunk of wild nature magic and capture it inside the receptacle." },
	{ name = "Wild Fire Magic", text = "You grab a piece of wild fire magic and capture it inside the receptacle." },
	{ name = "Wild Water Magic", text = "You soak up a bit of wild water magic and capture it inside the receptacle." },
}

-- Quest log texts (ours).
function R.describe(player, task)
	local state = R.state(player, task)
	if state == R.REPORTED then
		return "Done. Ashari has this task for you again in " .. R.hoursText(R.waitLeft(player, task)) .. "."
	end
	if state == R.READY then
		if task == "magic" then
			return "The receptacle is filled with a dry, rough powder. Bring it to Larfion the Shaman."
		end
		return "Done. Report to Ashari."
	end
	if state ~= R.ACTIVE then
		return "Ask Ashari in Hellgate for this task."
	end
	if task == "watering" then
		return "Fill the elven vial at the unspoilt cradle of tears, below the cave of leaves west of the camp, and bring it to Ashari. The water does not stay in the vial forever."
	elseif task == "magic" then
		return string.format("Use the receptacle on the wild magic in the magical cavern west of the camp, in this order: fury (red), nature (green), fire (yellow), water (blue). Caught: %d / 4", R.value(player, "MagicStage"))
	elseif task == "fire" then
		return string.format("Kill furious fire elementals in the hot cave far below the camp and use the firecatcher urn on their ashes at once. Flames caught: %d / 5", R.value(player, "Flames"))
	elseif task == "mushroom" then
		if R.value(player, "Mushrooms") >= R.needed.mushrooms then
			return "Done. Report to Ashari."
		end
		return string.format("Use the trained fire bug on the infected mushrooms of the crystal cave west of the camp. Mushrooms sterilised: %d / 5", R.value(player, "Mushrooms"))
	end
	return ""
end

-- ---------------------------------------------------------------------------
-- Ashari
-- ---------------------------------------------------------------------------
local BONUS_HINT = "Don't forget to talk to me if you think you're ready for your {bonus}."

local offers = {
	watering = {
		words = { "watering", "garden" },
		offer = {
			"Thank you. We use the unscathed tears of the gods we found in these hellish depths to water our gardens. It is thanks to these that we can survive down here. The garden feeds us as the fire gives us warmth. ...",
			"Take this vial and venture down the path of these depths to find the unspoilt cradle of tears. Oh - and please heed my words: there are old remains of the forest above down there. They seem connected to the cradle. Sometimes... they can come alive.",
		},
		report = {
			"Great, so you found the cradle and brought back the tears! Thank you so much on behalf of everyone here. " .. BONUS_HINT .. " ...",
			"Please return tomorrow if you want to help us again, the gardens need to be watered every day.",
		},
	},
	magic = {
		words = { "magic" },
		offer = {
			"Our shaman, Larfion, has asked me again to cultivate some of the wild magic for him that roams free in some nearby caverns. I do not know what this is for, but he seems to need quite much of this lately. ...",
			"It is a demand we simply cannot fulfil with all our other tasks at hand. ...",
			"Please take this receptacle to the magical cavern, you will recognise it when you are surrounded by magic. There are strangely coloured crystals down there but they are harmless. ...",
			"You will need to concentrate to cultivate the wild magic there. Listen carefully as I will try to explain to you how this is done: ...",
			"The most important thing is the order. First you gather 'fury magic' which usually appears red, second you should gather 'nature magic', appearing green. The third component to combine the two previous is 'fire magic' which should be fiery yellow. ...",
			"To neutralise all three and complete the cultivation, you should add a tiny bit of 'water magic' which shimmers blue. The components in the receptacle will now melt to a physical form and form a dry, rough powder.",
		},
	},
	fire = {
		words = { "fire" },
		offer = {
			"Our ancestors were sent into the fire for their sins. Yet, our small settlement needs the fire to survive. We also need fire to cleanse ourselves in a traditional ritual. ...",
			"There are harmless flames emanating from the ashes of fire elementals in extremely hot areas. There is a cave not that far from here where we used to gather fire for the ritual using firecatcher urns. ...",
			"However, recently the heat down there has risen tremendously. The only way to gather the fire from the ashes would be to quickly get in, eliminate enough elementals and gather the flames from their ashes with the firecatcher urn I gave you.",
		},
		report = "You gathered the flames with the firecatcher urn! Thank you very much on behalf of everyone here. " .. BONUS_HINT,
	},
	mushroom = {
		words = { "mushroom", "mushrooms" },
		offer = {
			"We mine crystals from some nearby mines. The meagre ore veins we found were not enough to make and repair useful, durable tools for everyone. ...",
			"The crystal cave we used to visit to get the crystals is near our camp, yet we cannot go there anymore. The cave is also hotbed for large mushrooms. Those are not exactly edible but not dangerous, either. ...",
			"However, our workers started to get sick mining there. We used to train firebugs to use them as a means to create fire. They would help a great deal in eliminating this spreading disease. ...",
			"When we discovered that it's a strange illness that befell the mushrooms, most workers refused to go even near that cave. Now we have no elf left to fight this plague. Please go to the mine and burn away that pest.",
		},
		report = "Burning away the illness from those mushrooms helped us a great deal but it is a long way until the caves are truly free from this plague. Thank you very much. " .. BONUS_HINT,
	},
}
R.offers = offers

local MAGIC_DONE = "So you followed the right order of colours and cultivated some wild magic for our shaman, I am impressed! Please visit him at once and tell him, I am sure he will provide some sort of reward for helping him out."

-- Ashari's answer to a task word. Returns the text (string or table).
function R.answer(player, task)
	local state = R.state(player, task)
	if task == "mushroom" and state == R.ACTIVE and R.value(player, "Mushrooms") >= R.needed.mushrooms then
		state = R.READY
	end
	if state == R.FREE then
		R.start(player, task)
		return offers[task].offer
	elseif state == R.READY then
		if task == "magic" then
			return MAGIC_DONE
		end
		if task == "mushroom" then
			player:setStorageValue(R.storage(task), R.READY)
		end
		R.report(player, task)
		return offers[task].report
	elseif state == R.REPORTED then
		return "You already helped us with that. Please return in " .. R.hoursText(R.waitLeft(player, task)) .. " if you want to help us again." -- ours
	end
	return "You are still working on it, I see. " .. R.describe(player, task) .. " If you lost what I gave you, just ask me for a new one." -- ours
end

local LOST = {
	given = "Here, take a new one. Please be more careful with it, we do not have many of them.", -- ours
	has = "But you still have it with you!", -- ours
	wait = "I just gave you a new one. Look for the old one first, we do not have many of them.", -- ours
	none = "I did not give you anything like that for a task.", -- ours
}

local BONUS_TEXT = {
	"So you want a bonus, let's see what you did there. You helped us watering the gardens, you drove back the disease at the mines, you collected flames for our ritual. ...",
	"And - perhaps the most important task in the eyes of our shaman - you cultivated wild magic for him. And all this in a single day! Thank you on behalf of our humble enclave, here is your bonus.",
}

local BONUS_PANNIER = "And - perhaps the most important task in the eyes of our shaman - you cultivated wild magic for him. And all this in a single day! Thank you on behalf of our humble enclave, here is your bonus and a pannier to carry it all."

local SHORTCUT = {
	"One more thing, as I believe you can handle yourself quite well. ...",
	"You can now use the passage back there to shorten your way back to the surface a bit. I can only grant you five passages, however, as I do not wish the others to think I allow strangers to come and go as they please.",
}

function R.bonusText(player)
	local result, pannier = R.claimBonus(player)
	if result == "missing" then
		return "If you manage to help us with {watering} our garden, the wild {magic}, the {fire} and the {mushrooms} in a single day, I will offer a bonus. You are not done yet." -- ours
	elseif result == "taken" then
		return "You already received your bonus. Help us with all four tasks again and I will offer another one." -- ours
	end
	local lines = { BONUS_TEXT[1], pannier and BONUS_PANNIER or BONUS_TEXT[2] }
	lines[2] = lines[2] .. " ..."
	lines[3] = SHORTCUT[1]
	lines[4] = SHORTCUT[2]
	return lines
end

local ASHARI_LORE = {
	{ { "name" }, "My name is Ashari. Mh... everything all right? You look as if it has some meaning to you? Oh sorry, I hope I did not offend you." },
	{ { "job" }, "I am the {first voice} amongst this {community}." },
	{ { "first voice" }, "I am the leader of our people in worldly matters. I am the one who gives everyone its responsibilities and sees over our {resources}." },
	{ { "resources" }, "This world is unforgiving and barren. Little can be done about that, but those of the {second generation} left us with more than the sins of the ancestors. They also gave us a home, hope, and at least some meagre resources." },
	{ { "second generation" }, {
		"We do not know for how long sinners have lived and died here in the afterworld before some of the second generation saw the damnation that the deeds of the first brought upon them. ...",
		"Second generation might have only been true for some of them. Some might have been third of fourth generation already, who knows. ...",
		"They were free of some of the {taint} of their mothers and fathers, and saw through their lies. Saw them as the sinners that they were. ...",
		"It became clear to them and their leader Feridil that only by distancing themselves from the sinful outcasts, they could begin the long walk on the road to salvation. ...",
		"They drove off the sinners and claimed a small part of this afterworld for themselves. They chose a home near the entrance to the afterworld to make it easier for the wise of Abar Dendri to watch and ultimately judge them. ...",
		"They also made note of each new sinner, that arrived in the afterworld. And they marked them, so they could later tell if a petitioner who came to join them, was of second generation at least. ...",
		"They secured the resources that they needed and organised their harvest. That was how our community came to be.",
	} },
	{ { "taint" }, "Larfion, our shaman, knows more about such matters. He is the guardian of our souls." },
	{ { "community" }, "We are bound together in our need to {purify} ourselves in this harsh {afterworld}. Our {resources} are limited and our enemies numerous. But it will help us to {atone}." },
	{ { "purify" }, "Meditation and hard work purify body and soul. But the {taint} runs deep." },
	{ { "atone" }, "Meditation and hard work purify body and soul. But the {taint} runs deep." },
	{ { "afterworld" }, "This is but a mockery of the world of light. Here we do not live, but are not truly dead either. We are similar to the undead that roam these caves. But unlike them we have the hope to {atone}." },
}

function R.setupAshari(keywordHandler, npcHandler)
	npcHandler:setMessage(MESSAGE_GREET, "Hello, stranger! These caves must seem strange to you. I wonder what brings you here... maybe you are interested in some work? There are several {tasks} I could need a hand with.")
	npcHandler:setMessage(MESSAGE_FAREWELL, "Bye!")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "Bye!")

	local function sayer(text)
		return function(npc, player)
			npcHandler:say(text, npc, player)
			return true
		end
	end
	local function call(fn)
		return function(npc, player)
			npcHandler:say(fn(player), npc, player)
			return true
		end
	end

	local tasksText = {
		"Oh if you want to help me, you can lend me a hand {watering} our garden, cultivating wild {magic} for our shaman, collecting {fire} for our settlement. ...",
		"You can also start by helping us sterilise the dangerous {mushrooms} that have been preventing us from entering our crystal mines. They are literally spreading like a disease lately. ...",
		"If you manage to get all of this done in a single day, I will offer a {bonus}!",
	}
	for _, word in ipairs({ "tasks", "task", "work", "help", "mission" }) do
		keywordHandler:addKeyword({ word }, sayer(tasksText))
	end
	-- the lost-item words first: "fire bug" and "firecatcher urn" must not answer as "fire"
	local lost = {
		{ { "elven vial", "vial" }, "watering" },
		{ { "receptacle" }, "magic" },
		{ { "firecatcher urn", "urn" }, "fire" },
		{ { "trained fire bug", "fire bug", "firebug" }, "mushroom" },
	}
	for _, entry in ipairs(lost) do
		for _, word in ipairs(entry[1]) do
			keywordHandler:addKeyword({ word }, call(function(player)
				return LOST[R.replace(player, entry[2])]
			end))
		end
	end
	for _, task in ipairs(R.order) do
		for _, word in ipairs(offers[task].words) do
			keywordHandler:addKeyword({ word }, call(function(player)
				return R.answer(player, task)
			end))
		end
	end
	keywordHandler:addKeyword({ "bonus" }, call(R.bonusText))
	for _, entry in ipairs(ASHARI_LORE) do
		for _, word in ipairs(entry[1]) do
			keywordHandler:addKeyword({ word }, sayer(entry[2]))
		end
	end
end

-- ---------------------------------------------------------------------------
-- Larfion the Shaman (BR transcript; his lore words are BR's)
-- ---------------------------------------------------------------------------
local LARFION_LORE = {
	{ { "job" }, "I'm the spiritual guide and keeper of knowledge for this {community}." },
	{ { "community" }, "We are the shame born, the repenters, the pardoners. The sins of our {ancestors} are the poison in our souls and our shame in the eyes of those born in the light of the {suns}." },
	{ { "ancestors" }, {
		"Our ancestors were outcasts and evil. We still bear their taint and shame. No such sinner is allowed in our ranks, but we welcome all those born down here. ...",
		"Only who is of the second generation can atone for the unspeakable sins that led to the punishment of the ancestors.",
	} },
	{ { "suns" }, "The suns are the eternal eyes of the {great judge}. He who is the justice of the {purified}." },
	{ { "great judge" }, "The suns are the eternal eyes of the great judge. He who is the justice of the {purified}." },
	{ { "purified" }, "All those who are born without sin in the light of the suns are purified in death. Unlike us {tainted} ones." },
	{ { "tainted" }, {
		"We are unclean because of the sins of our ancestors. In this harsh afterworld we are allowed to distance us from the ancestors and atone for their sins. If we die here, we are damned into nothingness. ...",
		"Only if we live in purity and humility, we might find pardon in the eyes of the {lightborn}.",
	} },
	{ { "lightborn" }, {
		"Those who are born under the light of the suns, are born pure. Unlike us. They live a life in light, splendour and without hunger, thirst or fear. They are wise and just and watching us. ...",
		"If they deem us worthy, they will take us into the light on the day of the {prophecy}.",
	} },
	{ { "prophecy" }, {
		"Our ancestors were soaked with evil. They were vile criminals that were cast out of the light and the lands of splendour that the ancestors called {Abar Dendri}. ...",
		"The wise judges of Abar Dendri spoke justice and they spoke true. No outcast was ever to see the light of the suns again. No single life could atone for their sins. ...",
		"Through those wise words they gave a clue. A shed of hope which they bestowed upon the sinners in their wisdom and mercy. ...",
		"But they were blinded by the darkness of the afterworld, they have been banished and their minds were clouded by the evil of their sins. ...",
		"Only Feridil of the second generation was enlightened enough to see what those words meant. He gathered the second born, slew the sinners and drove off those who escaped to cast them deeper into darkness. ...",
		"Then the great judge spoke to him in a vision. He showed him the path to salvation by purifying the blood by generations of {atonement}.",
	} },
	{ { "atonement" }, {
		"In their wisdom the wise of Abar Dendri provided the children of the sinners with an harsh environment to work off the sins through hard work. ...",
		"With every drop of sweat and blood that is shed in our suffering a little bit of the ancestors sinfulnesses is driven out. ...",
		"Only by enduring this trial we can better ourself. It is a slow process, since obviously the ancestors' sins were grave. ...",
		"If we needed any proof for that, the fact that the wise of Abar Dendri have not yet deemed us worthy to return into the light should show any doubter that we are not cleansed yet.",
	} },
	{ { "abar dendri" }, "Abar Dendri it is! As the words of the repenters that came before us told us. It is the land of plenty, without any need and where the light always shines and it is warm without a fire." },
}

-- Larfion's "something" -> yes -> yes. A "no" at either question loses the cultivated magic
-- (EN: "if you say the wrong thing your quest will be reset"): the filled receptacle turns back
-- into an empty one and the colours start again.
function R.larfionReward(player)
	if R.state(player, "magic") ~= R.READY then
		return nil
	end
	R.report(player, "magic")
	return {
		"Oh indeed... INDEED. This is what I was looking for. I... I now need some time alone but if Ashari ever happens to send you gathering more of this... you know where you can find Ashari. ...",
		"Oh a reward? Of... of course, here you go. If you want some sort of {bonus} you would have to talk to Ashari.",
	}
end

function R.larfionRefused(player)
	if R.state(player, "magic") == R.READY then
		player:removeItem(R.items.receptacleFull, 1)
		player:addItem(R.items.receptacle, 1)
		player:setStorageValue(S().MagicStage, 0)
		return "No? NO? Then... then it is useless to me! Ruined, all of it! Go and gather it again, properly this time." -- ours
	end
	return "Then do not waste my time." -- ours
end

function R.setupLarfion(keywordHandler, npcHandler)
	npcHandler:setMessage(MESSAGE_GREET, "I greet you - and I have to ask you to... just tell me if you have {something} for me.")
	npcHandler:setMessage(MESSAGE_FAREWELL, "Yes, yes erm - goodbye.")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "Yes, yes erm - goodbye.")

	local something = keywordHandler:addKeyword({ "something" }, function(npc, player)
		npcHandler:say("Yes, well you see, I am... waiting for something. Did Ashari tell you anything? Or ask you to do something?", npc, player)
		return true
	end)
	local handOver = something:addChildKeyword({ "yes" }, function(npc, player)
		npcHandler:say("So you have it? Yes? Well then give it to me! Hand it over... I mean... I really need to check if the cultivated magic has been... treated properly. You know? Do you understand? And I want to see it... now.", npc, player)
		return true
	end)
	something:addChildKeyword({ "no" }, function(npc, player)
		npcHandler:say(R.larfionRefused(player), npc, player)
		npcHandler:resetNpc(player)
		return true
	end)
	handOver:addChildKeyword({ "yes" }, function(npc, player)
		local text = R.larfionReward(player)
		npcHandler:say(text or "You do not have it! Do not play games with me. Come back when Ashari sent you to cultivate the wild magic... and you did.", npc, player) -- second line ours
		npcHandler:resetNpc(player)
		return true
	end)
	handOver:addChildKeyword({ "no" }, function(npc, player)
		npcHandler:say(R.larfionRefused(player), npc, player)
		npcHandler:resetNpc(player)
		return true
	end)

	for _, entry in ipairs(LARFION_LORE) do
		for _, word in ipairs(entry[1]) do
			keywordHandler:addKeyword({ word }, function(npc, player)
				npcHandler:say(entry[2], npc, player)
				return true
			end)
		end
	end
end
