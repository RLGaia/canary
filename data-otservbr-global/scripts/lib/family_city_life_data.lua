-- Gaia Family server: data for the "city life" NPCs (2026-10-13).
--
-- Ours, not upstream. The engine is data-otservbr-global/scripts/family/city_life.lua.
-- Everything here can be tuned freely; restart the server to apply.
-- FAMILY.md ("City life") explains each part.

FamilyCityLife = {
	-- Master switch. false = no city life NPCs at all.
	enabled = true,

	-- Walking NPCs created in each city at server start.
	walkersPerCity = 16,

	-- Vendors per kind (food, potions/runes, creature products). Each one is
	-- placed in a random city at server start and stays there that day.
	vendorsPerKind = 2,

	-- Chance (0-1) that a walker, after reaching a spot, sails to another city.
	travelChance = 0.08,

	-- Minutes a traveller spends "at sea" before appearing at the next harbour.
	travelMinutes = { 2, 5 },

	-- Seconds a walker waits at a spot before moving on.
	idleSeconds = { 8, 40 },

	-- Seconds between random lines a walker says (only when a player is near).
	chatterSeconds = { 45, 150 },
}

-- ---------------------------------------------------------------------------
-- Cities. center: a street tile (floor 7) where the walkable area search
-- starts. radius: how far from the center walkers wander. dock: the ship
-- captain's position; travellers walk to the closest street tile and "sail".
-- ---------------------------------------------------------------------------
FamilyCityLife.cities = {
	{ name = "Thais", center = Position(32369, 32241, 7), radius = 45, dock = Position(32310, 32209, 6) },
	{ name = "Carlin", center = Position(32360, 31782, 7), radius = 40, dock = Position(32387, 31822, 6) },
	{ name = "Venore", center = Position(32957, 32076, 7), radius = 58, dock = Position(32957, 32021, 6) },
	{ name = "Ab'Dendriel", center = Position(32732, 31634, 7), radius = 40, dock = Position(32735, 31670, 6) },
	{ name = "Edron", center = Position(33191, 31790, 7), radius = 40, dock = Position(33175, 31763, 6) },
	{ name = "Darashia", center = Position(33225, 32436, 7), radius = 40, dock = Position(33290, 32481, 6) },
	{ name = "Ankrahmun", center = Position(33197, 32851, 7), radius = 45, dock = Position(33091, 32883, 6) },
	{ name = "Port Hope", center = Position(32594, 32745, 7), radius = 40, dock = Position(32529, 32783, 6) },
	{ name = "Liberty Bay", center = Position(32317, 32826, 7), radius = 40, dock = Position(32286, 32891, 6) },
	{ name = "Svargrond", center = Position(32212, 31132, 7), radius = 35, dock = Position(32341, 31109, 6) },
	{ name = "Yalahar", center = Position(32787, 31276, 7), radius = 45, dock = Position(32818, 31278, 5) },
}

-- ---------------------------------------------------------------------------
-- Names (each NPC gets a unique one; names already used by a real NPC are
-- skipped automatically).
-- ---------------------------------------------------------------------------
FamilyCityLife.maleNames = {
	"Aldric", "Bram", "Cedric", "Dorran", "Halden", "Ivo", "Jorin",
	"Kael", "Lucan", "Magnus", "Nils", "Osric", "Pavel", "Quill", "Roderic", "Sten", "Tobin",
	"Ulric", "Varek", "Wendel", "Yorick", "Zander", "Arno", "Bastian", "Corvin", "Darian", "Emeric",
	"Fenwick", "Gunnar", "Hector", "Isidor", "Jasper", "Konrad", "Leif", "Marek", "Nestor", "Orin",
	"Perrin", "Rafe", "Severin", "Thorin", "Ulf", "Viggo", "Xaver", "Yannick", 
	"Anselm", "Caspian", "Dietrich", "Eamon", "Florian", "Gideon", "Ignatius", "Joachim",
	"Kasimir", "Lorcan", "Matthis", "Niall", "Oswin", "Percival", "Ruben", "Valen",
	"Wolfram", "Alaric", "Benedikt", "Cormac", "Desmond", "Elric", "Fabian", "Godfrey", "Horatio", "Jareth",
	"Tiago", "Mateus", "Davi", "Caio", "Renan", "Otavio", "Murilo", "Heitor",
	"Aurel", "Baldric", "Cassius", "Evander", "Finnian", "Galen", "Hadrian", "Ingram", "Jory", "Kellan",
	"Lysander", "Merrick", "Nolan", "Oberon", "Piers", "Ronan", "Soren", "Tamsin", "Ulrich", "Vance",
	"Warrick", "Brennan", "Cyril", "Dmitri", "Elias", "Fritjof", "Gustav", "Henrik", "Ansgar", "Bjarke",
	"Calder", "Dagfinn", "Erland",
}

FamilyCityLife.femaleNames = {
	"Adela", "Brina", "Cora", "Dalia", "Elsbeth", "Freya", "Greta", "Helka", "Ilsa", "Jorunn",
	"Kaia", "Liesel", "Mirela", "Nadja", "Odile", "Petra", "Rowena", "Signe", "Talia", "Ursa",
	"Vala", "Wilma", "Ysolde", "Alwen", "Berit", "Celia", "Dagny", "Elowen", "Fiora",
	"Gisela", "Hedda", "Imke", "Jessa", "Karin", "Linnea", "Maren", "Nora", "Oda", "Pia",
	"Runa", "Saskia", "Tove", "Una", "Vesna", "Wenna", "Alma", "Brigid", "Calla", "Dorte",
	"Edda", "Frida", "Gwen", "Hilde", "Inga", "Juna", "Kirsa", "Lotte", "Mila", "Nell",
	"Orla", "Pernille", "Rikke", "Solvi", "Thea", "Ylva", "Amara", "Bettina", "Clarissa", "Delphine",
	"Elodie", "Fenella", "Giselle", "Honora", "Jolene", "Katrin", "Lavinia", "Marisol", "Ninette",
	"Bianca", "Luana", "Yara", "Iara", "Lia", "Ayla", "Celeste", "Helena", "Livia",
	"Annika", "Brenna", "Cecily", "Daria", "Esme", "Fallon", "Gemma", "Hanne", "Ingrid", "Jutta",
	"Kalina", "Lenore", "Meike", "Nerys", "Ottilie", "Phoebe", "Rosalind", "Selma", "Ulla", "Verena",
	"Wynne", "Xenia", "Yvaine", "Zelda", "Aveline", "Branwen", "Carys", "Dunja", "Eira", "Fenna",
	"Gudrun", "Hella", "Ines", "Jana",
}

-- Player outfits (look types) the walkers wear, with random colours/addons.
FamilyCityLife.maleOutfits = { 128, 129, 130, 131, 132, 133, 134, 143, 144, 145, 146, 151, 152, 154, 251, 268, 273, 278, 289, 325 }
FamilyCityLife.femaleOutfits = { 136, 137, 138, 139, 140, 141, 142, 147, 148, 149, 150, 155, 156, 158, 252, 269, 270, 279, 288, 324 }

-- What walkers say they do (answer to "job").
FamilyCityLife.jobs = {
	"I'm an adventurer, like you. Mostly I hunt and sell what I find.",
	"I trade a bit between the cities. Ships are faster than walking, believe me.",
	"I'm a hunter. Wolves, bears, the occasional troll.",
	"I study magic, when I'm not out of mana.",
	"I'm saving gold for a house. Someday!",
	"I'm a knight in training. My shield arm still hurts.",
	"I collect stories about old quests. Ask me for a {tip}!",
	"I just arrived by ship. Still finding my way around.",
	"I'm on my way to the depot. Again.",
	"Fishing, mostly. And complaining about the weather.",
}

-- Random lines walkers say near players. {city} is replaced by the city name.
FamilyCityLife.chatter = {
	"Anyone selling dragon ham?",
	"I need more mana potions...",
	"Have you seen the boosted creature today?",
	"Rats again! Somebody call the guards.",
	"I heard a rare creature was spotted outside {city}.",
	"Never trust a fox wearing a nose ring.",
	"My backpack is full of junk again.",
	"Does anyone know the way to the depot?",
	"The ship leaves soon, I'd better hurry.",
	"I lost all my loot to a monster trap. Never again!",
	"Exercise weapons from the store never break here, did you know?",
	"Bosses come back after only an hour around here.",
	"I love {city} at this time of day.",
	"Hm, what was the word for the Djinn again...",
	"One day I'll open all four chests of the Annihilator!",
	"Rashid buys almost anything. Check where he is today.",
	"Ask me for a {tip} if you're bored.",
	"*yawns*",
	"I should buy some food before I go hunting.",
	"These boots are killing me.",
}

FamilyCityLife.cityChatter = {
	["Thais"] = { "The king's guards look grumpy today.", "The Thieves Guild is closer than you think..." },
	["Carlin"] = { "The girls brigade is looking for recruits.", "Carlin's flowers smell wonderful." },
	["Venore"] = { "Venore's swamps stink, but the trade is good.", "Watch out for the swamp trolls." },
	["Ab'Dendriel"] = { "The elves keep to themselves.", "Careful with the wasps north of here." },
	["Edron"] = { "The Academy scholars never sleep.", "I heard of demons deep below the island." },
	["Darashia"] = { "The Caliph's palace is breathtaking.", "Djinn fortresses are out in the desert." },
	["Ankrahmun"] = { "The pharaoh's tombs give me the chills.", "Sand everywhere. In my boots, in my bread..." },
	["Port Hope"] = { "The jungle is full of apes and worse.", "The Explorer Society meets right here in town." },
	["Liberty Bay"] = { "Pirates! Well... former pirates.", "The Shattered Isles are not far from here." },
	["Svargrond"] = { "Did you pass the Barbarian Test yet?", "Brrr. Mead helps against the cold." },
	["Yalahar"] = { "Yalahar's quarters are a maze.", "The mages of Yalahar are up to something." },
}

-- ---------------------------------------------------------------------------
-- Quest tips. Each tip shows when the player's level is at least minLevel,
-- and is skipped once the quest has started (started() returns true).
-- Where-to-go text was taken from the NPC positions in
-- world/otservbr-npc.xml (direction from the temple) and the keywords from
-- the NPC scripts, so it matches this server.
-- ---------------------------------------------------------------------------
local function storageAtLeast(key, value)
	return function(player)
		return key ~= nil and player:getStorageValue(key) >= value
	end
end

local Q = Storage.Quest

FamilyCityLife.tips = {
	{
		minLevel = 8,
		text = "Bozo, the jester in the Thais castle north-west of the temple, runs the fools guild. Say {join} to him for 'What a Foolish Quest'.",
		started = storageAtLeast(Q.U8_1.WhatAFoolishQuest.Questline, 1),
	},
	{
		minLevel = 15,
		text = "The postmen guild has its office in the mountains south-west of Kazordoon, one floor up. Ask Kevin for a {mission} and you'll travel all of Tibia.",
		started = storageAtLeast(Q.U7_24.ThePostmanMissions.Mission01, 1),
	},
	{
		minLevel = 15,
		text = "Dorian runs the Thieves Guild in the basement north-west of the Thais temple. Say {join}, then ask for a {mission}.",
		started = storageAtLeast(Q.U8_2.TheThievesGuildQuest.Questline, 1),
	},
	{
		minLevel = 20,
		text = "Angus of the Explorer Society lives in the east of Port Hope. Say {join} and he will send you around the world.",
		started = storageAtLeast(Q.U7_6.ExplorerSociety.QuestLine, 1),
	},
	{
		minLevel = 20,
		text = "Old Melchior lives in the desert north-west of Ankrahmun. Ask him about the {word of greeting} to talk to the Djinns. Here you can serve both the blue and the green Djinns!",
		started = storageAtLeast(Q.U7_4.DjinnWar.Factions, 1),
	},
	{
		minLevel = 20,
		text = "In Svargrond, Sven south-west of the temple holds the Barbarian Test. Ask him about becoming a {barbarian}; it opens the Ice Islands and the arena.",
		started = storageAtLeast(Q.U8_0.BarbarianTest.Questline, 1),
	},
	{
		minLevel = 25,
		text = "Grizzly Adams, east of the Port Hope temple and one floor up, gives hunting tasks. Say {join}, then ask for a {task}. The rewards are great.",
		started = storageAtLeast(Q.U8_5.KillingInTheNameOf.QuestLogEntry, 0),
	},
	{
		minLevel = 30,
		text = "After the Barbarian Test, Iskan the musher north-east of Svargrond has a {mission} for you: the start of the Ice Islands quest.",
		started = storageAtLeast(Q.U8_0.TheIceIslands.Questline, 1),
	},
	{
		minLevel = 30,
		text = "Halvar runs the Svargrond arena, north-east of the temple. Ask him about the {arena}. Each level gives a weapon reward, and here you may take all of them.",
		started = storageAtLeast(Q.U8_0.BarbarianArena.QuestLogGreenhorn, 1),
	},
	{
		minLevel = 35,
		text = "Kazzan, in the palace north of the Darashia temple, wants peace with the Djinns. Ask him for a {mission}.",
		started = storageAtLeast(Q.U8_1.TibiaTales.ToAppeaseTheMightyQuest, 1),
	},
	{
		minLevel = 40,
		text = "Three secret services recruit agents: Chester Kahs in Thais (north of the temple, upstairs), Emma in Carlin (east of the temple, upstairs) and Uncle in Venore (north, three floors up). Say {join}. Here you can serve all three, one after another, and each pays with a little multi-tool.",
		started = storageAtLeast(Q.U8_1.SecretService.Quest, 1),
	},
	{
		minLevel = 40,
		text = "Eleonore in Liberty Bay, north of the temple and two floors up, has a {mission} that leads to the Shattered Isles and the pirates.",
		started = storageAtLeast(Q.U7_8.TheShatteredIsles.DefaultStart, 1),
	},
	{
		minLevel = 50,
		text = "Hairycles, the ape shaman far north-east of Port Hope, needs a friend. Ask him for a {mission}: the Ape City quest.",
		started = storageAtLeast(Q.U7_6.TheApeCity.Started, 1),
	},
	{
		minLevel = 50,
		text = "The famous cook Jean Pierre lives south-west of Darashia, one floor up. Ask him to {cook} and about becoming his {apprentice}.",
		started = storageAtLeast(Q.U8_5.HotCuisineQuest.QuestStart, 1),
	},
	{
		minLevel = 60,
		text = "Spectulus works at the top of the Edron academy, east of the temple. Ask him for a {mission}: the Sea of Light.",
		started = storageAtLeast(Q.U8_54.SeaOfLight.Questline, 1),
	},
	{
		minLevel = 60,
		text = "Oldrak lives in a tower on the plains south-west of Venore. Ask him about {hugo}, then about the {myth}: the Paradox Tower.",
		started = storageAtLeast(Q.U7_24.TheParadoxTower.QuestLine, 1),
	},
	{
		minLevel = 100,
		text = "The Annihilator is deep under the north of Edron. You need level 100 for the lever; here one player is enough, and you may open all four reward chests.",
		started = storageAtLeast(Q.U7_24.TheAnnihilator.Reward, 1),
	},
	{
		minLevel = 100,
		text = "Henricus leads the Inquisition, in the basement south-west of the Thais temple. Ask for a {mission} and agree to join. Here you may open every chest of the final reward room.",
		started = storageAtLeast(Q.U8_2.TheInquisitionQuest.Questline, 1),
	},
	{
		minLevel = 120,
		text = "Ask Oldrak (tower on the plains south-west of Venore) about the {demon oak}. You need level 120 to enter its grounds, and here you may open every reward chest.",
		started = storageAtLeast(Q.U8_2.TheDemonOak.Progress, 1),
	},
	{
		minLevel = 250,
		text = "The Soul War starts with the Flickering Soul, deep underground south-east of Gray Beach. Ask about the {task}; you need level 250. Here the final chest gives a new Soul item after every win, or once a day.",
		started = function(player)
			return player:soulWarQuestKV():get("teleport-access") == true
		end,
	},
}

-- Tips shown when no quest tip fits (also mixed in now and then).
FamilyCityLife.serverTips = {
	"Exercise weapons from the Store never run out on this server, and training is twice as fast.",
	"Dying here only sends you back to the temple. No experience or items lost!",
	"Bosses can be fought again after one hour, and one player is enough for every boss lever.",
	"Rare creatures and raids come back about every half hour.",
	"Offline training works even while the server is off. Log out on a training statue.",
	"Auto-loot and auto-bank are on. Your gold goes straight to the bank.",
	"Rashid buys almost any loot. Ask me for {news} to know where he is today.",
}

-- Rashid's route, from scripts/globalevents/spawn/rashid.lua (os.date wday 1 = Sunday).
FamilyCityLife.rashidCity = { "Carlin", "Svargrond", "Liberty Bay", "Port Hope", "Ankrahmun", "Darashia", "Edron" }

-- ---------------------------------------------------------------------------
-- Vendors. Each kind has a title, how many random items it offers per server
-- start (alwaysItems are always offered), and its lists below.
-- ---------------------------------------------------------------------------
FamilyCityLifeStock = {}

FamilyCityLife.vendorKinds = {
	{ key = "food", title = "food seller", greeting = "Fresh food! Fruits, fish, ham... Want to {trade}?", stock = "food", randomCount = 14 },
	{ key = "potions", title = "potion and rune seller", greeting = "Potions and runes for the brave! Want to {trade}?", stock = "potions", always = "potions", randomFrom = "runes", randomCount = 16 },
	{ key = "creatures", title = "creature products trader", greeting = "Teeth, claws, scales and furs, for imbuements and addons. Want to {trade}?", stock = "creatureProducts", randomCount = 30 },
}

-- Food: prices are the cheapest NPC price in this datapack.
FamilyCityLifeStock.food = {
	{ itemName = "aubergine", clientId = 11460, buy = 8 },
	{ itemName = "banana", clientId = 3587, buy = 2 },
	{ itemName = "beetroot", clientId = 8017, buy = 2 },
	{ itemName = "blueberry", clientId = 3588, buy = 1 },
	{ itemName = "bread", clientId = 3600, buy = 2 },
	{ itemName = "broccoli", clientId = 11461, buy = 3 },
	{ itemName = "brown bread", clientId = 3602, buy = 3 },
	{ itemName = "brown mushroom", clientId = 3725, buy = 10 },
	{ itemName = "bulb of garlic", clientId = 8197, buy = 3 },
	{ itemName = "cake", clientId = 6277, buy = 1 },
	{ itemName = "carrot", clientId = 3595, buy = 2 },
	{ itemName = "cauliflower", clientId = 11462, buy = 4 },
	{ itemName = "cheese", clientId = 3607, buy = 4 },
	{ itemName = "cherry", clientId = 3590, buy = 1 },
	{ itemName = "coconut", clientId = 3589, buy = 8 },
	{ itemName = "cookie", clientId = 3598, buy = 2 },
	{ itemName = "corncob", clientId = 3597, buy = 3 },
	{ itemName = "cucumber", clientId = 8014, buy = 3 },
	{ itemName = "dragon ham", clientId = 3583, buy = 25 },
	{ itemName = "dragonfruit", clientId = 11682, buy = 5 },
	{ itemName = "egg", clientId = 3606, buy = 2 },
	{ itemName = "fish", clientId = 3578, buy = 5 },
	{ itemName = "grapes", clientId = 3592, buy = 3 },
	{ itemName = "ham", clientId = 3582, buy = 5 },
	{ itemName = "ice cream cone", clientId = 229, buy = 10 },
	{ itemName = "jalapeno pepper", clientId = 8016, buy = 2 },
	{ itemName = "lemon", clientId = 8013, buy = 3 },
	{ itemName = "mango", clientId = 5096, buy = 8 },
	{ itemName = "meat", clientId = 3577, buy = 3 },
	{ itemName = "melon", clientId = 3593, buy = 8 },
	{ itemName = "onion", clientId = 8015, buy = 2 },
	{ itemName = "orange", clientId = 3586, buy = 5 },
	{ itemName = "pear", clientId = 3584, buy = 4 },
	{ itemName = "peas", clientId = 11683, buy = 2 },
	{ itemName = "pineapple", clientId = 11459, buy = 14 },
	{ itemName = "plum", clientId = 8011, buy = 3 },
	{ itemName = "potato", clientId = 8010, buy = 4 },
	{ itemName = "pumpkin", clientId = 3594, buy = 10 },
	{ itemName = "raspberry", clientId = 8012, buy = 1 },
	{ itemName = "red apple", clientId = 3585, buy = 3 },
	{ itemName = "red mushroom", clientId = 3724, buy = 12 },
	{ itemName = "roll", clientId = 3601, buy = 2 },
	{ itemName = "salmon", clientId = 3579, buy = 4 },
	{ itemName = "strawberry", clientId = 3591, buy = 1 },
	{ itemName = "tomato", clientId = 3596, buy = 3 },
	{ itemName = "white mushroom", clientId = 3723, buy = 6 },
}
-- Potions (always sold) and runes (a random part each start); cheapest NPC price.
FamilyCityLifeStock.potions = {
	{ itemName = "small health potion", clientId = 7876, buy = 20 },
	{ itemName = "health potion", clientId = 266, buy = 50 },
	{ itemName = "antidote potion", clientId = 7644, buy = 50 },
	{ itemName = "mana potion", clientId = 268, buy = 56 },
	{ itemName = "strong mana potion", clientId = 237, buy = 108 },
	{ itemName = "strong health potion", clientId = 236, buy = 115 },
	{ itemName = "great mana potion", clientId = 238, buy = 158 },
	{ itemName = "great health potion", clientId = 239, buy = 225 },
	{ itemName = "great spirit potion", clientId = 7642, buy = 254 },
	{ itemName = "ultimate health potion", clientId = 7643, buy = 379 },
	{ itemName = "ultimate mana potion", clientId = 23373, buy = 488 },
	{ itemName = "ultimate spirit potion", clientId = 23374, buy = 488 },
	{ itemName = "supreme health potion", clientId = 23375, buy = 650 },
}
FamilyCityLifeStock.runes = {
	{ itemName = "light magic missile rune", clientId = 3174, buy = 4 },
	{ itemName = "heavy magic missile rune", clientId = 3198, buy = 12 },
	{ itemName = "stalagmite rune", clientId = 3179, buy = 12 },
	{ itemName = "destroy field rune", clientId = 3148, buy = 15 },
	{ itemName = "holy missile rune", clientId = 3182, buy = 16 },
	{ itemName = "poison field rune", clientId = 3172, buy = 21 },
	{ itemName = "desintegrate rune", clientId = 3197, buy = 26 },
	{ itemName = "fire field rune", clientId = 3188, buy = 28 },
	{ itemName = "fireball rune", clientId = 3189, buy = 30 },
	{ itemName = "icicle rune", clientId = 3158, buy = 30 },
	{ itemName = "explosion rune", clientId = 3200, buy = 31 },
	{ itemName = "energy field rune", clientId = 3164, buy = 38 },
	{ itemName = "stone shower rune", clientId = 3175, buy = 41 },
	{ itemName = "soulfire rune", clientId = 3195, buy = 46 },
	{ itemName = "poison wall rune", clientId = 3176, buy = 52 },
	{ itemName = "thunderstorm rune", clientId = 3202, buy = 52 },
	{ itemName = "fire wall rune", clientId = 3190, buy = 61 },
	{ itemName = "avalanche rune", clientId = 3161, buy = 64 },
	{ itemName = "great fireball rune", clientId = 3191, buy = 64 },
	{ itemName = "cure poison rune", clientId = 3153, buy = 65 },
	{ itemName = "convince creature rune", clientId = 3177, buy = 80 },
	{ itemName = "energy wall rune", clientId = 3166, buy = 85 },
	{ itemName = "poison bomb rune", clientId = 3173, buy = 85 },
	{ itemName = "intense healing rune", clientId = 3152, buy = 95 },
	{ itemName = "magic wall rune", clientId = 3180, buy = 116 },
	{ itemName = "fire bomb rune", clientId = 3192, buy = 147 },
	{ itemName = "wild growth rune", clientId = 3156, buy = 160 },
	{ itemName = "sudden death rune", clientId = 3155, buy = 162 },
	{ itemName = "ultimate healing rune", clientId = 3160, buy = 175 },
	{ itemName = "energy bomb rune", clientId = 3149, buy = 203 },
	{ itemName = "chameleon rune", clientId = 3178, buy = 210 },
	{ itemName = "animate dead rune", clientId = 3203, buy = 375 },
	{ itemName = "paralyze rune", clientId = 3165, buy = 700 },
}
-- Creature products: imbuement materials and addon/quest materials.
-- Price: 1.5x the best NPC buy-back price (rounded to 5), so hunting still pays.
FamilyCityLifeStock.creatureProducts = {
	{ itemName = "ape fur", clientId = 5883, buy = 180 }, -- addon/quest, NPCs pay 120
	{ itemName = "bat wing", clientId = 5894, buy = 75 }, -- addon/quest, NPCs pay 50
	{ itemName = "battle stone", clientId = 11447, buy = 435 }, -- imbuement, NPCs pay 290
	{ itemName = "bear paw", clientId = 5896, buy = 150 }, -- addon/quest, NPCs pay 100
	{ itemName = "behemoth claw", clientId = 5930, buy = 3000 }, -- addon/quest, NPCs pay 2000
	{ itemName = "black wool", clientId = 11448, buy = 450 }, -- addon/quest, NPCs pay 300
	{ itemName = "blazing bone", clientId = 16131, buy = 915 }, -- imbuement, NPCs pay 610
	{ itemName = "bloody pincers", clientId = 9633, buy = 150 }, -- imbuement, NPCs pay 100
	{ itemName = "brimstone fangs", clientId = 11702, buy = 570 }, -- imbuement, NPCs pay 380
	{ itemName = "brimstone shell", clientId = 11703, buy = 315 }, -- imbuement, NPCs pay 210
	{ itemName = "broken shamanic staff", clientId = 11452, buy = 50 }, -- imbuement, NPCs pay 35
	{ itemName = "chicken feather", clientId = 5890, buy = 45 }, -- addon/quest, NPCs pay 30
	{ itemName = "compass", clientId = 10302, buy = 70 }, -- imbuement, NPCs pay 45
	{ itemName = "crawler head plating", clientId = 14079, buy = 315 }, -- imbuement, NPCs pay 210
	{ itemName = "crystallized anger", clientId = 23507, buy = 600 }, -- imbuement, NPCs pay 400
	{ itemName = "cultish mask", clientId = 9638, buy = 420 }, -- imbuement, NPCs pay 280
	{ itemName = "cultish robe", clientId = 9639, buy = 225 }, -- imbuement, NPCs pay 150
	{ itemName = "cyclops toe", clientId = 9657, buy = 80 }, -- imbuement, NPCs pay 55
	{ itemName = "damselfly wing", clientId = 17458, buy = 30 }, -- imbuement, NPCs pay 20
	{ itemName = "deepling warts", clientId = 14012, buy = 270 }, -- imbuement, NPCs pay 180
	{ itemName = "demon dust", clientId = 5526, buy = 450 }, -- addon/quest, NPCs pay 300
	{ itemName = "demon horn", clientId = 5954, buy = 1500 }, -- imbuement, NPCs pay 1000
	{ itemName = "demonic skeletal hand", clientId = 9647, buy = 120 }, -- imbuement, NPCs pay 80
	{ itemName = "draken sulphur", clientId = 11658, buy = 825 }, -- imbuement, NPCs pay 550
	{ itemName = "elven hoof", clientId = 18994, buy = 170 }, -- imbuement, NPCs pay 115
	{ itemName = "elven scouting glass", clientId = 11464, buy = 75 }, -- imbuement, NPCs pay 50
	{ itemName = "elvish talisman", clientId = 9635, buy = 70 }, -- imbuement, NPCs pay 45
	{ itemName = "energy vein", clientId = 23508, buy = 405 }, -- imbuement, NPCs pay 270
	{ itemName = "fairy wings", clientId = 25694, buy = 300 }, -- imbuement, NPCs pay 200
	{ itemName = "fiery heart", clientId = 9636, buy = 560 }, -- imbuement, NPCs pay 375
	{ itemName = "fish fin", clientId = 5895, buy = 225 }, -- addon/quest, NPCs pay 150
	{ itemName = "frazzle skin", clientId = 20199, buy = 600 }, -- imbuement, NPCs pay 400
	{ itemName = "frosty heart", clientId = 9661, buy = 420 }, -- imbuement, NPCs pay 280
	{ itemName = "ghostly tissue", clientId = 9690, buy = 135 }, -- imbuement, NPCs pay 90
	{ itemName = "gloom wolf fur", clientId = 22007, buy = 105 }, -- imbuement, NPCs pay 70
	{ itemName = "goblin ear", clientId = 11539, buy = 30 }, -- addon/quest, NPCs pay 20
	{ itemName = "gold-brocaded cloth", clientId = 40529, buy = 260 }, -- imbuement, NPCs pay 175
	{ itemName = "goosebump leather", clientId = 20205, buy = 975 }, -- imbuement, NPCs pay 650
	{ itemName = "green dragon leather", clientId = 5877, buy = 150 }, -- imbuement, NPCs pay 100
	{ itemName = "green dragon scale", clientId = 5920, buy = 150 }, -- imbuement, NPCs pay 100
	{ itemName = "hardened bone", clientId = 5925, buy = 105 }, -- addon/quest, NPCs pay 70
	{ itemName = "hellspawn tail", clientId = 10304, buy = 710 }, -- imbuement, NPCs pay 475
	{ itemName = "honeycomb", clientId = 5902, buy = 60 }, -- addon/quest, NPCs pay 40
	{ itemName = "hydra head", clientId = 10282, buy = 900 }, -- addon/quest, NPCs pay 600
	{ itemName = "lion's mane", clientId = 9691, buy = 90 }, -- imbuement, NPCs pay 60
	{ itemName = "little bowl of myrrh", clientId = 25702, buy = 750 }, -- imbuement, NPCs pay 500
	{ itemName = "lizard leather", clientId = 5876, buy = 225 }, -- addon/quest, NPCs pay 150
	{ itemName = "lizard scale", clientId = 5881, buy = 180 }, -- addon/quest, NPCs pay 120
	{ itemName = "mammoth tusk", clientId = 10321, buy = 150 }, -- addon/quest, NPCs pay 100
	{ itemName = "mantassin tail", clientId = 11489, buy = 420 }, -- imbuement, NPCs pay 280
	{ itemName = "metal spike", clientId = 10298, buy = 480 }, -- imbuement, NPCs pay 320
	{ itemName = "minotaur leather", clientId = 5878, buy = 120 }, -- addon/quest, NPCs pay 80
	{ itemName = "mooh'tah shell", clientId = 21202, buy = 165 }, -- imbuement, NPCs pay 110
	{ itemName = "moohtant horn", clientId = 21200, buy = 210 }, -- imbuement, NPCs pay 140
	{ itemName = "mystical hourglass", clientId = 9660, buy = 1050 }, -- imbuement, NPCs pay 700
	{ itemName = "nose ring", clientId = 5804, buy = 3000 }, -- addon/quest, NPCs pay 2000
	{ itemName = "ogre nose ring", clientId = 22189, buy = 315 }, -- imbuement, NPCs pay 210
	{ itemName = "orc leather", clientId = 11479, buy = 45 }, -- addon/quest, NPCs pay 30
	{ itemName = "orc tooth", clientId = 10196, buy = 225 }, -- imbuement, NPCs pay 150
	{ itemName = "peacock feather fan", clientId = 21975, buy = 525 }, -- imbuement, NPCs pay 350
	{ itemName = "perfect behemoth fang", clientId = 5893, buy = 375 }, -- addon/quest, NPCs pay 250
	{ itemName = "petrified scream", clientId = 10420, buy = 375 }, -- imbuement, NPCs pay 250
	{ itemName = "piece of dead brain", clientId = 9663, buy = 630 }, -- imbuement, NPCs pay 420
	{ itemName = "piece of scarab shell", clientId = 9641, buy = 70 }, -- imbuement, NPCs pay 45
	{ itemName = "piece of swampling wood", clientId = 17823, buy = 45 }, -- imbuement, NPCs pay 30
	{ itemName = "pile of grave earth", clientId = 11484, buy = 40 }, -- imbuement, NPCs pay 25
	{ itemName = "poisonous slime", clientId = 9640, buy = 75 }, -- imbuement, NPCs pay 50
	{ itemName = "polar bear paw", clientId = 9650, buy = 45 }, -- imbuement, NPCs pay 30
	{ itemName = "protective charm", clientId = 11444, buy = 90 }, -- imbuement, NPCs pay 60
	{ itemName = "quill", clientId = 28567, buy = 1650 }, -- imbuement, NPCs pay 1100
	{ itemName = "red dragon leather", clientId = 5948, buy = 300 }, -- addon/quest, NPCs pay 200
	{ itemName = "red dragon scale", clientId = 5882, buy = 300 }, -- addon/quest, NPCs pay 200
	{ itemName = "rope belt", clientId = 11492, buy = 100 }, -- imbuement, NPCs pay 66
	{ itemName = "rorc feather", clientId = 18993, buy = 105 }, -- imbuement, NPCs pay 70
	{ itemName = "sabretooth", clientId = 10311, buy = 600 }, -- imbuement, NPCs pay 400
	{ itemName = "seacrest hair", clientId = 21801, buy = 390 }, -- imbuement, NPCs pay 260
	{ itemName = "silencer claws", clientId = 20200, buy = 585 }, -- imbuement, NPCs pay 390
	{ itemName = "slime heart", clientId = 21194, buy = 240 }, -- imbuement, NPCs pay 160
	{ itemName = "snake skin", clientId = 9694, buy = 600 }, -- imbuement, NPCs pay 400
	{ itemName = "sniper gloves", clientId = 5875, buy = 3000 }, -- addon/quest, NPCs pay 2000
	{ itemName = "some grimeleech wings", clientId = 22730, buy = 1800 }, -- imbuement, NPCs pay 1200
	{ itemName = "spider silk", clientId = 5879, buy = 150 }, -- addon/quest, NPCs pay 100
	{ itemName = "strand of medusa hair", clientId = 10309, buy = 900 }, -- imbuement, NPCs pay 600
	{ itemName = "swamp grass", clientId = 9686, buy = 30 }, -- imbuement, NPCs pay 20
	{ itemName = "tarantula egg", clientId = 10281, buy = 120 }, -- imbuement, NPCs pay 80
	{ itemName = "thick fur", clientId = 10307, buy = 225 }, -- imbuement, NPCs pay 150
	{ itemName = "turtle shell", clientId = 5899, buy = 135 }, -- addon/quest, NPCs pay 90
	{ itemName = "vampire dust", clientId = 5905, buy = 150 }, -- addon/quest, NPCs pay 100
	{ itemName = "vampire teeth", clientId = 9685, buy = 410 }, -- imbuement, NPCs pay 275
	{ itemName = "vexclaw talon", clientId = 22728, buy = 1650 }, -- imbuement, NPCs pay 1100
	{ itemName = "war crystal", clientId = 9654, buy = 690 }, -- imbuement, NPCs pay 460
	{ itemName = "warmaster's wristguards", clientId = 10405, buy = 300 }, -- imbuement, NPCs pay 200
	{ itemName = "waspoid wing", clientId = 14081, buy = 285 }, -- imbuement, NPCs pay 190
	{ itemName = "wereboar hooves", clientId = 22053, buy = 260 }, -- imbuement, NPCs pay 175
	{ itemName = "winter wolf fur", clientId = 10295, buy = 30 }, -- imbuement, NPCs pay 20
	{ itemName = "wolf paw", clientId = 5897, buy = 105 }, -- addon/quest, NPCs pay 70
	{ itemName = "wyrm scale", clientId = 9665, buy = 600 }, -- imbuement, NPCs pay 400
	{ itemName = "wyvern talisman", clientId = 9644, buy = 400 }, -- imbuement, NPCs pay 265
}
