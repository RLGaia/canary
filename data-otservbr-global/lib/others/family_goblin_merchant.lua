-- Gaia Family server: Goblin Merchant Quest, Rafzan's six tasks (2026-11-23). Ours:
-- upstream had Rafzan with his lore words and his shop, the task items and the map
-- objects, but no task dialogue and no item scripts.
--
-- Sources: TibiaWiki BR backup (Goblin Merchant Quest, Task:Rafzan with its screenshots,
-- Junk Trunk, Smashed Trunk), TibiaWiki EN (Goblin Merchant Quest, /Spoiler, Rafzan,
-- Rafzan/Transcripts, the item pages, Task Manager).
--   advertising  3 advertisement signs on cracked stones          600 exp, 100 gold
--   perfume      perfume gatherer: slug slime, black swamp gas,  1000 exp, 200 gold
--                rotworm fart, mouldy cheese (in that order)
--   guards       guardcatcher on 3 adventurers                     600 exp, 100 gold
--   busy         rat urine on the pond of the Venore Corym cave   1200 exp, 300 gold
--   destroy      trunkhammer on 3 junk trunks                     1200 exp, 300 gold
--   kill         5 marsh stalkers                                  600 exp, 100 gold
-- All six can be active at once; each can be taken again 20 hours after its report
-- (EN only; BR says "daily"). Task Manager after 500 reports (EN). Rewards per task
-- from EN (BR gives only the total, 1,100 gold and 5,200 experience: the same).
-- Rafzan's offers and the report line are the wiki transcripts; where they differ:
-- the perfume slime line is the EN spoiler's (any snail, wait for the corpse; BR and
-- the 2012 EN transcript have an older "special snakes of the trolls" line), the rest
-- follows BR and the EN transcript page. Lines for a task still running, one done
-- recently and a "no" are ours (no wiki has them).
-- Our numbers where the wikis give none: 25% of the guardcatcher shots make an
-- Angry Adventurer; a sign stays on its stone 10 minutes; a rotworm farts with 26%
-- (EN: "on average about 3.85 attempts"). Marsh stalker kills count for every
-- player who hurt the stalker (both of us).
-- Not built: the three stages of Rafzan's hut and look (Tibia: nobody knows what
-- upgrades it; Rodrigo 2026-11-23: leave it out).
--
-- Rafzan's file calls FamilyGoblinMerchant.setupRafzan; the items and the marsh
-- stalker kills are in data-otservbr-global/scripts/family/goblin_merchant.lua.
-- Loaded from lib/others/load.lua, before the NPCs.

FamilyGoblinMerchant = {
	-- task states: -1 or 0 free, 1 taken, 2 done (report to Rafzan), 3 reported
	FREE = 0,
	ACTIVE = 1,
	READY = 2,
	REPORTED = 3,
	order = { "advertising", "perfume", "guards", "busy", "destroy", "kill" },
	cooldown = 20 * 3600, -- EN
	reportsForAchievement = 500, -- EN, Task Manager
	items = {
		sign = 17668,
		signOnStone = 17680,
		crackedStone = 17679,
		guardcatcher = 17669,
		urine = 17671,
		trunkhammer = 17676,
		junkTrunk = 17677,
		smashedTrunk = 17678,
		swampGas = 17681,
		mouldyCheese = 3120,
		gatherer = { 17670, 17672, 17673, 17674 }, -- empty, after the slime, gas, fart
		gathererFull = 17675,
		freshSlug = 12533, -- the dead slug 10 seconds after the kill (12526 decays into it)
		newSlug = 12526,
	},
	-- the pond of the Venore Corym cave, floor 10 (BR 33134,32093; EN 33137,32094)
	pond = { fromX = 33136, toX = 33146, fromY = 32089, toY = 32099, z = 10, ground = 622 },
	signMinutes = 10, -- ours
	angryChance = 25, -- ours
	fartChance = 26, -- EN: about 3.85 attempts
	tasks = {
		advertising = { storage = "Advertising", count = "AdvertisingCount", need = 3, experience = 600, gold = 100 },
		perfume = { storage = "Perfume", experience = 1000, gold = 200 },
		guards = { storage = "Guards", count = "GuardsCount", need = 3, experience = 600, gold = 100 },
		busy = { storage = "Busy", experience = 1200, gold = 300 },
		destroy = { storage = "Destroy", count = "DestroyCount", need = 3, experience = 1200, gold = 300 },
		kill = { storage = "Kill", count = "KillCount", need = 5, experience = 600, gold = 100 },
	},
}

local G = FamilyGoblinMerchant
local KV_SCOPE = "family-goblin-merchant"

local function S()
	return Storage.Quest.U9_80.GoblinMerchant
end

function G.storage(task)
	return S()[G.tasks[task].storage]
end

function G.countStorage(task)
	local key = G.tasks[task].count
	return key and S()[key]
end

function G.count(player, task)
	local key = G.countStorage(task)
	return key and math.max(0, player:getStorageValue(key)) or 0
end

-- A reported task is free again 20 hours after its report.
function G.refresh(player)
	local kv = player:kv():scoped(KV_SCOPE)
	local now = os.time()
	for _, task in ipairs(G.order) do
		if player:getStorageValue(G.storage(task)) == G.REPORTED then
			local at = kv:get("reported-" .. task)
			if not at or now >= at + G.cooldown then
				player:setStorageValue(G.storage(task), G.FREE)
			end
		end
	end
end

function G.waitLeft(player, task)
	local at = player:kv():scoped(KV_SCOPE):get("reported-" .. task) or 0
	return math.max(0, at + G.cooldown - os.time())
end

function G.hoursText(seconds)
	local hours = math.ceil(seconds / 3600)
	return hours <= 1 and "about an hour" or ("about " .. hours .. " hours")
end

function G.state(player, task)
	G.refresh(player)
	local value = player:getStorageValue(G.storage(task))
	if value < 0 then
		return G.FREE
	end
	-- the perfume is done when the filled gatherer is in the backpack
	if task == "perfume" and value == G.ACTIVE and player:getItemCount(G.items.gathererFull) > 0 then
		return G.READY
	end
	return value
end

local function setState(player, task, value)
	player:setStorageValue(G.storage(task), value)
	if value == G.ACTIVE and player:getStorageValue(S().Questline) < 1 then
		player:setStorageValue(S().Questline, 1)
	end
end

-- Adds one to a counted task (signs, adventurers, trunks, marsh stalkers).
-- Returns the new count and whether the task is now done; nil when not active.
function G.addProgress(player, task)
	if G.state(player, task) ~= G.ACTIVE then
		return nil
	end
	local n = G.count(player, task) + 1
	player:setStorageValue(G.countStorage(task), n)
	if n >= G.tasks[task].need then
		setState(player, task, G.READY)
		return n, true
	end
	return n, false
end

function G.pondAt(position)
	local p = G.pond
	return position.z == p.z and position.x >= p.fromX and position.x <= p.toX and position.y >= p.fromY and position.y <= p.toY
end

-- Marks the pond for the "busy" task. Returns true when it counted.
function G.markPond(player)
	if G.state(player, "busy") ~= G.ACTIVE then
		return false
	end
	setState(player, "busy", G.READY)
	return true
end

-- Quest log texts. The ones of advertising, perfume, destroy and kill are Tibia's
-- (BR screenshots); guards and busy and the done/wait lines are ours.
function G.describe(player, task)
	local state = G.state(player, task)
	if state == G.REPORTED then
		return "Done. Rafzan has this task for you again in " .. G.hoursText(G.waitLeft(player, task)) .. "."
	end
	if state == G.READY then
		return "Done. Report to Rafzan in the Venore swamp."
	end
	if state ~= G.ACTIVE then
		return "Ask Rafzan in the Venore swamp for this task."
	end
	if task == "advertising" then
		return string.format("Place three advertisement signs into cracked stones in the swamp. %d / 3", G.count(player, task))
	elseif task == "perfume" then
		return "Use your perfume gatherer to collect the needed odours in the correct order. Look at your gatherer to learn about the next needed odour."
	elseif task == "guards" then
		return string.format("Secretly shoot adventurers in the swamp with the guardcatcher, so that some of them reconsider becoming Rafzan's guards. %d / 3", G.count(player, task))
	elseif task == "busy" then
		return "Sneak into the pond cave of the ratmen north-east of Rafzan's hut and use the bottle with rat urine on the pond."
	elseif task == "destroy" then
		return string.format("Destroy newly bought wares of the ratmen. Use your trunkhammer to destroy the trunks full of junk. %d / 3", G.count(player, task))
	elseif task == "kill" then
		return string.format("Kill five marsh stalkers. %d / 5", G.count(player, task))
	end
	return ""
end

-- Starts a task and hands out its item. Returns false when it cannot be taken now.
function G.start(player, task)
	if G.state(player, task) ~= G.FREE then
		return false
	end
	setState(player, task, G.ACTIVE)
	local countKey = G.countStorage(task)
	if countKey then
		player:setStorageValue(countKey, 0)
	end
	local it = G.items
	if task == "advertising" then
		player:addItem(it.sign, 3)
	elseif task == "perfume" then
		player:addItem(it.gatherer[1], 1) -- EN: a new empty one every time
	elseif task == "guards" then
		player:addItem(it.guardcatcher, 1)
	elseif task == "busy" then
		player:addItem(it.urine, 1)
	elseif task == "destroy" then
		player:addItem(it.trunkhammer, 1)
	end
	return true
end

-- Pays one task that is done. Returns true when paid.
function G.report(player, task)
	if G.state(player, task) ~= G.READY then
		return false
	end
	if task == "perfume" and not player:removeItem(G.items.gathererFull, 1) then
		return false
	end
	setState(player, task, G.REPORTED)
	player:kv():scoped(KV_SCOPE):set("reported-" .. task, os.time())
	local t = G.tasks[task]
	player:addExperience(t.experience, true)
	player:addMoney(t.gold)
	local reports = math.max(0, player:getStorageValue(S().Reports)) + 1
	player:setStorageValue(S().Reports, reports)
	if reports >= G.reportsForAchievement then
		player:addAchievement("Task Manager")
	end
	return true
end

-- ---------------------------------------------------------------------------
-- Rafzan
-- ---------------------------------------------------------------------------
local REPORT = "You did not too bad, me guess. Though me children will starve, I give you biggest reward, don't tell others. Only you get good reward. You are me best."

local DANGER = "But ratmen are STRONG and DANGEROUS!!! (Not recommended for levels below 35) Better not go alone when you are inexperienced. Are you helping poor me?"

local offers = {
	advertising = {
		words = { "advertising", "advertisement" },
		offer = "Me need to get well known all over the swamp. Cheapest prices, best service in whole swamp. Me need you to place some advertisement signs in the swamp. Are you helping poor me?",
		accept = "Oh, so thankful me be! So take these three signs and place them on cracked stones you find all over the swamp. There they stay at least for a while before stolen or been blown away.",
	},
	perfume = {
		words = { "perfume" },
		offer = {
			"Me mostly deal with ratmen for old stuff they collected. Nothing to make any profit, nonono. But me need stuff to keep alive. Ratmen are fond of perfume I invented. ...",
			"I need you to create more of it. Are you helping poor me?",
		},
		accept = {
			"Oh, so thankful me be! Use this container in the correct order on the following: ...",
			"First, FRESH snail slime from a slain snail. Any snail you find will do. You will have to wait a little before its corpse will allow you to gather the slime. ...",
			"Second, add a sample black swamp gas that can be found in some remote areas of the swamp. ...",
			"Third, the fart of a rotworm. Rotworms eat the strangest things and their farts have a special ... odour. Use the container on a living rotworm. With some luck you catch a fart. ...",
			"Last, you need to use the container on mouldy cheese, this is what ratmen love most! You might find some in possession of goblins. If you are done, return the container to me.",
		},
	},
	guards = {
		words = { "guards", "guard" },
		offer = {
			"Me little, me weak. Me need strong guys to protect me. Sadly humans love more be adventurers than protecting poor goblin,. Me think they think adventuring is more fun and safe. ...",
			"Me think when something bad would happen to them, that would teach them. Are you helping poor me?",
		},
		accept = "Oh, so thanky me be! Take this bow and secretly shoot them with it. It's only little bow, won't do much harm. Some of them might reconsider becoming me guard.",
	},
	busy = {
		words = { "busy" },
		offer = {
			"Ratmen always bickering and fighting each other. Keeps them occupied from stealing me stuff and makes them want to buy better stuff from me than the other ratmen have. ...",
			"Me need you to ... place some stuff of hostile rat clan in rat cave to make them angry. ...",
			DANGER,
		},
		accept = "Oh, so thankful me be! Take bottle of urine, me got it from rival clan, no ask how! Sneak into their pond cave and use this urine on the pond.",
	},
	destroy = {
		words = { "destroy", "destroyed" },
		offer = {
			"Ratmen often make deal with poor me. Sadly story short, they always make profit, me never. If stuff they buy is destroyed, they have to buy new stuff. I need you to destroy stuff they bought from me. ...",
			DANGER,
		},
		accept = "Oh, so thankful me be! Take this hammer and use it on the crates they got from me. Me sure they not yet unpacked it, you find it in some storage area.",
	},
	kill = {
		words = { "kill", "killing" },
		offer = "Mean marsh stalkers are threatening me little shop. They are the woodpeckers of swamp! Constantly hacking at me precious little building. Soon me be ruined. Are you helping poor me?",
		accept = "Oh, so thankful me be! You must kill five of this horrible goblin hut gnawers to teach them a lesson! CAN YOU HEAR ME MARSH STALKERS?! SWEET GOBLIN REVENGE IS ON IT'S WAY!",
	},
}
G.offers = offers

-- Rafzan's answer to a task word, for each state. Returns the text (string or table).
function G.answer(player, task)
	local state = G.state(player, task)
	if state == G.FREE then
		return offers[task].offer, true
	elseif state == G.READY then
		G.report(player, task)
		return REPORT
	elseif state == G.REPORTED then
		return "Me have no more of that work for now. Come back in " .. G.hoursText(G.waitLeft(player, task)) .. ", then poor me surely needs help again." -- ours
	end
	return "You not done yet! " .. G.describe(player, task) .. " If you lost me stuff, you can buy new from me, very cheap." -- ours
end

function G.setupRafzan(keywordHandler, npcHandler)
	npcHandler:setMessage(MESSAGE_GREET, "Hello, hello. Me peaceful, poor and honest goblin. Are you lookin' for {trade} or want to {help} me?")
	npcHandler:setMessage(MESSAGE_FAREWELL, "Bye bye. Come back with much money to trade soon.")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "Bye bye. Come back with much money to trade soon.")
	npcHandler:setMessage(MESSAGE_SENDTRADE, "Ah, you too clever for me to make any meagre profit. Just please, please don't rob poor stupid goblin too much, you master of shrewd trading.")

	local function sayer(text)
		return function(npc, player)
			npcHandler:say(text, npc, player)
			return true
		end
	end
	keywordHandler:addKeyword({ "help" }, sayer({
		"So much to do, so little help. Me poor goblin desperately needs help. Me have a few {tasks} me need to be done. ...",
		"I can offer you all money I made if you only help me a little with stuff which is easy to strong smart human but impossible for poor, little me.",
	}))
	keywordHandler:addKeyword({ "tasks" }, sayer("Are you here to {get} a task or to {report} you finished task?"))
	keywordHandler:addKeyword({ "task" }, sayer("Are you here to {get} a task or to {report} you finished task?"))
	keywordHandler:addKeyword({ "get" }, sayer({
		"So much to be done! Me desperately need {advertising}. Me have to create new ratmen {perfume}. Me in need of {guards} to keep me safe when trading. ...",
		"Me looking for someone to keep ratmen {busy}, me need hero to {destroy} some ratmen stuff, and me need someone to {kill} evil marsh stalker.",
	}))
	keywordHandler:addKeyword({ "report" }, sayer("What are you reporting about? Me {advertising} campaign, the {perfume}, recruitment of {guards}, keeping the ratmen {busy}, that you {destroyed} certain provisions or {killing} the marsh stalkers?"))

	for _, task in ipairs(G.order) do
		local o = offers[task]
		for _, word in ipairs(o.words) do
			local node = keywordHandler:addKeyword({ word }, function(npc, player)
				local text, offering = G.answer(player, task)
				npcHandler:say(text, npc, player)
				if not offering then
					npcHandler:resetNpc(player)
				end
				return true
			end)
			node:addChildKeyword({ "yes" }, function(npc, player)
				if G.start(player, task) then
					npcHandler:say(o.accept, npc, player)
				end
				npcHandler:resetNpc(player)
				return true
			end)
			node:addChildKeyword({ "no" }, function(npc, player)
				npcHandler:say("Oh, poor me. Me children will starve.", npc, player) -- ours
				npcHandler:resetNpc(player)
				return true
			end)
		end
	end
end
