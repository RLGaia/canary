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

-- Boss cooldown: none (since 2026-10-17; 1 hour before, upstream 20 hours).
-- solo_balance.lua also caps levers that set their own, longer cooldown, and
-- data-otservbr-global/scripts/family/boss_cooldown.lua removes the rest.
bossDefaultTimeToFightAgain = 0

-- Conveniences
autoLoot = true                 -- loot goes straight to your loot containers
autoBank = false                -- looted gold goes to the backpack (true until 2026-10-14); 100 coins change up by
                                -- themselves (data/scripts/family/coin_change.lua)
preyFreeThirdSlot = true        -- third Prey slot without Tibia Coins
taskHuntingFreeThirdSlot = true -- third Hunting Task slot without Tibia Coins
-- Since 2026-10-19 (asked by Rodrigo): rerolling the creature list is always
-- free, and "choose from the full list" costs no Prey Wildcards (upstream 5),
-- so you can always pick the creature you want. Side effects: locking a Prey
-- slot (keep creature and bonus when it runs out) and cancelling a Hunting
-- Task are free too. Same day: rerolling a Prey bonus or a Hunting Task reward
-- rarity costs no Wildcard either (upstream 1), so automatic bonus reroll when
-- a slot runs out is free as well.
preyBonusRerollPrice = 0
taskHuntingBonusRerollPrice = 0
preyFreeRerollTime = 0
preyRerollPricePerLevel = 0
preySelectListPrice = 0
taskHuntingFreeRerollTime = 0
taskHuntingRerollPricePerLevel = 0
taskHuntingSelectListPrice = 0
-- Since 2026-10-21 (Rodrigo): after claiming a Hunting Task the slot can take
-- a new creature at once (upstream waits 20 hours), and claimed Hunting Task
-- Points are multiplied by 10 (data/scripts/family/hunting_task_points.lua).
taskHuntingLimitedTasksExhaust = 0

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

-- Training: exercise weapons hit twice as fast (one hit per second).
-- Offline training (statues, beds) is 4x (2x until 2026-10-23, halved hours;
-- magic level and shielding follow in data/scripts/family/magic_training.lua
-- and offline_training.lua). solo_balance.lua makes exercise weapons last forever.
rateExerciseTrainingSpeed = 2.0
rateOfflineTrainingSpeed = 4.0

-- Respawn: the map's own times (classic hunts 90 s, newer areas 60 s).
-- 2x (45 s / 30 s) from 2026-10-12 to 2026-10-24; Rodrigo found it too fast.
-- Whole numbers only (the engine reads an integer). The boosted creature of
-- the day still respawns 2x faster (engine rule).
rateSpawn = 1

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

-- ===========================================================================
-- Exaltation Forge (2026-10-25). The rest of the boost (dust per kill, party
-- dust, influenced creatures near players, dust limit, tier prices) is in
-- data/scripts/family/forge_boost.lua.
-- ===========================================================================
-- Influenced creatures placed at random anywhere on the map (upstream 300 of
-- about 83,000 creatures). The ones near players come from forge_boost.lua.
forgeInfluencedLimit = 1500
-- Fiendish creatures alive at once (upstream 4; Tibia's Exaltation Overload 8).
forgeFiendishLimit = 8
-- Fusion success: 65% (upstream 50%), 80% with an exalted core (+15 as upstream).
forgeBaseSuccessRate = 65
-- Slivers per exalted core (upstream 50 = 1,000 dust; now 500 dust).
forgeCoreCost = 25

-- ===========================================================================
-- Store pictures (2026-10-24). The client draws items, mounts and outfits
-- itself, but category icons, home banners and offers like beds, blessings,
-- Premium Time and boosts are pictures it downloads from this address
-- (<url>64/<offer>.png, <url>13/<category>.png). Upstream points at a web
-- server on 127.0.0.1 that we do not run, so those offers had no picture.
-- The pictures are in family/store-images (this repository is public, so
-- GitHub serves them to both PCs); tools/family/store_images/check.py lists
-- and fills them when the Store catalog changes.
-- ===========================================================================
coinImagesURL = "https://raw.githubusercontent.com/RLGaia/canary/family/family/store-images/"
