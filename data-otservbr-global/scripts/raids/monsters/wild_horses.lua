-- FAMILY: Horse Station (lib/others/family_horse_station.lua): this second upstream copy of the raid would add its wide area to the same zone; the raid is defined in scripts/raids/thais/wild_horses.lua
if Family and Family.horseStation then
	return
end

local zone = Zone("thais.wild-horses")
zone:addArea(Position(32456, 32193, 7), Position(32491, 32261, 7))
zone:addArea(Position(32431, 32240, 7), Position(32464, 32280, 7))

local raid = Raid("thais.wild-horses", {
	zone = zone,
	allowedDays = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
	minActivePlayers = 3,
	initialChance = 30,
	targetChancePerDay = 50,
	maxChancePerCheck = 50,
	maxChecksPerDay = 2,
	minGapBetween = "12h",
})

for _ = 1, 7 do
	raid
		:addSpawnMonsters({
			{
				name = "Wild Horse",
				amount = 3,
			},
		})
		:autoAdvance("3h")
end

raid:register()
