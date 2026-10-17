-- Gaia Family server (ours, not upstream): Cyclopedia map actions.
--
-- Packet 0xDB, which Canary does not handle: the client sends it from
-- Cyclopedia > Map. Byte action 0 = "Start Discovering" + u16 subarea id;
-- action 1 = donate + u16 area id + u32 gold. Everything else is in
-- data/scripts/family/map_discovery.lua (FamilyDiscovery).

function onRecvbyte(player, msg, byte)
	if not FamilyDiscovery or not FamilyDiscovery.enabled then
		return
	end
	local action = msg:getByte()
	local id = msg:getU16()
	local amount = 0
	if action == 1 then
		amount = msg:getU32()
	end
	FamilyDiscovery.onClientAction(player, action, id, amount)
end
