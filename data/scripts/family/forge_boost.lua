-- Gaia Family server: Exaltation Forge boost (2026-10-25). Ours, not upstream.
--
-- Upstream (as in Tibia) dust only comes from influenced creatures (stage 1-5,
-- each stage 1-3 dust) and fiendish ones (counted as stage 15). At most 300
-- influenced creatures exist on a map of about 83,000, and a dead one is
-- replaced at a random spot anywhere, so two players met one or two an hour.
-- The tier prices are Tibia's (up to 15 billion gold for tier 10).
--
-- Here:
--   * every creature that comes near a player (about one screen, same floor)
--     gets one roll: 2.5% to become influenced, stage 3-5 (5% until the
--     evening of 2026-10-25, halved at Rodrigo's request). The global limit
--     (forgeInfluencedLimit in family/config.family.lua) is made room for by
--     clearing a random influenced creature far from every player;
--   * dust per kill x2: stage x2 to stage x6 (fiendish 30-90);
--   * in a party with shared experience switched on, every member gets the
--     full dust (Tibia: members in share range), at any distance, as our
--     shared experience (party_share.lua);
--   * the dust limit is raised to the maximum (225) at login, skipping the
--     10,875 dust upstream costs to raise it step by step;
--   * fusion gold: 10% of Tibia's prices up to tier 5, then a steeper cut
--     (tier 10 200 million instead of 15 billion); convergence prices get the
--     same cut per tier; exalted cores needed for a transfer are halved.
-- Config side (family/config.family.lua): 750 random influenced creatures,
-- 8 fiendish, fusion success 65% (80% with a core), 25 slivers per core.
--
-- Switch: Family.forgeBoost (false = upstream dust, limit and prices).

Family = Family or {}
Family.forgeBoost = true
Family.forgeDustMultiplier = 2 -- dust per kill = upstream x this
Family.forgeNearChance = 2.5 -- % per creature near a player (decimals allowed)
Family.forgeNearStages = { 3, 5 } -- stage of those influenced creatures
Family.forgeFullDustLimit = true -- dust limit 225 from the start

local NEAR_X, NEAR_Y = 9, 7 -- squares around the player (the client view)
local FAR = 30 -- creatures this far from every player may lose their influence

-- regular = fusion gold to reach that tier; core = cores for a transfer;
-- convergence fusion/transfer prices only exist for class 4.
-- Upstream (Tibia): class 1 25k; class 2 750k, 5M; class 3 4M, 10M, 20M;
-- class 4 8M, 20M, 40M, 65M, 100M, 250M, 750M, 2.5B, 8B, 15B with cores
-- 1, 2, 5, 10, 15, 25, 35, 50, 60, 85.
Family.forgePrices = {
	[1] = { { regular = 2500, core = 1 } },
	[2] = { { regular = 75000, core = 1 }, { regular = 500000, core = 1 } },
	[3] = { { regular = 400000, core = 1 }, { regular = 1000000, core = 1 }, { regular = 2000000, core = 2 } },
	[4] = {
		{ regular = 800000, core = 1, fusion = 5500000, transfer = 6500000 },
		{ regular = 2000000, core = 1, fusion = 11000000, transfer = 16500000 },
		{ regular = 4000000, core = 3, fusion = 17000000, transfer = 37500000 },
		{ regular = 6500000, core = 5, fusion = 30000000, transfer = 80000000 },
		{ regular = 10000000, core = 8, fusion = 87500000, transfer = 200000000 },
		{ regular = 15000000, core = 13, fusion = 141000000, transfer = 315000000 },
		{ regular = 30000000, core = 18, fusion = 278000000, transfer = 580000000 },
		{ regular = 60000000, core = 25, fusion = 510000000, transfer = 1020000000 },
		{ regular = 120000000, core = 30, fusion = 750000000, transfer = 1500000000 },
		{ regular = 200000000, core = 43, fusion = 1670000000, transfer = 4000000000 },
	},
}

-- ---------------------------------------------------------------------------
-- Dust per kill and party dust
-- ---------------------------------------------------------------------------

function Family.forgeGiveDust(player, amount)
	local total = player:getForgeDusts()
	local limit = player:getForgeDustLevel()
	if total >= limit then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You did not receive " .. amount .. " dust for the Exaltation Forge because you have already reached the maximum of " .. limit .. " dust.")
		return 0
	end
	local given = math.min(amount, limit - total)
	player:addForgeDusts(given)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You received " .. given .. " dust for the Exaltation Forge. You now have " .. player:getForgeDusts() .. " out of a maximum of " .. limit .. " dust.")
	return given
end

-- Who gets the dust of a kill: the killing player (or the summoner), or every
-- member of his party when shared experience is switched on.
function Family.forgeDustReceivers(killer)
	local owner = killer
	if owner and not owner:isPlayer() then
		owner = owner:getMaster()
	end
	if not owner or not owner:isPlayer() then
		return {}
	end
	local party = owner:getParty()
	if not party or not party:isSharedExperienceActive() then
		return { owner }
	end
	local receivers = { party:getLeader() }
	for _, member in ipairs(party:getMembers() or {}) do
		receivers[#receivers + 1] = member
	end
	return receivers
end

function Family.forgeDustAmount(stack)
	local multiplier = math.floor(configManager.getFloat(configKeys.FORGE_AMOUNT_MULTIPLIER) or 3)
	local low = stack * Family.forgeDustMultiplier
	return math.random(low, math.max(low, multiplier * low))
end

local upstreamOnDeath = ForgeMonster.onDeath

function ForgeMonster:onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	if not Family.forgeBoost then
		return upstreamOnDeath(self, creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	end
	if not creature then
		return true
	end
	local stack = creature:getForgeStack()
	if stack <= 0 then
		return true
	end
	local amount = Family.forgeDustAmount(stack)
	for _, player in ipairs(Family.forgeDustReceivers(killer or mostDamageKiller)) do
		Family.forgeGiveDust(player, amount)
	end
	return true
end

-- ---------------------------------------------------------------------------
-- Influenced creatures near players
-- ---------------------------------------------------------------------------

local rolled = {} -- creature id -> true once it had its roll

local function nearAnyPlayer(position, players)
	for _, player in ipairs(players) do
		local p = player:getPosition()
		if p.z == position.z and math.abs(p.x - position.x) <= FAR and math.abs(p.y - position.y) <= FAR then
			return true
		end
	end
	return false
end

-- Clears one randomly placed influenced creature far from every player, so
-- the one near a player fits under forgeInfluencedLimit.
function Family.forgeMakeRoom(players)
	local ids = Game.getInfluencedMonsters()
	local limit = configManager.getNumber(configKeys.FORGE_INFLUENCED_CREATURES_LIMIT)
	if #ids < limit then
		return true
	end
	local start = math.random(#ids)
	for i = 0, #ids - 1 do
		local id = ids[(start + i - 1) % #ids + 1]
		local monster = Monster(id)
		if not monster then
			Game.removeInfluencedMonster(id)
			return true
		end
		local stack = monster:getForgeStack()
		if stack > 0 and stack < 15 and not nearAnyPlayer(monster:getPosition(), players) then
			monster:clearFiendishStatus() -- resets influenced creatures too
			Game.removeInfluencedMonster(id)
			return true
		end
	end
	return false
end

function Family.forgeRollMonster(monster, players)
	local id = monster:getId()
	if rolled[id] then
		return false
	end
	rolled[id] = true
	if monster:getMaster() or monster:getForgeStack() > 0 then
		return false
	end
	local tile = Tile(monster:getPosition())
	if not tile or tile:hasFlag(TILESTATE_NOLOGOUT) or tile:hasFlag(TILESTATE_PROTECTIONZONE) then
		return false
	end
	if math.random() * 100 >= Family.forgeNearChance then
		return false
	end
	if not Family.forgeMakeRoom(players) then
		return false
	end
	return Game.addInfluencedMonster(monster, math.random(Family.forgeNearStages[1], Family.forgeNearStages[2])) == true
end

function Family.forgeCheckNearPlayers()
	local players = Game.getPlayers()
	local made = 0
	for _, player in ipairs(players) do
		local spectators = Game.getSpectators(player:getPosition(), false, false, NEAR_X, NEAR_X, NEAR_Y, NEAR_Y)
		for _, creature in ipairs(spectators) do
			local monster = creature:getMonster()
			if monster and Family.forgeRollMonster(monster, players) then
				made = made + 1
			end
		end
	end
	return made
end

local near = GlobalEvent("FamilyForgeNearPlayers")
local sweeps = 0

function near.onThink(interval)
	if not Family.forgeBoost then
		return true
	end
	Family.forgeCheckNearPlayers()
	sweeps = sweeps + 1
	if sweeps % 300 == 0 then -- every 10 minutes: forget creatures that are gone
		for id in pairs(rolled) do
			if not Monster(id) then
				rolled[id] = nil
			end
		end
	end
	return true
end

near:interval(2000)
near:register()

-- ---------------------------------------------------------------------------
-- Dust limit
-- ---------------------------------------------------------------------------

function Family.forgeRaiseDustLimit(player)
	if not Family.forgeBoost or not Family.forgeFullDustLimit then
		return false
	end
	local max = configManager.getNumber(configKeys.FORGE_MAX_DUST)
	local level = player:getForgeDustLevel()
	if level < max then
		player:addForgeDustLevel(max - level)
		return true
	end
	return false
end

local login = CreatureEvent("FamilyForgeDustLimit")

function login.onLogin(player)
	Family.forgeRaiseDustLimit(player)
	return true
end

login:register()

-- ---------------------------------------------------------------------------
-- Tier prices (after data/scripts/systems/item_tiers.lua, which loads later)
-- ---------------------------------------------------------------------------

function Family.forgeApplyPrices()
	local tiers = 0
	for classId, list in pairs(Family.forgePrices) do
		local classification = Game.createItemClassification(classId)
		for tier, price in ipairs(list) do
			classification:addTier(tier, price.core, price.regular, price.fusion or 0, price.transfer or 0)
			tiers = tiers + 1
		end
	end
	return tiers
end

local startup = GlobalEvent("FamilyForgeBoostStartup")

function startup.onStartup()
	if not Family.forgeBoost then
		logger.info("[Family] forge boost: off")
		return true
	end
	local tiers = Family.forgeApplyPrices()
	logger.info("[Family] forge boost: dust x{}, {}% influenced near players, dust limit {}, {} tier prices, influenced {}, fiendish {}, success {}%+{}%, core {} slivers", Family.forgeDustMultiplier, Family.forgeNearChance, configManager.getNumber(configKeys.FORGE_MAX_DUST), tiers, configManager.getNumber(configKeys.FORGE_INFLUENCED_CREATURES_LIMIT), configManager.getNumber(configKeys.FORGE_FIENDISH_CREATURES_LIMIT), configManager.getNumber(configKeys.FORGE_BASE_SUCCESS_RATE), configManager.getNumber(configKeys.FORGE_BONUS_SUCCESS_RATE), configManager.getNumber(configKeys.FORGE_CORE_COST))
	return true
end

startup:register()
