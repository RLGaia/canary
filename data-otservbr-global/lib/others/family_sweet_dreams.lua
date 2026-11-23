-- Gaia Family server: Threatened Dreams Quest, Sweet Dreams (Candia, update 13.40), built 2026-11-22
-- (asked by Rodrigo: "Proceed" after the Threatened Dreams review). Upstream had none of it: Candia and its
-- monsters are on our map, but no Candia NPC, no quest item did anything, the donut gates and the Sugar
-- Daddy portal led nowhere, and Gorga did not exist.
--
-- Sources: TibiaWiki BR "Threatened Dreams Quest" (our backup: steps, transcripts, server messages,
-- positions) and TibiaWiki EN (Threatened Dreams Quest/Spoiler, item, NPC and boss pages). The EN wiki
-- has no transcript pages for these NPCs. Lines marked "ours" are on neither wiki.
--
-- Steps (storage S.Main, quest log "Sweet Dreams"):
--   1 Maelyrra `donut` (after A Dream Come True): find the forest fury in Vandura.
--   2 A Captive Forest Fury (Corym Black Market, floor -4) `yes`.
--     The intricate cage key from the chest two floors down; the mirror image spell from Charlotta
--     (`mirror image`, 1000 gold); invisible, use the key on the cage door: both items are used up.
--   3 escaping: a message at each floor up, the last one outside the market (BR), A Friend in Need and
--     the gingerbread key recipe.
--   4 bake: lump of chocolate dough on the oven in Feyrist (our map lacked it: placed at startup), sugar
--     from the boxes in the three caves of the tainted fae (placed at startup), moon melons by night
--     (placed at startup, ours: white crystals mark them), lemons and raspberries from Valindara;
--     sugar on each fruit makes its sirup; glaze in the order moon melon, raspberry, lemon.
--   5 the glazed key on the donut gate (used up): from then on the gate leads to Candia (upstream's
--     teleport let everybody in).
--     Candia's NPCs only gesture until you used the candy lipstick from the castle (BR, EN).
--   6 Sugar Plum Fairy `mission`, `yes`: matcha turtle (Kroazur, with a tattered piece of paper), rose
--     milk cake (The Flaming Orchid), nightsky cupcake (Gorga, new: top of the Medusa Tower), rainbow
--     waffles (Katex Blood Tongue), always in the corpse while you need them (EN); deliver each by name.
--   7 Chocolate Mines (Candis, sub-steps S.Candis): Sugar Daddy behind the portal on floor -2 (our map's
--     portal had no destination; 2 h per player, BR), 3 candy cane beams from the chest north of Candis
--     on the three cordoned walls, 5 honey elementals in empty honey glasses.
--   8 report to the Sugar Plum Fairy; 9 the Candy Carnival is open (Toffee trades).
--  10 Dulcineo (greeting); 11 Tooth Fairy (Feyrist) `mission`: three toothbrushes on the pillows of
--     Quero's, Allen's and Rowenna's children; 12 the Pegasus Feather (use: the Pegasus mount and
--     I Wanna Fly Away); 13 Dulcineo thanks you.
--   Put the Cherry in the Cage (S.Bunny): Sugar Plum Fairy `taffy bunny`, A Taffy Bunny in the
--   Dessert Dungeons, report.
-- Added later the same day (Rodrigo: "Is it possible to proceed with these?"): Sugar Daddy's sugar rush
-- (summons, Powerless, Hex, the spoon on his body), Coco's two chocolate coin shops, the sand toys
-- (marzipan carrots, the trough, the surface taffy bunny's tip, the treasure, sand and vanilla sugar
-- castles), the four real-life recipes and the roleplay NPCs Jelly, A Floating Sugar Ball and A Stressed
-- Sugar Cube Worker. Sections below; their sources are in each section's header.
--
-- Player storages: 45836-45850 of the Threatened Dreams block; player KV "family-sweet-dreams".
-- World objects: scripts/family/sweet_dreams.lua. NPCs: sugar_plum_fairy, candis, dulcineo,
-- tooth_fairy_candia, a_captive_forest_fury, a_taffy_bunny, a_taffy_bunny_surface, toffee, coco, jelly,
-- a_floating_sugar_ball, a_stressed_sugar_cube_worker (ours) and maelyrra, charlotta. Monsters (ours):
-- cheeky_sugar_cube, mint_drop, truffle_worker.
-- Switch: Family.sweetDreams (false = none of this).

Family = Family or {}
Family.sweetDreams = true

FamilySweetDreams = FamilySweetDreams or {}
local SD = FamilySweetDreams

function SD.enabled()
	return Family.sweetDreams == true
end

SD.S = {
	Main = 45836,
	Bunny = 45837, -- 1 asked, 2 found, 3 reported
	Lipstick = 45838, -- 1 greeted the Sugar Plum Fairy, 2 lipstick used
	Candis = 45839, -- 1 workers missing, 2 Sugar Daddy killed, 3 candy canes, 4 walls done, 5 honey, 6 done
	Escape = 45840, -- the next escape message
	Sweets = { matcha = 45841, rose = 45842, waffles = 45843, nightsky = 45844 },
	Walls = { 45845, 45846, 45847 },
	Toothbrush = { quero = 45848, allen = 45849, rowenna = 45850 },
}
local S = SD.S

-- Items
SD.RECIPE = 48102
SD.CAGE_KEY = 48190
SD.MIRROR_SPELL = 48192
SD.OVEN = 48193
SD.CHOCOLATE_DOUGH = 8018
SD.KEY = { 48198, 48199, 48200, 48178 } -- plain, moon melon, + raspberry, + lemon
SD.SUGAR = 48201
SD.MOON_MELON = 48197
SD.LEMON, SD.RASPBERRY = 8013, 8012
SD.SIRUP = { moon = 48194, raspberry = 48195, lemon = 48196 }
SD.LIPSTICK = 48241
SD.PAPER = 48278
SD.CANDY_CANE = 48359
SD.HONEY_EMPTY, SD.HONEY_FULL = 31331, 48280
SD.TOOTHBRUSH = 48423
SD.PEGASUS_FEATHER = 48424
SD.PEGASUS_MOUNT = 227
SD.WHITE_CRYSTALS = 25356 -- ours: marks a moon melon plant (our map has none)
SD.SUGAR_BOX = 2469 -- box

SD.SWEETS = {
	{ key = "matcha", word = "matcha turtle", id = 48239, boss = "kroazur", line = "You found my matcha turtle! Thank you so much for bringing it back!" },
	{ key = "rose", word = "rose milk cake", id = 48238, boss = "the flaming orchid", line = "You found my rose milk cake! Thank you so much for bringing it back!" },
	{ key = "waffles", word = "rainbow waffles", id = 48248, boss = "katex blood tongue", line = "You found my rainbow waffles! Thank you so much for bringing them back!" },
	{ key = "nightsky", word = "nightsky cupcake", id = 48240, boss = "gorga", line = "You found my nightsky cupcake! Thank you so much for bringing it back!" },
}

-- Places
SD.OVEN_POS = Position(33516, 32230, 6) -- BR 33517,32230,6: that square is open air on our map
SD.CAGE_DOOR = Position(32294, 32837, 11)
SD.KEY_CHEST = Position(32296, 32793, 13)
SD.LIPSTICK_BOX = Position(33433, 32142, 4) -- the box in the castle (EN 33433,32143; BR 33434,32142)
SD.SUGAR_BOXES = { Position(33422, 32214, 8), Position(33495, 32284, 8), Position(33570, 32185, 9) } -- BR
SD.MELONS = { Position(33570, 32179, 7), Position(33396, 32227, 7), Position(33411, 32238, 7), Position(33439, 32244, 7), Position(33449, 32259, 7) } -- BR
SD.CANE_CHEST = { Position(33365, 32132, 8), Position(33365, 32133, 8), Position(33365, 32134, 8) } -- BR 33365,32132,8
SD.WALLS = { Position(33408, 32143, 8), Position(33360, 32180, 8), Position(33412, 32173, 9) } -- BR
SD.SUGAR_DADDY = {
	portal = Position(33397, 32200, 9), -- the portal (action id 30000 on our map, no destination)
	boss = Position(33372, 32226, 9),
	entry = Position(33372, 32241, 9),
	exit = Position(33372, 32244, 9), -- the end of the corridor leads back (ours)
	back = Position(33397, 32202, 9),
	from = Position(33360, 32215, 9),
	to = Position(33385, 32245, 9),
	minutes = 20, -- ours
	cooldown = 2 * 3600, -- BR
}
SD.DUNGEON_ENTRY = { from = Position(33430, 32139, 8), to = Position(33438, 32147, 8) } -- below the cave east of the castle (BR)

function SD.get(player, key)
	local v = player:getStorageValue(key)
	return v < 0 and 0 or v
end

function SD.set(player, key, value)
	player:setStorageValue(key, value)
end

local function kv(player)
	local k = player.kv and player:kv()
	return k and k:scoped("family-sweet-dreams")
end
function SD.kvGet(player, key)
	local k = kv(player)
	return k and k:get(key) or nil
end
function SD.kvSet(player, key, value)
	local k = kv(player)
	if k then
		k:set(key, value)
	end
end

local function has(player, id, n)
	return player:getItemCount(id) >= (n or 1)
end

local function addAchievement(player, name)
	if player.hasAchievement and not player:hasAchievement(name) then
		player:addAchievement(name)
	end
end

function SD.main(player)
	return SD.get(player, S.Main)
end

function SD.canTalk(player)
	return SD.get(player, S.Lipstick) >= 2
end

-- ---------------------------------------------------------------------------
-- NPC talk
-- ---------------------------------------------------------------------------

SD.handlers = {}
SD.npcs = {
	["Sugar Plum Fairy"] = { greet = "Sweet greetings, dear visitor!", farewell = "Sweet dreams!" }, -- farewell ours
	["Candis"] = { greet = "Greetings!", farewell = "Watch your step down here!" }, -- farewell ours
	["Dulcineo"] = { greet = "Sweet greetings, dear visitor!", farewell = "Farewell, my friend." }, -- ours
	["Tooth Fairy (Candia)"] = { greet = "Greetings, human being.", farewell = "Farewell, human being." }, -- farewell ours
	["A Captive Forest Fury"] = { greet = "Better not talk to me. It could make them angry.", farewell = "Farewell. May your dreams be pleasant." },
	["A Taffy Bunny"] = { greet = "*sniff* *sniff*", farewell = "*hop*" }, -- ours
	["Toffee"] = { greet = "Sweet greetings! Fresh fruit for candying, cakes and cookies!", farewell = "Sweet greetings!" }, -- ours
}

-- Candia's NPCs only gesture before the lipstick (BR transcripts of the Sugar Plum Fairy, Dulcineo, Toffee).
SD.gestures = {
	["Sugar Plum Fairy"] = "*The beautiful fairy greets you but you don't understand her. She makes a gesture as if to apply some lipstick. Then she is pointing upstairs. But what does that mean?*",
	["Dulcineo"] = "*The pastel-coloured faun greets you but you don't understand him. He makes a gesture as if to apply some lipstick. Then he is pointing to the east. But what does that mean?*",
	["Toffee"] = "*The globose cook greets you but you don't understand him. He makes a gesture as if to apply some lipstick. Then he is pointing to the east. But what does that mean?*",
	["Candis"] = "*The sugary miner greets you but you don't understand a word. It makes a gesture as if to apply some lipstick. Then it is pointing upwards. But what does that mean?*", -- ours
}

local function say(npcHandler, npc, player, text, t)
	npcHandler:say(text, npc, player)
	npcHandler:setTopic(player:getId(), t or 0)
	return true
end
local function topic(npcHandler, player)
	return npcHandler:getTopic(player:getId())
end

function SD.greeting(name, player)
	if SD.gestures[name] and not SD.canTalk(player) then
		if name == "Sugar Plum Fairy" and SD.get(player, S.Lipstick) < 1 then
			SD.set(player, S.Lipstick, 1) -- now the box upstairs holds the lipstick (EN)
		end
		return SD.gestures[name]
	end
	if name == "Sugar Plum Fairy" and SD.get(player, S.Lipstick) == 2 and not SD.kvGet(player, "fairy-understood") then
		SD.kvSet(player, "fairy-understood", true)
		return "Ah, I see, you used the candy lipstick. Now I understand you! Sweet greetings, dear visitor!" -- BR
	end
	if name == "A Captive Forest Fury" and SD.main(player) >= 1 and SD.main(player) <= 2 then
		return "Greetings, stranger. Please tell me, that you are here to help me!" -- BR
	end
	if name == "Dulcineo" then
		return SD.dulcineoGreeting(player)
	end
	if name == "A Taffy Bunny" then
		return SD.bunnyGreeting(player)
	end
	if name == "A Taffy Bunny (Surface)" then
		return SD.surfaceBunnyGreeting(player)
	end
	return SD.npcs[name].greet
end

function SD.talk(name, npc, creature, message, npcHandler, fallback)
	local player = Player(creature)
	if not player then
		return true
	end
	if SD.gestures[name] and not SD.canTalk(player) then
		return say(npcHandler, npc, player, SD.gestures[name])
	end
	local handler = SD.handlers[name]
	if handler and handler(npc, player, message, npcHandler) then
		return true
	end
	if fallback then
		return fallback(npc, creature, nil, message)
	end
	return true
end

function SD.setupNpc(name, npcHandler, opts)
	local info = SD.npcs[name]
	if not info or not SD.enabled() then
		return
	end
	opts = opts or {}
	npcHandler:setMessage(MESSAGE_GREET, info.greet)
	npcHandler:setMessage(MESSAGE_FAREWELL, info.farewell)
	npcHandler:setMessage(MESSAGE_WALKAWAY, info.farewell)
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
		local player = Player(creature)
		npcHandler:setMessage(MESSAGE_GREET, player and SD.greeting(name, player) or info.greet)
		return true
	end)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		if not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		return SD.talk(name, npc, creature, message, npcHandler, opts.fallback)
	end)
	if SD.gestures[name] then
		-- no trade before the lipstick, no trade before the Candy Carnival (EN: "You can now trade with Coco and Toffee")
		npcHandler:setCallback(CALLBACK_ON_TRADE_REQUEST, function(npc, creature)
			local player = Player(creature)
			if not player then
				return false
			end
			if not SD.canTalk(player) then
				npcHandler:say(SD.gestures[name], npc, creature)
				return false
			end
			if SD.main(player) < 9 then
				npcHandler:say("Sorry, the Candy Carnival isn't open yet. There is trouble in the Chocolate Mines.", npc, creature) -- ours
				return false
			end
			if opts.onTrade then
				return opts.onTrade(npc, player)
			end
			return true
		end)
	end
end

-- ----------------------------------------------------------- Maelyrra: donut
SD.maelyrraDonut = {
	"So, you saw the gate. Yes, I know where it leads: the island Candia, also known as Candyland. But you won't be able to pass. You will need a key - a home-baked key made from gingerbread dough, to be precise. ...",
	"But they have all been eaten and we don't have the recipe to bake new ones. A forest fury snatched it, but we lost track of her somewhere in Vandura. If you can find her, maybe you will find the recipe.",
}

-- called by FamilyThreatenedDreams' Maelyrra handler
function SD.maelyrra(npc, player, message, npcHandler)
	if not SD.enabled() or not (MsgContains(message, "donut") or MsgContains(message, "candia")) then
		return false
	end
	local M2 = Storage.Quest.U11_40.ThreatenedDreams.Mission02[1]
	if player:getStorageValue(M2) < 8 then
		return say(npcHandler, npc, player, "First help us to protect Feyrist, mortal being.") -- ours
	end
	if SD.main(player) < 1 then
		SD.set(player, S.Main, 1)
	end
	return say(npcHandler, npc, player, SD.maelyrraDonut)
end

-- ----------------------------------------------------------- the forest fury
local fury = {
	ask = {
		"I'm so happy to hear that. But you can't guide me out of here just like that - even if you had the key to this cage. You need to find a way to make me invisible so I can get out unseen. ...",
		"And if they see the cage is empty, there will be turmoil. If you find a way to create a mirror image of mine, an illusion, then they will think, I'm still in here. Yes, that could work. You should talk to someone who knows a bunch of spells.",
	},
	job = "I'm a prisoner here, as you can see.",
	name = "A forest fury never tells her real name.",
	time = "Time seems endless in this cage.",
	free = "Thank you again, friend. The recipe will help the fae.", -- ours
	waiting = "Please hurry! Find the key to this cage and a way to create a mirror image of mine.", -- ours
}

SD.handlers["A Captive Forest Fury"] = function(npc, player, message, npcHandler)
	if MsgContains(message, "job") then
		return say(npcHandler, npc, player, fury.job)
	elseif MsgContains(message, "name") then
		return say(npcHandler, npc, player, fury.name)
	elseif MsgContains(message, "time") then
		return say(npcHandler, npc, player, fury.time)
	end
	local main = SD.main(player)
	if MsgContains(message, "yes") or MsgContains(message, "help") or MsgContains(message, "recipe") then
		if main == 1 or main == 2 then
			SD.set(player, S.Main, 2)
			return say(npcHandler, npc, player, fury.ask)
		elseif main >= 3 then
			return say(npcHandler, npc, player, fury.free)
		end
		return say(npcHandler, npc, player, "Better not talk to me. It could make them angry.") -- BR greeting
	end
	return false
end

-- Charlotta (npc/charlotta.lua): the forest fury mirror image scroll.
SD.charlotta = {
	offer = "A very special wish. But yes, I have such a spell. Do you want to buy a forest fury mirror image scroll for 1000 gold?",
	sold = "Here you are. It will make a forest fury invisible and at the same time create an exact mirror image of her.",
	noMoney = "You don't have enough money.", -- ours
}
-- returns true when handled; topic 9001 waits for the yes
function SD.charlottaSay(npc, player, message, npcHandler)
	if not SD.enabled() then
		return false
	end
	if MsgContains(message, "mirror image") then
		if SD.main(player) < 2 then
			return false
		end
		return say(npcHandler, npc, player, SD.charlotta.offer, 9001)
	end
	if topic(npcHandler, player) == 9001 then
		if MsgContains(message, "yes") then
			if not player:removeMoneyBank(1000) then
				return say(npcHandler, npc, player, SD.charlotta.noMoney)
			end
			player:addItem(SD.MIRROR_SPELL, 1)
			return say(npcHandler, npc, player, SD.charlotta.sold)
		end
		npcHandler:setTopic(player:getId(), 0)
		return MsgContains(message, "no") and say(npcHandler, npc, player, "Then not.") or false
	end
	return false
end

-- The chest two floors below the cage (BR): the intricate cage key, again if lost before the fury is free.
function SD.keyChest(player)
	if not SD.enabled() then
		return false
	end
	if SD.main(player) ~= 2 or has(player, SD.CAGE_KEY) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
		return true
	end
	player:addItem(SD.CAGE_KEY, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found an intricate cage key.") -- BR
	return true
end

SD.ESCAPE = {
	"You make your way back to the exit. The invisible forest fury follows you quietly.",
	"Getting the invisible forest fury up the ladder is not an easy task. You almost get caught.",
	"Roping up a forest fury might be even more challenging than using the ladder. Fingers crossed!",
	"Quiet now! Hurry!",
	"Another rope spot ... Alright, you can do this!",
	"The narrow bridge is made of rotten planks. Fortunately, it can withstand the forest fury's weight.",
	"Another ladder ... But the last one, at least.",
	"You reach safety. 'Thank you, friend!', the forest fury whispers. She slips you a piece of paper before disappearing.",
} -- BR server log, in this order
-- which messages a floor shows when you reach it (ours: the wikis give the order, not the squares)
SD.ESCAPE_FLOORS = { [10] = { 2 }, [9] = { 3, 4 }, [8] = { 5, 6 }, [7] = { 7, 8 } }

-- The key on the cage door, invisible and with the mirror image spell (BR).
function SD.useCageKey(player, toPosition)
	if not SD.enabled() or toPosition ~= SD.CAGE_DOOR then
		return false
	end
	if SD.main(player) ~= 2 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The forest fury looks at you with big eyes.") -- ours
		return true
	end
	if not has(player, SD.MIRROR_SPELL) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "If you just open the cage, the Coryms will notice that the forest fury is gone. You need a mirror image of her.") -- ours
		return true
	end
	if not player:getCondition(CONDITION_INVISIBLE) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "They would see you. You have to be invisible to do this.") -- ours
		return true
	end
	player:removeItem(SD.CAGE_KEY, 1)
	player:removeItem(SD.MIRROR_SPELL, 1)
	SD.set(player, S.Main, 3)
	SD.set(player, S.Escape, 2)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cast the spell and the forest fury turns invisible. At the same time, an exact mirror image of her appears in the cage.")
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "At a favourable moment, you unlock the cage door and the forest fury slips out. It seems that nobody has noticed anything")
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, SD.ESCAPE[1])
	toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end

-- Called every few seconds for players on the escape (scripts/family/sweet_dreams.lua).
function SD.escapeTick(player)
	if SD.main(player) ~= 3 then
		return
	end
	local pos = player:getPosition()
	local nextMsg = SD.get(player, S.Escape)
	local list = SD.ESCAPE_FLOORS[pos.z]
	if not list or nextMsg < 2 then
		return
	end
	for _, i in ipairs(list) do
		if i >= nextMsg then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, SD.ESCAPE[i])
			nextMsg = i + 1
		end
	end
	SD.set(player, S.Escape, nextMsg)
	if nextMsg > #SD.ESCAPE then
		SD.set(player, S.Main, 4)
		addAchievement(player, "A Friend in Need")
		player:addItem(SD.RECIPE, 1)
	end
end

-- ----------------------------------------------------------- baking
function SD.bakeKey(player, item, target, toPosition)
	if not SD.enabled() or not target or type(target) ~= "userdata" or target:getId() ~= SD.OVEN then
		return false
	end
	if SD.main(player) < 4 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You don't know what to bake in this oven.") -- ours
		return true
	end
	item:remove(1)
	local key = Game.createItem(SD.KEY[1], 1, toPosition) -- EN: the key appears on top of the oven
	if not key then
		player:addItem(SD.KEY[1], 1)
	end
	toPosition:sendMagicEffect(CONST_ME_HITBYFIRE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You shape the dough into a key and bake it in the oven.") -- ours
	return true
end

-- Sugar on a fruit makes a sirup (BR, EN).
function SD.useSugar(player, item, target)
	if not SD.enabled() or not target or type(target) ~= "userdata" or not target.getId then
		return false
	end
	local sirup = ({ [SD.LEMON] = SD.SIRUP.lemon, [SD.RASPBERRY] = SD.SIRUP.raspberry, [SD.MOON_MELON] = SD.SIRUP.moon })[target:getId()]
	if not sirup then
		return false
	end
	target:remove(1)
	item:remove(1)
	player:addItem(sirup, 1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	return true
end

-- A sirup on the gingerbread key: moon melon, raspberry, lemon (BR).
local GLAZE = {
	[48194] = { from = 48198, to = 48199 },
	[48195] = { from = 48199, to = 48200 },
	[48196] = { from = 48200, to = 48178 },
}
local NEXT_SIRUP = { [48198] = "moon melon", [48199] = "raspberry", [48200] = "lemon" }
function SD.useSirup(player, item, target)
	if not SD.enabled() or not target or type(target) ~= "userdata" or not target.getId then
		return false
	end
	local key = target:getId()
	if not NEXT_SIRUP[key] then
		return false
	end
	local step = GLAZE[item:getId()]
	if step.from ~= key then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You should use the " .. NEXT_SIRUP[key] .. " sirup first. At least, the recipe says so. Just to be sure …") -- BR (moon melon); the others ours
		return true
	end
	item:remove(1)
	target:transform(step.to)
	player:getPosition():sendMagicEffect(step.to == SD.KEY[4] and CONST_ME_FIREWORK_YELLOW or CONST_ME_MAGIC_GREEN)
	return true
end

-- The sugar boxes in the three caves (BR): one sugar each, again after an hour (BR) until Candia is reached.
function SD.sugarBox(player, index)
	if not SD.enabled() or SD.main(player) < 4 or SD.main(player) >= 5 then
		return false
	end
	local key = "sugar-" .. index
	if (SD.kvGet(player, key) or 0) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The box is empty.")
		return true
	end
	SD.kvSet(player, key, os.time() + 3600)
	player:addItem(SD.SUGAR, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found some sugar.") -- ours
	return true
end

-- Moon melons by night (EN spoiler), each plant again after a minute (ours: EN "the reload time is short").
function SD.moonMelon(player, index)
	if not SD.enabled() then
		return false
	end
	if getTibiaTimerDayOrNight() ~= "night" then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The moon melons are still unripe. They ripen in the moonlight.") -- ours
		return true
	end
	local key = "melon-" .. index
	if (SD.kvGet(player, key) or 0) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is no ripe moon melon left right now.") -- ours
		return true
	end
	SD.kvSet(player, key, os.time() + 60)
	player:addItem(SD.MOON_MELON, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You harvest a moon melon.") -- ours
	return true
end

-- The donut gate in Feyrist (scripts/movements/teleport/candia.lua asks this before it teleports):
-- the glazed gingerbread key opens it once and is used up; from then on it is open for you.
function SD.gateOpen(player)
	if not SD.enabled() or SD.main(player) >= 5 then
		return true
	end
	if SD.main(player) == 4 and has(player, SD.KEY[4]) and player:removeItem(SD.KEY[4], 1) then
		SD.set(player, S.Main, 5)
		return true
	end
	return false -- BR: "Ao tentar passar por ele, nada acontecerá."
end

-- The castle box: the candy lipstick, after greeting the Sugar Plum Fairy (EN).
function SD.lipstickBox(player)
	if not SD.enabled() or SD.get(player, S.Lipstick) ~= 1 or has(player, SD.LIPSTICK) then
		return false
	end
	player:addItem(SD.LIPSTICK, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a candy lipstick.")
	return true
end

function SD.useLipstick(player, item)
	if not SD.enabled() then
		return false
	end
	SD.set(player, S.Lipstick, 2)
	item:remove(1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You paint your lips with the sweet sugar. Now you should be able to speak and understand Candy Fae.") -- BR
	player:getPosition():sendMagicEffect(CONST_ME_HEARTS)
	return true
end

-- ----------------------------------------------------------- Sugar Plum Fairy
local fairy = {
	offer = "Four of my rarest and most prized sweets were stolen: a matcha turtle, a nightsky cupcake, a rose milk cake and rainbow waffles. It was Kroazur, a wicked creature from the nightmare realms, who took them. Bring them back, will you?",
	accept = "How very sweet of you! I hope, the monster has not eaten them yet.",
	ask = "Did you already find my stolen sweets? I hope, the monster has not eaten them yet.",
	lastSweet = {
		"You really did me a great favour - but may I still ask for another? I have reason to believe that there is something wrong down in the Chocolate Mines. ...",
		"Please go there and check if everything is alright. You can find the entrance in the Chocolate Mountains near the Candy Carnival.",
	},
	mines = "Please go to the Chocolate Mines and check if everything is alright. You can find the entrance in the Chocolate Mountains near the Candy Carnival.", -- BR fragment
	carnival = {
		"Thank you for helping us with the problems in our Chocolate Mines! Now that our problems have been solved and we can enjoy being carefree and happy again, the long-awaited Candy Carnival may finally begin. ...",
		"You are of course cordially invited! You will find the festival grounds in the south of the island on the shores of the Moon Melon Sea.",
	},
	invited = "You are of course cordially invited! You will find the festival grounds in the south of the island on the shores of the Moon Melon Sea.", -- the end of the BR line
	notThis = "You don't have it with you, dear visitor.", -- ours
	already = "You already brought it back to me. Thank you!", -- ours
	bunnyOffer = {
		"Yes, one of my cute taffy bunnies has run away. Her name is Cherry and I'm really worried. She loves underground tunnels and caves, but there are nightmares from Roshamuul lurking down there with an appetite for sweet smaller creatures. ...",
		"Maybe you can keep an eye out for Cherry on your travels through Candia?",
	},
	bunnyAccept = "Thank you! I hope, you will find her.",
	bunnyWaiting = "Have you seen my little Cherry? She loves underground tunnels and caves.", -- ours
	bunnyFound = {
		"So the little runaway is down at the Hot Milk Springs? Unbelievable that she ran so far away, but she was always the more curious of my two taffies. I think she'll want to stay down there for a while. ...",
		"But at least now I know where she is. And the truffles who are relaxing there will certainly keep an eye on her. Thanks for your help, my friend!",
	},
	bunnyDone = "Thanks again for finding my little Cherry!", -- ours
}

local function sweetsLeft(player)
	local n = 0
	for _, s in ipairs(SD.SWEETS) do
		if SD.get(player, S.Sweets[s.key]) < 1 then
			n = n + 1
		end
	end
	return n
end

SD.handlers["Sugar Plum Fairy"] = function(npc, player, message, npcHandler)
	local main = SD.main(player)
	local t = topic(npcHandler, player)
	if MsgContains(message, "taffy bunny") or MsgContains(message, "bunny") or MsgContains(message, "cherry") then
		local b = SD.get(player, S.Bunny)
		if b < 1 then
			return say(npcHandler, npc, player, fairy.bunnyOffer, 2)
		elseif b == 1 then
			return say(npcHandler, npc, player, fairy.bunnyWaiting)
		elseif b == 2 then
			SD.set(player, S.Bunny, 3)
			return say(npcHandler, npc, player, fairy.bunnyFound)
		end
		return say(npcHandler, npc, player, fairy.bunnyDone)
	end
	for _, s in ipairs(SD.SWEETS) do
		if MsgContains(message, s.word) and main == 6 then
			if SD.get(player, S.Sweets[s.key]) >= 1 then
				return say(npcHandler, npc, player, fairy.already)
			end
			if not (has(player, s.id) and player:removeItem(s.id, 1)) then
				return say(npcHandler, npc, player, fairy.notThis)
			end
			SD.set(player, S.Sweets[s.key], 1)
			if sweetsLeft(player) == 0 then
				SD.set(player, S.Main, 7)
				local lines = { s.line .. " " .. fairy.lastSweet[1], fairy.lastSweet[2] }
				return say(npcHandler, npc, player, lines)
			end
			return say(npcHandler, npc, player, s.line)
		end
	end
	if MsgContains(message, "mission") then
		if main == 5 then
			return say(npcHandler, npc, player, fairy.offer, 1)
		elseif main == 6 then
			return say(npcHandler, npc, player, fairy.ask)
		elseif main == 7 then
			return say(npcHandler, npc, player, fairy.mines)
		elseif main == 8 then
			SD.set(player, S.Main, 9)
			return say(npcHandler, npc, player, fairy.carnival)
		elseif main >= 9 then
			return say(npcHandler, npc, player, fairy.invited)
		end
		return false
	end
	if MsgContains(message, "yes") then
		if t == 1 and main == 5 then
			SD.set(player, S.Main, 6)
			return say(npcHandler, npc, player, fairy.accept)
		elseif t == 2 and SD.get(player, S.Bunny) < 1 then
			SD.set(player, S.Bunny, 1)
			return say(npcHandler, npc, player, fairy.bunnyAccept)
		end
		return false
	end
	if MsgContains(message, "no") and t ~= 0 then
		return say(npcHandler, npc, player, "What a pity.") -- ours
	end
	return false
end

-- The bosses keep the sweets in their corpse while a player needs one (EN item pages: 100% until handed in).
function SD.bossLoot(monster, corpse)
	if not SD.enabled() or not corpse or not monster then
		return
	end
	local name = monster:getName():lower()
	local sweet
	for _, s in ipairs(SD.SWEETS) do
		if s.boss == name then
			sweet = s
		end
	end
	if not sweet then
		return
	end
	local needs, paper = false, false
	for cid, _ in pairs(monster:getDamageMap() or {}) do
		local p = Player(cid)
		if p and SD.main(p) == 6 and SD.get(p, S.Sweets[sweet.key]) < 1 then
			needs = true
			if sweet.key == "matcha" and SD.get(p, S.Sweets.matcha) < 1 then
				paper = true
			end
		end
	end
	if needs then
		corpse:addItem(sweet.id, 1)
		if paper then
			corpse:addItem(SD.PAPER, 1)
		end
	end
end

-- ----------------------------------------------------------- Candis
local candis = {
	workers = {
		"That is very thoughtful and kind of our sweet regent to send us help. We actually have a few problems down here, but the most serious one is that some of my workers have disappeared. However, I have a hunch where they might be. ...",
		"A terrible guess. There's a portal in the lower levels of the mines that all workers should keep away from. It leads to a cave where a dangerous monster lives. ...",
		"However, I fear that some of my workers were too curious and ventured near the portal anyway. Please, perhaps you can find them.",
	},
	workersHint = "There's a portal in the lower levels of the mines that all workers should keep away from. Please, perhaps you can find them.", -- BR fragments
	canes = {
		"Thank you so much for bringing back my missing workers. However, there is something else I need to ask you. We have a small security problem down here. Some parts of the mine are in acute danger of collapsing. ...",
		"You can easily recognise them, they are cordoned off areas with warning signs. The walls there need to be reinforced with new candy canes. You can find some in the chest over there. Please use them to stabilise the relevant areas.",
	},
	canesHint = "The walls there need to be reinforced with new candy canes. You can find some in the chest over there. Please use them to stabilise the relevant areas.", -- the end of the BR line
	honey = {
		"Very good! Thank you, my workers will be much safer now. But there is one last thing: Theft. Yes, I know it sounds outrageous, but it's true! Cherry drops, which are particularly rare and difficult to mine, keep getting stolen from us. ...",
		"But I know the culprits: The honey elementals who live in some of the smaller caves in this mine. But they only use the drops for vain purposes. ...",
		"Just imagine, they ingest them and when the drops dissolve in their honey body, they take on a beautiful reddish color. But that's not what the drops are for! Vain nonsense! Please, catch the cheeky honey elementals. ...",
		"It's best to lock them up in a few honey pots so they can't get up to any more mischief. Here, take those glasses to catch them, that should work.",
	},
	honeyHint = "Please, catch the cheeky honey elementals and lock them up in the honey glasses I gave you.", -- ours (BR fragments)
	moreGlasses = "You lost the glasses? Here, take some more.", -- ours
	done = "Well done! Thank you for catching those cheeky honey elementals! Our cherry drops should be safe now and the work in the mines can continue undisturbed.",
	after = "The work in the mines can continue undisturbed. Thank you!", -- ours (BR fragment)
}

SD.handlers["Candis"] = function(npc, player, message, npcHandler)
	if not (MsgContains(message, "mission") or MsgContains(message, "yes")) then
		return false
	end
	if MsgContains(message, "yes") and topic(npcHandler, player) == 0 then
		return false
	end
	local main, c = SD.main(player), SD.get(player, S.Candis)
	if main < 7 then
		return say(npcHandler, npc, player, "Visitors? Down here? Please be careful, the mines are dangerous.") -- ours
	end
	if main > 7 or c >= 6 then
		return say(npcHandler, npc, player, candis.after)
	end
	if c < 1 then
		SD.set(player, S.Candis, 1)
		return say(npcHandler, npc, player, candis.workers)
	elseif c == 1 then
		return say(npcHandler, npc, player, candis.workersHint)
	elseif c == 2 then
		SD.set(player, S.Candis, 3)
		return say(npcHandler, npc, player, candis.canes)
	elseif c == 3 then
		local done = 0
		for _, key in ipairs(S.Walls) do
			done = done + (SD.get(player, key) >= 1 and 1 or 0)
		end
		if done < #S.Walls then
			return say(npcHandler, npc, player, candis.canesHint)
		end
		SD.set(player, S.Candis, 5)
		player:addItem(SD.HONEY_EMPTY, 5)
		return say(npcHandler, npc, player, candis.honey)
	elseif c == 5 then
		if has(player, SD.HONEY_FULL, 5) and player:removeItem(SD.HONEY_FULL, 5) then
			SD.set(player, S.Candis, 6)
			SD.set(player, S.Main, 8)
			return say(npcHandler, npc, player, candis.done)
		end
		if player:getItemCount(SD.HONEY_EMPTY) + player:getItemCount(SD.HONEY_FULL) < 5 then
			player:addItem(SD.HONEY_EMPTY, 5 - player:getItemCount(SD.HONEY_EMPTY) - player:getItemCount(SD.HONEY_FULL))
			return say(npcHandler, npc, player, candis.moreGlasses)
		end
		return say(npcHandler, npc, player, candis.honeyHint)
	end
	return false
end

-- The chest north of Candis: three candy cane beams (again if lost while the walls are not done).
function SD.caneChest(player)
	if not SD.enabled() or SD.get(player, S.Candis) ~= 3 then
		return false
	end
	local needed = 0
	for _, key in ipairs(S.Walls) do
		needed = needed + (SD.get(player, key) >= 1 and 0 or 1)
	end
	needed = needed - player:getItemCount(SD.CANDY_CANE)
	if needed <= 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
		return true
	end
	player:addItem(SD.CANDY_CANE, needed)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, needed == 1 and "You have found a candy cane beam." or ("You have found " .. needed .. " candy cane beams."))
	return true
end

function SD.useCandyCane(player, item, toPosition)
	if not SD.enabled() or SD.get(player, S.Candis) ~= 3 then
		return false
	end
	for i, pos in ipairs(SD.WALLS) do
		if pos.z == toPosition.z and math.abs(pos.x - toPosition.x) <= 1 and math.abs(pos.y - toPosition.y) <= 1 then
			if SD.get(player, S.Walls[i]) >= 1 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This wall is already reinforced.") -- ours
				return true
			end
			item:remove(1)
			SD.set(player, S.Walls[i], 1)
			toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You reinforce the wall with a candy cane beam.") -- ours
			return true
		end
	end
	return false
end

-- An empty honey glass on a honey elemental (EN: "You have caught the honey elemental in the pot.").
function SD.useHoneyGlass(player, item, target)
	if not SD.enabled() or SD.get(player, S.Candis) ~= 5 then
		return false
	end
	if not target or type(target) ~= "userdata" or not target.isMonster or not target:isMonster() or target:getName():lower() ~= "honey elemental" then
		return false
	end
	if target:getMaster() then
		return false
	end
	target:getPosition():sendMagicEffect(CONST_ME_POFF)
	target:remove()
	item:remove(1)
	player:addItem(SD.HONEY_FULL, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have caught the honey elemental in the pot.")
	return true
end

-- Sugar Daddy's portal (action id 30000) and room.
function SD.enterSugarDaddy(player, fromPosition)
	local r = SD.SUGAR_DADDY
	if not player:canFightBoss("Sugar Daddy") then
		player:teleportTo(fromPosition, true)
		player:say("You have to wait to challenge this enemy again!", TALKTYPE_MONSTER_SAY)
		return true
	end
	if roomIsOccupied(r.boss, false, 12, 18) then
		player:teleportTo(fromPosition, true)
		player:say("Someone is fighting against the boss! You need wait awhile.", TALKTYPE_MONSTER_SAY)
		return true
	end
	clearRoom(r.boss, 12, 18)
	local boss = Game.createMonster("Sugar Daddy", r.boss, true, true)
	if not boss then
		player:teleportTo(fromPosition, true)
		return true
	end
	SD.newSugarDaddy(boss)
	player:teleportTo(r.entry)
	r.entry:sendMagicEffect(CONST_ME_TELEPORT)
	player:setBossCooldown("Sugar Daddy", os.time() + r.cooldown)
	player:say("You have " .. r.minutes .. " minutes to kill and loot this boss, else you will lose that chance and will be kicked out.", TALKTYPE_MONSTER_SAY)
	addEvent(clearBossRoom, r.minutes * 60 * 1000, player:getId(), r.boss, false, 12, 18, r.back)
	return true
end

function SD.sugarDaddyKilled(monster)
	for cid, _ in pairs(monster:getDamageMap() or {}) do
		local p = Player(cid)
		if p and SD.get(p, S.Candis) == 1 then
			SD.set(p, S.Candis, 2)
			p:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The missing sugar cube workers rush out of the cave.") -- ours (EN: they run away as you exit)
		end
	end
end

-- ----------------------------------------------------------- Dulcineo and the Tooth Fairy
local dulcineo = {
	ask = {
		"Sweet greetings, dear visitor! Thank you for your help with the stolen sweets and the problems in the Chocolate Mine. The Candy Carnival is now open again. Everyone is enjoying the festivities and attractions. ...",
		"However, I have to admit that I can't celebrate quite so carefree. Something is weighing on my mind. You should know that my lady, the Sugar Plum Fairy, has been falling out with her sister for a while now. ...",
		"Her sister is the Tooth Fairy and she is anything but happy about the sweets we make for the Tibian children. She says it's bad for their teeth and, between you and me, I think her concern is not entirely unjustified. ...",
		"Unfortunately, my sweet lady won't hear of it. But I know for a fact that the discord with her sister is weighing on her too. Perhaps I could ask you to do something for me - and therefore for the two sisters. ...",
		"Go and see the Tooth Fairy. She lives in Feyrist at the court of Queen Maelyrra. Perhaps there is something you can do to help her. ...",
		"If you tell her that you've come on my behalf - and therefore indirectly on behalf of the Sugar Plum Fairy - that might smooth things over a bit and even be the starting point for some kind of reconciliation talk.",
	},
	hint = "Go and see the Tooth Fairy. She lives in Feyrist at the court of Queen Maelyrra. Perhaps there is something you can do to help her.", -- BR fragment
	done = "Thank you, my friend, for taking on this diplomatically tricky mission. I have a feeling that the disagreements between my lady and her sister may now be resolved. Candia is in your debt.",
}

-- Dulcineo speaks his request as his greeting (BR: "Hi").
function SD.dulcineoGreeting(player)
	local main = SD.main(player)
	if main == 9 then
		SD.set(player, S.Main, 10)
		return table.concat(dulcineo.ask, " ")
	elseif main == 10 or main == 11 then
		return dulcineo.hint
	elseif main == 12 then
		SD.set(player, S.Main, 13)
		return dulcineo.done
	elseif main >= 13 then
		return "Sweet greetings, dear visitor! Candia is in your debt." -- ours
	end
	return SD.npcs["Dulcineo"].greet
end

SD.handlers["Dulcineo"] = function(npc, player, message, npcHandler)
	if MsgContains(message, "mission") then
		local main = SD.main(player)
		if main == 12 then
			SD.set(player, S.Main, 13)
			return say(npcHandler, npc, player, dulcineo.done)
		elseif main == 10 or main == 11 then
			return say(npcHandler, npc, player, dulcineo.hint)
		elseif main >= 13 then
			return say(npcHandler, npc, player, "Candia is in your debt.") -- BR fragment
		end
	end
	return false
end

local toothFairy = {
	ask = {
		"Ah, I know you. We have met in the outside world. Dulcineo sent you? Really? Hm, maybe my sister will see sense after all. Well, there's actually something you could do. All those sweets ... It's just not good for the baby teeth. ...",
		"And just think, some of the kids don't even own a toothbrush! That has to change! Could you go and put a toothbrush on the beds of the three children I'm talking about? ...",
		"I mean the children of Quero from Thais, Rowenna from Carlin and Allen from Venore. Please put one of these three toothbrushes under each of their pillows. Here you go.",
	},
	waiting = "Please put one of these three toothbrushes under each of their pillows: the children of Quero from Thais, Rowenna from Carlin and Allen from Venore.", -- BR fragment
	lost = "You lost a toothbrush? Here, take another one.", -- ours
	done = {
		"It's good that you brought the toothbrushes to those poor children. Now I can sleep easier, safe in the knowledge that I will get nice, clean milk teeth. Let me give you something to say thank you. ...",
		"Here, the feather of a pegasus. These magical creatures are rarely seen, even here in Feyrist. When outsiders mingle with us, they always stay up in the clouds, where they hide from mortal eyes. ...",
		"But this feather is a sign that the fairy folk trust you. With it, you will be able to call a pegasus to you.",
	},
	after = "Thank you again. The children will have nice, clean teeth.", -- ours
	before = "Greetings, human being. I'm the tooth fairy.", -- ours
}

local CHILDREN = { "quero", "allen", "rowenna" }
local function brushesPlaced(player)
	local n = 0
	for _, c in ipairs(CHILDREN) do
		n = n + (SD.get(player, S.Toothbrush[c]) >= 1 and 1 or 0)
	end
	return n
end

SD.handlers["Tooth Fairy (Candia)"] = function(npc, player, message, npcHandler)
	if not MsgContains(message, "mission") then
		return false
	end
	local main = SD.main(player)
	if main == 10 then
		SD.set(player, S.Main, 11)
		player:addItem(SD.TOOTHBRUSH, 3)
		return say(npcHandler, npc, player, toothFairy.ask)
	elseif main == 11 then
		local placed = brushesPlaced(player)
		if placed >= 3 then
			player:addItem(SD.PEGASUS_FEATHER, 1)
			SD.set(player, S.Main, 12)
			return say(npcHandler, npc, player, toothFairy.done)
		end
		local missing = 3 - placed - player:getItemCount(SD.TOOTHBRUSH)
		if missing > 0 then
			player:addItem(SD.TOOTHBRUSH, missing)
			return say(npcHandler, npc, player, toothFairy.lost)
		end
		return say(npcHandler, npc, player, toothFairy.waiting)
	elseif main >= 12 then
		return say(npcHandler, npc, player, toothFairy.after)
	end
	return say(npcHandler, npc, player, toothFairy.before)
end

SD.TOOTHBRUSH_TEXT = {
	quero = "You are placing the toothbrush for Quero's daughter on the pillow.",
	allen = "You are placing the toothbrush for Allen's son on the pillow.", -- ours (BR: "Allen's daughter"; Allen has a son, EN)
	rowenna = "You are placing the toothbrush for Rowenna's daughter on the pillow.",
}

-- A toothbrush on a child's bed (the beds of The Fairy Treasure: FamilyThreatenedDreams.CHILDREN).
function SD.useToothbrush(player, item, toPosition)
	if not SD.enabled() or SD.main(player) ~= 11 or not FamilyThreatenedDreams then
		return false
	end
	for child, room in pairs(FamilyThreatenedDreams.CHILDREN) do
		for _, pos in ipairs(room.bed) do
			if pos == toPosition then
				if SD.get(player, S.Toothbrush[child]) >= 1 then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There already is a toothbrush under this pillow.") -- ours
					return true
				end
				item:remove(1)
				SD.set(player, S.Toothbrush[child], 1)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, SD.TOOTHBRUSH_TEXT[child])
				return true
			end
		end
	end
	return false
end

function SD.usePegasusFeather(player, item)
	if not SD.enabled() then
		return false
	end
	if player:hasMount(SD.PEGASUS_MOUNT) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already can call a pegasus.") -- ours
		return true
	end
	player:addMount(SD.PEGASUS_MOUNT)
	addAchievement(player, "I Wanna Fly Away")
	item:remove(1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You can now call a pegasus.") -- ours
	return true
end

-- ----------------------------------------------------------- A Taffy Bunny
SD.BUNNY_FOUND = {
	"*You spot a pink taffy bunny hopping around between the hot milk springs. Strange, it doesn't seem to belong here. Could this be the bunny Cherry that the Sugar Plum Fairy is looking for?* ...",
	"But when you try to catch the runaway, you quickly realise that she is much too fast for you to catch her. Apparently, all you can do for now is tell Sugar the Plum Fairy where her pet is.",
} -- BR

function SD.bunnyGreeting(player)
	if SD.get(player, S.Bunny) == 1 then
		SD.set(player, S.Bunny, 2)
		return table.concat(SD.BUNNY_FOUND, " ")
	end
	return SD.npcs["A Taffy Bunny"].greet
end

SD.TUFT = "You discover a tuft of spun pink sugar on the floor. Could the missing taffy bunny Cherry be down here?" -- EN

function SD.dungeonStep(player)
	if SD.enabled() and SD.get(player, S.Bunny) == 1 and not SD.kvGet(player, "tuft") then
		SD.kvSet(player, "tuft", true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, SD.TUFT)
	end
end

-- ----------------------------------------------------------- Sugar Daddy's sugar rush (added 2026-11-22)
-- EN (Sugar Daddy): at about 3/4, 1/2 and 1/4 health he spawns 5 summons; meanwhile you are Powerless
-- (no attack spells or runes); if they are not all dead within 15 seconds you are Hexed for 1 minute and he
-- heals some life. The summons are the Cheeky Sugar Cube, the Mint Drop and the Truffle Worker (EN), one kind
-- per phase in the order of his three yells (order ours). Lesser Hex (EN's plain "Hexed" icon), the heal of
-- 1,600 (EN: his healing goes up to 1,600) and every message are ours.
SD.SUGAR_RUSH = {
	phases = {
		{ at = 0.75, monster = "Cheeky Sugar Cube", yell = "SUGAR!!!" },
		{ at = 0.50, monster = "Mint Drop", yell = "YOU HAVE BAD BREATH, TAKE A MINT!!!" },
		{ at = 0.25, monster = "Truffle Worker", yell = "I LOOOOOOVE CHOCOLATE TRUFFLES!!!" },
	},
	count = 5,
	seconds = 15,
	hexSeconds = 60,
	heal = 1600,
	start = "Sugar Daddy calls his sweet little helpers! Defeat them quickly!", -- ours
	failed = "Too slow! Sugar Daddy gets a sugar rush and you are hexed.", -- ours
	done = "You defeated Sugar Daddy's helpers.", -- ours
}
SD.rush = SD.rush or {} -- boss id -> { done = phases started, active = phase running, minions = { id = true } }
SD.minionBoss = SD.minionBoss or {} -- minion id -> boss id
SD.spoonHeal = SD.spoonHeal or {} -- player guid -> true: may use a spoon on Sugar Daddy's body once

function SD.inSugarDaddyRoom(pos)
	local r = SD.SUGAR_DADDY
	return pos.z == r.from.z and pos.x >= r.from.x and pos.x <= r.to.x and pos.y >= r.from.y and pos.y <= r.to.y
end

function SD.sugarDaddyPlayers()
	local list = {}
	for _, p in ipairs(Game.getPlayers()) do
		if SD.inSugarDaddyRoom(p:getPosition()) then
			list[#list + 1] = p
		end
	end
	return list
end

function SD.newSugarDaddy(boss)
	SD.rush[boss:getId()] = { done = 0, active = false, minions = {} }
	boss:registerEvent("FamilySugarDaddyRush")
end

local function powerless(seconds)
	local c = Condition(CONDITION_POWERLESS)
	c:setParameter(CONDITION_PARAM_TICKS, seconds * 1000)
	return c
end
local function lesserHex(seconds)
	local c = Condition(CONDITION_LESSERHEX)
	c:setParameter(CONDITION_PARAM_BUFF_HEALINGRECEIVED, 50)
	c:setParameter(CONDITION_PARAM_TICKS, seconds * 1000)
	return c
end

-- onHealthChange of Sugar Daddy: start the next phase when his health falls to its mark.
function SD.sugarRushCheck(boss, damage)
	local st = SD.rush[boss:getId()]
	if not st or st.active or damage <= 0 then
		return
	end
	local n = st.done + 1
	local phase = SD.SUGAR_RUSH.phases[n]
	if phase and boss:getHealth() - damage <= boss:getMaxHealth() * phase.at and boss:getHealth() - damage > 0 then
		SD.startSugarRush(boss, n)
	end
end

function SD.startSugarRush(boss, n)
	local R = SD.SUGAR_RUSH
	local st = SD.rush[boss:getId()]
	local phase = R.phases[n]
	st.done, st.active, st.minions = n, true, {}
	boss:say(phase.yell, TALKTYPE_MONSTER_YELL)
	local pos = boss:getPosition()
	for _ = 1, R.count do
		local m = Game.createMonster(phase.monster, pos, true, true)
		if m then
			st.minions[m:getId()] = true
			SD.minionBoss[m:getId()] = boss:getId()
			m:registerEvent("FamilySugarDaddyMinion")
		end
	end
	for _, p in ipairs(SD.sugarDaddyPlayers()) do
		p:addCondition(powerless(R.seconds))
		p:sendTextMessage(MESSAGE_EVENT_ADVANCE, R.start)
	end
	addEvent(SD.endSugarRush, R.seconds * 1000, boss:getId(), n)
end

-- After 15 seconds, or when the last helper dies.
function SD.endSugarRush(bossId, n)
	local R = SD.SUGAR_RUSH
	local st = SD.rush[bossId]
	if not st or not st.active or st.done ~= n then
		return
	end
	st.active = false
	local left = 0
	for id in pairs(st.minions) do
		local m = Creature(id)
		if m then
			left = left + 1
			m:getPosition():sendMagicEffect(CONST_ME_POFF)
			m:remove()
		end
		SD.minionBoss[id] = nil
	end
	st.minions = {}
	local boss = Creature(bossId)
	for _, p in ipairs(SD.sugarDaddyPlayers()) do
		p:removeCondition(CONDITION_POWERLESS)
		if left > 0 then
			p:addCondition(lesserHex(R.hexSeconds))
			p:sendTextMessage(MESSAGE_EVENT_ADVANCE, R.failed)
		else
			p:sendTextMessage(MESSAGE_EVENT_ADVANCE, R.done)
		end
	end
	if left > 0 and boss then
		boss:addHealth(R.heal)
		boss:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	end
end

function SD.minionDied(creature)
	local bossId = SD.minionBoss[creature:getId()]
	SD.minionBoss[creature:getId()] = nil
	local st = bossId and SD.rush[bossId]
	if not st or not st.active then
		return
	end
	st.minions[creature:getId()] = nil
	if next(st.minions) == nil then
		SD.endSugarRush(bossId, st.done)
	end
end

-- Sugar Daddy died: his helpers go, Powerless ends; each fighter may use a spoon on his body once (EN).
function SD.sugarDaddyGone(monster)
	local st = SD.rush[monster:getId()]
	SD.rush[monster:getId()] = nil
	if st then
		for id in pairs(st.minions) do
			local m = Creature(id)
			if m then
				m:remove()
			end
			SD.minionBoss[id] = nil
		end
	end
	for _, p in ipairs(SD.sugarDaddyPlayers()) do
		p:removeCondition(CONDITION_POWERLESS)
	end
	for cid, _ in pairs(monster:getDamageMap() or {}) do
		local p = Player(cid)
		if p then
			SD.spoonHeal[p:getGuid()] = true
		end
	end
end

SD.SUGAR_DADDY_CORPSE = 48416
-- A spoon (or tool gear) on Sugar Daddy's body: full health and mana (EN). Called by onUseSpoon.
function SD.spoonCorpse(player, target, toPosition)
	if not SD.enabled() or not target or not target.getId or target:getId() ~= SD.SUGAR_DADDY_CORPSE then
		return false
	end
	if not SD.spoonHeal[player:getGuid()] then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is nothing left to scrape off.") -- ours
		return true
	end
	SD.spoonHeal[player:getGuid()] = nil
	player:addHealth(player:getMaxHealth())
	player:addMana(player:getMaxMana())
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You scrape some sugar off Sugar Daddy. You feel completely refreshed.") -- ours
	return true
end

-- ----------------------------------------------------------- Coco (added 2026-11-22)
-- Two shops, one per coin (BR Coco: keyword "Milk Chocolate Coin" / "Dark Chocolate Coin", items and prices).
-- An NPC has one currency in our engine, so Coco switches it when a list is opened and checks it again
-- before each purchase (SD.cocoBuy).
SD.COCO = {
	milk = {
		coin = 48249,
		word = "milk chocolate coins",
		items = {
			{ itemName = "candy bed (headboard)", clientId = 48449, buy = 1500 }, -- which part is which: ours
			{ itemName = "candy bed (footboard)", clientId = 48450, buy = 1500 },
			{ itemName = "candy cone chair", clientId = 48427, buy = 1500 },
			{ itemName = "candy cushion", clientId = 48433, buy = 1500 },
			{ itemName = "candy-coated quiver", clientId = 45644, buy = 8000 },
			{ itemName = "candy necklace", clientId = 45641, buy = 5000 },
			{ itemName = "chocolate table", clientId = 48430, buy = 1500 },
			{ itemName = "creamy grimoire", clientId = 45640, buy = 8000 },
			{ itemName = "small gingerbread house", clientId = 49166, buy = 3000 },
		},
	},
	dark = {
		coin = 48250,
		word = "dark chocolate coins",
		items = {
			{ itemName = "biscuit barrier", clientId = 45643, buy = 8000 },
			{ itemName = "blue ice cream lamp", clientId = 48435, buy = 1125 },
			{ itemName = "chocolate fountain", clientId = 48432, buy = 1500 },
			{ itemName = "cocoa grimoire", clientId = 45639, buy = 8000 },
			{ itemName = "green ice cream lamp", clientId = 48439, buy = 1125 },
			{ itemName = "pink ice cream lamp", clientId = 48437, buy = 1125 },
			{ itemName = "pop tart painting", clientId = 48434, buy = 1500 },
			{ itemName = "ring of temptation", clientId = 45642, buy = 250 },
		},
	},
	trade = "I sell furniture and sweet gear. I take {milk chocolate coins} and {dark chocolate coins}. Which do you want to pay with?", -- ours
	opened = "Here are my offers for %s.", -- ours
}
SD.cocoShop = SD.cocoShop or {} -- player id -> "milk" or "dark"

function SD.cocoOpen(npc, player, kind, npcHandler)
	local shop = SD.COCO[kind]
	SD.cocoShop[player:getId()] = kind
	npc:setCurrency(shop.coin)
	npc:openShopWindowTable(player, shop.items)
	return say(npcHandler, npc, player, string.format(SD.COCO.opened, shop.word))
end

function SD.cocoBuy(npc, player, itemId, subType, amount, ignore, inBackpacks)
	local shop = SD.COCO[SD.cocoShop[player:getId()] or ""]
	if not shop then
		return
	end
	local price
	for _, it in ipairs(shop.items) do
		if it.clientId == itemId then
			price = it.buy
		end
	end
	if not price then
		return
	end
	if npc:getCurrency() ~= shop.coin then
		npc:setCurrency(shop.coin) -- the other player opened the other list meanwhile
	end
	if player:getItemCount(shop.coin) < price * amount then
		player:sendTextMessage(MESSAGE_TRADE, "You do not have enough " .. shop.word .. ".") -- ours
		return
	end
	npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end

SD.handlers["Coco"] = function(npc, player, message, npcHandler)
	local kind = (MsgContains(message, "milk") and "milk") or (MsgContains(message, "dark") and "dark") or nil
	if not kind then
		return false
	end
	if SD.main(player) < 9 then
		return say(npcHandler, npc, player, "Sorry, the Candy Carnival isn't open yet. There is trouble in the Chocolate Mines.") -- ours, as Toffee
	end
	return SD.cocoOpen(npc, player, kind, npcHandler)
end

-- ----------------------------------------------------------- Sand toys (added 2026-11-22)
-- BR Threatened Dreams Quest, Sand Toys (not in the quest log): marzipan carrots grow around Candia (one
-- every 30 seconds); feed 15 or more into the trough and the taffy bunny on the surface tells you about a
-- treasure; dig it up with a shovel on the northern headland: sand toys. Used on the sand of a town they
-- build a sand castle (1 hour), on Candia's vanilla sand a vanilla sugar castle (3 hours).
SD.CARROT_PLANT = { [48581] = 48586, [48580] = 48582 } -- plant -> what you pull (our map; single and handful)
SD.CARROT_TEXT = {
	[48586] = "You are pulling a marzipan carrot out of the pastry soil.", -- BR
	[48582] = "You are pulling some marzipan carrots out of the pastry soil.", -- BR
}
SD.CARROT_SECONDS = 30 -- BR, EN
SD.carrotTimes = SD.carrotTimes or {} -- "x,y,z" -> os.time() of the last pull
SD.TROUGH = Position(33425, 32151, 7) -- BR 33426,32151: our trough is one square west
SD.TROUGH_ID = 48583
SD.CARROTS_NEEDED = 15 -- BR "a partir de 15"; a handful counts as one (ours)
SD.TREASURE = { Position(33388, 32099, 7), Position(33389, 32099, 7) } -- BR 33389,32099; 33388 is the odd sand square there
SD.SAND_TOYS = 49156
SD.CASTLE = {
	-- ids: the two unnamed client objects next to the sand toys (49154, 49155: 64x64 pictures of update 13.40);
	-- 49155 stands around the treasure spot on Candia's beach, so it is the vanilla sugar castle (ours, not on a wiki)
	sand = { id = 49154, name = "sand castle", cooldown = 3600, text = "You are building a sand castle." }, -- BR
	vanilla = { id = 49155, name = "vanilla sugar castle", cooldown = 3 * 3600, text = "You are building a vanilla sugar castle." }, -- BR
	lifetime = 3600, -- ours: a castle outside a house crumbles after an hour
}
SD.VANILLA_SAND = { [45316] = true, [49101] = true } -- Candia's beach (our map)

local function posKey(pos)
	return pos.x .. "," .. pos.y .. "," .. pos.z
end

function SD.pullCarrot(player, item)
	local gives = SD.CARROT_PLANT[item:getId()]
	if not SD.enabled() or not gives then
		return false
	end
	local pos = item:getPosition()
	local key = posKey(pos)
	if os.time() - (SD.carrotTimes[key] or 0) < SD.CARROT_SECONDS then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "These marzipan carrots have not grown back yet.") -- ours
		return true
	end
	if not player:addItem(gives, 1) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cannot carry that.") -- ours
		return true
	end
	SD.carrotTimes[key] = os.time()
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, SD.CARROT_TEXT[gives])
	pos:sendMagicEffect(CONST_ME_POFF)
	return true
end

function SD.feedTrough(player, item, target, toPosition)
	if not SD.enabled() or not target or type(target) ~= "userdata" or not target.getId or target:getId() ~= SD.TROUGH_ID then
		return false
	end
	local fed = (SD.kvGet(player, "carrots") or 0) + 1
	SD.kvSet(player, "carrots", fed)
	item:remove(1)
	toPosition:sendMagicEffect(CONST_ME_HEARTS)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You put the marzipan carrots into the trough. Somewhere nearby, a bunny sniffs eagerly.") -- ours
	return true
end

SD.BUNNY_TIP = {
	"*Surprisingly, this time the bunny doesn't just sniff, but talks to you.* You brought me a LOT of marzipan carrots, friend. Really nice of you. ...",
	"Let me tell you a little secret in return: I know where a treasure is hidden. If you dig around the northern headlands of the island, you'll find it. Right up north, right by the water, yes.",
} -- BR
function SD.surfaceBunnyGreeting(player)
	if (SD.kvGet(player, "carrots") or 0) >= SD.CARROTS_NEEDED then
		SD.kvSet(player, "treasure-tip", true)
		return table.concat(SD.BUNNY_TIP, " ")
	end
	return SD.npcs["A Taffy Bunny"].greet
end

-- Called by onUseShovel.
function SD.digTreasure(player, toPosition)
	if not SD.enabled() then
		return false
	end
	local here = false
	for _, pos in ipairs(SD.TREASURE) do
		if toPosition.x == pos.x and toPosition.y == pos.y and toPosition.z == pos.z then
			here = true
		end
	end
	if not here or not SD.kvGet(player, "treasure-tip") then
		return false
	end
	if SD.kvGet(player, "sand-toys") then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You dig, but there is nothing else hidden here.") -- ours
		toPosition:sendMagicEffect(CONST_ME_POFF)
		return true
	end
	if not player:addItem(SD.SAND_TOYS, 1) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cannot carry that.") -- ours
		return true
	end
	SD.kvSet(player, "sand-toys", true)
	toPosition:sendMagicEffect(CONST_ME_POFF)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are digging up a set of sand toys. Perhaps you could build a sand castle with them. Or a vanilla sugar castle.") -- BR
	return true
end

function SD.castleKind(tile)
	local ground = tile and tile:getGround()
	if not ground then
		return nil
	end
	if SD.VANILLA_SAND[ground:getId()] then
		return "vanilla"
	end
	if ItemType(ground:getId()):getName() == "sand" then
		return "sand"
	end
	return nil
end

function SD.useSandToys(player, item, toPosition)
	if not SD.enabled() then
		return false
	end
	local tile = Tile(toPosition)
	local kind = SD.castleKind(tile)
	if not kind then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need sand to build a castle.") -- ours
		return true
	end
	if tile:getTopCreature() or tile:getTopDownItem() or tile:hasFlag(TILESTATE_BLOCKSOLID) then
		player:sendCancelMessage(RETURNVALUE_NOTENOUGHROOM)
		return true
	end
	local castle = SD.CASTLE[kind]
	local key = kind .. "-castle"
	local waitUntil = (SD.kvGet(player, key) or 0) + castle.cooldown
	if os.time() < waitUntil then
		local minutes = math.ceil((waitUntil - os.time()) / 60)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You can build your next %s in %d minute%s.", castle.name, minutes, minutes == 1 and "" or "s")) -- ours
		return true
	end
	local built = Game.createItem(castle.id, 1, toPosition)
	if not built then
		return true
	end
	SD.kvSet(player, key, os.time())
	toPosition:sendMagicEffect(CONST_ME_POFF)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, castle.text)
	if not tile:getHouse() then
		local pos = Position(toPosition.x, toPosition.y, toPosition.z)
		addEvent(function()
			local t = Tile(pos)
			local c = t and t:getItemById(castle.id)
			if c then
				c:remove()
				pos:sendMagicEffect(CONST_ME_POFF)
			end
		end, SD.CASTLE.lifetime * 1000)
	end
	return true
end

-- ----------------------------------------------------------- the four real-life recipes (added 2026-11-22)
-- Decorations, one of each per character, only after the whole of Sweet Dreams (EN item pages). Places: EN
-- item pages, matched with our map. BR's quest page swaps the matcha turtle (BR: the bottle) and the rainbow
-- waffles (BR: Sugar Daddy's room); we follow EN's item pages, the more specific source.
SD.RECIPES = {
	{ key = "matcha", id = 48481, name = "matcha turtle recipe", pos = Position(33362, 32222, 9) }, -- EN 33364,32223,9: chest in Sugar Daddy's room
	{ key = "rose", id = 48480, name = "rose milk cake recipe", pos = Position(33453, 32131, 9) }, -- EN 33454,32132,9 (BR 33454,32131): chest
	{ key = "nightsky", id = 48482, name = "nightsky cupcake recipe", pos = Position(33410, 32124, 5) }, -- EN 33412,32126,5: ice cream snowman
	{ key = "waffles", id = 48483, name = "rainbow waffles recipe", pos = Position(33357, 32122, 7) }, -- EN 33359,32123,7 (BR 33358,32123): bottle
}

function SD.takeRecipe(player, index)
	local r = SD.RECIPES[index]
	if not SD.enabled() or not r or SD.main(player) < 13 or SD.kvGet(player, "recipe-" .. r.key) then
		return false -- opens as usual (empty)
	end
	if not player:addItem(r.id, 1) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cannot carry that.") -- ours
		return true
	end
	SD.kvSet(player, "recipe-" .. r.key, true)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a " .. r.name .. ".")
	return true
end

-- ----------------------------------------------------------- roleplay NPCs (added 2026-11-22)
-- BR NPC pages: A Floating Sugar Ball and A Stressed Sugar Cube Worker (greeting and sounds). Jelly has no
-- line on either wiki: hers are ours.
SD.npcs["Coco"] = { greet = "Sweet greetings! Candy furniture and sweet gear for your chocolate coins!", farewell = "Sweet greetings!" } -- ours
SD.gestures["Coco"] = "*The little fae greets you but you don't understand her. She makes a gesture as if to apply some lipstick. Then she is pointing to the east. But what does that mean?*" -- ours, as Toffee's (BR)
SD.npcs["Jelly"] = { greet = "*The tiny fairy giggles, flutters once around your head and hums a sweet little tune.*", farewell = "*The tiny fairy waves at you.*" } -- ours
SD.npcs["A Floating Sugar Ball"] = { greet = "*This floating ball appears to be made of glowing red sugar. It moves gently up and down and emits a soft humming sound.*", farewell = "*hummmm*" } -- BR (farewell: its BR sound)
SD.npcs["A Stressed Sugar Cube Worker"] = { greet = "*The sugar cube worker does not give the impression of understanding you. And it seems to be rather busy.*", farewell = "This has to work ... somehow." } -- BR (farewell: its BR sound)
SD.npcs["A Taffy Bunny (Surface)"] = SD.npcs["A Taffy Bunny"]

-- ----------------------------------------------------------- quest log (texts ours)
SD.LOG = {
	[1] = "Maelyrra told you that the donut gate in Feyrist leads to Candia, but you need a gingerbread key. A forest fury stole the recipe and was last seen somewhere in Vandura.",
	[2] = "You found the forest fury caged in the Corym Black Market. Find the key to her cage and a mirror image spell, then free her while you are invisible.",
	[3] = "You freed the forest fury. Lead her out of the Corym Black Market without being seen.",
	[4] = "The forest fury gave you the gingerbread key recipe. Bake the key in the oven in Feyrist and glaze it with moon melon, raspberry and lemon sirup.",
	[5] = "The gingerbread key opened the donut gate to Candia. The candy fae there gesture as if to apply some lipstick.",
	[6] = "Kroazur stole four sweets of the Sugar Plum Fairy: a matcha turtle, a nightsky cupcake, a rose milk cake and rainbow waffles. Bring them back.",
	[7] = "The Sugar Plum Fairy asked you to check the Chocolate Mines. Candis there needs help.",
	[8] = "The Chocolate Mines are safe again. Report to the Sugar Plum Fairy.",
	[9] = "The Candy Carnival is open. Dulcineo seems to be worried about something.",
	[10] = "Dulcineo asked you to visit the Tooth Fairy in Feyrist on his behalf.",
	[11] = "The Tooth Fairy asked you to put a toothbrush under the pillows of Quero's, Allen's and Rowenna's children.",
	[12] = "The Tooth Fairy gave you a pegasus feather. Tell Dulcineo.",
	[13] = "You helped the Sugar Plum Fairy and her sister to make peace. Candia is in your debt.",
}
SD.CANDIS_LOG = {
	[1] = " Some of Candis' workers disappeared near the portal in the lower levels of the mines.",
	[2] = " You defeated Sugar Daddy. Tell Candis.",
	[3] = " Reinforce the three cordoned-off walls of the mines with the candy cane beams from the chest north of Candis.",
	[4] = "",
	[5] = " Catch five honey elementals in the honey glasses Candis gave you.",
}
function SD.mainLog(player)
	local main = SD.main(player)
	local text = SD.LOG[main] or ""
	if main == 6 then
		local left = {}
		for _, s in ipairs(SD.SWEETS) do
			if SD.get(player, S.Sweets[s.key]) < 1 then
				left[#left + 1] = s.word
			end
		end
		text = text .. " Still missing: " .. table.concat(left, ", ") .. "."
	elseif main == 7 then
		text = text .. (SD.CANDIS_LOG[SD.get(player, S.Candis)] or "")
	end
	return text
end
SD.BUNNY_LOG = {
	[1] = "The Sugar Plum Fairy's taffy bunny Cherry ran away. She loves underground tunnels and caves.",
	[2] = "You found Cherry at the Hot Milk Springs in the Dessert Dungeons, but she was too fast to catch. Tell the Sugar Plum Fairy.",
	[3] = "The Sugar Plum Fairy knows now where Cherry is.",
}
