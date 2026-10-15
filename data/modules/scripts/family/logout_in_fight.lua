-- Gaia Family server (ours, not upstream): logout during a fight.
--
-- The logout request (packet 0x14) passes through here before the server
-- handles it. Upstream refuses it while the battle icon is shown ("You may not
-- logout during or immediately after a fight!"); here the in-fight state is
-- cleared first, so the logout goes through at once. Tiles where logging out
-- is never allowed (some quest and arena rooms) still refuse it.
--
-- Switch: Family.logoutDuringFight (data/scripts/family/logout_in_fight.lua).

function onRecvbyte(player, msg, byte)
	if not Family or not Family.logoutDuringFight then
		return
	end
	local tile = Tile(player:getPosition())
	if tile and tile:hasFlag(TILESTATE_NOLOGOUT) then
		return
	end
	player:removeCondition(CONDITION_INFIGHT, CONDITIONID_DEFAULT)
end
