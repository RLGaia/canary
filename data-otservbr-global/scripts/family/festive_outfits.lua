-- Gaia Family server: Festive Outfits addons (2026-10-20). Ours, not upstream.
--
-- The First Dragon gives the Festive outfit; Muriel in Thais gives the two
-- addons (TibiaWiki "Festive Outfits Quest"): 3 porcelain masks for the first,
-- 50 colourful feathers for the second. Upstream's dialogue could never be
-- finished (FAMILY: in npc/muriel.lua). Both addons give the achievement
-- "Reason to Celebrate", also at login for characters who already have them.

FamilyFestive = {
	looks = { 929, 931 }, -- female, male
	addons = {
		[1] = { item = 25088, count = 3, storage = Storage.Quest.U11_02.FestiveOutfits.Addon1, name = "porcelain masks", text = "first" },
		[2] = { item = 25089, count = 50, storage = Storage.Quest.U11_02.FestiveOutfits.Addon2, name = "colourful feathers", text = "second" },
	},
	achievement = "Reason to Celebrate",
}

local F = FamilyFestive

function F.hasOutfit(player)
	return player:hasOutfit(F.looks[1]) or player:hasOutfit(F.looks[2])
end

function F.hasAddon(player, index)
	local addon = F.addons[index]
	return player:getStorageValue(addon.storage) == 2 or player:hasOutfit(F.looks[1], index) or player:hasOutfit(F.looks[2], index)
end

function F.checkAchievement(player)
	if F.hasAddon(player, 1) and F.hasAddon(player, 2) and not player:hasAchievement(F.achievement) then
		player:addAchievement(F.achievement)
	end
end

function F.trade(npc, creature, player, index, npcHandler)
	local addon = F.addons[index]
	local playerId = player:getId()
	npcHandler:setTopic(playerId, 0)
	if F.hasAddon(player, index) then
		npcHandler:say("You already have this accessory.", npc, creature)
		return
	end
	if player:getItemCount(addon.item) < addon.count or not player:removeItem(addon.item, addon.count) then
		npcHandler:say(string.format("Oh, sorry but you don't have enough %s! I need %d.", addon.name, addon.count), npc, creature)
		return
	end
	player:addOutfitAddon(F.looks[1], index)
	player:addOutfitAddon(F.looks[2], index)
	player:setStorageValue(addon.storage, 2)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	npcHandler:say(string.format("Very good! You gained the %s addon to the festive outfit.", addon.text), npc, creature)
	F.checkAchievement(player)
end

local login = CreatureEvent("FamilyFestiveLogin")

function login.onLogin(player)
	F.checkAchievement(player)
	return true
end

login:register()
