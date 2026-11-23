-- Gaia Family server: Threatened Dreams Quest review (2026-11-22, asked by Rodrigo: "check if everything
-- is working, including related items and dialogs").
--
-- Sources: TibiaWiki BR "Threatened Dreams Quest" (our backup, with its screenshots) and TibiaWiki EN
-- "Threatened Dreams Quest/Spoiler" (method, transcripts, server messages) and the NPC transcript pages
-- (lore words: lib/others/family_threatened_dreams_lore.lua). Lines marked "ours" are on neither wiki.
--
-- What changed against upstream:
--   Troubled Animals: Alkestios answers "mission" too (EN; BR "help") and "book" (EN); Ahmet turns the
--   book with old legends into the doctored one (EN item 25239), which is the one placed on the poacher
--   table; Ikassis gives the fae talisman (BR, EN); the ghostly wolf's lines after the fur (EN) and
--   "whelp" (EN); the pile of bones at Ulderek's Rock also works when the tent square was skipped;
--   feathers with the EN messages; lore words of Alkestios, Ikassis, the wolf and the swan (EN).
--   A Dream Come True: Maelyrra only starts after Alkestios' seal and asks for the three vessels;
--   the starlight vial counted on the moon mirror's storages (the barrier could not be finished when
--   the sculptures were done first); the vessels work on the whole sculpture, tree or mosaic;
--   Kroazur's lair is free access (EN); a freed fairy comes back after a minute (EN).
--   An Unlikely Couple: the panpipes no longer set the mission back; "fishtail" for the dancing fairy
--   (EN); the notes go to Aurita (EN) or Taegen (BR); Taegen asks for the raven herb at "mission" (EN);
--   the raven herb bush stands where the BR page shows it (33496,32197), also after a restart at
--   night, and gives one herb per night (upstream: once in 20 days).
--   Added (upstream had the NPCs without dialogue): The Fairy Treasure (Tooth Fairy, Tired Tree,
--   Grumpy Stone, the big fly agaric, the sun mosaic in the south of Thais, the tooth collection and
--   Toothfairy Assistant) and The Swan Feather Cloak (Valindara, 100 swan feathers at 8 swans of
--   Feyrist by day, 5 every 20 h each, the cloak 20 h later: EN; BR says 24 h). Watering can on a
--   happy sentient oak gives a blessed acorn every 10 h (BR, EN), and the acorn heals (EN).
--   Valindara greets as on both wikis and sells lemons and raspberries (BR).
--
-- Player storages: Storage.Quest.U11_40.ThreatenedDreams (the update's block, 45751-45850).
-- World objects: scripts/family/threatened_dreams.lua. Quest log: catalog/045_threatened_dreams.lua.
-- NPC files that call this: alkestios, ikassis, ghostly_wolf, a_swan, maelyrra, aurita, dancing_fairy,
-- taegen, valindara, tooth_fairy, tired_tree, grumpy_stone (FamilyThreatenedDreams.setupNpc).
-- Switch: Family.threatenedDreams (false = NPCs and objects as upstream).

Family = Family or {}
Family.threatenedDreams = true

FamilyThreatenedDreams = FamilyThreatenedDreams or {}
local D = FamilyThreatenedDreams
local TD = Storage.Quest.U11_40.ThreatenedDreams
D.TD = TD

function D.enabled()
	return Family.threatenedDreams == true
end

-- Items
D.BOOK = 25235 -- book with old legends (poacher chest)
D.BOOK_DOCTORED = 25239 -- book with old legends (doctored, EN)
D.TALISMAN = 25295
D.FUR = 25238
D.TATTERED_FEATHER = 25244
D.MUSIC_NOTES = 25782
D.RAVEN_HERB = 5953
D.MOON_DARK, D.MOON_LIT = 25729, 25730
D.VIAL_EMPTY, D.VIAL_GLEAMING = 25731, 25732
D.SUN_DARK, D.SUN_SHINING = 25733, 25734
D.PRESENT = 25302
D.MILK_TOOTH = 25303
D.MAP_UPPER_LEFT, D.MAP_BOTTOM_LEFT, D.MAP_UPPER_RIGHT = 24943, 24944, 24945
D.OLD_MAP = 24947
D.SWAN_FEATHER = 26181
D.SWAN_CLOAK = 25779
D.SMALL_RUBY = 3030
D.BLESSED_ACORN = 26074

-- Player storages (ours, inside the update's block)
D.S = {
	FairyTreasure = 45800, -- quest log: 1 started, 2 treasure found
	ToothFairy = 45801, -- 1 presents taken, 2 milk teeth delivered
	Tooth = { quero = 45802, allen = 45803, rowenna = 45804 }, -- milk tooth found
	Present = { quero = 45805, allen = 45806, rowenna = 45807 }, -- present on the pillow
	TiredTree = 45808, -- 1 asked for a story, 2 map part given
	GrumpyStone = 45809, -- 1 asked for scratching, 2 map part given
	Stones = { 45810, 45811, 45812, 45813, 45814 },
	OldMap = 45815, -- 1 the fourth part found
	Treasure = 45816,
	Cause = 45817, -- 1 told about the tooth collection
	Teeth = 45818, -- 45818-45823, one per tooth
	SwanCloak = 45824, -- 1 asked, 2 crafting, 3 received
	SwanCloakReady = 45825, -- os.time() when the cloak is ready
	SwanSpots = 45826, -- 45826-45833, os.time() when a spot gives feathers again
	AcornWater = 45834, -- os.time() when the oak gives an acorn again
	AcornEat = 45835, -- os.time() when an acorn can be eaten again
}
local S = D.S

function D.get(player, key)
	local v = player:getStorageValue(key)
	return v < 0 and 0 or v
end

function D.set(player, key, value)
	player:setStorageValue(key, value)
end

local function has(player, id, count)
	return player:getItemCount(id) >= (count or 1)
end

-- The quest log shows the quest once its first storage is set; side missions may come first.
function D.startLog(player)
	if D.get(player, TD.QuestLine) < 1 then
		D.set(player, TD.QuestLine, 1)
	end
end

function D.startFairyTreasure(player)
	D.startLog(player)
	if D.get(player, S.FairyTreasure) < 1 then
		D.set(player, S.FairyTreasure, 1)
	end
end

function D.isNight()
	return getTibiaTimerDayOrNight() == "night"
end

-- Give an item or say why not (the usual quest chest wording).
function D.give(player, id, count, foundText)
	count = count or 1
	local weight = ItemType(id):getWeight(count)
	if player:getFreeCapacity() < weight then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, foundText .. ". Weighing " .. string.format("%.2f", weight / 100) .. " oz, it is too heavy for you to carry.")
		return false
	end
	if not player:addItem(id, count) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, foundText .. ". But you have no room to take it.")
		return false
	end
	return true
end

-- ---------------------------------------------------------------------------
-- NPC talk: quest words first (each NPC's handler), then the lore words of the
-- EN transcripts (longest keyword first, whole words).
-- ---------------------------------------------------------------------------

D.handlers = {}
D.npcs = {
	["Alkestios"] = { greet = "Nature's blessing, traveller! May you not be affected by any sinister force.", farewell = "May your path always be even." },
	["Ikassis"] = { greet = "Nature's blessing, traveler!", farewell = "May Mother Nature protect you." },
	["Ghostly Wolf"] = { greet = "You are speaking the language of animals? I'm surprised. But I'm not in the right {mood} for a chat.", farewell = "Farewell." },
	["A Swan"] = { greet = "I salute you, mortal being.", farewell = "May your path be always even." },
	["Maelyrra"] = { greet = "Nature's blessings! Welcome to the land of dreams.", farewell = "May your path always be even." },
	["Aurita"] = { greet = "Greetings, traveller!", farewell = "May your path always be even." },
	["Dancing Fairy"] = { greet = "Nature's blessing!", farewell = "May your path always be even." },
	["Taegen"] = { greet = "Be greeted, mortal being!", farewell = "May enlightenment be your path, |PLAYERNAME|." },
	["Valindara"] = { greet = "Greetings, mortal being!", farewell = "May enlightenment be your path, |PLAYERNAME|." },
	["Tooth Fairy"] = { greet = "Greetings, human being.", farewell = "Farewell, human being." }, -- farewell ours
	["Tired Tree"] = { greet = "*yawn* Nature's blessing.", farewell = "Zzzzzz ..." }, -- farewell ours
	["Grumpy Stone"] = { greet = "Please don't bother me, human being. I have my own problems.", farewell = "Finally." }, -- farewell ours
}

function D.contains(message, words)
	for _, w in ipairs(words) do
		if MsgContains(message, w) then
			return true
		end
	end
	return false
end

function D.lore(name, message)
	local list = FamilyThreatenedDreamsLore and FamilyThreatenedDreamsLore[name]
	if not list then
		return nil
	end
	local best, bestLen
	for _, entry in ipairs(list) do
		for _, word in ipairs(entry[1]) do
			if (not bestLen or #word > bestLen) and MsgContains(message, word) then
				best, bestLen = entry[2], #word
			end
		end
	end
	return best
end

-- fallback: the NPC file's own callback (other quests or upstream words), asked last.
function D.talk(name, npc, creature, message, npcHandler, fallback)
	local player = Player(creature)
	if not player then
		return true
	end
	local handler = D.handlers[name]
	if handler and handler(npc, player, message, npcHandler) then
		return true
	end
	local text = D.lore(name, message)
	if text then
		npcHandler:say(text, npc, creature)
		npcHandler:setTopic(player:getId(), 0)
		return true
	end
	if fallback then
		return fallback(npc, creature, nil, message)
	end
	return true
end

-- Called by each NPC file after its own callbacks. opts.fallback: see D.talk.
function D.setupNpc(name, npcHandler, opts)
	local info = D.npcs[name]
	if not info or not D.enabled() then
		return
	end
	opts = opts or {}
	npcHandler:setMessage(MESSAGE_GREET, info.greet)
	npcHandler:setMessage(MESSAGE_FAREWELL, info.farewell)
	npcHandler:setMessage(MESSAGE_WALKAWAY, info.farewell)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		if not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		return D.talk(name, npc, creature, message, npcHandler, opts.fallback)
	end)
end

local function say(npcHandler, npc, player, text, topic)
	npcHandler:say(text, npc, player)
	npcHandler:setTopic(player:getId(), topic or 0)
	return true
end

local function topic(npcHandler, player)
	return npcHandler:getTopic(player:getId())
end

-- ---------------------------------------------------------------------------
-- Troubled Animals
-- ---------------------------------------------------------------------------

local M1 = TD.Mission01[1]

local alkestios = {
	offer = {
		"I indeed have some troubles since I'm travelling this part of the world. When I took over the body of a white deer I wasn't aware that such an animal is a sought after quarry for hunters and poachers. ...",
		"Now I'm living in the constant danger of being caught and killed. Of course, I could just take over another animal but this deer has really grown on me. I'd like to help this beautiful stag but I need your assistance. Are you willing to help me?",
	},
	accept = {
		"Your decision honours you. However, if you consider killing the poachers in question I ask you to halt. We, the fae, are rather peaceful beings and abhor bloodshed. Therefore, we must find another way to solve this problem. ...",
		"I already have an idea: Some birds told me that poachers are a superstitious lot. Perhaps we can get them with their own misbelief. I know that the poachers have a kind of camp north of the Green Claw Swamps. ...",
		"Please search it out and examine it closely. Perhaps you will find something you can use against them in order to stop them from hunting white deer.",
	},
	search = "Please search it out and examine it closely. Perhaps you will find something you can use against them in order to stop them from hunting white deer.", -- the end of the EN line
	book = {
		"I see, you found a book that contains old myths and legends about the woods and the forest animals. This could be of some use for us. If you find someone who could add a story ... Let's say about how it brings ill luck to kill a white deer. ...",
		"As I said, poachers are rather superstitious. If they would read such a story in an old book, they probably would believe it to be true. In this case they might stop hunting me.",
	},
	chasing = "The poachers are still chasing me. Please hurry and find a way to help me.", -- upstream (ours)
	success = {
		"You succeeded! It seems the poachers have read your little faked story about killing white deer and the ensuing doom. They stopped chasing me. Thank you! ...",
		"You proved yourself trustworthy - at least as far as I am concerned. But as I told you I'm actually not a real animal. If you want to enter our hidden island, you must prove that you are also willing to help real animals. Would you do that?",
	},
	wolf = {
		"I heard there is a problem with a wolf mother and her whelps. However, I don't know more about it. One of my sisters, {Ikassis}, has taken over the body of a snake. ...",
		"She knows more about the wolf. Seek her out in the north-west of Edron, near a circle of standing stones.",
	},
	helping = "My sister {Ikassis} and the others still need your help. Seek her out in the north-west of Edron, near a circle of standing stones.", -- ours (EN fragment)
	trust = {
		"I'm very happy that you could help {fae} and animals alike. You earned our trust and may now visit our secret realm. I marked you with an arcane fae seal. Hereby you will be able to use the elemental shrines strewn about Tibia. ...",
		"There are fire, ice, energy and earth shrines. If you don't know their locations you can also reach them by most temples in this world. The elemental shrines will transport you to Feyrist now that you bear the magical seal.",
	},
	sealed = "The elemental shrines will transport you to Feyrist now that you bear the magical seal.", -- the end of the EN line
}

D.handlers["Alkestios"] = function(npc, player, message, npcHandler)
	local state = D.get(player, M1)
	if MsgContains(message, "book") and state == 1 and has(player, D.BOOK) then
		return say(npcHandler, npc, player, alkestios.book)
	end
	if MsgContains(message, "mission") or MsgContains(message, "help") then
		if state < 1 then
			return say(npcHandler, npc, player, alkestios.offer, 1)
		elseif state == 1 then
			if has(player, D.BOOK) then
				return say(npcHandler, npc, player, alkestios.book)
			end
			return say(npcHandler, npc, player, alkestios.search)
		elseif state == 2 then
			return say(npcHandler, npc, player, alkestios.chasing)
		elseif state == 3 then
			return say(npcHandler, npc, player, alkestios.success, 2)
		elseif state >= 4 and state <= 14 then
			return say(npcHandler, npc, player, state == 4 and alkestios.wolf or alkestios.helping)
		elseif state == 15 then
			D.set(player, M1, 16)
			return say(npcHandler, npc, player, alkestios.trust)
		end
		return say(npcHandler, npc, player, alkestios.sealed)
	end
	if MsgContains(message, "yes") then
		local t = topic(npcHandler, player)
		if t == 1 and state < 1 then
			D.startLog(player)
			D.set(player, M1, 1)
			return say(npcHandler, npc, player, alkestios.accept)
		elseif t == 2 and state == 3 then
			D.set(player, M1, 4)
			return say(npcHandler, npc, player, alkestios.wolf)
		end
		return false
	end
	if MsgContains(message, "no") and topic(npcHandler, player) ~= 0 then
		return say(npcHandler, npc, player, "Then not.") -- upstream (ours)
	end
	return false
end

local ikassis = {
	offer = {
		"One of my sisters, in the disguise of a nightingale, told me that {Alkestios} would send you. There is a problem which is not concerning me but a wolf mother on the small island Cormaya. ...",
		"As we, the {fae}, consider ourselves guardians and protectors of plants and animals, it is important for me to help this wolf. Unfortunately, I can't do it myself because at the moment I'm bound to this vessel, this snake. ...",
		"Thus I can't cross the ocean to reach Cormaya. Will you help me?",
	},
	accept = {
		"Nature's blessings! You may find the desperate wolf mother in the south of Cormaya. You will know the place because there is a big stone that looks like a grumpy face. ...",
		"At night it will weep bloody tears and only at night you will meet the ghost there. Take this talisman so you may be able to talk with animals and even plants and stones. Just don't expect that all of them will answer you.",
	},
	wolfHint = "You may find the desperate wolf mother in the south of Cormaya. You will know the place because there is a big stone that looks like a grumpy face.", -- EN fragment
	peace = "The wolf's ghost has found peace. Thank you, human being. However, there is someone else who needs help: A sister of mine who's bereft of something very precious. You'll find her in the guise of a swan at a small river south-east of here.",
	swanHint = "You'll find my sister in the guise of a swan at a small river south-east of here.", -- ours (EN fragment)
	lostTalisman = "You lost the talisman? Here, take another one. Without it the animals won't understand you.", -- ours
}

D.handlers["Ikassis"] = function(npc, player, message, npcHandler)
	local state = D.get(player, M1)
	if MsgContains(message, "mission") then
		if state == 4 then
			return say(npcHandler, npc, player, ikassis.offer, 1)
		elseif state >= 5 and state <= 9 then
			if not has(player, D.TALISMAN) and player:addItem(D.TALISMAN, 1) then
				return say(npcHandler, npc, player, ikassis.lostTalisman)
			end
			return say(npcHandler, npc, player, ikassis.wolfHint)
		elseif state == 10 then
			D.set(player, M1, 11)
			return say(npcHandler, npc, player, ikassis.peace)
		elseif state >= 11 and state <= 14 then
			return say(npcHandler, npc, player, ikassis.swanHint)
		end
		return false
	end
	if MsgContains(message, "yes") and topic(npcHandler, player) == 1 and state == 4 then
		D.set(player, M1, 5)
		player:addItem(D.TALISMAN, 1)
		return say(npcHandler, npc, player, ikassis.accept)
	end
	if MsgContains(message, "no") and topic(npcHandler, player) ~= 0 then
		return say(npcHandler, npc, player, "Then not.") -- upstream (ours)
	end
	return false
end

local wolf = {
	offer = {
		"I'm heartbroken, traveler. Some months ago, I was taking care of my three newborn whelps. They just opened their eyes and started exploring the wilderness as a hunter came by. ...",
		"He shot me and took my three puppies with him. I have no idea where he brought them or whether they are still alive. This uncertainty harrows me and thus I'm unable to find peace. Will you help me?",
	},
	accept = {
		"I didn't dare hope for it! The man told something about selling my babies to the orcs so they could train them as war wolves. ...",
		"I guess he mentioned Ulderek's Rock. Please search for them and - be they alive or not - return and tell me what happened to them.",
	},
	search = "I guess he mentioned Ulderek's Rock. Please search for them and - be they alive or not - return and tell me what happened to them.", -- the end of the EN line
	fur = {
		"So one of my babies died and another one has to live with the orcs. This makes me very sad. But at least one of them could return to the forest and found a surrogate mother. I hope it will lead a long, happy and most of all free life. ...",
		"Please do one last thing for me: The fur you brought me, place it in this stone's mouth. This will be a worthy resting place.",
	},
	furPlace = "Please do one last thing for me: The fur you brought me, place it in this stone's mouth. This will be a worthy resting place.", -- the end of the EN line
	peace = "I guess I will stick around for a time to watch over the grave. After this final watch I will find peace, I can feel this. Thank you, human being. You redeemed me.",
}

D.handlers["Ghostly Wolf"] = function(npc, player, message, npcHandler)
	local state = D.get(player, M1)
	if MsgContains(message, "mission") or MsgContains(message, "whelp") then
		if state == 5 and MsgContains(message, "mission") then
			return say(npcHandler, npc, player, wolf.offer, 1)
		elseif state == 6 or state == 7 then
			return say(npcHandler, npc, player, wolf.search)
		elseif state == 8 then
			return say(npcHandler, npc, player, wolf.fur)
		elseif state == 9 then
			D.set(player, M1, 10)
			return say(npcHandler, npc, player, wolf.peace)
		elseif state >= 10 then
			return say(npcHandler, npc, player, wolf.peace)
		end
		return false
	end
	if MsgContains(message, "yes") and topic(npcHandler, player) == 1 and state == 5 then
		D.set(player, M1, 6)
		return say(npcHandler, npc, player, wolf.accept)
	end
	if MsgContains(message, "no") and topic(npcHandler, player) ~= 0 then
		return say(npcHandler, npc, player, "Then not.") -- upstream (ours)
	end
	return false
end

local swan = {
	offer = {
		"My sister Ikassis sent you? Blessed be her soul! Yes, it is true: I need help. Listen, I will tell you a secret but please don't break it. As you might already suspect I'm not really a swan but a {fae}. ...",
		"But other than many of my {siblings} I did not take over a swan's body. I'm a {swan maiden} and this is one of my two aspects. I can take the shape of a swan as well as that of a young maiden. ...",
		"But to do so I need a magical artefact: a cloak made of swan feathers. If I lose this cloak - or someone steals it from me - I'm stuck to the form of a swan and can't change shape anymore. And this is exactly what happened: ...",
		"A troll stalked me while I was bathing in the river and he stole my cloak. Now I am trapped in the form of a swan. Please, can you find the thief and bring back the cloak?",
	},
	accept = {
		"Thank you, human being! I guess the thieving troll headed to the mountains east of here. As far as I know you can only reach these mountain tops by diving into a small cave. ...",
		"The connecting tunnels will lead you to a mountain where you may discover him. I heard a man named Jerom talking about this when he passed by this river. Perhaps he knows more about it.",
	},
	search = "I guess the thieving troll headed to the mountains east of here. As far as I know you can only reach these mountain tops by diving into a small cave.", -- BR fragment
	feathers = "Have you found my cloak? Its feathers must be scattered somewhere between Edron and Darashia.", -- ours
	done = {
		"This is everything that remained of my cloak? That's terrible! However, I guess I can put the feathers together again. Yes, that should be enough feathers. ...",
		"Please give them to me so I can restore my cloak. But don't watch me! {Swan maiden}s don't like to be observed. Nature's blessings, human being. I will tell Ikassis that you have been of great assistance.",
	},
	thanks = "Nature's blessings, human being. I will tell Ikassis that you have been of great assistance.", -- BR fragment
}

D.handlers["A Swan"] = function(npc, player, message, npcHandler)
	local state = D.get(player, M1)
	if MsgContains(message, "mission") or MsgContains(message, "cloak") then
		if state == 11 then
			return say(npcHandler, npc, player, swan.offer, 1)
		elseif state == 12 then
			return say(npcHandler, npc, player, swan.search)
		elseif state == 13 or state == 14 then
			if has(player, D.TATTERED_FEATHER, 5) and player:removeItem(D.TATTERED_FEATHER, 5) then
				D.set(player, M1, 15)
				return say(npcHandler, npc, player, swan.done)
			end
			return say(npcHandler, npc, player, swan.feathers)
		elseif state >= 15 then
			return say(npcHandler, npc, player, swan.thanks)
		end
		return false
	end
	if MsgContains(message, "yes") and topic(npcHandler, player) == 1 and state == 11 then
		D.set(player, M1, 12)
		return say(npcHandler, npc, player, swan.accept)
	end
	if MsgContains(message, "no") and topic(npcHandler, player) ~= 0 then
		return say(npcHandler, npc, player, "Then not.") -- upstream (ours)
	end
	return false
end

-- Ahmet (npc/ahmet.lua): "book" only on the mission, the book becomes the doctored one.
D.ahmet = {
	offer = "I see: You want me to add an additional story to this book. A legend about how it brings ill luck to kill a white deer. I could do that, yes. It costs 5000 gold, however. Are you still interested?",
	done = {
		"Well then. Here, take the book, I added the story. Oh, just a piece of advice: Not to inflame prejudice but poachers are of rather simple disposition. I doubt they are ardent readers. ...",
		"So if you want to make sure they read this anytime soon, perhaps don't hide the book in a shelf or chest. Make sure to place it somewhere where they will find it easily, like very obviously on a table or something.",
	},
	noBook = "Which book? Bring me the book with old legends and I will add your story.", -- ours
	noMoney = "You don't have enough money.", -- ours (as for his documents)
}

-- returns true when handled
function D.ahmetBook(npc, player, message, npcHandler, accepted)
	if not D.enabled() then
		return false
	end
	if not accepted then
		if not MsgContains(message, "book") or D.get(player, M1) ~= 1 then
			return false
		end
		if not has(player, D.BOOK) then
			return say(npcHandler, npc, player, D.ahmet.noBook)
		end
		return say(npcHandler, npc, player, D.ahmet.offer, 5)
	end
	if D.get(player, M1) ~= 1 or not has(player, D.BOOK) then
		return say(npcHandler, npc, player, D.ahmet.noBook)
	end
	if not player:removeMoneyBank(5000) then
		return say(npcHandler, npc, player, D.ahmet.noMoney)
	end
	local book = player:getItemById(D.BOOK, true)
	if book then
		book:transform(D.BOOK_DOCTORED)
	else
		player:removeItem(D.BOOK, 1)
		player:addItem(D.BOOK_DOCTORED, 1)
	end
	D.set(player, M1, 2)
	return say(npcHandler, npc, player, D.ahmet.done)
end

-- The feather spots between Edron and Darashia (scripts/quests/threatened_dreams/movement_swan_feathers.lua):
-- the EN server messages.
D.featherMessages = {
	[25024] = "You found some beautiful swan feathers on the grass near the wheat.",
	[25025] = "You found some beautiful swan feathers in the dustbin.",
	[25026] = "You found some beautiful swan feathers entangled in the cactus stings.",
	[25027] = "You found some beautiful swan feathers beneath the dragon skull.",
	[25028] = "You found some beautiful swan feathers under the dead tree.",
}

-- ---------------------------------------------------------------------------
-- A Dream Come True (Maelyrra)
-- ---------------------------------------------------------------------------

local M2 = TD.Mission02[1]
local M3 = TD.Mission03[1]

local maelyrra = {
	offer = "Some annoying nightmarish creatures rove about in the tunnels underneath this island. They are threatening the members of my court and devastate the flora and fauna. They also threaten the natural balance. Would you go and fight them for me?",
	accept = "I knew you would be willing to help us. Kill two hundred of them as well as the terrible demon Kroazur who's leading them. That should bring some relief for the fae.",
	askKills = "Have you defeated the nightmare monsters?",
	killsDone = "Thank you! You rendered a great favour to the fae courts and Feyrist alike. Would you help us with another problem?",
	killsMore = "Kill two hundred of them as well as the terrible demon Kroazur who's leading them. That should bring some relief for the fae.", -- the EN line without its start
	nextProblem = "You rendered a great favour to the fae courts and Feyrist alike. Would you help us with another problem?", -- upstream (EN fragment)
	tainted = {
		"Some of our siblings are tainted by the destructive energies that threaten Feyrist. They are darker now, more aggressive, twisted ... I'm sure you already met them. ...",
		"They are living in tunnels and caves but at night they surface, even attacking their own siblings. They kidnapped some fairies, holding them prisoner in their mouldy dens. ...",
		"And as if this wasn't enough they stole an ancient and precious artefact, the moon mirror. Please seek out the tainted fae, retrieve the artefact and free the captured fairies. ...",
		"You may discover the entrance to the tainted caves somewhere in the deep forest. The tainted fae like to hide their treasures in hollow logs or trumps, so have a closer look at them.",
	},
	askMirror = "Have you found the moon mirror and freed the captured fairies?",
	mirrorDone = "Thank you, mortal being! Please keep the mirror. I think you may need it soon, because there is another problem. Would you help us again?",
	mirrorMore = "Please seek out the tainted fae, retrieve the artefact and free the captured fairies.", -- EN fragment
	againAsk = "Please keep the mirror. I think you may need it soon, because there is another problem. Would you help us again?", -- EN fragment
	vessels = {
		"You have to find three vessels that are able to hold three different types of light: starlight, sunlight and moon rays. You have already found the moon mirror but we also need the starlight vial and the sun catcher. ...",
		"Ask the mermaid Aurita for the starlight vial and the faun Taegen for the sun catcher.",
	},
	vesselsHint = "Ask the mermaid Aurita for the starlight vial and the faun Taegen for the sun catcher.", -- the end of the EN line
	askVessels = "Have you already found the starlight vial and the sun catcher?",
	lights = {
		"Very good, mortal being! Now you have to catch the respective light and store it in the corresponding vessel. You can gather moon rays by night but this will only work on one special sacred glade on Feyrist. ...",
		"You can find this glade in the deep forest, east of our village. The starlight must also be gathered by night. There is a rock plateau high in the mountains at the border to Roshamuul where you can catch the starlight in the vial. ...",
		"You will recognise the place by the elemental energy shrine there. You have to gather the sunlight by day, of course. There is a beach in the north of Feyrist, shaped like a snake's head. There you may gather Suon's light with the sun catcher.",
	},
	askLights = "Could you already gather the three lights?",
	lightsMore = "You have to catch the respective light and store it in the corresponding vessel.", -- upstream (ours)
	barrier = {
		"That's wonderful! Now you will be able to repair the magical barrier. You have to strengthen the arcane sources that power this mystic shield. There are three different arcane sources: the moon sculptures, the dream bird trees and the sun mosaics. ...",
		"There are five of each of them and you have to find them all to repair the barrier. Spread the gathered moon rays on the moon sculptures. Pour out the starlight over the dream bird trees and let the sunlight shine on the mosaics. ...",
		"If you charge all fifteen arcane sources with the respective light, Feyrist's protection will be ensured again.",
	},
	askBarrier = "Have you repaired the magical barrier? Is Feyrist safe?",
	barrierMore = "If you charge all fifteen arcane sources with the respective light, Feyrist's protection will be ensured again.", -- the end of the EN line
	reward = "Thank you, mortal being! The fae will be forever grateful. Take this blossom bag as a little thank-you gift. Such blossoms grow on our trees just once in a decade, so they are quite rare.",
	grateful = "Thank you again, mortal being! The fae will be forever grateful.", -- upstream (ours)
	stranger = "You are a stranger to the fae courts, mortal being. Prove yourself to Alkestios first.", -- ours
}

local function hasAny(player, ids)
	for _, id in ipairs(ids) do
		if has(player, id) then
			return true
		end
	end
	return false
end

D.handlers["Maelyrra"] = function(npc, player, message, npcHandler)
	-- Sweet Dreams: the donut gate (lib/others/family_sweet_dreams.lua)
	if FamilySweetDreams and FamilySweetDreams.maelyrra(npc, player, message, npcHandler) then
		return true
	end
	local state = D.get(player, M2)
	local t = topic(npcHandler, player)
	if MsgContains(message, "mission") then
		if state < 1 then
			if D.get(player, M1) < 16 then
				return say(npcHandler, npc, player, maelyrra.stranger)
			end
			return say(npcHandler, npc, player, maelyrra.offer, 1)
		elseif state <= 2 then
			return say(npcHandler, npc, player, maelyrra.askKills, 2)
		elseif state <= 4 then
			return say(npcHandler, npc, player, maelyrra.askMirror, 4)
		elseif state == 5 then
			return say(npcHandler, npc, player, maelyrra.askVessels, 6)
		elseif state == 6 then
			return say(npcHandler, npc, player, maelyrra.askLights, 7)
		elseif state == 7 then
			return say(npcHandler, npc, player, maelyrra.askBarrier, 8)
		end
		return say(npcHandler, npc, player, maelyrra.grateful)
	end
	if MsgContains(message, "yes") then
		if t == 1 and state < 1 then
			D.startLog(player)
			D.set(player, M2, 1)
			D.set(player, TD.Mission02.KroazurAccess, 1)
			D.set(player, TD.Mission02.EnfeebledCount, 0)
			D.set(player, TD.Mission02.FrazzlemawsCount, 0)
			if D.get(player, TD.QuestLine) < 2 then
				D.set(player, TD.QuestLine, 2)
			end
			return say(npcHandler, npc, player, maelyrra.accept)
		elseif t == 2 then
			local kills = D.get(player, TD.Mission02.EnfeebledCount) + D.get(player, TD.Mission02.FrazzlemawsCount)
			if state == 1 and D.get(player, TD.Mission02.KroazurKill) >= 1 and kills >= 200 then
				D.set(player, M2, 2)
				return say(npcHandler, npc, player, maelyrra.killsDone, 3)
			elseif state == 2 then
				return say(npcHandler, npc, player, maelyrra.nextProblem, 3)
			end
			return say(npcHandler, npc, player, maelyrra.killsMore)
		elseif t == 3 and state == 2 then
			D.set(player, M2, 3)
			return say(npcHandler, npc, player, maelyrra.tainted)
		elseif t == 4 then
			if state == 3 and D.get(player, TD.Mission02.FairiesCounter) >= 5 and D.get(player, TD.Mission02.DarkMoonMirror) == 1 then
				D.set(player, M2, 4)
				return say(npcHandler, npc, player, maelyrra.mirrorDone, 5)
			elseif state == 4 then
				return say(npcHandler, npc, player, maelyrra.againAsk, 5)
			end
			return say(npcHandler, npc, player, maelyrra.mirrorMore)
		elseif t == 5 and state == 4 then
			D.set(player, M2, 5)
			return say(npcHandler, npc, player, maelyrra.vessels)
		elseif t == 6 and state == 5 then
			-- FAMILY: the three vessels in the backpack (BR: "Agora que você tem os itens necessários")
			if D.get(player, M3) == 4 and hasAny(player, { D.MOON_DARK, D.MOON_LIT }) and hasAny(player, { D.VIAL_EMPTY, D.VIAL_GLEAMING }) and hasAny(player, { D.SUN_DARK, D.SUN_SHINING }) then
				D.set(player, M2, 6)
				return say(npcHandler, npc, player, maelyrra.lights)
			end
			return say(npcHandler, npc, player, maelyrra.vesselsHint)
		elseif t == 7 and state == 6 then
			if has(player, D.MOON_LIT) and has(player, D.VIAL_GLEAMING) and has(player, D.SUN_SHINING) then
				D.set(player, M2, 7)
				return say(npcHandler, npc, player, maelyrra.barrier)
			end
			return say(npcHandler, npc, player, maelyrra.lightsMore)
		elseif t == 8 and state == 7 then
			local mission = TD.Mission02
			if D.get(player, mission.ChargedMoonMirror) == 0 and D.get(player, mission.ChargedStarlightVial) == 0 and D.get(player, mission.ChargedSunCatcher) == 0 then
				player:addItem(25780, 1) -- blossom bag
				D.set(player, M2, 8)
				return say(npcHandler, npc, player, maelyrra.reward)
			end
			return say(npcHandler, npc, player, maelyrra.barrierMore)
		end
		return false
	end
	if MsgContains(message, "no") and t ~= 0 then
		return say(npcHandler, npc, player, "Then not.") -- upstream (ours)
	end
	return false
end

-- ---------------------------------------------------------------------------
-- An Unlikely Couple (Aurita, the dancing fairy, Taegen)
-- UnlikelyCouple: 1 asked, 2 told about the spell, 3 notes made, 4 notes delivered.
-- ---------------------------------------------------------------------------

local COUPLE = TD.Mission03.UnlikelyCouple

local aurita = {
	offer = {
		"Yes, there is something. I'm in love with {Taegen}, but he is a faun. As such he's inhabiting the forests, dancing with fairies. And I, being a mermaid, am living in the ocean, swimming with the fish between coral reefs. ...",
		"But I lost my heart to Taegen, I can't help it. We would love to spend some time together, but not just sitting on the beach. ...",
		"I'd love to show him my homestead beneath the waves. I have an idea but I can't do it alone. Would you help me?",
	},
	accept = {
		"That's very kind of you, my friend! Listen: I know there is a spell to transform my fishtail into legs. It is a temporary effect, so I could return to the ocean as soon as the spell ends. Unfortunately I don't know how to cast this spell. ...",
		"But there is a fairy who once told me about it. Perhaps she will share her knowledge. You can find her in a small fairy village in the southwest of {Feyrist}.",
	},
	fairy = "There is a fairy who once told me about this spell. Perhaps she will share her knowledge. You can find her in a small fairy village in the southwest of Feyrist.", -- upstream (EN fragment)
	notes = "The spell works! I already took a walk on the beach last night in the moonlight. Please talk to Taegen now, he may have another request.",
	happy = "Thank you again, friend! Taegen and I we're so happy now.", -- upstream (ours)
	vial = {
		"Thank you, friend! Please take the starlight vial. It is made of a very rare kind of enchanted glass and magical metals, so it is able to preserve starlight. ...",
		"A long time ago a pixie knight of Maelyrra carried it with her. But when she was flying above the waves she accidentally dropped it and it sunk. I found it but now you may take it and use it to help Feyrist.",
	},
	vialGiven = "I already gave you the empty starlight vial.", -- upstream (ours)
	vialLater = "First help Taegen, please. He is waiting for you.", -- ours
}

D.handlers["Aurita"] = function(npc, player, message, npcHandler)
	local state = D.get(player, M3)
	if MsgContains(message, "starlight vial") or MsgContains(message, "vial") then
		if state == 4 then
			if D.get(player, TD.Mission03.EmptyStarlightVial) < 1 then
				player:addItem(D.VIAL_EMPTY, 1)
				D.set(player, TD.Mission03.EmptyStarlightVial, 1)
				return say(npcHandler, npc, player, aurita.vial)
			end
			return say(npcHandler, npc, player, aurita.vialGiven)
		elseif state >= 1 then
			return say(npcHandler, npc, player, aurita.vialLater)
		end
		return false
	end
	if MsgContains(message, "mission") then
		if state < 1 then
			return say(npcHandler, npc, player, aurita.offer, 1)
		elseif state == 1 then
			return say(npcHandler, npc, player, aurita.fairy)
		elseif state == 2 then
			-- the notes are for Aurita (EN); Taegen takes them too (BR)
			if D.get(player, COUPLE) == 3 and has(player, D.MUSIC_NOTES) and player:removeItem(D.MUSIC_NOTES, 1) then
				D.set(player, COUPLE, 4)
			end
			return say(npcHandler, npc, player, D.get(player, COUPLE) >= 4 and aurita.notes or aurita.fairy)
		elseif state == 3 then
			return say(npcHandler, npc, player, aurita.notes)
		end
		return say(npcHandler, npc, player, aurita.happy)
	end
	if MsgContains(message, "yes") and topic(npcHandler, player) == 1 and state < 1 then
		D.set(player, M3, 1)
		D.set(player, COUPLE, 1)
		return say(npcHandler, npc, player, aurita.accept)
	end
	if MsgContains(message, "no") and topic(npcHandler, player) ~= 0 then
		return say(npcHandler, npc, player, "Then not.") -- upstream (ours)
	end
	return false
end

local dancingFairy = {
	spell = {
		"So, you are searching for a way to transform {Aurita}'s fishtail into legs temporarily. As you might already have figured out you need some magic for this purpose. There is a place on Feyrist where you can find the arcane energies you need. ...",
		"Northeast from here you'll discover a big lake with a small island. Take a swim there and you will find a magical fountain. If you play the panpipes while standing near this fountain, you will create some magical music notes. ...",
		"Collect them and give them to Aurita. Each of those notes will grant her a walk on the beach with {Taegen}.",
	},
	notes = "Collect them and give them to Aurita. Each of those notes will grant her a walk on the beach with {Taegen}.", -- the end of the EN line
}

D.handlers["Dancing Fairy"] = function(npc, player, message, npcHandler)
	if MsgContains(message, "spell") or MsgContains(message, "fishtail") then
		if D.get(player, M3) == 1 and D.get(player, COUPLE) <= 1 then
			D.set(player, COUPLE, 2)
			return say(npcHandler, npc, player, dancingFairy.spell)
		elseif D.get(player, M3) >= 1 then
			return say(npcHandler, npc, player, dancingFairy.spell)
		end
		return say(npcHandler, npc, player, dancingFairy.notes)
	end
	return false
end

local taegen = {
	offer = {
		"Yes, there is something. It's a bit embarassing, you must promise not to tell anyone else. I'm in love with Aurita. Well, that wouldn't be a reson to be ashamed, but she is a mermaid. ...",
		"A faun on the other hand is inhabiting the forests, dancing with fairies and, well, nymphs. But I lost my heart to the lovely Aurita. I can't help it. We would love to spend some time together, but not just sitting on the beach. ...",
		"I'd love to show her the deep forest I love so much. I have an idea but I can't do it alone. Would you help me?",
	}, -- upstream (ours)
	accept = {
		"That's very kind of you, my friend! Listen: I know there is a spell to transform her fishtail into legs. It is a temporary effect, so she could return to the ocean as soon as the spell ends. Unfortunately I don't know how to cast this spell. ...",
		"But there is a fairy who once told me about it. Perhaps she will share her knowledge. You can find her in a small fairy village in the southwest of Feyrist.",
	}, -- upstream (ours)
	fairy = "There is a fairy who once told me about this spell. Perhaps she will share her knowledge. You can find her in a small fairy village in the southwest of Feyrist.", -- upstream (EN fragment)
	herb = {
		"We are so happy. Now Aurita can take a walk on the beach. But I still can't visit her secret underwater grotto. To achieve this, we need something else: a very rare plant called raven herb. ...",
		"If eaten it allows an air breathing creature to breathe underwater for a while. Please find this plant for me. But know that you'll only find it at night. It resembles a common fern but its leaves are of a lighter green.",
	},
	notesFirst = "Have you made the magical music notes for Aurita? Without them she can't walk on the beach with me.", -- ours
	askHerb = "Have you found the {raven herb}?",
	herbThanks = "Thank you, friend! Now I can visit Aurita in her underwater grotto!",
	herbMore = "Please find this plant for me. But know that you'll only find it at night. It resembles a common fern but its leaves are of a lighter green.", -- BR fragment
	catcher = {
		"Thank you again, mortal being. A sun catcher is similar to a dream catcher but other than the latter it can preserve sunlight rather than bad dreams. I can craft one out of enchanted branches of a fairy tree as well as several enchanted gems. ...",
		"The branches are no problem, I will find some in the forest. But I don't have any gems. If you bring me some, I can craft a sun catcher for you. Do you have gems?",
	},
	craft = "Alright, I will craft a sun catcher for you.",
	crafted = "I already crafted one sun catcher for you.", -- upstream (ours)
	noGems = "I don't have any gems. If you bring me some, I can craft a sun catcher for you. Two small enchanted amethysts, emeralds, rubies and sapphires each.", -- ours (EN fragment)
	happy = "Thank you! We are so happy. Now Aurita can take a walk on the beach. And I can visit her secret underwater grotto.", -- upstream (ours)
}

local GEMS = { 675, 676, 677, 678 } -- small enchanted sapphire, ruby, emerald, amethyst

D.handlers["Taegen"] = function(npc, player, message, npcHandler)
	local state = D.get(player, M3)
	local t = topic(npcHandler, player)
	local isMission = MsgContains(message, "mission")
	local isCatcher = MsgContains(message, "sun catcher")
	if isMission or isCatcher or MsgContains(message, "raven herb") then
		if state < 1 then
			if isMission then
				return say(npcHandler, npc, player, taegen.offer, 1)
			end
			return false
		elseif state == 1 then
			return say(npcHandler, npc, player, taegen.fairy)
		elseif state == 2 then
			if D.get(player, COUPLE) == 3 and has(player, D.MUSIC_NOTES) and player:removeItem(D.MUSIC_NOTES, 1) then
				D.set(player, COUPLE, 4)
			end
			if D.get(player, COUPLE) >= 4 then
				D.set(player, M3, 3)
				return say(npcHandler, npc, player, taegen.herb)
			end
			return say(npcHandler, npc, player, taegen.notesFirst)
		elseif state == 3 then
			return say(npcHandler, npc, player, taegen.askHerb, 2)
		elseif state == 4 and isCatcher then
			return say(npcHandler, npc, player, taegen.catcher, 3)
		end
		return say(npcHandler, npc, player, taegen.happy)
	end
	if MsgContains(message, "yes") then
		if t == 1 and state < 1 then
			D.set(player, M3, 1)
			D.set(player, COUPLE, 1)
			return say(npcHandler, npc, player, taegen.accept)
		elseif t == 2 and state == 3 then
			if has(player, D.RAVEN_HERB) and player:removeItem(D.RAVEN_HERB, 1) then
				D.set(player, M3, 4)
				return say(npcHandler, npc, player, taegen.herbThanks)
			end
			return say(npcHandler, npc, player, taegen.herbMore)
		elseif t == 3 and state == 4 then
			if D.get(player, TD.Mission03.DarkSunCatcher) == 1 then
				return say(npcHandler, npc, player, taegen.crafted)
			end
			for _, id in ipairs(GEMS) do
				if not has(player, id, 2) then
					return say(npcHandler, npc, player, taegen.noGems)
				end
			end
			for _, id in ipairs(GEMS) do
				player:removeItem(id, 2)
			end
			player:addItem(D.SUN_DARK, 1)
			D.set(player, TD.Mission03.DarkSunCatcher, 1)
			return say(npcHandler, npc, player, taegen.craft)
		end
		return false
	end
	if MsgContains(message, "no") and t ~= 0 then
		return say(npcHandler, npc, player, "Then not.") -- upstream (ours)
	end
	return false
end

-- The panpipes on the lake island (scripts/actions/other/music.lua): returns true when notes were made.
function D.playPanpipes(player)
	if not D.enabled() then
		return false
	end
	if D.get(player, COUPLE) < 2 or player:getStorageValue(TD.Mission03.PanpipesTimer) >= os.time() then
		return false
	end
	if D.get(player, COUPLE) == 2 then
		D.set(player, COUPLE, 3)
	end
	if D.get(player, M3) == 1 then
		D.set(player, M3, 2) -- upstream set 2 every time, also after the mission
	end
	player:setStorageValue(TD.Mission03.PanpipesTimer, os.time() + 20 * 3600)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Mysteriously some colourful music notes fall of the panpipes. - Hurry, they will fade away quickly.")
	player:addItem(D.MUSIC_NOTES, 1)
	return true
end

-- ---------------------------------------------------------------------------
-- The Swan Feather Cloak (Valindara)
-- ---------------------------------------------------------------------------

D.CLOAK_HOURS = 20 -- EN "Wait 20 hours"; BR says 24 hours (the line says "return tomorrow")

local valindara = {
	offer = "You did us a great favour, mortal being! Well, as I promised I will craft you a feathery cloak. Bring me one hundred swan feathers and I will make them into a beautiful robe.",
	ask = "You did us a great favour, mortal being! Well, as I promised I will craft you a feathery cloak. Bring me one hundred swan feathers and I will make them into a beautiful robe. Do you have enough feathers yet?",
	crafting = "Very good. I will craft the cloak for you. This will take some time, so return tomorrow please.",
	notYet = "I'm still working on your cloak. Please return tomorrow.", -- ours
	ready = "You're returning just in time. Here, take the cloak I crafted for you. Thanks again for helping us, mortal being.",
	tooFew = "You don't have enough feathers yet. I need one hundred swan feathers for a cloak.", -- ours
	stranger = "Swan feather cloaks are only for those who helped the fae, mortal being.", -- ours
	done = "I hope you enjoy your feathery cloak, mortal being.", -- ours
}

D.handlers["Valindara"] = function(npc, player, message, npcHandler)
	if MsgContains(message, "cloak") then
		if D.get(player, M2) < 8 then
			return say(npcHandler, npc, player, valindara.stranger)
		end
		local cloak = D.get(player, S.SwanCloak)
		if cloak < 1 then
			D.startLog(player)
			D.set(player, S.SwanCloak, 1)
			return say(npcHandler, npc, player, valindara.offer) -- BR first transcript
		elseif cloak == 1 then
			return say(npcHandler, npc, player, valindara.ask, 1)
		elseif cloak == 2 then
			if os.time() < D.get(player, S.SwanCloakReady) then
				return say(npcHandler, npc, player, valindara.notYet)
			end
			if not D.give(player, D.SWAN_CLOAK, 1, "You have found a swan feather cloak") then
				return true
			end
			D.set(player, S.SwanCloak, 3)
			return say(npcHandler, npc, player, valindara.ready)
		end
		return say(npcHandler, npc, player, valindara.done)
	end
	if MsgContains(message, "yes") and topic(npcHandler, player) == 1 and D.get(player, S.SwanCloak) == 1 then
		if not (has(player, D.SWAN_FEATHER, 100) and player:removeItem(D.SWAN_FEATHER, 100)) then
			return say(npcHandler, npc, player, valindara.tooFew)
		end
		D.set(player, S.SwanCloak, 2)
		D.set(player, S.SwanCloakReady, os.time() + D.CLOAK_HOURS * 3600)
		return say(npcHandler, npc, player, valindara.crafting)
	end
	if MsgContains(message, "no") and topic(npcHandler, player) == 1 then
		return say(npcHandler, npc, player, "Then come back when you have one hundred swan feathers.") -- ours
	end
	return false
end

-- The eight swans of Feyrist (EN map marks; the BR screenshots show the player next to a swan):
-- stepping within 3 squares of one by day gives 5 feathers, again after 20 h (BR, EN).
D.SWANS = {
	Position(33495, 32315, 7),
	Position(33458, 32291, 7),
	Position(33464, 32228, 7),
	Position(33500, 32191, 7),
	Position(33547, 32222, 7),
	Position(33591, 32196, 7),
	Position(33470, 32249, 7),
	Position(33531, 32254, 7), -- EN mark 33524,32255: the nearest swans are 33531,32254 and 33533,32253
}
D.SWAN_RANGE = 3
D.SWAN_FEATHERS = 5
D.SWAN_HOURS = 20

-- MoveEvent on the squares around the swans (scripts/family/threatened_dreams.lua).
function D.swanStep(player, position)
	if not D.enabled() or D.get(player, M2) < 8 or D.isNight() then
		return
	end
	for i, swanPos in ipairs(D.SWANS) do
		if position.z == swanPos.z and math.abs(position.x - swanPos.x) <= D.SWAN_RANGE and math.abs(position.y - swanPos.y) <= D.SWAN_RANGE then
			local key = S.SwanSpots + i - 1
			if player:getStorageValue(key) > os.time() then
				return
			end
			if not D.give(player, D.SWAN_FEATHER, D.SWAN_FEATHERS, "You found some swan feathers") then
				return
			end
			player:setStorageValue(key, os.time() + D.SWAN_HOURS * 3600)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found some swan feathers!") -- BR screenshot
			position:sendMagicEffect(CONST_ME_POFF)
			return
		end
	end
end

-- ---------------------------------------------------------------------------
-- The Fairy Treasure (Tooth Fairy, Tired Tree, Grumpy Stone)
-- ---------------------------------------------------------------------------

-- The children's rooms (our map): a chest of drawers with the milk tooth and the bed for the present.
D.CHILDREN = {
	quero = { -- Thais, upstairs at Quero's (EN 32390,32220,6)
		drawers = { Position(32395, 32220, 6), Position(32395, 32221, 6), Position(32395, 32222, 6) },
		bed = { Position(32391, 32220, 6), Position(32391, 32221, 6) },
		present = "You are placing the present for Quero's daughter on the pillow.",
	},
	allen = { -- Venore, upstairs at Allen's (BR 32990,32063; the child's bed on floor 5)
		drawers = { Position(32987, 32063, 5) },
		bed = { Position(32987, 32060, 5), Position(32988, 32060, 5), Position(32987, 32061, 5), Position(32988, 32061, 5) },
		present = "You are placing the present for Allen's son on the pillow.",
	},
	rowenna = { -- Carlin, upstairs at Rowenna's (BR 32322,31795,6)
		drawers = { Position(32322, 31792, 6), Position(32322, 31793, 6) },
		bed = { Position(32327, 31794, 6), Position(32328, 31794, 6), Position(32327, 31795, 6), Position(32328, 31795, 6) },
		present = "You are placing the present for Rowenna's daughter on the pillow.",
	},
}

-- Action on a chest of drawers of a child's room: true when the quest step applied.
function D.useDrawers(player, child)
	if not D.enabled() or D.get(player, S.ToothFairy) ~= 1 or D.get(player, S.Tooth[child]) >= 1 then
		return false
	end
	if not D.give(player, D.MILK_TOOTH, 1, "You have found a milk tooth") then
		return true
	end
	D.set(player, S.Tooth[child], 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a milk tooth.") -- EN
	return true
end

-- The present used on a child's bed.
function D.usePresent(player, item, toPosition)
	if not D.enabled() or D.get(player, S.ToothFairy) ~= 1 then
		return false
	end
	for child, room in pairs(D.CHILDREN) do
		for _, pos in ipairs(room.bed) do
			if pos == toPosition then
				if D.get(player, S.Present[child]) >= 1 then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There already is a present on this pillow.") -- ours
					return true
				end
				item:remove(1)
				D.set(player, S.Present[child], 1)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, room.present) -- EN
				toPosition:sendMagicEffect(CONST_ME_GIFT_WRAPS)
				return true
			end
		end
	end
	return false
end

local CHILDREN_ORDER = { "quero", "allen", "rowenna" }

local function allPresents(player)
	for _, child in ipairs(CHILDREN_ORDER) do
		if D.get(player, S.Present[child]) < 1 then
			return false
		end
	end
	return true
end

local function presentsMissing(player)
	local n = 0
	for _, child in ipairs(CHILDREN_ORDER) do
		if D.get(player, S.Present[child]) < 1 then
			n = n + 1
		end
	end
	return n
end

-- Tooth collection (EN): word -> item id, the thanks line names the tooth.
D.TEETH = {
	{ word = "orc", id = 10196, name = "an orc tooth" },
	{ word = "shark", id = 22649, name = "shark teeth" },
	{ word = "vampire", id = 9685, name = "vampire teeth" },
	{ word = "behemoth", id = 5893, name = "a behemoth fang" },
	{ word = "carrion worm", id = 10275, name = "a carrion worm fang" },
	{ word = "werewolf", id = 22052, name = "werewolf fangs" },
}

local toothFairy = {
	offer = {
		"You've got me, I really have a little problem here. What gave it away? My sorrowful expression? Yes, I thought so. This is what troubles me: I'm the {tooth fairy}. Well, this wouldn't be a problem at all under normal circumstances. ...",
		"I love gathering children's {milk teeth} and bringing presents for them. Until now, I did so by using a spell. This spell teleported me into the children's bedrooms and - after carrying out my duty - back to my secret {realm}. ...",
		"But then I made the mistake of using a magical portal and entering this part of the world. Everything is strange and different here and the worst thing: my spells don't work! It will take some time until I can use the portal again. ...",
		"Thus I'm stuck here for a while. But there are some children who lost their first milk tooth and are now waiting for their presents. Without my spells, I'm feeling utterly helpless. ...",
		"I don't dare going to their homes at night but I know they will be sad about the missing presents. Would you help me?",
	},
	accept = {
		"Thank you very much, human being! You have to find three children: Quero's daughter in {Thais}, Allen's son in {Venore} and Rowenna's daughter in {Carlin}. Go to their bedrooms and find their milk teeth. ...",
		"Usually they put them on their bed stands. Then you have to put the gifts on their beds. Please take these presents and go to Thais, Carlin and Venore. Come back with the milk teeth.",
	},
	waiting = "Please take these presents and go to Thais, Carlin and Venore. Come back with the milk teeth.", -- the end of the EN line
	done = {
		"You're bringing the {milk teeth}! Thank you, human being; you were of great assistance to me! Please take this in return. It's the part of a map. If you find the other {parts}, it will show you the way to a hidden fairy treasure. ...",
		"Oh, and if you're interested, there's still another {cause} you could help me with.",
	},
	cause = {
		"As I'm the tooth fairy it should not surprise you to hear that I have a small collection. Yes, a tooth collection, of course. But I'm still lacking some special specimens. ...",
		"I would give you a little reward if you bring me one of the following - or all of them: an {orc} tooth, a {shark} tooth, a {vampire} tooth, a {behemoth} fang, a {carrion worm} fang or a {werewolf fangs}.",
	},
	parts = {
		"Three of my siblings and I have hidden the treasure after entering this part of the world. As you helped me with the children's presents it's fine by me if you find and take it. ...",
		"Of course you must ask my brothers and sisters for the other map parts. Unfortunately I don't know all of their whereabouts. But you can find some of them north of a place called {Carlin}. They took over a group of trees",
	},
	thanks = "Thank you again, human being. The children will be so happy.", -- ours
	lost = "You lost a present? I can wrap another one, but the gifts are precious. Give me a small ruby for each lost present, will you?", -- ours (BR: a small ruby per lost present)
	lostNone = "You still have all the presents you need.", -- ours
	lostGiven = "Here you are. Please be more careful this time.", -- ours
	noRuby = "You don't have enough small rubies.", -- ours
	tooth = "Oh, I see! You really found %s for me! Thank you, human being! Please take this in return.",
	haveTooth = "I already have such a specimen in my collection. Thank you anyway, human being.", -- ours
	noTooth = "You don't have it with you, human being.", -- ours
}

-- Presents still needed for the rooms without one (the BR "lost" exchange).
local function presentsToReplace(player)
	return presentsMissing(player) - player:getItemCount(D.PRESENT)
end

D.handlers["Tooth Fairy"] = function(npc, player, message, npcHandler)
	local state = D.get(player, S.ToothFairy)
	local t = topic(npcHandler, player)
	if MsgContains(message, "mission") then
		if state < 1 then
			return say(npcHandler, npc, player, toothFairy.offer, 1)
		elseif state == 1 then
			local teeth = 0
			for _, child in ipairs(CHILDREN_ORDER) do
				teeth = teeth + D.get(player, S.Tooth[child])
			end
			if teeth >= 3 and allPresents(player) and has(player, D.MILK_TOOTH, 3) then
				player:removeItem(D.MILK_TOOTH, 3)
				player:addItem(D.MAP_UPPER_LEFT, 1)
				D.set(player, S.ToothFairy, 2)
				D.startFairyTreasure(player)
				D.toothAchievement(player)
				return say(npcHandler, npc, player, toothFairy.done)
			end
			return say(npcHandler, npc, player, toothFairy.waiting)
		end
		return say(npcHandler, npc, player, toothFairy.thanks)
	end
	if MsgContains(message, "yes") then
		if t == 1 and state < 1 then
			if not D.give(player, D.PRESENT, 3, "You have found three presents") then
				return true
			end
			D.set(player, S.ToothFairy, 1)
			D.startFairyTreasure(player)
			return say(npcHandler, npc, player, toothFairy.accept)
		elseif t == 2 and state == 1 then
			local need = presentsToReplace(player)
			if need <= 0 then
				return say(npcHandler, npc, player, toothFairy.lostNone)
			end
			if not player:removeItem(D.SMALL_RUBY, need) then
				return say(npcHandler, npc, player, toothFairy.noRuby)
			end
			player:addItem(D.PRESENT, need)
			return say(npcHandler, npc, player, toothFairy.lostGiven)
		end
		return false
	end
	if MsgContains(message, "lost") and state == 1 then
		if presentsToReplace(player) <= 0 then
			return say(npcHandler, npc, player, toothFairy.lostNone)
		end
		return say(npcHandler, npc, player, toothFairy.lost, 2)
	end
	if MsgContains(message, "parts") then
		return say(npcHandler, npc, player, toothFairy.parts)
	end
	if MsgContains(message, "cause") or MsgContains(message, "collection") then
		D.set(player, S.Cause, 1)
		return say(npcHandler, npc, player, toothFairy.cause)
	end
	for i, tooth in ipairs(D.TEETH) do
		if MsgContains(message, tooth.word) then
			local key = S.Teeth + i - 1
			if D.get(player, key) >= 1 then
				return say(npcHandler, npc, player, toothFairy.haveTooth)
			end
			if not (has(player, tooth.id) and player:removeItem(tooth.id, 1)) then
				return say(npcHandler, npc, player, toothFairy.noTooth)
			end
			D.set(player, key, 1)
			player:addItem(3026, 1) -- white pearl (BR)
			D.toothAchievement(player)
			return say(npcHandler, npc, player, string.format(toothFairy.tooth, tooth.name))
		end
	end
	if MsgContains(message, "no") and t ~= 0 then
		return say(npcHandler, npc, player, "Then not.") -- ours
	end
	return false
end

-- Toothfairy Assistant: all six teeth and the milk teeth mission (EN).
function D.toothAchievement(player)
	if D.get(player, S.ToothFairy) < 2 then
		return
	end
	for i = 1, #D.TEETH do
		if D.get(player, S.Teeth + i - 1) < 1 then
			return
		end
	end
	if not player:hasAchievement("Toothfairy Assistant") then
		player:addAchievement("Toothfairy Assistant")
	end
end

local tiredTree = {
	offer = "I have a part of a certain map, yes. I would consider giving it to you if you do me a small favour. Would you do that?",
	accept = "Thank you very much, human being! Perhaps a bedtime story would help. We'd like to hear something about the dryads.",
	askStory = "If you know a good bedtime story I will give you the map. Do you have a story to tell?",
	askMission = "Have you found a story that could help us to drift off to sleep?",
	story = {
		"Oh, what a beautiful story. ... *yawn* Here, take this map part. We have no need for it when we are slumbering. *yawn* Some of our siblings have the third part. They took over a couple of stones in the north of some high mountains. ...",
		"There are ... dwarves I guess. ... Zzzzzz ...",
	},
	which = "Which story? *yawn* Tell me its name.", -- ours
	asleep = "Zzzzzz ...", -- ours (the end of the EN line)
	missionBefore = "My siblings and I, we are soo tired. We'd love to sleep and dream but there are strange and wicked disturbances that trouble nature itself. Thus, it is very hard to fall asleep. Would you help us?", -- BR
}

D.handlers["Tired Tree"] = function(npc, player, message, npcHandler)
	local state = D.get(player, S.TiredTree)
	local t = topic(npcHandler, player)
	if MsgContains(message, "the seeds of life") or MsgContains(message, "seeds of life") then
		if state == 1 then
			player:addItem(D.MAP_BOTTOM_LEFT, 1)
			D.set(player, S.TiredTree, 2)
			D.startFairyTreasure(player)
			return say(npcHandler, npc, player, tiredTree.story)
		end
		return false
	end
	if MsgContains(message, "map") or MsgContains(message, "mission") then
		if state < 1 then
			return say(npcHandler, npc, player, MsgContains(message, "map") and tiredTree.offer or tiredTree.missionBefore, 1)
		elseif state == 1 then
			return say(npcHandler, npc, player, MsgContains(message, "map") and tiredTree.askStory or tiredTree.askMission, 2)
		end
		return say(npcHandler, npc, player, tiredTree.asleep)
	end
	if MsgContains(message, "yes") then
		if t == 1 and state < 1 then
			D.set(player, S.TiredTree, 1)
			D.startFairyTreasure(player)
			return say(npcHandler, npc, player, tiredTree.accept)
		elseif t == 2 and state == 1 then
			return say(npcHandler, npc, player, tiredTree.which, 2)
		end
		return false
	end
	return false
end

local grumpyStone = {
	offer = {
		"As much as I dislike admitting it: I need help. WE need help. See, when we arrived in this part of the world, we quickly realised that we can't linger here while keeping our true forms. We need to take over animals, plants or stones. ...",
		"And we had to hurry. Some of my siblings were luckier than us and had the chance to take over animals like deer, birds or squirrels. We had to choose these stones and now we are stuck here. ...",
		"I don't know for how long and with this issue you can't help us, I'm afraid. But there is something else, a trifle compared to our main problem. Nonetheless, it is annoying. ...",
		"As for myself I'm fine but my sisters and brothers surrounding us are not. Their backs are itching terribly and we don't have arms and hands to scratch ourselves. Would you help us and scratch my siblings' backs to bring them some relief?",
	},
	accept = "No, this won't work. Your hands are too smooth. I guess you have to search for an appropriate tool. But no metal please! The sound of metal on stone is gruesome!",
	waiting = "My sisters and brothers are still lamenting. Their backs are itching terribly. But no metal please!", -- ours
	done = {
		"Thank you! Their lamentation lapsed into silence. Thus, I assume you brought them some relief. Here, take this map part in return. I'm not interested in this treasure anymore, I just want to return to our hidden realm. ...",
		"Search for the last part somewhere in the Fields of Glory. It's hidden in a big fly agaric.",
	},
	after = "Search for the last part somewhere in the Fields of Glory. It's hidden in a big fly agaric.", -- the end of the EN line
}

-- The five sentient stones around the Grumpy Stone (our map).
D.STONES = {
	Position(32617, 31863, 7),
	Position(32616, 31864, 7),
	Position(32620, 31864, 7),
	Position(32619, 31865, 7),
	Position(32615, 31866, 7),
}

local function stonesDone(player)
	for _, key in ipairs(S.Stones) do
		if D.get(player, key) < 1 then
			return false
		end
	end
	return true
end

D.handlers["Grumpy Stone"] = function(npc, player, message, npcHandler)
	local state = D.get(player, S.GrumpyStone)
	if MsgContains(message, "mission") then
		if state < 1 then
			return say(npcHandler, npc, player, grumpyStone.offer, 1)
		elseif state == 1 then
			if stonesDone(player) then
				player:addItem(D.MAP_UPPER_RIGHT, 1)
				D.set(player, S.GrumpyStone, 2)
				return say(npcHandler, npc, player, grumpyStone.done)
			end
			return say(npcHandler, npc, player, grumpyStone.waiting)
		end
		return say(npcHandler, npc, player, grumpyStone.after)
	end
	if MsgContains(message, "yes") and topic(npcHandler, player) == 1 and state < 1 then
		D.set(player, S.GrumpyStone, 1)
		D.startFairyTreasure(player)
		return say(npcHandler, npc, player, grumpyStone.accept)
	end
	if MsgContains(message, "no") and topic(npcHandler, player) ~= 0 then
		return say(npcHandler, npc, player, "Then go away.") -- ours
	end
	return false
end

-- The rake on a sentient stone (scripts/actions/tools/rake.lua): true when handled.
function D.rakeStone(player, target, toPosition)
	if not D.enabled() or not target or type(target) ~= "userdata" or not target.getId then
		return false
	end
	for i, pos in ipairs(D.STONES) do
		if pos == toPosition then
			if D.get(player, S.GrumpyStone) ~= 1 then
				return false
			end
			local key = S.Stones[i]
			if D.get(player, key) >= 1 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This stone's back doesn't itch anymore.") -- ours
				return true
			end
			D.set(player, key, 1)
			toPosition:sendMagicEffect(CONST_ME_POFF)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You scratch the stone's back with the rake. It seems to be relieved.") -- ours
			return true
		end
	end
	return false
end

-- The big fly agaric in the Fields of Glory: the fourth part joins the other three (EN).
D.FLY_AGARIC = Position(32319, 31701, 7)

function D.useFlyAgaric(player)
	if not D.enabled() or D.get(player, S.GrumpyStone) < 2 or D.get(player, S.OldMap) >= 1 then
		return false
	end
	if not (has(player, D.MAP_UPPER_LEFT) and has(player, D.MAP_BOTTOM_LEFT) and has(player, D.MAP_UPPER_RIGHT)) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You discover the fourth map part between the big fly agaric's gills. But it's useless without the other three parts.") -- EN + ours
		return true
	end
	player:removeItem(D.MAP_UPPER_LEFT, 1)
	player:removeItem(D.MAP_BOTTOM_LEFT, 1)
	player:removeItem(D.MAP_UPPER_RIGHT, 1)
	player:addItem(D.OLD_MAP, 1)
	D.set(player, S.OldMap, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You discover the fourth map part between the big fly agaric's gills.") -- EN
	return true
end

D.OLD_MAP_TEXT = "The old map is artfully drawn. It tells you to search for a stone sun mosaic in the very south of Thais." -- EN

-- The sun mosaic south of Thais (centre stone of our map; EN 32364,32416).
D.TREASURE = Position(32363, 32416, 7)

function D.useTreasure(player)
	if not D.enabled() or not has(player, D.OLD_MAP) then
		return false
	end
	if D.get(player, S.Treasure) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is nothing more hidden beneath the stones.") -- ours
		return true
	end
	local weight = ItemType(25698):getWeight() + ItemType(25737):getWeight(5) + ItemType(24390):getWeight(5)
	if player:getFreeCapacity() < weight then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You discover something shiny that is hidden beneath the stones. But it is too heavy for you to carry.")
		return true
	end
	player:addItem(25698, 1) -- butterfly ring
	player:addItem(25737, 5) -- rainbow quartz
	player:addItem(24390, 5) -- ancient coin
	D.set(player, S.Treasure, 1)
	D.startFairyTreasure(player)
	D.set(player, S.FairyTreasure, 2)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You discover something shiny that is hidden beneath the stones.") -- EN
	D.TREASURE:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end

-- ---------------------------------------------------------------------------
-- Blessed acorns (BR, EN): a watering can on a happy sentient oak, once every 10 hours;
-- the acorn heals like an ultimate spirit potion, again after 10 hours (EN).
-- ---------------------------------------------------------------------------

D.HAPPY_OAK = 25407
D.ACORN_HOURS = 10

function D.waterOak(player, target)
	if not D.enabled() or not target or type(target) ~= "userdata" or target:getId() ~= D.HAPPY_OAK then
		return false
	end
	if player:getStorageValue(S.AcornWater) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The sentient oak doesn't need any more water right now.") -- ours
		return true
	end
	if not D.give(player, D.BLESSED_ACORN, 1, "You have found a blessed acorn") then
		return true
	end
	player:setStorageValue(S.AcornWater, os.time() + D.ACORN_HOURS * 3600)
	target:getPosition():sendMagicEffect(CONST_ME_LOSEENERGY)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You water the sentient oak. A blessed acorn falls down.") -- ours
	return true
end

function D.eatAcorn(player, item)
	if not D.enabled() then
		return false
	end
	if player:getStorageValue(S.AcornEat) > os.time() then
		player:sendTextMessage(MESSAGE_FAILURE, "You have to wait before you can eat another blessed acorn.") -- ours
		return true
	end
	player:addHealth(math.random(435, 565))
	player:addMana(math.random(167, 233))
	player:setStorageValue(S.AcornEat, os.time() + D.ACORN_HOURS * 3600)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	item:remove(1)
	return true
end

-- ---------------------------------------------------------------------------
-- Quest log texts (catalog/045_threatened_dreams.lua), ours: the wikis give no log for these.
-- ---------------------------------------------------------------------------

function D.fairyTreasureLog(player)
	if D.get(player, S.FairyTreasure) >= 2 then
		return "With the old map you found the fairy treasure hidden beneath a stone sun mosaic in the very south of Thais."
	end
	local parts = {}
	local tf = D.get(player, S.ToothFairy)
	if tf == 1 then
		parts[#parts + 1] = "The Tooth Fairy south of Ab'Dendriel asked you to find the milk teeth of Quero's daughter in Thais, Allen's son in Venore and Rowenna's daughter in Carlin and to put her presents on their beds."
	elseif tf >= 2 then
		parts[#parts + 1] = "You brought the milk teeth to the Tooth Fairy and got the first part of an old map."
	end
	local tt = D.get(player, S.TiredTree)
	if tt == 1 then
		parts[#parts + 1] = "The tired trees north of Carlin want a bedtime story about the dryads."
	elseif tt >= 2 then
		parts[#parts + 1] = "The tired trees gave you the second map part for the story of The Seeds of Life."
	end
	local gs = D.get(player, S.GrumpyStone)
	if gs == 1 then
		parts[#parts + 1] = "The Grumpy Stone near Kazordoon asked you to scratch the backs of the five stones around it, but not with metal."
	elseif gs >= 2 then
		parts[#parts + 1] = "The Grumpy Stone gave you the third map part. The last part is hidden in a big fly agaric in the Fields of Glory."
	end
	if D.get(player, S.OldMap) >= 1 then
		parts[#parts + 1] = "You put the four parts together. The old map tells you to search for a stone sun mosaic in the very south of Thais."
	end
	if #parts == 0 then
		return "Some fae hid a treasure and tore its map into four parts."
	end
	return table.concat(parts, " ")
end

D.swanCloakLog = {
	[1] = "The swan maiden Valindara in the fae village of Feyrist will craft a swan feather cloak for you if you bring her one hundred swan feathers. You find them near the swans of Feyrist by day.",
	[2] = "Valindara is crafting your swan feather cloak. Return to her tomorrow.",
	[3] = "Valindara crafted a beautiful swan feather cloak for you.",
}
