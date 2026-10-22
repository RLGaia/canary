-- Gaia Family server (ours, not upstream): a Hunting Task action (0xBA) was
-- sent; claimed points are multiplied a moment later by
-- data/scripts/family/hunting_task_points.lua. Nothing is read from the
-- packet: the server still handles it as usual.

function onRecvbyte(player, msg, byte)
	if Family and Family.boostHuntingTaskClaim then
		Family.boostHuntingTaskClaim(player)
	end
end
