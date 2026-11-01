# NPC conversation checks (Gaia Family server)

Talk to an NPC without starting the server. `npc_talk.lua` loads one NPC file
with the real NPC library (`data/npclib`), our NPC rules
(`data/scripts/family/npc_keywords.lua`, `temple_healing.lua`), the storages and
the town list, and fakes only the engine (Npc, Player, addEvent). What the NPC
answers is what it answers in game, as long as it doesn't need something the
fake player lacks: missing player methods are printed once
(`[npc_talk] missing player method: ...`), and Lua errors in an NPC become a
failed check.

Run from the repository root with LuaJIT (`apt-get install luajit`):

```sh
luajit tools/family/npc_talk/dawnport.lua [dir-with-TibiaWiki-EN-wikitext]
```

`dawnport.lua` is the Dawnport check (2026-11-01, 330 checks): every Dawnport
Quest step with Mr Morris and Woblin in every state, the kill counting,
the `key` hints of the outpost NPCs, Inigo's and Oressa's fixes, every
`{highlighted}` word of the 13 Dawnport NPCs, and (with the optional
folder) every player line of `Inigo_Transcripts.txt`.

`explorer_society.lua` is The Explorer Society check (2026-11-01, 124 checks):
the whole quest through Angus and Mortimer with Uzgod, the Queen of the
Banshees, Elvith, Berenice, Lurik and the real chest and item scripts.

## Writing a check

```lua
local T = dofile("tools/family/npc_talk/npc_talk.lua")
local npc = T.load("data-otservbr-global/npc/woblin.lua")
local p = T.player({ level = 10, storage = { [Storage.Quest.U10_55.Dawnport.TheDormKey] = 1 }, items = { [21402] = 1 } })
npc:say(p, "hi")                                   -- returns the NPC's answer(s) as one string
T.check("key opens the step", npc:say(p, "key"):find("reward") ~= nil)
T.checkHints(npc, function() return T.player({}) end, { yes = true }) -- every {word} answers
T.finish()                                         -- totals; exit 1 on a failure
```

Fake player fields: `storage`, `items` (id = count), `money`, `bank`, `level`,
`vocation`, `sex`, `town`, `health`, `maxHealth`, `conditions`,
`accountStorage`. After talking: `p.added`, `p.removed`, `p.log` (messages),
`rawget(p, "shopOpened")`, `p.teleported`.

## Checklist for an NPC or quest conversation

1. Every step of the quest in every storage state answers (before the task,
   while it runs, item missing, item carried, after it is done).
2. The words the wikis use work, singular and plural (`troll`/`trolls`):
   TibiaWiki BR's "Hi - X - Yes" lines first, then the EN transcripts.
3. Every `{highlighted}` word answers (`T.checkHints`); words that only answer
   inside a step are skipped there and tested in their step.
4. Look for `a and b or c` in conditions: Lua reads it as `(a and b) or c`, so
   `c` alone passes (Inigo sent anyone saying "leave" to Rookgaard; Oressa made
   a level 1 a paladin after "bow", "yes").
5. A static `keywordHandler:addKeyword` answers before the callback: a quest
   word must not also be a plain keyword (Woblin's "key").
6. Rewards check that the item is really taken (`if player:removeItem(...)`).
7. When the NPC should trade, `trade` opens a shop (`npcConfig.shop`).
