local zone = Zone("nargor.diblis")
zone:addArea(Position(32008, 32794, 10), Position(32010, 32797, 10))

local raid = Raid("nargor.diblis", {
	zone = zone,
	allowedDays = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
	minActivePlayers = 3,
	initialChance = 0.02,
	targetChancePerDay = 0.02,
	maxChancePerCheck = 0.8,
})

raid
	:addSpawnMonsters({
		{
			name = "Diblis The Fair",
			amount = 1,
			position = Position(32009, 32795, 10),
			-- FAMILY: may come with 0-3 banshees (TibiaWiki EN), lib/others/family_vampire_hunter.lua
			spawn = FamilyVampire and FamilyVampire.companions("Banshee", 0, 3),
		},
	})
	:autoAdvance("24h")

raid:register()
