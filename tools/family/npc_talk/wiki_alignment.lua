-- Gaia Family server: "follow the wikis" check (2026-11-17), the spots where earlier reviews had kept
-- our server's behaviour: Venore Daily Tasks (20 hours per task, BR; bonus once per round), Pilgrimage
-- of Ashes (gold only when started below level 25, BR), Dalbrect's `family` (EN). Run from the
-- repository root:  luajit tools/family/npc_talk/wiki_alignment.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z, getDistance = function() return 0 end } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
dofile("data-otservbr-global/lib/others/family_venore_tasks.lua")
dofile("data-otservbr-global/lib/others/family_pilgrimage.lua")
dofile("data-otservbr-global/lib/others/family_white_raven.lua")

local function has(text, s) return ((text or ""):gsub("[{}]", "")):find(s, 1, true) ~= nil end
local check = T.check

-- Venore Daily Tasks ---------------------------------------------------------------------------------
local V = FamilyVenoreTasks
local VS = Storage.Quest.FamilyVenoreTasks
local norman = T.load("data-otservbr-global/npc/norman_the_foreman.lua")
local p = T.player({ level = 50 })
p.storage[VS.Sabotage] = V.READY
norman:say(p, "hi")
local r = norman:say(p, "sabotage")
check("Venore: report pays", has(r, "Good work on the sabotage") and p.storage[VS.Sabotage] == V.REPORTED, r)
r = norman:say(p, "sabotage")
check("Venore: 20 hours wait (BR)", has(r, "Come back in about 20 hours"), r)
norman:say(p, "bye")
p.kvdata["reported-sabotage"] = os.time() - 19 * 3600
check("Venore: still reported after 19 hours", V.state(p, "sabotage") == V.REPORTED)
p.kvdata["reported-sabotage"] = os.time() - 20 * 3600 - 1
check("Venore: free again after 20 hours", V.state(p, "sabotage") == V.FREE)
-- bonus once per round of three
local b = T.player({ level = 50 })
for _, task in ipairs(V.order) do
	b.storage[V.storage(task)] = V.REPORTED
	b.kvdata["reported-" .. task] = os.time() - 60
end
check("Venore: bonus after three", V.claimBonus(b) == true)
check("Venore: no second bonus in the round", V.claimBonus(b) == false)
for _, task in ipairs(V.order) do
	b.kvdata["reported-" .. task] = os.time() + 5 -- a new round reported later
end
check("Venore: bonus again in the next round", V.claimBonus(b) == true)
-- a character reported before the change (no time stored) is free
local old = T.player({})
old.storage[VS.Maintenance] = V.REPORTED
check("Venore: old reported task is free", V.state(old, "maintenance") == V.FREE)

-- Pilgrimage of Ashes ----------------------------------------------------------------------------------
local PS = Storage.Quest.FamilyPilgrimageOfAshes
local luke = T.load("data-otservbr-global/npc/guide_luke.lua")
local function blessAll(pl)
	rawset(pl, "hasBlessing", function() return true end)
end
local young = T.player({ level = 20 })
luke:say(young, "hi")
local o = luke:say(young, "pilgrimage")
check("Pilgrimage: offer below 25 (ours, full)", has(o, "five sacred places"), o)
luke:say(young, "yes")
luke:say(young, "bye")
young.level = 60
blessAll(young)
luke:say(young, "hi")
o = luke:say(young, "pilgrimage")
check("Pilgrimage: started below 25 gets the gold (BR)", has(o, "Take these 20 platinum coins") and (young.items[3035] or 0) == 20, o)
luke:say(young, "bye")
local vet = T.player({ level = 40 })
luke:say(vet, "hi")
o = luke:say(vet, "pilgrimage")
check("Pilgrimage: offer from 25 only discount (BR line)", has(o, "I will only grant a little discount on the blessings"), o)
luke:say(vet, "yes")
luke:say(vet, "bye")
blessAll(vet)
luke:say(vet, "hi")
o = luke:say(vet, "pilgrimage")
check("Pilgrimage: started at 25+ no gold (BR)", has(o, "complete") and (vet.items[3035] or 0) == 0, o)
luke:say(vet, "bye")

-- Dalbrect ----------------------------------------------------------------------------------------------
local dalbrect = T.load("data-otservbr-global/npc/dalbrect.lua")
local d = T.player({})
dalbrect:say(d, "hi")
local f = dalbrect:say(d, "family")
check("Dalbrect: family (EN)", has(f, "Once my family was once noble and wealthy"), f)
local fb = dalbrect:say(d, "family brooch")
check("Dalbrect: 'family brooch' still the brooch", has(fb, "examine a brooch"), fb)
dalbrect:say(d, "bye")

T.finish()
