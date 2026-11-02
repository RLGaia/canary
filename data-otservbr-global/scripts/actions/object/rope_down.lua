local cobraBastion = Action()

function cobraBastion.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return false
	end
	-- FAMILY: the chess floor opens after Guard Captain Quaid (TibiaWiki EN; scripts/family/cobra_bastion.lua)
	if Family and Family.cobraBastion and player:getStorageValue(Storage.Quest.U12_20.GraveDanger.QuaidKilled) < 1 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Guard Captain Quaid's men still guard the way down.") -- ours
		return true
	end
	player:teleportTo(Position(33394, 32650, 2))
end

cobraBastion:position(Position(33395, 32651, 1))
cobraBastion:register()

local oskayaat = Action()
function oskayaat.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return false
	end
	player:teleportTo(Position(33014, 32983, 8))
end

oskayaat:position(Position(33014, 32983, 7))
oskayaat:register()
