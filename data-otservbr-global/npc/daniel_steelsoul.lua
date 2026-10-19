local internalNpcName = "Daniel Steelsoul"
local npcType = Game.createNpcType(internalNpcName)
local npcConfig = {}

npcConfig.name = internalNpcName
npcConfig.description = internalNpcName

npcConfig.health = 100
npcConfig.maxHealth = npcConfig.health
npcConfig.walkInterval = 2000
npcConfig.walkRadius = 2

npcConfig.outfit = {
	lookType = 73,
}

npcConfig.flags = {
	floorchange = false,
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

local condition = Condition(CONDITION_FIRE)
condition:setParameter(CONDITION_PARAM_DELAYED, 1)
condition:addDamage(14, 1000, -10)

-- FAMILY: Edron City Tasks dialogue helpers (see data-otservbr-global/scripts/family/edron_tasks.lua).
local function formatNumber(value)
	local text = tostring(math.floor(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

local function joinWords(words)
	if #words == 1 then
		return words[1]
	end
	return table.concat(words, ", ", 1, #words - 1) .. " and " .. words[#words]
end

local function offer(npc, creature, player, task)
	local T = FamilyEdronTasks
	if T.isActive(player, task) then
		npcHandler:say(string.format("You are already hunting %s for me: %d of %d so far.", task.name, T.kills(player, task), task.kills), npc, creature)
		npcHandler:setTopic(player:getId(), 0)
		return
	end
	local names = {}
	for _, c in ipairs(task.creatures) do
		names[#names + 1] = T.plural(c)
	end
	local exp, gold = T.reward(player, task)
	local again = T.times(player, task) > 0 and string.format(" You have done this %d time%s already.", T.times(player, task), T.times(player, task) == 1 and "" or "s") or ""
	npcHandler:say({
		string.format("I need %d %s killed, you find them %s. %s all count.%s ...", task.kills, task.name, task.where, joinWords(names):gsub("^%l", string.upper), again),
		string.format("At your level I can pay %s experience and %s gold for it. Will you take this task?", formatNumber(exp), formatNumber(gold)),
	}, npc, creature)
	npcHandler:setTopic(player:getId(), 100 + task.index)
end

local function confirmCancel(npc, creature, player, task)
	local T = FamilyEdronTasks
	if not T.isActive(player, task) then
		npcHandler:say(string.format("You are not hunting %s for me.", task.name), npc, creature)
		npcHandler:setTopic(player:getId(), 0)
		return
	end
	npcHandler:say(string.format("Do you really want to give up the %s task? The %d kills you have will be lost.", task.name, T.kills(player, task)), npc, creature)
	npcHandler:setTopic(player:getId(), 200 + task.index)
end

local function report(npc, creature, player)
	local T = FamilyEdronTasks
	local messages, progress, available = {}, {}, {}
	for _, task in ipairs(T.list) do
		if T.isActive(player, task) then
			if T.kills(player, task) >= task.kills then
				local exp, gold = T.finish(player, task)
				messages[#messages + 1] = string.format("You killed %d %s, well done! Here is your reward: %s experience and %s gold.", task.kills, task.name, formatNumber(exp), formatNumber(gold))
				available[#available + 1] = "{" .. task.key .. "}"
			else
				progress[#progress + 1] = string.format("%s %d/%d", task.key, T.kills(player, task), task.kills)
			end
		else
			available[#available + 1] = "{" .. task.key .. "}"
		end
	end
	if #progress > 0 then
		messages[#messages + 1] = "Keep going with your tasks: " .. joinWords(progress) .. "."
	end
	if #available > 0 then
		messages[#messages + 1] = "I can give you these tasks: " .. joinWords(available) .. ". Which one? You can take several, and {cancel} one you don't want any more."
	else
		messages[#messages + 1] = "You are already working on every task I have."
	end
	npcHandler:say(#messages == 1 and messages[1] or messages, npc, creature)
	npcHandler:setTopic(player:getId(), 10)
end

local function creatureSayCallback(npc, creature, type, message)
	local player = Player(creature)
	local playerId = player:getId()

	if not npcHandler:checkInteraction(npc, creature) then
		return false
	end

	if table.contains({ "fuck", "idiot", "asshole", "ass", "fag", "stupid", "tyrant", "shit", "lunatic" }, message) then
		npcHandler:say("Take this!", npc, creature)
		player:getPosition():sendMagicEffect(CONST_ME_EXPLOSIONAREA)
		player:addCondition(condition)
		npcHandler:removeInteraction(npc, creature)
		npcHandler:resetNpc(creature)
	elseif MsgContains(message, "mission") then
		if player:getStorageValue(Storage.Quest.U8_1.TibiaTales.AgainstTheSpiderCult) < 1 then
			npcHandler:setTopic(playerId, 1)
			npcHandler:say("Very good, we need heroes like you to go on a suici.....er....to earn respect of the authorities here AND in addition get a great reward for it. Are you interested in the job?", npc, creature)
		elseif player:getStorageValue(Storage.Quest.U8_1.TibiaTales.AgainstTheSpiderCult) == 5 then
			player:setStorageValue(Storage.Quest.U8_1.TibiaTales.AgainstTheSpiderCult, 6)
			npcHandler:setTopic(playerId, 0)
			player:addItem(814, 1)
			npcHandler:say("What? YOU DID IT?!?! That's...that's...er....<drops a piece of paper. You see the headline 'death certificate'> like I expected!! Here is your reward.", npc, creature)
		end
	-- FAMILY: Edron City Tasks (data-otservbr-global/scripts/family/edron_tasks.lua): no level
	-- limits, the player chooses the task, several at once, rewards scaled with level, nine new
	-- tasks. Upstream's fixed order and level ranges (6-19, 20-39, 30-59) are gone.
	elseif MsgContains(message, "cancel") then
		local task = FamilyEdronTasks.find(message)
		if task then
			confirmCancel(npc, creature, player, task)
		else
			local active = {}
			for _, t in ipairs(FamilyEdronTasks.list) do
				if FamilyEdronTasks.isActive(player, t) then
					active[#active + 1] = "{" .. t.key .. "}"
				end
			end
			if #active == 0 then
				npcHandler:say("You are not working on any task for me right now.", npc, creature)
				npcHandler:setTopic(playerId, 0)
			else
				npcHandler:say("Which task do you want to give up: " .. joinWords(active) .. "?", npc, creature)
				npcHandler:setTopic(playerId, 20)
			end
		end
	elseif npcHandler:getTopic(playerId) == 20 and FamilyEdronTasks.find(message) then
		confirmCancel(npc, creature, player, FamilyEdronTasks.find(message))
	elseif MsgContains(message, "task") or MsgContains(message, "tasks") then
		report(npc, creature, player)
	elseif FamilyEdronTasks.find(message) and not MsgContains(message, "yes") and not MsgContains(message, "no") then
		offer(npc, creature, player, FamilyEdronTasks.find(message))
	elseif MsgContains(message, "yes") then
		local topic = npcHandler:getTopic(playerId)
		if topic == 1 then
			player:setStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart, 1)
			player:setStorageValue(Storage.Quest.U8_1.TibiaTales.AgainstTheSpiderCult, 1)
			npcHandler:say({
				"Very well, maybe you know that the orcs here in Edron learnt to raise giant spiders. It is going to become a serious threat. ...",
				"The mission is simple: go to the orcs and destroy all spider eggs that are hatched by the giant spider they have managed to catch. The orcs are located in the south of the western part of the island.",
			}, npc, creature)
		elseif topic > 100 and topic <= 100 + #FamilyEdronTasks.list then
			local task = FamilyEdronTasks.list[topic - 100]
			FamilyEdronTasks.start(player, task)
			npcHandler:say(string.format("Good hunting! Kill %d %s %s and come back to me. I've noted it in your quest log.", task.kills, task.name, task.where), npc, creature)
			npcHandler:setTopic(playerId, 0)
		elseif topic > 200 and topic <= 200 + #FamilyEdronTasks.list then
			local task = FamilyEdronTasks.list[topic - 200]
			FamilyEdronTasks.cancel(player, task)
			npcHandler:say(string.format("Fine, forget about the %s. Ask me for a {task} whenever you want another one.", task.name), npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	elseif MsgContains(message, "no") then
		local topic = npcHandler:getTopic(playerId)
		if topic > 100 then
			npcHandler:say("As you wish. Say {task} if you want to see what else I have for you.", npc, creature)
			npcHandler:setTopic(playerId, 0)
		end
	end
	return true
end

keywordHandler:addKeyword({ "job" }, StdModule.say, { npcHandler = npcHandler, text = "I am the governor of this isle, Edron, and grandmaster of the Knights of Banor's Blood." })
keywordHandler:addKeyword({ "king" }, StdModule.say, { npcHandler = npcHandler, text = "LONG LIVE THE KING!" })

npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, creatureSayCallback)
npcHandler:setMessage(MESSAGE_GREET, "Greetings and {Banor} be with you, |PLAYERNAME|!")
npcHandler:setMessage(MESSAGE_FAREWELL, "PRAISE TO BANOR!")
npcHandler:setMessage(MESSAGE_WALKAWAY, "PRAISE TO BANOR!")
npcHandler:addModule(FocusModule:new(), npcConfig.name, true, true, true)

-- npcType registering the npcConfig table
npcType:register(npcConfig)
