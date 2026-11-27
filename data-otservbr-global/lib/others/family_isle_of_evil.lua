-- Gaia Family server: The Isle of Evil Quest (2026-11-27). Ours: upstream had the NPCs, the kennel, The Cave
-- near Northport, the submarine and the island with its six bosses on the map, but no quest logic (Rapanaio's
-- boat sailed anyone to the island for free and Scutty was not even spawned).
--
-- Sources: TibiaWiki BR "The Isle of Evil Quest" (every transcript, screenshots Evil4-Evil22),
-- "The Isle of Evil (Book)"; TibiaWiki EN "The Isle of Evil Quest/Spoiler" (positions, item ids),
-- "Scutty/Transcripts", the item pages.
--
-- * Rapanaio (Kazordoon, floor 14): "isle of evil" ... "yes" starts it (his lore words are upstream's);
--   then the door west of him opens and its box holds the paper with the Isle of Evil text (BR/EN).
--   "mission" for missions 1-6 with both wikis' lines: the mechanical fishing rod (1), the mechanical fish,
--   10 vials of rum (2), a vial of fruit juice (3), Scutty's machine crate (4), the nautical map (5), then
--   "meet me downstairs" (6).
-- * Mechanical fish (mission 1): only in the sewers of Yalahar with nails (both wikis; upstream let any
--   water give one); a failed try may cost the nail with a shock: 35 energy damage and a skeleton look for
--   a few seconds (both wikis; the chance of a shock is ours).
-- * Scutty (spawned at last, EN 32576,31916,12, on the free square next to his table): "machine", "yes",
--   "yes" gives the worm punisher; heat it on a glowing crucible (10 s), whack 6 carrion worms in the
--   kennel; a drilling worm: "worms", "yes", 500 gold and start over; "mission" gives the machine crate
--   (BR lines and screenshot messages; Worm Whacker).
-- * Mortimer "nautical map" (BR lines); the hole on the beach east of Northport is closed again (a loose
--   stone pile to dig, both wikis); The Cave's quest box with the map was already there.
-- * Rapanaio on his submarine (behind the level 35 gate, EN; our map had level 50): "mission" and eight
--   "yes" take you to the island (BR); "evil isle" only after that.
-- * The island (mission 7): Rapanaio there tells you to go; the six bosses' corpses in the castle each give
--   one of their four items once (BR list), the Evil Mastermind's the fan club membership card, and after
--   that no other corpse gives anything (EN). Family rule (ours): every player may use each corpse, not
--   only the killer. "back" sails home (BR).
-- * King Tibianus "fan club membership card": the fan doll, 6,666 experience, King Tibianus Fan (both).
-- * Quest log: "The Isle of Evil" (the texts are ours).
--
-- Loaded from lib/others/load.lua.

FamilyIsleOfEvil = {
	rod = 9306,
	fish = 9307,
	vial = 2874,
	nail = 953,
	punisher = 9234,
	heated = 9201,
	crate = 9390,
	map = 9308,
	card = 9391,
	doll = 9389,
	paper = 641,
	paperText = "Eventually we reached an island that was thoroughly evil. It took all our courage and bravery to make our way through the dangerous territory to the dominating structure of the evil tower that loomed over the whole isle. We were well aware that the master of that tower had to be the epitome of evil and we had to enter his tower, regardless of the dangers involved. Only few had ever reached the isle and none of them had ever returned to tell the tale. But we were there and knew that it was our destiny to face the master of the isle. Retreat was not an option. We braved all the dangers that the isle seemed to throw against us and finally stood in front of the tower. Who would carry on our work if we failed? We knew if we did not stop the master of this isle, it might take decades until somebody else would find this isle and then it might be too late to stop the fiendish plot that threatened the whole world.",
	westDoor = Position(32678, 31990, 14),
	paperBox = Position(32674, 31989, 14),
	boatGate = Position(32681, 31992, 14),
	northportHole = Position(32531, 31628, 7),
	isle = Position(32668, 31457, 6),
	home = Position(32699, 31993, 14),
	yalahar = { x1 = 32680, y1 = 31050, x2 = 32960, y2 = 31330, z1 = 8, z2 = 12 }, -- the sewers under Yalahar (ours)
	kennel = { x1 = 32565, y1 = 31924, x2 = 32590, y2 = 31940, z = 12 },
	castle = { x1 = 32735, y1 = 31430, x2 = 32775, y2 = 31490, z1 = 1, z2 = 6 },
	worms = 6,
	penalty = 500,
	shockChance = 25, -- percent of failed tries, ours
	bosses = { -- corpse ids (fresh and after the first decay) -> rewards (BR)
		{ name = "Doctor Perhaps", corpses = { 18158, 18159 }, items = { 9399, 9383, 9372, 9373 } },
		{ name = "Dirtbeard", corpses = { 18197, 18194 }, items = { 9374, 9401, 9375, 9382 } },
		{ name = "Mephiles", corpses = { 6363, 6364 }, items = { 9376, 9387, 9400, 9377 } },
		{ name = "Boogey", corpses = { 8127, 8128 }, items = { 9379, 9385, 9384, 9378 } },
		{ name = "Monstor", corpses = { 6335, 6336 }, items = { 9381, 9386, 9380, 9396 } },
	},
	mastermindCorpses = { 7256, 7257 },
	TOPIC = 4901,
}

local E = FamilyIsleOfEvil

local function S()
	return Storage.Quest.U8_5.TheIsleOfEvil
end
E.S = S

function E.get(player, key)
	return math.max(0, player:getStorageValue(S()[key]))
end

function E.set(player, key, value)
	player:setStorageValue(S()[key], value)
end

-- Mission storage: 1 started, 2 fishing, 3 rum, 4 juice, 5 machine, 6 map, 7 boat, 8 on the island,
-- 9 card shown to Rapanaio, 10 done (King Tibianus). The quest log shows the same values.
function E.advance(player, value)
	if E.get(player, "Mission") < value then
		E.set(player, "Mission", value)
	end
end

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
	return true
end

local LINES = {
	isle = {
		"I KNOW it's out there! And I have proof! You see, I have constructed an evil-o-meter! It is an invention that locates places of great evil, such as the Ghostlands, the Plains of Havoc and the Edron Ruins. ...",
		"But then it registered another impulse. I tried my best to locate this impulse, believing it would probably point to another well known source of evil like the Hellgate. ...",
		"I was alarmed to realise that it was pointing to a remote isle that had been previously assumed to be uninhabited. I know that some horrendous evil lurks there. Some unspeakable horror, waiting to kill and devour unsuspecting travellers. ...",
		"I could not let that happen! So I did some research. Just as I was on the brink of giving up in desperation, I stumbled upon an ancient text that told of the Isle of Evil! ...",
		"Immediately, the nature of the threat I had discovered became alarmingly clear! All I needed was a hero and some transport. But would they listen?! NO! They laughed at me. Ignorance is Evil's helper! ...",
		"I still lack transport and a hero. Hmm .. seeing as I have no hero, you will have to do. What do you think? Are you willing to risk life and limb to save mankind? And womankind, of course?",
	},
	start = {
		"Although my instincts tell me to be wary of you, stranger, turning up so conveniently, I have no choice but to accept your help. ...",
		"Have a care! I have eyes like a hawk and am ever vigilant! If you even think about betraying me, I'll know! Well, I guess we had better talk about your first mission.",
	},
	fishing = {
		"They say there's a positive side to everything! And in this case it is perfectly true! In order for you to reach the Isle of Evil and slay its unspeakable horrors we will first finish my latest invention! ...",
		"As you might have guessed I am a highly talented inventor. Still, even inventors sometimes need some kind of .. inspiration. I can't tell you too much about your next mission since our enemies might capture and torture you for information. ...",
		"I optimized my invention by studying fish. Suffice it to say, I need one further specimen to study to put the finishing touches on my machine. ...",
		"I am afraid I need a specific fish, of course, as an ordinary fish just won't do the trick. Actually it is not a real fish but a kind of machine with the likeness of a fish! ...",
		"Imagine what I could learn from such a fish! And imagine what harm could be done if this fish were to fall into the wrong hands! We must retrieve that fish! ...",
		"Apparently, the people in the city of Yalahar had a mechanical fish, fish which are essential for my research. ...",
		"Now those Yalahari are quite elusive and even if we could get in contact with one of them, buying a fish from them would surely cost a fortune which we don't posses. ...",
		"But my sources have informed me that some of these fish might have escaped into the local sewers! Based on my knowledge of the fish I have designed a mechanical fishing rod which you can use. ...",
		"You won't catch any other fish with it but without it you haven't a chance of catching a mechanical fish. You will need to use nails as bait. ...",
		"Well perhaps I should mention a minor, insignificant problem that might occur. ...",
		"Due to the metallic nature of the fishing rod there is the very remote possibility that you might get into contact with one of the electric eels that also live in the sewers. ...",
		"In which case you might feel a little tingle from a teency tiny electric shock. I can't tell what effect that might have on your health but you should probably be careful that you are not badly wounded while fishing. ...",
		"Hm, thinking about it, perhaps those eels are part of the evil plan to thwart our efforts, who knows? So are you ready for that mission?",
	},
	rum = {
		"The machines of the .. uhm my inventions need a potent fuel. I have run hundreds of tests and found that only the most potent rum makes the most powerful fuel ...",
		"I did have enough rum to make the trip but .. well, you know .. the lads came over to celebrate my birthday and we ended up .. uhm testing the fuel.. Damn that tasty rum! Well its a risk of the job when the fuel tastes that good ...",
		"However, we will need some new fuel. 10 vials of rum exactly. ...",
		"Remember it has to be vials because after we got drunk one of the lads wandered of with my funnel thinking it was hat. Only vials will fit into my machine.",
	},
	machine = {
		"My invention is only as good as the engine that powers it. I need a high quality steam machine from the technomancers guild. You should ask my old mate Scutty about one. ...",
		"I have already sent him a request and some gold but chances are you will need to convince him somehow to lend us his precious machine.",
	},
	map = {
		"The evil we are fighting has not chosen the Isle of Evil on a mere whim. Quite the contrary, it has shown strategic genius by selecting an isle surrounded by hidden reefs and treacherous waters. ...",
		"This serves not only to conceal it from prying eyes, but it also poses a serious threat to anyone who wants to travel there. ...",
		"The sea around that isle is as dangerous as the isle and its inhabitants themselves. ...",
		"Without a proper map we are doomed! Doomed, I tell you! ...",
		"I have found out that a ship from the Explorers' Society charted the sea around the isle some years ago, so they should have some decent maps of that area ...",
		"According to my sources, the map is now being kept at one of their northern outposts. It is somewhere north east of Carlin, in a hamlet on the coast. Get that map and we'll soon be on our way to vanquish evil! ...",
		"And be warned: if the servants of evil have learned about the map it means not only the map and the Explorers' Society are in grave danger but also you and your mission could be in peril. Trust no one. ...",
		"Don't accept gifts from strangers and don't hitchhike in strangers' wagons. Don't sit with your back to the door in a tavern and what the heck would you be doing in a tavern while on an urgent mission anyway? ...",
		"Rest assured in the unfortunate case of your death, you will be avenged. Well, only in the unlikely case that you die while on this mission, of course.",
	},
}

-- Rapanaio in Kazordoon; called first in his npcType.onSay
function E.rapanaio(npc, creature, message, npcHandler)
	if not Family.isleOfEvil then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local m = E.get(player, "Mission")
	local topic = npcHandler:getTopic(id)
	if topic >= E.TOPIC and topic < E.TOPIC + 10 then
		npcHandler:setTopic(id, 0)
		if not MsgContains(message, "yes") then
			return say(npcHandler, npc, creature, "Then come back when you are ready.") -- ours
		end
		if topic == E.TOPIC then -- start
			E.advance(player, 1)
			return say(npcHandler, npc, creature, LINES.start)
		elseif topic == E.TOPIC + 1 then -- take the rod
			player:addItem(E.rod, 1)
			E.advance(player, 2)
			return say(npcHandler, npc, creature, "Great. Here is your fishing rod. Happy fishing. Don't return without the mechanical fish. Make sure you are not followed!")
		elseif topic == E.TOPIC + 2 then
			if not player:removeItem(E.fish, 1) then
				return say(npcHandler, npc, creature, "You don't have it with you. Don't return without the mechanical fish!") -- ours
			end
			E.advance(player, 3)
			return say(npcHandler, npc, creature, "Interesting, a most interesting construction. A marvel of science. While I try to figure out how it works you might as well continue with your next mission.")
		elseif topic == E.TOPIC + 3 then
			if player:getItemCount(E.vial, FLUID_RUM) < 10 then
				return say(npcHandler, npc, creature, "That is not enough fuel. 10 vials of rum exactly!") -- ours
			end
			player:removeItem(E.vial, 10, FLUID_RUM)
			E.advance(player, 4)
			return say(npcHandler, npc, creature, {
				"You did it! Ye Gods, what a temptation! But I will not give in! I will put it into the machine as soon as possible. Oh and if you happen to see a dwarf wearing a funnel, please ask him to return it to me. ...",
				"But now let's talk about your next mission.",
			})
		elseif topic == E.TOPIC + 4 then
			if not player:removeItem(E.vial, 1, FLUID_FRUITJUICE) then
				return say(npcHandler, npc, creature, "Where is it? I can't see any fruit juice!") -- ours
			end
			E.advance(player, 5)
			return say(npcHandler, npc, creature, {
				"Ahhhh that juice was just what I needed. I haven't had any fruit juice for ages! You can't fight evil the whole day without allowing yourself a small treat! ...",
				"Though I bet it would have tasted better in a glass with one of those amusing umbrellas on top! But I don't blame you. ...",
				"I fear we hunters of evil must be content with the small pleasures life grants us. Now where were we? Oh, yes you are probably eager to learn about your next mission as part of our big plan!",
			})
		elseif topic == E.TOPIC + 5 then
			if not player:removeItem(E.crate, 1) then
				return say(npcHandler, npc, creature, "I don't see any machine. Go and get it from Scutty!") -- ours
			end
			E.advance(player, 6)
			return say(npcHandler, npc, creature, "Ah, marvellous. That's the little beauty I was looking for. It will fit perfectly into my invention. Not much longer and we can start on our journey. However, I have another mission for you.")
		elseif topic == E.TOPIC + 6 then
			if not player:removeItem(E.map, 1) then
				return say(npcHandler, npc, creature, "You don't have it! Without a proper map we are doomed!") -- ours
			end
			E.advance(player, 7)
			return say(npcHandler, npc, creature, {
				"Hmm, what fine maps those explorers draw. Wouldn't it be a cunning idea to tattoo it on your back where evil would least expect to find it! I guess with a nail from my workshop and a bucket of old ship paint I could improvise that. ...",
				"On the other hand the forces of evil probably know all too well that I am cunning, so I have to surprise them with the unexpected! I'll just hide it in my beard! There we go. Now lets talk about our final mission.",
			})
		end
		return true
	end
	if MsgContains(message, "isle of evil") and m == 0 then
		npcHandler:say(LINES.isle, npc, creature)
		npcHandler:setTopic(id, E.TOPIC)
		return true
	end
	if not MsgContains(message, "mission") then
		return false
	end
	if m == 0 then
		return say(npcHandler, npc, creature, "Mission you say? Well MY mission is to fight evil with every power at my disposal! Hm, perhaps you have it in you to join the fight.")
	elseif m == 1 then
		npcHandler:setTopic(id, E.TOPIC + 1)
		return say(npcHandler, npc, creature, LINES.fishing)
	elseif m == 2 then
		npcHandler:setTopic(id, E.TOPIC + 2)
		return say(npcHandler, npc, creature, "Have you caught the mechanical fish?")
	elseif m >= 3 and m <= 6 then
		-- with the things he asked for: his question (BR); without: the mission
		local has = (m == 3 and player:getItemCount(E.vial, FLUID_RUM) >= 10) or (m == 4 and player:getItemCount(E.vial, FLUID_FRUITJUICE) >= 1) or (m == 5 and player:getItemCount(E.crate) >= 1) or (m == 6 and player:getItemCount(E.map) >= 1)
		if has then
			npcHandler:setTopic(id, E.TOPIC + m)
			return say(npcHandler, npc, creature, E.askLines[E.TOPIC + m])
		end
		local text = ({ [3] = LINES.rum, [4] = "Now that we have the rum, I still desperately need a vial of fruit juice to keep things going. Just get me one so we can proceed.", [5] = LINES.machine, [6] = LINES.map })[m]
		return say(npcHandler, npc, creature, text)
	elseif m == 7 then
		return say(npcHandler, npc, creature, {
			"While you were getting the map I put the finishing touches on our vessel. The machine works fine and with the improvements I have made, it should enable us to brave the seas to reach our destination. ...",
			"Meet me downstairs where you will learn more about our secret weapon.",
		})
	end
	return false
end

-- the asking lines need "yes" after them; the mission text is said, then "yes" is asked for
-- (rum, juice, crate, map: "Do you have the rum .. erm the fuel with you?" and so on, BR)
E.askLines = {
	[E.TOPIC + 3] = "Do you have the rum .. erm the fuel with you?",
	[E.TOPIC + 4] = "So you have brought me a vial of fruit juice?",
	[E.TOPIC + 5] = "Did you get the requested machine from Scutty?",
	[E.TOPIC + 6] = "So did you get that nautical map?",
}

-- Rapanaio on the submarine: "mission" and eight times "yes" (BR)
E.boatLines = {
	{ "Hello, my friend, what took you so long? Some sightseeing in my cavern, perhaps? You did not even notice me when I passed you in the cavern earlier. Tsk, you really should be more alert if you value your life. ...", "This here is my secret. An underwater boat! Evil will not even see us coming! I hope you are prepared for a big battle on that isle! If not, you had better go and get some additional resources and then return. So, do you feel ready for our trip?" },
	"You are aware that this could mean your death? I mean the evil is probably overpowering and .. and I will not be able to help you. I will have to stay with the boat to ensure the fight goes on even if you die. So, do you still think it is a good idea?",
	{ "Now seriously, we .. I mean, you don't have to do this! I would not blame you at all. You probably have plans for your future which don't contain being chained up in some madman's dungeon for the rest of your life, being cruelly tortured. ...", "Do you really want to take the risk upon yourself?" },
	"Are you absolutely sure?",
	"Honestly?",
	"This is your last chance - do you really want to do this?",
	"Well .. I guess then it is time for us to depart, right?",
	"I really hope I won't regret what you are doing here. Uhm, I mean I hope that we will not regret what we are doing, of course. We had better talk about your future mission when we arrive. So .. shall we really depart?",
}

function E.boat(npc, creature, message, npcHandler)
	if not Family.isleOfEvil then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local m = E.get(player, "Mission")
	local topic = npcHandler:getTopic(id)
	if topic >= E.TOPIC + 20 and topic < E.TOPIC + 30 then
		local step = topic - E.TOPIC - 20
		if not MsgContains(message, "yes") then
			npcHandler:setTopic(id, 0)
			return say(npcHandler, npc, creature, "I knew it! Come back when you have found your courage.") -- ours
		end
		if step < #E.boatLines then
			npcHandler:setTopic(id, topic + 1)
			npcHandler:say(E.boatLines[step + 1], npc, creature)
			return true
		end
		npcHandler:setTopic(id, 0)
		E.advance(player, 8)
		npcHandler:say("So be it!", npc, creature)
		npcHandler:resetNpc(creature)
		player:teleportTo(E.isle)
		E.isle:sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
	if MsgContains(message, "mission") and m == 7 then
		npcHandler:setTopic(id, E.TOPIC + 21)
		npcHandler:say(E.boatLines[1], npc, creature)
		return true
	end
	if MsgContains(message, "evil isle") and m < 8 then
		return say(npcHandler, npc, creature, "Evil isle? Psht! Not that loud! We are not ready to sail yet.") -- ours
	end
	return false
end

-- Rapanaio on the island
function E.islandRapanaio(npc, creature, message, npcHandler)
	if not Family.isleOfEvil then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	if npcHandler:getTopic(id) == E.TOPIC + 40 then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			npcHandler:say("I thought you were going to stay here forever. Let's go.", npc, creature)
			npcHandler:resetNpc(creature)
			player:teleportTo(E.home)
			E.home:sendMagicEffect(CONST_ME_TELEPORT)
			return true
		end
		return say(npcHandler, npc, creature, "As you wish.") -- ours
	end
	if MsgContains(message, "back") then
		npcHandler:setTopic(id, E.TOPIC + 40)
		return say(npcHandler, npc, creature, "Time to leave this unfriendly place, eh? So are you ready to depart?")
	end
	if MsgContains(message, "mission") then
		local m = E.get(player, "Mission")
		if m >= 8 and player:getItemCount(E.card) > 0 then
			E.advance(player, 9)
			return say(npcHandler, npc, creature, {
				"You made it?! Uhm, I mean of course you did! We did it! We have slain the master of all evil! The world will be a happier place from now on, thanks to our efforts. ...",
				"Concerning this membership card you have found, I think you should take it to King Tibianus, perhaps you will get a reward! Well, nothing stopping us going back, now, eh?",
			})
		end
		return say(npcHandler, npc, creature, "Now that we have arrived you should waste no time and fight your way to the lair of evil and destroy its master before it's too late!")
	end
	return false
end

-- Scutty
function E.scutty(npc, creature, message, npcHandler)
	if not Family.isleOfEvil then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local m = E.get(player, "Mission")
	local task = E.get(player, "Scutty")
	local topic = npcHandler:getTopic(id)
	if topic == E.TOPIC + 50 or topic == E.TOPIC + 51 then
		npcHandler:setTopic(id, 0)
		if not MsgContains(message, "yes") then
			return say(npcHandler, npc, creature, "Then don't waste my time.") -- ours
		end
		if topic == E.TOPIC + 50 then
			npcHandler:setTopic(id, E.TOPIC + 51)
			return say(npcHandler, npc, creature, {
				"Fine. As for the problem: you might know that we dwarfs sometimes use tamed rotworms to help dig our tunnels. Actually the worms we use are specially bred for that purpose. ...",
				"Though they are tame and docile they are still rotworms of course with their natural instincts. Recently some carrion worms dug their way into our drilling worm kennel. ...",
				"Though they pose no actual danger they cause our tame rotworms to panic and become agitated. ...",
				"If we leave this unchecked some of our worms might go feral and escape into the depths forever. Long story short, it's up to you to get rid of the carrion worms. Sadly, they are too cowardly to stay for a good fight. ...",
				"Instead I will lend you this hammer - the legendary 'worm punisher'. Now hitting them with that hammer might teach them a lesson but it won't keep them away for long. ...",
				"Therefore you'll have to heat up the hammer on one of the ovens over there and hit a carrion worm while the hammer is still hot. That will make the silly beasts think they have hit a pocket of lava and they will retreat for good. ...",
				"I think if you scare off six of those beasts the rest will follow them. But DON'T hit any of the ordinary worms! ...",
				"If you scare them even more you will have to pay me 500 gold in compensation before I'll allow you to continue. ...",
				"As soon as you have scared away six of the carrion worms talk to me about the worms and I'll give you that machine. Do we have a deal?",
			})
		end
		E.set(player, "Scutty", 1)
		E.set(player, "Worms", 0)
		E.set(player, "Penalty", 0)
		player:addItem(E.punisher, 1)
		return say(npcHandler, npc, creature, "Good. Here is the 'Worm punisher'. Remember DO NOT hurt the drilling worms! If you do it will cost you 500 gold!")
	end
	if topic == E.TOPIC + 52 then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			if not player:removeMoneyBank(E.penalty) then
				return say(npcHandler, npc, creature, "No gold, no deal.") -- ours
			end
			E.set(player, "Penalty", 0)
			E.set(player, "Worms", 0)
			return say(npcHandler, npc, creature, "Alright. Now scare off six carrion worms, and this time leave my drilling worms alone!") -- ours
		end
		return true
	end
	if m == 5 and task == 0 and MsgContains(message, "machine") then
		npcHandler:setTopic(id, E.TOPIC + 50)
		return say(npcHandler, npc, creature, {
			"So Rapanaio thinks I'd just hand out one of my greatest creations for a few coins of gold? Wrong! It works like this: you help me, then I'll help you. ...",
			"At the moment I'm tied up with an ongoing experiment and I could do with some help in a more mundane task. Are you in?",
		})
	end
	if task >= 1 and (MsgContains(message, "worms") or MsgContains(message, "worm")) and E.get(player, "Penalty") > 0 then
		npcHandler:setTopic(id, E.TOPIC + 52)
		return say(npcHandler, npc, creature, "You hit one of my precious drilling worms! That will cost you 500 gold before you may continue. Will you pay?") -- ours
	end
	if task == 2 and (MsgContains(message, "mission") or MsgContains(message, "worms") or MsgContains(message, "worm") or MsgContains(message, "machine")) then
		E.set(player, "Scutty", 3)
		player:addItem(E.crate, 1)
		return say(npcHandler, npc, creature, "Finally! I could have shaved off and grown a new beard in the time it has taken you to complete that task. However, here is your machine. Now leave me alone, I have experiments to carry out.")
	end
	return false
end

-- the worm punisher on a glowing crucible
function E.heat(player, item, target)
	if target.itemid ~= 9242 then
		return false
	end
	item:transform(E.heated)
	item:decay()
	target:getPosition():sendMagicEffect(CONST_ME_HITBYFIRE)
	return true
end

-- the heated punisher on a worm
function E.whack(player, item, target, toPosition)
	if not target or not target.itemid then
		return false
	end
	if target.itemid ~= 9196 and target.itemid ~= 9197 then
		return false
	end
	if E.get(player, "Scutty") ~= 1 then
		return true
	end
	toPosition:sendMagicEffect(CONST_ME_STUN)
	if target.itemid == 9196 then
		E.set(player, "Penalty", 1)
		E.set(player, "Worms", 0)
		player:say("Oh no! You have hit one of Scutty's precious drilling worms!", TALKTYPE_MONSTER_SAY) -- BR screenshot
		return true
	end
	if E.get(player, "Penalty") > 0 then
		return true
	end
	target:transform(9195) -- back into its hole
	target:decay()
	local count = E.get(player, "Worms") + 1
	E.set(player, "Worms", count)
	if count >= E.worms then
		E.set(player, "Scutty", 2)
		player:addAchievement("Worm Whacker")
		player:say("You've got him! That was the last one you had to scare off! Report to Scutty about the worms.", TALKTYPE_MONSTER_SAY) -- BR screenshot
	else
		player:say("You've got him! That will teach the beast a lesson!", TALKTYPE_MONSTER_SAY) -- BR screenshot
	end
	return true
end

-- the mechanical fishing rod; called first in scripts/actions/other/mechanical_fishing.lua
-- returns nil to let upstream continue, true when handled here
function E.fishing(player, target, toPosition)
	if not Family.isleOfEvil then
		return nil
	end
	local p = toPosition
	local y = E.yalahar
	local inSewers = p.z >= y.z1 and p.z <= y.z2 and p.x >= y.x1 and p.x <= y.x2 and p.y >= y.y1 and p.y <= y.y2
	if not inSewers then
		return nil -- upstream: the special fishing spots elsewhere
	end
	if player:getItemCount(E.nail) < 1 then
		toPosition:sendMagicEffect(CONST_ME_LOSEENERGY)
		return true
	end
	player:addSkillTries(SKILL_FISHING, 1, true)
	local chance = math.min(math.max(10 + (player:getEffectiveSkillLevel(SKILL_FISHING) - 10) * 0.597, 10), 50) -- upstream's chance
	if math.random(100) <= chance then
		player:removeItem(E.nail, 1)
		player:addItem(E.fish, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have caught a mechanical fish!") -- ours
		toPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
		return true
	end
	toPosition:sendMagicEffect(CONST_ME_LOSEENERGY)
	if math.random(100) <= E.shockChance then
		player:removeItem(E.nail, 1)
		doTargetCombatHealth(0, player, COMBAT_ENERGYDAMAGE, -35, -35, CONST_ME_ENERGYHIT)
		local condition = Condition(CONDITION_OUTFIT)
		condition:setTicks(4000)
		condition:setOutfit({ lookType = 33 }) -- skeleton
		player:addCondition(condition)
	end
	return true
end

local function inCastle(pos)
	local c = E.castle
	return pos.z >= c.z1 and pos.z <= c.z2 and pos.x >= c.x1 and pos.x <= c.x2 and pos.y >= c.y1 and pos.y <= c.y2
end

-- a boss corpse in the castle; returns true when handled (else the corpse opens as usual)
function E.useCorpse(player, item, position)
	if not Family.isleOfEvil or not inCastle(position) or E.get(player, "Mastermind") > 0 then
		return false
	end
	if table.contains(E.mastermindCorpses, item.itemid) then
		if not player:addItem(E.card, 1) then
			return false
		end
		E.set(player, "Mastermind", 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a fan club membership card.")
		return true
	end
	for index, boss in ipairs(E.bosses) do
		if table.contains(boss.corpses, item.itemid) then
			local bits = E.get(player, "Bosses")
			local flag = bit.lshift(1, index - 1)
			if bit.band(bits, flag) ~= 0 then
				return false
			end
			local reward = boss.items[math.random(#boss.items)]
			local it = player:addItem(reward, 1)
			if not it then
				return false
			end
			E.set(player, "Bosses", bit.bor(bits, flag))
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found " .. ItemType(reward):getArticle() .. " " .. ItemType(reward):getName() .. ".")
			return true
		end
	end
	return false
end

E.corpseIds = {}
for _, boss in ipairs(E.bosses) do
	for _, id in ipairs(boss.corpses) do
		E.corpseIds[#E.corpseIds + 1] = id
	end
end
for _, id in ipairs(E.mastermindCorpses) do
	E.corpseIds[#E.corpseIds + 1] = id
end

-- King Tibianus; called first in his creatureSayCallback
function E.king(npc, creature, message, npcHandler)
	if not Family.isleOfEvil then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player or not (MsgContains(message, "fan club membership card") or MsgContains(message, "membership card") or MsgContains(message, "fan club")) then
		return false
	end
	if not player:removeItem(E.card, 1) then
		return false
	end
	player:addItem(E.doll, 1)
	player:addExperience(6666, true)
	player:addAchievement("King Tibianus Fan")
	E.advance(player, 10)
	npcHandler:say({
		"Ah, A fan club premium membership card! You must be that intelligent fellow who wrote me all those flattering letters! Nice to finally meet my greatest admirer in person. Here, take this little token of appreciation. ...",
		"And now if you will excuse me, I have to attend urgent matters of state.",
	}, npc, creature)
	return true
end

-- the box west of Rapanaio
function E.usePaperBox(player)
	if E.get(player, "Mission") < 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The box is empty.") -- ours
		return true
	end
	if E.get(player, "Paper") > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The box is empty.")
		return true
	end
	local paper = player:addItem(E.paper, 1)
	if not paper then
		return true
	end
	paper:setAttribute(ITEM_ATTRIBUTE_TEXT, E.paperText)
	E.set(player, "Paper", 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a piece of paper.")
	return true
end

-- startup
function E.setup()
	local tile = Tile(E.westDoor)
	local door = tile and (tile:getItemById(7721) or tile:getItemById(7722))
	if door then
		door:setActionId(S().Mission) -- quest door: open once the quest is started
	end
	tile = Tile(E.paperBox)
	local box = tile and tile:getItemById(2469)
	if box then
		box:setActionId(48818) -- only makes the box immovable; the position action handles it
	end
	tile = Tile(E.boatGate)
	local gate = tile and tile:getItemById(7727)
	if gate then
		gate:setActionId(1035) -- level 35 (EN; our map had 50)
	end
	tile = Tile(E.northportHole)
	local hole = tile and tile:getItemById(615)
	if hole then
		hole:transform(606) -- a loose stone pile to dig open
	end
	local k = E.kennel
	for x = k.x1, k.x2 do
		for y = k.y1, k.y2 do
			local t = Tile(Position(x, y, k.z))
			if t then
				for _, it in ipairs(t:getItems() or {}) do
					local id = it:getId()
					if (id >= 9194 and id <= 9200) or id == 9242 or id == 9243 or id == 9244 then
						it:decay()
					end
				end
			end
		end
	end
end

-- Mortimer in Northport; called first in his creatureSayCallback
function E.mortimer(npc, creature, message, npcHandler)
	if not Family.isleOfEvil or not MsgContains(message, "nautical map") then
		return false
	end
	npcHandler:say({
		"Now this is getting ridiculous. That map has been lying around, collecting dust for years and now after those madmen stole it, someone else shows up asking for it. ...",
		"However, the map was completely useless because it only showed the waters around some remote piece of rock in the middle of the sea. We only stored it here for completeness. ...",
		"Some days ago some wannabe pirates turned up and threatened to kill me if I did not give them a map. ...",
		"As far as I could make out between their boasting and threatening they wanted to start out as pirates and thought it would be easier to start by stealing some maps before getting a whole ship. The only map I had here was that worthless nautical map. ...",
		"Luckily enough they seemed to have no idea how to read such maps and were pleased to get a map with some water and lines on it. ...",
		"So they took the map, but not before they had ruined the interior decorating and made me dance and sing pirate songs for them. ...",
		"I tell you something: If you manage to find those bandits and teach them a lesson you can keep the map. It's worthless anyway. As far as I could make out their hideout is somewhere to the east. ...",
		"They referred to it as 'the cave' and said the entrance is hidden. They also mentioned sand and two mossy stones. I hope that helps. I wish you luck.",
	}, npc, creature)
	return true
end
