-- Gaia Family server: Grimvale Quest, mission "The Curse of the Full Moon"
-- (2026-10-28). Ours, not upstream: Maeryn's NPC file had her lore and the
-- werewolf helmet enchanting, but she was not spawned, and the mission
-- (her quest dialogue, nightshade delivery, trap silvering, the 50 kills,
-- access to Feroxa's lair) did not exist; the nightshades and silver veins
-- are not on our map. World objects and events: scripts/family/full_moon.lua.
--
-- TibiaWiki EN ("Grimvale Quest/Spoiler"):
--   1 Maeryn (Grimvale, south-west house) `quest`, `yes`
--     bring 3 purple nightshade blossoms (`nightshade`), kill 50 were-creatures
--   2 Feroxa's lair opens for you while Feroxa is there
--   3 entering the lair completes the mission
-- Maeryn also silvers a closed trap with a vial of liquid silver (`trap`).
-- Rodrigo's choices (2026-10-28): the nightshades bloom and the silver
-- veins can be mined every day (Tibia: only at full moon, 12th-14th);
-- Feroxa's lair requires the mission, as in Tibia.
-- Lines marked "ours" are not from the wiki transcripts.
-- Switch: Family.curseOfTheFullMoon.

Family = Family or {}
Family.curseOfTheFullMoon = true

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

-- step 1 -> 2 when both parts are done
function M.checkDone(player)
	if M.state(player) == 1 and M.blossoms(player) >= M.blossomsNeeded and M.kills(player) >= M.killsNeeded then
		M.setState(player, 2)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You helped Maeryn against the curse. When Feroxa appears in the mines of Grimvale, her lair will be open to you.") -- ours
		return true
	end
	return false
end

function M.canEnterLair(player)
	return not Family.curseOfTheFullMoon or M.state(player) >= 2
end

-- Quest log text (ours, after the wiki walkthrough)
function M.describe(player)
	local state = M.state(player)
	if state == 1 then
		local parts = {}
		local blossoms = math.min(M.blossoms(player), M.blossomsNeeded)
		parts[#parts + 1] = blossoms >= M.blossomsNeeded and "You brought Maeryn the purple nightshade blossoms." or string.format("Bring Maeryn three purple nightshade blossoms (delivered: %d). They grow on blooming purple nightshades in the dungeon underneath Grimvale (pitfall in the north-east of the island): one on the first floor, two on the second.", blossoms)
		local kills = math.min(M.kills(player), M.killsNeeded)
		parts[#parts + 1] = string.format("Were-creatures killed: %d of 50.", kills)
		return "Maeryn needs help against the Curse of the Full Moon. " .. table.concat(parts, " ")
	elseif state == 2 then
		return "You helped Maeryn. When Feroxa appears in the mines of Grimvale, the teleport in the hall before her lair will take you to her. Silvered traps (a closed trap and a vial of liquid silver from a silver vein on the third floor of the dungeon, silvered by Maeryn) hurt her werewolf form."
	elseif state >= 3 then
		return "You entered Feroxa's lair. The Curse of the Full Moon has been confronted - she will return with the next full moon."
	end
	return "Talk to Maeryn on Grimvale."
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
			M.setState(player, 1)
			player:setStorageValue(S.Blossoms, 0)
			player:setStorageValue(S.Kills, 0)
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
		if state < 1 then
			say(npcHandler, npc, creature, {
				"It causes me great anxiety that the curse has spread and reached other regions of our world. The most serious problem here on Grimvale is, that many villagers were bitten by were-creatures. ...",
				"Until the next full moon they will turn into savage {beasts}. There is only one way to prevent this: we need enough purple {nightshade} blossoms. ...",
				"Three of these blossoms should suffice to heal some afflicted persons. But if you bring more I'd be grateful, of course. Would you do that?",
			})
			npcHandler:setTopic(id, TOPIC_QUEST)
		elseif state == 1 then
			local missing = {}
			if M.blossoms(player) < M.blossomsNeeded then
				missing[#missing + 1] = "three purple {nightshade} blossoms"
			end
			if M.kills(player) < M.killsNeeded then
				missing[#missing + 1] = string.format("fewer were-creatures - you have slain %d of fifty", M.kills(player))
			end
			say(npcHandler, npc, creature, "We still need " .. table.concat(missing, ", and ") .. ".") -- ours
		else
			say(npcHandler, npc, creature, "You have done a lot for Grimvale. When Feroxa shows herself in the mines, you may face her - take silvered {traps} with you.") -- ours
		end
		return true
	end
	if MsgContains(message, "nightshade") and state >= 1 then
		local count = player:getItemCount(M.blossom)
		if count < 1 then
			return false -- her own line about the blossoms
		end
		if M.blossoms(player) < M.blossomsNeeded and count < M.blossomsNeeded - M.blossoms(player) then
			say(npcHandler, npc, creature, string.format("These are not enough yet. I need %d blossoms.", M.blossomsNeeded - M.blossoms(player))) -- ours
			return true
		end
		player:removeItem(M.blossom, count)
		player:setStorageValue(S.Blossoms, M.blossoms(player) + count)
		say(npcHandler, npc, creature, "You brought some purple nightshade! Thank you. Now we may heal some affected villagers! You have rendered us a great favour, but if you find any more blossoms, don't hesitate to bring them to me.")
		M.checkDone(player)
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
