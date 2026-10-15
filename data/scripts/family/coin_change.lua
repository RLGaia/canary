-- Gaia Family server: automatic coin change (2026-10-14). Ours, not upstream.
--
-- Looted gold goes to the backpack again (autoBank = false in
-- family/config.family.lua), and coins change up by themselves: as soon as a
-- character carries 100 gold coins they become 1 platinum coin, and 100
-- platinum coins become 1 crystal coin. Works for every way coins arrive:
-- auto-loot, looting by hand, NPC sales, change from purchases.
--
-- Checked on every player "think" (about once a second): two item counts per
-- coin type, so it costs nothing noticeable. Coins in the depot or a house are
-- not touched, only what the character carries.
--
-- Switch: Family.autoCoinChange (false = coins stay as they are; using a full
-- stack still changes it by hand, as upstream).

Family = Family or {}
Family.autoCoinChange = true

local CHANGES = {
	{ from = ITEM_GOLD_COIN, to = ITEM_PLATINUM_COIN },
	{ from = ITEM_PLATINUM_COIN, to = ITEM_CRYSTAL_COIN },
}

-- Returns how many coins of the next kind were made.
local function changeUp(player, change)
	local count = player:getItemCount(change.from)
	if count < 100 then
		return 0
	end
	local made = math.floor(count / 100)
	-- New coins first, so a full backpack never loses anything.
	if player:addItem(change.to, made, false) then
		if player:removeItem(change.from, made * 100) then
			return made
		end
		player:removeItem(change.to, made) -- could not take the old coins: undo
		return 0
	end
	-- No room for the new coins yet. Removing the old ones first frees space;
	-- if the new coins still don't fit, the old ones go back (they fit where
	-- they were; as a last resort they drop at the character's feet, never
	-- vanish).
	if not player:removeItem(change.from, made * 100) then
		return 0
	end
	if player:addItem(change.to, made, false) then
		return made
	end
	if not player:addItem(change.from, made * 100, false) then
		player:addItem(change.from, made * 100, true)
	end
	return 0
end

function Family.changeCoins(player)
	local changed = false
	for _, change in ipairs(CHANGES) do
		if changeUp(player, change) > 0 then
			changed = true
		end
	end
	return changed
end

local callback = EventCallback("FamilyCoinChange")

function callback.playerOnThink(player, interval)
	if Family.autoCoinChange then
		Family.changeCoins(player)
	end
end

callback:register()

local report = GlobalEvent("FamilyCoinChangeReport")

function report.onStartup()
	logger.info("[Family] coins: autoBank={}, automatic change 100 gold -> 1 platinum -> 100 platinum -> 1 crystal={}", tostring(configManager.getBoolean(configKeys.AUTOBANK)), tostring(Family.autoCoinChange))
	return true
end

report:register()
