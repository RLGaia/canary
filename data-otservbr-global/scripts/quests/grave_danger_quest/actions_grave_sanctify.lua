GraveDangerSanctify = {}
local config = {
	[1] = {
		pos = Position(32644, 32394, 8),
		stor = Storage.Quest.U12_20.GraveDanger.Graves.DarkCathedral,
		msg = "This grave now been sanctified and is safe!",
	},
	[2] = {
		pos = Position(32542, 31846, 6),
		stor = Storage.Quest.U12_20.GraveDanger.Graves.FemorHills,
		msg = "This grave is already defiled and the lich knight has left! There is nothing you can do here.",
	},
	[3] = {
		pos = Position(33376, 32806, 8),
		stor = Storage.Quest.U12_20.GraveDanger.Graves.Ankrahmun,
		msg = "This grave now been sanctified and is safe!",
	},
	[4] = {
		pos = Position(32959, 31534, 7),
		stor = Storage.Quest.U12_20.GraveDanger.Graves.Vengoth,
		msg = "This grave is already defiled and the lich knight has left! There is nothing you can do here.",
	},
	[5] = {
		pos = Position(32776, 31817, 8),
		stor = Storage.Quest.U12_20.GraveDanger.Graves.Orclands,
		msg = "This grave is already defiled and the lich knight has left! There is nothing you can do here.",
	},
	[6] = {
		pos = Position(32012, 31558, 7),
		stor = Storage.Quest.U12_20.GraveDanger.Graves.IceIslands,
		msg = "This grave is already defiled and the lich knight has left! There is nothing you can do here.",
	},
	[7] = {
		pos = Position(33813, 31624, 9),
		stor = Storage.Quest.U12_20.GraveDanger.Graves.Kilmaresh,
		msg = "This grave now been sanctified and is safe!",
	},
}

-- FAMILY: the graves are two-square sarcophagi; holy water on either half counts (upstream only
-- the first square, the other half did nothing). A visited grave is 2 (1 = still to find), as the
-- quest log reads it (scripts/family/grave_danger.lua).
local function getGrave(pos)
	for i = 1, #config do
		local p = config[i].pos
		if pos.z == p.z and pos.x == p.x and (pos.y == p.y or pos.y == p.y + 1) then
			return i
		end
	end

	return nil
end

local grave_sanctify = Action()

function grave_sanctify.onUse(player, item, fromPosition, itemEx, toPosition)
	local index = toPosition and getGrave(toPosition)
	local thing = index and config[index]

	if not thing then
		return false
	end

	if player:getStorageValue(thing.stor) < 2 then
		player:setStorageValue(thing.stor, 2)
		thing.pos:sendMagicEffect(CONST_ME_HOLYAREA)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, thing.msg)
		player:setStorageValue(Storage.Quest.U12_20.GraveDanger.Graves.Progress, math.max(0, player:getStorageValue(Storage.Quest.U12_20.GraveDanger.Graves.Progress)) + 1)
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, thing.msg)
	end

	return true
end

GraveDangerSanctify.config = config -- FAMILY: read by scripts/family/grave_danger.lua
GraveDangerSanctify.getGrave = getGrave
grave_sanctify:id(31612)
grave_sanctify:register()
