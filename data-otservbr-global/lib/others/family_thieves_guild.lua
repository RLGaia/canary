-- Gaia Family server: The Thieves Guild Quest review (2026-11-20). Ours, not upstream.
--
-- Reported by Rodrigo: Theodore Loveless' key did nothing on his door ("You cannot use this
-- object."). Upstream gave that door the action id of the Mission 4 storage
-- (startup/tables/door_quest.lua), so the key and door scripts, which wait for action id 51394,
-- never ran. The whole quest was then checked against TibiaWiki BR (our backup) and the
-- TibiaWiki EN spoiler and transcripts. Fixed here and in the files named below:
--   * Mission 6: the key opens the door (key breaks, you slip in); lock picks open it too, with a
--     small chance (BR third method, "about 50 lock picks"; 2% per try is ours); the door lets you
--     out from inside; Chantalle, Herbert, Carina and Bertram say their wiki lines; Carina no
--     longer sells the precious necklace in her trade window (BR list), only to quest players.
--   * Mission 2 and 5 gave the wrong items: a fine vase (227) instead of the valuable vase (7932)
--     and a golden goblet (7369) instead of the stolen golden goblet (7870) (EN item pages).
--     Dorian still takes the old items from characters that already have them.
--   * Mission 3: Oswald's `gold` path ("Not that I am bribeable...", `yes`) went nowhere.
--   * Mission 4: Ahmet forged the documents only after his stolen bag was found, not after
--     killing a nomad (both wikis: kill at least one nomad); accepting his stolen-goods job gives
--     100 experience (BR only). Percybald gives the Amateur Actor achievement after his test (BR;
--     EN: "completing Mission 4"), and a new dwarf disguise kit if yours was used up before the
--     deal with Nurik (ours: the kit lasts 5 minutes and nothing else gave a new one).
--   * Mission 8: the Dark Cathedral teleport ignored the six levers (its map destination moved
--     players before the script); levers now go back after about 1 minute (EN; upstream 10).
--     Dorian gives the Master Thief achievement at the end (both wikis).
--   * Black Bert trades only with characters who finished the quest (both wikis).
--   * Quest log: Percybald is in Carlin (upstream said Venore).
-- The Kissing a Pig way to the key (BR fourth method) is in lib/others/family_kissing_pig.lua (2026-11-20).
--
-- Files: this lib; scripts/family/thieves_guild.lua (startup: teleport); FAMILY edits in
-- startup/tables/door_quest.lua and chest.lua, scripts/actions/tools/lock_pick.lua,
-- scripts/quests/the_thieves_guild_quest/actions_fish_napping_key.lua and _door.lua,
-- scripts/movements/teleport/dark_cathedral_teleports.lua, npc/ dorian, chantalle, herbert,
-- carina, bertram, oswald, ahmet, percybald, black_bert; quest log 026_the_thieves_guild.lua.
-- Switch: Family.thievesGuild (false = upstream behaviour where an edit checks it).

Family = Family or {}
Family.thievesGuild = true

FamilyThieves = FamilyThieves or {}
local FT = FamilyThieves
local S = Storage.Quest.U8_2.TheThievesGuildQuest
FT.S = S

FT.DOOR_AID = 51394
FT.DOOR_POS = Position(32359, 32787, 6)
FT.INSIDE_POS = Position(32359, 32788, 6)
FT.OUTSIDE_POS = Position(32359, 32786, 6)
FT.KEY = 7934
FT.LOCK_PICK = 7889
-- percent per lock pick on Theodore's door (ours: TibiaWiki BR advises about 50 lock picks)
FT.lockPickDoorChance = 2

FT.VASE = 7932 -- valuable vase (EN item page)
FT.OLD_VASE = 227 -- fine vase, given by upstream until 2026-11-20
FT.GOBLET = 7870 -- stolen golden goblet (EN item page)
FT.OLD_GOBLET = 7369 -- golden goblet, given by upstream until 2026-11-20
FT.KIT = 7865 -- dwarf disguise kit

local function get(player, key)
	return math.max(-1, player:getStorageValue(key))
end

-- Theodore's private room: x 32357-32359, y 32788-32791, floor 6.
function FT.isInside(pos)
	return pos.z == 6 and pos.x >= 32357 and pos.x <= 32359 and pos.y >= 32788 and pos.y <= 32791
end

-- The key and the lock picks work while the fish is still to be taken.
function FT.mayEnter(player)
	local m6 = get(player, S.Mission06)
	return m6 == 1 or m6 == 2
end

function FT.enterRoom(player)
	if get(player, S.Mission06) == 1 then
		player:setStorageValue(S.Mission06, 2)
	end
	player:teleportTo(FT.INSIDE_POS)
	FT.INSIDE_POS:sendMagicEffect(CONST_ME_TELEPORT)
end

local function locked(player)
	player:sendTextMessage(MESSAGE_FAILURE, "It is locked.")
end

-- Theodore Loveless' key on his door. Returns nil when the target is not that door.
function FT.useKey(player, item, target)
	if not target or not target.isItem or not target:isItem() then
		return nil
	end
	local pos = target:getPosition()
	if target:getActionId() ~= FT.DOOR_AID and pos ~= FT.DOOR_POS then
		return nil
	end
	if FT.isInside(player:getPosition()) then
		return FT.useDoor(player)
	end
	if not FT.mayEnter(player) then
		locked(player)
		return true
	end
	item:remove(1)
	player:say("In your haste you break the key while slipping in.", TALKTYPE_MONSTER_SAY)
	FT.enterRoom(player)
	return true
end

-- The door itself: it lets you out of the room, and is locked from the outside.
function FT.useDoor(player)
	if FT.isInside(player:getPosition()) then
		player:say("You slip through the door", TALKTYPE_MONSTER_SAY)
		player:teleportTo(FT.OUTSIDE_POS)
		FT.OUTSIDE_POS:sendMagicEffect(CONST_ME_TELEPORT)
		return true
	end
	locked(player)
	return true
end

-- A lock pick on the door: mostly breaks (Dorian: "unless you're extremely lucky").
function FT.lockPickDoor(player, item, roll)
	if FT.isInside(player:getPosition()) then
		return FT.useDoor(player)
	end
	if not FT.mayEnter(player) then
		locked(player)
		return true
	end
	roll = roll or math.random(100)
	if roll <= FT.lockPickDoorChance then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You cracked the lock!") -- ours
		FT.enterRoom(player)
	else
		item:remove(1)
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Your lock pick broke.")
	end
	return true
end

-- Dorian: remove the mission item, accepting what upstream used to give.
function FT.takeVase(player)
	return player:removeItem(FT.VASE, 1) or player:removeItem(FT.OLD_VASE, 1)
end

function FT.takeGoblet(player)
	if player:removeItem(FT.GOBLET, 1) then
		return true
	end
	return get(player, S.GoldenGoblet) >= 1 and player:removeItem(FT.OLD_GOBLET, 1)
end

function FT.addAchievement(player, name)
	if player.hasAchievement and player:hasAchievement(name) then
		return
	end
	if player.addAchievement then
		player:addAchievement(name)
	end
end

-- Black Bert: only for those who finished the quest.
function FT.finished(player)
	return get(player, S.Mission08) >= 3 or get(player, S.Questline) >= 9
end

FT.blackBertRefusal = "Psst! I don't know you. I only deal with friends of Dorian's guild." -- ours

-- Percybald: a new kit when the first one was used up before the deal with Nurik (ours).
function FT.newKit(player)
	if get(player, S.Mission04) ~= 6 or player:getItemCount(FT.KIT) > 0 then
		return false
	end
	player:addItem(FT.KIT, 1)
	return true
end
FT.newKitLine = "You wasted my disguise kit already? Hmpf. Here is another one. Now get lost, fate awaits me!" -- ours
