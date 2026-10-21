-- Gaia Family server: the client's Spell List shows only the spells you know
-- (2026-10-18). Ours, not upstream.
--
-- With toggleLearnSpells = true (config.lua, as in Tibia) every instant spell
-- has to be bought from a spell teacher before it can be cast. But the server's
-- basic data packet (0x9F, sent at login), which tells the client which spells
-- the character knows, still marks every spell of the vocation as known unless
-- the spell script itself says it needs learning. So the Spell List showed
-- spells like Berserk as known and casting them said "You need to learn this
-- spell first.".
--
-- This sends the packet again with the spells the character can really cast:
-- a second after login, and right after a spell is learned or forgotten, the
-- vocation changes or the player data is reloaded. The rest of the packet is
-- the same as the server's (premium, vocation, prey window, magic shield).
-- The server also sends its own packet when the wheel of destiny is saved or
-- a gem is changed (client packets 0x62 and 0xE7, seen by the module
-- data/modules/scripts/family/spell_list.lua), when transcendence starts
-- and ends (seen here as the avatar outfit condition coming and going) and
-- when the character comes back after a death (seen as a pause in its
-- thinking); the right list follows half a second later.
--
-- Switch: Family.knownSpellList (false = upstream).

Family = Family or {}
Family.knownSpellList = true

local OPCODE_BASIC_DATA = 0x9F

-- spell name -> { id = client spell id, vocations = { [vocation name] = true } }
local spellInfo = {}

local function infoOf(name)
	local info = spellInfo[name]
	if info == nil then
		info = false
		local spell = Spell(name)
		if spell then
			local ok, id = pcall(function()
				return spell:id()
			end)
			local vocations = {}
			local okVoc, list = pcall(function()
				return spell:vocation()
			end)
			-- a table keyed "1", "2"... (strings), so pairs, not ipairs
			if okVoc and type(list) == "table" then
				for _, vocName in pairs(list) do
					if type(vocName) == "string" then
						vocations[vocName:lower()] = true
					end
				end
			end
			if ok and type(id) == "number" and id > 0 then
				info = { id = id, vocations = vocations }
			end
		end
		spellInfo[name] = info
	end
	return info or nil
end

-- magicshield of data/XML/vocations.xml, by vocation id (read once)
local magicShield

local function hasMagicShield(vocationId)
	if not magicShield then
		magicShield = {}
		local file = io.open(CORE_DIRECTORY .. "/XML/vocations.xml", "r") or io.open("data/XML/vocations.xml", "r")
		if file then
			for tag in file:read("*a"):gmatch("<vocation%s[^>]*>") do
				local id = tonumber(tag:match('%sid="(%d+)"'))
				if id then
					magicShield[id] = tag:match('magicshield="([^"]*)"') == "1"
				end
			end
			file:close()
		end
	end
	return magicShield[vocationId] == true
end

-- Client spell ids the character knows (spells of its vocation it can cast).
function Family.knownSpellIds(player)
	local vocation = player:getVocation()
	local vocName = vocation and vocation:getName():lower() or ""
	local ids, seen = {}, {}
	for _, spell in ipairs(player:getInstantSpells() or {}) do
		local info = spell.name and infoOf(spell.name)
		if info and info.vocations[vocName] and not seen[info.id] then
			seen[info.id] = true
			ids[#ids + 1] = info.id
		end
	end
	table.sort(ids)
	return ids
end

function Family.sendSpellList(player)
	if not Family.knownSpellList or not configManager.getBoolean(configKeys.LEARN_SPELLS) then
		return
	end
	local vocation = player:getVocation()
	if not vocation then
		return
	end
	local msg = NetworkMessage()
	msg:addByte(OPCODE_BASIC_DATA)
	if player:isPremium() or player:isVip() then
		msg:addByte(1)
		msg:addU32(os.time() + (player:getPremiumDays() + 1) * 86400)
	else
		msg:addByte(0)
		msg:addU32(0)
	end
	msg:addByte(vocation:getClientId())
	-- prey window: not before the character has a vocation (as the server)
	local group = player:getGroup()
	msg:addByte((vocation:getId() == 0 and (not group or group:getId() < 4)) and 0 or 1)
	local ids = Family.knownSpellIds(player)
	msg:addU16(#ids)
	for _, id in ipairs(ids) do
		msg:addU16(id)
	end
	msg:addByte(hasMagicShield(vocation:getId()) and 1 or 0)
	msg:sendToPlayer(player)
end

local function sendLater(player, delay)
	if not Family.knownSpellList then
		return
	end
	local playerId = player:getId()
	addEvent(function()
		local p = Player(playerId)
		if p then
			Family.sendSpellList(p)
		end
	end, delay or 100)
end

Family.sendSpellListLater = sendLater

-- After the server's own packet (it is sent with the other login data).
local login = CreatureEvent("FamilySpellListLogin")

function login.onLogin(player)
	sendLater(player, 1000)
	return true
end

login:register()

-- Learning, forgetting, changing vocation, reloading: send the right list.
local wrapped = {}
for _, method in ipairs({ "learnSpell", "forgetSpell", "setVocation", "reloadData" }) do
	local original = Player[method]
	if original and not wrapped[method] then
		wrapped[method] = true
		Player[method] = function(self, ...)
			local result = original(self, ...)
			if Family.knownSpellList and self and self.getId then
				sendLater(self, 100)
			end
			return result
		end
	end
end

-- Transcendence: the server sends its own list when the avatar outfit is put
-- on and again when it ends. Any combat outfit condition counts (a costume
-- too): sending the right list once more does no harm.
local outfitOn = {}

-- After a death (2026-10-20): the character leaves the game while the death
-- window is open and comes back with the same character object when "Ok" is
-- clicked; the server then sends its own list again (all spells of the
-- vocation) but no login event runs. The character does not think while it
-- is away, so a pause of a few seconds between two thinks means it has just
-- come back: send the right list again.
local lastThink = {}
local AWAY_SECONDS = 3

local think = EventCallback("FamilySpellListThink")

function think.playerOnThink(player, interval)
	if not Family.knownSpellList then
		return
	end
	local id = player:getId()
	local now = os.time()
	if lastThink[id] and now - lastThink[id] >= AWAY_SECONDS then
		sendLater(player, 500)
	end
	lastThink[id] = now
	local on = player:getCondition(CONDITION_OUTFIT, CONDITIONID_COMBAT) ~= nil
	if outfitOn[id] ~= nil and outfitOn[id] ~= on then
		sendLater(player, 500)
	end
	outfitOn[id] = on
end

think:register()

local logout = CreatureEvent("FamilySpellListLogout")

function logout.onLogout(player)
	outfitOn[player:getId()] = nil
	lastThink[player:getId()] = nil
	return true
end

logout:register()
