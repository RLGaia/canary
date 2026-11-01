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
--
-- Parallel missions (2026-11-01, asked by Rodrigo). TibiaWiki BR: "Dentro de
-- cada um dos tres primeiros ranks, as missoes podem ser iniciadas e entregues
-- de uma vez so" (inside each of the first three ranks the missions can be
-- taken and delivered together); EN: "You can complete them in any order",
-- and after all three you are promoted (Journeyman, Relic Hunter, Explorer).
-- Upstream chained all nine missions through the QuestLine storage, one after
-- the other. Now the three missions of a rank run side by side: each mission
-- keeps its own storage (same values as upstream, so the quest log is
-- unchanged), the QuestLine stays at the rank (5, 26, 35) and moves to the
-- next rank (26, 35, 44) when all three are done. Characters in the middle of
-- the old chain go on from where they are. Angus and Mortimer answer the
-- rank I to III mission words here (F.parallel below), before their own
-- dialogue; the item scripts (ice pick, preparation kit, botanist's container,
-- tracing paper) and the chests ask F.atQuestLine / F.setQuestLine.
-- Switch: Family.explorerSocietyParallel (false = upstream order).

Family = Family or {}
Family.explorerSocietyAnswers = true
Family.explorerSocietyParallel = true

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

-- ---------------------------------------------------------------------------
-- Parallel missions of ranks I to III
-- ---------------------------------------------------------------------------

function F.parallelOn()
	return Family.explorerSocietyParallel == true
end

-- Item scripts and chests: upstream required QuestLine == the mission step.
function F.atQuestLine(player, value)
	return F.parallelOn() or player:getStorageValue(S().QuestLine) == value
end

function F.setQuestLine(player, value)
	if not F.parallelOn() then
		player:setStorageValue(S().QuestLine, value)
	end
end

local P = {}
F.parallel = P
P.TOPIC = 150 -- npcHandler topic while we wait for "yes"/"no"; the question itself is in P.pending
P.pending = {}

-- Texts from Angus (upstream file, TibiaWiki BR transcripts); Mortimer's are the same.
-- steps[state]: remind = while it runs (tool = item given again if lost), ask = report question
-- (items, next, thanks, missing), advance = the next part of the mission (give, next).
P.missions = {
	ice = {
		key = "TheIceDelivery", words = { "ice delivery" }, name = "ice delivery", first = 6, done = 8,
		offer = { "Our finest minds came up with the theory that deep beneath the ice island of Folda ice can be found that is ancient. To prove this theory we would need a sample of the aforesaid ice ...", "Of course the ice melts away quickly so you would need to hurry to bring it here ...", "Would you like to accept this mission?" },
		accept = { "So listen please: Take this ice pick and use it on a block of ice in the caves beneath Folda. Get some ice and bring it here as fast as you can ...", "Should the ice melt away, report on your ice delivery mission anyway. I will then tell you if the time is right to start another mission." },
		give = 4872,
		steps = {
			[6] = { remind = 6, tool = 4872, toolName = "ice pick" },
			[7] = { ask = "Did you get the ice we are looking for?", items = { 4837 }, next = 8, thanks = "Just in time. Sadly not much ice is left over but it will do. Thank you again.", melts = true },
		},
	},
	butterfly = {
		key = "TheButterflyHunt", words = { "butterfly hunt" }, name = "butterfly hunt", first = 9, done = 17,
		offer = "The mission asks you to collect some species of butterflies, are you interested?",
		accept = { "This preparation kit will allow you to collect a purple butterfly you have killed ...", "Just use it on the fresh corpse of a purple butterfly, return the prepared butterfly to me and give me a report of your butterfly hunt." },
		give = 4863,
		steps = {
			[9] = { remind = 9 },
			[10] = { ask = "Did you acquire the purple butterfly we are looking for?", items = { 4864 }, next = 11, thanks = "A little bit battered but it will do. Thank you! If you think you are ready, ask for another butterfly hunt.", missing = F.reports[8].missing },
			[11] = { advance = { "This preparation kit will allow you to collect a blue butterfly you have killed ...", "Just use it on the fresh corpse of a blue butterfly, return the prepared butterfly to me and give me a report of your butterfly hunt." }, give = 4863, next = 12 },
			[12] = { remind = 12 },
			[13] = { ask = "Did you acquire the blue butterfly we are looking for?", items = { 4865 }, next = 14, thanks = "A little bit battered but it will do. Thank you! If you think you are ready, ask for another butterfly hunt.", missing = F.reports[9].missing },
			[14] = { advance = { "This preparation kit will allow you to collect a red butterfly you have killed ...", "Just use it on the fresh corpse of a red butterfly, return the prepared butterfly to me and give me a report of your butterfly hunt." }, give = 4863, next = 15 },
			[15] = { remind = 15 },
			[16] = { ask = "Did you acquire the red butterfly we are looking for?", items = { 4866 }, next = 17, thanks = "That is an extraordinary species you have brought. Thank you! That was the last butterfly we needed.", missing = F.reports[10].missing },
		},
	},
	plant = {
		key = "ThePlantCollection", words = { "plant collection" }, name = "plant collection", first = 18, done = 26,
		offer = "In this mission we require you to get us some plant samples from Tiquandan plants. Would you like to fulfil this mission?",
		accept = "Fine! Here take this botanist's container. Use it on a jungle bells plant to collect a sample for us. Report about your plant collection when you have been successful.",
		give = 4867,
		steps = {
			[18] = { remind = 18, tool = 4867, toolName = "botanist's container" },
			[19] = { ask = "Did you acquire the sample of the jungle bells plant we are looking for?", items = { 4868 }, next = 20, thanks = "I see. It seems you've got some quite useful sample by sheer luck. Thank you! Just tell me when you are ready to continue with the plant collection.", missing = F.reports[12].missing },
			[20] = { advance = "Use this botanist's container on a witches cauldron to collect a sample for us. Bring it here and report about your plant collection.", give = 4867, next = 21 },
			[21] = { remind = 21, tool = 4867, toolName = "botanist's container" },
			[22] = { ask = "Did you acquire the sample of the witches cauldron we are looking for?", items = { 4869 }, next = 23, thanks = "Ah, finally. I started to wonder what took you so long. But thank you! Another fine sample, indeed. Just tell me when you are ready to continue with the plant collection.", missing = F.reports[13].missing },
			[23] = { advance = "Use this botanist's container on a giant jungle rose to obtain a sample for us. Bring it here and report about your plant collection.", give = 4867, next = 24 },
			[24] = { remind = 24, tool = 4867, toolName = "botanist's container" },
			[25] = { ask = "Did you acquire the sample of the giant jungle rose we are looking for?", items = { 4870 }, next = 26, thanks = "What a lovely sample! With that you have finished your plant collection missions.", missing = F.reports[14].missing },
		},
	},
	urn = {
		key = "TheLizardUrn", words = { "lizard urn" }, name = "lizard urn", first = 27, done = 29, door = "ChorurnDoor",
		offer = "The explorer society would like to acquire an ancient urn which is some sort of relic to the lizard people of Tiquanda. Would you like to accept this mission?",
		accept = { "You have indeed the spirit of an adventurer! In the south-east of Tiquanda is a small settlement of the lizard people ...", "Beneath the newly constructed temple there, the lizards hide the said urn. Our attempts to acquire this item were without success ...", "Perhaps you are more successful." },
		steps = {
			[27] = { remind = 27 },
			[28] = { ask = "Did you manage to get the ancient urn?", items = { 4847 }, next = 29, thanks = "Yes, that is the prized relic we have been looking for so long. You did a great job, thank you.", missing = F.reports[16].missing },
		},
	},
	bonelord = {
		key = "TheBonelordSecret", words = { "bonelord secrets", "bonelord secret" }, name = "bonelord secrets", first = 30, done = 32, door = "BonelordsDoor",
		offer = { "We want to learn more about the ancient race of bonelords. We believe the black pyramid north east of Darashia was originally built by them ...", "We ask you to explore the ruins of the black pyramid and look for any signs that prove our theory. You might probably find some document with the numeric bonelord language ...", "That would be sufficient proof. Would you like to accept this mission?" },
		accept = { "Excellent! So travel to the city of Darashia and then head north-east for the pyramid ...", "If any documents are left, you probably find them in the catacombs beneath. Good luck!" },
		steps = {
			[30] = { remind = 30 },
			[31] = { ask = "Have you found any proof that the pyramid was built by bonelords?", items = { 173 }, next = 32, thanks = "You did it! Excellent! The scientific world will be shaken by this discovery!", missing = F.reports[18].missing },
		},
	},
	powder = {
		key = "TheOrcPowder", words = { "orc powder" }, name = "orc powder", first = 33, done = 35, door = "OrcDoor",
		offer = { "It is commonly known that orcs of Uldereks Rock use some sort of powder to increase the fierceness of their war wolves and berserkers ...", "What we do not know are the ingredients of this powder and its effect on humans ...", "So we would like you to get a sample of the aforesaid powder. Do you want to accept this mission?" },
		accept = { "You are a brave soul. As far as we can tell, the orcs maintain some sort of training facility in some hill in the north-east of their city ...", "There you should find lots of their war wolves and hopefully also some of the orcish powder. Good luck!" },
		steps = {
			[33] = { remind = 33, ask = "Did you acquire some of the orcish powder?", items = { 13974, 4838 }, next = 35, thanks = "You really got it? Amazing! Thank you for your efforts.", missing = F.reports[20].missing, onlyWithItem = true },
			[34] = { ask = "Did you acquire some of the orcish powder?", items = { 13974, 4838 }, next = 35, thanks = "You really got it? Amazing! Thank you for your efforts.", missing = F.reports[20].missing },
		},
	},
	poetry = {
		key = "TheElvenPoetry", words = { "elven poetry", "elven book" }, name = "elven poetry", first = 36, done = 38, door = "ElvenDoor",
		offer = { "Some high ranking members would like to study elven poetry. They want the rare book 'Songs of the Forest' ...", "For sure someone in Ab'Dendriel will own a copy. So you would just have to ask around there. Are you willing to accept this mission?" },
		accept = "Excellent. This mission is easy but nonetheless vital. Travel to Ab'Dendriel and get the book.",
		steps = {
			[36] = { remind = 36 },
			[37] = { ask = "Did you acquire a copy of 'Songs of the Forest' for us?", items = { 4844 }, next = 38, thanks = "Let me have a look! Yes, that's what we wanted. A copy of 'Songs of the Forest'. I won't ask any questions about those bloodstains.", missing = F.reports[22].missing },
		},
	},
	memory = {
		key = "TheMemoryStone", words = { "memory stone" }, name = "memory stone", first = 39, done = 41, door = "MemoryStoneDoor",
		offer = { "We acquired some knowledge about special magic stones. Some lost civilisations used it to store knowledge and lore, just like we use books ...", "The wisdom in such stones must be immense, but so are the dangers faced by every person who tries to obtain one...", "As far as we know the ruins found in the north-west of Edron were once inhabited by beings who used such stones. Do you have the heart to go there and to get us such a stone?" },
		accept = "In the ruins of north-western Edron you should be able to find a memory stone. Good luck.",
		steps = {
			[39] = { remind = 39, bought = { 4841, "This memory stone looks damaged. Probably you bought it from some suspicious individual. Travel to Edron and get one on your own." } },
			[40] = { ask = "Were you able to acquire a memory stone for our society?", items = { 4841 }, next = 41, thanks = "A flawless memory stone! Incredible! It will take years even to figure out how it works but what an opportunity for science, thank you!", missing = F.reports[24].missing },
		},
	},
	runes = {
		key = "TheRuneWritings", words = { "rune writings" }, name = "rune writings", first = 42, done = 44,
		offer = { "We would like to study some ancient runes that were used by the lizard race. We suspect some relation of the lizards to the founders of Ankrahmun ...", "Somewhere under the ape infested city of Banuta, one can find dungeons that were once inhabited by lizards...", "Look there for an atypical structure that would rather fit to Ankrahmun and its Ankrahmun Tombs. Copy the runes you will find on this structure...", "Are you up to that challenge?" },
		accept = "Excellent! Here, take this tracing paper and use it on the object you will find there to create a copy of the ancient runes.",
		give = 4842,
		steps = {
			[42] = { remind = 42, tool = 4842, toolName = "tracing paper" },
			[43] = { ask = "Did you create a copy of the ancient runes as requested?", items = { 4843 }, next = 44, thanks = "It's a bit wrinkled but it will do. Thanks again.", missing = F.reports[26].missing },
		},
	},
}

-- TibiaWiki EN: Novice -> Journeyman -> Relic Hunter -> Explorer.
P.ranks = {
	{ base = 5, next = 26, promoted = "Journeyman", missions = { "ice", "butterfly", "plant" }, list = "The missions available for your rank are the {butterfly hunt}, {plant collection} and {ice delivery}." },
	{ base = 26, next = 35, promoted = "Relic Hunter", missions = { "urn", "bonelord", "powder" }, list = "The missions available for your rank are {lizard urn}, {bonelord secrets} and {orc powder}." },
	{ base = 35, next = 44, promoted = "Explorer", missions = { "poetry", "memory", "runes" }, list = "The missions available for your rank are {elven poetry}, {memory stone} and {rune writings}." },
}

for index, rank in ipairs(P.ranks) do
	for _, id in ipairs(rank.missions) do
		P.missions[id].rank = index
		P.missions[id].id = id
	end
end

local function rankOf(questLine)
	for index, rank in ipairs(P.ranks) do
		if questLine >= rank.base and questLine < rank.next then
			return index, rank
		end
	end
	return nil
end

local function missionFor(message)
	for _, id in ipairs({ "ice", "butterfly", "plant", "urn", "bonelord", "powder", "poetry", "memory", "runes" }) do
		if contains(message, P.missions[id].words) then
			return P.missions[id]
		end
	end
	return nil
end

local function rankDone(player, rank)
	for _, id in ipairs(rank.missions) do
		local m = P.missions[id]
		if player:getStorageValue(S()[m.key]) < m.done then
			return false
		end
	end
	return true
end

-- All three missions of the rank done: promotion (ours; the wikis only say you are promoted).
-- Returns the text (a second npcHandler:say would cancel the first, so the caller joins them).
local function promote(player, rank)
	if rankDone(player, rank) and player:getStorageValue(S().QuestLine) < rank.next then
		player:setStorageValue(S().QuestLine, rank.next)
		return "With that you have done all the missions of your rank. I hereby promote you to the rank of " .. rank.promoted .. "! Ask me for a {mission} whenever you are ready for more."
	end
	return nil
end

local function pendingKey(npcHandler, playerId)
	return tostring(npcHandler) .. ":" .. playerId
end

-- Answers the mission words of ranks I to III. Returns true when it answered
-- (the NPC's own dialogue is then skipped for this message).
function P.handle(npcHandler, npc, creature, message)
	local player = Player(creature)
	local playerId = player:getId()
	local ES = S()
	local say = function(text)
		npcHandler:say(text, npc, creature)
	end
	local questLine = player:getStorageValue(ES.QuestLine)
	local member = player:getStorageValue(ES.JoiningTheExplorers) >= 5 and questLine >= 5
	local rankIndex, rank = rankOf(questLine)
	local key = pendingKey(npcHandler, playerId)

	-- "yes"/"no" to one of our questions
	if npcHandler:getTopic(playerId) == P.TOPIC and (MsgContains(message, "yes") or MsgContains(message, "no")) then
		local pending = P.pending[key]
		P.pending[key] = nil
		npcHandler:setTopic(playerId, 0)
		if not pending then
			return false
		end
		local m = P.missions[pending.id]
		local yes = MsgContains(message, "yes")
		local state = player:getStorageValue(ES[m.key])
		if pending.kind == "offer" then
			if not yes then
				say("Come back when you are ready for the " .. m.name .. ".") -- ours
			elseif state < m.first then
				player:setStorageValue(ES[m.key], m.first)
				if m.door then
					player:setStorageValue(ES[m.door], 1)
				end
				if m.give then
					player:addItem(m.give, 1)
				end
				say(m.accept)
			end
			return true
		end
		local step = m.steps[state]
		if pending.kind == "ask" and step and step.ask then
			if not yes then
				if step.melts then
					say("Did it melt away?")
					P.pending[key] = { id = m.id, kind = "melted" }
					npcHandler:setTopic(playerId, P.TOPIC)
				else
					say("Come back when you have it.") -- ours
				end
				return true
			end
			local found = has(player, step.items)
			if found and player:removeItem(found, 1) then
				player:setStorageValue(ES[m.key], step.next)
				local promotion = promote(player, rank)
				say(promotion and { step.thanks, promotion } or step.thanks)
			elseif step.melts then
				say("You don't have the ice with you. Did it melt away?")
				P.pending[key] = { id = m.id, kind = "melted" }
				npcHandler:setTopic(playerId, P.TOPIC)
			else
				say(step.missing)
			end
			return true
		end
		if pending.kind == "melted" and state == 7 then
			if yes then
				player:setStorageValue(ES[m.key], 6)
				if player:getItemCount(4872) == 0 then
					player:addItem(4872, 1)
				end
				say("*Sigh* I think the time is right to grant you another chance to get that ice. Hurry up this time.")
			else
				say("Then bring me the ice and report about your {ice delivery}.") -- ours
			end
			return true
		end
		return true
	end

	if not member or not rank then
		return false
	end

	local m = missionFor(message)
	if m then
		local state = player:getStorageValue(ES[m.key])
		if m.rank < rankIndex or state >= m.done then
			say("You have already done that mission. Thank you again!")
		elseif m.rank > rankIndex then
			say("You can't do that mission yet. First finish the missions of your rank. " .. rank.list) -- ours
		elseif state < m.first then
			say(m.offer)
			P.pending[key] = { id = m.id, kind = "offer" }
			npcHandler:setTopic(playerId, P.TOPIC)
			return true
		else
			local step = m.steps[state]
			if not step then
				return false
			end
			if step.onlyWithItem and has(player, step.items) then
				-- Black Bert's powder before the chest (TibiaWiki BR: it is accepted)
				say(step.ask)
				P.pending[key] = { id = m.id, kind = "ask" }
				npcHandler:setTopic(playerId, P.TOPIC)
				return true
			elseif step.ask and not step.onlyWithItem then
				say(step.ask)
				P.pending[key] = { id = m.id, kind = "ask" }
				npcHandler:setTopic(playerId, P.TOPIC)
				return true
			elseif step.advance then
				player:setStorageValue(ES[m.key], step.next)
				player:addItem(step.give, 1)
				say(step.advance)
			elseif step.bought and player:getItemCount(step.bought[1]) > 0 then
				say(step.bought[2])
			elseif step.tool and player:getItemCount(step.tool) == 0 then
				player:addItem(step.tool, 1)
				say("You lost the " .. step.toolName .. "? Here, take another one. " .. F.reminders[step.remind]) -- ours
			else
				say(F.reminders[step.remind])
			end
		end
		npcHandler:setTopic(playerId, 0)
		return true
	end

	if MsgContains(message, "mission") then
		say(promote(player, rank) or rank.list)
		npcHandler:setTopic(playerId, 0)
		return true
	end
	return false
end

-- Wraps an NPC callback: our parallel missions first (ranks I to III), then
-- its own dialogue, then our answer if it said nothing.
function F.wrap(npcHandler, callback, base)
	local said = false
	local originalSay = npcHandler.say
	npcHandler.say = function(self, ...)
		said = true
		return originalSay(self, ...)
	end
	return function(npc, creature, msgType, message)
		if not Family.explorerSocietyAnswers and not F.parallelOn() then
			return callback(npc, creature, msgType, message)
		end
		local player = Player(creature)
		if not player or not npcHandler:checkInteraction(npc, creature) then
			return callback(npc, creature, msgType, message)
		end
		local ES = S()
		local topicBefore = npcHandler:getTopic(player:getId()) or 0
		local before = { ice = player:getStorageValue(ES.TheIceDelivery), dress = player:getStorageValue(ES.TheSpectralDress) }
		if F.parallelOn() and P.handle(npcHandler, npc, creature, message) then
			F.after(player, before)
			return true
		end
		said = false
		local result = callback(npc, creature, msgType, message)
		if not said and Family.explorerSocietyAnswers then
			F.fallback(npcHandler, npc, creature, message, topicBefore, base)
		end
		F.after(player, before)
		return result
	end
end
