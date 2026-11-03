-- FAMILY: Gaia Family server, !commands and !help with explanations and examples
-- (2026-11-03, asked by Rodrigo: he did not know what some commands are for or
-- how to type them).
--   !commands            the commands you can use, by topic, one line each
--   !commands gm|god|tests   the staff pages (only for accounts that can use them)
--   !commands <command>  what it does, how to type it, examples, notes
--   !commands <word>     every command whose help mentions the word
-- !help is the same. The texts are in data/scripts/lib/family_commands.lua.
-- Only commands the account may use are shown (the engine checks the account
-- type, so this does too); commands the config switches off are named apart.
-- Upstream data/scripts/talkactions/player/commands.lua calls Family.showCommands.

Family = Family or {}
Family.commandsHelp = true -- false: upstream !commands (names only), no !help

local WINDOW_ITEM = 639 -- same window item as upstream !commands
local C = FamilyCommands

local pageAliases = {
	player = "player",
	players = "player",
	gm = "gm",
	gamemaster = "gm",
	gamemasters = "gm",
	god = "god",
	test = "tests",
	tests = "tests",
}

local function strip(word)
	return ((word or ""):lower():gsub("^%s+", ""):gsub("%s+$", ""):gsub("^[!/]", ""))
end

local function accountType(player)
	return player:getAccountType() or ACCOUNT_TYPE_NORMAL
end

-- every registered command word -> its TalkAction (keys like "!house,!houses")
local function registered()
	local map = {}
	for key, talkAction in pairs(Game.getTalkActions()) do
		for word in tostring(key):gmatch("[^,]+") do
			map[word:gsub("^%s+", ""):gsub("%s+$", "")] = talkAction
		end
	end
	return map
end

local function canUse(player, talkAction)
	local accType = accountType(player)
	return accType == ACCOUNT_TYPE_GOD or talkAction:getGroupType() <= accType
end

-- "ok", "off" or nil (not registered or not allowed for this account)
local function state(player, entry, reg)
	local talkAction
	for _, word in ipairs(entry.words) do
		talkAction = talkAction or reg[word]
	end
	if not talkAction or not canUse(player, talkAction) then
		return nil
	end
	if entry.on and not entry.on() then
		return "off"
	end
	return "ok"
end

local function pageOf(key)
	for _, page in ipairs(C.pages) do
		if page.key == key then
			return page
		end
	end
end

local function pageForGroup(groupType)
	if groupType <= 1 then
		return "player"
	elseif groupType < 6 then
		return "gm"
	end
	return "god"
end

local function catalogWords()
	local words = {}
	for _, entry in ipairs(C.list) do
		for _, word in ipairs(entry.words) do
			words[word] = true
		end
	end
	return words
end

-- registered commands with no help entry: { word, description, groupType }
local function others(player, reg)
	local known, seen, list = catalogWords(), {}, {}
	for word, talkAction in pairs(reg) do
		-- only ! and / commands (quest phrases such as "The sun guides..." are talkactions too)
		if word:find("^[!/]") and not known[word] and not seen[talkAction] and talkAction:getGroupType() > 0 and canUse(player, talkAction) then
			seen[talkAction] = true
			list[#list + 1] = { word = word, description = talkAction:getDescription() or "", groupType = talkAction:getGroupType() }
		end
	end
	table.sort(list, function(a, b)
		return a.word < b.word
	end)
	return list
end

local function allowedPages(player, reg)
	local pages = {}
	for _, entry in ipairs(C.list) do
		if state(player, entry, reg) then
			pages[entry.page] = true
		end
	end
	return pages
end

local function capitalize(text)
	return (text:gsub("^%l", string.upper))
end

local function listPage(player, pageKey, reg)
	local page = pageOf(pageKey)
	local lines = { page.title, "" }
	lines[#lines + 1] = "How to use one, with examples: !commands <name>"
	lines[#lines + 1] = pageKey == "player" and "for example !commands deposit" or "for example !commands " .. (pageKey == "gm" and "goto" or pageKey == "god" and "i" or "rewardbag")

	local pages = allowedPages(player, reg)
	local staff = {}
	for _, other in ipairs(C.pages) do
		if other.key ~= pageKey and pages[other.key] then
			staff[#staff + 1] = other.key == "player" and "!commands (everyone)" or "!commands " .. other.key
		end
	end
	if #staff > 0 and (pages.gm or pages.god or pages.tests) then
		lines[#lines + 1] = "Other pages: " .. table.concat(staff, ", ")
	end

	local topics, byTopic, off = {}, {}, {}
	for _, entry in ipairs(C.list) do
		if entry.page == pageKey then
			local s = state(player, entry, reg)
			if s == "off" then
				off[#off + 1] = entry.words[1]
			elseif s == "ok" then
				if not byTopic[entry.topic] then
					byTopic[entry.topic] = {}
					topics[#topics + 1] = entry.topic
				end
				local list = byTopic[entry.topic]
				list[#list + 1] = entry.words[1] .. " - " .. entry.short
			end
		end
	end
	for _, topic in ipairs(topics) do
		lines[#lines + 1] = ""
		lines[#lines + 1] = topic:upper()
		for _, line in ipairs(byTopic[topic]) do
			lines[#lines + 1] = line
		end
	end

	local extra = {}
	for _, other in ipairs(others(player, reg)) do
		if pageForGroup(other.groupType) == pageKey then
			extra[#extra + 1] = other.word .. (other.description ~= "" and (" " .. other.description) or "")
		end
	end
	if #extra > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "OTHER COMMANDS (no help text yet)"
		for _, line in ipairs(extra) do
			lines[#lines + 1] = line
		end
	end
	if #off > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "Switched off on this server: " .. table.concat(off, ", ")
	end
	return table.concat(lines, "\n")
end

local function detail(entry, entryState)
	local lines = { entry.words[1], "" }
	lines[#lines + 1] = capitalize(entry.about or entry.short) .. ((entry.about or entry.short):find("[%.!?\"]$") and "" or ".")
	if entry.page == "gm" then
		lines[#lines + 1] = "(gamemasters and GOD)"
	elseif entry.page == "god" or entry.page == "tests" then
		lines[#lines + 1] = "(GOD only)"
	end
	if entryState == "off" then
		lines[#lines + 1] = "Switched off on this server: " .. (entry.offWhy or "by the server config") .. "."
	end
	if entry.use and #entry.use > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "HOW TO TYPE IT"
		for _, use in ipairs(entry.use) do
			lines[#lines + 1] = "  " .. use
		end
	end
	if entry.ex and #entry.ex > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = #entry.ex > 1 and "EXAMPLES" or "EXAMPLE"
		for _, ex in ipairs(entry.ex) do
			lines[#lines + 1] = "  " .. ex[1]
			if ex[2] and ex[2] ~= "" then
				lines[#lines + 1] = "    -> " .. ex[2]
			end
		end
	end
	if entry.notes and #entry.notes > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "GOOD TO KNOW"
		for _, note in ipairs(entry.notes) do
			lines[#lines + 1] = "- " .. note
		end
	end
	if #entry.words > 1 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "Same command: " .. table.concat(entry.words, ", ", 2)
	end
	if entry.see and #entry.see > 0 then
		lines[#lines + 1] = ""
		lines[#lines + 1] = "See also: " .. table.concat(entry.see, ", ")
	end
	return table.concat(lines, "\n")
end

-- entries (and uncatalogued commands) matching the typed name exactly
local function findExact(player, query, reg)
	local found = {}
	local wantPrefix = query:match("^%s*([!/])")
	local name = strip(query)
	for _, entry in ipairs(C.list) do
		local s = state(player, entry, reg)
		if s then
			for _, word in ipairs(entry.words) do
				if strip(word) == name and (not wantPrefix or word:sub(1, 1) == wantPrefix) then
					found[#found + 1] = { entry = entry, state = s }
					break
				end
			end
		end
	end
	if #found == 0 then
		for _, other in ipairs(others(player, reg)) do
			if strip(other.word) == name and (not wantPrefix or other.word:sub(1, 1) == wantPrefix) then
				found[#found + 1] = { entry = { words = { other.word }, page = pageForGroup(other.groupType), short = other.description ~= "" and other.description or "no help text yet" }, state = "ok" }
			end
		end
	end
	return found
end

local function search(player, query, reg)
	local word = strip(query)
	local found = {}
	-- a typed command name (!x, /x) is not a word to search for; very short words match everything
	if query:find("^%s*[!/]") or #word < 3 then
		return found
	end
	for _, entry in ipairs(C.list) do
		local s = state(player, entry, reg)
		if s then
			local text = table.concat(entry.words, " ") .. " " .. entry.topic .. " " .. entry.short .. " " .. (entry.about or "") .. " " .. table.concat(entry.notes or {}, " ")
			if text:lower():find(word, 1, true) then
				found[#found + 1] = { entry = entry, state = s }
			end
		end
	end
	return found
end

-- the text !commands <param> shows (also used by the self-test)
function Family.commandsText(player, param)
	local reg = registered()
	local query = (param or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local key = pageAliases[query:lower()]
	if query == "" then
		key = "player"
	end
	if key then
		local page = pageOf(key)
		if key ~= "player" and not allowedPages(player, reg)[key] then
			return nil, "Those commands are only for staff accounts."
		end
		return listPage(player, page.key, reg)
	end

	local found = findExact(player, query, reg)
	if #found == 0 then
		found = search(player, query, reg)
		if #found > 1 then
			local lines = { string.format("Commands about \"%s\"", query), "", "Type !commands <name> for one of them." }
			lines[#lines + 1] = ""
			for _, hit in ipairs(found) do
				lines[#lines + 1] = hit.entry.words[1] .. " - " .. hit.entry.short
			end
			return table.concat(lines, "\n")
		end
	end
	if #found == 0 then
		return nil, string.format("No command or help about \"%s\". Type !commands for the list.", query)
	end
	local texts = {}
	for _, hit in ipairs(found) do
		texts[#texts + 1] = detail(hit.entry, hit.state)
	end
	return table.concat(texts, "\n\n----------\n\n")
end

function Family.showCommands(player, param)
	local text, message = Family.commandsText(player, param)
	if text then
		player:showTextDialog(WINDOW_ITEM, text)
	else
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, message)
	end
	return true
end

if Family.commandsHelp then
	local help = TalkAction("!help")

	function help.onSay(player, words, param)
		return Family.showCommands(player, param)
	end

	help:separator(" ")
	help:setDescription("- same as !commands: the commands, or how to use one (!help deposit)")
	help:groupType("normal")
	help:register()
end
