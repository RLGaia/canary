-- Gaia Family server: achievements that upstream never gave (2026-10-20). Ours,
-- not upstream.
--
-- The Hero of Rathleton reward chest (Maxxen's chest) asked for "The Professors
-- Nut", a name that does not exist, so "The Professor's Nut" was never given.
-- The chest script is fixed (FAMILY: in hero_of_rathleton/actions_reward.lua);
-- characters who opened the chest before get the achievement at login.

local login = CreatureEvent("FamilyAchievementFixesLogin")

function login.onLogin(player)
	if player:getStorageValue(24850) >= 1 and not player:hasAchievement("The Professor's Nut") then
		player:addAchievement("The Professor's Nut")
	end
	return true
end

login:register()
