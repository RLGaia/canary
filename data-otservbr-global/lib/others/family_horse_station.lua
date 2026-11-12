-- Gaia Family server: Horse Station wild horses tamed as in Tibia (2026-11-12).
-- Ours, not upstream. Reported by Rodrigo: his father's wild horse vanished
-- after a failed sugar oat ("The horse runs away." removed it, about half of
-- the failures), so soon only one horse was left.
--
-- Now (TibiaWiki EN Sugar Oat, Wild Horse and Horse Station World Change
-- pages; TibiaWiki BR Horse Station World Change page from Rodrigo):
-- * Every sugar oat is eaten and the horse stays: "The wild horse happily
--   munches the sugar oat and runs on." (EN). Success: "The horse eats the
--   sugar oat and accepts you as its new master." (EN).
-- * Chance 25% per oat (chosen by Rodrigo; upstream 15%, Tibia about 1-3%:
--   EN says 30 to over 180 oats per horse).
-- * Wild horses come in groups of 0-3 every 3 hours (BR: up to 3; EN: 0-3)
--   near the Thais Troll Cave entrance, 32470,32259 (BR and EN). Upstream: 3
--   every time, at random over a wide area east of Thais. The first group of
--   a raid has at least one horse (ours), so the raid is never empty.
--   The raid still takes turns with the other rare raids (rare_creatures.lua).
-- Not done: the stable stages (renting horses at Palomino and Appaloosa
-- keeps the horses in), so the horses are always "on the loose" here.
--
-- Used by FAMILY: edits in scripts/actions/mounts/mounts.lua and
-- scripts/raids/thais/wild_horses.lua (scripts/raids/monsters/wild_horses.lua,
-- a second upstream copy of the same raid, is skipped).
-- Switch: Family.horseStation (false = upstream rules).

Family = Family or {}
Family.horseStation = true

FamilyHorseStation = {
	chance = 25, -- percent per sugar oat
	failMessage = "The wild horse happily munches the sugar oat and runs on.",
	successMessage = "The horse eats the sugar oat and accepts you as its new master.",
	-- spawn area around the Troll Cave entrance (32470,32259,7)
	area = { from = { x = 32464, y = 32253, z = 7 }, to = { x = 32477, y = 32265, z = 7 } },
	maxPerGroup = 3,
	groups = 7, -- one every waveGap (upstream: 7 waves)
	waveGap = "3h",
}
