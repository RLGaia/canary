-- Gaia Family server: Isle of the Kings, the monastery's restricted floors (2026-11-16).
--
-- Ours, not upstream. Asked by Rodrigo after The White Raven Monastery review: "let's make it, to
-- be more accurate". Upstream had none of it: the bookcase in Costello's office was empty, the
-- locked door to the upper floors had no key number (nobody could open it), the monks' floors had
-- no monks and nobody cared about intruders.
--
-- As in Tibia (TibiaWiki BR backup: Key 3350, Monastery Intruders (Book), Isle of the Kings,
-- Captain Jack, Costello; TibiaWiki EN: Isle of the Kings, Key 3350, Costello/Transcripts,
-- Captain Jack):
--   * the bookcase next to Costello (32180,31934,7) gives once per character a bag with Costello's
--     note "Monastery Intruders" and Key 3350;
--   * Key 3350 opens the locked door on the library floor (32178,31928,6) that leads to the stairs
--     up to the monks' floors;
--   * whoever goes through it (the stair room behind the door, 32177-32180,31925-31927,6) is a
--     trespasser: Captain Jack will not sail him back ("By the gods! ..."), Dalbrect will not sail
--     him to the isle, and Costello greets him with "WHAT? You have to be that trespasser..." and
--     only talks about "crime" or "absolution": the fine is 500 gold below level 20, 1,000 below
--     level 40, 5,000 up to level 60 and 10,000 above (EN, single source). Paying ends it.
-- Ours: the warning message when you enter, Dalbrect's refusal line, Costello's line when you
-- cannot pay, and the monk spawns upstairs (the wikis only say "Monk" for the upper floors; the
-- number and places are our guess: 4 on the bedroom floor, 2 on the floor above).
-- Trespasser mark: player KV (scope family-white-raven, key "trespasser").
-- Switch: Family.monasteryTrespass (false = no mark, no fine, no refusals; key and bookcase stay).

Family = Family or {}
Family.monasteryTrespass = true

FamilyWhiteRaven = {}
local W = FamilyWhiteRaven
W.kvScope = "family-white-raven"
W.keyNumber = 3350 -- action id of the key and of the door
W.keyItem = 2969 -- silver key (EN: "primarytype = Silver")
W.noteItem = 2815 -- scroll (BR appearance: Scroll (B))
W.bagItem = 2853
W.keyDoor = { x = 32178, y = 31928, z = 6 }
W.bookcase = { x = 32180, y = 31934, z = 7 }
W.restrictedRoom = { x1 = 32177, y1 = 31925, x2 = 32180, y2 = 31927, z = 6 }
W.noteText = "I have to hide that key better. One of that greedy adventurers that came here seemingly out of nowhere and refused to tell me how he got here stole it and disturbed the contemplation of the brothers upstairs. Gladly they could defeat him. When will those people learn some respect. How could they think there would be anything valuable? The next intruders will pay a bitter price for such an act of evil!"

W.lines = {
	costelloGreet = "WHAT? You have to be that trespasser my brothers told me about! Entering the restricted area is a horrible crime!",
	costelloBeGone = "Be gone!",
	costelloFine = "The only way to redeem such an offence is the sacrifice of %d gold pieces! Are you willing to pay that sum?",
	costelloThenBeGone = "Then be gone!",
	costelloPaid = "So receive your absolution! And never do such a thing again!",
	costelloNoMoney = "You cannot even pay for your crime? Then be gone!", -- ours
	captainJack = "By the gods! You must be that intruder the good brothers were talking about! Begone!",
	dalbrect = "The monks warned me about you, intruder! I will not sail you anywhere before you have made your peace with abbot Costello.", -- ours
	entered = "You have entered the restricted area of the White Raven Monastery. The monks will not forget this.", -- ours
}

local TOPIC_FINE = 50

local function kv(player)
	return player:kv():scoped(W.kvScope)
end

function W.isTrespasser(player)
	return Family.monasteryTrespass and kv(player):get("trespasser") == true
end

function W.setTrespasser(player, on)
	if on then
		kv(player):set("trespasser", true)
	else
		kv(player):remove("trespasser")
	end
end

function W.fine(level)
	if level < 20 then
		return 500
	elseif level < 40 then
		return 1000
	elseif level <= 60 then
		return 5000
	end
	return 10000
end

function W.inRestrictedRoom(pos)
	local r = W.restrictedRoom
	return pos.z == r.z and pos.x >= r.x1 and pos.x <= r.x2 and pos.y >= r.y1 and pos.y <= r.y2
end

local function isGreeting(message)
	for _, word in ipairs(FOCUS_GREETWORDS or { "hi", "hello" }) do
		if MsgContains(message, word) then
			return true
		end
	end
	return false
end

local function endTalk(npc, player, npcHandler)
	npcHandler:removeInteraction(npc, player)
end

-- Captain Jack: CALLBACK_ON_SAY. Returns false when the trespasser was turned away.
function W.captainJackOnSay(npc, player, message, npcHandler)
	if not W.isTrespasser(player) then
		return true
	end
	local talking = npcHandler:checkInteraction(npc, player)
	if not talking and not isGreeting(message) then
		return true
	end
	npcHandler:say(W.lines.captainJack, npc, player)
	if talking then
		endTalk(npc, player, npcHandler)
	end
	return false
end

-- Dalbrect: condition of his "passage" refusal keyword.
function W.dalbrectRefuses(player)
	return W.isTrespasser(player)
end

-- Costello: CALLBACK_GREET. Returns false when the trespasser greeting replaced the normal one.
function W.costelloGreet(npc, player, npcHandler)
	if not W.isTrespasser(player) then
		return true
	end
	npcHandler:say(W.lines.costelloGreet, npc, player)
	return false
end

-- Costello: CALLBACK_ON_SAY. While a trespasser talks to him, only the fine counts.
function W.costelloOnSay(npc, player, message, npcHandler)
	if not W.isTrespasser(player) or not npcHandler:checkInteraction(npc, player) then
		return true
	end
	local playerId = player:getId()
	if npcHandler:getTopic(playerId) == TOPIC_FINE then
		npcHandler:setTopic(playerId, 0)
		if not MsgContains(message, "yes") then
			npcHandler:say(W.lines.costelloThenBeGone, npc, player)
			endTalk(npc, player, npcHandler)
			return false
		end
		if not player:removeMoneyBank(W.fine(player:getLevel())) then
			npcHandler:say(W.lines.costelloNoMoney, npc, player)
			endTalk(npc, player, npcHandler)
			return false
		end
		W.setTrespasser(player, false)
		npcHandler:say(W.lines.costelloPaid, npc, player)
		return false
	end
	if MsgContains(message, "crime") or MsgContains(message, "absolution") then
		npcHandler:say(string.format(W.lines.costelloFine, W.fine(player:getLevel())), npc, player)
		npcHandler:setTopic(playerId, TOPIC_FINE)
		return false
	end
	npcHandler:say(W.lines.costelloBeGone, npc, player)
	endTalk(npc, player, npcHandler)
	return false
end
