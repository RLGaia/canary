local config = {
	["gaffir"] = {
		stor = Storage.Quest.U12_20.GraveDanger.GaffirKilled,
	},
	["custodian"] = {
		stor = Storage.Quest.U12_20.GraveDanger.CustodianKilled,
	},
	["guard captain quaid"] = {
		stor = Storage.Quest.U12_20.GraveDanger.QuaidKilled,
	},
	["scarlett etzel"] = {
		stor = Storage.Quest.U12_20.GraveDanger.ScarlettKilled,
	},
	["earl osam"] = {
		stor = Storage.Quest.U12_20.GraveDanger.Bosses.EarlOsam.Killed,
		extra = {
			stor = Storage.Quest.U12_20.GraveDanger.Graves.Cormaya,
			value = 2, -- FAMILY: 2 = visited (1 = to find), as the quest log reads it; was 1
		},
	},
	["count vlarkorth"] = {
		stor = Storage.Quest.U12_20.GraveDanger.Bosses.CountVlarkorth.Killed,
		extra = {
			stor = Storage.Quest.U12_20.GraveDanger.Graves.Edron,
			value = 2, -- FAMILY: 2 = visited (1 = to find), as the quest log reads it; was 1
		},
	},
	["sir baeloc"] = {
		stor = Storage.Quest.U12_20.GraveDanger.Bosses.BaelocNictros.Killed,
		extra = {
			stor = Storage.Quest.U12_20.GraveDanger.Graves.Darashia,
			value = 2, -- FAMILY: 2 = visited (1 = to find), as the quest log reads it; was 1
		},
	},
	["duke krule"] = {
		stor = Storage.Quest.U12_20.GraveDanger.Bosses.DukeKrule.Killed,
		extra = {
			stor = Storage.Quest.U12_20.GraveDanger.Graves.Thais,
			value = 2, -- FAMILY: 2 = visited (1 = to find), as the quest log reads it; was 1
		},
	},
	["lord azaram"] = {
		stor = Storage.Quest.U12_20.GraveDanger.Bosses.LordAzaram.Killed,
		extra = {
			stor = Storage.Quest.U12_20.GraveDanger.Graves.Ghostlands,
			value = 2, -- FAMILY: 2 = visited (1 = to find), as the quest log reads it; was 1
		},
	},
	["king zelos"] = {
		stor = Storage.Quest.U12_20.GraveDanger.Bosses.KingZelos.Killed,
	},
}

local grave_danger_death = CreatureEvent("grave_danger_death")

function grave_danger_death.onDeath(creature, corpse, killer, mostDamageKiller)
	local bossConfig = config[creature:getName():lower()]

	if not bossConfig then
		return true
	end

	local attackers = creature:getDamageMap()
	-- FAMILY: the Custodian's death gives one pass through his fire wall and a Cart Packed with Gold
	-- (scripts/family/cobra_bastion_secrets.lua)
	-- TibiaWiki BR: only those who dealt a good part of the damage get his passages (ours: 10%)
	local custodian = creature:getName():lower() == "custodian" and Family and Family.cobraBastion
	local earned = {}
	if custodian then
		local total = 0
		for _, entry in pairs(attackers) do
			total = total + (entry.total or 0)
		end
		for attackerId, entry in pairs(attackers) do
			earned[attackerId] = total <= 0 or (entry.total or 0) >= total * (Family.custodianShare or 0.1)
		end
	end
	if custodian and FamilyCobra and FamilyCobra.onCustodianDeath then
		local fought = {}
		for attackerId, _ in pairs(attackers) do
			local player = Player(attackerId)
			if player and earned[attackerId] then
				fought[#fought + 1] = player
			elseif player then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You did too little against the Custodian to pass his flames.") -- ours
			end
		end
		FamilyCobra.onCustodianDeath(fought)
	end
	for attackerId, _ in pairs(attackers) do
		local player = Player(attackerId)
		if player and custodian and not earned[attackerId] then
			player = nil
		end
		if player and player:getStorageValue(bossConfig.stor) < 1 then
			player:setStorageValue(bossConfig.stor, 1)

			if creature:getName():lower() == "scarlett etzel" then
				player:addAchievement("A Study in Scarlett")
				-- FAMILY: the quest log mission "The Order of the Cobra" is done (scripts/family/cobra_bastion.lua)
				player:setStorageValue(Storage.Quest.U12_20.GraveDanger.Cobra, 2)
			end

			if bossConfig.extra then
				player:setStorageValue(bossConfig.extra.stor, bossConfig.extra.value)
				local graves = player:getStorageValue(Storage.Quest.U12_20.GraveDanger.Graves.Progress)
				player:setStorageValue(Storage.Quest.U12_20.GraveDanger.Graves.Progress, graves + 1)
			end
		end
	end

	return true
end

grave_danger_death:register()
