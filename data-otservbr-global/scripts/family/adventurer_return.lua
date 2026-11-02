-- Gaia Family server: return fields in the Adventurers' Guild (2026-11-02,
-- asked by Rodrigo). Ours, not upstream.
--
-- The adventurer's stone works anywhere (data/scripts/family/adventurer_stone.lua),
-- but the guild's exit only leads to the home temple, so there was no way back
-- to the hunt. The guild now remembers the last two places where a player used
-- the stone, and two more magic forcefields lead back to them. In the exit row
-- on the guild floor (y 32292, z 6), seen from the room:
--
--   [left: second last place] [home temple] [home temple] [right: last place]
--        32208                   32209         32210          32211
--
-- The two new fields replace the obsidian statues beside the exit; a wall sign
-- above each one (instead of the tapestry) tells each player, when he looks at
-- it, where that field leads him: a temple, or the place's name on the
-- Cyclopedia map (e.g. "Edron Dragon Lair, 1 floor underground"; "near <city>"
-- where the map has no name), and how long ago he used the stone there.
--
-- Rules:
--   * Using the stone in the same spot as last time (same floor, up to 5
--     squares away) only refreshes the last place; it does not push the older
--     place out.
--   * Using the stone inside the guild records nothing.
--   * A field with no place yet, or whose place cannot be reached any more
--     (gone, no-logout area, boss or encounter room, a house you are not
--     invited to, blocked), sends you back with a message.
--   * The places stay after you use a field: you can go back as often as you
--     like.
--
-- Switch: Family.adventurerReturn (false = no fields or signs, nothing recorded).

Family = Family or {}
Family.adventurerReturn = true

local KV_SCOPE = "family-adventurer-return"
local SAME_SPOT = 5

local R = {
	-- aid 48770 = last place (right), 48771 = second last (left)
	fields = {
		{ key = "last", aid = 48770, pos = Position(32211, 32292, 6), sign = Position(32211, 32291, 6), side = "right" },
		{ key = "previous", aid = 48771, pos = Position(32208, 32292, 6), sign = Position(32208, 32291, 6), side = "left" },
	},
	statueId = 746, -- obsidian statue, replaced by the field
	fieldId = 1949, -- magic forcefield, as the guild's exit
	tapestryId = 2599, -- tapestry on the wall, replaced by the sign
	signId = 2023, -- wall sign for walls running west-east (2024 is for the other walls)
	-- The guild: the client's map subarea "Adventurers' Guild", plus a box for
	-- the few guild squares the client's shape misses (every square a player
	-- can walk to from the arrival is on floors 6-7 inside it; self-test).
	guildSubarea = "Adventurers' Guild",
	guild = { x1 = 32180, y1 = 32255, x2 = 32240, y2 = 32330, z1 = 6, z2 = 7 },
}
Family.adventurerReturnData = R

-- The client's Cyclopedia map name of a place (map discovery data), or nil.
local function subareaName(pos)
	if not (FamilyDiscovery and FamilyDiscovery.subareaAt and FamilyDiscoveryData) then
		return nil
	end
	local id = FamilyDiscovery.subareaAt(pos)
	local sub = id and FamilyDiscoveryData.subareas[id]
	return sub and sub.name or nil
end

local function inGuild(pos)
	if subareaName(pos) == R.guildSubarea then
		return true
	end
	local g = R.guild
	return pos.x >= g.x1 and pos.x <= g.x2 and pos.y >= g.y1 and pos.y <= g.y2 and pos.z >= g.z1 and pos.z <= g.z2
end
Family.adventurerReturnInGuild = inGuild

local function encode(pos, t)
	return string.format("%d,%d,%d,%d", pos.x, pos.y, pos.z, t or os.time())
end

local function decode(text)
	if type(text) ~= "string" then
		return nil
	end
	local x, y, z, t = text:match("^(%d+),(%d+),(%d+),(%d+)$")
	if not x then
		return nil
	end
	return Position(tonumber(x), tonumber(y), tonumber(z)), tonumber(t)
end

local function store(player)
	return player:kv():scoped(KV_SCOPE)
end

function Family.adventurerReturnGet(player, key)
	return decode(store(player):get(key))
end

-- Called by the adventurer's stone (actions/adventurers_guild/adventurers_stone.lua)
-- just before it takes the player to the guild.
function Family.adventurerReturnRecord(player, pos)
	if not Family.adventurerReturn or not player or not pos or inGuild(pos) then
		return false
	end
	local kv = store(player)
	local last = decode(kv:get("last"))
	local sameSpot = last and last.z == pos.z and math.max(math.abs(last.x - pos.x), math.abs(last.y - pos.y)) <= SAME_SPOT
	if last and not sameSpot then
		kv:set("previous", kv:get("last"))
	end
	kv:set("last", encode(pos))
	return true
end

-- The same limits as the stone itself, checked again when going back.
local function refusal(player, pos)
	local tile = Tile(pos)
	if not tile or not tile:getGround() then
		return "That place does not exist any more."
	end
	if tile:hasFlag(TILESTATE_NOLOGOUT) then
		return "The spiritual energy of that place is too strong."
	end
	if Zone and Zone.getByPosition then
		for _, zone in ipairs(Zone.getByPosition(pos) or {}) do
			local name = zone:getName() or ""
			if name:find("^boss%.") or name:find("^encounter") then
				return "The spiritual energy of that place is too strong."
			end
		end
	end
	local house = tile:getHouse()
	if house and house:getOwnerGuid() ~= player:getGuid() and not house:isInvited(player) then
		return "That place is in a house you are not invited to."
	end
	return nil
end

local function townsList()
	local list = {}
	for _, town in ipairs(Game.getTowns() or {}) do
		local temple = town:getTemplePosition()
		if temple and temple.x > 0 then
			list[#list + 1] = { name = town:getName(), temple = temple }
		end
	end
	return list
end

-- "the Edron temple" / "Edron Dragon Lair, 1 floor underground" (the client's
-- map name) / "near Edron, 3 floors underground" (where the map has no name)
function Family.adventurerReturnPlace(pos)
	local best, bestDist
	for _, town in ipairs(townsList()) do
		local d = math.max(math.abs(town.temple.x - pos.x), math.abs(town.temple.y - pos.y))
		if not bestDist or d < bestDist then
			best, bestDist = town, d
		end
	end
	if best and bestDist <= 10 and best.temple.z == pos.z then
		return "the " .. best.name .. " temple"
	end
	local text = subareaName(pos)
	if not text then
		if not best then
			return string.format("%d, %d, %d", pos.x, pos.y, pos.z)
		end
		text = "near " .. best.name
	end
	if pos.z > 7 then
		text = text .. string.format(", %d floor%s underground", pos.z - 7, pos.z - 7 == 1 and "" or "s")
	elseif pos.z < 7 then
		text = text .. string.format(", %d floor%s up", 7 - pos.z, 7 - pos.z == 1 and "" or "s")
	end
	return text
end

local function ago(t)
	local seconds = os.time() - (t or os.time())
	if seconds < 60 then
		return "just now"
	end
	return Game.getTimeInWords(seconds) .. " ago"
end

local function fieldAt(pos)
	for _, f in ipairs(R.fields) do
		if pos == f.pos then
			return f, false
		elseif pos == f.sign then
			return f, true
		end
	end
	return nil
end

local function destinationText(player, f)
	local pos, t = Family.adventurerReturnGet(player, f.key)
	if not pos then
		if f.key == "last" then
			return "nowhere yet: it remembers the last place where you use your adventurer's stone"
		end
		return "nowhere yet: it remembers the place before the last one where you used your adventurer's stone"
	end
	return string.format("%s (stone used %s)", Family.adventurerReturnPlace(pos), ago(t))
end

-- Called by the look event (eventcallbacks/player/on_look.lua): each player
-- reads his own places on the signs and fields.
function Family.adventurerReturnLookText(player, item, text)
	if not Family.adventurerReturn or not item or not item:isItem() then
		return text
	end
	local id = item:getId()
	if id ~= R.signId and id ~= R.fieldId then
		return text
	end
	local f, isSign = fieldAt(item:getPosition())
	if not f or (isSign and id ~= R.signId) or (not isSign and id ~= R.fieldId) then
		return text
	end
	if isSign then
		local which = f.key == "last" and "where you last used your adventurer's stone" or "where you used your adventurer's stone the time before"
		return string.format("%s\nThe %s field takes you back to %s: %s.\nThe two fields in the middle take you to your home temple.", text, f.side, which, destinationText(player, f))
	end
	return string.format("%s\nIt takes you to %s.", text, destinationText(player, f))
end

local function sendBack(player, fromPosition, position, message)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
	if fromPosition and fromPosition ~= position and fromPosition.x ~= 0 and player:teleportTo(fromPosition, true) then
		position:sendMagicEffect(CONST_ME_POFF)
	else
		position:sendMagicEffect(CONST_ME_POFF)
	end
end

local field = MoveEvent()

function field.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return true
	end
	local f
	for _, entry in ipairs(R.fields) do
		if entry.aid == item:getActionId() then
			f = entry
		end
	end
	if not f then
		return true
	end
	local destination = Family.adventurerReturnGet(player, f.key)
	if not destination then
		sendBack(player, fromPosition, position, "This field does not lead anywhere yet. It remembers the places where you use your adventurer's stone.")
		return true
	end
	local why = refusal(player, destination)
	if why then
		sendBack(player, fromPosition, position, why .. " This field cannot take you there.")
		return true
	end
	if not player:teleportTo(destination) then
		sendBack(player, fromPosition, position, "Something blocks that place. This field cannot take you there now.")
		return true
	end
	position:sendMagicEffect(CONST_ME_TELEPORT)
	destination:sendMagicEffect(CONST_ME_TELEPORT)
	return true
end

field:type("stepin")
for _, f in ipairs(R.fields) do
	field:aid(f.aid)
end
field:register()

-- Place the fields and signs (the map stays as upstream ships it).
local placer = GlobalEvent("FamilyAdventurerReturnPlace")

local function swap(pos, oldId, newId)
	local tile = Tile(pos)
	if not tile then
		return nil, "no square"
	end
	local existing = tile:getItemById(newId)
	if existing then
		return existing, "already there"
	end
	local old = tile:getItemById(oldId)
	if old then
		old:remove()
	end
	local item = Game.createItem(newId, 1, pos)
	return item, item and (old and "replaced" or "placed") or "FAILED"
end

function placer.onStartup()
	if not Family.adventurerReturn then
		return true
	end
	local notes = {}
	for _, f in ipairs(R.fields) do
		local item, how = swap(f.pos, R.statueId, R.fieldId)
		if item then
			item:setActionId(f.aid)
		end
		local _, signHow = swap(f.sign, R.tapestryId, R.signId)
		notes[#notes + 1] = string.format("%s field %s, sign %s", f.side, how, signHow)
	end
	logger.info("[Family] adventurer return fields: {}", table.concat(notes, "; "))
	return true
end

placer:register()
