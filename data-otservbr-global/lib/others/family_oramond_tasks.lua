-- Gaia Family server: Oramond Quest kill and delivery tasks (2026-11-08, asked by Rodrigo after
-- the Oramond review: upstream had 4 of the 20 tasks, so a Citizen rank meant ~150 repeats of them).
--
-- Batch 1 (this file):
--   Terrence (Rathleton guard): Taking the Rot Out (100 Rot Elementals / Glooth Blobs, any rank),
--     The Name of the Beast (100 Blood Beasts, commoner), The Minor Taurs (100 Mooh'Tah Warriors /
--     Minotaur Hunters / Worm Priestesses, commoner), Rust in Peace (100 Rustheap Golems / Metal
--     Gargoyles, inhabitant), The Major Taurs (100 Moohtants / Minotaur Amazons / Execowtioners,
--     citizen). 1 vote each; a report takes one batch of 100, more kills count as 100 (EN).
--   Drystan Wildweed: Nature's Balance (200 Glooth Bandits / Brigands, citizen); 200 are taken
--     off per report (BR), 2 votes (no source gives the number; ours).
--   Elbert: The Glooth Bandits (citizen): 2 votes per 10 glooth capsules (EN). Repeats need Four
--     Demanding Statues in Tibia; that mission is not built yet, so repeats are open.
-- Kills count from the first one once the player has the rank, without talking first (BR), for
-- every party member who shares the kill (onDeathForParty). Sources: TibiaWiki BR Oramond Quest
-- (page from Rodrigo), TibiaWiki EN Oramond Quest/Spoiler (task texts, Drystan's and Elbert's
-- transcripts). No transcript exists for Terrence's kill tasks: his lines are ours, built on the
-- EN task texts.
--
-- Switch: Family.oramondTasks.

Family = Family or {}
Family.oramondTasks = true

FamilyOramondTasks = FamilyOramondTasks or {}
local T = FamilyOramondTasks
local S = Storage.Quest.FamilyOramondTasks
local O = Storage.Quest.U10_50.OramondQuest

T.S = S
T.CAPSULE = 21814

function T.on()
	return Family.oramondTasks == true
end

local function rankOf(player)
	return FamilyRathleton and FamilyRathleton.rank(player) or 0
end

local function rankName(rank)
	return FamilyRathleton and FamilyRathleton.rankName(rank) or "citizen"
end

-- Terrence's hunts in his order; words = what the player may say.
T.hunts = {
	{
		key = "rot",
		name = "Taking the Rot Out",
		storage = S.Rot,
		words = { "rot", "rot elementals", "glooth blobs" },
		creatures = { "Rot Elemental", "Glooth Blob" },
		need = 100,
		minRank = 0,
		votes = 1,
		offer = "Rot elementals and glooth blobs infest every corner of this city, even underground. They clog our pipes and drains. Kill one hundred of them and report back to me.",
		what = "rot elementals or glooth blobs",
		where = "The Rathleton slums are full of them.",
	},
	{
		key = "beast",
		name = "The Name of the Beast",
		storage = S.Beast,
		words = { "blood", "bloodbeast", "bloodbeasts", "blood beast", "blood beasts", "beast" },
		creatures = { "Blood Beast" },
		need = 100,
		minRank = 1,
		votes = 1,
		offer = "Blood beasts are horrible creatures that roam our plains. Kill one hundred of them and report back to me.",
		what = "blood beasts",
		where = "They roam the plains around the city and the Glooth Factory.",
	},
	{
		key = "minor",
		name = "The Minor Taurs",
		storage = S.Minor,
		words = { "minor", "minor taurs" },
		creatures = { "Mooh'Tah Warrior", "Minotaur Hunter", "Worm Priestess" },
		need = 100,
		minRank = 1,
		votes = 1,
		offer = "Minotaurs are a constant threat to this city. Their lairs are south and east of the city. Kill one hundred mooh'tah warriors, minotaur hunters or worm priestesses and report back to me.",
		what = "mooh'tah warriors, minotaur hunters or worm priestesses",
		where = "You find them in the marshes and in the minotaur camp.",
	},
	{
		key = "gargoyles",
		name = "Rust in Peace",
		storage = S.Gargoyles,
		words = { "gargoyles", "gargoyle", "rust", "golems" },
		creatures = { "Rustheap Golem", "Metal Gargoyle" },
		need = 100,
		minRank = 2,
		votes = 1,
		offer = "Rustheap golems and malfunctioning metal gargoyles stalk the streets and molest our citizens. Destroy one hundred of them and report back to me.",
		what = "rustheap golems or metal gargoyles",
		where = "Most of them lurk in the workshops.",
	},
	{
		key = "major",
		name = "The Major Taurs",
		storage = S.Major,
		words = { "major", "major taurs", "dangerous" },
		creatures = { "Moohtant", "Minotaur Amazon", "Execowtioner" },
		need = 100,
		minRank = 3,
		votes = 1,
		offer = "The attacking minotaur hordes include some very dangerous elite troops that we need to eliminate. Kill one hundred moohtants, minotaur amazons or execowtioners and report back to me.",
		what = "moohtants, minotaur amazons or execowtioners",
		where = "The mountain hideout east of the camp is full of them.",
	},
}

T.bandits = {
	key = "bandits",
	name = "Nature's Balance",
	storage = S.Bandits,
	creatures = { "Glooth Bandit", "Glooth Brigand" },
	need = 200,
	minRank = 3,
	votes = 2, -- ours
}

-- creature name -> list of tasks
T.byCreature = {}
local function index(task)
	for _, name in ipairs(task.creatures) do
		T.byCreature[name] = T.byCreature[name] or {}
		table.insert(T.byCreature[name], task)
	end
end
for _, hunt in ipairs(T.hunts) do
	index(hunt)
end
index(T.bandits)

function T.count(player, task)
	return player:getStorageValue(task.storage)
end

local function addVotes(player, amount)
	player:setStorageValue(O.VotingPoints, math.max(0, player:getStorageValue(O.VotingPoints)) + amount)
end

local function openQuestLine(player)
	if player:getStorageValue(O.QuestLine) < 1 then
		player:setStorageValue(O.QuestLine, 1)
	end
end

-- A kill of a task creature (from scripts/family/oramond_tasks.lua).
function T.countKill(player, creatureName)
	if not T.on() then
		return
	end
	if T.combo and T.combo[creatureName] then
		T.comboKill(player, creatureName)
		return
	end
	local tasks = T.byCreature[creatureName]
	if not tasks then
		return
	end
	for _, task in ipairs(tasks) do
		if rankOf(player) >= task.minRank then
			local count = math.max(0, T.count(player, task))
			if count < task.need then
				count = count + 1
				player:setStorageValue(task.storage, count)
				openQuestLine(player)
				if count == task.need then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("%s: you killed %d. Report to %s.", task.name, task.need, task == T.bandits and "Drystan Wildweed" or "Terrence"))
				end
			end
		end
	end
end

function T.missionText(player, task)
	local count = math.max(0, T.count(player, task))
	local who = task == T.bandits and "Drystan Wildweed in the Underground Glooth Factory" or "Terrence at the Rathleton city gate"
	if count >= task.need then
		return string.format("You killed %d %s. Report to %s for your vote.", task.need, task.what or "glooth bandits or brigands", who)
	end
	return string.format("Kill %d %s for %s: %d so far.%s", task.need, task.what or "glooth bandits or brigands", who, count, task.where and (" " .. task.where) or "")
end

-- ------------------------------------------------------------------ Terrence

local function huntList(player)
	local names = {}
	for _, hunt in ipairs(T.hunts) do
		if rankOf(player) >= hunt.minRank then
			names[#names + 1] = "{" .. hunt.words[1] .. "}"
		end
	end
	if #names == 1 then
		return names[1]
	end
	return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

-- Returns true when Terrence answered.
function T.terrenceSay(npc, player, message, npcHandler)
	if not T.on() then
		return false
	end
	local say = function(text)
		npcHandler:say(text, npc, player)
	end
	for _, hunt in ipairs(T.hunts) do
		local matched = false
		for _, word in ipairs(hunt.words) do
			if MsgContains(message, word) then
				matched = true
				break
			end
		end
		if matched then
			if rankOf(player) < hunt.minRank then
				say("Only those who hold the citizen rank of " .. rankName(hunt.minRank) .. " in Rathleton may join this hunt. Ask Marvin in the magistrate about your status.")
				return true
			end
			local count = T.count(player, hunt)
			if count >= hunt.need then
				player:setStorageValue(hunt.storage, 0)
				addVotes(player, hunt.votes)
				say("One hundred! Fine work. That's one more voice in the magistrate of Rathleton for you. The hunt goes on, of course - the counting starts again.")
			elseif count >= 0 then
				say(string.format("You killed %d of the %d %s so far. %s", count, hunt.need, hunt.what, hunt.where))
			else
				player:setStorageValue(hunt.storage, 0)
				openQuestLine(player)
				say(hunt.offer)
			end
			return true
		end
	end
	if MsgContains(message, "killing") or MsgContains(message, "helping") or MsgContains(message, "help") or MsgContains(message, "mission") or MsgContains(message, "hunt") then
		say("The city guard pays for every hundred pests you kill with a voice in the magistrate. Right now you can help with " .. huntList(player) .. ". The minotaurs' {supplies} and a bit of {sabotage} would help too.")
		return true
	end
	return false
end

-- ------------------------------------------------------------------ Drystan Wildweed

function T.setupDrystan(npcHandler)
	local B = T.bandits
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
		local player = Player(creature)
		if T.on() and rankOf(player) >= B.minRank and T.count(player, B) >= B.need then
			npcHandler:setMessage(MESSAGE_GREET, "Greetings. Have you eliminated the glooth bandits?")
		else
			npcHandler:setMessage(MESSAGE_GREET, "I still have trouble with those annoying {thieves} - despite them having significantly weakened after your recent endeavours, though.")
		end
		return true
	end)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		local playerId = player:getId()
		if not T.on() then
			return true
		end
		local topic = npcHandler:getTopic(playerId)
		-- the greeting asks when the kills are done (setInteraction resets the topic after a greeting)
		local ready = rankOf(player) >= B.minRank and T.count(player, B) >= B.need
		if topic == 0 and ready and (MsgContains(message, "yes") or MsgContains(message, "no")) then
			topic = 2
		end
		if topic == 2 and MsgContains(message, "yes") then
			npcHandler:setTopic(playerId, 0)
			if T.count(player, B) >= B.need then
				player:setStorageValue(B.storage, T.count(player, B) - B.need)
				addVotes(player, B.votes)
				npcHandler:say("Great! You rendered a favour to nature and the city of Rathleton alike. This will get you a certain voice in the city.", npc, creature)
			end
		elseif topic == 2 and MsgContains(message, "no") then
			npcHandler:setTopic(playerId, 0)
			npcHandler:say("Then go on, the caves still suffer from them.", npc, creature) -- ours
		elseif topic == 1 and MsgContains(message, "yes") then
			npcHandler:setTopic(playerId, 0)
			if T.count(player, B) < 0 then
				player:setStorageValue(B.storage, 0)
			end
			openQuestLine(player)
			npcHandler:say("I knew you would be willing to help nature. Weed out two hundred of them. That should bring some relief for these caves.", npc, creature)
		elseif topic == 1 and MsgContains(message, "no") then
			npcHandler:setTopic(playerId, 0)
			npcHandler:say("A pity. Nature will remember those who help her.", npc, creature) -- ours
		elseif MsgContains(message, "thieves") or MsgContains(message, "mission") or MsgContains(message, "bandits") then
			if rankOf(player) < B.minRank then
				npcHandler:say("I only trust citizens of Rathleton with this. Come back when the magistrate counts you among them.", npc, creature) -- ours
				return true
			end
			local count = T.count(player, B)
			if count >= B.need then
				npcHandler:say("Have you eliminated the glooth bandits?", npc, creature)
				npcHandler:setTopic(playerId, 2)
			elseif count >= 0 then
				npcHandler:say(string.format("You weeded out %d of the two hundred so far. Keep going.", count), npc, creature) -- ours
			else
				npcHandler:say("Some utterly annoying rascals rove about in these tunnels. They are stealing glooth based weaponry and devastate the flora and fauna down here. They threaten the natural balance. Would you go and eliminate some for me?", npc, creature)
				npcHandler:setTopic(playerId, 1)
			end
		end
		return true
	end)
end

-- ------------------------------------------------------------------ Elbert
-- Capsules (batch 1) and, since batch 3, Four Demanding Statues and the glass tube for the
-- Mutated Glooth Plague. Repeated capsule deliveries need Four Demanding Statues done (EN).

local function elbertState(player)
	return player:getStorageValue(S.Capsules), player:getStorageValue(S.Statues)
end

local elbertLines = {
	{ "job", "I oversee the {glooth} pumping stations down here. Formerly I was the laboratory assistant to {Georgia Rainbird}, but her research work ... how might I phrase it? It is in abeyance at the moment." },
	{ "glooth", "This is a slimy substance which is produced by the glooth worms. It was a driving force for the progress in Rathleton. A substance that has great potential but also carries some {risks}." },
	{ "risks", "Yes, in these caves it seems to change in a strange way. This mutation has negative side effects. Ask {Georgia Rainbird}, she can tell you more." },
	{ "georgia", "She is a very gifted scientist, researching the potential but also the {risks} of the {glooth}. Unfortunately she recently had an accident and received a severe injury that interferes with her work." },
}

function T.setupElbert(npcHandler)
	local C = S.Capsules
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
		local player = Player(creature)
		local capsules, statues = elbertState(player)
		if T.on() and statues == 3 then
			player:setStorageValue(S.Statues, 4)
			addVotes(player, 4) -- EN: 4 voting points
			npcHandler:setMessage(MESSAGE_GREET, "That is most interesting news! Thank you for your efforts and risk-taking. Sure, if this ominous Circle of the Black Sphinx is behind all that, a successor for this warlock might appear. But at least for now the danger is averted. And if you find some more glooth capsules, bring them back to me, please.")
		elseif T.on() and capsules == 1 then
			npcHandler:setMessage(MESSAGE_GREET, "Ah, there you are! Do you bring back the stolen glooth supply capsules?")
		elseif T.on() and capsules >= 2 and statues < 1 then
			npcHandler:setMessage(MESSAGE_GREET, "I don't believe that these thieves act on their own behalf. There must be someone behind this gang. I want you to find this person. Would you help me?")
		elseif T.on() and statues >= 1 and statues <= 2 then
			npcHandler:setMessage(MESSAGE_GREET, "Greetings. Have you found out whether there is someone behind the glooth bandits - and if so, who?")
		elseif T.on() and capsules >= 2 then
			npcHandler:setMessage(MESSAGE_GREET, "Ah, there you are! Do you bring back more stolen glooth supply capsules?")
		else
			npcHandler:setMessage(MESSAGE_GREET, "Greetings. Excuse me but I don't have the time for useless conversation. I have a lot of work and unfortunately also some {trouble} here.")
		end
		return true
	end)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		local playerId = player:getId()
		if not T.on() then
			return true
		end
		local say = function(text)
			npcHandler:say(text, npc, creature)
		end
		local topic = npcHandler:getTopic(playerId)
		local capsules, statues = elbertState(player)
		local yes, no = MsgContains(message, "yes"), MsgContains(message, "no")
		-- the greeting asked something (setInteraction resets the topic after a greeting)
		if topic == 0 and (yes or no) then
			if capsules >= 2 and statues < 1 then
				topic = 3
			elseif statues == 1 or statues == 2 then
				topic = 4
			elseif capsules >= 1 then
				topic = 2
			end
		end
		if topic == 2 and yes then
			npcHandler:setTopic(playerId, 0)
			if capsules >= 2 and statues < 4 then
				say("First find out who is behind these thieves. Then I will gladly take more capsules.") -- ours (EN: repeats need Four Demanding Statues)
				return true
			end
			local batches = math.floor(player:getItemCount(T.CAPSULE) / 10)
			if batches < 1 then
				local tainted = player:getItemCount(21816) > 0 and " Tainted ones I cannot use until they are cleansed." or ""
				say("You don't have ten glooth capsules with you." .. tainted) -- ours
				return true
			end
			player:removeItem(T.CAPSULE, batches * 10)
			addVotes(player, batches * 2)
			player:setStorageValue(C, 2)
			if capsules == 1 then
				say({
					"Great! Thank you very much for your help. The city of Rathleton is a bit safer now. If you find more of these capsules bring them back to me, too. ...",
					"But these capsules here, they seem to be filled with some kind of mutated glooth. They are tainted. If you can cleanse them somehow, I will take them. ...",
					"But there is still another thing that troubles me. I don't believe that these thieves act on their own behalf. There must be someone behind this gang. ...",
					"I want you to find this person. Would you help me?",
				})
				npcHandler:setTopic(playerId, 3)
			else
				say("Great! Thank you very much for your help. The city of Rathleton is a bit safer now. This will get you a certain voice in the city. If you find more of these capsules bring them back to me, too.")
			end
		elseif topic == 2 and no then
			npcHandler:setTopic(playerId, 0)
			say("Then keep looking. The bandits in the tunnels carry them.") -- ours
		elseif topic == 3 and yes then
			npcHandler:setTopic(playerId, 0)
			player:setStorageValue(S.Statues, 1)
			T.kv(player):set("statues", 0)
			say({
				"Excellent! I even have a little hint: One of my labourers got lost in the south-western tunnels some days ago. There he heard that some glooth bandits were approaching and wisely hid himself. But suddenly they disappeared. ...",
				"I assume they have a sort of secret hideout in this area.",
			})
		elseif topic == 3 and no then
			npcHandler:setTopic(playerId, 0)
			say("Pity. Tell me if you change your mind.") -- ours
		elseif topic == 4 and (yes or no) then
			npcHandler:setTopic(playerId, 0)
			say("That doesn't sound very reasonable. Perhaps you should push on with your researches.")
		elseif topic == 1 and yes then
			npcHandler:setTopic(playerId, 0)
			player:setStorageValue(C, 1)
			openQuestLine(player)
			say("I'm very happy to hear that. If you have found ten glooth capsules talk to me again.")
		elseif topic == 1 and no then
			npcHandler:setTopic(playerId, 0)
			say("Then excuse me, I have work to do.") -- ours
		elseif MsgContains(message, "glass tube") or MsgContains(message, "tube") then
			if player:getStorageValue(S.Plague) >= 1 then
				player:addItem(21766, 1)
				say("Did Georgia send you? Indeed I have the glass tube you are looking for. Here, take it. I hope you will successfully fight the glooth mutation down here.")
			else
				say("A glass tube? What would you need that for?") -- ours
			end
		elseif MsgContains(message, "trouble") or MsgContains(message, "mission") or MsgContains(message, "capsules") then
			if rankOf(player) < 3 then
				say("This is a matter for citizens of Rathleton. Come back when the magistrate counts you among them.") -- ours
			elseif capsules >= 2 and statues < 1 then
				say("I don't believe that these thieves act on their own behalf. There must be someone behind this gang. I want you to find this person. Would you help me?")
				npcHandler:setTopic(playerId, 3)
			elseif statues == 1 or statues == 2 then
				say("I'm very happy that you agreed to help me.")
			elseif capsules >= 1 then
				say("Do you bring back " .. (capsules >= 2 and "more " or "") .. "stolen glooth supply capsules?")
				npcHandler:setTopic(playerId, 2)
			else
				say({
					"There is a band of thieves who bully the tunnels near the factory far too long. Even worse, they have stolen some important objects. ...",
					"On the one hand there were some special gauges I calibrated for Georgia Rainbird. She surely needed them for some important purpose. Further they have stolen a vast amount of ammunition for new glooth-based weapons, so called glooth ejectors. ...",
					"This ammunition consists of glooth-filled supply capsules. Would you help me and try to bring them back?",
				})
				npcHandler:setTopic(playerId, 1)
			end
		else
			for _, entry in ipairs(elbertLines) do
				if MsgContains(message, entry[1]) then
					say(entry[2])
					break
				end
			end
		end
		return true
	end)
end

-- ==================================================================== batch 2 (2026-11-08)
-- Sabotage and Rathleton Turnip Party (Terrence), Communication Breakdown and Combinatorics
-- (Doubleday, paid in favours that he exchanges for votes, with Probing), Dr Merlay's Misery.
-- Objects are on our map (Oramond Minotaur Camp, the four sewer machines, the lab); the world
-- side is in scripts/family/oramond_tasks.lua. Messages quoted in TibiaWiki EN are used as they
-- are; the rest is ours and marked.

T.SABOTAGE_NEED, T.TURNIP_NEED = 10, 10

function T.kv(player)
	return player:kv():scoped("family-oramond")
end

local function voteFor(player, amount)
	addVotes(player, amount)
end

function T.favors(player)
	local favors = T.kv(player):get("favors") or 0
	if player:getStorageValue(O.Probing.Mission) == 3 then
		favors = favors + 1 -- an upstream probing report not exchanged yet
	end
	return favors
end

function T.addFavors(player, amount)
	T.kv(player):set("favors", (T.kv(player):get("favors") or 0) + amount)
end

-- Takes favours, the upstream probing report first.
function T.takeFavors(player, amount)
	if amount > 0 and player:getStorageValue(O.Probing.Mission) == 3 then
		player:setStorageValue(O.Probing.Mission, -1)
		amount = amount - 1
	end
	if amount > 0 then
		T.kv(player):set("favors", math.max(0, (T.kv(player):get("favors") or 0) - amount))
	end
end

-- ------------------------------------------------------------------ Terrence: supplies, sabotage

T.terrenceTasks = {
	{
		words = { "supplies", "supply", "turnips", "turnip" },
		storage = S.Turnips,
		need = T.TURNIP_NEED,
		offer = "The minotaurs keep their turnip supplies in crates up on the mountain of their camp. Sink ten of those crates in the water - gently and secretly, mind you - and report back to me.", -- ours
		progress = "You sank %d of the ten supply crates so far.", -- ours
		done = "Ten crates of turnips at the bottom of the sea! That will hurt them. That's one more voice in the magistrate for you.", -- ours
	},
	{
		words = { "sabotage" },
		storage = S.Sabotage,
		need = T.SABOTAGE_NEED,
		offer = "The mootants wear armor no blade can pierce. But the cowcoa they brew on their mountain is acrid enough to eat through it. Fill a cup at the nozzle south of their mill, pour it over ten of their armor racks and report back to me.", -- ours
		progress = "You destroyed %d of the ten armor racks so far.", -- ours
		done = "Ten armor racks? Excellent sabotage! That's one more voice in the magistrate for you.", -- ours
	},
}

local baseTerrenceSay = T.terrenceSay
function T.terrenceSay(npc, player, message, npcHandler)
	if T.on() then
		for _, task in ipairs(T.terrenceTasks) do
			for _, word in ipairs(task.words) do
				if MsgContains(message, word) then
					local count = player:getStorageValue(task.storage)
					if count >= task.need then
						player:setStorageValue(task.storage, 0)
						voteFor(player, 1)
						npcHandler:say(task.done, npc, player)
					elseif count >= 0 then
						npcHandler:say(string.format(task.progress, count), npc, player)
					else
						player:setStorageValue(task.storage, 0)
						openQuestLine(player)
						npcHandler:say(task.offer, npc, player)
					end
					return true
				end
			end
		end
	end
	return baseTerrenceSay(npc, player, message, npcHandler)
end

-- A destroyed rack turns back into a whole one after 3 minutes (EN).
T.RACK_RESET = 180
function T.destroyRack(rack)
	local pos = rack:getPosition()
	local where = Position(pos.x, pos.y, pos.z)
	rack:transform(21161)
	addEvent(function()
		local tile = Tile(where)
		local destroyed = tile and tile:getItemById(21161)
		if destroyed then
			destroyed:transform(21163)
		end
	end, T.RACK_RESET * 1000)
end

-- Item side, called from scripts/family/oramond_tasks.lua.
function T.addSabotage(player)
	local count = math.max(0, player:getStorageValue(S.Sabotage))
	if count >= T.SABOTAGE_NEED then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already sabotaged a fair amount of minotaur gear. Any further attempts will arouse suspicion. Return to a city official.")
		return false
	end
	player:setStorageValue(S.Sabotage, count + 1)
	openQuestLine(player)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The acrid cowcoa reacts with the armor. Whatever it was made of, it is no more.")
	return true
end

function T.canTakeCrate(player)
	if math.max(0, player:getStorageValue(S.Turnips)) >= T.TURNIP_NEED then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You thinned out these supplies quite effectively - any more and they would surely notice. Return to a city official.")
		return false
	end
	return true
end

function T.addTurnips(player)
	player:setStorageValue(S.Turnips, math.max(0, player:getStorageValue(S.Turnips)) + 1)
	openQuestLine(player)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You gently acquaint the crate with fresh water, destroying the turnip in the process - the feeling of being watched disappears.")
end

-- ------------------------------------------------------------------ Combinatorics

T.combo = { ["Glooth Golem"] = "g", ["Devourer"] = "d", ["Glooth Anemone"] = "a" }
T.comboNames = { g = "Glooth Golem", d = "Devourer", a = "Glooth Anemone" }
local ORDERS = { "gda", "gad", "dga", "dag", "agd", "adg" }

function T.comboOrder(player)
	local order = T.kv(player):get("combo-order")
	if not order then
		order = ORDERS[math.random(#ORDERS)]
		T.kv(player):set("combo-order", order)
		T.kv(player):set("combo-step", 0)
		T.kv(player):set("combo-sequences", 0)
		T.kv(player):set("combo-chains", 0)
	end
	return order
end

local function orderText(order)
	local names = {}
	for i = 1, 3 do
		names[i] = T.comboNames[order:sub(i, i)]
	end
	return table.concat(names, ", ")
end

-- Kills in the right order make sequences; from the fourth sequence in a row each one is a
-- consecutive chain (Combo Master: 10 chains = 39 kills, its description). A wrong kill ends the
-- streak and the chains not reported yet (EN).
function T.comboKill(player, creatureName)
	local letter = T.combo[creatureName]
	if not letter or not T.on() then
		return
	end
	local kv = T.kv(player)
	local order = T.comboOrder(player)
	if player:getStorageValue(S.Combinatorics) < 1 then
		player:setStorageValue(S.Combinatorics, 1)
		openQuestLine(player)
	end
	local step = kv:get("combo-step") or 0
	if order:sub(step + 1, step + 1) ~= letter then
		local lost = kv:get("combo-chains") or 0
		kv:set("combo-step", 0)
		kv:set("combo-sequences", 0)
		kv:set("combo-chains", 0)
		player:sendTextMessage(MESSAGE_STATUS, string.format("Combinatorics: wrong order, the combo is broken%s. Order: %s.", lost > 0 and string.format(" (%d chains lost)", lost) or "", orderText(order)))
		return
	end
	step = step + 1
	if step < 3 then
		kv:set("combo-step", step)
		player:sendTextMessage(MESSAGE_STATUS, string.format("Combinatorics: %s %d of 3, next %s.", T.comboNames[letter], step, T.comboNames[order:sub(step + 1, step + 1)]))
		return
	end
	kv:set("combo-step", 0)
	local sequences = (kv:get("combo-sequences") or 0) + 1
	kv:set("combo-sequences", sequences)
	local streak = math.max(0, sequences - 3)
	if streak > 0 then
		kv:set("combo-chains", (kv:get("combo-chains") or 0) + 1)
	end
	if streak >= 10 and not player:hasAchievement("Combo Master") then
		player:addAchievement("Combo Master")
	end
	player:sendTextMessage(MESSAGE_STATUS, string.format("Combinatorics: sequence %d complete, %d consecutive chains to report. Next %s.", sequences, kv:get("combo-chains") or 0, T.comboNames[order:sub(1, 1)]))
end

function T.comboText(player)
	local kv = T.kv(player)
	local order = kv:get("combo-order")
	if not order then
		return "Kill a glooth golem, a devourer and a glooth anemone in the right order in the Rathleton new sewers for Doubleday."
	end
	return string.format("Kill in this order in the Rathleton new sewers: %s. Sequences in a row: %d. Consecutive chains to report to Doubleday: %d. Favours with Doubleday: %d.", orderText(order), kv:get("combo-sequences") or 0, kv:get("combo-chains") or 0, T.favors(player))
end

-- ------------------------------------------------------------------ Doubleday

-- Topics 20+ (upstream uses 1-9).
function T.doubledaySay(npc, player, message, npcHandler)
	if not T.on() then
		return false
	end
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	local say = function(text)
		npcHandler:say(text, npc, player)
	end
	local kv = T.kv(player)

	if topic == 21 and MsgContains(message, "yes") then
		npcHandler:setTopic(id, 0)
		kv:remove("combo-order")
		local order = T.comboOrder(player)
		player:setStorageValue(S.Combinatorics, 1)
		openQuestLine(player)
		say({
			"Ha, I knew it! Well, just go to the new sewers and kill some monsters that's it! Here is how to do it and which combination to try, it's always a little different, see... ...",
			"First a " .. T.comboNames[order:sub(1, 1)] .. ", then a " .. T.comboNames[order:sub(2, 2)] .. " and then a " .. T.comboNames[order:sub(3, 3)] .. ". ...",
			"Now, no need for any vessel or whatever - just come back here, I will scrape the blood from your coat and you tell me what I want to know about each... 'sample'. Hey, I can even keep track of your combo score.",
		})
		return true
	elseif topic == 22 and MsgContains(message, "yes") then
		npcHandler:setTopic(id, 0)
		local chains = kv:get("combo-chains") or 0
		if chains < 1 then
			say("Hmm, no consecutive chains on your coat. Remember: three sequences in a row first, then every further sequence makes a chain.") -- ours
			return true
		end
		kv:set("combo-chains", 0)
		T.addFavors(player, chains)
		say(string.format("%d consecutive chains! Marvellous samples. I noted them - ask me for an {exchange} whenever you want your votes.", chains)) -- ours
		return true
	elseif topic == 23 and MsgContains(message, "yes") then
		npcHandler:setTopic(id, 0)
		player:setStorageValue(S.Communication, 1)
		openQuestLine(player)
		say({
			"Splendid! My altered glooth carries sounds - but it is quite unstable, so I had to leave my machines running in the new sewers. The way down is the sewer grate under the docks, south-west of here. ...",
			"At a machine, turn one of the valves three times and watch the colour of the steam. Then pull the levers of those colours in the same order. A bit of coloured glooth will come out - fill it into a vial and bring it to me.",
		}) -- ours
		return true
	elseif topic == 24 then
		local amount = tonumber(message:match("%d+"))
		if amount then
			local favors = T.favors(player)
			if amount < 1 then
				return true
			elseif amount > favors then
				say("Hey, let's try to be reasonable here, alright? That's a bit too much for what you did, isn't it? It may seem that way but the number of votes I can offer isn't limitless.")
				return true
			end
			kv:set("exchange-amount", amount)
			npcHandler:setTopic(id, 25)
			say(string.format("Alright then, that's %d vote(s) you want - I won't take them back, are you sure?", amount))
			return true
		end
	elseif topic == 25 and MsgContains(message, "yes") then
		npcHandler:setTopic(id, 0)
		local amount = kv:get("exchange-amount") or 0
		if amount < 1 or amount > T.favors(player) then
			return true
		end
		T.takeFavors(player, amount)
		voteFor(player, amount)
		say(string.format("Good, you just gained %d genuine votes in the magistrate!", amount))
		return true
	end

	if MsgContains(message, "exchange") then
		local favors = T.favors(player)
		if favors < 1 then
			say("You haven't helped me with anything I could pay votes for yet. Ask me about my {experiment}.") -- ours
			npcHandler:setTopic(id, 0)
		else
			say(string.format("Well, let's see, you helped me %d times before exchanging any votes - how many votes do you want me to give you in exchange?", favors))
			npcHandler:setTopic(id, 24)
		end
		return true
	elseif MsgContains(message, "combinatorics") then
		if not kv:get("combo-order") then
			say({
				"Besides the state of the altered glooth down there, I am trying to figure out more about the structure of the creatures this affects. This requires blood - in a certain combination! ...",
				"See, down there in the upper parts of the new sewers, you can find three sorts of creatures. When I went down there the last time - and that was quite some time ago - I found a strange substance. ...",
				"Undoubtedly blood - but not just any blood. It must have been a certain combination of everything that crawls down there. Believe it or not - it made a puddle of my altered glooth down there perfectly stable! ...",
				"I couldn't find out the combination - but I took samples! See, this is like - mixing a certain cocktail, you need to put different liquids with different densities in a specific order to get the best effect, ahem heh heh, eh? ...",
				"Well, don't you get it? If you can kill them in a specific order (which I will explain to you in DETAIL before), the mixed blood will be ideal for my research! ...",
				"Sounds crazy, doesn't it? Well it isn't! If I can figure out what kind of monster combination made the altered glooth stable - there will be no shortage of altered glooth anymore! ...",
				"With that being said - only combo chains (3x 3 creatures in a row and consecutive chains) will be rewarded! So, are you in or not or what?",
			})
			npcHandler:setTopic(id, 21)
		else
			say(string.format("So, let me see your coat... %d consecutive chains since you last reported. Shall I scrape them off and note them?", kv:get("combo-chains") or 0)) -- ours
			npcHandler:setTopic(id, 22)
		end
		return true
	elseif MsgContains(message, "communication") or MsgContains(message, "communications") then
		local state = player:getStorageValue(S.Communication)
		if state >= 2 then
			player:removeItem(21188, 1)
			player:setStorageValue(S.Communication, 0)
			T.addFavors(player, 1)
			say("The coloured glooth! Even a little broken it tells me everything I need. Thank you - ask me for an {exchange} when you want votes for it.") -- ours
			npcHandler:setTopic(id, 0)
		elseif state == 1 then
			say("Did you get a vial of coloured glooth from one of my machines yet? Valves first, three times - then the levers of the same colours, in the same order.") -- ours
			npcHandler:setTopic(id, 0)
		else
			say("I am working on a wireless communication system for Rathleton - altered glooth conducts sounds wonderfully. But I need samples from my machines in the new sewers. Will you fetch one?") -- ours
			npcHandler:setTopic(id, 23)
		end
		return true
	end
	return false
end

-- ------------------------------------------------------------------ Communication Breakdown machines

T.COLOURS = {
	r = { name = "Red", effect = CONST_ME_REDSMOKE, lever = 21125 },
	y = { name = "Yellow", effect = CONST_ME_YELLOWSMOKE, lever = 21126 },
	g = { name = "Green", effect = CONST_ME_GREENSMOKE, lever = 21127 },
	v = { name = "Violet", effect = CONST_ME_PURPLESMOKE, lever = 21128 },
}
T.colourByLever = {}
for key, colour in pairs(T.COLOURS) do
	T.colourByLever[colour.lever] = key
end

-- The four machines on our map: lever column (red at the top) and where the glooth appears.
T.machines = {
	{ lever = Position(33618, 31927, 9), glooth = Position(33618, 31926, 9) },
	{ lever = Position(33640, 31928, 10), glooth = Position(33640, 31927, 10) },
	{ lever = Position(33625, 31958, 9), glooth = Position(33624, 31957, 9) }, -- no ground north of the levers
	{ lever = Position(33667, 31980, 9), glooth = Position(33667, 31979, 9) },
}

function T.machineAt(position)
	for index, machine in ipairs(T.machines) do
		if machine.lever.z == position.z and math.abs(machine.lever.x - position.x) <= 6 and math.abs(machine.lever.y + 1 - position.y) <= 6 then
			return index, machine
		end
	end
end

function T.useValve(player, position)
	local index = T.machineAt(position)
	if not index then
		return false
	end
	local kv = T.kv(player)
	local colours = kv:get("comm-colours") or ""
	if kv:get("comm-machine") ~= index or #colours >= 3 then
		colours = ""
		kv:set("comm-machine", index)
		kv:set("comm-pulled", "")
	end
	local keys = { "r", "y", "g", "v" }
	local key = keys[math.random(#keys)]
	colours = colours .. key
	kv:set("comm-colours", colours)
	local colour = T.COLOURS[key]
	player:getPosition():sendMagicEffect(colour.effect)
	player:say(colour.name .. " steam emerges...", TALKTYPE_MONSTER_SAY, false, player, position)
	return true
end

T.leverReady = {}

-- Returns "glooth" when the right three levers were pulled.
function T.pullLever(player, item, position)
	local key = T.colourByLever[item:getId()]
	local index, machine = T.machineAt(position)
	if not key or not index then
		return false
	end
	local spot = position.x .. "," .. position.y .. "," .. position.z
	if (T.leverReady[spot] or 0) > os.time() then
		player:sendCancelMessage("The lever is still moving back.") -- ours
		return true
	end
	T.leverReady[spot] = os.time() + 5 -- EN: levers take 5 seconds to return
	position:sendMagicEffect(T.COLOURS[key].effect)
	local kv = T.kv(player)
	local colours = kv:get("comm-colours") or ""
	if kv:get("comm-machine") ~= index or #colours < 3 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nothing happens. Turn a valve of this machine first.") -- ours
		return true
	end
	local pulled = (kv:get("comm-pulled") or "") .. key
	if colours:sub(1, #pulled) ~= pulled then
		kv:set("comm-pulled", "")
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The machine coughs and nothing comes out. That was not the colour of the steam.") -- ours
		return true
	end
	if #pulled < 3 then
		kv:set("comm-pulled", pulled)
		return true
	end
	kv:set("comm-pulled", "")
	kv:set("comm-colours", "")
	local tile = Tile(machine.glooth)
	if tile and not tile:getItemById(21152) then
		local glooth = Game.createItem(21152, 1, machine.glooth)
		if glooth then
			local where = Position(machine.glooth.x, machine.glooth.y, machine.glooth.z)
			addEvent(function()
				local t = Tile(where)
				local g = t and t:getItemById(21152)
				if g then
					g:remove()
				end
			end, 2 * 60 * 1000)
		end
	end
	machine.glooth:sendMagicEffect(CONST_ME_GREENSMOKE)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Strangely coloured glooth seeps out of the machine.") -- ours
	return true
end

function T.takeGlooth(player, item)
	if player:getStorageValue(S.Communication) ~= 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "It is a strange, coloured glooth. You have no use for it.") -- ours
		return true
	end
	item:remove()
	player:addItem(21188, 1)
	player:setStorageValue(S.Communication, 2)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You fill some of the coloured glooth in a vessel. It seems to affect it, making it fragile. Better carry it somewhere safe.")
	return true
end

-- ------------------------------------------------------------------ Dr Merlay's Misery

T.LETTERS, T.POTION, T.BLOOM, T.MIXTURE, T.PILL = 21141, 21154, 21213, 21216, 21142
T.friends = { maro = 1, alaistar = 2, azalea = 4, fyodor = 8, emily = 16 }
T.ALL_FRIENDS = 31

local function visited(player, friend)
	return bit.band(T.kv(player):get("merlay-visits") or 0, T.friends[friend]) ~= 0
end

local function visit(player, friend)
	T.kv(player):set("merlay-visits", bit.bor(T.kv(player):get("merlay-visits") or 0, T.friends[friend]))
end

function T.isRotElemental(player)
	return (T.kv(player):get("rot-until") or 0) >= os.time()
end

function T.hasLabAccess(player)
	return T.kv(player):get("lab-access") == true
end

function T.merlayGreeting(player)
	if player:getStorageValue(S.Merlay) >= 1 then
		return "Welcome, my eagerly awaited friend! How did it go? Please tell me everything!"
	end
	return "Don't look at me! I'm {hideous}!"
end

local merlayLines = {
	{ "hideous", "What do you think? Look at me! Do you think I was born this way? I was a respected glooth {scientist} and tradesman!" },
	{ "scientist", "The {glooth} has been my nemesis! It caused this strange transformation and now I dare not even walk the street at nights anymore." },
	{ "glooth", "Ah, that strange enticing stuff! It is incredibly versatile, so fascinatingly useful! And yet, and yet... <looks down at himself>" },
	{ "name", "I used to be Dr Henry Merlay, but now.... <howls>" },
	{ "merlay", "Yes, yes, the one who disappeared years ago in that tragic glooth {factory} incident." },
	{ "factory", "Ah, it was the pride of my days! An experimental glooth and working units production factory - nobody could construct metal golems like I did! <sadly> All in the past, now... all in the past." },
	{ "time", "<anxiously> The time? Which year is it? How long have I been here underground?" },
	{ "wife", "My beautiful, lovely Emily. Is she still alive? Did she forget me? ... I can't bear to think of it!" },
	{ "emily", "Oh, my beloved wife. I don't know what became of her. So many years ... The horror of not knowing!" },
	{ "graham", "Who? And he looks like me? Are you sure?" },
	{ "maro", { "He was my only friend, the only one who did not turn away in horror when he chanced to see me one night, when I went above ground. ...", "No one else listened! They all screamed and ran in horror! And I can hardly blame them. Who would believe me to be Henry Merlay? <sigh> ...", "But now Maro runs that tool shop he cannot come any longer. I understand. But I need someone to fetch and deliver my {letters}." } },
	{ "alaistar", "My best friend in younger days. I charged him to look after Emily. But I don't know what happened since then. Is he alive and still my friend?" },
	{ "mordecai", "We appreciated each other, though we never became quite as good friends as Alaistar and I." },
	{ "carefew", "The nemesis of my family. He has always been against all modern concepts, and has looked upon my revolutionary findings with an unfriendly eye. I fear he has influenced everyone in this town against me." },
}

-- Returns true when the NPC answered. friend = "merlay", "roswitha" or a key of T.friends.
function T.merlaySay(npc, player, message, npcHandler, friend)
	if not T.on() then
		return false
	end
	local id = player:getId()
	local say = function(text)
		npcHandler:say(text, npc, player)
	end
	local state = player:getStorageValue(S.Merlay)
	local kv = T.kv(player)

	if friend == "roswitha" then
		if MsgContains(message, "pint") then
			if (kv:get("pint-at") or 0) > os.time() then
				say("One free pint an hour, my lad - ask for a {drink} if you want another one.") -- ours
			else
				kv:set("pint-at", os.time() + 60 * 60)
				player:addItem(21137, 1)
				say("Here you go, a fresh pint of glooth - on the house! Drink it while it's frothy.") -- ours
			end
			return true
		elseif MsgContains(message, "drink") then
			if not player:removeMoneyBank(10) then
				say("That's 10 gold, my lad. Come back when you have it.") -- ours
			else
				player:addItem(21137, 1)
				say("A pint of glooth, 10 gold. Cheers!") -- ours
			end
			return true
		end
		return false
	end

	if friend == "merlay" then
		local topic = npcHandler:getTopic(id)
		if topic == 31 and MsgContains(message, "yes") then
			npcHandler:setTopic(id, 0)
			player:addItem(T.LETTERS, 1)
			player:setStorageValue(S.Merlay, 1)
			kv:set("merlay-visits", 0)
			openQuestLine(player)
			say({
				"Thank you, thank you! Here are my letters. Take the first one to Maro in his tool shop - he will tell you where the others live: Alaistar, Azalea, Fyodor and my Emily. ...",
				"Alaistar is a clever man. If anyone knows how to make a cure, it is him. Bring me whatever he gives you.",
			}) -- ours
			return true
		elseif topic == 32 and MsgContains(message, "yes") then
			npcHandler:setTopic(id, 0)
			if player:getItemCount(T.PILL) < 1 then
				say("But... where is it? You don't have the pill with you!") -- ours
				return true
			end
			player:removeItem(T.PILL, 1)
			if player:getItemCount(T.LETTERS) > 0 then
				player:removeItem(T.LETTERS, 1)
			end
			player:setStorageValue(S.Merlay, 0)
			kv:set("merlay-visits", 0)
			voteFor(player, 1)
			say({
				"<gulps> Ah.... I can feel it working already... Please my friend, accept my humblest thanks for your help! Feel free to exert my city voting right at the magistrate for me, I cannot use it at present. ...",
				"And now, leave me some privacy to change into something more... humane. But feel free to visit me anytime!",
			})
			return true
		elseif topic == 32 and MsgContains(message, "no") then
			npcHandler:setTopic(id, 0)
			say("Oh... I thought... never mind.") -- ours
			return true
		end
		if MsgContains(message, "pill") or MsgContains(message, "ominously glowing pill") then
			if state >= 1 and player:getItemCount(T.PILL) > 0 then
				if bit.band(kv:get("merlay-visits") or 0, T.ALL_FRIENDS) ~= T.ALL_FRIENDS then
					say("A pill? But did you deliver all my letters? Maro, Alaistar, Azalea, Fyodor and Emily must know I am alive!") -- ours
					return true
				end
				say({ "It worked! It WORKED! Please, give it to me, I must try it!", "I must have misheard you, could you please say that again? Yes or no?" })
				npcHandler:setTopic(id, 32)
			else
				say("A pill? I wish there was a pill against... this.") -- ours
			end
			return true
		elseif MsgContains(message, "mixture") or MsgContains(message, "cool gloothy mixture") then
			if state >= 1 and player:getItemCount(T.MIXTURE) > 0 then
				player:setStorageValue(S.Merlay, 2)
				say("This... this looks promising! You have it from Alaistar? Perfect! Quickly, use the particle accelerator with it, maybe this can create a potent lozenge that can cure me!")
			else
				say("Mixture? Alaistar would know about mixtures. Did you visit him?") -- ours
			end
			return true
		elseif MsgContains(message, "help") or MsgContains(message, "letters") or MsgContains(message, "letter") or MsgContains(message, "mission") then
			if state >= 1 then
				local missing = {}
				for _, name in ipairs({ "maro", "alaistar", "azalea", "fyodor", "emily" }) do
					if not visited(player, name) then
						missing[#missing + 1] = name:gsub("^%l", string.upper)
					end
				end
				if #missing > 0 then
					say("Please deliver my letters - still waiting are: " .. table.concat(missing, ", ") .. "." .. (player:getItemCount(T.LETTERS) < 1 and " Here, take another bundle, you seem to have lost yours." or "")) -- ours
					if player:getItemCount(T.LETTERS) < 1 then
						player:addItem(T.LETTERS, 1)
					end
				else
					say("Everyone knows? Then bring me Alaistar's cure - stabilised with a soothe bloom and pressed into a {pill} in my particle accelerator.") -- ours
				end
			else
				say("Would you... would you help me? I need someone to deliver my letters to my friends and my wife up in the city. Will you do it?") -- ours
				npcHandler:setTopic(id, 31)
			end
			return true
		end
		for _, entry in ipairs(merlayLines) do
			if MsgContains(message, entry[1]) then
				say(entry[2])
				return true
			end
		end
		return false
	end

	-- the friends in the city
	local hasLetters = state >= 1 and player:getItemCount(T.LETTERS) > 0
	if friend == "maro" and MsgContains(message, "message") and hasLetters then
		say("Thank you for bringing me his letter. And you need to see some other fellow hoomans, yes?")
		npcHandler:setTopic(id, 41)
		visit(player, "maro")
		return true
	elseif friend == "maro" and npcHandler:getTopic(id) == 41 and MsgContains(message, "yes") then
		npcHandler:setTopic(id, 0)
		say({
			"Maro knows them by smell, although they did not tell him their names. But they told father Alaistar their names, because he was the best friend of fellow hooman, a long time ago, and he trusted me. Azalea and Fyodor, they are called. ...",
			"Then there is the lady friend Emily. She will be gladdest of all to hear from fellow hooman friend! ...",
			"But now you should see father Alaistar upstairs, he will be glad to hear from fellow hooman friend, and may have an idea that will help cure him!",
		})
		return true
	elseif friend == "alaistar" and (MsgContains(message, "message") or MsgContains(message, "letter")) and hasLetters then
		say("You... have... a message... from... Henry?? By the gods above and below! Keep quiet. He still lives? I thought, after all these years of silence... never mind. Let me read his message for a {moment}.")
		npcHandler:setTopic(id, 42)
		return true
	elseif friend == "alaistar" and MsgContains(message, "moment") and npcHandler:getTopic(id) == 42 then
		npcHandler:setTopic(id, 0)
		visit(player, "alaistar")
		player:addItem(T.POTION, 1)
		say({
			"This is fantastic! He writes he may have found the missing coagent for the gloothomagic combination! ...",
			"<reads intently> This is it, the final clue I was missing! Of course, the coefficient <mumbles unintelligibly> the particle acceleration.... Of course! Yes! This could actually work! Let me mix you something. ...",
			"... There! This glooth potion could be the base for the cure. I agree with Henry that he needs to cure this from the inside, maybe through a pill of lozenge. ...",
			"However, this potion is VERY unstable, so you must combine it with a freshly granulated soothe bloom first, to neutralise the toxic effects, before you can make a lozenge out of it. Azalea has reared a soothe blossom, please visit her. ...",
			"And please also visit Fyodor if you did not already do so. I know that he can help Henry with his writing problem, he is just the right man for it. ...",
			"Remember, the stabilised potion must be mixed in Henry's patented particle accelerator to create the exact right density for the lozenge! He must have an accelerator in his lab. Thank you, and please send my regards to Henry.",
		})
		return true
	elseif friend == "alaistar" and MsgContains(message, "lost") and visited(player, "alaistar") and state >= 1 then
		player:addItem(T.POTION, 1)
		say("Lost it? Here, I mixed another glooth potion. Handle it with care!") -- ours
		return true
	elseif friend == "azalea" and MsgContains(message, "letter") and hasLetters then
		visit(player, "azalea")
		kv:set("bloom-at", os.time() + 60 * 60)
		player:addItem(T.BLOOM, 1)
		say({
			"It is from the doctor who is in pain! Finally he has decided to turn to his friends again. This pleases me. ...",
			"Here, take this darling I nurtured for him with you. I spoke words of power to it. It should help alleviate the torment in his soul, and will seek to restore his original shape. ...",
			"If you did not already visit all the others, please do so. They will be pleased to hear news from him and to be able to help him again. Thank you for your help.",
		})
		return true
	elseif friend == "azalea" and MsgContains(message, "lost") and visited(player, "azalea") and state >= 1 then
		if (kv:get("bloom-at") or 0) > os.time() then
			say("A soothe bloom needs time to grow. Come back in an hour.") -- ours
		else
			kv:set("bloom-at", os.time() + 60 * 60)
			player:addItem(T.BLOOM, 1)
			say("Here is another soothe bloom. Take better care of this one.") -- ours
		end
		return true
	elseif friend == "fyodor" and (MsgContains(message, "friend") or MsgContains(message, "letter")) and hasLetters then
		visit(player, "fyodor")
		say({
			"<reads> 'To whomever it concerns '... Hey! This is... it is... from... it really is, isn't it? This is capital news! ...",
			"I will do as he pleads. I must act at once! I will seek his leftover writings and copy his letters in his style for him. The injustice he and his family have suffered shall not endure. My pen is at his command! ...",
			"You should see his wife Emily, if you have not already done so. Thank you again and again, you have served a good cause and helped a great man!",
		})
		return true
	elseif friend == "emily" and (MsgContains(message, "message") or MsgContains(message, "letter")) and hasLetters then
		say("You have news, news from Henry! What is it? Where is he? Why doesn't he come himself? Is he ill? Captured? Suffering? Dying? {Tell} me at once, I beg you!")
		npcHandler:setTopic(id, 43)
		return true
	elseif friend == "emily" and MsgContains(message, "tell") and npcHandler:getTopic(id) == 43 then
		npcHandler:setTopic(id, 0)
		visit(player, "emily")
		say("A letter? A letter from Henry! Oh, how wonderful! After all this time! I must read it at once. Oh, you have made me so happy! I shall forever be in your debt!")
		return true
	end
	return false
end

-- For NPCs without their own callbacks (Maro, Azalea, Fyodor, Emily, Dr Merlay).
function T.setupMerlayFriend(npcHandler, friend)
	if friend == "merlay" then
		npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
			npcHandler:setMessage(MESSAGE_GREET, T.merlayGreeting(Player(creature)))
			return true
		end)
	end
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if player then
			T.merlaySay(npc, player, message, npcHandler, friend)
		end
		return true
	end)
end

function T.missionTextBatch2(player, key)
	if key == "Sabotage" then
		return string.format("Destroy ten mootant armor racks in the Oramond Minotaur Camp with cups of cowcoa from the nozzle south of the mill on the mountain, then report to Terrence: %d of 10.", math.max(0, player:getStorageValue(S.Sabotage)))
	elseif key == "Turnips" then
		return string.format("Take supply crates from the mountain of the Oramond Minotaur Camp and sink them gently in the water, then report to Terrence: %d of 10.", math.max(0, player:getStorageValue(S.Turnips)))
	elseif key == "Communication" then
		if player:getStorageValue(S.Communication) >= 2 then
			return "You have a vial of coloured glooth. Bring it to Doubleday."
		end
		return "Get a vial of coloured glooth from one of Doubleday's machines in the Rathleton new sewers: turn a valve three times, then pull the levers of the steam colours in the same order."
	elseif key == "Combinatorics" then
		return T.comboText(player)
	elseif key == "Merlay" then
		local state = player:getStorageValue(S.Merlay)
		if state < 1 then
			return "Dr Merlay can be helped again. Get a pint of glooth from Roswitha to reach his laboratory."
		end
		local missing = {}
		for _, name in ipairs({ "maro", "alaistar", "azalea", "fyodor", "emily" }) do
			if not visited(player, name) then
				missing[#missing + 1] = name:gsub("^%l", string.upper)
			end
		end
		if #missing > 0 then
			return "Deliver Dr Merlay's letters. Still waiting: " .. table.concat(missing, ", ") .. "."
		end
		return "Use Alaistar's glooth potion on Azalea's soothe bloom, press the mixture into a pill in Dr Merlay's particle accelerator and give it to him."
	end
	return ""
end

-- ==================================================================== batch 3 (2026-11-08)
-- Four Demanding Statues (Elbert) and The Mutated Glooth Plague (Georgia Rainbird, missing
-- upstream: new NPC file). Sources: TibiaWiki EN Oramond Quest/Spoiler (method, server
-- messages, Elbert's and Georgia's transcripts, the two books), BR Oramond Quest; the objects
-- were found on our map (statue room 33574,32034,12, warlock room z11, Georgia's lab).

-- ------------------------------------------------------------------ Four Demanding Statues

T.STATUES = {
	bless = { bit = 1, message = "Mysteriously the statue comes to life, nodds generously and spreads its wings. Then it turns back into its lifeless state." },
	adorn = { bit = 2, message = "Mysteriously the statue comes to life, stretches out its arm and takes the flowers. Then it turns back into its lifeless state." },
	feed = { bit = 4, message = "Mysteriously the statue comes to life, bends its head and devours the offered meat. Then it turns back into its lifeless state." },
	entertain = { bit = 8, message = "Mysteriously the kingly statue comes to life, smiles slightly and nodds generously. Then it turns back into its lifeless state." },
}
T.STATUE_POS = {
	bless = Position(33574, 32027, 12), -- angel statue, north
	adorn = Position(33581, 32034, 12), -- sacred statue, east
	feed = Position(33574, 32041, 12), -- cobra statue, south
	entertain = Position(33567, 32034, 12), -- king statue, west
}
T.ALL_STATUES = 15

function T.statuesDone(player)
	return bit.band(T.kv(player):get("statues") or 0, T.ALL_STATUES) == T.ALL_STATUES
end

-- wish = bless/adorn/feed/entertain; returns true when it counted.
function T.pleaseStatue(player, wish)
	local state = player:getStorageValue(S.Statues)
	if state < 1 or state >= 3 then
		return false
	end
	local entry = T.STATUES[wish]
	local mask = T.kv(player):get("statues") or 0
	T.kv(player):set("statues", bit.bor(mask, entry.bit))
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, entry.message)
	return true
end

function T.nearStatue(player, wish, range)
	local pos, at = player:getPosition(), T.STATUE_POS[wish]
	return pos.z == at.z and math.abs(pos.x - at.x) <= (range or 2) and math.abs(pos.y - at.y) <= (range or 2)
end

-- From music.lua (FAMILY hook): the lyre near the king statue.
function T.playLyre(player)
	if T.on() and T.nearStatue(player, "entertain", 3) then
		T.pleaseStatue(player, "entertain")
	end
end

function T.warlockKilled(player)
	if player:getStorageValue(S.Statues) == 1 and T.statuesDone(player) then
		player:setStorageValue(S.Statues, 2)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Has the warlock been behind the glooth bandits' assaults? Most likely, but you need a proof. Isn't there a letter in the shelf?")
	end
end

T.WARLOCK_LETTER = "My esteemed colleague,\n\nwe are very pleased to hear that your activities near Rathleton are flourishing. To be honest, at first we were more than suspicious as we learned that you are hiring a gang of criminals and have them do the more inconvenient tasks for you. But seemingly you are able to keep away from them the important information about your actual goals and intentions. Furthermore your succes in establishing a makeshift laboratory in the tunnels under Rathleton and even acquiring some novel glooth based weaponry speaks for itself. The mutated glooth you mentioned in your last letter is an interesting matter. Perhaps it is useable in an arcane way to enhance spells or improve potions. Even the creation of yet unknown artefacts could be possible. We think your endeavours are taking a good path.\n\nWith best regards\nUquora the High-Handed of the Circle of the Black Sphinx"

-- ------------------------------------------------------------------ The Mutated Glooth Plague

T.DEVICE, T.CONVERTER, T.FILLED = 21759, 21761, 21767
T.GEAR, T.VALVE, T.GAUGE, T.TUBE = 21755, 21758, 21757, 21766
T.MUSHROOM, T.DISTILLATE = 21768, 21769
T.POOLS_NEED = 8
T.PARTS = {
	[21755] = { bit = 1, count = 5, text = "You mount the gear wheels on the broken device." },
	[21758] = { bit = 2, count = 1, text = "You mount the valve on the broken device." },
	[21757] = { bit = 4, count = 1, text = "You mount the indicator gauge on the broken device." },
	[21766] = { bit = 8, count = 1, text = "You mount the glass tube on the broken device." },
}

-- A part used on the strange device. Returns true when it was handled.
function T.mountPart(player, part, device)
	local entry = T.PARTS[part:getId()]
	if not entry then
		return false
	end
	local mask = T.kv(player):get("device-parts") or 0
	if bit.band(mask, entry.bit) ~= 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This part is already mounted.") -- ours
		return true
	end
	if player:getItemCount(part:getId()) < entry.count then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You need %d of them.", entry.count)) -- ours
		return true
	end
	player:removeItem(part:getId(), entry.count)
	mask = bit.bor(mask, entry.bit)
	if mask == 15 then
		T.kv(player):set("device-parts", 0)
		device:transform(T.CONVERTER)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, entry.text .. " Now it seems to work.")
	else
		T.kv(player):set("device-parts", mask)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, entry.text .. " But it doesn't seem complete yet.")
	end
	return true
end

-- The filled converter used on a purple slime square; returns true when it counted.
function T.convertPool(player, position)
	local kv = T.kv(player)
	local key = position.x .. "," .. position.y .. "," .. position.z
	local done = kv:get("pools") or ""
	if done:find("[" .. key .. "]", 1, true) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This glooth is already converted.") -- ours
		return false
	end
	done = done .. "[" .. key .. "]"
	local count = (kv:get("pool-count") or 0) + 1
	kv:set("pools", done)
	kv:set("pool-count", count)
	if count >= T.POOLS_NEED then
		kv:set("pools", "")
		kv:set("pool-count", 0)
		player:removeItem(T.FILLED, 1)
		player:addItem(T.DEVICE, 1)
		player:addItem(T.GEAR, 5)
		player:addItem(T.VALVE, 1)
		player:addItem(T.GAUGE, 1)
		player:addItem(T.TUBE, 1)
		if player:getStorageValue(S.Plague) >= 1 then
			player:setStorageValue(S.Plague, 3)
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The mutated glooth turns back into its primal state - and the converter falls apart into its components. Report to Georgia Rainbird.") -- ours
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("The mutated glooth turns back into its primal state (%d of %d).", count, T.POOLS_NEED)) -- ours
	end
	return true
end

-- ------------------------------------------------------------------ Georgia Rainbird

local georgiaLines = {
	{ "busy", "I am researching the {glooth} and its mutation. Or I was, before I lost my eyesight." }, -- ours
	{ "blind", "An accident in my laboratory. A flask of mutated glooth burst right in front of my face. Now I need other people's eyes." }, -- ours
	{ "glooth", "Something is happening to the glooth in these caves. It seems to change in a strange way. This mutation has negative side effects and must be stopped." },
	{ "components", "You need five special {gear wheels} I haven't in stock here in the laboratory. Furthermore the converter requires a {glass tube}, a {valve} and a specially calibrated indicator {gauge}." },
	{ "gear wheels", "Bronze gear wheels. The golems and gargoyles of Rathleton are full of them." }, -- ours
	{ "glass tube", "My former assistant Elbert should still have one. Ask him for a glass tube." }, -- ours
	{ "valve", "The copper valves of the pumping pipes down here fit perfectly. Just demount one." }, -- ours
	{ "gauge", "I calibrated some indicator gauges myself. A box with them stands in the western tunnels - if the bandits left any." }, -- ours
}

function T.setupGeorgia(npcHandler)
	npcHandler:setMessage(MESSAGE_GREET, "Greetings. You don't have to shout, my ears are very good! Besides I'm quite {busy}, as you may see.")
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		local id = player:getId()
		if not T.on() then
			return true
		end
		local say = function(text)
			npcHandler:say(text, npc, creature)
		end
		local topic = npcHandler:getTopic(id)
		local state = player:getStorageValue(S.Plague)
		if topic == 51 and MsgContains(message, "yes") then
			player:addItem(T.DEVICE, 1)
			player:setStorageValue(S.Plague, 1)
			T.kv(player):set("device-parts", 0)
			openQuestLine(player)
			say({
				"Splendid! So listen: I think I found a way to eliminate the mutated glooth by converting it back into its primal state. I have constructed a special device, a glooth converter - or at least, I was about to do so. ...",
				"Then I lost my eyesight and wasn't able to finish my work. There are still some missing {components}. If you could obtain them, we might complete the converter. ...",
				"Here, I give you the unfinished device, so you can mount the missing parts. Do you know what you need for the repair?",
			})
			npcHandler:setTopic(id, 52)
			return true
		elseif topic == 51 and MsgContains(message, "no") then
			npcHandler:setTopic(id, 0)
			say("Then don't waste my time.") -- ours
			return true
		elseif topic == 52 and MsgContains(message, "no") then
			npcHandler:setTopic(id, 0)
			say("You need five special {gear wheels} I haven't in stock here in the laboratory. Furthermore the converter requires a {glass tube}, a {valve} and a specially calibrated indicator {gauge}.")
			return true
		elseif topic == 52 and MsgContains(message, "yes") then
			npcHandler:setTopic(id, 0)
			say("Good. Mount the parts on the device and come back to me with the converter.") -- ours
			return true
		end
		if MsgContains(message, "lost glooth converter") or (MsgContains(message, "lost") and state >= 1) then
			player:addItem(T.DEVICE, 1)
			T.kv(player):set("device-parts", 0)
			say("Lost it? I still have the old frame of another device. Here, but you will have to mount all the parts again.") -- ours
			return true
		elseif MsgContains(message, "mission") then
			if rankOf(player) < 3 then
				say("I only work with citizens of Rathleton.") -- ours
			elseif state == 3 then
				player:setStorageValue(S.Plague, 1)
				addVotes(player, 5) -- EN: 5 votes
				say("Eight pools of mutated glooth converted? Wonderful! That should stop the mutation for a while. Take these voices in the magistrate - and you may help me again any time, the glooth keeps mutating.") -- ours
			elseif state >= 1 then
				if player:getItemCount(T.CONVERTER) > 0 or player:getItemCount(T.FILLED) > 0 or state == 2 then
					player:setStorageValue(S.Plague, 2)
					say({
						"The converter works? Splendid! But it needs an antidote to eliminate the harmful influence of the mutated glooth. Pick a crimson crest mushroom - they grow near the purple glooth pools in the east. ...",
						"Distil it in my alchemical apparatus here and fill the vial into the converter. Then use the converter on eight pools of mutated glooth.",
					}) -- ours
				else
					say("Mount the missing {components} on the device first.") -- ours
				end
			else
				say({
					"Indeed you could help me with a little triviality. Something is happening to the {glooth} in these caves. It seems to change in a strange way. This mutation has negative side effects and must be stopped. ...",
					"Unfortunately I'm {blind} and can't fulfil some tasks any more. I need your eyes. Would you help me?",
				})
				npcHandler:setTopic(id, 51)
			end
			return true
		end
		for _, entry in ipairs(georgiaLines) do
			if MsgContains(message, entry[1]) then
				say(entry[2])
				return true
			end
		end
		return true
	end)
end

function T.missionTextBatch3(player, key)
	if key == "Statues" then
		local state = player:getStorageValue(S.Statues)
		if state >= 4 then
			return "You found out that the warlock of the Circle of the Black Sphinx was behind the glooth bandits. Elbert takes glooth capsules again."
		elseif state == 3 then
			return "You found the warlock's letter. Report to Elbert."
		elseif state == 2 then
			return "The warlock is dead. Search the shelf in his room for a proof."
		end
		local mask = T.kv(player):get("statues") or 0
		local wishes = {}
		for _, wish in ipairs({ "bless", "adorn", "feed", "entertain" }) do
			if bit.band(mask, T.STATUES[wish].bit) == 0 then
				wishes[#wishes + 1] = wish
			end
		end
		if #wishes > 0 then
			return "Find the glooth bandits' hideout in the south-western tunnels. Four statues there want to be: " .. table.concat(wishes, ", ") .. "."
		end
		return "The four statues are content. Pass the forcefield between them and find out who leads the glooth bandits."
	elseif key == "Plague" then
		local state = player:getStorageValue(S.Plague)
		if state == 3 then
			return "You converted eight pools of mutated glooth. Report to Georgia Rainbird."
		elseif state == 2 then
			return string.format("Distil a crimson crest mushroom in Georgia's alchemical apparatus, fill the converter and convert eight pools of mutated glooth: %d of 8.", T.kv(player):get("pool-count") or 0)
		end
		return "Mount five bronze gear wheels, a copper valve, a calibrated indicator gauge and a glass tube on Georgia Rainbird's strange device, then ask her for the next step."
	end
	return ""
end

-- From actions_holy_water.lua (FAMILY hook).
function T.blessStatue(player, item, target, toPosition)
	if not T.on() or not target or not target.getId or target:getId() ~= 2031 then
		return false
	end
	local at = T.STATUE_POS.bless
	if toPosition.x ~= at.x or toPosition.y ~= at.y or toPosition.z ~= at.z then
		return false
	end
	if T.pleaseStatue(player, "bless") then
		item:remove(1)
	end
	return true
end
