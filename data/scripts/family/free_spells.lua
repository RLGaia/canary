-- Gaia Family server: spells are free and learned by themselves (2026-11-02).
-- Ours, not upstream.
--
-- With toggleLearnSpells = true every instant spell has to be bought from a
-- spell teacher NPC. Here every spell that a spell teacher sells is learned
-- for free as soon as the character can use it (its vocation, level and
-- magic level, the same check the teachers make: player:canLearnSpell):
--   * on level and magic level advance, with a message per spell;
--   * at login, so characters that already had the level catch up;
--   * when the vocation changes (Dawnport choice, promotion).
-- The teachers stay: asked about a spell, they answer "You already know this
-- spell." or, below its level, "You cannot learn this spell.", so no gold is
-- ever taken.
--
-- Spells no teacher sells are NOT touched: quest rewards (the monk shrines of
-- The Way of the Monk), Wheel of Destiny spells (the avatars, great death
-- beam, terra/ice burst...), house spells. They are learned as before.
--
-- The list below is every spellName of StdModule.learnSpell / addSpellKeyword
-- in data-otservbr-global/npc (v3.6.1, 163 spells). It has to be made again
-- only if spell teachers change.
--
-- Switch: Family.freeSpells (false = buy spells from the teachers, upstream).

Family = Family or {}
Family.freeSpells = true

local TAUGHT = {
	"animate dead rune", "annihilation", "apprentice's strike", "arrow call", "avalanche rune",
	"balanced brawl", "berserk", "blood rage", "bruise bane", "brutal strike", "buzz",
	"cancel invisibility", "cancel magic shield", "chained penance", "challenge", "chameleon rune",
	"charge", "chill out", "chivalrous challenge", "conjure arrow", "conjure explosive arrow",
	"conjure wand of darkness", "convince creature rune", "creature illusion", "cure bleeding",
	"cure burning", "cure curse", "cure electrification", "cure poison", "cure poison rune", "curse",
	"death strike", "destroy field rune", "devastating knockout", "disintegrate rune",
	"divine caldera", "divine healing", "divine missile", "double jab", "electrify", "enchant party",
	"enchant spear", "energy beam", "energy bomb rune", "energy field rune", "energy strike",
	"energy wall rune", "energy wave", "enlighten party", "envenom", "eternal winter",
	"ethereal spear", "explosion rune", "expose weakness", "fair wound cleansing", "fierce berserk",
	"find fiend", "find person", "fire bomb rune", "fire field rune", "fire wall rune", "fire wave",
	"fireball rune", "flame strike", "flurry of blows", "focus serenity", "food", "front sweep",
	"great energy beam", "great fire wave", "great fireball rune", "great light",
	"greater flurry of blows", "greater tiger clash", "groundshaker", "haste", "heal friend",
	"heal party", "heavy magic missile rune", "hell's core", "holy flash", "holy missile rune",
	"ice strike", "ice wave", "icicle rune", "ignite", "inflict wound", "intense healing",
	"intense healing rune", "intense recovery", "intense wound cleansing", "invisibility",
	"lesser ethereal spear", "lesser front sweep", "levitate", "light", "light healing",
	"light magic missile rune", "lightning", "magic patch", "magic rope", "magic shield",
	"magic wall rune", "mass healing", "mass spirit mend", "mentor other", "monk familiar",
	"mud attack", "nature's embrace", "paralyze rune", "physical strike", "poison bomb rune",
	"poison field rune", "poison wall rune", "protect party", "protector", "rage of the skies",
	"recovery", "restoration", "restore balance", "salvation", "sap strength", "scorch",
	"sharpshooter", "soulfire rune", "spirit mend", "stalagmite rune", "stone shower rune",
	"strong energy strike", "strong ethereal spear", "strong flame strike", "strong haste",
	"strong ice strike", "strong ice wave", "strong terra strike", "sudden death rune",
	"summon creature", "summon druid familiar", "summon knight familiar", "summon paladin familiar",
	"summon sorcerer familiar", "sweeping takedown", "swift foot", "swift jab", "terra strike",
	"terra wave", "thunderstorm rune", "tiger clash", "train party", "ultimate energy strike",
	"ultimate flame strike", "ultimate healing", "ultimate healing rune", "ultimate ice strike",
	"ultimate light", "ultimate terra strike", "virtue of harmony", "virtue of justice",
	"virtue of sustain", "whirlwind throw", "wild growth rune", "wound cleansing", "wrath of nature",
}

local function spellLabel(name)
	local spell = Spell(name)
	if not spell then
		return name
	end
	local okName, display = pcall(function()
		return spell:name()
	end)
	local okWords, words = pcall(function()
		return spell:words()
	end)
	display = okName and display or name
	if okWords and type(words) == "string" and words ~= "" then
		return string.format("%s (%s)", display, words)
	end
	return display
end

-- Learns every taught spell the character can use and does not know yet.
-- Returns the labels of the spells learned now.
function Family.learnFreeSpells(player)
	local learned = {}
	if not Family.freeSpells or not configManager.getBoolean(configKeys.LEARN_SPELLS) then
		return learned
	end
	for _, name in ipairs(TAUGHT) do
		if Spell(name) and not player:hasLearnedSpell(name) and player:canLearnSpell(name) then
			player:learnSpell(name)
			learned[#learned + 1] = spellLabel(name)
		end
	end
	return learned
end

local function tell(player, learned)
	for _, label in ipairs(learned) do
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have learned the spell " .. label .. ".")
	end
end

local login = CreatureEvent("FamilyFreeSpellsLogin")

function login.onLogin(player)
	player:registerEvent("FamilyFreeSpellsAdvance")
	local playerId = player:getId()
	-- after the login messages, so they do not hide these
	addEvent(function()
		local p = Player(playerId)
		if p then
			tell(p, Family.learnFreeSpells(p))
		end
	end, 1500)
	return true
end

login:register()

local advance = CreatureEvent("FamilyFreeSpellsAdvance")

function advance.onAdvance(player, skill, oldLevel, newLevel)
	if newLevel > oldLevel and (skill == SKILL_LEVEL or skill == SKILL_MAGLEVEL) then
		local playerId = player:getId()
		-- the new level is set after onAdvance returns: look a moment later
		addEvent(function()
			local p = Player(playerId)
			if p then
				tell(p, Family.learnFreeSpells(p))
			end
		end, 100)
	end
	return true
end

advance:register()

-- Vocation change: the new vocation may already have the level for its spells.
if not Family.freeSpellsVocationWrapped then
	Family.freeSpellsVocationWrapped = true
	local original = Player.setVocation
	Player.setVocation = function(self, ...)
		local result = original(self, ...)
		if Family.freeSpells and self and self.getId then
			local playerId = self:getId()
			addEvent(function()
				local p = Player(playerId)
				if p then
					tell(p, Family.learnFreeSpells(p))
				end
			end, 200)
		end
		return result
	end
end
