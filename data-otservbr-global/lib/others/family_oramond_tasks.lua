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
		say("The city guard pays for every hundred pests you kill with a voice in the magistrate. Right now you can help with " .. huntList(player) .. ".")
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

function T.setupElbert(npcHandler)
	local C = S.Capsules
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
		local player = Player(creature)
		local state = player:getStorageValue(C)
		if T.on() and state == 1 then
			npcHandler:setMessage(MESSAGE_GREET, "Ah, there you are! Do you bring back the stolen glooth supply capsules?")
		elseif T.on() and state >= 2 then
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
		local topic = npcHandler:getTopic(playerId)
		local state = player:getStorageValue(C)
		-- the greeting asks once the job is taken (setInteraction resets the topic after a greeting)
		if topic == 0 and state >= 1 and (MsgContains(message, "yes") or MsgContains(message, "no")) then
			topic = 2
		end
		if topic == 2 and MsgContains(message, "yes") then
			npcHandler:setTopic(playerId, 0)
			local batches = math.floor(player:getItemCount(T.CAPSULE) / 10)
			if batches < 1 then
				local tainted = player:getItemCount(21816) > 0 and " Tainted ones I cannot use until they are cleansed." or ""
				npcHandler:say("You don't have ten glooth capsules with you." .. tainted, npc, creature) -- ours
				return true
			end
			player:removeItem(T.CAPSULE, batches * 10)
			addVotes(player, batches * 2)
			player:setStorageValue(C, 2)
			if state == 1 then
				npcHandler:say({
					"Great! Thank you very much for your help. The city of Rathleton is a bit safer now. If you find more of these capsules bring them back to me, too. ...",
					"But these capsules here, they seem to be filled with some kind of mutated glooth. They are tainted. If you can cleanse them somehow, I will take them.",
				}, npc, creature)
			else
				npcHandler:say("Great! Thank you very much for your help. The city of Rathleton is a bit safer now. This will get you a certain voice in the city. If you find more of these capsules bring them back to me, too.", npc, creature)
			end
		elseif topic == 2 and MsgContains(message, "no") then
			npcHandler:setTopic(playerId, 0)
			npcHandler:say("Then keep looking. The bandits in the tunnels carry them.", npc, creature) -- ours
		elseif topic == 1 and MsgContains(message, "yes") then
			npcHandler:setTopic(playerId, 0)
			player:setStorageValue(C, 1)
			openQuestLine(player)
			npcHandler:say("I'm very happy to hear that. If you have found ten glooth capsules talk to me again.", npc, creature)
		elseif topic == 1 and MsgContains(message, "no") then
			npcHandler:setTopic(playerId, 0)
			npcHandler:say("Then excuse me, I have work to do.", npc, creature) -- ours
		elseif MsgContains(message, "trouble") or MsgContains(message, "mission") or MsgContains(message, "capsules") then
			if rankOf(player) < 3 then
				npcHandler:say("This is a matter for citizens of Rathleton. Come back when the magistrate counts you among them.", npc, creature) -- ours
			elseif state >= 1 then
				npcHandler:say("Do you bring back " .. (state >= 2 and "more " or "") .. "stolen glooth supply capsules?", npc, creature)
				npcHandler:setTopic(playerId, 2)
			else
				npcHandler:say({
					"There is a band of thieves who bully the tunnels near the factory far too long. Even worse, they have stolen some important objects. ...",
					"On the one hand there were some special gauges I calibrated for Georgia Rainbird. She surely needed them for some important purpose. Further they have stolen a vast amount of ammunition for new glooth-based weapons, so called glooth ejectors. ...",
					"This ammunition consists of glooth-filled supply capsules. Would you help me and try to bring them back?",
				}, npc, creature)
				npcHandler:setTopic(playerId, 1)
			end
		end
		return true
	end)
end
