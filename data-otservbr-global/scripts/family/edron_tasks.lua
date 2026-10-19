-- Gaia Family server: Edron City Tasks (2026-10-19). Ours, not upstream.
-- Asked by Rodrigo: Daniel Steelsoul's hunting tasks without level limits, a
-- free choice of task, several at once, rewards that grow with your level, new
-- tasks on Edron's hunting grounds, a quest log entry and an achievement.
--
-- Daniel Steelsoul (data-otservbr-global/npc/daniel_steelsoul.lua) gives 13
-- tasks: the four of Tibia (trolls, goblins, rotworms, cyclopes) and nine of
-- ours. Say "task": he hands out the rewards of finished tasks, tells you how
-- far you are with the others and lists the ones you can take. Say a task's
-- name and "yes" to take it; "cancel" gives one up. Any number of tasks can
-- run at once and every task can be repeated.
--
-- Reward of a task: a share of the experience your next level needs (never
-- less than the task's base experience; not multiplied by the experience
-- rates) and base gold x level / 20 (never less than the base gold).
--
-- Kills: the four Tibia tasks keep their upstream storages and counter
-- (scripts/quests/killing_in_the_name_of/creaturescripts_monster_kill.lua);
-- the new ones are counted here. Party kills count for every member, as in
-- the other task systems. A kill can count for Grizzly Adams too.
--
-- Quest log: "Edron City Tasks" (lib/core/quests/catalog/053_edron_city_tasks.lua),
-- one entry per task: progress while it runs, "(completed)" once finished at
-- least once. When every task was finished at least once the quest is
-- completed and the achievement "Champion of Edron" (secret, so the client
-- shows its name and text from the server) is given.

FamilyEdronTasks = FamilyEdronTasks or {}
local T = FamilyEdronTasks

T.achievement = "Champion of Edron"

local S = Storage.Quest.FamilyEdronTasks
local K = Storage.Quest.U8_5.KillingInTheNameOf

-- state: -1 never taken, 0 active, 1 finished. count: kills so far.
-- alt: first per-creature counter (creature k at alt + k - 1).
T.list = {
	{
		key = "trolls",
		words = { "troll", "trolls" },
		name = "trolls",
		kills = 100,
		creatures = { "troll", "troll champion" },
		where = "in the troll den west of Edron city",
		share = 0.03,
		exp = 200,
		gold = 200,
		state = K.TrollTask,
		count = K.MonsterKillCount.TrollCount,
		alt = K.AltKillCount.TrollCount,
		times = S.Times.Trolls,
		upstream = true,
	},
	{
		key = "goblins",
		words = { "goblin", "goblins" },
		name = "goblins",
		kills = 150,
		creatures = { "goblin", "goblin scavenger", "goblin assassin" },
		where = "in the goblin den west of Edron city",
		share = 0.03,
		exp = 300,
		gold = 250,
		state = K.GoblinTask,
		count = K.MonsterKillCount.GoblinCount,
		alt = K.AltKillCount.GoblinCount,
		times = S.Times.Goblins,
		upstream = true,
	},
	{
		key = "rotworms",
		words = { "rotworm", "rotworms" },
		name = "rotworms",
		kills = 300,
		creatures = { "rotworm", "carrion worm" },
		where = "in their tunnels south of Edron city",
		share = 0.05,
		exp = 1000,
		gold = 400,
		state = K.RotwormTask,
		count = K.MonsterKillCount.RotwormCount,
		alt = K.AltKillCount.RotwormCount,
		times = S.Times.Rotworms,
		upstream = true,
	},
	{
		key = "cyclopes",
		words = { "cyclops", "cyclopes" },
		name = "cyclopes",
		kills = 500,
		creatures = { "cyclops", "cyclops drone", "cyclops smith" },
		where = "in Cyclopolis north of Edron city",
		share = 0.10,
		exp = 3000,
		gold = 800,
		state = K.CyclopsTask,
		count = K.MonsterKillCount.CyclopsCount,
		alt = K.AltKillCount.CyclopsCount,
		times = S.Times.Cyclopes,
		upstream = true,
	},
	{
		key = "orcs",
		words = { "orc", "orcs" },
		name = "orcs",
		kills = 300,
		creatures = { "orc", "orc spearman", "orc warrior", "orc shaman", "orc berserker", "orc leader" },
		where = "in the orc lands of western Edron",
		share = 0.08,
		exp = 2000,
		gold = 600,
		base = S.Orcs,
		times = S.Times.Orcs,
	},
	{
		key = "dwarves",
		words = { "dwarf", "dwarves", "dwarfs" },
		name = "dwarves",
		kills = 200,
		creatures = { "dwarf", "dwarf soldier", "dwarf guard" },
		where = "in the dwarf mines of Cormaya",
		share = 0.05,
		exp = 1500,
		gold = 500,
		base = S.Dwarves,
		times = S.Times.Dwarves,
	},
	{
		key = "treelings",
		words = { "treeling", "treelings" },
		name = "treelings and leaf golems",
		kills = 300,
		creatures = { "haunted treeling", "leaf golem", "wilting leaf golem" },
		where = "in the Treeling Dungeon and the Dryad Gardens",
		share = 0.08,
		exp = 4000,
		gold = 1000,
		base = S.Treelings,
		times = S.Times.Treelings,
	},
	{
		key = "wyverns",
		words = { "wyvern", "wyverns" },
		name = "wyverns",
		kills = 200,
		creatures = { "wyvern" },
		where = "on Wyvern Hill",
		share = 0.08,
		exp = 4000,
		gold = 1000,
		base = S.Wyverns,
		times = S.Times.Wyverns,
	},
	{
		key = "undead",
		words = { "undead" },
		name = "undead",
		kills = 500,
		creatures = { "ghoul", "skeleton", "demon skeleton", "mummy", "crypt shambler", "bonebeast" },
		where = "on Ghoul Hill and in the undead lairs",
		share = 0.12,
		exp = 6000,
		gold = 1500,
		base = S.Undead,
		times = S.Times.Undead,
	},
	{
		key = "lycanthropes",
		words = { "lycanthrope", "lycanthropes", "werecreatures" },
		name = "lycanthropes",
		kills = 400,
		creatures = { "werewolf", "werebear", "wereboar", "werebadger", "werefox" },
		where = "in the lycanthrope grounds of Edron and Cormaya",
		share = 0.15,
		exp = 10000,
		gold = 2500,
		base = S.Lycanthropes,
		times = S.Times.Lycanthropes,
	},
	{
		key = "heroes",
		words = { "hero", "heroes" },
		name = "renegade heroes",
		kills = 300,
		creatures = { "hero", "renegade knight", "vicious squire", "vile grandmaster" },
		where = "in the hero fortress north of Edron",
		share = 0.15,
		exp = 10000,
		gold = 2500,
		base = S.Heroes,
		times = S.Times.Heroes,
	},
	{
		key = "dragons",
		words = { "dragon", "dragons" },
		name = "dragons",
		kills = 300,
		creatures = { "dragon", "dragon lord" },
		where = "in the dragon lair of Edron",
		share = 0.15,
		exp = 10000,
		gold = 2500,
		base = S.Dragons,
		times = S.Times.Dragons,
	},
	{
		key = "demons",
		words = { "demon", "demons" },
		name = "demons",
		kills = 300,
		creatures = { "demon" },
		where = "in the demon caves deep below Edron",
		share = 0.25,
		exp = 30000,
		gold = 5000,
		base = S.Demons,
		times = S.Times.Demons,
	},
}

for index, task in ipairs(T.list) do
	task.index = index
	if task.base then
		task.state = task.base
		task.count = task.base + 1
		task.alt = task.base + 2
	end
end

-- Helpers ---------------------------------------------------------------

local function get(player, key)
	return player:getStorageValue(key)
end

function T.isActive(player, task)
	return get(player, task.state) == 0
end

function T.kills(player, task)
	return math.max(get(player, task.count), 0)
end

function T.times(player, task)
	return math.max(get(player, task.times), 0)
end

local function plural(name)
	if name == "cyclops" then
		return "cyclopes"
	elseif name:match("man$") and not name:match("shaman$") then
		return name:sub(1, -4) .. "men"
	elseif name:match("wolf$") then
		return name:sub(1, -2) .. "ves"
	elseif name == "dwarf" then
		return "dwarves"
	elseif name:match("[^aeiou]y$") then
		return name:sub(1, -2) .. "ies"
	end
	return name .. "s"
end
T.plural = plural

-- "12 trolls and 3 troll champions"
function T.breakdown(player, task)
	local parts = {}
	for k, creature in ipairs(task.creatures) do
		local n = math.max(get(player, task.alt + k - 1), 0)
		parts[#parts + 1] = string.format("%d %s", n, n == 1 and creature or plural(creature))
	end
	if #parts == 1 then
		return parts[1]
	end
	return table.concat(parts, ", ", 1, #parts - 1) .. " and " .. parts[#parts]
end

function T.find(message)
	for _, task in ipairs(T.list) do
		for _, word in ipairs(task.words) do
			if MsgContains(message, word) then
				return task
			end
		end
	end
	return nil
end

function T.reward(player, task)
	local level = player:getLevel()
	local nextLevel = Game.getExperienceForLevel(level + 1) - Game.getExperienceForLevel(level)
	local exp = math.max(task.exp, math.floor(nextLevel * task.share))
	local gold = math.max(task.gold, math.floor(task.gold * level / 20))
	return exp, gold
end

function T.startQuest(player)
	if get(player, S.Questline) < 1 then
		player:setStorageValue(S.Questline, 1)
	end
end

function T.start(player, task)
	T.startQuest(player)
	player:setStorageValue(task.count, 0)
	for k = 1, #task.creatures do
		player:setStorageValue(task.alt + k - 1, 0)
	end
	player:setStorageValue(task.state, 0)
	if get(player, task.times) < 0 then
		player:setStorageValue(task.times, 0)
	else
		player:setStorageValue(task.times, get(player, task.times)) -- quest tracker refresh
	end
end

function T.cancel(player, task)
	local finishedBefore = T.times(player, task) > 0
	player:setStorageValue(task.state, finishedBefore and 1 or -1)
	player:setStorageValue(task.count, 0)
	if not finishedBefore then
		player:setStorageValue(task.times, -1) -- never finished: off the quest log again
	end
end

function T.allDone(player)
	for _, task in ipairs(T.list) do
		if T.times(player, task) < 1 then
			return false
		end
	end
	return true
end

function T.checkAchievement(player)
	if T.allDone(player) and not player:hasAchievement(T.achievement) then
		player:addAchievement(T.achievement)
	end
end

-- Hands in a finished task. Returns experience and gold given.
function T.finish(player, task)
	local exp, gold = T.reward(player, task)
	player:setStorageValue(task.state, 1)
	player:setStorageValue(task.times, T.times(player, task) + 1)
	player:addExperience(exp, true)
	player:addMoney(gold)
	T.checkAchievement(player)
	return exp, gold
end

-- Characters who did Daniel's tasks before 2026-10-19: count them.
function T.migrate(player)
	for _, task in ipairs(T.list) do
		local state, times = get(player, task.state), get(player, task.times)
		if state == 1 and times < 1 then
			player:setStorageValue(task.times, 1)
			T.startQuest(player)
		elseif state == 0 and times < 0 then
			player:setStorageValue(task.times, 0)
			T.startQuest(player)
		end
	end
	T.checkAchievement(player)
end

-- Kill counting for the new tasks --------------------------------------

local byCreature = {}
for _, task in ipairs(T.list) do
	if not task.upstream then
		for k, creature in ipairs(task.creatures) do
			byCreature[creature] = byCreature[creature] or {}
			table.insert(byCreature[creature], { task = task, k = k })
		end
	end
end

function T.countKill(player, creatureName)
	local entries = byCreature[creatureName:lower()]
	if not entries then
		return
	end
	for _, e in ipairs(entries) do
		local task = e.task
		if T.isActive(player, task) then
			local alt = task.alt + e.k - 1
			player:setStorageValue(alt, math.max(get(player, alt), 0) + 1)
			local n = T.kills(player, task) + 1
			player:setStorageValue(task.count, n)
			player:setStorageValue(task.times, get(player, task.times)) -- quest tracker refresh
			if n == task.kills then
				player:sendTextMessage(MESSAGE_EVENT_ADVANCE, string.format("You have killed %d %s. Report to Daniel Steelsoul in Edron for your reward.", task.kills, task.name))
			end
		end
	end
end

local death = CreatureEvent("FamilyEdronTaskDeath")

function death.onDeath(creature, corpse, lastHitKiller, mostDamageKiller)
	local name = creature:getName()
	onDeathForParty(creature, mostDamageKiller, function(_, player)
		T.countKill(player, name)
	end)
	return true
end

death:register()

local startup = GlobalEvent("FamilyEdronTaskStartup")

function startup.onStartup()
	local registered = 0
	for creature in pairs(byCreature) do
		local mType = MonsterType(creature)
		if mType then
			mType:registerEvent("FamilyEdronTaskDeath")
			registered = registered + 1
		else
			logger.error("[Family] Edron tasks: unknown creature {}", creature)
		end
	end
	logger.info("[Family] Edron tasks: {} tasks, kills of {} creatures counted for the new ones", #T.list, registered)
	return true
end

startup:register()

local login = CreatureEvent("FamilyEdronTaskLogin")

function login.onLogin(player)
	T.migrate(player)
	return true
end

login:register()
