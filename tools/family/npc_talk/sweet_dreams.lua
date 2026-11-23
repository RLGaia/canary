-- Gaia Family server: Threatened Dreams Quest, Sweet Dreams check (2026-11-22). One character plays
-- Sweet Dreams with the lines of the TibiaWiki BR page (world steps set as storages or items or run
-- through the lib's functions): Maelyrra's donut, the forest fury, Charlotta, the escape, baking and
-- glazing, the gate, the lipstick, the Sugar Plum Fairy's sweets, Candis, Dulcineo, the Tooth Fairy,
-- the Pegasus Feather and the taffy bunny. Run from the repository root:
--   luajit tools/family/npc_talk/sweet_dreams.lua

local T = dofile("tools/family/npc_talk/npc_talk.lua")
Position = Position or function(x, y, z) return { x = x, y = y, z = z, sendMagicEffect = function() end } end
DATA_DIRECTORY = DATA_DIRECTORY or "data-otservbr-global"
for k, v in pairs({ CONST_ME_GIFT_WRAPS = 28, CONST_ME_MAGIC_GREEN = 15, CONST_ME_LOSEENERGY = 2, CONST_ME_HITBYFIRE = 16, CONST_ME_FIREWORK_YELLOW = 29, CONST_ME_HEARTS = 36, CONST_ME_BLOCKHIT = 9, CONDITION_INVISIBLE = 8, CALLBACK_GREET = CALLBACK_GREET or 2, CALLBACK_ON_TRADE_REQUEST = CALLBACK_ON_TRADE_REQUEST or 8, MESSAGE_TRADE = 20 }) do
	_G[k] = _G[k] or v
end
dofile("data-otservbr-global/lib/others/family_threatened_dreams_lore.lua")
dofile("data-otservbr-global/lib/others/family_threatened_dreams.lua")
dofile("data-otservbr-global/lib/others/family_sweet_dreams.lua")
local SD = FamilySweetDreams
Game.createItem = Game.createItem or function() return nil end
local S = SD.S
local M2 = Storage.Quest.U11_40.ThreatenedDreams.Mission02[1]

local function player(o)
	local p = T.player(o)
	p.achievements = {}
	p.mounts = {}
	rawset(p, "addAchievement", function(self, name) self.achievements[#self.achievements + 1] = name return true end)
	rawset(p, "hasAchievement", function(self, name)
		for _, a in ipairs(self.achievements) do
			if a == name then return true end
		end
		return false
	end)
	rawset(p, "hasMount", function(self, id) return self.mounts[id] == true end)
	rawset(p, "addMount", function(self, id) self.mounts[id] = true end)
	rawset(p, "getFreeCapacity", function() return 1000000 end)
	return p
end
local function plain(s) return (s:gsub("[{}]", "")) end
local function has(text, s) return text ~= nil and plain(text):find(plain(s), 1, true) ~= nil end
local function item(p, id)
	return { getId = function() return id end, remove = function() p.items[id] = (p.items[id] or 1) - 1 end, transform = function(self, to) p.items[id] = p.items[id] - 1; p.items[to] = (p.items[to] or 0) + 1; id = to end }
end
local function target(id)
	local t = { removed = false }
	t.getId = function() return id end
	t.remove = function() t.removed = true end
	t.transform = function(_, to) id = to end
	return setmetatable(t, { __index = function() return nil end })
end
-- the lib checks type(target) == "userdata"; give it a userdata-like proxy
local function ud(id)
	local proxy = newproxy(true)
	local t = target(id)
	getmetatable(proxy).__index = t
	return proxy, t
end

local p = player({ money = 0 })
p.storage[M2] = 8 -- A Dream Come True done

-- ------------------------------------------------------------- Maelyrra
local mae = T.load("data-otservbr-global/npc/maelyrra.lua")
mae:say(p, "hi")
local a = mae:say(p, "donut")
T.check("Maelyrra 'donut' (BR)", has(a, "So, you saw the gate.") and has(a, "maybe you will find the recipe.") and p.storage[S.Main] == 1, a)
mae:say(p, "bye")

-- ------------------------------------------------------------- the forest fury
local fury = T.load("data-otservbr-global/npc/a_captive_forest_fury.lua")
local stranger = player()
T.check("fury greets a stranger (BR NPC page)", fury:say(stranger, "hi") == "Better not talk to me. It could make them angry.")
T.check("fury 'job' (BR)", fury:say(stranger, "job") == "I'm a prisoner here, as you can see.")
T.check("fury farewell (BR)", fury:say(stranger, "bye") == "Farewell. May your dreams be pleasant.")
T.check("fury greets the helper (BR)", fury:say(p, "hi") == "Greetings, stranger. Please tell me, that you are here to help me!")
a = fury:say(p, "yes")
T.check("fury's plan (BR)", has(a, "I'm so happy to hear that.") and has(a, "talk to someone who knows a bunch of spells.") and p.storage[S.Main] == 2, a)
fury:say(p, "bye")

-- ------------------------------------------------------------- Charlotta
local charlotta = T.load("data-otservbr-global/npc/charlotta.lua")
charlotta:say(p, "hi")
a = charlotta:say(p, "mirror image")
T.check("Charlotta's offer (BR)", a == SD.charlotta.offer, a)
a = charlotta:say(p, "yes")
T.check("no money (ours)", has(a, "You don't have enough money.") and (p.items[SD.MIRROR_SPELL] or 0) == 0, a)
p.money = 1000
charlotta:say(p, "mirror image")
a = charlotta:say(p, "yes")
T.check("mirror image spell (BR)", has(a, "It will make a forest fury invisible") and p.items[SD.MIRROR_SPELL] == 1 and p.money == 0, a)
charlotta:say(p, "bye")

-- ------------------------------------------------------------- key chest, cage, escape
T.check("key chest (BR)", SD.keyChest(p) and p.items[SD.CAGE_KEY] == 1 and p.log[#p.log] == "You have found an intricate cage key.")
T.check("key chest only while needed", SD.keyChest(p) and p.items[SD.CAGE_KEY] == 1)
T.check("cage refuses without invisibility (ours)", SD.useCageKey(p, SD.CAGE_DOOR) and p.storage[S.Main] == 2)
p.conditions[CONDITION_INVISIBLE] = true
T.check("cage opens (BR)", SD.useCageKey(p, SD.CAGE_DOOR) and p.storage[S.Main] == 3 and p.items[SD.CAGE_KEY] == 0 and p.items[SD.MIRROR_SPELL] == 0 and p.log[#p.log] == SD.ESCAPE[1])
local z = 11
rawset(p, "getPosition", function() return { x = 0, y = 0, z = z, sendMagicEffect = function() end } end)
local before = #p.log
for _, floor in ipairs({ 10, 9, 8, 7 }) do
	z = floor
	SD.escapeTick(p)
end
T.check("escape messages in the BR order", #p.log - before == 7 and p.log[#p.log] == SD.ESCAPE[8] and p.log[before + 1] == SD.ESCAPE[2])
T.check("recipe and A Friend in Need (BR, EN)", p.storage[S.Main] == 4 and p.items[SD.RECIPE] == 1 and p:hasAchievement("A Friend in Need"))

-- ------------------------------------------------------------- baking
p.items[SD.CHOCOLATE_DOUGH] = 1
local oven = ud(SD.OVEN)
T.check("key baked on the oven", SD.bakeKey(p, item(p, SD.CHOCOLATE_DOUGH), oven, Position(0, 0, 6)) and p.items[SD.CHOCOLATE_DOUGH] == 0)
p.items[SD.KEY[1]] = 1 -- picked up from the oven
p.items[SD.SUGAR], p.items[SD.LEMON], p.items[SD.RASPBERRY], p.items[SD.MOON_MELON] = 3, 1, 1, 1
for _, f in ipairs({ SD.LEMON, SD.RASPBERRY, SD.MOON_MELON }) do
	local tgt = ud(f)
	SD.useSugar(p, item(p, SD.SUGAR), tgt)
end
T.check("three sirups", p.items[SD.SIRUP.lemon] == 1 and p.items[SD.SIRUP.raspberry] == 1 and p.items[SD.SIRUP.moon] == 1 and p.items[SD.SUGAR] == 0)
local keyProxy, keyT = ud(SD.KEY[1])
SD.useSirup(p, item(p, SD.SIRUP.lemon), keyProxy)
T.check("wrong order (BR)", has(p.log[#p.log], "You should use the moon melon sirup first. At least, the recipe says so.") and p.items[SD.SIRUP.lemon] == 1)
SD.useSirup(p, item(p, SD.SIRUP.moon), keyProxy)
SD.useSirup(p, item(p, SD.SIRUP.raspberry), keyProxy)
SD.useSirup(p, item(p, SD.SIRUP.lemon), keyProxy)
T.check("key glazed (EN ids)", keyT.getId() == SD.KEY[4])
p.items[SD.KEY[4]] = 1
local nobody = player()
T.check("gate does nothing without the key (BR)", not SD.gateOpen(nobody))
T.check("donut gate takes the key", SD.gateOpen(p) and p.storage[S.Main] == 5 and p.items[SD.KEY[4]] == 0)
T.check("gate stays open", SD.gateOpen(p))

-- ------------------------------------------------------------- Candia
local spf = T.load("data-otservbr-global/npc/sugar_plum_fairy.lua")
a = spf:say(p, "hi")
T.check("fairy gestures (BR)", has(a, "She makes a gesture as if to apply some lipstick.") and p.storage[S.Lipstick] == 1, a)
a = spf:say(p, "mission")
T.check("no talk before the lipstick (BR)", has(a, "you don't understand her"), a)
spf:say(p, "bye")
T.check("lipstick box after the greeting (EN)", SD.lipstickBox(p) and p.items[SD.LIPSTICK] == 1)
T.check("lipstick (BR)", SD.useLipstick(p, item(p, SD.LIPSTICK)) and p.storage[S.Lipstick] == 2 and p.log[#p.log] == "You paint your lips with the sweet sugar. Now you should be able to speak and understand Candy Fae.")
a = spf:say(p, "hi")
T.check("fairy understands you (BR)", a == "Ah, I see, you used the candy lipstick. Now I understand you! Sweet greetings, dear visitor!", a)
a = spf:say(p, "mission")
T.check("stolen sweets (BR)", has(a, "Four of my rarest and most prized sweets were stolen") and has(a, "Bring them back, will you?"), a)
a = spf:say(p, "yes")
T.check("sweets accepted (BR)", a == "How very sweet of you! I hope, the monster has not eaten them yet." and p.storage[S.Main] == 6, a)
a = spf:say(p, "taffy bunny")
T.check("taffy bunny (BR)", has(a, "Her name is Cherry") and has(a, "on your travels through Candia?"), a)
a = spf:say(p, "yes")
T.check("bunny accepted (BR)", a == "Thank you! I hope, you will find her." and p.storage[S.Bunny] == 1, a)
for i, s in ipairs(SD.SWEETS) do
	p.items[s.id] = 1
	a = spf:say(p, s.word)
	T.check("sweet '" .. s.word .. "' (BR)", has(a, s.line) and p.items[s.id] == 0, a)
	if i == #SD.SWEETS then
		T.check("Chocolate Mines (BR)", has(a, "may I still ask for another?") and has(a, "near the Candy Carnival.") and p.storage[S.Main] == 7, a)
	end
end
spf:say(p, "bye")

-- the bunny
local bunny = T.load("data-otservbr-global/npc/a_taffy_bunny.lua")
a = bunny:say(p, "hi")
T.check("taffy bunny found (BR)", has(a, "You spot a pink taffy bunny") and has(a, "tell Sugar the Plum Fairy where her pet is.") and p.storage[S.Bunny] == 2, a)
bunny:say(p, "bye")
spf:say(p, "hi")
a = spf:say(p, "taffy bunny")
T.check("bunny reported (BR)", has(a, "So the little runaway is down at the Hot Milk Springs?") and p.storage[S.Bunny] == 3, a)
spf:say(p, "bye")

-- Candis
local candis = T.load("data-otservbr-global/npc/candis.lua")
T.check("Candis greeting (BR)", candis:say(p, "hi") == "Greetings!")
a = candis:say(p, "mission")
T.check("missing workers (BR)", has(a, "some of my workers have disappeared") and has(a, "Please, perhaps you can find them.") and p.storage[S.Candis] == 1, a)
p.storage[S.Candis] = 2 -- Sugar Daddy killed (server test)
a = candis:say(p, "mission")
T.check("candy canes (BR)", has(a, "Thank you so much for bringing back my missing workers.") and has(a, "stabilise the relevant areas.") and p.storage[S.Candis] == 3, a)
T.check("cane chest (BR: three)", SD.caneChest(p) and p.items[SD.CANDY_CANE] == 3)
for i, pos in ipairs(SD.WALLS) do
	SD.useCandyCane(p, item(p, SD.CANDY_CANE), pos)
end
T.check("three walls", p.storage[S.Walls[1]] == 1 and p.storage[S.Walls[3]] == 1 and p.items[SD.CANDY_CANE] == 0)
a = candis:say(p, "mission")
T.check("honey glasses (BR)", has(a, "Very good! Thank you, my workers will be much safer now.") and has(a, "Here, take those glasses") and p.items[SD.HONEY_EMPTY] == 5 and p.storage[S.Candis] == 5, a)
p.items[SD.HONEY_EMPTY], p.items[SD.HONEY_FULL] = 0, 5 -- five honey elementals caught (server test)
a = candis:say(p, "mission")
T.check("mines done (BR)", has(a, "Well done! Thank you for catching those cheeky honey elementals!") and p.items[SD.HONEY_FULL] == 0 and p.storage[S.Main] == 8, a)
candis:say(p, "bye")
spf:say(p, "hi")
a = spf:say(p, "mission")
T.check("Candy Carnival (BR)", has(a, "the long-awaited Candy Carnival may finally begin.") and has(a, "on the shores of the Moon Melon Sea.") and p.storage[S.Main] == 9, a)
spf:say(p, "bye")

-- Dulcineo, the Tooth Fairy
local dul = T.load("data-otservbr-global/npc/dulcineo.lua")
a = dul:say(stranger, "hi")
T.check("Dulcineo gestures (BR)", has(a, "The pastel-coloured faun greets you"), a)
dul:say(stranger, "bye")
a = dul:say(p, "hi")
T.check("Dulcineo's request (BR)", has(a, "Thank you for your help with the stolen sweets") and has(a, "some kind of reconciliation talk.") and p.storage[S.Main] == 10, a)
dul:say(p, "bye")
local tf = T.load("data-otservbr-global/npc/tooth_fairy_candia.lua")
T.check("Tooth Fairy greeting (BR)", tf:say(p, "hi") == "Greetings, human being.")
a = tf:say(p, "mission")
T.check("toothbrushes (BR)", has(a, "Dulcineo sent you? Really?") and has(a, "Here you go.") and p.items[SD.TOOTHBRUSH] == 3 and p.storage[S.Main] == 11, a)
FamilyThreatenedDreams.CHILDREN.quero.bed[1] = { x = 1, y = 1, z = 6 }
FamilyThreatenedDreams.CHILDREN.allen.bed[1] = { x = 2, y = 2, z = 5 }
FamilyThreatenedDreams.CHILDREN.rowenna.bed[1] = { x = 3, y = 3, z = 6 }
for _, child in ipairs({ "quero", "allen", "rowenna" }) do
	SD.useToothbrush(p, item(p, SD.TOOTHBRUSH), FamilyThreatenedDreams.CHILDREN[child].bed[1])
end
T.check("three pillows (BR)", p.storage[S.Toothbrush.quero] == 1 and p.storage[S.Toothbrush.rowenna] == 1 and p.items[SD.TOOTHBRUSH] == 0 and p.log[#p.log - 2] == "You are placing the toothbrush for Quero's daughter on the pillow.")
a = tf:say(p, "mission")
T.check("Pegasus Feather (BR)", has(a, "It's good that you brought the toothbrushes") and has(a, "you will be able to call a pegasus to you.") and p.items[SD.PEGASUS_FEATHER] == 1 and p.storage[S.Main] == 12, a)
tf:say(p, "bye")
T.check("feather gives the Pegasus and I Wanna Fly Away (EN)", SD.usePegasusFeather(p, item(p, SD.PEGASUS_FEATHER)) and p.mounts[SD.PEGASUS_MOUNT] and p:hasAchievement("I Wanna Fly Away") and p.items[SD.PEGASUS_FEATHER] == 0)
a = dul:say(p, "hi")
T.check("Dulcineo thanks (BR)", a == "Thank you, my friend, for taking on this diplomatically tricky mission. I have a feeling that the disagreements between my lady and her sister may now be resolved. Candia is in your debt." and p.storage[S.Main] == 13, a)
dul:say(p, "bye")
T.check("quest log text", has(SD.mainLog(p), "Candia is in your debt"))

-- Toffee
local toffee = T.load("data-otservbr-global/npc/toffee.lua")
a = toffee:say(stranger, "hi")
T.check("Toffee gestures (BR)", has(a, "The globose cook greets you"), a)

T.finish()
