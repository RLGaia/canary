-- FAMILY: Horse Station (lib/others/family_horse_station.lua): groups of 0-3 wild horses every 3 hours near the Thais Troll Cave entrance, as in Tibia (upstream: always 3, anywhere in a wide area)
if Family and Family.horseStation and FamilyHorseStation then
	local H = FamilyHorseStation
	local familyZone = Zone("thais.wild-horses")
	familyZone:addArea(Position(H.area.from.x, H.area.from.y, H.area.from.z), Position(H.area.to.x, H.area.to.y, H.area.to.z))

	local familyRaid = Raid("thais.wild-horses", {
		zone = familyZone,
		allowedDays = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
		minActivePlayers = 0,
		initialChance = 30,
		targetChancePerDay = 50,
		maxChancePerCheck = 50,
		maxChecksPerDay = 2,
		minGapBetween = "23h",
	})

	for group = 1, H.groups do
		familyRaid
			:addStage({
				start = function()
					-- the first group has at least one horse (ours), the others 0-3 (TibiaWiki EN/BR)
					local amount = math.random(group == 1 and 1 or 0, H.maxPerGroup)
					if amount > 0 then
						familyRaid:spawnMonsters({ name = "Wild Horse", amount = amount })
					end
				end,
			})
			:autoAdvance(H.waveGap)
	end

	familyRaid:register()
	return
end

local zone = Zone("thais.wild-horses")
zone:addArea(Position(32456, 32193, 7), Position(32491, 32261, 7))
zone:addArea(Position(32431, 32240, 7), Position(32464, 32280, 7))

local raid = Raid("thais.wild-horses", {
	zone = zone,
	allowedDays = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
	minActivePlayers = 0,
	initialChance = 30,
	targetChancePerDay = 50,
	maxChancePerCheck = 50,
	maxChecksPerDay = 2,
	minGapBetween = "23h",
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
