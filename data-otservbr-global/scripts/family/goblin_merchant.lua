-- Gaia Family server: Goblin Merchant Quest, the parts outside Rafzan (2026-11-23).
-- Ours, not upstream. Rules and sources: data-otservbr-global/lib/others/family_goblin_merchant.lua.
--
-- * Advertisement signs go into cracked stones (10 minutes, then the stone is free again).
-- * The guardcatcher on an adventurer: it limps off ("Arrrgh! Not my knee!") or, 25%,
--   turns into an Angry Adventurer ("You fiend! I will get you, servant of evil!");
--   the bow breaks after the third one that limps off.
-- * The perfume gatherer fills in order: a slug corpse 10 seconds after the kill,
--   black swamp gas, a living rotworm (26% per try), mouldy cheese (used up). It works
--   without the task too (EN: frequent taskers fill a supply in advance).
-- * The bottle with rat urine on the pond of the Venore Corym cave (floor 10).
-- * The trunkhammer smashes junk trunks (they come back after 4 minutes, items.xml);
--   it breaks after the third.
-- * Marsh stalker kills count for every player who hurt the stalker.
-- Messages in quotes above and "You gather the ... part of the rat perfume!", "Damn, it
-- didn't fart!", "The keen noses of the ratmen will smell the mark of their rivals!" and
-- "Luckily the makeshift bow breaks ..." are Tibia's (BR screenshots, EN); the others ours.
--
-- Switch: Family.goblinMerchant (false = the items do nothing and kills do not count;
-- Rafzan still talks).

Family = Family or {}
Family.goblinMerchant = true

local G = FamilyGoblinMerchant
local it = G.items

local function message(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

local function isItem(target)
	return target and type(target) == "userdata" and target.isItem and target:isItem()
end

local function isMonsterNamed(target, name)
	return target and type(target) == "userdata" and target.isMonster and target:isMonster() and target:getName():lower() == name:lower()
end

-- ---------------------------------------------------------------------------
-- Advertisement signs
-- ---------------------------------------------------------------------------
local function freeStone(position)
	local tile = Tile(position)
	local sign = tile and tile:getItemById(it.signOnStone)
	if sign then
		sign:transform(it.crackedStone)
		position:sendMagicEffect(CONST_ME_POFF)
	end
end

local sign = Action()

function sign.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.goblinMerchant or not isItem(target) then
		return false
	end
	local id = target:getId()
	if id == it.signOnStone then
		message(player, "There is already a sign in this stone.") -- ours
		return true
	end
	if id ~= it.crackedStone then
		return false
	end
	if G.state(player, "advertising") ~= G.ACTIVE then
		message(player, "Rafzan did not ask you to place any signs.") -- ours
		return true
	end
	local n, done = G.addProgress(player, "advertising")
	item:remove(1)
	target:transform(it.signOnStone)
	toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
	addEvent(freeStone, G.signMinutes * 60 * 1000, Position(toPosition.x, toPosition.y, toPosition.z))
	if done then
		message(player, "You placed the last advertisement sign. Report to Rafzan.") -- ours
	else
		message(player, string.format("You place an advertisement sign into the cracked stone. %d / 3", n)) -- ours
	end
	return true
end

sign:id(it.sign)
sign:register()

-- ---------------------------------------------------------------------------
-- Guardcatcher
-- ---------------------------------------------------------------------------
local guardcatcher = Action()

function guardcatcher.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.goblinMerchant or not isMonsterNamed(target, "Adventurer") then
		return false
	end
	if G.state(player, "guards") ~= G.ACTIVE then
		message(player, "Rafzan did not ask you to shoot anybody.") -- ours
		return true
	end
	local position = target:getPosition()
	player:getPosition():sendDistanceEffect(position, CONST_ANI_ARROW)
	if math.random(100) <= G.angryChance then
		target:remove()
		local angry = Game.createMonster("Angry Adventurer", position, false, true)
		if angry then
			angry:say("You fiend! I will get you, servant of evil!", TALKTYPE_MONSTER_SAY)
			angry:setTarget(player)
		end
		return true
	end
	target:say("Arrrgh! Not my knee!", TALKTYPE_MONSTER_SAY)
	position:sendMagicEffect(CONST_ME_DRAWBLOOD)
	target:remove()
	local n, done = G.addProgress(player, "guards")
	if done then
		item:remove(1)
		message(player, "Luckily the makeshift bow breaks as you hit the last adventurer you needed and not earlier!")
	elseif n then
		message(player, string.format("This adventurer will surely reconsider becoming Rafzan's guard. %d / 3", n)) -- ours
	end
	return true
end

guardcatcher:id(it.guardcatcher)
guardcatcher:allowFarUse(true) -- a bow
guardcatcher:register()

-- ---------------------------------------------------------------------------
-- Perfume gatherer
-- ---------------------------------------------------------------------------
local stageOf = {}
for i, id in ipairs(it.gatherer) do
	stageOf[id] = i
end

-- Returns true when the target is the odour of this stage; also sends the messages.
local function gather(player, item, stage, target, toPosition)
	if stage == 1 then
		if not isItem(target) then
			return nil
		end
		if target:getId() == it.newSlug then
			message(player, "The slime is not ready yet. Wait a little.") -- ours (EN: wait 10 seconds)
			return false
		end
		if target:getId() ~= it.freshSlug then
			return nil
		end
		message(player, "You gather the first part of the rat perfume!")
	elseif stage == 2 then
		if not isItem(target) or target:getId() ~= it.swampGas then
			return nil
		end
		message(player, "You gather the second part of the rat perfume!")
	elseif stage == 3 then
		if not isMonsterNamed(target, "Rotworm") then
			return nil
		end
		if math.random(100) > G.fartChance then
			message(player, "Damn, it didn't fart!")
			return false
		end
		message(player, "You gather the third part of the rat perfume!")
	elseif stage == 4 then
		if not isItem(target) or target:getId() ~= it.mouldyCheese then
			return nil
		end
		target:remove(1)
		message(player, "You gather the last part of the rat perfume!")
	end
	return true
end

local gatherer = Action()

function gatherer.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.goblinMerchant then
		return false
	end
	local stage = stageOf[item:getId()]
	if not stage then
		return false
	end
	local result = gather(player, item, stage, target, toPosition)
	if result == nil then
		return false
	end
	if result then
		item:transform(stage < 4 and it.gatherer[stage + 1] or it.gathererFull)
		toPosition:sendMagicEffect(CONST_ME_GREEN_RINGS)
	end
	return true
end

for _, id in ipairs(it.gatherer) do
	gatherer:id(id)
end
gatherer:allowFarUse(true) -- rotworms move
gatherer:register()

-- ---------------------------------------------------------------------------
-- Bottle with rat urine
-- ---------------------------------------------------------------------------
local urine = Action()

function urine.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.goblinMerchant or not toPosition or not G.pondAt(toPosition) then
		return false
	end
	local tile = Tile(toPosition)
	local ground = tile and tile:getGround()
	if not ground or ground:getId() ~= G.pond.ground then
		return false
	end
	if not G.markPond(player) then
		message(player, "Rafzan did not ask you to do that.") -- ours
		return true
	end
	item:remove(1)
	toPosition:sendMagicEffect(CONST_ME_YELLOW_RINGS)
	message(player, "The keen noses of the ratmen will smell the mark of their rivals!")
	return true
end

urine:id(it.urine)
urine:allowFarUse(true) -- EN: from a distance, like a fishing rod
urine:register()

-- ---------------------------------------------------------------------------
-- Trunkhammer
-- ---------------------------------------------------------------------------
local hammer = Action()

function hammer.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not Family.goblinMerchant or not isItem(target) or target:getId() ~= it.junkTrunk then
		return false
	end
	if G.state(player, "destroy") ~= G.ACTIVE then
		message(player, "Rafzan did not ask you to destroy anything.") -- ours
		return true
	end
	local n, done = G.addProgress(player, "destroy")
	target:transform(it.smashedTrunk)
	target:decay()
	toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
	if done then
		item:remove(1)
		message(player, "You smash the last junk trunk and your trunkhammer breaks. Report to Rafzan.") -- ours
	else
		message(player, string.format("You smash the junk trunk. %d / 3", n)) -- ours
	end
	return true
end

hammer:id(it.trunkhammer)
hammer:register()

-- ---------------------------------------------------------------------------
-- Marsh stalkers
-- ---------------------------------------------------------------------------
local function countStalker(player)
	local n, done = G.addProgress(player, "kill")
	if done then
		message(player, "You killed five marsh stalkers. Report to Rafzan.") -- ours
	elseif n then
		message(player, string.format("Marsh stalkers killed for Rafzan: %d / 5", n)) -- ours
	end
end
G.countStalker = countStalker

local death = CreatureEvent("FamilyGoblinMerchantStalker")

function death.onDeath(creature, corpse, lastHitKiller, mostDamageKiller)
	if Family.goblinMerchant then
		onDeathForDamagingPlayers(creature, function(_, player)
			countStalker(player)
		end)
	end
	return true
end

death:register()

local startup = GlobalEvent("FamilyGoblinMerchantStartup")

function startup.onStartup()
	local mType = MonsterType("Marsh Stalker")
	if mType then
		mType:registerEvent("FamilyGoblinMerchantStalker")
	else
		logger.error("[Family] Goblin Merchant: monster type Marsh Stalker not found")
	end
	logger.info("[Family] Goblin Merchant: {}", Family.goblinMerchant and "on" or "off")
	return true
end

startup:register()
