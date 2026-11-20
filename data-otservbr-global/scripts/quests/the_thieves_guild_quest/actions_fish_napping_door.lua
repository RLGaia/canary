local theThievesDoor = Action()
function theThievesDoor.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: the door lets you out from inside the room in any state (upstream only after taking the
	-- fish) and is locked from outside (lib/others/family_thieves_guild.lua)
	if Family and Family.thievesGuild and FamilyThieves then
		return FamilyThieves.useDoor(player)
	end
	if player:getStorageValue(Storage.Quest.U8_2.TheThievesGuildQuest.Mission06) == 3 then
		player:say("You slip through the door", TALKTYPE_MONSTER_SAY)
		player:teleportTo(Position(32359, 32786, 6))
	end
	return true
end

theThievesDoor:aid(51394)
theThievesDoor:register()
