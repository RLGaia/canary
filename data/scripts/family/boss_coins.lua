-- Gaia Family server: bosses drop Tibia Coins (2026-10-18). Ours, not
-- upstream. Asked by Rodrigo; amounts chosen with him.
--
-- Every boss (in the Bosstiary or with a reward chest) drops Tibia Coins, the
-- stackable item that adds transferable coins to the account when used. The
-- amount follows the boss's hit points (its difficulty; the Bosstiary class
-- only says how often a boss can be fought):
--
--   hit points          coins
--   up to 10,000        1-2
--   10,001-50,000       2-4
--   50,001-150,000      4-8
--   150,001-500,000     8-15
--   over 500,000        15-30
--
-- The coins always drop. With a reward chest each player who helped gets his
-- own. Hit points are those of the creature files (before bossHP of
-- config.family.lua). Boss parts and phases get nothing: creatures with no
-- loot at all (Heart of Destruction's disruptions, the Wrath of the Emperor
-- snakes, Destabilized Ferumbras...) and helpers with no experience outside
-- the Bosstiary (Weakened Demon...). Loot added at startup by other files
-- counts: the coins are added right after every startup script ran.
-- One coin is worth 5,000 gold at the Coin Brokers.
--
-- Switch: Family.bossCoins; tiers in Family.bossCoinTiers.

Family = Family or {}
Family.bossCoins = true

Family.bossCoinTiers = {
	{ maxHealth = 10000, min = 1, max = 2 },
	{ maxHealth = 50000, min = 2, max = 4 },
	{ maxHealth = 150000, min = 4, max = 8 },
	{ maxHealth = 500000, min = 8, max = 15 },
	{ maxHealth = math.huge, min = 15, max = 30 },
}

local TIBIA_COINS = 22118

-- Coins for a monster type: min, max (nil when it gets none).
function Family.bossCoinsFor(mType)
	local raceId = mType:bossRaceId() or 0
	local isBoss = raceId > 0 or mType:isRewardBoss()
	if not isBoss then
		return nil
	end
	if raceId == 0 and (mType:experience() or 0) == 0 then
		return nil -- a helper of a boss fight
	end
	local loot = mType:getLoot() or {}
	if #loot == 0 then
		return nil -- a part or phase of a boss fight
	end
	local health = mType:maxHealth() or 0
	for _, tier in ipairs(Family.bossCoinTiers) do
		if health <= tier.maxHealth then
			return tier.min, tier.max
		end
	end
end

local startup = GlobalEvent("FamilyBossCoins")

local function addCoins()
	local count, byTier = 0, {}
	for _, mType in pairs(Game.getMonsterTypes()) do
		local min, max = Family.bossCoinsFor(mType)
		if min then
			local present = false
			for _, loot in ipairs(mType:getLoot() or {}) do
				present = present or loot.itemId == TIBIA_COINS
			end
			if not present then
				mType:createLoot({ { id = TIBIA_COINS, chance = 100000, minCount = min, maxCount = max } })
				count = count + 1
				byTier[max] = (byTier[max] or 0) + 1
			end
		end
	end
	local parts = {}
	for _, tier in ipairs(Family.bossCoinTiers) do
		parts[#parts + 1] = string.format("%d-%d: %d", tier.min, tier.max, byTier[tier.max] or 0)
	end
	logger.info("[Family] boss coins: {} bosses ({})", count, table.concat(parts, ", "))
end

function startup.onStartup()
	if Family.bossCoins then
		addEvent(addCoins, 0) -- after the other startup scripts (loot they add counts)
	end
	return true
end

startup:register()
