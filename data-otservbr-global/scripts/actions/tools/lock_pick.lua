local lockPick = Action()

function lockPick.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	-- FAMILY: lock picks also work on Theodore Loveless' door (TibiaWiki BR, third method of Mission 6;
	-- lib/others/family_thieves_guild.lua)
	if Family and Family.thievesGuild and FamilyThieves and target and target.actionid == FamilyThieves.DOOR_AID then
		return FamilyThieves.lockPickDoor(player, item)
	end

	if target.actionid ~= 12503 then
		return false
	end

	if math.random(100) <= 30 then
		if player:getStorageValue(Storage.Quest.U8_2.TheThievesGuildQuest.Mission02) == 1 then
			-- FAMILY: the valuable vase (7932, TibiaWiki EN), not a fine vase (227)
			player:addItem((Family and Family.thievesGuild) and 7932 or 227, 1)
			player:setStorageValue(Storage.Quest.U8_2.TheThievesGuildQuest.Mission02, 2)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your lock pick open this chest!")
		end
	else
		item:remove(1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your lock pick broke.")
	end
	return true
end

lockPick:id(7889)
lockPick:register()
