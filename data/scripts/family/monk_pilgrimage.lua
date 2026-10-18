-- Gaia Family server: what The Way of the Monk was missing (2026-10-17).
-- Ours, not upstream. The NPCs, the shrine floors and the start and end of the
-- pilgrimage are fixed in the quest files themselves (see FAMILY.md).
--
-- 1. The crystal sphere of the Adventurers' Guild. Upstream the Blue Valley
--    teleport script listens at the guild (next to the daily reward shrine), but
--    our map has no sphere there, so there was nothing to use. It is put there at
--    startup (the same sphere as the one east of Thais). Using it brings you to
--    the Blue Valley; the spheres there bring you back to where you came from.
--
-- 2. Melee protection of the shrines. In Tibia every Blue Valley shrine a monk
--    has embraced takes 2% off the damage of melee attacks against him (20% with
--    all ten). Upstream only gives the attack bonus of the shrines. Here a monk's
--    damage from melee attacks (monsters' and players' basic attacks, not spells
--    or other attacks) is lowered by 2% for each shrine visited.
--
-- Switches: Family.monkGuildSphere, Family.monkShrineMeleeProtection.

Family = Family or {}
Family.monkGuildSphere = true
Family.monkShrineMeleeProtection = true

local GUILD_SPHERE_ID = 50227 -- the Thais sphere (32456,32290,7)
local GUILD_SPHERE_POS = Position(32203, 32303, 6)
local PROTECTION_PER_SHRINE = 2 -- percent

-- Shrines a character has embraced (ShrinesCount is the next one, starting at 1).
function Family.monkShrinesVisited(player)
	local count = player:getStorageValue(Storage.Quest.U14_15.TheWayOfTheMonk.ShrinesCount)
	if type(count) ~= "number" or count < 1 then
		return 0
	end
	return math.min(count - 1, #TheWayOfTheMonkShrines)
end

-- Percent taken off melee damage for this character (0 for other vocations).
function Family.monkMeleeProtection(player)
	if not Family.monkShrineMeleeProtection or player:getVocation():getBaseId() ~= VOCATION.BASE_ID.MONK then
		return 0
	end
	return Family.monkShrinesVisited(player) * PROTECTION_PER_SHRINE
end

local guard = CreatureEvent("FamilyMonkShrineGuard")

function guard.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if origin ~= ORIGIN_MELEE or not attacker or primaryType == COMBAT_HEALING then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	local player = creature:getPlayer()
	if not player then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	local percent = Family.monkMeleeProtection(player)
	if percent <= 0 then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	local keep = (100 - percent) / 100
	primaryDamage = math.floor(math.abs(primaryDamage) * keep + 0.5)
	secondaryDamage = math.floor(math.abs(secondaryDamage) * keep + 0.5)
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

guard:register()

local login = CreatureEvent("FamilyMonkShrineGuardLogin")

function login.onLogin(player)
	-- Everyone (cheap): a character becomes a monk in Dawnport without logging out.
	player:registerEvent("FamilyMonkShrineGuard")
	return true
end

login:register()

local startup = GlobalEvent("FamilyMonkPilgrimage")

function startup.onStartup()
	local placed = "kept"
	if Family.monkGuildSphere then
		local tile = Tile(GUILD_SPHERE_POS)
		if tile and not tile:getItemById(GUILD_SPHERE_ID) then
			placed = Game.createItem(GUILD_SPHERE_ID, 1, GUILD_SPHERE_POS) and "placed" or "FAILED"
		end
	end
	logger.info("[Family] monk: Adventurers' Guild sphere to the Blue Valley {}, shrine melee protection {}", placed, tostring(Family.monkShrineMeleeProtection))
	return true
end

startup:register()
