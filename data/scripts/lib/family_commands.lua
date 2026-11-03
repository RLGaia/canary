-- FAMILY: Gaia Family server, help for the chat commands (2026-11-03, asked by Rodrigo).
-- Why: upstream !commands only listed the command names (almost none had a
-- description), so it was not clear what a command is for or how to type it.
-- This file is the help text: for each command what it does, how to type it,
-- examples and notes. data/scripts/family/commands_help.lua shows it
-- (!commands, !help, !commands <name>). A command that is registered but not
-- in this list still shows up, under "Other commands".
--
-- Entry fields:
--   words    the command and its aliases (as registered)
--   page     "player", "gm", "god" or "tests" (the list page it is shown on)
--   topic    heading on the list page
--   short    one line for the list page
--   about    what it does (detail page; defaults to short)
--   use      how to type it (one line per form)
--   ex       examples: { "what to type", "what happens" }
--   notes    good to know
--   see      related commands
--   on       function returning false when the server config switches it off
--   offWhy   why it does nothing on our server (shown when on() is false)

FamilyCommands = FamilyCommands or {}
local C = FamilyCommands

C.pages = {
	{ key = "player", title = "Commands for everyone", minType = 1 },
	{ key = "gm", title = "Gamemaster commands", minType = 4 },
	{ key = "god", title = "GOD commands", minType = 6 },
	{ key = "tests", title = "Test and developer commands (GOD)", minType = 4 },
}

C.list = {}

local function add(entry)
	C.list[#C.list + 1] = entry
end

local function cfgBool(key)
	return function()
		return configKeys[key] ~= nil and configManager.getBoolean(configKeys[key])
	end
end

-- ===================================================================== player

add({
	words = { "!commands" },
	page = "player",
	topic = "Help",
	short = "this help: the list, or how to use one command",
	use = { "!commands", "!commands <command>", "!commands <word>" },
	ex = {
		{ "!commands", "the list of commands you can use" },
		{ "!commands transfer", "how to use !transfer, with examples" },
		{ "!commands gold", "every command whose help talks about gold" },
	},
	notes = { "You can leave out the ! or / of the command: !commands deposit." },
	see = { "!help" },
})

add({
	words = { "!help" },
	page = "player",
	topic = "Help",
	short = "same as !commands",
	use = { "!help", "!help <command>" },
	ex = { { "!help bless", "how to use !bless" } },
	see = { "!commands" },
})

add({
	words = { "!house", "!houses" },
	page = "player",
	topic = "Houses",
	short = "house guide: buying, rent, house spells, your houses",
	about = "Shows a guide to houses: how to buy one, the rent, the commands and the house spells (guest list, door list, kick), and for each house you own the rent and the date it is paid until.",
	use = { "!house" },
	ex = { { "!house", "opens the guide" } },
	see = { "!buyhouse", "!leavehouse", "!sellhouse" },
})

add({
	words = { "!buyhouse" },
	page = "player",
	topic = "Houses",
	short = "buy the house whose door you are facing",
	about = "Buys a free house at once. Stand on the square just outside the house door, facing the door, and type the command. The price is the house's rent, paid once (gold you carry first, then the bank). After that the same rent is taken from your bank every 30 days.",
	use = { "!buyhouse" },
	ex = { { "!buyhouse", "(outside the door, facing it) the house is yours" } },
	notes = {
		"You can also buy in the Cyclopedia: Houses, pick the house, Bid.",
		"No limit on how many houses you own.",
		"You learn the house spells: aleta sio (guests), aleta som (subowners), aleta grav (door list), alana sio (kick).",
	},
	see = { "!house", "!leavehouse" },
})

add({
	words = { "!leavehouse" },
	page = "player",
	topic = "Houses",
	short = "give up the house you are standing in",
	about = "Gives up your house. Stand inside it and type the command. The house becomes free at the next server start; what was inside goes to your depot. No money back.",
	use = { "!leavehouse" },
	ex = { { "!leavehouse", "(inside your house) it is free again after the next restart" } },
	see = { "!house", "!sellhouse" },
})

add({
	words = { "!sellhouse" },
	page = "player",
	topic = "Houses",
	short = "pass your house to another player (trade window)",
	about = "Offers the house you stand in to another player. A trade window opens with the house deed; when both accept, the house changes owner at the next server start.",
	use = { "!sellhouse <player name>" },
	ex = { { "!sellhouse Bob", "(inside your house, Bob next to you) the trade window opens" } },
	notes = { "The other player must be online and close to you.", "Refused if that player already owns a house (engine rule)." },
	see = { "!house", "!leavehouse" },
})

add({
	words = { "!promotion", "!promotions" },
	page = "player",
	topic = "Your character",
	short = "your promotion, its bonuses and the next ones",
	about = "Shows your promotion title, the bonuses it gives, the next promotion (level and price) and the full list. Promotions after level 20 are bought from the kings and queens (King Tibianus, Queen Eloise, Emperor Kruzak, Emperor Rehal, Ishebad, Enpa Rudra): say promotion, then yes.",
	use = { "!promotion" },
	ex = { { "!promotion", "opens the promotion guide" } },
})

add({
	words = { "!mounts", "!mount" },
	page = "player",
	topic = "Your character",
	short = "your mounts and the terrain where each is faster",
	about = "Lists your mounts with their terrains (where each one is faster) and what you get on the ground where you stand now.",
	use = { "!mounts" },
	ex = { { "!mounts", "the list of your mounts and their terrains" } },
})

add({
	words = { "!bless" },
	page = "player",
	topic = "Your character",
	short = "buy all the blessings you are missing",
	about = "Buys every blessing you do not have yet, in one go. The price depends on your level; it is paid with the gold you carry first, then from the bank.",
	use = { "!bless" },
	ex = { { "!bless", "\"You received the remaining 7 blesses for a total of ... gold\"" } },
	notes = { "Not while in a fight outside a protection zone.", "If you already have them all: \"You are already blessed\"." },
	see = { "!aol" },
})

add({
	words = { "!aol" },
	page = "player",
	topic = "Your character",
	short = "buy an amulet of loss",
	about = "Buys an amulet of loss and puts it in your backpack. Worn on the neck, it keeps your items when you die (it is used up then).",
	use = { "!aol" },
	ex = { { "!aol", "an amulet of loss for 50,000 gold" } },
	notes = { "Paid with the gold you carry first, then from the bank." },
	see = { "!bless" },
})

add({
	words = { "!checktaint" },
	page = "player",
	topic = "Your character",
	short = "your Soul War taint level",
	use = { "!checktaint" },
	ex = { { "!checktaint", "your taint level, or that you have none" } },
})

add({
	words = { "!balance" },
	page = "player",
	topic = "Bank",
	short = "how much gold you have in the bank",
	use = { "!balance" },
	ex = { { "!balance", "\"Your current bank balance is 1,234,567.\"" } },
	see = { "!deposit", "!withdraw", "!transfer" },
})

add({
	words = { "!deposit" },
	page = "player",
	topic = "Bank",
	short = "put gold you carry into the bank",
	use = { "!deposit <amount>", "!deposit all" },
	ex = {
		{ "!deposit 5000", "puts 5,000 gold in the bank" },
		{ "!deposit all", "puts every coin you carry (gold, platinum, crystal) in the bank" },
	},
	notes = { "Works anywhere, no banker needed." },
	see = { "!balance", "!withdraw" },
})

add({
	words = { "!withdraw" },
	page = "player",
	topic = "Bank",
	short = "take gold out of the bank",
	use = { "!withdraw <amount>" },
	ex = { { "!withdraw 10000", "10,000 gold from the bank to your backpack" } },
	notes = { "Type a number (there is no \"all\" here; a banker NPC accepts \"withdraw all\")." },
	see = { "!balance", "!deposit" },
})

add({
	words = { "!transfer" },
	page = "player",
	topic = "Bank",
	short = "send gold from your bank to another character",
	use = { "!transfer <name>, <amount>" },
	ex = { { "!transfer Bob, 25000", "25,000 gold from your bank to Bob's bank" } },
	notes = { "Mind the comma between the name and the amount." },
	see = { "!balance" },
})

add({
	words = { "!autoloot" },
	page = "player",
	topic = "Loot and shops",
	short = "loot every creature you kill by itself (on/all/off)",
	about = "When on, each corpse you kill (and can walk to) is looted at once, the same way as Quick Loot: your Quick Loot settings decide what is taken and which loot containers it goes to. Off until you turn it on; the choice is kept after logout.",
	use = { "!autoloot on", "!autoloot all", "!autoloot off" },
	ex = {
		{ "!autoloot on", "loots normal creatures, not bosses" },
		{ "!autoloot all", "loots bosses too" },
		{ "!autoloot off", "back to looting by hand" },
	},
	on = cfgBool("AUTOLOOT"),
	offWhy = "autoLoot is off in the server config",
})

add({
	words = { "!flask" },
	page = "player",
	topic = "Loot and shops",
	short = "stop getting empty flasks after potions (on/off)",
	use = { "!flask on", "!flask off" },
	ex = {
		{ "!flask on", "potions leave no empty flask" },
		{ "!flask off", "you get the empty flasks again" },
	},
	notes = { "Kept after logout." },
})

add({
	words = { "!hiddenshop" },
	page = "player",
	topic = "Loot and shops",
	short = "NPC trade: hide sell items you do not carry (on/off)",
	about = "In the NPC trade window, the Sell list hides the items you are not carrying, so you see only what you can sell right now.",
	use = { "!hiddenshop on", "!hiddenshop off" },
	ex = {
		{ "!hiddenshop on", "Sell list shows only what you carry" },
		{ "!hiddenshop off", "Sell list shows everything the NPC buys" },
	},
	notes = { "Kept after logout. Close and open the trade again to see the change." },
})

add({
	words = { "!refill" },
	page = "player",
	topic = "Loot and shops",
	short = "recharge used-up rings and amulets with silver tokens",
	about = "Recharges the empty items you carry, paying silver tokens: pendulet, sleep shawl, blister ring, theurgic amulet, ring of souls, turtle amulet (2 tokens each); spiritthorn ring, alicorn ring, arcanomancer sigil, arboreal ring (5 tokens each).",
	use = { "!refill" },
	ex = { { "!refill", "\"Refilled pendulet for a total of 2 silver tokens.\"" } },
	notes = { "One of each kind per use; type it again for a second one." },
})

add({
	words = { "!online" },
	page = "player",
	topic = "Information",
	short = "who is online (level, vocation, active/idle/training)",
	use = { "!online" },
	ex = { { "!online", "\"2 players online | Training: 0 | Idle: 1 | Active: 1\"" } },
})

add({
	words = { "!serverinfo" },
	page = "player",
	topic = "Information",
	short = "the server rates (experience, skills, loot) and rules",
	about = "Shows the rates for your character now (experience stage for your level, skill and magic stages, loot rate) and some server rules.",
	use = { "!serverinfo" },
	ex = { { "!serverinfo", "opens a window with the rates" } },
})

add({
	words = { "!time" },
	page = "player",
	topic = "Information",
	short = "the time in Tibia (day or night)",
	use = { "!time" },
	ex = { { "!time", "\"Now is night in Tibia Time, time now is 21:40.\"" } },
})

add({
	words = { "/save" },
	page = "player",
	topic = "Server",
	short = "save the server now (everyone can use it here)",
	about = "Saves every character and house to the database at once. Useful before closing the server window.",
	use = { "/save", "/save <minutes>" },
	ex = {
		{ "/save", "saves now: \"Server has been saved.\"" },
		{ "/save 5", "saves once, 5 minutes from now" },
	},
})

add({
	words = { "!livestream" },
	page = "player",
	topic = "Other",
	short = "let others watch your character (level 200+)",
	about = "Canary's livestream (cast): other people can watch your game through a client that supports spectating. While the stream is on without a password you get +15% experience (livestreamExperienceMultiplier).",
	use = { "!livestream", "!livestream on", "!livestream off", "!livestream password, <word>", "!livestream show" },
	ex = {
		{ "!livestream", "the full list of options" },
		{ "!livestream on", "starts the stream" },
	},
	notes = { "Needs level 200.", "Watching was never tried on our server and client." },
})

add({
	words = { "!emote" },
	page = "player",
	topic = "Other",
	short = "show your spell words as an emote (on/off)",
	use = { "!emote on", "!emote off" },
	ex = { { "!emote on", "your spells show as emotes" } },
	on = cfgBool("EMOTE_SPELLS"),
	offWhy = "emoteSpells is off in the server config",
})

add({
	words = { "!reward" },
	page = "player",
	topic = "Other",
	short = "one free exercise weapon",
	use = { "!reward" },
	ex = { { "!reward", "a window to choose the exercise weapon" } },
	on = cfgBool("TOGGLE_RECEIVE_REWARD"),
	offWhy = "toggleReceiveReward is off in the server config",
})

add({
	words = { "!vip", "!checkvip" },
	page = "player",
	topic = "Other",
	short = "your VIP days",
	use = { "!vip" },
	ex = { { "!vip", "your VIP status" } },
	on = cfgBool("VIP_SYSTEM_ENABLED"),
	offWhy = "the VIP system is off in the server config",
})

-- ========================================================================= gm

add({
	words = { "/pos", "!pos" },
	page = "gm",
	topic = "Moving around",
	short = "your position, or go to a position",
	use = { "/pos", "/pos <x>, <y>, <z>" },
	ex = {
		{ "/pos", "\"Your current position is: 32369, 32241, 7.\"" },
		{ "/pos 32369, 32241, 7", "teleports you there (the Thais temple)" },
	},
	notes = { "Positions from TibiaWiki (Mapper Coords) work here too after converting them." },
	see = { "/goto", "/town" },
})

add({
	words = { "/goto" },
	page = "gm",
	topic = "Moving around",
	short = "go to a player, monster or NPC by name",
	about = "Teleports you to a creature by name. With a monster name, typing it again goes to the next one with that name (\"Teleported to creature 2/14\").",
	use = { "/goto <name>", "/goto fiendish", "/goto influenced" },
	ex = {
		{ "/goto Bob", "to the player Bob" },
		{ "/goto Dragon Lord", "to a dragon lord; again for the next one" },
		{ "/goto influenced", "to an influenced (forge) creature" },
	},
	see = { "/c", "/pos" },
})

add({
	words = { "/c" },
	page = "gm",
	topic = "Moving around",
	short = "bring a creature to you",
	use = { "/c <name>" },
	ex = { { "/c Bob", "Bob is teleported next to you" } },
	see = { "/goto", "/t" },
})

add({
	words = { "/t" },
	page = "gm",
	topic = "Moving around",
	short = "go to your temple, or send a player to his",
	use = { "/t", "/t <player name>" },
	ex = {
		{ "/t", "you go to your home temple" },
		{ "/t Bob", "Bob goes to his home temple" },
	},
	see = { "/town" },
})

add({
	words = { "/town" },
	page = "gm",
	topic = "Moving around",
	short = "go to a town's temple",
	use = { "/town <town name or number>" },
	ex = { { "/town Carlin", "to the Carlin temple" }, { "/town 8", "to the temple of town number 8" } },
	see = { "/t", "/pos" },
})

add({
	words = { "/up" },
	page = "gm",
	topic = "Moving around",
	short = "one floor up, same square",
	use = { "/up" },
	ex = { { "/up", "you go one floor up" } },
	see = { "/down", "/a" },
})

add({
	words = { "/down" },
	page = "gm",
	topic = "Moving around",
	short = "one floor down, same square",
	use = { "/down" },
	ex = { { "/down", "you go one floor down" } },
	see = { "/up", "/a" },
})

add({
	words = { "/a" },
	page = "gm",
	topic = "Moving around",
	short = "jump some squares ahead (through walls)",
	use = { "/a <squares>" },
	ex = { { "/a 5", "5 squares in the direction you face" } },
	see = { "/up", "/down" },
})

add({
	words = { "/teleport", "/tp" },
	page = "gm",
	topic = "Moving around",
	short = "put a magic portal in front of you to a position",
	about = "Creates a magic portal on the square in front of you; walking into it takes anyone to the position you give.",
	use = { "/tp <x>, <y>, <z>" },
	ex = { { "/tp 32369, 32241, 7", "a portal to the Thais temple" } },
	notes = { "It stays until removed: face it and type /r." },
	see = { "/r", "/pos" },
})

add({
	words = { "/active" },
	page = "gm",
	topic = "Moving around",
	short = "go to a random active player",
	use = { "/active" },
	ex = { { "/active", "to a player who is not idle or training" } },
})

add({
	words = { "/listplayers" },
	page = "gm",
	topic = "Moving around",
	short = "pick a player from a window and go to him",
	use = { "/listplayers", "/listplayers all" },
	ex = { { "/listplayers", "active players only" }, { "/listplayers all", "also idle and training players" } },
})

add({
	words = { "!position" },
	page = "gm",
	topic = "Moving around",
	short = "your position (tutors)",
	use = { "!position" },
	ex = { { "!position", "\"Your current position is: 32369, 32241, 7.\"" } },
	see = { "/pos" },
})

add({
	words = { "/info" },
	page = "gm",
	topic = "Players",
	short = "a player's level, skills and position",
	use = { "/info <player name>" },
	ex = { { "/info Bob", "a window with Bob's level, skills, speed, position and IP" } },
	see = { "/spy" },
})

add({
	words = { "/spy" },
	page = "gm",
	topic = "Players",
	short = "what a player wears and carries",
	use = { "/spy <player name>" },
	ex = { { "/spy Bob", "Bob's equipment and backpack contents" } },
	see = { "/info" },
})

add({
	words = { "/bless" },
	page = "gm",
	topic = "Players",
	short = "your own blessings",
	use = { "/bless" },
	ex = { { "/bless", "which blessings you have" } },
	see = { "!bless" },
})

add({
	words = { "/goldrank" },
	page = "gm",
	topic = "Players",
	short = "the 10 richest bank accounts",
	use = { "/goldrank" },
	ex = { { "/goldrank", "\"1- Bob (1,234,567).\"" } },
})

add({
	words = { "/mc" },
	page = "gm",
	topic = "Players",
	short = "characters online from the same computer (IP)",
	use = { "/mc" },
	ex = { { "/mc", "the IPs with more than one character online" } },
})

add({
	words = { "/getlook" },
	page = "gm",
	topic = "Players",
	short = "the outfit numbers of a creature",
	use = { "/getlook <name>" },
	ex = { { "/getlook Bob", "<look type=\"128\" head=\"78\" ... />" } },
	see = { "/looktype" },
})

add({
	words = { "/ghost" },
	page = "gm",
	topic = "Look and effects",
	short = "become invisible (type again to be visible)",
	use = { "/ghost" },
	ex = { { "/ghost", "\"You are now invisible.\"" } },
})

add({
	words = { "/looktype" },
	page = "gm",
	topic = "Look and effects",
	short = "change your outfit to any creature's",
	use = { "/looktype <number>" },
	ex = { { "/looktype 35", "you look like a demon" }, { "/looktype 128", "back to the citizen outfit" } },
	notes = { "Changing the outfit in the outfit window turns it back." },
	see = { "/getlook" },
})

add({
	words = { "/effect" },
	page = "gm",
	topic = "Look and effects",
	short = "show a magic effect on your square",
	use = { "/effect <number>" },
	ex = { { "/effect 13", "a magic effect on your square" } },
	see = { "/distanceeffect" },
})

add({
	words = { "/distanceeffect" },
	page = "gm",
	topic = "Look and effects",
	short = "shoot a missile effect 7 squares ahead",
	use = { "/distanceeffect <number>" },
	ex = { { "/distanceeffect 4", "a missile flies 7 squares ahead" } },
	see = { "/effect" },
})

add({
	words = { "/setlight" },
	page = "gm",
	topic = "Look and effects",
	short = "light around you (color, strength)",
	use = { "/setlight <color 0-1500>, <strength 1-32>" },
	ex = { { "/setlight 215, 8", "a strong light around you" } },
})

add({
	words = { "/afk" },
	page = "gm",
	topic = "Look and effects",
	short = "show that you are away (on/off)",
	use = { "/afk on", "/afk off" },
	ex = { { "/afk on", "an AFK text over your character" } },
})

add({
	words = { "/b" },
	page = "gm",
	topic = "Server",
	short = "a message to every player online",
	use = { "/b <text>" },
	ex = { { "/b Server restart in 5 minutes", "everyone sees the message" } },
})

add({
	words = { "/clean" },
	page = "gm",
	topic = "Server",
	short = "remove the items lying on the map floor",
	use = { "/clean" },
	ex = { { "/clean", "\"Cleaned 123 items from the map.\"" } },
	notes = { "Items in houses stay." },
})

add({
	words = { "/countmonsters" },
	page = "gm",
	topic = "Server",
	short = "count the monsters in the spawn file",
	about = "Counts the monsters in world/otservbr-monster.xml and writes the list to monster_count.txt in the server folder; the total goes to the server console.",
	use = { "/countmonsters" },
	ex = { { "/countmonsters", "writes monster_count.txt" } },
})

add({
	words = { "/getstorage" },
	page = "gm",
	topic = "Server",
	short = "read a quest storage of a player",
	use = { "/getstorage <player name>, <storage number>" },
	ex = { { "/getstorage Bob, 48600", "the value of storage 48600 for Bob" } },
	notes = { "The player must be online." },
	see = { "/setstorage" },
})

add({
	words = { "/kick" },
	page = "gm",
	topic = "Server",
	short = "disconnect a player",
	use = { "/kick <player name>" },
	ex = { { "/kick Bob", "Bob is logged out" } },
})

add({
	words = { "/ban" },
	page = "gm",
	topic = "Server",
	short = "ban an account for some days",
	use = { "/ban <player name>, <days>, <reason>" },
	ex = { { "/ban Bob, 1, testing", "Bob's account is banned for a day" } },
	see = { "/unban" },
})

add({
	words = { "/unban" },
	page = "gm",
	topic = "Server",
	short = "lift a ban",
	use = { "/unban <player name>" },
	ex = { { "/unban Bob", "Bob can log in again" } },
	see = { "/ban" },
})

add({
	words = { "/namelock" },
	page = "gm",
	topic = "Server",
	short = "force a player to choose a new name",
	use = { "/namelock <player name>, <reason>" },
	ex = { { "/namelock Bob, bad name", "Bob must pick a new name" } },
})

-- ======================================================================== god

add({
	words = { "/i" },
	page = "god",
	topic = "Items and money",
	short = "create an item",
	use = { "/i <item name or id>", "/i <item name or id>, <count>", "/i <item name or id>, <count>, <tier 1-10>" },
	ex = {
		{ "/i magic sword", "one magic sword" },
		{ "/i crystal coin, 100", "100 crystal coins (1,000,000 gold)" },
		{ "/i 3031, 50", "50 gold coins, by item id" },
		{ "/i soulcutter, 1, 2", "a soulcutter of forge tier 2 (only items the forge can upgrade take a tier)" },
	},
	notes = { "Item ids: TibiaWiki (item page) or items.xml.", "Many stackable items are split into new bags as needed." },
	see = { "/r", "/addreward" },
})

add({
	words = { "/addmoney" },
	page = "god",
	topic = "Items and money",
	short = "add gold to a player's bank",
	use = { "/addmoney <player name>, <amount>" },
	ex = { { "/addmoney Bob, 100000", "100,000 gold in Bob's bank" } },
	see = { "!balance" },
})

add({
	words = { "/addreward" },
	page = "god",
	topic = "Items and money",
	short = "put an item in a reward chest",
	use = { "/addreward <item name or id>, <count>", "/addreward <item name or id>, <count>, <player name>" },
	ex = { { "/addreward gold ingot, 2, Bob", "2 gold ingots in Bob's reward chest" } },
})

add({
	words = { "/inbox" },
	page = "god",
	topic = "Items and money",
	short = "add or remove an item in a player's store inbox",
	use = { "/inbox <player name>,add,<item id>", "/inbox <player name>,remove,<item id>" },
	ex = { { "/inbox Bob,add,3043", "a crystal coin in Bob's store inbox" } },
	notes = { "Write add/remove right after the comma, without a space.", "Does nothing if the inbox is empty." },
})

add({
	words = { "/m" },
	page = "god",
	topic = "Creatures",
	short = "create monsters next to you",
	use = { "/m <monster>", "/m <monster>, <count>", "/m <monster>, <count>, fiendish", "/m <monster>, <count>, <influenced 1-5>" },
	ex = {
		{ "/m Dragon", "one dragon" },
		{ "/m Rat, 10", "10 rats around you" },
		{ "/m Demon, 1, fiendish", "a fiendish demon" },
		{ "/m Hydra, 1, 3", "an influenced hydra, stage 3" },
	},
	notes = { "They do not respawn. Remove one by facing it and typing /r." },
	see = { "/s", "/spawn", "/r" },
})

add({
	words = { "/s" },
	page = "god",
	topic = "Creatures",
	short = "create a monster as your summon",
	use = { "/s <monster>" },
	ex = { { "/s Dragon", "a dragon that follows you and fights for you" } },
	see = { "/m" },
})

add({
	words = { "/spawn" },
	page = "god",
	topic = "Creatures",
	short = "a respawning monster on your square",
	use = { "/spawn <monster>", "/spawn <monster>, <seconds>" },
	ex = { { "/spawn Rat, 30", "a rat that comes back 30 s after it dies" } },
	notes = { "Until the next server start." },
	see = { "/m" },
})

add({
	words = { "/n" },
	page = "god",
	topic = "Creatures",
	short = "create an NPC on your square",
	use = { "/n <npc name>", "/n <npc name>, true" },
	ex = { { "/n Rashid", "Rashid stands here until the next restart" } },
	notes = { "With \", true\" it is also written into the map's NPC file and stays for good. Better leave that to Claude, so the change goes into the repository too." },
})

add({
	words = { "/r" },
	page = "god",
	topic = "Creatures",
	short = "remove the creature or item in front of you",
	use = { "/r", "/r <count>", "/r all" },
	ex = {
		{ "/r", "removes the creature or top item you face" },
		{ "/r 10", "10 from the stack you face" },
		{ "/r all", "every item on that square" },
	},
	notes = { "Never the ground." },
})

add({
	words = { "/setmonstername" },
	page = "god",
	topic = "Creatures",
	short = "rename the monsters near you",
	use = { "/setmonstername <new name>" },
	ex = { { "/setmonstername Fluffy", "every monster within 4 squares is called Fluffy" } },
})

add({
	words = { "/raid" },
	page = "god",
	topic = "Creatures",
	short = "start a raid now",
	use = { "/raid <raid name>" },
	ex = { { "/raid Orshabaal", "the Orshabaal raid starts (messages, then the boss)" }, { "/raid Dragons", "the Dragons raid" } },
	notes = { "Names as in data-otservbr-global/raids/raids.xml. /raidtimers shows when they come by themselves." },
	see = { "/listraid", "/raidtimers" },
})

add({
	words = { "/listraid" },
	page = "god",
	topic = "Creatures",
	short = "the Lua raids /raid can start",
	use = { "/listraid" },
	ex = { { "/listraid", "\"Registered raids: ...\"" } },
	notes = { "Only the Lua raids; the classic ones are in raids.xml." },
	see = { "/raid" },
})

add({
	words = { "/raidtimers" },
	page = "god",
	topic = "Family server",
	short = "when each raid boss comes (hours of play)",
	use = { "/raidtimers" },
	ex = { { "/raidtimers", "\"Orshabaal (legendary): in 12.3 h of play\" ..." } },
	see = { "/raid" },
})

add({
	words = { "/fullmoon" },
	page = "god",
	topic = "Family server",
	short = "Grimvale full moon: status, force on/off, Feroxa",
	use = { "/fullmoon", "/fullmoon on", "/fullmoon off", "/fullmoon auto", "/fullmoon feroxa" },
	ex = {
		{ "/fullmoon", "is it full moon, minutes played today, did Feroxa come" },
		{ "/fullmoon on", "full moon now, whatever the day" },
		{ "/fullmoon auto", "back to Saturdays" },
		{ "/fullmoon feroxa", "Feroxa at the next minute (on a full moon)" },
	},
})

add({
	words = { "/citylife" },
	page = "god",
	topic = "Family server",
	short = "the walking city NPCs: how many, where, vendors",
	use = { "/citylife" },
	ex = { { "/citylife", "NPCs per city, at sea, talking, where the vendors are" } },
})

add({
	words = { "/forceperiod" },
	page = "god",
	topic = "Family server",
	short = "force day or night",
	use = { "/forceperiod day", "/forceperiod night", "/forceperiod auto" },
	ex = { { "/forceperiod night", "night-only things happen now" }, { "/forceperiod auto", "back to the clock" } },
})

add({
	words = { "/setpromotion" },
	page = "god",
	topic = "Characters",
	short = "set a player's promotion tier (0-5)",
	use = { "/setpromotion <player name>, <tier>" },
	ex = { { "/setpromotion Bob, 2", "Bob gets the level 400 promotion and its bonuses" }, { "/setpromotion Bob, 0", "no promotion after level 20" } },
	notes = { "The player must be online. Nothing is charged." },
	see = { "!promotion" },
})

add({
	words = { "/addskill" },
	page = "god",
	topic = "Characters",
	short = "add levels, magic level or a skill",
	use = { "/addskill <player name>, <what>", "/addskill <player name>, <what>, <amount>" },
	ex = {
		{ "/addskill Bob, level, 10", "10 levels" },
		{ "/addskill Bob, magic, 5", "5 magic levels" },
		{ "/addskill Bob, sword", "1 sword level" },
	},
	notes = { "what: level, magic, sword, axe, club, dist (distance), shield, fish (fishing); anything else means fist." },
})

add({
	words = { "/addmount" },
	page = "god",
	topic = "Characters",
	short = "give a mount, or all mounts",
	use = { "/addmount <player name>, <mount id>", "/addmount <player name>, all" },
	ex = { { "/addmount Bob, all", "every mount" }, { "/addmount Bob, 1", "mount number 1 (Widow Queen)" } },
	notes = { "Mount ids are in data/XML/mounts.xml." },
})

add({
	words = { "/addaddon" },
	page = "god",
	topic = "Characters",
	short = "give outfit addons",
	use = { "/addaddon <player name>, <looktype>, <addons 0-3>", "/addaddon <player name>, all, <addons 0-3>" },
	ex = { { "/addaddon Bob, all, 3", "both addons on every outfit" }, { "/addaddon Bob, 128, 3", "both citizen addons (male citizen looktype)" } },
	notes = { "Addons: 1 = first, 2 = second, 3 = both." },
})

add({
	words = { "/addcharms" },
	page = "god",
	topic = "Characters",
	short = "give charm points",
	use = { "/addcharms <player name>, <amount>" },
	ex = { { "/addcharms Bob, 500", "500 charm points" } },
	see = { "/addminorcharms", "/resetcharms", "/charmrunes", "/setbestiary" },
})

add({
	words = { "/addminorcharms" },
	page = "god",
	topic = "Characters",
	short = "give minor charm echoes",
	use = { "/addminorcharms <player name>, <amount>" },
	ex = { { "/addminorcharms Bob, 100", "100 minor charm echoes" } },
	see = { "/addcharms" },
})

add({
	words = { "/resetcharms" },
	page = "god",
	topic = "Characters",
	short = "reset charms and bestiary",
	use = { "/resetcharms", "/resetcharms <player name>" },
	ex = { { "/resetcharms Bob", "Bob's charms and bestiary start over" } },
	notes = { "Without a name it is your own." },
})

add({
	words = { "/charmexpansion" },
	page = "god",
	topic = "Characters",
	short = "give the Charm Expansion",
	use = { "/charmexpansion", "/charmexpansion <player name>" },
	ex = { { "/charmexpansion Bob", "Bob gets the Charm Expansion" } },
})

add({
	words = { "/charmrunes" },
	page = "god",
	topic = "Characters",
	short = "unlock every charm",
	use = { "/charmrunes", "/charmrunes <player name>" },
	ex = { { "/charmrunes Bob", "every charm unlocked for Bob" } },
})

add({
	words = { "/setbestiary" },
	page = "god",
	topic = "Characters",
	short = "set bestiary kills",
	use = { "/setbestiary <player name>, <monster>, <kills>", "/setbestiary <player name>, all, <kills>" },
	ex = { { "/setbestiary Bob, Dragon, 1000", "1,000 dragon kills in Bob's bestiary" } },
})

add({
	words = { "/addbosskill" },
	page = "god",
	topic = "Characters",
	short = "add boss kills to the Bosstiary",
	use = { "/addbosskill <kills>, <boss>", "/addbosskill <kills>, <boss>, <player name>" },
	ex = { { "/addbosskill 5, Orshabaal, Bob", "5 Orshabaal kills for Bob" } },
	notes = { "The number comes first here." },
})

add({
	words = { "/clearcooldown" },
	page = "god",
	topic = "Characters",
	short = "fight a boss again now",
	use = { "/clearcooldown <boss>", "/clearcooldown <boss>, <player name>" },
	ex = { { "/clearcooldown Scarlett Etzel, Bob", "Bob can fight Scarlett Etzel again" } },
})

add({
	words = { "/resetcd" },
	page = "god",
	topic = "Characters",
	short = "reset spell cooldowns",
	use = { "/resetcd", "/resetcd <player name>" },
	ex = { { "/resetcd", "your spells are ready" }, { "/resetcd Bob", "Bob's spells are ready" } },
})

add({
	words = { "/adddusts" },
	page = "god",
	topic = "Characters",
	short = "give forge dust",
	use = { "/adddusts <player name>, <amount>" },
	ex = { { "/adddusts Bob, 100", "100 dust" } },
	see = { "/removedusts", "/setdusts", "/getdusts", "/adddustlevel" },
})

add({
	words = { "/removedusts" },
	page = "god",
	topic = "Characters",
	short = "take forge dust",
	use = { "/removedusts <player name>, <amount>" },
	ex = { { "/removedusts Bob, 50", "50 dust less" } },
})

add({
	words = { "/setdusts" },
	page = "god",
	topic = "Characters",
	short = "set forge dust",
	use = { "/setdusts <player name>, <amount>" },
	ex = { { "/setdusts Bob, 225", "Bob has exactly 225 dust" } },
})

add({
	words = { "/getdusts" },
	page = "god",
	topic = "Characters",
	short = "see forge dust",
	use = { "/getdusts <player name>" },
	ex = { { "/getdusts Bob", "how much dust Bob has" } },
})

add({
	words = { "/adddustlevel" },
	page = "god",
	topic = "Characters",
	short = "raise the dust limit",
	use = { "/adddustlevel <player name>, <levels>" },
	ex = { { "/adddustlevel Bob, 10", "Bob can keep 10 more dust" } },
})

add({
	words = { "/addachievement" },
	page = "god",
	topic = "Characters",
	short = "give an achievement",
	use = { "/addachievement <player name>, <achievement id or name>" },
	ex = { { "/addachievement Bob, Allow Cookies?", "Bob gets that achievement" } },
	see = { "/removeachievement", "/checkachievements" },
})

add({
	words = { "/removeachievement" },
	page = "god",
	topic = "Characters",
	short = "take an achievement away",
	use = { "/removeachievement <player name>, <achievement id or name>" },
	ex = { { "/removeachievement Bob, Allow Cookies?", "Bob loses it" } },
})

add({
	words = { "/checkachievements" },
	page = "god",
	topic = "Characters",
	short = "a player's achievements",
	use = { "/checkachievements <player name>" },
	ex = { { "/checkachievements Bob", "Bob's achievements" } },
})

add({
	words = { "/addtitle" },
	page = "god",
	topic = "Characters",
	short = "give a title (Cyclopedia)",
	use = { "/addtitle <player name>, <title id>" },
	ex = { { "/addtitle Bob, 1", "title number 1" } },
	see = { "/settitle" },
})

add({
	words = { "/settitle" },
	page = "god",
	topic = "Characters",
	short = "choose the title a player shows",
	use = { "/settitle <player name>, <title id>" },
	ex = { { "/settitle Bob, 1", "Bob shows title number 1" } },
})

add({
	words = { "/addbadge" },
	page = "god",
	topic = "Characters",
	short = "give a badge (Cyclopedia)",
	use = { "/addbadge <player name>, <badge id>" },
	ex = { { "/addbadge Bob, 1", "badge number 1" } },
})

add({
	words = { "/setstorage" },
	page = "god",
	topic = "Characters",
	short = "change a quest storage",
	about = "Sets a storage value; storages keep quest progress. Wrong values can break a quest, so read it first with /getstorage.",
	use = { "/setstorage <storage number>, <value>", "/setstorage <storage number>, <value>, <player name>" },
	ex = { { "/setstorage 48600, 1, Bob", "storage 48600 of Bob becomes 1" }, { "/setstorage 48600, -1", "your own storage 48600 is cleared" } },
	notes = { "The order here is storage, value, name (the name last)." },
	see = { "/getstorage" },
})

add({
	words = { "/getkv" },
	page = "god",
	topic = "Characters",
	short = "read a key-value setting of a player",
	use = { "/getkv <key>", "/getkv <key>, <player name>" },
	ex = { { "/getkv family-promotion.tier, Bob", "Bob's promotion tier" } },
	see = { "/setkv", "/getallkv" },
})

add({
	words = { "/setkv" },
	page = "god",
	topic = "Characters",
	short = "change a key-value setting of a player",
	use = { "/setkv <key>, <value>", "/setkv <key>, <value>, <player name>" },
	ex = { { "/setkv family-promotion.tier, 1, Bob", "Bob's promotion tier becomes 1" } },
})

add({
	words = { "/getallkv" },
	page = "god",
	topic = "Characters",
	short = "list every key-value setting of a player",
	use = { "/getallkv", "/getallkv <player name>" },
	ex = { { "/getallkv Bob", "every key and value Bob has" } },
})

add({
	words = { "/attr" },
	page = "god",
	topic = "Characters",
	short = "change the item, creature or player in front of you",
	about = "Changes something about what you face. Items: aid (action id), uid, desc, name, decay, transform, clone, attack, defense, armor, charge, remove. Creatures: health, mana, speed, droploot, skull, direction, say. Players: fyi, tutorial, guildnick, group, vocation, stamina, town, balance, save, type, premium.",
	use = { "/attr <what>, <value>" },
	ex = {
		{ "/attr desc, A gift from Dad", "the item gets that text when looked at" },
		{ "/attr aid, 1000", "the item gets action id 1000" },
		{ "/attr stamina, 2520", "the player you face gets 42 hours of stamina" },
	},
})

add({
	words = { "/owner" },
	page = "god",
	topic = "Houses",
	short = "give the house you stand in to a player, or free it",
	use = { "/owner <player name>", "/owner none" },
	ex = { { "/owner Bob", "the house is Bob's, nothing charged" }, { "/owner none", "the house is free (and furnished for sale)" } },
})

add({
	words = { "/gotohouse" },
	page = "god",
	topic = "Houses",
	short = "go to your house door",
	use = { "/gotohouse", "/gotohouse <player name>" },
	ex = { { "/gotohouse", "to the door of your house" } },
	notes = { "With a name, that player is sent to the door of his own house (not you)." },
})

add({
	words = { "/hireling" },
	page = "god",
	topic = "Houses",
	short = "create a hireling lamp",
	use = { "/hireling", "/hireling <name>, <sex: 1 male, 2 female>" },
	ex = { { "/hireling Alfred, 1", "a lamp for a male hireling called Alfred" } },
})

add({
	words = { "/reload" },
	page = "god",
	topic = "Server",
	short = "reload files without restarting",
	use = { "/reload <what>" },
	ex = { { "/reload scripts", "reloads the Lua scripts" }, { "/reload npcs", "reloads the NPCs" } },
	notes = {
		"what: all, chat, config, core, events, familiar, groups, imbuements, items, modules, monsters, mounts, outfits, npcs, raids, scripts, vocations.",
		"Reloading can leave things half updated; a restart is safer.",
	},
})

add({
	words = { "/closeserver" },
	page = "god",
	topic = "Server",
	short = "close the server to players, or shut it down",
	use = { "/closeserver", "/closeserver shutdown", "/closeserver maintainance" },
	ex = { { "/closeserver", "no one but staff can log in" }, { "/closeserver shutdown", "saves and stops the server" } },
	see = { "/openserver" },
})

add({
	words = { "/openserver" },
	page = "god",
	topic = "Server",
	short = "open the server to players again",
	use = { "/openserver" },
	ex = { { "/openserver", "\"Server is now open.\"" } },
	see = { "/closeserver" },
})

add({
	words = { "/zones" },
	page = "god",
	topic = "Server",
	short = "look at the map zones (lists, counts, go there)",
	use = { "/zones list", "/zones list, <word>", "/zones goto, <zone>", "/zones countMonsters, <zone>" },
	ex = { { "/zones list, boss", "zones with \"boss\" in the name" }, { "/zones goto, <zone>", "to a random square of that zone" } },
	notes = { "Also: removeMonsters, countNpcs, removeNpcs, listPlayers, countPlayers, kickPlayers, size." },
})

add({
	words = { "/settaint" },
	page = "god",
	topic = "Server",
	short = "set a Soul War taint",
	use = { "/settaint <player name>, <taint 1-5>" },
	ex = { { "/settaint Bob, 2", "Bob gets taint level 2" } },
	see = { "!checktaint", "/removetaint" },
})

add({
	words = { "/removetaint" },
	page = "god",
	topic = "Server",
	short = "remove a Soul War taint",
	use = { "/removetaint <player name>, <taint>" },
	ex = { { "/removetaint Bob, 2", "Bob loses taint level 2" } },
})

add({
	words = { "/changeflowmap" },
	page = "god",
	topic = "Server",
	short = "Soul War ebb and flow map",
	use = { "/changeflowmap empty", "/changeflowmap inundate" },
	ex = { { "/changeflowmap empty", "the ebb and flow area without water" } },
	notes = { "\"ebb\" has an upstream typo and gives a Lua error." },
})

add({
	words = { "/addtutor" },
	page = "god",
	topic = "Server",
	short = "make a player a tutor",
	use = { "/addtutor <player name>" },
	ex = { { "/addtutor Bob", "Bob becomes a tutor" } },
	see = { "/removetutor" },
})

add({
	words = { "/removetutor" },
	page = "god",
	topic = "Server",
	short = "make a tutor a normal player again",
	use = { "/removetutor <player name>" },
	ex = { { "/removetutor Bob", "Bob is a normal player again" } },
})

add({
	words = { "/hasflag" },
	page = "god",
	topic = "Server",
	short = "does a player have a group flag",
	use = { "/hasflag <player name>, <flag number or name>" },
	ex = { { "/hasflag Bob, CannotBeAttacked", "yes or no" } },
	see = { "/setflag", "/removeflag" },
})

add({
	words = { "/setflag" },
	page = "god",
	topic = "Server",
	short = "give a player a group flag",
	use = { "/setflag <player name>, <flag number or name>" },
	ex = { { "/setflag Bob, CannotBeAttacked", "monsters cannot attack Bob" } },
})

add({
	words = { "/removeflag" },
	page = "god",
	topic = "Server",
	short = "take a group flag away",
	use = { "/removeflag <player name>, <flag number or name>" },
	ex = { { "/removeflag Bob, CannotBeAttacked", "back to normal" } },
})

add({
	words = { "/ipban" },
	page = "god",
	topic = "Server",
	short = "ban a player's IP",
	use = { "/ipban <player name>" },
	ex = { { "/ipban Bob", "no one can log in from Bob's IP" } },
})

add({
	words = { "/vip" },
	page = "god",
	topic = "Server",
	short = "VIP days of a player",
	use = { "/vip check, <name>", "/vip adddays, <name>, <days>" },
	ex = { { "/vip adddays, Bob, 30", "30 VIP days" } },
	on = cfgBool("VIP_SYSTEM_ENABLED"),
	offWhy = "the VIP system is off in the server config",
})

-- ====================================================================== tests

local function test(words, short, use, group)
	add({ words = words, page = "tests", topic = group or "Tests", short = short, use = use, ex = { { use[1], short } } })
end

test({ "/openforge" }, "open the Exaltation Forge window", { "/openforge" }, "Forge")
test({ "/fiendish" }, "go to a fiendish creature", { "/fiendish" }, "Forge")
test({ "/influenced" }, "go to an influenced creature", { "/influenced" }, "Forge")
test({ "/setfiendish" }, "make a new fiendish creature", { "/setfiendish" }, "Forge")
test({ "/rewardbag" }, "open a reward bag N times and see what comes out", { "/rewardbag 34109, 100" }, "Loot")
test({ "/createloot" }, "fill your loot pouch with N random items", { "/createloot 50" }, "Loot")
test({ "/addloot" }, "put an item in your loot pouch", { "/addloot <item name or id>, <count>" }, "Loot")
test({ "/countloot" }, "count the items in your loot pouch", { "/countloot" }, "Loot")
test({ "/clearloot" }, "empty your loot pouch", { "/clearloot" }, "Loot")
test({ "/createtestshop" }, "fill your loot pouch with shop items", { "/createtestshop" }, "Loot")
test({ "!testcontainer" }, "list (or remove with \"remove\") a test container", { "!testcontainer" }, "Loot")
test({ "/clearhirelingstas" }, "reset the hireling data of a player", { "/clearhirelingstas <player name>" }, "Characters")
test({ "/proficiency" }, "add weapon proficiency experience", { "/proficiency <experience>" }, "Characters")
test({ "/testtaintconditions" }, "test the Soul War taint conditions", { "/testtaintconditions" }, "Characters")
test({ "/areasound" }, "play a sound to everyone near you", { "/areasound <sound id>" }, "Sounds and icons")
test({ "/internalsound" }, "play a sound only you hear", { "/internalsound <sound id>" }, "Sounds and icons")
test({ "/globalsound" }, "play a sound to every player", { "/globalsound <sound id>" }, "Sounds and icons")
test({ "/ambientsound" }, "change your ambient sound", { "/ambientsound <sound id>" }, "Sounds and icons")
test({ "/musicsound" }, "change your music", { "/musicsound <sound id>" }, "Sounds and icons")
test({ "/testicon" }, "show status icons", { "/testicon <icon>, <icon>" }, "Sounds and icons")
test({ "/bakragoreicon" }, "show the Bakragore icon (or remove)", { "/bakragoreicon <number>" }, "Sounds and icons")
test({ "/playericon" }, "show a creature icon on you", { "/playericon <icon id>, <quantity>" }, "Sounds and icons")
test({ "/testmessage" }, "send yourself a message of a given type", { "/testmessage <type>" }, "Server")
test({ "/testlog" }, "write a line to the server log", { "/testlog info, hello" }, "Server")
test({ "/simraid" }, "simulate the raid chance formula", { "/simraid <initial chance>, <chance per day>, <max per check>" }, "Server")
