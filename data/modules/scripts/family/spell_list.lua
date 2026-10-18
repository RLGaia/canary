-- Gaia Family server (ours, not upstream): after the client saves the wheel of
-- destiny (0x62) or changes a gem (0xE7) the server sends its own spell list,
-- which marks unlearned spells as known; send the right one half a second
-- later (data/scripts/family/spell_list.lua). Nothing is read from the packet:
-- the server still handles it as usual.

function onRecvbyte(player, msg, byte)
	if Family and Family.sendSpellListLater then
		Family.sendSpellListLater(player, 500)
	end
end
