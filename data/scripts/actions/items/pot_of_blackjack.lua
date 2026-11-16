-- FAMILY: a pot lasts 4 gulps (2026-11-16, asked by Rodrigo; family_hot_cuisine.lua). TibiaWiki EN:
-- heals 5000 HP, "Can be used 4 times", the first 3 uses say "...still some blackjack in it.", the 4th
-- "...No leftovers!" and the pot disappears; the count is kept on the character, not on the pot (a
-- bought or second pot goes on with the same count); green sparkles every time. TibiaWiki BR says
-- 2-4 times. Upstream counted gulps but removed the pot at every use (and its count never reset).
-- Switch: Family.hotCuisine (false = upstream code below).
local GULPS = 4

local potOfBlackjack = Action()

function potOfBlackjack.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:hasExhaustion("special-foods-cooldown") then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to wait before using it again.")
		return true
	end

	if Family and Family.hotCuisine then
		local kv = player:kv():scoped("family-hot-cuisine")
		local taken = (tonumber(kv:get("blackjack-gulps")) or 0) + 1
		player:addHealth(5000)
		player:say("Gulp.", TALKTYPE_MONSTER_SAY)
		player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
		player:setExhaustion("special-foods-cooldown", 10 * 60)
		if taken < GULPS then
			kv:set("blackjack-gulps", taken)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take a gulp from the large bowl, but there's still some blackjack in it.")
		else
			kv:set("blackjack-gulps", 0)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take the last gulp from the large bowl. No leftovers!")
			item:remove(1)
		end
		return true
	end

	local remainingGulps = player:kv():get("pot-of-blackjack") or math.random(2, 4)

	if remainingGulps > 0 then
		remainingGulps = remainingGulps - 1
		player:kv():set("pot-of-blackjack", remainingGulps)

		local message
		if remainingGulps > 0 then
			message = "You take a gulp from the large bowl, but there's still some blackjack in it."
		else
			message = "You take the last gulp from the large bowl. No leftovers!"
		end

		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
	end

	player:addHealth(5000)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take a gulp from the large bowl.")
	player:say("Gulp.", TALKTYPE_MONSTER_SAY)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
	player:setExhaustion("special-foods-cooldown", 10 * 60)
	item:remove(1)
	return true
end

potOfBlackjack:id(11586)
potOfBlackjack:register()
