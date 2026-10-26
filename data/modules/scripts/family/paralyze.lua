-- Gaia Family server (ours, not upstream): paralysis only slows walking.
--
-- Runs just before the server handles a spoken message (byte 150) or the use
-- of an item (130 use, 131 use with, 132 use on a creature). When a paralyzed
-- player says something or uses a rune or potion, the paralysis is taken off
-- for that moment, so the C++ walk exhaust does not swallow the spell or refuse
-- the rune or potion; it is put back right away (see
-- data/scripts/lib/family_paralyze.lua). The packet is read and put back: the
-- server still handles it as usual.
--
-- Switch: Family.paralyzeOnlySlows.

local SAY_TYPES = {
	[TALKTYPE_SAY] = true,
	[TALKTYPE_WHISPER] = true,
	[TALKTYPE_YELL] = true,
}

local function isRuneOrPotion(itemId)
	local itemType = ItemType(itemId)
	if not itemType or itemType:getId() == 0 then
		return false
	end
	return itemType:isRune() or itemType:getType() == ITEM_TYPE_POTION
end

function onRecvbyte(player, msg, byte)
	if not FamilyParalyze or not Family or not Family.paralyzeOnlySlows then
		return
	end
	if not player:hasCondition(CONDITION_PARALYZE) then
		return
	end

	-- Put the read position back exactly where it was (reads past the end of a
	-- short packet do not move it).
	local unread = msg:getUnreadBytes()
	if byte == 150 then
		local talkType = msg:getByte()
		msg:skipBytes(-(unread - msg:getUnreadBytes()))
		if not SAY_TYPES[talkType] then
			return
		end
	else
		-- position (u16 x, u16 y, u8 z), then the item id
		msg:getU16()
		msg:getU16()
		msg:getByte()
		local itemId = msg:getU16()
		msg:skipBytes(-(unread - msg:getUnreadBytes()))
		if not isRuneOrPotion(itemId) then
			return
		end
	end

	FamilyParalyze.lift(player)
end
