-- Gaia Family server (ours, not upstream): a Prey action (0xEB) was sent; a
-- list reroll gets the daily free reroll rule of
-- data/scripts/family/prey_reroll.lua. The packet is read and put back: the
-- server still handles it as usual.

function onRecvbyte(player, msg, byte)
	if Family and Family.preyRerollAction then
		Family.preyRerollAction(player, msg, "prey")
	end
end
