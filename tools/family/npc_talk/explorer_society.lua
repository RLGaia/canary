-- The Explorer Society: every conversation and step (2026-11-01).
-- Run from the repository root:  luajit tools/family/npc_talk/explorer_society.lua
-- Walks the whole quest through Angus (Port Hope) and Mortimer (Northport), with
-- Uzgod, the Queen of the Banshees, Elvith, Berenice, Lurik and the real chest and
-- item scripts, in every state: before, during, item missing, item carried, done.
local T = dofile("tools/family/npc_talk/npc_talk.lua")
dofile("data-otservbr-global/lib/others/family_explorer_society.lua")
local ES = Storage.Quest.U7_6.ExplorerSociety
local check = T.check
local function has(text, pattern) return text:lower():find(pattern:lower(), 1, true) ~= nil end
local NPC = "data-otservbr-global/npc/"

-- achievements given
local achievements = {}
local function player(o)
	local p = T.player(o)
	p.achievements = {}
	p.addAchievement = function(self, name) self.achievements[name] = true end
	return p
end

-- capture item scripts (Action) to use them like the server does
local actions = {}
Action = function()
	local a = { ids = {}, uids = {} }
	function a:id(...) for _, v in ipairs({ ... }) do self.ids[#self.ids + 1] = v end end
	function a:uid(...) for _, v in ipairs({ ... }) do self.uids[#self.uids + 1] = v end end
	function a:aid() end
	function a:register() actions[#actions + 1] = self end
	return a
end
CONST_ME_MAGIC_BLUE = CONST_ME_MAGIC_BLUE or 3
MESSAGE_EVENT_ADVANCE = MESSAGE_EVENT_ADVANCE or 1
local function pos() return { sendMagicEffect = function() end } end
local function useItem(p, itemId, target, uid)
	for _, a in ipairs(actions) do
		local match = false
		for _, id in ipairs(a.ids) do match = match or id == itemId end
		for _, u in ipairs(a.uids) do match = match or (uid and u == uid) end
		if match then
			local item = { itemid = itemId, uid = uid or 0 }
			function item:transform(id) p.items[itemId] = (p.items[itemId] or 1) - 1; p.items[id] = (p.items[id] or 0) + 1; self.itemid = id end
			function item:remove() end
			target = target or {}
			target.remove = target.remove or function() end
			target.transform = target.transform or function() end
			return a.onUse(p, item, pos(), target, pos(), false)
		end
	end
	error("no action for item " .. itemId)
end
dofile("data-otservbr-global/scripts/quests/the_explorer_society/actions_findings.lua")
dofile("data-otservbr-global/scripts/quests/the_explorer_society/actions_icicle.lua")
dofile("data-otservbr-global/scripts/quests/the_explorer_society/actions_butterfly.lua")
dofile("data-otservbr-global/scripts/quests/the_explorer_society/actions_tracing_paper.lua")
local function openChest(p, uid, chestItem)
	return useItem(p, chestItem or 2472, nil, uid)
end

local angus = T.load(NPC .. "angus.lua")
local mortimer = T.load(NPC .. "mortimer.lua")
local uzgod = T.load(NPC .. "uzgod.lua")
local queen = T.load(NPC .. "the_queen_of_the_banshees.lua")
local elvith = T.load(NPC .. "elvith.lua")
local berenice = T.load(NPC .. "berenice.lua")
local lurik = T.load(NPC .. "lurik.lua")

-- --------------------------------------------------------------- the reported case
do
	local p = player({ storage = { [ES.JoiningTheExplorers] = 1, [ES.QuestLine] = 1 }, items = { [4872] = 1 } })
	angus:say(p, "hi")
	check("Angus pickaxe asks", has(angus:say(p, "pickaxe"), "Did you get the requested pickaxe"))
	check("Angus yes with an ice pick explains (reported)", has(angus:say(p, "yes"), "That is an ice pick"))
	angus:say(p, "pickaxe")
	p.items[4872] = 0
	check("Angus yes with nothing explains", has(angus:say(p, "yes"), "don't have the dwarven pickaxe"))
	local m = player({ storage = { [ES.JoiningTheExplorers] = 1, [ES.QuestLine] = 1 }, items = { [4872] = 1 } })
	mortimer:say(m, "hi")
	mortimer:say(m, "pickaxe")
	check("Mortimer yes with an ice pick explains", has(mortimer:say(m, "yes"), "That is an ice pick"))
	-- a non-member cannot join through "pickaxe" (upstream bug)
	local n = player({ items = { [4845] = 1 } })
	angus:say(n, "hi")
	check("non-member: pickaxe answers", has(angus:say(n, "pickaxe"), "not a member"))
	angus:say(n, "yes")
	check("non-member: pickaxe, yes does not make a member", n.storage[ES.JoiningTheExplorers] == nil and n.items[4845] == 1)
end

-- --------------------------------------------------------------- the whole quest
local p = player({ level = 120, money = 100000 })
angus:say(p, "hi")
check("join", has(angus:say(p, "join"), "Do you want to join"))
angus:say(p, "yes")
angus:say(p, "yes")
check("joined: JoiningTheExplorers 1", p.storage[ES.JoiningTheExplorers] == 1 and p.storage[ES.QuestLine] == 1)
check("join again answers", angus:say(p, "join") ~= "")
check("mission before the pickaxe answers", has(angus:say(p, "mission"), "pickaxe"))
check("ice delivery before the pickaxe answers", angus:say(p, "ice delivery") ~= "")

-- Uzgod and the brooch
uzgod:say(p, "hi")
check("Uzgod pickaxe asks", has(uzgod:say(p, "pickaxe"), "You wanting to get pickaxe"))
uzgod:say(p, "yes")
uzgod:say(p, "yes")
check("Uzgod sends to Dwacatra", p.storage[ES.JoiningTheExplorers] == 2 and p.storage[ES.DwacatraDoor] == 1)
check("Uzgod pickaxe while the brooch is missing", has(uzgod:say(p, "pickaxe"), "brooch"))
check("Uzgod brooch before finding it", has(uzgod:say(p, "brooch"), "dwacatra"))
openChest(p, 14029, 2473)
check("Dwacatra chest gives the brooch", p.items[4834] == 1 and p.storage[ES.JoiningTheExplorers] == 3)
openChest(p, 14029, 2473)
check("chest again: empty, no Lua error", p.log[#p.log] and has(p.log[#p.log], "is empty"), p.log[#p.log])
p.items[4834] = 0
uzgod:say(p, "brooch")
check("Uzgod yes without the brooch answers", has(uzgod:say(p, "yes"), "not having brooch"))
p.items[4834] = 1
uzgod:say(p, "brooch")
uzgod:say(p, "yes")
check("Uzgod gives the pickaxe", has(uzgod:say(p, "yes"), "Here you have it") and p.items[4845] == 1 and p.storage[ES.JoiningTheExplorers] == 4)
check("Uzgod pickaxe afterwards", uzgod:say(p, "pickaxe") ~= "")

-- membership
angus:say(p, "pickaxe")
check("Angus takes the pickaxe", has(angus:say(p, "yes"), "officially welcome") and p.storage[ES.QuestLine] == 5)
check("pickaxe afterwards", has(angus:say(p, "pickaxe"), "already brought"))
check("join afterwards", has(angus:say(p, "join"), "already a member"))

-- Rank I: order and reminders
check("mission lists rank I", has(angus:say(p, "mission"), "{butterfly hunt}"))
check("butterfly hunt before the ice: finish first", has(angus:say(p, "butterfly hunt"), "finish the {ice delivery} first"))
check("plant collection before: finish first", has(angus:say(p, "plant collection"), "first"))
angus:say(p, "ice delivery")
angus:say(p, "yes")
check("ice delivery accepted, ice pick given", p.storage[ES.TheIceDelivery] == 6 and p.items[4872] == 1)
check("ice delivery while running: reminder", has(angus:say(p, "ice delivery"), "Folda"))
useItem(p, 4872, { itemid = 4994 })
check("ice pick on Folda ice gives an icicle", p.items[4837] == 1 and p.storage[ES.TheIceDelivery] == 7)
angus:say(p, "ice delivery")
check("ice delivered + Just in Time", has(angus:say(p, "yes"), "Just in time") and p.storage[ES.TheIceDelivery] == 8 and p.achievements["Just in Time"])
check("ice delivery afterwards", has(angus:say(p, "ice delivery"), "already done"))
-- melted ice (another character): yes without ice, lost ice pick
do
	local m = player({ storage = { [ES.JoiningTheExplorers] = 5, [ES.QuestLine] = 7, [ES.TheIceDelivery] = 7 } })
	angus:say(m, "hi")
	angus:say(m, "ice delivery")
	check("ice: yes without ice asks if it melted", has(angus:say(m, "yes"), "Did it melt away?"))
	check("ice: melted, another chance and a new ice pick", has(angus:say(m, "yes"), "another chance") and m.storage[ES.TheIceDelivery] == 6 and m.items[4872] == 1)
	local n = player({ storage = { [ES.JoiningTheExplorers] = 5, [ES.QuestLine] = 7, [ES.TheIceDelivery] = 7 }, items = { [4872] = 1 } })
	angus:say(n, "hi")
	angus:say(n, "ice delivery")
	angus:say(n, "no")
	check("ice: no - melted - yes (EN) still works", has(angus:say(n, "yes"), "another chance") and n.items[4872] == 1)
end

-- butterflies
angus:say(p, "butterfly hunt")
angus:say(p, "yes")
check("butterfly hunt: first kit", p.items[4863] == 1 and p.storage[ES.TheButterflyHunt] == 9)
check("butterfly hunt while running: purple reminder", has(angus:say(p, "butterfly hunt"), "purple butterfly"))
p.items[4863] = 0
check("lost kit: offered for 250", has(angus:say(p, "preparation kit"), "250 gold"))
angus:say(p, "yes")
check("lost kit bought", p.items[4863] == 1)
useItem(p, 4863, { itemid = 4992 })
check("kit on a purple butterfly", p.items[4864] == 1 and p.storage[ES.TheButterflyHunt] == 10)
p.items[4864] = 0
angus:say(p, "butterfly hunt")
check("purple: yes without it answers", has(angus:say(p, "yes"), "don't have the prepared purple"))
p.items[4864] = 1
angus:say(p, "butterfly hunt")
check("purple reported", has(angus:say(p, "yes"), "battered") and p.storage[ES.TheButterflyHunt] == 11)
angus:say(p, "butterfly hunt")
useItem(p, 4863, { itemid = 4993 })
angus:say(p, "butterfly hunt")
angus:say(p, "yes")
angus:say(p, "butterfly hunt")
useItem(p, 4863, { itemid = 4991 })
angus:say(p, "butterfly hunt")
check("red reported, hunt done", has(angus:say(p, "yes"), "last butterfly") and p.storage[ES.TheButterflyHunt] == 17)

-- plants (samples set as the botanist script does)
angus:say(p, "plant collection")
angus:say(p, "yes")
check("plant collection: container", p.items[4867] == 1 and p.storage[ES.ThePlantCollection] == 18)
check("plants while running: jungle bells reminder", has(angus:say(p, "plant collection"), "jungle bells"))
local function sample(state, item)
	p.storage[ES.ThePlantCollection] = state
	p.storage[ES.QuestLine] = state
	p.items[4867] = 0
	p.items[item] = 1
end
sample(19, 4868)
angus:say(p, "plant collection")
angus:say(p, "yes")
angus:say(p, "plant collection")
sample(22, 4869)
angus:say(p, "plant collection")
angus:say(p, "yes")
angus:say(p, "plant collection")
sample(25, 4870)
angus:say(p, "plant collection")
check("plants done", has(angus:say(p, "yes"), "finished your plant collection") and p.storage[ES.QuestLine] == 26)

-- Rank II
check("mission lists rank II", has(angus:say(p, "mission"), "{lizard urn}"))
check("chest before the mission: empty, nothing changes", (function()
	openChest(p, 14030, 2469)
	return p.storage[ES.TheBonelordSecret] == nil and p.items[173] == nil and p.storage[ES.QuestLine] == 26
end)())
angus:say(p, "lizard urn")
angus:say(p, "yes")
check("rank II mission while the urn runs (was silent)", has(angus:say(p, "mission"), "{lizard urn}"))
check("lizard urn while running: reminder", has(angus:say(p, "lizard urn"), "temple"))
check("bonelord secrets before: finish first", has(angus:say(p, "bonelord secrets"), "first"))
openChest(p, 40041, 2472)
angus:say(p, "lizard urn")
check("urn reported", has(angus:say(p, "yes"), "prized relic") and p.storage[ES.QuestLine] == 29)
angus:say(p, "bonelord secrets")
angus:say(p, "yes")
openChest(p, 14030, 2469)
angus:say(p, "bonelord secrets")
check("parchment reported", has(angus:say(p, "yes"), "scientific world") and p.storage[ES.QuestLine] == 32)
angus:say(p, "orc powder")
angus:say(p, "yes")
p.items[4838] = 1 -- Black Bert's strange powder (TibiaWiki BR)
p.storage[ES.TheOrcPowder] = 34
angus:say(p, "orc powder")
check("Black Bert's strange powder accepted (BR)", has(angus:say(p, "yes"), "Amazing") and p.items[4838] == 0 and p.storage[ES.QuestLine] == 35)

-- Rank III
check("mission lists rank III", has(angus:say(p, "mission"), "{elven poetry}"))
angus:say(p, "elven poetry")
angus:say(p, "yes")
check("elven book while running: reminder", has(angus:say(p, "elven book"), "Songs of the Forest"))
openChest(p, 14032, 2472)
check("Hellgate chest gives the book", p.items[4844] == 1 and p.storage[ES.TheElvenPoetry] == 37)
p.items[4844] = 0
angus:say(p, "elven book")
check("book: yes without it points to Elvith", has(angus:say(p, "yes"), "Elvith"))
elvith:say(p, "hi")
check("Elvith offers a lost copy", has(elvith:say(p, "elven poetry"), "500 gold"))
elvith:say(p, "yes")
check("Elvith sells the book", p.items[4844] == 1 and p.money == 100000 - 250 - 500)
angus:say(p, "hi")
angus:say(p, "elven book")
check("book reported", has(angus:say(p, "yes"), "bloodstains") and p.storage[ES.QuestLine] == 38)
angus:say(p, "memory stone")
angus:say(p, "yes")
p.items[4841] = 1 -- bought from Black Bert
check("bought memory stone refused (BR line)", has(angus:say(p, "memory stone"), "looks damaged"))
p.items[4841] = 0
openChest(p, 14033, 2469)
angus:say(p, "memory stone")
check("memory stone reported", has(angus:say(p, "yes"), "flawless") and p.storage[ES.QuestLine] == 41)
angus:say(p, "rune writings")
angus:say(p, "yes")
check("tracing paper given", p.items[4842] == 1)
useItem(p, 4842, { itemid = 2199, uid = 3010 })
angus:say(p, "rune writings")
check("runes reported", has(angus:say(p, "yes"), "wrinkled") and p.storage[ES.QuestLine] == 44)

-- Rank IV
angus:say(p, "mission")
angus:say(p, "yes")
angus:say(p, "yes")
check("ectoplasm: container", p.items[4852] == 1 and p.storage[ES.QuestLine] == 45)
check("mission while collecting ectoplasm: reminder (was silent)", has(angus:say(p, "mission"), "ghost"))
p.storage[ES.TheEctoplasm] = 46
p.storage[ES.QuestLine] = 46
p.items[4852] = 0
angus:say(p, "mission")
check("ectoplasm: yes without it answers", has(angus:say(p, "yes"), "don't have the collected ectoplasm"))
p.items[4853] = 1
angus:say(p, "mission")
angus:say(p, "yes")
angus:say(p, "mission")
angus:say(p, "yes")
check("spectral dress accepted", p.storage[ES.TheSpectralDress] == 48)
check("mission while getting the dress: reminder", has(angus:say(p, "mission"), "queen of the banshees"))
p.items[4836] = 1 -- bought
check("bought dress refused before the queen's", has(angus:say(p, "mission"), "not given to you by the queen"))
p.items[4836] = 0
queen:say(p, "hi")
check("queen grants the dress", has(queen:say(p, "spectral dress"), "permission"))
check("queen asked again answers (was silent)", has(queen:say(p, "spectral dress"), "already granted"))
openChest(p, 14034, 2469)
angus:say(p, "hi")
angus:say(p, "mission")
check("dress reported + Explorer", has(angus:say(p, "yes"), "final phase") and p.storage[ES.TheSpectralDress] == 50 and p.achievements["Explorer"])
angus:say(p, "mission")
check("spectral stone: sent to Northport", p.storage[ES.TheSpectralStone] == 51 and p.storage[ES.SpectralStone] == 1)
check("mission again: travel to Northport (was silent)", has(angus:say(p, "mission"), "Northport"))
mortimer:say(p, "hi")
check("Mortimer mails the papers", has(mortimer:say(p, "mission"), "papers are in the mail") and p.storage[ES.QuestLine] == 52)
check("Mortimer asked again: back to Port Hope (was silent)", has(mortimer:say(p, "mission"), "Port Hope"))
angus:say(p, "hi")
angus:say(p, "mission")
angus:say(p, "yes")
check("spectral essence given", p.items[4840] == 1 and p.storage[ES.QuestLine] == 53)
p.items[4840] = 0
check("lost essence: a new one", has(angus:say(p, "mission"), "Here, take another one") and p.items[4840] == 1)
p.storage[ES.TheSpectralStone] = 55
p.storage[ES.QuestLine] = 55
check("astral portals reward", has(angus:say(p, "mission"), "small teleport") and p.items[5021] == 6 and p.storage[ES.QuestLine] == 56)
check("mission afterwards (was silent)", has(angus:say(p, "mission"), "done all the missions"))

-- Berenice and Calassa
berenice:say(p, "hi")
check("Berenice calassa straight away (BR)", has(berenice:say(p, "calassa"), "Would you like to know more"))
berenice:say(p, "yes")
berenice:say(p, "yes")
check("Calassa accepted", p.storage[ES.CalassaQuest] == 1)
check("Berenice mission while running (was silent)", has(berenice:say(p, "mission"), "Captain Max"))
openChest(p, 14035, 2469)
check("Calassa chest gives the damaged logbook", p.items[6124] == 1 and p.storage[ES.CalassaQuest] == 2)
p.items[6124] = 0
berenice:say(p, "mission")
check("Berenice yes without the logbook answers", has(berenice:say(p, "yes"), "don't have the logbook"))
p.items[6124] = 1
berenice:say(p, "mission")
check("logbook reported", has(berenice:say(p, "yes"), "That's the logbook") and p.storage[ES.CalassaQuest] == 3)
check("Berenice afterwards answers", berenice:say(p, "mission") ~= "")

-- Lurik
lurik:say(p, "hi")
check("Lurik offers The Island of Dragons (was never offered)", has(lurik:say(p, "mission"), "Would you like to go on a mission"))
lurik:say(p, "yes")
check("Island of Dragons accepted", p.storage[ES.TheIslandofDragons] == 57)
check("Lurik while running: reminder", has(lurik:say(p, "mission"), "Okolnir"))
p.storage[ES.TheIslandofDragons] = 58
p.storage[ES.QuestLine] = 58
p.items[7314] = 1
check("dragon scale reported", has(lurik:say(p, "mission"), "frozen dragon lord") and p.storage[ES.QuestLine] == 59)
check("ice music given", has(lurik:say(p, "mission"), "resonance crystal") and p.items[7242] == 1 and p.storage[ES.QuestLine] == 60)
check("Lurik while recording: reminder", has(lurik:say(p, "mission"), "stalagmites"))
p.storage[ES.TheIceMusic] = 61
p.storage[ES.QuestLine] = 61
check("Lurik without the recording answers", has(lurik:say(p, "mission"), "Where is the resonance crystal"))
p.items[7315] = 1
check("ice music reported", has(lurik:say(p, "mission"), "Liberty Bay and Svargrond") and p.storage[ES.QuestLine] == 62)
check("Lurik afterwards answers", lurik:say(p, "mission") ~= "")

-- every highlighted word answers
local fresh = function() return player({ level = 50 }) end
for _, t in ipairs({ angus, mortimer, uzgod, queen, elvith, berenice, lurik }) do
	-- the Queen's {SEVENTH}/{kiss} belong to The Queen of the Banshees Quest steps
	T.checkHints(t, fresh, { yes = true, calassa = true, seventh = true, kiss = true })
end
T.finish()
