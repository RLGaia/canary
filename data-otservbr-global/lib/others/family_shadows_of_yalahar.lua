-- Gaia Family server: Shadows of Yalahar Quest (2026-11-27). Ours: upstream had Telas, the Telas Golem, the
-- researchers' NPC files (Boveas and Dreadeye not spawned), Black Bert's quest items and most mission rooms on
-- the map, but no quest logic at all (an empty storage table), no Golem Servant and the mission doors sealed.
--
-- Sources: TibiaWiki BR "Shadows of Yalahar Quest" (every Telas line, the researchers, the disassembler
-- messages, the charges); TibiaWiki EN "Shadows of Yalahar Quest/Spoiler" (positions, the cannon's 5 seconds,
-- the disassembler chances, the library rule, the Golem Servant transcript, the 5 platinum and the hour of
-- waiting), the object and item pages.
--
-- Rodrigo agreed (2026-11-27): the Golem Servant has a worker golem look (ours); the mission 12 room keeps the
-- wiki's creatures (Black Bert sells the head as the easy way); mission 9 can summon a War Golem or a Fire
-- Devil and send you to the Ghostship (the Enraged Bookworm does not exist on our server).
--
-- Where the wikis disagree: Telas needs In Service of Yalahar mission 3 done (BR; EN: started). The library
-- follows EN (1 to 5 books, then the inkwell; BR: all 8 books): Telas' own words say the chance grows with every
-- book. Ours: every chance and timer the wikis leave open (marked below), the box spots that our map lacked, the
-- lines marked ours.
--
-- Loaded from lib/others/load.lua.

FamilyShadowsYalahar = {
	TOPIC = 5301,
	items = {
		core = 9249, crystal = 9251, disassembler = 9235, part = 9233, blueprint = 9247, powerCore = 9252,
		stabilizer = 9248, pill = 9537, head = 9255, wrench = 16251, nail = 953,
	},
	ingredients = { -- index = bit; item, where (the container square), Telas' lines
		{ name = "deep crystal", item = 9240, at = { Position(32697, 31585, 13), Position(32690, 31586, 13), Position(32692, 31588, 13) }, -- the crystals of the single giant spider's room (EN; which crystals is ours)
			ask = "According to dwarven miners you might find the deep crystal somewhere in the depths under Ab'Dendriel. I have no idea where though, or even how to get there.",
			got = "I truly hope this is a deep crystal. I have to admit, all those crystals look the same to me." },
		{ name = "dark essence", item = 9238, at = { Position(32994, 32405, 12), Position(32995, 32405, 12) }, door = Position(32993, 32405, 12),
			ask = "One of the more unpleasant components that I need is some dark essence. Some of my colleagues believe that it sometimes condenses in the depths beneath the cursed town of Drefia in the desert of the Daramian continent.",
			got = "By the Gods! Handle that dark essence with care! Didn't I mention it might explode? Ooops, I probably forgot to tell you! Well, whatever, I'll put it in a safe place for now. Thank you for your efforts my friend." },
		{ name = "shadow orb", item = 9237, at = { Position(32629, 32446, 10) }, door = Position(32628, 32446, 10),
			ask = { "One of the components is a shadow orb. So far, I have had no luck acquiring one. I even tried one of my more dubious contacts but he refused, saying that he would only mess with the guys in the dark cathedral if he had a death wish'. ...", "I think if you find this dark cathedral you might find a shadow orb." },
			got = "Ah, a perfect shadow orb! This is exactly what we need." },
		{ name = "bloodkiss flower", item = 9241, at = { Position(33038, 32185, 9) }, door = Position(33038, 32184, 9),
			ask = "Some of the elves of Shadowthorn cultivate a plant known as bloodkiss. I need one sample for the ritual.",
			got = "What a beautiful flower. A shame that we have to destroy it in the ritual." },
		{ name = "worm queen tooth", item = 9239, at = { Position(32181, 32468, 10) }, -- behind the Fibula key door (both wikis: keys 3940 and 3980)
			ask = "I am convinced that the tooth from a long dead rotworm queen will make an apt replacement for one of the more exotic ingredients in the Yalahari ritual. The books in the Edron academy suggest that the most likely place to find one might be deeper Fibula.",
			got = "My, this rotworm tooth looks old. But the older the better. It will certainly be sufficient for our ritual." },
		{ name = "animal fetish", item = 9236, at = { Position(32979, 31713, 6), Position(32980, 31713, 6) },
			ask = "One of the components could easily be substituted by an animal fetish. I have heard that the orcs in the Orcland use them to tame their war wolves. That's where you should start looking.",
			got = "Phew. That fetish stinks. I'd better put it into some sort of container." },
	},
	researchers = { "Milos", "Cerdras", "Boveas", "Scutty", "Dreadeye" },
	-- mission 2: the elemental cannons (EN: telescopes, the strange apparatus on the counters) and the crystal
	-- columns they aim at (9133-9136 green, 9137-9140 red, they swap every 10 s)
	cannons = { Position(32866, 31257, 11), Position(32868, 31257, 11), Position(32870, 31257, 11), Position(32872, 31257, 11), Position(32874, 31257, 11) },
	columns = { Position(32867, 31253, 11), Position(32869, 31253, 11), Position(32871, 31253, 11), Position(32873, 31253, 11) },
	cannonTime = 5, -- seconds (EN)
	dispenser = Position(32864, 31262, 11),
	charger = { Position(32709, 31193, 9), Position(32710, 31193, 9), Position(32709, 31194, 9), Position(32710, 31194, 9) },
	powerCore = Position(32648, 31104, 10), -- the core dispenser in the alchemists' quarter
	blueprintBox = { Position(32905, 31279, 11), Position(32906, 31279, 11), Position(32904, 31280, 11) }, -- ours: our map had no box
	stabilizerBox = { Position(32944, 31196, 13), Position(32945, 31197, 13) }, -- ours: our map had no box
	headBox = { Position(32549, 31246, 13), Position(32550, 31246, 13) }, -- ours: our map had no box
	wrenchChest = { Position(33270, 31791, 11), Position(33271, 31791, 11) }, -- ours: "a chest nearby" (Telas)
	books = {
		Position(32797, 31189, 9), Position(32797, 31193, 9), Position(32797, 31197, 9), Position(32801, 31189, 9),
		Position(32805, 31189, 9), Position(32805, 31193, 9), Position(32801, 31197, 9), Position(32805, 31197, 9),
	},
	inkwell = Position(32801, 31193, 9),
	ghostship = Position(33321, 32184, 7), -- TibiaWiki EN
	headache = 60, -- seconds (both wikis: a minute)
	elevatorDown = Position(32894, 31297, 11), elevatorUp = Position(32894, 31297, 9),
	button = Position(32895, 31296, 9), shower = Position(32895, 31296, 11),
	fenrockIn = Position(32550, 31274, 9), fenrockOut = Position(32550, 31272, 9),
	fenrockInside = Position(32549, 31270, 9), fenrockOutside = Position(32550, 31276, 9),
	lift9 = { Position(32549, 31249, 9), Position(32550, 31249, 9), Position(32549, 31250, 9), Position(32550, 31250, 9) },
	lift11 = { Position(32549, 31249, 11), Position(32550, 31249, 11), Position(32549, 31250, 11), Position(32550, 31250, 11) },
	liftDown = Position(32548, 31250, 11), liftUp = Position(32548, 31251, 9),
	servantTime = 120, -- seconds per requested item (ours; EN: "a limited amount of time")
	parts = { -- the Golem Servant's items: container id on the map, item, his request line (EN)
		{ box = 9168, item = 9152, line = "V-belt irreparably damaged. Replacement needed immediately!" },
		{ box = 9161, item = 9170, line = "Several parts instable. Wonder glue infusion necessary." },
		{ box = 9158, item = 9149, line = "Danger! Danger! Elemental water urgently needed for cooling!" },
		{ box = 9167, item = 9150, line = "Energy net required immediately!" },
		{ box = 9163, item = 9147, line = "Grease! Grease! Procedure impossible without proper amount of grease!" },
		{ box = 9164, item = 9151, line = "Essential component: bag of screws is missing!" },
		{ box = 9166, item = 9148, line = "Repair procedure requires giant screwdriver. Hurry, flesh unit!" },
		{ box = 9165, item = 9154, line = "Spare part needed! Spare part needed!" }, -- ours
		{ box = 9169, item = 9153, line = "Yalahari gear wheel broken. Replace it, flesh unit!" }, -- ours
		{ box = 9162, item = 9156, line = "Green power core depleted. Insert a new one!" }, -- ours
		{ box = 9160, item = 9155, line = "Red power core required for the main circuit!" }, -- ours
		{ box = 9159, item = 9157, line = "Chaos matter required for the stabilisation field!" }, -- ours
	},
	progress = { -- EN, in his order
		"Task fulfilled!", "Initializing repairs!", "Excellent performance!", "Critical failure avoided!",
		"Total destruction averted!", "Repairs progressing satisfactorily.", "Total destruction averted!",
		"Flesh unit is functioning in acceptable parameters!",
	},
	labForcefield = Position(33271, 31797, 6), labLever = Position(33272, 31797, 6), lab = Position(33268, 31797, 11),
	golemLever = Position(33269, 31789, 11),
	wait = 3600, -- one Tibian day (both wikis: an hour)
}

local Y = FamilyShadowsYalahar
local I = Y.items

local function S()
	return Storage.Quest.U8_5.ShadowsOfYalahar
end
Y.S = S

function Y.get(player, key)
	return math.max(0, player:getStorageValue(S()[key]))
end

function Y.set(player, key, value)
	player:setStorageValue(S()[key], value)
end

-- Mission storage: 2n-1 = mission n given, 2n = mission n reported (26 = done)
function Y.stage(player)
	return Y.get(player, "Mission")
end

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
	return true
end

local function hasBit(v, i)
	return bit.band(v, bit.lshift(1, i - 1)) ~= 0
end

local function setBit(player, key, i)
	Y.set(player, key, bit.bor(Y.get(player, key), bit.lshift(1, i - 1)))
end

local function count(v)
	local n = 0
	while v > 0 do
		n = n + (v % 2)
		v = math.floor(v / 2)
	end
	return n
end

-- the doors of the mission rooms (quest doors: open while their storage is set)
Y.doors = {
	{ key = "Door2", positions = { Position(32885, 31259, 10) } },
	{ key = "Door5", positions = { Position(32699, 31184, 9) } },
	{ key = "Door6", positions = { Position(32902, 31292, 10) } },
	{ key = "Door7", positions = { Position(32649, 31113, 10) } },
	{ key = "Door8", positions = { Position(32950, 31203, 13), Position(32950, 31207, 13) } },
	{ key = "Door9", positions = { Position(32787, 31195, 8) } },
	{ key = "Door10", positions = {} },
	{ key = "Door11", positions = { Position(32894, 31302, 9) } },
}
for _, ing in ipairs(Y.ingredients) do
	if ing.door then
		table.insert(Y.doors[7].positions, ing.door)
	end
end

local doorOpen = { Door2 = 3, Door5 = 9, Door6 = 11, Door7 = 13, Door8 = 15, Door9 = 17, Door10 = 19, Door11 = 21 }
local doorClose = { Door6 = 12 } -- EN: the blueprint room cannot be entered again

function Y.setStage(player, value)
	Y.set(player, "Mission", value)
	for door, from in pairs(doorOpen) do
		local open = value >= from and (not doorClose[door] or value < doorClose[door])
		player:setStorageValue(S()[door], open and 1 or -1)
	end
end

-- ---------------------------------------------------------------- Telas

local LINES = {
	[1] = {
		"My research on the creation of golems has progressed well so far. However, it is good to acknowledge the accomplishments of others in this science. ...",
		"I am in contact with certain gifted individuals who have themselves gained significant insights into this subject. ...",
		"I want you to contact them and ask them for their research notes. They should have the means to send them to me so you don't have to worry about picking up the papers and possibly losing them. ...",
		"From our previous correspondence I'd say all of them are supportive but reaching some of them might prove troublesome. ...",
		"I need the research notes from the technomancer Scutty of Kazordoon, the theoretical mago-scientist Milos of the Edron Academy. ...",
		"The field scientist Boveas, who can be found in Mintwalin, the druid Cerdras of Carlin and Dreadeye, a bonelord of the Braindeath Streak, who lives somewhere in the necropolis deep below Ab'Dendriel.",
	},
	[2] = {
		"Ah, yes. I have received all the reports I need and have already been able to glance through them. ...",
		"It will take some time to evaluate all those different approaches to the topic. Meanwhile, we can get on with the other tasks to advance our project. ...",
		"When you are ready, just ask me for your next mission.",
	},
	[3] = {
		"I hate to admit it, but I am still unable to create some of the necessary parts. Unfortunately, modern day technology just doesn't have the complexity to recreate the Yalaharian mago-mechanic cores. ...",
		"However, I do need to find out whether my other components function properly, so for my first attempt, an existing core will have to do. Unfortunately, we can't just go to Yalahar and ask for one. ...",
		"The Yalahari are not known for sharing their knowledge willingly. On the other hand, much of their machinery is not even used these days. ...",
		"Can you search in their factory quarter for some of the cores? But, pay attention now! The cores are not that easy to get ...",
		"According to my research, while the cores are being used, they are incredibly hot so you can't just remove one. Also, the Yalahari have added additional security and maintenance-friendly mechanisms. ...",
		"In each machine that uses cores, they have installed what I would call cooler cannons. ...",
		"The cannons can be used to cool overheated cores or cool down a normal core so it can be removed for maintenance. There are two drawbacks though. ...",
		"First you need to hit the core with the cooler cannon when it reaches the correct temperature. ...",
		"If you shoot too early it will be frozen in place and the system won't be able to remove it. ...",
		"The second drawback is that the cannon uses enormous amounts of energy, so you can only fire it every few seconds and will have to wait until it is fully recharged. ...",
		"If you hit the core while it is red hot it will cool down to room temperature and can be removed from the machine, but the system will replace it with another immediately. You should be able to get the cooled and inactive core from a nearby dispenser. ...",
		"As far as I can tell the core should remain inactive and do nothing funny like spontaneously overheat and fry you or something equally unpleasant.",
	},
	[4] = {
		"Ah, a mago mechanic core. A true marvel of Yalahari science. One day, my friend, we will be able to build our own. ...",
		"My understanding is growing daily. For now we will incorporate this core into our construction. ...",
		"You have proven yourself to be incredibly helpful. More missions await you.",
	},
	[5] = {
		"A golem's major power source is a mix of elemental forces. ...",
		"Most of the elements need only a low concentration of purity but the earth component, which is the overriding element in a Yalaharian golem, requires a huge amount of very pure concentrate. ...",
		"That is why crystals are often fused into the golem's body. ...",
		"Could you get me some elemental crystals? Use an ordinary pick axe on a slain earth elemental. With some luck you will gain an elemental shard. ...",
		"Ten of them should be enough for me to create an elemental crystal.",
	},
	[6] = {
		"So you have brought me all 10 shards for the core! That is one step further towards the construction of our very own golem! Without your help I would never have made it this far. ...",
		"I wish your next mission were less dangerous but sadly it isn't. But more about that when we talk about your next mission.",
	},
	[7] = {
		"I always find new things in the Yalaharian metallurgy to amaze me. In order to construct parts that are even remotely similar I had to spend a fortune and wait years for a dwarven smith to finish them. ...",
		"Luckily, there is a much cheaper source for even better material: existing golems. There are quite a few running aimlessly through Yalahar and posing a threat to unwary travellers. ...",
		"So by disabling those golems not only do we further our research but we also do something to clean up the city's golem problem! I'll lend you this golem-disassembler. ...",
		"When you have killed a golem wait a moment until all of his systems shut down. Then use the disassembler on his corpse. ...",
		"But, be careful! If you wait too long the parts will lose their charges and be worthless. ...",
		"Chances are that the disassembler will only produce scrap metal but now and then you'll get a golem part. I need six of them to make any progress in my work.",
	},
	[8] = "Ah, with your newest acquisition you have brought me 6 golem parts. With that we are done and can continue with your next mission.",
	[9] = {
		"Well, this one is somewhat hard to explain. The power core of the golem needs some specific charges to make it work. The good news is that I have discovered the perfect carrier for the charge. ...",
		"The bad news is, it's you! Well, let me elaborate: I need three different charges. ...",
		"You can charge yourself by walking though a charge generator. One of these can be found in the alchemists' quarter. ...",
		"Get yourself charged and return to me. I will suck the charge into one of my own inventions and can tell you if you carried one of the three charges we needed. ...",
		"Unfortunately, the machine may charge you in two further ways to the three charges we actually need. The other two charges are of no use to our project. ...",
		"But, on the positive side, each charge that we don't need can be sold to other scientists and I am willing to share some gold with you for your efforts.",
	},
	[10] = "We are finished with collecting charges! Now we can proceed and your next mission awaits you!",
	[11] = "I need a blueprint of a golem to compare with my own plans. I need to figure out where problems might arise. Please search the factory quarter for some blueprints that I can use.",
	[12] = "Yes, you've got them! That will aid my understanding of the construction of a golem. But there is still a lot to do and new missions waiting.",
	[13] = "In order to understand a Yalaharian power core I have to disassemble one. I think there are still some old and burnt out power cores to be found in the alchemists' quarter of Yalahar. Please get me one, the state of the core is not that important.",
	[14] = "Phenomenal! That's precisely what we need. A bit tattered and rusty but it will do perfectly. While I am busy with this, you can get on with some other missions.",
	[15] = {
		"I hope to save myself the effort of reinventing a stabilizer small enough to fit into the golem. I will have to get an original Yalahari stabilizer or be forced to create a four legged golem, which clearly won't do. ...",
		"Therefore, I need you to search the sunken quarter for a stabilizer.",
	},
	[16] = "Phenomenal! You must have good eyesight to have spotted this little fellow. However, don't mind my mumbling. New missions await you.",
	[17] = {
		"While visiting Yalahar I discovered one of their libraries in the magicians' quarter. I solved the logic puzzle that prevented unwanted intruders and began to study their rituals. ...",
		"I was THAT close to reconstructing the ritual when one of the Yalahari, Azerus, discovered me and had me thrown out of the city. I think all those guardian golems know me now and I can't show my face there any more ...",
		"You, on the other hand, can! I will tell you how to open the puzzle lock so you can enter the library. ...",
		"I fear that the Yalahari may have posted some Golems there as guards so you'll have to fight them to use the library undisturbed. Your mission is to reconstruct the ancient golem ritual from their books. ...",
		"There are hints scattered throughout the books in the library. Be warned! Yalahari literature is not easy reading! You might get a headache, which will make you forget what you just read. ...",
		"The chances of recreating the ritual are greater the more you read. On the other hand the more books you read the more likely it is that you'll get a headache and forget everything you have learned. ...",
		"If you get a headache you will have to wait a minute or two for it to wear off before you can continue. There are rumors about headache pills on the black market, but I have no idea where to find one. ...",
		"When you feel ready to recreate the ritual use the scribe's desk in the center of the room. You'll know when you have been successful.",
	},
	[18] = "Impressive! To be honest, I feared a bit for your sanity, but you made it! And you are still healthy and sane! Well, at least I hope so. I fully understand if you want to take a few days off before you continue with your next mission.",
	[19] = {
		"Yalahari rituals are quite complicated and need certain reagents that are not readily available nowadays. I think I can come up with some substitutes for most of them though. ...",
		"Specifically, three items need to be replaced. Are you ready for your first mission?",
	},
	[20] = "Finally! You have brought all the ingredients we need! We can talk about your next mission whenever you like.",
	[21] = {
		"I am disheartened. All my efforts to get this golem to function have been in vain! There is still something missing. Were I not a scientist I'd say it was the soul. ...",
		"I can't get the brain patterns working and without that a golem is just a useless shell. ...",
		"At the moment I would settle for some existing brain patterns but the golems that are still around seem to lack the sophisticated brain patterns needed to meld with my creation. There is one final hope though. ...",
		"While I was doing my research in Yalahar I stumbled upon reports about a remote scientific outpost of the Yalahari. There they were experimenting with something they called MI, short for magical intelligence. ...",
		"That should create some far more intelligent golems. I desperately need one of those golem's heads. The base has to be somewhere beneath the isle, nowadays is known as Fenrock. ...",
		"Unfortunately, I believe that you have to be a Yalahari or a Yalaharian servant to enter the complex. ...",
		"However, on the bright side, in the course of doing these missions you have been charged with Yalahari energy, read their mind twisting books and have come into contact with much of their technology. ...",
		"Additionally, there are electric showers that were often used by Yalaharian scientists. I have found out that one of the few electric showers that are still working is somewhere in the factory quarter. ...",
		"First, you will have to use it on yourself, then report back to me. I will use an ancient Yalahari device on you to amplify all the Yalahari characteristics you have acquired. ...",
		"Our only slim hope is that this might fool the system enough to allow you to enter the complex.",
	},
	[24] = "The head! You've got it! Incredible! Now we have everything we need! Give me a Tibian day to prepare everything for the activation process, then meet me here again.",
	[25] = {
		"We have made it, my friend! We have everything we need to reconstruct a Yalaharian golem! This is a great day for science. ...",
		"Without your help none of this would have been possible. We will both take our place in history soon. Meet me downstairs in my laboratory. ...",
		"The honour of activating the golem shall belong to you, my friend.",
	},
	[26] = {
		"It's alive! Well, not strictly alive, of course, but moving and talking! Hmm, it seems to be behaving strangely, but perhaps it just needs some training or something like that! ...",
		"I am so grateful to you! I grant you the privilege of being allowed to enter my laboratory. My latest experiments involve creatures from the far north. ...",
		"I've upgraded them with some experimental golem technology and those formerly wild creatures can now actually be mounted. ...",
		"For all of your good work, feel free to take one with you. Just use the golem wrench on it that you'll find in a chest nearby. Thanks again!",
	},
	done = {
		"Admittedly, I am at a bit of loss as to specifying exactly what it is that we have created here. It is a functional golem and it is working. ...",
		"On the other hand, it seems odd and a bit self-preoccupied. It's almost as if it had some kind of sentience. ...",
		"It's even more of a marvel than I had hoped for! Absolutely fascinating! I will run a series of tests and .. and .. there is so much to be done. ...",
		"It seems my work has only just begun!",
	},
}
Y.LINES = LINES

local CHARGES = { "A", "B", "C", "X", "Y" }
Y.CHARGES = CHARGES

-- the remaining wanted items per mission report: { stage, item, amount }
local DELIVER = {
	[3] = { I.core, 1 }, [5] = { I.crystal, 10 }, [7] = { I.part, 6 }, [11] = { I.blueprint, 1 },
	[13] = { I.powerCore, 1 }, [15] = { I.stabilizer, 1 }, [23] = { I.head, 1 },
}

local function mayStart(player)
	return player:getStorageValue(Storage.Quest.U8_4.InServiceOfYalahar.Mission03) >= 6
end
Y.mayStart = mayStart

function Y.greeting(player)
	return Y.stage(player) == 0 and "Hello! Sorry I'm a bit busy." or "Hello!"
end

function Y.telas(npc, creature, message, npcHandler)
	if not Family.shadowsOfYalahar then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local v = Y.stage(player)
	local topic = npcHandler:getTopic(id)
	if MsgContains(message, "trade") and v < 26 then
		return say(npcHandler, npc, creature, "I am sorry, I only trade with my most trusted assistants.") -- ours (BR: trade is a reward)
	end
	if topic == Y.TOPIC or topic == Y.TOPIC + 1 then
		npcHandler:setTopic(id, 0)
		if not MsgContains(message, "yes") then
			return say(npcHandler, npc, creature, "As you wish.") -- ours
		end
		if topic == Y.TOPIC + 1 then -- mission 11 report and the amplifying charge
			Y.setStage(player, 23)
			player:getPosition():sendMagicEffect(CONST_ME_ENERGYAREA)
			return say(npcHandler, npc, creature, "It's done! I really hope that will be enough to enter the complex. It is probably somewhere in the underground of Fenrock. I have no idea what you might find there but look for a golem's head and bring it to me.")
		end
		-- mission 10: a new ingredient
		local done = Y.get(player, "Ingredients")
		local left = {}
		for i = 1, #Y.ingredients do
			if not hasBit(done, i) then
				left[#left + 1] = i
			end
		end
		local pick = left[math.random(#left)]
		Y.set(player, "Ingredient", pick)
		return say(npcHandler, npc, creature, Y.ingredients[pick].ask)
	end
	if not MsgContains(message, "mission") then
		return false
	end
	if v == 0 and not mayStart(player) then
		return say(npcHandler, npc, creature, "Perhaps once you have proven yourself in the service of Yalahar I could use your help.") -- ours
	end
	if v >= 26 then
		return say(npcHandler, npc, creature, LINES.done)
	end
	if v % 2 == 0 then -- the next mission
		if v == 24 then
			if os.time() < Y.get(player, "Ready") then
				return say(npcHandler, npc, creature, "I am not ready yet. Give me a Tibian day to prepare everything for the activation process.") -- ours
			end
			Y.setStage(player, 25)
			return say(npcHandler, npc, creature, LINES[25])
		end
		local nextStage = v + 1
		Y.setStage(player, nextStage)
		if nextStage == 7 then
			player:addItem(I.disassembler, 1)
		elseif nextStage == 19 then
			npcHandler:setTopic(id, Y.TOPIC)
		end
		return say(npcHandler, npc, creature, LINES[nextStage])
	end
	-- reports
	if v == 1 then
		if count(Y.get(player, "Notes")) >= #Y.researchers then
			Y.setStage(player, 2)
			return say(npcHandler, npc, creature, LINES[2])
		end
		return say(npcHandler, npc, creature, "I still need the research notes of Scutty, Milos, Boveas, Cerdras and Dreadeye.") -- ours
	elseif v == 9 then
		local c = Y.get(player, "Charge")
		local got = Y.get(player, "Charges")
		if c == 0 then
			if got == 7 then
				Y.setStage(player, 10)
				return say(npcHandler, npc, creature, LINES[10])
			end
			return say(npcHandler, npc, creature, "You carry no charge. Walk through the charge generator in the alchemists' quarter.") -- ours
		end
		Y.set(player, "Charge", 0)
		player:getPosition():sendMagicEffect(CONST_ME_ENERGYHIT)
		if c <= 3 and hasBit(got, c) then
			player:addMoney(900)
			return say(npcHandler, npc, creature, "Hm, that is another " .. CHARGES[c] .. "-charge. Though it won't advance our project it will bring us a good price from other researchers. I will give you 900 gold for that charge.")
		elseif c == 1 then
			setBit(player, "Charges", 1)
			return say(npcHandler, npc, creature, "Excellent. You brought an A-charge. Just what we needed.")
		elseif c == 2 then
			setBit(player, "Charges", 2)
			return say(npcHandler, npc, creature, "Exemplary! A B-charge! Incredible!")
		elseif c == 3 then
			setBit(player, "Charges", 3)
			return say(npcHandler, npc, creature, "We have got a major C-charge! Excellent!")
		elseif c == 4 then
			player:addMoney(1500)
			return say(npcHandler, npc, creature, "Oh, that's an X-charge. Nevermind. Although we don't need it, the academy might use it for their lightning research. Here is your share of the money I'll get from reselling it. That makes 1500 gold.")
		end
		player:addMoney(1200)
		return say(npcHandler, npc, creature, "Though this Y-charge is quite rare we don't need it for our research. However, some independent researchers will be willing to part with a fair amount of coin for it. I'll advance you 1200 gold. I'm sure I'll get that much back from my colleague.")
	elseif v == 17 then
		if Y.get(player, "Ritual") > 0 then
			Y.setStage(player, 18)
			return say(npcHandler, npc, creature, LINES[18])
		end
		return say(npcHandler, npc, creature, "Reconstruct the ritual from the books of the library, then use the scribe's desk in the center of the room.") -- ours
	elseif v == 19 then
		local done = Y.get(player, "Ingredients")
		local cur = Y.get(player, "Ingredient")
		if count(done) >= 3 then
			Y.setStage(player, 20)
			return say(npcHandler, npc, creature, LINES[20])
		end
		if cur == 0 then
			npcHandler:setTopic(id, Y.TOPIC)
			return say(npcHandler, npc, creature, done == 0 and "Are you ready for your first mission?" or "Are you up to your assignment?")
		end
		local ing = Y.ingredients[cur]
		if not player:removeItem(ing.item, 1) then
			return say(npcHandler, npc, creature, ing.ask)
		end
		setBit(player, "Ingredients", cur)
		Y.set(player, "Ingredient", 0)
		if count(Y.get(player, "Ingredients")) >= 3 then
			Y.setStage(player, 20)
			return say(npcHandler, npc, creature, { ing.got, LINES[20] })
		end
		return say(npcHandler, npc, creature, ing.got)
	elseif v == 21 then
		if Y.get(player, "Showered") == 0 then
			return say(npcHandler, npc, creature, "Use the electric shower in the factory quarter first, then report back to me.") -- ours
		end
		npcHandler:setTopic(id, Y.TOPIC + 1)
		return say(npcHandler, npc, creature, "Ah, yes. My instruments tell me you have taken the shower! Are you ready to receive the amplifying charge?")
	elseif v == 25 then
		if Y.get(player, "Activated") == 0 then
			return say(npcHandler, npc, creature, "It was a long and perilous road, my friend, but we made it! I assure you, without your help this would never have been possible. Now do it my friend! Pull the lever and give life to our masterpiece!")
		end
		Y.setStage(player, 26)
		player:addExperience(25000, true)
		player:addAchievement("Golem in the Gears")
		return say(npcHandler, npc, creature, LINES[26])
	end
	local want = DELIVER[v]
	if want then
		if player:getItemCount(want[1]) < want[2] then
			return say(npcHandler, npc, creature, "Come back when you have it.") -- ours
		end
		player:removeItem(want[1], want[2])
		if v == 23 then
			Y.setStage(player, 24)
			Y.set(player, "Ready", os.time() + Y.wait)
			player:addItem(3035, 5) -- 5 platinum coins (EN)
			return say(npcHandler, npc, creature, LINES[24])
		end
		Y.setStage(player, v + 1)
		return say(npcHandler, npc, creature, LINES[v + 1])
	end
	return false
end

-- ---------------------------------------------------------------- the researchers

local NOTES = {
	Milos = "Oh, of course I'll send him my notes immediately. Perhaps he'll come back and visit us here sometime. Do pass on my regards to him, won't you?",
	Cerdras = {
		"I see no harm in sending him my notes. I hope it will help him in his efforts. ...",
		"Maybe you could persuade him to use the time my research saves him in touch with nature. I am sure this will help him focus his mind on his studies.",
	},
	Boveas = "Oh, of course I can send him my research notes. I'll drop them into the next mailbox as soon as possible. May the Gods bless the royal Tibian mail system and its fearless and sometimes maimed postmen.",
	Scutty = {
		"Ok, ok. Considering how much knowledge Telas was willing to share and keeping in mind that he promised to send me the results of his research I'll make an exception. I will send him the information he wants .. even a bit more. ...",
		"He'd better live up to his promises, a dwarf does not forget or forgive easily.",
	},
	Dreadeye = {
		"Of course! He will receive the knowledge that I choose to share with him - although with his limited intelligence I doubt he will grasp the concepts I send him. ...",
		"Warn him that the consequences, for you both, will be dire if you fail to succeed in your undertaking. Your limited intellect cannot comprehend the importance of this. ...",
		"Even I do not know what this portends. But.. yet .. sometimes .. there is a glimpse. An insight that unsettles me. An emotion long forgotten.",
	},
}
local GOLEMS = { -- EN, "golems"
	Milos = "I am more into theories then into practice but I have come up with several very solid theories that may be invaluable to Telas, if they work in practice. I would not go as far as to say that I have reinvented how golems can be constructed but I think some of my approaches are quite unique. Even by disproving some of my ideas Telas stands to gain some significant insights into his chosen field of study. I am only too pleased that my theories are being applied in such a useful way!",
	Scutty = "Yes, yes. Fascinating issue. Hmm. Let's see .. I don't know too much about golems themselves, but I have a good idea about the mechanics involved. After researching some material that Telas sent me I was able to work out some crucial information. Using the information I have put together, Telas should be able to pass on the specs to the blacksmiths. At least he can get the mechanical components organised.",
	Boveas = "Before I turned my attention to minotaur lore, I was researching the construction of golems. Finally I reached a point where I felt a breakthrough was imminent. But months turned to years and the break through eluded me. After years of stagnation and frustration I moved on and never looked back. I am willing to part with the information I have gathered so far in the hope I can assist Telas in his researches. May he be successful where I failed. I will mail him my research papers immediately.",
	Cerdras = "I have indeed gathered some knowledge in the field of elemental golems. Particularly the secrets of the Earth element, which is involved in the process of their creation.",
	Dreadeye = "Ah yes, the issue of golems. I know. Much of the knowledge on this subject that my race have... acquired over the centuries is at my disposal. And I am disposed to share it.",
}

function Y.researcher(name)
	return function(npc, creature, message, npcHandler)
		if not Family.shadowsOfYalahar then
			return false
		end
		local player = creature and creature:getPlayer()
		if not player or Y.stage(player) ~= 1 then
			return false
		end
		local index
		for i, n in ipairs(Y.researchers) do
			if n == name then
				index = i
			end
		end
		if MsgContains(message, "research notes") or MsgContains(message, "notes") then
			if hasBit(Y.get(player, "Notes"), index) then
				return say(npcHandler, npc, creature, "I have already sent my notes to Telas.") -- ours
			end
			setBit(player, "Notes", index)
			return say(npcHandler, npc, creature, NOTES[name])
		end
		if MsgContains(message, "golems") or MsgContains(message, "golem") then
			return say(npcHandler, npc, creature, GOLEMS[name])
		end
		return false
	end
end

-- ---------------------------------------------------------------- objects

local cannonUsed = {}

-- mission 2: an elemental cannon
function Y.useCannon(player, position)
	if Y.stage(player) ~= 3 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The cannon is not charged.") -- ours
		return true
	end
	local guid = player:getGuid()
	if (cannonUsed[guid] or 0) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The cannon is still recharging.") -- ours (EN: 5 seconds)
		return true
	end
	cannonUsed[guid] = os.time() + Y.cannonTime
	local best, dist
	for _, c in ipairs(Y.columns) do
		local d = math.abs(c.x - position.x)
		if not best or d < dist then
			best, dist = c, d
		end
	end
	position:sendDistanceEffect(best, CONST_ANI_ICE)
	local tile = Tile(best)
	local red = false
	for id = 9137, 9140 do
		if tile and tile:getItemById(id) then
			red = true
		end
	end
	if red then
		best:sendMagicEffect(CONST_ME_ICEAREA)
		Y.set(player, "Core", 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The core cools down to room temperature. The system ejects it into the dispenser.") -- ours
	else
		best:sendMagicEffect(CONST_ME_ICEATTACK)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The core was not hot enough and is frozen in place.") -- ours (Telas: too early)
	end
	return true
end

function Y.useDispenser(player)
	if Y.stage(player) == 3 and Y.get(player, "Core") == 1 and player:addItem(I.core, 1) then
		Y.set(player, "Core", 0)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have taken a cooled mago mechanic core.") -- ours
		return true
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The dispenser is empty.") -- ours
	return true
end

-- mission 3: a pick on a slain earth elemental (corpse 8105); returns true when handled
function Y.onPick(player, target)
	if not Family.shadowsOfYalahar or not target or type(target) ~= "userdata" or not target.isItem or not target:isItem() then
		return false
	end
	if target.itemid ~= 8105 or Y.stage(player) ~= 5 then
		return false
	end
	if target:getActionId() == 48819 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is nothing left to gain from these remains.") -- ours
		return true
	end
	target:setActionId(48819)
	if math.random(100) <= 30 then -- ours (EN: not every dead earth elemental gives one)
		player:addItem(I.crystal, 1)
		target:getPosition():sendMagicEffect(CONST_ME_GREEN_RINGS)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have gained an elemental crystal.") -- ours
	else
		target:getPosition():sendMagicEffect(CONST_ME_BLOCKHIT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You did not find any elemental crystal.") -- ours
	end
	return true
end

-- mission 4: the golem disassembler on a slain worker golem (corpse 8887); EN chances (damaged worker golems)
function Y.useDisassembler(player, item, target)
	if not target or type(target) ~= "userdata" or not target.isItem or not target:isItem() or target.itemid ~= 8887 then
		return false
	end
	if Y.stage(player) ~= 7 or target:getActionId() == 48819 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have ruined the golem remains!")
		return true
	end
	target:setActionId(48819)
	local pos = target:getPosition()
	local roll = math.random(100)
	if roll <= 47 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have ruined the golem remains!")
	elseif roll <= 73 then
		player:addItem(I.part, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have salvaged a golem part!")
	elseif roll <= 88 then
		local c = Condition(CONDITION_ENERGY)
		c:setParameter(CONDITION_PARAM_DELAYED, true)
		c:addDamage(4, 2000, -25) -- EN: 4 turns of 25
		player:addCondition(c)
		pos:sendMagicEffect(CONST_ME_ENERGYHIT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "What an electrifying experience!")
	elseif roll <= 95 then
		player:addItem(I.nail, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have salvaged some scrap metal!")
	else
		Game.createMonster("Rat", pos, true, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There was something stuck in the golem!")
	end
	return true
end

-- mission 5: the charge generator
function Y.stepCharger(player, position)
	if Y.stage(player) ~= 9 then
		return
	end
	if Y.get(player, "Charge") > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are already charged.") -- ours
		return
	end
	Y.set(player, "Charge", math.random(#CHARGES))
	position:sendMagicEffect(CONST_ME_ENERGYAREA)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have gained a charge!")
end

-- missions 6, 7, 8, 12 and the wrench: a box that gives one item
function Y.useBox(player, which)
	local v = Y.stage(player)
	local spec = ({
		blueprint = { 11, I.blueprint, 1 }, power = { 13, I.powerCore, 2 }, stabilizer = { 15, I.stabilizer, 3 },
		head = { 23, I.head, 4 }, wrench = { 26, I.wrench, 5 },
	})[which]
	local got = Y.get(player, "Got")
	if v ~= spec[1] or (hasBit(got, spec[3]) and (which == "wrench" or player:getItemCount(spec[2]) > 0)) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "It is empty.")
		return true
	end
	if not player:addItem(spec[2], 1) then
		return true
	end
	setBit(player, "Got", spec[3])
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. ItemType(spec[2]):getArticle() .. " " .. ItemType(spec[2]):getName() .. ".")
	return true
end

-- mission 9: the books and the scribe's desk
local function headache(player)
	Y.set(player, "Headache", os.time() + Y.headache)
	Y.set(player, "Books", 0)
	player:getPosition():sendMagicEffect(CONST_ME_STUN)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You get a terrible headache and forget everything you have read.") -- ours
end

local function failure(player)
	headache(player)
	local roll = math.random(100)
	if roll <= 5 then
		player:teleportTo(Y.ghostship) -- EN
		Y.ghostship:sendMagicEffect(CONST_ME_TELEPORT)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The book's words swirl around you and you find yourself somewhere else!") -- ours
	elseif roll <= 30 then
		Game.createMonster(math.random(2) == 1 and "War Golem" or "Fire Devil", player:getPosition(), true, true) -- EN
	end
end

function Y.useBook(player, position)
	if Y.stage(player) ~= 17 or Y.get(player, "Ritual") > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The text is written in an ancient Yalahari script that makes your head swim.") -- ours
		return true
	end
	if Y.get(player, "Headache") > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your head hurts too much to read.") -- ours
		return true
	end
	local index
	for i, p in ipairs(Y.books) do
		if p == position then
			index = i
		end
	end
	local read = Y.get(player, "Books")
	if hasBit(read, index) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already studied this book.") -- ours
		return true
	end
	if math.random(100) <= 10 + 8 * count(read) then -- ours: the more you read, the likelier a headache (Telas)
		failure(player)
		return true
	end
	setBit(player, "Books", index)
	position:sendMagicEffect(CONST_ME_FIREWORK_YELLOW)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have learned something about the Yalahari ritual.") -- ours (BR: fireworks)
	return true
end

function Y.useInkwell(player)
	if Y.stage(player) ~= 17 or Y.get(player, "Ritual") > 0 then
		return false
	end
	if Y.get(player, "Headache") > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your head hurts too much to write.") -- ours
		return true
	end
	local read = count(Y.get(player, "Books"))
	if read == 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have not read anything about the ritual yet.") -- ours
		return true
	end
	if math.random(100) > 20 * read then -- ours: certain after 5 books (EN: 1 to 5 books)
		failure(player)
		return true
	end
	Y.set(player, "Ritual", 1)
	Y.inkwell:sendMagicEffect(CONST_ME_FIREWORK_BLUE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have successfully reconstructed the ancient golem ritual!") -- ours
	return true
end

-- called from data/scripts/actions/items/foods.lua before the pill is eaten ("Your head begins to feel better.")
function Y.usePill(player)
	Y.set(player, "Headache", 0)
end

-- mission 10: an ingredient spot; returns false to let the object act as usual
function Y.useIngredient(player, position)
	local cur = Y.get(player, "Ingredient")
	if Y.stage(player) ~= 19 or cur == 0 then
		return false
	end
	local ing = Y.ingredients[cur]
	for _, p in ipairs(ing.at) do
		if p == position then
			if player:getItemCount(ing.item) > 0 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is nothing more here.") -- ours
				return true
			end
			player:addItem(ing.item, 1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. ItemType(ing.item):getArticle() .. " " .. ing.name .. ".")
			return true
		end
	end
	return false
end

-- mission 11: the elevator button and the shower (both sparkling gems)
function Y.useButton(player, position)
	local v = Y.stage(player)
	if position == Y.button then
		if v < 21 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nothing happens.") -- ours
			return true
		end
		player:teleportTo(Y.elevatorDown)
		Y.elevatorDown:sendMagicEffect(CONST_ME_ENERGYAREA)
		return true
	end
	if v == 21 and Y.get(player, "Showered") == 0 then
		Y.set(player, "Showered", 1)
		player:getPosition():sendMagicEffect(CONST_ME_ENERGYAREA)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take an electric shower. Your hair stands on end.") -- ours
		return true
	end
	player:teleportTo(Y.elevatorUp)
	Y.elevatorUp:sendMagicEffect(CONST_ME_ENERGYAREA)
	return true
end

-- mission 12: Fenrock's teleporters, the lift, the Golem Servant's boxes
function Y.stepFenrock(player, position, fromPosition)
	if position == Y.fenrockOut then
		player:teleportTo(Y.fenrockOutside)
		Y.fenrockOutside:sendMagicEffect(CONST_ME_TELEPORT)
		return
	end
	if Y.stage(player) < 23 then
		player:teleportTo(fromPosition, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Access denied. Only Yalahari and their servants may enter.") -- ours
		return
	end
	player:teleportTo(Y.fenrockInside)
	Y.fenrockInside:sendMagicEffect(CONST_ME_TELEPORT)
end

function Y.stepLift(player, position, fromPosition)
	if position.z == 11 then
		player:teleportTo(Y.liftUp)
		Y.liftUp:sendMagicEffect(CONST_ME_ENERGYAREA)
		return
	end
	if Y.get(player, "Lift") == 0 then
		player:teleportTo(fromPosition, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The lift is damaged.") -- ours
		return
	end
	player:teleportTo(Y.liftDown)
	Y.liftDown:sendMagicEffect(CONST_ME_ENERGYAREA)
end

function Y.useServantBox(player, item)
	for _, p in ipairs(Y.parts) do
		if p.box == item.itemid then
			if Y.stage(player) ~= 23 then
				return false
			end
			player:addItem(p.item, 1)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take " .. ItemType(p.item):getArticle() .. " " .. ItemType(p.item):getName() .. ".")
			return true
		end
	end
	return false
end

-- the Golem Servant
function Y.servant(npc, creature, message, npcHandler)
	if not Family.shadowsOfYalahar then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	if topic >= Y.TOPIC + 10 and topic <= Y.TOPIC + 12 then
		npcHandler:setTopic(id, 0)
		if not MsgContains(message, "yes") then
			return say(npcHandler, npc, creature, "Understood! No repair procedure initiated.")
		end
		if topic == Y.TOPIC + 11 then -- the item
			local want = Y.parts[Y.get(player, "ServantItem")]
			if not want or os.time() > Y.get(player, "ServantTime") or not player:removeItem(want.item, 1) then
				Y.set(player, "Servant", 0)
				Y.set(player, "ServantItem", 0)
				return say(npcHandler, npc, creature, "Repair procedure failed! The repairs have to start from the beginning.") -- ours
			end
			local n = Y.get(player, "Servant") + 1
			Y.set(player, "Servant", n)
			Y.set(player, "ServantItem", 0)
			if n >= 8 then
				npcHandler:setTopic(id, Y.TOPIC + 12)
			else
				npcHandler:setTopic(id, Y.TOPIC + 10)
			end
			return say(npcHandler, npc, creature, Y.progress[n] .. " Repair progress " .. n .. " / 8 ! Can we continue?")
		end
		if topic == Y.TOPIC + 12 then
			Y.set(player, "Lift", 1)
			Y.set(player, "Servant", 0)
			npcHandler:resetNpc(creature)
			return say(npcHandler, npc, creature, "Repair procedure complete! Elevator fully operational. Ending communication. Have a nice day. Good bye.")
		end
		-- a new request
		local pick = math.random(#Y.parts)
		Y.set(player, "ServantItem", pick)
		Y.set(player, "ServantTime", os.time() + Y.servantTime)
		return say(npcHandler, npc, creature, Y.parts[pick].line)
	end
	if Y.get(player, "ServantItem") > 0 and (MsgContains(message, "yes") or MsgContains(message, "item")) then
		npcHandler:setTopic(id, Y.TOPIC + 11)
		return say(npcHandler, npc, creature, "Do you have the required item, flesh unit?")
	end
	if MsgContains(message, "repairs") or MsgContains(message, "repair") then
		if Y.get(player, "Lift") > 0 then
			return say(npcHandler, npc, creature, "The lift is fully operational.") -- ours
		end
		Y.set(player, "Servant", 0)
		Y.set(player, "ServantItem", 0)
		npcHandler:setTopic(id, Y.TOPIC + 10)
		return say(npcHandler, npc, creature, {
			"You must bring me the correct components or tools. The items deteriorate when they leave their conservation fields so you must be quick ...",
			"Are you ready, flesh unit?",
		})
	end
	if MsgContains(message, "lift") then
		if Y.get(player, "Lift") > 0 then
			return say(npcHandler, npc, creature, "The lift is fully operational.") -- ours
		end
		return say(npcHandler, npc, creature, {
			"The lift is damaged, sir or madame flesh unit! I could initiate the repair process but I need the correct tools and parts for the repairs ...",
			"If you wish to initiate the repair process ask me for {repairs}, male or female unit.",
		})
	end
	return false
end

function Y.servantGreeting(player)
	if Y.get(player, "ServantItem") > 0 then
		return "Do you have the required item, flesh unit?"
	end
	return "Greetings! What brings you {here}?"
end

-- mission 13: Telas' lab and the lever
function Y.stepLab(player, position, fromPosition)
	if Y.stage(player) < 25 then
		player:teleportTo(fromPosition, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Telas has not invited you into his laboratory.") -- ours
		return
	end
	player:teleportTo(Y.lab)
	Y.lab:sendMagicEffect(CONST_ME_TELEPORT)
end

function Y.useGolemLever(player, item)
	if Y.stage(player) ~= 25 or Y.get(player, "Activated") > 0 then
		return false
	end
	Y.set(player, "Activated", 1)
	item:transform(item.itemid == 2772 and 2773 or 2772)
	Position(33267, 31789, 11):sendMagicEffect(CONST_ME_ENERGYAREA)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Sparks fly and the golem's eyes begin to glow. It's alive!") -- ours
	return true
end

-- ---------------------------------------------------------------- quest log

local LOG = {
	[1] = "Ask Scutty (Kazordoon), Milos (Edron academy), Boveas (Mintwallin), Cerdras (Carlin druid guild) and Dreadeye (Hellgate) for their research notes.",
	[3] = "Shoot an elemental cannon in the factory quarter of Yalahar at a red hot core, then take the cooled mago mechanic core from the dispenser.",
	[5] = "Use a pick on slain earth elementals to gain 10 elemental crystals.",
	[7] = "Use the golem disassembler on slain worker golems to salvage 6 golem parts.",
	[9] = "Walk through the charge generator in the alchemists' quarter and bring Telas an A-, a B- and a C-charge.",
	[11] = "Search the factory quarter for a golem blueprint.",
	[13] = "Find an old power core in the alchemists' quarter.",
	[15] = "Search the sunken quarter for a stabilizer.",
	[17] = "Reconstruct the golem ritual from the books of the Yalahar library and use the scribe's desk.",
	[19] = "Bring Telas three substitutes for the ritual's reagents.",
	[21] = "Use the electric shower in the factory quarter and report to Telas.",
	[23] = "Find a golem's head in the Yalahari complex beneath Fenrock. The Golem Servant can repair the lift.",
	[24] = "Wait a Tibian day while Telas prepares the activation.",
	[25] = "Pull the lever in Telas' laboratory to activate the golem, then talk to Telas.",
	[26] = "The golem is alive. Telas lets you into his laboratory and trades with you.",
}

function Y.describe(player)
	local v = Y.stage(player)
	if v % 2 == 0 and v < 24 then
		return "Ask Telas in Edron for your next mission."
	end
	local text = LOG[v] or LOG[1]
	if v == 1 then
		local notes, left = Y.get(player, "Notes"), {}
		for i, n in ipairs(Y.researchers) do
			if not hasBit(notes, i) then
				left[#left + 1] = n
			end
		end
		text = text .. " Still missing: " .. (#left > 0 and table.concat(left, ", ") or "none, report to Telas") .. "."
	elseif v == 9 then
		local got, have = Y.get(player, "Charges"), {}
		for i = 1, 3 do
			if hasBit(got, i) then
				have[#have + 1] = CHARGES[i]
			end
		end
		text = text .. " Delivered: " .. (#have > 0 and table.concat(have, ", ") or "none") .. "."
	elseif v == 19 then
		local cur = Y.get(player, "Ingredient")
		text = text .. string.format(" Delivered: %d of 3.", count(Y.get(player, "Ingredients"))) .. (cur > 0 and (" Now: " .. Y.ingredients[cur].name .. ".") or "")
	end
	return text
end

-- ---------------------------------------------------------------- startup

local function placeOnce(candidates, id, aid)
	for _, p in ipairs(candidates) do
		local t = Tile(p)
		if t and t:getItemById(id) then
			return p
		end
	end
	for _, p in ipairs(candidates) do
		local t = Tile(p)
		if t and t:getGround() and not t:hasFlag(TILESTATE_BLOCKSOLID) then
			local it = Game.createItem(id, 1, p)
			if it then
				it:setActionId(aid)
				return p
			end
		end
	end
end

function Y.setup()
	local questDoor = {}
	for _, v in ipairs(QuestDoorTable or {}) do
		questDoor[v.closedDoor] = true
		questDoor[v.openDoor] = true
	end
	for _, d in ipairs(Y.doors) do
		for _, p in ipairs(d.positions) do
			local t = Tile(p)
			for _, it in ipairs(t and t:getItems() or {}) do
				if questDoor[it:getId()] then
					it:setActionId(S()[d.key])
				end
			end
		end
	end
	for _, c in ipairs(Y.columns) do
		local t = Tile(c)
		for _, it in ipairs(t and t:getItems() or {}) do
			if it:getId() >= 9133 and it:getId() <= 9140 then
				it:decay()
			end
		end
	end
	-- boxes our map lacked (ours; aid 48820 only makes them immovable)
	Y.blueprintAt = placeOnce(Y.blueprintBox, 2469, 48820)
	Y.stabilizerAt = placeOnce(Y.stabilizerBox, 2469, 48820)
	Y.headAt = placeOnce(Y.headBox, 2469, 48820)
	Y.wrenchAt = placeOnce(Y.wrenchChest, 2472, 48820)
	Y.boxAt = {}
	for k, at in pairs({ blueprint = Y.blueprintAt, stabilizer = Y.stabilizerAt, head = Y.headAt, wrench = Y.wrenchAt, power = Y.powerCore }) do
		if at then
			Y.boxAt[at.x .. "," .. at.y .. "," .. at.z] = k
		end
	end
	for _, p in ipairs({ Y.fenrockIn, Y.fenrockOut, Y.labForcefield }) do
		local t = Tile(p)
		local tp = t and t:getItemById(1949)
		if tp then
			tp:setDestination(Position(0, 0, 0))
		end
	end
end
