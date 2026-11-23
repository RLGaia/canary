local function placeFruits(position, fruit, nofruit)
	local item = Tile(position):getItemById(nofruit)

	if item then
		item:transform(fruit)
	end
end

local fruitId = 29995

local actions_sunFruit = Action()

function actions_sunFruit.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not player then
		return true
	end

	local r = (FamilyDreamCourts and FamilyDreamCourts.enabled()) and 2 or math.random(2, 4) -- FAMILY: 2 fruits (EN, BR)

	player:addItem(fruitId, r)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found some " .. ItemType(fruitId):getName() .. "s.")
	item:transform(29970)
	item:getPosition():sendMagicEffect(CONST_ME_MAGIC_RED)
	addEvent(placeFruits, ((FamilyDreamCourts and FamilyDreamCourts.enabled()) and 2 or 1) * 60 * 60 * 1000, item:getPosition(), 29969, 29970) -- FAMILY: BR "2h?" (EN: a long cooldown)

	return true
end

actions_sunFruit:id(29969)
actions_sunFruit:register()
