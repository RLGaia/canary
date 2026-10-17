-- FAMILY: Measuring Tibia (Cyclopedia map discovery). Ours, not upstream: the
-- discovery itself is in data/scripts/family/map_discovery.lua.
local function areasText(player)
	local done = FamilyDiscovery and FamilyDiscovery.completedAreas(player) or 0
	local total = FamilyDiscovery and FamilyDiscovery.countedTotal or 20
	local text = string.format("You have fully discovered %d of %d areas of Tibia. \z
		An area is fully discovered when all its subareas are. ", done, total)
	if done >= 20 then
		return text .. "Charos in the Adventurers' Guild gives the Discoverer outfit with both addons for it."
	end
	return text .. "Charos in the Adventurers' Guild gives the Discoverer outfit for 10 areas, \z
		its first addon for 15 and the second addon for 20."
end

local quest = {
	name = "Measuring Tibia",
	startStorageId = Storage.Quest.U11_80.MeasuringTibia.Questline,
	startStorageValue = 1,
	missions = {
		[1] = {
			name = "A Speck of Land",
			storageId = Storage.Quest.U11_80.MeasuringTibia.SpeckOfLand,
			missionId = 11101,
			startValue = 1,
			endValue = 2,
			description = function(player)
				if FamilyDiscovery then
					return FamilyDiscovery.speckText(player)
				end
				return "Discover the subareas of Tibia: find 7 points of interest in each of them."
			end,
		},
		[2] = {
			name = "The Wide World",
			storageId = Storage.Quest.U11_80.MeasuringTibia.WideWorld,
			missionId = 11102,
			startValue = 0,
			endValue = 20,
			description = areasText,
		},
	},
}

return quest
