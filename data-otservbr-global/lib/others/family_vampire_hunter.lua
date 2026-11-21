-- Gaia Family server: Vampire Hunter Quest review (2026-11-20). Ours, not upstream.
--
-- Reviewed against TibiaWiki BR "Vampire Hunter Quest" (our backup; ranks, rewards, Storkus'
-- lines, the Razing rank's refusal line, the Vengoth door) and TibiaWiki EN (spoiler with every
-- rank's transcript, Vampire Lord Token, Vampire Doll, Blood Skull, Razing!, Castlemania, the five
-- vampire lords' pages, Kazordoon Libraries).
--
-- What was wrong upstream:
--  * Storkus never gave the Razing! achievement (both wikis: with the last rank).
--  * Without enough tokens he said "Ye' don't have enought tokens."; BR has his real refusal for
--    the last rank, so every rank now refuses in that way (the five lines below the sixth are ours,
--    made after that line).
--  * His greeting had an extra "Good you're showing up." that no wiki has; the farewell ended with a
--    full stop (both wikis: "Greetings, Player!", "Good bye, Player!"). No `job` answer (BR quotes
--    it). After the last rank "vampire lord token" said nothing (now a line, ours).
--  * Castlemania asks for the blood skull too (both wikis); our check left it out because "nothing
--    records it", but the Vengoth chest does (storage BloodSkull): now required, and checked when
--    the skull is taken and when the last rank is reached.
--  * Storkus' bookcases (three shelves next to him) were empty; the seven books of both wikis are
--    put in at startup (BR TIBN shelf numbers and the BR picture: shelf 03 north, 01 south).
--  * The vampire lords: Sir Valorcrest dropped two tokens (both wikis: one); none brought its
--    companions; The Pale Count came without his raid message, straight into his sanctuary, and his
--    second phase was broken (a script for a monster "the pale count2" that does not exist, never
--    attached to him). See scripts/family/vampire_lords.lua.
--
-- Already as on the wikis (checked 2026-11-20): the ranks need 1, 4, 5, 10, 30 and 50 tokens given
-- at once, for 1,000 / 5,000 / 10,000 / 20,000 / 50,000 / 100,000 experience; the last also gives
-- the vampire doll and opens the Vengoth castle door (32953,31460,9) to the chest with the blood
-- skull (32972,31461,10; reach-checked on our map); tokens only after The Inquisition missions 1-3
-- (reported to Henricus). The five vampire lords appear in our rotations (Zevelon Duskbringer in
-- raid_scheduler.lua, the other four as Lua raids in data/scripts/family/rare_creatures.lua) at
-- the wiki places, and each drops one token always.
--
-- Switch: Family.vampireHunter (false = Storkus, the books, the lords and Castlemania as before).

Family = Family or {}
Family.vampireHunter = true

FamilyVampire = FamilyVampire or {}
local V = FamilyVampire

V.TOKEN = 8192
V.DOLL = 8191
V.TOPIC = 30 -- Storkus' topic while he waits for "yes" (upstream uses 1-9)

V.greeting = "Greetings, |PLAYERNAME|!"
V.farewell = "Good bye, |PLAYERNAME|!"
V.job = "I used to be a carpenter, but that was ages ago. Now I am a vampire hunter." -- BR (NPC notes)
V.ask = "Would ye' like to give me vampire tokens?"
V.allDone = "Ye' already are a razing vampire hunter. There's no higher rank I could give ye'. Still, good hunt to ye'!" -- ours

-- Ranks (both wikis): tokens given at once, experience, Storkus' line when it is reached.
V.ranks = {
	{ name = "Fluke", tokens = 1, experience = 1000, ordinal = "first", amount = "a token", line = "Ye' brought the token needed to advance to the first vampire hunter rank. I consider that a fluke, but still, congrats! Let me share some of my experience with ye'." },
	{ name = "Lucky", tokens = 4, experience = 5000, ordinal = "second", amount = "four tokens", line = "Ye' brought the four tokens needed to advance to the second vampire hunter rank. Pretty lucky ye' are! Let me share some of my experience with ye'." },
	{ name = "Determined", tokens = 5, experience = 10000, ordinal = "third", amount = "five tokens", line = "Ye' brought the five tokens needed to advance to the third vampire hunter rank. Wow, you're pretty determined! Let me share some of my experience with ye'." },
	{ name = "Painstaking", tokens = 10, experience = 20000, ordinal = "fourth", amount = "ten tokens", line = "Ye' brought the ten tokens needed to advance to the fourth vampire hunter rank. You're absolutely painstaking! Let me share some of my experience with ye'." },
	{ name = "Obliterative", tokens = 30, experience = 50000, ordinal = "fifth", amount = "thirty tokens", line = "Ye' brought the thirty tokens needed to advance to the fifth vampire hunter rank. You're completely obliterative, kid! Let me share some of my experience with ye'." },
	{ name = "Razing", tokens = 50, experience = 100000, ordinal = "sixth and last", amount = "fifty tokens", line = "Ye' brought the fifty tokens needed to advance to the last vampire hunter rank. Now that's something. You're razing-amazing! Let me share some of my experience and a little something with ye'!" },
}

-- Not enough tokens. The sixth rank's line is BR's; the others follow it (ours).
function V.refusal(rank)
	local r = V.ranks[rank]
	local text = "To promote ye' to the " .. r.ordinal .. " vampire hunter rank I need " .. r.amount .. " from ye' - which ye' don't have right now."
	if r.tokens > 1 then
		text = text .. " Please bring them all at once, it's a hassle to keep track of how many ye' brought and so on."
	end
	return text
end

local function rankOf(player)
	return math.max(player:getStorageValue(Storage.Quest.U8_2.VampireHunterQuest.Rank), 0)
end
V.rankOf = rankOf

-- Tokens are accepted once The Inquisition missions 1-3 are done (both wikis): Mission 3 is
-- reported to Henricus (Questline 11).
function V.canGiveTokens(player)
	return player:getStorageValue(Storage.Quest.U8_2.TheInquisitionQuest.Questline) >= 11
end

function V.checkCastlemania(player)
	if FamilyBloodBrothers and FamilyBloodBrothers.checkCastlemania then
		FamilyBloodBrothers.checkCastlemania(player)
	end
end

-- From Storkus' say callback, before upstream's code. True = answered here.
function V.storkus(npcHandler, npc, player, message)
	if not Family.vampireHunter then
		return false
	end
	local playerId = player:getId()
	if MsgContains(message, "job") then
		npcHandler:say(V.job, npc, player)
		npcHandler:setTopic(playerId, 0)
		return true
	end
	if MsgContains(message, "vampire lord token") or (MsgContains(message, "token") and V.canGiveTokens(player)) then
		if not V.canGiveTokens(player) then
			return false -- as upstream: nothing before Mission 3 is done
		end
		if rankOf(player) >= #V.ranks then
			npcHandler:say(V.allDone, npc, player)
			npcHandler:setTopic(playerId, 0)
			return true
		end
		npcHandler:say(V.ask, npc, player)
		npcHandler:setTopic(playerId, V.TOPIC)
		return true
	end
	if npcHandler:getTopic(playerId) ~= V.TOPIC then
		return false
	end
	npcHandler:setTopic(playerId, 0)
	if MsgContains(message, "yes") then
		local next = rankOf(player) + 1
		local r = V.ranks[next]
		if not r then
			return true
		end
		if player:getItemCount(V.TOKEN) < r.tokens or not player:removeItem(V.TOKEN, r.tokens) then
			npcHandler:say(V.refusal(next), npc, player)
			return true
		end
		npcHandler:say(r.line, npc, player)
		player:setStorageValue(Storage.Quest.U8_2.VampireHunterQuest.Rank, next)
		player:addExperience(r.experience, true)
		if next == #V.ranks then
			player:addItem(V.DOLL, 1)
			player:setStorageValue(Storage.Quest.U8_2.VampireHunterQuest.Door, 1)
			player:addAchievement("Razing!")
			V.checkCastlemania(player)
		end
		return true
	end
	if MsgContains(message, "no") then
		return true -- he lets it be (no line on the wikis)
	end
	return false
end

-- After the Vengoth chest gave the blood skull (scripts/actions/system/quest_reward_common.lua).
V.BLOOD_SKULL_CHEST = 6278
function V.afterChest(player, uid)
	if Family.vampireHunter and uid == V.BLOOD_SKULL_CHEST then
		V.checkCastlemania(player)
	end
end

-- Lua raids of the vampire lords: a spawn callback that brings companions around the lord.
function V.companions(name, min, max)
	return function(boss)
		if not Family.vampireHunter or not boss then
			return
		end
		local pos = boss:getPosition()
		for _ = 1, math.random(min, max) do
			Game.createMonster(name, pos, true, false)
		end
	end
end

-- The Pale Count (TibiaWiki EN): the raid message, the first fight in the hall shaped like a bat
-- (floor 14), and at yellow health (the client's yellow: 60% or less) he says his line and comes back
-- with full health in front of the mirror of his sanctuary below; only that second fight gives loot.
V.paleCount = {
	message = "The Pale Count has risen from his crypt deep under Drefia. Blood will flow.",
	hall = Position(32965, 32423, 14), -- EN Mapper Coords (BR: 32964,32421,14, the same hall)
	sanctuary = Position(32972, 32418, 15), -- EN "exactly here" (BR: 32973,32420,15; upstream 32969,32420)
	yellowPercent = 60,
	line = "Dare to follow me to my Sanctuary below and you shall DIE!",
	event = "FamilyPaleCountPhase",
}

-- Storkus' bookcases (TibiaWiki BR "Bibliotecas de Kazordoon City", TIBN shelf numbers 027203SH01-03
-- and the item ids in the TIBN; TibiaWiki EN Kazordoon Libraries has the same books per bookcase).
-- Texts: BR originals, checked against EN.
V.books = {
	{ -- Vampire Hunter's Handbook I (TIBN ...027203-SH03-2821)
		containerId = 2438,
		itemId = 2821,
		position = { x = 32587, y = 31961, z = 7 },
		text = [[
Vampire Hunter's Handbook I

The vampire is a beast created by evil, a parasite that needs the blood of the living to sustain his own parody of life. It is also a plague that spreads quickly if not fought by adequate means.

A vampire is no longer a living being. When turning into a vampire the soul of the former living being is destroyed and with it also its emotions and certain values. They are replaced by something evil and malignant. Where there was love, there is now desire; where there was valour, there is now cold-heartedness. Every positive aspect of life is transformed into a mockery, just like the whole vampire is a mockery of life.

The bite of a vampire is infectious. Sometimes, the now poisoned blood spreads through the body of the victim and raises it from the dead as a new vampire. This happens mostly when the vampire drains the victim slowly of it's blood.

There are cases in which a vampire visited its victim over several weeks or even months, slowly stealing their strength and leaving their evil stigma. Such victims raise much more likely as a vampire than victims that were robbed of there blood in a few minutes.

A vampire depends on the blood of others. If a vampire is not able to drink blood on a regular basis, it will wither and dry out, until it finally crumbles into dust.

Vampires are nocturnal creatures. They fear the sunlight because it evaporates the tainted and stolen blood in their veins. Sunlight greatly accelerates the process which lets vampires dry out. Only a well-fed vampire is able to resist the sunlight for a while.

The senses of a vampire are sharpened similar to those of predatory beasts. Still, just like these beasts, it is possible to chase them with the appropriate skills. Garlic, for example, is able to overload a vampire's senses. For this reason, vampires avoid garlic whenever possible.

Vampires also seem to have a special bond to certain animals. Wolves, rats and bats are often found in the company of a vampire. They are even able to shapeshift in such an animal. As the transformation into a bat is the most common one among vampires, it is assumed that it is also the most natural one for them.

Other animals, however, are rather scared by vampires. Horses sense vampires very easily and express great fear near a vampire's grave.

Even though vampires usually keep their human appearance, they share the physical strength of other undead. By applying this strength more conscious than other undead they are even more powerful. Their unliving body is able to withstand a large amount of damage, depending on the amount of blood that they've consumed recently. The body rather soaks the damage than to repel it. This can probably be explained with vampires being rather shadows than true bodies, for the same reason they lack a mirror image. However, it is said that vampires can manipulate the mind of others, making them believe that they see a reflection.

Some vampires are able to use this shadowy state of their body to become a cloud of darkness that is completely invulnerable to physical damage. However, all reports of using this special ability tell about very old vampires. It seems that vampires grow more and more powerful with each decade or century they live their undead lives.
]],
	},
	{ -- Vampire Hunter's Handbook II (TIBN ...027203-SH03-2821)
		containerId = 2438,
		itemId = 2821,
		position = { x = 32587, y = 31961, z = 7 },
		text = [[
Vampire Hunter's Handbook II

Vampires can be immobilised, also for a very long time, if the right method is used. If their physical body takes too much damage, it will go down. Sunlight will dry them out and even turn them into dust. If you drive a wooden object into the heart of a vampire, the flow of the vampire's tainted blood is stopped, leaving him completely helpless. It should be mentioned, though, that if the heart is partly missed or if the object is not large enough, the vampire might still be able to move.
Since a vampire is dead anyway, none of these methods allows to destroy a vampire for good. With enough time and blood, a vampire can recover from any of those seeming deaths. The only known way to permanently defeat a vampire is to kill him with a blessed stake. A blessed stake, however, is a rare object that cannot be obtained easily.
]],
	},
	{ -- The Book of Vile Evil (TIBN ...027203-SH02-2844)
		containerId = 2439,
		itemId = 2844,
		position = { x = 32587, y = 31962, z = 7 },
		text = [[
The Book of Vile Evil

A vampire is an impure sinner that in life served the dark gods.

Through this connection he is infused with increasingly tainted and dark energy over the course of his existence. In life they do many damnable things for their dark gods, burdening their souls to such an extent that they will most likely rise as ghosts if the dark gods do not claim their souls.

In some cases where the soul has been claimed, the hollow spirit still captured within the dead soulless body can utilise the dark energies of the corpse and animate it.

Just as an undead being is controlled by a necromancer, the vampire is merely a shell controlled by the spirit residing within.

The spirit constantly needs to refresh the dark energy he is using up and is in dire need for a substitute for the soul. Additional special circumstances such as holy ground or sunlight amplify the rate in which the dark energies decrease. To substitute this, the vampire is forced to steal the souls of the living.

The easiest way for him to accomplish this is by stealing the blood of living humans. The blood normally contains some amount of soul energy, however, a vampire is able to force more soul energy into it's victims blood while feeding.

In his own dead shell the vampire transforms the stolen soul energy into new dark energy. This process keeps him in existence. Over the years, the entire body only consists of dark energy residue and slowly turns into a shadow with substance.

If the vampiric body is destroyed, the spirit within becomes entrapped in the remains. Helpless it is cursed to wait for enough dark energy to accumulate in order to be able to recreate the shadow body in some way. Given time and sacrifices, a vampire might slowly rise from the state of apparent destruction to once again haunt the mortals.

Another possibility is that the remains are close to some source of dark power, giving off enough pure dark energy to occasionally haunt the dreams of the living or to form a ghostly body to steal the life breath of sleepers in the vicinity of the vampires' corpse. This process might take longer but will still lead to the vampires' resurrection.

The only way to irrevocably destroy a vampire is a blessed stake. The stake will destroy the evil spirits' ties to our world and send it into hell screaming.
]],
	},
	{ -- Novel on Vampire Hunters (TIBN ...027203-SH02-2825)
		containerId = 2439,
		itemId = 2825,
		position = { x = 32587, y = 31962, z = 7 },
		text = [[
I've been hunting vampires since the days your grandfather's grandfather was an infant. So you better listen to me, otherwise you might end up dead. Even if you listen to me, there is a good chance that those beasts will get you. I don't care why there are vampires and when they came here. The only thing that matters is that we will outlive them!

Don't think about them in terms of beings. They're nothing than beasts, trust me. They are cunning and deceptive, but still beasts.

Don't fall for their nonsense of being the rulers of the night. There is no dark curse, it was their own choice to become a vampire. They feed on humans because they are placing their own stinking existence above all else, and as I said, this was their own choice.

Vampires came to the mining colony in which I was living with my family. There were many of them, they were clever, they knew how to use magic, and they wielded dangerous weapons. My people had nothing. They killed some to still their thirst for blood, and many just for fun. We fought them in the tunnels, armed only with a few tools. At last we managed to let the tunnel collapse to kill the majority of us. This way they were at least no longer able to use us as source to satisfy their thirst for blood.

It was my curse to survive. It took me three days to dig myself out of the tunnel. Then I was found by the inquisitors that were chasing the vampires. I stayed with them for a while, accompanying them on their vampire hunts. But they were humans and their lives were short, so they attended other matters at some point. I left them and joined other hunters, and travelled the world.

I have killed my share of vampires in all those years, some weak, some strong. I learnt to fight, I learnt to run, I learnt their weaknesses, and I learnt their strengths.

Whenever you think you know all about a trade, you learn something new. If you fail to learn, you'll die. I've known many good people that died while hunting vampires. It took a few hundred years until I considered myself as quite good in this trade.

There is one weakness all vampires have in common: they're cowards. They proved this already when choosing the life of a vampire instead of facing the feared death. They prove this at each sundown when they rise again instead of ending their miserable existence. They prefer to spread their curse than to stop it. Selfishness is their main motive. Even though they form packs just like other beasts, they know no loyalty or support when danger arises.

Listen, I'm supposed to train you in the art of vampire hunting. But that's not how it works. If you are a fool, I cannot train you to be a genius. I suppose you know how to fight, else they would not have sent you. To learn the tricks of my trade, arm yourself with a blessed stake and hunt some vampires. Bring me their dust to prove your worthiness.
]],
	},
	{ -- The Blood Curse (TIBN ...027203-SH01-2827)
		containerId = 2440,
		itemId = 2827,
		position = { x = 32587, y = 31963, z = 7 },
		text = [[
The Blood Curse

Sages claim that we owe vampires to the dark deeds of some gods or demons. Some say, Urgith created them as a new tool for his wars. Others believe that vampires are an undead variation created by some powerful but not godlike being, very likely by one of the Ruthless Seven. Some think vampires are made by the Lord of the undead, other see Verminor as their creator. Again others see vampirism as some kind of curse.

It is said that the first vampire was a powerful warrior king who successfully fought the undead in the Corpse War. Being promised forbidden power and unification with his beloved ones, a once loyal follower of the king became the pawn of the dark powers. He poisoned his liege, probably over several months, using some nasty mixture which was handed to him.

As the king became sick and no one was able to heal him, the traitor stepped forward with a strange medicine. Trusting in his beloved servant, the king drank the medicine which actually was the blood of some servant that had been murdered recently. The medicine seemed to restore the king's strength, so the traitor had no trouble to feed him with more blood. Soon the king's appearance started to change. His aversion to sunlight and his paleness were attributed to his illness, but also the king's temper and behaviour turned more and more violent and aggressive. Nonetheless, the people loved their king and put up with his moods.

The traitor fuelled the king's growing paranoia with lies, so it was easy to convince him to get rid of certain court members. One by one the loyal advisers were removed and replaced with dark cultists. When the king was cut off from any loyal support, they stopped to give him blood and his illness returned, even worse than before. When he convulsed in pain and agony, they presented him a peasant to drain blood from. Almost insane by his ravenous thirst, the king accepted this sinister gift. As soon as he realised what was happening, he went berserk. In a fit of rage, he slaughtered each and every cultist that he encountered, but in the end they trapped him in his castle. The survivors fled with the corpse of the peasant who soon rose as a vampire. They drained him of his dark blood and killed him. Then they drank the blood to become vampires themselves.

The king was finally freed by loyal subjects. He had turned into something he had fought his whole life - an undead. It is said he left his castle in that very night, some say to hunt the traitors, others claim to end his undead life.
]],
	},
	{ -- The Origin of Vampires (TIBN ...027203-SH01-2832)
		containerId = 2440,
		itemId = 2832,
		position = { x = 32587, y = 31963, z = 7 },
		text = [[
The Origin of Vampires

Since the vampiric curse is spread through infectious bites, many vampires know only little about the origin of their kind. Then again the longevity or even immortality of vampires makes it possible that they have even existed before the creation of mankind.

Of course such beasts are hard to capture and they do not like to share their knowledge. Even if you are lucky enough to be able to talk to one, you cannot be sure if he is telling the truth. In fact, most questioned subjects were making up stories and boasted about their importance, age and accomplishments.

Lacking historical knowledge, such individuals can usually be cornered by accurate historical questions. This leaves a few sources that can be seen as credible to some extent. Still, their reports are diverse and share only a few facts. These common facts are the most reliable information we have these days.

The vampires claim that the eldest of their kin still remember a time when humankind was still divided in nomadic tribes that suffered in the wars of the gods. Some see this as a reference that the creation of the first vampires took place before the Corpse War.

The majority of vampires agreed that there was only one shrouded forefather vampire, though few mention also a small coven from which the vampire plague was initiated. The most reliable sources tell about some 'lost kingdom' where the first vampires ruled over a herd of humans that they treated like cattle.

At some point in history, the younger vampires rebelled against the elders who suppressed them. Others claim the rebellion took place to gain power in this static aristocracy in which the older vampires would have never made room for the next generation due to being near to immortal. It is unknown which side won. In fact the discrepancies in the single stories are so large that we assume that the vampires themselves are unsure about the happenings in these obviously chaotic days. Some claim the rebels won and chased the aristocracy away, others say the ruling cast won and met the rebels with such brute force that the few survivors could only flee. Then again there are stories that the fight between the vampires awakened something evil which drove the surviving combatants off their once safe haven. A few stories even claim that the humans used this opportunity to rebel against their cruel oppressors.

There are no hints about the location of this lost vampire kingdom. It is assumed that it was somewhere overseas, though. Some historians suggest Edron, but, the ruins in Edron are said to origin from much earlier times. Others assume it might have been on the mysterious continent Darama, either in Drefia or in Ankrahmun. However, the destruction of Drefia took place much later and there were no reports about undead activity, except for the works of several local necromancers, before this time. Ankrahmun, on the other hand, has a very accurate historical library and there is no such thing like a vampire kingdom mentioned at all.
]],
	},
	{ -- The Shadows of the Vampires (TIBN ...027203-SH01-2824)
		containerId = 2440,
		itemId = 2824,
		position = { x = 32587, y = 31963, z = 7 },
		text = [[
The Shadows of the Vampires

The vampire plague had its origin in mortals dabbling with the dark arts.

In the wake of the Corpse War, several humans began practising forms of necromancy for one reason or another.

Some saw the seemingly overwhelming powers of the undead and desired them for themselves. Others desperately tried to discover some countermeasures for the undead threat.

Researching for either good or evil, a small cabal of people studying necromancy became infected or cursed, slowly turning them into ghouls themselves. The change was slow enough for the necromancer fledglings to try to avert this change with any means possible. They came up with several methods, mostly based on alchemy. At long last they turned distilled human blood mixed with several forbidden ingredients of demonic origin into an effective potion. Not only did the potion end the rotting transformation, it also revitalised the drinker, making him feel healthier and stronger than ever before. It seemed to be an immediate success.

After the entire cabal received the 'cure' it quickly became obvious that the success was only temporal at best. Soon they began feeling weak. Human food offered them nourishment no more. Again and again they were forced to revert to their potion. Trying desperately to find a permanent cure, they varied the original formula, to no avail.

Two of the brightest minds of the cabal finally joined efforts in their research, refusing to let others participate. This slowed them down in their experiments. At long last they came up with a theory that the blood of one of their 'kind' just might be the cure they need.

Instead of carefully draining themselves and exchanging the blood, they started an argument over who should be the first to be cured. Soon the argument got out of hand, resulting in a fight about who had made the discovery and who deserved the praise. A fight of words turned into a fight of fists, one of them ended up dead and the unwilling donor of the much needed blood.

The survivor indeed felt cured, even better than before. He disclosed his research to his fellow necromancers, declaring the death of his colleague an accident. The others were too interested in the cure to truly care, eager to be cured themselves. Though blood was gathered and exchanged it did little to cease the transformation, let alone stop it. The 'cured' necromancer soon figured out the blood had to be taken from a living donor in such a mass and speed that the victim would surely die.

Secretly he shared this knowledge with his most trusted brethren. They slew the others by night. After the initial shock the victims fought back. More than half of the cabal met its demise in this fight. Only few escaped, doomed to become nearly mindless ghouls.

The others learnt soon enough that the supposed cure only stabilised their semi-undead state in some way. Though no longer dependent on complicated alchemical potions, they knew that only the blood of the living would quench their thirst. Also, they were able to infect their victims with some strange strain of their own illness, making them the first true vampires with the attributes and vulnerabilities that are known to us today. It was not possible to recreate the original illness or curse that in combination with several not documented potions initially turned the cabal into unliving things.
]],
	},
}
