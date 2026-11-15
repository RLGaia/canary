-- Gaia Family server: The Postman Missions Quest fixes (2026-11-15).
--
-- Ours, not upstream. Asked by Rodrigo: review the whole quest and its
-- dialogue against our TibiaWiki BR backup (RLGaia/tibiawiki-backup, page
-- "The Postman Missions Quest", revid 419399) and the TibiaWiki EN spoiler
-- and NPC transcripts. Lines from the wikis are marked "BR"/"EN"; lines
-- marked "ours" are new, in the NPC's style.
--
-- What upstream got wrong (and what this file does instead):
--   * Kevin: several "mission" answers reset a finished step. Asking for a
--     mission while carrying the bill gave another bill; asking during
--     mission 10 restarted mission 9 (Santa) after "yes"; saying anything
--     but "yes" after "you got it fixed" left the character stuck without
--     the Assistant rank. Kevin now answers by the character's real
--     progress and says "First you need to complete your current mission."
--     (upstream line) while a mission is open.
--   * Kevin wanted all 20 bones at once; now he takes them one by one
--     ("yes") or all at once ("all"), as in both wikis, and counts them.
--   * Kevin gave "the horn of sundering" (3252) as the Post Horn reward; the
--     Post Horn is item 2957 (EN item page, our items.xml).
--   * "dress patterns" (plural, as both wikis tell the player to say) did not
--     match "dress pattern" for Kevin, Hugo and Talphion.
--   * Mission 7: Lokur answered only after the other five officers (the BR
--     and EN routes visit him third or fourth), counted again every time he
--     was asked, and Kroox only understood the exact lower-case text
--     "lokurs measurements". Olrik took 5 gold for any "yes" (also from
--     players not on the mission) and could count his measurements twice.
--     Now every officer counts once, in any order; Kroox needs Lokur's
--     referral; Olrik's dice game follows the EN transcript and only a lost
--     roll costs 5 gold. Ninos (Issavi) no longer gives Benjamin's
--     measurements (an upstream copy of Benjamin's file).
--   * Noodles only reacted in the fixed order banana skin, dirty fur,
--     mouldy cheese; any other order was silent. Now any order works and the
--     mouldy cheese makes him spit (both wikis), as EN says "It could happen
--     even with the first sniffed item".
--   * A Strange Fellow needed five "hat"s (the first one said his greeting),
--     made five rabbits (BR: four), and any "yes" took the bill away even
--     when he had not asked for it.
--   * The Grand Postman boat discount (10 gp, both wikis) never applied: the
--     "postman" travel discount had no storage (npclib custom_modules.lua).
--
-- Switch: Family.postmanFixes (false = the upstream dialogue of every NPC
-- above comes back).

Family = Family or {}
Family.postmanFixes = true

FamilyPostman = FamilyPostman or {}
local P = FamilyPostman

local Q = Storage.Quest.U7_24.ThePostmanMissions
local S = Storage.Quest.FamilyPostman

local ITEM_BONE = 3115
local ITEM_BILL = 3216
local ITEM_WALDOS_HORN = 3219
local ITEM_LETTER_MARKWIN = 3220
local ITEM_POST_HORN = 2957
local ITEM_OFFICER_HAT = 3576
local ITEM_ARROW = 3447
local ITEM_GRAPES = 3592

local BONES_NEEDED = 20
local IN_PROGRESS = "First you need to complete your current mission." -- upstream line

local function get(player, key)
	return player:getStorageValue(key)
end

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
end

local function has(message, ...)
	for _, word in ipairs({ ... }) do
		if MsgContains(message, word) then
			return true
		end
	end
	return false
end

local function dressPattern(message)
	return has(message, "dress pattern", "dress patterns")
end
P.dressPattern = dressPattern

----------------------------------------------------------------------------
-- Mission 7: measurements
----------------------------------------------------------------------------

local MEASUREMENTS = {
	Q.MeasurementsBenjamin,
	Q.MeasurementsKroox,
	Q.MeasurementsDove,
	Q.MeasurementsLiane,
	Q.MeasurementsChrystal,
	Q.MeasurementsOlrik,
}

function P.measurementsDone(player)
	local done = 0
	for _, key in ipairs(MEASUREMENTS) do
		if get(player, key) == 1 then
			done = done + 1
		end
	end
	return done
end

-- Mission07: 1 = started, 2..6 = 1..5 officers done, 8 = all six (the value
-- Kevin and the quest log expect), 9 = reported to Kevin.
local function measurementActive(player, key)
	local m7 = get(player, Q.Mission07)
	return m7 >= 1 and m7 <= 8 and get(player, key) ~= 1
end

local function recordMeasurement(player, key)
	player:setStorageValue(key, 1)
	local done = P.measurementsDone(player)
	player:setStorageValue(Q.Mission07, done >= #MEASUREMENTS and 8 or 1 + done)
end
P.recordMeasurement = recordMeasurement

local TOPIC_LIANE = 801
local TOPIC_DOVE = 802
local TOPIC_OLRIK_FIRST = 803
local TOPIC_OLRIK_AGAIN = 804
local TOPIC_OLRIK_READY = 805

local function olrikRoll(npc, creature, npcHandler, player, prefix)
	local playerId = player:getId()
	local number = math.random(6)
	if number == 6 then
		-- EN
		say(npcHandler, npc, creature, prefix .. " 6! You have won! How lucky you are! So listen ...<tells you what you need to know>")
		recordMeasurement(player, Q.MeasurementsOlrik)
		npcHandler:setTopic(playerId, 0)
		return
	end
	if not player:removeMoneyBank(5) then
		say(npcHandler, npc, creature, "You don't even have 5 gold to bet. Come back when you do.") -- ours
		npcHandler:setTopic(playerId, 0)
		return
	end
	-- EN
	say(npcHandler, npc, creature, prefix .. " " .. number .. "! You have lost. He he. Another game?")
	npcHandler:setTopic(playerId, TOPIC_OLRIK_AGAIN)
end

local officers = {}

officers["Benjamin"] = function(npc, creature, message, npcHandler, player)
	if not MsgContains(message, "measurements") then
		return false
	end
	if measurementActive(player, Q.MeasurementsBenjamin) then
		-- EN/BR
		say(npcHandler, npc, creature, "Oh they don't change that much since in the old days as... <tells a boring and confusing story about a cake, a parcel, himself and two squirrels, at least he tells you his measurements in the end>")
		recordMeasurement(player, Q.MeasurementsBenjamin)
	else
		say(npcHandler, npc, creature, "...")
	end
	npcHandler:setTopic(player:getId(), 0)
	return true
end

officers["Chrystal"] = function(npc, creature, message, npcHandler, player)
	if not MsgContains(message, "measurements") then
		return false
	end
	if measurementActive(player, Q.MeasurementsChrystal) then
		say(npcHandler, npc, creature, "If it's necessary ... <tells you her measurements>") -- EN/BR
		recordMeasurement(player, Q.MeasurementsChrystal)
	else
		say(npcHandler, npc, creature, "...")
	end
	npcHandler:setTopic(player:getId(), 0)
	return true
end

-- Ninos (Issavi) is not one of Kevin's six officers.
officers["Ninos"] = function(npc, creature, message, npcHandler, player)
	if not MsgContains(message, "measurements") then
		return false
	end
	say(npcHandler, npc, creature, "...")
	npcHandler:setTopic(player:getId(), 0)
	return true
end

local function itemOfficer(key, topic, question, thanks, itemId, count)
	return function(npc, creature, message, npcHandler, player)
		local playerId = player:getId()
		if MsgContains(message, "measurements") then
			if measurementActive(player, key) then
				say(npcHandler, npc, creature, question)
				npcHandler:setTopic(playerId, topic)
			else
				say(npcHandler, npc, creature, "...")
				npcHandler:setTopic(playerId, 0)
			end
			return true
		end
		if npcHandler:getTopic(playerId) ~= topic then
			return false
		end
		if MsgContains(message, "yes") then
			if measurementActive(player, key) and player:removeItem(itemId, count) then
				say(npcHandler, npc, creature, thanks)
				recordMeasurement(player, key)
			else
				say(npcHandler, npc, creature, "Oh, you don't have it.") -- upstream line
			end
		elseif MsgContains(message, "no") then
			say(npcHandler, npc, creature, "Then come back when you have them.") -- ours
		else
			return false
		end
		npcHandler:setTopic(playerId, 0)
		return true
	end
end

officers["Liane"] = itemOfficer(
	Q.MeasurementsLiane,
	TOPIC_LIANE,
	-- EN/BR
	"I have more urgent problem to attend then that. Those hawks are hunting my carrier pigeons. Bring me 12 arrows and I'll see if I have the time for this nonsense. Do you have 12 arrows with you?",
	"Great! Now I'll teach them a lesson ... For those measurements ... <tells you her measurements>",
	ITEM_ARROW,
	12
)

officers["Dove"] = itemOfficer(
	Q.MeasurementsDove,
	TOPIC_DOVE,
	-- EN/BR
	"Oh no! I knew that day would come! I am slightly above the allowed weight and if you can't supply me with some grapes to slim down I will get fired. Do you happen to have some grapes with you?",
	"Oh thank you! Thank you so much! So listen ... <whispers her measurements>",
	ITEM_GRAPES,
	1
)

officers["Olrik"] = function(npc, creature, message, npcHandler, player)
	local playerId = player:getId()
	if MsgContains(message, "measurements") then
		if measurementActive(player, Q.MeasurementsOlrik) then
			-- EN/BR
			say(npcHandler, npc, creature, "My measurements? Listen, lets make that a bit more exciting ... No, no, not what you think! I mean let's gamble. I will roll a dice. If I roll a 6 you win and I'll tell you what you need to know, else I win and get 5 gold. Deal?")
			npcHandler:setTopic(playerId, TOPIC_OLRIK_FIRST)
		else
			say(npcHandler, npc, creature, "...")
			npcHandler:setTopic(playerId, 0)
		end
		return true
	end
	local topic = npcHandler:getTopic(playerId)
	if topic ~= TOPIC_OLRIK_FIRST and topic ~= TOPIC_OLRIK_AGAIN and topic ~= TOPIC_OLRIK_READY then
		return false
	end
	if MsgContains(message, "no") then
		say(npcHandler, npc, creature, "As you wish.") -- ours
		npcHandler:setTopic(playerId, 0)
		return true
	elseif not MsgContains(message, "yes") then
		return false
	elseif not measurementActive(player, Q.MeasurementsOlrik) then
		npcHandler:setTopic(playerId, 0)
		return true
	end
	if topic == TOPIC_OLRIK_AGAIN then
		say(npcHandler, npc, creature, "Ok, no weights in the dice, no dirty tricks, are you ready?") -- EN/BR
		npcHandler:setTopic(playerId, TOPIC_OLRIK_READY)
	elseif topic == TOPIC_OLRIK_FIRST then
		olrikRoll(npc, creature, npcHandler, player, "Ok, and its ...") -- EN/BR
	else
		olrikRoll(npc, creature, npcHandler, player, "Ok, here we go ...") -- EN/BR
	end
	return true
end

officers["Lokur"] = function(npc, creature, message, npcHandler, player)
	if not MsgContains(message, "measurements") then
		return false
	end
	if measurementActive(player, Q.MeasurementsKroox) then
		-- EN/BR
		say(npcHandler, npc, creature, "Come on, I have no clue what they are. Better ask my armorer Kroox for such nonsense. Go and ask him for good ol' Lokurs measurements, he'll know.")
		player:setStorageValue(S.LokurSent, 1)
	else
		say(npcHandler, npc, creature, "...")
	end
	npcHandler:setTopic(player:getId(), 0)
	return true
end

officers["Kroox"] = function(npc, creature, message, npcHandler, player)
	if not MsgContains(message, "measurements") then
		return false
	end
	if measurementActive(player, Q.MeasurementsKroox) and get(player, S.LokurSent) == 1 then
		say(npcHandler, npc, creature, "Hm, well I guess its ok to tell you ... <tells you about Lokurs measurements>") -- EN/BR
		recordMeasurement(player, Q.MeasurementsKroox)
	else
		say(npcHandler, npc, creature, "...")
	end
	npcHandler:setTopic(player:getId(), 0)
	return true
end

-- Called first in the dialogue of Benjamin, Chrystal, Liane, Dove, Olrik,
-- Lokur, Kroox and Ninos. Returns true when the message was handled here.
function P.officer(npc, creature, message, npcHandler)
	local handler = officers[npc:getName()]
	local player = Player(creature)
	if not handler or not player then
		return false
	end
	return handler(npc, creature, message, npcHandler, player)
end

----------------------------------------------------------------------------
-- Mission 3: A Strange Fellow (David Brassacres)
----------------------------------------------------------------------------

local HAT_LINES = { -- EN/BR
	"What? My hat?? Theres... nothing special about it!",
	"Stop bugging me about that hat, do you listen?",
	"Hey! Don't touch that hat! Leave it alone!!! Don't do this!!!!",
	"Noooooo! Argh, ok, ok, I guess I can't deny it anymore, I am David Brassacres, the magnificent, so what do you want?",
}
local TOPIC_REVEALED = #HAT_LINES
local TOPIC_BILL = 10

function P.strangeFellow(npc, creature, message, npcHandler)
	local player = Player(creature)
	local playerId = player:getId()
	if get(player, Q.Mission03) ~= 1 then
		return true
	end
	local topic = npcHandler:getTopic(playerId)
	if MsgContains(message, "hat") then
		if topic < TOPIC_REVEALED then
			say(npcHandler, npc, creature, HAT_LINES[topic + 1])
			npcHandler:setTopic(playerId, topic + 1)
			if topic + 1 == TOPIC_REVEALED then
				for _ = 1, 4 do -- BR: four rabbits
					Game.createMonster("Rabbit", npc:getPosition(), true)
				end
				npc:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			end
		end
	elseif MsgContains(message, "bill") then
		if topic == TOPIC_REVEALED then
			say(npcHandler, npc, creature, "A bill? Oh boy so you are delivering another bill to poor me?") -- EN/BR
			npcHandler:setTopic(playerId, TOPIC_BILL)
		end
	elseif topic == TOPIC_BILL then
		if MsgContains(message, "yes") then
			if player:removeItem(ITEM_BILL, 1) then
				-- EN/BR
				say(npcHandler, npc, creature, "Ok, ok, I'll take it. I guess I have no other choice anyways. And now leave me alone in my misery please.")
				player:setStorageValue(Q.Mission03, 2)
				npcHandler:setTopic(playerId, 0)
			else
				say(npcHandler, npc, creature, "Ha! You don't even have it with you! Go away!") -- ours
				npcHandler:setTopic(playerId, TOPIC_REVEALED)
			end
		else
			say(npcHandler, npc, creature, "Good! Then leave me alone.") -- ours
			npcHandler:setTopic(playerId, TOPIC_REVEALED)
		end
	end
	return true
end

----------------------------------------------------------------------------
-- Mission 6: Noodles
----------------------------------------------------------------------------

local SNIFF = {
	{ words = { "banana" }, item = 3104, topic = 1 }, -- banana skin
	{ words = { "fur" }, item = 3105, topic = 2 }, -- dirty fur
	{ words = { "cheese" }, item = 3120, topic = 3 }, -- mouldy cheese
}

function P.noodles(npc, creature, message, npcHandler)
	local player = Player(creature)
	local playerId = player:getId()
	local m6 = get(player, Q.Mission06)
	if m6 < 7 or m6 > 9 then
		return true
	end
	if MsgContains(message, "like") then
		local topic = npcHandler:getTopic(playerId)
		if topic == 3 then
			say(npcHandler, npc, creature, "Meeep! Grrrrr! <spits>") -- EN/BR
			player:setStorageValue(Q.Mission06, 10)
		elseif topic == 1 or topic == 2 then
			say(npcHandler, npc, creature, "Woof!") -- EN/BR
			-- quest log: 8 = likes banana skin, 9 = likes dirty fur too
			player:setStorageValue(Q.Mission06, math.max(m6, topic == 1 and 8 or 9))
		end
		npcHandler:setTopic(playerId, 0)
		return true
	end
	for _, entry in ipairs(SNIFF) do
		for _, word in ipairs(entry.words) do
			if MsgContains(message, word) then
				if player:getItemCount(entry.item) > 0 then
					say(npcHandler, npc, creature, "<sniff><sniff>") -- EN/BR
					npcHandler:setTopic(playerId, entry.topic)
				else
					say(npcHandler, npc, creature, "<sniff>") -- EN (any other word)
					npcHandler:setTopic(playerId, 0)
				end
				return true
			end
		end
	end
	return true
end

----------------------------------------------------------------------------
-- Kevin
----------------------------------------------------------------------------

local function giveItem(player, itemId)
	local item = player:addItem(itemId, 1)
	if not item then
		-- no room or capacity: leave it at the player's feet
		Game.createItem(itemId, 1, player:getPosition())
	end
end

local K = {} -- topics
K.JOIN1, K.JOIN2, K.JOIN3, K.ROUTE1, K.ROUTE2, K.ROUTE3, K.ROUTE4 = 1, 2, 3, 4, 5, 6, 7
K.MAILBOX, K.FIXED, K.BILL, K.BONES_START = 8, 9, 10, 11
K.BONE_ONE, K.ADV_POSTMAN, K.PRESENT, K.UNIFORMS = 13, 14, 15, 16
K.NOODLES, K.MEASURE, K.ADV_GRAND, K.WALDO1, K.WALDO2 = 18, 19, 20, 21, 22
K.WALDO_HORN, K.ADV_SPECIAL, K.SANTA, K.MARKWIN, K.ADV_ARCH = 23, 24, 25, 26, 27
K.ADVANCE_FIRST, K.BONES_ALL = 28, 29

local function kevinMission(npc, creature, npcHandler, player)
	local playerId = player:getId()
	local rank = get(player, Q.Rank)
	local m = {}
	for i = 1, 10 do
		m[i] = get(player, Q[string.format("Mission%02d", i)])
	end
	local function ask(text, topic)
		say(npcHandler, npc, creature, text)
		npcHandler:setTopic(playerId, topic or 0)
	end
	if m[1] < 1 then
		-- EN/BR
		return ask("You are not a member of our guild yet! We have high standards for our members. To rise in our guild is a difficult but rewarding task. Are you interested in joining?", K.JOIN1)
	elseif m[1] < 5 then
		return ask(IN_PROGRESS)
	elseif m[1] == 5 then
		-- EN/BR
		return ask("So you have finally made it! I did not think that you would have it in you ... However: are you ready for another assignment?", K.MAILBOX)
	elseif m[2] == 1 then
		return ask(IN_PROGRESS)
	elseif m[2] == 2 or (m[2] == 3 and rank < 1) then
		-- EN/BR (also for characters left without the rank by the old dialogue)
		return ask("Excellent, you got it fixed! This will teach this mailbox a lesson indeed! Are you interested in another assignment?", K.FIXED)
	elseif m[3] < 1 then
		return ask("So are you ready for another mission?", K.BILL) -- upstream line
	elseif m[3] == 1 then
		if player:getItemCount(ITEM_BILL) < 1 then
			giveItem(player, ITEM_BILL)
			return ask("You lost the bill? How careless! Here is a copy. Now go and find David Brassacres in Venore.") -- ours
		end
		return ask(IN_PROGRESS)
	elseif m[3] == 2 or m[4] < 1 then
		-- EN/BR
		return ask("You truly got him? Quite impressive. You are a very promising candidate! I think I have another mission for you. Are you interested?", K.BONES_START)
	elseif m[4] == 1 then
		return ask("Do you bring a bone for our officers' safety fund?", K.BONE_ONE) -- EN/BR
	elseif rank < 2 then
		-- EN/BR
		return ask("You have made it! We have enough bones for the fund! You remind me of myself when I was young! Interested in another mission?", K.ADVANCE_FIRST)
	elseif m[5] < 1 then
		-- EN/BR
		return ask("You have made it! We have enough bones for the fund! You remind me of myself when I was young! Interested in another mission?", K.PRESENT)
	elseif m[5] < 3 then
		return ask(IN_PROGRESS)
	elseif m[5] == 3 then
		-- EN/BR
		return ask("Splendid, I knew we could trust you. I would like to ask for your help in another matter. Are you interested?", K.UNIFORMS)
	elseif m[6] == 10 then
		-- EN/BR (the "dress pattern" answer)
		player:setStorageValue(Q.Mission06, 11)
		return ask("Fine, fine. I think that should do it. Tell Hugo that we order those uniforms. The completed dress pattern will soon arrive in Venore. Report to me when you have talked to him.")
	elseif m[6] < 12 then
		return ask(IN_PROGRESS)
	elseif m[6] == 12 then
		player:setStorageValue(Q.Mission06, 13)
		return ask("Excellent! Another job well done! Would you accept another mission?", K.ADVANCE_FIRST) -- EN/BR
	elseif rank < 3 then
		return ask("Excellent! Another job well done! Would you accept another mission?", K.ADVANCE_FIRST) -- EN/BR
	elseif m[7] < 1 then
		return ask("Excellent! Another job well done! Would you accept another mission?", K.MEASURE) -- EN/BR
	elseif m[7] < 8 then
		return ask(IN_PROGRESS)
	elseif m[7] == 8 then
		return ask("Once more you have impressed me! Are you willing to do another job?", K.WALDO1) -- EN/BR
	elseif m[8] == 1 then
		return ask(IN_PROGRESS)
	elseif m[8] == 2 then
		return ask("So Waldo is dead? This is grave news indeed. Did you recover his posthorn?", K.WALDO_HORN) -- EN/BR
	elseif rank < 4 then
		return ask("So are you ready for another mission?", K.ADVANCE_FIRST) -- upstream line
	elseif m[9] < 1 then
		return ask("So are you ready for another mission?", K.SANTA) -- BR
	elseif m[9] < 3 then
		return ask(IN_PROGRESS)
	elseif m[9] == 3 then
		-- EN/BR
		return ask("You did it? I hope you did not catch a flu in the cold! Anyway, there's another mission for you. Are you interested?", K.MARKWIN)
	elseif m[10] == 1 then
		if player:getItemCount(ITEM_LETTER_MARKWIN) < 1 then
			giveItem(player, ITEM_LETTER_MARKWIN)
			return ask("You lost the letter? Here, his mother sent another one. Take good care of it this time.") -- ours
		end
		return ask(IN_PROGRESS)
	elseif m[10] == 2 then
		player:setStorageValue(Q.Mission10, 3)
		-- EN/BR
		return ask("You have delivered that letter? You are a true post officer. All over the land bards shall praise your name. There are no missions for you left right now.")
	elseif rank < 5 then
		-- upstream line
		return ask("There are no missions for you left right now. But you are worthy indeed. Do you want to advance in our guild?", K.ADV_ARCH)
	end
	return ask("There are no missions for you left right now. You already have the title of Archpostman.") -- upstream line
end

local function kevinAdvancement(npc, creature, npcHandler, player)
	local playerId = player:getId()
	local rank = get(player, Q.Rank)
	local topic
	if rank == 1 and get(player, Q.Mission04) == 2 then
		topic = K.ADV_POSTMAN
	elseif rank == 2 and get(player, Q.Mission06) == 13 then
		topic = K.ADV_GRAND
	elseif rank == 3 and get(player, Q.Mission08) == 3 then
		topic = K.ADV_SPECIAL
	elseif rank == 4 and get(player, Q.Mission10) == 3 then
		topic = K.ADV_ARCH
	end
	if not topic then
		say(npcHandler, npc, creature, "You will have to complete more missions before you can advance in our guild.") -- ours
		npcHandler:setTopic(playerId, 0)
		return
	end
	say(npcHandler, npc, creature, "You are worthy indeed. Do you want to advance in our guild?") -- EN/BR
	npcHandler:setTopic(playerId, topic)
end

local function kevinBones(npc, creature, npcHandler, player, all)
	local playerId = player:getId()
	local count = math.max(0, get(player, S.Bones))
	local need = BONES_NEEDED - count
	local carried = player:getItemCount(ITEM_BONE)
	local give = all and need or 1
	if carried < give then
		say(npcHandler, npc, creature, "You don't have it...") -- upstream line
		npcHandler:setTopic(playerId, 0)
		return
	end
	player:removeItem(ITEM_BONE, give)
	count = count + give
	player:setStorageValue(S.Bones, count)
	if count >= BONES_NEEDED then
		player:setStorageValue(Q.Mission04, 2)
		-- EN/BR
		say(npcHandler, npc, creature, "You have collected 20 bones. Excellent! Now let's talk about further missions if you are interested.")
	else
		-- EN/BR
		say(npcHandler, npc, creature, string.format("Excellent! You have collected %d bones. Just report about your mission again if you find more.", count))
	end
	npcHandler:setTopic(playerId, 0)
end

local yes = {}
yes[K.JOIN1] = { "Hm, I might consider your proposal, but first you will have to prove your worth by doing some tasks for us. Are you willing to do that?", K.JOIN2 }
yes[K.JOIN2] = { "Excellent! Your first task will be quite simple. But you should better write my instructions down anyways. You can read and write?", K.JOIN3 }
yes[K.JOIN3] = { "So listen, you will check certain tours our members have to take to see if there is some trouble. First travel with Captain Bluebear's ship from Thais to Carlin, understood?", K.ROUTE1 }
yes[K.ROUTE1] = { "Excellent! Once you have done that you will travel with Uzon to Edron. You will find him in the Femor Hills. Understood?", K.ROUTE2 }
yes[K.ROUTE2] = { "Fine, fine! Next, travel with Captain Seahorse to the city of Venore. Understood?", K.ROUTE3 }
yes[K.ROUTE3] = { "Good! Finally, find the technomancer Brodrosch and travel with him to the Isle of Cormaya. After this passage report back to me here. Understood?", K.ROUTE4 }
yes[K.WALDO1] = { "Ok, but your next assignment might be dangerous. Our Courier Waldo has been missing for a while. I must assume he is dead. Can you follow me so far?", K.WALDO2 }

local function kevinYes(npc, creature, npcHandler, player, topic)
	local playerId = player:getId()
	local function done(text, nextTopic)
		say(npcHandler, npc, creature, text)
		npcHandler:setTopic(playerId, nextTopic or 0)
	end
	local step = yes[topic]
	if step then
		return done(step[1], step[2])
	end
	-- every topic below re-checks the progress it was asked for
	if topic == K.ROUTE4 and get(player, Q.Mission01) < 1 then
		player:setStorageValue(Q.Mission01, 1)
		return done("Ok, remember: the Tibian mail service puts trust in you! Don't fail and report back soon. Just tell me about your {mission}.")
	elseif topic == K.MAILBOX and get(player, Q.Mission01) == 5 then
		player:setStorageValue(Q.Mission01, 6)
		player:setStorageValue(Q.Mission02, 1)
		return done("I am glad to hear that. One of our mailboxes was reported to be jammed. It is located on the so called 'mountain' on the isle Folda. Get a crowbar and fix the mailbox. Report about your mission when you have done so.")
	elseif topic == K.FIXED and get(player, Q.Mission02) >= 2 then
		player:setStorageValue(Q.Mission02, 3)
		player:setStorageValue(Q.Rank, math.max(1, get(player, Q.Rank)))
		return done("For your noble deeds I grant you the title Assistant Postofficer. All Postofficers will charge you less money from now on. After every second mission ask me for an ADVANCEMENT. Your next task will be a bit more challenging. Do you feel ready for it?", K.BILL)
	elseif topic == K.BILL and get(player, Q.Mission03) < 1 then
		player:setStorageValue(Q.Mission03, 1)
		giveItem(player, ITEM_BILL)
		return done("I need you to deliver a bill to the stage magician David Brassacres. He's hiding from his creditors somewhere in Venore. It's likely you will have to trick him somehow to reveal his identity. Report back when you delivered this bill.")
	elseif topic == K.BONES_START and get(player, Q.Mission04) < 1 and get(player, Q.Mission03) >= 2 then
		player:setStorageValue(Q.Mission03, 3)
		player:setStorageValue(Q.Mission04, 1)
		return done("Ok, listen: we have some serious trouble with aggressive dogs lately. We have accumulated some bones as a sort of pacifier but we need more. Collect 20 bones like the one in my room to the left and report here.")
	elseif topic == K.BONE_ONE and get(player, Q.Mission04) == 1 then
		return kevinBones(npc, creature, npcHandler, player, false)
	elseif topic == K.BONES_ALL and get(player, Q.Mission04) == 1 then
		return kevinBones(npc, creature, npcHandler, player, true)
	elseif topic == K.ADV_POSTMAN and get(player, Q.Rank) == 1 then
		player:setStorageValue(Q.Rank, 2)
		giveItem(player, ITEM_OFFICER_HAT)
		return done("I grant you the title of postman. You are now a full member of our guild. Here have your own officers hat and wear it with pride.")
	elseif topic == K.PRESENT and get(player, Q.Mission05) < 1 then
		player:setStorageValue(Q.Mission05, 1)
		return done("Since I am convinced I can trust you, this time you must deliver a valuable present to Dermot on Fibula. Do NOT open it!!! You will find the present behind the door here on the lower right side of this room.")
	elseif topic == K.UNIFORMS and get(player, Q.Mission05) == 3 then
		player:setStorageValue(Q.Mission05, 4)
		player:setStorageValue(Q.Mission06, 1)
		return done("Ok. We need a new set of uniforms, and only the best will do for us. Please travel to Venore and negotiate with Hugo Chief a contract for new uniforms.")
	elseif topic == K.NOODLES and get(player, Q.Mission06) == 6 then
		player:setStorageValue(Q.Mission06, 7)
		return done("Good. Go there and find out what taste he dislikes most: mouldy cheese, a piece of fur or a banana skin. Tell him to SNIFF, then the object. Show him the object and ask 'Do you like that?'. DON'T let the guards know what you are doing.")
	elseif topic == K.ADV_GRAND and get(player, Q.Rank) == 2 then
		player:setStorageValue(Q.Rank, 3)
		return done("From now on it shall be known that you are a grand postman. You are now a privileged member until the end of days. Most captains around the world have an agreement with our guild to transport our privileged members, like you, for less gold.")
	elseif topic == K.MEASURE and get(player, Q.Mission07) < 1 then
		player:setStorageValue(Q.Mission07, 1)
		return done("Good, so listen. Hugo Chief informed me that he needs the measurements of our post officers. Go and bring me the measurements of Ben, Lokur, Dove, Liane, Chrystal and Olrik.")
	elseif topic == K.WALDO2 and get(player, Q.Mission07) == 8 then
		player:setStorageValue(Q.Mission07, 9)
		player:setStorageValue(Q.Mission08, 1)
		return done("Find out about his whereabouts and retrieve him or at least his posthorn. He was looking for a new underground passage that is rumoured to be found underneath the troll-infested Mountain east of Thais.")
	elseif topic == K.WALDO_HORN and get(player, Q.Mission08) == 2 then
		if not player:removeItem(ITEM_WALDOS_HORN, 1) then
			return done("You don't have it with you! Bring me his posthorn.") -- ours
		end
		player:setStorageValue(Q.Mission08, 3)
		return done("Thank you. We will honour this. Your next mission will be a very special one. Good thing you are a special person as well. Are you ready?", K.ADVANCE_FIRST)
	elseif topic == K.ADV_SPECIAL and get(player, Q.Rank) == 3 then
		player:setStorageValue(Q.Rank, 4)
		giveItem(player, ITEM_POST_HORN)
		return done("From now on you are a grand postman for special operations. You are an honoured member of our guild and earned the privilege of your own post horn. Here, take it.")
	elseif topic == K.SANTA and get(player, Q.Mission09) < 1 then
		player:setStorageValue(Q.Mission09, 1)
		return done("So listen well. Behind the lower left door you will find a bag. The letters in the bag are for none other than Santa Claus! Deliver them to his house on the isle of Vega, {use} the bag on his mailbox and report back here.")
	elseif topic == K.MARKWIN and get(player, Q.Mission09) == 3 then
		player:setStorageValue(Q.Mission09, 4)
		player:setStorageValue(Q.Mission10, 1)
		giveItem(player, ITEM_LETTER_MARKWIN)
		return done("Excellent. Here is a letter for you to deliver. Well, to be honest, no one else volunteered. It's a letter from the mother of Markwin, the king of Mintwallin. Deliver that letter to him, but note that you will not be welcome there.")
	elseif topic == K.ADV_ARCH and get(player, Q.Rank) == 4 and get(player, Q.Mission10) == 3 then
		player:setStorageValue(Q.Rank, 5)
		player:setStorageValue(Q.Door, 1)
		player:addAchievement("Archpostman")
		return done("I grant you the title of archpostman. You are a legend in our guild. As privilege of your newly acquired status you are allowed to make use of certain mailboxes in dangerous areas. Just look out for them and you'll see.")
	elseif topic == K.ADVANCE_FIRST then
		return done("Your eagerness is a virtue, young one, but first let's talk about advancement.")
	end
	npcHandler:setTopic(playerId, 0)
end

local function kevinDressPattern(npc, creature, npcHandler, player)
	local playerId = player:getId()
	local m6 = get(player, Q.Mission06)
	if m6 == 2 then
		player:setStorageValue(Q.Mission06, 3)
		say(npcHandler, npc, creature, "Oh yes, where did we get that from ...? Let's see, first ask the great technomancer in Kazordoon for the technical details. Return here afterwards.")
	elseif m6 == 4 then
		player:setStorageValue(Q.Mission06, 5)
		say(npcHandler, npc, creature, "The mail with Talphion's instructions just arrived. I remember we asked Queen Eloise of Carlin for the perfect colours. Go there, ask her about the UNIFORMS and report back here.")
	elseif m6 == 6 then
		say(npcHandler, npc, creature, "The queen has sent me the samples we needed. The next part is tricky. We need the uniforms to emanate some odor that dogs hate. The dog with the best 'taste' in that field is Noodles, the dog of King Tibianus. Do you understand so far?")
		npcHandler:setTopic(playerId, K.NOODLES)
		return
	elseif m6 == 10 then
		player:setStorageValue(Q.Mission06, 11)
		say(npcHandler, npc, creature, "Fine, fine. I think that should do it. Tell Hugo that we order those uniforms. The completed dress pattern will soon arrive in Venore. Report to me when you have talked to him.")
	end
	npcHandler:setTopic(playerId, 0)
end

-- Kevin's whole quest dialogue. Lines are EN/BR unless marked otherwise.
function P.kevin(npc, creature, message, npcHandler)
	local player = Player(creature)
	local topic = npcHandler:getTopic(player:getId())
	if MsgContains(message, "mission") then
		kevinMission(npc, creature, npcHandler, player)
	elseif dressPattern(message) then
		kevinDressPattern(npc, creature, npcHandler, player)
	elseif MsgContains(message, "advancement") then
		kevinAdvancement(npc, creature, npcHandler, player)
	elseif MsgContains(message, "all") and get(player, Q.Mission04) == 1 then
		say(npcHandler, npc, creature, "Are you sure you have collected all the 20 bones needed?")
		npcHandler:setTopic(player:getId(), K.BONES_ALL)
	elseif MsgContains(message, "yes") and topic > 0 then
		kevinYes(npc, creature, npcHandler, player, topic)
	elseif MsgContains(message, "no") and topic > 0 then
		say(npcHandler, npc, creature, "As you wish. Just tell me about your {mission} when you are ready.") -- ours
		npcHandler:setTopic(player:getId(), 0)
	end
	return true
end
