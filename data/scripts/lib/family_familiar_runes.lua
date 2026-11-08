-- Gaia Family server: area runes on your own familiar's square (2026-11-08).
-- Ours, not upstream.
--
-- Aiming an area rune (great fireball, avalanche, thunderstorm, ...) with the
-- crosshair at the square where your own familiar stands did nothing. When a
-- creature is on the square the client sends "use on creature", and Canary
-- v3.6.1 refuses every rune and potion used on your own familiar
-- (Game::playerUseWithCreature, "You cannot use this object."; meant to stop
-- healing it). That check is in the pinned binary and only looks at the
-- familiar flag of the familiar's monster type, so:
--
-- 1. The use-on-creature module (byte 132,
--    data/modules/scripts/family/paralyze.lua) calls
--    FamilyFamiliarRunes.beforeUseOnCreature just before the server handles
--    the packet. For an aggressive rune that does not need a target, aimed at
--    the player's own familiar, the familiar flag of that monster type is
--    switched off for the moment.
-- 2. It is switched back on as soon as the rune's area is checked
--    (creatureOnAreaCombat in data/scripts/family/familiar_area_runes.lua),
--    and in any case after 1.5 s (a rune used during the 1-second action delay
--    after another rune or potion is retried by the server after that delay).
--
-- Unchanged: potions and target runes (sudden death, ultimate healing, ...)
-- used on your own familiar are still refused, and the area never hurts the
-- familiar (players' summons cannot be attacked on a no-PvP world).
--
-- Switch: Family.areaRunesOnFamiliar (false = upstream rule).

Family = Family or {}
Family.areaRunesOnFamiliar = true

FamilyFamiliarRunes = FamilyFamiliarRunes or {}
FamilyFamiliarRunes.restoreDelay = 1500
-- monster type name (lower case) -> { mType = MonsterType, players = { [playerId] = true }, event = id }
FamilyFamiliarRunes.pending = FamilyFamiliarRunes.pending or {}
-- player id -> monster type name (lower case)
FamilyFamiliarRunes.byPlayer = FamilyFamiliarRunes.byPlayer or {}

-- An aggressive rune that is thrown at a square (not at a creature).
function FamilyFamiliarRunes.isAreaRune(itemId)
	local itemType = ItemType(itemId)
	if not itemType or itemType:getId() == 0 or not itemType:isRune() then
		return false
	end
	local spell = Spell(itemId)
	return spell ~= nil and not spell:needTarget() and spell:isAggressive()
end

-- Switches the familiar flag of that type back on.
function FamilyFamiliarRunes.restore(key)
	local entry = FamilyFamiliarRunes.pending[key]
	if not entry then
		return
	end
	FamilyFamiliarRunes.pending[key] = nil
	if entry.event then
		stopEvent(entry.event)
	end
	for playerId in pairs(entry.players) do
		if FamilyFamiliarRunes.byPlayer[playerId] == key then
			FamilyFamiliarRunes.byPlayer[playerId] = nil
		end
	end
	entry.mType:familiar(true)
end

local function restoreLater(key)
	local entry = FamilyFamiliarRunes.pending[key]
	if entry then
		entry.event = nil
	end
	FamilyFamiliarRunes.restore(key)
end

-- The rune of this player has reached its area check: the flag can go back
-- (unless another player is still waiting on the same familiar type).
function FamilyFamiliarRunes.restoreForPlayer(playerId)
	local key = FamilyFamiliarRunes.byPlayer[playerId]
	if not key then
		return
	end
	FamilyFamiliarRunes.byPlayer[playerId] = nil
	local entry = FamilyFamiliarRunes.pending[key]
	if not entry then
		return
	end
	entry.players[playerId] = nil
	if next(entry.players) == nil then
		FamilyFamiliarRunes.restore(key)
	end
end

-- Byte 132 (use an item on a creature): position (u16 x, u16 y, u8 z), item
-- id (u16), stack position (u8), creature id (u32). The read position is put
-- back, so the server still handles the packet as usual. Returns true when
-- the familiar flag was switched off.
function FamilyFamiliarRunes.beforeUseOnCreature(player, msg)
	if not Family.areaRunesOnFamiliar then
		return false
	end

	local unread = msg:getUnreadBytes()
	if unread < 12 then
		return false
	end
	msg:getU16()
	msg:getU16()
	msg:getByte()
	local itemId = msg:getU16()
	msg:getByte()
	local creatureId = msg:getU32()
	msg:skipBytes(-(unread - msg:getUnreadBytes()))

	local familiar = Monster(creatureId)
	if not familiar then
		return false
	end
	local master = familiar:getMaster()
	if not master or master:getId() ~= player:getId() then
		return false
	end
	local mType = familiar:getType()
	if not mType then
		return false
	end
	local key = mType:name():lower()
	local entry = FamilyFamiliarRunes.pending[key]
	if not mType:familiar() and not entry then
		return false
	end
	if not FamilyFamiliarRunes.isAreaRune(itemId) then
		return false
	end

	if not entry then
		entry = { mType = mType, players = {} }
		FamilyFamiliarRunes.pending[key] = entry
	end
	if entry.event then
		stopEvent(entry.event)
	end
	entry.players[player:getId()] = true
	FamilyFamiliarRunes.byPlayer[player:getId()] = key
	mType:familiar(false)
	entry.event = addEvent(restoreLater, FamilyFamiliarRunes.restoreDelay, key)
	return true
end
