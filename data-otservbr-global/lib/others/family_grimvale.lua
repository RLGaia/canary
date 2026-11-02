-- Gaia Family server: Grimvale Quest, mission "The Curse Spreads" (2026-10-28).
-- Ours, not upstream: upstream has the monsters, items and map, but no
-- mission (no dialogue, no storages), and the five were-beast leaders could be
-- fought by anyone. World objects and events: scripts/family/curse_spreads.lua.
--
-- Story as in Tibia (TibiaWiki EN "Grimvale Quest/Spoiler"; NPC lines from
-- the TibiaWiki BR transcripts, checked 2026-11-01):
--   0 Maeryn (Grimvale) `the curse spreads`, `yes`         -> talk to Daniel
--   1 Daniel Steelsoul (Edron castle) asks for help         -> talk to Milos
--   2 Milos (academy, NW tower +4): find his four notes
--   3 Milos gets the notes: crimson nightshade blossoms and the ley line
--     tablet; brew the nightshade distillate at the apparatus in Sinclair's
--     lab (blossoms, silver dust, gold dust, shadow bite berries)
--   4 Daniel takes the potion                              -> Yoem on Cormaya
--   5 Yoem: investigate the water. The Mystic Flame into the Last Sanctum
--     lets in only those who did the Moonshadow ritual (the V of white tiles
--     in the Grimvale ruins); both wikis, fixed 2026-11-01
--   6 the tainted basin found in the Last Sanctum           -> Yoem
--   7 Yoem                                                 -> Milos
--   8 Milos gives the golden symbol of Suon: lift the curse from the dark
--     stone totems (Krailos, Banuta, Vengoth)
--   9 the basin is clean                                    -> Yoem
--  10 Yoem                                                 -> Daniel
--  11 Daniel: kill Bloodback, Darkfang, Sharpclaw, Shadowpelt, Black Vixen
--  12 Daniel gives the foxtail amulet; the death portals carry you
-- Lines marked "ours" in the code are not from the wiki transcripts (the wiki
-- has none for those moments).
-- Switch: Family.curseSpreads (false = the leaders' gates open for everyone
-- again and the NPCs say nothing about the curse).

Family = Family or {}
Family.curseSpreads = true

FamilyCurseSpreads = {}
local C = FamilyCurseSpreads
local S = Storage.Quest.FamilyCurseSpreads

C.items = {
	goldParchment = 27372,
	silverParchment = 27371,
	shadowParchment = 27443,
	scribbledNote = 27370,
	blossoms = 27465,
	tablet = 27464,
	goldNuggets = 27444,
	silverNuggets = 27445,
	goldDust = 27446,
	silverDust = 27447,
	berries = 27460,
	distillate = 27461,
	symbol = 27499,
	amulet = 27565,
}

C.notes = { -- bit in S.Notes
	{ bit = 1, item = 27372 },
	{ bit = 2, item = 27371 },
	{ bit = 4, item = 27443 },
	{ bit = 8, item = 27370 },
}

C.totems = {
	{ bit = 1, name = "Krailos", pos = Position(33680, 31630, 7) },
	{ bit = 2, name = "Banuta", pos = Position(32809, 32587, 7) },
	{ bit = 4, name = "Vengoth", pos = Position(32949, 31489, 6) },
}

C.leaders = {
	{ bit = 1, name = "Bloodback", where = "underneath Edron" },
	{ bit = 2, name = "Darkfang", where = "underneath Edron" },
	{ bit = 4, name = "Sharpclaw", where = "underneath Edron" },
	{ bit = 8, name = "Shadowpelt", where = "underneath Cormaya" },
	{ bit = 16, name = "Black Vixen", where = "underneath Cormaya" },
}

local function get(player, key)
	return math.max(0, player:getStorageValue(key))
end

function C.state(player)
	return get(player, S.Mission)
end

function C.setState(player, value)
	player:setStorageValue(S.Mission, value)
	if FamilyGrimvaleStart then
		FamilyGrimvaleStart(player)
	end
end

local function hasBit(value, bit)
	return math.floor(value / bit) % 2 == 1
end
C.hasBit = hasBit

function C.addBit(player, key, bit)
	local value = get(player, key)
	if not hasBit(value, bit) then
		player:setStorageValue(key, value + bit)
		return true
	end
	return false
end

function C.allTotems(player)
	return get(player, S.Totems) == 7
end

function C.allLeaders(player)
	return get(player, S.Leaders) == 31
end

function C.canFightLeaders(player)
	return not Family.curseSpreads or C.state(player) >= 11
end

local function joinNames(list)
	if #list <= 1 then
		return list[1] or ""
	end
	return table.concat(list, ", ", 1, #list - 1) .. " and " .. list[#list]
end

function C.missingLeaders(player)
	local value, names = get(player, S.Leaders), {}
	for _, leader in ipairs(C.leaders) do
		if not hasBit(value, leader.bit) then
			names[#names + 1] = leader.name
		end
	end
	return names
end

function C.missingTotems(player)
	local value, names = get(player, S.Totems), {}
	for _, totem in ipairs(C.totems) do
		if not hasBit(value, totem.bit) then
			names[#names + 1] = totem.name
		end
	end
	return names
end

-- Quest log text (ours, after the wiki walkthrough)
function C.describe(player)
	local state = C.state(player)
	if state == 1 then
		return "Daniel Steelsoul told you about the Curse of the Full Moon that reached Edron. The purple nightshade cures only the people outside the town. Ask the mages of the Magic Academy of Edron about the curse - Milos, in the north-western tower, might know more."
	elseif state == 2 then
		local found = 0
		for _, note in ipairs(C.notes) do
			if hasBit(get(player, S.Notes), note.bit) then
				found = found + 1
			end
		end
		return string.format("Milos thinks a ley line crossing Edron weakens the purple nightshade. Find his four old notes and bring them to him: three pieces of parchment in the bookcases of the library in the academy's central tower (one on floor +4, two on floor +3) and a hastily scribbled note in a box next to Puffels, in the cellar of the south tower. Notes found: %d of 4.", found)
	elseif state == 3 then
		return "Milos gave you crimson nightshade blossoms and a stone tablet with ley lines. Following his notes, you also need shadow bite berries (from the shadow bite plants underneath Edron), gold dust and silver dust (grind gold and silver nuggets from the Corym mines on the wooden grinder two floors below Milos). Then use the blossoms, the silver dust, the gold dust and the berries, in this order, on the apparatus in Sinclair's laboratory and bring the potion to Daniel Steelsoul."
	elseif state == 4 then
		return "Daniel Steelsoul has the potion for Edron's citizens. The curse also reached Cormaya: talk to Yoem there about the curse."
	elseif state == 5 then
		if get(player, S.Ritual) >= 1 then
			return "Yoem thinks the ground water of Cormaya is tainted. Search the Last Sanctum, behind the Mystic Flame at the end of the tunnels in the east of Cormaya, for the place where the water gets tainted: follow the cave to the south-west and go down."
		end
		return "Yoem thinks the ground water of Cormaya is tainted. Search the Last Sanctum, behind the Mystic Flame at the end of the tunnels in the east of Cormaya, for the place where the water gets tainted. The flame lets in only those who proved worthy in the Moonshadow Temple: in the ruins deep underneath Grimvale (Cornell in Edron brings you there) form a V with the white tiles using the levers, then pull any lever."
	elseif state == 6 then
		return "In the Last Sanctum you found the basin where Cormaya's water gets tainted. Tell Yoem about it."
	elseif state == 7 then
		return "Yoem asked you to find help at the Magic Academy of Edron. Tell Milos about the curse and your discovery."
	elseif state == 8 then
		local missing = C.missingTotems(player)
		if #missing == 0 then
			return "You removed the curse from all three dark stone totems. Go back to the basin in the Last Sanctum and see whether the water stays clean."
		end
		return string.format("Milos gave you his golden symbol of Suon. Use it on the dark stone totems at the sources of the three ley lines that meet underneath Cormaya. Still cursed: %s.", joinNames(missing))
	elseif state == 9 then
		return "The water in the Last Sanctum stays clean now. Tell Yoem about it."
	elseif state == 10 then
		return "Yoem thanked you. Return to Daniel Steelsoul in Edron and tell him about the curse."
	elseif state == 11 then
		local missing = C.missingLeaders(player)
		if #missing == 0 then
			return "You defeated all five were-beast leaders. Report to Daniel Steelsoul."
		end
		return string.format("Daniel Steelsoul asked you to defeat the five were-beast leaders behind the magical gates in the caves underneath Edron and Cormaya. Still alive: %s.", joinNames(missing))
	elseif state >= 12 then
		return "You helped Edron and Cormaya against the Curse of the Full Moon. Daniel Steelsoul gave you a foxtail amulet, and the death portals between the caves underneath Edron and the Last Sanctum carry you now. The were-beast leaders can be challenged again."
	end
	return "Talk to Daniel Steelsoul in Edron about the curse."
end

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
end

local TOPIC_HELP = 300

local daniel = {}
function daniel.curse(npc, creature, player, npcHandler)
	local state = C.state(player)
	if state < 1 then
		say(npcHandler, npc, creature, {
			"Yes, recently we have a major problem here on Edron. Strange proceedings are troubling me as well as the common citizens. With each full moon, monsters are roaming the woods - monsters that we only knew from tales until now. ...",
			"They look like badgers and foxes who are transforming into humans. Unfortunately, it's the other way round: Peaceful citizens transform into feral beasts as soon as the moon is full. ...",
			"Some hunters even claim that they have spotted monstrous humanoid boars, wolves and bears. I know what is going on on {Grimvale} so I sent a messenger to {Maeryn}. She confirmed what I already feared: Those creatures are were-beasts. ...",
			"The so-called Curse of the Full Moon is spreading and reached Edron. I asked Maeryn for help but she has plenty of trouble on Grimvale and can't leave the island. ...",
			"Do you know something about this curse and - even more important - would you be willing to help us?",
		})
		npcHandler:setTopic(player:getId(), TOPIC_HELP)
	elseif state <= 2 then
		say(npcHandler, npc, creature, "I'm neither a sage nor a magician. Please pay a visit to the Magic Academy of Edron. Perhaps one of the mages there can help you.")
	elseif state == 3 then
		-- ours
		say(npcHandler, npc, creature, "Did Master Milos find a way to help the people in town? Bring me the {potion} as soon as it is ready.")
	elseif state <= 9 then
		-- ours
		say(npcHandler, npc, creature, "The potion works! But please help Yoem on Cormaya, the curse must not spread any further.")
	elseif state == 10 then
		say(npcHandler, npc, creature, {
			"I'm very happy that you could help the people of Cormaya. May Banor bless you. But I have one last request: The were-beasts are led by alpha leaders. ...",
			"Please seek out the subterranean caves of the lycanthropes on Edron and Cormaya and kill the alpha leader of each kind of were-beast, five altogether. This should weaken them enough to hold them at bay for quite a while.",
		})
		C.setState(player, 11)
	elseif state == 11 then
		local missing = C.missingLeaders(player)
		if #missing > 0 then
			-- ours
			say(npcHandler, npc, creature, string.format("The curse will keep spreading as long as its leaders are alive. Still to defeat: %s.", joinNames(missing)))
			return
		end
		say(npcHandler, npc, creature, {
			"You defeated the five alpha leaders! Well done, this should weaken them enough to hold them at bay for quite a while. Please take this pendant in return, it may be of use for you. ...",
			"The were-sickness won't disappear completely but it will be easier for us now. At least I hope so! Yesterday a travelling salesman told me that he spotted a feral creature in the Darama desert that looked like half man and half lion. ...",
			"Banor grant that this is just unfounded gossip and that the curse didn't spread further. Well, I guess, we will find out soon. Edron, for the time being, is a safer place now, thanks to you.",
		})
		player:addItem(C.items.amulet, 1)
		C.setState(player, 12)
		FamilyGrimvaleOverTheMoon(player)
	else
		-- ours
		say(npcHandler, npc, creature, "Thanks to you the curse is under control, at least for now. PRAISE TO BANOR!")
	end
end

function daniel.yes(npc, creature, player, npcHandler)
	say(npcHandler, npc, creature, {
		"I'm very relieved to hear that. The most important thing right now is to cure the curse of as many affected people as possible. Maeryn already told me that the purple nightshade is able to revert the effects of lycanthropy. ...",
		"We tried this but it worked only partially. Strangely, we were able to cure the people living outside the town in the more rural parts of Edron. But there are also some affected people in the town itself and the nightshade doesn't have any effect. ...",
		"I'm neither a sage nor a magician. But I'm the one who is supposed to find a solution for this problem. Please pay a visit to the Magic Academy of Edron. Perhaps one of the mages there can help you.",
	})
	if C.state(player) < 1 then
		C.setState(player, 1)
	end
	npcHandler:setTopic(player:getId(), 0)
end

function daniel.potion(npc, creature, player, npcHandler)
	local state = C.state(player)
	if state ~= 3 then
		return false
	end
	if not player:removeItem(C.items.distillate, 1) then
		-- ours
		say(npcHandler, npc, creature, "Bring me the potion as soon as you have brewed it.")
		return true
	end
	say(npcHandler, npc, creature, {
		"You did a great job! I really have hope that this potion may cure the infected people here in town. At least I have trust in Master Milos' experience. But there's another problem: Cormaya. ...",
		"The curse reached {Cormaya}, too. Please go there and talk to {Yoem}.",
	})
	C.setState(player, 4)
	return true
end

local milos = {}
function milos.curse(npc, creature, player, npcHandler)
	local state = C.state(player)
	if state < 1 then
		-- ours
		say(npcHandler, npc, creature, "The curse? I've heard rumours. Daniel Steelsoul is the one dealing with it, as far as I know.")
	elseif state == 2 and milos.hasNotes(player) then
		milos.deliverNotes(npc, creature, player, npcHandler)
	elseif state == 1 or state == 2 then
		say(npcHandler, npc, creature, {
			"I heard about this problem. It is, indeed, very strange that only the people who live inside the town cannot be healed by purple nightshade blossoms. But I have a theory: I have done some research on {ley} lines. ...",
			"You could call them ancient, straight 'paths' in the landscape which have spiritual and arcane significance. This means, on a ley line spells could be enhanced or weakened, potions or artefacts might work differently than expected. ...",
			"One of those ley lines is crossing the town of Edron and I heavily suppose that this is the reason why the purple nightshade doesn't suffice to cure the curse. You have to find a way to potentiate the purple nightshade's efficacy. ...",
			"I once did some research on the question 'How to increase the potency of herbal substances'. If you find my old {notes} they might help you.",
		})
		C.setState(player, 2)
	elseif state == 3 then
		say(npcHandler, npc, creature, {
			"Now you can brew a potion that might cure the ley line enhanced form of the curse. You have to distil the crimson nightshade first. You can use the alchemical devices in Sinclair's laboratory, here in the Academy. ...",
			"Then you have to add the silver and gold powder, in this order! At last you add the Shadow Bite Berries.",
		})
	elseif state <= 6 then
		-- ours
		say(npcHandler, npc, creature, "Did the potion work? I'm really curious whether my ley line theory holds.")
	elseif state == 7 then
		say(npcHandler, npc, creature, {
			"This is a very interesting discovery! Somehow, the lycanthropes created tainted statues at the terminal points of the three ley lines intersecting underneath Cormaya. But the most powerful point of a ley line is its point of origin. ...",
			"Thus I assume that there is a second statue at the source of each ley line. Those statues cause the evil that is tainting Cormaya's ground water. You have to travel along the three ley lines to find the source of each one. ...",
			"Use the map I gave you earlier. It shows the point of origin of each listed ley line. If you reach those points I'm sure you will discover statues there, similar to those in the temple underneath Cormaya. ...",
			"As it is a curse related to the moon, you will need a sun artefact to reverse it. A holy symbol of Suon should serve this purpose. Here, take mine for this mission.",
		})
		player:addItem(C.items.symbol, 1)
		C.setState(player, 8)
	elseif state == 8 then
		local missing = C.missingTotems(player)
		if #missing > 0 then
			-- ours
			say(npcHandler, npc, creature, string.format("Use the symbol of Suon on the statues at the sources of the ley lines. My tablet shows them: %s.", joinNames(missing)))
		else
			-- ours
			say(npcHandler, npc, creature, "All three sources are cleansed? Then look at the water underneath Cormaya once more.")
		end
	else
		-- ours
		say(npcHandler, npc, creature, "Fascinating, truly fascinating. The ley lines are clean again. I must write this down... where did I put my quill?")
	end
end

function milos.hasNotes(player)
	for _, note in ipairs(C.notes) do
		if player:getItemCount(note.item) < 1 then
			return false
		end
	end
	return true
end

function milos.notes(npc, creature, player, npcHandler)
	local state = C.state(player)
	if state ~= 2 then
		return false
	end
	if not milos.hasNotes(player) then
		-- ours
		say(npcHandler, npc, creature, "I wrote my notes on three pieces of parchment and a hastily scribbled note. The parchments must be in the library of the central tower, in the bookcases on the third and fourth floors. And the note... I think I left it in a box next to Puffels, down in the cellar of the south tower. Bring me all four.")
		return true
	end
	return milos.deliverNotes(npc, creature, player, npcHandler)
end

-- TibiaWiki BR: with the four notes, `the curse spreads` (or `notes`) hands them over
function milos.deliverNotes(npc, creature, player, npcHandler)
	for _, note in ipairs(C.notes) do
		player:removeItem(note.item, 1)
	end
	say(npcHandler, npc, creature, {
		"You discovered my notes! Well done! If you find the recommended {ingredients} you can brew a potion that might cure the ley line enhanced form of the curse. ...",
		"But as basic ingredient you need a special kind of nightshade. Not the purple but the {crimson} one. It is even rarer than the purple nightshade but Maeryn sent me one sample from Grimvale. Here, take it and put it to good use. ...",
		"In addition, take this ancient inscription. It is a map of some of the known Tibian ley lines. Perhaps it can be of use for you.",
	})
	player:addItem(C.items.blossoms, 1)
	player:addItem(C.items.tablet, 1)
	C.setState(player, 3)
	return true
end

local yoem = {}
function yoem.curse(npc, creature, player, npcHandler)
	local state = C.state(player)
	if state < 4 then
		-- ours
		say(npcHandler, npc, creature, "The curse? Daniel Steelsoul in Edron knows more about it than I do.")
	elseif state == 4 then
		say(npcHandler, npc, creature, {
			"Yes, the Curse of the Full Moon has reached Cormaya, too. More and more people are affected but something is really strange: Some of them weren't bitten by were-beasts. So far we thought this is the only way to be infected. ...",
			"But now it's obvious that there has to be another way. If you ask me: I guess it's the ground water. Someone has to enter the caverns underneath Cormaya and investigate. ...",
			"In the east of the island there are tunnels where we often spot were-beasts at night. Perhaps you should start there.",
		})
		C.setState(player, 5)
	elseif state == 5 then
		-- ours
		say(npcHandler, npc, creature, "In the east of the island there are tunnels where we often spot were-beasts at night. Perhaps you should start there.")
	elseif state == 6 then
		say(npcHandler, npc, creature, "So I was right, it is the ground water! Please try to reverse this contamination. Unfortunately, I don't know anything about magic or arcane matters. But you could ask somebody at the Magic Academy of Edron.")
		C.setState(player, 7)
	elseif state <= 8 then
		say(npcHandler, npc, creature, "Unfortunately, I don't know anything about magic or arcane matters. But you could ask somebody at the Magic Academy of Edron.")
	elseif state == 9 then
		say(npcHandler, npc, creature, "You succeeded! Thank you very much for your help, my friend. Please return to Edron and tell Daniel Steelsoul about it, he will be interested in this outcome, too.")
		C.setState(player, 10)
	else
		-- ours
		say(npcHandler, npc, creature, "Thanks to you, Cormaya's water is clean again. Thank you, my friend!")
	end
end

-- Maeryn (Grimvale) starts the mission in TibiaWiki BR: `the curse spreads`, `yes`.
-- She only sends you to Daniel Steelsoul, who starts the quest log.
local TOPIC_MAERYN = 302
local function maerynSay(npc, creature, player, message, npcHandler)
	if npcHandler:getTopic(player:getId()) == TOPIC_MAERYN then
		npcHandler:setTopic(player:getId(), 0)
		if MsgContains(message, "yes") then
			say(npcHandler, npc, creature, "Thank you so much! Please travel to Edron and talk to Daniel Steelsoul. I'm sure he can tell you more about the spreading of the curse.")
			return true
		elseif MsgContains(message, "no") then
			say(npcHandler, npc, creature, "I understand. Should you change your mind, Edron needs every help it can get.") -- ours
			return true
		end
	end
	if not MsgContains(message, "spreads") then
		return false
	end
	if C.state(player) >= 1 then
		-- ours
		say(npcHandler, npc, creature, "Daniel Steelsoul told me you are helping Edron and Cormaya against the curse. Thank you, my friend.")
		return true
	end
	say(npcHandler, npc, creature, {
		"We tried to prevent this really hard. Cornell won't ferry anyone affected by the curse back to Edron. But somehow one or more cursed people must have slipped through the cracks. Now the curse reached Edron, maybe even Cormaya! ...",
		"This is a catastrophe. I'm sure they need help in Edron but I can't leave Grimvale. The curse is very strong here and my people need me. Would you be willing to travel to Edron and aid them there?",
	})
	npcHandler:setTopic(player:getId(), TOPIC_MAERYN)
	return true
end

-- Achievement "Over the Moon" (TibiaWiki BR): The Curse of the Full Moon and
-- The Curse Spreads both done. Called when either of them is completed.
function FamilyGrimvaleOverTheMoon(player)
	local spreads = C.state(player) >= 12
	local fullMoon = FamilyFullMoon and FamilyFullMoon.state(player) >= 3
	if spreads and fullMoon and not player:hasAchievement("Over the Moon") then
		player:addAchievement("Over the Moon")
	end
end

-- Called from the NPCs' default message callback. Returns true when handled.
function C.onSay(who, npc, creature, player, message, npcHandler)
	if not Family.curseSpreads then
		return false
	end
	if who == "daniel" then
		if npcHandler:getTopic(player:getId()) == TOPIC_HELP then
			if MsgContains(message, "yes") then
				daniel.yes(npc, creature, player, npcHandler)
				return true
			elseif MsgContains(message, "no") then
				say(npcHandler, npc, creature, "That's a pity. Come back if you change your mind.") -- ours
				npcHandler:setTopic(player:getId(), 0)
				return true
			end
		end
		if MsgContains(message, "curse") then
			daniel.curse(npc, creature, player, npcHandler)
			return true
		elseif MsgContains(message, "potion") then
			return daniel.potion(npc, creature, player, npcHandler)
		end
	elseif who == "milos" then
		if MsgContains(message, "curse") then
			milos.curse(npc, creature, player, npcHandler)
			return true
		elseif MsgContains(message, "notes") then
			return milos.notes(npc, creature, player, npcHandler)
		elseif MsgContains(message, "ley") then
			say(npcHandler, npc, creature, {
				"Most Tibian cultures have some knowledge about those straight lines that run across the landscape, connecting both, natural and sacred sites. Some also call them 'fairy paths' or 'spirit lines'. ...",
				"As far as I know, in Zao they are called 'dragon lines'. Markers connecting the ley lines can be mounds, cairns, standing stones, stone circles, ponds, wells, shrines, temples or cross-roads.",
			})
			return true
		elseif MsgContains(message, "ingredients") and C.state(player) >= 3 then
			say(npcHandler, npc, creature, "Just have a look at my notes. The required components are listed there.")
			return true
		elseif MsgContains(message, "crimson") and C.state(player) >= 3 then
			say(npcHandler, npc, creature, {
				"This is a very rare subspecies of the purple nightshade. It grows exclusively on the small island Grimvale, and even there it is anything but common. In fact, it is so rare, it didn't even have a scientific name as of yet. ...",
				"So, with becoming modesty, I called it 'solanacea coccinea'.",
			})
			return true
		elseif MsgContains(message, "distracted") then
			-- ours
			say(npcHandler, npc, creature, "Oh, I'm pondering the strangest theory about the paths of magical energy through our world. Never mind.")
			return true
		end
	elseif who == "maeryn" then
		return maerynSay(npc, creature, player, message, npcHandler)
	elseif who == "yoem" then
		if MsgContains(message, "curse") then
			yoem.curse(npc, creature, player, npcHandler)
			return true
		end
	end
	return false
end
