-- FAMILY (2026-11-20, Vampire Hunter Quest review): TibiaWiki EN's raid message, the first fight in the
-- hall on floor 14 and the second one in his sanctuary below (lib/others/family_vampire_hunter.lua,
-- scripts/family/vampire_lords.lua). Upstream put him straight into the sanctuary, without a message.
local familyPale = Family and Family.vampireHunter and FamilyVampire and FamilyVampire.paleCount

local zone = Zone("drefia.the-pale-count")
if familyPale then
	zone:addArea(Position(familyPale.hall.x - 1, familyPale.hall.y - 1, familyPale.hall.z), Position(familyPale.hall.x + 1, familyPale.hall.y + 1, familyPale.hall.z))
else
	zone:addArea(Position(32968, 32419, 15), Position(32970, 32421, 15))
end

local raid = Raid("drefia.the-pale-count", {
	zone = zone,
	allowedDays = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },
	minActivePlayers = 3,
	initialChance = 0.01,
	targetChancePerDay = 0.02,
	maxChancePerCheck = 0.7,
})

if familyPale then
	raid:addBroadcast(familyPale.message):autoAdvance("1s")
	raid
		:addSpawnMonsters({
			{
				name = "The Pale Count",
				amount = 1,
				position = familyPale.hall,
				event = familyPale.event,
			},
		})
		:autoAdvance("24h")
else
	raid
		:addSpawnMonsters({
			{
				name = "The Pale Count",
				amount = 1,
				position = Position(32969, 32420, 15),
			},
		})
		:autoAdvance("24h")
end

raid:register()
