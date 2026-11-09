-- Gaia Family server: Rathleton Quest, Marvin's voting and the citizen ranks (2026-11-08,
-- asked by Rodrigo: the City Access slide at the boat let everyone into Rathleton).
--
-- Upstream Canary v3.6.1 had no ranks at all: Marvin only knew the Dark Trails "funding" vote,
-- the Oramond tasks gave votes that could not be spent, and every Citizen reward was open to
-- everyone. Sources (checked 2026-11-08): TibiaWiki BR "Rathleton Quest" and "Slime Slide"
-- (pages saved by Rodrigo), TibiaWiki EN "Rathleton Quest/Spoiler" (Marvin's lines), "Captain
-- Gulliver", "Captain Fearless", "Charles", "Captain Seahorse", "Oramond Dungeon", "The Voting
-- Results".
--
-- What changes for the players (details in FAMILY.md):
--   * Marvin: voting, learn, amount, status (+ quest log), topic, promotion, background,
--     results. Topics by rank: shortcut (everyone), dungeon (commoner), boss (inhabitant),
--     raid (citizen). Ranks after votes CAST: family numbers below (Tibia: 50/150/300/500),
--     with the achievements Rathleton Commoner/Inhabitant/Citizen/Squire.
--   * The votes of each 7-day period are counted when the period ends (every Monday at
--     06:00, server save); the most voted option of each topic then holds for the next period:
--     the active shortcut slide (minotaurs, fungi, catacombs) and the magistrate dungeon
--     (golems, minotaurs, wrath of evil) and the boss Flora offers for one voting right
--     (Bullwark, Lisa or the Glooth Fairy, since 2026-11-09) and the hourly Glooth Factory
--     raid (scripts/family/oramond_raids.lua, since 2026-11-09).
--   * Citizen rank: the City Access slide at the boat and the slide back from the city, the
--     Glooth Factory slide, and the ships Oramond <-> Edron, Venore, Port Hope, Krailos.
--
-- Switch: Family.rathletonRanks (false = upstream: open slides, weekday dungeon, old Marvin).

Family = Family or {}
Family.rathletonRanks = true

FamilyRathleton = FamilyRathleton or {}
local R = FamilyRathleton
local S = Storage.Quest.FamilyRathleton
R.S = S

local VOTING_POINTS = Storage.Quest.U10_50.OramondQuest.VotingPoints

function R.on()
	return Family.rathletonRanks == true
end

-- Votes cast needed for each rank (Tibia: 50, 150, 300, 500). Family numbers: a quarter,
-- rounded up (half until 2026-11-09, when Rodrigo halved them again).
R.ranks = {
	{ name = "commoner", votes = 13, achievement = "Rathleton Commoner" },
	{ name = "inhabitant", votes = 38, achievement = "Rathleton Inhabitant" },
	{ name = "citizen", votes = 75, achievement = "Rathleton Citizen" },
	{ name = "squire", votes = 125, achievement = "Rathleton Squire" },
}
R.COMMONER, R.INHABITANT, R.CITIZEN, R.SQUIRE = 1, 2, 3, 4

-- Length of a voting period and its first start (a Monday at server save, local time).
R.periodDays = 7 -- Tibia (and here until 2026-11-09): 14; Rodrigo asked for one week
R.periodStart = os.time({ year = 2026, month = 11, day = 9, hour = 6, min = 0, sec = 0 })

-- Topics in Marvin's order. bit = first bit of the topic in S.Voted (one bit per option).
-- words: what the player may say; castOn: Marvin's confirmation; result: the board line.
R.topics = {
	{
		key = "shortcut",
		words = { "shortcut", "shortcuts" },
		minRank = 0,
		bit = 0,
		default = "catacombs",
		intro = "Well, in the topic shortcut you have the possibility to vote for shortcuts back from the {minotaurs}, {fungi} or {catacombs}.",
		options = {
			{ key = "minotaurs", words = { "minotaur", "minotaurs" }, castOn = "the shortcut to the minotaurs", result = "the shortcut back from the minotaurs" },
			{ key = "fungi", words = { "fungi", "fungus" }, castOn = "the shortcut to the fungi", result = "the shortcut back from the fungi" },
			{ key = "catacombs", words = { "catacomb", "catacombs" }, castOn = "the shortcut to the catacombs", result = "the shortcut back from the catacombs" },
		},
	},
	{
		key = "dungeon",
		words = { "dungeon", "dungeons" },
		minRank = R.COMMONER,
		bit = 3,
		default = "wrath",
		intro = "Well, the dungeon you have the possibility to vote for can be full of {golems}, {minotaurs} or the {wrath} of evil.",
		options = {
			{ key = "golems", words = { "golem", "golems" }, castOn = "the golems", result = "the golems in the dungeon" },
			{ key = "minotaurs", words = { "minotaur", "minotaurs" }, castOn = "the minotaurs", result = "the minotaurs in the dungeon" },
			{ key = "wrath", words = { "wrath", "wrath of evil" }, castOn = "the wrath of evil", result = "the wrath of evil in the dungeon" },
		},
	},
	{
		key = "boss",
		words = { "boss", "bosses" },
		minRank = R.INHABITANT,
		bit = 6,
		default = "glooth fairy",
		intro = "Well, in this topic you have the possibility to vote for bosses: the furious moohtant {Bullwark}, the poisonous {Lisa} or the mighty {Glooth Fairy}.",
		options = {
			{ key = "bullwark", words = { "bullwark" }, castOn = "Bullwark", result = "Bullwark" },
			{ key = "lisa", words = { "lisa" }, castOn = "Lisa", result = "Lisa" },
			{ key = "glooth fairy", words = { "glooth fairy", "fairy" }, castOn = "the Glooth Fairy", result = "the Glooth Fairy" },
		},
	},
	{
		key = "raid",
		words = { "raid", "raids" },
		minRank = R.CITIZEN,
		bit = 9,
		default = "minotaurs",
		intro = "Well in the topic raid you have the possibility to vote for {minotaurs}, {mechanical creatures} or {wild life}.",
		options = {
			{ key = "minotaurs", words = { "minotaur", "minotaurs" }, castOn = "minotaurs", result = "the minotaur raids" },
			{ key = "mechanical creatures", words = { "mechanical creatures", "mechanical" }, castOn = "mechanical creatures", result = "the raids of mechanical creatures" },
			{ key = "wild life", words = { "wild life", "wildlife" }, castOn = "wild life", result = "the wild life raids" },
		},
	},
}
R.topicByKey = {}
for _, topic in ipairs(R.topics) do
	R.topicByKey[topic.key] = topic
	for index, option in ipairs(topic.options) do
		option.bit = topic.bit + index - 1
	end
end

-- ------------------------------------------------------------------ player state

local function value(player, key)
	return math.max(0, player:getStorageValue(key))
end

function R.votesCast(player)
	return value(player, S.VotesCast)
end

function R.votesLeft(player)
	return value(player, VOTING_POINTS)
end

function R.rank(player)
	return value(player, S.Rank)
end

function R.rankName(rank)
	local entry = R.ranks[rank]
	return entry and entry.name or nil
end

function R.isCitizen(player)
	return R.rank(player) >= R.CITIZEN
end

-- For travel keywords that refuse (condition true = not allowed).
function R.notCitizen(player)
	return R.on() and not R.isCitizen(player)
end

-- Votes cast still missing for the next rank (0 = can be promoted, nil = highest rank).
function R.missingForNext(player)
	local nextRank = R.ranks[R.rank(player) + 1]
	if not nextRank then
		return nil
	end
	return math.max(0, nextRank.votes - R.votesCast(player))
end

function R.canPromote(player)
	return R.missingForNext(player) == 0
end

function R.hasVoted(player, option)
	return bit.band(value(player, S.Voted), bit.lshift(1, option.bit)) ~= 0
end

function R.hasVotedAll(player, topicKey)
	for _, option in ipairs(R.topicByKey[topicKey].options) do
		if not R.hasVoted(player, option) then
			return false
		end
	end
	return true
end

-- Counts votes cast (Marvin's topics and the Dark Trails funding vote).
function R.addVotesCast(player, amount)
	player:setStorageValue(S.VotesCast, R.votesCast(player) + amount)
end

-- ------------------------------------------------------------------ periods and results

local function store()
	return kv.scoped("family-rathleton")
end

function R.periodIndex(now)
	return math.floor(((now or os.time()) - R.periodStart) / (R.periodDays * 24 * 60 * 60))
end

local function tallyKey(topic, option)
	return "tally-" .. topic.key .. "-" .. option.key:gsub(" ", "-")
end

-- Closes finished periods: the most voted option of each topic becomes the result (ties and
-- periods without votes keep the previous result).
function R.refresh(now)
	local current = R.periodIndex(now)
	local db = store()
	local stored = db:get("period")
	if stored == current then
		return
	end
	if stored ~= nil then
		for _, topic in ipairs(R.topics) do
			local previous = db:get("result-" .. topic.key) or topic.default
			local best, bestVotes, tie = nil, 0, false
			for _, option in ipairs(topic.options) do
				local votes = db:get(tallyKey(topic, option)) or 0
				if votes > bestVotes then
					best, bestVotes, tie = option.key, votes, false
				elseif votes > 0 and votes == bestVotes then
					tie = true
				end
				db:remove(tallyKey(topic, option))
			end
			if best and not tie then
				db:set("result-" .. topic.key, best)
			elseif best and tie then
				db:set("result-" .. topic.key, previous)
			end
		end
	end
	db:set("period", current)
end

-- The option that won the last period (or the topic default).
function R.result(topicKey)
	R.refresh()
	local topic = R.topicByKey[topicKey]
	return store():get("result-" .. topicKey) or topic.default
end

function R.resultOption(topicKey)
	local key = R.result(topicKey)
	for _, option in ipairs(R.topicByKey[topicKey].options) do
		if option.key == key then
			return option
		end
	end
	return R.topicByKey[topicKey].options[1]
end

function R.tally(topicKey, optionKey)
	R.refresh()
	local topic = R.topicByKey[topicKey]
	for _, option in ipairs(topic.options) do
		if option.key == optionKey then
			return store():get(tallyKey(topic, option)) or 0
		end
	end
	return 0
end

function R.resultLines()
	local lines = {}
	for _, topic in ipairs(R.topics) do
		lines[#lines + 1] = "The citizens of Rathleton voted for " .. R.resultOption(topic.key).result .. "."
	end
	return lines
end

-- Seconds until the current results change.
function R.secondsToNextPeriod(now)
	now = now or os.time()
	local length = R.periodDays * 24 * 60 * 60
	return R.periodStart + (R.periodIndex(now) + 1) * length - now
end

function R.castVotes(player, topic, option, amount)
	R.refresh()
	player:setStorageValue(VOTING_POINTS, R.votesLeft(player) - amount)
	R.addVotesCast(player, amount)
	player:setStorageValue(S.Voted, bit.bor(value(player, S.Voted), bit.lshift(1, option.bit)))
	local db = store()
	db:set(tallyKey(topic, option), (db:get(tallyKey(topic, option)) or 0) + amount)
end

function R.promote(player)
	local rank = R.rank(player) + 1
	local entry = R.ranks[rank]
	player:setStorageValue(S.Rank, rank)
	player:addAchievement(entry.achievement)
	return entry
end

-- ------------------------------------------------------------------ slides

-- Citizen-only slime slides by action id (TibiaWiki BR Rathleton Quest: the slide to the boat
-- and back, and the Glooth Factory; EN agrees). back = where a refused player stands when he
-- came onto the slide without a step (login, teleport). The messages are ours.
R.citizenSlides = {
	[42630] = { text = "Only citizens of Rathleton may take this shortcut into the city. The minotaur access next to it is open to everyone.", back = Position(33487, 31983, 7) },
	[42631] = { text = "Only citizens of Rathleton may take this shortcut to the boat.", back = Position(33637, 31892, 6) },
	[36489] = { text = "Only citizens of Rathleton may enter the Glooth Factory.", back = Position(33651, 31942, 7) },
}

-- Returns true when the player was refused (and sent back).
function R.refuseSlide(player, actionId, position, fromPosition)
	local slide = R.citizenSlides[actionId]
	if not slide or not R.on() or R.isCitizen(player) then
		return false
	end
	local back = fromPosition
	if not back or (back.x == position.x and back.y == position.y and back.z == position.z) then
		back = slide.back
	end
	player:teleportTo(back, true)
	player:sendCancelMessage(slide.text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, slide.text)
	return true
end

-- The magistrate slide (aid 42628, 33669,31887,5) needs the commoner rank (EN Oramond Dungeon:
-- "you must have cast at least 50 votes", Tibia's commoner). true = refused.
R.DUNGEON_SLIDE_BACK = Position(33669, 31886, 5) -- ours: when the player came from nowhere

function R.refuseDungeon(player, position, fromPosition)
	if not R.on() or R.rank(player) >= R.COMMONER then
		return false
	end
	local back = fromPosition
	if not back or (back.x == position.x and back.y == position.y and back.z == position.z) then
		back = R.DUNGEON_SLIDE_BACK
	end
	player:teleportTo(back, true)
	local text = string.format("Only commoners of Rathleton may use this slide. Cast %d votes at Marvin first.", R.ranks[R.COMMONER].votes) -- ours
	player:sendCancelMessage(text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	return true
end

-- Where the magistrate slide (aid 42628) leads for each dungeon result. The three set-ups are
-- separate areas on our map (TibiaWiki EN Oramond Dungeon: one cave with three set-ups).
R.dungeonPositions = {
	["golems"] = Position(31061, 32605, 9),
	["minotaurs"] = Position(31254, 32604, 9),
	["wrath"] = Position(33459, 31715, 9),
}

-- ------------------------------------------------------------------ quest log

function R.statusText(player)
	local rank = R.rank(player)
	local text = rank == 0 and "You have no citizen rank in Rathleton yet." or ("Your citizen rank in Rathleton is " .. R.rankName(rank) .. ".")
	text = text .. string.format(" You have cast %d votes at Marvin in the magistrate and can still cast %d.", R.votesCast(player), R.votesLeft(player))
	local missing = R.missingForNext(player)
	if missing == nil then
		return text .. " This is the highest rank."
	elseif missing == 0 then
		return text .. " Ask Marvin for a promotion to " .. R.rankName(rank + 1) .. "."
	end
	return text .. string.format(" %d more cast votes and Marvin can promote you to %s.", missing, R.rankName(rank + 1))
end

-- ------------------------------------------------------------------ travel

-- Adds a ship route that only citizens may take (before any other keyword of that name).
function R.addCitizenTravel(keywordHandler, npcHandler, keyword, cost, destination)
	keywordHandler:addKeyword({ keyword }, StdModule.say, { npcHandler = npcHandler, text = "I'm sorry, but this passage is reserved for citizens of Rathleton." }, R.notCitizen)
	local node = keywordHandler:addKeyword({ keyword }, StdModule.say, { npcHandler = npcHandler, text = "Do you seek a passage to " .. keyword:titleCase() .. " for |TRAVELCOST|?", cost = cost, discount = "postman" })
	node:addChildKeyword({ "yes" }, StdModule.travel, { npcHandler = npcHandler, premium = false, cost = cost, discount = "postman", destination = destination })
	node:addChildKeyword({ "no" }, StdModule.say, { npcHandler = npcHandler, text = "We would like to serve you some time.", reset = true })
end

-- ------------------------------------------------------------------ Marvin

R.talk = R.talk or {}

local function has(message, words)
	for _, word in ipairs(words) do
		if MsgContains(message, word) then
			return true
		end
	end
	return false
end

local function topicsFor(rank)
	local names = {}
	for _, topic in ipairs(R.topics) do
		if rank >= topic.minRank then
			names[#names + 1] = topic.key == "shortcut" and "a {shortcut}" or topic.key == "boss" and "{boss}es" or topic.key == "raid" and "{raid}s" or ("{" .. topic.key .. "}")
		end
	end
	if #names == 1 then
		return names[1]
	end
	return table.concat(names, ", ", 1, #names - 1) .. " or " .. names[#names]
end

function R.greeting(player)
	if R.canPromote(player) then
		return "Welcome back, " .. player:getName() .. "! You gathered enough points to advance in your citizen rank. Ask me anytime for {promotion}. Tell me if you want to participate in a {voting}."
	end
	return "Greetings! I guess you are here for the {voting}."
end

-- Handles one message to Marvin; returns true when it answered.
function R.marvinSay(npc, player, message, npcHandler)
	local playerId = player:getId()
	local state = R.talk[playerId] or {}
	R.talk[playerId] = state
	local say = function(text)
		npcHandler:say(text, npc, player)
	end

	-- answers to a question
	if state.step == "confirm" then
		state.step = nil
		if MsgContains(message, "yes") then
			if R.votesLeft(player) < state.amount then
				say("You do not have that many votes anymore.")
				return true
			end
			R.castVotes(player, state.topic, state.option, state.amount)
			say("Thanks, you successfully cast your vote. Feel free to continue gathering votes by helping the city! Farewell.")
			return true
		elseif MsgContains(message, "no") then
			say("Then not. Tell me if you want to vote on another {topic}.") -- ours
			return true
		end
	elseif state.step == "status" then
		state.step = nil
		if MsgContains(message, "yes") then
			player:setStorageValue(S.StatusLog, 1)
			say("Well, from now on you can check the status of your citizenship by yourself or ask me anytime, " .. player:getName() .. "!")
			return true
		elseif MsgContains(message, "no") then
			say("As you wish. Ask me about your {status} whenever you like.") -- ours
			return true
		end
	elseif state.step == "amount" then
		local amount = tonumber(message:match("%d+"))
		if not amount and MsgContains(message, "all") then
			amount = R.votesLeft(player)
		end
		if amount then
			local left = R.votesLeft(player)
			if amount < 1 or amount > left then
				say(string.format("You can't cast more votes than you have. How many of your %d votes do you want to cast?", left)) -- ours
				return true
			end
			state.amount = amount
			state.step = "confirm"
			say(string.format("Did I get that right: You want to cast %d of your votes on %s?", amount, state.option.castOn))
			return true
		end
	end

	-- a topic or an option of the current topic
	local rank = R.rank(player)
	for _, topic in ipairs(R.topics) do
		if has(message, topic.words) then
			state.step, state.topic = nil, nil
			if rank < topic.minRank then
				say("You need a higher citizen rank to vote on this topic. Ask me about your {status}.") -- ours
				return true
			end
			local left = R.votesLeft(player)
			if left < 1 then
				say("You have no votes left to cast. Help the citizens of Rathleton with their tasks to earn more.") -- ours
				return true
			end
			state.topic = topic
			state.step = "option"
			say({
				string.format("So far you earned %d votes. Each single vote can be spent on a different topic, but you can also cast all your votes on one voting. ...", left),
				topic.intro,
			})
			return true
		end
	end
	if state.step == "option" and state.topic then
		for _, option in ipairs(state.topic.options) do
			if has(message, option.words) then
				state.option = option
				state.step = "amount"
				say(string.format("How many of your %d votes do you want to cast?", R.votesLeft(player)))
				return true
			end
		end
	end

	if MsgContains(message, "voting") or MsgContains(message, "vote") then
		state.step = nil
		say("I'm responsible for overseeing the voting process. Are you here to {learn} more about the voting, your {amount} of voting rights, your citizen rank {status} or do you want to vote on a {topic}?")
		return true
	elseif MsgContains(message, "topic") or MsgContains(message, "topics") then
		state.step = nil
		say("Today you might vote for " .. topicsFor(rank) .. ". If you are interested some {background} information, feel free to ask me.")
		return true
	elseif MsgContains(message, "learn") then
		say({ -- ours
			"Every citizen who helps the city earns voting rights - the people of Rathleton will tell you where help is needed. You can cast them here on a {topic}. ...",
			string.format("Every %d days I count the votes, and what most citizens voted for holds until the next count. The more votes you cast, the higher your citizen {status} may rise.", R.periodDays),
		})
		return true
	elseif MsgContains(message, "amount") then
		say(string.format("You can still cast %d votes. So far you have cast %d.", R.votesLeft(player), R.votesCast(player))) -- ours
		return true
	elseif MsgContains(message, "status") then
		local missing = R.missingForNext(player)
		local text
		if rank == 0 then
			text = "Currently, you have no citizen rank."
		else
			text = "Your current citizen rank is " .. R.rankName(rank) .. "."
		end
		if missing == nil then
			text = text .. " This is the highest rank I can confer." -- ours
		elseif missing == 0 then
			text = text .. " You can ask me for a {promotion}."
		else
			text = text .. string.format(" You lack %d successful voting casts if you seek a promotion.", missing)
		end
		if player:getStorageValue(S.StatusLog) < 1 then
			text = text .. " Do you want me to add your status in your quest log, yes or no?"
			state.step = "status"
		end
		say(text)
		return true
	elseif MsgContains(message, "promotion") or MsgContains(message, "promote") then
		local missing = R.missingForNext(player)
		if missing == nil then
			say("You already hold the highest citizen rank, squire.") -- ours
		elseif missing > 0 then
			say(string.format("You lack %d successful voting casts if you seek a promotion.", missing))
		else
			local entry = R.promote(player)
			local tail = entry.name == "squire" and "From now you can participate in votings on new topics." or "From now on, you can cast your votes on new topics."
			say(string.format("You cast %d votes. I will promote your citizen rank to %s. Congratulations, %s! %s", R.votesCast(player), entry.name, player:getName(), tail))
		end
		return true
	elseif MsgContains(message, "background") then
		say({ -- ours
			"The {shortcut} decides which slime slide brings our hunters back to the city: from the minotaurs, the fungi or the catacombs. The {dungeon} below the magistrate fills with what the citizens choose. ...",
			"Inhabitants also decide which {boss} shows up in the sewers, and citizens which {raid}s come to the Glooth Factory. The {results} of the last count are on the board next to me.",
		})
		return true
	elseif MsgContains(message, "results") or MsgContains(message, "result") then
		local lines = R.resultLines()
		say({ lines[1] .. " " .. lines[2] .. " ...", lines[3] .. " " .. lines[4] }) -- ours (the board's lines)
		return true
	end
	return false
end

function R.marvinReset(player)
	R.talk[player:getId()] = nil
end

-- ------------------------------------------------------------------ bosses (2026-11-09)
-- Flora stands where the boss voted for this period can be fought (TibiaWiki BR Flora: her three
-- spots) and charges one voting right to send you into its lever room; the second rank
-- (inhabitant) is needed (BR Bullwark, Lisa). The lever sends everyone in the room to the boss
-- after one minute and then rests (EN 16 min 40 s; BR Lisa: 15 minutes); a fight lasts at most
-- 15 minutes (EN). Bullwark's lever room had no script. Lisa's boss room is not on our map
-- (only her lever hall, 33549-33567,31902-31909,8): she is fought in the hall itself and
-- everyone is sent back to Flora one minute after her death (ours).

R.bosses = {
	["bullwark"] = {
		name = "Bullwark",
		flora = Position(33702, 31856, 7), -- BR (EN 33703,31856,7)
		leverRoom = Position(33700, 31847, 7),
		lever = Position(33699, 31849, 7),
		leverBox = { 33697, 31841, 33709, 31851, 7 },
		bossBox = { 33694, 31818, 33711, 31840, 7 },
		arrival = Position(33702, 31836, 7),
		spawn = Position(33702, 31829, 7), -- EN 131.166|124.85|7
		exit = Position(33695, 31820, 7), -- the forcefield in the boss room
		out = Position(33703, 31857, 7),
		about = "A furious, devastating lump of meat and muscles. He is pure destruction. Take care!",
	},
	["lisa"] = {
		name = "Lisa",
		flora = Position(33558, 31913, 8), -- BR and EN
		leverRoom = Position(33565, 31905, 8),
		lever = Position(33550, 31905, 8),
		leverBox = { 33549, 31902, 33567, 31909, 8 },
		bossBox = { 33549, 31902, 33567, 31909, 8 },
		arena = true, -- no boss room on our map: the fight is in the lever hall
		spawn = Position(33553, 31905, 8),
		out = Position(33560, 31913, 8),
		rest = 15 * 60, -- BR
		about = "Poisonous and sly. She looks like a harmless glooth anemone, but she heals herself when she is about to die. Strike hard and fast!", -- ours (EN: her heal)
	},
	["glooth fairy"] = {
		name = "Glooth Fairy",
		the = "the ",
		flora = Position(33654, 31942, 9), -- EN (BR 33655,31941,9 is a wall on our map; upstream spawn 33654,31937,9)
		leverRoom = Position(33660, 31936, 9), -- upstream's lever (uid 1020) runs the fight
		upstream = true,
		about = "A glooth-powered monstrosity of the new sewers. She heals herself and paralyses the careless. Take care!", -- ours
	},
}
R.LEVER_REST = 1000 -- 16 min 40 s (EN)
R.FIGHT_TIME = 15 * 60 -- EN: maxbattlelength 900

-- The boss Flora offers now.
function R.activeBoss()
	local key = R.result("boss")
	if not R.bosses[key] then
		key = "glooth fairy"
	end
	return key, R.bosses[key]
end

-- Seconds until the lever of a boss can be pulled again (0 = ready).
function R.leverRest(key)
	return R.bosses[key].rest or R.LEVER_REST
end

function R.leverWait(key, now)
	now = now or os.time()
	if R.bosses[key].upstream then
		return math.max(0, Game.getStorageValue(GlobalStorage.GloothFairyTimer) - now)
	end
	return math.max(0, (store():get("lever-" .. key:gsub(" ", "-")) or 0) - now)
end

function R.setLeverWait(key, seconds)
	store():set("lever-" .. key:gsub(" ", "-"), os.time() + seconds)
end

function R.floraGreeting(player)
	local _, boss = R.activeBoss()
	local name = (boss.the or "") .. "{" .. boss.name .. "}"
	return "Greetings, " .. player:getName() .. ". Well, we all know what time it is. Always when we meet, the citizens of Rathleton voted for " .. name .. "! ... Well, the rules are as simple as always. Ask me for a {fight} and I'll teleport you into the room with the lever, therefore I'll charge one voting right. ... From this room there is no way back to me. Pull the trigger and after one minute you and your buddies will face " .. name .. "."
end

function R.setupFlora(npcHandler)
	npcHandler:setCallback(CALLBACK_GREET, function(npc, creature)
		npcHandler:setMessage(MESSAGE_GREET, R.floraGreeting(Player(creature)))
		npcHandler:setTopic(creature:getId(), 0)
		return true
	end)
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not player or not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		local id = player:getId()
		local key, boss = R.activeBoss()
		local say = function(text)
			npcHandler:say(text, npc, creature)
		end
		if MsgContains(message, "fight") then
			say("Do you really want to enter " .. (boss.the or "") .. boss.name .. "'s hideout. There is no chickening out and I also have to charge one voting right! {Yes} or {no}?")
			npcHandler:setTopic(id, 1)
		elseif MsgContains(message, "yes") and npcHandler:getTopic(id) == 1 then
			npcHandler:setTopic(id, 0)
			local wait = R.leverWait(key)
			if R.rank(player) < R.INHABITANT then
				say("Only inhabitants of Rathleton may face the boss the citizens voted for. Ask Marvin about your {promotion}.") -- ours (BR: second rank)
			elseif R.votesLeft(player) < 1 then
				say("You have no voting right left to spend. Help the city of Rathleton and come back.") -- ours
			elseif wait > 0 then
				say(string.format("The lever is still resting after the last fight. Come back in %d minute%s, or you would be stuck in there.", math.ceil(wait / 60), wait > 60 and "s" or "")) -- ours
			else
				player:setStorageValue(VOTING_POINTS, R.votesLeft(player) - 1)
				say("Here you go!")
				player:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
				player:teleportTo(boss.leverRoom)
				boss.leverRoom:sendMagicEffect(CONST_ME_TELEPORT)
			end
		elseif MsgContains(message, "no") and npcHandler:getTopic(id) == 1 then
			npcHandler:setTopic(id, 0)
			say("Okay...")
		else
			for _, other in pairs(R.bosses) do
				if MsgContains(message, other.name:lower()) or (other.name == "Glooth Fairy" and MsgContains(message, "fairy")) then
					say(other.about)
					return true
				end
			end
		end
		return true
	end)
end
