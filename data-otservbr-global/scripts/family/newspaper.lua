-- Gaia Family server: the daily newspaper (2026-10-14).
--
-- Ours, not upstream. A newspaper seller stands near the temple of each city
-- in FamilyCityLife.cities and sells today's edition for 1 gold coin
-- (hi -> newspaper -> yes). The newspaper is a "golden newspaper" item renamed
-- "newspaper"; using it opens the edition. Its text is written when it is
-- bought and never changes, so a paper from an earlier day shows that day's
-- news, with its date at the top. A new day starts at 06:00, the server
-- save time (like the daily reward).
--
-- What an edition holds: boosted creature and boss; where Rashid, Yasir and
-- the travelling vendors are; world changes (Fury Gate, Nightmare Isle,
-- Grimvale, Their Master's Voice); rare creatures and bosses seen today or
-- still possible today, and where classic raids can strike; active events
-- (experience, loot, skill); server updates of the last week and the
-- adventurers' chronicle of the last day played (since 2026-10-26, see
-- chronicle.lua); server notes.
--
-- Reading is hooked into data/scripts/actions/items/dolls.lua (FAMILY: edit),
-- which already handles "use" on the golden newspaper.

Family = Family or {}

FamilyNewspaper = {
	enabled = true,
	title = "Gaia Times",
	price = 1,
	itemId = 8153, -- golden newspaper (picture of a newspaper)
	weight = 100, -- 1.00 oz instead of 24 oz
	dayStartHour = 6, -- a new edition every day at the server save time
}

local cfg = FamilyNewspaper
if not cfg.enabled then
	return
end

local MARK = "family-newspaper-day"
local cityLife = FamilyCityLife or {}
local cities = cityLife.cities or {}

-- ---------------------------------------------------------------------------
-- Dates: the "newspaper day" runs from 06:00 to 06:00.
-- ---------------------------------------------------------------------------
local function dayStart(now)
	now = now or os.time()
	local t = os.date("*t", now)
	t.hour, t.min, t.sec = cfg.dayStartHour, 0, 0
	local start = os.time(t)
	if start > now then
		start = start - 24 * 60 * 60
	end
	return start
end

local function dayKey(now)
	return os.date("%Y-%m-%d", dayStart(now))
end

local function longDate(key)
	local y, m, d = key:match("(%d+)-(%d+)-(%d+)")
	local stamp = os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
	return os.date("%A, %B ", stamp) .. tonumber(d) .. os.date(", %Y", stamp)
end

-- ---------------------------------------------------------------------------
-- News sources
-- ---------------------------------------------------------------------------
local function nearestCity(position)
	local best, bestDistance
	for _, city in ipairs(cities) do
		local c = city.center
		if c then
			local distance = math.max(math.abs(c.x - position.x), math.abs(c.y - position.y))
			if not bestDistance or distance < bestDistance then
				best, bestDistance = city.name, distance
			end
		end
	end
	return best
end

local function rashidCity()
	local rashid = Npc("Rashid")
	if rashid then
		return nearestCity(rashid:getPosition())
	end
	local route = cityLife.rashidCity
	return route and route[os.date("*t").wday]
end

local furyGateCities = { "Ab'Dendriel", "Ankrahmun", "Carlin", "Darashia", "Edron", "Kazordoon", "Liberty Bay", "Port Hope", "Thais", "Venore" }

local function furyGateCity()
	local id = GlobalStorage and GlobalStorage.FuryGates and Game.getStorageValue(GlobalStorage.FuryGates)
	return id and furyGateCities[id]
end

local function nightmareIsle()
	local isles = GlobalStorage and GlobalStorage.WorldBoard and GlobalStorage.WorldBoard.NightmareIsle
	if not isles then
		return nil
	end
	local names = { AnkrahmunNorth = "north of Ankrahmun", DarashiaNorth = "north of Darashia", DarashiaWest = "west of Darashia" }
	for key, label in pairs(names) do
		if isles[key] and Game.getStorageValue(isles[key]) == 1 then
			return label
		end
	end
	return nil
end

-- Their Master's Voice (Edron, 20% of server starts): the world change script
-- sets FamilyTheirMastersVoiceActive when it triggers (FAMILY: edit in
-- scripts/world_changes/their_masters_voice.lua).
local function theirMastersVoice()
	return FamilyTheirMastersVoiceActive == true
end

local raidNames = {
	["thais.rats"] = "A rat plague in Thais",
	["thais.wild-horses"] = "Wild horses near Thais",
	["undead-cavebear"] = "The Undead Cavebear",
	["tiquanda.midnight-panther"] = "The Midnight Panther in Tiquanda",
	["folda.yeti"] = "The Yeti on Folda",
	["farmine.draptor"] = "Draptors and Grand Mother Foulscale near Farmine",
	["edron.white-pale"] = "White Pale near Edron",
	["svargrond.hirintror"] = "Hirintror near Svargrond",
	["darashia.tyrn"] = "Tyrn near Darashia",
	["fury-gates.furiosa"] = "Furyosa at the Fury Gates",
	["muggy_plains.battlemaster_zunzu"] = "Battlemaster Zunzu on the Muggy Plains",
	["drefia.arachir"] = "Arachir the Ancient One in Drefia",
	["ankrahmun.the-welter"] = "The Welter near Ankrahmun",
	["nargor.diblis"] = "Diblis the Fair on Nargor",
	["roshamuul.mawhawk"] = "Mawhawk on Roshamuul",
	["edron.valorcrest"] = "Sir Valorcrest near Edron",
	["venore.the-old-widow"] = "The Old Widow near Venore",
	["drefia.the-pale-count"] = "The Pale Count in Drefia",
	["edron.weakened-shlorg"] = "Weakened Shlorg near Edron",
}

local function prettify(text)
	return (text:gsub("[_%-%.]", " "):gsub("(%a)([%w']*)", function(a, b)
		return a:upper() .. b
	end))
end

local function raidNews()
	local seen, possible = {}, {}
	if not Raid or not Raid.registry then
		return seen, possible
	end
	local since = dayStart()
	for name, raid in pairs(Raid.registry) do
		local label = raidNames[name] or prettify(name)
		local last = raid.kv and raid.kv:get("last-occurrence") or 0
		if last >= since then
			local alive = false
			for id in pairs(raid.familySpawned or {}) do
				if Monster(id) then
					alive = true
					break
				end
			end
			seen[#seen + 1] = string.format("%s (%s%s)", label, os.date("%H:%M", last), alive and ", still roaming" or "")
		elseif not raid.allowedDays or raid:isAllowedDay() then
			possible[#possible + 1] = label
		end
	end
	table.sort(seen)
	table.sort(possible)
	return seen, possible
end

local classicRaidPlaces
local function classicRaidRegions()
	if classicRaidPlaces then
		return classicRaidPlaces
	end
	classicRaidPlaces = {}
	local path = configManager.getString(configKeys.DATA_DIRECTORY) .. "/raids/raids.xml"
	local file = io.open(path, "r")
	if not file then
		return classicRaidPlaces
	end
	local content = file:read("*a"):gsub("<!%-%-.-%-%->", "")
	file:close()
	local fixed = { abdendriel = "Ab'Dendriel", liberty_bay = "Liberty Bay", port_hope = "Port Hope" }
	local seen = {}
	for folder in content:gmatch('<raid%s[^>]-file="([^/"]+)/') do
		local place = fixed[folder] or prettify(folder)
		if not seen[place] then
			seen[place] = true
			classicRaidPlaces[#classicRaidPlaces + 1] = place
		end
	end
	table.sort(classicRaidPlaces)
	return classicRaidPlaces
end

local function vendorNews()
	local byKind = {}
	local order = {}
	local walkers = cityLife.internal and cityLife.internal.walkers or {}
	for _, walker in ipairs(walkers) do
		if walker.kind and walker.city then
			local title = walker.kind.title
			if not byKind[title] then
				byKind[title] = {}
				order[#order + 1] = title
			end
			table.insert(byKind[title], walker.city.name)
		end
	end
	local lines = {}
	for _, title in ipairs(order) do
		table.sort(byKind[title])
		lines[#lines + 1] = string.format("  %s%s: %s", title:sub(1, 1):upper(), title:sub(2), table.concat(byKind[title], ", "))
	end
	return lines
end

local function eventNews()
	local lines = {}
	if FamilyWinter and FamilyWinter.newsLines then
		for _, text in ipairs(FamilyWinter.newsLines()) do
			lines[#lines + 1] = text
		end
	end
	if not EventsScheduler then
		return lines
	end
	local function add(value, what)
		value = tonumber(value) or 100
		if value > 100 then
			lines[#lines + 1] = string.format("  %s +%d%%", what, value - 100)
		end
	end
	add(EventsScheduler.getEventSExp(), "Experience")
	add(EventsScheduler.getEventSLoot(), "Loot")
	add(EventsScheduler.getEventSBossLoot(), "Boss loot")
	add(EventsScheduler.getEventSSkill(), "Skill training")
	add(EventsScheduler.getSpawnMonsterSchedule(), "Monster respawn")
	return lines
end

-- ---------------------------------------------------------------------------
-- The edition
-- ---------------------------------------------------------------------------
function Family.newspaperText(key)
	key = key or dayKey()
	local out = {}
	local function line(text)
		out[#out + 1] = text or ""
	end

	line(cfg.title:upper())
	line(longDate(key))
	line("Today's edition, until tomorrow's server save at " .. string.format("%02d:00", cfg.dayStartHour) .. ".")
	line()

	line("BOOSTED TODAY")
	local creature = Game.getBoostedCreature()
	local boss = Game.getBoostedBoss()
	line("  Creature: " .. ((creature and creature ~= "") and creature or "not announced yet"))
	line("  Boss: " .. ((boss and boss ~= "") and boss or "not announced yet"))
	line()

	line("TRADERS")
	local rashid = rashidCity()
	line("  Rashid buys almost any loot in " .. (rashid or "an unknown city") .. " today.")
	if FamilyYasirCity then
		line("  Yasir, the oriental trader, has docked in " .. FamilyYasirCity .. ".")
	end
	local vendors = vendorNews()
	if #vendors > 0 then
		line("  Travelling vendors in town:")
		for _, v in ipairs(vendors) do
			line("  " .. v)
		end
	end
	line()

	line("WORLD CHANGES")
	local changes = 0
	local fury = furyGateCity()
	if fury then
		line("  A Fury Gate has opened in " .. fury .. ".")
		changes = changes + 1
	end
	local isle = nightmareIsle()
	if isle then
		line("  A Nightmare Isle has risen " .. isle .. ".")
		changes = changes + 1
	end
	if tonumber(os.date("%d", dayStart())) == 13 then
		line("  Full moon over Grimvale: wereboars and werebadgers roam.")
		changes = changes + 1
	end
	if theirMastersVoice() then
		line("  Their Master's Voice: slime is spreading beneath Edron. The Servant Sentry asks for help.")
		changes = changes + 1
	end
	if changes == 0 then
		line("  Nothing unusual reported.")
	end
	line()

	line("INVASIONS AND RARE CREATURES")
	local seen, possible = raidNews()
	if #seen > 0 then
		line("  Seen today: " .. table.concat(seen, "; ") .. ".")
	end
	if #possible > 0 then
		line("  May appear today: " .. table.concat(possible, "; ") .. ".")
	end
	local places = classicRaidRegions()
	if #places > 0 then
		line("  Raiders may strike near: " .. table.concat(places, ", ") .. ".")
	end
	line("  They return about every half hour once defeated.")
	line()

	line("EVENTS")
	local events = eventNews()
	if #events == 0 then
		line("  No special events today.")
	else
		for _, e in ipairs(events) do
			line(e)
		end
	end
	line()

	-- Since 2026-10-26: the server changelog (scripts/lib/family_changelog.lua)
	-- and the adventurers' chronicle of the last day played (chronicle.lua).
	if Family.changelogLines then
		local changes = Family.changelogLines(key)
		if #changes > 0 then
			line("SERVER UPDATES")
			for _, change in ipairs(changes) do
				line(change)
			end
			line()
		end
	end

	if Family.chronicleLines then
		local day, chronicle = Family.chronicleLines(key)
		line("ADVENTURERS' CHRONICLE")
		if day then
			line("  " .. longDate(day) .. ":")
			for _, text in ipairs(chronicle) do
				line(text)
			end
		else
			line("  No adventures were recorded in the last days.")
		end
		line()
	end

	line("SERVER NOTES")
	line("  The world is saved every 15 minutes; type /save to save now.")
	line("  Daily reward and newspaper renew at " .. string.format("%02d:00", cfg.dayStartHour) .. ".")
	line("  Houses: say !house. All commands: !commands.")
	return table.concat(out, "\n")
end

-- Leftover of an earlier version, which put this notice in front of older
-- papers every time they were read (the client stores the shown text in the
-- item, so it piled up). Removed from papers when they are read.
local OLD_NOTICE = "OLD EDITION %([^\n]*%)%.\nToday's news is sold by any newspaper seller%.\n\n"

-- The text shown when a newspaper item is used, or nil when the item is not
-- one of ours. The edition's date is in its first lines, so older papers
-- need no extra notice.
local function displayText(item)
	if not item or item:getId() ~= cfg.itemId then
		return nil
	end
	local key = item:getCustomAttribute(MARK)
	if not key or key == "" then
		return nil
	end
	local text = item:getAttribute(ITEM_ATTRIBUTE_TEXT) or ""
	return (text:gsub(OLD_NOTICE, ""))
end

-- Shows a bought newspaper. Returns true when the item is one of ours.
function Family.readNewspaper(player, item)
	local text = displayText(item)
	if not text then
		return false
	end
	player:showTextDialog(item, text)
	return true
end

local function printNewspaper(item)
	local key = dayKey()
	item:setAttribute(ITEM_ATTRIBUTE_NAME, "newspaper")
	item:setAttribute(ITEM_ATTRIBUTE_ARTICLE, "a")
	item:setAttribute(ITEM_ATTRIBUTE_WEIGHT, cfg.weight)
	item:setAttribute(ITEM_ATTRIBUTE_DESCRIPTION, string.format("The %s of %s. Use it to read.", cfg.title, longDate(key)))
	item:setAttribute(ITEM_ATTRIBUTE_TEXT, Family.newspaperText(key))
	item:setCustomAttribute(MARK, key)
	return item
end

local function makeNewspaper(player)
	local item = player:addItem(cfg.itemId, 1)
	if not item then
		return nil
	end
	return printNewspaper(item)
end

-- ---------------------------------------------------------------------------
-- The sellers
-- ---------------------------------------------------------------------------
local function sellerName(cityName)
	return cityName .. " Newspaper Seller"
end

local function createSellerType(cityName)
	local name = sellerName(cityName)
	local npcType = Game.createNpcType(name)
	local npcConfig = {
		name = name,
		description = name,
		health = 100,
		maxHealth = 100,
		walkInterval = 3000,
		walkRadius = 3,
		outfit = { lookType = 128, lookHead = 78, lookBody = 106, lookLegs = 58, lookFeet = 76, lookAddons = 0 },
		flags = { floorchange = false },
		speechBubble = SPEECHBUBBLE_NORMAL,
		voices = {
			interval = 15000,
			chance = 35,
			{ text = "Extra! Extra! Read all about it!" },
			{ text = "Today's " .. cfg.title .. ", only " .. cfg.price .. " gold!" },
			{ text = "Boosted creatures, traders, invasions... all in the " .. cfg.title .. "!" },
		},
	}

	local keywordHandler = KeywordHandler:new()
	local npcHandler = NpcHandler:new(keywordHandler)

	npcType.onThink = function(npc, interval)
		npcHandler:onThink(npc, interval)
	end
	npcType.onAppear = function(npc, creature)
		npcHandler:onAppear(npc, creature)
	end
	npcType.onDisappear = function(npc, creature)
		npcHandler:onDisappear(npc, creature)
	end
	npcType.onMove = function(npc, creature, fromPosition, toPosition)
		npcHandler:onMove(npc, creature, fromPosition, toPosition)
	end
	npcType.onSay = function(npc, creature, type, message)
		npcHandler:onSay(npc, creature, type, message)
	end
	npcType.onCloseChannel = function(npc, creature)
		npcHandler:onCloseChannel(npc, creature)
	end

	npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, function(npc, creature, type, message)
		local player = Player(creature)
		if not player or not npcHandler:checkInteraction(npc, creature) then
			return false
		end
		local playerId = player:getId()

		if npcHandler:getTopic(playerId) == 1 then
			npcHandler:setTopic(playerId, 0)
			if MsgContains(message, "yes") then
				if not player:removeMoneyBank(cfg.price) then
					npcHandler:say("You need " .. cfg.price .. " gold coin for the newspaper.", npc, creature)
					return true
				end
				if not makeNewspaper(player) then
					player:addMoney(cfg.price)
					npcHandler:say("Your hands are full! Make some room in your backpack and ask me again.", npc, creature)
					return true
				end
				npcHandler:say("Here you are, fresh from the press! Use it to read. Come back tomorrow for the next edition.", npc, creature)
				player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
			else
				npcHandler:say("Maybe tomorrow, then.", npc, creature)
			end
			return true
		end

		if MsgContains(message, "newspaper") or MsgContains(message, "paper") or MsgContains(message, "news") or MsgContains(message, "buy") or MsgContains(message, "times") then
			npcHandler:say(string.format("Today's %s, %s, for %d gold coin. Want one?", cfg.title, longDate(dayKey()), cfg.price), npc, creature)
			npcHandler:setTopic(playerId, 1)
		elseif MsgContains(message, "boost") or MsgContains(message, "headline") then
			npcHandler:say("Today's headline: everyone is hunting " .. (Game.getBoostedCreature() or "something") .. "! The rest is in the {newspaper}.", npc, creature)
		elseif MsgContains(message, "job") then
			npcHandler:say("I sell the " .. cfg.title .. ". A new edition every morning at " .. string.format("%02d:00", cfg.dayStartHour) .. ". Want a {newspaper}?", npc, creature)
		elseif MsgContains(message, "name") then
			npcHandler:say("Just call me the paperboy. Want a {newspaper}?", npc, creature)
		end
		return true
	end)

	npcHandler:setMessage(MESSAGE_GREET, "Hello, |PLAYERNAME|! Today's {newspaper} is out: boosted creatures, traders, invasions. Only " .. cfg.price .. " gold!")
	npcHandler:setMessage(MESSAGE_FAREWELL, "Read all about it, |PLAYERNAME|!")
	npcHandler:setMessage(MESSAGE_WALKAWAY, "Extra! Extra!")
	npcHandler:addModule(FocusModule:new(), name, true, true, false)

	npcType:register(npcConfig)
end

for _, city in ipairs(cities) do
	createSellerType(city.name)
end

local newspaperSellers = GlobalEvent("FamilyNewspaperSellers")

function newspaperSellers.onStartup()
	local placed = 0
	for _, city in ipairs(cities) do
		local npc = Game.createNpc(sellerName(city.name), city.center, true)
		if npc then
			npc:setMasterPos(npc:getPosition())
			placed = placed + 1
		else
			logger.warn("[Family] newspaper: no free tile near the center of {}", city.name)
		end
	end
	logger.info("[Family] newspaper: {} sellers, {} gold per {} (new edition at {})", placed, cfg.price, cfg.title, string.format("%02d:00", cfg.dayStartHour))
	return true
end

newspaperSellers:register()

-- Test hooks (used by temporary self-tests only).
cfg.internal = { dayKey = dayKey, displayText = displayText, printNewspaper = printNewspaper, markKey = MARK }
