-- Gaia Family server: monster corpses can be moved right away (2026-10-17).
-- Ours, not upstream.
--
-- As in real Tibia, a monster's corpse is locked to the floor for its first
-- 10 seconds: that first look of the corpse ("dead rotworm", "slain demon"...)
-- is marked as unmovable in the client files, so the client does not even let
-- you drag it. After 10 seconds it turns into the next, movable look.
--
-- Here that first step happens at once: right after the loot is put in the
-- corpse, it turns into its movable look. It is the same corpse: the loot
-- stays inside, the "Loot of ..." message and auto loot work as before, and
-- it still rots away on the usual schedule (10 seconds shorter). The loot
-- protection is kept: for the first 10 seconds only the killer (and his party)
-- can open it, as upstream.
--
-- Five small corpses (rotworm, spider, dog, rabbit, bear) are not marked as
-- corpses any more in their movable look, so, as upstream after 10 seconds,
-- "loot all" on a tile and nearby quick loot skip them; opening them, auto
-- loot and quick looting that one corpse work.
--
-- Not changed: boss reward corpses (the reward chest system), corpses used by
-- quests (they carry an action or unique id), player corpses.
--
-- Switch: Family.movableFreshCorpses (false = upstream 10-second lock).

Family = Family or {}
Family.movableFreshCorpses = true

local PROTECTION_MS = 10 * 1000 -- upstream loot protection time
local REWARD_CORPSE_OWNER = 2 ^ 31 - 1

-- Movable look a fresh corpse of this item id turns into, or nil (cached).
local nextLook = {}

function Family.movableCorpseId(itemId)
	local known = nextLook[itemId]
	if known ~= nil then
		return known or nil
	end
	-- The next look is what the corpse becomes after 10 seconds anyway (a
	-- smaller one keeps all the loot, as upstream).
	local result = false
	local itemType = ItemType(itemId)
	if itemType and itemType:getId() ~= 0 and itemType:isContainer() and not itemType:isMovable() then
		local decayId = itemType:getDecayId()
		local nextType = decayId and decayId > 0 and ItemType(decayId)
		if nextType and nextType:getId() ~= 0 and nextType:isContainer() and nextType:isMovable() then
			result = decayId
		end
	end
	nextLook[itemId] = result
	return result or nil
end

-- Turns a fresh corpse into its movable look. Returns true when it did.
function Family.unlockCorpse(corpse)
	if not Family.movableFreshCorpses or not corpse or not corpse:getParent() then
		return false
	end
	if corpse:hasAttribute(ITEM_ATTRIBUTE_ACTIONID) or corpse:hasAttribute(ITEM_ATTRIBUTE_UNIQUEID) then
		return false
	end
	local owner = corpse.getCorpseOwner and corpse:getCorpseOwner() or 0
	if owner == REWARD_CORPSE_OWNER then
		return false
	end
	local newId = Family.movableCorpseId(corpse:getId())
	if not newId then
		return false
	end
	if not corpse:transform(newId) or corpse:getId() ~= newId then
		return false
	end
	if owner > 0 then
		-- Changing the look clears the owner; keep the usual 10 seconds.
		corpse:setAttribute("corpseowner", owner)
		addEvent(function()
			if corpse:getAttribute("corpseowner") == owner then
				corpse:removeAttribute("corpseowner")
			end
		end, PROTECTION_MS)
	end
	return true
end

local callback = EventCallback("FamilyMovableCorpses")

function callback.monsterPostDropLoot(monster, corpse)
	if not Family.movableFreshCorpses or not corpse then
		return
	end
	-- Right after the death is fully handled (loot message, auto loot,
	-- quest death scripts), not in the middle of it.
	addEvent(function()
		Family.unlockCorpse(corpse)
	end, 100)
end

callback:register()

local report = GlobalEvent("FamilyMovableCorpsesReport")

function report.onStartup()
	logger.info("[Family] corpses: monster corpses movable right away: {}", tostring(Family.movableFreshCorpses))
	return true
end

report:register()
