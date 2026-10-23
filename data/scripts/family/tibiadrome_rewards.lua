-- Gaia Family server: Tibiadrome phase 2 (2026-10-23). Ours, not upstream.
-- Rotations, Drome points, potions by mail and the Drome Cube. The exchange
-- itself is the NPC Lorenzo (data-otservbr-global/npc/lorenzo.lua), who stands
-- in the lobby next to Xodet. The fights are in tibiadrome.lua.
--
-- As in Tibia (TibiaWiki BR "Tibiadrome"):
-- * A rotation lasts two weeks. Ours start on Wednesdays at 06:00 (server
--   time), the first on 2026-10-21. Combat modifiers are not used (decided
--   2026-10-18).
-- * When a rotation ends, every character who cleared at least one wave in it
--   gets points for his Drome level, and the places of the ranking get
--   concoctions (the Tibiadrome potions) in a parcel in the inbox, with a
--   letter: places 1-5 three, 6-10 two, 11-20 one; of the others, 20% (at most
--   50) get one by lot. Ties: lower experience when the level was reached wins.
-- * The Drome level starts again at 0; the next run starts 5 waves below the
--   last level reached (kv "start", see Family.dromeStartLevel).
-- * A Drome Cube (2,500 points at Lorenzo) gives one random concoction.
--
-- Ours:
-- * Points: 100 per Drome level (Tibia 10; x10 chosen by Rodrigo).
-- * The PC is often off when a rotation ends, so a character's rotation is
--   settled the first time he is seen afterwards: at login, at the arena
--   portals, when a wave is cleared, when talking to Lorenzo, and once a minute
--   for everyone online. The ranking is kept per rotation in the global KV
--   (written when a wave is cleared), so it does not depend on who logs in
--   first.
-- * Stamina Extension is never given (stamina never goes down on this server;
--   Rodrigo chose to leave it out).
-- * The concoctions themselves (effects, 1 hour while online, 24 hours until
--   the same one can be used again) are upstream: data/libs/systems/
--   concoctions.lua and data/scripts/systems/concoctions.lua.
--
-- Switch: Family.tibiadromeRewards (false = no rotations, points or mail; the
-- Drome level then never resets).

Family = Family or {}
Family.tibiadromeRewards = true

local R = {
	pointsPerLevel = 100,
	rotationDays = 14,
	firstRotation = { year = 2026, month = 10, day = 21, hour = 6, min = 0, sec = 0 }, -- a Wednesday
	startBelow = 5,
	potionsByPlace = { { 5, 3 }, { 10, 2 }, { 20, 1 } }, -- up to place, potions
	extraShare = 0.2,
	extraMax = 50,
	cubeId = 36827,
}
Family.dromeRewards = R

local EPOCH = os.time(R.firstRotation)
local ROTATION_SECONDS = R.rotationDays * 24 * 60 * 60
local RECORDS = "family-drome-rotations"
local LETTER = 3506 -- stamped letter (ITEM_LETTER_STAMPED is not a Lua constant)

local function playerKv(player)
	return player:kv():scoped("family-drome")
end

-- ---------------------------------------------------------------------------
-- Rotations
-- ---------------------------------------------------------------------------
function Family.dromeRotation(now)
	return math.max(0, math.floor(((now or os.time()) - EPOCH) / ROTATION_SECONDS))
end

function Family.dromeRotationEnd(rotation)
	return EPOCH + ((rotation or Family.dromeRotation()) + 1) * ROTATION_SECONDS
end

function Family.dromePoints(player)
	local points = playerKv(player):get("points")
	return type(points) == "number" and points or 0
end

function Family.addDromePoints(player, amount)
	playerKv(player):set("points", math.max(0, Family.dromePoints(player) + amount))
end

local function recordScope(rotation)
	return kv.scoped(RECORDS):scoped(tostring(rotation))
end

-- Called by tibiadrome.lua when a character reaches a new Drome level.
function Family.dromeRecord(player, level)
	if not Family.tibiadromeRewards then
		return
	end
	local scope = recordScope(Family.dromeRotation())
	local guid = player:getGuid()
	local old = scope:get("l" .. guid)
	if type(old) ~= "number" or level > old then
		scope:set("l" .. guid, level)
		scope:set("e" .. guid, player:getExperience())
	end
end

-- Everyone who cleared a wave in a rotation, best first.
function Family.dromeRanking(rotation)
	local scope = recordScope(rotation)
	local list = {}
	for _, key in ipairs(scope:keys() or {}) do
		local guid = tostring(key):match("^l(%d+)$")
		if guid then
			local level = scope:get(key)
			if type(level) == "number" and level > 0 then
				local exp = scope:get("e" .. guid)
				list[#list + 1] = { guid = tonumber(guid), level = level, exp = type(exp) == "number" and exp or 0 }
			end
		end
	end
	table.sort(list, function(a, b)
		if a.level ~= b.level then
			return a.level > b.level
		end
		if a.exp ~= b.exp then
			return a.exp < b.exp
		end
		return a.guid < b.guid
	end)
	return list
end

-- ---------------------------------------------------------------------------
-- Concoctions
-- ---------------------------------------------------------------------------
local potionIds
local function potionPool()
	if not potionIds then
		potionIds = {}
		for key, id in pairs(Concoction and Concoction.Ids or {}) do
			if key ~= "StaminaExtension" and type(id) == "number" then
				potionIds[#potionIds + 1] = id
			end
		end
		table.sort(potionIds)
	end
	return potionIds
end
Family.dromePotionPool = potionPool

function Family.dromeRandomPotion()
	local pool = potionPool()
	return pool[math.random(#pool)]
end

local function potionCount(place, total)
	for _, row in ipairs(R.potionsByPlace) do
		if place <= row[1] then
			return row[2]
		end
	end
	local rest = total - R.potionsByPlace[#R.potionsByPlace][1]
	if rest <= 0 then
		return 0
	end
	local extras = math.min(R.extraMax, math.floor(rest * R.extraShare))
	return math.random(rest) <= extras and 1 or 0
end

local function mailRewards(player, potions, lines)
	local inbox = player:getInbox()
	if not inbox then
		return false
	end
	local parcel = Game.createItem(ITEM_PARCEL_STAMPED, 1)
	if not parcel then
		return false
	end
	for _ = 1, potions do
		parcel:addItem(Family.dromeRandomPotion(), 1)
	end
	local letter = parcel:addItem(LETTER, 1)
	if letter then
		letter:setAttribute(ITEM_ATTRIBUTE_TEXT, table.concat(lines, "\n"))
	end
	return inbox:addItemEx(parcel, INDEX_WHEREEVER, FLAG_NOLIMIT) == RETURNVALUE_NOERROR
end

local function dateText(time)
	local t = os.date("*t", time)
	return string.format("%s, %d %s %d, %02d:%02d", os.date("%A", time), t.day, os.date("%B", time), t.year, t.hour, t.min)
end

-- 12500 -> "12,500"
function Family.dromeNumber(n)
	local text = tostring(math.floor(n))
	while true do
		local replaced
		text, replaced = text:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			return text
		end
	end
end
local num = Family.dromeNumber
Family.dromeDateText = dateText

-- Pays the rotations a character has not been paid for yet. Safe to call often.
function Family.dromeSettle(player)
	if not Family.tibiadromeRewards or not player then
		return
	end
	local k = playerKv(player)
	local now = Family.dromeRotation()
	local rotation = k:get("rotation")
	if type(rotation) ~= "number" then
		-- First time (Drome levels from phase 1 belong to the current rotation).
		k:set("rotation", now)
		local level = Family.dromeLevel(player)
		if level > 0 then
			Family.dromeRecord(player, level)
		end
		return
	end
	if rotation >= now then
		return
	end

	local level = Family.dromeLevel(player)
	k:set("level", 0)
	k:set("rotation", now)
	if level <= 0 then
		return -- did not fight in that rotation; "start" stays as it was
	end
	k:set("start", math.max(0, level - R.startBelow))

	local points = level * R.pointsPerLevel
	Family.addDromePoints(player, points)

	local ranking = Family.dromeRanking(rotation)
	local place = #ranking + 1
	for i, row in ipairs(ranking) do
		if row.guid == player:getGuid() then
			place = i
			break
		end
	end
	local total = math.max(#ranking, place)
	local potions = potionCount(place, total)

	local lines = {
		"Tibiadrome",
		string.format("Rotation that ended on %s", dateText(Family.dromeRotationEnd(rotation))),
		"",
		string.format("Dear %s,", player:getName()),
		string.format("you reached Drome level %d and place %d of %d.", level, place, total),
		string.format("%s Drome points were added to your account (now %s).", num(points), num(Family.dromePoints(player))),
		potions > 0 and string.format("Enclosed: %d concoction%s for your efforts.", potions, potions == 1 and "" or "s") or "No concoction this time.",
		"",
		"Lorenzo, Tibiadrome",
	}
	local mailed = mailRewards(player, potions, lines)
	local text = string.format("The Tibiadrome rotation is over: Drome level %d, place %d of %d, %s Drome points (now %s).%s Your next run starts at wave %d.", level, place, total, num(points), num(Family.dromePoints(player)), mailed and (potions > 0 and string.format(" %d concoction%s in your inbox.", potions, potions == 1 and " is" or "s are") or " A letter is in your inbox.") or "", math.max(0, level - R.startBelow) + 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, text)
	logger.info("[Family] Tibiadrome: {} paid for rotation {} (level {}, place {}/{}, {} points, {} potions)", player:getName(), rotation, level, place, total, points, potions)
end

-- ---------------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------------
local login = CreatureEvent("FamilyDromeRewardsLogin")

function login.onLogin(player)
	local playerId = player:getId()
	addEvent(function()
		local p = Player(playerId)
		if p then
			Family.dromeSettle(p)
		end
	end, 2000)
	return true
end

login:register()

-- Rotations that end while characters are online.
local watch = GlobalEvent("FamilyDromeRotationWatch")
local lastRotation = Family.dromeRotation()

function watch.onThink(interval)
	local now = Family.dromeRotation()
	if now ~= lastRotation then
		lastRotation = now
		for _, player in ipairs(Game.getPlayers()) do
			Family.dromeSettle(player)
		end
	end
	return true
end

watch:interval(60 * 1000)
watch:register()

-- Drome Cube: one random concoction (never Stamina Extension here).
local cube = Action()

function cube.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	local id = Family.dromeRandomPotion()
	if not id then
		return false
	end
	item:remove(1)
	player:addItem(id, 1)
	player:getPosition():sendMagicEffect(CONST_ME_GIFT_WRAPS)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You open the drome cube and find %s.", ItemType(id):getArticle() ~= "" and (ItemType(id):getArticle() .. " " .. ItemType(id):getName()) or ItemType(id):getName()))
	return true
end

cube:id(R.cubeId)
cube:register()

local startup = GlobalEvent("FamilyDromeRewardsStartup")

function startup.onStartup()
	local rotation = Family.dromeRotation()
	logger.info("[Family] Tibiadrome rewards: {}, rotation {} ends {}, {} points per level, {} concoctions in the pool", Family.tibiadromeRewards and "on" or "off", rotation, dateText(Family.dromeRotationEnd(rotation)), R.pointsPerLevel, #potionPool())
	return true
end

startup:register()
