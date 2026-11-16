-- Gaia Family server: Hot Cuisine Quest, the Zaoan Sauce (2026-11-16).
--
-- Ours, not upstream: v3.6.1 knows the item (client data) but nothing uses it. TibiaWiki EN and BR:
-- Fist Fighting +10 for one hour, the 10-minute wait of the Hot Cuisine dishes. Same pattern as the
-- other dishes (data/scripts/actions/items/carrot_cake.lua). Its own condition sub id, so it stacks
-- with the Veggie Casserole (melee). The messages are ours.
-- Switch: Family.hotCuisine (lib/others/family_hot_cuisine.lua).

if not Family.hotCuisine then
	return
end

local ZAOAN_SAUCE = 50334
local SUBID = 48601 -- any number not used by another attribute condition

local fistCondition = Condition(CONDITION_ATTRIBUTES)
fistCondition:setParameter(CONDITION_PARAM_SUBID, SUBID)
fistCondition:setParameter(CONDITION_PARAM_BUFF_SPELL, 1)
fistCondition:setParameter(CONDITION_PARAM_TICKS, 60 * 60 * 1000)
fistCondition:setParameter(CONDITION_PARAM_SKILL_FIST, 10)
fistCondition:setParameter(CONDITION_PARAM_FORCEUPDATE, true)

local zaoanSauce = Action()

function zaoanSauce.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if player:hasExhaustion("special-foods-cooldown") then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You need to wait before using it again.")
		return true
	end

	player:updateFood(item:getId(), 3600)
	player:addCondition(fistCondition)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You feel body and soul in harmony.")
	player:say("Mmmm.", TALKTYPE_MONSTER_SAY)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
	player:setExhaustion("special-foods-cooldown", 10 * 60)
	item:remove(1)
	return true
end

zaoanSauce:id(ZAOAN_SAUCE)
zaoanSauce:register()
