-- Gaia Family server: party experience is shared anywhere (2026-10-17). Ours,
-- not upstream.
--
-- Upstream, shared experience (once switched on in the party menu) only works
-- while every member is within 30 squares of the leader (one floor up or down)
-- and took part in the fight in the last 2 minutes; otherwise each player keeps
-- only the experience of their own kills. The level rule is already off
-- (partyShareRangeMultiplier in family/config.family.lua).
--
-- Here, when shared experience is switched on but the server refuses it for
-- distance or inactivity, the experience is shared anyway, the same way:
-- each kill's experience is multiplied by the party bonus (more for different
-- vocations) and divided by the party size, and every member gets that share
-- with their own stage, stamina, prey, boosted creature and XP boost bonuses,
-- wherever they are. The party icons may still show members as too far away or
-- inactive; that is only the display.
--
-- Switch: Family.partyShareAnywhere (false = upstream rules).

Family = Family or {}
Family.partyShareAnywhere = true

-- Same formula as Party:onShareExperience (data/events/scripts/party.lua).
local function shareOf(party, exp)
	local vocations = party:getUniqueVocationsCount()
	local size = party:getMemberCount() + 1
	local multiplier = (0.1 * (vocations ^ 2)) - (0.2 * vocations) + 1.3
	if size >= 4 then
		multiplier = multiplier - 0.1
	end
	return math.ceil((exp * multiplier) / size)
end

-- The bonuses Player:onGainExperience (data/events/scripts/player.lua) gives a
-- player for a kill, applied to a share that player did not kill himself.
local function finalExperience(member, target, exp)
	if target:getName():lower() == Game.getBoostedCreature():lower() then
		exp = exp * 2
	end
	if configManager.getBoolean(configKeys.PREY_ENABLED) then
		local monsterType = target:getType()
		if monsterType and monsterType:raceId() > 0 then
			exp = math.ceil((exp * member:getPreyExperiencePercentage(monsterType:raceId())) / 100)
		end
	end
	local xpBoostPercent = member:getXpBoostTime() > 0 and member:getXpBoostPercent() or 0
	local lowLevelBonus = member:getFinalLowLevelBonus()
	return math.floor((exp * (1 + xpBoostPercent / 100 + lowLevelBonus / 100)) * member:getFinalBonusStamina() * member:getFinalBaseRateExperience())
end

local sharing = false

-- Called for each player's own part of a kill. Returns the experience that
-- player keeps (before his own bonuses, which the server applies next).
function Family.partyShare(player, target, exp)
	if sharing or not Family.partyShareAnywhere or not target or target:isPlayer() or exp <= 0 then
		return exp
	end
	local party = player:getParty()
	if not party or not party:isSharedExperienceActive() or party:isSharedExperienceEnabled() then
		return exp -- not in a sharing party, or the server already shares it
	end
	local share = shareOf(party, exp)
	local members = party:getMembers() or {}
	members[#members + 1] = party:getLeader()
	sharing = true
	for _, member in ipairs(members) do
		if member and member:getId() ~= player:getId() then
			local amount = finalExperience(member, target, share)
			if amount > 0 then
				member:addExperience(amount, true)
			end
		end
	end
	sharing = false
	return share
end

local callback = EventCallback("FamilyPartyShareAnywhere")

function callback.playerOnGainExperience(player, target, exp, rawExp)
	return Family.partyShare(player, target, exp)
end

callback:register()

local report = GlobalEvent("FamilyPartyShareReport")

function report.onStartup()
	logger.info("[Family] party: shared experience at any distance and activity: {} (any level: partyShareRangeMultiplier {})", tostring(Family.partyShareAnywhere), configManager.getFloat(configKeys.PARTY_SHARE_RANGE_MULTIPLIER))
	return true
end

report:register()
