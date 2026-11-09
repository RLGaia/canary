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

-- ==================================================================== batch 4 (2026-11-08)
-- The Gloud Ship (Zeronex, Nicholas, Yeo - missing upstream: new NPC file -, the six NPCs of the
-- Publicity achievement) and Tending Gloothworms (Wesley). Sources: TibiaWiki BR Oramond Quest
-- (method, transcripts, screenshots matched square by square with our map: pharmacy bookcases,
-- cauldrons, data machine map), EN Oramond Quest/Spoiler (transcripts, server messages, 3 votes
-- for the mission). Neither wiki says what Wesley pays: 2 votes per daily routine (ours). Our
-- map has one steel spider and no glooth cauldron objects: spiders are added at startup in the
-- Glooth Factory building (BR 33551,31928,7) and the cauldrons are the pipe machines of the
-- building east of the pharmacy (BR 33622,31945,7).

T.SILK, T.SPOOL, T.STRONG_CLOTH, T.FORK = 21819, 21820, 21873, 21877
T.GLOO, T.AIRTIGHT_GLOO, T.AIRTIGHT_CLOTH = 21803, 21876, 21870
T.GAS_BAG, T.FULL_GAS_BAG = 21880, 21881
T.FARINA, T.VINEGAR, T.ESSENCE, T.PLASMA, T.RUBBISH = 21841, 21872, 21839, 21840, 3109
T.LEATHER, T.SHRIMP = 10279, 3581
T.SILK_NEED, T.HARVEST_NEED, T.LEATHER_NEED, T.SHRIMP_NEED = 15, 20, 20, 10
T.GLOUD_VOTES, T.GLOUD_TASK_VOTES, T.WORM_VOTES = 3, 1, 2

-- S.Gloud: 1 cloth, 2 gloo, 3 gas bag, 4 done; 5/6/7 = task harvesting/concocting/retrieving.
T.GLOUD_TASKS = { harvesting = 5, concocting = 6, retrieving = 7 }

local function gloud(player)
	return player:getStorageValue(S.Gloud)
end

function T.harvesting(player)
	local state = gloud(player)
	return state == 1 or state == 5
end

function T.cooking(player)
	local state = gloud(player)
	return state == 2 or state == 6
end

function T.retrieving(player)
	local state = gloud(player)
	return state == 3 or state == 7
end

local function advance(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

-- ------------------------------------------------------------------ strong cloth

T.spiderCooldown = {}

-- The milking fork used on a steel spider at pos.
function T.milkSpider(player, pos)
	if not T.harvesting(player) then
		advance(player, "The spider scuttles away from the fork.") -- ours
		return true
	end
	local key = player:getId() .. ":" .. pos.x .. "," .. pos.y .. "," .. pos.z
	if (T.spiderCooldown[key] or 0) > os.time() then
		advance(player, "This spider has no silk left right now. Give it a minute.") -- ours (BR: 1 minute per spider)
		return true
	end
	T.spiderCooldown[key] = os.time() + 60
	player:addItem(T.SILK, 1)
	advance(player, "With much care, you extracted some steel spider silk.")
	return true
end

-- Steel spider silk used on the yarn-winding winch.
function T.windYarn(player)
	if player:getItemCount(T.SILK) < T.SILK_NEED then
		advance(player, string.format("You need %d pieces of steel spider silk to spin a spool of yarn.", T.SILK_NEED)) -- ours
		return true
	end
	player:removeItem(T.SILK, T.SILK_NEED)
	player:addItem(T.SPOOL, 1)
	advance(player, "You have spun the yarn on a spool. Now you can weave a cloth.")
	return true
end

-- The spool used on a weaving loom.
function T.weaveCloth(player, spool)
	spool:remove(1)
	player:addItem(T.STRONG_CLOTH, 1)
	advance(player, "You have woven a fine strong cloth.")
	return true
end

-- ------------------------------------------------------------------ airtight gloo

-- The pharmacy bookcases (BR screenshots matched with our map).
T.SHELVES = {
	{ pos = Position(33614, 31939, 6), item = T.FARINA, name = "glooth farina" },
	{ pos = Position(33614, 31939, 5), item = T.ESSENCE, name = "pink gloud essence" },
	{ pos = Position(33616, 31939, 5), item = T.VINEGAR, name = "glooth vinegar" },
}

-- A pharmacy bookcase used; false lets it open as usual.
function T.searchShelf(player, pos)
	for _, shelf in ipairs(T.SHELVES) do
		if shelf.pos.x == pos.x and shelf.pos.y == pos.y and shelf.pos.z == pos.z then
			if not T.cooking(player) or player:getItemCount(shelf.item) > 0 then
				return false
			end
			player:addItem(shelf.item, 1)
			advance(player, "You have found " .. shelf.name .. ".")
			return true
		end
	end
	return false
end

-- The glooth cauldrons: the middle of the pipe machines east of the pharmacy, both floors.
function T.isCauldron(pos)
	return pos.x >= 33621 and pos.x <= 33623 and ((pos.y == 31945 and pos.z == 7) or (pos.y == 31940 and pos.z == 6))
end

T.BREW_NEEDS = {
	[T.VINEGAR] = "The concoction is too thick. Liquefy it with glooth vinegar.",
	[T.FARINA] = "The concoction does not stick! Sequester it with glooth farina.",
	[T.ESSENCE] = "The concoction loses its colour. Tint it with pink gloud essence.", -- ours (the wikis lack this message)
}
T.BREW_ORDER = { T.VINEGAR, T.FARINA, T.ESSENCE }

-- The bottle of gloo used on a cauldron.
function T.startBrew(player, bottle)
	local kv = T.kv(player)
	if not T.cooking(player) then
		advance(player, "You have no reason to cook gloo right now.") -- ours
		return true
	end
	if (kv:get("brew") or 0) > 0 then
		advance(player, "Your gloo is already cooking. Keep stirring the cauldron.") -- ours
		return true
	end
	bottle:remove(1)
	kv:set("brew", math.random(5, 7)) -- stirs left (ours)
	kv:set("brew-need", 0)
	advance(player, "<gloop> <gloop gloop>")
	return true
end

-- The cauldron used. false = nothing cooking (no message of ours).
function T.stirBrew(player)
	local kv = T.kv(player)
	local left = kv:get("brew") or 0
	if left <= 0 then
		return false
	end
	local need = kv:get("brew-need") or 0
	if need ~= 0 then
		advance(player, T.BREW_NEEDS[need])
		return true
	end
	left = left - 1
	if left <= 0 then
		kv:set("brew", 0)
		player:addItem(T.AIRTIGHT_GLOO, 1)
		advance(player, "You have retrieved some airtight gloo.")
		return true
	end
	kv:set("brew", left)
	local roll = math.random(100)
	if roll <= 35 then
		need = T.BREW_ORDER[math.random(#T.BREW_ORDER)]
		kv:set("brew-need", need)
		advance(player, T.BREW_NEEDS[need])
	elseif roll <= 45 then
		player:addItem(T.PLASMA, 1)
		advance(player, "You have retrieved some glooth plasma. Maybe you should shake it to see if it settles down?")
	else
		advance(player, "<bubble> <bloop> ... <blop> <blop>")
	end
	return true
end

-- An ingredient used on a cauldron. false = nothing cooking.
function T.addIngredient(player, ingredient)
	local kv = T.kv(player)
	if (kv:get("brew") or 0) <= 0 then
		return false
	end
	if (kv:get("brew-need") or 0) ~= ingredient:getId() then
		advance(player, "The concoction doesn't need that right now.") -- ours
		return true
	end
	ingredient:remove(1)
	kv:set("brew-need", 0)
	advance(player, "The concoction bubbles contentedly. Keep stirring.") -- ours
	return true
end

-- The glooth plasma used (EN: it never settles, it only decomposes in the end).
function T.shakePlasma(player, plasma)
	if math.random(2) == 1 then
		advance(player, "Nothing happens. Maybe if you shook it a little more?")
	else
		plasma:transform(T.RUBBISH)
		advance(player, "The mix decomposes. Try to cook up some gloo at the cauldrons again.")
	end
	return true
end

-- ------------------------------------------------------------------ gloud (Zeronex's laboratory)

-- Glooth data machines are two squares; pos = the east square, the one to use (EN).
T.LAB_MACHINES = {
	{ n = 1, pos = Position(33394, 31967, 12) }, -- north
	{ n = 2, pos = Position(33385, 31968, 12) }, -- north-west
	{ n = 3, pos = Position(33381, 31979, 12) }, -- west
}
T.LAB_CENTRE = Position(33395, 31981, 12) -- the gas bag machine (BR map: red circle)
T.CALIBRATION_USES = 3 -- ours (EN: "repeatedly")

local function onMachine(pos, at)
	return pos.z == at.z and pos.y == at.y and (pos.x == at.x or pos.x == at.x - 1)
end

function T.isLabCentre(pos)
	return onMachine(pos, T.LAB_CENTRE)
end

-- A glooth data machine of the lab used; false = not one of them or no task.
function T.useLabMachine(player, pos)
	for _, machine in ipairs(T.LAB_MACHINES) do
		if onMachine(pos, machine.pos) then
			if not T.retrieving(player) then
				return false
			end
			local kv = T.kv(player)
			local key = "calibration-" .. machine.n
			local uses = (kv:get(key) or 0) + 1
			if uses >= T.CALIBRATION_USES then
				kv:set(key, T.CALIBRATION_USES)
				advance(player, string.format("+++ 0%d REPORT --- CALIBRATION COMPLETE --- VALUES IDEAL +++", machine.n))
			else
				kv:set(key, uses)
				advance(player, string.format("+++ 0%d REPORT --- CALIBRATING --- VALUES DEVIATING +++", machine.n)) -- ours
			end
			return true
		end
	end
	return false
end

function T.labCalibrated(player)
	local kv = T.kv(player)
	for _, machine in ipairs(T.LAB_MACHINES) do
		if (kv:get("calibration-" .. machine.n) or 0) < T.CALIBRATION_USES then
			return false
		end
	end
	return true
end

-- The gas bag used on the centre machine.
function T.fillGasBag(player, bag)
	if not T.labCalibrated(player) then
		advance(player, "Nothing comes out of the machine. The three machines on the walls are not calibrated yet.") -- ours
		return true
	end
	local kv = T.kv(player)
	for _, machine in ipairs(T.LAB_MACHINES) do
		kv:set("calibration-" .. machine.n, 0)
	end
	bag:transform(T.FULL_GAS_BAG)
	advance(player, "You fill some of the gloud into the gas bag.")
	return true
end

-- ------------------------------------------------------------------ Zeronex

local zeronexLines = {
	{ "process", "Maybe the mixture will work this time! I am sure it can only be a minuscule variation that needs to take place. Then the {gloud}-filled balloon should be lifted UP, and we achieve non-magical levitation, or airborne travel!" },
	{ "gloud", "My own invention to indicate gaseous glooth, made up from the words 'glooth' and 'cloud' - gloud. Gloud will {revolutionise} research, travel, and everything else!" },
	{ "revolutionise", {
		"Don't you see the implications? Airborne travel would no longer confine us to the boundaries of Oramond with its dangerous cliffs and this devious fog! ...",
		"The possibilities to travel, to observe and to learn from a higher vantage point are sheer endless! ...",
		"And I shall be the one to give this to the world. It will redeem the name of Pierre Zeronex, and show everyone they were wrong to exclude me from my research, to forbid me the use of my laboratory!",
	} },
	{ "job", { "Well, it's not so much as a job, but rather a vocation. I am a research scientist by trade. ...", "I research the use of heavy glooth gases, or Gloud, as I call it. A rather {dangerous} job, at that." } },
	{ "dangerous", "I had to abandon the old laboratory after the last ...{incident}." },
	{ "name", "Professor Pierre Zeronex. You may have heard of me. Hopefully not." }, -- ours
}

local GLOUD_START = {
	"Splendid! Now, first, I need a durable and tough airtight cloth. The tissue must be strong and flexible. Previous experiments with existing cloth and weaving have proven ineffective; I need a new thread. ...",
	"There is a specialist for cloth in town; he once boasted to know of a very strong cloth but wouldn't say more to me on the subject. Nicholas Cavendish is his name. Ask him, but please don't mention my name.",
}

T.GLOUD_TASK_TEXT = {
	harvesting = "Wonderful! I need more steel spider silk for the next balloons. Milk the spiders with this fork and bring me 20 samples of their silk.", -- ours
	concocting = "Wonderful! Cook some more airtight gloo for me. Here is a bottle of gloo to start with - and another airtight cloth to show around. Mind the ingredients from the pharmacy!", -- ours
	retrieving = "Wonderful! I need a fresh gloud sample. Calibrate the three machines on the walls of my laboratory and fill this gas bag at the centre machine.", -- ours
}

function T.zeronexGreeting(player)
	local state = gloud(player)
	if (state >= 1 and state <= 3) or state >= 5 then
		return "Hmm? Oh yes, hello. Please, what do you have to report? Any progress?"
	end
	return "Hmm? Oh yes, hello. Please, take a seat. I am in the middle of a very interesting {process}."
end

-- Reports the mission step or task; returns true when something was handed in.
local function zeronexReport(player, say)
	local state = gloud(player)
	if state == 1 and player:getItemCount(T.STRONG_CLOTH) > 0 then
		player:removeItem(T.STRONG_CLOTH, 1)
		player:setStorageValue(S.Gloud, 2)
		say({
			"This is the cloth? Wonderful! Ah, it looks very promising, very promising indeed! Now, on to the next step - making the cloth airtight. We need some kind of adhesive, or glue. ...",
			"I have heard rumours of a very strong glue, used for making boats watertight. I believe that there is a fisherman in the harbour, Yeo, who might know more on this subject. Please visit him.",
		})
		return true
	elseif state == 2 and player:getItemCount(T.AIRTIGHT_GLOO) > 0 then
		player:removeItem(T.AIRTIGHT_GLOO, 1)
		player:addItem(T.AIRTIGHT_CLOTH, 1)
		player:addItem(T.GAS_BAG, 1)
		T.kv(player):set("brew", 0)
		player:setStorageValue(S.Gloud, 3)
		say({
			"Yeees, yeeees.... very promising indeed. Let's try it out - voilà! ...",
			"This is a prototype, of course. We'll put it to the test. I'll keep my sample and you - in fact, you can keep this prototype and maybe show it to some people and see how they react... for publicity, you might say. ...",
			"Now, on to the last step! I need you to go to my lab. It is underground, far southwest in the Glooth Factory. Calibrate the three glooth machines on the wall, according to this - <whisper whisper whisper> ...",
			"Then, when all three machines are calibrated thusly, use this special gas bag at the centre machine - it will dispense some gloud into it. Then bring the filled gas bag to me and you'll receive your reward!",
		})
		return true
	elseif state == 3 and player:getItemCount(T.FULL_GAS_BAG) > 0 then
		player:removeItem(T.FULL_GAS_BAG, 1)
		player:setStorageValue(S.Gloud, 4)
		addVotes(player, T.GLOUD_VOTES)
		say({
			"Yes! YES! Finally a fresh gloud sample! Give it here. This is the moment of truth for me, and of reward for you, my friend! Here, take this voting right, you earned it. ...",
			"And if you would like to asisst me further, don't hesitate to call in at any time!",
		})
		return true
	end
	local done = { [5] = { T.SILK, T.HARVEST_NEED }, [6] = { T.AIRTIGHT_GLOO, 1 }, [7] = { T.FULL_GAS_BAG, 1 } }
	local task = done[state]
	if task and player:getItemCount(task[1]) >= task[2] then
		player:removeItem(task[1], task[2])
		player:setStorageValue(S.Gloud, 4)
		addVotes(player, T.GLOUD_TASK_VOTES)
		say("Splendid, splendid! This brings me one step closer to the first gloud ship. Here, take this voting right. And don't hesitate to call in again!") -- ours
		return true
	end
	return false
end

local function zeronexReminder(player)
	local state = gloud(player)
	if state == 1 then
		return "I still need that strong cloth. Ask Nicholas Cavendish about a {very strong cloth} - but don't mention my name!" -- ours
	elseif state == 2 then
		return "I still need the {airtight gloo}. Yeo the fisherman knows of a strong glue." -- ours
	elseif state == 3 then
		return "The gas bag is still empty? Calibrate the three machines on the walls of my laboratory, far southwest in the Glooth Factory, then fill the bag at the centre machine." -- ours
	elseif state == 5 then
		return string.format("I still need %d samples of steel spider silk.", T.HARVEST_NEED) -- ours
	elseif state == 6 then
		return "I still need a bottle of airtight gloo." -- ours
	elseif state == 7 then
		return "I still need a full gas bag from my laboratory." -- ours
	end
	return "If you would like to assist me further: I always need someone for {harvesting} spider silk, {concocting} gloo or {retrieving} gloud." -- ours
end

function T.setupZeronex(npcHandler)
	npcHandler:setMessage(MESSAGE_FAREWELL, "<absentmindedly> Err yes, good bye!")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "<absentmindedly> Err yes, good bye!")
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
		npcHandler:setMessage(MESSAGE_GREET, T.zeronexGreeting(Player(creature)))
		return true
	end)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not T.on() or not player or not npcHandler:checkInteraction(npc, creature) then
			return true
		end
		local id = player:getId()
		local say = function(text)
			npcHandler:say(text, npc, creature)
		end
		local state = gloud(player)
		local topic = npcHandler:getTopic(id)
		if topic == 61 then
			npcHandler:setTopic(id, 0)
			if MsgContains(message, "yes") then
				player:setStorageValue(S.Gloud, 1)
				openQuestLine(player)
				say(GLOUD_START)
			else
				say("Pity. Science waits for no one, you know.") -- ours
			end
			return true
		end
		if MsgContains(message, "airtight cloth") and state >= 3 then
			if player:getItemCount(T.AIRTIGHT_CLOTH) > 0 then
				say("You still have a prototype. Show it around - for publicity!") -- ours
			else
				player:addItem(T.AIRTIGHT_CLOTH, 1)
				say("Of course, take another prototype. Show it to some people and see how they react - for publicity!") -- ours
			end
			return true
		end
		for word, value in pairs(T.GLOUD_TASKS) do
			if MsgContains(message, word) and state >= 4 then
				if state == value then
					if not zeronexReport(player, say) then
						say(zeronexReminder(player))
					end
				elseif state ~= 4 then
					say("One thing after the other! Finish your current task first. " .. zeronexReminder(player)) -- ours
				else
					player:setStorageValue(S.Gloud, value)
					if word == "harvesting" and player:getItemCount(T.FORK) < 1 then
						player:addItem(T.FORK, 1)
					elseif word == "concocting" then
						player:addItem(T.GLOO, 1)
						player:addItem(T.AIRTIGHT_CLOTH, 1)
						T.kv(player):set("brew", 0)
					elseif word == "retrieving" then
						player:addItem(T.GAS_BAG, 1)
					end
					say(T.GLOUD_TASK_TEXT[word])
				end
				return true
			end
		end
		if MsgContains(message, "incident") then
			if state < 1 then
				say("Well, the concoction was nearly right. Nearly. Unfortunately, I had miscalculated the effect that the pressurised gloothine would have on the gaseous mixture and the tank exploded... I am sorry, am I boring you?")
				if rankOf(player) >= 3 then
					npcHandler:setTopic(id, 61)
				end
			else
				say("Let's not talk about that. Let's talk about your progress!") -- ours
			end
			return true
		end
		if MsgContains(message, "mission") or MsgContains(message, "report") or MsgContains(message, "airtight gloo") or MsgContains(message, "progress") or (MsgContains(message, "yes") and state >= 1) then
			if state < 1 then
				if rankOf(player) < 3 then
					say("I need someone whom the magistrate trusts - a citizen of Rathleton. Come back when you are one.") -- ours
					return true
				end
				say({
					"Ah, I am on the brink of achieving greatness! With my inventions, tomorrow might come today! ...",
					"But first, I need to perfect some unprecedented, novel things - an airtight cloth, which also requires the making of an airtight adhesive; and last but not least, a certain gaseous mixture. ...",
					"However, as my name is ill-famed, I cannot pursue my experiments in town for fear of being exiled once and for all. Will you go on the necessary errands for me?",
				})
				npcHandler:setTopic(id, 61)
			elseif not zeronexReport(player, say) then
				say(zeronexReminder(player))
			end
			return true
		end
		for _, entry in ipairs(zeronexLines) do
			if MsgContains(message, entry[1]) then
				say(entry[2])
				return true
			end
		end
		return true
	end)
end

-- ------------------------------------------------------------------ Nicholas, Yeo, Publicity

T.PUBLICITY = { yeo = 1, nicholas = 2, barazbaz = 4, alaistar = 8, fayla = 16, christine = 32 }
T.ALL_PUBLICITY = 63
local publicityLines = { -- ours
	yeo = "Airtight, eh? Made with old Yeo's gloo, I bet. Nice work, I'll show it to the fishermen.",
	nicholas = "Hm! Strong cloth, airtight... I can see where my secret went. Well, it IS exquisite work. I'll show it to my customers.",
	barazbaz = "An airtight cloth? Interesting. I will mention it to the magistrate.",
	alaistar = "Fascinating! Airtight, you say? That could keep potions fresh for ages. I'll show it around.",
	fayla = "Oh, how practical! I'll tell everyone about it.",
	christine = "Airtight? My, my. Whoever made this knows their craft. I'll pass the word.",
}

-- "airtight cloth" to one of the six NPCs; true when answered.
function T.publicitySay(npc, player, message, npcHandler, who)
	if not T.on() or not MsgContains(message, "airtight cloth") or gloud(player) < 3 then
		return false
	end
	if not npcHandler:checkInteraction(npc, player) then
		return false
	end
	local mask = T.kv(player):get("publicity") or 0
	local bitOf = T.PUBLICITY[who]
	if bit.band(mask, bitOf) ~= 0 then
		npcHandler:say("You showed me that cloth already. Very airtight, I remember.", npc, player) -- ours
		return true
	end
	if player:getItemCount(T.AIRTIGHT_CLOTH) < 1 then
		npcHandler:say("An airtight cloth? I'd like to see one.", npc, player) -- ours
		return true
	end
	player:removeItem(T.AIRTIGHT_CLOTH, 1)
	mask = bit.bor(mask, bitOf)
	T.kv(player):set("publicity", mask)
	npcHandler:say(publicityLines[who], npc, player)
	if mask == T.ALL_PUBLICITY and not player:hasAchievement("Publicity") then
		player:addAchievement("Publicity")
	end
	return true
end

-- For NPCs without their own callback (Fayla, Christine).
function T.setupPublicity(npcHandler, who)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if player then
			T.publicitySay(npc, player, message, npcHandler, who)
		end
		return true
	end)
end

function T.setupNicholas(npcHandler)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not T.on() or not player then
			return true
		end
		if T.publicitySay(npc, player, message, npcHandler, "nicholas") then
			return true
		end
		if not MsgContains(message, "strong cloth") or not npcHandler:checkInteraction(npc, creature) then
			return true
		end
		local say = function(text)
			npcHandler:say(text, npc, creature)
		end
		local kv = T.kv(player)
		if gloud(player) < 1 then
			say("Strong cloth? All my cloth is strong, my friend. Ask me for a {trade}.") -- ours
		elseif kv:get("nicholas") == 2 then
			if player:getItemCount(T.FORK) < 1 then
				player:addItem(T.FORK, 1)
				say("Lost the milking fork? Here, take another one - and keep your voice down!") -- ours
			else
				say("Pshshsht! Steel spider silk, yarn, then a weaving loom. That's all I will say!") -- ours
			end
		elseif kv:get("nicholas") == 1 and player:getItemCount(T.LEATHER) >= T.LEATHER_NEED then
			player:removeItem(T.LEATHER, T.LEATHER_NEED)
			player:addItem(T.FORK, 1)
			kv:set("nicholas", 2)
			say({
				"Quiet, please. This must not become common knowledge, you know. Oh - that's the crocodile leather? It's even more beautiful than I thought! Only look at the texture! Marvellous! And the - but I am getting carried away. ...",
				"Now, here's the secret - to make a really strong cloth, you need a special kind of silk - steel spider silk. The spiders live in the dark and dank of abandoned buildings, cellars and sewers, so be wary of other, more dangerous, monsters! ...",
				"Use this milking fork to harvest their silk. Once you have the spiders' raw silk, first make it into yarn and then spin the yarn on a weaving loom - and voilà! you have a strong cloth. ...",
				"How you achieve the latter steps is none of my business - you know a valuable secret already. ...",
				"Look for some leftover looms in the workshops quarter to spin yarn and cloth; all my looms are in operation around the clock and can't be spared.",
			})
		elseif kv:get("nicholas") == 1 then
			say("Quiet, please. This must not become common knowledge, you know. 20 pieces of crocodile leather, that's my price.") -- ours
		else
			kv:set("nicholas", 1)
			say({
				"Pshshsht! Keep your voice down! This is a well-kept trade secret, you know! I'm not about to just confer it to anyone just like that! ...",
				"We may come to a deal, though. I have heard of a fancy, exotic animal skin that would make the most extravagant cloth, if only I could get hold of it! ...",
				"I am talking of crocodile leather, of course. A most exquisite thing! I want 20 pieces of crocodile leather in exchange for my most valued expertise here.",
			})
		end
		return true
	end)
end

function T.yeoGreeting(player)
	if player:getItemCount(T.SHRIMP) >= T.SHRIMP_NEED then
		return "Mhmmm, what a lovely smell of shrimp."
	end
	return "Hrm?"
end

function T.setupYeo(npcHandler)
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
		npcHandler:setMessage(MESSAGE_GREET, T.yeoGreeting(Player(creature)))
		return true
	end)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not T.on() or not player then
			return true
		end
		if T.publicitySay(npc, player, message, npcHandler, "yeo") then
			return true
		end
		if not npcHandler:checkInteraction(npc, creature) then
			return true
		end
		local id = player:getId()
		local say = function(text)
			npcHandler:say(text, npc, creature)
		end
		local wantsGloo = T.cooking(player) and player:getItemCount(T.GLOO) < 1 and player:getItemCount(T.AIRTIGHT_GLOO) < 1
		if npcHandler:getTopic(id) == 71 then
			npcHandler:setTopic(id, 0)
			if MsgContains(message, "yes") and wantsGloo and player:getItemCount(T.SHRIMP) >= T.SHRIMP_NEED then
				player:removeItem(T.SHRIMP, T.SHRIMP_NEED)
				player:addItem(T.GLOO, 1)
				T.kv(player):set("brew", 0)
				say({
					"Perfect. Here's your gloo, friend. Now, listen closely. You want it even more than watertight - airtight, right? Then you need to cook it up some more. There's glooth cauldrons next to the old pharmacist building that everyone can use. ...",
					"Just pay attention to what the mixture needs. Methinks it might be necessary to add some glooth vinegar or some glooth farina, depending on the cooking process. ...",
					"All needed ingredients can be found in the pharmacist building - third building left from the stairs that lead to uptown. Good luck with your experiment, friend!",
				})
			elseif MsgContains(message, "yes") then
				say("Hrm. I don't see 10 shrimp.") -- ours
			else
				say("Hrm. Then off with you.") -- ours
			end
			return true
		end
		if MsgContains(message, "strong glue") or MsgContains(message, "glue") then
			say("Ah, you need some kind of really sticky glue? Impervious to water, too? That's a job for old Yeo. Yeah, I can make you some {gloo}.")
		elseif MsgContains(message, "gloo") then
			if not wantsGloo then
				say("Gloo? You don't need any gloo now, friend.") -- ours
			elseif player:getItemCount(T.SHRIMP) >= T.SHRIMP_NEED then
				say("Yep, you can have some gloo in exchange for 10 shrimp. Did you bring me those 10 shrimp?")
				npcHandler:setTopic(id, 71)
			else
				say("See here, I'm hungry. If I make gloo, I can't take care of cooking. That means you need to fetch me something. I want shrimp, 10 fresh shrimp at least! Bring me those and I'll give you a vial of gloo.")
			end
		elseif MsgContains(message, "job") then
			say("Fishing. And making {gloo} for the boats, now and then.") -- ours
		elseif MsgContains(message, "name") then
			say("Yeo.") -- ours
		end
		return true
	end)
end

-- ------------------------------------------------------------------ Tending Gloothworms

T.WORM_MACHINE = Position(33648, 31876, 12) -- east square of the farm's data machine (EN 131.112|124.132)
T.FUNNELS = {
	Position(33644, 31852, 12), Position(33644, 31861, 12), Position(33650, 31861, 12), Position(33653, 31869, 12),
	Position(33656, 31861, 12), Position(33661, 31852, 12), Position(33661, 31861, 12),
}
T.FARM_BOX = { 33636, 31846, 33665, 31880, 12 }
T.TUBES = { 21826, 21827, 21828, 21829, 21844, 21845 }
T.HOE, T.RAKE, T.POWDER, T.WATER = 3455, 3452, 21837, 21838
T.FUNGUS, T.FUNGUS_SHREDDED = 21836, 21842

T.WORM_TASKS = {
	{
		key = "calibrate",
		name = "Calibrating the Irrigation Funnels",
		need = 7,
		assign = "The ground has taken up too much water! Calibrate all of the 7 irrigation funnels in the glooth farm.",
		done = "Ah, very good. The funnel values have returned to normal.",
		log = "Calibrate all 7 irrigation funnels in the gloothworm farm north-east of Wesley",
	},
	{
		key = "water",
		name = "Distilled Water",
		need = 7,
		assign = {
			"The gloothworms need distilled water! Use one of the distil machines here in the cave to get pure water. Then pour some drops of the pure water into the 7 irrigation funnels. ...",
			"Remember to use all 7 irrigation funnels! We need the water to be spread around evenly.",
		},
		done = "Ah, very good. Water supply values of the gloothworm tubes are back to normal. Well done.",
		log = "Fill a vial at a water distilling machine west of Wesley and pour it into all 7 irrigation funnels of the farm",
	},
	{
		key = "feed",
		name = "Feeding the Worms",
		need = 5,
		tool = T.HOE,
		assign = {
			"The gloothworms need feeding! It's a very strict mushroom diet. Go to the cave southeast of here and shred some of the mushrooms into flakes. You need exactly 5 doses. Here, take this hoe to do it. ...",
			"When you have 5 doses of fungus powder, scatter all 5 doses on the gloothworm tubes in the farm. Return to me after that.",
		},
		done = "Ah, very good. My data reveals the gloothworms are correctly fed. I'll take the hoe back now.",
		lost = "Hmm, the gloothworms are correctly fed. Good. But I still need that hoe back. Please hand it over. If you lost it, buy a new one at {Maro}.", -- ours, after the rake line
		log = "Shred edible rock fungi with the hoe in the cave south-east of Wesley and scatter 5 doses of fungus powder on the gloothworm tubes",
	},
	{
		key = "rake",
		name = "Rake Away",
		need = 10,
		tool = T.RAKE,
		assign = {
			"There's too much excremental floss around the gloothworm tubes! Quick, before they choke under it - use this rake on the gloothworm tubes! ...",
			"Use it evenly, on at least at 10 gloothworm tube spots! The floss must be raked away.",
		},
		done = "Ah, I see toxic values are back to uncritical. Swell!",
		lost = "Hmm, toxic values are returning to uncritical. Good. But I still need that rake back. Please hand it over. If you lost it, buy a new one at {Maro}.",
		log = "Rake the excremental floss away from 10 gloothworm tubes in the farm",
	},
}

local function worms(player)
	return player:getStorageValue(S.Gloothworms)
end

function T.wormTask(player)
	local state = worms(player)
	if state >= 3 and state <= 6 then
		return T.WORM_TASKS[state - 2]
	end
	return nil
end

function T.dayKey()
	return os.date("%Y-%m-%d", os.time() - 6 * 60 * 60) -- days start at 06:00 (ours, like the Rathleton periods)
end

-- Starts a new day of tasks when the date changed.
local function wormDay(player)
	local kv = T.kv(player)
	if kv:get("worm-day") ~= T.dayKey() then
		kv:set("worm-day", T.dayKey())
		kv:set("worm-done", 0)
		kv:set("worm-bits", 0)
		if worms(player) == 7 then
			player:setStorageValue(S.Gloothworms, 1)
			return true
		end
	end
	return false
end

local function wormProgress(player)
	return T.kv(player):get("worm-count") or 0
end

-- Marks one spot of the current task; false when it was counted already.
local function wormSpot(player, pos)
	local kv = T.kv(player)
	local key = "[" .. pos.x .. "," .. pos.y .. "," .. pos.z .. "]"
	local spots = kv:get("worm-spots") or ""
	if spots:find(key, 1, true) then
		return false
	end
	kv:set("worm-spots", spots .. key)
	kv:set("worm-count", (kv:get("worm-count") or 0) + 1)
	return true
end

-- The farm's data machine used; false = another data machine.
function T.readWormMachine(player, pos)
	if not onMachine(pos, T.WORM_MACHINE) then
		return false
	end
	wormDay(player)
	if worms(player) == 1 then
		player:setStorageValue(S.Gloothworms, 2)
		advance(player, "--- ALERT --- 0001110010110011001 --- ALERT ---")
	else
		advance(player, "--- STATUS --- 0000000000000000000 --- STATUS ---") -- ours
	end
	return true
end

local function funnelIndex(pos)
	for i, at in ipairs(T.FUNNELS) do
		if at.x == pos.x and at.y == pos.y and at.z == pos.z then
			return i
		end
	end
	return nil
end

local function taskDone(player, task, text)
	if wormProgress(player) >= task.need then
		advance(player, text)
	end
end

-- An irrigation funnel used (calibrate) or the distilled water used on it (water).
function T.useFunnel(player, pos, water)
	local task = T.wormTask(player)
	if not funnelIndex(pos) or not task or task.key ~= (water and "water" or "calibrate") then
		return false
	end
	if not wormSpot(player, pos) then
		advance(player, water and "This funnel has its water already." or "This funnel is already calibrated.") -- ours
		return true
	end
	if water then
		advance(player, "You pour a measured amount of pure water down the funnel.")
	else
		advance(player, "<squeak> <scrrt> The funnel is correctly calibrated.")
	end
	taskDone(player, task, "That was the last irrigation funnel. Return to Wesley.") -- ours
	return true
end

-- A water distilling machine used.
function T.distilWater(player)
	local task = T.wormTask(player)
	if not task or task.key ~= "water" then
		return false
	end
	if player:getItemCount(T.WATER) > 0 then
		advance(player, "You already have a vial of distilled water.") -- ours
	else
		player:addItem(T.WATER, 1)
		advance(player, "You fill a vial with distilled water.") -- ours
	end
	return true
end

-- The hoe used on an edible rock fungus: true when shredded (the caller makes it regrow),
-- false when the player has enough, nil when no feeding task.
function T.shredFungus(player)
	local task = T.wormTask(player)
	if not task or task.key ~= "feed" then
		return nil
	end
	if player:getItemCount(T.POWDER) + wormProgress(player) >= task.need then
		advance(player, "You have enough fungus powder for the gloothworms.") -- ours
		return false
	end
	player:addItem(T.POWDER, 1)
	advance(player, "You shred the fungus into a dose of fungus powder.") -- ours
	return true
end

function T.isFarmTube(target, pos)
	local b = T.FARM_BOX
	return target and target.getId and table.contains(T.TUBES, target:getId()) and pos.z == b[5] and pos.x >= b[1] and pos.x <= b[3] and pos.y >= b[2] and pos.y <= b[4]
end

-- Fungus powder used on a gloothworm tube.
function T.feedTube(player, powder, target, pos)
	local task = T.wormTask(player)
	if not task or task.key ~= "feed" or not T.isFarmTube(target, pos) then
		return false
	end
	if not wormSpot(player, pos) then
		advance(player, "These gloothworms have been fed already. Try another tube.") -- ours
		return true
	end
	powder:remove(1)
	advance(player, "You scatter a dose of fungus powder on the gloothworm tube.") -- ours
	taskDone(player, task, "That was the last dose. Return to Wesley.") -- ours
	return true
end

-- From rake.lua (FAMILY hook): the rake used on a gloothworm tube.
function T.rakeTube(player, target, pos)
	local task = T.wormTask(player)
	if not T.on() or not task or task.key ~= "rake" or not T.isFarmTube(target, pos) then
		return false
	end
	if not wormSpot(player, pos) then
		advance(player, "This tube is clean already. Try another one.") -- ours
		return true
	end
	if wormProgress(player) >= task.need then
		advance(player, "That's the last of the excrement floss you had to rake away. Return to Wesley to check the gloothworm data.")
	else
		advance(player, "You rake away the excremental floss.") -- ours
	end
	return true
end

function T.wesleyGreeting(player)
	local state = worms(player)
	if state < 1 then
		return "Hi! Are you the new assistant? No? Well then, I'll make you an honorary assistant."
	elseif state >= 2 and state <= 6 then
		return "Ah, hello! Well, what is your {report}?"
	end
	return "Ah, my faithful assistant! Your help is very welcome."
end

local function wesleyReport(player, say)
	local state = worms(player)
	local kv = T.kv(player)
	if state == 1 then
		say("Please read the analysis code on the gloothworm surveillance machine northeast of here, and then report to me.")
		return
	elseif state == 2 then
		local free = {}
		local bits = kv:get("worm-bits") or 0
		for i = 1, #T.WORM_TASKS do
			if bit.band(bits, 2 ^ (i - 1)) == 0 then
				free[#free + 1] = i
			end
		end
		local index = free[math.random(#free)]
		local task = T.WORM_TASKS[index]
		kv:set("worm-spots", "")
		kv:set("worm-count", 0)
		if task.tool and player:getItemCount(task.tool) < 1 then
			player:addItem(task.tool, 1)
		end
		player:setStorageValue(S.Gloothworms, index + 2)
		say(task.assign)
		return
	end
	local task = T.wormTask(player)
	if not task then
		say("Ask me for a {mission} first.") -- ours
		return
	end
	if wormProgress(player) < task.need then
		say(string.format("The data hasn't changed much yet. %s: %d of %d done.", task.name, wormProgress(player), task.need)) -- ours
		return
	end
	if task.tool then
		if player:getItemCount(task.tool) < 1 then
			say(task.lost)
			return
		end
		player:removeItem(task.tool, 1)
	end
	if task.key == "water" and player:getItemCount(T.WATER) > 0 then
		player:removeItem(T.WATER, player:getItemCount(T.WATER))
	end
	local done = (kv:get("worm-done") or 0) + 1
	kv:set("worm-done", done)
	kv:set("worm-bits", bit.bor(kv:get("worm-bits") or 0, 2 ^ (state - 3)))
	if done >= 3 then
		player:setStorageValue(S.Gloothworms, 7)
		addVotes(player, T.WORM_VOTES)
		say({
			task.done .. " Well, that's about all for now. ...",
			"I need to work on the surveillance machines for a little, so you can take a break for a while. Here's your reward!",
		})
	else
		player:setStorageValue(S.Gloothworms, 1)
		say(task.done .. " Please go to the northern glooth surveillance machine to find out what else needs doing.")
	end
end

function T.setupWesley(npcHandler)
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
		local player = Player(creature)
		wormDay(player)
		npcHandler:setMessage(MESSAGE_GREET, T.wesleyGreeting(player))
		return true
	end)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not T.on() or not player or not npcHandler:checkInteraction(npc, creature) then
			return true
		end
		local say = function(text)
			npcHandler:say(text, npc, creature)
		end
		wormDay(player)
		local state = worms(player)
		if MsgContains(message, "mission") or MsgContains(message, "task") then
			if rankOf(player) < 3 then
				say("I only take citizens of Rathleton as assistants. The gloothworms are too precious.") -- ours
			elseif state == 7 then
				say("That's all for today. The gloothworms are fine for now - come back tomorrow.") -- ours
			elseif state < 1 then
				player:setStorageValue(S.Gloothworms, 1)
				openQuestLine(player)
				say({
					"So you'll assist me? Great! Okay. You will look after the gloothworms - find out what they need and then do the associated task. ...",
					"A daily routine implies at least three different tasks done. To receive a task, take a look at the gloothworm surveillance machine in the northern cave and then tell me what it says.",
				})
			elseif state == 1 then
				say({
					"You know what to do - find out what the gloothworms need and then do the associated task. ...",
					"Take a look at the gloothworm surveillance machine in the northern cave and then tell me what it says.",
				})
			elseif state == 2 then
				say("What did the machine say? Give me your {report}.") -- ours
			else
				say("First finish your task, then give me your {report}.") -- ours
			end
			return true
		elseif MsgContains(message, "report") then
			if rankOf(player) < 3 or state < 1 or state == 7 then
				say("Report? You are not my assistant today.") -- ours
			else
				wesleyReport(player, say)
			end
			return true
		elseif MsgContains(message, "gloothworm") or MsgContains(message, "farm") then
			say("Gloothworms produce the glooth that keeps this city running. They are delicate creatures - water, food, cleanliness, everything must be just right.") -- ours
			return true
		elseif MsgContains(message, "job") then
			say("I'm a farmer. A gloothworm farmer.") -- ours
			return true
		elseif MsgContains(message, "maro") then
			say("Maro runs the tool shop in town. He sells rakes and hoes.") -- ours
			return true
		end
		return true
	end)
end

function T.missionTextBatch4(player, key)
	if key == "Gloud" then
		local state = gloud(player)
		if state == 1 then
			local kv = T.kv(player)
			if kv:get("nicholas") == 2 then
				return string.format("Milk steel spiders in the Glooth Factory building with Nicholas' fork (%d silk so far), spin %d silk on a yarn-winding winch and weave the yarn on a weaving loom in the room below Zeronex. Bring the strong cloth to Zeronex.", player:getItemCount(T.SILK), T.SILK_NEED)
			end
			return "Ask Nicholas Cavendish above the post office about a very strong cloth, but don't mention Zeronex. He wants 20 pieces of crocodile leather."
		elseif state == 2 then
			return "Trade 10 shrimp for a bottle of gloo with Yeo in the harbour and cook it into airtight gloo at the glooth cauldrons east of the pharmacy. The ingredients are in the pharmacy bookcases. Bring it to Zeronex."
		elseif state == 3 then
			return "Calibrate the three glooth data machines on the walls of Zeronex' laboratory, far south-west in the Underground Glooth Factory, fill the gas bag at the centre machine and bring it to Zeronex."
		elseif state == 5 then
			return string.format("Harvesting: bring %d samples of steel spider silk to Zeronex (%d so far).", T.HARVEST_NEED, player:getItemCount(T.SILK))
		elseif state == 6 then
			return "Concocting: cook a bottle of airtight gloo and bring it to Zeronex."
		elseif state == 7 then
			return "Retrieving: fill the gas bag in Zeronex' laboratory and bring it to him."
		end
		return "Zeronex has his gloud sample. He pays one voice in the magistrate for harvesting, concocting or retrieving."
	elseif key == "Gloothworms" then
		local state = worms(player)
		local task = T.wormTask(player)
		if task then
			return string.format("%s: %s (%d of %d). Then report to Wesley.", task.name, task.log, wormProgress(player), task.need)
		elseif state == 2 then
			return "You read the gloothworm surveillance machine. Report to Wesley."
		elseif state == 7 then
			return "You finished three tasks for Wesley today. He will need you again tomorrow."
		end
		return string.format("Read the gloothworm surveillance machine north-east of Wesley and report to him. Tasks done today: %d of 3.", T.kv(player):get("worm-done") or 0)
	end
	return ""
end
