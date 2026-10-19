-- Gaia Family server: houses for sale are furnished (2026-10-19). Ours, not
-- upstream. Asked by Rodrigo: houses should look lived-in like on the real
-- worlds, stay free to buy, and be empty the moment they are bought.
--
-- Every house without an owner gets furniture in its town's style at every
-- server start (Thais/Carlin/Edron/Venore classic, Ab'Dendriel elven,
-- Kazordoon/Farmine dwarven, Svargrond nordic, Ankrahmun/Darashia/Issavi
-- desert, Port Hope/Liberty Bay tropical, Yalahar alchemistic). About a third
-- of them, mostly the big ones, are "rich": luxury furniture, trophies, statues
-- and valuable equipment on tables and floors. Where each piece goes is
-- planned by tools/family/house_decor/plan.py (house_decor_data.lua): pieces
-- stand against walls facing the room, chairs face their table, hangings go on
-- inner walls, and doors, stairs and beds stay reachable.
--
-- Nobody can enter a house without an owner, so the furniture is only seen
-- through windows and doors. Every piece carries the custom attribute
-- "familyDecor". It is removed:
--   - when a house is bought (Cyclopedia bid, !buyhouse, GOD /owner), before
--     the new owner gets it: the house is empty, only the map's own fixtures
--     (beds, ovens...) stay;
--   - at every start from houses that have an owner (safety) and from all
--     houses before the unowned ones are furnished again (no duplicates).
-- A house that is given up gets its furniture back at the next start.
--
-- Switch: Family.houseDecor (false = no furniture, and any left is removed at
-- the next start).

Family = Family or {}
Family.houseDecor = true

local KEY = "familyDecor"
local data

local function loadData()
	if data == nil then
		local ok, result = pcall(dofile, CORE_DIRECTORY .. "/scripts/family/house_decor_data.lua")
		if ok and type(result) == "table" then
			data = result
		else
			data = false
			logger.error("[Family] house decor: could not read the plan: {}", tostring(result))
		end
	end
	return data or nil
end

-- Removes the furniture of one house. Returns how many pieces were removed.
function Family.houseDecorClear(house)
	local removed = 0
	for _, tile in ipairs(house:getTiles() or {}) do
		local items = tile:getItems() or {}
		for i = #items, 1, -1 do
			local item = items[i]
			if item:getCustomAttribute(KEY) then
				item:remove()
				removed = removed + 1
			end
		end
	end
	return removed
end

-- Furnishes one house (no owner). Returns how many pieces were placed.
function Family.houseDecorate(house)
	local plan = loadData()
	local cells = plan and plan[house:getId()]
	if not cells or house:getOwnerGuid() ~= 0 then
		return 0
	end
	local placed = 0
	for _, cell in ipairs(cells) do
		local position = Position(cell[1], cell[2], cell[3])
		local tile = Tile(position)
		local tileHouse = tile and tile:getHouse()
		if tileHouse and tileHouse:getId() == house:getId() and not tile:getTopCreature() then
			local item = Game.createItem(cell[4], 1, position)
			if item then
				item:setCustomAttribute(KEY, 1)
				placed = placed + 1
			end
		end
	end
	return placed
end

local function startup()
	local cleared, placed, furnished = 0, 0, 0
	for _, house in ipairs(Game.getHouses()) do
		cleared = cleared + Family.houseDecorClear(house)
		if Family.houseDecor and house:getOwnerGuid() == 0 then
			local n = Family.houseDecorate(house)
			if n > 0 then
				placed = placed + n
				furnished = furnished + 1
			end
		end
	end
	logger.info("[Family] house decor: {} pieces in {} houses for sale ({} old pieces removed)", placed, furnished, cleared)
end

local event = GlobalEvent("FamilyHouseDecor")

function event.onStartup()
	addEvent(startup, 0)
	return true
end

event:register()
