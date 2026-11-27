-- Gaia Family server: Twenty Miles Beneath the Sea Quest (2026-11-27). Ours: upstream had the Seacrest Grounds
-- on the map, the NPC files of Mr Brandon and the Guardian of the Deep Seas (not spawned, no talk) and a
-- maelstrom that needed a diving helmet; about 60 portals of the grounds had no destination and there was
-- no quest logic.
--
-- Sources: TibiaWiki BR "Twenty Miles Beneath the Sea Quest" (dialogue, the five song lines, the slumber
-- line); TibiaWiki EN "Twenty Miles Beneath the Sea Quest/Spoiler" (routes, positions, item ids, server
-- messages), "Mr Brandon/Transcripts", "Seacrest Grounds", the item pages.
--
-- * Mr Brandon (EN 33548,31864,7): `assist`, `yes`; the maelstrom behind him takes everyone down (no
--   helmet needed, both wikis: drowning damage without one) to the Guardian; `wedding ring`; `mission`
--   for the slabs, `yeo`; `mission` for the Sea Ear (the maelstrom then leads to the seashell cave).
-- * Guardian of the Deep Seas (EN 33547,31632,14): `wedding ring`, `something`, `will`; `mission`.
-- * Mission 1: a skull from each of the 5 piles of bones (EN spots), used on a nacre altar or a stone
--   snake shrine; the cursed gold on the hoard in the far south moves you behind it to the chest with
--   the ring. Brandon's reward opens the western portal (Lost Mountains).
-- * Mission 2: the blue slab in the sunken ship's chest, the yellow one in the Secret Shrine (a maze of
--   whirlpools, different for every player, EN), the red one from Yeo for a seacrest pearl; the Guardian
--   gives the first two back and they go on the broken nacre altars below him (blue left, yellow
--   centre, red right; each altar is whole for a minute, EN). Opens the eastern portal (Sunken City).
-- * Mission 3: the Sea Ear in one of the large seashells of Brandon's cave (EN: the others hold broken
--   shells, a fishbone and fish, nothing or a crab); the Sea Ear on the strange statues of the Sunken City
--   for the five lines of the song (BR/EN; a statue slumbers for a while after each try); the Sea Ear on
--   the ancient sundial for the time compass; `compass`. Opens the northern portal (Birthing Grounds).
-- * Ours: every portal destination the wikis do not give (the network, the whirlpool maze, the cave), the
--   chance of a song line (50%) and the statue's slumber (3 min), the shells' 2 minutes, every line
--   marked ours. The Fire-Feathered Serpent world change (second part) is not built yet: its two portals
--   are closed.
--
-- Loaded from lib/others/load.lua.

FamilyTwentyMiles = {
	ring = 21745,
	gold = 21746,
	blue = 21753,
	yellow = 21861,
	red = 21862,
	seaEar = 21754,
	skull = 21770,
	compass = 21795,
	pearl = 21747,
	brokenShells = 21395,
	TOPIC = 5101,
	guardianSpot = Position(33545, 31634, 14), -- where the maelstrom and the shortcut put you, by the Guardian
	hub = Position(33555, 31630, 13), -- the four portals above the Guardian
	brandonSpot = Position(33545, 31860, 7), -- by the maelstrom behind Brandon
	cave = Position(33721, 31815, 8),
	box = { x1 = 33370, y1 = 31600, x2 = 33580, y2 = 31910, z1 = 13, z2 = 15 },
	bones = { Position(33456, 31648, 15), Position(33444, 31741, 15), Position(33500, 31775, 15), Position(33474, 31859, 15), Position(33411, 31890, 15) },
	hoardBox = { x1 = 33415, y1 = 31885, x2 = 33430, y2 = 31899, z = 15 },
	hoardRoom = Position(33422, 31896, 15),
	ringChest = Position(33422, 31898, 15),
	shipChest = Position(33434, 31765, 15),
	shrineChest = Position(33391, 31794, 15),
	altars = { Position(33538, 31636, 15), Position(33542, 31636, 15), Position(33546, 31636, 15) }, -- left, centre, right
	sundial = Position(33394, 31889, 15),
	shells = { Position(33709, 31804, 8), Position(33709, 31810, 8), Position(33719, 31831, 8), Position(33723, 31819, 8), Position(33740, 31817, 8) },
	shellTime = 120, -- seconds a shell stays open (ours)
	songChance = 50, -- percent (ours)
	slumber = 180, -- seconds (ours)
	song = {
		"<...Where time's body is...>",
		"<...a wandering shadow...>",
		"<...trapped in stone, ...>",
		"<...the tail of fire ends ...>",
		"<... with my slumber beneath the sea.>",
	},
}

local M = FamilyTwentyMiles
M.slabs = { M.blue, M.yellow, M.red }

local function S()
	return Storage.Quest.U10_70.TwentyMilesBeneathTheSea
end
M.S = S

function M.get(player, key)
	return math.max(0, player:getStorageValue(S()[key]))
end

function M.set(player, key, value)
	player:setStorageValue(S()[key], value)
end

-- Mission storage (also the quest log state):
-- 1 Brandon asked, 2 skulls to lay, 4 cursed gold, 5 ring found, 6 ring returned (west open),
-- 7 Brandon's slabs, 8 find the first slab, 9 second slab (shrine open), 10 see Brandon, 11 Yeo,
-- 12 red slab, 13 lay the slabs, 15 mission 2 done (east open), 16 ask Brandon about the Sea Ear,
-- 17 seashell cave, 18 Sea Ear found, 19 Brandon saw it, 20 listen to the statues, 21 song complete,
-- 22 the sundial, 23 time compass, 24 done (north open)
function M.mission(player)
	return M.get(player, "Mission")
end

function M.advance(player, value)
	if M.mission(player) < value then
		M.set(player, "Mission", value)
	end
end

local function key(pos)
	return pos.x .. "," .. pos.y .. "," .. pos.z
end
M.key = key

local function inBox(pos, b)
	return pos.x >= b.x1 and pos.x <= b.x2 and pos.y >= b.y1 and pos.y <= b.y2 and pos.z >= (b.z1 or b.z) and pos.z <= (b.z2 or b.z)
end
M.inBox = inBox

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
	return true
end

local function bitSet(player, k, index)
	local v = M.get(player, k)
	local f = bit.lshift(1, index - 1)
	return bit.band(v, f) ~= 0, v, f
end

-- ---------------------------------------------------------------- Mr Brandon

M.brandonLore = {
	job = "I, er, am some kind of ferryman to the bottom of the sea. Warden of the sea currents. But I really don't like to go back down there. <swallows hard> You can go on your own, you know.",
	roswitha = "Ah, my beloved wife. Quick temper and a warm smile. How I miss her cooking.",
	name = "Technically, I am Wilbur Fortescue Brandon, but that doesn't mean much now.",
	now = "After what I have seen, there is no going back. They'll haunt me and everyone here. I have to stand guard!",
	guard = "I... I can't tell you.",
	tell = "No, really! You would not believe me anyway.",
	believe = "That's what you say now, but I know you won't believe me. It is simply too monstrous.",
	monstrous = "I have been deep, deep down below. I have seen them.",
	them = "I can't say their name or they'll come for me. And if they come for me, they will come for the city, too. I cannot let that happen.",
	come = {
		"I entered their lair and took some ... things. I should not have done that, but I did. And they awoke. They came after me.... I fled. ...",
		"The mist closed around me like a choking fist. I remember the high sea, rolling and roaring and then - pain. Blackness. When I woke up, I was here. Home.",
	},
	things = "I couldn't help it! We are poor, you know! I thought they'd fetch a good price if I sold them to the jeweller. <sigh> But I think they are cursed. They should be brought back where they came from.",
	back = {
		"On the bottom of the ocean, there are sunken treasures and strange sites between the reefs. Wrecked ships lie there ... lost cities, drowned temples. ...",
		"When I was there, I saw these things, gleaming like lost jewels upon ancient altars. I thought, what use are they to the drowned? So I took them. But then, They awoke and hunted me. I fled in panic. ...",
		"But I couldn't let go of the strange things I found. The gold, the nacre... it was so beautiful! Those others... They howled behind me. ...",
		"I went wild with fear and swam for my life, dropping the cursed gold. They grabbed me... They roared with anger, and pulled at me with a hundred cold and slimy tentacles, snatching at me. They tore off my wedding ring. Then I escaped. ...",
		"Now, I am doomed. Stranded between life and death for a bleak eternity. <sigh>",
	},
}

function M.brandonGreeting(player)
	local m = M.mission(player)
	if m == 0 then
		return "Hello. Stranded here, like me? <sigh> Maybe you could {assist} me in my tragic lot."
	elseif m >= 7 and m <= 15 then
		return "Ah, hello my friend! What brings you up here?"
	end
	return "Hello again. You want to go down? Go ahead. I certainly wouldn't <shudders>"
end

function M.brandon(npc, creature, message, npcHandler)
	if not Family.twentyMiles then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local m = M.mission(player)
	if npcHandler:getTopic(id) == M.TOPIC then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			M.advance(player, 1)
			return say(npcHandler, npc, creature, {
				"Thank you. I ask much, I know. You will meet horrible creatures that never saw the light of day, and they will come at you. But I hope you will make it back alive. ...",
				"Swim into the maelstrom behind me, and you will reach the bottom of the ocean.",
			})
		end
		return say(npcHandler, npc, creature, "<sigh> I understand. Nobody wants to go down there.") -- ours
	end
	if m == 0 and MsgContains(message, "assist") then
		npcHandler:setTopic(id, M.TOPIC)
		return say(npcHandler, npc, creature, {
			"I have taken a few... things from down there, and now They are angry at me and haunt me. ...",
			"I dare not go back down there, but I lost my wedding ring! It means the world to me. ...",
			"I will grant you access to places deep under the sea, if you bring back my wedding ring - would you go looking for it at the bottom of the sea?",
		})
	end
	if MsgContains(message, "wedding ring") or (MsgContains(message, "ring") and player:getItemCount(M.ring) > 0) then
		if m >= 5 and m < 6 and player:removeItem(M.ring, 1) then
			M.advance(player, 6)
			return say(npcHandler, npc, creature, {
				"My ring! It is indeed my ring! Thank you so much! At least something of my old life is now with me. About your reward - ...",
				"I can influence sea currents and vortices a little bit. Enough to send you to interesting places - you can use the vortex anytime to reach the southwestern Seacrest ground. ...",
				"Also - ahem. If you could spare the time... maybe you could help me with something else? Just tell me when you're interested in another {mission}.",
			})
		end
		if m >= 1 and m < 6 then
			return say(npcHandler, npc, creature, "My ring! It lies somewhere at the bottom of the sea. Swim into the maelstrom behind me.") -- ours
		end
	end
	if MsgContains(message, "yeo") and m >= 11 then
		return say(npcHandler, npc, creature, {
			"We used to be friends before I... changed. He's a hardened fisher man, and particularly loves clams and sea shells and nacre. ...",
			"Lives at Rathleton harbour - always mending nets or caulking boats or some such.",
		})
	end
	if MsgContains(message, "mission") then
		if m == 6 then
			M.advance(player, 7)
			return say(npcHandler, npc, creature, {
				"Gosh, thanks a ton, mate! I know I have not been the most considerate of men in my lifetime, but I am not unredeemable... I hope. ...",
				"Ahem. Er. I, uh, well, the cursed gold is not all I stole and why I am cursed. ...",
				"And maybe, if I help you find the three nacre altar slabs, maybe I will be allowed to die after I did my penance. ...",
				"Now, those slabs. I, er, was in a hurry and wanted to store them somewhere safe. I hid one in a barrel in a sunken ship, but I lost the other two. ...",
				"Sorry, but that's all I remember - besides the tentacled thing with a hundred eyes coming after me. <shudders> ...",
				"Maybe the Guardian knows more. Anyway, thanks for helping me. I depend on you, friend.",
			})
		elseif m == 10 or m == 11 then
			M.advance(player, 11)
			return say(npcHandler, npc, creature, "Ah! The third was washed ashore by the currents? Probably fished up by someone? Let me think. The only one I know of who casts his nets for clams here on the shore is old {Yeo}.")
		elseif m == 16 or m == 17 then
			M.advance(player, 17)
			return say(npcHandler, npc, creature, {
				"You're on a mission from the Guardian? What about? Oh. Er. The what? A Sea SPEAR? Never heard of it. The Seer? Who? Oh, the SEA EAR. Sorry. ...",
				"Yes, er. About that Sea Ear. It's really a cute little thing. Can't really remember where I put it. ...",
				"Well, that weapon you're aiming at me is not really helping me remember, but... I see your point! ...",
				"Alright, I think I remember. When running away from the .... THINGS, a maelstrom washed me into this cave. Lots of shipwrecks and seashells. So I stuffed the Sea Ear into one of these seashells and ran for it. ...",
				"I think I can change the maelstrom here so that it'll bring you there. Just swim into the maelstrom behind me.",
			})
		elseif m == 18 and player:getItemCount(M.seaEar) > 0 then
			M.advance(player, 19)
			return say(npcHandler, npc, creature, {
				"Yes, that's the Sea Ear. Isn't it pretty? See the nacre glimmer and shimmer! The soft hues! The... ...",
				"Ahem. I mean, I took good care of it, didn't I? You can tell the Guardian I only put in a safe place.",
			})
		elseif m >= 1 and m < 6 then
			return say(npcHandler, npc, creature, "My wedding ring! Please find it at the bottom of the sea.") -- ours
		elseif m >= 7 then
			return say(npcHandler, npc, creature, "Go ahead, talk to the Guardian down there. I certainly won't.") -- ours
		end
	end
	for word, text in pairs(M.brandonLore) do
		if MsgContains(message, word) then
			return say(npcHandler, npc, creature, text)
		end
	end
	return false
end

-- ---------------------------------------------------------------- Guardian of the Deep Seas

function M.guardian(npc, creature, message, npcHandler)
	if not Family.twentyMiles then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local m = M.mission(player)
	local topic = npcHandler:getTopic(id)
	if topic == M.TOPIC + 1 then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "will") or MsgContains(message, "yes") then
			M.advance(player, 2)
			return say(npcHandler, npc, creature, {
				"Good. Find the skulls of my 5 loyal seamen and lay them to rest on the altars of the Dark Powers. ...",
				"There are many altars near the smoking rift of volcanoes. Use a skull on a stone snake shrine, or lay it on a nacre altar to set its soul free. ...",
				"Return to me when you have lain all 5 skulls to rest.",
			})
		end
		return say(npcHandler, npc, creature, "Then leave the abyss in peace.") -- ours
	elseif topic == M.TOPIC + 2 then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") and M.get(player, "Laid") >= 5 then
			player:addItem(M.gold, 1)
			M.advance(player, 4)
			return say(npcHandler, npc, creature, {
				"You did indeed! I had not thought it possible. Well then. Brandon may not be worthy of redemption, but it is noble of you to undertake it for him. ...",
				"Take this cursed gold. Use it on the hoard of cursed gold you find in the south, far from here. ...",
				"Behind the hoard stands the treasure chest that holds Brandon's wedding ring.",
			})
		end
		return say(npcHandler, npc, creature, "Return to me when you have lain all 5 skulls to rest.")
	end
	if MsgContains(message, "wedding ring") and m >= 1 and m < 4 then
		return say(npcHandler, npc, creature, {
			"No use! It is where the cursed hoard of gold lies, far from here, in the south. ...",
			"To reach the chest that holds the ring, you have sacrifice some of the stolen cursed gold to the hoard. But I will not entrust it to you without you proving your worth to me - you must do {something} for me first.",
		})
	end
	if (MsgContains(message, "something") or MsgContains(message, "assist") or (MsgContains(message, "mission") and m == 1)) and m == 1 then
		npcHandler:setTopic(id, M.TOPIC + 1)
		return say(npcHandler, npc, creature, {
			"The loyal men who went down with me - their bones still lie at the bottom of the sea, gnawed clean by blood crabs and sharks, mourned for by their tormented spirits! ...",
			"Find their bones and offer them on the altars you find near them. ...",
			"When the Dark Powers have released the tormented spirits of my men, then I will give you the cursed gold so you may offer it to the hoard, and get the wedding ring. {Will} you do this?",
		})
	end
	if MsgContains(message, "quest") and m == 15 then
		M.advance(player, 16)
		return say(npcHandler, npc, creature, {
			"I want you to retrieve the protective charm of the sunken city. Tell me, did Brandon mention what else he took when he robbed the nacre altar slabs? He didn't? I thought so. ...",
			"Then you will need to ask him first what he did with the Sea Ear. It is the protective seal of the charm that defends the Sunken City. Brandon broke that charm by stealing the Sea Ear. ...",
			"As a consequence, the statues' protective song was broken and the time compass disappeared and must be found again. ...",
			"Go to Brandon and ask him where he hid the Sea Ear! Make him give it to you, and then, go to the Sunken City and listen to the statues with it so we may find the compass' secret hiding place.",
		})
	end
	if MsgContains(message, "compass") and m == 23 and player:removeItem(M.compass, 1) then
		M.advance(player, 24)
		return say(npcHandler, npc, creature, {
			"That's it! It truly is! The compass has returned to the Guardian! Now, the souls of the Sunken City are safe again! ...",
			"Thank you. You have earned the right to enter the last Seacrest ground, the birthing grounds of the seacrests. ...",
			"Be careful though. The searcrests are holy beasts, and killing too many will incite the wrath of the Fire-Feathered Serpent.",
		})
	end
	if not MsgContains(message, "mission") then
		return false
	end
	if m == 0 then
		return say(npcHandler, npc, creature, "The Fire-Feathered Serpent is dreaming fitfully. Tread lightly, whatever may be your mission.")
	elseif m == 2 or m == 3 then
		if M.get(player, "Laid") >= 5 then
			npcHandler:setTopic(id, M.TOPIC + 2)
			return say(npcHandler, npc, creature, "Have you laid all five seamen to rest on the altars?")
		end
		return say(npcHandler, npc, creature, "Return to me when you have lain all 5 skulls to rest.")
	elseif m == 4 then
		if player:getItemCount(M.gold) == 0 and player:getItemCount(M.ring) == 0 then
			player:addItem(M.gold, 1)
			return say(npcHandler, npc, creature, "You lost the cursed gold? Take this, and do not lose it again. Use it on the hoard of cursed gold in the south.") -- ours
		end
		return say(npcHandler, npc, creature, "Use the cursed gold on the hoard of cursed gold you find in the south, far from here. Behind the hoard stands the treasure chest that holds Brandon's wedding ring.")
	elseif m == 5 or m == 6 then
		return say(npcHandler, npc, creature, "Bring Brandon his ring, then.") -- ours
	elseif m == 7 then
		M.advance(player, 8)
		return say(npcHandler, npc, creature, {
			"So Brandon sent you down again to do something for him? Typical. He always liked to let others do the dirty work. ...",
			"Well, before I tell you ANYTHING about where the sacred slabs might be, you will have to prove your good will. Return to me when you have found the first nacre slab to prove you are in earnest.",
		})
	elseif m == 8 then
		if player:removeItem(M.blue, 1) then
			M.advance(player, 9)
			return say(npcHandler, npc, creature, "So you really want to find the slabs it seems. I'll keep this one for now. Go look for the second one in the Secret Shrine in the southwestern Seacrest grounds. It was hidden there for safety. You may enter there now for this quest.")
		end
		return say(npcHandler, npc, creature, "Return to me when you have found the first nacre slab to prove you are in earnest.")
	elseif m == 9 then
		if player:removeItem(M.yellow, 1) then
			M.advance(player, 10)
			return say(npcHandler, npc, creature, "So you found it. Well done. I'll keep it here for now. Now go find the third missing slab! Brandon might know where the currents have taken it. Go see him!")
		end
		return say(npcHandler, npc, creature, "Go look for the second slab in the Secret Shrine in the southwestern Seacrest grounds.") -- ours
	elseif m == 10 or m == 11 then
		return say(npcHandler, npc, creature, "Brandon might know where the currents have taken the third slab. Go see him!") -- ours
	elseif m == 12 then
		if player:getItemCount(M.red) == 0 then
			return say(npcHandler, npc, creature, "Where is the third slab?") -- ours
		end
		player:addItem(M.blue, 1)
		player:addItem(M.yellow, 1)
		M.advance(player, 13)
		return say(npcHandler, npc, creature, {
			"You found it! Ah, wonderful. It has suffered somewhat, but I believe if it's back in its proper place, the altar slabs will become as good as new. ...",
			"Go down the stairs, to the altar room right underneath. Lay each of the three nacre slabs on an altar - blue on the left, yellow in the centre, red to the right. Then come back to receive your reward.",
		})
	elseif m == 13 or m == 14 then
		if M.get(player, "Altars") == 7 then
			M.advance(player, 15)
			return say(npcHandler, npc, creature, {
				"Well done. The Dark Powers will be beseeched now, for a while at least. You can tell Brandon that. ...",
				"And as for you, you may enter the Sunken City as a reward. There is another {quest} that goes with it, if you feel up to it.",
			})
		end
		for i, slab in ipairs(M.slabs) do
			if not bitSet(player, "Altars", i) and player:getItemCount(slab) == 0 then
				player:addItem(slab, 1) -- ours: a lost slab
			end
		end
		return say(npcHandler, npc, creature, "Go down the stairs, to the altar room right underneath. Lay each of the three nacre slabs on an altar - blue on the left, yellow in the centre, red to the right. Then come back to receive your reward.")
	elseif m == 15 then
		return say(npcHandler, npc, creature, "You may enter the Sunken City. There is another {quest} that goes with it, if you feel up to it.") -- ours
	elseif m >= 16 and m <= 18 then
		return say(npcHandler, npc, creature, "Go to Brandon and ask him where he hid the Sea Ear!") -- ours
	elseif m == 19 then
		M.advance(player, 20)
		return say(npcHandler, npc, creature, {
			"Now that you have acquired the Sea Ear, we can begin. Go to the Sunken City and use the Sea Ear with the statues. ...",
			"They will tell you where to find the time compass. When you have found the time compass, bring it to me.",
		})
	elseif m == 20 then
		return say(npcHandler, npc, creature, "Go to the Sunken City and use the Sea Ear with the statues. They will tell you where to find the time compass.") -- ours
	elseif m == 21 or m == 22 then
		M.advance(player, 22)
		return say(npcHandler, npc, creature, "Ah, that is easy. The compass is hidden beneath the Eternity Altar, the most southern altar, at the end of the volcano ridge. Go and fetch it!")
	elseif m == 23 then
		return say(npcHandler, npc, creature, "Do you have the {compass}?") -- ours
	elseif m >= 24 then
		return say(npcHandler, npc, creature, "The Fire-Feathered Serpent is dreaming fitfully. Tread lightly, whatever may be your mission.")
	end
	return false
end

-- ---------------------------------------------------------------- Yeo

function M.yeo(npc, creature, message, npcHandler)
	if not Family.twentyMiles then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	local id = player:getId()
	local m = M.mission(player)
	if npcHandler:getTopic(id) == M.TOPIC + 10 then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			if not player:removeItem(M.pearl, 1) then
				return say(npcHandler, npc, creature, "Hrm. I don't see any mother-of-pearl orb.") -- ours
			end
			player:addItem(M.red, 1)
			M.advance(player, 12)
			return say(npcHandler, npc, creature, "Yes, that's it! Look at it! Isn't it a beauty? Thanks, friend. And here you go - the nacre slab.")
		end
		return say(npcHandler, npc, creature, "Hrm. Then no deal.") -- ours
	end
	if m ~= 11 then
		return false
	end
	if MsgContains(message, "fishing") then
		return say(npcHandler, npc, creature, "I find the most {interesting} stuff, you know. Broken statues. Stones. Clams. Nacre. Bones. Fish. I sell the fish and clams and keep the rest.")
	end
	local asked = M.get(player, "Yeo") > 0
	if MsgContains(message, "use") then
		M.set(player, "Yeo", 1)
		return say(npcHandler, npc, creature, "You want this broken nacre slab? Oh, but I want something for it in exchange, friend! You bring me a big shiny mother-of-pearl orb like I saw in my dream with that seacrest thing, and it's a deal.")
	end
	if MsgContains(message, "nacre slab") or MsgContains(message, "seacrest pearl") or MsgContains(message, "interesting") or MsgContains(message, "pearl") then
		if asked and not MsgContains(message, "interesting") then
			npcHandler:setTopic(id, M.TOPIC + 10)
			return say(npcHandler, npc, creature, "You brought me that mother-of-pearl orb I asked you about?")
		end
		return say(npcHandler, npc, creature, {
			"Sure. This nacre slab here's my latest found. I went to where the cliffs are really rough and there are some mean currents, and cast my net. ...",
			"The nacre slab looks real nice - but it's cracked and doesn't seem to be of any {use}. I just like to look at it. Been even dreaming about it, and some strange maned snakelike beasts.",
		})
	end
	return false
end

-- ---------------------------------------------------------------- items and objects

-- a pile of bones of a drowned seaman; returns true when handled, false to open the pile as usual
function M.useBones(player, position)
	local m = M.mission(player)
	for i, p in ipairs(M.bones) do
		if p == position then
			if m < 2 or m >= 4 then
				return false
			end
			local has, v, f = bitSet(player, "Bones", i)
			if has then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already taken the skull from these bones.") -- ours
				return true
			end
			if not player:addItem(M.skull, 1) then
				return true
			end
			M.set(player, "Bones", bit.bor(v, f))
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a drowned seaman's skull.") -- ours
			return true
		end
	end
	return false
end

-- the skull on a nacre altar or a stone snake shrine
function M.laySkull(player, item, target)
	if not target or not target.itemid or (target.itemid ~= 21796 and target.itemid ~= 21751) then
		return false
	end
	if not inBox(target:getPosition(), M.box) then
		return false
	end
	item:remove(1)
	M.set(player, "Laid", M.get(player, "Laid") + 1)
	target:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The skull crumbles into fine sand and is gone. This soul has been laid to rest.")
	return true
end

-- the cursed gold on the hoard
function M.useGold(player, item, target, toPosition)
	if not toPosition or not inBox(toPosition, M.hoardBox) then
		return false
	end
	if not target or not target.itemid or not (target.itemid == 21750 or (target.itemid >= 21914 and target.itemid <= 21931)) then
		return false
	end
	item:remove(1)
	toPosition:sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:teleportTo(M.hoardRoom)
	M.hoardRoom:sendMagicEffect(CONST_ME_WATERSPLASH)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The hoard swallows the cursed gold and the current pulls you behind it.") -- ours
	return true
end

local function chestGives(player, itemId, text)
	if not player:addItem(itemId, 1) then
		return false
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	return true
end

function M.useChest(player, position)
	local m = M.mission(player)
	if position == M.ringChest then
		if m == 4 and chestGives(player, M.ring, "You have found Brandon's wedding ring.") then
			M.advance(player, 5)
			return true
		end
	elseif position == M.shipChest then
		local has, v, f = bitSet(player, "Slabs", 1)
		if m >= 7 and m <= 8 and (not has or player:getItemCount(M.blue) == 0 and m == 8) and chestGives(player, M.blue, "You have found a nacre slab.") then
			M.set(player, "Slabs", bit.bor(v, f))
			return true
		end
	elseif position == M.shrineChest then
		local has, v, f = bitSet(player, "Slabs", 2)
		if m == 9 and (not has or player:getItemCount(M.yellow) == 0) and chestGives(player, M.yellow, "You have found a nacre slab.") then
			M.set(player, "Slabs", bit.bor(v, f))
			return true
		end
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The chest is empty.")
	return true
end

-- a slab on a broken nacre altar
function M.useSlab(player, item, target, toPosition)
	if not target or not target.itemid or target.itemid ~= 21787 then
		return false
	end
	for i, p in ipairs(M.altars) do
		if p == toPosition then
			if M.mission(player) < 13 then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The Guardian has not told you to lay the slab here yet.") -- ours
				return true
			end
			if item.itemid ~= M.slabs[i] then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The slab does not fit into this altar.") -- ours
				return true
			end
			local _, v, f = bitSet(player, "Altars", i)
			item:remove(1)
			M.set(player, "Altars", bit.bor(v, f))
			target:transform(21796)
			toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The nacre slab fits perfectly and the altar shimmers in unearthly beauty again.") -- ours
			addEvent(function(pos)
				local t = Tile(pos)
				local altar = t and t:getItemById(21796)
				if altar then
					altar:transform(21787)
				end
			end, 60 * 1000, toPosition)
			return true
		end
	end
	return false
end

-- the large seashells of Brandon's cave
M.openShells = {}

function M.seaEarShell(player)
	return (player:getGuid() % #M.shells) + 1
end

function M.useShell(player, item, position)
	if item.itemid ~= 21798 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "It is empty.")
		return true
	end
	local index
	for i, p in ipairs(M.shells) do
		if p == position then
			index = i
		end
	end
	if not index then
		return false
	end
	item:transform(21799)
	addEvent(function(pos)
		local t = Tile(pos)
		local shell = t and t:getItemById(21799)
		if shell then
			shell:transform(21798)
		end
	end, M.shellTime * 1000, position)
	local m = M.mission(player)
	if m == 17 and index == M.seaEarShell(player) and player:getItemCount(M.seaEar) == 0 then
		player:addItem(M.seaEar, 1)
		M.advance(player, 18)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found the Sea Ear!") -- ours
		return true
	end
	local roll = math.random(4) -- EN: broken shells, a fishbone and two fish, nothing or a crab
	if roll == 1 then
		player:addItem(M.brokenShells, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found some broken shells.")
	elseif roll == 2 then
		player:addItem(3111, 1)
		player:addItem(3578, 2)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found a fishbone and two fish.")
	elseif roll == 3 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The seashell is empty.")
	else
		Game.createMonster("Crab", position, true, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A crab was hiding in the seashell!") -- ours
	end
	return true
end

-- the Sea Ear on a strange statue of the Sunken City or on the ancient sundial
M.statues = {
	{ 33495, 31771, 14 }, { 33495, 31772, 14 }, { 33497, 31771, 14 }, { 33497, 31772, 14 }, { 33502, 31771, 14 }, { 33502, 31772, 14 }, { 33504, 31771, 14 }, { 33504, 31772, 14 },
	{ 33507, 31749, 14 }, { 33512, 31748, 14 }, { 33512, 31749, 14 }, { 33529, 31772, 13 }, { 33529, 31773, 13 }, { 33531, 31723, 14 }, { 33531, 31724, 14 }, { 33542, 31758, 14 },
	{ 33542, 31759, 14 }, { 33545, 31792, 15 }, { 33545, 31793, 15 }, { 33548, 31805, 15 }, { 33548, 31806, 15 }, { 33551, 31797, 14 }, { 33551, 31798, 14 }, { 33552, 31792, 15 },
	{ 33552, 31793, 15 }, { 33553, 31678, 14 }, { 33553, 31679, 14 }, { 33555, 31775, 13 }, { 33555, 31776, 13 }, { 33556, 31670, 14 }, { 33556, 31671, 14 }, { 33557, 31797, 14 },
	{ 33557, 31798, 14 }, { 33559, 31670, 14 }, { 33559, 31671, 14 }, { 33566, 31704, 13 }, { 33566, 31705, 13 }, { 33566, 31719, 13 }, { 33566, 31720, 13 },
}
M.statueSet = {}
do
	local all = {}
	for _, s in ipairs(M.statues) do
		all[s[1] .. "," .. s[2] .. "," .. s[3]] = true
	end
	for _, s in ipairs(M.statues) do
		-- a statue is two squares (top and bottom): both answer as one statue (the top square's key)
		local top = all[s[1] .. "," .. (s[2] - 1) .. "," .. s[3]] and (s[2] - 1) or s[2]
		M.statueSet[s[1] .. "," .. s[2] .. "," .. s[3]] = s[1] .. "," .. top .. "," .. s[3]
	end
end
M.sleeping = {}

function M.useSeaEar(player, target, toPosition)
	if not toPosition then
		return false
	end
	local m = M.mission(player)
	if toPosition == M.sundial then
		if m == 22 then
			if player:addItem(M.compass, 1) then
				M.advance(player, 23)
				toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Beneath the sundial you find the time compass.") -- ours
			end
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nothing happens.") -- ours
		end
		return true
	end
	local k = M.statueSet[key(toPosition)]
	if not k then
		return false
	end
	if m ~= 20 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You hear only the murmur of the sea.") -- ours
		return true
	end
	local sleepKey = player:getGuid() .. ":" .. k
	if (M.sleeping[sleepKey] or 0) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "<The statue seems to slumber. Maybe you should return later.>")
		return true
	end
	M.sleeping[sleepKey] = os.time() + M.slumber
	local heard = M.get(player, "Song")
	local missing = {}
	for i = 1, #M.song do
		if bit.band(heard, bit.lshift(1, i - 1)) == 0 then
			missing[#missing + 1] = i
		end
	end
	if #missing == 0 or math.random(100) > M.songChance then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "<The statue's song is too faint to make out.>") -- ours
		return true
	end
	local line = missing[math.random(#missing)]
	heard = bit.bor(heard, bit.lshift(1, line - 1))
	M.set(player, "Song", heard)
	toPosition:sendMagicEffect(CONST_ME_SOUND_BLUE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, M.song[line])
	if heard == 31 then
		M.advance(player, 21)
	end
	return true
end

-- ---------------------------------------------------------------- portals

-- vortex down / geyser up, found on the map (a geyser takes you up next to its vortex, the vortex down
-- next to its geyser; EN's routes confirm the pairing)
M.pairs = {
	{ vortex = Position(33384, 31816, 14), geyser = Position(33383, 31818, 15), down = Position(33383, 31819, 15), up = Position(33384, 31817, 14) },
	{ vortex = Position(33411, 31823, 14), geyser = Position(33412, 31823, 15), down = Position(33412, 31824, 15), up = Position(33412, 31823, 14) },
	{ vortex = Position(33418, 31665, 13), geyser = Position(33419, 31664, 14), down = Position(33420, 31664, 14), up = Position(33419, 31665, 13) },
	{ vortex = Position(33425, 31796, 14), geyser = Position(33427, 31796, 15), down = Position(33427, 31797, 15), up = Position(33425, 31797, 14) },
	{ vortex = Position(33443, 31786, 14), geyser = Position(33443, 31788, 15), down = Position(33443, 31789, 15), up = Position(33443, 31787, 14) },
	{ vortex = Position(33450, 31629, 13), geyser = Position(33449, 31631, 14), down = Position(33450, 31631, 14), up = Position(33450, 31630, 13) },
	{ vortex = Position(33450, 31812, 14), geyser = Position(33451, 31812, 15), down = Position(33451, 31813, 15), up = Position(33450, 31813, 14) },
	{ vortex = Position(33497, 31849, 14), geyser = Position(33495, 31848, 15), down = Position(33495, 31849, 15), up = Position(33497, 31850, 14) },
	{ vortex = Position(33510, 31774, 14), geyser = Position(33512, 31773, 15), down = Position(33512, 31774, 15), up = Position(33510, 31773, 14) },
	{ vortex = Position(33535, 31745, 14), geyser = Position(33536, 31746, 15), down = Position(33536, 31747, 15), up = Position(33536, 31745, 14) },
	{ vortex = Position(33563, 31746, 14), geyser = Position(33565, 31747, 15), down = Position(33565, 31746, 15), up = Position(33563, 31747, 14) },
}

-- fixed portals: destination and the mission value needed (nil = open)
M.portals = {
	["33552,31628,13"] = { to = Position(33399, 31806, 13), need = 6 }, -- west: Lost Mountains (mission 1)
	["33558,31628,13"] = { to = Position(33551, 31773, 13), need = 15 }, -- east: Sunken City (mission 2)
	["33555,31624,13"] = { to = Position(33422, 31664, 13), need = 24 }, -- north: Birthing Grounds (mission 3)
	["33399,31808,13"] = { to = M.hub }, -- back from the Lost Mountains
	["33562,31775,13"] = { to = M.hub }, -- back from the Sunken City
	["33423,31663,13"] = { to = M.hub }, -- back from the Birthing Grounds
	["33424,31900,15"] = { to = M.hub }, -- out of the hoard room (EN: back at the four teleporters)
	["33406,31862,14"] = { to = M.guardianSpot }, -- the shortcut by the Eternity Altar (EN)
	["33398,31805,15"] = { maze = true, need = 9 }, -- into the Secret Shrine
	["33395,31804,15"] = { to = Position(33398, 31806, 15) }, -- out of the Secret Shrine
	["33418,31665,15"] = { to = Position(33420, 31664, 14) }, -- the geyser under the Birthing Grounds' vortex
	["33553,31624,15"] = { closed = true }, -- world change: the Orb of Darkness Eternal (not built yet)
	["33476,31711,15"] = { closed = true }, -- world change: the Everhungry Altar (not built yet)
	["33479,31699,15"] = { to = Position(33475, 31711, 15) },
}
for _, p in ipairs(M.pairs) do
	M.portals[key(p.vortex)] = { to = p.down }
	M.portals[key(p.geyser)] = { to = p.up }
end

-- the Secret Shrine: a maze of whirlpools, different for each player (EN); the cells as found on the map
M.maze = {
	start = 20, -- the cell the entrance puts you in
	exit = 10, -- the cell with the way out (the forcefield at 33395,31804)
	center = { 14, 15 }, -- by the chest
	cells = {
		{ land = Position(33385, 31803, 15), vortices = { "33386,31803,15" } },
		{ land = Position(33386, 31807, 15), vortices = { "33387,31808,15" } },
		{ land = Position(33387, 31792, 15), vortices = { "33387,31790,15", "33387,31794,15", "33389,31794,15" } },
		{ land = Position(33386, 31798, 15), vortices = { "33388,31798,15" } },
		{ land = Position(33386, 31800, 15), vortices = { "33387,31800,15" } },
		{ land = Position(33388, 31800, 15), vortices = { "33387,31800,15" } },
		{ land = Position(33389, 31786, 15), vortices = { "33390,31786,15" } },
		{ land = Position(33391, 31806, 15), vortices = { "33391,31807,15" } },
		{ land = Position(33392, 31785, 15), vortices = { "33390,31786,15", "33393,31785,15" } },
		{ land = Position(33392, 31802, 15), vortices = { "33391,31801,15", "33393,31803,15" } },
		{ land = Position(33391, 31791, 15), vortices = { "33392,31791,15" } },
		{ land = Position(33393, 31792, 15), vortices = { "33392,31791,15", "33392,31793,15" } },
		{ land = Position(33393, 31797, 15), vortices = { "33392,31795,15" } },
		{ land = Position(33391, 31793, 15), vortices = { "33390,31793,15", "33392,31793,15" } },
		{ land = Position(33391, 31795, 15), vortices = { "33390,31795,15", "33392,31795,15" } },
		{ land = Position(33395, 31789, 15), vortices = { "33396,31788,15" } },
		{ land = Position(33396, 31795, 15), vortices = { "33395,31796,15", "33393,31794,15" } },
		{ land = Position(33398, 31794, 15), vortices = { "33397,31792,15", "33399,31794,15" } },
		{ land = Position(33400, 31789, 15), vortices = { "33399,31788,15" } },
		{ land = Position(33398, 31799, 15), vortices = { "33399,31798,15" } },
	},
}
M.mazeVortex = {}
for _, c in ipairs(M.maze.cells) do
	for _, v in ipairs(c.vortices) do
		M.mazeVortex[v] = true
	end
end

-- per player: vortex key -> cell index; a random path of 5 cells leads from the start to the chest
M.mazeCache = {}
function M.mazeFor(player)
	local guid = player:getGuid()
	if M.mazeCache[guid] then
		return M.mazeCache[guid]
	end
	local cells = M.maze.cells
	local isCenter = { [M.maze.center[1]] = true, [M.maze.center[2]] = true }
	local seed = guid * 7919 + 17
	local function rnd(n)
		seed = (seed * 1103515245 + 12345) % 2147483648
		return (math.floor(seed / 65536) % n) + 1
	end
	for _ = 1, 100 do
		local map = {}
		local plain = {}
		for i = 1, #cells do
			if not isCenter[i] then
				plain[#plain + 1] = i
			end
		end
		for v in pairs(M.mazeVortex) do
			map[v] = plain[rnd(#plain)]
		end
		for _, c in ipairs(M.maze.center) do
			for _, v in ipairs(cells[c].vortices) do
				map[v] = M.maze.exit -- from the chest the whirlpools lead to the way out
			end
		end
		local chain, cur = {}, M.maze.start
		for _ = 1, 5 do
			local nxt = plain[rnd(#plain)]
			local vs = cells[cur].vortices
			map[vs[rnd(#vs)]] = nxt
			chain[#chain + 1] = nxt
			cur = nxt
		end
		local vs = cells[cur].vortices
		map[vs[rnd(#vs)]] = M.maze.center[rnd(2)]
		-- check: the chest can be reached from the start, and the way out from the chest
		local seen, queue, found = { [M.maze.start] = true }, { M.maze.start }, false
		while #queue > 0 do
			local c = table.remove(queue, 1)
			if isCenter[c] then
				found = true
			end
			for _, v in ipairs(cells[c].vortices) do
				local d = map[v]
				if d and not seen[d] then
					seen[d] = true
					queue[#queue + 1] = d
				end
			end
		end
		if found and seen[M.maze.exit] then
			M.mazeCache[guid] = map
			return map
		end
	end
	local map = {}
	for v in pairs(M.mazeVortex) do
		map[v] = M.maze.center[1]
	end
	M.mazeCache[guid] = map
	return map
end

-- the seashell cave (ours): the northwest maelstrom leads out (EN), the others between the cave's parts
M.caveVortex = {
	["33701,31795,8"] = M.brandonSpot,
	["33705,31807,8"] = Position(33727, 31803, 8),
	["33711,31822,8"] = Position(33723, 31823, 8),
	["33740,31832,8"] = Position(33739, 31815, 8),
	["33737,31834,8"] = Position(33741, 31800, 8),
	["33722,31824,8"] = M.cave,
	["33728,31804,8"] = M.cave,
	["33740,31819,8"] = Position(33741, 31800, 8),
	["33741,31818,8"] = M.cave,
	["33744,31814,8"] = Position(33727, 31803, 8),
	["33745,31816,8"] = Position(33723, 31823, 8),
	["33748,31810,8"] = Position(33713, 31831, 8),
	["33738,31799,8"] = Position(33739, 31815, 8),
	["33740,31801,8"] = M.cave,
	["33743,31804,8"] = M.cave,
}
for _, k in ipairs({ "33696,31806,8", "33700,31816,8", "33705,31812,8", "33706,31821,8", "33710,31826,8", "33712,31831,8", "33720,31836,8" }) do
	M.caveVortex[k] = M.cave
end

local function move(player, to, fromPosition)
	if not to then
		return true
	end
	player:teleportTo(to)
	to:sendMagicEffect(CONST_ME_WATERSPLASH)
	return true
end

-- the maelstrom behind Mr Brandon (upstream scripts/movements/oramond/seacrest.lua calls this)
function M.maelstrom(player)
	if M.mission(player) == 17 and player:getItemCount(M.seaEar) == 0 then
		return move(player, M.cave)
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You enter the seacrest ground.")
	return move(player, M.guardianSpot)
end

-- every portal of the grounds and the cave; returns true when handled
function M.stepPortal(player, position, fromPosition)
	local k = key(position)
	local cave = M.caveVortex[k]
	if cave then
		return move(player, cave)
	end
	if M.mazeVortex[k] then
		local cell = M.maze.cells[M.mazeFor(player)[k] or M.maze.exit]
		return move(player, cell.land)
	end
	local p = M.portals[k]
	if not p then
		return false
	end
	if p.closed then
		player:teleportTo(fromPosition, true)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A strong current pushes you back. It seems this way is not open yet.") -- ours
		return true
	end
	if p.need and M.mission(player) < p.need then
		player:teleportTo(fromPosition, true)
		fromPosition:sendMagicEffect(CONST_ME_WATERSPLASH)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A strong current pushes you back. You may not enter there yet.") -- ours
		return true
	end
	if p.maze then
		return move(player, M.maze.cells[M.maze.start].land)
	end
	return move(player, p.to)
end

M.portalPositions = {}
for k in pairs(M.portals) do
	M.portalPositions[#M.portalPositions + 1] = k
end
for k in pairs(M.mazeVortex) do
	M.portalPositions[#M.portalPositions + 1] = k
end
for k in pairs(M.caveVortex) do
	M.portalPositions[#M.portalPositions + 1] = k
end

function M.toPosition(k)
	local x, y, z = k:match("(%d+),(%d+),(%d+)")
	return Position(tonumber(x), tonumber(y), tonumber(z))
end

-- ---------------------------------------------------------------- quest log

function M.describe(player)
	local m = M.mission(player)
	local lines = {
		[1] = "Mr Brandon west of Rathleton lost his wedding ring at the bottom of the sea. Swim into the maelstrom behind him and find the Guardian of the Deep Seas.",
		[2] = string.format("Lay the skulls of the Guardian's 5 drowned seamen to rest on the nacre altars or stone snake shrines (%d of 5).", math.min(5, M.get(player, "Laid"))),
		[4] = "Use the cursed gold on the hoard of cursed gold far in the south. The chest behind it holds Brandon's wedding ring.",
		[5] = "Bring Mr Brandon his wedding ring.",
		[6] = "Brandon opened the western current for you. He has another mission.",
		[7] = "Ask the Guardian about the three nacre altar slabs Brandon stole.",
		[8] = "Find the first nacre slab in the sunken ship of the western Seacrest grounds and bring it to the Guardian.",
		[9] = "Find the second nacre slab in the Secret Shrine of the southwestern Seacrest grounds.",
		[10] = "Ask Mr Brandon where the currents took the third nacre slab.",
		[11] = "Old Yeo at Rathleton harbour fished up the third nacre slab.",
		[12] = "Bring the third nacre slab to the Guardian.",
		[13] = "Lay the three nacre slabs on the altars under the Guardian: blue on the left, yellow in the centre, red to the right.",
		[15] = "You may enter the Sunken City. The Guardian has another quest.",
		[16] = "Ask Mr Brandon what he did with the Sea Ear.",
		[17] = "Find the Sea Ear in one of the seashells of the cave Brandon's maelstrom takes you to.",
		[18] = "Show Mr Brandon the Sea Ear.",
		[19] = "Tell the Guardian that you have the Sea Ear.",
		[21] = "You heard the whole song. Tell the Guardian.",
		[22] = "Use the Sea Ear on the ancient sundial of the Eternity Altar, the most southern altar at the end of the volcano ridge.",
		[23] = "Bring the time compass to the Guardian.",
		[24] = "The time compass is back with the Guardian. You may enter the Birthing Grounds of the seacrests.",
	}
	if m == 20 then
		local heard, out = M.get(player, "Song"), {}
		for i, l in ipairs(M.song) do
			if bit.band(heard, bit.lshift(1, i - 1)) ~= 0 then
				out[#out + 1] = l
			end
		end
		return "Use the Sea Ear on the strange statues of the Sunken City. The song so far: " .. (#out > 0 and table.concat(out, " ") or "nothing yet") .. "."
	end
	local best
	for v, text in pairs(lines) do
		if v <= m and (not best or v > best) then
			best = v
		end
	end
	return best and lines[best] or lines[1]
end

-- ---------------------------------------------------------------- startup

function M.setup()
	for _, k in ipairs(M.portalPositions) do
		local t = Tile(M.toPosition(k))
		if t then
			for _, it in ipairs(t:getItems() or {}) do
				local id = it:getId()
				if id == 1949 or id == 21739 or id == 21740 or id == 21741 then
					it:setDestination(Position(0, 0, 0)) -- the MoveEvent moves the player (ours)
				end
			end
		end
	end
end
