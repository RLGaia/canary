-- Gaia Family server: The Order of the Lion Quest (2026-11-09).
-- Ours, not upstream: Canary v3.6.1 has Bounac, its monsters, the boat, the
-- elevator and the Drume battle lever, but none of the quest's NPCs, no quest
-- log, no Fugue and no reward. Sources: TibiaWiki BR quest page (Rodrigo's
-- HTML, 2026-11-09) first, TibiaWiki EN spoiler and transcripts to complement
-- (Kesar's waits, the Falcon/Cobra check, Wes' and Jehan's lines). Lines
-- marked "ours" are not from the wikis.
--
-- QuestLine (Storage.Quest.U12_40.TheOrderOfTheLion.QuestLine):
--   1 Evrard the Miller (day): get the ledger and the map from the usurpers'
--     camp in the east (the east door opens: AccessEastSide)
--   2 Evrard (`news`): passphrase YSELDA, the south door opens
--     (AccessSouthernSide); earn the trust of Dal, Fral, Jehan, Onfroi, Wes
--   3 all five trust you                        -> the Bounac Guard (`pass`)
--   4 inside the castle                         -> Kesar the Younger (day, `siege`)
--   5 Kesar: "wait" (10 minutes, EN; asking earlier starts the wait again)
--   6 Kesar's plan: after one Tibian day (1 hour), at night, Fugue comes to
--     the throne room when a player of this step is there
--   7 Fugue defeated                            -> Kesar (day); needs the
--     Order of the Falcon and the Order of the Cobra done (EN)
--   8 Kesar: "escort me" after the skirmishes settle (5 minutes, ours; BR
--     "alguns minutos")
--   9 the meeting with Drume watched            -> Kesar
--  10 Kesar: battle at the eastern coast (the Drume lever opens)
--  11 Drume defeated                            -> Kesar
--  12 Hero of Bounac (title, Lionheart, Bounac trade, the sealed doors)
-- Extra: Fitzmaurice (night, prison) `wine` -> Fitzgerald (Cobra Bastion pool)
-- -> Fitzwilliam's Special Reserve -> Fitzmaurice: achievement Malefitz.
-- Switch: Family.orderOfTheLion (false = the new NPCs say nothing about it and
-- the Drume lever, the elevator and Augustin work as upstream).

Family = Family or {}
Family.orderOfTheLion = true

FamilyLion = {}
local L = FamilyLion
local Q = Storage.Quest.U12_40.TheOrderOfTheLion
L.heroStorage = Storage.Quest.FamilyOrderOfTheLion.Hero

L.kesarWait = 10 * 60 -- EN: "wait at least 10 minutes" (BR says one Tibian day)
L.fugueWait = 60 * 60 -- one Tibian day (BR and EN)
L.escortWait = 5 * 60 -- ours (BR: "alguns minutos")
L.heroTitle = 89 -- "Hero of Bounac" in the server's title list

L.items = {
	ham = 3582,
	bread = 3600,
	longbow = 34161,
	ledger = 635, -- a parchment with the usurpers' list of goods
	map = 2822,
	wine = 34209, -- Fitzwilliam's Special Reserve
}

-- Throne room (floor +5) where Fugue comes at night
L.throneRoom = { from = Position(32364, 32475, 2), to = Position(32381, 32481, 2) }
L.fugueSpot = Position(32372, 32478, 2)

-- The meeting: the player watches from the small room east of Bounac (BR 32447,32493,7); Kesar and
-- Drume talk in the room with the desk just north of it (BR screenshots Mensagem 01-08)
L.meetingRoom = Position(32447, 32493, 7)
L.meetingKesar = Position(32448, 32490, 7)
L.meetingDrume = Position(32446, 32490, 7)

L.castleInside = Position(32398, 32481, 4) -- behind the gate at the Bounac Guard

-- the five residents, in the quest log order of the BR screenshot
L.trust = {
	{ key = "dal", label = "Huntress" },
	{ key = "jehan", label = "Baker" },
	{ key = "onfroi", label = "Wizard" },
	{ key = "wes", label = "Blacksmith" },
	{ key = "fral", label = "Butcher" },
}

-- Player KV ----------------------------------------------------------------

local function kv(player)
	return player:kv():scoped("family-lion")
end

function L.get(player, key)
	return tonumber(kv(player):get(key)) or 0
end

function L.set(player, key, value)
	kv(player):set(key, value)
end

function L.state(player)
	return math.max(0, player:getStorageValue(Q.QuestLine))
end

function L.setState(player, value)
	player:setStorageValue(Q.QuestLine, value)
end

function L.isNight()
	return getTibiaTimerDayOrNight and getTibiaTimerDayOrNight() == "night"
end

function L.isHero(player)
	return player:getStorageValue(L.heroStorage) == 1
end

function L.inThroneRoom(pos)
	local a, b = L.throneRoom.from, L.throneRoom.to
	return pos.z == a.z and pos.x >= a.x and pos.x <= b.x and pos.y >= a.y and pos.y <= b.y
end

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
end

local function trustCount(player)
	local n = 0
	for _, t in ipairs(L.trust) do
		if L.get(player, "task_" .. t.key) == 2 then
			n = n + 1
		end
	end
	return n
end
L.trustCount = trustCount

local function earnTrust(player, key)
	L.set(player, "task_" .. key, 2)
	if L.state(player) == 2 and trustCount(player) >= #L.trust then
		L.setState(player, 3)
	else
		-- the quest tracker refreshes only on the mission storage: write it again
		L.setState(player, L.state(player))
	end
end

-- The Falcon and Cobra orders (EN: Kesar checks them after Fugue)
function L.otherOrdersDone(player)
	local falcon = player:getStorageValue(Storage.Quest.U11_80.TheSecretLibrary.FalconBastion.Questline) >= 2
	local cobra = player:getStorageValue(Storage.Quest.U12_20.GraveDanger.Cobra) >= 2
	return falcon and cobra
end

-- Quest log --------------------------------------------------------------------

function L.describe(player)
	local state = L.state(player)
	if state == 1 then
		local got = {}
		if L.get(player, "ledger") == 1 then
			got[#got + 1] = "the ledger"
		end
		if L.get(player, "map") == 1 then
			got[#got + 1] = "the map"
		end
		return "Evrard the Miller wants a ledger and a map from the camp of the usurpers east of his mill. The ledger is in a warehouse at the harbour; the map must be where they keep their boat. Be quiet!" -- ours
			.. (#got > 0 and ("\n\nFound: " .. table.concat(got, " and ") .. ".") or "")
	elseif state == 2 or state == 3 then
		-- BR screenshot of the quest log
		local lines = { "To help break the siege you need to earn the trust of the locals and reach their ruler Kesar.", "", "Miller 1/1" }
		for _, t in ipairs(L.trust) do
			lines[#lines + 1] = string.format("%s %d/1", t.label, L.get(player, "task_" .. t.key) == 2 and 1 or 0)
		end
		if state == 3 then
			lines[#lines + 1] = ""
			lines[#lines + 1] = "The locals trust you now. Ask the Bounac Guard at the castle gate to let you pass." -- ours
		end
		return table.concat(lines, "\n")
	elseif state == 4 or state == 5 then
		return "You are inside the castle of Bounac. Talk to Kesar the Younger in the throne room about the siege. He holds court only during the day." -- ours
	elseif state == 6 then
		return "Kesar the Younger told you his plan: Fugue, Drume or both will appear in the throne room soon. Be there at night and defend yourself." -- ours
	elseif state == 7 then
		return "You defeated Fugue in the throne room. Report to Kesar the Younger during the day." -- ours
	elseif state == 8 then
		return "Kesar the Younger wants you to escort him to a meeting with Drume as soon as the skirmishes along the coast have settled. Ask him again about the siege." -- ours
	elseif state == 9 then
		return "The meeting with Drume failed. Talk to Kesar the Younger about the siege." -- ours
	elseif state == 10 then
		return "Drume wants war. Meet Kesar the Younger and his men on the battlefield near the eastern coast of Bounac and defeat Drume." -- ours
	elseif state == 11 then
		return "Drume's forces lie broken on the battlefield. Report to Kesar the Younger." -- ours
	elseif state >= 12 then
		return "You broke the siege of Bounac and Kesar the Younger named you 'Hero of Bounac'. You may roam Bounac as you please and trade with its people." -- ours
	end
	return ""
end

-- Dialogue ---------------------------------------------------------------------

local TOPIC_EVRARD_HELP = 401
local TOPIC_EVRARD_QUIET = 402
local TOPIC_EVRARD_STUFF = 403
local TOPIC_EVRARD_QUIET2 = 404
local TOPIC_HAND = 405
local TOPIC_PASS = 406
local TOPIC_PLAN = 407
local TOPIC_ESCORT = 408

local dialogue = {}
L.greetings = {}

-- Evrard the Miller (TibiaWiki BR/EN transcripts)
L.greetings.evrard = function(player)
	if L.state(player) == 0 then
		return "Greetings. Can I help you, traveller?"
	end
	return "Ah it's you, any {news}? If you just want to use the mill, you can do so, too."
end

dialogue.evrard = function(npc, creature, player, message, npcHandler)
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	local state = L.state(player)
	if topic == TOPIC_EVRARD_QUIET then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			say(npcHandler, npc, creature, "Good, now go. Remember: be like a light summer breeze - quick, almost unnoticeable and most importantly QUIET!")
			L.setState(player, 1)
			player:setStorageValue(Q.AccessEastSide, 1)
		else
			say(npcHandler, npc, creature, "Then listen more carefully next time. Come back if you want to help me.") -- ours
		end
		return true
	elseif topic == TOPIC_EVRARD_STUFF then
		npcHandler:setTopic(id, 0)
		if not MsgContains(message, "yes") then
			say(npcHandler, npc, creature, "Then don't waste my time. The ledger is in a warehouse at the harbour, and they must keep their map somewhere near.") -- ours
			return true
		end
		if L.get(player, "ledger") ~= 1 or L.get(player, "map") ~= 1 then
			say(npcHandler, npc, creature, "You don't have both of them. I want the ledger AND the map!") -- ours
			return true
		end
		say(npcHandler, npc, creature, {
			"You did it! Let me just take a peek... ...",
			"What? No, no - keep them. I uhm, don't want to have anything to do with this. Just wanted to... take a quick look, you know. ...",
			"Have you been quiet as I asked you?",
		})
		npcHandler:setTopic(id, TOPIC_EVRARD_QUIET2)
		return true
	elseif topic == TOPIC_EVRARD_QUIET2 then
		npcHandler:setTopic(id, 0)
		local lines = {
			"Oh you have? Why did I hear screams of battle, fear and loathing from over there about the time you were gone? ...",
			"And I really hope yours were the screams of battle and not those of fear. ...",
			"Anyway, you did it and that's very good. I am thankful for that and I'll open up an underground route I sometimes use when I want to enter the city quickly. ...",
			"This way you can get past any guards and find out more about the situation. And one more thing: ...",
			"There's a passphrase: YSELDA. Remember that. Now go and the best of luck to you, traveller!",
		}
		if not MsgContains(message, "yes") then
			lines[1] = "Well, at least you are honest. I heard the screams of battle, fear and loathing from over there. ..." -- ours
		end
		say(npcHandler, npc, creature, lines)
		L.setState(player, 2)
		player:setStorageValue(Q.AccessSouthernSide, 1)
		return true
	end

	if state == 0 and MsgContains(message, "yes") then
		say(npcHandler, npc, creature, {
			"Alright, look. You already know that camp to the east, with the bad guys roaming around, right? Great. ...",
			"They have a ledger and a map there, and I want that. Both these items. The ledger is in a warehouse at the harbour. ...",
			"I don't know where that map is, though but I am sure they have one where they've marked all the locations they've been at. ...",
			"And most importantly: BE QUIET! Try not to be seen. Be a shadow. Got that?",
		})
		npcHandler:setTopic(id, TOPIC_EVRARD_QUIET)
		return true
	elseif MsgContains(message, "news") then
		if state == 1 then
			say(npcHandler, npc, creature, "What about the small errand I mentioned? Did you get the stuff?")
			npcHandler:setTopic(id, TOPIC_EVRARD_STUFF)
		elseif state >= 2 then
			say(npcHandler, npc, creature, "Remember the passphrase: YSELDA. The people in the south of the town will know what to do.") -- ours
		else
			say(npcHandler, npc, creature, "News? There's a siege going on, that's the news.") -- ours
		end
		return true
	elseif MsgContains(message, "mill") then
		say(npcHandler, npc, creature, "Go ahead and use the mill, if you have some wheat.") -- ours
		return true
	end
	return false
end

-- The five residents: YSELDA ------------------------------------------------------

local INTRO = {
	"Well, for quite some time we are planning to help our king during this awful siege. As you know the passphrase, one of us already trusts you. ...",
	"Outsiders are not welcome here during the siege. If you want to get into the castle, you will have to earn all our trust. ...",
	"If you can do that, a member of the lion guard who is in contact with us, will let you in. ...",
	"Just ask any of us the passphrase and we will see what we can do for you.",
}

L.tasks = {
	dal = {
		kills = "deer",
		count = 20,
		introLine = "So, you know the passphrase... You came to the right place, I guess. ...", -- ours (BR/EN have only Fral's and Wes' first line)
		task = {
			"So, you truly want to prove your worth to us... well, I'd like to ask for a favour then. ...",
			"There are plenty of deer in the woods of Bounac. However, with the siege going on and the strict regulations, I can't hunt. ...",
			"Hunt 20 deer for me to protect our forest and keep our hunting grounds in good order.",
		},
		done = "Impressive, for a semi-professional! You helped Bounac and me a great deal. You have my trust, traveller.",
		notYet = "You have hunted %d of the 20 deer so far. The woods of Bounac are full of them.", -- ours
	},
	fral = {
		item = L.items.ham,
		count = 20,
		introLine = "Oh, yes uhm. You came to the right place, I guess. ...",
		task = "If you want to prove trustworthy to me, I need you to bring me some raw ham, about 20 chunks if you can. Then we'll see.",
		offer = { "Good, I can smell about 20 pieces of raw ham there in your pockets. ...", "Will you hand those over to me?" },
		done = "Great, thanks. And? Oh, yes. Consider my trust... earned.",
		notYet = "I can't smell 20 pieces of raw ham on you. Bring me about 20 chunks.", -- ours
	},
	jehan = {
		item = L.items.bread,
		count = 10,
		introLine = "Oh, yes, the passphrase! You came to the right place, I guess. ...", -- ours
		task = "To prove trustworthy to me... hm, well, you could... oh, yes! Of course, we have a severe shortage of bread! If I knew someone who could organise about ten loafs of bread, I'd be saved for today!",
		offer = "Ten loafs of bread! Colour me impressed. Will you hand those over to me?",
		done = "Thanks, you saved my day and most certainly earned my trust!",
		notYet = "Ten loafs of bread, that's all I ask. Come back when you have them.", -- ours
	},
	onfroi = {
		kills = "crypt",
		count = 20,
		introLine = "Hm? The passphrase... well then. You came to the right place, I guess. ...", -- ours
		task = {
			"You mean it, right? Where did you got that from, actually?. ...",
			"Now, I have indeed a favour to ask. If you can accomplish that, you've earned my trust surely. ...",
			"There is a crypt down below the town. It is old and seismic activity has stirred up some bad energies down there. ...",
			"I want you to venture exactly to that crypt and see if there are any powerful creatures down there. ...",
			"And if there are... please... remove them. Rest assured that I have nothing to do with the rise of any mortally-depleted entities down there ...",
			"At least not this time. You see, the locals are starting to suspect me. But I'm not much of a fighter or warlock. ...",
			"So if there is indeed something below us and you can destroy let's say 20 of it, I'd be in your debt.",
		},
		done = "You did it, excellent! Most respectable, you did great! That took a load of my mind. And you've earned my trust!",
		notYet = "You destroyed %d of the 20 crypt warriors so far. Please go on, before the locals blame me.", -- ours
	},
	wes = {
		item = L.items.longbow,
		count = 20,
		introLine = "Ah yes, right. You came to the right place, ahem. ...",
		task = {
			"Alright then, let's see if you are really trustworthy. I need more material to forge better equipment for our men. ...",
			"Bring me about 20 broken longbows from fallen usurpers and we will see.",
		},
		offer = {
			"Alright then, let's see if you are really trustworthy. You have about 20 broken longbows there, this is exactly what I need to fulfill my next order from the king. ...",
			"Are you willing to hand them over to me?",
		},
		done = "Excellent, just what I needed. You have earned my trust, traveller. Good luck!",
		notYet = "Bring me about 20 broken longbows from fallen usurpers. The usurper archers carry them.", -- ours
	},
}

local function yselda(who, npc, creature, player, npcHandler)
	local t = L.tasks[who]
	local key = "task_" .. who
	local state = L.state(player)
	if state < 2 then
		say(npcHandler, npc, creature, "Yselda? I don't know what you are talking about.") -- ours
		return
	end
	local value = L.get(player, key)
	if value == 2 or state >= 3 then
		say(npcHandler, npc, creature, "You already have my trust, traveller.") -- ours
		return
	end
	if L.get(player, "intro") == 0 then
		local lines = { t.introLine }
		for _, l in ipairs(INTRO) do
			lines[#lines + 1] = l
		end
		say(npcHandler, npc, creature, lines)
		L.set(player, "intro", 1)
		return
	end
	if value == 0 then
		say(npcHandler, npc, creature, t.task)
		L.set(player, key, 1)
		if t.kills then
			L.set(player, t.kills, 0)
		end
		return
	end
	if t.kills then
		local n = L.get(player, t.kills)
		if n >= t.count then
			say(npcHandler, npc, creature, t.done)
			earnTrust(player, who)
		else
			say(npcHandler, npc, creature, string.format(t.notYet, n))
		end
	elseif player:getItemCount(t.item) >= t.count then
		say(npcHandler, npc, creature, t.offer)
		npcHandler:setTopic(player:getId(), TOPIC_HAND)
	else
		say(npcHandler, npc, creature, t.notYet)
	end
end

local function resident(who)
	return function(npc, creature, player, message, npcHandler)
		local id = player:getId()
		if npcHandler:getTopic(id) == TOPIC_HAND then
			npcHandler:setTopic(id, 0)
			local t = L.tasks[who]
			if MsgContains(message, "yes") then
				if L.get(player, "task_" .. who) == 1 and player:getItemCount(t.item) >= t.count and player:removeItem(t.item, t.count) then
					say(npcHandler, npc, creature, t.done)
					earnTrust(player, who)
				else
					say(npcHandler, npc, creature, t.notYet)
				end
			else
				say(npcHandler, npc, creature, "Then come back when you have made up your mind.") -- ours
			end
			return true
		end
		if MsgContains(message, "yselda") then
			yselda(who, npc, creature, player, npcHandler)
			return true
		end
		return false
	end
end
for _, t in ipairs(L.trust) do
	dialogue[t.key] = resident(t.key)
end

L.greetings.dal = function()
	return "Good day, traveller! I am out of stock currently. Since I have my hands full with hunting, I can't prepare any animals."
end
L.greetings.fral = function()
	return "Hello, customer! I got meat."
end
L.greetings.jehan = function()
	if L.isNight() then
		return "Welcome to the Bread & Butter! Do you... hey, it's already closing time. This is my home!"
	end
	return "Welcome to the Bread & Butter! Do you want to buy pastries or butter? Because we're all out of bread."
end
L.greetings.onfroi = function()
	return "Welcome, traveller! Is it tea you're looking... oh, is it still morning? Anyway, browse my stock now."
end
L.greetings.wes = function()
	return "Hail, customer! Welcome to Wes and son, blacksmith (and teacher). Can I do something for you?"
end

-- Bounac Guard ---------------------------------------------------------------------

L.greetings.guard = function()
	return "YOU CANNOT PASS, TRAVELLER. THE CASTLE OF BOUNAC IS UNDER SIEGE."
end

local function letIn(player)
	player:getPosition():sendMagicEffect(CONST_ME_POFF)
	player:teleportTo(L.castleInside)
	L.castleInside:sendMagicEffect(CONST_ME_TELEPORT)
end
L.letIn = letIn

dialogue.guard = function(npc, creature, player, message, npcHandler)
	local id = player:getId()
	if npcHandler:getTopic(id) == TOPIC_PASS then
		npcHandler:setTopic(id, 0)
		if not MsgContains(message, "yes") then
			say(npcHandler, npc, creature, "THEN STAY OUT, TRAVELLER!") -- ours
			return true
		end
		local state = L.state(player)
		if state < 3 then
			say(npcHandler, npc, creature, "NOBODY PASSES WITHOUT THE TRUST OF THE PEOPLE OF BOUNAC!") -- ours
			return true
		end
		say(npcHandler, npc, creature, {
			"ALRIGHT ALRIGHT, LOWER YOUR VOICE STRANGER, I'M NOT DEAF! ...",
			"Alright, traveller, I've already heard of you. You can enter the castle. Good luck!",
		})
		if state == 3 then
			L.setState(player, 4)
		end
		addEvent(function(pid)
			local p = Player(pid)
			if p then
				L.letIn(p)
			end
		end, 4000, id)
		return true
	end
	if MsgContains(message, "pass") then
		say(npcHandler, npc, creature, "YOU WANT PASSAGE, TRAVELLER?")
		npcHandler:setTopic(id, TOPIC_PASS)
		return true
	end
	return false
end

-- Kesar the Younger ---------------------------------------------------------------

L.greetings.kesar = function()
	return "Hail, traveller. What brings you here during these dire times under siege? The fair Bounac is suffering greatly."
end

local KESAR_WAIT = {
	"You will have to wait until I have time to take care of your request. In the meantime, take a seat. ...",
	"Usually they're reserved for my council but they never seem to sit down... and somehow I doubt you will, either.",
}

local KESAR_FUGUE = {
	"Fugue... he attacked right away and had to be punished. You did the right thing. However, this will probably mean all out war if Drume does not come to his senses. ...",
	"I will have to arrange a meeting with him immediately to prevent the worst from happening. There is still another way. ...",
	"Will you escort me to the camp of the usurpers?",
}

local KESAR_SKIRMISH = {
	"Good, however, we have to wait until the recent skirmishes along the coast have settled down. ...",
	"We will venture down to the battlefield as soon as the other fights have died down.",
}

dialogue.kesar = function(npc, creature, player, message, npcHandler)
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	local state = L.state(player)
	local now = os.time()
	if topic == TOPIC_PLAN then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") and state == 5 then
			say(npcHandler, npc, creature, {
				"Excellent. Here is my plan. Either Fugue, Drume or both will appear here soon. If they try anything funny - defend yourself. ...",
				"If we can get them both at the right moment, they're done for. They will pay for what they have done. ...",
				"However, if only one of them appears and one of them is left... well, we shall not think of that now.",
			})
			L.setState(player, 6)
			L.set(player, "fugueAfter", now + L.fugueWait)
		else
			say(npcHandler, npc, creature, "Think it over. Bounac needs every sword it can get.") -- ours
		end
		return true
	elseif topic == TOPIC_ESCORT then
		npcHandler:setTopic(id, 0)
		if not MsgContains(message, "yes") then
			say(npcHandler, npc, creature, "I understand. But time is running out for Bounac.") -- ours
			return true
		end
		if state == 7 then
			say(npcHandler, npc, creature, KESAR_SKIRMISH)
			L.setState(player, 8)
			L.set(player, "escortAfter", now + L.escortWait)
		elseif state == 8 then
			if now < L.get(player, "escortAfter") then
				say(npcHandler, npc, creature, KESAR_SKIRMISH)
			else
				say(npcHandler, npc, creature, "Alright, let us go then. And thank you.")
						addEvent(function(pid)
					local p = Player(pid)
					if p and FamilyLion.startMeeting then
						FamilyLion.startMeeting(p)
					end
				end, 3000, id)
			end
		end
		return true
	end

	if not MsgContains(message, "siege") then
		return false
	end
	if L.isNight() then
		say(npcHandler, npc, creature, "It is late, traveller. Come to the throne room in the morning, then we shall talk about the siege.") -- ours
		return true
	end
	if state < 4 then
		say(npcHandler, npc, creature, "How did you get in here? Guards!") -- ours
	elseif state == 4 then
		say(npcHandler, npc, creature, KESAR_WAIT)
		L.setState(player, 5)
		L.set(player, "kesarWait", now + L.kesarWait)
	elseif state == 5 then
		if now < L.get(player, "kesarWait") then
			-- EN: asking before the time is up starts the wait again
			say(npcHandler, npc, creature, KESAR_WAIT)
			L.set(player, "kesarWait", now + L.kesarWait)
		else
			say(npcHandler, npc, creature, {
				"So, I trust you're not here to join the usurpers besieging our humble enclave. Otherwise my men would've surely put you in your place before you even passed the gate. ...",
				"Sources are telling me that you helped our small community quite a bit. And you seem to know your way around the usurpers. ...",
				"I will trust you, as I trust my men who already put faith in you. What do you say, are you interested in a plan?",
			})
			npcHandler:setTopic(id, TOPIC_PLAN)
		end
	elseif state == 6 then
		say(npcHandler, npc, creature, "Be patient. Either Fugue, Drume or both will appear here soon. If they try anything funny - defend yourself.") -- ours (from his plan)
	elseif state == 7 then
		if not L.otherOrdersDone(player) then
			say(npcHandler, npc, creature, {
				"Last night I had an idea. It came to my mind that we must not stand alone against this onslaught. There are other knights. Other orders who may sympathise with our cause ...",
				"As you might already know, I am a direct descendant of Kesar, leader of the knightly order of the Lion. ...",
				"He was one of three knights who once served King Xenom and left Edron in search of a greater purpose. ...",
				"Travel to the city of Edron and find out what you can about the order of the Falcon. ...",
				"And there is another order, I am not quite sure of its name but they travelled far south of Edron, into the desert.",
			})
		else
			say(npcHandler, npc, creature, KESAR_FUGUE)
			npcHandler:setTopic(id, TOPIC_ESCORT)
		end
	elseif state == 8 then
		say(npcHandler, npc, creature, "Will you escort me to the camp of the usurpers?")
		npcHandler:setTopic(id, TOPIC_ESCORT)
	elseif state == 9 then
		say(npcHandler, npc, creature, {
			"What news from the orders of the Falcon and the other successor order? ...",
			"The Order of the Cobra you say? Both destroyed...? The flame of virtue, the power of righteousness - diminished? In all of them? Oh... ...",
			"Far too long have I stayed silent and idle. Drume wants war. We will meet him in battle near the eastern coast of Bounac. ...",
			"Prepare yourself and I will see you on the battlefield. Good luck, my friend.",
		})
		L.setState(player, 10)
	elseif state == 10 then
		say(npcHandler, npc, creature, "Drume awaits us on the battlefield near the eastern coast of Bounac. Prepare yourself, my friend.") -- ours
	elseif state == 11 then
		say(npcHandler, npc, creature, {
			"It is done. Drume's forces lie broken on the battlefield. You witnessed the fall of a great enemy of the Order of the Lion. ...",
			"You stood tall against the enemy forces and helped our cause wherever you could. ...",
			"I will therefore announce you the 'Hero of Bounac'. You are honourable citizen of this town now. ...",
			"Feel free to roam Bounac as you please. This also means certain benefits when trading with our court trader Augustin. ...",
			"Whenever you're here for a visit, the large house to the south of Bounac is now completely at your disposal. ...",
			"And if we can persuade you into a longer stay perhaps, there is a small house further to the south of the island which may pique your interest. ...",
			"Thank you for your service to Bounac, Hero.",
		})
		L.makeHero(player)
	else
		say(npcHandler, npc, creature, "Bounac is free again, thanks to you, Hero.") -- ours
	end
	return true
end

function L.makeHero(player)
	L.setState(player, 12)
	player:setStorageValue(L.heroStorage, 1)
	if player.addAchievement then
		player:addAchievement("Lionheart")
	end
	if player.addTitle then
		player:addTitle(L.heroTitle)
	end
end

-- Fitzmaurice and Fitzgerald (Malefitz) ------------------------------------------

L.greetings.fitzmaurice = function()
	return "Oh, hello there!"
end

dialogue.fitzmaurice = function(npc, creature, player, message, npcHandler)
	if not MsgContains(message, "wine") then
		return false
	end
	if L.get(player, "wine") < 2 and player:getItemCount(L.items.wine) > 0 then
		say(npcHandler, npc, creature, {
			"Hm, nah, I shouldn't really bother you with this. You know... what do you have there? Wine? A Fitzwilliam's Special...? Oh! ...",
			"Now that's what I call WINE, thank you very much! Hope you enjoy your stay in Bounac as much as I do, my friend!",
		})
		player:removeItem(L.items.wine, 1)
		L.set(player, "wine", 2)
		if player.addAchievement then
			player:addAchievement("Malefitz")
		end
	elseif L.get(player, "wine") >= 2 then
		say(npcHandler, npc, creature, "That was the best wine I had in years. Thank you again, my friend!") -- ours
	else
		say(npcHandler, npc, creature, {
			"Hm, nah, I shouldn't really bother you with this. You know, they have some excellent food down here but the wine... ...",
			"It sure tastes like the real thing but they seem to stretch it with water. ...",
			"Now I don't know if this is just for us prisoners down here or if it's because of the siege but I'd really like to taste some good wine. ...",
			"Don't know if you ever met my brothers but one of them, Fitzwilliam, is a keen gourmet of wine and used to have a vineyard estate.",
		})
		L.set(player, "wine", 1)
	end
	return true
end

L.greetings.fitzgerald = function()
	return "Ahh, the water is just right. Hello there!" -- ours
end

dialogue.fitzgerald = function(npc, creature, player, message, npcHandler)
	if not (MsgContains(message, "wine") or MsgContains(message, "fitzmaurice") or MsgContains(message, "fitzwilliam")) then
		return false
	end
	if L.get(player, "wine") == 1 and player:getItemCount(L.items.wine) == 0 then
		say(npcHandler, npc, creature, {
			"Fitzmaurice? A prisoner in Bounac, complaining about watered wine? Ha, that's my brother alright. ...",
			"Here, take this bottle from Fitzwilliam's own cellar. I was saving it for a special occasion, but family is family.",
		}) -- ours
		player:addItem(L.items.wine, 1)
	else
		say(npcHandler, npc, creature, "My brother Fitzwilliam makes the finest wine in all of Tibia. Not that anybody ever asks me about it.") -- ours
	end
	return true
end

-- Trade: the Bounac merchants trade only with the Hero of Bounac (BR/EN) ------------

function L.canTrade(player)
	return not Family.orderOfTheLion or L.isHero(player)
end

function L.tradeRefused(npc, creature, npcHandler)
	say(npcHandler, npc, creature, "I am sorry, traveller. While the siege lasts I only trade with the citizens of Bounac.") -- ours
end

-- Called from the NPCs' default message callback. Returns true when handled.
function L.onSay(who, npc, creature, player, message, npcHandler)
	if not Family.orderOfTheLion or not dialogue[who] then
		return false
	end
	return dialogue[who](npc, creature, player, message, npcHandler) == true
end

-- Greeting text for this player (nil = the NPC's own greeting)
function L.greeting(who, player)
	if not Family.orderOfTheLion or not L.greetings[who] then
		return nil
	end
	return L.greetings[who](player)
end
