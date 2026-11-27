-- FAMILY: The Isle of Evil Quest (ours, 2026-11-27): upstream had no quest log for it. Texts ours
-- (lib/others/family_isle_of_evil.lua). Mission id 11299.
local S = Storage.Quest.U8_5.TheIsleOfEvil

return {
	name = "The Isle of Evil",
	startStorageId = S.Mission,
	startStorageValue = 1,
	missions = {
		{
			name = "The Isle of Evil",
			storageId = S.Mission,
			missionId = 11299,
			startValue = 1,
			endValue = 10,
			states = {
				[1] = "Rapanaio in Kazordoon believes in an Isle of Evil and needs a hero. Ask him about your mission.",
				[2] = "Catch a mechanical fish in the sewers of Yalahar with Rapanaio's mechanical fishing rod, using nails as bait.",
				[3] = "Bring Rapanaio 10 vials of rum. Only vials fit into his machine.",
				[4] = "Bring Rapanaio a vial of fruit juice.",
				[5] = "Ask Scutty in the technomancers' workshop of Kazordoon about the machine for Rapanaio.",
				[6] = "Get the nautical map of the Explorer Society from Mortimer in Northport, or rather from the bandits who stole it.",
				[7] = "Meet Rapanaio downstairs at his secret weapon.",
				[8] = "Fight your way to the lair of evil on the isle and destroy its master.",
				[9] = "You slew the Evil Mastermind. Show his fan club membership card to King Tibianus.",
				[10] = "King Tibianus thanked his greatest admirer. The world is safe from the Isle of Evil.",
			},
		},
	},
}
