local zone = Zone("drefia.arachir")
zone:addArea(Position(32963, 32399, 12), Position(32965, 32401, 12))

local raid = Raid("drefia.arachir", {
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
			name = "Arachir the Ancient One",
			amount = 1,
			position = Position(32964, 32400, 12),
			-- FAMILY: comes with 3 vampires (TibiaWiki BR; EN "up to 4"), lib/others/family_vampire_hunter.lua
			spawn = FamilyVampire and FamilyVampire.companions("Vampire", 3, 3),
		},
	})
	:autoAdvance("24h")

raid:register()
