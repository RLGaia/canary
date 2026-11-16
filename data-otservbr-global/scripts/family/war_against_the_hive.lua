-- Gaia Family server: War Against the Hive Quest, objects and kills (2026-11-16). Ours, not upstream.
-- Orockle, the stages, rewards and the hive gates are in lib/others/family_hive.lua (read its header
-- for the sources and the family rules). Here: every mission item, the kollos kills, the insectoid
-- remains (outfit and addons) and the dung ball. Server messages are ours unless marked EN.
-- Switch: Family.warAgainstTheHive.

local H = FamilyHive
if not H then
	return
end

local CRAWLER_CORPSE = 13865
local SPIDRIS_CORPSE = 13870
local DISSOLVER, DISSOLVED = 14052, 14053
local REAGENT, FLUID = 14054, 14055
local DRUM, POWDER, BOMB, GOO = 14255, 13974, 13976, 14051
local PORE, PORE_OVERGROWN = 14064, 14065
local REMAINS, REMAINS_POS = 13408, Position(33482, 31199, 1)
local DUNG_BALL = 14753
local MARK = "familyHiveUsed"

local drumUsed = {} -- player id -> os.time of the last hatchling call
local crystalBack = {} -- "x,y,z" -> os.time the crystal is whole again

local function posKey(pos)
	return pos.x .. "," .. pos.y .. "," .. pos.z
end

local function isCreatureNamed(target, name)
	return target and target.isCreature and target:isCreature() and target:getName():lower() == name:lower()
end

-- One item of a stack becomes another item (or the single item is transformed).
local function turnInto(player, item, newId)
	if item:getCount() > 1 then
		item:remove(1)
		local new = player:addItem(newId, 1, true)
		return new
	end
	item:transform(newId)
	return item
end

local function noMission(player)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Orockle has not asked you to do this.")
	return true
end

-- Flask of chitin dissolver on a crawler that has just died.
local dissolver = Action()

function dissolver.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() then
		return false
	end
	if not target or not target.isItem or not target:isItem() or target:getId() ~= CRAWLER_CORPSE then
		return false
	end
	if target:getCustomAttribute(MARK) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is no chitin left to dissolve on this corpse.")
		return true
	end
	target:setCustomAttribute(MARK, 1)
	turnInto(player, item, DISSOLVED)
	toPosition:sendMagicEffect(CONST_ME_GREEN_RINGS)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You dissolve some chitin of the crawler.")
	return true
end

dissolver:id(DISSOLVER)
dissolver:allowFarUse(true)
dissolver:blockWalls(true)
dissolver:register()

-- Swarmer drum: calls a tame swarmer hatchling on the ground level of the hive (30 s, EN).
local drum = Action()

local function inQuirefang(pos)
	local a = H.AREA
	return pos.x >= a.x1 and pos.x <= a.x2 and pos.y >= a.y1 and pos.y <= a.y2
end

function drum.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() then
		return false
	end
	local m = H.byKey.acid
	if not H.active(player, m) or H.progress(player, m) >= m.need then
		return noMission(player)
	end
	local pos = player:getPosition()
	if not inQuirefang(pos) or pos.z ~= 7 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You can only call a hatchling on the ground level of the hive.") -- after Orockle's line
		return true
	end
	local last = drumUsed[player:getId()] or 0
	if os.time() - last < 30 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You have to wait %d seconds before you can use the drum again.", 30 - (os.time() - last)))
		return true
	end
	local hatchling = Game.createMonster("Swarmer Hatchling", pos, true, false)
	if not hatchling then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There is no room for a hatchling here.")
		return true
	end
	drumUsed[player:getId()] = os.time()
	hatchling:setMaster(player)
	hatchling:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	pos:sendMagicEffect(CONST_ME_SOUND_GREEN)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "A swarmer hatchling answers the call of the drum.")
	addEvent(function(cid)
		local c = Creature(cid)
		if c then
			c:getPosition():sendMagicEffect(CONST_ME_POFF)
			c:remove()
		end
	end, 60 * 1000, hatchling:getId())
	return true
end

drum:id(DRUM)
drum:register()

-- Flask of dissolved chitin on a swarmer hatchling.
local dissolved = Action()

function dissolved.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() or not isCreatureNamed(target, "Swarmer Hatchling") then
		return false
	end
	local m = H.byKey.acid
	if not H.active(player, m) then
		return noMission(player)
	end
	if not H.advance(player, m, "The hatchling swallows the dissolved chitin and hurries back to Orockle.") then
		return true
	end
	item:remove(1)
	target:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	target:remove()
	return true
end

dissolved:id(DISSOLVED)
dissolved:allowFarUse(true)
dissolved:blockWalls(true)
dissolved:register()

-- Strange powder on 8 different insectoid antennae.
local powder = Action()

function powder.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() or not target or not target.isItem or not target:isItem() then
		return false
	end
	local id = target:getId()
	if id ~= 13295 and id ~= 13296 then
		return false
	end
	local m = H.byKey.blind
	if not H.active(player, m) then
		return noMission(player)
	end
	local key = posKey(target:getPosition())
	local db = H.kv(player)
	local done = db:get("antennae") or ""
	if done:find(";" .. key .. ";", 1, true) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have already blinded this antenna.")
		return true
	end
	if H.advance(player, m, "You blind the antenna with the powder.") then
		db:set("antennae", (done == "" and ";" or done) .. key .. ";")
		toPosition:sendMagicEffect(CONST_ME_YELLOW_RINGS)
	end
	return true
end

powder:id(POWDER)
powder:allowFarUse(true)
powder:blockWalls(true)
powder:register()

-- Blob bomb, thrown at a floor blob (from a distance, EN).
local bomb = Action()

function bomb.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() or not isCreatureNamed(target, "Floor Blob") then
		return false
	end
	local m = H.byKey.digestion
	if not H.active(player, m) then
		return noMission(player)
	end
	if H.advance(player, m, "The acid bomb bursts the blob of nutrients.") then
		player:getPosition():sendDistanceEffect(target:getPosition(), CONST_ANI_SMALLEARTH)
		target:getPosition():sendMagicEffect(CONST_ME_GREEN_RINGS)
		target:remove()
	end
	return true
end

bomb:id(BOMB)
bomb:allowFarUse(true)
bomb:blockWalls(true)
bomb:register()

-- Gooey substance on a hive pore: the pore is overgrown for 60 seconds and its swarmers vanish (EN).
local goo = Action()

local function disablePore(pos)
	local tile = Tile(pos)
	if not tile then
		return
	end
	for _, c in ipairs(tile:getCreatures() or {}) do
		if c:getName():lower() == "hive pore" then
			c:remove()
		end
	end
	for _, c in ipairs(Game.getSpectators(pos, false, false, 3, 3, 3, 3)) do
		if c:isMonster() and c:getName():lower() == "lesser swarmer" then
			c:getPosition():sendMagicEffect(CONST_ME_POFF)
			c:remove()
		end
	end
	local pore = tile:getItemById(PORE)
	if pore then
		pore:transform(PORE_OVERGROWN)
		addEvent(function(p)
			local t = Tile(p)
			local grown = t and t:getItemById(PORE_OVERGROWN)
			if grown then
				grown:transform(PORE)
			end
		end, 60 * 1000, Position(pos))
	end
end

function goo.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() or not target then
		return false
	end
	local isPore = isCreatureNamed(target, "Hive Pore") or (target.isItem and target:isItem() and target:getId() == PORE)
	if not isPore then
		if target.isItem and target:isItem() and target:getId() == PORE_OVERGROWN then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This hive pore is already stuffed.")
			return true
		end
		return false
	end
	local m = H.byKey.disable
	if not H.active(player, m) then
		return noMission(player)
	end
	local pos = Position(target:getPosition())
	if H.advance(player, m, "You stuff the hive pore with the goo.") then
		pos:sendMagicEffect(CONST_ME_GREEN_RINGS)
		disablePore(pos)
	end
	return true
end

goo:id(GOO)
goo:allowFarUse(true)
goo:blockWalls(true)
goo:register()

-- Reagent flask on a spidris that has just died: aggressive fluid (back to a reagent flask after
-- 2 minutes: items.xml, EN "a few minutes").
local reagent = Action()

function reagent.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() or not target or not target.isItem or not target:isItem() or target:getId() ~= SPIDRIS_CORPSE then
		return false
	end
	if target:getCustomAttribute(MARK) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Nothing of this spidris can be used anymore.")
		return true
	end
	target:setCustomAttribute(MARK, 1)
	local fluid = turnInto(player, item, FLUID)
	if fluid then
		fluid:decay()
	end
	toPosition:sendMagicEffect(CONST_ME_GREEN_RINGS)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The reagent turns into a volatile and acidic fluid. It will not stay aggressive for long.")
	return true
end

reagent:id(REAGENT)
reagent:allowFarUse(true)
reagent:blockWalls(true)
reagent:register()

-- Aggressive fluid on an insectoid monolith (a control crystal; whole again after 5 minutes, EN).
local fluid = Action()

function fluid.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() or not target or not target.isItem or not target:isItem() then
		return false
	end
	local id = target:getId()
	if id ~= 14074 and id ~= 14075 then
		return false
	end
	local m = H.byKey["break"]
	if not H.active(player, m) then
		return noMission(player)
	end
	local key = posKey(target:getPosition())
	if (crystalBack[key] or 0) > os.time() then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "This crystal is still shattered. It has not grown back yet.")
		return true
	end
	if H.advance(player, m, "The aggressive fluid shatters the crystal.") then
		crystalBack[key] = os.time() + 5 * 60
		toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
		toPosition:sendMagicEffect(CONST_ME_GREEN_RINGS)
		item:transform(REAGENT)
	end
	return true
end

fluid:id(FLUID)
fluid:allowFarUse(true)
fluid:blockWalls(true)
fluid:register()

-- Insectoid remains on the top floor of the western tower: outfit and addons (EN messages).
local remains = Action()

function remains.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() or item:getPosition() ~= REMAINS_POS then
		return false
	end
	local war = H.warExp(player)
	if war < H.WAR_OUTFIT then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You lack the experience in fighting the hive to make anything of these remains (%d/%d war experience).", war, H.WAR_OUTFIT))
		return true
	end
	local look = player:getSex() == PLAYERSEX_FEMALE and H.OUTFIT.female or H.OUTFIT.male
	local given = false
	if not player:hasOutfit(look) then
		player:addOutfit(H.OUTFIT.male)
		player:addOutfit(H.OUTFIT.female)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your experience in fighting the hive allows you to assemble a makeshift hive born outfit.")
		given = true
	end
	if war >= H.WAR_ADDON1 and not player:hasOutfit(look, 1) then
		player:addOutfitAddon(H.OUTFIT.male, 1)
		player:addOutfitAddon(H.OUTFIT.female, 1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your increased experience in the war against the hive allows you to find a suitable addon to your hive outfit.")
		given = true
	end
	if war >= H.WAR_ADDON2 and not player:hasOutfit(look, 2) then
		player:addOutfitAddon(H.OUTFIT.male, 2)
		player:addOutfitAddon(H.OUTFIT.female, 2)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your constant battles against the hive allow you to claim the last addon for your outfit from the remains.")
		given = true
	end
	if player:hasOutfit(look, 3) and not player:hasAchievement("Bane of the Hive") then
		player:addAchievement("Bane of the Hive")
	end
	if given then
		player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
	else
		local nextAt = war < H.WAR_ADDON1 and H.WAR_ADDON1 or (war < H.WAR_ADDON2 and H.WAR_ADDON2 or nil)
		if nextAt then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You find nothing more in the remains yet (%d/%d war experience).", war, nextAt))
		else
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You find nothing more in the remains.")
		end
	end
	return true
end

remains:id(REMAINS)
remains:register()

-- Dung ball (quest item, dropped by the Hive Born bosses): 10 war experience, no favour (EN).
local dung = Action()

function dung.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not H.enabled() then
		return false
	end
	item:remove(1)
	H.addWarExp(player, 10)
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_GREEN)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have gained some valuable experience in the war against the hive.") -- EN
	return true
end

dung:id(DUNG_BALL)
dung:register()

-- Kollos kills (every party member who shares the kill).
local death = CreatureEvent("FamilyHiveKollosDeath")

function death.onDeath(creature, corpse, lastHitKiller, mostDamageKiller)
	if not H.enabled() then
		return true
	end
	onDeathForParty(creature, mostDamageKiller, function(_, player)
		local m = H.byKey.kill
		if H.active(player, m) and H.progress(player, m) < m.need then
			H.advance(player, m, "You have killed a guard of the hive.")
		end
	end)
	return true
end

death:register()

local startup = GlobalEvent("FamilyHiveStartup")

function startup.onStartup()
	local mType = MonsterType("Kollos")
	if mType then
		mType:registerEvent("FamilyHiveKollosDeath")
	else
		logger.error("[Family] War Against the Hive: monster type Kollos not found")
	end
	logger.info("[Family] War Against the Hive: stage {}, {} actions needed a day", H.stage(), H.perDay())
	return true
end

startup:register()
