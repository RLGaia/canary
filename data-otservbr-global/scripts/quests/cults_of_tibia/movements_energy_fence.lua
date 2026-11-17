local misguided = {
	[1] = Position(32527, 32468, 10),
	[2] = Position(32528, 32468, 10),
	[3] = Position(32529, 32468, 10),
	[4] = Position(32530, 32468, 10),
	[5] = Position(32531, 32468, 10),
	[6] = Position(32532, 32468, 10),
	[7] = Position(32533, 32468, 10),
	[8] = Position(32534, 32468, 10),
	[9] = Position(32535, 32468, 10),
	[10] = Position(32536, 32468, 10),
	[11] = Position(32537, 32468, 10),
	[12] = Position(32538, 32468, 10),
}

local energyFence = MoveEvent()

function energyFence.onStepIn(creature, item, position, fromPosition)
	local firstCheck = Position(32350, 31657, 8)
	local secondCheck = Position(32327, 31692, 9)
	local misguidedFirst = Position(32527, 32468, 10)

	local player = creature:getPlayer()
	if not player then
		creature:teleportTo(fromPosition)
		return false
	end

	-- FAMILY (2026-11-17): the first barrier (floor -1) takes the green, decaying souls and the second (floor -2)
	-- the blue, withering ones (BR: "A barreira de energia verde fica no subsolo -1 e a azul no subsolo -2"; EN the
	-- same); upstream checked them the other way round. Messages per barrier (the second pair is ours).
	local family = Family and Family.cultsOfTibia
	local firstStorage = family and Storage.Quest.U11_40.CultsOfTibia.Humans.Decaying or Storage.Quest.U11_40.CultsOfTibia.Humans.Vaporized
	local secondStorage = family and Storage.Quest.U11_40.CultsOfTibia.Humans.Vaporized or Storage.Quest.U11_40.CultsOfTibia.Humans.Decaying
	-- FAMILY (2026-11-17): a barrier passed once stays open; souls of its colour absorbed too long ago fade
	-- (BR: the absorbed energy is lost if you take too long; FamilyCults.soulsFaded)
	local function familyReady(colour, storage)
		if not family then
			return player:getStorageValue(storage) == 10
		end
		if FamilyCults.barrierPassed(player, colour) then
			return true
		end
		if FamilyCults.soulsFaded(player, colour) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The power of the " .. colour .. " souls you absorbed has faded away. You took too long.") -- ours
			return false
		end
		if player:getStorageValue(storage) == 10 then
			FamilyCults.passBarrier(player, colour)
			return true
		end
		return false
	end
	if position == firstCheck or position == Position(firstCheck.x + 1, firstCheck.y, firstCheck.z) or position == Position(firstCheck.x + 2, firstCheck.y, firstCheck.z) then
		if familyReady("decaying", firstStorage) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, family and "With you being the vessel binding the power of decaying souls, you step through the magic barrier." or "With you being the vessel binding the power of whitered souls, you step through the magic barrier.")
			player:getPosition():sendMagicEffect(CONST_ME_ENERGYHIT)
		else
			player:teleportTo(fromPosition, true)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The combined powers of decaying souls roaming these halls may help breach this barrier, it needs but a vessel to bind them.")
		end
	elseif position == secondCheck or position == Position(secondCheck.x + 1, secondCheck.y, secondCheck.z) or position == Position(secondCheck.x + 2, secondCheck.y, secondCheck.z) then
		if familyReady("withering", secondStorage) then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "With you being the vessel binding the power of withered souls, you step through the magic barrier.")
			player:getPosition():sendMagicEffect(CONST_ME_ENERGYHIT)
		else
			player:teleportTo(fromPosition, true)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, family and "The combined powers of withering souls roaming these halls may help breach this barrier, it needs but a vessel to bind them." or "The combined powers of decaying souls roaming these halls may help breach this barrier, it needs but a vessel to bind them.")
		end
	elseif misguided then
		for i, position in pairs(misguided) do
			if player:getStorageValue(Storage.Quest.U11_40.CultsOfTibia.Misguided.Exorcisms) >= 5 then
				player:getPosition():sendMagicEffect(CONST_ME_ENERGYHIT)
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "As you cross the threshold in to the inner sanctuary of the cult of the Misguided, you feel an eerie presence all around you.")
				break
			else
				player:teleportTo(fromPosition, true)
			end
		end
	end
	return true
end

energyFence:type("stepin")
energyFence:aid(5581)
energyFence:register()
