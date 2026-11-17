-- Gaia Family server: Meriana Rebels (Ray's pirate task) and the Pirate Outfit addons check (2026-11-17).
-- Raymond Striker's task (accept, report three times with the hideout, then money only), Duncan's
-- sabre task (Addon, task, eye patches, peg legs, hooks, codeword), Morgan's "firebird", Ariella's
-- hat and Swashbuckler, with the TibiaWiki BR backup's lines. The hideout door and the boss
-- teleporter are checked in the self-test. Run from the repository root:
--   luajit tools/family/npc_talk/meriana_rebels.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
dofile("data-otservbr-global/lib/others/family_shattered_isles.lua")
dofile("data-otservbr-global/lib/others/family_meriana_rebels.lua")
dofile("data-otservbr-global/lib/quests/killing_in_the_name_of.lua")
local SI = Storage.Quest.U7_8.TheShatteredIsles
local PO = Storage.Quest.U7_8.PirateOutfits
local K = Storage.Quest.U8_5.KillingInTheNameOf
local REPEAT = REPEATSTORAGE_BASE + #tasks.GrizzlyAdams + 1

local function player(o)
	local p = T.player(o)
	p.achievements = {}
	p.addons = {}
	p.exp = 0
	rawset(p, "addAchievement", function(self, name) self.achievements[#self.achievements + 1] = name return true end)
	rawset(p, "addOutfitAddon", function(self, look, addon) self.addons[look] = bit.bor(self.addons[look] or 0, addon) end)
	rawset(p, "hasOutfit", function(self, look, addon) return bit.band(self.addons[look] or 0, addon) == addon end)
	rawset(p, "addExperience", function(self, n) self.exp = self.exp + n end)
	return p
end

local function plain(text) return ((text or ""):gsub("[{}]", "")) end
local function has(text, s) return plain(text):find(s, 1, true) ~= nil end
local function hasAchievement(p, name)
	for _, a in ipairs(p.achievements) do
		if a == name then return true end
	end
	return false
end

local npcs = {}
for _, name in ipairs({ "raymond_striker", "duncan", "morgan", "ariella" }) do
	npcs[name] = T.load("data-otservbr-global/npc/" .. name .. ".lua")
end

local function talk(p, name, lines)
	local out = {}
	for _, line in ipairs(lines) do
		out[#out + 1] = npcs[name]:say(p, line) or ""
	end
	npcs[name]:say(p, "bye")
	return out
end

-- Meriana Rebels: Pirates -------------------------------------------------------------------------
local p = player({ money = 0, level = 80, storage = { [SI.RaysMission4] = 5, [SI.AccessToLagunaIsland] = 1 } })
local r = talk(p, "raymond_striker", { "hi", "task", "yes" })
T.check("Ray: task offer (BR)", has(r[2], "would you be willing to kill 3000 pirates for us?"), r[2])
T.check("Ray: accepted (BR)", has(r[3], "Perfect. I know it sounds like a lot"), r[3])
T.check("task running, first time", p.storage[K.PirateTask] == 0 and p.storage[REPEAT] == 1)
r = talk(p, "raymond_striker", { "hi", "task" })
T.check("Ray: not enough pirates yet", has(r[2], "Go kill more pirates"), r[2])
for round = 1, 4 do
	p.storage[K.MonsterKillCount.PirateCount] = 3000
	r = talk(p, "raymond_striker", { "hi", "task" })
	if round <= 2 then
		T.check("report " .. round .. ": hideout (BR)", has(r[2], "secret hideout somewhere on Nargor") and p.storage[K.PirateTask] == 1, r[2])
	elseif round == 3 then
		T.check("report 3: last time (BR)", has(r[2], "This was probably the last time") and p.storage[K.PirateTask] == 1, r[2])
	else
		T.check("report 4: money only (BR)", has(r[2], "What would we do without you?") and p.storage[K.PirateTask] == 3, r[2])
	end
	T.check("report " .. round .. ": 10,000 exp and 5,000 gold", p.exp == 10000 * round and p.money == 5000 * round, p.money)
	if round <= 3 then
		T.check("door open with Ray's permission", FamilyMerianaRebels.mayPass(p))
		p.storage[K.PirateTask] = 2 -- through the teleporter
		T.check("door still opens until reported (way out)", FamilyMerianaRebels.mayPass(p))
		r = talk(p, "raymond_striker", { "hi", "task", "yes" })
		T.check("Ray: after the hideout (BR)", has(r[2], "So you went into the leaders' hideout?") and has(r[3], "Perfect."), r[2])
		T.check("door sealed with a new task", not FamilyMerianaRebels.mayPass(p))
	else
		r = talk(p, "raymond_striker", { "hi", "task", "yes" })
		T.check("Ray: again after the 4th (ours)", has(r[2], "kill pirates again") and p.storage[K.PirateTask] == 0, r[2])
	end
end
T.check("no task before Ray's missions", (function()
	local q = player({ storage = { [SI.RaysMission4] = 3 } })
	local t = talk(q, "raymond_striker", { "hi", "task" })
	return (q.storage[K.PirateTask] or -1) == -1
end)())

-- Pirate Outfit addon 1: Duncan and Morgan --------------------------------------------------------
local o = player({ storage = { [PO.PirateBaseOutfit] = 1 } })
local d = talk(o, "duncan", { "hi", "Addon", "task", "yes", "yes" })
T.check("Duncan: Addon with a capital (BR)", has(d[2], "You're talking about my sabre?"), d[2])
T.check("Duncan: task (BR)", has(d[3], "willing to prove you're worthy of wearing such a sabre?"), d[3])
T.check("Duncan: belongings (BR)", has(d[4], "by bringing me some of their belongings") and has(d[4], "in that order"), d[4])
T.check("Duncan: eye patches first (BR)", has(d[5], "Come back to me once you have gathered 100 eye patches") and o.storage[PO.PirateSabreAddon] == 1, d[5])
o.items[6098], o.items[6126], o.items[6097] = 100, 100, 100
d = talk(o, "duncan", { "hi", "Eye Patches", "yes", "Peg Legs", "yes", "Hooks", "yes" })
T.check("Duncan: eye patches (BR)", has(d[2], "Have you gathered 100 eye patches?") and has(d[3], "now bring me 100 peg legs"), d[3])
T.check("Duncan: peg legs (BR)", has(d[4], "Have you gathered 100 peg legs?") and has(d[5], "Lastly, bring me 100 pirate hooks"), d[5])
T.check("Duncan: codeword said (BR)", has(d[6], "Have you gathered 100 hooks?") and has(d[7], "tell him this codeword: 'firebird'"), d[7])
T.check("items taken, sabre step 4", o.items[6098] == 0 and o.items[6126] == 0 and o.items[6097] == 0 and o.storage[PO.PirateSabreAddon] == 4)
local mo = talk(o, "morgan", { "hi", "firebird" })
T.check("Morgan: sabre (BR)", has(mo[2], "So Duncan sent you, eh?") and o.addons[151] == 1 and o.addons[155] == 1, mo[2])
T.check("no Swashbuckler with one addon", not hasAchievement(o, "Swashbuckler"))

-- Pirate Outfit addon 2: Ariella ------------------------------------------------------------------
o.items[6099], o.items[6100], o.items[6101], o.items[6102] = 1, 1, 1, 1
local a = talk(o, "ariella", { "hi", "Addon", "task", "yes" })
T.check("Ariella: hat (BR)", has(a[2], "You mean my hat?"), a[2])
T.check("Ariella: four leaders (BR)", has(a[3], "the shirt of the Lethal Lissy, the sabre of Ron the Ripper"), a[3])
T.check("Ariella: incredible (BR)", has(a[4], "INCREDIBLE! You have found all four of them!") and o.addons[151] == 3, a[4])
T.check("Swashbuckler with both addons (BR)", hasAchievement(o, "Swashbuckler"))
-- the other order: hat first, then sabre
local h = player({ storage = { [PO.PirateBaseOutfit] = 1, [PO.PirateSabreAddon] = 4 } })
h.items[6099], h.items[6100], h.items[6101], h.items[6102] = 1, 1, 1, 1
talk(h, "ariella", { "hi", "addon", "task", "yes" })
T.check("hat first: no Swashbuckler yet", not hasAchievement(h, "Swashbuckler"))
talk(h, "morgan", { "hi", "firebird" })
T.check("sabre second: Swashbuckler", hasAchievement(h, "Swashbuckler"))

T.finish()
