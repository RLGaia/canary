-- Gaia Family server: The Dream Courts Quest review (2026-11-23, asked by Rodrigo: "check if everything
-- is working, including related items and dialogs").
--
-- Sources: TibiaWiki BR "The Dream Courts Quest" and the NPC/item pages (our backup), TibiaWiki EN
-- "The Dream Courts Quest/Spoiler", the NPC transcripts (Myzzi, Vanys, Undal, Andrew Lyze, Stricken
-- Soul), "Dream Warrior Outfits Quest/Spoiler" and the item pages. Lines marked "ours" are on
-- neither wiki.
--
-- What changed against upstream (details in FAMILY.md):
--   NPCs: Myzzi answers her words in any order (EN: "entrances", "yes"), "no" (BR) and her later
--   greeting (EN/BR); Vanys and Undal answer "task" straight away, tell the long story (EN, six parts
--   with "continue"), "keys", "lost" (EN: a new talisman), and either court reports the quest (EN);
--   the reward gives the Dream Catcher achievement; the addons follow both wikis (pomegranates = first,
--   ice shield = second, Dream Warrior with both). Andrew Lyze: lore words in any order, the repair
--   really asks for every material, the golden axe comes with the bait (10 minutes, again for 5,000 gold:
--   EN), "unleash", the report with 50,000 experience (BR), "charge" blue/green/violet for 20,000/
--   50,000/100,000 gold and a crystal (EN, BR). Stricken Soul's name, job, scholar, bye and the
--   "not your name" line (BR, EN). The arena elves take champions of either court (EN, BR), tell the
--   boss of the day (ours: our map has no notice board) and count the Champion of Summer/Winter wins.
--   World: the magic portal next to Andrew and the chest room behind it (our custom map
--   world/custom/family-dream-courts.otbm: our map has neither room nor chest), the leaking ectoplasm
--   buckets, the three sarcophagus outcomes (EN), the temple vines (half of the maximum health, EN),
--   the last ward stone used by hand after the Faceless Bane (EN, BR), the Medusa's Ointment on the
--   stone door, the old lock with a crowbar or a tool (EN), the painting portal, the sun fruit bushes
--   (2 fruits, EN/BR), the crystal columns (every colour from every column, EN/BR), one boss of the day
--   for the arena map, the lever and the teleport (wiki order), the Faceless Bane rounds and the
--   Nightmare Beast's curse with the dream catcher pole (EN, BR).
--
-- Player storages: Storage.Quest.U12_00.TheDreamCourts (the update's block, 46301-46600; ours from 46369).
-- World objects: scripts/family/dream_courts.lua. Quest log: catalog/050_the_dream_courts.lua.
-- Switch: Family.dreamCourts (false = upstream behaviour).

Family = Family or {}
Family.dreamCourts = true

FamilyDreamCourts = FamilyDreamCourts or {}
local D = FamilyDreamCourts
local DC = Storage.Quest.U12_00.TheDreamCourts
D.DC = DC

function D.enabled()
	return Family.dreamCourts == true
end

-- Our storages (free part of the U12_00 block).
D.S = {
	BaitUntil = 46369, -- Lucifuga bait active until (os.time)
	ChestColour = 46370, -- colour of the charge that brought the player into the chest room (1 blue, 2 green, 3 violet)
	ChestBlue = 46371, -- next time the blue chest gives something
	ChestGreen = 46372,
	ChestViolet = 46373,
	ArenaSide = 46374, -- 1 Summer Court, 2 Winter Court
	SummerWins = 46375,
	WinterWins = 46376,
	SarcophagusTime = 46377, -- next time this player may open a sarcophagus
	MaskTime = 46378, -- next time this player may use a dream catcher on someone
}

-- Items
D.TALISMAN = 30132
D.BROKEN_COMPASS = 25746
D.CHARGEABLE_COMPASS = 29291
D.COMPASS = { [1] = 29292, [2] = 29293, [3] = 29294 } -- charged blue, green, violet
D.GOLDEN_AXE = 29286
D.CRYSTAL = { [1] = 29287, [2] = 29288, [3] = 29289 } -- blue, green, violet crystal
D.POISON_GLAND = 29348
D.GLASS = { blue = 29345, green = 29346, violet = 29347 }
D.POMEGRANATE = 30169
D.ICE_SHIELD = 30168
D.OINTMENT = 21506
D.OLD_LOCK = 29992
D.NAIL = 953
D.SUN_FRUIT = 29995
D.DREAM_CATCHER = 29276
D.POLE, D.POLE_USED = 29274, 29275
D.OUTFITS = { 1146, 1147 }

D.COLOUR_NAME = { [1] = "blue", [2] = "green", [3] = "violet" }
D.CHARGE_FEE = { [1] = 20000, [2] = 50000, [3] = 100000 } -- EN, BR
D.CHEST_TIME = 20 * 60 * 60 -- EN: once every 20 hours per charge colour
D.BAIT_TIME = 10 * 60 -- EN, BR: about 10 minutes
D.BAIT_FEE = 5000 -- EN

-- Ward stones
D.STONE_SUMMER, D.STONE_SUMMER_LIT = 29334, 29335
D.STONE_WINTER, D.STONE_WINTER_LIT = 29336, 29337
D.PORT_HOPE_STONE = Position(32769, 32621, 10)
D.CATHEDRAL_STONE = Position(33576, 32537, 15)
D.MSG_SUMMER = "You charge the summer ward stone and the engraved sun glows in a golden light." -- EN
D.MSG_WINTER = "You charge the winter ward stone and the engraved ice crystal glows in a blue light." -- EN

-- Andrew Lyze's magic portal and our chest room (world/custom/family-dream-courts.otbm)
D.MAGIC_PORTAL = Position(32760, 32627, 7)
D.PORTAL_EXIT = Position(32761, 32627, 7)
D.ROOM = {
	from = Position(32642, 32740, 11),
	to = Position(32646, 32744, 11),
	arrive = Position(32644, 32742, 11),
	chest = Position(32644, 32740, 11),
	field = Position(32644, 32744, 11),
}
D.ROOM_CHEST = 23740 -- brass-shod chest (EN: Andrew Lyze's chest)
D.ROOM_FIELD = 1949 -- magic forcefield (BR: blue forcefield back to the NPC)
D.ROOM_FIELD_AID = 48787 -- ours (action id; 48781-48786 are the Forbidden Islands hub portals)

-- Old table in the Dream Labyrinth with the old lock (upstream positions)
D.OLD_TABLE = { Position(32005, 32002, 14), Position(32005, 32003, 14), Position(32006, 32002, 14), Position(32006, 32003, 14) }
D.STONE_DOOR = Position(31983, 31960, 14)

-- Nightmare Beast's room
D.BEAST_ROOM = { from = Position(32195, 32035, 15), to = Position(32220, 32055, 15) }
D.BEAST_EXIT = Position(32213, 32083, 15)
D.POLE_POS = Position(32206, 32045, 15) -- ours: the middle of the room (our map has no pole)

-- Faceless Bane's room
D.FACELESS_ROOM = { from = Position(33607, 32553, 13), to = Position(33627, 32570, 13) }

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
end

local function storage(player, key)
	return player:getStorageValue(key)
end

local function inRoom(pos, room)
	return pos.z == room.from.z and pos.x >= room.from.x and pos.x <= room.to.x and pos.y >= room.from.y and pos.y <= room.to.y
end
D.inRoom = inRoom

local function playersIn(room)
	local list = {}
	local cx = math.floor((room.from.x + room.to.x) / 2)
	local cy = math.floor((room.from.y + room.to.y) / 2)
	local rx = math.ceil((room.to.x - room.from.x) / 2) + 1
	local ry = math.ceil((room.to.y - room.from.y) / 2) + 1
	for _, c in ipairs(Game.getSpectators(Position(cx, cy, room.from.z), false, true, rx, rx, ry, ry)) do
		if c:isPlayer() and inRoom(c:getPosition(), room) then
			list[#list + 1] = c
		end
	end
	return list
end
D.playersIn = playersIn

-- ---------------------------------------------------------------- the boss of the day
-- Both wikis: the five arena champions always come in this order, a new one at every server save.
-- Our server stops every day at 06:00, so the day starts at 06:00 and the arena map, the lever and
-- the teleport all use the boss picked at startup (upstream had three different weekday tables).
-- The timers are the storages the boss deaths write (DreamScarGlobal; the BossLever keeps its own too).
D.ARENA_BOSSES = {
	{ name = "Plagueroot", map = "plagueroot", timer = DC.DreamScarGlobal.PlagueRootTimer },
	{ name = "Malofur Mangrinder", map = "malofur_mangrinder", timer = DC.DreamScarGlobal.MalofurTimer },
	{ name = "Maxxenius", map = "maxxenius", timer = DC.DreamScarGlobal.MaxxeniusTimer },
	{ name = "Alptramun", map = "alptramun", timer = DC.DreamScarGlobal.AlptramunTimer },
	{ name = "Izcandar the Banished", map = "izcandar_the_banished", timer = DC.DreamScarGlobal.IzcandarTimer },
}

function D.arenaDay(t)
	local d = os.date("*t", (t or os.time()) - 6 * 60 * 60)
	return math.floor(os.time({ year = d.year, month = d.month, day = d.day, hour = 12 }) / 86400)
end

function D.bossOfTheDay(t)
	if t == nil then
		return D.todayBoss or D.pickBossOfTheDay()
	end
	return D.ARENA_BOSSES[D.arenaDay(t) % #D.ARENA_BOSSES + 1]
end

function D.pickBossOfTheDay()
	D.todayBoss = D.ARENA_BOSSES[D.arenaDay() % #D.ARENA_BOSSES + 1]
	return D.todayBoss
end

-- The elven parchment from the chests of both courts (BR "Elven Parchment (Book)", the original English text).
D.ELVEN_PARCHMENT = 30146
D.ELVEN_PARCHMENT_TEXT = "There are seven Dream Doors in the Labyrinth of Summer's and Winter's Dreams: The Rose Door, the Invisible Door, the Stone Door, the Painted Door, the Ice Bird Door, the Skull Door and the Empty Door. For each door, a verse survived the long history of the dream elves:\n\"Reunite the lonely maiden with her sisters to open the Door of Roses.\"\n\"Only in a ghostly light the Invisible Door will come into view.\"\n\"Petrified for centuries, the Stone Door can be passed only with the help of its curse's blood.\"\n\"Turn surface into space, transform imagination into reality and you may pass the Painted Door.\"\n\"Only the scent of liquorice, raspberries, pepper and fish will open the Ice Bird Door.\"\n\"Three lonely misadventurers, long forgotten, waiting for what the Skull Door bodes. Beware: The first try will also be your last!\"\n\"The Empty Door obeys the logic of dreams: What seals another door might open this one.\""

-- ---------------------------------------------------------------- Myzzi
D.MYZZI_GREET_AFTER = "Hello adventurer. I'm so happy that you agreed to help!" -- EN, BR

function D.myzziSay(npcHandler, npc, creature, message)
	local player = Player(creature)
	local pid = player:getId()
	local started = storage(player, DC.Main.Questline) >= 1
	if npcHandler:getTopic(pid) == 6 and not started then
		if MsgContains(message, "yes") then
			say(npcHandler, npc, creature, "You are a true hero! Here, take my enchantment and you will be able to pass the portals. Now hurry, my friends are waiting.")
			player:setStorageValue(DC.Main.Questline, 1)
			npcHandler:setTopic(pid, 0)
			return true
		elseif MsgContains(message, "no") then
			say(npcHandler, npc, creature, "Oh no, oh no! What a pity! Please reconsider!") -- BR
			npcHandler:setTopic(pid, 0)
			return true
		end
	end
	if MsgContains(message, "good") then
		say(npcHandler, npc, creature, "I'm just a mere messenger and I'm here to find brave adventurers that might {help} my friends in this time of need.")
	elseif MsgContains(message, "help") then
		say(npcHandler, npc, creature, "Lady Alivar of the Summer Court and Lord Cadion of the Winter Court are in need of brave adventurers to avert a great {threat} for the whole world.")
	elseif MsgContains(message, "threat") then
		say(npcHandler, npc, creature, {
			"I know only little and I forget so much. So many things going around my mind! ...",
			"However, I can grant you access to the {Courts} of Summer and Winter if you promise to help! There you can meet with Undal or Vanys, the servants of Lord Cadion and Lady Alivar. They will be able to tell you more about the issue.",
		})
	elseif MsgContains(message, "courts") or MsgContains(message, "court") then
		say(npcHandler, npc, creature, {
			"There are {entrances} to the hidden Courts of Summer and Winter in secluded places. You can find the portal to the Winter Court high in the mountains of Tyrsung and the portal to the Summer Court in the meadows of Feyrist. ...",
			"With my magic you will be able to enter the Courts. Find Undal or Vanys and talk to them.",
		})
	elseif MsgContains(message, "entrances") or MsgContains(message, "entrance") then
		if started then
			say(npcHandler, npc, creature, "With my magic you will be able to enter the Courts. Find Undal or Vanys and talk to them.")
		else
			say(npcHandler, npc, creature, "So, are you willing to help in this time of need?")
			npcHandler:setTopic(pid, 6)
		end
	end
	return true
end

-- ---------------------------------------------------------------- Vanys and Undal
local LONG_STORY = {
	{
		"Though the dreamborn have many similarities with common elves, they are not creatures of your world. They were created through the dreams of a powerful elf whose name is long forgotten. All that is known, is that he was a exceptional dreamweaver. ...",
		"His mastery over dreams was that great, that his dreams became substantial. It is said, he was the most advanced dreamweaver that ever walked the world. ...",
		"He was also an artist and he was lonely. So he decided to dream of a new race of elves that might keep him company. He dreamed his creation into life and they flourished. At first the dreamer was pleased and lived with his people in happiness. ...",
		"But with time came doubts and his joys grew shallow. That was when he begun to have troublesome dreams of guilt and burden. One day he left his people. ...",
		"Do you wish me to {continue}?",
	},
	{
		"It is unclear if he simply went away or dread had befallen him. But be it as it may, his children were left alone and lacked his fatherly wisdom and guidance. Their despair and fear fed the thing whose seed was born of their creators troubles. ...",
		"The seed grew and grew and so did the confusion of the dreamborn. The dream gardens that has fed the dreamborn in abundance begun to bear bitter fruits and for the first time in existence they had to tend to themselves. ...",
		"They looked to the other races and adopted many of their customs and manners. That way they survived yet they lost their innocence forever. ...",
		"The seed of nightmare fed on this, prospered and finally gave birth to a horrible creature, unbeknown to the dreamborn. ...",
		"It begun to visit them in their dreams and brought with it animosity and dissent. Those things tore a friction in the realm of dreams that the dreamborn inhabited and at one fateful day it begun to break apart. ...",
		"Do you wish me to {continue}?",
	},
	{
		"The greatest of their kind lost their lives in an effort to prevent the seemingly inevitable annihilation. They became dreams again and with their essence mended the wounds that the friction had caused. ...",
		"Yet though the realms survived, they were now split and a dreamscar remained in the world, where the breaking point of the realm had been. The two separated realms drifted apart but managed to uphold contact. ...",
		"Still through the whisperings of the beast the friction in the realm was not the only one to cope with. Also the people of the new realms became to differ more and more. ...",
		"They did no longer see the others as brothers and sisters but some very distant relatives at best. ...",
		"Though all the differences were mostly superficial, a deep mistrust towards the others and a great arrogance about their own side begun to grow. Regardless of this there was no open hostilities between the dreamborn. ...",
		"A mockery here, a slight there. It might have lead to conflict on its own but things were forced anyway quite soon. Feeding on the dreamborns animosities the nightmare abomination had grown in size and power and if was hungry for more. ...",
		"Do you wish me to {continue}?",
	},
	{
		"Making its lair in the festering wound between the realms it was no longer content to devour bad dreams, it wanted more, it wanted the dreamborn themselves. So with all its power it arose and attacked the realm of the dreamborn. ...",
		"At first it were only occasional hunts in the dark but its appetites grew with every dreamborn it devoured. Soon the realm became aware of missing people. But instead of acting in unison, they accused each other of foul play. ...",
		"The anger fed the beast even more and with time it grew more powerful and more bold. Soon its attacks increased but even after sightings of its slaughterings, each of the realms still assumed that this was the work of the others. ...",
		"The most wise minds on both sides though were not that easily fooled. They managed to pinpoint the threat and even to understand its nature. ...",
		"It took long to convince their people of what they had learned. Time that allowed the beast to prosper even more. ...",
		"Do you wish me to {continue}?",
	},
	{
		"When they finally united to fight the threat, it was almost too late. Some of the most powerful dreamborn gave up their lives to bind their essence into obelisks of power. ...",
		"The others weaved powerful spells and wards into those stones which where placed all over the world in a certain pattern to weave a net that would bind the beast and blunt its power. ...",
		"Then their two leaders gathered their best men to fight the beast in its lair. The battle was hard and all but the two kings were forced to retreat. ...",
		"The two would challenge the beast and try to kill it once and for all, while their allies outside would prepare enchantments of binding that they should activate should their leaders fail. ...",
		"Despite all other claims it is unclear what happened next. Leaving out the numerous interpretations and the one true version that each side claims to know, the only sure thing is, that the beast stayed alive and the wards had to be activated. ...",
		"Do you wish me to {continue}?",
	},
	{
		"The wounded beast was bound and trapped. For all eternity as it seemed. But little is meant for eternity and in our days the old wards have begun to waver. The beast arises again and its power slowly tires out the ancient spells. ...",
		"In these dark days a stranger from beyond appeared. He made allies at the courts of summer and winter. With sweet words, promises of power and tales of plotting by the other court he poisons the hearts of many nobles on both sides. ...",
		"He promises he knows ways to bind the beast to the will of a dreamborn, a perverse thought that sadly has an appeal to many. ...",
		"He talks about destroying the wardstones that are in the heart of the courts. He plays both courts against each other and no one is willing to listen. ...",
		"The only ones aware of this foul play are lady Alivar from the summer court and lord Cadion from the court of winter whose hearts are bound in a forbidden, secret love to each other. ...",
		"Due to their secretive meetings and private talk they are aware that the stranger is playing a destructive game with the courts. But no one will listen and the reveal of their love would put both in danger and invalidate any proof they might have. ...",
		"Do you wish me to {continue}?",
	},
	{
		"So they came up with a plan how to stop the unleashing of the beast. First it needs adventurers to travel the world and charge the minor wardstones with new energy. ...",
		"Having done that, the adventurers will have to enter the dream scar, where the prison of the beast is located. The scar has become a prominent arena in these days, where champions of the courts train to prepare for various threats. ...",
		"The adventurers have to become champions of the arena to gain access to the lower areas of the scar where the prison of the nightmare beast is located. ...",
		"There they can enter the chamber the beast is banished to and hopefully will be able to slay the beast whose strength should be dampened by the newly empowered wards. This should end the threat once and for all. ...",
		"So do you want me to tell you more about the {story} behind of this or rather talk about the {task} at hand?",
	},
}

-- Undal's transcript (EN) has a few words that differ from Vanys'.
local UNDAL_WORDS = {
	{ "All that is known, is that he was a exceptional", "All that is known is, that he was an exceptional" },
	{ "The dream gardens that has fed", "The dream gardens that have fed" },
	{ "there was no open hostilities", "there were no open hostilities" },
	{ "and if was hungry for more", "and it was hungry for more" },
}

function D.longStory(part, npcName)
	local lines = {}
	for i, line in ipairs(LONG_STORY[part]) do
		if npcName == "Undal" then
			for _, w in ipairs(UNDAL_WORDS) do
				local a, b = line:find(w[1], 1, true)
				if a then
					line = line:sub(1, a - 1) .. w[2] .. line:sub(b + 1)
				end
			end
		end
		lines[i] = line
	end
	return lines
end
D.LONG_PARTS = #LONG_STORY

local TOPIC_TALK, TOPIC_STORY = 1, 2
local TOPIC_LONG = 10 -- 10 + part already told
local TOPIC_ADDON, TOPIC_ADDON_OFFER, TOPIC_ADDON_WHICH = 30, 31, 32

local function hasDreamOutfit(player)
	return player:hasOutfit(D.OUTFITS[1]) or player:hasOutfit(D.OUTFITS[2])
end

local function giveAddon(player, addon)
	for _, lookType in ipairs(D.OUTFITS) do
		player:addOutfitAddon(lookType, addon)
	end
	if player:hasOutfit(D.OUTFITS[1], 3) or player:hasOutfit(D.OUTFITS[2], 3) then
		player:addAchievement("Dream Warrior") -- BR: both addons
	end
end

local function hasAddon(player, addon)
	return player:hasOutfit(D.OUTFITS[1], addon) or player:hasOutfit(D.OUTFITS[2], addon)
end

function D.courtSay(npcHandler, npc, creature, message, court)
	local player = Player(creature)
	local pid = player:getId()
	local topic = npcHandler:getTopic(pid)
	local npcName = court == "winter" and "Undal" or "Vanys"
	local stones = storage(player, DC.WardStones.Questline)

	if topic == TOPIC_ADDON and MsgContains(message, "yes") then
		say(npcHandler, npc, creature, "I provide two addons. For the first one I need you to bring me five pomegranates. For the second addon you need an ice shield. Do you want one of these addons?")
		npcHandler:setTopic(pid, TOPIC_ADDON_OFFER)
		return true
	elseif topic == TOPIC_ADDON_OFFER and MsgContains(message, "yes") then
		say(npcHandler, npc, creature, "What do you have for me: the {pomegranates} or the {ice shield}?")
		npcHandler:setTopic(pid, TOPIC_ADDON_WHICH)
		return true
	elseif topic == TOPIC_ADDON_WHICH and (MsgContains(message, "pomegranate") or MsgContains(message, "pomegranates")) then
		npcHandler:setTopic(pid, 0)
		if hasAddon(player, 1) then
			say(npcHandler, npc, creature, "You already have this addon.") -- ours
		elseif player:getItemCount(D.POMEGRANATE) >= 5 and player:removeItem(D.POMEGRANATE, 5) then
			giveAddon(player, 1)
			say(npcHandler, npc, creature, "Very good! You gained the first addon to the dream warrior outfit.")
		else
			say(npcHandler, npc, creature, "You do not have enough items.")
		end
		return true
	elseif topic == TOPIC_ADDON_WHICH and MsgContains(message, "shield") then
		npcHandler:setTopic(pid, 0)
		if hasAddon(player, 2) then
			say(npcHandler, npc, creature, "You already have this addon.") -- ours
		elseif player:getItemCount(D.ICE_SHIELD) >= 1 and player:removeItem(D.ICE_SHIELD, 1) then
			giveAddon(player, 2)
			say(npcHandler, npc, creature, "Very good! You gained the second addon to the dream warrior outfit.")
		else
			say(npcHandler, npc, creature, "You do not have enough items.")
		end
		return true
	end

	if topic >= TOPIC_LONG and topic < TOPIC_LONG + D.LONG_PARTS and (MsgContains(message, "continue") or MsgContains(message, "yes")) then
		local part = topic - TOPIC_LONG + 1
		say(npcHandler, npc, creature, D.longStory(part, npcName))
		npcHandler:setTopic(pid, part < D.LONG_PARTS and TOPIC_LONG + part or 0)
		return true
	end

	if MsgContains(message, "talk") then
		say(npcHandler, npc, creature, "So do you want to learn the {story} behind of this or rather talk about the {task} at hand?")
		npcHandler:setTopic(pid, TOPIC_TALK)
	elseif MsgContains(message, "story") then
		say(npcHandler, npc, creature, "Do you prefer the {long} version or the {short} version?")
		npcHandler:setTopic(pid, TOPIC_STORY)
	elseif MsgContains(message, "short") then
		say(npcHandler, npc, creature, {
			"You will have to re-empower several wardstones all over the world, to weaken the beast of nightmares. ...",
			"The next step would be to enter a place known as dream scar and participate in battles, to gain access to the lower areas. ...",
			"There the nightmare beast can be challenged and defeated.",
		})
		npcHandler:setTopic(pid, TOPIC_STORY)
	elseif MsgContains(message, "long") then
		say(npcHandler, npc, creature, D.longStory(1, npcName))
		npcHandler:setTopic(pid, TOPIC_LONG + 1)
	elseif MsgContains(message, "task") or MsgContains(message, "mission") then
		npcHandler:setTopic(pid, 0)
		if stones < 1 then
			say(npcHandler, npc, creature, {
				"You have to empower eight ward stones. Once charged with arcane energy, they will strengthen the Nightmare Beast's prison and at the same time weaken this terrible creature. We know about the specific location of six of those stones. ...",
				"You can find them in the mountains of the island Okolnir, in a water elemental cave beneath Folda, in the depths of Calassa, in the forests of Feyrist and on the islands Meriana and Cormaya. ...",
				"The location of the other two ward stones is a bit more obscure, however. We are not completely sure where they are. You should make inquiries at an abandoned house in the Plains of Havoc. You may find it east of an outlaw camp. ...",
				"The other stone seems to be somewhere in Tiquanda. Search for a small stone building south-west of Banuta. Take this talisman to empower the ward stones. It will work with the six stones at the known locations. ...",
				"However, the empowering of the two hidden stones could be a bit more complicated. But you have to find out on yourself what to do with those stones.",
			})
			if storage(player, DC.Main.Questline) < 1 then
				player:setStorageValue(DC.Main.Questline, 1)
			end
			player:setStorageValue(court == "winter" and DC.Main.TheWinterCourt or DC.Main.TheSummerCourt, 1)
			player:setStorageValue(DC.WardStones.Questline, 1)
			player:setStorageValue(DC.WardStones.Count, 0)
			player:addItem(D.TALISMAN, 1)
		elseif stones == 1 and storage(player, DC.WardStones.Count) < 8 then
			-- ours
			say(npcHandler, npc, creature, string.format("You have empowered %d of the eight ward stones so far. Come back when all of them are charged with arcane energy.", math.max(storage(player, DC.WardStones.Count), 0)))
		elseif stones == 1 then
			say(npcHandler, npc, creature, {
				"You empowered all eight ward stones. Well done! You may now enter the Dream Labyrinth via the portal here in the Court. Beneath it you will find the Nightmare Beast's lair. But the labyrinth is protected by seven so called Dream Doors. ...",
				"You have to find the Seven {Keys} to unlock the Seven Dream Doors down there. Only then you will be able to enter the Nightmare Beast's lair.",
			})
			player:setStorageValue(DC.WardStones.Questline, 2)
			if storage(player, DC.TheSevenKeys.Questline) < 1 then
				player:setStorageValue(DC.TheSevenKeys.Questline, 1)
			end
		elseif stones == 2 then
			-- ours
			say(npcHandler, npc, creature, "Find the Seven {Keys} to open the Dream Doors, prove yourself in the arena of the dream scar and slay the Nightmare Beast in its lair.")
		elseif stones == 3 then
			say(npcHandler, npc, creature, "The Nightmare Beast is slain. You have done well. The Courts of Summer and Winter will be forever grateful. For your efforts I want to reward you with our traditional dream warrior outfit. May it suit you well!")
			for _, lookType in ipairs(D.OUTFITS) do
				player:addOutfit(lookType)
			end
			player:addAchievement("Dream Catcher") -- EN: after reporting to Undal or Vanys
			player:setStorageValue(DC.WardStones.Questline, 4)
		else
			say(npcHandler, npc, creature, "The Courts of Summer and Winter will be forever grateful.") -- ours
		end
	elseif MsgContains(message, "keys") or MsgContains(message, "key") then
		if stones >= 2 then
			say(npcHandler, npc, creature, "They are not literally keys but rather puzzles you have to solve or a secret mechanism you have to discover in order to open the Dream Doors. A parchment in the chest here can tell you more about it.")
		end
	elseif MsgContains(message, "lost") or MsgContains(message, "talisman") then
		if stones == 1 and player:getItemCount(D.TALISMAN) < 1 then
			player:addItem(D.TALISMAN, 1)
			say(npcHandler, npc, creature, "Here is a new talisman. Take better care of it this time!") -- ours (EN: "lost" gives a new one)
		elseif stones == 1 then
			say(npcHandler, npc, creature, "You still have your talisman. Use it on the ward stones.") -- ours
		end
	elseif MsgContains(message, "addon") or MsgContains(message, "addons") then
		if hasDreamOutfit(player) then
			say(npcHandler, npc, creature, "Are you interested in one or two addons to your dream warrior outfit?")
			npcHandler:setTopic(pid, TOPIC_ADDON)
		else
			say(npcHandler, npc, creature, "You don't even have the outfit.")
		end
	end
	return true
end

-- ---------------------------------------------------------------- Andrew Lyze
local UR = DC.UnsafeRelease
-- UnsafeRelease.Questline: 1 materials asked, 2 compass repaired, 3 compass charged (unleash),
-- 4 chest opened for the first time, 5 reported (50,000 experience, BR).
local T_REPAIR, T_READY, T_BUY, T_BAIT, T_CHARGE, T_CHARGE_YES = 11, 12, 51, 60, 70, 71

local function hasAll(player, list)
	for _, k in ipairs(list) do
		if player:getItemCount(k[1]) < k[2] then
			return false
		end
	end
	return true
end

local function removeAll(player, list)
	for _, k in ipairs(list) do
		player:removeItem(k[1], k[2])
	end
end

D.REPAIR_ITEMS = { { D.BROKEN_COMPASS, 1 }, { D.GLASS.blue, 50 }, { D.GLASS.green, 15 }, { D.GLASS.violet, 5 } }
D.UNLEASH_ITEMS = { { D.CHARGEABLE_COMPASS, 1 }, { D.CRYSTAL[1], 5 }, { D.CRYSTAL[2], 3 }, { D.CRYSTAL[3], 1 }, { D.POISON_GLAND, 1 } }

function D.baitActive(player)
	return storage(player, D.S.BaitUntil) > os.time()
end

function D.giveBait(player)
	player:setStorageValue(D.S.BaitUntil, os.time() + D.BAIT_TIME)
	player:getPosition():sendMagicEffect(CONST_ME_POFF)
end

function D.andrewGreet(npcHandler, npc, player)
	local state = storage(player, UR.Questline)
	if state < 1 then
		return "Hello, I am the warden of this {monument}. The {sarcophagus} in front of you was established to prevent people from going {down} there. But I doubt that this step is sufficient."
	elseif state == 1 then
		return "Well, let's see if your mission was successful. Just bring me all needed {materials}."
	elseif state == 2 and storage(player, UR.GotAxe) < 1 then
		npcHandler:setTopic(player:getId(), T_READY)
		return "The next step is the charging of the compass. For this you have to dig three different crystals down there: 5 blue, 3 green and one violet crystal. Are you ready to do that?"
	elseif state == 2 then
		return "If you dug up all three crystals of sufficient quantity and obtained the poison gland, the charging of your compass can start! For the very first time it will be charged by the violet crystal. Ready to {unleash} the power of the crystals?"
	elseif state == 3 then
		return "Your compass is charged. Use it on the magic portal next to the sarcophagus." -- ours
	elseif state == 4 then
		player:setStorageValue(UR.Questline, 5)
		player:addExperience(50000, true) -- BR: 50,000 experience
		local npcId, playerId = npc:getId(), player:getId()
		addEvent(function()
			local n, p = Npc(npcId), Player(playerId)
			if n and p then
				npcHandler:say("Thank you very much for your help to repair the compass. Whenever you need help to {charge} the compass again, just ask me!", n, p)
			end
		end, 3000)
		return "Nice to see that the charged compass works properly. Because the amount of energy in the compass is much higher after the initial charging process it is still charged. This should be different in the future. ..."
	end
	return "Greetings. Do you need me to {charge} your compass?" -- ours
end

function D.andrewSay(npcHandler, npc, creature, message)
	local player = Player(creature)
	local pid = player:getId()
	local topic = npcHandler:getTopic(pid)
	local state = storage(player, UR.Questline)

	if MsgContains(message, "yes") then
		if topic == T_REPAIR then
			npcHandler:setTopic(pid, 0)
			if not hasAll(player, D.REPAIR_ITEMS) then
				say(npcHandler, npc, creature, "You don't have the needed items yet.")
				return true
			end
			removeAll(player, D.REPAIR_ITEMS)
			player:addItem(D.CHARGEABLE_COMPASS, 1)
			player:setStorageValue(UR.Questline, 2)
			say(npcHandler, npc, creature, {
				"Alright, I put the glasses into the right pattern and can repair the compass. ...",
				"There we are! The next step is the charging of the compass. For this you have to dig three different crystals down there: 5 blue, 3 green and one violet crystal. Are you ready to do that?",
			})
			npcHandler:setTopic(pid, T_READY)
		elseif topic == T_READY and state == 2 and storage(player, UR.GotAxe) < 1 then
			player:addItem(D.GOLDEN_AXE, 1)
			player:setStorageValue(UR.GotAxe, 1)
			D.giveBait(player)
			say(npcHandler, npc, creature, {
				"Nice! To do so, take this golden axe and mine the prominent crystals in the cave. Besides, I need a poison gland of quite rare spiders, they are called lucifuga araneae. ...",
				"These are quite shy, but I have a {bait} for you to lure them. But take care not to face too many of them at once. And hurry, the effect won't last forever!",
			})
			npcHandler:setTopic(pid, 0)
		elseif topic == T_BUY then
			npcHandler:setTopic(pid, 0)
			if player:removeMoneyBank(10000) then
				player:addItem(D.BROKEN_COMPASS, 1)
				say(npcHandler, npc, creature, "Here's your broken compass!")
			else
				say(npcHandler, npc, creature, "You don't have enough money.")
			end
		elseif topic == T_BAIT then
			npcHandler:setTopic(pid, 0)
			if player:removeMoneyBank(D.BAIT_FEE) then
				D.giveBait(player)
				say(npcHandler, npc, creature, "Done. Hurry, the effect won't last forever!") -- ours
			else
				say(npcHandler, npc, creature, "You don't have enough money.")
			end
		elseif topic >= T_CHARGE_YES and topic <= T_CHARGE_YES + 2 then
			local colour = topic - T_CHARGE_YES + 1
			npcHandler:setTopic(pid, 0)
			local compass = player:getItemById(D.CHARGEABLE_COMPASS, true)
			if not compass then
				say(npcHandler, npc, creature, "You need a compass without a charge for this.") -- ours
			elseif player:getItemCount(D.CRYSTAL[colour]) < 1 then
				say(npcHandler, npc, creature, "You need a " .. D.COLOUR_NAME[colour] .. " crystal for this charge.") -- ours
			elseif not player:removeMoneyBank(D.CHARGE_FEE[colour]) then
				say(npcHandler, npc, creature, "You don't have enough money.")
			else
				player:removeItem(D.CRYSTAL[colour], 1)
				compass:transform(D.COMPASS[colour])
				say(npcHandler, npc, creature, "I put the crystal onto the top of the compass. As you can see, it is now pulsating in a " .. D.COLOUR_NAME[colour] .. " colour.") -- ours, after the EN unleash line
			end
		end
		return true
	elseif MsgContains(message, "no") and topic ~= 0 then
		say(npcHandler, npc, creature, "Don't waste my time.")
		npcHandler:setTopic(pid, 0)
		return true
	end

	if topic == T_CHARGE then
		for colour, name in pairs(D.COLOUR_NAME) do
			if MsgContains(message, name) or (colour == 3 and MsgContains(message, "purple")) then
				say(npcHandler, npc, creature, string.format("For a %s charge I need a %s crystal and %d gold. Shall I charge your compass?", name, name, D.CHARGE_FEE[colour])) -- ours
				npcHandler:setTopic(pid, T_CHARGE_YES + colour - 1)
				return true
			end
		end
	end

	if MsgContains(message, "monument") then
		say(npcHandler, npc, creature, {
			"Well, a while ago powerful magic devices were used all around Tibia. These are chargeable compasses. There was but one problem: they offered the possibility to make people rich in a quite easy way. ...",
			"Therefore, these instruments were very coveted. People tried to get their hands on them at all costs. And so it happened what everybody feared - bloody battles forged ahead. ...",
			"To put an end to these cruel escalations, eventually all of the devices were collected and destroyed. The remains were buried {deep} in the earth.",
		})
	elseif MsgContains(message, "deep") or MsgContains(message, "depths") then
		say(npcHandler, npc, creature, "As far as I know it is a place of helish heat with bloodthirsty monsters of all kinds.")
	elseif MsgContains(message, "sarcophagus") then
		say(npcHandler, npc, creature, "This sarcophagus seals the entrance to the caves down there. Only here you can get all the {materials} you need for a working compass of this kind. So no entrance here - no further magic compasses in Tibia. In theory.")
	elseif MsgContains(message, "down") then
		say(npcHandler, npc, creature, "On first glance, this cave does not look very spectacular, but the things you find in there, are. You have to know that this is the only place where you can find the respective materials to build the compass.")
	elseif MsgContains(message, "materials") or MsgContains(message, "material") then
		if state < 1 then
			say(npcHandler, npc, creature, {
				"Only in the cave down there you will find the materials you need to repair the {compass}. Now you know why the entrance is sealed. There's the seal, but I have a deal for you: ...",
				"I can repair the compass for you if you deliver what I need. Besides the broken compass you have to bring me the following materials: 50 blue glas plates, 15 green glas plates and 5 violet glas plates. ...",
				"They all can be found in this closed cave in front of you. I should have destroyed this seal key but things have changed. The entrance is opened now, go down and do what has to be done.",
			})
			player:setStorageValue(UR.Questline, 1)
		elseif state == 1 then
			say(npcHandler, npc, creature, "May I repair your compass if possible?")
			npcHandler:setTopic(pid, T_REPAIR)
		else
			say(npcHandler, npc, creature, "I already repaired your compass.") -- ours
		end
	elseif MsgContains(message, "unleash") then
		if state == 2 and storage(player, UR.GotAxe) < 1 then
			say(npcHandler, npc, creature, "The next step is the charging of the compass. For this you have to dig three different crystals down there: 5 blue, 3 green and one violet crystal. Are you ready to do that?")
			npcHandler:setTopic(pid, T_READY)
		elseif state == 2 then
			if not hasAll(player, D.UNLEASH_ITEMS) then
				say(npcHandler, npc, creature, "You don't have the needed items yet.")
				return true
			end
			removeAll(player, D.UNLEASH_ITEMS)
			player:addItem(D.COMPASS[3], 1)
			player:setStorageValue(UR.Questline, 3)
			say(npcHandler, npc, creature, {
				"I put these crystals onto the top of compass. As you can see, the compass is now pulsating in a warm, violet colour. ...",
				"Now this compass is ready for usage. It can transfer the bound energy to other inanimate objects to open certain gates or chests.",
			})
		end
	elseif MsgContains(message, "bait") then
		if state == 2 and storage(player, UR.GotAxe) >= 1 then
			if D.baitActive(player) then
				say(npcHandler, npc, creature, "You're already with my bait!")
			else
				say(npcHandler, npc, creature, string.format("Do you want me to put another bait on you for %d gold?", D.BAIT_FEE)) -- ours (EN: 5,000 gold)
				npcHandler:setTopic(pid, T_BAIT)
			end
		else
			say(npcHandler, npc, creature, "You cannot do that yet.")
		end
	elseif MsgContains(message, "charge") or MsgContains(message, "recharge") then
		if state >= 3 then
			say(npcHandler, npc, creature, "Which charge do you want: {blue}, {green} or {violet}?") -- ours
			npcHandler:setTopic(pid, T_CHARGE)
		else
			say(npcHandler, npc, creature, "You cannot do that yet.")
		end
	elseif MsgContains(message, "compass") then
		say(npcHandler, npc, creature, "It was decided to collect all of the compasses, destroy them and throw them in the fiery {depths} of Tibia. I still have some of them here. I {sell} them for a low price if you want.")
	elseif MsgContains(message, "sell") or MsgContains(message, "buy") then
		say(npcHandler, npc, creature, "Would you like to buy a broken compass for 10.000 gold?")
		npcHandler:setTopic(pid, T_BUY)
	end
	return true
end

-- ---------------------------------------------------------------- Stricken Soul
function D.strickenSay(npcHandler, npc, creature, message)
	local player = Player(creature)
	local pid = player:getId()
	local topic = npcHandler:getTopic(pid)
	local name = player:getName()
	if topic == 3 then
		if MsgContains(message, name) or message:lower() == name:lower() then
			say(npcHandler, npc, creature, {
				"Ah yeeeeees, " .. name .. "... I will remember you. Now, lessons are every day in the morning and once a week in the evening... ...",
				"Oh, you're not here for this, are you? So about the ghoooosts, yes. You seeeee, there are 3 secret passages here. ...",
				"Thiiiiis is no ordinary house... it is a nexus, a gateway to a once hidden cathedral. Sheltering a small and peaceful society of scholars and monks. Secluded from every distraction. ...",
				"I was one of them and ordered to hold contact to the outside woooorld. But then, something... happened. ...",
				"Outsiders managed to sneak in, infiltrate and influence the society... for the worse. Who knows for what ends. They chaaaaanged... ...",
				"Shortly after, contact was lost... the nexus broken and sealed, ghosts appeared... eeeeeeeverywhere. ...",
				"Find the three passages... one is right here in the cellars, one in the jungles of Tiquanda and one in the deserts of Darama. ...",
				"Restore their connection and open this nexus to access the buried cathedral and find the cause to this... eliminate all remainders there if you must, " .. name .. ".",
			})
			if storage(player, DC.HauntedHouse.Questline) < 1 then
				player:setStorageValue(DC.HauntedHouse.Questline, 1)
			end
			npcHandler:setTopic(pid, 0)
		else
			say(npcHandler, npc, creature, "That is noooooot your name... tell me your naaaaaame!") -- EN
		end
		return true
	end
	if MsgContains(message, "yes") and storage(player, DC.HauntedHouse.Questline) < 1 then
		if topic == 2 then
			say(npcHandler, npc, creature, "Excellent... I hope they will haaaaaaunt my house no longer. What was your... naaaaaame again, tell me?")
			npcHandler:setTopic(pid, 3)
		else
			say(npcHandler, npc, creature, "Yeeeees... you need to help meeeeeee. I want those ghosts gone... this is my home and I need it to teach my students. Will you take care of the... ghosts?")
			npcHandler:setTopic(pid, 2)
		end
	elseif MsgContains(message, "name") then
		say(npcHandler, npc, creature, "I am... I was... I... it was such a looooong time ago.") -- BR
	elseif MsgContains(message, "job") then
		say(npcHandler, npc, creature, "I... was... not a servant. Not a lord nor a knight. I was a... traveller. Yeeeees. A scholar! I hoarded knowledge... some I would advise or teach. But of thoooooose I have no memory.") -- BR
	elseif MsgContains(message, "scholar") then
		say(npcHandler, npc, creature, "Yes, I am... a scholar! I teach... my knowledge... I can take you in as another student... just need to remember... your naaaaaame...") -- BR
		if storage(player, DC.HauntedHouse.Questline) < 1 then
			npcHandler:setTopic(pid, 3)
		end
	end
	return true
end

-- ---------------------------------------------------------------- the arena elves
function D.arenaSay(npcHandler, npc, creature, message, side)
	local player = Player(creature)
	local pid = player:getId()
	local sideId = side == "winter" and 2 or 1
	if MsgContains(message, "fight") or MsgContains(message, "cause") then
		if storage(player, DC.TheSevenKeys.Questline) < 2 then
			say(npcHandler, npc, creature, "Only those who passed the Seven Dream Doors may fight in this arena.") -- ours
		elseif storage(player, D.S.ArenaSide) == sideId and storage(player, DC.DreamScar.Permission) >= 1 then
			say(npcHandler, npc, creature, "You already fight for our cause. The teleport is open for you.") -- ours
		else
			say(npcHandler, npc, creature, "We allow able champions of all races to fight for our cause against the challenges of the {arena}. So are you interested? I'm not interested in fancy'wordplay, so a simple {yes} or {no} will suffice!")
			npcHandler:setTopic(pid, 2)
		end
	elseif MsgContains(message, "yes") and npcHandler:getTopic(pid) == 2 then
		player:setStorageValue(DC.DreamScar.Permission, 1)
		player:setStorageValue(D.S.ArenaSide, sideId)
		say(npcHandler, npc, creature, "You are now able to enter the teleport.")
		npcHandler:setTopic(pid, 0)
	elseif MsgContains(message, "no") and npcHandler:getTopic(pid) == 2 then
		say(npcHandler, npc, creature, "As you wish.")
		npcHandler:setTopic(pid, 0)
	elseif MsgContains(message, "arena") then
		say(npcHandler, npc, creature, "This place has always been a site where the champions of summer and winter have clashed in battle. Over the centuries this spectacle has drawn many creatures here to watch, participate and indulge in less savory activities.")
	elseif MsgContains(message, "boss") or MsgContains(message, "champion") or MsgContains(message, "today") then
		say(npcHandler, npc, creature, "Today's champion of the arena is " .. D.bossOfTheDay().name .. ".") -- ours (our map has no notice board)
	end
	return true
end

-- A win in the arena counts for the side the player fights for (Champion of Summer/Winter: 20 wins).
function D.arenaWin(player)
	local side = storage(player, D.S.ArenaSide)
	if side ~= 1 and side ~= 2 then
		return
	end
	local key = side == 1 and D.S.SummerWins or D.S.WinterWins
	local wins = math.max(storage(player, key), 0) + 1
	player:setStorageValue(key, wins)
	if wins >= 20 then
		player:addAchievement(side == 1 and "Champion of Summer" or "Champion of Winter")
	end
end

D.ARENA_BOSS_NAMES = {
	["plagueroot"] = true,
	["malofur mangrinder"] = true,
	["maxxenius"] = true,
	["alptramun"] = true,
	["izcandar the banished"] = true,
	["izcandar champion of winter"] = true,
	["izcandar champion of summer"] = true,
}

-- ---------------------------------------------------------------- crystals, compass, chest room
-- Golden axe: every column can give every crystal (EN, BR); its own colour is the most likely (ours).
D.COLUMN_COLOUR = { [8865] = 1, [14940] = 2, [14974] = 3 }

function D.crystalFor(columnId)
	local own = D.COLUMN_COLOUR[columnId] or 1
	local r = math.random(1, 10)
	if r <= 6 then
		return own
	end
	local others = {}
	for c = 1, 3 do
		if c ~= own then
			others[#others + 1] = c
		end
	end
	return others[r <= 8 and 1 or 2]
end

D.CRYSTAL_MESSAGE = { [1] = "You got a blue crystal!", [2] = "You got a green crystal!", [3] = "You got a violet crystal!" }

local CHEST_TIMER = { [1] = D.S.ChestBlue, [2] = D.S.ChestGreen, [3] = D.S.ChestViolet }

-- EN spoiler (BR lists only the first three for blue and the first two for green).
D.CHEST_REWARDS = {
	[1] = { { "ornate locket", 1 }, { "blue gem", 2 }, { "gold ingot", 2 }, { "giant sapphire", 1 } },
	[2] = { { "crunor idol", 1 }, { "green gem", 3 }, { "gold ingot", 5 }, { "giant ruby", 1 }, { "bar of gold", 1 } },
	[3] = { { "dragon figurine", 1 }, { "bar of gold", 1 }, { "gold ingot", 9 }, { "violet gem", 3 }, { "giant emerald", 1 } },
}

local function compassColour(itemId)
	for colour, id in pairs(D.COMPASS) do
		if id == itemId then
			return colour
		end
	end
end

-- A charged compass used on something. Returns true when handled.
function D.useCompass(player, item, target, toPosition)
	local colour = compassColour(item.itemid)
	if not colour or not toPosition then
		return false
	end
	local state = storage(player, UR.Questline)
	if toPosition == D.MAGIC_PORTAL then
		if storage(player, CHEST_TIMER[colour]) > os.time() then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The magic portal does not react. The " .. D.COLOUR_NAME[colour] .. " chest will not open for you again so soon.") -- ours
			return true
		end
		if not (state == 3 and colour == 3) then
			item:transform(D.CHARGEABLE_COMPASS) -- every later use costs the charge (EN)
		end
		player:setStorageValue(D.S.ChestColour, colour)
		D.PORTAL_EXIT:sendMagicEffect(CONST_ME_TELEPORT)
		player:teleportTo(D.ROOM.arrive)
		D.ROOM.arrive:sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The compass transfers its energy to the magic portal and you are pulled through.") -- ours
		return true
	end
	if toPosition == D.PORT_HOPE_STONE and colour == 3 then
		if state >= 3 and storage(player, DC.WardStones.PortHopeStone) < 1 and storage(player, DC.WardStones.Questline) >= 1 then
			player:setStorageValue(DC.WardStones.PortHopeStone, 1)
			player:setStorageValue(DC.WardStones.Count, math.max(storage(player, DC.WardStones.Count), 0) + 1)
			player:say("The energy is transferred to the rune stone. It glows now!", TALKTYPE_MONSTER_SAY)
			toPosition:sendMagicEffect(CONST_ME_THUNDER)
			item:transform(D.CHARGEABLE_COMPASS)
			D.lightStone(toPosition, D.STONE_SUMMER, D.STONE_SUMMER_LIT)
			return true
		end
	end
	return false
end

function D.lightStone(position, off, on)
	local stone = Tile(position) and Tile(position):getItemById(off)
	if stone then
		stone:transform(on)
		addEvent(function()
			local tile = Tile(position)
			local lit = tile and tile:getItemById(on)
			if lit then
				lit:transform(off)
			end
		end, 30 * 1000)
	end
end

function D.useChest(player)
	local colour = storage(player, D.S.ChestColour)
	if colour < 1 or colour > 3 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
		return true
	end
	local list = D.CHEST_REWARDS[colour]
	local pick = list[math.random(1, #list)]
	local itemType = ItemType(pick[1])
	player:addItem(itemType:getId(), pick[2])
	player:setStorageValue(D.S.ChestColour, 0)
	player:setStorageValue(CHEST_TIMER[colour], os.time() + D.CHEST_TIME)
	if storage(player, UR.Questline) == 3 then
		player:setStorageValue(UR.Questline, 4)
	end
	local name = pick[2] > 1 and (pick[2] .. " " .. itemType:getPluralName()) or (itemType:getArticle() .. " " .. itemType:getName())
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. name .. ".")
	return true
end

function D.leaveChestRoom(player)
	player:setStorageValue(D.S.ChestColour, 0)
	player:teleportTo(D.PORTAL_EXIT)
	D.PORTAL_EXIT:sendMagicEffect(CONST_ME_TELEPORT)
end

-- ---------------------------------------------------------------- Haunted House
-- Mutated eggs and the leaking bucket (EN: it slowly fills; the ectoplasm leaks out after 3, 2 or 1 minute).
D.BUCKET = { empty = 29310, some = 29307, half = 29308, full = 29309 }
D.BUCKET_NEXT = { [29310] = 29307, [29307] = 29308, [29308] = 29309 }

function D.fillBucket(player, item, egg)
	local nextId = D.BUCKET_NEXT[item.itemid]
	if not nextId then
		return false
	end
	local eggPos = egg:getPosition()
	if math.random(1, 10) <= 5 then
		item:transform(nextId)
		item:decay()
		player:getPosition():sendMagicEffect(CONST_ME_POISONAREA)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The ectoplasm all over this egg was already seeping inside the cocoon itself. You manage to fill some of it into the bucket.")
	else
		eggPos:sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is not enough ectoplasm left to fill it in the bucket.")
	end
	local eggId = egg.itemid
	egg:transform(233)
	addEvent(function()
		local tile = Tile(eggPos)
		local plain = tile and tile:getItemById(233)
		if plain then
			plain:transform(eggId)
		end
	end, math.random(1, 10) * 60 * 1000)
	return true
end

-- The ectoplasm sarcophagi of the tomb (EN: damage and a mummy, a curse and a mummy, or a key).
function D.openSarcophagus(player, position)
	if storage(player, D.S.SarcophagusTime) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The opening of the last sarcophagus still haunts you. Wait some time for your spirits to return.")
		return true
	end
	player:setStorageValue(D.S.SarcophagusTime, os.time() + 30) -- EN: 30 seconds
	local r = math.random(1, 10)
	if r <= 4 then
		local key = player:addItem(29351, 1)
		if key then
			key:decay()
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You found a strangely ornamented key amongst heaps of dust, worthless trinkets and bandages.")
		return true
	end
	Game.createMonster("Mummy", position, true)
	position:sendMagicEffect(CONST_ME_POFF)
	local others = Game.getSpectators(position, false, true, 7, 7, 5, 5)
	if r <= 7 then
		for _, p in ipairs(others) do
			doTargetCombatHealth(0, p, COMBAT_EARTHDAMAGE, -50, -600, CONST_ME_SMALLPLANTS)
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The curse of disturbing this fragile, ancient peace is your price to pay!")
	else
		for _, p in ipairs(others) do
			local curse = Condition(CONDITION_CURSED)
			curse:setParameter(CONDITION_PARAM_DELAYED, true)
			curse:addDamage(10, 2000, -25)
			p:addCondition(curse)
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The curse of disturbing this fragile, ancient peace is your price to pay! You also triggered a trap!")
	end
	return true
end

-- ---------------------------------------------------------------- ward stones by hand, ointment, old lock
-- The eighth stone is used by hand after the Faceless Bane (EN, BR); the talisman works too.
function D.useCathedralStone(player, stone)
	if storage(player, DC.WardStones.CatedralStone) >= 1 then
		return false
	end
	if storage(player, DC.HauntedHouse.Questline) ~= 5 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The ward stone does not react. Something in this cathedral still blocks its power.") -- ours
		return true
	end
	player:setStorageValue(DC.HauntedHouse.Questline, 6)
	player:setStorageValue(DC.WardStones.CatedralStone, 1)
	player:setStorageValue(DC.WardStones.Count, math.max(storage(player, DC.WardStones.Count), 0) + 1)
	D.CATHEDRAL_STONE:sendMagicEffect(CONST_ME_THUNDER)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, D.MSG_SUMMER)
	D.lightStone(D.CATHEDRAL_STONE, D.STONE_SUMMER, D.STONE_SUMMER_LIT)
	return true
end

function D.useOintment(player, toPosition)
	if not toPosition or toPosition ~= D.STONE_DOOR then
		return false
	end
	if storage(player, DC.TheSevenKeys.DoorMedusa) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door is no longer petrified.") -- ours
		return true
	end
	player:setStorageValue(DC.TheSevenKeys.DoorMedusa, 1)
	player:setStorageValue(DC.TheSevenKeys.Count, math.max(storage(player, DC.TheSevenKeys.Count), 0) + 1)
	toPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "As Medusa's Ointment takes effect, the door is unpetrified. You can use it now.")
	return true
end

function D.isOldTable(position)
	for _, p in ipairs(D.OLD_TABLE) do
		if p == position then
			return true
		end
	end
	return false
end

-- A crowbar or a tool on the old table (EN: Secret Agent tool or crowbar).
function D.leverOldLock(player, toPosition)
	if not D.isOldTable(toPosition) then
		return false
	end
	if storage(player, DC.TheSevenKeys.Lock) >= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already removed the old lock.")
		return true
	end
	player:addItem(D.OLD_LOCK, 1)
	player:addItem(D.NAIL, 4)
	player:setStorageValue(DC.TheSevenKeys.Lock, 1)
	toPosition:sendMagicEffect(CONST_ME_POFF)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You lever the old lock out of the door. A few nails fall out as well.") -- ours
	return true
end

-- ---------------------------------------------------------------- the Nightmare Beast's curse
-- EN, BR: shortly after the fight starts one player is cursed: 15 seconds as a spectre, then 10 seconds
-- as a phantasm, then thrown out of the room. Another player takes a dream catcher from the pole in the
-- middle of the room (10 s cooldown, EN) and uses it on the cursed one: the curse moves to him.
D.curse = D.curse or { cid = nil, since = 0, nextAt = 0 }
D.CURSE_SPECTRE, D.CURSE_PHANTASM = 15, 10
D.CURSE_PAUSE = 8 -- ours: seconds before the next curse after one ends
D.MASK_COOLDOWN = 10 -- ours (EN: a cooldown, no number)

local function curseOutfit(player, lookType, seconds)
	local c = Condition(CONDITION_OUTFIT)
	c:setTicks(seconds * 1000)
	c:setOutfit({ lookType = lookType })
	player:addCondition(c)
end

function D.cursePlayer(player, moved)
	D.curse.cid = player:getId()
	D.curse.since = os.time()
	D.curse.phase = 1
	curseOutfit(player, 235, D.CURSE_SPECTRE) -- spectre
	player:getPosition():sendMagicEffect(CONST_ME_SLEEP)
	if not moved then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The beast laid a terrible curse on you!")
	end
end

function D.endCurse(player, thrownOut)
	D.curse.cid = nil
	D.curse.phase = nil
	D.curse.nextAt = os.time() + D.CURSE_PAUSE
	if player then
		player:removeCondition(CONDITION_OUTFIT)
		if thrownOut then
			player:teleportTo(D.BEAST_EXIT)
			D.BEAST_EXIT:sendMagicEffect(CONST_ME_TELEPORT)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The curse overwhelms you and drags you out of the beast's lair.") -- ours
		end
	end
end

-- Called from the beast's think event (about once a second).
function D.curseThink(beast)
	local players = D.playersIn(D.BEAST_ROOM)
	local now = os.time()
	local cursed = D.curse.cid and Player(D.curse.cid)
	if cursed and not D.inRoom(cursed:getPosition(), D.BEAST_ROOM) then
		D.endCurse(cursed, false)
		cursed = nil
	end
	if not cursed then
		if D.curse.cid then
			D.curse.cid = nil
		end
		if #players > 0 and now >= (D.curse.nextAt or 0) then
			D.cursePlayer(players[math.random(1, #players)])
		end
		return
	end
	local elapsed = now - D.curse.since
	if elapsed >= D.CURSE_SPECTRE + D.CURSE_PHANTASM then
		D.endCurse(cursed, true)
	elseif D.curse.phase == 1 and elapsed >= D.CURSE_SPECTRE then
		D.curse.phase = 2
		curseOutfit(cursed, 241, D.CURSE_PHANTASM) -- phantasm
	else
		cursed:getPosition():sendMagicEffect(CONST_ME_SLEEP)
	end
end

function D.resetCurse()
	local cursed = D.curse.cid and Player(D.curse.cid)
	if cursed then
		cursed:removeCondition(CONDITION_OUTFIT)
	end
	D.curse = { cid = nil, since = 0, nextAt = os.time() + 10 } -- EN: "not long after entering"
end

function D.usePole(player, item)
	if item.itemid ~= D.POLE then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The dream catcher pole has to recover first.") -- ours
		return true
	end
	local pos = item:getPosition()
	item:transform(D.POLE_USED)
	local mask = Game.createItem(D.DREAM_CATCHER, 1, Position(pos.x, pos.y + 1, pos.z))
	if mask then
		mask:decay()
		mask:getPosition():sendMagicEffect(CONST_ME_BLOCKHIT)
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You can rip off a dream catcher!")
	addEvent(function()
		local tile = Tile(pos)
		local used = tile and tile:getItemById(D.POLE_USED)
		if used then
			used:transform(D.POLE)
		end
	end, 10 * 1000)
	return true
end

function D.useMask(player, item, target)
	if not target or not target.isPlayer or not target:isPlayer() then
		return false
	end
	if target:getId() == player:getId() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cannot free yourself from the curse.") -- ours (EN: not possible)
		return true
	end
	if D.curse.cid ~= target:getId() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This player is not cursed.") -- ours
		return true
	end
	if storage(player, D.S.MaskTime) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have to wait a moment before you can use a dream catcher again.") -- ours
		return true
	end
	player:setStorageValue(D.S.MaskTime, os.time() + D.MASK_COOLDOWN)
	item:remove(1)
	target:removeCondition(CONDITION_OUTFIT)
	target:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have a feeling of dread.")
	D.cursePlayer(player, true)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take the dreamcurse on yourself!")
	return true
end

-- ---------------------------------------------------------------- the Faceless Bane
-- BR: a player has to step on all 13 iron floors within 15 seconds; then the players have 60 seconds to
-- deal 30,000 damage. Done: it heals completely, becomes invulnerable again and the three spectres
-- appear (the floors work again when they are dead). Failed: it heals completely and the floors work
-- again. The third time 35,000 damage kill it. EN: it heals twice before it dies.
-- Our bosses over 20,000 health have half of it (rateBossHealth, Rodrigo's choice), so a round asks for the
-- same share of the health: 30,000 of 35,000 (6/7).
D.FACELESS_TILES = 13
D.FACELESS_STEP_TIME = 15
D.FACELESS_WINDOW = 60
D.FACELESS_ROUND_SHARE = 30000 / 35000
D.faceless = D.faceless or {}

function D.facelessReset()
	D.faceless = { stepped = {}, firstStep = 0, vulnerableUntil = 0, damage = 0, rounds = 0, spectres = {} }
end
D.facelessReset()

-- A new Faceless Bane starts a new fight (the monster's onSpawn is not reliable for this).
local function facelessEnsure(boss)
	if boss and D.faceless.boss ~= boss:getId() then
		D.facelessReset()
		D.faceless.boss = boss:getId()
	end
	return boss
end

local function facelessBoss()
	for _, c in ipairs(Game.getSpectators(Position(33617, 32562, 13), false, false, 11, 11, 10, 10)) do
		if c:isMonster() and c:getName():lower() == "faceless bane" then
			return facelessEnsure(c)
		end
	end
end

local function spectresAlive()
	for _, cid in ipairs(D.faceless.spectres) do
		if Creature(cid) then
			return true
		end
	end
	return false
end

function D.facelessStep(player, position)
	if not facelessBoss() then
		return
	end
	local f = D.faceless
	if f.vulnerableUntil > os.time() or spectresAlive() then
		return
	end
	local now = os.time()
	if now - f.firstStep > D.FACELESS_STEP_TIME then
		f.stepped = {}
		f.firstStep = now
	end
	local key = position.x .. ":" .. position.y
	if f.stepped[key] then
		return
	end
	f.stepped[key] = true
	position:sendMagicEffect(CONST_ME_YELLOWENERGY)
	local count = 0
	for _ in pairs(f.stepped) do
		count = count + 1
	end
	if count >= D.FACELESS_TILES then
		f.stepped = {}
		f.vulnerableUntil = now + D.FACELESS_WINDOW
		f.damage = 0
		local boss = facelessBoss()
		if boss then
			boss:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
			boss:say("The Faceless Bane is exposed!", TALKTYPE_MONSTER_SAY) -- ours (BR: an energy discharge in the pipes)
		end
	end
end

function D.facelessThink(boss)
	facelessEnsure(boss)
	local f = D.faceless
	if f.vulnerableUntil > 0 and os.time() >= f.vulnerableUntil then
		-- the 60 seconds are over without enough damage: full health, the floors work again
		f.vulnerableUntil = 0
		f.damage = 0
		boss:addHealth(boss:getMaxHealth())
	end
end

-- Returns the damage the boss really takes.
function D.facelessDamage(boss, damage)
	facelessEnsure(boss)
	local f = D.faceless
	if f.vulnerableUntil <= os.time() then
		return 0
	end
	if f.rounds >= 2 then
		return damage -- third round: it can die
	end
	f.damage = f.damage + damage
	if f.damage >= math.floor(boss:getMaxHealth() * D.FACELESS_ROUND_SHARE) or boss:getHealth() - damage <= 1 then
		f.rounds = f.rounds + 1
		f.vulnerableUntil = 0
		f.damage = 0
		local pos = boss:getPosition()
		addEvent(function(cid)
			local b = Creature(cid)
			if b then
				b:addHealth(b:getMaxHealth())
			end
		end, 0, boss:getId())
		f.spectres = {}
		for _, name in ipairs({ "Burster Spectre", "Gazer Spectre", "Ripper Spectre" }) do
			local s = Game.createMonster(name, pos, true, true)
			if s then
				f.spectres[#f.spectres + 1] = s:getId()
			end
		end
		return 0
	end
	return damage
end
