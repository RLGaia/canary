local function cleanMMap(frompos, topos)
	for _x = frompos.x, topos.x, 1 do
		for _y = frompos.y, topos.y, 1 do
			for _z = frompos.z, topos.z, 1 do
				local newpos = Position(_x, _y, _z)
				local tile = Tile(newpos)
				if tile and tile:getItemCount() > 0 then
					for _, it in pairs(tile:getItems()) do
						if it then
							local itemType = ItemType(it:getId())
							if itemType and not itemType:isCorpse() and not itemType:isContainer() and itemType:getWeaponType() <= WEAPON_NONE then
								it:remove()
							end
						end
					end
				end
			end
		end
	end
end

local function changeMap(mapName)
	local map = (type(Game.getStorageValue("cultsMisguidedMap")) == "string" and Game.getStorageValue("cultsMisguidedMap") or "illusion")
	if map:lower() == mapName:lower() then
		return true
	end
	local frompos = Position(32523, 32323, 10)
	local topos = Position(32573, 32477, 10)
	cleanMMap(frompos, topos)
	cleanMMap(Position(32512, 32364, 10), Position(32526, 32474, 10))
	if mapName:lower() == "illusion" then
		Game.setStorageValue("cultsMisguidedMap", "illusion")
		Game.loadMap(DATA_DIRECTORY .. "/world/quest/cults_of_tibia/misguided/illusion.otbm")
	else
		Game.setStorageValue("cultsMisguidedMap", "reality")
		Game.loadMap(DATA_DIRECTORY .. "/world/quest/cults_of_tibia/misguided/reality.otbm")
		addEvent(changeMap, 15000, "illusion")
	end
end

local cultsOfTibiaMisguided = Action()

function cultsOfTibiaMisguided.onUse(player, item, position, target, targetPosition)
	local creature = Creature(target)
	if not creature then
		return false
	end

	local map = (type(Game.getStorageValue("cultsMap")) == "string" and Game.getStorageValue("cultsMap") or "illusion")
	if creature:getName():lower() == "misguided bully" or creature:getName():lower() == "misguided thief" then
		player:setStorageValue(Storage.Quest.U11_40.CultsOfTibia.Misguided.Monsters, 0)
		if Family and Family.cultsOfTibia then
			item:transform(FamilyCults.rubbishAmulet)
		else
			item:remove(1)
		end
		local kind = creature:getName():lower() == "misguided thief" and "thief" or "bully" -- FAMILY (2026-11-17): read before the creature is removed
		local pos = creature:getPosition()
		Game.createItem(25298, 1, pos)
		creature:remove()

		local newCreature = Game.createMonster("Misguided Shadow", pos)
		if newCreature then
			newCreature:getPosition():sendMagicEffect(CONST_ME_TELEPORT)
		end

		-- FAMILY (2026-11-17): thief or bully as the creature was (EN "You paralyze the bully/thief ..."), the amulet
		-- turns back into a rubbish amulet where it was, with EN's message; upstream put a new one in the backpack.
		local family = Family and Family.cultsOfTibia
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, family and ("You paralyse the " .. kind .. " and the amulet reveals the true face of the creature behind the possession of this misguided creature.") or "You paralyse the bully and the amulet reveals the true face of the creature behind the possession of this misguided creature.")
		if map == "illusion" then
			changeMap("reality")
		end
		if family then
			player:setStorageValue(Storage.Quest.U11_40.CultsOfTibia.Misguided.Time, 0)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The amulet you are wearing suddenly feels quite cool and emits a strange light.") -- EN
		else
			local it = player:addItem(25296, 1)
			it:decay()
		end
	end

	return true
end

cultsOfTibiaMisguided:id(25297)
cultsOfTibiaMisguided:register()
