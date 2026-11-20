-- Theodore Loveless' key

local theThievesKey = Action()
function theThievesKey.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: the door gets action id 51394 again (startup/tables/door_quest.lua); the key works while
	-- the fish is still to be taken (also a key bought on the market), and from inside it lets you out
	-- (lib/others/family_thieves_guild.lua)
	if Family and Family.thievesGuild and FamilyThieves then
		local handled = FamilyThieves.useKey(player, item, target)
		if handled ~= nil then
			return handled
		end
		return false
	end
	if player:getStorageValue(Storage.Quest.U8_2.TheThievesGuildQuest.Mission06) == 2 then
		if target.actionid == 51394 and item.itemid == 7934 then
			player:removeItem(7934, 1)
			player:say("In your haste you break the key while slipping in.", TALKTYPE_MONSTER_SAY)
			player:teleportTo(Position(32359, 32788, 6))
			return true
		end
	end
	return false
end

theThievesKey:id(7934)
theThievesKey:register()
