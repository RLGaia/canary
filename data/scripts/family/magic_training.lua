-- Gaia Family server: faster magic level training (2026-10-23). Ours, not upstream.
--
-- Asked by Rodrigo ("magic level is very slow on statues and dummies").
--
-- Statues (offline training, also house beds): upstream counts only the
-- vocation's mana regeneration as mana spent (Master Sorcerer 1 mana per
-- second, Royal Paladin 0.67, Elite Knight 0.33, then x rateOfflineTrainingSpeed),
-- which made magic level about 300 times slower than on an exercise dummy,
-- while melee on a statue is about 14 times slower than on a dummy. Now every
-- second away counts statueMagicManaPerSecond mana spent, for every vocation:
-- 600 / 14 at first (2026-10-23), then 600 / 7 the same evening when every
-- statue skill was made twice as fast (halved hours). This value already
-- includes rateOfflineTrainingSpeed. The magic level stages of
-- solo_balance.lua (12/9/7/4) apply on top, as before.
-- Rough hours away: sorcerer/druid ML 60 to 90 about 37 h (upstream regeneration
-- 1,588 h), 90 to 100 about 107 h; paladin 25 to 30 about 21 h; monk 30 to 40
-- about 64 h; knight 8 to 10 about 11 h.
--
-- Exercise dummies (and training rods/wands): every hit counts
-- exerciseMagicManaPerHit mana spent (upstream 600), times the dummy rate.
-- Hits come once a second here (rateExerciseTrainingSpeed 2). Rough hours:
-- sorcerer/druid ML 60 to 90 about 2.6 h, 90 to 100 about 7.6 h, 100 to 110
-- about 20 h; paladin 30 to 35 about 11 h; monk 30 to 40 about 4.6 h.
--
-- The changes are marked FAMILY: in
-- data/scripts/creaturescripts/player/offline_training.lua and
-- data/scripts/actions/items/exercise_training_weapons.lua.
--
-- Switches: nil restores upstream (Family.statueMagicManaPerSecond = nil uses
-- mana regeneration, Family.exerciseMagicManaPerHit = nil uses 600).

Family = Family or {}
Family.statueMagicManaPerSecond = 600 / 7
Family.exerciseMagicManaPerHit = 1200

local report = GlobalEvent("FamilyMagicTrainingReport")

function report.onStartup()
	logger.info("[Family] magic training: statue {} mana per second, exercise {} mana per hit", Family.statueMagicManaPerSecond and string.format("%.1f", Family.statueMagicManaPerSecond) or "regeneration (upstream)", tostring(Family.exerciseMagicManaPerHit or 600))
	return true
end

report:register()
