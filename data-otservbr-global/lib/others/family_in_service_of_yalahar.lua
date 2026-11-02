-- Gaia Family server: In Service of Yalahar fixes (2026-11-02, asked by Rodrigo).
-- Upstream Canary v3.6.1 scripts the whole quest; this file holds what our fixes share.
--
-- Sources (checked 2026-11-02): TibiaWiki BR "In Service of Yalahar Quest" (page saved by
-- Rodrigo) and TibiaWiki EN "In Service of Yalahar Quest/Spoiler" (transcripts, achievements).
--
-- What changes for the players (details in FAMILY.md):
--   * Mission 02: the seven guards take their report in any order (upstream: one fixed order
--     around the city, so starting in the Magician Quarter, as both wikis allow, did nothing).
--   * Missions 03-08: the side taken in each mission is recorded (Side03-Side08) so that
--     Mission 09 can tell who was followed: Palimuth's words (EN) and the achievements Follower
--     of Palimuth, Follower of Azerus and Turncoat (EN), which upstream never gave.
--   * Mission 05: Morik can be called again when he is gone and you have no helmet (ours).
--   * Mission 06: Azerus gives a new ghost charm when yours was lost (ours).
--   * Reward room: the fourth chest (Yalahari Footwraps, EN) is placed by
--     scripts/family/in_service_of_yalahar.lua.
-- Plain bug fixes (notes chests, weapon matrix, ghost charm charges, NPC lines) are FAMILY edits
-- of the upstream files and do not depend on the switch.
--
-- Switch: Family.inServiceOfYalahar (false = upstream guard order, no side records, no
-- achievements, no Morik or charm replacement, no fourth chest).

Family = Family or {}
Family.inServiceOfYalahar = true

FamilyYalahar = FamilyYalahar or {}
local Y = FamilyYalahar
local S = Storage.Quest.FamilyInServiceOfYalahar
local Q = Storage.Quest.U8_4.InServiceOfYalahar
Y.S = S

Y.PALIMUTH = 1
Y.AZERUS = 2

local SIDE_KEYS = { [3] = S.Side03, [4] = S.Side04, [5] = S.Side05, [6] = S.Side06, [7] = S.Side07, [8] = S.Side08 }

function Y.setSide(player, mission, side)
	if Family.inServiceOfYalahar and SIDE_KEYS[mission] then
		player:setStorageValue(SIDE_KEYS[mission], side)
	end
end

-- Missions done for each side (3-8). Missions recorded before this fix are read from the
-- upstream storages where they tell the side (4 Mr. West, 5 Tamerin, 7 quara, 8 matrix).
function Y.sideCounts(player)
	local good, bad = 0, 0
	for mission = 3, 8 do
		local side = player:getStorageValue(SIDE_KEYS[mission])
		if side ~= Y.PALIMUTH and side ~= Y.AZERUS then
			local fallback = ({ [4] = Q.MrWestStatus, [5] = Q.TamerinStatus, [7] = Q.QuaraState, [8] = Q.MatrixState })[mission]
			side = fallback and player:getStorageValue(fallback) or -1
		end
		if side == Y.PALIMUTH then
			good = good + 1
		elseif side == Y.AZERUS then
			bad = bad + 1
		end
	end
	return good, bad
end

-- Mission 09 (TibiaWiki EN): all missions for the chosen side = Follower of that side; missions
-- for both sides = Turncoat; all missions for one side but the other one chosen = none.
function Y.decisionAchievement(player, chosen)
	if not Family.inServiceOfYalahar then
		return
	end
	local good, bad = Y.sideCounts(player)
	if good > 0 and bad > 0 then
		player:addAchievement("Turncoat")
	elseif chosen == Y.PALIMUTH and bad == 0 and good > 0 then
		player:addAchievement("Follower of Palimuth")
	elseif chosen == Y.AZERUS and good == 0 and bad > 0 then
		player:addAchievement("Follower of Azerus")
	end
end

-- Mission 02: may this guard take the report now? Records the guard. `upstreamOk` is the
-- upstream order check, used when the switch is off.
local GUARD_BITS = { tony = 1, hal = 2, bruce = 4, reed = 8, barry = 16, oliver = 32, peter = 64 }
function Y.guardCanReport(player, guard, upstreamOk)
	if not Family.inServiceOfYalahar then
		return upstreamOk
	end
	local line = player:getStorageValue(Q.Questline)
	if line < 7 or line > 13 then
		return false
	end
	local bit = GUARD_BITS[guard]
	local mask = math.max(0, player:getStorageValue(S.Guards))
	if not bit or mask % (bit * 2) >= bit then
		return false
	end
	player:setStorageValue(S.Guards, mask + bit)
	return true
end

function Y.told(player, bit)
	local mask = math.max(0, player:getStorageValue(S.Told))
	return mask % (bit * 2) >= bit
end

function Y.setTold(player, bit)
	if not Y.told(player, bit) then
		player:setStorageValue(S.Told, math.max(0, player:getStorageValue(S.Told)) + bit)
	end
end

-- Mission 06: is a ghost charm of the quest still in the game for this player?
Y.CARVING = Position(32776, 31062, 7)
local CHARM_IDS = { 8822, 8827 }
local PLACED_IDS = { 8823, 8824, 8825, 8859, 8827 }
function Y.hasGhostCharm(player)
	for _, id in ipairs(CHARM_IDS) do
		if player:getItemCount(id) > 0 then
			return true
		end
	end
	local tile = Tile(Y.CARVING)
	if tile then
		for _, id in ipairs(PLACED_IDS) do
			if tile:getItemById(id) then
				return true
			end
		end
	end
	return false
end
