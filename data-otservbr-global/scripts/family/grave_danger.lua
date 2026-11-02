-- Gaia Family server: Grave Danger fixes (2026-11-02). Ours, not upstream.
--
-- Checked against TibiaWiki BR (Grave Danger Quest, page saved by Rodrigo) and TibiaWiki EN
-- (Grave Danger Quest spoiler and Jack Springer's transcripts):
--   * The twelve grave missions read 1 = "Find the grave ..." and 2 = "... visited", and the
--     first mission counts (sum of the twelve) - 12. Upstream started them at 0 and set 1 on a
--     visit, so visited graves showed "Find ..." and the count went negative. Now Jack starts
--     them at 1 (keeping graves visited and Scarlett killed before the talk), a visit sets 2,
--     and Jack's report counts the graves at 2. Characters from before are converted once at
--     login (0 -> 1, 1 -> 2).
--   * The four graves the legion already emptied (Femor Hills, Vengoth, Orclands entrance,
--     Folda) count when you walk up to them (BR: "basta entrar na cripta"); holy water still
--     works there too (EN).
--   * Holy water works on either half of a grave (actions_grave_sanctify.lua, FAMILY).
--   * King Zelos: the sealed door before his vortex (32173,31922,8) needed a storage nothing
--     set; Jack sets it when he sends you to the isle of the kings, and older characters get it
--     at login.
--   * The Custodian's passages (smoke and fire walls) go to those who dealt at least
--     Family.custodianShare of his damage (BR: "causando bastante dano"; the share is ours).
--
-- Switch: Family.graveDangerFixes (false = the visit zones and login conversion are off).

Family = Family or {}
Family.graveDangerFixes = true
Family.custodianShare = 0.1

FamilyGrave = FamilyGrave or {}
local G = FamilyGrave
local GD = Storage.Quest.U12_20.GraveDanger

G.graves = {
	GD.Graves.Edron,
	GD.Graves.DarkCathedral,
	GD.Graves.Ghostlands,
	GD.Graves.Cormaya,
	GD.Graves.FemorHills,
	GD.Graves.Ankrahmun,
	GD.Graves.Kilmaresh,
	GD.Graves.Vengoth,
	GD.Graves.Darashia,
	GD.Graves.Thais,
	GD.Graves.Orclands,
	GD.Graves.IceIslands,
}

local DEFILED = "This grave is already defiled and the lich knight has left! There is nothing you can do here." -- upstream line

G.emptied = {
	{ name = "femor", stor = GD.Graves.FemorHills, pos = Position(32542, 31846, 6) },
	{ name = "vengoth", stor = GD.Graves.Vengoth, pos = Position(32959, 31534, 7) },
	{ name = "orclands", stor = GD.Graves.Orclands, pos = Position(32776, 31817, 8) },
	{ name = "folda", stor = GD.Graves.IceIslands, pos = Position(32012, 31558, 7) },
}
G.visitRange = 3

function G.start(player)
	for _, stor in ipairs(G.graves) do
		if player:getStorageValue(stor) < 1 then
			player:setStorageValue(stor, 1)
		end
	end
	if player:getStorageValue(GD.Graves.Progress) < 0 then
		player:setStorageValue(GD.Graves.Progress, 0)
	end
end

function G.count(player)
	local n = 0
	for _, stor in ipairs(G.graves) do
		if player:getStorageValue(stor) >= 2 then
			n = n + 1
		end
	end
	return n
end

function G.visit(player, grave)
	if player:getStorageValue(GD.Questline) < 1 or player:getStorageValue(grave.stor) >= 2 then
		return false
	end
	player:setStorageValue(grave.stor, 2)
	player:setStorageValue(GD.Graves.Progress, math.max(0, player:getStorageValue(GD.Graves.Progress)) + 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, DEFILED)
	grave.pos:sendMagicEffect(CONST_ME_MORTAREA)
	return true
end

for _, grave in ipairs(G.emptied) do
	local r = G.visitRange
	local zone = Zone("family.grave-danger." .. grave.name)
	zone:addArea(Position(grave.pos.x - r, grave.pos.y - r, grave.pos.z), Position(grave.pos.x + r, grave.pos.y + r + 1, grave.pos.z))
	local event = ZoneEvent(zone)
	function event.afterEnter(_zone, creature)
		local player = creature:getPlayer()
		if player and Family.graveDangerFixes then
			G.visit(player, grave)
		end
	end
	event:register()
end

-- once per character: the old values (0 = not visited, 1 = visited) become 1 and 2
function G.convert(player)
	local kv = player:kv():scoped("family-grave-danger")
	if kv:get("graves-v2") then
		return false
	end
	for _, stor in ipairs(G.graves) do
		local v = player:getStorageValue(stor)
		if v == 1 then
			player:setStorageValue(stor, 2)
		elseif v == 0 then
			player:setStorageValue(stor, 1)
		end
	end
	kv:set("graves-v2", 1)
	return true
end

function G.repair(player)
	if player:getStorageValue(GD.Stage) >= 1 and player:getStorageValue(GD.Bosses.KingZelos.Room) < 1 then
		player:setStorageValue(GD.Bosses.KingZelos.Room, 1)
	end
end

local login = CreatureEvent("FamilyGraveDangerLogin")
function login.onLogin(player)
	if Family.graveDangerFixes then
		G.convert(player)
		G.repair(player)
	end
	return true
end
login:register()
