-- Gaia Family server: temple NPCs heal fully (2026-10-16). Ours, not upstream.
--
-- Upstream the temple NPCs who offer to {heal} (Isimov, Quentin, Pydar and 25
-- others) only help characters below 40 hit points, and only up to 40; above
-- that they answer "You aren't looking that bad". Here, saying "heal" to any of
-- them restores full health and mana and cures poison, burning, electrification,
-- bleeding and the other damage conditions, whenever something is missing.
-- With full health and mana and no condition the NPC answers as upstream.
--
-- No NPC file is changed: this recognises the temple healers by their upstream
-- "You aren't looking that bad" answer to "heal".
--
-- Switches: Family.templeFullHeal (false = upstream), Family.templeRestoreMana.

Family = Family or {}
Family.templeFullHeal = true
Family.templeRestoreMana = true

local REFUSAL = "aren't looking that bad"

local BAD_CONDITIONS = {
	CONDITION_POISON,
	CONDITION_FIRE,
	CONDITION_ENERGY,
	CONDITION_BLEEDING,
	CONDITION_FREEZING,
	CONDITION_DAZZLED,
	CONDITION_CURSED,
	CONDITION_DROWN,
}

-- Roots of the NPCs that heal (cached: true / false per keyword tree).
local healerRoots = setmetatable({}, { __mode = "k" })

local function isHealerRoot(root)
	if not root then
		return false
	end
	local known = healerRoots[root]
	if known ~= nil then
		return known
	end
	local found = false
	for _, child in pairs(root.children or {}) do
		local text = child.parameters and child.parameters.text
		if type(text) == "string" and text:find(REFUSAL, 1, true) then
			found = true
			break
		end
	end
	healerRoots[root] = found
	return found
end

local function needsHealing(player)
	if player:getHealth() < player:getMaxHealth() then
		return true
	end
	if Family.templeRestoreMana and player:getMana() < player:getMaxMana() then
		return true
	end
	for _, condition in ipairs(BAD_CONDITIONS) do
		if player:getCondition(condition) then
			return true
		end
	end
	return false
end

-- Heals the player fully. Returns true when something was restored.
function Family.templeHeal(player)
	if not needsHealing(player) then
		return false
	end
	for _, condition in ipairs(BAD_CONDITIONS) do
		player:removeCondition(condition)
	end
	player:addHealth(player:getMaxHealth() - player:getHealth())
	if Family.templeRestoreMana then
		player:addMana(player:getMaxMana() - player:getMana())
	end
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end

-- The NPC library is loaded after these scripts, so the hook is installed at
-- startup (before anyone can log in).
local function installHook()
	if not KeywordNode or KeywordNode.familyTempleHealing then
		return KeywordNode ~= nil
	end
	local originalProcessMessage = KeywordNode.processMessage
	function KeywordNode:processMessage(npc, creature, message)
		if Family.templeFullHeal and self.keywords and self.keywords[1] == "heal" and #self.keywords == 1 and self.parameters and self.parameters.npcHandler and isHealerRoot(self.parent) then
			local player = Player(creature)
			if player and Family.templeHeal(player) then
				self.parameters.npcHandler:say("You are hurt, my child. I will heal your wounds.", npc, creature)
				return true -- handled; the node's own action (cure, effect) finds nothing left to do
			end
		end
		return originalProcessMessage(self, npc, creature, message)
	end
	KeywordNode.familyTempleHealing = true
	return true
end

local report = GlobalEvent("FamilyTempleHealingReport")

function report.onStartup()
	if not installHook() then
		logger.warn("[Family] temple healing: NPC library not found, upstream healing applies")
		return true
	end
	logger.info("[Family] temple healing: full health{} for anyone hurt: {}", Family.templeRestoreMana and " and mana" or "", tostring(Family.templeFullHeal))
	return true
end

report:register()
