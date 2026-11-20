-- FAMILY: Kissing a Pig Quest (ours, 2026-11-20): upstream had no quest. TibiaWiki EN says the quest
-- has a log, BR that it changes only with the last kiss; texts are ours. Mission id 11274.
-- The quest: lib/others/family_kissing_pig.lua.
local S = Storage.Quest.U8_1.KissingAPig

return {
	name = "Kissing a Pig",
	startStorageId = S.Questline,
	startStorageValue = 1,
	missions = {
		{
			name = "The Best Kisser in the Land",
			storageId = S.Questline,
			missionId = 11274,
			startValue = 1,
			endValue = 2,
			states = {
				[1] = "Shantalla, a talking pig on the farm south of the Thais magic shop, says she is a princess cursed by a witch. Only a kiss of the best kisser in the land can lift the curse. Learn all you can about kissing in the cities, the countryside and even dangerous places, then kiss her again.",
				[2] = "You became the best kisser in the land. Shantalla was no princess, just a talking pig that loves to kiss, but she told you about the Firlefanz in a chest in the basement of her farm.",
			},
		},
	},
}
