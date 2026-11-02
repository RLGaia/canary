-- Gaia Family server: The Ape City Quest, mission 9 canopic jars (2026-11-02,
-- review asked by Rodrigo). Ours, not upstream.
--
-- On deeper Banuta's first floor four canopic jars (uids 40092-40095) must be
-- broken to open the teleport to the lever floor (uid 9258). TibiaWiki BR and
-- EN: break them with a melee weapon (or a crowbar), the snake destroyer
-- does not work; while all four are broken the teleport takes everyone, so
-- one player can break them for the group; they come back after 5 minutes.
--
-- Upstream got this backwards: weapons and crowbars do nothing on the four
-- jars (the destroy code skips items with a unique id), only the snake
-- destroyer breaks them, and the teleport checks per-player storages, so the
-- second player was stopped while the jars were still broken and could not
-- break them himself until they came back.
--
-- Now a weapon or crowbar breaks a jar (same hit chance as any destroyable
-- object), the jar turns into its remains (back after 300 s, items.xml) and
-- the teleport is open while all four squares hold remains.
-- Hooks (FAMILY edits): onDestroyItem in scripts/lib/register_actions.lua,
-- the teleport in scripts/quests/the_ape_city/movements_mission9_the_deepest_catacomb_teleport.lua.
--
-- Switch: Family.apeCityJars (false = upstream).

Family = Family or {}
Family.apeCityJars = true

FamilyApeJars = {
	jar = 4995,
	remains = 4996,
	positions = {
		[40092] = Position(32792, 32527, 10),
		[40093] = Position(32823, 32525, 10),
		[40094] = Position(32876, 32584, 10),
		[40095] = Position(32744, 32586, 10),
	},
}

-- Called by onDestroyItem before its unique-id check. nil = not ours.
function FamilyApeJars.onDestroy(player, item, target, toPosition)
	if not Family.apeCityJars or not target or target.itemid ~= FamilyApeJars.jar then
		return nil
	end
	if not FamilyApeJars.positions[target:getUniqueId()] then
		return nil
	end

	local attack = ItemType(item.itemid):getAttack()
	if math.random(1, 80) <= (attack and attack > 10 and attack or 10) then
		target:transform(FamilyApeJars.remains)
		target:decay()
		toPosition:sendMagicEffect(CONST_ME_BLOCKHIT)
	else
		toPosition:sendMagicEffect(CONST_ME_POFF)
	end
	return true
end

function FamilyApeJars.allBroken()
	for _, position in pairs(FamilyApeJars.positions) do
		local tile = Tile(position)
		if not tile or not tile:getItemById(FamilyApeJars.remains) then
			return false
		end
	end
	return true
end
