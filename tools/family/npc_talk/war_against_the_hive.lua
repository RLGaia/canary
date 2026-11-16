-- Gaia Family server: War Against the Hive Quest check (2026-11-16).
-- One character plays Orockle's missions with the real NPC file: greeting, fight, mission lists by
-- stage, the six missions (offer, items, reminders, report, rewards, achievements), quit (one or
-- several missions, the 30-minute wait), the pheromone reward, news, points, and the Hive stages
-- over several game days (scaled shared counter), the guides' "hive" keyword, the hive gate rule
-- and the quest log texts. Mission steps done with objects are set as storages here; the objects
-- are checked by the server self-test.
--   luajit tools/family/npc_talk/war_against_the_hive.lua
local T = dofile("tools/family/npc_talk/npc_talk.lua")
MAPMARK_TICK = 0
Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
Game.getTimeInWords = Game.getTimeInWords or function(s) return tostring(s) .. " seconds" end
local kvStore = {}
kv = {
	scoped = function(name)
		kvStore[name] = kvStore[name] or {}
		local data = kvStore[name]
		return {
			get = function(_, k) return data[k] end,
			set = function(_, k, v) data[k] = v end,
			remove = function(_, k) data[k] = nil end,
		}
	end,
}
dofile("data-otservbr-global/lib/others/family_pilgrimage.lua")
dofile("data-otservbr-global/lib/others/family_hive.lua")
local H = FamilyHive
local S = H.S

local orockle = T.load("data-otservbr-global/npc/orockle.lua")
local luke = T.load("data-otservbr-global/npc/guide_luke.lua")
local rahlkora = T.load("data-otservbr-global/npc/guide_rahlkora.lua")

local function has(answer, text)
	return answer:find(text, 1, true) ~= nil
end
local function check(name, answer, text)
	return T.check(name, has(answer, text), answer:sub(1, 140))
end

local function player(o)
	local p = T.player(o)
	p.achievements, p.exp, p.marks = {}, 0, 0
	rawset(p, "addAchievement", function(self, name) self.achievements[name] = true return true end)
	rawset(p, "hasAchievement", function(self, name) return self.achievements[name] == true end)
	rawset(p, "addExperience", function(self, n) self.exp = self.exp + n end)
	rawset(p, "addMapMark", function(self) self.marks = self.marks + 1 end)
	return p
end

local DAY = 24 * 60 * 60
local now = os.time()
local function nextDay()
	now = now + DAY
	return H.refresh(now)
end

-- ---------------------------------------------------------------- stage 1
T.check("starts at stage 1", H.stage() == 1)
local p = player({ level = 120, name = "Saradoc Knight" })
check("greeting (EN/BR)", orockle:say(p, "hi"), "Greetings pilgrim! I sense you are here to {fight} the {Hive Born}.")
check("fight (EN)", orockle:say(p, "fight"), "You can help in the fight against the hive.")
local list = orockle:say(p, "mission")
check("stage 1 mission list (BR/EN)", list, "You could try to {blind} the hive")
T.check("stage 1: no kill/break in the list", not has(list, "{kill}"), list)
check("quit hint", list, "You can always {quit} a mission of course.")
check("kill at stage 1: ours", orockle:say(p, "kill"), "still too strong")
check("reward at stage 1: not open yet", orockle:say(p, "reward"), "only collect your reward if the Hive has already started to open itself")
check("news at stage 1", orockle:say(p, "news"), "The hive is well defended and prepared for war. 0 actions")
check("guide Luke: hive", luke:say(p, "hi") .. luke:say(p, "hive"), "The hive is well defended")
check("guide Rahlkora: hive", rahlkora:say(p, "hi") .. rahlkora:say(p, "hive"), "The hive is well defended")

-- the four stage 1 missions
local items = { acid = { [14255] = 1, [14052] = 8 }, blind = { [13974] = 1 }, digestion = { [13976] = 1 }, disable = { [14051] = 1 } }
for _, key in ipairs({ "acid", "blind", "digestion", "disable" }) do
	local m = H.byKey[key]
	local offer = orockle:say(p, key)
	check(key .. ": offer (BR/EN)", offer, m.offer[1]:sub(1, 40))
	check(key .. ": offer ends with the question", offer, "Do you want to take this mission?")
	local before = {}
	for id in pairs(items[key]) do before[id] = p.items[id] or 0 end
	check(key .. ": yes (BR/EN)", orockle:say(p, "yes"), m.accept:sub(1, 30))
	for id, count in pairs(items[key]) do
		T.check(key .. ": got item " .. id .. " x" .. count, (p.items[id] or 0) - before[id] == count, tostring(p.items[id]))
	end
	T.check(key .. ": progress 0", p.storage[m.progress] == 0)
	T.check(key .. ": times 0 (quest log line)", p.storage[m.times] == 0)
	check(key .. ": asked again before done", orockle:say(p, key), "You have not finished this mission yet: 0 of " .. m.need)
end
T.check("questline started", p.storage[S.Questline] == 1)
T.check("digestion: map mark", p.marks == 1)
check("quest log: mission line while active", H.describeMission(p, H.byKey.blind), "Antennae Blinding: 0 of 8 antennae blinded.")

-- report all four
for _, key in ipairs({ "acid", "blind", "digestion", "disable" }) do
	local m = H.byKey[key]
	p.storage[m.progress] = m.need
	check(key .. ": quest log says report", H.describeMission(p, m), "Report to Orockle")
	local exp = p.exp
	check(key .. ": report (BR/EN)", orockle:say(p, key), m.report:sub(1, 30))
	T.check(key .. ": 1000 experience", p.exp - exp == 1000, p.exp - exp)
	T.check(key .. ": progress cleared", p.storage[m.progress] == -1)
	T.check(key .. ": times 1", p.storage[m.times] == 1)
	check(key .. ": quest log after", H.describeMission(p, m), "You have done this mission 1 time.")
end
T.check("4 war experience", H.warExp(p) == 4, H.warExp(p))
T.check("4 favour", H.favour(p) == 4, H.favour(p))
T.check("4 actions today", H.actionsToday() == 4, H.actionsToday())
check("points (ours)", orockle:say(p, "points"), "4 war experience against the hive and 4 favour")
check("news counts the actions", orockle:say(p, "news"), "4 actions have been taken against the Hive Born. 10 actions are necessary")

-- achievements at 10 reports
p.storage[H.byKey.acid.times] = 9
orockle:say(p, "acid")
orockle:say(p, "yes")
p.storage[H.byKey.acid.progress] = 8
orockle:say(p, "acid")
T.check("Gatherer at 10 acid reports", p.achievements["Gatherer"] == true)
T.check("no Supplier yet", not p.achievements["Supplier"])

-- quit
orockle:say(p, "blind")
orockle:say(p, "yes")
check("quit with one mission", orockle:say(p, "quit"), "Are you sure you want to quit your current mission?")
check("no: ours", orockle:say(p, "no"), "As you wish.")
orockle:say(p, "digestion")
orockle:say(p, "yes")
check("quit with two missions asks which (ours)", orockle:say(p, "quit"), "Which mission do you want to quit: {blind}, {digestion}?")
check("which: blind", orockle:say(p, "blind"), "Are you sure you want to quit your current mission?")
check("quit: yes (EN)", orockle:say(p, "yes"), "So be it. Should you choose to start it again")
T.check("blind quit", p.storage[H.byKey.blind.progress] == -1)
T.check("digestion still running", p.storage[H.byKey.digestion.progress] == 0)
check("quit again within 30 minutes (EN)", orockle:say(p, "quit"), "You need to wait 30 minutes before you can quit another mission.")
check("blind can be taken again", orockle:say(p, "blind"), H.byKey.blind.offer[1]:sub(1, 30))
orockle:say(p, "no")

-- ---------------------------------------------------------------- stages over days
for _ = 1, 5 do H.addAction() end -- 4 + 1 (Gatherer report) + 5 = 10
T.check("10 actions today", H.actionsToday() == 10, H.actionsToday())
T.check("still stage 1 until the server save", H.stage() == 1)
T.check("next day: stage 2", nextDay() == 2)
check("guide at stage 2 (EN)", luke:say(p, "hive"), "The defences of the hive are breached. The hive structure to the east is open. 0 actions")
list = orockle:say(p, "mission")
check("stage 2 mission list (BR/EN)", list, "As usual you could try to {blind} the hive")
check("stage 2 list has kill and break", list, "it is also possible to {kill} the guards or to {break} the control crystals")
T.check("a day without actions: stays stage 2 (ours)", nextDay() == 2)

for _, key in ipairs({ "kill", "break" }) do
	local m = H.byKey[key]
	check(key .. ": offer (BR/EN)", orockle:say(p, key), m.offer[1]:sub(1, 40))
	check(key .. ": yes", orockle:say(p, "yes"), m.accept:sub(1, 20))
	p.storage[m.progress] = m.need
	local exp, war = p.exp, H.warExp(p)
	check(key .. ": report", orockle:say(p, key), m.report:sub(1, 25))
	T.check(key .. ": 1500 experience", p.exp - exp == 1500)
	T.check(key .. ": 2 war experience", H.warExp(p) - war == 2)
end
T.check("reagent flask given", (p.items[14054] or 0) == 1)

-- pheromone reward
check("reward with too little favour", orockle:say(p, "reward"), "Your efforts are commendable (" .. H.favour(p) .. "/50).")
p.storage[S.Favour] = 60
check("reward offer (BR/EN)", orockle:say(p, "reward"), "Your efforts are commendable (60/50). If you wish, I grant you a treatment")
check("reward: yes (EN)", orockle:say(p, "yes"), "So be it! Keep in mind it will wear off after a week")
T.check("50 favour taken", H.favour(p) == 10)
T.check("pheromone for a week", H.pheromoneLeft(p) > 6 * DAY and H.pheromoneLeft(p) <= 7 * DAY)
check("reward again: not worn off (ours)", orockle:say(p, "reward"), "The pheromone on you has not worn off yet.")

-- gates: stage 2 + pheromone = no entry
T.check("gate closed at stage 2", H.gatePass(p, 13291, { x = 33484, y = 31205, z = 7 }, { x = 33485, y = 31205, z = 7 }) == false)
check("gate message at stage 2 (ours)", p.log[#p.log] and p.log[#p.log].text or table.concat(p.log, " "), "not weakened enough")

-- stage 3
for _ = 1, 10 do H.addAction() end
T.check("next day: stage 3", nextDay() == 3)
check("guide at stage 3 (EN)", luke:say(p, "hive"), "The hives defences have fallen.")
T.check("gate opens with pheromone at stage 3 (east to west)", H.gatePass(p, 13291, { x = 33484, y = 31205, z = 7 }, { x = 33485, y = 31205, z = 7 }) == true)
local q = player({ name = "Father" })
T.check("gate refuses without pheromone", H.gatePass(q, 13291, { x = 33484, y = 31204, z = 7 }, { x = 33485, y = 31204, z = 7 }) == false)
p.storage[S.Pheromone] = os.time() - 1 -- worn off inside
T.check("worn off inside: can still leave (other square of the same gate)", H.gatePass(p, 13290, { x = 33484, y = 31204, z = 7 }, { x = 33483, y = 31204, z = 7 }) == true)
T.check("outside again without pheromone: refused", H.gatePass(p, 13290, { x = 33484, y = 31204, z = 7 }, { x = 33485, y = 31204, z = 7 }) == false)
T.check("north/south gate: same rule", H.gatePass(q, 13279, { x = 33589, y = 31238, z = 7 }, { x = 33589, y = 31237, z = 7 }) == false)

for day = 1, 4 do
	T.check("stage 3 day " .. (day + 1), nextDay() == 3)
end
check("last day of stage 3: guide warns (ours)", luke:say(p, "hive"), "But not for long: 10 actions today")
T.check("last day without actions: back to stage 1", nextDay() == 1)

-- stage 3 that holds: back to stage 2
for _ = 1, 10 do H.addAction() end
nextDay()
for _ = 1, 10 do H.addAction() end
T.check("stage 3 again", nextDay() == 3)
for _ = 1, 4 do nextDay() end
for _ = 1, 10 do H.addAction() end
T.check("enough actions on the last day: stage 2", nextDay() == 2)
T.check("several days at once (server off): 2 empty days keep stage 2", H.refresh(now + 3 * DAY) == 2)

-- war experience achievements and quest log
p.storage[S.WarExp] = 299
H.addWarExp(p, 1)
T.check("Hive Fighter at 300", p.achievements["Hive Fighter"] == true)
H.addWarExp(p, 200)
T.check("Hive War Veteran at 500", p.achievements["Hive War Veteran"] == true)
check("quest log: war line", H.describeWar(p), "You have gained 500 war experience")
local quest = dofile("data-otservbr-global/lib/core/quests/catalog/060_war_against_the_hive.lua")
T.check("quest log: 7 missions", #quest.missions == 7, #quest.missions)
check("quest log mission text from the catalog", quest.missions[2].description(p), "Chitin Dissolving")

-- switch off: Orockle as upstream (greets, says nothing about missions)
Family.warAgainstTheHive = false
local off = player({})
orockle:say(off, "hi")
T.check("switch off: no mission answer", not has(orockle:say(off, "mission"), "blind"))
Family.warAgainstTheHive = true

orockle:bye(p)
T.checkHints(orockle, function() return player({ level = 120 }) end)
T.finish()
