-- Gaia Family server: Dragon Slayer Outfits Quest (2026-10-26). Ours, not upstream.
--
-- TibiaWiki BR/EN ("Dragon Slayer Outfits Quest"): A Sweaty Cyclops (Big Ben)
-- in Ab'Dendriel makes the outfit and both addons when asked about the
-- "dragon slayer attire". In Tibia: outfit 75,000,000 gold, 5,000 dragons and
-- 5,000 dragon lords (bestiary), the achievements Hoard of the Dragon, Reason to
-- Celebrate and Treasure Hunter, 1 bottled dragon breath, 500 green and 500 red
-- dragon scales, 100 green and 100 red dragon leathers; addon 1: 25,000,000
-- gold, 6,250 of each, 15 albino dragon leathers, 25 pieces of draconian steel,
-- 10,000 Drome points; addon 2: 25,000,000 gold, 7,500 of each, the title
-- Competent Beastslayer, 25 albino dragon leathers, 10 dragon lord trophies and
-- 10 dragon trophies.
--
-- Family version (chosen by Rodrigo): gold and kills one fifth (15M / 5M / 5M;
-- 1,000 / 1,250 / 1,500 of each), everything else as in Tibia. The bottled
-- dragon breath comes from The First Dragon and the albino leather from the
-- Albino Dragons (scripts/family/dragon_slayer.lua). Big Ben's lines with
-- "You needin'...", "You want attire of true dragon slayer?", "Indeed! You
-- worthy of attire!...", "You want somethin' to add..." and "Here you have now!"
-- are from TibiaWiki's transcripts; the kill/achievement line, the missing list
-- and the refusals are ours. TibiaWiki shows no quest log entry; ours is in
-- "Outfit and Addon Quests".
--
-- Used by npc/a_sweaty_cyclops.lua (FAMILY hook). Loaded from
-- lib/others/load.lua, before the NPCs.

FamilyDragonSlayer = {
	looktype = { male = 1288, female = 1289 },
	titleId = 71, -- Competent Beastslayer (C++: 320,000 Hunting Task points)
	titleName = "Competent Beastslayer",
	titlePoints = 320000,
	dragonRace = 34,
	dragonLordRace = 39,
	bestiaryBase = 61305000, -- C++ STORAGEVALUE_BESTIARYKILLCOUNT + race id
	steps = {
		{
			what = "attire",
			gold = 15000000,
			kills = 1000,
			items = {
				{ 44179, 1, "bottled dragon breath" },
				{ 5920, 500, "green dragon scales" },
				{ 5877, 100, "green dragon leather" },
				{ 5882, 500, "red dragon scales" },
				{ 5948, 100, "red dragon leather" },
			},
			achievements = { "Hoard of the Dragon", "Reason to Celebrate", "Treasure Hunter" },
		},
		{
			what = "first addon",
			gold = 5000000,
			kills = 1250,
			items = {
				{ 44157, 15, "albino dragon leather" },
				{ 5889, 25, "draconian steel" },
			},
			drome = 10000,
		},
		{
			what = "second addon",
			gold = 5000000,
			kills = 1500,
			items = {
				{ 44157, 25, "albino dragon leather" },
				{ 7399, 10, "dragon lord trophies" },
				{ 44158, 10, "dragon trophies" },
			},
			title = true,
		},
	},
	topics = { askOutfit = 70, confirmOutfit = 71, askAddon = 72 },
}

local D = FamilyDragonSlayer

local function storage()
	return Storage.Quest.FamilyDragonSlayer.Mission
end

-- Dotted thousands, as Big Ben says them ("15.000.000").
local function dotted(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end
D.dotted = dotted

local function commas(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

function D.state(player)
	return player:getStorageValue(storage())
end

-- 1 = outfit next, 2 = first addon next, 3 = second addon next, nil = all done.
function D.nextStep(player)
	local state = math.max(1, D.state(player))
	if state >= 4 then
		return nil
	end
	return state
end

function D.kills(player, race)
	return math.max(0, player:getStorageValue(D.bestiaryBase + race))
end

function D.hasTitle(player)
	for _, title in ipairs(player:getTitles() or {}) do
		if title.id == D.titleId then
			return true
		end
	end
	-- Canary unlocks it at login when the balance reaches 320,000; check now too.
	if player:getTaskHuntingPoints() >= D.titlePoints then
		player:addTitle(D.titleId)
		return true
	end
	return false
end

function D.dromePoints(player)
	if Family and Family.dromeSettle then
		Family.dromeSettle(player)
	end
	return Family and Family.dromePoints and Family.dromePoints(player) or 0
end

-- What is still missing for a step, as short phrases (empty = ready).
function D.missing(player, index)
	local step = D.steps[index]
	local out = {}
	if player:getMoney() + player:getBankBalance() < step.gold then
		out[#out + 1] = dotted(step.gold) .. " gold (bank counts)"
	end
	for _, race in ipairs({ { D.dragonRace, "dragons" }, { D.dragonLordRace, "dragon lords" } }) do
		local have = D.kills(player, race[1])
		if have < step.kills then
			out[#out + 1] = string.format("%s %s slain (lil' one has %s)", dotted(step.kills), race[2], dotted(have))
		end
	end
	for _, item in ipairs(step.items) do
		local have = player:getItemCount(item[1])
		if have < item[2] then
			out[#out + 1] = string.format("%dx %s (lil' one carry %d)", item[2], item[3], have)
		end
	end
	for _, name in ipairs(step.achievements or {}) do
		if not player:hasAchievement(name) then
			out[#out + 1] = "achievement " .. name
		end
	end
	if step.drome and D.dromePoints(player) < step.drome then
		out[#out + 1] = string.format("%s drome points (lil' one has %s)", dotted(step.drome), dotted(D.dromePoints(player)))
	end
	if step.title and not D.hasTitle(player) then
		out[#out + 1] = "title " .. D.titleName
	end
	return out
end

-- Takes everything and gives the outfit or addon. False when something is missing.
function D.give(player, index)
	if #D.missing(player, index) > 0 then
		return false
	end
	local step = D.steps[index]
	for _, item in ipairs(step.items) do
		if not player:removeItem(item[1], item[2]) then
			return false
		end
	end
	if not player:removeMoneyBank(step.gold) then
		return false
	end
	if step.drome then
		Family.addDromePoints(player, -step.drome)
	end
	if index == 1 then
		player:addOutfit(D.looktype.male)
		player:addOutfit(D.looktype.female)
	else
		player:addOutfitAddon(D.looktype.male, index - 1)
		player:addOutfitAddon(D.looktype.female, index - 1)
	end
	player:setStorageValue(storage(), index + 1)
	player:getPosition():sendMagicEffect(CONST_ME_FIREWORK_RED)
	return true
end

function D.start(player)
	if D.state(player) < 1 then
		player:setStorageValue(storage(), 1)
	end
	if player:getStorageValue(Storage.OutfitQuest.DefaultStart) < 1 then
		player:setStorageValue(Storage.OutfitQuest.DefaultStart, 1) -- shows "Outfit and Addon Quests"
	end
end

-- Quest log text (ours).
function D.describe(player)
	local index = D.nextStep(player)
	if not index then
		return "Big Ben, the sweaty cyclops smith in Ab'Dendriel, made you the full attire of a true dragon slayer with both addons."
	end
	local step = D.steps[index]
	local parts = {}
	for _, item in ipairs(step.items) do
		parts[#parts + 1] = string.format("%d %s", item[2], item[3])
	end
	local extra = ""
	if step.achievements then
		extra = " You also need the achievements " .. table.concat(step.achievements, ", ") .. "."
	elseif step.drome then
		extra = string.format(" You also need %s Drome points.", commas(step.drome))
	elseif step.title then
		extra = " You also need the title " .. D.titleName .. " (" .. commas(D.titlePoints) .. " Hunting Task points)."
	end
	local intro = index == 1 and "Big Ben, the sweaty cyclops smith in Ab'Dendriel, can make you the attire of a true dragon slayer." or string.format("Big Ben in Ab'Dendriel can add the %s to your dragon slayer attire.", step.what)
	return string.format("%s He wants %s gold, %s, and %s dragons and %s dragon lords slain (you: %s and %s).%s", intro, commas(step.gold), table.concat(parts, ", "), commas(step.kills), commas(step.kills), commas(D.kills(player, D.dragonRace)), commas(D.kills(player, D.dragonLordRace)), extra)
end

local function sayMissing(npc, creature, npcHandler, list)
	local lines = {}
	local chunk = {}
	for i, part in ipairs(list) do
		chunk[#chunk + 1] = part
		if #chunk == 3 or i == #list then
			lines[#lines + 1] = table.concat(chunk, ", ") .. (i == #list and "." or ", ...")
			chunk = {}
		end
	end
	lines[1] = "Lil' one not ready. Big Ben still missin': " .. lines[1]
	npcHandler:say(lines, npc, creature)
end

-- Big Ben's dialogue. Returns true when the message was handled.
function D.onSay(npc, creature, message, npcHandler)
	if not (Family and Family.dragonSlayerOutfits) then
		return false
	end
	local player = Player(creature)
	if not player then
		return false
	end
	local playerId = player:getId()
	local topic = npcHandler:getTopic(playerId)
	local T = D.topics

	if MsgContains(message, "attire") or MsgContains(message, "dragon slayer outfit") or MsgContains(message, "dragon slayer outfits") then
		D.start(player)
		local index = D.nextStep(player)
		if not index then
			npcHandler:say("Lil' one already wear full attire of true dragon slayer! Big Ben no can add more.", npc, creature)
			npcHandler:setTopic(playerId, 0)
			return true
		end
		local step = D.steps[index]
		if index == 1 then
			npcHandler:say({
				string.format("You needin' %s gold, 1x bottled dragon breath, 500x green dragon scales, 100x green dragon leather, ...", dotted(step.gold)),
				"500x red dragon scales, 100x red dragon leather to get stuff! ...",
				string.format("And lil' one must have slain %s dragons and %s dragon lords, found Hoard of the Dragon and all First Dragon treasure, and have Reason to Celebrate. ...", dotted(step.kills), dotted(step.kills)),
				"You want attire of true dragon slayer? Yes or no?",
			}, npc, creature)
			npcHandler:setTopic(playerId, T.askOutfit)
		else
			local first
			if index == 2 then
				first = string.format("You needin' %s gold, 15 x albino dragon leather, 25 x draconian steel, %s drome points! ...", dotted(step.gold), step.drome)
			else
				first = string.format("You needin' %s gold, 25 x albino dragon leather, 10 x dragon lord trophies, 10 x dragon trophies! ...", dotted(step.gold))
			end
			local second = string.format("And %s dragons and %s dragon lords slain by lil' one%s. ...", dotted(step.kills), dotted(step.kills), step.title and ", and lil' one be " .. D.titleName or "")
			npcHandler:say({ first, second, "You want somethin' to add to dragon slayer attire? Yes or no?" }, npc, creature)
			npcHandler:setTopic(playerId, T.askAddon)
		end
		return true
	end

	if topic ~= T.askOutfit and topic ~= T.confirmOutfit and topic ~= T.askAddon then
		return false
	end

	if MsgContains(message, "no") then
		npcHandler:say("Hum. Lil' one come back when ready.", npc, creature)
		npcHandler:setTopic(playerId, 0)
		return true
	end
	if not MsgContains(message, "yes") then
		return false
	end

	local index = D.nextStep(player)
	if not index or (topic == T.askAddon) ~= (index > 1) then
		npcHandler:setTopic(playerId, 0)
		return false
	end
	local missing = D.missing(player, index)
	if #missing > 0 then
		sayMissing(npc, creature, npcHandler, missing)
		npcHandler:setTopic(playerId, 0)
		return true
	end
	if topic == T.askOutfit then
		npcHandler:say("Indeed! You worthy of attire! You want me to make attire, yes or no?", npc, creature)
		npcHandler:setTopic(playerId, T.confirmOutfit)
		return true
	end
	if D.give(player, index) then
		npcHandler:say("Here you have now!", npc, creature)
	else
		npcHandler:say("Hum? Somethin' wrong. Lil' one try again.", npc, creature)
	end
	npcHandler:setTopic(playerId, 0)
	return true
end
