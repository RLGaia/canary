-- FAMILY: the three plans in the Nargor tavern are registered by position (2026-11-17). Upstream
-- waited for unique ids 40001-40003, which no item on our map has, so Ray's Mission 3 could never
-- be finished. Positions and messages: data-otservbr-global/lib/others/family_shattered_isles.lua.
-- With Family.shatteredIsles = false the plans stay as upstream left them (unused).
local S = FamilyShatteredIsles

local function planAt(position)
	for _, plan in ipairs(S.plans) do
		if plan.pos.x == position.x and plan.pos.y == position.y and plan.pos.z == position.z then
			return plan
		end
	end
	return nil
end

local nargorMaps = Action()

function nargorMaps.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local setting = planAt(item:getPosition())
	if not setting or not S.enabled() then
		return false
	end

	if player:getStorageValue(Storage.Quest.U7_8.TheShatteredIsles.RaysMission3) ~= 1 then
		return false
	end

	if player:getStorageValue(setting.storage) < 0 then
		player:setStorageValue(setting.storage, 1)
		player:say(setting.message, TALKTYPE_MONSTER_SAY)
		return true
	end
	return false
end

for _, plan in ipairs(S.plans) do
	nargorMaps:position(Position(plan.pos.x, plan.pos.y, plan.pos.z))
end
nargorMaps:register()
