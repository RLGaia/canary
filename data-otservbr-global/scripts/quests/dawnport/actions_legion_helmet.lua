local sacrificialPosition = {
	Position(32111, 31933, 8),
	Position(32112, 31933, 8),
}

local effectPosition = {
	Position(32110, 31933, 8),
	Position(32113, 31933, 8),
}

local sacredSnake = Action()

function sacredSnake.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item.itemid == 21469 then
		for i = 1, #sacrificialPosition do
			local tile = Tile(sacrificialPosition[i])
			if toPosition == sacrificialPosition[i] then
				if not player:kv():scoped("lizard-god-teleport"):get("discovered") then
					-- FAMILY: one egg only (upstream also ran player:removeItem, taking a second egg) and set the
					-- storage the portal (movements_legion_helmet.lua) checks; upstream only set this KV, so the
					-- portal never let anyone through (2026-11-02, reported by Rodrigo)
					player:kv():scoped("lizard-god-teleport"):set("discovered", true)
					player:setStorageValue(Storage.Quest.U10_55.SanctuaryOfTheLizardGod.LizardGodTeleport, 1)
					player:say("The lizard god accepts your offer! You may enter the santuary!", TALKTYPE_MONSTER_SAY, false, player, toPosition)
					toPosition:sendMagicEffect(CONST_ME_MORTAREA)
					item:remove(1)
					for i = 1, #effectPosition do
						effectPosition[i]:sendMagicEffect(CONST_ME_FIREAREA)
					end
				else
					player:say("You have already discovered this teleport.", TALKTYPE_MONSTER_SAY, false, player, toPosition)
				end
				return true
			end
		end
	end
	return true
end

sacredSnake:id(21469)
sacredSnake:register()
