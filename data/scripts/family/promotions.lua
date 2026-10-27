-- Gaia Family server: promotions after the level 20 one (2026-10-27).
-- Ours, not upstream. Tiers, names, prices and bonus math are in
-- data/scripts/lib/family_promotions.lua (FamilyPromotions); this file:
--
-- * Bonuses: about once a second each character is checked; the promotion
--   bonuses are one attribute condition (damage dealt and taken, critical,
--   leech, max health/mana, capacity, auto-attack, healing, elements) and one
--   regeneration condition (a share of max health and mana every 3 seconds,
--   only while fed, like the normal one). Both are rebuilt when the tier,
--   level or vocation changes, and re-added after logging in. Max health,
--   mana and capacity percentages are taken from the values without them.
-- * Knights' melee bonus: creatureOnCombat on auto-attacks (origin melee).
-- * NPCs: the six promoting NPCs (King Tibianus, Queen Eloise, Emperor
--   Kruzak, Emperor Rehal, Ishebad, Enpa Rudra) answer "promotion" with the
--   next promotion once the level 20 one is done, and "yes" buys it (bank
--   and carried gold, like the upstream promotion). Hook on
--   KeywordNode:processMessage installed at startup (the NPC library loads
--   after these scripts); no NPC file changed.
-- * !promotion: your title, bonuses, next promotion and the full list.
-- * Look text: "He is an elite knight (Knight Commander)." (FAMILY edit in
--   data/scripts/eventcallbacks/player/on_look.lua).
-- * GOD: /setpromotion Name, tier
--
-- Switch: Family.promotions (lib file).

local P = FamilyPromotions

local ATTRIBUTES_SUBID = 7310
local REGEN_SUBID = 7311

local ELEMENT_PARAMS = {
	physical = CONDITION_PARAM_INCREASE_PHYSICALPERCENT,
	fire = CONDITION_PARAM_INCREASE_FIREPERCENT,
	energy = CONDITION_PARAM_INCREASE_ENERGYPERCENT,
	ice = CONDITION_PARAM_INCREASE_ICEPERCENT,
	earth = CONDITION_PARAM_INCREASE_EARTHPERCENT,
	death = CONDITION_PARAM_INCREASE_DEATHPERCENT,
	holy = CONDITION_PARAM_INCREASE_HOLYPERCENT,
}

local state = {} -- player id -> { attributes = key, regen = key, melee = percent }

local function isFed(player)
	return player:getCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT) ~= nil
end

local function round(value)
	return math.floor(value + 0.5)
end

-- The attribute condition for a set of bonuses (nil when there is nothing).
function P.attributeCondition(b)
	local condition = Condition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT, ATTRIBUTES_SUBID)
	condition:setTicks(-1)
	local any = false
	local function set(param, value)
		if value and value ~= 0 then
			condition:setParameter(param, value)
			any = true
		end
	end
	if b.damageDealt > 0 then
		set(CONDITION_PARAM_BUFF_DAMAGEDEALT, 100 + round(b.damageDealt))
	end
	if b.damageTaken > 0 then
		set(CONDITION_PARAM_BUFF_DAMAGERECEIVED, 100 - round(b.damageTaken))
	end
	set(CONDITION_PARAM_SKILL_CRITICAL_HIT_CHANCE, round(b.critChance * 100))
	set(CONDITION_PARAM_SKILL_CRITICAL_HIT_DAMAGE, round(b.critDamage * 100))
	set(CONDITION_PARAM_SKILL_LIFE_LEECH_AMOUNT, round(b.lifeLeech * 100))
	set(CONDITION_PARAM_SKILL_MANA_LEECH_AMOUNT, round(b.manaLeech * 100))
	if b.maxHealth > 0 then
		set(CONDITION_PARAM_STAT_MAXHITPOINTSPERCENT, 100 + round(b.maxHealth))
	end
	if b.maxMana > 0 then
		set(CONDITION_PARAM_STAT_MAXMANAPOINTSPERCENT, 100 + round(b.maxMana))
	end
	set(CONDITION_PARAM_STAT_CAPACITYPERCENT, round(b.capacity))
	if b.autoAttack > 0 then
		set(CONDITION_PARAM_BUFF_AUTOATTACKDEALT, 100 + round(b.autoAttack))
	end
	if b.healing > 0 then
		set(CONDITION_PARAM_BUFF_HEALINGDEALT, 100 + round(b.healing))
	end
	for element, value in pairs(b.elements) do
		if ELEMENT_PARAMS[element] then
			set(ELEMENT_PARAMS[element], round(value))
		end
	end
	return any and condition or nil
end

local function setAttributes(player, s, key, b)
	if s.attributes == key and (key == "none" or player:getCondition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT, ATTRIBUTES_SUBID)) then
		return
	end
	player:removeCondition(CONDITION_ATTRIBUTES, CONDITIONID_DEFAULT, ATTRIBUTES_SUBID)
	if key ~= "none" then
		local condition = P.attributeCondition(b)
		if condition then
			player:addCondition(condition)
		end
	end
	s.attributes = key
end

local function setRegen(player, s, key, health, mana)
	if s.regen == key then
		return
	end
	player:removeCondition(CONDITION_REGENERATION, CONDITIONID_DEFAULT, REGEN_SUBID)
	if key ~= "none" then
		local condition = Condition(CONDITION_REGENERATION, CONDITIONID_DEFAULT, REGEN_SUBID)
		condition:setTicks(-1)
		condition:setParameter(CONDITION_PARAM_HEALTHGAIN, health)
		condition:setParameter(CONDITION_PARAM_HEALTHTICKS, P.regenTicks)
		condition:setParameter(CONDITION_PARAM_MANAGAIN, mana)
		condition:setParameter(CONDITION_PARAM_MANATICKS, P.regenTicks)
		player:addCondition(condition)
	end
	s.regen = key
end

function P.update(player)
	local id = player:getId()
	local s = state[id]
	if not s then
		s = {}
		state[id] = s
	end
	local kind = P.kind(player)
	local tier = (Family.promotions and kind) and P.tier(player) or 0
	local b = P.bonuses(kind or "", tier)

	local attributesKey = "none"
	if tier > 0 then
		attributesKey = string.format("%s/%d/%d", kind, tier, player:getLevel())
	end
	setAttributes(player, s, attributesKey, b)

	local regenKey = "none"
	local health, mana = 0, 0
	if tier > 0 and b.regen > 0 and isFed(player) then
		health = math.floor(player:getMaxHealth() * b.regen / 100)
		mana = math.floor(player:getMaxMana() * b.regen / 100)
		if health > 0 or mana > 0 then
			regenKey = string.format("%d/%d", health, mana)
		end
	end
	setRegen(player, s, regenKey, health, mana)

	s.melee = b.melee
	P.cooldownFactors[id] = P.cooldownFactor(tier)
end

local think = EventCallback("FamilyPromotionsThink")

function think.playerOnThink(player, interval)
	P.update(player)
end

think:register()

local login = CreatureEvent("FamilyPromotionsLogin")

function login.onLogin(player)
	state[player:getId()] = { attributes = "?", regen = "?" }
	P.update(player)
	return true
end

login:register()

local logout = CreatureEvent("FamilyPromotionsLogout")

function logout.onLogout(player)
	state[player:getId()] = nil
	P.cooldownFactors[player:getId()] = nil
	return true
end

logout:register()

-- Knights: melee auto-attacks.
function P.meleeBonus(caster, damage)
	if not Family.promotions or not caster or not caster:isPlayer() or damage.origin ~= ORIGIN_MELEE then
		return false
	end
	local s = state[caster:getId()]
	local percent = s and s.melee or 0
	if percent <= 0 then
		return false
	end
	local multiplier = 1 + percent / 100
	if damage.primary.type ~= COMBAT_HEALING then
		damage.primary.value = math.floor(damage.primary.value * multiplier)
	end
	if damage.secondary.type ~= COMBAT_HEALING then
		damage.secondary.value = math.floor(damage.secondary.value * multiplier)
	end
	return true
end

local combat = EventCallback("FamilyPromotionsMelee")

function combat.creatureOnCombat(caster, target, damage)
	P.meleeBonus(caster, damage)
	return true
end

combat:register()

-- Buying the next promotion. Returns ok, text for the NPC.
function P.nextFor(player)
	local tier = P.tier(player)
	return P.tiers[tier + 1], tier + 1
end

function P.offerText(player)
	local kind = P.kind(player)
	local nextRow, nextTier = P.nextFor(player)
	if not nextRow then
		return string.format("You have reached every promotion there is, %s. There is nothing left I could grant you.", P.title(kind, P.tier(player), player:getVocation():getName()))
	end
	local title = P.title(kind, nextTier)
	if player:getLevel() < nextRow.level then
		return string.format("Your next promotion is %s, at level %d. Come back when you have reached it.", title, nextRow.level)
	end
	return string.format("You have proven yourself. I can raise you to %s for %s gold coins. Do you want me to promote you?", title, P.formatGold(nextRow.gold))
end

function P.buy(player)
	local kind = P.kind(player)
	local nextRow, nextTier = P.nextFor(player)
	if not kind or not nextRow then
		return false, "There is no promotion left I could grant you."
	end
	if player:getLevel() < nextRow.level then
		return false, string.format("I am sorry, but I can only promote you once you have reached level %d.", nextRow.level)
	end
	if not player:removeMoneyBank(nextRow.gold) then
		return false, "You do not have enough money!"
	end
	P.setTier(player, nextTier)
	local title = P.title(kind, nextTier)
	P.update(player)
	player:getPosition():sendMagicEffect(CONST_ME_HOLYAREA)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You are now %s %s. Say !promotion to see your bonuses.", title:match("^[AEIOU]") and "an" or "a", title))
	if Family.chronicleRecord then
		Family.chronicleRecord(player, "p", title)
	end
	logger.info("[Family] promotion: {} is now {} (tier {})", player:getName(), title, nextTier)
	return true, string.format("Congratulations! You are now %s.", title)
end

-- NPC hook: the promoting NPCs' "promot" node and its "yes" child.
local function installNpcHook()
	if not KeywordNode or not StdModule then
		return false
	end
	if KeywordNode.familyPromotions then
		return true
	end
	local say, promote = StdModule.say, StdModule.promotePlayer
	local originalProcessMessage = KeywordNode.processMessage
	function KeywordNode:processMessage(npc, creature, message)
		if Family.promotions and self.parameters and self.parameters.npcHandler then
			local isOffer = self.callback == say and self.keywords and self.keywords[1] == "promot"
			local isBuy = self.callback == promote
			if isOffer or isBuy then
				local player = Player(creature)
				if player and P.hasBasePromotion(player) and P.kind(player) then
					local npcHandler = self.parameters.npcHandler
					if not npcHandler:checkInteraction(npc, creature) then
						return false
					end
					if isOffer then
						npcHandler:say(P.offerText(player), npc, creature)
					else
						local _, text = P.buy(player)
						npcHandler:say(text, npc, creature)
						npcHandler:resetNpc(creature)
					end
					return true
				end
			end
		end
		return originalProcessMessage(self, npc, creature, message)
	end
	KeywordNode.familyPromotions = true
	return true
end

-- Look text: "He is an elite knight (Knight Commander)."
function Family.promotionLookText(target, text)
	if not Family.promotions then
		return text
	end
	local tier = P.tier(target)
	local kind = P.kind(target)
	if tier <= 0 or not kind then
		return text
	end
	local description = target:getVocation():getDescription()
	local first, last = text:find(description .. ".", 1, true)
	if not first then
		return text
	end
	return text:sub(1, last - 1) .. " (" .. P.title(kind, tier) .. ")" .. text:sub(last)
end

-- !promotion
local function bonusLines(kind, b)
	local lines = {}
	local function add(format, value)
		if value and value > 0 then
			lines[#lines + 1] = string.format(format, P.formatPercent(value))
		end
	end
	add("  Damage dealt +%s%%", b.damageDealt)
	add("  Damage taken -%s%%", b.damageTaken)
	add("  Spell cooldowns -%s%%", b.cooldown)
	add("  Critical hit chance +%s%%", b.critChance)
	add("  Critical extra damage +%s%%", b.critDamage)
	add("  Regeneration %s%% of max health and mana every 3 s (while fed)", b.regen)
	add("  Capacity +%s%%", b.capacity)
	add("  Max health +%s%%", b.maxHealth)
	add("  Max mana +%s%%", b.maxMana)
	add("  Melee auto-attack damage +%s%%", b.melee)
	add(kind == "monk" and "  Fist auto-attack damage +%s%%" or "  Ranged auto-attack damage +%s%%", b.autoAttack)
	add("  Healing dealt +%s%%", b.healing)
	add("  Life leech +%s%%", b.lifeLeech)
	add("  Mana leech +%s%%", b.manaLeech)
	for _, element in ipairs(P.elementOrder) do
		add("  " .. element:gsub("^%l", string.upper) .. " damage +%s%%", b.elements[element])
	end
	return lines
end

function P.guide(player)
	local lines = { "PROMOTIONS" }
	local kind = P.kind(player)
	if not kind then
		lines[#lines + 1] = "Promotions are for characters with a vocation."
		return table.concat(lines, "\n")
	end
	local vocation = player:getVocation()
	local tier = P.tier(player)
	local promotedName = vocation:getName()
	if P.hasBasePromotion(player) then
		lines[#lines + 1] = string.format("You are %s.", tier > 0 and string.format("%s (%s, promotion %d of %d)", P.title(kind, tier), promotedName, tier, #P.tiers) or promotedName)
	else
		local promotion = vocation:getPromotion()
		promotedName = promotion and promotion:getName() or promotedName
		lines[#lines + 1] = string.format("You are %s. First get promoted to %s at level %d (%s gold).", vocation:getName(), promotedName, P.basePromotion.level, P.formatGold(P.basePromotion.gold))
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = "YOUR PROMOTION BONUSES"
	local current = bonusLines(kind, P.bonuses(kind, tier))
	if #current == 0 then
		lines[#lines + 1] = "  none yet"
	else
		for _, line in ipairs(current) do
			lines[#lines + 1] = line
		end
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = "NEXT PROMOTION"
	local nextRow = P.tiers[tier + 1]
	if nextRow then
		lines[#lines + 1] = string.format("  %s at level %d for %s gold.", P.title(kind, tier + 1), nextRow.level, P.formatGold(nextRow.gold))
		lines[#lines + 1] = "  Say 'promotion' to " .. table.concat(P.npcs, ", ") .. "."
	else
		lines[#lines + 1] = "  You have every promotion there is."
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = "ALL PROMOTIONS"
	lines[#lines + 1] = string.format("  Level %d: %s (%s gold)%s", P.basePromotion.level, promotedName, P.formatGold(P.basePromotion.gold), P.hasBasePromotion(player) and " - done" or "")
	for i, row in ipairs(P.tiers) do
		lines[#lines + 1] = string.format("  Level %d: %s (%s gold)%s", row.level, P.title(kind, i), P.formatGold(row.gold), i <= tier and " - done" or "")
	end

	lines[#lines + 1] = ""
	lines[#lines + 1] = "EACH PROMOTION ADDS"
	for _, line in ipairs(bonusLines(kind, P.bonuses(kind, 1))) do
		lines[#lines + 1] = line
	end
	lines[#lines + 1] = "  (damage, damage taken and cooldowns multiply per promotion; cooldowns never go below half)"

	local last = #P.tiers
	lines[#lines + 1] = ""
	lines[#lines + 1] = string.format("WITH ALL %d PROMOTIONS", last)
	for _, line in ipairs(bonusLines(kind, P.bonuses(kind, last))) do
		lines[#lines + 1] = line
	end
	return table.concat(lines, "\n")
end

local GUIDE_ITEM = 2821 -- book shown as the dialog icon

local guide = TalkAction("!promotion", "!promotions")

function guide.onSay(player, words, param)
	player:showTextDialog(GUIDE_ITEM, P.guide(player))
	return true
end

guide:setDescription("- your promotion, its bonuses and the next promotions")
guide:groupType("normal")
guide:register()

local setTier = TalkAction("/setpromotion")

function setTier.onSay(player, words, param)
	local name, value = param:match("^%s*(.-)%s*,%s*(%d+)%s*$")
	local target = name and Player(name)
	if not target then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Usage: /setpromotion Name, tier (0 to " .. #P.tiers .. "). The player must be online.")
		return true
	end
	local tier = math.max(0, math.min(#P.tiers, tonumber(value)))
	P.setTier(target, tier)
	P.update(target)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("%s: promotion tier %d (%s).", target:getName(), P.tier(target), P.title(P.kind(target) or "", P.tier(target), target:getVocation():getName())))
	return true
end

setTier:separator(" ")
setTier:groupType("god")
setTier:register()

local startup = GlobalEvent("FamilyPromotionsStartup")

function startup.onStartup()
	local hooked = installNpcHook()
	if not hooked then
		logger.warn("[Family] promotions: NPC library not found, the NPCs only offer the level 20 promotion")
	end
	local levels = {}
	for _, row in ipairs(P.tiers) do
		levels[#levels + 1] = tostring(row.level)
	end
	logger.info("[Family] promotions: {} (levels {}), NPC hook {}, cooldown hook {}", tostring(Family.promotions), table.concat(levels, "/"), tostring(hooked), tostring(rawgetmetatable("Spell").__newindex == P.spellNewIndex))
	return true
end

startup:register()
