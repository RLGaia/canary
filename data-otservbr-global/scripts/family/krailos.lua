-- Gaia Family server: Krailos Quest, world objects (2026-11-22). Ours, not upstream.
-- Rules, messages and talk: lib/others/family_krailos.lua (FamilyKrailos).
-- Elsewhere: the skull orchid (Explorer Society botanist's container script) and Larek's grille
-- (scripts/quests/krailos/movements_access_depot.lua).

local K = FamilyKrailos

-- Hungry New World: the sarcophagus in the Nightmare room holds the ancient map. Other uses do
-- what they did before (return false).
local sarcophagus = Action()
function sarcophagus.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return K.useSarcophagus(player)
end
for _, pos in ipairs(K.SARCOPHAGUS) do
	sarcophagus:position(pos)
end
sarcophagus:register()

-- Hungry New World: the thieving steppe bird's nest south of the village.
local nest = Action()
function nest.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	return K.useBirdNest(player)
end
nest:position(K.BIRD_NEST)
nest:register()

-- The Great Hunger ------------------------------------------------------------

local function itemAction(ids, handler)
	local a = Action()
	function a.onUse(player, item, fromPosition, target, toPosition, isHotkey)
		return handler(player, item, target, toPosition)
	end
	for _, id in ipairs(ids) do
		a:id(id)
	end
	a:register()
end

-- shark teeth and onyx chips into the gourd
itemAction({ K.SHARK_TEETH, K.ONYX_CHIP }, function(player, item, target)
	return K.fillGourd(player, item, target)
end)
-- pollen + egg shells, grey-blue powder + red oil, red paint on the rattling gourd
itemAction(K.mixIds, function(player, item, target)
	return K.mix(player, item, target)
end)
itemAction({ K.PAINTED_RATTLE }, function(player)
	return K.shakeRattle(player)
end)
itemAction({ K.HYAENA_TRAP }, function(player, item, target)
	return K.trapHyaena(player, item, target)
end)
local runeSets = {}
for _, r in ipairs(K.RUNES) do
	runeSets[#runeSets + 1] = r.set
end
itemAction(runeSets, function(player, item, target, toPosition)
	return K.placeRunes(player, item, toPosition)
end)
-- map objects
itemAction({ K.VOODOO_LILY }, function(player, item, target, toPosition)
	return K.useVoodooLily(player, item:getPosition())
end)
itemAction({ K.DRAGON_NEST }, function(player)
	return K.useDragonNest(player)
end)
itemAction({ K.FLOATING_FLASK }, function(player)
	return K.useFloatingFlask(player)
end)

-- Quenching the Thirst ---------------------------------------------------------

itemAction({ K.CARAFE }, function(player, item, target, toPosition)
	return K.useCarafe(player, item, target, toPosition)
end)
-- the hoe on golden quartzes: the hoe action of scripts/family/oramond_tasks.lua calls K.useHoe
itemAction({ K.QUARTZ_POWDER }, function(player, item, target, toPosition)
	return K.usePowder(player, item, toPosition)
end)

-- The salt sea keeps its water for the rest of the game day (also after a restart) and dries at
-- 06:00 (the daily stop; this covers a server that runs through it).
local lakeStartup = GlobalEvent("FamilyKrailosLakeStartup")
function lakeStartup.onStartup()
	if K.enabled() and K.lakeState() ~= K.LAKE_DRY then
		K.showLake(K.lakeState())
	end
	return true
end
lakeStartup:register()

local lakeDries = GlobalEvent("FamilyKrailosLakeDries")
function lakeDries.onTime(interval)
	if K.enabled() then
		K.showLake(K.LAKE_DRY)
	end
	return true
end
lakeDries:time("06:00:00")
lakeDries:register()
