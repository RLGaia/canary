-- Gaia Family server: The New Frontier Quest fixes (2026-11-09).
--
-- Ours, not upstream. Asked by Rodrigo: review the quest and its dialogue
-- against TibiaWiki BR (page HTML from Rodrigo) and the TibiaWiki EN spoiler
-- and NPC transcripts. Lines from the wikis are marked "EN"/"BR"; the others
-- are ours, in each NPC's style.
--
-- Mission 5 (Getting Things Busy). Upstream: every word the player said to
-- King Tibianus, Leeland, Angus, Wyrdin, Telas or Humgolf during the mission
-- that the NPC did not expect ("job", "trade", a typo...) answered "Wrong
-- Word." and failed the negotiation, even before "farmine"; several right
-- answers used the wrong line (Leeland's "impress" said the "plea" line,
-- his "flatter" repeated the greeting, the king's gift line was his question),
-- and some wrong words were simply silent. Now:
--   * only the six words count, and only right after "farmine";
--   * each NPC has one secret word per character, chosen among the words that
--     convince him in the EN transcripts (the same luck Ongulf warns about,
--     "You probably need some luck as well");
--   * every word answers with the NPC's real line (EN), or with one of ours
--     where the transcripts have none;
--   * after a failure "farmine" asks for the gift (Black Bert's item), "yes"
--     takes it and the talk goes on, as in the EN transcripts.
-- The six NPCs call FamilyNewFrontier.negotiate at the top of their dialogue
-- (marked FAMILY: in their files).
-- Switch: Family.newFrontierNegotiation (false = the NPCs' upstream code is
-- gone, so the switch only turns the mission off; keep it true).
--
-- Ongulf (npc/ongulf.lua) and Zurak/Chrak use the small helpers at the end.
-- Switch: Family.newFrontierAnswers (false = upstream silence for Ongulf's
-- waiting stages, Zurak's "reward" and Chrak's rules).

Family = Family or {}
Family.newFrontierNegotiation = true
Family.newFrontierAnswers = true

FamilyNewFrontier = FamilyNewFrontier or {}
local F = FamilyNewFrontier

local WORDS = { "flatter", "threaten", "impress", "bluff", "plea", "reason" }

local function TNF()
	return Storage.Quest.U8_54.TheNewFrontier
end

-- success: the words that may convince him (EN), with his line.
-- fail: his line for a word that did not convince him (EN); other: ours.
F.npcs = {
	king = {
		storage = "KingTibianus",
		gift = 10009, -- flask of crown polisher
		intro = "Ah, I vaguely remember that our little allies were eager to build some base. So speak up, what do you want?",
		success = {
			flatter = "Indeed, indeed. Without the help of Thais, our allies stand no chance! Well, I'll send some money to support their cause.",
			impress = "Well, the things you tell me about the usefulness of this mine seem a bit exaggerated. Admittedly, it would be a shame though if we weren't participating in gaining all those treasures. I'll send some help to our allies.",
			reason = "Admittedly, we made some promises. My honour obliges me to fulfil these promises even if I'm not convinced that this is a good idea.",
		},
		fail = {
			plea = "I'm sorry but I have obligations to my people. I cannot spend money needed here to finance some shaky project.",
			threaten = "How dare you? I'm the sovereign of a vast realm. I don't bow to any threats! Out of my eyes before I have you executed to make an example!",
			bluff = "You must take me for a fool. We have our eyes and ears everywhere and we are well aware that you are lying to us! Get out of my sight!",
		},
		other = "Such words will not convince the king of Thais. Our negotiations are over.", -- ours
		apology = "Did you come to apologise for your inappropriate behaviour?",
		accepted = "Hm, a well thought out and tasteful present. So let's continue our negotiations. Why should I assist in the construction of the Farmine base?",
		done = "I have already promised to send money to our little allies.", -- ours
	},
	leeland = {
		storage = "Leeland",
		gift = 10028, -- soul contract
		intro = "Oh yes, that project the whole dwarven community is so excited about. I guess I already know why you are here, but speak up.",
		success = {
			plea = "Your pathetic whimpering amuses me. For this I grant you my assistance. But listen, one day I'll ask you to return this favour. From now on, you owe me one.",
			reason = "The idea of a promising market and new resources suits us quite well. I think it is reasonable to send some assistance.",
			impress = "Well, there might be some profit in this project. I'll convince my fellow traders to help you out. For a modest fee, we'll take the ungrateful reselling in our capable hands.",
		},
		fail = {
			bluff = "Come on. I can smell a lie before you've even told it. Spare me your made-up stories. There will be no support from Venore.",
			threaten = "Your attempts to scare me are amusing at best. But threats become tiresome quickly. I think our negotiations end here.",
			flatter = "Empty words to support a hopeless cause. I don't see any profit for our city in this project.",
		},
		other = "I don't see any profit for Venore in what you say. There will be no support from us.", -- ours
		apology = "You better have a present with you to soothe my anger. Do you have a gift?",
		accepted = "How amusing. Of course this is just a piece of paper, but I'll take it as a token of your good will. Now where did we stop?",
		done = "The traders of Venore will take care of the dwarven surplus, as I promised.", -- ours
	},
	angus = {
		storage = "Angus",
		gift = 10011, -- map to the unknown
		intro = "Oh yes, an interesting topic. We had vivid discussions about this discovery. But what is it that you want?",
		success = {
			bluff = {
				"Those stories are just amazing! Men with faces on their stomach instead of heads you say? And hens that lay golden eggs? Whereas, most amazing is this fountain of youth you've mentioned! ...",
				"I'll immediately send some of our most dedicated explorers to check those things out!",
			},
			impress = "A whole new land is indeed very tempting. I can hardly imagine all the wonders that await us there. I doubt I could stop our explorers from going there even if I tried to.",
			threaten = "Well, of course we can't allow some amateurs to surpass us in our efforts to explore the land. I think it is mandatory to be ahead of anyone else, and I'll send some of our finest explorers to this strange new land.",
		},
		fail = {
			impress = "For all I've heard, this is rather a barren isle than a whole new land. There are so many places to explore in this world, I won't send our best explorers on account of a rumour.",
			plea = "I'm sorry, but we are dedicated to science and exploration. We don't have the resources to serve as scouts for some mining project.",
			bluff = "Oh give me a break! I'm long enough a member of the Explorer Society to recognise a cock-and-bull story when I hear one.",
		},
		other = "That is hardly a reason for the Explorer Society to send anyone there. I'm afraid we cannot help.", -- ours
		apology = "You bring up this topic again? I don't think our talks make any sense unless you prove that you are a supporter of science. Do you have some proof for your dedication to science?",
		accepted = "What a strange map. I wonder if any of our explorers recognises this coastal lines. However, you earned yourself another chance to convince me. Why do you think that Farmine would be interesting for us?",
		done = "Our explorers are already preparing their journey to this strange new land.", -- ours
	},
	wyrdin = {
		storage = "Wyrdin",
		gift = 10025, -- almanac of magic
		intro = "I've heard some odd rumours about this new dwarven outpost. But tell me, what has the Edron academy to do with Farmine?",
		success = {
			plea = "<sighs> Okay, sending some trader there won't hurt. I hope it will be worth the effort, though.",
			reason = {
				"Well, it can't be wrong to be there when new discoveries are made. Also, all those soldiers of fortune that might travel there could turn out to be a good source of income for a magic shop. ...",
				"I think we'll send a representative. At least, for some time.",
			},
			bluff = "What do you mean the druids of Carlin could provide the service as well? They are incompetent imposters! I will not allow them to ruin our reputation! I'll send some trader with supplies right away!",
			flatter = "Hm, you are right, we are at the forefront of knowledge and innovation. Our dwarven friends could learn much from one of our representatives.",
		},
		fail = {
			impress = "Well, the efforts of the dwarfs are impressive but we really have no interest in mining or mineralogy.",
			threaten = "I still don't think that any success or failure of this project will have an impact on the academy. We will not intervene in this dwarven project.",
		},
		other = "That does not convince me at all. The academy will not get involved in this dwarven project.", -- ours
		apology = "I'm not sure if I'm in the mood to talk about that matter again. Or do you have anything that might change my mind?",
		accepted = {
			"By Uman! That's one of the rare almanacs of Origus! I had no idea that you are a scholar yourself! And a generous one on top of it! ...",
			"This book must be worth some thousand crystal coins on the free market. Look at the signature here, it's Origus' very own! ...",
			"Of course we should talk again about your request. What do you say makes Farmine important?",
		},
		done = "The academy will send a representative to Farmine, as I said.", -- ours
	},
	telas = {
		storage = "Telas",
		gift = 10027, -- universal tool
		intro = "I have heard only little about this mine. I am a bit absorbed in my studies. But what does this mine have to do with me?",
		success = {
			reason = "Well it sounds like a good idea to test my golems in some real environment. I think it is acceptable to send some of them to Farmine.",
			flatter = "Well, of course my worker golems are quite usefull and it might indeed be a good idea to see who they operate on realistic conditions. I will send some to farmine soon.",
			plea = "Well, if the situation is that desperate I think it is possible to send some of the golems to help the poor dwarfs out of their misery.",
		},
		fail = {
			reason = "Oh no. My golems aren't yet in testing stage. There is no way I could risk them or the life of others by putting them under such a stress test too early.",
			threaten = "I don't think this kind of language is appropriate. It seems better to end this discussuion here and now.",
			bluff = "It's a bit insulting that you try to trick one of the smartest brains in the scientific comunity. I don't fall for it!",
			impress = "Oh, come on. You obviously lack the scientific knowledge to back up what you are talking about. Sorry, I can't risk my reputation as scientist by sending probably malfunctioning golems to that mine.",
		},
		other = "That is no argument a scientist could accept. My golems stay here.", -- ours
		apology = "You are starting this discussion again? Why should I listen to you this time, do you have anything to convince me to let you even try?",
		accepted = "Oh how nice of you. I might have misjudged you. So let us return to this matter of worker golems. Do you have any better arguments this time?",
		done = "Some of my worker golems are already on their way to Farmine.", -- ours
	},
	humgolf = {
		storage = "Humgolf",
		gift = 10026, -- baby rotworm
		intro = "Bah, Farmine here, Farmine there. Is there nothing else than Farmine to talk about these days? Hrmpf, whatever. So what do you want?",
		success = {
			flatter = "Yeah, of course they can't do without my worms. Mining and worms go hand in hand. Well, in the case of the worms it is only an imaginary hand of course. I'll send them some of my finest worms.",
			threaten = "Hah! Now you talk like a dwarf! That's the spirit! Of course you can have some of my worms. I'll send a bunch to Farmine as soon as possible.",
		},
		fail = {
			bluff = "Some of my relatives are working there and you dare to tell me such a lie? Your tongue is good for nothing but worm food.",
			impress = "It takes more to impress a dwarf. A lot more.",
		},
		other = "Bah! That's no way to talk to a dwarf. Forget about my worms.", -- ours
		apology = "You are here to apologise? Have you got anything that would make me reconsider my decision never to talk to you again about this subject?",
		accepted = "Uh, how cute! Look how he's snapping for my fingers! You really know how to make an old dwarf happy! Well, so let's try again. Why do you think I should send my precious worms to Farmine?",
		done = "My worms are already on their way to Farmine. Don't worry about that.", -- ours
	},
}

-- Fixed order of the success words, so the secret word stays the same.
for _, data in pairs(F.npcs) do
	data.order = {}
	for _, word in ipairs(WORDS) do
		if data.success[word] then
			data.order[#data.order + 1] = word
		end
	end
end

local NPC_INDEX = { king = 1, leeland = 2, angus = 3, wyrdin = 4, telas = 5, humgolf = 6 }

-- The secret word of this character for this NPC (same on every talk).
function F.secretWord(player, key)
	local data = F.npcs[key]
	local n = #data.order
	local seed = player:getGuid() * 7 + NPC_INDEX[key] * 13
	return data.order[(seed % n) + 1]
end

-- pending[key][playerId] = { what = "words" | "gift", until = os.time() + 120 }
F.pending = F.pending or {}

local function setPending(key, playerId, what)
	F.pending[key] = F.pending[key] or {}
	F.pending[key][playerId] = what and { what = what, untilTime = os.time() + 120 } or nil
end

local function getPending(key, playerId)
	local entry = F.pending[key] and F.pending[key][playerId]
	if entry and entry.untilTime >= os.time() then
		return entry.what
	end
	return nil
end

local function wordIn(message)
	for _, word in ipairs(WORDS) do
		if MsgContains(message, word) then
			return word
		end
	end
	return nil
end

-- Returns true when the message was part of the Mission 5 talk (answered here).
function F.negotiate(npc, creature, message, npcHandler, key)
	if not Family.newFrontierNegotiation then
		return false
	end
	local player = Player(creature)
	local data = F.npcs[key]
	if not player or not data then
		return false
	end
	local s = TNF()
	local stateKey = s.Mission05[data.storage]
	local state = player:getStorageValue(stateKey)
	local playerId = player:getId()
	local questline = player:getStorageValue(s.Questline)

	if MsgContains(message, "farmine") then
		if questline ~= 14 then
			return false
		end
		if state == 3 then
			npcHandler:say(data.done, npc, creature)
			setPending(key, playerId, nil)
		elseif state == 2 then
			npcHandler:say(data.apology, npc, creature)
			setPending(key, playerId, "gift")
		else
			npcHandler:say(data.intro, npc, creature)
			setPending(key, playerId, "words")
		end
		return true
	end

	local pending = getPending(key, playerId)
	if not pending or questline ~= 14 then
		return false
	end

	if pending == "words" then
		local word = wordIn(message)
		if not word then
			return false -- anything else goes to the NPC's own dialogue
		end
		setPending(key, playerId, nil)
		if word == F.secretWord(player, key) then
			npcHandler:say(data.success[word], npc, creature)
			player:setStorageValue(stateKey, 3)
		else
			npcHandler:say(data.fail[word] or data.other, npc, creature)
			player:setStorageValue(stateKey, 2) -- quest log: find an item for another chance
		end
		return true
	end

	if pending == "gift" then
		if MsgContains(message, "yes") then
			if player:removeItem(data.gift, 1) then
				npcHandler:say(data.accepted, npc, creature)
				player:setStorageValue(stateKey, 1)
				setPending(key, playerId, "words")
			else
				npcHandler:say("You have nothing with you that could change my mind.", npc, creature) -- ours
				setPending(key, playerId, nil)
			end
			return true
		elseif MsgContains(message, "no") then
			npcHandler:say("Then there is nothing more to discuss.", npc, creature) -- ours
			setPending(key, playerId, nil)
			return true
		end
	end
	return false
end

-- Ongulf while a mission runs (ours; upstream said nothing).
F.ongulfReminders = {
	[1] = "Take the lift up into the mountains and find a passage leading out of them. Then come back and tell me.",
	[4] = "Have you talked to Melfar yet? You'll find him in the western mines outside of The Big Old One. We need those men and that wood.",
	[5] = "Melfar has not sent anything yet. Do what he asked you to do and talk to him again.",
	[8] = "Find these vines in this mountain, climb up there and find out who is spying on us!",
	[11] = "Use the mining lift to reach mine A07 and slay the leader of those stone creatures.",
	[14] = "We still need the support of all our partners. Your quest log tells you who has not agreed yet. If you blow the negotiations, Black Bert in Thais may have the right bribe.",
	[16] = "Find the leaders of the orcs in the steppe and make them stop their attack plans. This is our only hope.",
	[17] = "Find the leaders of the orcs in the steppe and make them stop their attack plans. This is our only hope.",
	[18] = "Find the leaders of the orcs in the steppe and make them stop their attack plans. This is our only hope.",
	[21] = "If the orcs are right, those lizards are somewhere in or behind the mountains in the north. Find them and keep them away from us.",
	[22] = "If the orcs are right, those lizards are somewhere in or behind the mountains in the north. Find them and keep them away from us.",
	[23] = "You look like someone who has been in a lizard prison. Whatever happened up there, come back when you are done with it.",
	[24] = "You look pale, my friend. Whatever those lizards want from you, come back when you are done with it.",
	[25] = "You look pale, my friend. Whatever those lizards want from you, come back when you are done with it.",
	[26] = "You look pale, my friend. Whatever those lizards want from you, come back when you are done with it.",
	[27] = "You look pale, my friend. Whatever those lizards want from you, come back when you are done with it.",
	[29] = "This new land is yours to be taken. Go out and make your fortune! With Farmine you have always a safe haven to return to.",
}

-- Ongulf's greeting on each floor of Farmine: stage 1 (EN/BR), stage 2 (BR,
-- report of mission 3) and stage 3 (EN, report of mission 10; BR, report of
-- mission 6).
F.ongulfGreetings = {
	[14] = "Hello, |PLAYERNAME|. You've come at a good time for our {project}.",
	[12] = "Hello. At last our {project} is progressing.",
	[10] = "Hello. Now that's what I'd call a {project} working ... more or less.",
}

-- Mortal Combat reward room (BR: Zurak "reward"; same square Tirecz sends the
-- winners to).
F.rewardRoom = Position(33062, 31029, 7)

function F.rewardMissing(player)
	local s = TNF()
	if player:getStorageValue(s.Questline) < 26 then
		return false
	end
	if player:getStorageValue(s.Questline) == 26 then
		return true -- the outfit (armor rack) was not taken yet
	end
	return player:getStorageValue(s.Reward.Potions) < 1 or player:getStorageValue(s.Reward.GoldIngot) < 1 or player:getStorageValue(s.Reward.PigBank) < 1
end
