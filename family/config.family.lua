-- Family server overrides
--
-- start-server.ps1 builds config.lua as:
--   config.lua.dist (upstream defaults, untouched)
--   + this file (family gameplay/server choices, committed to Git)
--   + machine settings generated from family\local.env (IP, DB password)
-- Later assignments win, so anything set here overrides config.lua.dist.
-- Edit THIS file, never config.lua (it is regenerated on every start).

-- Upstream regenerates docs/lua-api on every start when this is true, which
-- would leave tracked files modified in Git. We don't need the API docs.
generateLuaApiDocs = false

ownerName = "Gaia Family"
location = "South America"

-- ===========================================================================
-- Solo / duo balance (chosen 2026-10-12). The level curves for experience,
-- skills and magic live in data/scripts/family/solo_balance.lua, together
-- with the boss-lever and Tibia Coin rules.
-- ===========================================================================

-- Accounts are always premium: all areas, promotions, houses and travel.
freePremium = true

-- No player-vs-player combat: no skulls, no accidental PvP.
worldType = "no-pvp"

-- Experience, skills and magic follow the level curves in solo_balance.lua.
rateUseStages = true

-- Loot: 3x (2x until 2026-10-14): every item's drop chance is tripled, up to
-- 100%; a stack (gold coins too) drops more often, not bigger. Rare items
-- first so the corpse never drops them for lack of space.
rateLoot = 3
sortLootByChance = true

-- Bosses ("moderate"): 50% health, 70% damage, normal defense.
-- Applies to every monster with a Bosstiary class; normal monsters are unchanged.
rateBossHealth = 0.5
rateBossAttack = 0.7
rateBossDefense = 1.0

-- Boss cooldown: 1 hour instead of 20. solo_balance.lua also caps levers
-- that set their own, longer cooldown.
bossDefaultTimeToFightAgain = 60 * 60

-- Conveniences
autoLoot = true                 -- loot goes straight to your loot containers
autoBank = false                -- looted gold goes to the backpack (true until 2026-10-14); 100 coins change up by
                                -- themselves (data/scripts/family/coin_change.lua)
preyFreeThirdSlot = true        -- third Prey slot without Tibia Coins
taskHuntingFreeThirdSlot = true -- third Hunting Task slot without Tibia Coins

-- ===========================================================================
-- Batch 2 (2026-10-12): death, training and respawn
-- ===========================================================================

-- Death: no experience, skill or item loss. You only wake up in the temple.
-- 0 = lose nothing (upstream -1 = the normal Tibia formula).
deathLosePercent = 0
-- Free full blessings below this level, so equipment never drops on death.
-- solo_balance.lua also turns off item drops on death for characters
-- without a vocation (Dawnport).
adventurersBlessingLevel = 100000

-- Training: exercise weapons and offline training (statues) work twice as
-- fast. solo_balance.lua makes exercise weapons last forever.
rateExerciseTrainingSpeed = 2.0
rateOfflineTrainingSpeed = 2.0

-- Respawn: monsters come back twice as fast (classic hunts: 90 s -> 45 s).
rateSpawn = 2

-- ===========================================================================
-- Houses (2026-10-13): Cyclopedia -> Houses -> Bid buys a free house at once
-- (data/scripts/family/house_instant_buy.lua), or !buyhouse while looking at
-- the door. Type !house in game for a short guide.
-- ===========================================================================

-- Fallback when an auction does start (instant purchase switched off): it ends
-- at the next server save time and the house is handed over at the next start.
toggleCyclopediaHouseAuction = true
daysToCloseBid = 0
-- Price: the house's rent, paid once from the bank. houseRentRate scales every
-- rent; 0.65 makes ordinary houses cost about 2,000 gold per square meter.
houseRentRate = 0.65
-- !buyhouse charges the same: 0 per square meter + 1x the (scaled) rent.
housePriceEachSQM = 0
housePriceRentMultiplier = 1.0
-- No rent after buying, and a house is never lost for not logging in.
houseRentPeriod = "never"
houseLoseAfterInactivity = 0
-- No minimum level for !buyhouse (Cyclopedia has none).
houseBuyLevel = 0

-- ===========================================================================
-- Saving (2026-10-13): data/scripts/family/auto_save.lua saves the whole
-- server every 15 minutes, without cleaning the map. Every character can also
-- type /save in game (FAMILY: edit in data/scripts/talkactions/god/save.lua).
-- ===========================================================================
-- Off: upstream's interval save (data/scripts/globalevents/save_interval.lua)
-- never ran with globalServerSaveTime = "06:00:00" (it expects "HH:MM"), and if
-- fixed it would also clean the map (delete items on the ground).
toggleSaveInterval = false

-- ===========================================================================
-- Party (2026-10-17): shared experience works at any level difference.
-- ===========================================================================
-- Upstream the lowest member must be at least 2/3 of the highest level
-- (multiplier 1.5: minimum = highest / 1.5). With 10000 the minimum is 1, so
-- every level shares. The other rules stay: members within 30 squares of the
-- leader (and one floor) and active in the fight in the last 2 minutes.
partyShareRangeMultiplier = 10000
