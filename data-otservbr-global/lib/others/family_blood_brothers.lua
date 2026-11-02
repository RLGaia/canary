-- Gaia Family server: Blood Brothers Quest, missions 4-10 and extras (2026-11-02).
-- Ours, not upstream: upstream Canary v3.6.1 ends at the start of Mission 04 (Julius gives the
-- map, nothing else). World objects and events: scripts/family/blood_brothers.lua; bosses:
-- monster/quests/blood_brothers/*.lua; NPCs: npc/a_wandering_soul.lua, npc/a_fading_memory.lua.
--
-- Sources (checked 2026-11-02): TibiaWiki BR "Blood Brothers Quest" (page saved by Rodrigo:
-- dialogues, map points, page and goblet squares) and TibiaWiki EN "Blood Brothers Quest/Spoiler",
-- the boss, book and item pages. Julius' lines are the wiki transcripts; lines marked "ours"
-- are not in either wiki.
--
-- Family rules (Rodrigo, 2026-11-02):
--   * Mission 05: two players with charged blood crystals on any two of the castle spots are
--     enough (Tibia: four players on the four spots).
--   * Mission 09: no female character is needed for Marziel.
--
-- Steps:
--   M04 1 mark at least 5 of the 8 spots on Julius' map (castle entrance required); report:
--       2500 experience for every spot over five (BR/EN: 7500 for all eight). "map": new map.
--   M05 1 blood crystal (chest in the cult hideout, floor -3) -> 2 charge it at A Wandering Soul
--       -> 3 stand on the castle spots -> 4 inside (the mystic flame lets you in from now on)
--       -> 5 reported
--   M06 1 Marziel's torn diary (bookcase, south-east tower) -> 2 reported (1000 exp, ours)
--   M07-M10 kill Boreth, Lersatio, Marziel, Arthei; a blessed wooden stake on the remains gives
--       the dust, Julius takes it. M10 gives the vampiric crest.
--   Diary pages II-VII (old pieces of paper 8747-8752): 1000 experience each at Julius ("diary").
--   Blood goblet: courtyard pile of bones, door from Arthei's tower opens after the crest.
--
-- Switch: Family.bloodBrothers (false = Julius stops after Mission 04 and nothing here reacts).

Family = Family or {}
Family.bloodBrothers = true

FamilyBloodBrothers = FamilyBloodBrothers or {}
local B = FamilyBloodBrothers
local BB = Storage.Quest.U8_4.BloodBrothers
local S = Storage.Quest.FamilyBloodBrothers
B.S = S

-- items
B.JULIUS_MAP = 8200
B.CRYSTAL = 8453
B.CRYSTAL_CHARGED = 8225
B.TORN_BOOK = 8275
B.GHOST_TEAR = 8746
B.CREST = 9041
B.GOBLET = 8531
B.DUST = { boreth = 8717, lersatio = 8718, marziel = 8719, arthei = 8720 }

-- Finds bit mask (storage S.Finds)
B.F_CHEST = 64
B.F_BOOK = 128
B.F_GOBLET = 256
B.F_TEAR = 512
B.F_GARDEN = 65536
B.F_CHARGED = 131072 -- A Wandering Soul charged a crystal for you once
function B.pageFoundBit(i)
	return 2 ^ (i - 1) -- pages 1-6 = II-VII
end
function B.pageDeliveredBit(i)
	return 1024 * 2 ^ (i - 1)
end

local function get(player, key)
	return math.max(0, player:getStorageValue(key))
end
B.get = get

function B.hasBit(player, key, bit)
	return math.floor(get(player, key) / bit) % 2 == 1
end

function B.setBit(player, key, bit)
	if not B.hasBit(player, key, bit) then
		player:setStorageValue(key, get(player, key) + bit)
	end
end

-- Julius' map: the eight unusual spots (TibiaWiki EN Mapper Coords and BR points, a few squares
-- around each, matched with our map). Index 8 is the castle entrance, which Julius requires.
B.spots = {
	{ name = "bottomless pit", from = Position(32946, 31517, 7), to = Position(32953, 31524, 7) },
	{ name = "bone circle", from = Position(32938, 31491, 7), to = Position(32945, 31498, 7) },
	{ name = "haunted ruin", from = Position(32909, 31487, 7), to = Position(32918, 31496, 7) },
	{ name = "lonely grave", from = Position(32900, 31466, 7), to = Position(32907, 31474, 7) },
	{ name = "miraculously burning trees", from = Position(32879, 31495, 7), to = Position(32888, 31505, 7) },
	{ name = "old shrine", from = Position(32929, 31559, 4), to = Position(32936, 31566, 4) },
	{ name = "castle garden", from = Position(32960, 31494, 6), to = Position(32967, 31500, 6) },
	{ name = "castle entrance", from = Position(32950, 31485, 6), to = Position(32956, 31491, 6) },
}
B.CASTLE_SPOT = 8
B.SPOT_XP = 2500

local function inBox(pos, from, to)
	return pos.z == from.z and pos.x >= from.x and pos.x <= to.x and pos.y >= from.y and pos.y <= to.y
end
B.inBox = inBox

function B.marks(player)
	return get(player, S.Marks) % 256
end

function B.markCount(player)
	local m, n = B.marks(player), 0
	for i = 0, 7 do
		if math.floor(m / 2 ^ i) % 2 == 1 then
			n = n + 1
		end
	end
	return n
end

function B.paidSpots(player)
	return math.floor(get(player, S.Marks) / 256) % 16
end

-- pays 2500 experience for every marked spot over five not paid yet; returns the number paid
function B.payMarks(player)
	local count, paid = B.markCount(player), B.paidSpots(player)
	local extra = math.max(0, count - 5)
	if extra <= paid then
		return 0
	end
	player:addExperience((extra - paid) * B.SPOT_XP, true)
	player:setStorageValue(S.Marks, B.marks(player) + 256 * extra)
	return extra - paid
end

local NUMBER = { [6] = "six", [7] = "seven", [8] = "eight" }

-- diary pages: item id, the square (and a second square where BR and EN differ), Julius' line
-- (TibiaWiki BR "Entregando as páginas para Julius", matched to the page texts of TibiaWiki EN)
B.pages = {
	{
		id = 8747,
		pos = { Position(32964, 31471, 2) }, -- south-east tower top, pile of bones (BR = EN)
		line = "Let me see... that's very interesting. So Arthei was basically almost dead after the incident. I wonder what happened next?",
		text = "<this is a ripped page, probably from a diary>\nIV. 3rd\nArthei is not getting better... neither is he getting worse, his state has been the same for the last days. We have established a regular watch plan now during the night so that Kala can get some rest. I have not given up hope, yet, but things are not looking good. It is hard to believe that the poor creature in the bed is my brother. I fear that only a miracle can help him now.\n\nIV. 5th\nI cannot put into words yet what happened last night... and neither do I know whether it is good... or evil? I have to think about it...",
	},
	{
		id = 8748,
		pos = { Position(32943, 31471, 5) }, -- south-west tower, chest of drawers (BR = EN)
		line = "Wow... now that is some story. A strange creature over Arthei's bed, and afterwards he is completely healed? I wonder what happened next...",
		text = "<this is a ripped page, probably from a diary>\nIV. 7th\nEverything is so strange... two nights ago the weirdest thing happened... I fell asleep during the night watch at my brother's bed, must have been only for a few minutes, but when I opened my eyes, I saw a black... being... hovering over Arthei's bed, getting closer and closer to him. I wanted to jump to my feet and scream, but I was unable to move. All I could do was dig my nails into my own flesh. Then suddenly, the being looked directly into my eyes. I remember thinking 'how strange', because the creature had no face and thus no eyes, yet I knew that it was looking at me. Then I couldn't bear the cold of its look anymore and passed out. I don't know what happened afterwards. All that matters now is that Arthei has recovered. And with recovered I mean that there is not a SCRATCH on him anymore. He is completely well, I'm not able to explain why, but I don't care. Kala is crying for joy, I think the black being wasn't evil, but a god.",
	},
	{
		id = 8749,
		pos = { Position(32960, 31456, 6) }, -- north-east tower, bookcase (EN; BR 32960,31457 is the floor in front)
		line = "Hmm... so after that incident, Arthei is a completely changed person, sneaking out at night and not recognising his wife. I wonder what happened next?",
		text = "<this is a ripped page, probably from a diary>\nIV. 8th\nThis is not good at all. At first we were all so happy about the miracle of Arthei's recovery that we didn't care about anything else, but now, some... side effects have appeared. Arthei has never looked as pale as now and he hardly speaks a single word. At least he still knows that we are his brothers, but he doesn't seem to recognise Kala, his wife. This is incredibly hard for her because she was really doing anything in her might to help him get better. And now that he is well again, he is very distant. He calls her 'that woman' and doesn't let her into his room. God, this is so bad. We are hoping that this is only a mood swing or some sort of amnesia that will pass over time...\n\nIV. 12th\nKala is gone!! Oh, what horrible times are those. In her sadness, and confronted with Arthei's constant rejection, she must have left the house last night. She left almost all of her belongings. We are so worried about her... and hope so badly that she didn't decide to throw her life away as desperate as she has been. Arthei didn't even notice... and when we told him, he just shrugged his shoulders. She doesn't deserve this... she is such a sweet and caring woman. We have been looking all over the city for her - in the accessible parts that is - but couldn't find her. I will look for her later again.\n\nIV. 13th\nKala remains missing... and Arthei seems to sneak out at night too, although he is always back in the mornings. I only noticed because I was getting up from my bed to fetch a mug of water, when I saw him closing the front door. What is he doing outside at this time? And, come to think about it, he has never left the house or even his room during daytime ever since he recovered. What has happened to him?",
	},
	{
		id = 8750,
		pos = { Position(32939, 31459, 6), Position(32940, 31459, 6) }, -- north-west tower, bookcase (EN 32939, BR 32940)
		line = "How very interesting... so that is how the four brothers got over to that island... they were chased off by the citizens of Yalahar. I wonder what happened next?",
		text = "<this is a ripped page, probably from a diary>\nIV. 20th\nSince we've moved into this house, we barely had any contact to the other citizens of Yalahar. However this has changed during the last week. People are getting suspicious of Arthei - some saw him after the explosion and know that his sudden recovery can't have happened in a natural way. And they are starting to talk... what makes matters worse is that some murders have occurred since Arthei's recovery. I don't know any details or what exactly was the cause for their death, but I can't stop thinking that Arthei might have something to do with it. His nightly excursions... the state he is in... and it seems that I'm not the only one who thinks that way. As I said... people are starting to talk...\n\nIV. 22th\nI don't know how long we can stay here. People whisper with each other and stare hatefully at Lersatio, Boreth and me when we cross the street. I really want to protect my brother, but I'm very scared.\n\nIV. 25th\nOn the ocean again... this night, we were almost killed by a mob who banged at our door with the obvious intention to remove what they consider a threat to their lives. Well... I can't blame them... we pulled struggling Arthei out of the house and with us, and now we're out at sea on the small boat we arrived in. Luckily they didn't destroy it before they came for us. Please, let us find land... I guess that means back to square one.",
	},
	{
		id = 8751,
		pos = { Position(32945, 31446, 6) }, -- northern tower, bookcase (EN; BR 32946,31447 is the floor in front)
		line = "So... after their arrival, the green island of Vengoth seems to be under a curse... well, doesn't surprise me.",
		text = "<this is a ripped page, probably from a diary>\nIV. 26th\nFinally, luck is on our side again! Just a few hours to the east we found another island - and it's beautiful! Grass, flowers, mountains in the distance and enough natural resources for a fresh start.\n\nIV. 28th\nThings are getting even better - on the hill east of the grassy area we found what seems to be an abandoned mansion. We spent some hours clearing all the spider webs and now it is quite a good place to stay in. Fate smiles on us! Ever since we found the mansion, Arthei has locked himself into one of the rooms, though. I hope that he will eventually recover in this peaceful environment.\n\nV. 2nd\nWe made ourselves a home in the mansion and try to farm the land. I think if we can cultivate crops and vegetables, this place will be simply perfect for us.\n\nIV. 10th\nNot much success yet. The land is very dry, drier than it seemed when we arrived. We also haven't seen Arthei for a few days.\n\nIV. 20th\nThis must be... a curse? The grass is withering... the water is getting muddy... even the hill seems stonier, although common sense tells me that this is not possible. What's going on here?",
	},
	{
		id = 8752,
		pos = { Position(32953, 31440, 3) }, -- next to A Fading Memory, stone coffin (EN; BR 32952,31442 is the floor)
		line = {
			"Aha! That's the most interesting bit. They blamed Arthei for the curse and tried to get rid of his vampire self, and it's blatantly obvious that they couldn't defeat him. ...",
			"So, I suppose he turned his brothers into vampires, and actually they were quite happy about that due to their new superiority. What a story... however, some pieces are still missing...",
		},
		text = "<this is a ripped page, probably from a diary>\nV. 25th\nI'm incredibly tired. Each day we work until the sun sets, trying to farm the land but it seems impossible. I'm sure we all have lost a few pounds. Lersatio even had to disguise himself to sneak back into Yalahar and get some supplies. The water on the island is almost swampy now... the grass is brown almost everywhere.... the trees are losing their leaves... jagged stones have formed from the once green hill. We are not speaking of it often, but I know that my two brothers and I are thinking the same... it's a curse, and it sticks to Arthei.\n\nVI. 2nd\nAnother week lost. Not much more to say.\n\nVI. 5th\nWe have made a grave decision. We will deliver Arthei, the land and us from this curse. Tonight this will end. It has to end. It's our brother, but I'm sure that this decision will be the best for all of us.",
	},
}
B.PAGE_XP = 1000
B.BOOK_XP = 1000 -- Julius' "small bonus" for the diary; no wiki gives the amount (ours)
B.BOOK_POS = Position(32961, 31471, 6) -- south-east tower, bookcase (EN)
B.BOOK_TEXT = "II. 28th\nToday my brothers and I are leaving from Carlin to find a new place for us and our families. None of the great Tibian cities have made us feel at home yet. There must be something else, and we will find it.\n\nIII. 5th\nWe've been at sea for a few days now. Time seems endless, and so does the ocean. We have supplies for 3 more weeks. Should we not find land within the next week we will cancel our expedition to make sure we get back home safely.\n\nIII. 8th\nStill nothing... but the screams of seagulls and the sound of the waves... we are still hoping.\n\nIII. 10th\nWe've spotted land! It's still a day away, but it seems to be a really large island. Not only that, we can also make out tall towers in the distance. Strangely though, this city - or whatever it is - can't be found on our map, despite its obvious size.\n\nIII. 11th\nWe've arrived at the harbour of Yalahar, as the inhabitants call it. Obviously large parts of the city are destroyed and closed for the public. We will stay in a tavern tonight - finally, a bed again! - and then try to find a place to live in.\n\nIII. 14th\nFinding a house seems to be harder than expected. The inner city of Yalahar which seems safe and rather wealthy has almost no place left, especially not for outsiders as us. Maybe we can live in one of the outer quarters, close to the city walls at least.\n\nIII. 18th\nLersatio found an unoccupied house not too far away from the centre. It is close to an alchemical lab. Maybe we can even find some work there. Things are looking great!\n\nIII. 20th\nWe've settled down and started the repair work on the house. This may take a while, but we are sending note to our families to come after us. Arthei's wife Kala insisted to come with us right from the start, so they are already together, but I am starting to miss my girl immensely. Oh sweet Melava, I hope you are well.\n\nIII. 21th\nThis place is not as good as it seemed. The closeness to the alchemical laboratories proves to be a constant menace and now I understand why they didn't want it in the centre. Frequent explosions are startling us during the whole day, and even at nighttime there is a lot of noise from the facilities. Due to these circumstances we will probably try to find another place, luckily we haven't put too much work into the house, yet. Also, our families won't come, yet.\n\nIII. 30th\nOh god... something horrible happened and I've not been able to write for a while... a week ago there was a HUGE explosion in the night... fire spread upon almost all houses nearby... we barely escaped the flames... my hands are burnt, because I pulled my brother out of the burning house and we all are still coughing grey substance... Boreth and Lersation got out with some scratches and burns, but otherwise we three are fine. It's just Arthei... he got burnt really badly... I barely recognise his face... Kala is sitting at his bed 24 hours a day with red swollen eyes and praying for his life. When she falls asleep in exhaustion we are keeping watch.\n\n<from here on, all of the pages have been torn out, only the last page remains:>\n\nTHE FIRST DAY OF ETERNITY\nI CAN SEE NOW. FOOLS. ALL OF YOU. HAHAHAHAHA."

function B.deliveredPages(player)
	local n = 0
	for i = 1, #B.pages do
		if B.hasBit(player, S.Finds, B.pageDeliveredBit(i)) then
			n = n + 1
		end
	end
	return n
end

-- Castlemania (TibiaWiki EN): the quest, all eight spots, the six pages, the blood goblet and the
-- Vampire Hunter Quest (rank 6). The blood skull is also listed there, but nothing on our server
-- records it, so it is left out (ours).
function B.checkCastlemania(player)
	if player:hasAchievement("Castlemania") then
		return false
	end
	if get(player, S.Mission10) < 2 or B.marks(player) ~= 255 or B.deliveredPages(player) < #B.pages then
		return false
	end
	if not B.hasBit(player, S.Finds, B.F_GOBLET) then
		return false
	end
	if player:getStorageValue(Storage.Quest.U8_2.VampireHunterQuest.Rank) < 6 then
		return false
	end
	player:addAchievement("Castlemania")
	return true
end

-- ---------------------------------------------------------------------------
-- Julius (npc/julius.lua calls B.julius first; true = handled)
-- ---------------------------------------------------------------------------
local T = {
	MAP_REPORT = 101,
	M5_ASK = 102,
	M5_PLAN = 103,
	M5_FOUND = 104,
	M5_CHARGE = 105,
	M5_CHARGED = 106,
	M5_NEWS = 107,
	M5_SPOTS = 108,
	M6_SPOOKY = 109,
	M6_ASK = 110,
	M6_FOUND = 111,
	M6_BOOK = 112,
	M6_DOOR = 113,
	M7 = 114,
	M8 = 115,
	M9 = 116,
	M10 = 117,
	NEW_MAP = 118,
	DIARY = 119,
}
B.T = T

local function say(npcHandler, text, npc, creature, topic)
	npcHandler:say(text, npc, creature)
	npcHandler:setTopic(creature:getId(), topic or 0)
	return true
end

local function dustMission(player, key, missionKey)
	if get(player, missionKey) ~= 1 then
		return false
	end
	return player:getItemCount(B.DUST[key]) > 0
end

local function juliusMission(npc, player, npcHandler)
	local m4, m5, m6 = get(player, BB.Mission04), get(player, S.Mission05), get(player, S.Mission06)
	local m7, m8, m9, m10 = get(player, S.Mission07), get(player, S.Mission08), get(player, S.Mission09), get(player, S.Mission10)
	if m4 == 1 then
		return say(npcHandler, "Are you back with a useful map of Vengoth?", npc, player, T.MAP_REPORT)
	elseif m5 == 0 then
		return say(npcHandler, {
			"The spots you found on Vengoth are really interesting, especially the castle. There's something dark and spooky surrounding all of these places. ...",
			"I think if we found a way to get into the castle, we might get to the bottom of all this. Are you prepared to help me?",
		}, npc, player, T.M5_ASK)
	elseif m5 == 1 then
		return say(npcHandler, "As I said, I don't know where you might get a blood crystal - but did you find one?", npc, player, T.M5_FOUND)
	elseif m5 == 2 then
		if player:getItemCount(B.CRYSTAL_CHARGED) < 1 then
			-- ours: the crystal is not charged (yet, or any more)
			return say(npcHandler, "That crystal does not shimmer with any energy. Find someone who lost something or someone dear to him or her.", npc, player)
		end
		return say(npcHandler, "Ah! I can see in your eyes that you found someone! Do you have that charged crystal?", npc, player, T.M5_CHARGED)
	elseif m5 == 3 then
		-- ours (family rule: two holders are enough)
		return say(npcHandler, "Find someone else who holds a charged blood crystal. Stand on two of those spots with the strange symbols around the castle at the same time, and the castle's dark energy will attune you.", npc, player)
	elseif m5 == 4 then
		return say(npcHandler, "Ah! Welcome back! So you have been inside the castle? Was it as spooky as in the stories told by people?", npc, player, T.M6_SPOOKY)
	elseif m6 == 1 then
		return say(npcHandler, "Did you find anything of interest inside the castle?", npc, player, T.M6_FOUND)
	elseif m7 == 1 then
		if dustMission(player, "boreth", S.Mission07) then
			return say(npcHandler, "Impressive. A plant-crazy vampire... didn't think something like that existed. Have you got proof of his death?", npc, player, T.M7)
		end
		-- ours
		return say(npcHandler, "There must be another open door somewhere in that castle. Find the first of the brothers and bring me proof of his death.", npc, player)
	elseif m8 == 1 then
		if dustMission(player, "lersatio", S.Mission08) then
			return say(npcHandler, "A vain vampire hoping to see his image in the mirror once again some day... how ironic. Have you got proof of his death?", npc, player, T.M8)
		end
		return say(npcHandler, "Find the second brother in another tower of the castle and awaken him. Bring me proof of his death.", npc, player) -- ours
	elseif m9 == 1 then
		if dustMission(player, "marziel", S.Mission09) then
			return say(npcHandler, "I can't help but to feel sorry about Marziel... he seemed to have been a decent guy according to his diary. But- have you got proof of his death?", npc, player, T.M9)
		end
		return say(npcHandler, "Climb up to the room of the third brother, Marziel, and bring me proof of his death.", npc, player) -- ours
	elseif m10 == 1 then
		if dustMission(player, "arthei", S.Mission10) then
			return say(npcHandler, "You are back! You truly are a hero and a fierce vampire slayer! Have you got proof of Arthei's death?", npc, player, T.M10)
		end
		return say(npcHandler, "Arthei is the last of them. I promise that when you come back with his ashes, your task for me is done and you will be generously rewarded.", npc, player) -- ours, from his own words
	elseif m10 >= 2 then
		return say(npcHandler, "Thank you very much for your help, I think the city is much safer now.", npc, player)
	end
	return false
end

local function juliusYes(npc, player, npcHandler, topic)
	if topic == T.MAP_REPORT then
		if player:getItemCount(B.JULIUS_MAP) < 1 then
			return say(npcHandler, "You don't have my map with you. If you lost it, ask me for a new {map}.", npc, player) -- ours
		end
		local marks, count = B.marks(player), B.markCount(player)
		if math.floor(marks / 2 ^ (B.CASTLE_SPOT - 1)) % 2 ~= 1 or count < 5 then
			return say(npcHandler, "Don't forget, come back with at least five marks! Also, they say there is a castle on this island. That mark HAS to be included.", npc, player) -- his own lines
		end
		player:removeItem(B.JULIUS_MAP, 1)
		player:setStorageValue(BB.Mission04, 2)
		B.payMarks(player)
		B.checkCastlemania(player)
		if count > 5 then
			return say(npcHandler, "Well done, you even marked " .. NUMBER[count] .. " places! I'll grant you a little bonus for that. Come back later and ask me about your next mission. I have to think.", npc, player)
		end
		return say(npcHandler, "Well done. Come back later and ask me about your next mission. I have to think.", npc, player) -- the wiki line without the bonus
	elseif topic == T.M5_ASK then
		return say(npcHandler, {
			"Good, now listen to what I've thought of. From what I've heard, there's a strong magic barrier blocking the entrance to the castle. ...",
			"If we could somehow redirect or focus that energy somewhere else, it might be possible to pass that door. I heard of a rare stone called 'blood crystal'. ...",
			"It is said to have the power to store magic energy. If you could find such a stone we might be able to charge it with energy that will attract the dark power floating around the castle. ...",
			"Unfortunately I have no idea where to look for a blood crystal. I think you might have to ask around in Yalahar, maybe someone knows where you could find one. Can you do that?",
		}, npc, player, T.M5_PLAN)
	elseif topic == T.M5_PLAN then
		player:setStorageValue(S.Mission05, 1)
		return say(npcHandler, "Fine then. Good luck!", npc, player)
	elseif topic == T.M5_FOUND then
		if player:getItemCount(B.CRYSTAL) < 1 and player:getItemCount(B.CRYSTAL_CHARGED) < 1 then
			return say(npcHandler, "Then try harder.", npc, player) -- his line from Mission 02
		end
		return say(npcHandler, {
			"Oh, look how it shimmers... such a pretty sight... now we just need to get it filled with magic energy. Maybe if you could find someone ...",
			"... someone who lost something or someone dear to him or her. Sometimes those people unknowingly emit massive amounts of energy - during their life and even after their death. ...",
			"If you can find someone like that, I'm sure that you will be able to charge the blood crystal. That's the only help I can give you though. Are you willing to try?",
		}, npc, player, T.M5_CHARGE)
	elseif topic == T.M5_CHARGE then
		player:setStorageValue(S.Mission05, 2)
		return say(npcHandler, "Once you have a charged crystal, hurry back to me. I don't know how long that power will last. Good luck!", npc, player)
	elseif topic == T.M5_CHARGED then
		if player:getItemCount(B.CRYSTAL_CHARGED) < 1 then
			return say(npcHandler, "Then try harder.", npc, player)
		end
		return say(npcHandler, {
			"Very good, now don't lose that precious crystal! I doubt you'll be able to get another one. While you've been on the road, I wasn't lazy either. ...",
			"I have good news and bad news. Which do you want to hear first?",
		}, npc, player, T.M5_NEWS)
	elseif topic == T.M5_SPOTS then
		player:setStorageValue(S.Mission05, 3)
		return say(npcHandler, "Great. You are impressing me more and more. Once you have been to the castle, come back and we will discuss further missions.", npc, player)
	elseif topic == T.M6_SPOOKY then
		return say(npcHandler, {
			"Well anyway, as it seems there's more than that door protecting the castle, since you were not able to proceed any further - and those ghosts patrolling the hallway seem invulnerable. ...",
			"I wonder what the story behind this place is. Maybe you can somehow find a way past the ghosts and deeper down into the castle. ...",
			"If you could find some documents or books about this place there that would be a great help. Anything that tells us more about the master of this castle and how this place got so cursed. Could you do that?",
		}, npc, player, T.M6_ASK)
	elseif topic == T.M6_ASK then
		player:setStorageValue(S.Mission05, 5)
		player:setStorageValue(S.Mission06, 1)
		return say(npcHandler, "Fine. You know, those old castle sometimes have hidden passages and stuff like that. That's at least what they say in fairytales. Good luck!", npc, player)
	elseif topic == T.M6_FOUND then
		if player:getItemCount(B.TORN_BOOK) < 1 then
			return say(npcHandler, "Then keep looking. Those old castles sometimes have hidden passages.", npc, player) -- ours
		end
		return say(npcHandler, "Oh! That is indeed MOST interesting. Can I have that book you found?", npc, player, T.M6_BOOK)
	elseif topic == T.M6_BOOK then
		if not player:removeItem(B.TORN_BOOK, 1) then
			return say(npcHandler, "Then keep looking. Those old castles sometimes have hidden passages.", npc, player)
		end
		player:addExperience(B.BOOK_XP, true)
		return say(npcHandler, {
			"Thank you so much, I'll grant you a small bonus for that. Let me take a closer look, hmm. There are a lot of pages missing... but that last page is kind of disturbing. ...",
			"The name on the front page says 'Marziel'... and it seems that his brothers and himself have something to do with this place. ...",
			"There are a lot of missing pages... I wonder what happened after March 30th? Listen, should you stumble across any more pages, please bring them to me for a small reward. I'd really like to figure this out. ...",
			"Apart from that, I guess to meet the brothers, you have to explore the castle even more. Maybe you can find another open door somewhere and look where - or who - it leads to?",
		}, npc, player, T.M6_DOOR)
	elseif topic == T.M6_DOOR then
		player:setStorageValue(S.Mission06, 2)
		player:setStorageValue(S.Mission07, 1)
		return say(npcHandler, "Good luck. I mean it.", npc, player)
	elseif topic == T.M7 then
		if not dustMission(player, "boreth", S.Mission07) or not player:removeItem(B.DUST.boreth, 1) then
			return say(npcHandler, "Then try harder.", npc, player)
		end
		player:setStorageValue(S.Mission07, 2)
		player:setStorageValue(S.Mission08, 1)
		return say(npcHandler, {
			"That's what I was hoping for! I will start investigating that dust. Maybe we can gain valuable information on how we can defeat the vampire plague once and for all. ...",
			"Listen, brave vampire slayer, I don't think that your task in this castle is done yet. According to the diary you found, there are three other brothers called Lersatio, Marziel and Arthei. ...",
			"We have to seek them all out and destroy them in order to weaken their power over the land. After Boreth's death, it is quite possible that you can gain access to another tower in the castle. ...",
			"That is your chance to find the second brother and awaken him. Good luck - again.",
		}, npc, player)
	elseif topic == T.M8 then
		if not dustMission(player, "lersatio", S.Mission08) or not player:removeItem(B.DUST.lersatio, 1) then
			return say(npcHandler, "Then try harder.", npc, player)
		end
		player:setStorageValue(S.Mission08, 2)
		player:setStorageValue(S.Mission09, 1)
		return say(npcHandler, {
			"You are definitely one of the bravest and craziest adventurers I ever met. Each time you prove to me that there is no task too dangerous for you. ...",
			"There are only two brothers left now, and I can feel that their grasp on Yalahar is getting weaker. We cannot stop now but have to finish what we started. ...",
			"See if you can slip into another tower of the castle and climb up to the room of the third brother. Since Arthei is their master, I guess Marziel is who we are going for now. ...",
			"The author of that diary... writing down the cursed story of his life. I hope he will rest in peace. Good luck.",
		}, npc, player)
	elseif topic == T.M9 then
		if not dustMission(player, "marziel", S.Mission09) or not player:removeItem(B.DUST.marziel, 1) then
			return say(npcHandler, "Then try harder.", npc, player)
		end
		player:setStorageValue(S.Mission09, 2)
		player:setStorageValue(S.Mission10, 1)
		return say(npcHandler, {
			"Well, let's see it this way - I guess he is relieved of his burden now - and so are his victims. Strange that a once such nice person turned out to be almost the cruelest of the brothers. ...",
			"I don't know what is awaiting you when you face Arthei. I hope that you can find a way to break his evil power and shatter his black soul... if a vampire still has a soul. ...",
			"I promise that when you come back with his ashes, your task for me is done and you will be generously rewarded. Don't let me down now.",
		}, npc, player)
	elseif topic == T.M10 then
		if not dustMission(player, "arthei", S.Mission10) or not player:removeItem(B.DUST.arthei, 1) then
			return say(npcHandler, "Then try harder.", npc, player)
		end
		player:setStorageValue(S.Mission10, 2)
		B.setBit(player, S.Finds, B.F_GARDEN)
		player:addItem(B.CREST, 1)
		B.checkCastlemania(player)
		return say(npcHandler, {
			"So you really managed to defeat all four of the brothers. Unbelievable. As reward for you deeds, I'll grant you special crest. ...",
			"I won't reveal what it does, but I'm sure you'll find out for yourself. Thank you very much for your help, I think the city is much safer now.",
		}, npc, player)
	elseif topic == T.NEW_MAP then
		player:addItem(B.JULIUS_MAP, 1)
		return say(npcHandler, "Here is the map. When you are standing near a remarkable spot, use it to mark that spot on the map.", npc, player) -- his line
	elseif topic == T.DIARY then
		for i, page in ipairs(B.pages) do
			if not B.hasBit(player, S.Finds, B.pageDeliveredBit(i)) and player:getItemCount(page.id) > 0 then
				player:removeItem(page.id, 1)
				B.setBit(player, S.Finds, B.pageDeliveredBit(i))
				player:addExperience(B.PAGE_XP, true)
				local line = page.line
				if B.deliveredPages(player) == #B.pages then
					local parts = {}
					for _, l in ipairs(type(line) == "table" and line or { line }) do
						parts[#parts + 1] = l
					end
					parts[#parts] = parts[#parts] .. " ..."
					parts[#parts + 1] = "This fills the last gap in that story. Wow... thanks for helping me piece it together!"
					line = parts
				end
				B.checkCastlemania(player)
				return say(npcHandler, line, npc, player)
			end
		end
		return say(npcHandler, "You don't seem to have any page of that diary with you.", npc, player) -- ours
	end
	return false
end

function B.julius(npc, creature, message, npcHandler)
	if not Family.bloodBrothers then
		return false
	end
	local player = Player(creature)
	if not player then
		return false
	end
	local topic = npcHandler:getTopic(player:getId())
	local msg = message:lower()

	if MsgContains(msg, "mission") then
		-- The Inquisition, mission 3 done: Julius trusts you without the garlic bread (TibiaWiki EN:
		-- you skip Mission 01; BR: talk to him with the garlic necklace). Line ours.
		local m1 = get(player, BB.Mission01)
		if m1 >= 1 and m1 <= 3 and player:getStorageValue(Storage.Quest.U8_2.TheInquisitionQuest.Mission03) >= 6 then
			player:setStorageValue(BB.Mission01, 4)
			return say(npcHandler, "Ah, a member of the inquisition. That is proof enough for me, I think I can trust you. So, are you ready for your first real task?", npc, player, 5)
		end
		-- "Let me check - yes indeed, there's garlic in it": he checks the bread (ours when there is none)
		if m1 == 3 and player:getItemCount(8194) < 1 then
			return say(npcHandler, "You don't have any garlic bread with you. Talk to me again about your mission once you have the garlic bread.", npc, player)
		end
		if get(player, BB.Mission04) >= 1 then
			return juliusMission(npc, player, npcHandler)
		end
		return false
	end

	if topic >= 101 and topic <= 119 then
		if topic == T.M5_NEWS then
			-- "Which do you want to hear first?" - any answer (the wiki shows "yes")
			return say(npcHandler, {
				"Well, in that case I'll tell you the good news first. I figured out how you can get into the castle using that blood crystal, quite easy actually. ...",
				"The bad thing is, you can't do it alone, but you need three more people who are also in possession of a charged blood crystal. ...",
				"The four of you have to stand on special spots around the castle. Unfortunately, in my books it doesn't say where exactly, but it mentions strange symbols. ...",
				"Once all four of you are standing on those spots holding a crystal, each of you will attract the castle's dark energy and get attuned to it. ...",
				"I don't know what will happen, but afterwards you should be able to pass the castle gate, if I'm not mistaken. Do you think you can do that?",
			}, npc, player, T.M5_SPOTS)
		end
		if MsgContains(msg, "yes") then
			return juliusYes(npc, player, npcHandler, topic)
		end
		if MsgContains(msg, "no") then
			return say(npcHandler, "Getting cold feet, eh?", npc, player) -- his reply to anything else
		end
	end

	if MsgContains(msg, "map") then
		local m4 = get(player, BB.Mission04)
		if m4 < 1 then
			return false
		end
		if player:getItemCount(B.JULIUS_MAP) > 0 then
			if m4 >= 2 and B.payMarks(player) > 0 then
				B.checkCastlemania(player)
				return say(npcHandler, "Well done, you even marked " .. NUMBER[B.markCount(player)] .. " places! I'll grant you a little bonus for that.", npc, player)
			end
			return say(npcHandler, "When you are standing near a remarkable spot, use it to mark that spot on the map.", npc, player) -- his line
		end
		if m4 >= 2 and B.markCount(player) >= 8 then
			return say(npcHandler, "You already marked every remarkable place on Vengoth for me.", npc, player) -- ours
		end
		return say(npcHandler, "Do you want a new map of Vengoth to mark the remaining places?", npc, player, T.NEW_MAP) -- ours (TibiaWiki: map, yes)
	end

	if MsgContains(msg, "diary") or MsgContains(msg, "page") then
		if get(player, S.Mission06) < 2 then
			return false
		end
		return say(npcHandler, "Have you brought a missing page from Marziel's diary?", npc, player, T.DIARY)
	end
	return false
end
