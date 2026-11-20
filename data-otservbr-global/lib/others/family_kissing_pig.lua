-- Gaia Family server: Kissing a Pig Quest (2026-11-20). Ours, not upstream.
--
-- Asked by Rodrigo after The Thieves Guild review (its fourth way to Theodore Loveless' key needs
-- this quest). Canary v3.6.1 had all the NPCs on the map but no quest: the pig always gave the same
-- answer, Hoggle, Elvith, Lynda, Zebron, Budrik, the dwarven ghost and Toothless Tim knew nothing
-- about kissing, the doors and the Firlefanz chest had no rules.
--
-- Sources: TibiaWiki BR "Kissing a Pig Quest" (our backup, steps and transcripts) first, TibiaWiki EN
-- spoiler, NPC transcripts and item pages to complete it (Caramellia's and the Queen's lines, item
-- ids 170, 172-179, 229, 896, the ice cream's 2 minutes, the basin burning about 2 minutes, the dice
-- rules, Tim's line for women). Lines marked "ours" are on neither wiki.
--
-- The seven lessons, in any order (EN): Caramellia (Hoggle's lawn mowing first, then the Femor
-- Hills grass can be cut), Elvith (a perfect poem: blank poetry parchment from Olrik, an inkwell on
-- it three times after the first line), Lynda (Venorean ice cream from Boozer, melts in 2 minutes),
-- Zebron (three dice games won in a row, 25 gold lost per game lost), the dwarven ghost (5 picks to
-- Budrik for the Grothmok tunnel door, burn his fake beard in the lit coal basin of his Kazordoon
-- quarters), Toothless Tim (drunk: three alcoholic drinks), the Queen of the Banshees' kiss (the last
-- seal of The Queen of the Banshees Quest). The pig's answer follows the number of lessons (BR/EN
-- lines); with all seven: hearts, Passionate Kisser, the farm basement door opens, Firlefanz in the
-- chest there. Hoggle pays 5 gold.
--
-- Ours where no wiki says: the lawn-mowing square is one north and seven EAST of Hoggle's gate (EN
-- says west, where our map has his house); the poem steps succeed 2 times in 3 (a failed poem is
-- ruined, as the EN item pages say); Zebron's dice: you win only with a higher number; three drinks
-- count while you stay drunk (each drink 1 minute); the pig's answer with no lesson; the answers in
-- states the wikis do not show. Also Nothing Can Stop Me (EN: 100 uses of a machete on jungle grass
-- or wild growth), which no script gave. BR says the dwarven ghost may give Ghostwhisperer; EN does
-- not list him for it: not given.
--
-- The Thieves Guild, Mission 6, fourth way (BR): after this quest Bertram (women) or Chantalle (men)
-- give Theodore Loveless' key for a kiss (Bertram's lines BR, Chantalle's ours).
--
-- Files: this lib; scripts/family/kissing_pig.lua (doors, chests, inkwell, beard); FAMILY edits in
-- npc/ pig, hoggle, caramellia, elvith, olrik, lynda, zebron, budrik, a_dwarven_ghost, toothless_tim,
-- bertram, chantalle; scripts/lib/register_actions.lua (machete), scripts/quests/others/
-- actions_fire_bug.lua, scripts/actions/other/fluids.lua; storages 42232-42242
-- (Storage.Quest.U8_1.KissingAPig); quest log catalog/061_kissing_a_pig.lua (mission id 11274).
-- Switch: Family.kissingPig.

Family = Family or {}
Family.kissingPig = true

FamilyKissing = FamilyKissing or {}
local FK = FamilyKissing
local S = Storage.Quest.U8_1.KissingAPig
FK.S = S

FK.HOGGLE_GATE = Position(32542, 32143, 7)
FK.LAWN_SQUARE = Position(32549, 32142, 7) -- one north, seven east of the gate (ours, see above)
FK.FEMOR = { fromX = 32583, toX = 32596, fromY = 31786, toY = 31797, z = 4 } -- the tower's magic grass
FK.BASEMENT_DOOR = Position(32386, 32243, 8)
FK.FIRLEFANZ_CHEST = Position(32385, 32245, 8)
FK.GROTHMOK_DOOR = Position(32441, 31912, 12)
FK.BEARD_BOX = Position(32590, 31930, 5)
FK.COAL_BASIN = Position(32594, 31930, 5)

FK.FIRLEFANZ = 896
FK.BEARD = 170
FK.ICE_CREAM = 229
FK.PICK = 3456
FK.BLANK_POEM = 172
FK.POEM_DONE = 179
-- inkwell on a poem: { next on success, ruined } (EN item pages)
FK.POEM_STEPS = { [172] = { 173, 173 }, [173] = { 175, 174 }, [175] = { 177, 176 }, [177] = { 179, 178 } }
FK.poemChance = 67 -- percent per step after the first line (ours)
FK.basinSeconds = 120 -- the lit basin goes out (EN: about 2 minutes)
FK.drinksNeeded = 3

local function get(player, key)
	return math.max(-1, player:getStorageValue(key))
end
FK.get = get

local function samePos(a, b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end
FK.samePos = samePos

-- ----------------------------------------------------------------- lessons
function FK.lessons(player)
	local n = 0
	if get(player, S.Caramellia) >= 1 then n = n + 1 end
	if get(player, S.Elvith) >= 2 then n = n + 1 end
	if get(player, S.Lynda) >= 1 then n = n + 1 end
	if get(player, S.Zebron) >= 1 then n = n + 1 end
	if get(player, S.DwarvenGhost) >= 3 then n = n + 1 end
	if get(player, S.ToothlessTim) >= 1 then n = n + 1 end
	if get(player, Storage.Quest.U7_2.TheQueenOfTheBanshees.LastSeal) >= 1 then n = n + 1 end
	return n
end

function FK.finished(player)
	return get(player, S.Questline) >= 2
end

FK.pigLines = {
	[0] = "Uhh. Hm. That was ... well, wet. You still have to learn everything about kissing.", -- ours
	[1] = "Uhhh. Well, that was ... promising. But you are FAR from being the best kisser in the land.",
	[2] = "Mhmm. Nice try. You definitely have some experience but you should improve your skill DRASTICALLY.",
	[3] = "Mhmmm. Oh my, you have learnt a few tricks indeed. But it takes more to become the best kisser in the world. FAR more.",
	[4] = "Mhm Uhhh. Not bad, not bad at all! But you can still improve your skill a LOT.",
	[5] = "Ahhh. That was really nice. But you STILL lack the refinement of perfection.",
	[6] = "Mhm. Ahh. In ... incredible ... but ... I fear there's still something to learn for you.",
}
FK.pigFinal = {
	"Uhh. Ahh. Mhm. By the gods, you are really and truly the best kisser in the whole land. But ... I'm afraid I have to confess something ...",
	"There is no curse. I'm nothing than an ordinary pig that is able to speak by coincidence and loves to kiss. But your efforts shall not go unrewarded ...",
	"Of course I can't marry you - my mother would turn on her skewer. But I can tell you the hiding-place of some ancient sword ...",
	"Look in the basement of this farm. You should find a chest there containing the mighty Firlefanz.",
}
FK.pigAgain = "You really are the best kisser in the land, but I'm still just a pig. Look in the basement of this farm for the Firlefanz." -- ours

-- topics (high numbers: the NPC files use small ones)
local T = {
	PIG = 61, HOGGLE = 62, CARAMELLIA = 63, ELVITH = 64, LYNDA = 65, ZEBRON = 66, BUDRIK = 67,
	TIM1 = 68, TIM2 = 69, KEY1 = 70, KEY2 = 71, OLRIK = 72,
}
FK.T = T

local function addAchievement(player, name)
	if player.hasAchievement and player:hasAchievement(name) then
		return
	end
	if player.addAchievement then
		player:addAchievement(name)
	end
end
FK.addAchievement = addAchievement

-- ------------------------------------------------------------------ drinks
local function kvGet(player, key)
	local kv = player.kv and player:kv()
	if not kv then return nil end
	return kv:scoped("family-kissing-pig"):get(key)
end
local function kvSet(player, key, value)
	local kv = player.kv and player:kv()
	if kv then
		kv:scoped("family-kissing-pig"):set(key, value)
	end
end

-- called from scripts/actions/other/fluids.lua when an alcoholic drink makes the player drunk
function FK.onDrink(player)
	local now = os.time()
	local last = kvGet(player, "drinkTime") or 0
	local count = kvGet(player, "drinks") or 0
	if now - last > 60 then
		count = 0
	end
	kvSet(player, "drinks", count + 1)
	kvSet(player, "drinkTime", now)
end

function FK.isDrunk(player)
	if not player:getCondition(CONDITION_DRUNK) then
		return false
	end
	local last = kvGet(player, "drinkTime") or 0
	return os.time() - last <= 60 and (kvGet(player, "drinks") or 0) >= FK.drinksNeeded
end

-- ------------------------------------------------------------------ NPC talk
-- Returns true when the line was handled (the NPC file then skips its own keywords).
local handlers = {}

local function say(h, npc, creature, text)
	h:say(text, npc, creature)
end

handlers.pig = function(h, npc, player, msg)
	local id = player:getId()
	if MsgContains(msg, "kiss") then
		if FK.finished(player) then
			say(h, npc, player, FK.pigAgain)
			return true
		end
		say(h, npc, player, "Do you want to try to release me with a kiss?")
		h:setTopic(id, T.PIG)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.PIG then
		h:setTopic(id, 0)
		if get(player, S.Questline) < 1 then
			player:setStorageValue(S.Questline, 1)
		end
		local n = FK.lessons(player)
		if n >= 7 then
			player:setStorageValue(S.Questline, 2)
			player:setStorageValue(S.FirlefanzDoor, 1)
			addAchievement(player, "Passionate Kisser")
			if npc.getPosition then
				local pos = npc:getPosition()
				if pos and pos.sendMagicEffect then
					pos:sendMagicEffect(CONST_ME_HEARTS)
				end
			end
			say(h, npc, player, FK.pigFinal)
		else
			say(h, npc, player, FK.pigLines[n])
		end
		return true
	end
	return false
end

handlers.hoggle = function(h, npc, player, msg)
	local id = player:getId()
	local st = get(player, S.Hoggle)
	if MsgContains(msg, "garden") then
		if st < 1 then
			say(h, npc, player, {
				"My garden is full of wild-growing plants and my back is aching like hell. Perhaps you are interested in cutting these pest plants...",
				"I'll give you 5 shiny pieces of gold for this job. Is this a deal?",
			})
			h:setTopic(id, T.HOGGLE)
		elseif st == 1 then
			say(h, npc, player, "Tell me about the garden when you are finished.") -- ours
		elseif st == 2 then
			player:setStorageValue(S.Hoggle, 3)
			player:addMoney(5)
			say(h, npc, player, "I hope you were diligent and accurate. Here is your gold. Don't spend it on alcohol or tobacco!")
		else
			say(h, npc, player, "My garden looks fine now, thanks to you.") -- ours
		end
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.HOGGLE then
		h:setTopic(id, 0)
		player:setStorageValue(S.Hoggle, 1)
		say(h, npc, player, "Excellent. You will have to rattle at the garden gate a bit to get it open, it's quite old, you know. Tell me about the garden when you are finished.")
		return true
	elseif MsgContains(msg, "no") and h:getTopic(id) == T.HOGGLE then
		h:setTopic(id, 0)
		say(h, npc, player, "Too bad. My poor back...") -- ours
		return true
	end
	return false
end

handlers.caramellia = function(h, npc, player, msg)
	local id = player:getId()
	if MsgContains(msg, "true love never dies") then
		say(h, npc, player, "Those were his words, weren't they?")
		h:setTopic(id, T.CARAMELLIA)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.CARAMELLIA then
		h:setTopic(id, 0)
		player:setStorageValue(S.Caramellia, 1)
		say(h, npc, player, {
			"Yes, it's true, he is so right. As long as I remember the love and happiness we shared, neither love nor my beloved will be truly dead ...",
			"They will always have a special place in my heart. Thank you stranger, for reminding me about it. Know that life is like a kiss of lovers ...",
			"It's about sharing emotions and feelings, it's about knowing that you are not alone but belong to something greater, something more beautiful ...",
			"Keep this in mind and your life will improve and so will your kisses.",
		})
		return true
	end
	return false
end

handlers.elvith = function(h, npc, player, msg)
	local id = player:getId()
	local st = get(player, S.Elvith)
	if MsgContains(msg, "kiss") then
		if st >= 2 then
			say(h, npc, player, "I have already shared my little secrets with you.") -- ours
		else
			if st < 1 then
				player:setStorageValue(S.Elvith, 1)
			end
			say(h, npc, player, {
				"I will not share the secrets of kissing with someone not worthy. Impress me! Write a good love poem and then show it to me ...",
				"You can buy poetry parchment at the Thaian embassy. Use an inkwell on it to write a poem.",
			})
		end
		return true
	elseif MsgContains(msg, "poem") and not MsgContains(msg, "love poem") and st == 1 then
		say(h, npc, player, "Do you have a love poem that might impress me?")
		h:setTopic(id, T.ELVITH)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.ELVITH then
		h:setTopic(id, 0)
		if player:removeItem(FK.POEM_DONE, 1) then
			player:setStorageValue(S.Elvith, 2)
			say(h, npc, player, "You are a pure genius! You should really consider writing a few songs for me. It's a pleasure to share my little secrets with you. So listen <whisper> <whisper>.")
		else
			say(h, npc, player, "That is not a poem to impress anyone. Come back with a perfect one.") -- ours
		end
		return true
	end
	return false
end

handlers.olrik = function(h, npc, player, msg)
	local id = player:getId()
	if MsgContains(msg, "poetry parchment") then
		say(h, npc, player, "Do you want to buy a blank poetry parchment for 60 gold?") -- ours (BR: he sells it for 60)
		h:setTopic(id, T.OLRIK)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.OLRIK then
		h:setTopic(id, 0)
		if player:removeMoneyBank(60) then
			player:addItem(FK.BLANK_POEM, 1)
			say(h, npc, player, "Here you are. Use an inkwell on it to write your poem.") -- ours
		else
			say(h, npc, player, "You don't have enough money.") -- ours
		end
		return true
	end
	return false
end

handlers.lynda = function(h, npc, player, msg)
	local id = player:getId()
	if MsgContains(msg, "ice cream") and get(player, S.Lynda) < 1 and player:getItemCount(FK.ICE_CREAM) > 0 then
		say(h, npc, player, "Are you saying you have ... some Venorean ice cream for me???")
		h:setTopic(id, T.LYNDA)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.LYNDA then
		h:setTopic(id, 0)
		if player:removeItem(FK.ICE_CREAM, 1) then
			player:setStorageValue(S.Lynda, 1)
			say(h, npc, player, {
				"Oh, that is marvellous. Thank you very much. You know, I just LOVE ice cream! Of course it can't be compared to the love to the gods ...",
				"To truly love is pure happiness of heart and soul. <She tells you much about pure love and devotion. You learn a lot for life.>",
			})
		else
			say(h, npc, player, "Oh. It must have melted. What a pity.") -- ours
		end
		return true
	end
	return false
end

FK.zebronStreak = {}
handlers.zebron = function(h, npc, player, msg)
	local id = player:getId()
	local done = get(player, S.Zebron) >= 1
	if MsgContains(msg, "kiss") then
		if done then
			say(h, npc, player, "I've told you all my little secrets already. Care for a game instead?") -- ours
		else
			say(h, npc, player, "Ah, love is the most exciting game of all. I've learnt a few tricks of this game, too and I might share them with someone worthy.")
		end
		return true
	elseif MsgContains(msg, "worthy") and not done then
		say(h, npc, player, "If you want to learn my kissing secrets, you will have to beat me in a game of dice first! Your bet is 25 gold a game, beat me 3 times in a row and I will tell you all my little secrets. Are you interested?")
		h:setTopic(id, T.ZEBRON)
		FK.zebronStreak[id] = 0
		return true
	elseif h:getTopic(id) == T.ZEBRON and MsgContains(msg, "yes") then
		if player:getMoney() + player:getBankBalance() < 25 then
			h:setTopic(id, 0)
			say(h, npc, player, "You don't even have 25 gold to bet. Come back when you can pay.") -- ours
			return true
		end
		if npc.getPosition then
			local pos = npc:getPosition()
			if pos and pos.sendMagicEffect then
				pos:sendMagicEffect(CONST_ME_CRAPS)
			end
		end
		local mine, his = math.random(6), math.random(6)
		if FK.forceDice then
			mine, his = FK.forceDice()
		end
		if mine > his then
			local streak = (FK.zebronStreak[id] or 0) + 1
			FK.zebronStreak[id] = streak
			if streak >= 3 then
				h:setTopic(id, 0)
				FK.zebronStreak[id] = nil
				player:setStorageValue(S.Zebron, 1)
				say(h, npc, player, "You win with " .. mine .. " over " .. his .. ". I'm mildly impressed. You've beaten me 3 times in a row, so what? Oh well, now listen to my secrets: <whisper> <whisper> <whisper>. Interesting, isn't it?")
			else
				say(h, npc, player, "You win with " .. mine .. " over " .. his .. ". You'll keep your 25 gold this time. Are you ready for another game?")
			end
		else
			FK.zebronStreak[id] = 0
			player:removeMoneyBank(25)
			say(h, npc, player, "I win with " .. his .. " over " .. mine .. ". Your 25 gold are mine. Are you ready for another game?") -- ours
		end
		return true
	elseif h:getTopic(id) == T.ZEBRON and MsgContains(msg, "no") then
		h:setTopic(id, 0)
		FK.zebronStreak[id] = nil
		say(h, npc, player, "As you wish. Luck is a fickle lady anyway.") -- ours
		return true
	end
	return false
end

handlers.budrik = function(h, npc, player, msg)
	local id = player:getId()
	if (MsgContains(msg, "pick") or MsgContains(msg, "picks")) and get(player, S.Grothmok) < 1 then
		say(h, npc, player, "You brought the picks?")
		h:setTopic(id, T.BUDRIK)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.BUDRIK then
		h:setTopic(id, 0)
		if player:removeItem(FK.PICK, 5) then
			player:setStorageValue(S.Grothmok, 1)
			say(h, npc, player, "Not the best craftsmanship but they'll do. As promised I grant you permission to enter the Grothmok tunnels. Good luck.")
		else
			say(h, npc, player, "Bring me 5 picks and I'll let you into the Grothmok tunnels.") -- ours
		end
		return true
	end
	return false
end

handlers.ghost = function(h, npc, player, msg)
	local st = get(player, S.DwarvenGhost)
	if MsgContains(msg, "kiss") then
		if st >= 3 then
			say(h, npc, player, "You already know as much about kissing as I did during my lifetime, mortal.") -- ours
		else
			say(h, npc, player, {
				"My secrets about kissing have died with me. I alone know them, so they are well kept ... But ... thinking about it ...",
				"Not all of my secrets are really well kept. There is one thing you could do for me, mortal. One favour by you to gain a favour of me.",
			})
		end
		return true
	elseif MsgContains(msg, "favour") and st < 2 then
		player:setStorageValue(S.DwarvenGhost, 1)
		say(h, npc, player, {
			"I don't want the legend about myself to be ruined. Therefore, I need you to do something for me. Go to my quarters in Kazordoon ...",
			"In my drawer you will find ... a false beard ... don't ask any questions mortal! Light the coal basin in my chambers and burn the damned beard in it ...",
			"If you are done, forget that you have ever entered my quarters. Come here and I will tell you what you want to know!",
		})
		return true
	elseif MsgContains(msg, "beard") then
		if st == 2 then
			player:setStorageValue(S.DwarvenGhost, 3)
			say(h, npc, player, {
				"Indeed, you have served me well. Now my legend is preserved once and for all. I will grant you the knowledge that you are seeking. Hereby, I pass a portion of my knowledge to your mind ...",
				"Ahhh, it's done. Now you know as much about kissing as I did during my lifetime.",
			})
		elseif st == 1 then
			say(h, npc, player, "The beard still exists, mortal. Burn it in the coal basin of my quarters!") -- ours
		else
			return false
		end
		return true
	end
	return false
end

handlers.tim = function(h, npc, player, msg)
	if not FK.isDrunk(player) then
		return false
	end
	local id = player:getId()
	if MsgContains(msg, "kiss") then
		say(h, npc, player, "Ah, the joyous art of kissing is a sophisticated thing indeed. In my youth I enjoyed the delights of kissing with a few fine ladies. Would you like to learn more about kissing?")
		h:setTopic(id, T.TIM1)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.TIM1 then
		say(h, npc, player, "I could tell you much about kissing but I rather show you how to kiss properly. Are you prepared?")
		h:setTopic(id, T.TIM2)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.TIM2 then
		h:setTopic(id, 0)
		player:setStorageValue(S.ToothlessTim, 1)
		if player:getSex() == PLAYERSEX_FEMALE then
			say(h, npc, player, "Mhmmmm. It's been a while since I kissed a lady.")
		else
			say(h, npc, player, "Mhmmmm. You don't kiss bad for a guy.")
		end
		return true
	end
	return false
end

-- The Thieves Guild, Mission 6, fourth way: a kiss for Theodore Loveless' key.
local function keyKiss(h, npc, player, msg, female, word)
	local id = player:getId()
	local TG = Storage.Quest.U8_2.TheThievesGuildQuest
	local right = get(player, TG.Mission06) == 1 and FK.finished(player) and ((player:getSex() == PLAYERSEX_FEMALE) == female)
	if MsgContains(msg, "kiss") and right then
		say(h, npc, player, "Oh, I've heard you are the " .. word .. " of kisses, is that true???")
		h:setTopic(id, T.KEY1)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.KEY1 then
		say(h, npc, player, "Hmmm. If it's true, I'd give you the key you are looking for in exchange for a kiss! Are you interested?")
		h:setTopic(id, T.KEY2)
		return true
	elseif MsgContains(msg, "yes") and h:getTopic(id) == T.KEY2 then
		h:setTopic(id, 0)
		if right then
			player:addItem(7934, 1)
			player:setStorageValue(TG.Mission06, 2)
			say(h, npc, player, "Ohhhh! Th .. Thank you! Here is .. your key!")
		end
		return true
	end
	return false
end
handlers.bertram = function(h, npc, player, msg)
	return keyKiss(h, npc, player, msg, true, "queen") -- BR
end
handlers.chantalle = function(h, npc, player, msg)
	return keyKiss(h, npc, player, msg, false, "king") -- ours, as Bertram's
end

-- From an NPC file's npcType.onSay, before npcHandler:onSay.
function FK.onSay(name, npcHandler, npc, creature, message, msgtype)
	if not Family.kissingPig then
		return false
	end
	local player = Player(creature)
	if not player or not npcHandler:checkInteraction(npc, creature) then
		return false
	end
	if msgtype and TALKTYPE_PRIVATE_PN and msgtype ~= TALKTYPE_PRIVATE_PN then
		return false -- as the NPC library: while talking, only the NPC channel counts
	end
	local handler = handlers[name]
	if not handler then
		return false
	end
	local handled = handler(npcHandler, npc, player, message)
	if handled and npcHandler.setTalkStart then
		npcHandler:setTalkStart(player:getId(), os.time())
	end
	return handled
end

-- Toothless Tim: understandable only when drunk (greeting and farewell).
FK.timDrunkGreet = "Greetings my friend. What a splendid day we have, don't you agree."
FK.timSoberGreet = "Hmmmhh ... grbl ... nnhh?" -- ours
FK.timFarewell = "Good bye my friend. It was a pleasure to have a conversation with you."

-- ------------------------------------------------------------ world objects
function FK.inFemor(pos)
	local f = FK.FEMOR
	return pos.z == f.z and pos.x >= f.fromX and pos.x <= f.toX and pos.y >= f.fromY and pos.y <= f.toY
end

-- From onUseMachete (scripts/lib/register_actions.lua). Returns true when the use is finished here.
FK.cutGrass = { [3696] = true, [3702] = true, [17153] = true, [2130] = true, [3635] = true, [30224] = true }
function FK.onMachete(player, target, toPosition)
	if not Family.kissingPig or not target or not target.itemid then
		return false
	end
	if target.itemid == 3696 and FK.inFemor(toPosition) and get(player, S.Hoggle) < 2 then
		toPosition:sendMagicEffect(CONST_ME_POFF)
		player:sendTextMessage(MESSAGE_FAILURE, "The grass grows back as fast as you can cut it.") -- ours (EN: "grows as fast as you can cut it")
		return true
	end
	if target.itemid == 3696 and samePos(toPosition, FK.LAWN_SQUARE) and get(player, S.Hoggle) == 1 then
		player:setStorageValue(S.Hoggle, 2)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You advanced in lawn mowing.")
	end
	if FK.cutGrass[target.itemid] then
		local cuts = (kvGet(player, "machete") or 0) + 1
		kvSet(player, "machete", cuts)
		if cuts >= 100 then
			addAchievement(player, "Nothing Can Stop Me")
		end
	end
	return false
end

-- From actions_fire_bug.lua: the coal basin in the dwarven ghost's quarters always lights.
function FK.onFireBug(player, target, toPosition)
	if not Family.kissingPig or not target or not target.itemid or not samePos(toPosition, FK.COAL_BASIN) then
		return false
	end
	if target.itemid ~= 2114 then
		return true
	end
	target:transform(2113)
	toPosition:sendMagicEffect(CONST_ME_HITBYFIRE)
	addEvent(function(pos)
		local tile = Tile(pos)
		local lit = tile and tile:getItemById(2113)
		if lit then
			lit:transform(2114)
		end
	end, FK.basinSeconds * 1000, FK.COAL_BASIN)
	return true
end
