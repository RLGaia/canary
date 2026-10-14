-- Gaia Family server (ours, not upstream): Cyclopedia house packets (0xAD)
-- pass through here before the server handles them. A bid on a free house
-- buys it at once; see data/scripts/family/house_instant_buy.lua.

function onRecvbyte(player, msg, byte)
	if Family and Family.cyclopediaInstantBuy then
		Family.cyclopediaInstantBuy(player, msg)
	end
end
