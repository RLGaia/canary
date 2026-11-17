-- Gaia Family server: Cults of Tibia Quest review (2026-11-17).
--
-- Ours, not upstream. Asked by Rodrigo: review the whole quest, its items and
-- its dialogue against our TibiaWiki BR backup (RLGaia/tibiawiki-backup) and
-- the TibiaWiki EN spoiler, item and NPC pages. Lines taken from the wikis are
-- marked "BR"/"EN" in the files; the others are ours.
--
-- What changed (details in FAMILY.md, "Cults of Tibia Quest"):
--   * Gerimor: 13 lore words (BR/EN), "mission" as well as "missions", the
--     monk's Sensing Crown as final reward (both wikis).
--   * Every cult can be started at its own hideout (EN) and then shows in the
--     quest log (startQuestline below); quest log texts without "ASD".
--   * Barkless: Tigo answers every word at any time; the second tar tile
--     gives its own message; the ice death sends you to your temple with full
--     health instead of leaving you at 1 health dressed as a corpse.
--   * Humans: green souls (decaying) open the first barrier, blue souls
--     (withering) the second (both wikis; upstream had them swapped); the
--     remains are the real "remains of a ... soul" objects and vanish after
--     20 seconds (EN).
--   * Life/Prosperity: Angelo's dialogue (EN transcript), Angelo refuses to
--     talk after the Sandking dies and the loupe crate works anyway (both
--     wikis), the pink fluid is used up, a Sand Brood corpse heals the
--     Sandking 7,500 (EN).
--   * Prosperity: Gareth and Iwar typos and words, the Denominator asks five
--     questions about your number (both wikis), with a 2-minute limit (BR).
--   * Misguided: Noozer "yes" (EN), the rubbish amulet's fall-off message and
--     lost charge, 5 minutes to use the glowing amulet (EN).
--   * Final battle: the Zarcorix of Yalahar disappears when the Corruptor of
--     Souls dies (EN; upstream looked in the wrong room).
--
-- Switch: Family.cultsOfTibia (false = upstream behaviour where the files
-- check it: quest log start, ice death, Humans barriers and remains,
-- Denominator, rubbish amulet). Plain text fixes are not switched.

Family = Family or {}
Family.cultsOfTibia = true

FamilyCults = FamilyCults or {}
local F = FamilyCults

local function S()
	return Storage.Quest.U11_40.CultsOfTibia
end

-- A cult started at its own hideout (not through Gerimor) still shows the
-- quest in the quest log.
function F.startQuestline(player)
	if not (Family and Family.cultsOfTibia) then
		return
	end
	if player:getStorageValue(S().Questline) < 1 then
		player:setStorageValue(S().Questline, 1)
	end
end

-- Barkless purification: Tibia shows a death without any loss and you come
-- back in your temple (BR: "voce voltara para o templo mas nao perdera nada").
function F.purificationDeath(player)
	local town = player:getTown()
	local temple = town and town:getTemplePosition()
	if temple then
		player:teleportTo(temple)
		temple:sendMagicEffect(CONST_ME_TELEPORT)
	end
	player:addHealth(player:getMaxHealth())
	player:addMana(player:getMaxMana())
end

-- Humans: the souls the cultists leave behind (EN item pages: 25778 is the
-- decaying soul, green light; 25777 the withering soul, blue light).
F.decayingSoul = 25778
F.witheringSoul = 25777
F.soulSeconds = 20 -- EN: "You have 20 seconds to collect (by stepping on) them before they vanish."

-- The Denominator ------------------------------------------------------------
-- Both wikis: five questions about your three-digit number XYZ (each digit
-- 0-5, from the lever's three rows of stones); the last one is always the
-- number itself. EN lists the known questions.

function F.digits(player)
	return math.max(player:getStorageValue(S().MotA.Stone1), 0), math.max(player:getStorageValue(S().MotA.Stone2), 0), math.max(player:getStorageValue(S().MotA.Stone3), 0)
end

function F.number(player)
	local x, y, z = F.digits(player)
	return x * 100 + y * 10 + z
end

function F.isPrime(n)
	if n < 2 then
		return false
	end
	if n % 2 == 0 then
		return n == 2
	end
	for i = 3, math.floor(math.sqrt(n)), 2 do
		if n % i == 0 then
			return false
		end
	end
	return true
end

-- A prime with another prime two below or two above it.
function F.isTwinPrime(n)
	return F.isPrime(n) and (F.isPrime(n - 2) or F.isPrime(n + 2))
end

-- kind "number": the answer is a number; kind "yesno": true/false.
F.questions = {
	{ text = "What is the sum of the first and the second digit?", kind = "number", answer = function(x, y, z, n) return x + y end },
	{ text = "What is the sum of the first and the third digit?", kind = "number", answer = function(x, y, z, n) return x + z end },
	{ text = "What is the sum of the second and the third digit?", kind = "number", answer = function(x, y, z, n) return y + z end },
	{ text = "What is the digit sum?", kind = "number", answer = function(x, y, z, n) return x + y + z end },
	{ text = "Is the number divisible by 3?", kind = "yesno", answer = function(x, y, z, n) return n % 3 == 0 end },
	{ text = "Is the number divisible by 5?", kind = "yesno", answer = function(x, y, z, n) return n % 5 == 0 end },
	{ text = "Is the number prime?", kind = "yesno", answer = function(x, y, z, n) return F.isPrime(n) end },
	{ text = "Does the number belong to a prime twin?", kind = "yesno", answer = function(x, y, z, n) return F.isTwinPrime(n) end },
}
F.finalQuestion = { text = "What is the correct number?", kind = "number", answer = function(x, y, z, n) return n end }
F.quizSeconds = 120 -- BR: "Voce tera aproximadamente dois minutos para responder as perguntas"

-- Four different questions in a random order, then the number.
function F.pickQuestions()
	local pool = {}
	for i = 1, #F.questions do
		pool[i] = i
	end
	local picked = {}
	for i = 1, 4 do
		local j = math.random(i, #pool)
		pool[i], pool[j] = pool[j], pool[i]
		picked[i] = pool[i]
	end
	return picked
end

function F.question(index)
	if index == 0 then
		return F.finalQuestion
	end
	return F.questions[index]
end

-- true when `message` answers question `q` right for this player.
function F.checkAnswer(player, q, message)
	local x, y, z = F.digits(player)
	local n = x * 100 + y * 10 + z
	local right = q.answer(x, y, z, n)
	if q.kind == "yesno" then
		if MsgContains(message, "yes") then
			return right == true
		elseif MsgContains(message, "no") then
			return right == false
		end
		return false
	end
	local given = tonumber((message:gsub("[^%d]", "")))
	return given ~= nil and given == right
end

-- The rubbish amulet (Misguided) ----------------------------------------------
F.rubbishAmulet = 25296
F.glowingAmulet = 25297
F.glowingSeconds = 5 * 60 -- EN: "you will have 5 minutes to use it on a living Misguided"

-- EN: "The amulet fell off. You took too long to recharge it. Whatever power it
-- accumulated is now lost." (BR: "...to charge it..."); the charge starts again.
function F.amuletFellOff(player, amulet)
	amulet:moveTo(player:getPosition())
	player:setStorageValue(S().Misguided.Monsters, 0)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The amulet fell off. You took too long to charge it. Whatever power it accumulated is now lost.")
end

-- The charged amulet loses its glow when it is not used within 5 minutes
-- (what happens then is ours: it turns back into a rubbish amulet and the
-- charging starts again).
function F.watchGlowingAmulet(playerId, stamp)
	addEvent(function()
		local player = Player(playerId)
		if not player then
			return
		end
		if player:getStorageValue(S().Misguided.Time) ~= stamp then
			return
		end
		local amulet = player:getItemById(F.glowingAmulet, true)
		if amulet then
			amulet:transform(F.rubbishAmulet)
			player:setStorageValue(S().Misguided.Monsters, 0)
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The glow of the amulet fades away. Whatever power it accumulated is now lost.")
		end
	end, F.glowingSeconds * 1000)
end
