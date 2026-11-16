-- Gaia Family server: War Against the Hive Quest and the Hive Born world change (2026-11-16,
-- asked by Rodrigo after a review: upstream had Orockle's quest dialogue commented out, so no
-- mission could be taken; the mission items did nothing; there were no War Exp or Favour points,
-- no Hive stage, no Insectoid outfit, the 21 achievements were never given and the hive gates let
-- everybody through).
--
-- Sources: TibiaWiki BR "War Against The Hive Quest", "Hive Born World Change", "Insectoid Outfits
-- Quest" and the item pages (our backup, saved 2026-11-12); TibiaWiki EN "War Against the Hive
-- Quest/Spoiler" (transcripts, quit and reward lines, pore and crystal timings), "Insectoid Outfits
-- Quest/Spoiler" (remains and server messages), "Dung Ball (Quest)", "Aggressive Fluid". Both
-- wikis agree on every count and reward. Lines marked "ours" are on neither wiki.
--
-- Missions (Orockle, any number at the same time; the items stay with the player):
--   stage 1: acid (8 dissolved chitin fed to swarmer hatchlings), blind (8 different antennae),
--            digestion (7 floor blobs), disable (7 hive pores): 1000 experience, 1 War Exp, 1 Favour
--   stage 2+: kill (9 kollos), break (5 crystals): 1500 experience, 2 War Exp, 2 Favour
--   Achievements at 10/50/100 reports of each mission; Hive Fighter (300 War Exp), Hive War
--   Veteran (500), Bane of the Hive (both addons).
-- Reward: 50 Favour buys a pheromone for a week (hive gates, stage 3 only). Insectoid outfit
--   from the insectoid remains on the top floor of the western tower: 300 / 500 / 1000 War Exp.
--
-- Hive stages (Rodrigo's choice 2026-11-16: "scaled shared counter"): as in Tibia, every report is
-- one action against the Hive Born, counted for the whole server per game day (server save at
-- 06:00) and the stage changes at the next server save; Tibia needs 200 actions in one day, here
-- Family.hiveActionsPerDay (10). Stage 3 lasts 5 days; on its last day the actions decide whether it
-- falls back to stage 2 or stage 1. Stage 2 does not fall back (no wiki says it does; ours).
-- Kept from Tibia (Rodrigo): 300/500/1000 War Exp, 50 Favour per pheromone.
-- Not built (later, Rodrigo): the Hive bosses (Chopper, Maw, Mindmasher, Rotspit, Shadowstalker,
--   Fleshslicer) that drop the dung balls; a dung ball already gives 10 War Exp when used.
-- Not done on purpose: the blob bomb does not dissolve (Orockle still warns about it), and the
--   tower entrances are open at every stage on our map (in Tibia the eastern tower opens in stage 2).
--
-- Player storages: Storage.Quest.U9_4.WarAgainstTheHive (43700-43716, an empty upstream block).
-- World stage: game KV family-hive. Antennae blinded and gates passed: player KV family-hive.
-- Objects, kills, remains, dung ball: scripts/family/war_against_the_hive.lua.
-- NPC files that call this: orockle and the 13 guide NPCs (keyword "hive").
-- Switch: Family.warAgainstTheHive (false = Orockle and the guides as upstream, objects do nothing).

Family = Family or {}
Family.warAgainstTheHive = true
Family.hiveActionsPerDay = 10 -- Tibia: 200 (the whole server in one day)

FamilyHive = FamilyHive or {}
local H = FamilyHive
local S = Storage.Quest.U9_4.WarAgainstTheHive
H.S = S

H.STAGE3_DAYS = 5
H.PHEROMONE_FAVOUR = 50
H.PHEROMONE_TIME = 7 * 24 * 60 * 60
H.QUIT_WAIT = 30 * 60
H.OUTFIT = { male = 465, female = 466 }
H.WAR_OUTFIT, H.WAR_ADDON1, H.WAR_ADDON2 = 300, 500, 1000
H.AREA = { x1 = 33380, y1 = 31100, x2 = 33660, y2 = 31380 } -- Quirefang, for the swarmer drum

function H.enabled()
	return Family.warAgainstTheHive == true
end

-- Missions in Orockle's order. words: what the player may say (first = clickable word).
H.missions = {
	{
		key = "acid",
		name = "Chitin Dissolving",
		words = { "acid", "chitin" },
		stage = 1,
		need = 8,
		points = 1,
		experience = 1000,
		items = { { 14255, 1 }, { 14052, 8 } },
		times = S.Times.Acid,
		progress = S.Progress.Acid,
		achievements = { { 10, "Gatherer" }, { 50, "Supplier" }, { 100, "Chitin Bane" } },
		offer = {
			"For the sabotage of the hive we need a supply of dissolved chitin from the Hive Born which we can turn into a potent acid. The crawlers offer the best of it. ...",
			"To gain the acid we will have to turn the hive against itself. Use a dissolver on the corpse of a crawler that has died just a short moment ago. Then use the drum I'll give you to call one of the swarmer hatchlings that I could tame. ...",
			"Feed the dissolved chitin to the hatchling. It will return imediately to me and turn the digested fluid into a potent acid. Feed it 8 units of dissolved chitin and return to me. You can only call a hatchling on the ground level though. ...",
			"Do you want to take this mission?",
		},
		accept = "Fine. I'll await your return. If you lose a dissolver, you'll have to buy a new one.",
		report = "Good. This will help us in our further efforts. Just ask for more missions if you feel ready.",
		log = "Kill crawlers, use a flask of chitin dissolver on a fresh crawler corpse, call a swarmer hatchling with the swarmer drum on the ground level of the hive and feed it the flask of dissolved chitin.",
		unit = "hatchlings fed",
	},
	{
		key = "blind",
		name = "Antennae Blinding",
		words = { "blind", "antenna", "antennae" },
		stage = 1,
		need = 8,
		points = 1,
		experience = 1000,
		items = { { 13974, 1 } },
		times = S.Times.Blind,
		progress = S.Progress.Blind,
		achievements = { { 10, "Minor Disturbance" }, { 50, "Dazzler" }, { 100, "Hive Blinder" } },
		offer = {
			"You might have noticed the antennae that grow out of the hive structures sometimes. With them the hive communicates with the Hive Born. If you mess up the antennae, their communication is disrupted. ...",
			"Soldiers will not be deployed or reinforced anymore, workers won't build or repair where it is needed. All you have to do is use a bag of this blinding powder on them. Do you want to take this mission?",
		},
		accept = "Fine. You'll have to blind 8 of the antennae. I'll await your return. If you lose the powder, you'll have to buy new one.",
		report = "Yes, I already notice the mantle of silence you have cast over the hive. Just ask for more missions if you feel ready.",
		log = "Use the strange powder on 8 different insectoid antennae on the hills in the east of the hive.",
		unit = "antennae blinded",
	},
	{
		key = "digestion",
		name = "Hive Digestion",
		words = { "digestion", "digest" },
		stage = 1,
		need = 7,
		points = 1,
		experience = 1000,
		items = { { 13976, 1 } },
		times = S.Times.Digestion,
		progress = S.Progress.Digestion,
		achievements = { { 10, "Hickup" }, { 50, "Heartburn" }, { 100, "Stomach Ulcer" } },
		offer = {
			"In some regards, the hive is a living thing. To disrupt its digestion is a blow on the hive itself. I will give you some projectiles, fuelled by the acid of the Hive Born themselves. ...",
			"Use them in the digestion chambers underneath the small hive pyramid far east of the pools of dread. I will mark it on your map. ...",
			"Look for the knots of transported nutrients and aim at them with the acid bag. You will recognize them as blobs moving under the floor. Destroy 7 of them. This way the hive will get 'sick'. ...",
			"Do not destroy more, else the room might fill up with digestive acid and you'd be nothing more than hive-food yourself. Do you want to take this mission?",
		},
		accept = "Fine. I'll await your return. Remember though, the bomb is unstable and will dissolve after some time. Of course you can always buy new ones.",
		report = "Ah yes, excellent. I can hear the hive screaming in pain. Just ask for more missions if you feel ready.",
		log = "Go down two floors in the small hive pyramid far east of the pools of dread and throw the blob bomb at 7 floor blobs moving under the floor.",
		unit = "floor blobs destroyed",
		mark = { x = 33586, y = 31260, z = 7, text = "Hive digestion chambers" }, -- the pyramid above the chambers (map text ours)
	},
	{
		key = "disable",
		name = "Pore Stuffing",
		words = { "disable", "pores", "pore" },
		stage = 1,
		need = 7,
		points = 1,
		experience = 1000,
		items = { { 14051, 1 } },
		times = S.Times.Disable,
		progress = S.Progress.Disable,
		achievements = { { 10, "Planter" }, { 50, "Pimple" }, { 100, "Suppressor" } },
		offer = {
			"The hive can even transport and control several eggs. They can be used to create quickly some lesser Hive Born. Though unremarkable on their own, their sheer number and unceasing assaults are a threat. ...",
			"You can use a special goo to disrupt the spawn pores of the hive in the east. Disable 7 of them to stop their threat. Do you want to take this mission?",
		},
		accept = "Fine. I'll await your return. If you lose the goo, you'll have to buy new one.",
		report = "Yes, yes, the hive is hampered, I can feel it. Just ask for more missions if you feel ready.",
		log = "Use the gooey substance on 7 hive pores in the east of the hive. A disabled pore recovers after a minute.",
		unit = "hive pores disabled",
	},
	{
		key = "kill",
		name = "Guard Killing",
		words = { "kill", "guards", "kollos" },
		stage = 2,
		need = 9,
		points = 2,
		experience = 1500,
		items = {},
		times = S.Times.Kill,
		progress = S.Progress.Kill,
		achievements = { { 10, "Guard Killer" }, { 50, "Hive Infiltrator" }, { 100, "Exterminator" } },
		offer = {
			"The guards of the hive have numerous functions which are essential for the survival of the hive. Killing them will disrupt the functions of the hive severely. It will be your task to kill 9 creatures of the kollos strain. Do you want to take this mission?",
		},
		accept = "Fine. I'll await your return.",
		report = "I feel your mission was victorious. Excellent! Just ask for more missions if you feel ready.",
		log = "Kill 9 kollos in the hive towers.",
		unit = "kollos killed",
	},
	{
		key = "break",
		name = "Crystal Destruction",
		words = { "break", "crystals", "crystal" },
		stage = 2,
		need = 5,
		points = 2,
		experience = 1500,
		items = { { 14054, 1 } },
		times = S.Times.Break,
		progress = S.Progress.Break,
		achievements = { { 10, "Headache" }, { 50, "Confusion" }, { 100, "Manic" } },
		offer = {
			"In the hive you can find ominous crystals. With them, the will of the hive is focused and transmitted. Destroy 5 of them to plunge the hive into chaos! Do you want to take this mission?",
		},
		accept = "Fine. Take this reagent. Use it on a dead spidris to turn it into a volatile and acidic fluid. It will be able to destroy one of the crystals but then you have to refuel it on another spidris's corpse. I'll await your return.",
		report = "The hive is shivering, screaming in confusion. Well done. Just ask for more missions if you feel ready.",
		log = "Use the reagent flask on a fresh spidris corpse and the aggressive fluid on an insectoid monolith in the hive towers, 5 times. A broken crystal grows back after 5 minutes.",
		unit = "crystals destroyed",
	},
}
H.byKey = {}
for index, m in ipairs(H.missions) do
	m.index = index
	H.byKey[m.key] = m
end

-- ---------------------------------------------------------------------------
-- Player values
-- ---------------------------------------------------------------------------

local function value(player, storage)
	return math.max(0, player:getStorageValue(storage))
end

function H.kv(player)
	return player:kv():scoped("family-hive")
end

function H.warExp(player)
	return value(player, S.WarExp)
end

function H.favour(player)
	return value(player, S.Favour)
end

function H.times(player, m)
	return value(player, m.times)
end

function H.active(player, m)
	return player:getStorageValue(m.progress) >= 0
end

function H.progress(player, m)
	return value(player, m.progress)
end

function H.pheromoneLeft(player)
	return math.max(0, player:getStorageValue(S.Pheromone) - os.time())
end

function H.addWarExp(player, amount)
	player:setStorageValue(S.WarExp, H.warExp(player) + amount)
	if player:getStorageValue(S.Questline) < 1 then
		player:setStorageValue(S.Questline, 1)
	end
	if H.warExp(player) >= 300 and not player:hasAchievement("Hive Fighter") then
		player:addAchievement("Hive Fighter")
	end
	if H.warExp(player) >= 500 and not player:hasAchievement("Hive War Veteran") then
		player:addAchievement("Hive War Veteran")
	end
end

-- Counts one more step of an active mission. Returns true if it counted.
function H.advance(player, m, text)
	if not H.active(player, m) then
		return false
	end
	local n = H.progress(player, m)
	if n >= m.need then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You have done enough for this mission. Return to Orockle.")) -- ours
		return false
	end
	n = n + 1
	player:setStorageValue(m.progress, n)
	local line = string.format("%s (%d/%d)", text, n, m.need) -- ours
	if n >= m.need then
		line = line .. " Return to Orockle." -- ours
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, line)
	return true
end

-- ---------------------------------------------------------------------------
-- Hive stage (whole server)
-- ---------------------------------------------------------------------------

local function store()
	return kv.scoped("family-hive")
end

local function saveHour()
	if configManager and configKeys and configKeys.GLOBAL_SERVER_SAVE_TIME then
		return tonumber((configManager.getString(configKeys.GLOBAL_SERVER_SAVE_TIME) or ""):match("^(%d+)")) or 6
	end
	return 6
end

-- Game day number: changes at the server save time (06:00).
function H.dayNumber(now)
	local t = os.date("*t", (now or os.time()) - saveHour() * 3600)
	return math.floor(os.time({ year = t.year, month = t.month, day = t.day, hour = 12 }) / 86400)
end

local function perDay()
	return math.max(1, tonumber(Family.hiveActionsPerDay) or 10)
end
H.perDay = perDay

-- Closes the game days that ended since the last look: the stage changes at the server save.
function H.refresh(now)
	local db = store()
	local today = H.dayNumber(now)
	local day = tonumber(db:get("day")) or today
	local stage = tonumber(db:get("stage")) or 1
	local actions = tonumber(db:get("actions")) or 0
	local days3 = tonumber(db:get("days3")) or 0
	if day >= today then
		if db:get("day") == nil then
			db:set("day", today)
			db:set("stage", stage)
		end
		return stage
	end
	while day < today do
		if stage == 1 then
			if actions >= perDay() then
				stage = 2
			end
		elseif stage == 2 then
			if actions >= perDay() then
				stage, days3 = 3, 0
			end
		else
			days3 = days3 + 1
			if days3 >= H.STAGE3_DAYS then
				stage = actions >= perDay() and 2 or 1
				days3 = 0
			end
		end
		actions = 0
		day = day + 1
	end
	db:set("day", today)
	db:set("stage", stage)
	db:set("actions", 0)
	db:set("days3", days3)
	logger.info("[Family] War Against the Hive: stage {} today", stage)
	return stage
end

function H.stage()
	return H.refresh()
end

function H.actionsToday()
	H.refresh()
	return tonumber(store():get("actions")) or 0
end

function H.addAction()
	H.refresh()
	store():set("actions", H.actionsToday() + 1)
end

-- Days of stage 3 left, today included.
function H.stage3DaysLeft()
	H.refresh()
	return H.STAGE3_DAYS - (tonumber(store():get("days3")) or 0)
end

-- For tests and GMs: set the stage now.
function H.setStage(stage)
	H.refresh()
	local db = store()
	db:set("stage", stage)
	db:set("days3", 0)
	db:set("actions", 0)
end

-- What the guides (keyword "hive") and Orockle ("news") say.
function H.newsText()
	local stage = H.stage()
	local actions = H.actionsToday()
	if stage == 1 then
		-- first sentence from both wikis ("..." there); the rest ours, after the stage 2 line
		return string.format("The hive is well defended and prepared for war. %d actions have been taken against the Hive Born. %d actions are necessary to breach its defences.", actions, perDay())
	elseif stage == 2 then
		return string.format("The defences of the hive are breached. The hive structure to the east is open. %d actions have been taken against the Hive Born. %d actions are necessary to advance further into the hive.", actions, perDay())
	end
	local text = string.format("The hives defences have fallen. Its armies are confused and in shambles. All structures are open for invaders. %d actions have been taken against the Hive Born. This position will hold for a while.", actions)
	if H.stage3DaysLeft() <= 1 then
		text = text .. string.format(" But not for long: %d actions today will keep the defences of the hive breached.", perDay()) -- ours
	end
	return text
end

-- ---------------------------------------------------------------------------
-- Rewards
-- ---------------------------------------------------------------------------

function H.complete(player, m)
	player:addExperience(m.experience, true)
	player:setStorageValue(m.times, H.times(player, m) + 1)
	player:setStorageValue(m.progress, -1)
	player:setStorageValue(S.Favour, H.favour(player) + m.points)
	H.addWarExp(player, m.points)
	local times = H.times(player, m)
	for _, a in ipairs(m.achievements) do
		if times >= a[1] and not player:hasAchievement(a[2]) then
			player:addAchievement(a[2])
		end
	end
	if m.key == "blind" then
		H.kv(player):remove("antennae")
	end
	H.addAction()
end

function H.start(player, m)
	player:setStorageValue(m.progress, 0)
	if player:getStorageValue(m.times) < 0 then
		player:setStorageValue(m.times, 0)
	end
	if player:getStorageValue(S.Questline) < 1 then
		player:setStorageValue(S.Questline, 1)
	end
	if m.key == "blind" then
		H.kv(player):remove("antennae")
	end
	for _, entry in ipairs(m.items) do
		local it = ItemType(entry[1])
		if it:isStackable() then
			player:addItem(entry[1], entry[2], true)
		else
			for _ = 1, entry[2] do
				player:addItem(entry[1], 1, true)
			end
		end
	end
	if m.mark then
		player:addMapMark(Position(m.mark.x, m.mark.y, m.mark.z), MAPMARK_TICK, m.mark.text)
	end
end

-- ---------------------------------------------------------------------------
-- Hive gates (hive_gates.lua): pheromone and stage 3 to go in; always out again
-- ---------------------------------------------------------------------------

-- A gate is 3 squares wide; gates crossed north/south share their y and floor, the others their x.
local function gateKey(itemId, gatePos)
	if itemId >= 13278 and itemId <= 13283 then
		return "gate-y-" .. gatePos.y .. "-" .. gatePos.z, "y"
	end
	return "gate-x-" .. gatePos.x .. "-" .. gatePos.z, "x"
end

function H.hasAccess(player)
	return H.stage() >= 3 and H.pheromoneLeft(player) > 0
end

-- Returns true if the player may pass from fromPos through the gate.
function H.gatePass(player, itemId, gatePos, fromPos)
	if player:getGroup():getAccess() then
		return true
	end
	-- only the Hive on Quirefang: the hive gates of the Hive Outpost (Vandura) stay open to everyone
	local a = H.AREA
	if gatePos.x < a.x1 or gatePos.x > a.x2 or gatePos.y < a.y1 or gatePos.y > a.y2 then
		return true
	end
	local key, axis = gateKey(itemId, gatePos)
	local db = H.kv(player)
	local outside = tonumber(db:get(key))
	local here = fromPos[axis]
	if outside and outside ~= here then
		db:remove(key) -- inside: leaving is always possible (Orockle)
		return true
	end
	if H.hasAccess(player) then
		db:set(key, here)
		return true
	end
	if H.stage() < 3 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The hive gate does not let you pass. The hive is not weakened enough yet.") -- ours
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The hive gate does not let you pass. Its smell keeps strangers out.") -- ours
	end
	return false
end

-- ---------------------------------------------------------------------------
-- NPCs
-- ---------------------------------------------------------------------------

local function contains(message, words)
	for _, word in ipairs(words) do
		if MsgContains(message, word) then
			return true
		end
	end
	return false
end

-- Guides: "hive" tells the stage (BR and EN).
function H.setupGuide(keywordHandler, npcHandler)
	keywordHandler:addKeyword({ "hive" }, function(npc, creature)
		if not H.enabled() or not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		npcHandler:say(H.newsText(), npc, creature)
		return true
	end)
end

local T_OFFER = 0 -- + mission index
local T_REWARD = 20
local T_QUIT_WHICH = 29
local T_QUIT = 30 -- + mission index

local function missionList(stage)
	if stage >= 2 then
		return {
			"As usual you could try to {blind} the hive, you might disrupt its {digestion}, you could gather {acid} or you can {disable} the swarm pores. ...",
			"Due to our recent success, the hives' defences are broken and it is also possible to {kill} the guards or to {break} the control crystals ...",
			"You can always {quit} a mission of course.",
		}
	end
	return {
		"You could try to {blind} the hive, you might disrupt its {digestion}, you could gather {acid} or you can {disable} the swarm pores. ...",
		"You can always {quit} a mission of course.",
	}
end

local function activeMissions(player)
	local list = {}
	for _, m in ipairs(H.missions) do
		if H.active(player, m) then
			table.insert(list, m)
		end
	end
	return list
end

function H.orockleSay(npc, creature, message, npcHandler)
	local player = Player(creature)
	if not player then
		return false
	end
	local pid = player:getId()
	local topic = npcHandler:getTopic(pid)
	local function say(text)
		npcHandler:say(text, npc, creature)
	end

	if MsgContains(message, "yes") and topic ~= 0 then
		npcHandler:setTopic(pid, 0)
		if topic > T_OFFER and topic <= #H.missions then
			local m = H.missions[topic]
			H.start(player, m)
			say(m.accept)
		elseif topic == T_REWARD then
			if H.favour(player) < H.PHEROMONE_FAVOUR then
				say("You have not done enough for our cause yet.") -- ours
				return true
			end
			player:setStorageValue(S.Favour, H.favour(player) - H.PHEROMONE_FAVOUR)
			player:setStorageValue(S.Pheromone, os.time() + H.PHEROMONE_TIME)
			say("So be it! Keep in mind it will wear off after a week, though. Don't worry, you can't be trapped there. It is always possible to leave the mentioned rooms.")
		elseif topic > T_QUIT and topic <= T_QUIT + #H.missions then
			local m = H.missions[topic - T_QUIT]
			player:setStorageValue(m.progress, -1)
			player:setStorageValue(S.QuitTime, os.time() + H.QUIT_WAIT)
			if m.key == "blind" then
				H.kv(player):remove("antennae")
			end
			say("So be it. Should you choose to start it again, you can ask me for missions as soon as you feel ready.")
		end
		return true
	end
	if MsgContains(message, "no") and topic ~= 0 then
		npcHandler:setTopic(pid, 0)
		say("As you wish.") -- ours
		return true
	end

	-- which mission to quit
	if topic == T_QUIT_WHICH then
		for _, m in ipairs(activeMissions(player)) do
			if contains(message, m.words) then
				npcHandler:setTopic(pid, T_QUIT + m.index)
				say("Are you sure you want to quit your current mission? Your progress in your old task will not be lost.")
				return true
			end
		end
	end

	if MsgContains(message, "quit") then
		local list = activeMissions(player)
		if #list == 0 then
			say("You have no mission you could quit.") -- ours
		elseif player:getStorageValue(S.QuitTime) > os.time() then
			say("You need to wait 30 minutes before you can quit another mission.")
		elseif #list == 1 then
			npcHandler:setTopic(pid, T_QUIT + list[1].index)
			say("Are you sure you want to quit your current mission? Your progress in your old task will not be lost.")
		else
			local words = {}
			for _, m in ipairs(list) do
				table.insert(words, "{" .. m.words[1] .. "}")
			end
			npcHandler:setTopic(pid, T_QUIT_WHICH)
			say("Which mission do you want to quit: " .. table.concat(words, ", ") .. "?") -- ours
		end
		return true
	end

	for _, m in ipairs(H.missions) do
		if contains(message, m.words) then
			npcHandler:setTopic(pid, 0)
			if H.active(player, m) then
				if H.progress(player, m) >= m.need then
					H.complete(player, m)
					say(m.report)
				else
					say(string.format("You have not finished this mission yet: %d of %d %s. %s", H.progress(player, m), m.need, m.unit, m.log)) -- ours
				end
			elseif H.stage() < m.stage then
				say("The defences of the hive are still too strong for that. Help us to breach them first.") -- ours
			else
				npcHandler:setTopic(pid, T_OFFER + m.index)
				say(m.offer)
			end
			return true
		end
	end

	if MsgContains(message, "mission") then
		npcHandler:setTopic(pid, 0)
		say(missionList(H.stage()))
	elseif MsgContains(message, "fight") then
		say("You can help in the fight against the hive. There are several missions available to destabilise the hive. Just ask for them if you want to learn more. After completing many missions you might be worthy to get a {reward}.")
	elseif MsgContains(message, "reward") then
		local favour = H.favour(player)
		if H.stage() < 2 then
			say("Remember that you can only collect your reward if the Hive has already started to open itself. Help us to breach its defences first.") -- first sentence EN, the rest ours
		elseif H.pheromoneLeft(player) > 0 then
			say(string.format("The pheromone on you has not worn off yet. It will last for %s.", Game.getTimeInWords(H.pheromoneLeft(player)))) -- ours
		elseif favour < H.PHEROMONE_FAVOUR then
			say(string.format("Your efforts are commendable (%d/%d). Come back when you have done more for our cause.", favour, H.PHEROMONE_FAVOUR)) -- first sentence BR, the rest ours
		else
			npcHandler:setTopic(pid, T_REWARD)
			say({
				string.format("Your efforts are commendable (%d/%d). If you wish, I grant you a treatment with a pheromone that will allow you to access some of the best guarded rooms in the hive. ...", favour, H.PHEROMONE_FAVOUR),
				"But you need to know that the pheromone will wear off after a week and that you can only access the rooms when the hive is weakened and open. When the pheromone wears off, you'll have to put new efforts into our war to get another reward. ...",
				"Remember that you can only collect your reward if the Hive has already started to open itself. So, do you want your reward now?",
			})
		end
	elseif MsgContains(message, "news") then
		say(H.newsText())
	elseif MsgContains(message, "points") or MsgContains(message, "favour") or MsgContains(message, "favor") then
		say(string.format("You have gained %d war experience against the hive and %d favour with me.", H.warExp(player), H.favour(player))) -- ours
	elseif MsgContains(message, "hive") then
		say("The children of the hive will not stop until everything and everyone has become part of their disgusting world. Quirefang is only the beginning! Ask me for {news} about the war.") -- ours, after the quest legend
	else
		return false
	end
	return true
end

function H.setupOrockle(npcHandler)
	npcHandler:setMessage(MESSAGE_GREET, "Greetings pilgrim! I sense you are here to {fight} the {Hive Born}.")
	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		if not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		if not H.enabled() then
			return true
		end
		H.orockleSay(npc, creature, message, npcHandler)
		return true
	end)
end

-- ---------------------------------------------------------------------------
-- Quest log texts (lib/core/quests/catalog/060_war_against_the_hive.lua)
-- ---------------------------------------------------------------------------

function H.describeWar(player)
	local stage = H.stage()
	local text = string.format("You have gained %d war experience and %d favour in the war against the hive (outfit 300, first addon 500, second addon 1000 war experience). The hive is in its %s stage.", H.warExp(player), H.favour(player), ({ "first", "second", "third" })[stage] or "first")
	local left = H.pheromoneLeft(player)
	if left > 0 then
		text = text .. string.format(" Orockle's pheromone lets you pass the hive gates for %s.", Game.getTimeInWords(left))
	elseif H.favour(player) >= H.PHEROMONE_FAVOUR then
		text = text .. " Ask Orockle for a reward: 50 favour buy a pheromone that opens the hive gates for a week while the hive is open."
	end
	return text
end

function H.describeMission(player, m)
	local times = H.times(player, m)
	local done = times > 0 and string.format(" You have done this mission %d time%s.", times, times == 1 and "" or "s") or ""
	if H.active(player, m) then
		local n = H.progress(player, m)
		if n >= m.need then
			return string.format("%s: %d of %d %s. Report to Orockle.%s", m.name, n, m.need, m.unit, done)
		end
		return string.format("%s: %d of %d %s. %s%s", m.name, n, m.need, m.unit, m.log, done)
	end
	return string.format("%s for Orockle.%s Ask him for this mission again whenever you like.", m.name, done)
end
