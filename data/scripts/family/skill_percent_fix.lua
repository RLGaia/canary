-- Gaia Family server: correct skill percentages after death (2026-10-20). Ours,
-- not upstream.
--
-- Reported by Rodrigo: after dying, sword and shielding showed 100% to the next
-- level. Nothing was lost (deathLosePercent = 0 keeps every skill try), but
-- Canary's death code works the percentage out against the tries of the
-- CURRENT skill level instead of the next one (src/creatures/players/
-- player.cpp, Player::death). The bar then shows the real progress times the
-- vocation's skill multiplier (knight x1.1: 91% shows as 100%, and above that
-- as 0%), until the next skill try or a full logout. The server program cannot
-- be changed here, so this script puts the right percentage back: it compares
-- each skill's percentage with its saved tries and rewrites only a wrong one
-- (same level, same tries). Checked at login and about once a second.
--
-- melee_skills.lua also reads the true percentage from here, so a wrong bar is
-- never copied between sword, axe and club.

Family = Family or {}
Family.fixSkillPercents = true

local SKILLS = { SKILL_FIST, SKILL_CLUB, SKILL_SWORD, SKILL_AXE, SKILL_DISTANCE, SKILL_SHIELD, SKILL_FISHING }

-- The real progress (0-100) of a skill towards its next level, from its tries.
function Family.trueSkillPercent(player, skill)
	local nextReq = player:getVocation():getRequiredSkillTries(skill, player:getSkillLevel(skill) + 1)
	if not nextReq or nextReq <= 0 then
		return 0
	end
	local percent = player:getSkillTries(skill) * 100 / nextReq
	return percent > 100 and 0 or percent
end

-- Rewrites the skills whose shown percentage is wrong. Returns how many.
function Family.fixSkillPercentsFor(player)
	if not Family.fixSkillPercents then
		return 0
	end
	local fixed = 0
	for _, skill in ipairs(SKILLS) do
		if math.abs(player:getSkillPercent(skill) - Family.trueSkillPercent(player, skill)) > 0.5 then
			player:setSkillLevel(skill, player:getSkillLevel(skill), player:getSkillTries(skill))
			fixed = fixed + 1
		end
	end
	return fixed
end

local login = CreatureEvent("FamilySkillPercentLogin")

function login.onLogin(player)
	Family.fixSkillPercentsFor(player)
	return true
end

login:register()

local think = EventCallback("FamilySkillPercentThink")

function think.playerOnThink(player, interval)
	Family.fixSkillPercentsFor(player)
end

think:register()
