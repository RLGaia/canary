local UniqueTable = {
	[25002] = {
		storage = Storage.Quest.U11_02.TheFirstDragon.DesertTile,
		msg = "You enter the beautiful oasis. By visiting this sacred site you're infused with the power of water bringing life to the desert.",
	},
	[25003] = {
		storage = Storage.Quest.U11_02.TheFirstDragon.StoneSculptureTile,
		msg = "You enter the circle of trees and flowers. By visiting this sacred site you're infused with the power of nature and plants.",
	},
	[25004] = {
		storage = Storage.Quest.U11_02.TheFirstDragon.SuntowerTile,
		msg = "You entered the suntower of Ab'dendriel. By visiting this sacred site you're infused with the power of the life-giving sun.",
	},
}

-- FAMILY: the Life counter is the number of sacred sites visited (2026-10-18).
function TheFirstDragonSecretsVisited(player)
	local visited = 0
	for _, setting in pairs(UniqueTable) do
		if player:getStorageValue(setting.storage) > 0 then
			visited = visited + 1
		end
	end
	return visited
end

function TheFirstDragonSyncSecrets(player)
	local visited = TheFirstDragonSecretsVisited(player)
	local counter = Storage.Quest.U11_02.TheFirstDragon.SecretsCounter
	if visited > 0 and player:getStorageValue(counter) ~= visited then
		player:setStorageValue(counter, visited)
	end
	return visited
end

local secretsLogin = CreatureEvent("FamilyFirstDragonSecrets")
function secretsLogin.onLogin(player)
	TheFirstDragonSyncSecrets(player)
	return true
end
secretsLogin:register()

local zorvoraxSecrets = MoveEvent()

function zorvoraxSecrets.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end

	local setting = UniqueTable[item.actionid]
	if not setting then
		return true
	end

	if player:getStorageValue(setting.storage) < 1 then
		player:setStorageValue(setting.storage, 1)
		TheFirstDragonSyncSecrets(player) -- FAMILY: count of sites visited (upstream +1 from -1 lost the first site visited before Tamoril)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, setting.msg)
		return true
	end
	return true
end

for index, value in pairs(UniqueTable) do
	zorvoraxSecrets:aid(index)
end

zorvoraxSecrets:register()
