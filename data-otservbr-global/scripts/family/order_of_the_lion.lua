-- Gaia Family server: The Order of the Lion Quest, world side (2026-11-09).
-- Story, dialogue and quest log: lib/others/family_order_of_the_lion.lua (FamilyLion).
-- Here: the Bounac NPCs at their day and night spots (TibiaWiki BR), the ledger
-- and the map in the usurpers' camp, the deer and crypt warrior counts, Fugue
-- in the throne room at night, the meeting with Drume, the Drume battle
-- result, the doors that open for the quest and for the Hero of Bounac, and
-- the GOD command /lion. Switch: Family.orderOfTheLion.

local L = FamilyLion
local Q = Storage.Quest.U12_40.TheOrderOfTheLion

local function on()
	return Family.orderOfTheLion and L ~= nil
end

local function msg(player, text)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
end

-- NPCs at their day and night spots ----------------------------------------------
-- BR coordinates (TibiaWiki BR quest page); Kesar's night quarters and Fitzgerald
-- from TibiaWiki EN. nil = not there at that time (Evrard by day only, Fitzmaurice
-- at night only).
L.npcSpots = {
	{ name = "Evrard the Miller", day = Position(32421, 32463, 7) },
	{ name = "Fral the Butcher", day = Position(32446, 32481, 4), night = Position(32399, 32495, 6) },
	{ name = "Dal the Huntress", day = Position(32436, 32493, 5), night = Position(32436, 32493, 4) },
	{ name = "Jehan the Baker", day = Position(32423, 32481, 4), night = Position(32391, 32459, 6) },
	{ name = "Onfroi", day = Position(32428, 32488, 5), night = Position(32429, 32489, 2) },
	{ name = "Wes the Blacksmith", day = Position(32423, 32481, 5), night = Position(32374, 32467, 6) },
	{ name = "Bounac Guard", day = Position(32400, 32481, 4), night = Position(32400, 32481, 4) },
	{ name = "Kesar the Younger", day = Position(32365, 32478, 2), night = Position(32368, 32474, 3) },
	{ name = "Fitzmaurice", night = Position(32411, 32486, 7) },
	{ name = "Fitzgerald", day = Position(33382, 32676, 3), night = Position(33382, 32676, 3) },
}

local placed = {} -- name -> { id = creature id, phase = "day"/"night" }

function L.placeNpcs(force)
	local phase = L.isNight() and "night" or "day"
	for _, spot in ipairs(L.npcSpots) do
		local entry = placed[spot.name]
		local npc = entry and Npc(entry.id)
		local target = spot[phase]
		if not on() then
			target = nil
		end
		if npc and (force or entry.phase ~= phase or not target) then
			if target then
				if npc:getPosition() ~= target then
					npc:getPosition():sendMagicEffect(CONST_ME_POFF)
					npc:teleportTo(target)
					target:sendMagicEffect(CONST_ME_TELEPORT)
				end
				npc:setMasterPos(target)
				entry.phase = phase
			else
				npc:getPosition():sendMagicEffect(CONST_ME_POFF)
				npc:remove()
				placed[spot.name] = nil
			end
		elseif not npc and target then
			local created = Game.createNpc(spot.name, target, false, true)
			if created then
				created:setMasterPos(target)
				placed[spot.name] = { id = created:getId(), phase = phase }
			else
				logger.error("[FamilyLion] could not place NPC " .. spot.name)
			end
		end
	end
end

function L.npcOf(name)
	local entry = placed[name]
	return entry and Npc(entry.id) or nil
end

-- Doors ------------------------------------------------------------------------
-- Sealed quest doors of Bounac (QuestDoorTable 5122) without an action id on our
-- map: they open for the Hero of Bounac (BR: "Desbloqueio de algumas portas que
-- antes permaneciam seladas"). The door of the small meeting room opens with the
-- east side access, so the meeting can be left.
L.heroDoors = {
	Position(32395, 32475, 4),
	Position(32368, 32482, 6),
	Position(32391, 32456, 7),
	Position(32385, 32457, 7),
	Position(32400, 32457, 7),
	Position(32441, 32469, 7),
}
L.meetingDoor = Position(32447, 32494, 7)

local function setDoorAid(pos, aid)
	local tile = Tile(pos)
	if not tile then
		return false
	end
	for _, item in ipairs(tile:getItems() or {}) do
		if ItemType(item:getId()):isDoor() then
			item:setActionId(aid)
			return true
		end
	end
	return false
end

-- Passages for the Hero of Bounac -------------------------------------------------------------
-- The Bounac depot (32389-32392,32486-32489,7) and the house south of it are closed off on our map.
-- Rodrigo's BR screenshot shows the depot entered from that house; its two doorways (a plank on the
-- floor under a stone wall: 32392,32496,7 from the street, 32394,32493,6 from the yard one floor up)
-- let the Hero of Bounac through (BR: "Acesso ao Depot da Ilha"). Kesar: "Feel free to roam Bounac as
-- you please", so the three Bounac doors no script can open (ids 33632/33634, not in any door table:
-- Wes' room at night, the kitchen of the house south of the town, a door in the north) also let the
-- Hero through (2026-11-09). Others find them sealed.
L.heroPassages = {
	{ wall = Position(32392, 32496, 7), inside = Position(32392, 32495, 7), outside = Position(32392, 32497, 7), depot = true },
	{ wall = Position(32394, 32493, 6), inside = Position(32393, 32493, 6), outside = Position(32395, 32493, 6), depot = true },
	{ wall = Position(32374, 32465, 6), inside = Position(32374, 32466, 6), outside = Position(32374, 32464, 6) },
	{ wall = Position(32421, 32502, 7), inside = Position(32422, 32502, 7), outside = Position(32420, 32502, 7) },
	{ wall = Position(32398, 32460, 6), inside = Position(32399, 32460, 6), outside = Position(32397, 32460, 6) },
}
L.depotPassages = { L.heroPassages[1], L.heroPassages[2] }

function L.usePassage(player, passage)
	if not L.isHero(player) then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The door seems to be sealed against unwanted intruders.")
		return false
	end
	local pos = player:getPosition()
	local dest = pos == passage.inside and passage.outside or passage.inside
	if pos ~= passage.inside and pos ~= passage.outside and pos:getDistance(passage.inside) < pos:getDistance(passage.outside) then
		dest = passage.outside
	end
	player:teleportTo(dest)
	dest:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

local passage = Action()
function passage.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if not on() then
		return false
	end
	for _, p in ipairs(L.heroPassages) do
		if toPosition == p.wall then
			L.usePassage(player, p)
			return true
		end
	end
	return false
end
for _, p in ipairs(L.heroPassages) do
	passage:position(p.wall)
end
passage:register()

-- The ledger and the map ------------------------------------------------------------
-- They stay where they are (both players need them); taking one gives a copy to a
-- player on the errand.
L.docAid = 48619
L.ledgerPos = Position(32469, 32503, 7)
L.mapPos = Position(32483, 32495, 7)

local function markDocs()
	local n = 0
	local tile = Tile(L.ledgerPos)
	local ledger = tile and tile:getItemById(L.items.ledger)
	if ledger then
		ledger:setActionId(L.docAid)
		n = n + 1
	end
	tile = Tile(L.mapPos)
	if tile then
		for _, item in ipairs(tile:getItems() or {}) do
			if item:isContainer() then
				for _, inner in ipairs(Container(item.uid):getItems(true) or {}) do
					if inner:getId() == L.items.map then
						inner:setActionId(L.docAid)
						n = n + 1
					end
				end
			end
		end
	end
	return n
end

function L.takeDoc(player, item)
	local key = item:getId() == L.items.map and "map" or "ledger"
	if L.state(player) ~= 1 then
		player:sendCancelMessage("This belongs to the usurpers. Better leave it where it is.") -- ours
		return false
	end
	if L.get(player, key) == 1 then
		player:sendCancelMessage("You already have it.") -- ours
		return false
	end
	local copy = player:addItem(item:getId(), 1)
	if copy then
		local text = item:getAttribute(ITEM_ATTRIBUTE_TEXT)
		if text and text ~= "" then
			copy:setAttribute(ITEM_ATTRIBUTE_TEXT, text)
		end
		L.set(player, key, 1)
		L.setState(player, 1) -- refresh the quest log
		msg(player, key == "map" and "You take the usurpers' map." or "You take the ledger. Quick, before anybody notices!") -- ours
	end
	return true
end

local docMove = EventCallback("FamilyLionDocs")
function docMove.playerOnMoveItem(player, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	if on() and item:getActionId() == L.docAid then
		L.takeDoc(player, item)
		return false
	end
	return true
end
docMove:register()

-- Deer and crypt warriors -------------------------------------------------------------

local function countKill(player, who, key, label)
	if L.state(player) == 2 and L.get(player, "task_" .. who) == 1 then
		local n = L.get(player, key)
		if n < 20 then
			n = n + 1
			L.set(player, key, n)
			player:sendTextMessage(MESSAGE_STATUS, string.format("%s: %d/20", label, n)) -- ours
		end
	end
end

local deerDeath = CreatureEvent("FamilyLionDeer")
function deerDeath.onDeath(creature)
	if on() then
		onDeathForDamagingPlayers(creature, function(_, player)
			countKill(player, "dal", "deer", "Deer hunted for Dal")
		end)
	end
	return true
end
deerDeath:register()

local cryptDeath = CreatureEvent("FamilyLionCrypt")
function cryptDeath.onDeath(creature)
	if on() then
		onDeathForDamagingPlayers(creature, function(_, player)
			countKill(player, "onfroi", "crypt", "Crypt warriors destroyed for Onfroi")
		end)
	end
	return true
end
cryptDeath:register()

-- Fugue -------------------------------------------------------------------------------
-- After Kesar's plan and one Tibian day, at night, Fugue and 5 usurper warlocks (EN)
-- come when a player of that step is in the throne room. He leaves after 10 minutes
-- if not defeated (EN: "a few minutes"); then he can come again another night (ours;
-- BR says only once per character).
L.fugueStay = 10 * 60
L.fugue = nil -- { id = creature id, until = os.time() }

local function fugueAlive()
	return L.fugue and Monster(L.fugue.id) ~= nil
end

-- (a hook, so a self-test can give its own players)
function L.getPlayers()
	return Game.getPlayers()
end

local function throneRoomPlayers(minState, maxState)
	local list = {}
	for _, p in ipairs(L.getPlayers()) do
		local st = L.state(p)
		if L.inThroneRoom(p:getPosition()) and st >= minState and st <= maxState then
			list[#list + 1] = p
		end
	end
	return list
end

function L.checkFugue()
	if not on() then
		return
	end
	if L.fugue then
		local fugue = Monster(L.fugue.id)
		if fugue and os.time() >= L.fugue["until"] and not fugue:getTarget() then
			fugue:getPosition():sendMagicEffect(CONST_ME_POFF)
			fugue:remove()
			L.fugue = nil
		elseif not fugue then
			L.fugue = nil
		end
		return
	end
	if not L.isNight() then
		return
	end
	local ready = false
	for _, p in ipairs(throneRoomPlayers(6, 6)) do
		if os.time() >= L.get(p, "fugueAfter") then
			ready = true
		end
	end
	if not ready then
		return
	end
	local fugue = Game.createMonster("Fugue", L.fugueSpot, true, true)
	if not fugue then
		return
	end
	L.fugue = { id = fugue:getId(), ["until"] = os.time() + L.fugueStay }
	fugue:registerEvent("FamilyLionFugueDeath")
	L.fugueSpot:sendMagicEffect(CONST_ME_TELEPORT)
	for i = 1, 5 do
		local pos = Position(L.fugueSpot.x + math.random(-3, 3), L.fugueSpot.y + math.random(-2, 2), L.fugueSpot.z)
		local warlock = Game.createMonster("Usurper Warlock", pos, true, false)
		if warlock then
			pos:sendMagicEffect(CONST_ME_TELEPORT)
		end
	end
	fugue:say("Kesar does not belong here!", TALKTYPE_MONSTER_YELL)
end

local fugueDeath = CreatureEvent("FamilyLionFugueDeath")
function fugueDeath.onDeath(creature)
	L.fugue = nil
	local done = {}
	local function finish(player)
		if L.state(player) == 6 and not done[player:getId()] then
			done[player:getId()] = true
			L.setState(player, 7)
			msg(player, "Fugue is defeated! Wait for the day and tell Kesar the Younger about it.") -- ours
		end
	end
	onDeathForDamagingPlayers(creature, function(_, player)
		finish(player)
	end)
	for _, p in ipairs(throneRoomPlayers(6, 6)) do
		finish(p)
	end
	return true
end
fugueDeath:register()

-- The meeting with Drume ---------------------------------------------------------------
-- Kesar takes the player to the small room east of Bounac (BR 32447,32493,7) and talks
-- to Drume in the room with the desk north of it. The 8 lines are Tibia's, read from
-- the TibiaWiki BR screenshots Mensagem 01/08 - 08/08 (sent by Rodrigo, 2026-11-09).
L.meetingLines = {
	{ "drume", "Your appearance here means nothing else than my brother's untimely death. Am I right, Kesar?" },
	{ "kesar", "I am here to talk about peace, Drume. It is time to end this madness." },
	{ "drume", "Mad? Remind me, king, who was the one leaving Bounac to rot in the sun, a legacy lost. And who killed my dear brother, Fugue?" },
	{ "kesar", "Yes. Yes, it was me. We may be lost for what we've done. But even if we failed our people, we both need to come to our senses." },
	{ "drume", "You and you alone failed our people. My people, Kesar. I've witnessed Bounac's decay long enough. I challenge the order." },
	{ "kesar", "We don't have to do this, Drume. Let this stay between you and me, let our men out of this. Our people suffered long enough." },
	{ "drume", "My men will fight to the bitter end. Will you stand? I will see you on the battlefield. Now leave, Kesar. This meeting is over." },
	{ "kesar", "So be it, Drume. So be it." },
}
L.meetingGap = 5000
L.meetingBack = Position(32367, 32478, 2) -- before Kesar's throne (ours)
L.meeting = nil -- { kesar = id, drume = id }

local function inMeetingRoom(pos)
	return pos.z == 7 and pos.y == 32493 and (pos.x == 32446 or pos.x == 32447)
end

local function endMeeting()
	if L.meeting then
		for _, id in ipairs({ L.meeting.kesar, L.meeting.drume }) do
			local npc = Npc(id)
			if npc then
				npc:getPosition():sendMagicEffect(CONST_ME_POFF)
				npc:remove()
			end
		end
	end
	L.meeting = nil
	for _, p in ipairs(L.getPlayers()) do
		if inMeetingRoom(p:getPosition()) and L.state(p) == 8 then
			L.setState(p, 9)
			p:teleportTo(L.meetingBack)
			L.meetingBack:sendMagicEffect(CONST_ME_TELEPORT)
			msg(p, "The talks have failed. Kesar the Younger returns to his castle. Ask him about the siege.") -- ours
		end
	end
end

function L.startMeeting(player)
	player:getPosition():sendMagicEffect(CONST_ME_POFF)
	player:teleportTo(L.meetingRoom)
	L.meetingRoom:sendMagicEffect(CONST_ME_TELEPORT)
	if L.meeting then
		return -- already running: watch the rest
	end
	local kesar = Game.createNpc("Kesar (Bounac Meeting)", L.meetingKesar, false, true)
	local drume = Game.createNpc("Drume (Bounac Meeting)", L.meetingDrume, false, true)
	if not kesar or not drume then
		logger.error("[FamilyLion] meeting NPCs could not be placed")
		L.meeting = { kesar = kesar and kesar:getId() or 0, drume = drume and drume:getId() or 0 }
		endMeeting()
		return
	end
	L.meeting = { kesar = kesar:getId(), drume = drume:getId() }
	L.meetingKesar:sendMagicEffect(CONST_ME_TELEPORT)
	L.meetingDrume:sendMagicEffect(CONST_ME_TELEPORT)
	for i, line in ipairs(L.meetingLines) do
		addEvent(function(who, text)
			if not L.meeting then
				return
			end
			local npc = Npc(L.meeting[who])
			if npc then
				npc:say(text, TALKTYPE_SAY)
			end
		end, i * L.meetingGap, line[1], line[2])
	end
	addEvent(endMeeting, (#L.meetingLines + 1) * L.meetingGap)
end

-- Drume -------------------------------------------------------------------------------
-- The battle lever needs Kesar's call (state 10) or the Hero of Bounac (FAMILY edit
-- in scripts/quests/the_order_of_lion/action-drume.lua). His defeat completes step 10.

function L.canFightDrume(player)
	return not on() or L.state(player) >= 10
end

local ARENA_CENTER = Position(32439, 32523, 7)
local drumeDeath = CreatureEvent("FamilyLionDrumeDeath")
function drumeDeath.onDeath(creature)
	if not on() then
		return true
	end
	local seen = {}
	local function finish(player)
		if L.state(player) == 10 and not seen[player:getId()] then
			seen[player:getId()] = true
			L.setState(player, 11)
			msg(player, "Drume is defeated! Report to Kesar the Younger in his castle.") -- ours
		end
	end
	onDeathForDamagingPlayers(creature, function(_, player)
		finish(player)
	end)
	for _, spec in ipairs(Game.getSpectators(ARENA_CENTER, false, true, 22, 22, 16, 16)) do
		finish(spec)
	end
	return true
end
drumeDeath:register()

-- Startup and the clock -------------------------------------------------------------------

local startup = GlobalEvent("FamilyLionStartup")
function startup.onStartup()
	for name, event in pairs({ ["Deer"] = "FamilyLionDeer", ["Crypt Warrior"] = "FamilyLionCrypt", ["Drume"] = "FamilyLionDrumeDeath" }) do
		local mType = MonsterType(name)
		if mType then
			mType:registerEvent(event)
		end
	end
	if not on() then
		return true
	end
	local doors = 0
	for _, pos in ipairs(L.heroDoors) do
		if setDoorAid(pos, L.heroStorage) then
			doors = doors + 1
		end
	end
	if setDoorAid(L.meetingDoor, Q.AccessEastSide) then
		doors = doors + 1
	end
	local docs = markDocs()
	addEvent(function()
		L.placeNpcs(true)
	end, 1000)
	logger.info("[FamilyLion] Bounac: {} doors, {} quest documents", doors, docs)
	return true
end
startup:register()

local clock = GlobalEvent("FamilyLionClock")
function clock.onThink(interval)
	L.placeNpcs(false)
	L.checkFugue()
	return true
end
clock:interval(5000)
clock:register()

-- GOD: /lion [state <n> | hero | npcs] -------------------------------------------------------
local god = TalkAction("/lion")
function god.onSay(player, words, param)
	local args = param:split(" ")
	if args[1] == "state" and tonumber(args[2]) then
		L.setState(player, tonumber(args[2]))
	elseif args[1] == "hero" then
		L.makeHero(player)
	elseif args[1] == "npcs" then
		L.placeNpcs(true)
	end
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("Order of the Lion: state %d, trust %d/5, deer %d, crypt %d, %s, Fugue %s, hero %s.", L.state(player), L.trustCount(player), L.get(player, "deer"), L.get(player, "crypt"), L.isNight() and "night" or "day", fugueAlive() and "here" or "away", tostring(L.isHero(player))))
	return true
end
god:separator(" ")
god:groupType("god")
god:register()
