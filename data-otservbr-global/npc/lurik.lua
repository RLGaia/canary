local internalNpcName = "Lurik"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 133,
	lookHead = 38,
	lookBody = 94,
	lookLegs = 96,
	lookFeet = 116,
	lookAddons = 3,
}

npcConfig.flags = {
	floorchange = false,
}

local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)

npcType.onThink = function(npc, interval)
	npcHandler:onThink(npc, interval)
end

npcType.onAppear = function(npc, creature)
	npcHandler:onAppear(npc, creature)
end

npcType.onDisappear = function(npc, creature)
	npcHandler:onDisappear(npc, creature)
end

npcType.onMove = function(npc, creature, fromPosition, toPosition)
	npcHandler:onMove(npc, creature, fromPosition, toPosition)
end

npcType.onSay = function(npc, creature, type, message)
	npcHandler:onSay(npc, creature, type, message)
end

npcType.onCloseChannel = function(npc, creature)
	npcHandler:onCloseChannel(npc, creature)
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if MsgContains(message, "mission") then
		-- FAMILY: upstream offered the mission only when it was already accepted (TheIslandofDragons == 57,
		-- which only accepting sets), so The Island of Dragons and The Ice Music never started. Now offered
		-- after The Astral Portals; every step answers (2026-11-01). Lines marked ours.
		local ES = Storage.Quest.U7_6.ExplorerSociety
		local esLine = player:getStorageValue(ES.QuestLine)
		-- FAMILY: The Frozen Trench (upstream had no script for it; scripts/family/frozen_trench.lua, 2026-11-01).
		-- TibiaWiki BR: after The Undersea Kingdom and at least "Formorgar Mines 3" of The Ice Islands Quest.
		local ft = Storage.Quest.FamilyFrozenTrench.Mission
		local ftState = player:getStorageValue(ft)
		local ftOn = Family and Family.frozenTrench
		local ftReady = ftOn and ftState < 1 and player:getStorageValue(ES.CalassaQuest) >= 3 and (player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission11) >= 2 or player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) >= 39)
		if ftOn and ftState == 2 then
			npcHandler:say({
				"These are horrible news. I wonder if there was a malfunction of the diving helmet ...",
				"In any case, a horrible death for that poor explorer. ...",
				"We will try to retrieve the frozen corpse to give him a proper burial. ...",
				"Thank you very much for your help! You have completed two very difficult undersea missions for us and deserve a reward. ...",
				"As token of our appreciation and with respect to your achievement, you are hereby granted the sea scout badge. ...",
				"I will put the according stamp in your explorer log. Thank you again!",
			}, npc, creature)
			player:setStorageValue(ft, 3)
			player:addAchievement("Sea Scout")
			npcHandler:setTopic(playerId, 0)
		elseif ftReady then
			npcHandler:say({
				"Ah, you've just come in time. An experienced explorer is just what we need here! ...",
				"And as I heard from Berenice, you have also experience in undersea exploration. ...",
				"Would you be willing to go on a special mission in an underwater ice cave? It's pretty risky, I know. ...",
				"However, I think you have just what it takes! Do you agree?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 4)
		elseif player:getStorageValue(ES.TheAstralPortals) == 56 and esLine == 56 and player:getStorageValue(ES.TheIslandofDragons) < 57 then
			npcHandler:say("Ah, you've just come in time. An experienced explorer is just what we need here! Would you like to go on a mission for us?", npc, creature)
			npcHandler:setTopic(playerId, 1)
		elseif player:getStorageValue(ES.TheIslandofDragons) == 57 and esLine == 57 then
			npcHandler:say("Travel to Okolnir and try to find a proof for the existence of dragon lords there in the old times. I think old Buddel might be able to bring you there.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		elseif player:getStorageValue(ES.TheIceMusic) == 60 and esLine == 60 then
			if player:getItemCount(7242) == 0 then
				player:addItem(7242, 1)
				npcHandler:say("You lost the resonance crystal? Take another one and use it on the stalagmites in the cave on Hrodmir, north of Krimhorn, to record the sound of the wind.", npc, creature) -- ours
			else
				npcHandler:say("Please use the resonance crystal on the stalagmites in the cave on Hrodmir, north of the southernmost barbarian camp Krimhorn, to record the sound of the wind.", npc, creature)
			end
			npcHandler:setTopic(playerId, 0)
		elseif player:getStorageValue(ES.TheIceMusic) == 61 and esLine == 61 and player:getItemCount(7315) == 0 then
			npcHandler:say("Where is the resonance crystal with the recorded ice music? Please bring it to me.", npc, creature) -- ours
			npcHandler:setTopic(playerId, 0)
		elseif player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIslandofDragons) == 58 and player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.QuestLine) == 58 then
			if player:removeItem(7314, 1) then
				npcHandler:say({
					"A frozen dragon lord? This is just the information we needed! And you even brought a scale from it! Take these 5000 gold pieces as a reward. ...",
					"As you did such a great job, I might have another mission for you later.",
				}, npc, creature)
				player:addItem(3035, 50)
				player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIslandofDragons, 59)
				player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.QuestLine, 59)
			else
				npcHandler:say("You're not done yet...", npc, creature)
			end
		elseif player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIslandofDragons) == 59 and player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.QuestLine) == 59 then
			npcHandler:say({
				"Ah, yes, the mission. Let me tell you about something called ice music. ...",
				"There is a cave on Hrodmir, north of the southernmost barbarian camp Krimhorn. ...",
				"In this cave, there are a waterfall and a lot of stalagmites. ...",
				"When the wind blows into this cave and hits the stalagmites, it is supposed to create a sound similar to a soft song. ...",
				"Please take this resonance crystal and use it on the stalagmites in the cave to record the sound of the wind.",
			}, npc, creature)
			player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIceMusic, 60)
			player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.QuestLine, 60)
			player:addItem(7242, 1)
		elseif player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIceMusic) == 61 and player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.QuestLine) == 61 and player:removeItem(7315, 1) then
			npcHandler:say({
				"Ah! You did it! I can't wait to hear the sound... but I will do that in a silent moment. ...",
				"You helped as much in our research here. As a reward, you may use our astral portal in the upper room from now on. ...",
				"For just one orichalcum pearl, you can travel between Liberty Bay and Svargrond. Thank you again!",
			}, npc, creature)
			npcHandler:setTopic(playerId, 0)
			player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIceMusic, 62)
			player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.QuestLine, 62)
			player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.IceMusicDoor, 1)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 32 then
			npcHandler:say({
				"You are the one who became an honorary barbarian! The one who made friends with the grim local musher and helped the shamans of Nibelor! The one they call old bearhugg ... erm ... I mean indeed I might have a mission for someone like you ...",
				"We are trying to find out what is happening in the raider camps. Through our connection to the shamans we could get a covered contact in their majorcamp far to the south. We equipped our contact with a memory crystal so he could report all he knew ...",
				"We need you to recover this crystal. Travel to the southern camp of the raiders and find our contact man there. Get the memory crystal and bring ithere. The society and the shamans will then decide our next steps. Do you think you can do this?",
			}, npc, creature)
			npcHandler:setTopic(playerId, 2)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 33 then
			npcHandler:say("Have you retrieved the memory crystal?", npc, creature)
			npcHandler:setTopic(playerId, 3)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 34 and player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.MemoryCrystal) > os.time() then
			npcHandler:say("Give me some more time!", npc, creature)
			npcHandler:setTopic(playerId, 0)
		elseif player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline) == 34 and player:getStorageValue(Storage.Quest.U8_0.TheIceIslands.MemoryCrystal) < os.time() then
			npcHandler:say({
				"The information was quite useful. What worries me most are not the raiders but those that have driven them from the old mines...",
				"We need to investigate the mines. Most entrances collapsed due to the lack of maintenance but there should be some possibilities to get in ...",
				"In case you find a door, Ill tell you the old trick of the Carlin mining company to open it <whisper> <whisper>. Find some hint or someone who is willing to talk about what is going on there.",
			}, npc, creature)
			npcHandler:setTopic(playerId, 0)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 35)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission09, 1) -- Questlog The Ice Islands Quest, Formorgar Mines 1: The Mission
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.FormorgarMinesDoor, 1)
		elseif ftOn and ftState == 1 then
			-- ours: what to do while the mission runs
			npcHandler:say("Get old Buddel to bring you to Tyrsung and sneak to the southern coast, where the ship of the Venorean hunters anchors. Wear your helmet of the deep, jump into the water from the planks south of the ship and find out what has happened to our explorer down in the Frozen Trench.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		elseif player:getStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIceMusic) >= 62 then
			npcHandler:say("You helped us so much already. Remember: for just one orichalcum pearl, you can travel between Liberty Bay and Svargrond. Thank you again!", npc, creature) -- FAMILY: ours
			npcHandler:setTopic(playerId, 0)
		else
			npcHandler:say("Our missions here are for experienced members of the explorer society. Come back when you have proven yourself in our bases in Port Hope or Northport.", npc, creature) -- FAMILY: ours
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "yes") then
		-- ISLAND OF DRAGONS
		if npcHandler:getTopic(playerId) == 1 then
			npcHandler:say({
				"Now we're talking! Maybe you've already heard of the island Okolnir south of Hrodmir. ...",
				"Okolnir is the home of a new and fierce dragon race, the so-called frost dragons. However, we have no idea where they originate from. ...",
				"Rumours say that dragon lords, that roamed on this isle, were somehow turned into frost dragons when the great frost covered Okolnir. ...",
				"Travel to Okolnir and try to find a proof for the existence of dragon lords there in the old times. I think old Buddel might be able to bring you there.",
			}, npc, creature)
			npcHandler:setTopic(playerId, 0)
			player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.TheIslandofDragons, 57)
			player:setStorageValue(Storage.Quest.U7_6.ExplorerSociety.QuestLine, 57)
			-- ISLAND OF DRAGONS
		elseif npcHandler:getTopic(playerId) == 2 then
			npcHandler:say("Excellent. Just report about your mission when you got the memory crystal.", npc, creature)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 33)
			player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission08, 2) -- Questlog The Ice Islands Quest, The Contact
			npcHandler:setTopic(playerId, 0)
		elseif npcHandler:getTopic(playerId) == 3 then
			if player:removeItem(7281, 1) then
				npcHandler:say("Ah, great. Please give me some time to evaluate the information. Then talk to me again about your mission. ", npc, creature)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Questline, 34)
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.Mission08, 4) -- Questlog The Ice Islands Quest, The Contact
				player:setStorageValue(Storage.Quest.U8_0.TheIceIslands.MemoryCrystal, os.time() + 5 * 60)
				npcHandler:setTopic(playerId, 0)
			end
		elseif npcHandler:getTopic(playerId) == 4 then
			-- FAMILY: The Frozen Trench accepted (2026-11-01)
			npcHandler:say({
				"Wonderful. I knew that I could count on you. Get old Buddel to bring you to Tyrsung and secretly sneak to the southern coast. ...",
				"The ship of the Venorean hunters should anchor there. They have no idea that they stopped right over the Frozen Trench. ...",
				"This ice cave is said to bear many secrets. We sent one of our best explorers to investigate what's going on down there. ...",
				"However, he has not returned yet and we fear the worst. Please investigate the underwater cave and find out what has happened to him!",
			}, npc, creature)
			player:setStorageValue(Storage.Quest.FamilyFrozenTrench.Mission, 1)
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "no") and npcHandler:getTopic(playerId) == 4 then
		npcHandler:say("I understand. It is a dangerous mission. Come back if you change your mind.", npc, creature) -- FAMILY: ours
		npcHandler:setTopic(playerId, 0)
	end
	return true
end

npcHandler:setMessage(MESSAGE_GREET, "Welcome to the {explorer society} headquarter of Svargrond, |PLAYERNAME|!")
-- FAMILY: his greeting offers {explorer society} but nothing answered it; our line (2026-11-01)
keywordHandler:addKeyword({ "explorer society" }, StdModule.say, { npcHandler = npcHandler, text = "The explorer society explores all the lands of Tibia. Here in Svargrond we study the ice islands and the seas around them. If you are one of us, ask me for a {mission}." })
npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

npcConfig.shop = {
	{ itemName = "orichalcum pearl", clientId = 5021, buy = 80 },
}
-- On buy npc shop message
npcType.onBuyItem = function(npc, player, itemId, subType, amount, ignore, inBackpacks, totalCost)
	npc:sellItem(player, itemId, amount, subType, 0, ignore, inBackpacks)
end
-- On sell npc shop message
npcType.onSellItem = function(npc, player, itemId, subtype, amount, ignore, name, totalCost)
	player:sendTextMessage(MESSAGE_TRADE, string.format("Sold %ix %s for %i gold.", amount, name, totalCost))
end
-- On check npc shop message (look item)
npcType.onCheckItem = function(npc, player, clientId, subType) end

npcType:register(npcConfig)
