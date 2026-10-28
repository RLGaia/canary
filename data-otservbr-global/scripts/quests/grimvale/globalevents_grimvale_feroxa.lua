local spawnByDay = true
local spawnDay = 13
local currentDay = os.date("%d")

local grimVale = GlobalEvent("grimvale")

function grimVale.onThink(interval, lastExecution)
	-- FAMILY: Feroxa comes through the raid scheduler (scripts/family/raid_scheduler.lua) and her
	-- lair opens through scripts/family/full_moon.lua; this full-moon map change would rebuild the
	-- hall before the lair and its teleport.
	if Family and Family.curseOfTheFullMoon then
		return true
	end
	local chance = Game.getStorageValue(GlobalStorage.Feroxa.Chance)
	if Game.getStorageValue(GlobalStorage.Feroxa.Active) >= 1 then
		return true
	end

	if spawnByDay then
		if Game.getStorageValue(GlobalStorage.Feroxa.Active) < 1 then
			if spawnDay == tonumber(currentDay) then
				if chance <= 5 then
					addEvent(removeItems, 30 * 60 * 1000)
					addEvent(Game.loadMap, 30 * 60 * 1000, DATA_DIRECTORY .. "/world/world_changes/full_moon/middle.otbm")
					addEvent(grimvaleSpectators, 30 * 60 * 1000)
					Game.setStorageValue(GlobalStorage.Feroxa.Active, 1)
					Game.broadcastMessage("Grimvale drowns in werecreatures as the full moon reaches its apex and ancient evil returns.", MESSAGE_EVENT_ADVANCE)
				else
					Game.setStorageValue(GlobalStorage.Feroxa.Chance, math.random(1, 10))
				end
			end
		end
	end
	return true
end

grimVale:interval(60000)
grimVale:register()
