-- Gaia Family server: loot brought up to date with TibiaWiki (from 2026-10-18).
-- Ours, not upstream.
--
-- Canary's creature files miss some of the items Tibia's creatures drop. The
-- tool tools/family/loot_audit (README there) reads each creature's loot on
-- TibiaWiki (BR) and writes the items our files do not have into
-- loot_updates_data.lua; they are added here at startup, without changing the
-- creature files. Chances follow TibiaWiki's rarity: always 100%, common 33%,
-- uncommon 10%, semi-rare 2.8%, rare 0.9%, very rare 0.2% (before the loot
-- rate of config.family.lua). Items our files have and TibiaWiki does not are
-- kept (tools/family/loot_audit/report.md lists them). Event and raid drops
-- are left out.
--
-- Switch: Family.lootUpdates (false = the creature files only).

Family = Family or {}
Family.lootUpdates = true

local startup = GlobalEvent("FamilyLootUpdates")

function startup.onStartup()
	if not Family.lootUpdates then
		return true
	end
	local path = CORE_DIRECTORY .. "/scripts/family/loot_updates_data.lua"
	local ok, data = pcall(dofile, path)
	if not ok or type(data) ~= "table" then
		logger.error("[Family] loot updates: could not read {}: {}", path, tostring(data))
		return true
	end
	local creatures, items, missing = 0, 0, {}
	for name, loot in pairs(data) do
		local mType = Game.getMonsterTypeByName(name)
		if mType then
			local have = {}
			for _, entry in ipairs(mType:getLoot() or {}) do
				have[entry.itemId] = true
			end
			local add = {}
			for _, entry in ipairs(loot) do
				local id = entry.id or ItemType(entry.name):getId()
				if id and id > 0 and not have[id] then
					add[#add + 1] = entry
				end
			end
			if #add > 0 then
				mType:createLoot(add)
				creatures = creatures + 1
				items = items + #add
			end
		else
			missing[#missing + 1] = name
		end
	end
	logger.info("[Family] loot updates: {} items added to {} creatures{}", items, creatures, #missing > 0 and (", NOT FOUND: " .. table.concat(missing, ", ")) or "")
	return true
end

startup:register()
