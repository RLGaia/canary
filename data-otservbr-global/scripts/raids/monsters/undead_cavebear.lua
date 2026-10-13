-- FAMILY: own name and zone (upstream reuses "farmine.draptor", so one of the
-- two raids replaced the other and both shared one zone)
local zone = Zone("undead-cavebear")
zone:addArea(Position(31909, 32554, 7), Position(31983, 32579, 7))

local raid = Raid("undead-cavebear", {
	zone = zone,
	allowedDays = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
	minActivePlayers = 2,
	initialChance = 0.02,
	targetChancePerDay = 0.02,
	maxChancePerCheck = 0.6,
	minGapBetween = "12h",
})

for i = 1, 3 do
	raid
		:addSpawnMonsters({
			{
				name = "Undead Cavebear",
				amount = 3,
			},
		})
		:autoAdvance("2m")
end

raid:register()
