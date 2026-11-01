-- Gaia Family server (ours, not upstream): a Hunting Task action (0xBA) was
-- sent; claimed points are multiplied a moment later by
-- data/scripts/family/hunting_task_points.lua, which also makes the slot
-- selectable again; a list reroll gets the daily free reroll rule of
-- data/scripts/family/prey_reroll.lua. The packet is read and put back: the server still
-- handles it as usual.

function onRecvbyte(player, msg, byte)
	if Family and Family.boostHuntingTaskClaim then
		Family.boostHuntingTaskClaim(player, msg)
	end
	if Family and Family.preyRerollAction then
		Family.preyRerollAction(player, msg, "task") -- daily free list reroll (prey_reroll.lua)
	end
end
