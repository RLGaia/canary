-- Gaia Family server (2026-10-23): Lorenzo, the Tibiadrome reward exchange.
-- Ours (Canary has no Lorenzo). TibiaWiki BR: Lorenzo trades Drome points for
-- the items below (prices of update 12.70); the Phant is "hi, phant, yes" and the
-- Lion of War outfits "hi, attires, yes". Points, rotations and mail are in
-- data/scripts/family/tibiadrome_rewards.lua; the fights in tibiadrome.lua.
-- His look and other lines are ours (no transcript of his current dialogue).
local internalNpcName = "Lorenzo"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 1

npcConfig.outfit = {
	lookType = 128,
	lookHead = 78,
	lookBody = 94,
	lookLegs = 79,
	lookFeet = 114,
	lookAddons = 3,
}

npcConfig.flags = {
	floorchange = false,
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onMove = function(npc, creature, fromPosition, toPosition)
	npcHandler:onMove(npc, creature, fromPosition, toPosition)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

-- name = what the player says; item = item id, mount = mount id, outfit = { male, female }
local offers = {
	{ name = "arena badge replica", price = 250, item = 36833 },
	{ name = "brown pit demon", price = 400, item = 23489 },
	{ name = "green pit demon", price = 750, item = 23490 },
	{ name = "blue pit demon", price = 1500, item = 23491 },
	{ name = "drome cube", price = 2500, item = 36827 },
	{ name = "plushie of a domestikion", price = 2500, item = 36869 },
	{ name = "plushie of a hoodinion", price = 2500, item = 36867 },
	{ name = "plushie of a mearidion", price = 2500, item = 36868 },
	{ name = "plushie of a murmillion", price = 2500, item = 36865 },
	{ name = "plushie of a scissorion", price = 2500, item = 36866 },
	{ name = "ogre rowdy doll", price = 2500, item = 32944 },
	{ name = "retching horror doll", price = 2500, item = 32945 },
	{ name = "black pit demon", price = 3000, item = 23492 },
	{ name = "sublime tournament accolade", price = 5000, item = 31472 },
	{ name = "tournament accolade", price = 5000, item = 31470 },
	{ name = "red pit demon", price = 6000, item = 23493 },
	{ name = "phant", price = 8000, mount = 182, achievement = "Phantastic!" },
	{ name = "lion of war", alias = "attires", price = 12500, outfit = { 1206, 1207 } },
}

-- Longest names first, so "sublime tournament accolade" wins over "tournament accolade".
local byLength = {}
for _, offer in ipairs(offers) do
	byLength[#byLength + 1] = offer
end
table.sort(byLength, function(a, b)
	return #a.name > #b.name
end)

local TOPIC_CONFIRM = 1
local chosen = {}

local function pointsText(points)
	local text = tostring(points)
	while true do
		local replaced
		text, replaced = text:gsub("^(%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			return text
		end
	end
end

local function findOffer(message)
	for _, offer in ipairs(byLength) do
		if MsgContains(message, offer.name) or (offer.alias and MsgContains(message, offer.alias)) then
			return offer
		end
	end
end

local function owned(player, offer)
	if offer.mount then
		return player:hasMount(offer.mount)
	end
	if offer.outfit then
		local look = player:getSex() == PLAYERSEX_FEMALE and offer.outfit[2] or offer.outfit[1]
		return player:hasOutfit(look, 3)
	end
	return false
end

local function deliver(player, offer)
	if offer.mount then
		player:addMount(offer.mount)
		if offer.achievement then
			player:addAchievement(offer.achievement)
		end
		return "Here is your Phant. Treat him well, he remembers everything!"
	end
	if offer.outfit then
		for _, look in ipairs(offer.outfit) do
			player:addOutfit(look)
			player:addOutfitAddon(look, 3)
		end
		return "Here are your Lion of War attires, with both addons. Wear them with pride!"
	end
	player:addItem(offer.item, 1)
	return string.format("Here you are, %s %s.", ItemType(offer.item):getArticle(), ItemType(offer.item):getName())
end

local function rewardList()
	local parts = {}
	for _, offer in ipairs(offers) do
		parts[#parts + 1] = string.format("{%s} %s", offer.name, pointsText(offer.price))
	end
	return parts
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if Family and Family.dromeSettle then
		Family.dromeSettle(player)
	end
	local points = Family and Family.dromePoints and Family.dromePoints(player) or 0

	if npcHandler:getTopic(playerId) == TOPIC_CONFIRM then
		local offer = chosen[playerId]
		npcHandler:setTopic(playerId, 0)
		chosen[playerId] = nil
		if offer and MsgContains(message, "yes") then
			if owned(player, offer) then
				npcHandler:say("You already have that.", npc, creature)
			elseif points < offer.price then
				npcHandler:say(string.format("You have only %s Drome points, but that costs %s. Fight in the {arena}, the {rotation} pays you.", pointsText(points), pointsText(offer.price)), npc, creature)
			else
				Family.addDromePoints(player, -offer.price)
				npcHandler:say(deliver(player, offer) .. string.format(" You have %s Drome points left.", pointsText(Family.dromePoints(player))), npc, creature)
				logger.info("[Family] Tibiadrome: {} bought {} for {} points", player:getName(), offer.name, offer.price)
			end
			return true
		elseif MsgContains(message, "no") then
			npcHandler:say("As you wish. Anything else from my {rewards}?", npc, creature)
			return true
		end
		-- anything else: treat it as a new question below
	end

	local offer = findOffer(message)
	if offer then
		if owned(player, offer) then
			npcHandler:say("You already have that.", npc, creature)
			return true
		end
		local what = offer.mount and "the Phant mount" or offer.outfit and "the complete Lion of War outfit (both addons)" or string.format("%s %s", ItemType(offer.item):getArticle(), ItemType(offer.item):getName())
		npcHandler:say(string.format("Do you want %s for %s Drome points? You have %s.", what, pointsText(offer.price), pointsText(points)), npc, creature)
		chosen[playerId] = offer
		npcHandler:setTopic(playerId, TOPIC_CONFIRM)
	elseif MsgContains(message, "rewards") or MsgContains(message, "trade") or MsgContains(message, "offer") or MsgContains(message, "exchange") then
		local list = rewardList()
		npcHandler:say({
			"For Drome points I give " .. table.concat(list, ", ", 1, 8) .. ",",
			table.concat(list, ", ", 9, #list) .. ". Just tell me what you want.",
		}, npc, creature, 100)
	elseif MsgContains(message, "points") then
		local level = Family.dromeLevel and Family.dromeLevel(player) or 0
		local start = Family.dromeStartLevel and Family.dromeStartLevel(player) or level
		-- (2026-10-25) say what the current level will pay: points only arrive when the rotation ends
		local perLevel = Family.dromeRewards and Family.dromeRewards.pointsPerLevel or 100
		local pending = level > 0 and string.format(" When this rotation ends on %s you get %s Drome points for it (%d per level).", Family.dromeDateText(Family.dromeRotationEnd()), pointsText(level * perLevel), perLevel) or " Clear a wave in the arena to earn points when this rotation ends."
		npcHandler:say(string.format("You have %s Drome points to spend. In this {rotation} your Drome level is %d; your next run starts at wave %d.%s", pointsText(points), level, start + 1, pending), npc, creature)
	elseif MsgContains(message, "rotation") then
		local endTime = Family.dromeRotationEnd()
		local days = math.max(0, math.ceil((endTime - os.time()) / 86400))
		local perLevel = Family.dromeRewards and Family.dromeRewards.pointsPerLevel or 100
		npcHandler:say({
			string.format("This rotation ends on %s (in %d day%s). Then everyone who cleared a wave gets %d Drome points per Drome level, and the best get {concoctions} by mail.", Family.dromeDateText(endTime), days, days == 1 and "" or "s", perLevel),
			"After that the Drome levels start again, but your next run starts five waves below the level you reached. See the {ranking} for this rotation.",
		}, npc, creature, 100)
	elseif MsgContains(message, "ranking") or MsgContains(message, "rank") then
		local ranking = Family.dromeRanking(Family.dromeRotation())
		if #ranking == 0 then
			npcHandler:say("Nobody has cleared a wave in this rotation yet. Be the first!", npc, creature)
		else
			local parts = {}
			for i = 1, math.min(5, #ranking) do
				local name = "someone"
				local resultId = db.storeQuery("SELECT `name` FROM `players` WHERE `id` = " .. ranking[i].guid)
				if resultId then
					name = Result.getString(resultId, "name")
					Result.free(resultId)
				end
				parts[#parts + 1] = string.format("%d. %s (level %d)", i, name, ranking[i].level)
			end
			npcHandler:say("The best of this rotation: " .. table.concat(parts, ", ") .. ".", npc, creature)
		end
	elseif MsgContains(message, "concoctions") or MsgContains(message, "potions") or MsgContains(message, "cube") then
		npcHandler:say({
			"Concoctions are Tibiadrome potions: more critical hits, double loot, bestiary kills counting twice, protection or damage against an element, or all your spells ready at once. ...",
			"Each lasts one hour while you are online, and the same kind can be drunk again after a day. Places 1 to 5 of a rotation get three by mail, 6 to 10 two, 11 to 20 one. A {drome cube} holds one.",
		}, npc, creature, 100)
	elseif MsgContains(message, "arena") or MsgContains(message, "tibiadrome") or MsgContains(message, "drome") then
		npcHandler:say("Step through the portals in the north and fight wave after wave. The highest wave you clear is your Drome level for this {rotation}.", npc, creature)
	elseif MsgContains(message, "job") then
		npcHandler:say("I keep the Tibiadrome's treasures. Fighters trade their Drome points with me for {rewards}.", npc, creature)
	elseif MsgContains(message, "name") then
		npcHandler:say("I am Lorenzo. My brothers and sisters used to run the old arenas.", npc, creature)
	elseif MsgContains(message, "xodet") then
		npcHandler:say("Xodet sells potions and runes. Buy before you fight, the arena refills what you carry in.", npc, creature)
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Welcome to the Tibiadrome, |PLAYERNAME|! I trade {rewards} for Drome points. Ask me about your {points}, the {rotation} or the {ranking}.")
npcHandler:setMessage(MESSAGE_FAREWELL, "Fight well, |PLAYERNAME|!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "Fight well!")

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcType:register(npcConfig)
