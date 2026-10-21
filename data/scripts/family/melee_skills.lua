-- Gaia Family server: one shared melee skill (2026-10-17). Ours, not upstream.
--
-- Sword, axe and club fighting move together: whenever one of them goes up
-- (hunting, exercise weapons, training statues, offline training), the other
-- two are raised to the same level and the same progress towards the next
-- level. So training sword to 90 also gives axe 90 and club 90, and changing
-- weapons never costs anything. Nothing is ever lowered: the highest of the
-- three always wins. Fist fighting, distance, shielding and magic level stay
-- separate.
--
-- Checked at login and about once a second while playing (three numbers
-- compared; skills are only rewritten when one fell behind by at least 1% of
-- a level, so the client is not flooded with updates).
--
-- Switch: Family.sharedMeleeSkills (false = upstream: three separate skills;
-- skills already raised stay as they are).

Family = Family or {}
Family.sharedMeleeSkills = true

local MELEE = { SKILL_SWORD, SKILL_AXE, SKILL_CLUB }
local TOLERANCE = 1 -- percent of a level

-- Raises the melee skills that fell behind. Returns how many were changed.
function Family.syncMeleeSkills(player)
	if not Family.sharedMeleeSkills then
		return 0
	end
	local bestLevel, bestPercent = -1, 0
	-- FAMILY: the true percentage from the tries (skill_percent_fix.lua), not
	-- the shown one, which Canary gets wrong after a death.
	local function percentOf(skill)
		return Family.trueSkillPercent and Family.trueSkillPercent(player, skill) or player:getSkillPercent(skill)
	end
	for _, skill in ipairs(MELEE) do
		local level, percent = player:getSkillLevel(skill), percentOf(skill)
		if level > bestLevel or (level == bestLevel and percent > bestPercent) then
			bestLevel, bestPercent = level, percent
		end
	end
	local changed = 0
	local vocation = player:getVocation()
	for _, skill in ipairs(MELEE) do
		local level, percent = player:getSkillLevel(skill), percentOf(skill)
		if level < bestLevel or (level == bestLevel and percent < bestPercent - TOLERANCE) then
			local nextReq = vocation:getRequiredSkillTries(skill, bestLevel + 1)
			local tries = 0
			-- Very high levels for a vocation weak in that skill can need more
			-- tries than a number can hold; then only the level is copied.
			if nextReq and nextReq > 0 and nextReq < 2 ^ 53 then
				tries = math.ceil(nextReq * bestPercent / 100)
				if tries >= nextReq then
					tries = nextReq - 1
				end
			end
			player:setSkillLevel(skill, bestLevel, math.max(tries, 0))
			changed = changed + 1
		end
	end
	return changed
end

local login = CreatureEvent("FamilyMeleeSkillsLogin")

function login.onLogin(player)
	Family.syncMeleeSkills(player)
	return true
end

login:register()

local think = EventCallback("FamilyMeleeSkillsThink")

function think.playerOnThink(player, interval)
	Family.syncMeleeSkills(player)
end

think:register()

local report = GlobalEvent("FamilyMeleeSkillsReport")

function report.onStartup()
	logger.info("[Family] melee skills: sword, axe and club shared: {}", tostring(Family.sharedMeleeSkills))
	return true
end

report:register()
