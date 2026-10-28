-- Gaia Family server: Grimvale Quest, mission "An Ancient Feud" (2026-10-28).
-- Ours, not upstream: upstream has the Lion Sanctum, its four bosses and the
-- items, but no mission, no NPCs (Domizian, a Skull, Rhargu, Heliodor) and
-- nothing that opened the Sanctum doors. World objects and events:
-- scripts/family/ancient_feud.lua. Starts after The Curse Spreads (Daniel
-- Steelsoul: "Talk to Daniel again", TibiaWiki EN).
--
--   1 Daniel Steelsoul (`lion`)                       -> Domizian in Darashia
--   2 Domizian: investigate the Hyaena Lairs (pool of blood, skulls on a
--     stonepile, blood-stained pagoda; a Skull at night: `undead`, `leader`)
--   3 Domizian (`undead`)                             -> find Rhargu
--   4 Rhargu: haunch of boar, hard-boiled hydra egg, 5 lion's manes and a
--     cask with 5 salted cave rats
--   5 Rhargu gives the lit torch: burn the bone shrine
--   6 the shrine does not burn                         -> Domizian (`destroy`)
--   7 bless the torch (chopped lion's mane petals on the north-eastern mosaic
--     tile in the Sanctum), burn the shrine
--   8 shrine burnt                                     -> Domizian
--   9 kill 300 werehyaenas and shamans (counted since step 2)
--  10 Domizian gives the lion ring: the lion column, the sandstone statue
--  11 the statue: bring Katex' blood, Srezz' eye, Utua's poison, Yirkas' egg
--  12 the mosaic by the statue leads to Heliodor
--  13 Heliodor told (achievement Drama in Darama)       -> Domizian
--  14 Domizian: lion mosaics; the shortcuts and the Sanctum doors stay open
-- Lines marked "ours" are not from the wiki transcripts.
-- Switch: Family.ancientFeud (false = the NPCs say nothing about it; the
-- Sanctum doors then open only with the upstream storage).

Family = Family or {}
Family.ancientFeud = true

FamilyAncientFeud = {}
local F = FamilyAncientFeud
local S = Storage.Quest.FamilyAncientFeud

F.kills = 300

F.items = {
	haunch = 12310,
	hydraEgg = 4839,
	boiledEgg = 33947,
	mane = 9691,
	emptyCask = 33917,
	fullCask = 33942,
	torch = 34017,
	blessedTorch = 34016,
	goblinCask = 33948,
	ring = 34080,
	mosaicHead = 34218,
	mosaicMane = 34217,
}

F.tokens = {
	{ item = 34100, boss = "Katex Blood Tongue" },
	{ item = 34103, boss = "Srezz Yellow Eyes" },
	{ item = 34101, boss = "Utua Stone Sting" },
	{ item = 34102, boss = "Yirkas Blue Scales" },
}

F.clues = {
	{ bit = 1, name = "the pool of blood" },
	{ bit = 2, name = "the skulls on a stonepile" },
	{ bit = 4, name = "the blood-stained pagoda" },
	{ bit = 8, name = "a talking skull" },
}

local function get(player, key)
	return math.max(0, player:getStorageValue(key))
end

function F.state(player)
	return get(player, S.Mission)
end

function F.setState(player, value)
	player:setStorageValue(S.Mission, value)
	if FamilyGrimvaleStart then
		FamilyGrimvaleStart(player)
	end
end

local function hasBit(value, bit)
	return math.floor(value / bit) % 2 == 1
end

function F.addClue(player, bit)
	local value = get(player, S.Clues)
	if not hasBit(value, bit) then
		player:setStorageValue(S.Clues, value + bit)
		return true
	end
	return false
end

function F.allClues(player)
	return get(player, S.Clues) == 15
end

function F.killCount(player)
	return get(player, S.Kills)
end

function F.done(player)
	return F.state(player) >= 14
end

local function joinNames(list)
	if #list <= 1 then
		return list[1] or ""
	end
	return table.concat(list, ", ", 1, #list - 1) .. " and " .. list[#list]
end

function F.missingClues(player)
	local value, names = get(player, S.Clues), {}
	for _, clue in ipairs(F.clues) do
		if not hasBit(value, clue.bit) then
			names[#names + 1] = clue.name
		end
	end
	return names
end

function F.missingTokens(player)
	local names = {}
	for _, token in ipairs(F.tokens) do
		if player:getItemCount(token.item) < 1 then
			names[#names + 1] = ItemType(token.item):getName()
		end
	end
	return names
end

-- Quest log text (ours, after the wiki walkthrough)
function F.describe(player)
	local state = F.state(player)
	if state == 1 then
		return "Daniel Steelsoul heard rumours that the curse has spread to the Darama Desert. Talk to his friend Domizian, who lives in a house at the harbour of Darashia, about the lions."
	elseif state == 2 then
		local missing = F.missingClues(player)
		local text = "Domizian suspects a pact between the werehyaenas and the undead of Drefia. Investigate the Hyaena Lairs north of Darashia (entrance at a large standing stone)."
		if #missing > 0 then
			return text .. " Still to find: " .. joinNames(missing) .. ". The skull only talks at night."
		end
		return text .. " You found enough: tell Domizian about the undead."
	elseif state == 3 then
		return "The werehyaenas' leader, Rhargu, lives in her own cave deep in the Hyaena Lairs. Ask her about the curse."
	elseif state == 4 then
		return "Rhargu wants food: a haunch of boar, a hard-boiled hydra egg (boil a hydra egg on the campfire in the lairs), five lion's manes and her cask filled with five salted cave rats (catch cave rats with a net from Halif, salt them with salt from Mugluf, put them into the cask). Then tell her about the curse."
	elseif state == 5 then
		return "Rhargu gave you a sandalwood torch. Burn down the bone shrine at the dragon skeleton in the Hyaena Lairs with it."
	elseif state == 6 then
		return "The bone shrine would not burn. Ask Domizian how to destroy it."
	elseif state == 7 then
		return "Bless the torch in the Lion Sanctum: say 'The sun guides our hearts. The moon guards our dreams' at its door, chop a lion's mane flower (from the ramp above Lion's Rock) with a knife, then stand on the north-eastern tile of the sun and moon mosaic and sprinkle the petals into the torch's flame. Then burn the bone shrine."
	elseif state == 8 then
		return "The bone shrine is destroyed. Tell Domizian about the curse."
	elseif state == 9 then
		return string.format("Domizian asked you to kill 300 werehyaenas and werehyaena shamans. Killed so far: %d of 300.", math.min(F.killCount(player), F.kills))
	elseif state == 10 then
		return "Domizian is a werelion, exiled by his king Heliodor. Wear his lion ring and touch the lion column in the south-west of the Sanctum's upper floor to reach the lower part. There, use the sandstone statue to ask for an audience with Heliodor."
	elseif state == 11 then
		local missing = F.missingTokens(player)
		if #missing == 0 then
			return "You have the tokens of all four beasts. Use the sandstone statue again."
		end
		return "To be worthy of the king, defeat the four beasts behind the door north of the statue and bring their tokens to the statue. Still missing: " .. joinNames(missing) .. "."
	elseif state == 12 then
		return "The statue accepted the tokens. Step on the mosaic next to it and tell Heliodor about the curse."
	elseif state == 13 then
		return "Heliodor will consider pardoning Domizian. Tell Domizian about it."
	elseif state >= 14 then
		return "You helped Domizian and the werelions against the werehyaenas. The shortcuts to the Lion Sanctum, the statue on top of Lion's Rock and the door to the Hyaena Lairs, are open for you."
	end
	return "Talk to Daniel Steelsoul in Edron about the lions."
end

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
end

local TOPIC_LION = 301
local TOPIC_FOOD = 302

local dialogue = {}

dialogue.daniel = function(npc, creature, player, message, npcHandler)
	local id = player:getId()
	if npcHandler:getTopic(id) == TOPIC_LION and MsgContains(message, "yes") then
		say(npcHandler, npc, creature, {
			"Then please travel to Darashia and search for a man called Domizian. He lives in a house at the harbour. I know him for many years, he's a trustworthy friend. ...",
			"I'm sure, he can tell you more about the curse in the Darama Desert.",
		})
		F.setState(player, 1)
		npcHandler:setTopic(id, 0)
		return true
	end
	if not MsgContains(message, "lion") and not MsgContains(message, "lions") then
		return false
	end
	local state = F.state(player)
	if state < 1 then
		if FamilyCurseSpreads and FamilyCurseSpreads.state(player) < 12 then
			say(npcHandler, npc, creature, "Lions? First we have to get the curse here under control.") -- ours
			return true
		end
		say(npcHandler, npc, creature, "Lately I heard rumours about the curse. That it has spread to the Darama Desert and that the lions there could also be were-creatures. Do you want to get to the bottom of it?")
		npcHandler:setTopic(id, TOPIC_LION)
	elseif state < 14 then
		say(npcHandler, npc, creature, "Domizian in Darashia knows more about the curse in the Darama Desert. He lives in a house at the harbour.") -- ours
	else
		say(npcHandler, npc, creature, "Domizian wrote me about your deeds in the desert. Well done!") -- ours
	end
	return true
end

dialogue.domizian = function(npc, creature, player, message, npcHandler)
	local state = F.state(player)
	local lion = MsgContains(message, "lion") or MsgContains(message, "lions")
	local curse = MsgContains(message, "curse")
	if state == 1 and (lion or curse) then
		say(npcHandler, npc, creature, {
			"So, Daniel Steelsoul sent you? He is a most respectable man and I'm honoured to know him. It is of advantage that you have already dealt with the were-sickness so you won't hurl yourself into this adventure unprepared. ...",
			"Listen, the curse has indeed spread to the Darama Desert - but not recently. It exists here since a long time but only few know about it. Here, it's not werewolves or werebears. The danger that plagues this region are the werehyaenas. ...",
			"Until now they were savage and smelly beasts who hunted down a travelling merchant now and then. But mostly they stayed in their subterranean lairs and lived off carrion. ...",
			"But a few weeks ago something changed. Suddenly they had shamans, something I never saw before. Those shamans are using bone talismans and paint their fur with runes. Runes I saw just once before ... on an artefact from Drefia. ...",
			"I'm afraid the werehyaenas have a kind of pact with the {undead} of Drefia but I don't have proof. Please go to their lairs and investigate. You will find the entrance north of the town, at a large standing stone. ...",
			"Be careful down there, though! Werehyaenas might not be the only danger you will have to face. I heard strange stories about blood pools, a talking skull and even liches.",
		})
		F.setState(player, 2)
		return true
	end
	if MsgContains(message, "undead") then
		if state == 2 then
			if F.allClues(player) then
				-- ours
				say(npcHandler, npc, creature, {
					"So it's true! The undead of Drefia are working together with the werehyaenas. And their leader is a hyaena called Rhargu? ...",
					"Then find her in the depths of the lairs. Perhaps she can be persuaded to end this pact - werehyaenas are not known for their loyalty.",
				})
				F.setState(player, 3)
			else
				say(npcHandler, npc, creature, "I still have no proof. Search the lairs: " .. joinNames(F.missingClues(player)) .. ".") -- ours
			end
			return true
		end
		return false
	end
	if MsgContains(message, "destroy") then
		if state == 6 or state == 7 then
			say(npcHandler, npc, creature, {
				"I guess you need something holy or at least blessed to destroy this evil site. The werelions know a ritual that allows you to bless fire in general. It should work with this torch, too. ...",
				"But you can do that only at a special altar in our sanctum. Go to the Lion's Rock in the north-west of Darashia. Descend to the area where the most noble lions are guarding a secret entrance. ...",
				"There is a door, you can only open if you know the right phrase. It is: 'The sun guides our hearts. The moon guards our dreams'. Down there you will find a room with a mosaic, showing a sun and a moon. ...",
				"There is an altar where you can bless the torch. You have to find a lion mane flower and chop the petals up small. Then sprinkle the chopped petals into the flame while standing at the altar. ...",
				"Thus, the fire will be blessed and should be able to burn down the evil bone shrine.",
			})
			if state == 6 then
				F.setState(player, 7)
			end
			return true
		end
		return false
	end
	if not (curse or lion) then
		return false
	end
	if state < 1 then
		say(npcHandler, npc, creature, "The curse? I don't know what you are talking about.") -- ours
	elseif state <= 3 then
		say(npcHandler, npc, creature, "Please investigate the lairs of the werehyaenas north of the town. I need proof of their pact with the {undead}.") -- ours
	elseif state <= 5 then
		say(npcHandler, npc, creature, "Rhargu, the leader of the werehyaenas? Be careful, they are treacherous.") -- ours
	elseif state <= 7 then
		say(npcHandler, npc, creature, "The bone shrine has to be destroyed. Do you need my help to {destroy} it?") -- ours
	elseif state == 8 then
		say(npcHandler, npc, creature, {
			"You destroyed the pact between the werehyaenas and the undead! You did Darashia a great favour, that's for sure. But there are still so many of them, they could be a real threat to the caravans that try to reach the city. ...",
			"Please, kill three hundred of those ferocious werehyaenas and their shamans.",
		})
		F.setState(player, 9)
	elseif state == 9 then
		local kills = math.min(F.killCount(player), F.kills)
		if kills < F.kills then
			say(npcHandler, npc, creature, string.format("There are still so many of them. So far you killed %d of three hundred.", kills)) -- ours
			return true
		end
		say(npcHandler, npc, creature, {
			"Yes, there are less of them now! What a relief for Darashia. Well, I guess, now I can trust you enough to tell you a little secret about myself. I'm actually a werelion. Don't be scared, though. ...",
			"There's something special to the werelions: We can control the curse and don't attack people like mindless beasts. This is the reason why I can live here in the city and talk to you in such a civilized way. ...",
			"Well, the werehyaenas were a danger to Darashia but they also caused a very personal problem for me. Look, I assumed that they are up to something and that this something could be the undead in Drefia. ...",
			"I warned our king, Heliodor, about it but he didn't believe me. I insisted and got short-tempered - which is never a good idea in the presence of your king. He exiled me as punishment for my impudence. ...",
			"This is the reason why I live here in Darashia. This city has its conveniences but I would like to return to my pride. Please find Heliodor and tell him about the werehyaenas' pact with the undead. ...",
			"Take this ring, it will allow you to enter the lower part of the sanctum. Wear it while you touch one of the lion columns in the centre of the sanctum's upper floor. Then you will reach the lower part.",
		})
		player:addItem(F.items.ring, 1)
		F.setState(player, 10)
	elseif state <= 12 then
		if state == 10 and player:getItemCount(F.items.ring) < 1 and not (player:getSlotItem(CONST_SLOT_RING) and player:getSlotItem(CONST_SLOT_RING):getId() == F.items.ring) then
			player:addItem(F.items.ring, 1)
			say(npcHandler, npc, creature, "You lost my ring? Here, take this one. Wear it while you touch the lion column.") -- ours
			return true
		end
		say(npcHandler, npc, creature, "Please find Heliodor in the lower part of the sanctum and tell him about the werehyaenas' pact with the undead.") -- ours
	elseif state == 13 then
		say(npcHandler, npc, creature, "You found Heliodor and told him about the werehyaenas? He will consider to pardon me? I don't know how I could thank you! Take this as a small compensation for your efforts!")
		player:addItem(F.items.mosaicHead, 1)
		player:addItem(F.items.mosaicMane, 1)
		player:setStorageValue(Storage.Quest.U10_80.GrimvaleQuest.AncientFeudDoors, 1)
		player:setStorageValue(Storage.Quest.U10_80.GrimvaleQuest.AncientFeudShortcut, 1)
		F.setState(player, 14)
	else
		say(npcHandler, npc, creature, "Perhaps one day I can return to my pride. Thank you, my friend.") -- ours
	end
	return true
end

-- a Skull: only talks at night (TibiaWiki EN)
function F.isNight()
	return getTibiaTimerDayOrNight and getTibiaTimerDayOrNight() == "night"
end

dialogue.skull = function(npc, creature, player, message, npcHandler)
	if not F.isNight() then
		return true -- silent by day
	end
	if MsgContains(message, "undead") then
		say(npcHandler, npc, creature, "Listen: The undead of Drefia are working together with the werehyaenas. I overheard a secret conversation between the werehyaena {leader} and a lich right here!")
		return true
	elseif MsgContains(message, "leader") then
		say(npcHandler, npc, creature, "A fierce and cunning hyaena named Rhargu. She lives in her own cave down here.")
		if F.state(player) == 2 then
			F.addClue(player, 8)
		end
		return true
	end
	return false
end

dialogue.rhargu = function(npc, creature, player, message, npcHandler)
	local id = player:getId()
	local state = F.state(player)
	local I = F.items
	if npcHandler:getTopic(id) == TOPIC_FOOD then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			local missing = {}
			if player:getItemCount(I.haunch) < 1 then missing[#missing + 1] = "a haunch of boar" end
			if player:getItemCount(I.boiledEgg) < 1 then missing[#missing + 1] = "a hard-boiled hydra egg" end
			if player:getItemCount(I.mane) < 5 then missing[#missing + 1] = "five lion's manes" end
			if player:getItemCount(I.fullCask) < 1 then missing[#missing + 1] = "a cask full of salted cave rats" end
			if #missing > 0 then
				say(npcHandler, npc, creature, "Grrr! Liar! Where is " .. joinNames(missing) .. "?") -- ours
				return true
			end
			player:removeItem(I.haunch, 1)
			player:removeItem(I.boiledEgg, 1)
			player:removeItem(I.mane, 5)
			player:removeItem(I.fullCask, 1)
			say(npcHandler, npc, creature, {
				"Give me! And take this. A special torch, made of sandalwood. Burn down the bone shrine at the dragon skeleton with this torch. That will destroy the connection with the undead. ...",
				"And I have a little reward for you. Take this cask. It's funny but smelly. You can have it.",
			})
			player:addItem(I.torch, 1)
			player:addItem(I.goblinCask, 1)
			F.setState(player, 5)
		else
			say(npcHandler, npc, creature, "Then go and get it! Grrr.") -- ours
		end
		return true
	end
	if MsgContains(message, "torch") and state >= 5 and state <= 7 then
		if player:getItemCount(I.torch) > 0 or player:getItemCount(I.blessedTorch) > 0 then
			say(npcHandler, npc, creature, "You still have the torch. Burn the shrine with it!") -- ours
		else
			player:addItem(I.torch, 1)
			say(npcHandler, npc, creature, "Clumsy human! Here, take another one.") -- ours
		end
		return true
	end
	if not MsgContains(message, "curse") then
		return false
	end
	if state < 3 then
		say(npcHandler, npc, creature, "Grrr! Go away, human, before I eat you!") -- ours
	elseif state == 3 then
		say(npcHandler, npc, creature, {
			"None of your business, the undead! On the other hand .. they haven't done so much for us. Gave us some talismans for our shamans. But no food! I asked for it. They never brought it. ...",
			"If you bring me the food I wish for, I could end this. Or tell you how to end it. But you have to bring me a boar haunch, those are so tasty! And a hard-boiled hydra egg. Always wanted to try one. ...",
			"Also, take this cask and fill it with salted cave rats. My favourite snack! At last, bring me five lion manes. Want to decorate my cave with them, grhrr. And make sure you can take this cask.",
		})
		player:addItem(I.emptyCask, 1)
		F.setState(player, 4)
	elseif state == 4 then
		say(npcHandler, npc, creature, "Do you have my food?")
		npcHandler:setTopic(id, TOPIC_FOOD)
	elseif state <= 7 then
		say(npcHandler, npc, creature, "Burn down the bone shrine at the dragon skeleton with the torch. If you lost it, ask me for another {torch}.") -- ours
	else
		say(npcHandler, npc, creature, "The undead are gone. Now go away, I'm eating!") -- ours
	end
	return true
end

dialogue.heliodor = function(npc, creature, player, message, npcHandler)
	if not MsgContains(message, "curse") then
		return false
	end
	if F.state(player) == 12 then
		say(npcHandler, npc, creature, {
			"Alas, this is a very interesting story you are telling me! Thank you, human, for acquainting me! I will consider to pardon Domizian but I have to take my time to think it through. ...",
			"But now, please leave this place. You did us a certain favour but for all that, humans are not welcome here.",
		})
		F.setState(player, 13)
		if player.addAchievement then
			player:addAchievement("Drama in Darama")
		end
	else
		say(npcHandler, npc, creature, "Humans are not welcome here. Leave this place.") -- ours
	end
	return true
end

-- Called from the NPCs' default message callback. Returns true when handled.
function F.onSay(who, npc, creature, player, message, npcHandler)
	if not Family.ancientFeud or not dialogue[who] then
		return false
	end
	return dialogue[who](npc, creature, player, message, npcHandler) == true
end
