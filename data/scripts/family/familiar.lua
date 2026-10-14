-- Gaia Family server: permanent familiars (2026-10-14). Ours, not upstream.
--
-- Upstream, the familiar spell (knight "utevo gran res eq", paladin "utevo
-- gran res sac", druid "utevo gran res dru", sorcerer "utevo gran res ven",
-- monk "utevo gran res tio"; level 200, premium) calls a familiar for 15
-- minutes, followed by a 15-minute cooldown. Here:
--
-- * the familiar stays until its master says the spell again (it then leaves,
--   free of charge) or until it dies;
-- * no cooldown: after dismissing it, or after it dies, say the spell again;
-- * mana is only charged when the familiar appears (upstream cost: knight
--   1000, monk 1500, paladin 2000, druid and sorcerer 3000);
-- * it comes back by itself after logging out and in, or after the master
--   dies, until it is dismissed or killed.
--
-- Unchanged: level 200, one summon at a time, familiars follow their master
-- (also through stairs and teleports) but cannot enter boss rooms.
--
-- Switch: FAMILY_PERMANENT_FAMILIAR in data/scripts/lib/family_familiar.lua.
-- The upstream functions replaced here live in data/libs/functions/player.lua.

Family = Family or {}
Family.permanentFamiliar = FAMILY_PERMANENT_FAMILIAR

if not Family.permanentFamiliar then
	return
end

-- Stored as the familiar's "summon time": far enough to never run out.
local FOREVER = 10 * 365 * 24 * 60 * 60

local function stopUpstreamTimers(player)
	for i = 1, #FAMILIAR_TIMER do
		stopEvent(player:getStorageValue(FAMILIAR_TIMER[i].storage))
		player:setStorageValue(FAMILIAR_TIMER[i].storage, -1)
	end
end

function Family.findFamiliar(player)
	local name = player:getFamiliarName()
	if not name then
		return nil
	end
	for _, summon in ipairs(player:getSummons()) do
		if summon:getName():lower() == name:lower() then
			return summon
		end
	end
	return nil
end

-- Replaces the upstream Player:createFamiliar: same familiar, no timer.
-- Also used by the upstream login script to bring the familiar back.
function Player:createFamiliar(familiarName, timeLeft)
	local playerPosition = self:getPosition()
	if not familiarName then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local myFamiliar = Game.createMonster(familiarName, playerPosition, true, false, self)
	if not myFamiliar then
		self:sendCancelMessage(RETURNVALUE_NOTENOUGHROOM)
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	myFamiliar:setOutfit({ lookType = self:getFamiliarLooktype() })
	myFamiliar:registerEvent("FamiliarDeath")
	myFamiliar:changeSpeed(math.max(self:getSpeed() - myFamiliar:getBaseSpeed(), 0))
	playerPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
	myFamiliar:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	stopUpstreamTimers(self)
	self:kv():set("familiar-summon-time", os.time() + FOREVER)
	return true
end

-- Replaces the upstream Player:CreateFamiliarSpell (called by the five
-- familiar spells): the spell now toggles the familiar.
function Player:CreateFamiliarSpell(spellId)
	local playerPosition = self:getPosition()
	if not self:isPremium() then
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		self:sendCancelMessage("You need a premium account.")
		return false
	end

	local current = Family.findFamiliar(self)
	if current then
		-- Dismiss. Returning false: no mana, no exhaustion, nothing said aloud.
		stopUpstreamTimers(self)
		self:kv():set("familiar-summon-time", os.time())
		playerPosition:sendMagicEffect(CONST_ME_MAGIC_BLUE)
		current:getPosition():sendMagicEffect(CONST_ME_POFF)
		current:remove()
		self:sendTextMessage(MESSAGE_STATUS, "Your familiar has left. Say the spell again to call it back.")
		return false
	end

	if #self:getSummons() >= 1 and self:getAccountType() < ACCOUNT_TYPE_GOD then
		self:sendCancelMessage("You can't have other summons.")
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local familiarName = self:getFamiliarName()
	if not familiarName then
		self:sendCancelMessage(RETURNVALUE_NOTPOSSIBLE)
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	local mana = FAMILY_FAMILIAR_MANA[spellId] or 0
	if self:getMana() < mana and not self:hasFlag(PlayerFlag_HasInfiniteMana) then
		self:sendCancelMessage(RETURNVALUE_NOTENOUGHMANA)
		playerPosition:sendMagicEffect(CONST_ME_POFF)
		return false
	end

	if not self:createFamiliar(familiarName, FOREVER) then
		return false
	end
	if mana > 0 and not self:hasFlag(PlayerFlag_HasInfiniteMana) then
		self:addManaSpent(mana)
		self:addMana(-mana)
	end
	self:sendTextMessage(MESSAGE_STATUS, "Your familiar will stay with you. Say the spell again to send it away.")
	return true
end

local familiarReport = GlobalEvent("FamilyFamiliarReport")

function familiarReport.onStartup()
	local costs = {}
	for spellId, mana in pairs(FAMILY_FAMILIAR_MANA) do
		costs[#costs + 1] = string.format("%d:%d", spellId, mana)
	end
	table.sort(costs)
	logger.info("[Family] familiars: permanent=true, saying the spell again dismisses (free); mana by spell id {}", table.concat(costs, " "))
	return true
end

familiarReport:register()
