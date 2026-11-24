-- Gaia Family server: the Machinery of War Quest (2026-11-24). Ours: upstream had Baxter with the
-- bricklayers' kits, the broken walls, the war machines and the chalk board on the map, but no logic.
--
-- Sources: TibiaWiki BR backup ("Machinery of War Quest" with its screenshots and transcripts),
-- TibiaWiki EN ("Machinery of War Quest/Spoiler", "Baxter/Transcripts", "Bricklayers' Kit").
--
-- * Baxter: "mission" points to the orc war; "orc war" (level 50, EN) starts it and only then
--   sells bricklayers' kits (EN: "you need to have started the Machinery of War Quest");
--   "orc land", "war plans", "achievement" (both wikis' lines).
-- * Task 1, outposts: the 44 broken brick walls of the 6 outposts and walls around Ulderek's Rock
--   (our map). A bricklayers' kit repairs one. When a place is whole: "Orcs are attacking this
--   outpost!!" (BR screenshot) and orcs come every 30 s for 5 minutes (EN; the six creature lists
--   are EN's, which place gets which list is ours); orcs nobody killed leave after 10 minutes (EN).
-- * Task 2, the war machines: a fire bug on each of the 8 ballistae, 8 catapults and the 6 wheels
--   of the 2 siege towers (both wikis). They burn until the next reset.
-- * Walls and machines come back broken / unburnt 6 hours after they were all done (EN: "once
--   every 6~7 hours"), and at every server start.
-- * Achievements (EN): all the war machines burnt = 1; the outposts repaired twice = 1 (BR says
--   repairing alone gives nothing; EN is the more detailed and recent text, so we follow it).
--   1,000 experience each, 2,000 as War Hero; ranks at 3/6/12/20 with 2,000/3,000/5,000/7,000.
-- * Family rule (ours, two players): a task counts for everyone who did part of it once it is
--   complete, so father and son can share the walls and machines.
-- * Task 3, war plans: ask Baxter, use the chalk board in the orc fortress (floor 8, 32974/32975,
--   31773): "You know the current plans of the orcs now. Better tell Baxter about them." (BR
--   screenshot), without asking: "You have no clue whats this drawing is supposed to mean" (BR);
--   report for 1,000 experience; then "Come back in a few days" for 3 days (the days are ours).
-- * Quest log: Tibia Tales, "Orc War Rank" (BR names it; the texts are ours).
--
-- Loaded from lib/others/load.lua.

FamilyMachineryOfWar = {
	level = 50, -- EN
	kit = 7785,
	fireBug = 5467,
	resetTime = 6 * 60 * 60, -- EN: once every 6~7 hours
	plansCooldown = 3 * 24 * 60 * 60, -- ours ("a few days")
	exp = 1000,
	expHero = 2000,
	ranks = {
		{ need = 3, name = "henchman", exp = 2000, text = "Good news everyone!! %s will be promoted to 'henchman' of war! Congratulations!" },
		{ need = 6, name = "mercenary", exp = 3000, text = "Good news everyone!! %s will be promoted to 'mercenary' of war! Congratulations!" },
		{ need = 12, name = "orc butcher", exp = 5000, text = "Good news everyone!! %s will be promoted to the rank of an 'orc butcher'! Congratulations!" },
		{ need = 20, name = "war hero", exp = 7000, text = "Good news everyone!! %s will be promoted to the highest rank, a 'war hero'! Congratulations!" },
	},
	-- broken brick wall -> brick wall (our map: 6280/6282 lie in horizontal lines, 6281/6283 in vertical ones)
	repaired = { [6280] = 1271, [6281] = 1277, [6282] = 1271, [6283] = 1277 },
	-- the six places with broken walls (our map), with EN's orc lists
	sites = {
		{ box = { 32793, 31731, 32798, 31737 }, orcs = { ["Orc Warrior"] = 8, ["Orc Berserker"] = 14, ["Orc Shaman"] = 9, ["Orc Rider"] = 4, ["Orc Leader"] = 1, ["Orc Warlord"] = 1 } },
		{ box = { 32771, 31774, 32776, 31780 }, orcs = { ["Orc Warrior"] = 10, ["Orc Berserker"] = 13, ["Orc Shaman"] = 10, ["Orc Rider"] = 5, ["Orc Leader"] = 1, ["Orc Warlord"] = 1 } },
		{ box = { 32798, 31769, 32805, 31778 }, orcs = { ["Orc Warrior"] = 12, ["Orc Berserker"] = 15, ["Orc Shaman"] = 9, ["Orc Rider"] = 6, ["Orc Leader"] = 1, ["Orc Warlord"] = 1 } },
		{ box = { 32808, 31789, 32815, 31798 }, orcs = { ["Orc Warrior"] = 9, ["Orc Berserker"] = 9, ["Orc Shaman"] = 5, ["Orc Rider"] = 4, ["Orc Leader"] = 1 } },
		{ box = { 32791, 31812, 32796, 31818 }, orcs = { ["Orc Warrior"] = 8, ["Orc Berserker"] = 15, ["Orc Shaman"] = 7, ["Orc Rider"] = 5, ["Orc Leader"] = 1, ["Orc Warlord"] = 1 } },
		{ box = { 32852, 31816, 32857, 31822 }, orcs = { ["Orc Warrior"] = 10, ["Orc Berserker"] = 14, ["Orc Shaman"] = 11, ["Orc Rider"] = 4, ["Orc Leader"] = 2, ["Orc Warlord"] = 1 } },
	},
	machineAreas = { -- floor 7, our map
		{ kind = "ballista", ids = { 5695, 5696, 5697 }, box = { 32820, 31704, 32840, 31716 } },
		{ kind = "catapult", ids = { 5605, 5606, 5607, 5608 }, box = { 32900, 31730, 32912, 31744 } },
		{ kind = "wheel", ids = { 7775, 7776 }, box = { 32958, 31812, 32968, 31826 } },
	},
	fire = 2123, -- a fire field that does not go out by itself
	waves = 10, -- every 30 s for 5 minutes
	orcStay = 10 * 60, -- EN
	chalkBoard = { Position(32974, 31773, 8), Position(32975, 31773, 8) },
}

local M = FamilyMachineryOfWar

local function S()
	return Storage.Quest.U8_2.MachineryOfWar
end
M.S = S

function M.get(player, key)
	return math.max(0, player:getStorageValue(S()[key]))
end

function M.set(player, key, value)
	player:setStorageValue(S()[key], value)
end

-- runtime state (the map resets at every start, so this lives in memory)
M.walls = {} -- "x,y" -> { pos, broken id, site }
M.siteDone = {}
M.machines = {} -- list of { kind, squares = { Position }, burnt }
M.repairers = {} -- creature id -> true, this cycle
M.burners = {}
M.repairTimer = nil
M.burnTimer = nil
M.orcs = {}

local function key(pos)
	return pos.x .. "," .. pos.y .. "," .. pos.z
end

local function inBox(pos, box, z)
	return pos.z == (z or 7) and pos.x >= box[1] and pos.x <= box[3] and pos.y >= box[2] and pos.y <= box[4]
end

-- startup: find the broken walls and the war machines on the map
function M.setup()
	M.walls, M.machines = {}, {}
	for index, site in ipairs(M.sites) do
		local b = site.box
		site.walls = 0
		for x = b[1], b[3] do
			for y = b[2], b[4] do
				local pos = Position(x, y, 7)
				local tile = Tile(pos)
				if tile then
					for broken in pairs(M.repaired) do
						if tile:getItemById(broken) then
							M.walls[key(pos)] = { pos = pos, broken = broken, site = index }
							site.walls = site.walls + 1
						end
					end
				end
			end
		end
	end
	for _, area in ipairs(M.machineAreas) do
		local seen = {}
		local squares = {}
		local b = area.box
		for x = b[1], b[3] do
			for y = b[2], b[4] do
				local tile = Tile(Position(x, y, 7))
				if tile then
					for _, id in ipairs(area.ids) do
						if tile:getItemById(id) then
							squares[#squares + 1] = Position(x, y, 7)
							break
						end
					end
				end
			end
		end
		-- group touching squares into one machine
		for _, start in ipairs(squares) do
			if not seen[key(start)] then
				local machine = { kind = area.kind, squares = {}, burnt = false }
				local stack = { start }
				seen[key(start)] = true
				while #stack > 0 do
					local p = table.remove(stack)
					machine.squares[#machine.squares + 1] = p
					for _, q in ipairs(squares) do
						if not seen[key(q)] and math.abs(q.x - p.x) <= 1 and math.abs(q.y - p.y) <= 1 then
							seen[key(q)] = true
							stack[#stack + 1] = q
						end
					end
				end
				M.machines[#M.machines + 1] = machine
			end
		end
	end
	M.siteDone = {}
	logger.info("[FamilyMachineryOfWar] walls " .. M.countWalls() .. ", machines " .. #M.machines)
end

function M.countWalls()
	local n = 0
	for _ in pairs(M.walls) do
		n = n + 1
	end
	return n
end

local function siteRepaired(index)
	for _, wall in pairs(M.walls) do
		if wall.site == index then
			local tile = Tile(wall.pos)
			if tile and tile:getItemById(wall.broken) then
				return false
			end
		end
	end
	return true
end

local function allRepaired()
	for index in ipairs(M.sites) do
		if not siteRepaired(index) then
			return false
		end
	end
	return true
end

-- a bricklayers' kit; called from scripts/actions/tools/bricklayer_kit.lua
function M.onKit(player, item, target, toPosition)
	if not Family.machineryOfWar or type(target) ~= "userdata" or not target.isItem or not target:isItem() then
		return false
	end
	local wall = M.walls[key(toPosition)]
	if not wall or target.itemid ~= wall.broken then
		return false
	end
	target:transform(M.repaired[wall.broken])
	toPosition:sendMagicEffect(CONST_ME_POFF)
	item:remove(1)
	M.repairers[player:getId()] = true
	if not M.siteDone[wall.site] and siteRepaired(wall.site) then
		M.siteDone[wall.site] = true
		player:say("Orcs are attacking this outpost!!", TALKTYPE_MONSTER_SAY) -- BR screenshot
		M.attack(wall.site)
	end
	if allRepaired() and not M.repairTimer then
		for cid in pairs(M.repairers) do
			local p = Player(cid)
			if p then
				M.set(p, "Repairs", M.get(p, "Repairs") + 1)
				if M.get(p, "Repairs") >= 2 then
					M.set(p, "Repairs", 0)
					M.set(p, "Pending", M.get(p, "Pending") + 1)
				end
			end
		end
		M.repairers = {}
		M.repairTimer = addEvent(M.breakWalls, M.resetTime * 1000)
	end
	return true
end

function M.breakWalls()
	M.repairTimer = nil
	for _, wall in pairs(M.walls) do
		local tile = Tile(wall.pos)
		local whole = tile and tile:getItemById(M.repaired[wall.broken])
		if whole then
			whole:transform(wall.broken)
		end
	end
	M.siteDone = {}
	M.repairers = {}
end

local function freeSquare(site)
	local b = site.box
	for _ = 1, 80 do
		local pos = Position(math.random(b[1] - 6, b[3] + 6), math.random(b[2] - 6, b[4] + 6), 7)
		local tile = Tile(pos)
		if tile and tile:getGround() and not tile:hasFlag(TILESTATE_PROTECTIONZONE) and not tile:hasFlag(TILESTATE_BLOCKSOLID) and not tile:getTopCreature() then
			return pos
		end
	end
	return nil
end

-- orcs attack a repaired place: every 30 s for 5 minutes
function M.attack(index)
	local site = M.sites[index]
	local list = {}
	for name, count in pairs(site.orcs) do
		for _ = 1, count do
			list[#list + 1] = name
		end
	end
	local perWave = math.ceil(#list / M.waves)
	for wave = 1, M.waves do
		local function spawnWave()
			for i = (wave - 1) * perWave + 1, math.min(wave * perWave, #list) do
				local pos = freeSquare(site)
				local orc = pos and Game.createMonster(list[i], pos, false, true)
				if orc then
					M.spawned = (M.spawned or 0) + 1
					pos:sendMagicEffect(CONST_ME_TELEPORT)
					local id = orc:getId()
					addEvent(function()
						local c = Creature(id)
						if c then
							c:remove()
						end
					end, M.orcStay * 1000)
				end
			end
		end
		if wave == 1 then
			spawnWave()
		else
			addEvent(spawnWave, (wave - 1) * 30 * 1000)
		end
	end
end

local function machineAt(pos)
	for _, machine in ipairs(M.machines) do
		for _, p in ipairs(machine.squares) do
			if p == pos then
				return machine
			end
		end
	end
	return nil
end

local function allBurnt()
	for _, machine in ipairs(M.machines) do
		if not machine.burnt then
			return false
		end
	end
	return #M.machines > 0
end

-- a fire bug on a war machine; called from scripts/quests/others/actions_fire_bug.lua
function M.onFireBug(player, toPosition)
	if not Family.machineryOfWar then
		return false
	end
	local machine = machineAt(toPosition)
	if not machine then
		return false
	end
	if machine.burnt then
		return true
	end
	machine.burnt = true
	for _, p in ipairs(machine.squares) do
		Game.createItem(M.fire, 1, p)
		p:sendMagicEffect(CONST_ME_HITBYFIRE)
	end
	M.burners[player:getId()] = true
	if allBurnt() and not M.burnTimer then
		for cid in pairs(M.burners) do
			local p = Player(cid)
			if p then
				M.set(p, "Pending", M.get(p, "Pending") + 1)
			end
		end
		M.burners = {}
		M.burnTimer = addEvent(M.putOutFires, M.resetTime * 1000)
	end
	return true
end

function M.putOutFires()
	M.burnTimer = nil
	for _, machine in ipairs(M.machines) do
		for _, p in ipairs(machine.squares) do
			local tile = Tile(p)
			local fire = tile and tile:getItemById(M.fire)
			if fire then
				fire:remove()
			end
		end
		machine.burnt = false
	end
	M.burners = {}
end

function M.rankIndex(player)
	return math.max(0, M.get(player, "Rank") - 1)
end

-- Baxter
function M.baxter(npc, creature, message, npcHandler)
	if not Family.machineryOfWar then
		return false
	end
	local player = creature and creature:getPlayer()
	if not player then
		return false
	end
	if MsgContains(message, "orc war") then
		if M.get(player, "Rank") > 0 then
			return false -- upstream: "I have already told you about your mission! ..."
		end
		if player:getLevel() < M.level then
			npcHandler:say("I have no use for recruits who die in the first skirmish! Come back when you are better trained!", npc, creature) -- EN
			return true
		end
		M.set(player, "Rank", 1)
		if player:getStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart) < 1 then
			player:setStorageValue(Storage.Quest.U8_1.TibiaTales.DefaultStart, 1)
		end
		npcHandler:say({
			"I hope you know where to find orc land!! There are various things that you can do for your country! First of all, we need to establish some outposts that need to be maintained. ...",
			"For that, you can buy bricklayer kits from me. Just tell me if you need some. Secondly, the orcs are building ballistae, catapults and siege towers for their attack! Set them on fire! ...",
			"Thirdly, we need to find out what they are planning. Go find the current war plans! Actually they are not THAT smart, so they don't change them very often. Ask me first before you are heading there for nothing! ...",
			"That would be all for the moment. Oh I forgot, you collect achievement points while you're on duty. Ask me regularly about them, you might get a promotion if you're doing well!",
		}, npc, creature)
		return true
	end
	if MsgContains(message, "mission") or MsgContains(message, "quest") or MsgContains(message, "work") then
		npcHandler:say({
			"We've got a rat problem in the sewers. In the name of our glorious king, I'm paying 1 blinking piece of gold for every freshly killed rat you bring me. ...",
			"You seem strong! Do you want to help fighting the orcs? They prepare themselves for war! We need everyone who's capable of killing greenskins! Ask me about the orc war if you are interested.",
		}, npc, creature)
		return true
	end
	if MsgContains(message, "orc land") then
		npcHandler:say("It's north east of here. Pass the mountains of Kazordoon and go east. Past the wyvern nest, you'll find our outpost and then you'll enter Ulderek's Rock. Take care!", npc, creature)
		return true
	end
	if M.get(player, "Rank") < 1 then
		return false
	end
	if MsgContains(message, "war plans") or MsgContains(message, "war plan") then
		local plans = M.get(player, "Plans")
		if plans == 2 then
			M.set(player, "Plans", 0)
			M.set(player, "PlansTime", os.time())
			player:addExperience(M.exp, true)
			npcHandler:say("Great job!! I have to discuss their plans with the king immediately. Keep it up!", npc, creature)
		elseif os.time() - M.get(player, "PlansTime") < M.plansCooldown then
			npcHandler:say("We already know their current plan! Come back in a few days. By then they might have changed their plans and I will have a mission for you.", npc, creature)
		else
			M.set(player, "Plans", 1)
			npcHandler:say("The orcs are moving their troops. We need to know what they are up to! Go to the orc fortress. There should be some kind of blackboard somewhere. Study it and tell me their plans!", npc, creature)
		end
		return true
	end
	if MsgContains(message, "achievement") or MsgContains(message, "achievements") then
		local pending = M.get(player, "Pending")
		if pending < 1 then
			npcHandler:say("You have not done anything for the war since we last spoke. The outposts and the orc machines are waiting for you!", npc, creature) -- ours
			return true
		end
		M.set(player, "Pending", 0)
		local lines = {}
		for _ = 1, pending do
			local count = M.get(player, "Achievements") + 1
			M.set(player, "Achievements", count)
			local rank = M.rankIndex(player)
			player:addExperience(rank >= #M.ranks and M.expHero or M.exp, true)
			local nextRank = M.ranks[rank + 1]
			if nextRank and count >= nextRank.need then
				M.set(player, "Rank", rank + 2)
				player:addExperience(nextRank.exp, true)
				lines[#lines + 1] = string.format(nextRank.text, player:getName())
			end
		end
		if #lines == 0 then
			local rank = M.rankIndex(player)
			if rank == 0 then
				lines[1] = "Not bad, you will come a long way if you keep up the good work!"
			else
				lines[1] = string.format("Salutations %s %s!! Keep up the good work! Here you go.", M.ranks[rank].name, player:getName())
			end
		end
		npcHandler:say(#lines == 1 and lines[1] or lines, npc, creature)
		return true
	end
	return false
end

-- the war plans on the chalk board
function M.useChalkBoard(player)
	if M.get(player, "Plans") ~= 1 then
		player:say("You have no clue whats this drawing is supposed to mean", TALKTYPE_MONSTER_SAY) -- BR
		return true
	end
	M.set(player, "Plans", 2)
	player:say("You know the current plans of the orcs now. Better tell Baxter about them.", TALKTYPE_MONSTER_SAY) -- BR screenshot
	return true
end

-- Baxter's trade: kits only for those who started (EN)
function M.mayBuy(player, itemId)
	if not Family.machineryOfWar or itemId ~= M.kit then
		return true
	end
	return M.get(player, "Rank") > 0
end
