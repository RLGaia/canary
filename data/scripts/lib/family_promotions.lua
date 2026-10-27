-- Gaia Family server: promotions after the level 20 one (2026-10-27).
-- Ours, not upstream. Asked by Rodrigo: new promotions at level milestones,
-- each one stronger, open-ended (Tibia has no level cap), strong enough to
-- help two players through content made for bigger teams.
--
-- They are not new vocations: the pinned engine keeps familiars in a table
-- sized for vocation ids 0-10 (a higher id would read past it when the outfit
-- window opens) and the client knows only the five vocations. A promotion is a
-- tier stored per character (KV family-promotion / tier) on top of the
-- promoted vocation (Elite Knight, Royal Paladin, Master Sorcerer, Elder
-- Druid, Exalted Monk). The bonuses are conditions and two hooks:
--   data/scripts/family/promotions.lua  bonuses, NPC dialogue, !promotion,
--                                        look text, knight melee bonus
--   this file                           tiers, bonus math, spell cooldowns
--
-- Spell cooldowns: the engine adds a spell's cooldown after its Lua
-- onCastSpell returns. Every onCastSpell is attached through Spell's
-- __newindex (data/libs/functions/revscriptsys.lua); this file wraps that
-- __newindex (data/scripts/lib loads before every spell) so a player's cast
-- shortens the fresh cooldown right after the engine set it, never below
-- half of the spell's base cooldown (the engine's own floor).
--
-- Adding a promotion later: add a row to FamilyPromotions.tiers (level, gold,
-- a name per vocation). Every promotion adds the same step of bonuses;
-- damage, damage taken and cooldowns multiply per step, so they never reach
-- 0 or 100%.
--
-- Switch: Family.promotions.

Family = Family or {}
Family.promotions = true

FamilyPromotions = {
	tiers = {
		{ level = 200, gold = 300000, names = { knight = "Knight Commander", paladin = "Templar", sorcerer = "Magus", druid = "Archdruid", monk = "Enlightened Monk" } },
		{ level = 400, gold = 1000000, names = { knight = "Champion", paladin = "Justicar", sorcerer = "Spellbinder", druid = "Grovekeeper", monk = "Sage" } },
		{ level = 600, gold = 3000000, names = { knight = "Warlord", paladin = "Crusader", sorcerer = "Archmage", druid = "Wildwarden", monk = "Grandmaster" } },
		{ level = 800, gold = 5000000, names = { knight = "Warmaster", paladin = "Avenger", sorcerer = "Archon", druid = "Earthshaper", monk = "Celestial" } },
		{ level = 1000, gold = 8000000, names = { knight = "Paragon", paladin = "Exemplar", sorcerer = "Arcane Sovereign", druid = "Hierophant", monk = "Ascendant" } },
	},

	-- Every promotion, every vocation.
	shared = {
		damageDealt = 5, -- percent, multiplies per promotion (x1.05)
		damageTaken = 3, -- percent, multiplies per promotion (x0.97)
		cooldown = 6, -- percent, multiplies per promotion (x0.94)
		critChance = 2, -- percent points
		critDamage = 5, -- percent points of extra critical damage
		regen = 0.3, -- percent of max health and of max mana every regenTicks, while fed
		capacity = 5, -- percent
	},
	regenTicks = 3000,
	cooldownFloor = 0.5, -- share of the spell's base cooldown that always stays

	-- Each vocation, every promotion, on top of the shared step.
	-- damageTaken multiplies like the shared one; the rest adds up.
	vocations = {
		knight = { maxHealth = 4, damageTaken = 2, melee = 4, lifeLeech = 1 },
		paladin = { autoAttack = 5, elements = { holy = 4 }, critDamage = 5, maxHealth = 2, maxMana = 2 },
		sorcerer = { elements = { fire = 4, energy = 4, death = 4 }, maxMana = 4, manaLeech = 1 },
		druid = { healing = 6, elements = { ice = 4, earth = 4 }, maxMana = 4 },
		monk = { autoAttack = 5, elements = { physical = 4 }, lifeLeech = 1, maxHealth = 2 },
	},

	-- The level 20 promotion, for the !promotion list.
	basePromotion = { level = 20, gold = 20000 },
	npcs = { "King Tibianus", "Queen Eloise", "Emperor Kruzak", "Emperor Rehal", "Ishebad", "Enpa Rudra" },
}

local P = FamilyPromotions

local KIND_BY_BASE = { [1] = "sorcerer", [2] = "druid", [3] = "paladin", [4] = "knight", [9] = "monk" }
P.elementOrder = { "physical", "fire", "energy", "ice", "earth", "death", "holy" }

-- "knight", "paladin", "sorcerer", "druid", "monk" or nil
function P.kind(player)
	local vocation = player:getVocation()
	return vocation and KIND_BY_BASE[vocation:getBaseId()] or nil
end

-- true when the character has the level 20 promotion
function P.hasBasePromotion(player)
	local vocation = player:getVocation()
	if not vocation then
		return false
	end
	return vocation:getBaseId() ~= 0 and vocation:getId() ~= vocation:getBaseId()
end

local function scope(player)
	return player:kv():scoped("family-promotion")
end

-- Number of promotions after the level 20 one (0 = none yet).
function P.tier(player)
	if not P.hasBasePromotion(player) then
		return 0
	end
	local value = tonumber(scope(player):get("tier")) or 0
	return math.max(0, math.min(#P.tiers, math.floor(value)))
end

function P.setTier(player, tier)
	scope(player):set("tier", tier)
end

-- Title of a tier for a vocation kind (tier 0 = the vocation's own name).
function P.title(kind, tier, vocationName)
	if tier <= 0 then
		return vocationName
	end
	local row = P.tiers[tier]
	return (row and row.names[kind]) or string.format("Ascension %d", tier)
end

-- The promotion bonuses of a vocation kind at a tier, as totals.
function P.bonuses(kind, tier)
	local s, v = P.shared, P.vocations[kind] or {}
	local b = {
		damageDealt = 0,
		damageTaken = 0,
		cooldown = 0,
		critChance = 0,
		critDamage = 0,
		regen = 0,
		capacity = 0,
		maxHealth = 0,
		maxMana = 0,
		melee = 0,
		autoAttack = 0,
		healing = 0,
		lifeLeech = 0,
		manaLeech = 0,
		elements = {},
	}
	if tier <= 0 then
		return b
	end
	local takenStep = (1 - s.damageTaken / 100) * (1 - (v.damageTaken or 0) / 100)
	b.damageDealt = ((1 + s.damageDealt / 100) ^ tier - 1) * 100
	b.damageTaken = (1 - takenStep ^ tier) * 100
	b.cooldown = (1 - (1 - s.cooldown / 100) ^ tier) * 100
	b.critChance = (s.critChance + (v.critChance or 0)) * tier
	b.critDamage = (s.critDamage + (v.critDamage or 0)) * tier
	b.regen = s.regen * tier
	b.capacity = s.capacity * tier
	for _, field in ipairs({ "maxHealth", "maxMana", "melee", "autoAttack", "healing", "lifeLeech", "manaLeech" }) do
		b[field] = (v[field] or 0) * tier
	end
	for element, value in pairs(v.elements or {}) do
		b.elements[element] = value * tier
	end
	return b
end

-- Remaining share of a cooldown at a tier (1 = unchanged).
function P.cooldownFactor(tier)
	if tier <= 0 then
		return 1
	end
	return (1 - P.shared.cooldown / 100) ^ tier
end

-- Cached per player id by the bonus updater, read on every cast.
P.cooldownFactors = P.cooldownFactors or {}

-- Shortens the fresh cooldown of a spell the player has just cast.
-- Returns the new ticks, or nil when nothing changed.
function P.shortenCooldown(player, spellId, baseCooldown, factor)
	local condition = player:getCondition(CONDITION_SPELLCOOLDOWN, CONDITIONID_DEFAULT, spellId)
	if not condition then
		return nil
	end
	local ticks = condition:getTicks()
	if not ticks or ticks <= 0 then
		return nil
	end
	local floor = math.floor(baseCooldown * P.cooldownFloor)
	local wanted = math.max(math.floor(ticks * factor), math.min(ticks, floor))
	if wanted >= ticks then
		return nil
	end
	-- a new condition, so the client gets the new time (sendSpellCooldown in
	-- Lua takes the spell id as one byte; ids go up to 297)
	player:removeCondition(CONDITION_SPELLCOOLDOWN, CONDITIONID_DEFAULT, spellId)
	local shorter = Condition(CONDITION_SPELLCOOLDOWN, CONDITIONID_DEFAULT, spellId)
	shorter:setTicks(wanted)
	player:addCondition(shorter)
	return wanted
end

local function afterCast(creature, spell)
	if not Family.promotions or not creature or not creature:isPlayer() then
		return
	end
	local factor = P.cooldownFactors[creature:getId()]
	if not factor or factor >= 1 then
		return
	end
	local spellId, baseCooldown = spell:id(), spell:cooldown()
	if not spellId or spellId == 0 or not baseCooldown or baseCooldown <= 0 then
		return
	end
	local playerId = creature:getId()
	-- the engine adds the cooldown after onCastSpell returns
	addEvent(function()
		local player = Player(playerId)
		if player then
			P.shortenCooldown(player, spellId, baseCooldown, factor)
		end
	end, 0)
end

function P.wrapCast(spell, callback)
	return function(creature, variant, ...)
		local result = callback(creature, variant, ...)
		if result then
			afterCast(creature, spell)
		end
		return result
	end
end

do
	local meta = rawgetmetatable("Spell")
	if meta then
		-- kept outside FamilyPromotions so a /reload does not wrap the wrapper
		FamilyUpstreamSpellNewIndex = FamilyUpstreamSpellNewIndex or meta.__newindex
		P.upstreamSpellNewIndex = FamilyUpstreamSpellNewIndex
		function P.spellNewIndex(self, key, value)
			if key == "onCastSpell" and type(value) == "function" then
				value = P.wrapCast(self, value)
			end
			return P.upstreamSpellNewIndex(self, key, value)
		end
		meta.__newindex = P.spellNewIndex
	end
end

-- Readable numbers: 1234567 -> "1,234,567"; 7.5 -> "7.5"; 8.0 -> "8"
function P.formatGold(value)
	local text = tostring(math.floor(value))
	while true do
		local replaced, n = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		text = replaced
		if n == 0 then
			return text
		end
	end
end

function P.formatPercent(value)
	local rounded = math.floor(value * 10 + 0.5) / 10
	if rounded == math.floor(rounded) then
		return string.format("%d", rounded)
	end
	return string.format("%.1f", rounded)
end
