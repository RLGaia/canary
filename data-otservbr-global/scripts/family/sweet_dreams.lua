-- Gaia Family server: Threatened Dreams Quest, Sweet Dreams world objects (2026-11-22). Ours, not upstream.
-- Talk and rules: lib/others/family_sweet_dreams.lua (FamilySweetDreams).

local SD = FamilySweetDreams
if not SD then
	return
end

-- Objects our map lacks (placed at startup): the oven in Feyrist, the chest with the intricate cage key,
-- the sugar boxes in the three caves and marks for the moon melon plants.
local placed = {
	{ pos = SD.OVEN_POS, id = SD.OVEN },
	{ pos = SD.KEY_CHEST, id = 2472 }, -- chest
}
for _, pos in ipairs(SD.SUGAR_BOXES) do
	placed[#placed + 1] = { pos = pos, id = SD.SUGAR_BOX }
end
for _, pos in ipairs(SD.MELONS) do
	placed[#placed + 1] = { pos = pos, id = SD.WHITE_CRYSTALS }
end

local startup = GlobalEvent("FamilySweetDreamsStartup")
function startup.onStartup()
	if not SD.enabled() then
		return true
	end
	for _, p in ipairs(placed) do
		local tile = Tile(p.pos)
		if not tile then
			logger.warn("[Family] Sweet Dreams: no square at {}", p.pos:toString())
		elseif not tile:getItemById(p.id) then
			local item = Game.createItem(p.id, 1, p.pos)
			if not item then
				logger.warn("[Family] Sweet Dreams: could not place item {} at {}", p.id, p.pos:toString())
			end
		end
	end
	return true
end
startup:register()

-- The oven gets the dough (data-otservbr-global/scripts/actions/other/baking.lua calls SD.bakeKey);
-- here: the chest, boxes and melon plants.
local keyChest = Action()
function keyChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if item:getId() ~= 2472 then
		return false
	end
	return SD.keyChest(player)
end
keyChest:position(SD.KEY_CHEST)
keyChest:register()

for i, pos in ipairs(SD.SUGAR_BOXES) do
	local box = Action()
	function box.onUse(player, item, fromPosition, target, toPosition, isHotkey)
		if item:getId() ~= SD.SUGAR_BOX then
			return false
		end
		if SD.sugarBox(player, i) then
			return true
		end
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The box is empty.")
		return true
	end
	box:position(pos)
	box:register()
end

for i, pos in ipairs(SD.MELONS) do
	local melon = Action()
	function melon.onUse(player, item, fromPosition, target, toPosition, isHotkey)
		if item:getId() ~= SD.WHITE_CRYSTALS then
			return false
		end
		return SD.moonMelon(player, i)
	end
	melon:position(pos)
	melon:register()
end

-- Items used on something.
local cageKey = Action()
function cageKey.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return SD.useCageKey(player, toPosition)
end
cageKey:id(SD.CAGE_KEY)
cageKey:register()

local sugar = Action()
function sugar.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return SD.useSugar(player, item, target)
end
sugar:id(SD.SUGAR)
sugar:register()

local sirup = Action()
function sirup.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return SD.useSirup(player, item, target)
end
sirup:id(SD.SIRUP.moon, SD.SIRUP.raspberry, SD.SIRUP.lemon)
sirup:register()

local lipstick = Action()
function lipstick.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return SD.useLipstick(player, item)
end
lipstick:id(SD.LIPSTICK)
lipstick:register()

local lipstickBox = Action()
function lipstickBox.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if SD.lipstickBox(player) then
		return true
	end
	return false -- opens as usual
end
lipstickBox:position(SD.LIPSTICK_BOX)
lipstickBox:register()

local caneChest = Action()
function caneChest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if SD.caneChest(player) then
		return true
	end
	return false
end
for _, pos in ipairs(SD.CANE_CHEST) do
	caneChest:position(pos)
end
caneChest:register()

local candyCane = Action()
function candyCane.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return SD.useCandyCane(player, item, toPosition)
end
candyCane:id(SD.CANDY_CANE)
candyCane:register()

local toothbrush = Action()
function toothbrush.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if SD.useToothbrush(player, item, toPosition) then
		return true
	end
	return false
end
toothbrush:id(SD.TOOTHBRUSH)
toothbrush:register()

local feather = Action()
function feather.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return SD.usePegasusFeather(player, item)
end
feather:id(SD.PEGASUS_FEATHER)
feather:register()

-- Sugar Daddy's portal (action id 30000 on our map, without a destination) and the way back.
local portal = MoveEvent()
function portal.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player or not SD.enabled() then
		return true
	end
	return SD.enterSugarDaddy(player, fromPosition)
end
portal:position(SD.SUGAR_DADDY.portal)
portal:register()

local roomExit = MoveEvent()
function roomExit.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player and SD.enabled() then
		player:teleportTo(SD.SUGAR_DADDY.back)
		SD.SUGAR_DADDY.back:sendMagicEffect(CONST_ME_TELEPORT)
	end
	return true
end
roomExit:position(SD.SUGAR_DADDY.exit)
roomExit:register()

-- The Dessert Dungeons below the cave east of the castle: the tuft of pink sugar.
local dungeon = MoveEvent()
function dungeon.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if player then
		SD.dungeonStep(player)
	end
	return true
end
for x = SD.DUNGEON_ENTRY.from.x, SD.DUNGEON_ENTRY.to.x do
	for y = SD.DUNGEON_ENTRY.from.y, SD.DUNGEON_ENTRY.to.y do
		dungeon:position(Position(x, y, SD.DUNGEON_ENTRY.from.z))
	end
end
dungeon:register()

-- Quest sweets in the boss corpses; Sugar Daddy's kill for Candis.
local loot = EventCallback("FamilySweetDreamsLoot")
function loot.monsterOnDropLoot(monster, corpse)
	if not SD.enabled() then
		return
	end
	SD.bossLoot(monster, corpse)
	if monster:getName():lower() == "sugar daddy" then
		SD.sugarDaddyKilled(monster)
		SD.sugarDaddyGone(monster)
	end
end
loot:register()

-- The escape from the Corym Black Market: the next message when the player reaches the next floor.
local escape = GlobalEvent("FamilySweetDreamsEscape")
function escape.onThink(interval)
	if not SD.enabled() then
		return true
	end
	for _, player in ipairs(Game.getPlayers()) do
		if SD.main(player) == 3 then
			SD.escapeTick(player)
		end
	end
	return true
end
escape:interval(2000)
escape:register()

-- Sugar Daddy's sugar rush (lib: SD.sugarRushCheck); his helpers report their death.
local rush = CreatureEvent("FamilySugarDaddyRush")
function rush.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if SD.enabled() and primaryType ~= COMBAT_HEALING then
		SD.sugarRushCheck(creature, math.abs(primaryDamage or 0) + math.abs(secondaryDamage or 0)) -- values are negative here
	end
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end
rush:register()

local minion = CreatureEvent("FamilySugarDaddyMinion")
function minion.onDeath(creature, corpse, killer, mostDamageKiller, unjustified, mostDamageUnjustified)
	SD.minionDied(creature)
	return true
end
minion:register()

-- Coco's shops are opened by talk (lib); here nothing else.

-- Sand toys: the carrot plants, carrots on the trough, the sand toys themselves. The treasure is dug
-- in onUseShovel (scripts/lib/register_actions.lua calls SD.digTreasure).
local carrotPlant = Action()
function carrotPlant.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return SD.pullCarrot(player, item)
end
for id in pairs(SD.CARROT_PLANT) do
	carrotPlant:id(id)
end
carrotPlant:register()

local carrot = Action()
function carrot.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return SD.feedTrough(player, item, target, toPosition)
end
carrot:id(48586, 48582)
carrot:register()

local sandToys = Action()
function sandToys.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not toPosition or toPosition.x == CONTAINER_POSITION then
		return false
	end
	return SD.useSandToys(player, item, toPosition)
end
sandToys:id(SD.SAND_TOYS)
sandToys:register()

-- The four real-life recipes in their containers (return false: the container opens as usual).
for i, r in ipairs(SD.RECIPES) do
	local recipe = Action()
	function recipe.onUse(player, item, fromPosition, target, toPosition, isHotkey)
		return SD.takeRecipe(player, i)
	end
	recipe:position(r.pos)
	recipe:register()
end
