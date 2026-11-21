-- Gaia Family server: Vampire Hunter Quest review, world side (2026-11-20). Ours, not upstream.
-- Rules and sources: lib/others/family_vampire_hunter.lua (FamilyVampire).
--
-- * Storkus' three bookcases get their seven books at startup.
-- * The Pale Count's two fights (TibiaWiki EN): his raid (scripts/raids/bosses/the_pale_count.lua)
--   puts him in the hall on floor 14 with this event; at yellow health he says his line and comes
--   back with full health in his sanctuary below. He cannot die in the hall, so only the second fight
--   gives loot (BR: only taking part in the last phase counts). Upstream's version of this
--   (creaturescripts/monster/the_pale_count_kill.lua) created a monster "the pale count2" that does
--   not exist and was never attached to him.

local V = FamilyVampire

local books = GlobalEvent("FamilyVampireBooks")

function books.onStartup()
	if not Family.vampireHunter then
		return true
	end
	loadLuaMapBookDocument(V.books)
	return true
end

books:register()

local moving = {}

-- Also called by the self-test.
function V.paleCountToSanctuary(id)
	moving[id] = nil
	local pale = Monster(id)
	if not pale then
		return nil
	end
	local p = V.paleCount
	pale:say(p.line, TALKTYPE_MONSTER_SAY)
	pale:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	pale:remove()
	local again = Game.createMonster("The Pale Count", p.sanctuary, true, true)
	if not again then
		logger.error("[Family] The Pale Count could not come back in his sanctuary")
		return nil
	end
	again:setRewardBoss()
	again:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
	-- the rare-raid rotation waits while he lives (data/scripts/family/rare_creatures.lua)
	local raid = Raid and Raid.registry and Raid.registry["drefia.the-pale-count"]
	if raid then
		raid.familySpawned = raid.familySpawned or {}
		raid.familySpawned[again:getId()] = true
	end
	return again
end

local phase = CreatureEvent(V.paleCount.event)

-- Damage reaches this event as negative numbers (game.cpp, combatChangeHealth); the values given
-- back are made negative again by the server.
local function hurts(value, type)
	return type ~= COMBAT_HEALING and math.abs(value) or 0
end

function phase.onHealthChange(creature, attacker, primaryDamage, primaryType, secondaryDamage, secondaryType, origin)
	if not Family.vampireHunter or not creature:isMonster() then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	local health = creature:getHealth()
	local total = hurts(primaryDamage, primaryType) + hurts(secondaryDamage, secondaryType)
	if total <= 0 then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	local id = creature:getId()
	if moving[id] then
		return 0, primaryType, 0, secondaryType -- already on his way down
	end
	if (health - total) * 100 > creature:getMaxHealth() * V.paleCount.yellowPercent then
		return primaryDamage, primaryType, secondaryDamage, secondaryType
	end
	-- Yellow: never below 1 health here, then down to the sanctuary.
	if total >= health then
		local keep = health - 1
		local p = math.min(hurts(primaryDamage, primaryType), keep)
		local s = math.min(hurts(secondaryDamage, secondaryType), keep - p)
		if primaryType ~= COMBAT_HEALING then
			primaryDamage = p
		end
		if secondaryType ~= COMBAT_HEALING then
			secondaryDamage = s
		end
	end
	moving[id] = true
	addEvent(V.paleCountToSanctuary, 100, id)
	return primaryDamage, primaryType, secondaryDamage, secondaryType
end

phase:register()
