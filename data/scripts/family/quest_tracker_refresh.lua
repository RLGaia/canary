-- Gaia Family server: keep the quest tracker up to date (2026-10-20). Ours,
-- not upstream.
--
-- Reported by Rodrigo's father: the quest tracker (the small window with the
-- tracked quests) did not change while playing, only after opening the quest
-- log. Upstream refreshes the tracker only when the changed storage is a
-- quest's own key (a mission storage, start or end storage). Many missions
-- show progress read from other storages, e.g. the kills of an Edron City
-- task or Grizzly Adams' points, so their text in the tracker stayed old.
--
-- Here, after any storage change of a player who tracks missions, the tracked
-- texts are built again shortly after (a short delay groups several changes),
-- and the tracker is sent only when one of them really changed. A slow check
-- every few seconds also catches progress kept outside storages (KV).

Family = Family or {}
Family.questTrackerRefresh = true
Family.questTrackerRefreshDelay = 300 -- ms after a storage change
Family.questTrackerRefreshInterval = 5000 -- ms between the slow checks

local pending = {}

-- True if a tracked mission would show a different text now.
function Family.questTrackerChanged(player)
	local tracked = PlayerTrackedMissionsData and PlayerTrackedMissionsData[player:getId()]
	if not tracked or #tracked == 0 then
		return false
	end
	for _, mission in ipairs(tracked) do
		if mission and mission.questId and mission.missionId then
			local current = player:getTrackedMissionDataByIds(mission.questId, mission.missionId)
			if current and (current.missionId ~= mission.missionId or current.missionName ~= mission.missionName or current.missionDesc ~= mission.missionDesc) then
				return true
			end
		end
	end
	return false
end

function Family.questTrackerCheck(playerId)
	pending[playerId] = nil
	local player = Player(playerId)
	if player and Family.questTrackerChanged(player) then
		player:refreshTrackedMissions()
	end
end

local originalUpdateStorage = Player.updateStorage
function Player.updateStorage(self, key, value, oldValue, currentFrameTime)
	originalUpdateStorage(self, key, value, oldValue, currentFrameTime)
	if not Family.questTrackerRefresh then
		return
	end
	local playerId = self:getId()
	local tracked = PlayerTrackedMissionsData and PlayerTrackedMissionsData[playerId]
	if tracked and #tracked > 0 and not pending[playerId] then
		pending[playerId] = addEvent(Family.questTrackerCheck, Family.questTrackerRefreshDelay, playerId)
	end
end

local slowCheck = GlobalEvent("FamilyQuestTrackerRefresh")

function slowCheck.onThink(interval)
	if not Family.questTrackerRefresh or not PlayerTrackedMissionsData then
		return true
	end
	for playerId, tracked in pairs(PlayerTrackedMissionsData) do
		if #tracked > 0 and not pending[playerId] then
			local player = Player(playerId)
			if player and Family.questTrackerChanged(player) then
				player:refreshTrackedMissions()
			end
		end
	end
	return true
end

slowCheck:interval(Family.questTrackerRefreshInterval)
slowCheck:register()

local startup = GlobalEvent("FamilyQuestTrackerRefreshStartup")

function startup.onStartup()
	logger.info("[Family] quest tracker refresh: {} (after storage changes and every {} s)", tostring(Family.questTrackerRefresh), Family.questTrackerRefreshInterval / 1000)
	return true
end

startup:register()
