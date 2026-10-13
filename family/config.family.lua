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

-- Loot: 2x, rare items first so the corpse never drops them for lack of space.
rateLoot = 2
sortLootByChance = true

-- Bosses ("moderate"): 50% health, 70% damage, normal defense.
-- Applies to every monster with a Bosstiary class; normal monsters are unchanged.
rateBossHealth = 0.5
rateBossAttack = 0.7
rateBossDefense = 1.0

-- Boss cooldown: 4 hours instead of 20. solo_balance.lua also caps levers
-- that set their own, longer cooldown.
bossDefaultTimeToFightAgain = 4 * 60 * 60

-- Conveniences
autoLoot = true                 -- loot goes straight to your loot containers
autoBank = true                 -- looted gold goes straight to the bank
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
