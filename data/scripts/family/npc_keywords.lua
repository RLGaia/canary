-- Gaia Family server: NPCs understand their keywords better (2026-10-18).
-- Ours, not upstream.
--
-- Upstream's NPC system (data/npclib/npc_system/keyword_handler.lua) answers
-- the first keyword it finds anywhere inside what you said, even inside a
-- longer word, and compares keywords written with capital letters against
-- what you said in small letters. So:
-- * a short keyword stole the answer of a longer one: "crunor" and "norma"
--   got the answer of "no" (Hyacinth, Lily, Tom), "tibianus" the one of
--   "tibia", "uzgod" the one of "god", "intense healing" the one of "heal",
--   "lesser front sweep" the one of "front sweep";
-- * keywords with capitals never answered (the Blue Valley monks' "blue
--   valley", "name", "job"..., Kais, Kendra, Oswald, Sinatuki);
-- * keywords with a hyphen never answered ("enpa-deia", "three-fold path").
--
-- Here each NPC looks for the keyword in three rounds and answers the best
-- match of the earliest round:
--   1. the whole word ("no" does not match "crunor");
--   2. the start of a word ("heal" matches "healing", "spell" does not match
--      "spells", as before);
--   3. anywhere, as upstream (nothing that worked before stops working).
-- In a round the longest keyword wins ("lesser front sweep" before "front
-- sweep"); equal lengths keep the NPC's order (keywords with conditions,
-- such as a heal only for the wounded, work as before). Capitals and hyphens
-- in keywords are treated as plain letters. The order of the NPC menus is
-- kept: the answers of the topic you are in come first, then the topic above
-- it, then the NPC's main topics.
--
-- The upstream functions are replaced at startup (the NPC library loads after
-- this file), so the NPC files stay as they are.
--
-- Switch: Family.npcKeywordRounds (false = upstream matching).

Family = Family or {}
Family.npcKeywordRounds = true

local MAGIC = "[%%%^%$%(%)%[%]%*%+%?]" -- a real Lua pattern ("%d+" for amounts...)

local function plain(text)
	return (text:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0"))
end

-- Finds keyword in message (already lowercase) from position init.
-- round 1 = whole word, 2 = start of a word, 3 = anywhere.
-- Returns the start and end positions in message, or nil.
function Family.npcKeywordFind(message, keyword, round, init)
	init = init or 1
	if keyword:find(MAGIC) then
		-- a pattern, as upstream (the same in every round)
		return string.find(message, keyword, init)
	end
	local word = plain(keyword:lower())
	if round == 3 then
		return string.find(message, word, init)
	end
	-- pad with spaces so a word at the edges has a boundary
	local padded = " " .. message .. " "
	local pattern = "%W" .. word .. (round == 1 and "%W" or "")
	local a, b = string.find(padded, pattern, init)
	if not a then
		return nil
	end
	-- back to positions in message: a is the boundary before the word
	return a, (round == 1 and b - 2 or b - 1)
end

local function checkMessage(node, player, message, round)
	if node.keywords.callback ~= nil then
		if round ~= 1 then
			return false -- callbacks (greetings...) are asked once, in the first round
		end
		local ret, data = node.keywords.callback(node.keywords, message)
		if not ret then
			return false
		end
		if node.condition and not node.condition(Player(player), data) then
			return false
		end
		return true
	end

	local data = {}
	local last = 0
	for _, keyword in ipairs(node.keywords) do
		if type(keyword) == "string" then
			local a, b = Family.npcKeywordFind(message, keyword, round)
			if a == nil or b == nil or a < last then
				return false
			end
			if keyword:sub(1, 1) == "%" then
				data[#data + 1] = tonumber(message:sub(a, b)) or nil
			end
			last = a
		end
	end

	if node.condition and not node.condition(Player(player), data) then
		return false
	end
	return true
end

-- Letters in a node's keywords (greetings and other callbacks count 0).
local function keywordLength(node)
	if node.keywords.callback ~= nil then
		return 0
	end
	local length = 0
	for _, keyword in ipairs(node.keywords) do
		if type(keyword) == "string" and not keyword:find(MAGIC) then
			length = length + #keyword
		end
	end
	return length
end

local upstream = {}

local function install()
	if not KeywordNode or not KeywordHandler then
		return false
	end
	if not upstream.processNodeMessage then
		upstream.processNodeMessage = KeywordHandler.processNodeMessage
		upstream.checkMessage = KeywordNode.checkMessage
	end

	function KeywordNode:checkMessage(player, message, round)
		if not Family.npcKeywordRounds then
			return upstream.checkMessage(self, player, message)
		end
		return checkMessage(self, player, message, round or 3)
	end

	function KeywordHandler:processNodeMessage(node, npc, player, message)
		if not Family.npcKeywordRounds then
			return upstream.processNodeMessage(self, node, npc, player, message)
		end
		local playerId = player:getId()
		local messageLower = message:lower()
		local tried = {}
		for round = 1, 3 do
			-- matches of this round, longest keyword first (ties keep the NPC's order)
			local matches = {}
			for index, childNode in ipairs(node.children) do
				if not tried[childNode] and childNode:checkMessage(player, messageLower, round) then
					matches[#matches + 1] = { node = childNode, index = index, length = keywordLength(childNode) }
				end
			end
			table.sort(matches, function(a, b)
				if a.length ~= b.length then
					return a.length > b.length
				end
				return a.index < b.index
			end)
			for _, match in ipairs(matches) do
				local childNode = match.node
				tried[childNode] = true
				local oldLast = self.lastNode[playerId]
				self.lastNode[playerId] = childNode
				-- Make sure node is the parent of childNode (as one node can be parent to several nodes).
				childNode.parent = node
				if childNode:processMessage(npc, player, messageLower) then
					childNode:processAction(player, messageLower)
					return true
				end
				self.lastNode[playerId] = oldLast
			end
		end
		return false
	end
	return true
end

install() -- after a reload of the scripts

local startup = GlobalEvent("FamilyNpcKeywords")

function startup.onStartup()
	local ok = install()
	logger.info("[Family] NPC keywords: whole words first {}", ok and tostring(Family.npcKeywordRounds) or "NOT INSTALLED")
	return true
end

startup:register()
