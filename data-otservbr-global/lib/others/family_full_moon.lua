-- Gaia Family server: Grimvale Quest, mission "The Curse of the Full Moon"
-- (2026-10-28). Ours, not upstream: Maeryn's NPC file had her lore and the
-- werewolf helmet enchanting, but she was not spawned, and the mission
-- (her quest dialogue, nightshade delivery, trap silvering, the 50 kills,
-- access to Feroxa's lair) did not exist; the nightshades and silver veins
-- are not on our map. World objects and events: scripts/family/full_moon.lua.
--
-- Since 2026-11-01 aligned with TibiaWiki BR (Rodrigo: the more reliable
-- source). Four tasks:
--   Nightshades    Maeryn `mission`, `yes`; bring 3 purple nightshade
--                  blossoms (`nightshade`); more can be given afterwards
--   Silver Traps   Maeryn `trap`, `yes` silvers a closed trap with a vial of
--                  liquid silver (silver veins, third floor underground)
--   Were-Creatures kill 50 were-creatures; no NPC needed, the quest log
--                  starts with the first kill
--   Moonshadow     the lever ritual in the ruins underneath Grimvale (the V of
--                  white tiles); storage Storage.Quest.FamilyCurseSpreads.Ritual,
--                  which also opens the Mystic Flame into the Last Sanctum
-- Feroxa needs Were-Creatures and Moonshadow. Defeating her completes the
-- mission and uses both up: to face her again, ask Maeryn for the mission
-- again and do both once more (TibiaWiki BR).
-- States (S.Mission): 1 in progress, 2 ready for Feroxa, 3 Feroxa defeated.
-- Rodrigo's choices: the full moon is every Saturday (2026-11-03; Tibia:
-- 12th-14th); the nightshades bloom and the silver veins can be mined only
-- then, as in Tibia (every day from 2026-10-28 to 2026-11-03).
-- Lines marked "ours" are not from the wiki transcripts.
-- Switch: Family.curseOfTheFullMoon.

Family = Family or {}
Family.curseOfTheFullMoon = true
-- No creatures on the Grimvale island surface except butterflies (Rodrigo,
-- 2026-11-02): the surface spawns were taken out of world/otservbr-monster.xml,
-- and this switch stops scripts/world_changes/grimvale_respawn_event.lua, which
-- added bandits, badgers and butterflies at startup (wereboars and werebadgers
-- on the 13th).
Family.grimvaleQuietSurface = true

-- The full moon (Rodrigo, 2026-11-03): every Saturday, 00:00-23:59 by the
-- server PC's clock, instead of Tibia's 12th-14th. While it lasts: six
-- were-creatures on the Grimvale surface, the purple nightshades bloom, the
-- silver veins can be mined, and Feroxa comes once, after
-- M.feroxaAfterMinutes minutes of play that day (scripts/family/full_moon.lua).
-- GOD: /fullmoon on | off | auto (auto = by the weekday).
Family.fullMoonWeekday = 7 -- os.date("*t").wday: 1 Sunday ... 7 Saturday
Family.fullMoonForced = nil -- set by /fullmoon: true, false or nil (auto)

FamilyFullMoon = {}
local M = FamilyFullMoon
local S = Storage.Quest.FamilyFullMoon

M.blossomsNeeded = 3
M.killsNeeded = 50
M.blossom = 22082
M.vial = 22058
M.closedTrap = 3481
M.silveredTrap = 22074

M.wereCreatures = { "Werewolf", "Werebear", "Wereboar", "Werebadger", "Werefox", "Werehyaena", "Werehyaena Shaman", "Werelion", "Werelioness" }

M.feroxaAfterMinutes = 60

function M.isFullMoon(time)
	if Family.fullMoonForced ~= nil then
		return Family.fullMoonForced
	end
	return os.date("*t", time or os.time()).wday == Family.fullMoonWeekday
end

local function get(player, key)
	return math.max(0, player:getStorageValue(key))
end

-- the Grimvale Quest entry of the quest log starts with any of its missions
function FamilyGrimvaleStart(player)
	if player:getStorageValue(Storage.Quest.FamilyGrimvale.Questline) < 1 then
		player:setStorageValue(Storage.Quest.FamilyGrimvale.Questline, 1)
	end
end

function M.state(player)
	return get(player, S.Mission)
end

function M.setState(player, value)
	player:setStorageValue(S.Mission, value)
	FamilyGrimvaleStart(player)
end

function M.kills(player)
	return get(player, S.Kills)
end

function M.blossoms(player)
	return get(player, S.Blossoms)
end

function M.blossomsAsked(player)
	return player:getStorageValue(S.Blossoms) >= 0
end

function M.ritualDone(player)
	return player:getStorageValue(Storage.Quest.FamilyCurseSpreads.Ritual) >= 1
end

-- any task started shows the mission in the quest log
function M.begin(player)
	if M.state(player) < 1 then
		M.setState(player, 1)
	end
end

-- 1 -> 2 when Were-Creatures and Moonshadow are both done
function M.checkReady(player)
	if M.state(player) == 1 and M.kills(player) >= M.killsNeeded and M.ritualDone(player) then
		M.setState(player, 2)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You slew the were-creatures and performed the ritual in the Moonshadow Temple. When Feroxa appears in the mines of Grimvale, her lair will be open to you.") -- ours
		return true
	end
	return false
end

-- called by the lever ritual (scripts/family/curse_spreads.lua)
function M.onRitual(player)
	if not Family.curseOfTheFullMoon or M.state(player) == 3 then
		return
	end
	M.begin(player)
	M.checkReady(player)
end

function M.canEnterLair(player)
	if not Family.curseOfTheFullMoon then
		return true
	end
	return M.state(player) ~= 3 and M.kills(player) >= M.killsNeeded and M.ritualDone(player)
end

-- Feroxa defeated: mission done, Were-Creatures and Moonshadow used up
function M.onFeroxaDefeated(player)
	if not Family.curseOfTheFullMoon or M.state(player) == 3 then
		return
	end
	FamilyGrimvaleStart(player)
	player:setStorageValue(S.Mission, 3)
	player:setStorageValue(S.Kills, 0)
	player:setStorageValue(Storage.Quest.FamilyCurseSpreads.Ritual, 0)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Feroxa is defeated, at least until the next full moon. To face her again, ask Maeryn for a mission: slay fifty were-creatures and perform the ritual in the Moonshadow Temple once more.") -- ours
	if FamilyGrimvaleOverTheMoon then
		FamilyGrimvaleOverTheMoon(player)
	end
end

-- Quest log text (ours, after the TibiaWiki BR walkthrough)
function M.describe(player)
	local state = M.state(player)
	if state >= 3 then
		return "You defeated Feroxa. To face her again, ask Maeryn on Grimvale for a mission: the Were-Creatures and Moonshadow tasks have to be done once more."
	end
	local lines = {}
	if not M.blossomsAsked(player) then
		lines[#lines + 1] = "Nightshades: Maeryn on Grimvale needs help (ask her for a mission)."
	elseif M.blossoms(player) < M.blossomsNeeded then
		lines[#lines + 1] = string.format("Nightshades: bring Maeryn three purple nightshade blossoms (delivered: %d). They grow on purple nightshades in the dungeon underneath Grimvale (hole in the north-east of the island): one on the first floor, two on the second; they bloom only under the full moon, on Saturdays.", M.blossoms(player))
	else
		lines[#lines + 1] = "Nightshades: you brought Maeryn the purple nightshade blossoms."
	end
	lines[#lines + 1] = string.format("Were-Creatures: %d of 50 slain.", math.min(M.kills(player), M.killsNeeded))
	if M.ritualDone(player) then
		lines[#lines + 1] = "Moonshadow: you performed the ritual in the Moonshadow Temple."
	else
		lines[#lines + 1] = "Moonshadow: in the ruins at the bottom of the dungeon underneath Grimvale, form a V with the white tiles using the five levers, then pull any lever."
	end
	lines[#lines + 1] = "Silver Traps: a closed trap (Gladys) and a vial of liquid silver (silver veins, third floor underground; they can be mined only under the full moon, on Saturdays) - Maeryn silvers it. Only silver hurts Feroxa's beast form."
	if M.canEnterLair(player) then
		lines[#lines + 1] = "Feroxa: she returns once every full moon (Saturday). Her lair is open to you while she is there; the teleport in the hall before it takes you in."
	else
		lines[#lines + 1] = "Feroxa: her lair opens to you once Were-Creatures and Moonshadow are done."
	end
	return table.concat(lines, "\n")
end

local TOPIC_QUEST = 50
local TOPIC_TRAP = 51

local function say(npcHandler, npc, creature, text)
	npcHandler:say(text, npc, creature)
end

-- Maeryn's default callback calls this first. Returns true when handled.
function M.onSay(npc, creature, player, message, npcHandler)
	if not Family.curseOfTheFullMoon then
		return false
	end
	local id = player:getId()
	local topic = npcHandler:getTopic(id)
	local state = M.state(player)
	if topic == TOPIC_QUEST then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			say(npcHandler, npc, creature, "Thank you! These plants are reported to grow in the tunnels underneath the village, but I don't know the proper location.")
			if M.state(player) == 3 then
				M.setState(player, 1) -- asked again after Feroxa (TibiaWiki BR)
			else
				M.begin(player)
			end
			player:setStorageValue(S.Blossoms, 0)
			M.checkReady(player)
			return true
		elseif MsgContains(message, "no") then
			say(npcHandler, npc, creature, "Too bad. Come back if you change your mind.") -- ours
			return true
		end
	elseif topic == TOPIC_TRAP then
		npcHandler:setTopic(id, 0)
		if MsgContains(message, "yes") then
			if player:getItemCount(M.closedTrap) < 1 or player:getItemCount(M.vial) < 1 then
				say(npcHandler, npc, creature, "You need a closed trap and a vial of liquid silver for that.") -- ours
				return true
			end
			player:removeItem(M.closedTrap, 1)
			player:removeItem(M.vial, 1)
			player:addItem(M.silveredTrap, 1)
			say(npcHandler, npc, creature, "Well then, give me the trap and the silver. - Thank you. Now wait just a moment. This won't take too long.")
			return true
		elseif MsgContains(message, "no") then
			say(npcHandler, npc, creature, "As you wish.") -- ours
			return true
		end
	end
	if MsgContains(message, "quest") or MsgContains(message, "mission") then
		if not M.blossomsAsked(player) or state == 3 then
			say(npcHandler, npc, creature, {
				"Many villagers were bitten by were-creatures, that's the most serious problem right now. Until the next full moon they will turn into savage {beasts}. There is only one way to prevent this: we need enough purple {nightshade} blossoms. ...",
				"Three of these blossoms should suffice to heal some afflicted persons. But if you bring more I'd be grateful, of course. Would you do that?",
			})
			npcHandler:setTopic(id, TOPIC_QUEST)
			return true
		end
		local missing = {}
		if M.blossoms(player) < M.blossomsNeeded then
			missing[#missing + 1] = "three purple {nightshade} blossoms"
		end
		if M.kills(player) < M.killsNeeded then
			missing[#missing + 1] = string.format("fewer were-creatures - you have slain %d of fifty", M.kills(player))
		end
		if not M.ritualDone(player) then
			missing[#missing + 1] = "someone to perform the ritual in the Moonshadow Temple, deep underneath the village"
		end
		if #missing == 0 then
			say(npcHandler, npc, creature, "You have done a lot for Grimvale. When Feroxa shows herself in the mines, you may face her - take silvered {traps} with you.") -- ours
		else
			say(npcHandler, npc, creature, "We still need " .. table.concat(missing, ", and ") .. ".") -- ours
		end
		return true
	end
	-- TibiaWiki BR: she takes three blossoms at a time, again and again
	if MsgContains(message, "nightshade") and M.blossomsAsked(player) then
		local count = player:getItemCount(M.blossom)
		if count < 1 then
			return false -- her own line about the blossoms
		end
		if count < M.blossomsNeeded then
			say(npcHandler, npc, creature, string.format("These are not enough. I need %d blossoms.", M.blossomsNeeded)) -- ours
			return true
		end
		player:removeItem(M.blossom, M.blossomsNeeded)
		player:setStorageValue(S.Blossoms, M.blossoms(player) + M.blossomsNeeded)
		say(npcHandler, npc, creature, "You brought some purple nightshade! Thank you. Now we may heal some affected villagers! You have rendered us a great favour, but if you find any more blossoms, don't hesitate to bring them to me.")
		return true
	end
	if MsgContains(message, "trap") or MsgContains(message, "traps") then
		if player:getItemCount(M.closedTrap) < 1 or player:getItemCount(M.vial) < 1 then
			say(npcHandler, npc, creature, "If you bring me a closed trap and a vial of liquid silver, I can silver the trap for you. Only silver hurts the beast that Feroxa becomes.") -- ours
			return true
		end
		say(npcHandler, npc, creature, "You've got a trap and some liquid silver? Great! I know something about silvering wolf traps. May I help you?")
		npcHandler:setTopic(id, TOPIC_TRAP)
		return true
	end
	return false
end
