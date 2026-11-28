-- Gaia Family server: Shadows of Yalahar Quest, items, map objects and doors (2026-11-27). Ours, not upstream.
-- Rules and sources: data-otservbr-global/lib/others/family_shadows_of_yalahar.lua.
--
-- (The headache pill is eaten through data/scripts/actions/items/foods.lua.)
-- * Mission 2: the elemental cannons and the core dispenser; 4: the golem disassembler; 5: the charge
--   generator; 6, 7, 8, 12, 13: the boxes with the blueprint, the old power core, the stabilizer, the golem
--   head and the golem wrench; 9: the books, the scribe's desk and the headache pill; 10: the six ingredient
--   spots; 11: the elevator button and the shower; 12: Fenrock's teleporters, the lift and the Golem Servant's
--   twelve boxes; 13: the way into Telas' laboratory and the golem lever.
-- * Startup: the mission doors get their storages, the crystal columns start changing colour, the missing
--   boxes are placed, the teleporters lose their map destinations.
-- Telas, the five researchers and the Golem Servant call FamilyShadowsYalahar from their own files, the pick
-- from scripts/lib/register_actions.lua (mission 3).
--
-- Switch: Family.shadowsOfYalahar (false = upstream: no quest).

Family = Family or {}
Family.shadowsOfYalahar = true

local Y = FamilyShadowsYalahar

local function on()
	return Family.shadowsOfYalahar
end

local cannons = Action()
function cannons.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	return Y.useCannon(player, fromPosition)
end
for _, p in ipairs(Y.cannons) do
	cannons:position(p)
end
cannons:register()

local dispenser = Action()
function dispenser.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	return Y.useDispenser(player)
end
dispenser:position(Y.dispenser)
dispenser:register()

local disassembler = Action()
function disassembler.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	return Y.useDisassembler(player, item, target)
end
disassembler:id(Y.items.disassembler)
disassembler:register()

local boxes = Action()
function boxes.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	local k = Y.boxAt and Y.boxAt[fromPosition.x .. "," .. fromPosition.y .. "," .. fromPosition.z]
	if not k then
		return false
	end
	return Y.useBox(player, k)
end
for _, list in ipairs({ Y.blueprintBox, Y.stabilizerBox, Y.headBox, Y.wrenchChest, { Y.powerCore } }) do
	for _, p in ipairs(list) do
		boxes:position(p)
	end
end
boxes:register()

local library = Action()
function library.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	if fromPosition == Y.inkwell then
		return Y.useInkwell(player)
	end
	return Y.useBook(player, fromPosition)
end
for _, p in ipairs(Y.books) do
	library:position(p)
end
library:position(Y.inkwell)
library:register()

local ingredients = Action()
function ingredients.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	return Y.useIngredient(player, fromPosition)
end
for _, ing in ipairs(Y.ingredients) do
	for _, p in ipairs(ing.at) do
		ingredients:position(p)
	end
end
ingredients:register()

local button = Action()
function button.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	return Y.useButton(player, fromPosition)
end
button:position(Y.button)
button:position(Y.shower)
button:register()

local servantBoxes = Action()
function servantBoxes.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	return Y.useServantBox(player, item)
end
for _, p in ipairs(Y.parts) do
	servantBoxes:id(p.box)
end
servantBoxes:register()

local golemLever = Action()
function golemLever.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	return Y.useGolemLever(player, item)
end
golemLever:position(Y.golemLever)
golemLever:register()

local steps = MoveEvent()
function steps.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not on() then
		return true
	end
	if position.z == 9 and position.x >= 32709 and position.x <= 32710 and position.y >= 31193 and position.y <= 31194 then
		Y.stepCharger(player, position)
	elseif position == Y.fenrockIn or position == Y.fenrockOut then
		Y.stepFenrock(player, position, fromPosition)
	elseif position == Y.labForcefield then
		Y.stepLab(player, position, fromPosition)
	else
		Y.stepLift(player, position, fromPosition)
	end
	return true
end
steps:type("stepin")
for _, list in ipairs({ Y.charger, { Y.fenrockIn, Y.fenrockOut, Y.labForcefield }, Y.lift9, Y.lift11 }) do
	for _, p in ipairs(list) do
		steps:position(p)
	end
end
steps:register()

local startup = GlobalEvent("FamilyShadowsYalaharStartup")
function startup.onStartup()
	if on() then
		Y.setup()
	end
	return true
end
startup:register()
