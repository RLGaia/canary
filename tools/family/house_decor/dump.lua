-- Gaia Family server (ours): dumps every house and the tiles around it for
-- tools/family/house_decor/plan.py. Copy to data/scripts/, start the server
-- once, remove it again. Writes house_dump.txt in the server's folder.
local ev = GlobalEvent("FamilyHouseDump")
function ev.onStartup()
	addEvent(function()
		local f = io.open("house_dump.txt", "w")
		for _, house in ipairs(Game.getHouses()) do
			local town = house:getTown()
			local e = house:getExitPosition()
			f:write(string.format("H\t%d\t%s\t%s\t%d\t%d,%d,%d\n", house:getId(), house:getName(), town and town:getName() or "", house:getOwnerGuid(), e.x, e.y, e.z))
			local box = {}
			for _, tile in ipairs(house:getTiles()) do
				local p = tile:getPosition()
				local b = box[p.z] or { x0 = p.x, x1 = p.x, y0 = p.y, y1 = p.y }
				b.x0, b.x1, b.y0, b.y1 = math.min(b.x0, p.x), math.max(b.x1, p.x), math.min(b.y0, p.y), math.max(b.y1, p.y)
				box[p.z] = b
			end
			for z, b in pairs(box) do
				for y = b.y0 - 2, b.y1 + 2 do
					for x = b.x0 - 2, b.x1 + 2 do
						local tile = Tile(x, y, z)
						if tile then
							local ids = {}
							local g = tile:getGround()
							if g then
								ids[#ids + 1] = g:getId()
							end
							for _, it in ipairs(tile:getItems() or {}) do
								if not it:getCustomAttribute("familyDecor") then
									ids[#ids + 1] = it:getId()
								end
							end
							local th = tile:getHouse()
							f:write(string.format("T\t%d\t%d\t%d\t%d\t%s\n", x, y, z, th and th:getId() or 0, table.concat(ids, ",")))
						end
					end
				end
			end
			for _, d in ipairs(house:getDoors() or {}) do
				local p = d:getPosition()
				f:write(string.format("D\t%d\t%d\t%d\n", p.x, p.y, p.z))
			end
			for _, b in ipairs(house:getBeds() or {}) do
				local p = b:getPosition()
				f:write(string.format("B\t%d\t%d\t%d\n", p.x, p.y, p.z))
			end
		end
		f:close()
		logger.info("[Family] house dump written: house_dump.txt")
	end, 5000)
	return true
end
ev:register()
