-- Gaia Family server: Adventures of Galthen, "Galthen and the Lost Queen" (2026-11-23). Ours:
-- upstream had Megasylvan Yselda's lever and monster, the Forest of Life entrances, the satchel tree,
-- An Idol's VBOX, the Bounacean Lion door and John's carpets, but none of the story: no Yselda talk,
-- no Lesh or Alphonse, no soup kettle, no ritual words, no saplings, no outfit, tulip or addon.
-- Quest Roadmap #16 (Royal Bounacean Advisor Outfits): the outfit and the first addon. The second
-- addon (The Order of the Stag, update 15.20, Isle of Ada) is not possible with client 15.11
-- (Rodrigo 2026-11-23: leave it out; see claude/server-status.md).
--
-- Sources: TibiaWiki BR backup "Adventures of Galthen Quest" (all transcripts and squares),
-- "Royal Bounacean Advisor Outfits Quest", "John The Carpenter", "Larfion"; TibiaWiki EN
-- "Adventures of Galthen Quest/Spoiler", "Royal Bounacean Advisor Outfits Quest/Spoiler",
-- "Megasylvan Yselda", "Megasylvan Sapling (Creature)", the item pages and the achievements.
--
-- The story (storage LostQueen):
--   0 -> Kesar the Younger (day, Hero of Bounac) `yselda`, then anything   -> 1
--   1 -> Lesh the Seer (hut 32406,32471,6) `yselda`                        -> 2
--   2 -> Spectulus (Edron academy) `yselda`, `yes`                         -> 3
--        An Idol: use the floor in front of him (VBOX), the dead tree gives Galthen's satchel (upstream)
--   3 -> Innkeeper Alphonse (inn 32417,32501,7) `yselda`, `yes` x3: Ritual Notes -> 4
--   4 -> Kesar `yselda`: access to the Bounacean Lion (door storage AccessDoor) -> 5
--   5 -> soup kettle (32591,32484,13): 20 carnisylvan fingers, 10 barks, 2 human teeth, then use it -> 6
--        (the crystal teleporter by the Sleeping Carnisylvans and the lever need this)
--   6 -> Megasylvan Yselda killed (Woodcarver)                             -> 7
--   7 -> Kesar `yselda`: the outfit; with her four saplings alive also the violet tulip and John -> 8
--   8 -> the tulip used next to Yselda after a kill with the saplings alive (Bounacean Chivalry) -> 9
-- John (Bounac), at night: `yselda` gives the first addon (Kesar's permission), then `fragments`.
-- The ritual words DEMIHBOULDR, SOMMBHA and WITHER said in the boss room make Yselda vulnerable
-- (Yselda: "AAAAAAAAAAAAAH!!!"); from then on her four Megasylvan Saplings (10,000 health, EN) lose
-- health every 2 seconds and must be healed (Ultimate Healing Runes, Mass Healing).
-- Our numbers: the saplings lose 400 every 2 seconds (Tibia: about 1,000 for a team of five, EN;
-- BR "about 200 per turn"; 40% for two players). Lines no wiki has are marked ours.

FamilyGalthen = {
	items = {
		fingers = 36805,
		barks = 36806,
		teeth = 36807,
		tulip = 36812,
		notes = 36923, -- Ritual Notes
		parchment = 2819,
		kettle = 11811,
	},
	need = { fingers = 20, barks = 10, teeth = 2 },
	outfit = { male = 1436, female = 1437 },
	kettlePos = Position(32591, 32484, 13),
	gatePos = Position(32580, 32481, 12), -- crystal teleporter by the Sleeping Carnisylvans
	gateAid = 48788,
	leverRoom = Position(32581, 32500, 12),
	idolFloor = { Position(32397, 32510, 7), Position(32398, 32510, 7) },
	idolPos = Position(32398, 32509, 7),
	yseldaNpcPos = Position(32619, 32492, 12),
	bossPos = Position(32619, 32493, 12),
	room = { fromX = 32601, toX = 32633, fromY = 32486, toY = 32509, z = 12 },
	saplings = {
		Position(32609, 32489, 12),
		Position(32628, 32488, 12),
		Position(32609, 32504, 12),
		Position(32629, 32506, 12),
	},
	saplingDamage = 400, -- ours, every 2 s
	words = { "demihbouldr", "sommbha", "wither" },
	parchmentText = "Ancient notes from the knight Galthen, written specifically about disturbing events in and around the then young enclave of Bounac. A particularly long and detailed passage deals with the disappearance of a woman. Presumably due to a curse. The disappearance and heritage of the woman in great length with every clue known to Galthen at the time being meticulously recorded by the knight himself.",
	fight = { active = false, vulnerable = false, saplingDied = false, heard = {} },
}

local G = FamilyGalthen

local function S()
	return Storage.Quest.U12_70.AdventuresOfGalthen
end
G.S = S

function G.get(player, key)
	return math.max(0, player:getStorageValue(S()[key]))
end

function G.set(player, key, value)
	player:setStorageValue(S()[key], value)
end

function G.state(player)
	return G.get(player, "LostQueen")
end

function G.setState(player, value)
	if G.state(player) < value then
		G.set(player, "LostQueen", value)
	end
	if player:getStorageValue(S().Questline) < 1 then
		G.set(player, "Questline", 1)
	end
end

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
end

local function isNight()
	return FamilyLion and FamilyLion.isNight and FamilyLion.isNight()
end

local function isHero(player)
	return not FamilyLion or not FamilyLion.isHero or FamilyLion.isHero(player)
end

-- ---------------------------------------------------------------------------
-- Kesar the Younger
-- ---------------------------------------------------------------------------
local TOPIC_KESAR = 4701

function G.kesarGreeting(player)
	if isHero(player) and not isNight() then
		return "Hail, what can I do for the hero of Bounac? The siege is finally under control, thanks to you."
	end
	return nil
end

local KESAR_START = {
	"Wait, before you say anything - you truly have earned my trust and the goodwill of all the people of Bounac. However, this matter is of the most delicate nature. ...",
	"Her name is merely a whisper across these lands and I dare not summon the cruel ghosts of our cursed past. ...",
	"Yselda, my beloved wife has been taken from me. I am sure of it. Dark forces far beyond my control took a part in this malicious play. ...",
	"Someone, or something... took her. Away from me, away from Bounac I fear and into the depths of a dark misery not even the foulest of creatures could have conjured up. ...",
	"I've seen it. I have seen her. Standing there, just standing. Trying to talk to me. Shrouded in a black mass ...",
	"I visited a seer, Lesh, he showed me her dark fate. To this day I battle the dreams I paid this unsettling knowledge with. ...",
	"She is not dead, nor is she alive. She just stands there, waiting. Breathing, watching. Excuse me, I cannot bear these thoughts much longer.",
}

local KESAR_ACCESS = {
	"You found what? What are you trying to imply...? I see you reluctant to tell me the full story. Remind me, hero, why should I give you access to anything at all if that is the case? ...",
	"You want access to what...? There are no such places. Why is this connected to my poor Yselda? You must tell me everything you know! ...",
	"Investigate? Hm. To what ends? She is gone for so long. Yet my heart is still full of hope. Hmmh... ...",
	"Alas, hero of Bounac, have it your way then. You have proven your worth many a time. So let me tell you of one place that has been kept sealed for a long time. ...",
	"Under these very halls, deep within the mountain, there is a massive cove, carved into the rock. ...",
	"A long time ago when my father discovered the island, he lead a whole unit into the caves beneath. They came to a large opening in pitch black darkness. ...",
	"One of the knights climbed the rocky walls in search for a higher position to illuminate the area with his torch. ...",
	"He saw a gigantic lion, embedded into the stone floor. Shedding more lights from more torches into the place showed them something far more terrifying, however. ...",
	"Bones lay scattered across the whole site. And they moved. ...",
	"The knights saw the lion and the bones as a sign and fled. The area was sealed, never to be opened and the key was hidden. I myself have not yet laid eyes on the chamber. ...",
	"I will grant you access to the Bounacean Lion but promise me, for the safety of Bounac, never to let anything out of there.",
}

local KESAR_REPORT_START = {
	"Tell me... everything. ...",
	"I see... so you did what I could not. While I sat here, lazy, ignorant... yes, yes, it was probably for the better. ...",
	"I would not have been able to do what you have done. It was not for me to finish what that terrible curse has started who knows how many generations ago. ...",
	"You did good in leaving me out of your own investigations. My ability to take decisions would have been clouded, tarnished would have been my vision and with hands all but paralysed. ...",
}

local KESAR_REPORT_DIED = {
	"Yselda lives yet she does not all the same. I will mount an expedition post-haste, though I fear it is too late to make any difference. ...",
	"Now... I need to reflect on the events. I thank you, hero of Bounac. As a token of my gratitude, you are now joining the circle of my royal advisors, ceremonial garb and all. ...",
	"Now, I have pressing matters to attend to once again. Dark days may yet lie ahead, dark days indeed.",
}

local KESAR_REPORT_ALIVE = {
	"So, Yselda lives, albeit in a most dire state. I will mount an expedition post-haste. ...",
	"As a token of my gratitude, you are now joining the circle of my royal advisors, ceremonial garb and all. Please also visit John, the Carpenter afterwards and tell him I sent you. ...",
	"But, there is one other thing. ...",
	"Hero of Bounac, I would like to ask for a most delicate favour. Please, take this tulip and bring it to my beloved Yselda while I muster my men. There is no time to lose. ...",
	"And if this is the last thing her old self recognises of me, so be it. Hurry, please.",
}

local function concat(a, b)
	local out = {}
	for _, l in ipairs(a) do
		out[#out + 1] = l
	end
	for _, l in ipairs(b) do
		out[#out + 1] = l
	end
	return out
end

function G.giveOutfit(player)
	if G.get(player, "Outfit") >= 1 then
		return
	end
	G.set(player, "Outfit", 1)
	player:addOutfit(G.outfit.male)
	player:addOutfit(G.outfit.female)
end

function G.giveTulip(player)
	if G.get(player, "Tulip") >= 1 then
		return false
	end
	G.set(player, "Tulip", 1)
	G.set(player, "JohnPermission", 1)
	player:addItem(G.items.tulip, 1)
	return true
end

-- Returns the text for Kesar's `yselda`, or nil when this player gets no Yselda talk.
function G.kesarYselda(player, npcHandler, npc, creature)
	local state = G.state(player)
	if not isHero(player) then
		return nil
	end
	if state == 0 then
		npcHandler:setTopic(player:getId(), TOPIC_KESAR)
		return "Yselda... my Yselda. What do you know about her, hero of Bounac?"
	elseif state < 4 then
		return "Have you found out anything about my Yselda? Lesh the seer showed me her fate, perhaps he can tell you more." -- ours
	elseif state == 4 then
		G.setState(player, 5)
		G.set(player, "AccessDoor", 1)
		return KESAR_ACCESS
	elseif state < 7 then
		return "The Bounacean Lion lies beneath us, sealed for so long. Find out what happened to my Yselda, hero." -- ours
	elseif state == 7 then
		G.setState(player, 8)
		G.giveOutfit(player)
		if G.get(player, "Outcome") >= 2 then
			G.giveTulip(player)
			return concat(KESAR_REPORT_START, KESAR_REPORT_ALIVE)
		end
		return concat(KESAR_REPORT_START, KESAR_REPORT_DIED)
	elseif state == 8 then
		if G.get(player, "Outcome") >= 2 and G.giveTulip(player) then
			-- a later kill with her saplings alive
			return {
				"You saved her children as well? Then there is hope yet. Please also visit John, the Carpenter and tell him I sent you. ...", -- ours
				KESAR_REPORT_ALIVE[4],
				KESAR_REPORT_ALIVE[5],
			}
		end
		if G.get(player, "Tulip") == 1 then
			return "Please, bring the tulip to my beloved Yselda. Hurry." -- ours
		end
		return "Thank you, hero of Bounac. My expedition will do what it can for Yselda." -- ours
	end
	return "You have my eternal gratitude " .. player:getName() .. ", hero of Bounac."
end

-- Called from Kesar's message callback before The Order of the Lion. Returns true when handled.
function G.kesarSay(npc, creature, player, message, npcHandler)
	local id = player:getId()
	if npcHandler:getTopic(id) == TOPIC_KESAR then
		npcHandler:setTopic(id, 0)
		G.setState(player, 1)
		say(npcHandler, npc, creature, KESAR_START)
		return true
	end
	if not MsgContains(message, "yselda") then
		return false
	end
	if isNight() then
		say(npcHandler, npc, creature, "It is late, traveller. Come to the throne room in the morning.") -- ours
		return true
	end
	local text = G.kesarYselda(player, npcHandler, npc, creature)
	if not text then
		return false
	end
	say(npcHandler, npc, creature, text)
	return true
end

-- ---------------------------------------------------------------------------
-- Lesh the Seer (new NPC; BR transcript)
-- ---------------------------------------------------------------------------
local LESH = {
	"Yselda, yes... poor, dammed Yselda. Kesar is all but in distress since her disappearance. Unfortunately, I inherited the gift of sight. ...",
	"And Kesar, our king sent after this very seer you are talking to right now, for me to find her... Yselda. ...",
	"Yet I couldn't please the king, nor could I soothe his soul. ...",
	"What is the true curse? The curse itself or to witness a curse as the most powerful man in the lands yet unable to step in and make a change? ...",
	"I showed Kesar what happened to his beloved. A curse, terrible and dark. She left to find answers to questions she didn't know the past planted in her. ...",
	"She lives, yet sits in the dark, still, without motion. Waiting, ever waiting and watching. I gave the king this vision, for he asked for it. ...",
	"He was never the same since. But... there is still hope. I saw a knight. No, not you, hero. An old, weary knight - yet did flames of zeal burn strong in him. ...",
	"He was on a path to find a lost one, much the same as you. But it is not that path which now crosses your own. ...",
	"He was here, generations ago, investigating events much similar to what currently unfolds. Find the trace of the knight Galthen. ...",
	"He left Bounac for Edron to council the mages, follow him.",
}

function G.leshGreeting()
	if isNight() then
		return "A horrible night for a curse in Bounac, isn't it? Or aren't you here because of... Kesar? No, I know - it's {Yselda} occupies your mind."
	end
	return "A good day I wish, wanderer. Are you here because of the curse? I know you're here because of it... I know it. But am I right?"
end

function G.leshSay(npc, creature, player, message, npcHandler)
	if MsgContains(message, "yselda") or MsgContains(message, "curse") or (MsgContains(message, "yes") and G.state(player) >= 1) then
		if G.state(player) < 1 then
			say(npcHandler, npc, creature, "Yselda... a name not to be spoken lightly. Ask our king about her, if he lets you.") -- ours
			return true
		end
		G.setState(player, 2)
		say(npcHandler, npc, creature, LESH)
		return true
	end
	return false
end

-- ---------------------------------------------------------------------------
-- Spectulus (hook in his upstream file)
-- ---------------------------------------------------------------------------
local TOPIC_SPECTULUS = 4702
local SPECTULUS = {
	"I see, so the king of Bounac, Kesar the Younger has lost his betrothed. Hmm, by what you described to me, her disappearance seems to be connected to a curse. ...",
	"I have an idea! You see, some time ago I was conducting experiments with plants regarding their abilities to root, most notably a young oak tree. ...",
	"Trees have a remarkable way of... ah yes, your impatient eyes tell me that you're not here for botanical studies. So, where was I? ...",
	"Ah yes, so I was looking for academic publications on the subject and between 'Two Ferns', an abridged version of a popular book on forest flora, and 'Tree out of Four', I remembered it. ...",
	"Carnisylvans', a collection of notes from an investigation of an island enclave by the name of Bounac. Conducted by elder mages from the Edron academy as well as the honourable knight and former Edron citizen Galthen. ...",
	"A large portion of this work is dedicated to trees, you know. However, much of it has been hastily written down without much research. ...",
	"As you may already have guessed, it didn't prove very useful for my current endeavour - yet, while consistently disturbing, I found its contents... ...",
	"...remarkably memorable. A great curse seems to transform people into a form of... wooden facsimile of a human being. ...",
	"Look, I know this sounds strange but a lot of the crude conclusions from the older mages rang true. ...",
	"A form of biological curse forced females to transform after giving birth, conduct a strange ritual on their children and... ...",
	"Wander out into the dark, leaving everything behind. Never to return and ultimately to carry out a complete metamorphosis. ...",
	"If that's what happened to Kesar's Yselda, she might have gone to find a place to fully metamorph. ...",
	"If my own conclusions at this point are any indication, we should try to look for a large cave or tunnel underground. ...",
	"Bounac is an island, not many ships have left from there during the siege as far as I know so chances are slim that she ever left it that way. ...",
	"Since people didn't see her leave and no body was found, I assume she took a path known to the royal court of Bounac exclusively. ...",
	"At first you should try to find out what Galthen discovered. Maybe he left some traces in Bounac. You should go there and look for secret areas, cellars, places off-limits to everyone but the king himself. ...",
	"Convince the king to give you every key to every secret of the enclave, it will be your only hope to find out what happened to Yselda.",
}

function G.spectulusSay(npc, creature, player, message, npcHandler)
	local id = player:getId()
	if npcHandler:getTopic(id) == TOPIC_SPECTULUS then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			G.setState(player, 3)
			say(npcHandler, npc, creature, SPECTULUS)
		else
			say(npcHandler, npc, creature, "As you wish. My door is always open for interesting stories.") -- ours
		end
		return true
	end
	if not MsgContains(message, "yselda") or G.state(player) < 2 then
		return false
	end
	say(npcHandler, npc, creature, "That name... it means something to you, {yes}? Do you want to tell me about it?")
	npcHandler:setTopic(id, TOPIC_SPECTULUS)
	return true
end

-- ---------------------------------------------------------------------------
-- Innkeeper Alphonse (new NPC; BR transcript)
-- ---------------------------------------------------------------------------
local ALPHONSE = {
	{
		"There was a knight, Galthen, I assume the name already rings a bell since you're interested in the story of poor Yselda. ...",
		"My Father told me of him, I remember the story very well for he was most disturbed by its implications. You know, my father was not an easy man to frighten... ...",
		"But this tale? Well, let's just say he wasn't about to forget what Galthen had to say for he visited the Lionheart back in the day when my father was still young. ...",
		"After a long and delightful evening in the inn, the old knight loosened up a bit. He told my old man that he was on an investigation of a strange cult. ...",
		"I do not know if all this is related to a cult that actually existed or if it was a cult at all, I'm only telling you what I was told. ...",
		"He told my father of strange occult rituals and that noblewoman, princesses were disappearing to follow an unknown path, never to be seen again. ...",
		"A young woman with no relation to Kesar, the father of Kesar the Younger was about to be married to a knight from the original order of knights who founded this enclave. ...",
		"The woman was already pregnant, which was quite a problem for the young couple but the fact was not known to anyone yet but the couple themselves - and the old knight Galthen as it turned out. ...",
		"Give me a second, I have to take care of the most unnerving customer over at the second to last table in the back. Tell me if you want to continue, alright?",
	},
	{
		"Yes. So, sorry for that but the customer is king in Bounac, especially if the king himself refuses to bask in these honours himself. ...",
		"Where was I? Ah yes, the young couple. So it turns out Galthen helped the couple cover their secret and get married in the end, however... ...",
		"The woman fell victim to a cruel ritual or part of a cult tradition for she disappeared not long after giving birth to her daughter. ...",
		"Just as she was about to recover, she left Bounac, never to be seen again, not a word to the young father or anyone in the enclave. ...",
		"Galthen could not bring her back, but he could explain some of the events behind her disappearance. Apparently she had to go to a secret place, to die. ...",
		"She also conducted a strange ritual the night her daughter was born. When her husband was alerted by noises in the middle of the night, he first assumed that his wife was sleepwalking, due to the stress and pain of being in labour and giving birth. ...",
		"However, she was mumbling in a strange tongue, seemingly dreaming while fully awake. As he shook her and took the child, she woke up furiously and violently grabbed his throat before she recognised him and came to her senses. ...",
		"Fears for the life and well-being of the child arose and local healers where called to look after the child. Galthen seemed to recognise the ritual and immediately performed a blessing to counter it. ...",
		"When the woman disappeared not long after the events, he told the father to focus on his daughter and take good care of the child. ...",
		"For once she came of age there would still be a slight chance for her to take the same dreadful path as her mother. Galthen ultimately left to investigate her disappearance and for other, even more pressing matters. ...",
		"And my father went on with his life to witness this weird course of events a second time, when the daughter came of age - just as the old knight had predicted. ...",
		"Her father died at the hands of thieves when she was but 15 years old. Neither did he witness her marriage with a young and handsome nobleman, nor did he have to suffer through the loss of her disappearance after giving birth to his grand-daughter. ...",
		"This grand-daughter was Yselda herself. I was born not long after her and I knew her as a fair and honourable woman with a kind heart. ...",
		"She fell in love with Kesar the Younger and undoubtedly the king told you the rest of the story himself, am I right?",
	},
	{
		"In any case, I know the story sounds strange, however, neither me nor my father are madmen - there is a truth to this, I assure you. ...",
		"The old knight left some of his notes while he stayed in the inn. My father kept them as a memento. You can have them if you want, here. ...",
		"Maybe you can solve the puzzle once and for all. I doubt there is hope for Yselda but to me it seems the circle has been broken, for she had no child and may have gone of her own free will.",
	},
}

function G.alphonseSay(npc, creature, player, message, npcHandler)
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	if topic >= 4711 and topic <= 4713 then
		npcHandler:setTopic(id, 0)
		if not MsgContains(message, "yes") then
			say(npcHandler, npc, creature, "Another time, then. The story is not going anywhere.") -- ours
			return true
		end
		local part = topic - 4710
		say(npcHandler, npc, creature, ALPHONSE[part])
		if part < 3 then
			npcHandler:setTopic(id, topic + 1)
		else
			if player:getItemCount(G.items.notes) < 1 then
				player:addItem(G.items.notes, 1)
			end
			G.setState(player, 4)
		end
		return true
	end
	if MsgContains(message, "yselda") or MsgContains(message, "galthen") then
		if G.state(player) < 3 then
			say(npcHandler, npc, creature, "Yselda? Poor girl. Ask our king, if you dare. I'd rather not speak of it to strangers.") -- ours
			return true
		end
		say(npcHandler, npc, creature, "I know why you're asking this. Is it because of the tragedy of her life? The burden, our beloved Kesar has to carry still?")
		npcHandler:setTopic(id, 4711)
		return true
	end
	return false
end

-- ---------------------------------------------------------------------------
-- John (Bounac), at night
-- ---------------------------------------------------------------------------
local JOHN = {
	"Oh wait wait wait, aren't you the Hero of Bounac, Royal advisor to the king himself? ...",
	"What you did for Kesar and the people of Bounac is not to be measured in any currency of the world - let me express my deepest gratitude. ...",
	"In the name of the people of Bounac, let me say thank you, brave hero. And oh yes, I have something for you, too! ...",
	"As I can see you already received the royal advisor outfit, let me give this an even more ornate touch. Right now. ...",
	"What? Yes, carpenter. Why? Do you think I can't sew? Here, let me show the unbeliever... ...",
	"There! There you go. Just like that. What do you say? Ah, don't say a word - it looks very fashionable. Given I had only my field equipment here. ...",
	"There is one more thing, you can now also ask me for something I'd not normally sell in my shope. You know... ...",
	"I once got ahold of these... strange cloth fragments. I don't know what they are but a traveller once wanted to pay me a ridiculous sum to just take a look at one. ...",
	"Somehow I felt that it wasn't... right. I refused. And now, now I am confident that I have found a better customer for these items. You! ...",
	"Just ask me for some of the {fragments} if you like, any time. I carry most of them with me all the time for they weigh almost nothing. Strange.",
}

function G.johnGreeting()
	if isNight() then
		return "Good evening, sorry but it's already quite late and I'm technically on vacation... please make it quick!"
	end
	return "Oh, hello. I'm only home for a moment, I'm off to my bath at the underground lake. Come back in the evening." -- ours (by day he bathes, BR)
end

function G.canTradeJohn(player)
	return G.get(player, "JohnAddon") >= 1
end

-- Returns true when handled.
function G.johnSay(npc, creature, player, message, npcHandler)
	if MsgContains(message, "fragments") then
		if not G.canTradeJohn(player) then
			say(npcHandler, npc, creature, "Fragments? I don't know what you mean.") -- ours
			return true
		end
		npc:openShopWindow(player)
		say(npcHandler, npc, creature, "Here, have a look. Strange things, aren't they?") -- ours
		return true
	end
	if not MsgContains(message, "yselda") then
		return false
	end
	if not isNight() then
		say(npcHandler, npc, creature, "Not now, please, come back in the evening.") -- ours
		return true
	end
	if G.get(player, "JohnPermission") < 1 or G.get(player, "Outfit") < 1 then
		say(npcHandler, npc, creature, "Yselda? The queen? I'm just a carpenter, I don't know anything about her.") -- ours
		return true
	end
	if G.get(player, "JohnAddon") >= 1 then
		say(npcHandler, npc, creature, "It still looks very fashionable on you! And remember the {fragments}, any time.") -- ours
		return true
	end
	G.set(player, "JohnAddon", 1)
	player:addOutfitAddon(G.outfit.male, 1)
	player:addOutfitAddon(G.outfit.female, 1)
	say(npcHandler, npc, creature, JOHN)
	return true
end

-- ---------------------------------------------------------------------------
-- Yselda (new NPC in the boss room)
-- ---------------------------------------------------------------------------
local YSELDA_DIED = {
	"You freed me... yet my children had to die. It may have been for the better, brave warrior. All around me, I can see them awake. Brothers, sisters, generations. We will not rest, we cannot be stopped. ...",
	"Our will is of iron and stone. Our souls ever dreaming, powerful beyond this world and never to falter. ...",
	"You have to go now, warrior... heed my warning: it's about to begin, this world may yet tremble under the crushing force of other sylvans like me. ...",
	"I found a way to connect, for I was not pure but they merged, I became them, they became... me. You have to go, I will... try to keep, a stand...",
}

local YSELDA_ALIVE = {
	"You freed me, brave warrior... and you even saved my... children. ...",
	"I always wanted children in my life, I never... had... I never was able... to...ach! ...",
	"No... no - do not worry about me. This pain is for me to bear. I cherish the light of life that is once again visible to my eyes. ...",
	"Yet I also see what happened around me. What exists... around me. I will have to stay here, for my former self is no more. My heart... is with my husband, Kesar. Always. ...",
	"Tell him... I will keep watch, I will not let the elder sylvans wake. Bounac... this world, will be safe. ...",
	"Now go! Leave this place, warrior... and be my herold. Let this warning be known to all the people of Bounac and beyond: ...",
	"Do not come here and leave us dream, for we are the sleep and siblings to death.",
}

-- The greeting after a kill this player took part in; nil while the fight is on.
function G.yseldaGreeting(player)
	local kv = player:kv():scoped("family-galthen")
	local last = kv:get("last-kill")
	if G.fight.active or not last or os.time() - last > 30 * 60 then
		return "..." -- ours: she does not answer while the curse holds her
	end
	return (kv:get("last-outcome") or 1) >= 2 and YSELDA_ALIVE or YSELDA_DIED
end

-- ---------------------------------------------------------------------------
-- The fight
-- ---------------------------------------------------------------------------
function G.inRoom(pos)
	local r = G.room
	return pos.z == r.z and pos.x >= r.fromX and pos.x <= r.toX and pos.y >= r.fromY and pos.y <= r.toY
end

G.roomCenter = Position(32617, 32497, 12)

-- Creatures of that name inside the boss room.
function G.inRoomNamed(name)
	local out = {}
	for _, c in ipairs(Game.getSpectators(G.roomCenter, false, false, 17, 17, 12, 12)) do
		if c:getName() == name and G.inRoom(c:getPosition()) then
			out[#out + 1] = c
		end
	end
	return out
end

-- Megasylvan Yselda appeared: a new fight (also called when the words find a boss of a new fight).
function G.startFight(bossId)
	G.fight = { active = true, vulnerable = false, saplingDied = false, heard = {}, bossId = bossId }
end

-- The boss of the running fight, starting a new fight state when a new boss stands there.
function G.currentBoss()
	local boss = G.inRoomNamed("Megasylvan Yselda")[1]
	if not boss then
		return nil
	end
	if G.fight.bossId ~= boss:getId() then
		G.startFight(boss:getId())
	end
	return boss
end

-- Words said in the room. Returns true when this made Yselda vulnerable.
function G.hear(player, message)
	if not G.inRoom(player:getPosition()) or not G.currentBoss() then
		return false
	end
	local f = G.fight
	if f.vulnerable then
		return false
	end
	local text = message:lower()
	for _, word in ipairs(G.words) do
		if text:find(word, 1, true) then
			f.heard[word] = true
		end
	end
	for _, word in ipairs(G.words) do
		if not f.heard[word] then
			return false
		end
	end
	f.vulnerable = true
	G.hurtSaplings(f)
	return true
end

function G.isVulnerable(boss)
	return G.fight.active and G.fight.vulnerable and G.fight.bossId == boss:getId()
end

-- Every 2 seconds while the fight runs: the saplings wither.
function G.hurtSaplings(f)
	if G.fight ~= f or not f.active or not f.vulnerable then
		return
	end
	-- setHealth: the engine refuses combat damage on creatures that cannot be attacked
	for _, sapling in ipairs(G.inRoomNamed("Megasylvan Sapling")) do
		local left = sapling:getHealth() - G.saplingDamage
		local pos = sapling:getPosition()
		if left <= 0 then
			pos:sendMagicEffect(CONST_ME_POFF)
			sapling:remove()
			G.saplingDied()
			for _, p in ipairs(Game.getSpectators(G.roomCenter, false, true, 17, 17, 12, 12)) do
				p:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A megasylvan sapling withers away.") -- ours
			end
		else
			sapling:setHealth(left)
			pos:sendMagicEffect(CONST_ME_GREEN_RINGS)
		end
	end
	addEvent(G.hurtSaplings, 2000, f)
end

function G.saplingDied()
	if G.fight.active then
		G.fight.saplingDied = true
	end
end

-- Megasylvan Yselda died: every player in the room gets the kill.
function G.yseldaDied(players)
	local f = G.fight
	f.active = false
	local outcome = f.saplingDied and 1 or 2
	for _, player in ipairs(players) do
		G.set(player, "Outcome", math.max(G.get(player, "Outcome"), outcome))
		local kv = player:kv():scoped("family-galthen")
		kv:set("last-kill", os.time())
		kv:set("last-outcome", outcome)
		if G.state(player) >= 5 then
			G.setState(player, 7)
		end
		player:addAchievement("Woodcarver")
	end
	for _, sapling in ipairs(G.inRoomNamed("Megasylvan Sapling")) do
		sapling:remove()
	end
	return outcome
end

-- The tulip used next to Yselda. Returns the text to show, or nil when not near her.
function G.useTulip(player)
	local near = false
	for _, c in ipairs(Game.getSpectators(player:getPosition(), false, false, 3, 3, 3, 3)) do
		if c:isNpc() and c:getName() == "Yselda" then
			near = true
		end
	end
	if not near then
		return nil
	end
	local kv = player:kv():scoped("family-galthen")
	if G.get(player, "Tulip") ~= 1 then
		return "Yselda does not seem to notice the flower." -- ours
	end
	if (kv:get("last-outcome") or 0) < 2 or os.time() - (kv:get("last-kill") or 0) > 30 * 60 then
		return "The curse still holds Yselda. Free her and her children first." -- ours
	end
	player:removeItem(G.items.tulip, 1)
	G.set(player, "Tulip", 2)
	G.setState(player, 9)
	player:addAchievement("Bounacean Chivalry")
	return "Yselda takes Kesar's tulip with trembling fingers. For a moment, a smile crosses her face." -- ours
end

-- ---------------------------------------------------------------------------
-- The soup kettle
-- ---------------------------------------------------------------------------
-- An ingredient used on the kettle. Returns the text.
function G.addIngredient(player, item)
	local which = ({ [G.items.fingers] = "fingers", [G.items.barks] = "barks", [G.items.teeth] = "teeth" })[item:getId()]
	if not which then
		return nil
	end
	if G.state(player) < 5 then
		return "A strange creature looks into your eyes. While it is clearly sentient, its mind seems to hide far away from this place."
	end
	if G.state(player) >= 6 then
		return "The soup is ready already." -- ours
	end
	local key = ({ fingers = "Fingers", barks = "Barks", teeth = "Teeth" })[which]
	local have = G.get(player, key)
	local need = G.need[which]
	if have >= need then
		return "There is enough of this in the kettle already." -- ours
	end
	local put = math.min(need - have, item:getCount())
	item:remove(put)
	G.set(player, key, have + put)
	local names = { fingers = "carnisylvan fingers", barks = "carnisylvan barks", teeth = "human teeth" }
	return string.format("You put %d %s into the kettle (%d / %d).", put, names[which], have + put, need) -- ours
end

-- The kettle used. Returns the text.
function G.useKettle(player)
	if G.state(player) < 5 then
		return "A strange creature looks into your eyes. While it is clearly sentient, its mind seems to hide far away from this place."
	end
	if G.state(player) >= 6 then
		return "Excellet. It is done. Now to pour it all over... everything... everyone... yes, just like that."
	end
	local missing = {}
	for which, need in pairs(G.need) do
		local key = ({ fingers = "Fingers", barks = "Barks", teeth = "Teeth" })[which]
		local left = need - G.get(player, key)
		if left > 0 then
			missing[#missing + 1] = string.format("%d %s", left, ({ fingers = "carnisylvan fingers", barks = "carnisylvan barks", teeth = "human teeth" })[which])
		end
	end
	if #missing > 0 then
		table.sort(missing)
		return "The soup is not complete. It still needs " .. table.concat(missing, ", ") .. "." -- ours
	end
	G.setState(player, 6)
	return "Excellet. It is done. Now to pour it all over... everything... everyone... yes, just like that."
end

-- ---------------------------------------------------------------------------
-- Quest log (ours)
-- ---------------------------------------------------------------------------
function G.describe(player)
	local state = G.state(player)
	local texts = {
		[0] = "Ask Kesar the Younger in Bounac about Yselda.",
		[1] = "Kesar the Younger told you about his wife Yselda. Talk to Lesh the Seer in his hut in the mountains of Bounac.",
		[2] = "Lesh the Seer told you to follow the trace of the knight Galthen to the mages of Edron. Talk to Spectulus in the Edron academy.",
		[3] = "Spectulus thinks Yselda took a path known only to the royal court. Look for Galthen's traces in Bounac: An Idol in the south and Innkeeper Alphonse in the inn.",
		[4] = "Innkeeper Alphonse gave you Galthen's ritual notes. Tell Kesar the Younger what you found out.",
		[5] = "Kesar the Younger granted you access to the Bounacean Lion. Find the soup kettle deep in the Forest of Life and prepare the soup: 20 carnisylvan fingers, 10 carnisylvan barks and 2 human teeth.",
		[6] = "The soup is ready. Walk to the Sleeping Carnisylvans to reach Megasylvan Yselda. Say the ritual words DEMIHBOULDR, SOMMBHA and WITHER and keep her four saplings alive.",
		[7] = "You defeated Megasylvan Yselda. Report to Kesar the Younger.",
		[8] = "Kesar the Younger made you a royal advisor." .. (G.get(player, "Tulip") == 1 and " Bring his violet tulip to Yselda after freeing her again with her saplings alive." or "") .. (G.get(player, "JohnPermission") >= 1 and G.get(player, "JohnAddon") < 1 and " Visit John, the carpenter, at night." or ""),
		[9] = "You brought Kesar's tulip to Yselda." .. (G.get(player, "JohnPermission") >= 1 and G.get(player, "JohnAddon") < 1 and " Visit John, the carpenter, at night." or ""),
	}
	return texts[state] or ""
end

-- Greeting helpers for the new NPC files
function G.leshGreetingFor(player)
	return G.leshGreeting()
end

function G.alphonseGreeting(player)
	return "Welcome, customer! Enjoy a hot meal, fine cheese or a glass of wine!"
end

function G.yseldaSay(npc, creature, player, message, npcHandler)
	return false
end
