-- Gaia Family server: The Ice Islands Quest review (2026-11-16).
--
-- Ours, not upstream. Asked by Rodrigo: review the quest, its items and its
-- dialogue against our TibiaWiki BR backup (RLGaia/tibiawiki-backup) and the
-- TibiaWiki EN spoiler and NPC transcripts. Lines from the wikis are marked
-- "EN"/"BR" in the NPC files; the others are ours, in each NPC's style.
--
-- Nibelor 5: Cure the Dogs (Nilsor). Upstream wanted the seven ingredients in
-- a fixed order, one per talk, and each ingredient could be gathered only once
-- per character (a lost or sold one stopped the quest). Both wikis: "you can
-- collect the ingredients in any order and bring them all together" (BR), turn
-- them in "individually by talking about them" (EN). Now:
--   * any order; Nilsor remembers which ones he has (player KV
--     family-ice-islands "nilsor", one bit per ingredient; a character in the
--     middle of the old chain keeps the ones the chain already took);
--   * "medicine" works like "mission" (EN: "talk to me about the medicine");
--   * an ingredient can be gathered again while Nilsor still needs it and you
--     carry none (spoon: spores, fine sulphur; knife: cactus, frostbite herb,
--     purple kiss blossom). The squeezing gear of girlpower works as a knife
--     here, as BR says. A spoon on a lava hole no longer swallows What a
--     Foolish Quest's sulphur once you had Ice Islands mission 5.
-- Switch: Family.iceIslandsFixes (false = upstream code everywhere it is used).
--
-- Gathering rules (2026-11-16, asked by Rodrigo): one ingredient every 5 minutes, shared by the
-- spoon, the knife and Nilsor's waterskin ("You might try again later.": EN; BR "tempo de espera
-- compartilhado de 5 minutos"); the sun adorer cactus, the purple kiss and the geyser only by day,
-- the frostbite herb only by night (BR; EN says it for the purple kiss and the herb). Tibian day
-- 06:00-18:00 world time, as Family.isNight. The wrong-time messages are ours.
-- Switch: Family.iceIslandsGatherRules.
--
-- Lore words of Sven, Hjaern, Siflind and Nilsor from the EN transcripts.
-- Switch: Family.iceIslandsAnswers.

Family = Family or {}
Family.iceIslandsFixes = true
Family.iceIslandsAnswers = true
Family.iceIslandsGatherRules = true

FamilyIceIslands = FamilyIceIslands or {}
local F = FamilyIceIslands

local function S()
	return Storage.Quest.U8_0.TheIceIslands
end

-- Nilsor's list, in the order of his own line (and of the upstream chain).
F.ingredients = {
	{
		name = "a part of the sun adorer cactus",
		item = 7245,
		words = { "cactus" },
		ask = "You will find this kind of cactus at places that are called deserts. Only an ordinary kitchen knife will be precise enough to produce the ingredient weneed. Do you have a part of that cactus with you?", -- EN
	},
	{
		name = "a vial of geyser water",
		item = 7246,
		words = { "geyser water", "water", "geyser" },
		ask = {
			"You will need a specially prepared waterskin to collect the water. You can buy one from me ...", -- EN
			"Use it on a geyser that is NOT active. The water of active geysers is far too hot. You can find inactive geysers on Okolnir. Do you have somegeyser water with you?",
		},
	},
	{
		name = "fine sulphur of a lava hole",
		item = 7247,
		words = { "sulphur" },
		ask = "I need fine sulphur of an inactive lava hole. No other sulphur will do. Use an ordinary kitchen spoon on an inactive lava hole. Do you have fine sulphurwith you?", -- EN
	},
	{
		name = "a frostbite herb",
		item = 7248,
		words = { "frostbite herb", "herb", "frostbite" },
		ask = "The frostbite herb is a local plant but its quite rare. You can find it on mountain peaks. You will need to cut it with a fine kitchen knife. Do you have a frostbite herb with you?", -- EN
	},
	{
		name = "a blossom of a purple kiss",
		item = 7249,
		words = { "blossom", "purple kiss" },
		ask = "The purple kiss is a plant that grows in a place called jungle. You will have to use a kitchen knife to harvest its blossom. Do you have a blossom of a purple kiss with you?", -- EN
	},
	{
		name = "a hydra tongue",
		item = 7250,
		words = { "hydra tongue", "tongue" },
		ask = "The hydra tongue is a common pest plant in warmer regions. You might find one in a shop. Do you have a hydra tongue with you?", -- EN
	},
	{
		name = "spores of a giant glimmercap mushroom",
		item = 7251,
		words = { "spores", "glimmercap", "mushroom" },
		ask = "The giant glimmercap mushroom exists in caves and other preferably warm and humid places. Use an ordinary kitchen spoon on a mushroom to collectits spores. Do you have the glimmercap spores?", -- EN
	},
}

local TOPIC_ACCEPT = 1 -- Nilsor's upstream topic for "Are you willing to help me?"
local TOPIC_PASSAGE = 10 -- Nilsor's upstream travel topic
local TOPIC_INGREDIENT = 100 -- + ingredient index

local function kv(player)
	return player:kv():scoped("family-ice-islands")
end

local function mask(player)
	return tonumber(kv(player):get("nilsor")) or 0
end

local function hasBit(value, i)
	return math.floor(value / 2 ^ (i - 1)) % 2 == 1
end

-- true when Nilsor already has ingredient i (our bits, or the old fixed chain: Questline 22 = cactus taken, ...)
function F.delivered(player, i)
	local q = player:getStorageValue(S().Questline)
	if q >= 28 then
		return true
	end
	if q >= 22 and i <= q - 21 then
		return true
	end
	return hasBit(mask(player), i)
end

function F.deliveredCount(player)
	local n = 0
	for i = 1, #F.ingredients do
		if F.delivered(player, i) then
			n = n + 1
		end
	end
	return n
end

local function setDelivered(player, i)
	local m = mask(player)
	if not hasBit(m, i) then
		kv(player):set("nilsor", m + 2 ^ (i - 1))
	end
end

-- Nilsor still needs ingredient i (mission running, not handed in yet).
function F.needed(player, i)
	local q = player:getStorageValue(S().Questline)
	return q >= 21 and q <= 27 and not F.delivered(player, i)
end

local function missing(player)
	local names = {}
	for i, ing in ipairs(F.ingredients) do
		if not F.delivered(player, i) then
			names[#names + 1] = ing.name
		end
	end
	if #names <= 1 then
		return names[1] or ""
	end
	return table.concat(names, ", ", 1, #names - 1) .. " and " .. names[#names]
end

local function ingredientIn(message)
	for i, ing in ipairs(F.ingredients) do
		for _, w in ipairs(ing.words) do
			if MsgContains(message, w) then
				return i
			end
		end
	end
	return nil
end

-- Nilsor's quest talk. Returns true when it answered (the rest of his callback is skipped).
function F.nilsor(npc, creature, message, npcHandler)
	if not Family.iceIslandsFixes then
		return false
	end
	local player = Player(creature)
	local playerId = player:getId()
	local q = player:getStorageValue(S().Questline)
	local topic = npcHandler:getTopic(playerId)

	if MsgContains(message, "yes") then
		if topic == TOPIC_ACCEPT and q == 20 then
			npcHandler:say({
				"A thousand thanks in advance. I need no less than 7 ingredients for the cure. You can ask me about each specifically ...", -- EN
				"I need a part of the sun adorer cactus, a vial of geyser water, sulphur of a lava hole, a frostbite herb, a blossom of a purple kiss, a hydra tongue and spores of a giant glimmercap mushroom ...",
				"Turn them in individually by talking about them to me. As soon as I obtained them all, talk to me about the medicine.",
			}, npc, creature)
			player:setStorageValue(S().Questline, 21)
			player:setStorageValue(S().Mission06, 1) -- quest log: 0 of 7
			npcHandler:setTopic(playerId, 0)
			return true
		end
		local i = topic - TOPIC_INGREDIENT
		if F.ingredients[i] then
			npcHandler:setTopic(playerId, 0)
			if not F.needed(player, i) then
				return true
			end
			if not player:removeItem(F.ingredients[i].item, 1) then
				npcHandler:say("Come back when you have the ingredient.", npc, creature) -- ours (upstream)
				return true
			end
			setDelivered(player, i)
			local count = F.deliveredCount(player)
			player:setStorageValue(S().Mission06, 1 + count) -- quest log: count of 7
			if count >= #F.ingredients then
				player:setStorageValue(S().Questline, 28)
				npcHandler:say("Thank you for this ingredient. Now I have all of them. Talk to me about the {medicine}.", npc, creature) -- EN first sentence, rest ours
			else
				npcHandler:say("Thank you for this ingredient.", npc, creature) -- EN
			end
			return true
		end
		return false
	end

	if MsgContains(message, "no") then
		if topic == TOPIC_PASSAGE then
			npcHandler:say("As you wish.", npc, creature) -- EN
			npcHandler:setTopic(playerId, 0)
			return true
		elseif F.ingredients[topic - TOPIC_INGREDIENT] then
			npcHandler:say("Then come back when you have the ingredient.", npc, creature) -- ours (upstream)
			npcHandler:setTopic(playerId, 0)
			return true
		elseif topic == TOPIC_ACCEPT then
			npcHandler:say("I understand. Perhaps you change your mind. My poor dogs ...", npc, creature) -- ours
			npcHandler:setTopic(playerId, 0)
			return true
		end
		return false
	end

	if MsgContains(message, "mission") or MsgContains(message, "medicine") then
		if q == 20 then
			npcHandler:say({
				"I am in dire need of help. A plague has befallen my dogs. I even called a druid of Carlin for help but all he could do was to recommend some strong medicine ...", -- EN
				"The thing is the ingredients of the medicine are extremely rare and some only exist in far away and distant lands. If you could help me collecting the ingredients, I would be eternally grateful ...",
				"Are you willing to help me?",
			}, npc, creature)
			npcHandler:setTopic(playerId, TOPIC_ACCEPT)
			return true
		elseif q >= 21 and q <= 27 then
			npcHandler:say("I still need " .. missing(player) .. ". Turn them in individually by talking about them to me.", npc, creature) -- ours, from his EN line
			npcHandler:setTopic(playerId, 0)
			return true
		elseif q == 28 then
			npcHandler:say({
				"Thank you. Now I have all necessary ingredients. As a reward I grant you the use of our dog sled, which is located to the east of here. ...", -- EN
				"The dogs can be a bit moody, but if you always carry some ham with you there shouldnt be any problems. Oh, and Hjaern might have a mission for you. So maybe you go and talk to him.",
			}, npc, creature)
			player:setStorageValue(S().Questline, 29)
			player:setStorageValue(S().Mission06, 8)
			player:setStorageValue(S().Mission07, 1) -- quest log: The Secret of Helheim
			npcHandler:setTopic(playerId, 0)
			return true
		elseif MsgContains(message, "medicine") then
			if q > 28 then
				npcHandler:say("My dogs are healthy again, thanks to you.", npc, creature) -- ours
			else
				npcHandler:say("The druids say that a strong medicine can cure almost every illness of the dogs.", npc, creature) -- ours
			end
			npcHandler:setTopic(playerId, 0)
			return true
		end
		return false
	end

	local i = ingredientIn(message)
	if i and q >= 21 and q <= 27 then
		if F.delivered(player, i) then
			npcHandler:say("You already brought me " .. F.ingredients[i].name .. ".", npc, creature) -- ours
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say(F.ingredients[i].ask, npc, creature)
			npcHandler:setTopic(playerId, TOPIC_INGREDIENT + i)
		end
		return true
	end
	return false
end

-- Gathering the ingredients. Called at the top of onUseSpoon and onUseKitchenKnife
-- (scripts/lib/register_actions.lua). Returns true when it handled the use.
-- BR: the sneaky stabber (red) has both tools, the whacking driller (blue) only the knife,
-- the squeezing gear (pink) works as both in this quest.
local KNIFES = { [3469] = true, [9594] = true, [9596] = true, [9598] = true }
local SPOONS = { [3468] = true, [9594] = true, [9596] = true }

local function revert(position, fromId, toId)
	local tile = Tile(position)
	local thing = tile and tile:getItemById(fromId)
	if thing then
		thing:transform(toId)
	end
end

F.gathering = {
	-- target item id: tool, ingredient index, message, effect, transform (temporarily), time of day
	[3920] = { tool = SPOONS, index = 7, text = "You retrieve spores from a mushroom.", effect = "red" },
	[390] = { tool = SPOONS, index = 3, text = "You retrieve a fine sulphur from a lava hole.", effect = "red" },
	[7261] = { tool = KNIFES, index = 4, text = "You cut a leaf from a frostbite herb.", effect = "blue", time = "night" },
	[3647] = { tool = KNIFES, index = 1, text = "You cut a flower from a cactus.", effect = "green", transform = 3646, time = "day" },
	[3753] = { tool = KNIFES, index = 5, text = "You cut a flower from a bush.", effect = "green", transform = 3750, time = "day" },
}

F.GATHER_WAIT = 5 * 60 -- seconds between two ingredients (EN/BR)

function F.isNight()
	local minutes = getWorldTime()
	return minutes < 6 * 60 or minutes > 18 * 60
end

-- Time of day and the shared wait. Returns true when the player may gather now; else says why.
function F.mayGather(player, time)
	if not Family.iceIslandsGatherRules then
		return true
	end
	if time == "day" and F.isNight() then
		player:say("You can only do this during the day.", TALKTYPE_MONSTER_SAY) -- ours
		return false
	elseif time == "night" and not F.isNight() then
		player:say("You can only do this during the night.", TALKTYPE_MONSTER_SAY) -- ours
		return false
	end
	local last = tonumber(kv(player):get("gathered")) or 0
	if os.time() < last + F.GATHER_WAIT then
		player:say("You might try again later.", TALKTYPE_MONSTER_SAY) -- EN
		return false
	end
	return true
end

function F.gathered(player)
	kv(player):set("gathered", os.time())
end

-- Nilsor's waterskin on an inactive geyser (scripts/quests/the_ice_islands_quest/actions_cure.lua).
function F.fillWaterskin(player, item, toPosition)
	if not F.needed(player, 2) or player:getItemCount(F.ingredients[2].item) > 0 then
		return true -- nothing needed: the waterskin stays empty
	end
	if not F.mayGather(player, "day") then
		return true
	end
	toPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	player:say("You take some hot water from the geyser.", TALKTYPE_MONSTER_SAY)
	item:transform(F.ingredients[2].item)
	F.gathered(player)
	return true
end

function F.gather(player, item, target, toPosition)
	if not Family.iceIslandsFixes or not target or not target.getId then
		return false
	end
	local targetId = target:getId()
	local g = F.gathering[targetId]
	if not g or not g.tool[item:getId()] then
		return false
	end
	local ing = F.ingredients[g.index]
	if not F.needed(player, g.index) or player:getItemCount(ing.item) > 0 then
		-- not for this quest now: the 3920 mushroom stays silent as upstream, the others go on to their other quests
		return targetId == 3920
	end
	if not F.mayGather(player, g.time) then
		return true
	end
	F.gathered(player)
	player:addItem(ing.item, 1)
	local effects = { red = CONST_ME_MAGIC_RED, blue = CONST_ME_MAGIC_BLUE, green = CONST_ME_MAGIC_GREEN }
	toPosition:sendMagicEffect(effects[g.effect])
	player:say(g.text, TALKTYPE_MONSTER_SAY)
	if g.transform then
		target:transform(g.transform)
		addEvent(revert, 60 * 1000, toPosition, g.transform, targetId)
	end
	return true
end

-- Formorgar Mines hoist (scripts/quests/formogar_mine_hoist/movements_hoist.lua).
-- EN/BR: the floor plan (pile of bones, second floor) lets you go from the first floor
-- to the second; the instructions (box, deepest floor) work the hoist on the second and
-- third floors. Upstream checked a box storage that nothing ever set, so nobody could use it.
function F.hoistMap(player)
	return player:getStorageValue(S().FormorgarMinesHoistSkeleton) == 1
end

function F.hoistInstructions(player)
	-- the box used to set FormorgarGlacierChest; both count
	return player:getStorageValue(S().FormorgarMinesHoistChest) == 1 or player:getStorageValue(S().FormorgarGlacierChest) == 1
end

-- Hjaern (npc/hjaern.lua) ----------------------------------------------------

local CHARM = 7289
local SHARD = 7290

-- "mission" while a step runs. Returns true when it answered.
function F.hjaernReminder(npc, creature, npcHandler)
	local player = Player(creature)
	local q = player:getStorageValue(S().Questline)
	if q == 30 then
		npcHandler:say("As I explained, travel to Helheim, seek the reason for the unrest there and then report to me about your mission.", npc, creature) -- EN
	elseif q >= 32 and q <= 35 then
		npcHandler:say("Search for Lurik and talk to him about a probable mission he might have for you.", npc, creature) -- EN
	elseif q == 36 then
		npcHandler:say("You have been in the old mines? The spirits are restless there. Did you find a name, a sign of one of our people?", npc, creature) -- ours
	elseif q == 37 then
		npcHandler:say("Talk to the restless spirit of my apprentice Tylaf in the old mines and then report to me about your mission.", npc, creature) -- ours, from his EN line
	elseif q == 39 then
		local marked = 0
		for _, key in ipairs({ "Obelisk01", "Obelisk02", "Obelisk03", "Obelisk04" }) do
			if player:getStorageValue(S()[key]) == 5 then
				marked = marked + 1
			end
		end
		if marked >= 4 then
			return false -- the report (npc file)
		end
		if player:getItemCount(CHARM) == 0 then
			player:addItem(CHARM, 1)
			npcHandler:say("You lost the spirit charm of cold? Take this one. Travel to the mines and find the four special obelisks to mark them with the charm.", npc, creature) -- ours
		else
			npcHandler:say("Travel to the mines and find four special obelisks to mark them with the charm. The spirits feel " .. marked .. " of them so far. Report about your mission when you are done.", npc, creature) -- ours, from his EN line
		end
	else
		return false
	end
	return true
end

local function snowstorm(player)
	if player:hasOutfit(251, 3) or player:hasOutfit(252, 3) then
		player:addAchievement("Out in the Snowstorm")
	end
end

local function firstAddon(player)
	player:addOutfitAddon(251, 1)
	player:addOutfitAddon(252, 1)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	player:setStorageValue(S().Questline, 42)
	player:setStorageValue(S().NorsemanOutfit, 2) -- quest log: Norseman Outfits
end

local function secondAddon(player)
	player:addOutfitAddon(251, 2)
	player:addOutfitAddon(252, 2)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	player:setStorageValue(S().Questline, 44)
	player:setStorageValue(S().NorsemanOutfit, 3)
	snowstorm(player)
end

local TOPIC_FIVE, TOPIC_TEN, TOPIC_SELL = 3, 4, 5 -- Hjaern's upstream topics

-- "shard", "shards", "frostheart"
function F.hjaernShards(npc, creature, npcHandler)
	local player = Player(creature)
	local playerId = player:getId()
	local q = player:getStorageValue(S().Questline)
	if q == 40 then
		npcHandler:say("Do you bring frostheart shards for our spell?", npc, creature) -- EN
		npcHandler:setTopic(playerId, TOPIC_FIVE)
	elseif q == 41 then -- 5 shards given before 2026-11-16, addon not taken yet
		firstAddon(player)
		npcHandler:say("Take this. It might suit your Nordic outfit fine.", npc, creature) -- EN
		npcHandler:setTopic(playerId, 0)
	elseif q == 42 then
		npcHandler:say("Do you bring frostheart shards for our spell?", npc, creature) -- EN
		npcHandler:setTopic(playerId, TOPIC_TEN)
	elseif q == 43 then -- 15 shards given before 2026-11-16
		secondAddon(player)
		npcHandler:say("Take this. It might suit your Nordic outfit fine. From now on we only can give you 2000 gold pieces for each shard.", npc, creature) -- EN
		npcHandler:setTopic(playerId, 0)
	elseif q >= 44 then
		snowstorm(player)
		npcHandler:say("Do you want to sell all your shards for 2000 gold coins per each?", npc, creature) -- ours (upstream)
		npcHandler:setTopic(playerId, TOPIC_SELL)
	else
		npcHandler:say("The shards of the frostheart hold the power of ice. Our spirits may need them one day.", npc, creature) -- ours
		npcHandler:setTopic(playerId, 0)
	end
	return true
end

function F.hjaernShardsYes(npc, creature, npcHandler)
	local player = Player(creature)
	local playerId = player:getId()
	local topic = npcHandler:getTopic(playerId)
	local q = player:getStorageValue(S().Questline)
	if topic == TOPIC_FIVE and q == 40 then
		if player:removeItem(SHARD, 5) then
			firstAddon(player)
			npcHandler:say("Excellent, you collected 5 frostheart shards. Take this. It might suit your Nordic outfit fine.", npc, creature) -- EN/BR
		else
			npcHandler:say("You need 5 frostheart shards. Come back when you have them.", npc, creature) -- ours
		end
	elseif topic == TOPIC_TEN and q == 42 then
		if player:removeItem(SHARD, 10) then
			secondAddon(player)
			npcHandler:say("Excellent, you collected 15 frostheart shards. Take this. It might suit your Nordic outfit fine. From now on we only can give you 2000 gold pieces for each shard.", npc, creature) -- EN/BR
		else
			npcHandler:say("You need 10 more frostheart shards. Come back when you have them.", npc, creature) -- ours
		end
	elseif topic == TOPIC_SELL and q >= 44 then
		local count = player:getItemCount(SHARD)
		if count > 0 and player:removeItem(SHARD, count) then
			player:addMoney(count * 2000)
			npcHandler:say("Here your are. " .. count * 2000 .. " gold coins for " .. count .. " shards.", npc, creature) -- ours (upstream)
		else
			npcHandler:say("You don't have any shards with you.", npc, creature) -- ours
		end
	else
		return false
	end
	npcHandler:setTopic(playerId, 0)
	return true
end

function F.hjaernReward(npc, creature, npcHandler)
	local player = Player(creature)
	local q = player:getStorageValue(S().Questline)
	if q == 41 or q == 43 then
		return F.hjaernShards(npc, creature, npcHandler)
	elseif q == 40 or q == 42 then
		npcHandler:say("We need a few shards more, then you might receive another reward.", npc, creature) -- EN
	elseif q >= 44 then
		snowstorm(player)
		npcHandler:say("You already have all we can give you. But we still pay 2000 gold pieces for each {shard} you bring.", npc, creature) -- ours
	else
		return false
	end
	npcHandler:setTopic(player:getId(), 0)
	return true
end
