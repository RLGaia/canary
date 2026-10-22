-- Gaia Family server: Venore Daily Tasks (2026-10-21). Ours, not upstream.
--
-- TibiaWiki ("Venore Daily Tasks"): Norman the Foreman (central production site in
-- the Venore swamp) has three tasks, each paying 250 gold and 250 experience, and a
-- bonus of 250 gold and 250 experience for doing all three:
--   sabotage     kill five Little Corym Charlatans in the cave under the hidden mud
--                hole south of the ropespot at the southern production site
--   maintenance  lubricate the nine machines (a saw, a crane and a wooden treadmill
--                at the northern, central and southern production sites) with the
--                can of oil he gives you
--   pathfinder   bring his grind stone to Scott the Scout (north) and his
--                pathfinder kit to Frank the Plank (south)
-- In Tibia each task can be done again 20 hours later; here everything opens again
-- at the server save (06:00), like the daily reward (Rodrigo's choice). A task taken
-- but not finished keeps its progress over the reset. The bonus is for the three
-- tasks reported in the same game day. Norman's offers use the TibiaWiki lines; the
-- other lines are ours (TibiaWiki has no transcript of them). There is no time limit
-- in the charlatan cave (TibiaQA: 5 minutes in Tibia).
--
-- The NPC files of Norman, Scott and Frank call FamilyVenoreTasks.setupNorman /
-- setupScott / setupFrank (they had no dialogue at all). The hidden hole, the can of
-- oil and the kills are in data-otservbr-global/scripts/family/venore_tasks.lua.
-- Loaded from lib/others/load.lua, before the NPCs.

FamilyVenoreTasks = {
	gold = 250,
	experience = 250,
	killsNeeded = 5,
	creature = "Little Corym Charlatan",
	items = { oil = 17513, kit = 17514, stone = 17617 },
	hole = Position(33029, 32141, 7), -- rock soil south of the ropespot
	caveEntry = Position(33029, 32142, 8),
	-- the nine machines: a saw, a crane and a wooden treadmill per production site
	machineIds = { [17405] = "saw", [17406] = "saw", [17407] = "crane", [17408] = "crane", [17515] = "treadmill" },
	sites = {
		{ name = "northern", maxY = 32060 },
		{ name = "central", maxY = 32120 },
		{ name = "southern", maxY = 99999 },
	},
	kinds = { "saw", "crane", "treadmill" },
	-- task states: -1 or 0 free, 1 taken, 2 done (report to Norman), 3 reported today
	FREE = 0,
	ACTIVE = 1,
	READY = 2,
	REPORTED = 3,
	order = { "sabotage", "maintenance", "pathfinder" },
}

local V = FamilyVenoreTasks
local KV_SCOPE = "family-venore-tasks"

local function S()
	return Storage.Quest.FamilyVenoreTasks
end

function V.storage(task)
	local s = S()
	return ({ sabotage = s.Sabotage, maintenance = s.Maintenance, pathfinder = s.Pathfinder })[task]
end

-- The game day: it changes at the server save time (as Family.stoneDay).
function V.day(now)
	now = now or os.time()
	local hour = 6
	if configManager and configKeys and configKeys.GLOBAL_SERVER_SAVE_TIME then
		hour = tonumber((configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME) or ""):match("^(%d+)")) or 6
	end
	return os.date("%Y-%m-%d", now - hour * 3600)
end

-- A new game day frees the tasks reported before it and the bonus.
function V.refresh(player)
	local kv = player:kv():scoped(KV_SCOPE)
	local today = V.day()
	if kv:get("day") == today then
		return
	end
	kv:set("day", today)
	for _, task in ipairs(V.order) do
		if player:getStorageValue(V.storage(task)) == V.REPORTED then
			player:setStorageValue(V.storage(task), V.FREE)
		end
	end
	player:setStorageValue(S().Bonus, 0)
end

function V.state(player, task)
	V.refresh(player)
	local value = player:getStorageValue(V.storage(task))
	return value < 0 and V.FREE or value
end

local function setState(player, task, value)
	player:setStorageValue(V.storage(task), value)
	if value == V.ACTIVE and player:getStorageValue(S().Questline) < 1 then
		player:setStorageValue(S().Questline, 1)
	end
end

local function bit(n)
	return 2 ^ n
end

local function hasBit(mask, n)
	return math.floor(mask / bit(n)) % 2 == 1
end

-- Machines: bit (site - 1) * 3 + kind - 1.
function V.machineIndex(position, itemId)
	local kind = V.machineIds[itemId]
	if not kind then
		return nil
	end
	for siteIndex, site in ipairs(V.sites) do
		if position.y <= site.maxY then
			for kindIndex, name in ipairs(V.kinds) do
				if name == kind then
					return (siteIndex - 1) * 3 + kindIndex - 1, site.name, kind
				end
			end
		end
	end
end

function V.machinesDone(player)
	local mask = math.max(0, player:getStorageValue(S().Machines))
	local n = 0
	for i = 0, 8 do
		if hasBit(mask, i) then
			n = n + 1
		end
	end
	return n, mask
end

-- Called by the can of oil. Returns the text to show, or nil when not a machine.
function V.lubricate(player, position, itemId)
	local index, siteName, kind = V.machineIndex(position, itemId)
	if not index then
		return nil
	end
	if V.state(player, "maintenance") ~= V.ACTIVE then
		return "Norman the Foreman did not ask you to lubricate anything."
	end
	local done, mask = V.machinesDone(player)
	if hasBit(mask, index) then
		return string.format("You already lubricated the %s of the %s production site.", kind, siteName)
	end
	mask = mask + bit(index)
	player:setStorageValue(S().Machines, mask)
	done = done + 1
	if done >= 9 then
		setState(player, "maintenance", V.READY)
		return "You lubricated the last machine. Report to Norman the Foreman."
	end
	return string.format("You lubricate the %s of the %s production site (%d of 9).", kind, siteName, done)
end

-- Called when a Little Corym Charlatan dies.
function V.countKill(player)
	if V.state(player, "sabotage") ~= V.ACTIVE then
		return
	end
	local kills = math.max(0, player:getStorageValue(S().Kills)) + 1
	player:setStorageValue(S().Kills, kills)
	if kills >= V.killsNeeded then
		setState(player, "sabotage", V.READY)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "That should teach the charlatans to stay off Norman's property. Report to Norman the Foreman.")
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Little corym charlatans killed for Norman: %d of %d.", kills, V.killsNeeded))
	end
end

-- Deliveries: bit 0 grind stone (Scott), bit 1 pathfinder kit (Frank).
function V.deliver(player, which)
	if V.state(player, "pathfinder") ~= V.ACTIVE then
		return "none"
	end
	local mask = math.max(0, player:getStorageValue(S().Deliveries))
	local n = which == "stone" and 0 or 1
	if hasBit(mask, n) then
		return "already"
	end
	if not player:removeItem(V.items[which], 1) then
		return "missing"
	end
	mask = mask + bit(n)
	player:setStorageValue(S().Deliveries, mask)
	if hasBit(mask, 0) and hasBit(mask, 1) then
		setState(player, "pathfinder", V.READY)
		return "last"
	end
	return "ok"
end

-- Text for the quest log and for Norman's "task" answer.
function V.describe(player, task)
	local state = V.state(player, task)
	if state == V.REPORTED then
		return "Done for today. Norman the Foreman has new work after the server save (06:00)."
	end
	if task == "sabotage" then
		if state == V.ACTIVE then
			return string.format("Kill five little corym charlatans in the cave under the hidden mud hole south of the ropespot at the southern production site (33029,32141). So far: %d of %d.", math.max(0, player:getStorageValue(S().Kills)), V.killsNeeded)
		elseif state == V.READY then
			return "You killed five little corym charlatans. Report to Norman the Foreman."
		end
	elseif task == "maintenance" then
		if state == V.ACTIVE then
			local done, mask = V.machinesDone(player)
			local missing = {}
			for siteIndex, site in ipairs(V.sites) do
				for kindIndex, kind in ipairs(V.kinds) do
					if not hasBit(mask, (siteIndex - 1) * 3 + kindIndex - 1) then
						missing[#missing + 1] = site.name .. " " .. kind
					end
				end
			end
			return string.format("Use the can of oil on the saw, the crane and the wooden treadmill of the northern, central and southern production sites. Done: %d of 9. Missing: %s.", done, table.concat(missing, ", "))
		elseif state == V.READY then
			return "You lubricated all nine machines. Report to Norman the Foreman."
		end
	elseif task == "pathfinder" then
		if state == V.ACTIVE then
			local mask = math.max(0, player:getStorageValue(S().Deliveries))
			return string.format("Bring the grind stone to Scott the Scout in the northern swamp (%s) and the pathfinder kit to Frank the Plank at the southern production site (%s).", hasBit(mask, 0) and "delivered" or "not yet", hasBit(mask, 1) and "delivered" or "not yet")
		elseif state == V.READY then
			return "Scott and Frank got their deliveries. Report to Norman the Foreman."
		end
	end
	return "Ask Norman the Foreman in the Venore swamp for this task."
end

local function reward(player, gold, experience)
	player:addExperience(experience, true)
	player:addMoney(gold)
end

-- Pays every task that is ready. Returns the names paid.
function V.report(player)
	local paid = {}
	for _, task in ipairs(V.order) do
		if V.state(player, task) == V.READY then
			setState(player, task, V.REPORTED)
			if task == "maintenance" then
				player:removeItem(V.items.oil, 1)
			end
			reward(player, V.gold, V.experience)
			paid[#paid + 1] = task
		end
	end
	return paid
end

function V.allReported(player)
	for _, task in ipairs(V.order) do
		if V.state(player, task) ~= V.REPORTED then
			return false
		end
	end
	return true
end

function V.claimBonus(player)
	if not V.allReported(player) or player:getStorageValue(S().Bonus) == 1 then
		return false
	end
	player:setStorageValue(S().Bonus, 1)
	reward(player, V.gold, V.experience)
	return true
end

-- Starts a task (gives its items). Returns false when it cannot be taken now.
function V.start(player, task)
	if V.state(player, task) ~= V.FREE then
		return false
	end
	setState(player, task, V.ACTIVE)
	if task == "sabotage" then
		player:setStorageValue(S().Kills, 0)
	elseif task == "maintenance" then
		player:setStorageValue(S().Machines, 0)
		if player:getItemCount(V.items.oil) < 1 then
			player:addItem(V.items.oil, 1)
		end
	elseif task == "pathfinder" then
		player:setStorageValue(S().Deliveries, 0)
		player:addItem(V.items.stone, 1)
		player:addItem(V.items.kit, 1)
	end
	return true
end

-- ---------------------------------------------------------------------------
-- NPC dialogues
-- ---------------------------------------------------------------------------
local offers = {
	sabotage = {
		offer = "You're a man for subtle work? I need some little corym rats... disposed of. Still interested?",
		accept = "Good. Down at the southern production site there's a ropespot, and right south of it a hidden mud hole. Inside, kill five little charlatans so they get the message to STAY OFF our property. Bring a rope to get out again, and come back when you're done.",
	},
	maintenance = {
		offer = "Our three production sites run on heavy tools: saws, cranes and wooden treadmills. In this swamp they rust and stick in no time if nobody oils 'em. You want to help us maintaining our equipment?",
		accept = "Very good. Here, take this can of oil and lubricate the wooden treadmill, the saw and the crane of each production site, north, centre and south. Nine machines, then come back to me.",
	},
	pathfinder = {
		offer = "My pathfinder crew clears the swamp weed and lays the planks for the swamp paths. Now, I want you to bring this grind stone to Scott the Scout and that pathfinder kit to Frank the Plank. You in?",
		accept = "As you wish. Here. Take this pathfinder kit and bring it to Frank the Plank at the southern production site. Scott the Scout is eagerly waiting for this grinding stone as his blades are becoming blunt. He's up in the northern swamp. Come back when you're finished.",
	},
}

local function reportText(paid)
	if #paid == 0 then
		return nil
	end
	local total = #paid * V.gold
	return string.format("Good work on the %s! Here's your pay: %d gold and some experience. Ask me about the {bonus} once all three tasks are done today.", table.concat(paid, " and the "), total)
end

function V.setupNorman(keywordHandler, npcHandler)
	npcHandler:setMessage(MESSAGE_GREET, "Hello friend. You lookin' for a {job}? I could use a hand here.")
	npcHandler:setMessage(MESSAGE_FAREWELL, "Off with you then. Mind the swamp.")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "Oi! Don't just wander off!")

	keywordHandler:addKeyword({ "job" }, StdModule.say, {
		npcHandler = npcHandler,
		text = "I'm the foreman of the production sites here. We need people for some action in the fields of {sabotage}, {maintenance} or {pathfinder} assistance. Each pays 250 gold and some experience, and there's a {bonus} if you do all three in a day.",
	})
	keywordHandler:addAliasKeyword({ "work" })
	keywordHandler:addAliasKeyword({ "help" })
	keywordHandler:addKeyword({ "name" }, StdModule.say, { npcHandler = npcHandler, text = "Norman. Norman the Foreman, and don't you forget it." })

	for _, task in ipairs(V.order) do
		local node = keywordHandler:addKeyword({ task }, function(npc, player)
			local state = V.state(player, task)
			if state == V.FREE then
				npcHandler:say(offers[task].offer, npc, player)
				return true
			end
			if state == V.READY then
				npcHandler:say(reportText(V.report(player)), npc, player)
			elseif state == V.REPORTED then
				npcHandler:say("You did that already today. Come back after the next shift starts (06:00), I'll have more work then.", npc, player)
			else
				npcHandler:say("You're still on it. " .. V.describe(player, task), npc, player)
			end
			npcHandler:resetNpc(player)
			return true
		end)
		node:addChildKeyword({ "yes" }, function(npc, player)
			if V.start(player, task) then
				npcHandler:say(offers[task].accept, npc, player)
			end
			npcHandler:resetNpc(player)
			return true
		end)
		node:addChildKeyword({ "no" }, function(npc, player)
			npcHandler:say("Suit yourself.", npc, player)
			npcHandler:resetNpc(player)
			return true
		end)
	end

	keywordHandler:addKeyword({ "report" }, function(npc, player)
		local text = reportText(V.report(player))
		npcHandler:say(text or "You've got nothing to report. Ask me about {sabotage}, {maintenance} or {pathfinder} work.", npc, player)
		return true
	end)
	keywordHandler:addAliasKeyword({ "done" })
	keywordHandler:addAliasKeyword({ "reward" })

	keywordHandler:addKeyword({ "task" }, function(npc, player)
		local lines = {}
		for _, task in ipairs(V.order) do
			local state = V.state(player, task)
			local text = state == V.FREE and "free, ask me about it" or V.describe(player, task)
			lines[#lines + 1] = string.format("{%s}: %s", task, text)
		end
		npcHandler:say(table.concat(lines, " "), npc, player)
		return true
	end)
	keywordHandler:addAliasKeyword({ "tasks" })
	keywordHandler:addAliasKeyword({ "mission" })

	local bonus = keywordHandler:addKeyword({ "bonus" }, function(npc, player)
		npcHandler:say("Finish all three tasks in a day and I'll pay you extra gold and experience. Want me to check?", npc, player)
		return true
	end)
	bonus:addChildKeyword({ "yes" }, function(npc, player)
		if player:getStorageValue(Storage.Quest.FamilyVenoreTasks.Bonus) == 1 and V.allReported(player) then
			npcHandler:say("You got your bonus today already. Greedy, aren't we?", npc, player)
		elseif V.claimBonus(player) then
			npcHandler:say("All three in one day! That's what I call a worker. Here's your bonus: 250 gold and some experience.", npc, player)
		else
			npcHandler:say("Ah, well. Looks like you've still got work to do today. Finish the {sabotage}, {maintenance} and {pathfinder} tasks and report them, and if you're quick, the bonus is yours.", npc, player)
		end
		npcHandler:resetNpc(player)
		return true
	end)
	bonus:addChildKeyword({ "no" }, function(npc, player)
		npcHandler:say("Then get back to work!", npc, player)
		npcHandler:resetNpc(player)
		return true
	end)
end

-- Scott the Scout (grind stone) and Frank the Plank (pathfinder kit).
local receivers = {
	stone = {
		greet = "Hm? Oh, hello there. Watch your step, the northern swamp is full of nasty things. If Norman sent you, I'm waiting for my {grind stone}.",
		job = "I'm Scott the Scout. I look for safe ways through the northern swamp and mark them for Norman's pathfinder crew.",
		keywords = { "grind stone", "stone", "norman", "delivery" },
		name = "grind stone",
		thanks = "Finally, my grind stone! My blades were getting as blunt as a troll's wit. Thanks!",
		waiting = "Norman promised me a new grind stone. Haven't seen it yet.",
	},
	kit = {
		greet = "Ahoy there, landlubber! Careful on those planks. If Norman sent you, I'm waiting for a {pathfinder kit}.",
		job = "I'm Frank the Plank. I lay the planks of the swamp paths around the southern production site.",
		keywords = { "pathfinder kit", "kit", "norman", "delivery" },
		name = "pathfinder kit",
		thanks = "My pathfinder kit! Now I can get back to laying planks. Thanks a lot!",
		waiting = "Norman promised me a new pathfinder kit. Haven't seen it yet.",
	},
}

local function setupReceiver(keywordHandler, npcHandler, which)
	local r = receivers[which]
	npcHandler:setMessage(MESSAGE_GREET, r.greet)
	npcHandler:setMessage(MESSAGE_FAREWELL, "Take care out there.")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "Take care out there.")
	keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = r.job })
	local function give(npc, player)
		local result = V.deliver(player, which)
		if result == "ok" then
			npcHandler:say(r.thanks .. " Tell Norman I got it.", npc, player)
		elseif result == "last" then
			npcHandler:say(r.thanks .. " That was the last delivery, so go tell Norman.", npc, player)
		elseif result == "already" then
			npcHandler:say("You brought it already. Thanks again!", npc, player)
		elseif result == "missing" then
			npcHandler:say("Where is it? Norman gave you the " .. r.name .. " for me, didn't he? Come back when you have it.", npc, player)
		else
			npcHandler:say(r.waiting, npc, player)
		end
		return true
	end
	for _, word in ipairs(r.keywords) do
		keywordHandler:addKeyword({ word }, give)
	end
end

function V.setupScott(keywordHandler, npcHandler)
	setupReceiver(keywordHandler, npcHandler, "stone")
end

function V.setupFrank(keywordHandler, npcHandler)
	setupReceiver(keywordHandler, npcHandler, "kit")
end
