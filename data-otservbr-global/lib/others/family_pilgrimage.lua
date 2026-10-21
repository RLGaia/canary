-- Gaia Family server: Pilgrimage of Ashes Quest (2026-10-20). Ours, not upstream.
--
-- TibiaWiki ("Pilgrimage of Ashes Quest"): a guide tells you about the
-- pilgrimage; at each of the five sacred places the priest blesses you for
-- 1,000 gold less (once per blessing) when you ask for your "mission"; with all
-- five blessings, a guide pays 20 platinum coins. Here the reward is paid at
-- every level (in Tibia only below level 25), and having blessings before the
-- start does not matter: you only need all five at the end.
--
-- Used by the 13 guide NPCs (FamilyPilgrimage.addGuide) and by Norf, Humphrey,
-- Edala, Pydar and Eremo (FamilyPilgrimage.addPriest). Loaded from
-- lib/others/load.lua, before the NPCs.

FamilyPilgrimage = {
	discount = 1000,
	reward = { id = 3035, count = 20 }, -- platinum coins
	blessings = {
		[5] = { name = "spiritual shielding", where = "Norf in the White Flower Temple south of Thais" },
		[6] = { name = "embrace of Tibia", where = "Humphrey at the stone circle north of Carlin" },
		[4] = { name = "fire of the suns", where = "Edala in the Sun Tower near Ab'Dendriel" },
		[3] = { name = "spark of the phoenix", where = "Kawill and Pydar in the earth and fire temples of Kazordoon" },
		[2] = { name = "wisdom of solitude", where = "the hermit Eremo on his island near Cormaya" },
	},
	order = { 5, 6, 4, 3, 2 },
}

local P = FamilyPilgrimage

local function storages()
	return Storage.Quest.FamilyPilgrimageOfAshes
end

function P.state(player)
	return player:getStorageValue(storages().Mission)
end

function P.missing(player)
	local list = {}
	for _, bless in ipairs(P.order) do
		if not player:hasBlessing(bless) then
			list[#list + 1] = P.blessings[bless].where
		end
	end
	return list
end

function P.cost(player)
	return math.max(0, Blessings.getBlessingCost(player:getLevel(), false, false) - P.discount)
end

-- Guide NPCs: "pilgrimage" starts the quest, and later pays the reward.
function P.addGuide(keywordHandler, npcHandler)
	local node = keywordHandler:addKeyword({ "pilgrimage" }, function(npc, player, message, keywords, parameters, node)
		local state = P.state(player)
		if state < 1 then
			npcHandler:say({
				"The Pilgrimage of Ashes leads you to the five sacred places of the blessings: Norf in the White Flower Temple south of Thais, Humphrey at the stone circle north of Carlin, Edala in the Sun Tower near Ab'Dendriel, Kawill and Pydar in Kazordoon, and the hermit Eremo on his island near Cormaya. ...",
				"Ask each of them for your {mission}, and they will bless you for 1,000 gold less. Come back to any guide when you have all five blessings. Do you want to go on the pilgrimage?",
			}, npc, player)
		elseif state == 1 then
			local missing = P.missing(player)
			if #missing == 0 then
				player:setStorageValue(storages().Mission, 2)
				player:addItem(P.reward.id, P.reward.count)
				player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
				npcHandler:say("You carry all five blessings! Your pilgrimage of ashes is complete. Take these 20 platinum coins, pilgrim.", npc, player)
			else
				npcHandler:say("You still need the blessing of: " .. table.concat(missing, "; ") .. ".", npc, player)
			end
			npcHandler:resetNpc(player)
		else
			npcHandler:say("You have already completed the Pilgrimage of Ashes.", npc, player)
			npcHandler:resetNpc(player)
		end
		return true
	end, {})
	node:addChildKeyword({ "yes" }, function(npc, player)
		player:setStorageValue(storages().Mission, 1)
		if player:getStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart) < 1 then
			player:setStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart, 1)
		end
		npcHandler:say("Then go, pilgrim. Start wherever you like, and ask the priests for your {mission}.", npc, player)
		npcHandler:resetNpc(player)
		return true
	end, {}, function(player)
		return P.state(player) < 1
	end)
	node:addChildKeyword({ "" }, function(npc, player)
		npcHandler:say("Maybe another time.", npc, player)
		npcHandler:resetNpc(player)
		return true
	end, {})
	keywordHandler:addAliasKeyword({ "ashes" })
end

-- Blessing NPCs: "mission" gives the pilgrim's blessing for 1,000 gold less, once.
function P.addPriest(keywordHandler, npcHandler, bless)
	local info = P.blessings[bless]
	local node = keywordHandler:addKeyword({ "mission" }, function(npc, player)
		local state = P.state(player)
		if state < 1 then
			npcHandler:say("Pilgrims on the {pilgrimage} of ashes come here for their blessing. Any guide in the cities can tell you about it.", npc, player)
			npcHandler:resetNpc(player)
		elseif state >= 2 then
			npcHandler:say("Your pilgrimage is complete. May the gods protect you.", npc, player)
			npcHandler:resetNpc(player)
		elseif player:hasBlessing(bless) then
			npcHandler:say("You already carry the " .. info.name .. ". Go on with your pilgrimage.", npc, player)
			npcHandler:resetNpc(player)
		elseif player:getStorageValue(storages().Discount[bless]) == 1 then
			npcHandler:say("You already received this blessing as a pilgrim. Ask me for the " .. info.name .. " if you want it again.", npc, player)
			npcHandler:resetNpc(player)
		elseif bless == 3 and player:getStorageValue(Storage.KawillBlessing) ~= 1 then
			npcHandler:say("You need the blessing of the great geomancer Kawill in the earth temple first.", npc, player)
			npcHandler:resetNpc(player)
		else
			npcHandler:say(string.format("A pilgrim! For you, the %s costs only %d gold. Do you want to receive it?", info.name, P.cost(player)), npc, player)
		end
		return true
	end, {})
	node:addChildKeyword({ "yes" }, function(npc, player)
		local cost = P.cost(player)
		if not player:removeMoneyBank(cost) then
			npcHandler:say("Oh. You do not have enough money.", npc, player)
		else
			if bless == 3 then
				player:setStorageValue(Storage.KawillBlessing, 0)
			end
			player:addBlessing(bless, 1)
			player:setStorageValue(storages().Discount[bless], 1)
			player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			npcHandler:say("So receive the " .. info.name .. ", pilgrim.", npc, player)
		end
		npcHandler:resetNpc(player)
		return true
	end, {}, function(player)
		return P.state(player) == 1 and not player:hasBlessing(bless) and player:getStorageValue(storages().Discount[bless]) ~= 1 and (bless ~= 3 or player:getStorageValue(Storage.KawillBlessing) == 1)
	end)
	node:addChildKeyword({ "" }, function(npc, player)
		npcHandler:say("As you wish.", npc, player)
		npcHandler:resetNpc(player)
		return true
	end, {})
end
