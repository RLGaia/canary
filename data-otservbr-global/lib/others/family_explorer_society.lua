-- Gaia Family server: The Explorer Society, every step answers (2026-11-01).
--
-- Ours, not upstream. Reported by Rodrigo: with an ice pick (bought on the
-- market) instead of the dwarven pickaxe, Angus asked "Did you get the
-- requested pickaxe...?" and then said nothing to "yes". Upstream Angus and
-- Mortimer have many such dead ends: every report (pickaxe, ice, butterflies,
-- plants, urn, parchment, powder, book, memory stone, runes, ectoplasm, dress)
-- is silent without the item, the mission words are silent while a mission
-- runs or when asked out of order, "mission" is silent in the middle of ranks
-- II to IV, "join" is silent for members.
--
-- Angus and Mortimer call FamilyExplorer.wrap (marked FAMILY: in their files):
-- their own dialogue runs first, unchanged; only when it said nothing, the
-- answer comes from here. Sources: TibiaWiki BR (The Explorer Society Quest,
-- HTML from Rodrigo) and the TibiaWiki EN spoiler. Lines from the wikis are
-- marked "BR"/"EN"; the others are ours, in Angus' style.
--   * TibiaWiki BR/EN: the dwarven pickaxe may come from Uzgod, the dwarven
--     mines or the market; the ice pick is the tool of The Ice Delivery.
--   * TibiaWiki BR: Black Bert's strange powder is accepted (the item the chest
--     gives, 13974, and the one Black Bert sells, 4838, have the same name).
--   * TibiaWiki BR/EN: a memory stone or spectral dress bought from Black Bert
--     only counts after you have found one yourself.
--   * TibiaWiki EN: a lost preparation kit is bought with "preparation kit".
--   * Achievements: "Just in Time" for The Ice Delivery (EN: also Rashid's
--     Wednesday mission, in rashid.lua) and "Explorer" for the spectral dress
--     (BR); upstream gave neither.
--
-- Switch: Family.explorerSocietyAnswers (false = upstream silence).

Family = Family or {}
Family.explorerSocietyAnswers = true

FamilyExplorer = FamilyExplorer or {}
local F = FamilyExplorer

local function S()
	return Storage.Quest.U7_6.ExplorerSociety
end

-- Missions of ranks I to III in the order upstream asks for them (the
-- QuestLine storage moves through these values).
-- offer = QuestLine value at which the mission is offered, done = after it.
F.missions = {
	{ words = { "ice delivery" }, key = "TheIceDelivery", offer = 5, done = 8, name = "ice delivery" },
	{ words = { "butterfly hunt" }, key = "TheButterflyHunt", offer = 8, done = 17, name = "butterfly hunt" },
	{ words = { "plant collection" }, key = "ThePlantCollection", offer = 17, done = 26, name = "plant collection" },
	{ words = { "lizard urn" }, key = "TheLizardUrn", offer = 26, done = 29, name = "lizard urn" },
	{ words = { "bonelord secrets", "bonelord secret" }, key = "TheBonelordSecret", offer = 29, done = 32, name = "bonelord secrets" },
	{ words = { "orc powder" }, key = "TheOrcPowder", offer = 32, done = 35, name = "orc powder" },
	{ words = { "elven poetry", "elven book" }, key = "TheElvenPoetry", offer = 35, done = 38, name = "elven poetry" },
	{ words = { "memory stone" }, key = "TheMemoryStone", offer = 38, done = 41, name = "memory stone" },
	{ words = { "rune writings" }, key = "TheRuneWritings", offer = 41, done = 44, name = "rune writings" },
}

-- What to do while a mission runs, by QuestLine value (ours, his words where possible).
F.reminders = {
	[6] = "So listen please: Take the ice pick and use it on a block of ice in the caves beneath Folda. Get some ice and report about your {ice delivery} as fast as you can.",
	[9] = "Just use the preparation kit on the fresh corpse of a purple butterfly, return the prepared butterfly to me and give me a report of your {butterfly hunt}.",
	[12] = "Just use the preparation kit on the fresh corpse of a blue butterfly, return the prepared butterfly to me and give me a report of your {butterfly hunt}.",
	[15] = "Just use the preparation kit on the fresh corpse of a red butterfly, return the prepared butterfly to me and give me a report of your {butterfly hunt}.",
	[18] = "Use the botanist's container on a jungle bells plant to collect a sample for us. Report about your {plant collection} when you have been successful.",
	[21] = "Use the botanist's container on a witches cauldron to collect a sample for us. Bring it here and report about your {plant collection}.",
	[24] = "Use the botanist's container on a giant jungle rose to obtain a sample for us. Bring it here and report about your {plant collection}.",
	[27] = "In the south-east of Tiquanda is a small settlement of the lizard people. Beneath the newly constructed temple there, the lizards hide the urn. Report about the {lizard urn} when you have it.",
	[30] = "Travel to the city of Darashia and then head north-east for the pyramid. If any documents are left, you probably find them in the catacombs beneath. Report about the {bonelord secrets} then.",
	[33] = "The orcs maintain some sort of training facility in some hill in the north-east of their city. There you should find the orcish powder. Report about the {orc powder} then.",
	[36] = "Travel to Ab'Dendriel and get the book 'Songs of the Forest'. Report about the {elven book} when you have it.",
	[39] = "In the ruins of north-western Edron you should be able to find a memory stone. Report about the {memory stone} when you have it.",
	[42] = "Use the tracing paper on the atypical structure in the lizard dungeons beneath Banuta to copy the ancient runes. Report about the {rune writings} then.",
	[45] = "Use the ectoplasm container on a ghost that was recently slain. Return with the collected ectoplasm and report about your {mission}.",
	[48] = "Try to get a spectral dress from the queen of the banshees in the deepest dungeons beneath the Ghostlands, south west of Carlin. Report about your {mission} then.",
}

-- Report topics of Angus and Mortimer (the same numbers in both files):
-- the item the answer "yes" hands over, and what to say without it.
F.reports = {
	[3] = { items = { 4845 } },
	[5] = { items = { 4837 } },
	[8] = { items = { 4864 }, missing = "You don't have the prepared purple butterfly with you. Just use the preparation kit on the fresh corpse of a purple butterfly and return it to me." },
	[9] = { items = { 4865 }, missing = "You don't have the prepared blue butterfly with you. Just use the preparation kit on the fresh corpse of a blue butterfly and return it to me." },
	[10] = { items = { 4866 }, missing = "You don't have the prepared red butterfly with you. Just use the preparation kit on the fresh corpse of a red butterfly and return it to me." },
	[12] = { items = { 4868 }, missing = "You don't have the sample of the jungle bells plant with you." },
	[13] = { items = { 4869 }, missing = "You don't have the sample of the witches cauldron with you." },
	[14] = { items = { 4870 }, missing = "You don't have the sample of the giant jungle rose with you." },
	[16] = { items = { 4847 }, missing = "You don't have the ancient urn with you." },
	[18] = { items = { 173 }, missing = "You don't have the document from the pyramid with you." },
	[20] = {
		items = { 13974, 4838 },
		missing = "You don't have the orcish powder with you.",
		-- Black Bert's strange powder (4838) is accepted too (TibiaWiki BR); upstream took only 13974
		accept = { key = "TheOrcPowder", value = 35, text = "You really got it? Amazing! Thank you for your efforts." },
	},
	[22] = { items = { 4844 }, missing = "You don't have a copy of 'Songs of the Forest' with you. If you lost it, Elvith in Ab'Dendriel might sell you another one." },
	[24] = { items = { 4841 }, missing = "You don't have the memory stone with you." },
	[26] = { items = { 4843 }, missing = "You don't have the copy of the ancient runes with you." },
	[29] = { items = { 4853 }, missing = "You don't have the collected ectoplasm with you. Use the container on a ghost that was recently slain." },
	[31] = { items = { 4836 }, missing = "You don't have the spectral dress with you." },
}

local function has(player, items)
	for _, id in ipairs(items) do
		if player:getItemCount(id) > 0 then
			return id
		end
	end
	return nil
end

local function contains(message, words)
	for _, w in ipairs(words) do
		if MsgContains(message, w) then
			return true
		end
	end
	return false
end

local function currentMission(questLine)
	for _, m in ipairs(F.missions) do
		if questLine >= m.offer and questLine < m.done then
			return m
		end
	end
	return nil
end

-- base: "Port Hope" (Angus) or "Northport" (Mortimer); spectralBase: 1 Angus, 2 Mortimer.
local BASES = {
	["Port Hope"] = { other = "Northport", spectralBase = 1 },
	["Northport"] = { other = "Port Hope", spectralBase = 2 },
}

-- Answers when the NPC's own dialogue said nothing. Returns true when it answered.
function F.fallback(npcHandler, npc, creature, message, topicBefore, base)
	local player = Player(creature)
	local playerId = player:getId()
	local ES = S()
	local say = function(text)
		npcHandler:say(text, npc, creature)
	end
	local questLine = player:getStorageValue(ES.QuestLine)
	local joining = player:getStorageValue(ES.JoiningTheExplorers)
	local member = joining >= 5 and questLine >= 5

	-- "yes" to a report without the item
	if MsgContains(message, "yes") and F.reports[topicBefore] then
		local report = F.reports[topicBefore]
		local found = has(player, report.items)
		if found and report.accept and player:removeItem(found, 1) then
			player:setStorageValue(ES[report.accept.key], report.accept.value)
			player:setStorageValue(ES.QuestLine, report.accept.value)
			say(report.accept.text)
			npcHandler:setTopic(playerId, 0)
			return true
		end
		if topicBefore == 3 then
			if player:getItemCount(4872) > 0 then
				say("That is an ice pick! We will need one of those later, but now we need the dwarven pickaxe we ordered from Uzgod in Kazordoon. Dwarven pickaxes can also be found in the dwarven mines.")
			else
				say("You don't have the dwarven pickaxe with you. Get it from Uzgod in Kazordoon and report about the {pickaxe} again.")
			end
			npcHandler:setTopic(playerId, 0)
		elseif topicBefore == 5 then
			say("You don't have the ice with you. Did it melt away?")
			npcHandler:setTopic(playerId, 6)
		else
			say(report.missing)
			npcHandler:setTopic(playerId, 0)
		end
		return true
	end

	-- a lost preparation kit (TibiaWiki EN: say "preparation kit")
	if MsgContains(message, "preparation kit") or MsgContains(message, "conservation kit") then
		local hunt = player:getStorageValue(ES.TheButterflyHunt)
		if (hunt == 9 or hunt == 12 or hunt == 15) and player:getItemCount(4863) == 0 then
			say("Did you lose your preparation kit? I can give you a new one for 250 gold. Do you want it?")
			npcHandler:setTopic(playerId, 90)
		else
			say("You can buy preparation kits in my {trade}.")
			npcHandler:setTopic(playerId, 0)
		end
		return true
	end
	if MsgContains(message, "yes") and topicBefore == 90 then
		if player:removeMoneyBank(250) then
			player:addItem(4863, 1)
			say("Here you are. Don't lose it again!")
		else
			say("You don't have enough money.")
		end
		npcHandler:setTopic(playerId, 0)
		return true
	end

	if MsgContains(message, "join") then
		if member then
			say("You are already a member of the explorer society. Ask me for a {mission} to improve your rank.")
		else
			say("You have already asked to join us. Bring us the {pickaxe} from Uzgod in Kazordoon to prove your dedication.")
		end
		return true
	end

	if MsgContains(message, "pickaxe") then
		if member then
			say("You have already brought us the pickaxe. Thank you again!")
		else
			say("You are not a member of the explorer society. Do you want to {join} us?")
		end
		return true
	end

	-- the mission words of ranks I to III
	for index, m in ipairs(F.missions) do
		if contains(message, m.words) then
			local state = player:getStorageValue(ES[m.key])
			if not member then
				say(joining >= 1 and "First bring us the {pickaxe} from Uzgod in Kazordoon. Then you can ask for missions." or "You are not a member of the explorer society. Do you want to {join} us?")
			elseif state >= m.done or questLine >= m.done then
				say("You have already done that mission. Thank you again!")
			elseif m.key == "TheMemoryStone" and player:getItemCount(4841) > 0 and state == 39 then
				-- BR line: a bought memory stone does not count before you found one yourself
				say("This memory stone looks damaged. Probably you bought it from some suspicious individual. Travel to Edron and get one on your own.")
			elseif F.reminders[questLine] and currentMission(questLine) == m then
				say(F.reminders[questLine])
			elseif questLine < m.offer then
				local current = currentMission(questLine)
				say(current and ("Please finish the {" .. current.name .. "} first. Then ask me for the " .. m.name .. ".") or "You can't do that mission yet.")
			else
				say(F.reminders[questLine] or "Ask me for a {mission} to see what you can do for us.")
			end
			npcHandler:setTopic(playerId, 0)
			return true
		end
	end

	if MsgContains(message, "mission") then
		local info = BASES[base] or BASES["Port Hope"]
		if not member then
			say(joining >= 1 and "First bring us the {pickaxe} from Uzgod in Kazordoon." or "You are not a member of the explorer society. Do you want to {join} us?")
		elseif questLine >= 26 and questLine < 35 then
			say("The missions available for your rank are {lizard urn}, {bonelord secrets} and {orc powder}.")
		elseif questLine >= 35 and questLine < 44 then
			say("The missions available for your rank are {elven poetry}, {memory stone} and {rune writings}.")
		elseif questLine == 45 or questLine == 46 then
			say(F.reminders[45])
		elseif questLine == 48 or questLine == 49 then
			if player:getItemCount(4836) > 0 and player:getStorageValue(ES.TheSpectralDress) == 48 then
				say("This dress was not given to you by the queen of the banshees. You will have to get the dress from her yourself.")
			else
				say(F.reminders[48])
			end
		elseif questLine == 51 then
			say("Please travel to our base in " .. info.other .. " and ask them to mail us their latest research reports. Then return here and ask about new missions.")
		elseif questLine == 52 then
			say("The papers are in the mail already. Return to our base in " .. info.other .. " and ask about new missions there.")
		elseif questLine == 53 or questLine == 54 then
			if player:getItemCount(4840) == 0 then
				player:addItem(4840, 1)
				say("You lost the spectral essence? Here, take another one. Use it on the strange carving in our base here and on the one in " .. info.other .. ". Then report about your {mission}.")
			else
				say("Use the spectral essence on the strange carving in our base here and on the one in " .. info.other .. ". As soon as you have charged the portal tiles that way, report about your {mission}.")
			end
		elseif questLine >= 56 then
			say("You have done all the missions of our base. Thank you! Our members in Liberty Bay and Svargrond might need your help, too.")
		else
			say("Ask me about the missions of your rank.")
		end
		npcHandler:setTopic(playerId, 0)
		return true
	end
	return false
end

-- Things to do after the NPC's own dialogue (both when it answered and not).
function F.after(player, before)
	local ES = S()
	-- achievements upstream never gave
	if before.ice ~= 8 and player:getStorageValue(ES.TheIceDelivery) == 8 then
		player:addAchievement("Just in Time")
	end
	if before.dress ~= 50 and player:getStorageValue(ES.TheSpectralDress) == 50 then
		player:addAchievement("Explorer")
	end
	-- a new chance at the ice: a new ice pick if it was lost
	if before.ice == 7 and player:getStorageValue(ES.TheIceDelivery) == 6 and player:getItemCount(4872) == 0 then
		player:addItem(4872, 1)
	end
end

-- Wraps an NPC callback: its own dialogue first, then our answer if it said nothing.
function F.wrap(npcHandler, callback, base)
	local said = false
	local originalSay = npcHandler.say
	npcHandler.say = function(self, ...)
		said = true
		return originalSay(self, ...)
	end
	return function(npc, creature, msgType, message)
		if not Family.explorerSocietyAnswers then
			return callback(npc, creature, msgType, message)
		end
		local player = Player(creature)
		if not player or not npcHandler:checkInteraction(npc, creature) then
			return callback(npc, creature, msgType, message)
		end
		local ES = S()
		local topicBefore = npcHandler:getTopic(player:getId()) or 0
		local before = { ice = player:getStorageValue(ES.TheIceDelivery), dress = player:getStorageValue(ES.TheSpectralDress) }
		said = false
		local result = callback(npc, creature, msgType, message)
		if not said then
			F.fallback(npcHandler, npc, creature, message, topicBefore, base)
		end
		F.after(player, before)
		return result
	end
end
