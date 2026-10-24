# Gaia Family Server

Private Canary server for a small group of players.
This fork follows [opentibiabr/canary](https://github.com/opentibiabr/canary);
all family changes live on the `family` branch.

The server runs **natively on Windows**: no Docker, no WSL, no virtualization
(SVM can stay off in the BIOS).

## Pinned versions

| Piece | Version | Where it comes from |
|---|---|---|
| Canary server | v3.6.1 (`canary.exe`) | release zip, downloaded and checksum-verified by `family\setup.ps1` |
| Game data (quests, NPCs, monsters) | v3.6.1 | this repository, branch `family` (starts at tag `v3.6.1`) |
| Map | `otservbr.otbm` from release v3.6.1 | downloaded by Canary on its first start |
| Login server | `family-1` (`login-server.exe`): our fork's build of upstream `main` (May 2026) plus the world PvP type. Unlike v1.1.3 it fills the login screen's Boosted (creature and boss) and Event Schedule panels, and the character list shows "Optional PvP" | release zip from <https://github.com/RLGaia/login-server/releases/tag/family-1>, downloaded and checksum-verified by `family\setup.ps1`; `start-server.ps1` passes `SERVER_PATH` (this folder) so it can read `config.lua` and `data\json\eventscheduler\events.json`. Back to v1.1.3: the URL and checksum are kept in a comment in `family\lib.ps1` |
| Database | MariaDB 11.4 for Windows | <https://mariadb.org/download/> |
| Game client | 15.11 (`15.11.c9d1cf`) | <https://github.com/dudantas/tibia-client/releases/tag/15.11.c9d1cf> |

Server and client versions must always match. The pinned download URLs and
checksums live at the top of `family\lib.ps1`.

## What is in `family\`

| File | Purpose |
|---|---|
| `local.env.example` | Template for `local.env` (git-ignored): database password, server IP, ports |
| `config.family.lua` | Our changes to Canary's settings (committed). Never edit `config.lua` itself |
| `setup.ps1` | One-time setup, safe to re-run: downloads programs, creates the database, imports the schema, replaces the public GOD password |
| `new-account.ps1` | Creates an account and its first character (`-AddCharacter` adds more) |
| `edit-account.ps1` | Changes an account's login or password (also `@god`), or a character's name or sex; free, server stopped, backs up first |
| `start-server.ps1` | Builds `config.lua`, starts the login server and Canary |
| `backup-db.ps1` | Dumps the database to `%USERPROFILE%\OT-backups`, keeps the newest 30 |
| `restore-db.ps1` | Restores the database from one of those backups (server stopped; backs up the current database first) |
| `client-mute-hit-sound.ps1` | Run on each player's PC with the game client closed: mutes the Light Healing sound that the pinned server plays on every hit (see "Hit sound" below). Needs nothing else from the repository, so it can be copied alone; `-ClientPath` for another client folder, `-Undo` restores the original |
| `store-images\` | Store pictures the game client downloads from GitHub (`coinImagesURL`); see "Store pictures" below |

## Golden rules

- Never commit `family\local.env`, database backups or the game client.
- Edit `family\config.family.lua`, never `config.lua` (it is rebuilt on every start).
- Add new files instead of editing upstream files whenever possible, which keeps updates painless.
- Commit email: the GitHub noreply address (`RLGaia@users.noreply.github.com`).
- Stop the server with **Ctrl+C** in its window (after logging out), never by closing the window.

## One-time setup (server PC)

1. **Git for Windows** (if not installed): <https://git-scm.com/download/win>
2. **MariaDB 11.4**: at <https://mariadb.org/download/> choose version 11.4, Windows, x86_64, MSI.
   In the installer:
   - set a **root password** and keep it (setup asks for it once);
   - keep "Install as service" checked;
   - keep "Enable networking" on port 3306;
   - leave "Enable access from remote machines for root" **unchecked**.
3. **Get the code** (PowerShell):
   ```powershell
   git clone https://github.com/RLGaia/canary.git
   cd canary
   git checkout family
   ```
4. **Machine settings**:
   ```powershell
   Copy-Item family\local.env.example family\local.env
   notepad family\local.env      # set DB_PASSWORD to a new strong password
   ```
5. **Setup** (asks for the MariaDB root password and a new GOD password):
   ```powershell
   powershell -ExecutionPolicy Bypass -File family\setup.ps1
   ```
6. **Accounts**, once per player:
   ```powershell
   powershell -ExecutionPolicy Bypass -File family\new-account.ps1
   ```
   Logins look like an email (`player1@server`); they don't need to be real.
   New characters start like real Tibia: no vocation, on the Dawnport tutorial island.
   To change a login, a password, a character name or sex later (server stopped):
   `powershell -ExecutionPolicy Bypass -File family\edit-account.ps1`.
7. **Game client 15.11** (on each PC that plays):
   - Download the tag's source archive:
     <https://github.com/dudantas/tibia-client/archive/refs/tags/15.11.c9d1cf.zip>
     (about 435 MB unpacked). This archive *is* the client. The release's attached
     `client-11.zip` and `tibia-8.6-extended.zip` are other client versions; don't use them.
   - Extract it outside this repository, e.g. `C:\Games\tibia-client-15.11`.
   - Extract `bin\Qt6WebEngineCore.rar` into that same `bin` folder (Windows 11 Explorer
     or 7-Zip can open `.rar`).
   - Per the release notes, mark the `cache` folder's files as read-only.
   - Run `bin\client.exe`. It already points to `http://127.0.0.1/login.php`, where the
     login server listens.

## Daily use

```powershell
powershell -ExecutionPolicy Bypass -File family\start-server.ps1
```

The login server opens in a minimized window and Canary runs in the current one;
the first start downloads the map (~176 MB). Wait for **"Gaia Family server online!"**,
then log in with the client. To stop: log out, press **Ctrl+C** in the server
window and wait for "Server stopped."

The first time each program starts, Windows Firewall may ask for network access.
Click **Cancel**: the port rule below is the only firewall rule the server needs.

## Playing together (Tailscale)

1. Install Tailscale on both PCs and sign in to the same tailnet (free Personal plan).
2. In `family\local.env`, set `SERVER_IP` to this PC's Tailscale IP (`100.x.y.z`).
3. Allow the game ports for Tailscale addresses only (PowerShell as administrator):
   ```powershell
   New-NetFirewallRule -DisplayName "Canary game server" -Direction Inbound -Protocol TCP -LocalPort 80,7171,7172 -RemoteAddress 100.64.0.0/10 -Action Allow
   ```
4. Restart the server.
5. On **both** PCs, edit the client's `conf\config.ini`:
   ```ini
   loginWebService=http://100.x.y.z/login.php
   clientWebService=http://100.x.y.z/login.php
   ```

Never forward router ports. Nothing needs to be exposed to the internet.

## Security

The repository is public, so it holds no passwords, backups or client files;
those stay in `family\local.env` (git-ignored) and the backup folder.

- **Listen address.** `start-server.ps1` makes Canary (`bindOnlyGlobalAddress = true`)
  and the login server (`LOGIN_IP`) listen only on `SERVER_IP`: 127.0.0.1 or the
  Tailscale IP, never the home Wi-Fi. It stops with a message when that address is
  not on the PC (for example Tailscale is disconnected).
- **Firewall.** One inbound rule, ports 80/7171/7172 from `100.64.0.0/10` only. Remove
  any per-program rules for `canary.exe` / `login-server.exe` that Windows created
  from its firewall question (manual, section 11).
- **MariaDB** listens on 127.0.0.1 only (`bind-address=127.0.0.1` in `my.ini`).
- **Tailscale ACL.** Invited players reach only the game ports of the server PC;
  the owner keeps full access (manual, section 11).
- **Passwords.** Game passwords are unique (not reused elsewhere). The backup folder
  on OneDrive holds the database (password hashes) and `local.env`, so the
  Microsoft account uses two-step verification.

## Game balance (solo / duo)

Chosen on 2026-10-12. The server log confirms it on every start with two `[Family]` lines.

| Area | Setting | Where |
|---|---|---|
| Premium | Every account is always premium | `family\config.family.lua` (`freePremium`) |
| PvP | No PvP (`no-pvp`) | `family\config.family.lua` |
| Experience | 50x to level 8, 80x to 50, 60x to 100, 40x to 150, 30x to 200, 15x to 300, 12x to 500, 11x to 600, 10x to 700, 8x to 800, 5x after (by character level). Rubinot's curve up to 400, then a gentler taper (levels 400 to 800 in about 80 hours of hunting) and a 5x floor. Chosen 2026-10-14; before: 10/8/6/4 | `data\scripts\family\solo_balance.lua` |
| Skills | 12x up to skill 60, 9x to 80, 7x to 100, 4x after, never lower (by the level of that skill; raised from 10/7/5/3 on 2026-10-13). In game, `!serverinfo` shows your current rates | same |
| Magic level | 12x up to ML 30, 9x to 60, 7x to 90, 4x after (raised from 10/7/5/3 on 2026-10-13) | same |
| Loot | 3x (2x until 2026-10-14): every item's drop chance tripled, up to 100%; stacks such as gold drop more often, not bigger. Rarest items first | `family\config.family.lua` |
| Bosses | 50% health, 70% damage (Bosstiary bosses only) | `family\config.family.lua` |
| Boss cooldown | None (since 2026-10-17; 1 hour before, upstream 20 h): every boss can be fought again right away, also those whose lever, portal or quest sets its own wait (Grimvale, Feaster of Souls, Prince Drazzak, Grave Danger, Forgotten Knowledge, Dream Courts, Brokul, First Dragon, Dangerous Depths warzone bosses; since 2026-10-20 the 8 hours of free warzone entry after stopping the lava pumps are kept, they are not a wait). An occupied boss room still stays closed until the fight is over | `family\config.family.lua` (`bossDefaultTimeToFightAgain = 0`), `solo_balance.lua`, `data-otservbr-global\scripts\family\boss_cooldown.lua` (`Family.noBossCooldown`) |
| Boss levers | One player is always enough (all 66 standard levers, Soul War included) | `solo_balance.lua` |
| Tibia Coins | Not free (since 2026-10-13): a Coin Broker near the temple of each port city sells transferable Tibia Coins for 5,000 gold each (buy only). All balances were reset to 0 once | `data-otservbr-global\scripts\family\coin_broker.lua` |
| Conveniences | Auto-loot, free third Prey and Hunting Task slots. Since 2026-10-19 rerolling the Prey and Hunting Task lists is always free and choosing a creature from the full list costs no Prey Wildcards (so locking a Prey slot and cancelling a Hunting Task are free too); rerolling a Prey bonus or a Hunting Task reward rarity costs no Wildcard either, so automatic bonus reroll is free too. The config only applies to slots created at a character's first login, so at every start `data\scripts\family\prey_slots.lua` also opens third slots saved as locked (Prey: empty slot, Hunting Tasks: empty list, both with a free reroll) | `family\config.family.lua`, `prey_slots.lua` |
| Hunting Task Points | Since 2026-10-21 (Rodrigo's choice): claiming a Hunting Task in the Prey window pays 10 times the points (a hard creature, 5 stars, 800 kills: 9,120 instead of 912); a message says the total, while the window still shows the normal amounts. After claiming, the slot takes a new creature at once (upstream waits 20 hours): the slot shows an empty creature list with the Free reroll and full-list buttons, and the first click gives a new list (the C++ would leave it Exhausted, buttons disabled, until the next login; relogging also fixes it). Walter Jaeger in Thais sells for them (Falconer outfit 100,000, Antelope 145,000, trophies, falcon pet). Switches `Family.huntingTaskPointsMultiplier`, `Family.huntingTaskSlotReadyAfterClaim` | `data\scripts\family\hunting_task_points.lua`, module `data\modules\scripts\family\hunting_tasks.lua`, `taskHuntingLimitedTasksExhaust = 0` in `family\config.family.lua` |
| Death | No experience, skill or item loss: you only wake up in the temple. Everyone always has full blessings | `family\config.family.lua`, `solo_balance.lua` |
| Training | Exercise weapons never run out (one from the Store costs 25 coins; NPCs also sell them for gold); exercise training 2x faster, offline training 4x (2x until 2026-10-23) | both files |
| Respawn | Normal (the map's times: classic hunts 90 s, newer areas 60 s; the boosted creature 2x faster). It was 2x faster (45 s / 30 s) from 2026-10-12 to 2026-10-24 | `family\config.family.lua` |
| Rare creatures | Rare raid creatures and bosses (Midnight Panther, Draptor, Undead Cavebear, Yeti, The Old Widow, Tyrn..., plus the Thais rat plague) take turns: one starts at a time, at least 15 min after the previous one (`Family.rareRaidGapMinutes`; since 2026-10-17 each is announced 60 min before it starts, for the map discovery raid warnings), picked at random among the raids that are ready (one player online, 30 min since that raid's last run, its previous creatures dead). Classic raids: at most 30 min between raids. Rare map spawns: at most 60 min (30 min while respawn was 2x) | `data\scripts\family\rare_creatures.lua` and the files below |
| Party quests | One player can do the quests in the table below | the files listed there |
| Exclusive quests | Both Djinn factions; all three Secret Service agencies, one after another; every chest of a "choose one reward" room | `data\scripts\family\solo_quests.lua` |
| City life | About 190 walking NPCs in 11 cities with quest tips, ship travel and 12 vendors (see "City life" below) | `data-otservbr-global\scripts\family\city_life.lua` |
| Houses | Bought at once in Cyclopedia > Houses > Bid, or with `!buyhouse` at the door. Price = the house's rent x 0.65, paid once; no rent, never lost, no level, no limit; guildhalls without a guild. `!house` in game shows a guide (see "Houses" below) | `family\config.family.lua`, `data\scripts\lib\family_houses.lua` |
| House furniture | Since 2026-10-19 every house for sale is furnished in its town's style (classic in Thais, Carlin, Edron, Venore and the rest; elven in Ab'Dendriel; dwarven in Kazordoon and Farmine; nordic in Svargrond; desert in Ankrahmun, Darashia and Issavi; tropical in Port Hope and Liberty Bay; alchemistic in Yalahar). About a third, mostly the big ones, are rich: luxury furniture, trophies, statues and valuable equipment on tables and floors. Cluttered like lived-in houses: books, bags, food, kitchenware, candles, tools and instruments on tables, furniture tops and much of the floor (rich houses: gems, gold, goblets, treasures). Seen through windows and doors (nobody can enter a house without an owner). Pieces stand against walls facing the room, chairs face their table, hangings go on inner walls; doors, stairs and beds stay reachable. Buying a house (Cyclopedia, `!buyhouse`, GOD `/owner`) removes all of it first: you get the house empty, with only the map's own fixtures. A house given up is furnished again at the next start | `data\scripts\family\house_decor.lua` (`Family.houseDecor`), plan in `house_decor_data.lua`, tool in `tools\family\house_decor` |
| Saving | The whole server saves every 15 minutes (`data\scripts\family\auto_save.lua`; the map is not cleaned, so items on the ground stay). Any character can type `/save` (or `/save 5` for 5 minutes from now). Upstream's interval save never ran with `globalServerSaveTime = "06:00:00"` (it expects HH:MM), so `toggleSaveInterval = false` | `family\config.family.lua`, `auto_save.lua` |
| Newspaper | A newspaper seller near the temple of each of the 11 city-life cities sells today's *Gaia Times* for 1 gp (`hi`, `newspaper`, `yes`). Using it shows boosted creature and boss, Rashid, Yasir and vendor cities, world changes, rare creatures seen or possible today, raid regions, events and server notes, with the edition's date at the top. New edition at 06:00 (see "Newspaper" below) | `data-otservbr-global\scripts\family\newspaper.lua` |
| Daily reward | The streak never expires: missing days costs no joker tokens and keeps the streak bonuses. A new reward day starts at 06:00 even if the server was off then (upstream, the day only advanced while the server ran at 06:00). After a claim the Reward Wall shows a countdown instead of upstream's "expired" / "You did not claim your daily reward in time", and a message says the items are in the Store inbox. Upstream fix #4146 backported 2026-10-19: picking several charged items (runes) gives that many items, the pick is checked, a failed delivery is rolled back, the countdown counts 24 h (not 25) and missed days are counted with a server save counter; `Family.keepDailyRewardWindow` keeps that counter from ever costing a joker token or the streak Since 2026-10-21 (Rodrigo's choice) there are no Prey rerolls on the wall (Prey is free here): day 3 gives an XP boost (+50%, 30 minutes, like day 7) and day 5 gives 25 Tibia Coins (picked on the wall, put in the Store inbox; use them to add them to the coin balance); every XP boost claim adds its full time (upstream only topped the boost back up to 30 minutes). Switch `Family.dailyRewardNoPrey`. Since 2026-10-24 (Rodrigo's choice) day 6 is a mixed pick of 20: the 8 training weapons, the vocation's potions and runes (as on days 1, 2 and 4) and an XP boost, in any mix; each XP boost pick adds 3 minutes of +50% experience at once (20 picks = 1 hour) and puts nothing in the inbox (on the wall it has the picture of a scroll of heroic deeds); training weapons keep their normal 50 charges and a potion pick gives one potion (upstream gave every day 6 pick 50 charges). Switch `Family.dailyRewardDay6Mix` | `data\scripts\family\daily_reward.lua` (`Family.dailyRewardNeverExpires`, `Family.dailyRewardWallCountdown`) |
| Rookgaard | Mainland characters can visit (since 2026-10-15): Captain Bluebear in Thais sails there for 100 gp (`hi`, `rookgaard`, `yes`, arriving at the Rookgaard temple). The Oracle, above the Rookgaard academy, sends a character with a vocation back to its home town's temple for free (`hi`, `yes`; Thais if the home town is a beginner island). Characters without a vocation still choose town and vocation as upstream. Rookgaard quests such as the Present Box (Legion Helmet from Seymour) and Dragon Corpse work once per character | `data-otservbr-global\scripts\family\rookgaard_travel.lua` (`Family.rookgaardTravel`) |
| Winter event | December only (since 2026-10-15): monsters drop christmas tokens (1.5% x rateLoot = 4.5% per kill; Ruprecht on Vega trades them all year, reached with Nielson north of Carlin: `hi`, `vega`, `yes`); Santa Claus in the Thais temple gives one present per character per year (`hi`, `present`); Grynch Clan goblins raid a random big city at most every 90 min (harmless, drop christmas present bags); Captain Breezelda in Svargrond sails to Percht Island (`hi`, `percht`, `yes`, 100 gp), where Frosty trades the three Percht sleigh mounts for 10 percht horns + 10 broken bells each and sails back to Svargrond all year. The Percht Queen fight is not implemented. The newspaper lists the event | `data-otservbr-global\scripts\family\winter_event.lua` (`FamilyWinter`) |
| Temple healing | Since 2026-10-16: temple NPCs who offer to `heal` (28 of them, e.g. Isimov, Quentin, Pydar) restore full health and mana and cure poison, burning and other damage conditions whenever something is missing (upstream: only below 40 HP, up to 40). No NPC file changed; the healers are recognised by their upstream answer | `data\scripts\family\temple_healing.lua` (`Family.templeFullHeal`, `Family.templeRestoreMana`) |
| Offline training | Since 2026-10-17: logging out on a training statue trains for the whole time away, up to 365 days (upstream 21; `Family.offlineTrainingMaxDays`), also while the server is off (measured from logout to the next login; upstream at most 12 hours). The offline training time (12:00 in the client) is never used up: it is full after every login. No 10-minute minimum: every full minute away counts. The skill stages apply as for normal training, times 4 from `rateOfflineTrainingSpeed` (2 until 2026-10-23, when every statue skill was made twice as fast); shielding, which trains next to every statue skill, is doubled too (`Family.offlineShieldMultiplier` = 2). House beds (premium; headboard + footboard from Ukea near Ab'Dendriel, 40 gp each, or Store beds) open the same skill choice and train the same way; waking up in a bed restores full health, mana and soul (upstream: only while food regeneration lasts, and 1 soul per 15 minutes) | `data\scripts\family\offline_training.lua` (`Family.offlineTrainingUnlimited`, `Family.bedFullRest`) |
| Magic level training | Since 2026-10-23 magic level trains faster. On a training statue (or a house bed) every second away counts as about 86 mana spent (600/7; 600/14 for a few minutes on 2026-10-23, then statue hours halved) for every vocation; upstream counts only your mana regeneration (Master Sorcerer 1 mana per second, knights a third of that), about 300 times slower than a dummy, while melee on a statue is about 14 times slower. On an exercise dummy, rods and wands count 1,200 mana per hit (upstream 600), times the dummy's rate (house dummies 110%). The magic level stages apply on top. Rough hours: sorcerer/druid ML 60 to 90 about 37 h away on a statue (was 1,588) or 2.6 h on a dummy (was 5.3); 90 to 100 about 107 h or 7.6 h; paladin 25 to 30 about 21 h or 1.5 h; monk 30 to 40 about 64 h or 4.6 h; knight 8 to 10 about 11 h or 0.8 h | `data\scripts\family\magic_training.lua` (`Family.statueMagicManaPerSecond`, `Family.exerciseMagicManaPerHit`; nil = upstream) |
| Melee skills | Since 2026-10-17: sword, axe and club fighting are one shared skill: when one goes up (hunting, exercise weapons, statues, offline training), the other two are raised to the same level and progress; the highest always wins, nothing is lowered. Fist, distance, shielding and magic level stay separate | `data\scripts\family\melee_skills.lua` (`Family.sharedMeleeSkills`) |
| Party | Since 2026-10-17: shared experience (switched on in the party menu) works at any level difference, at any distance and without the 2-minute activity rule. The level rule is a config value; when the server still refuses sharing for distance or inactivity, a script shares each kill the same way (party bonus, divided by party size, each member's own bonuses). The party icons may still show members as far away or inactive | `family\config.family.lua` (`partyShareRangeMultiplier = 10000`; upstream 1.5), `data\scripts\family\party_share.lua` (`Family.partyShareAnywhere`) |
| Corpses | Since 2026-10-17: monster corpses can be moved right away (upstream they are locked to the floor for their first 10 seconds). The corpse turns into its next, movable look as soon as the loot is in it: same loot, same rotting time (10 s shorter), loot message and auto-loot as before, and for the first 10 seconds only the killer and his party can open it. Boss reward corpses and quest corpses are not changed. Rotworm, spider, dog, rabbit and bear corpses keep the 10-second lock (their movable look is not a corpse for the client: it would lose the loot sparkle, auto-loot and quick loot; fixed 2026-10-17) | `data\scripts\family\movable_corpses.lua` (`Family.movableFreshCorpses`) |
| Map discovery | Since 2026-10-17: Cyclopedia > Map works as in Tibia. Select a subarea in the Cyclopedia map and press "Start Discovering" to place its 10 points of interest; one subarea at a time (starting another drops the points of the previous one; "Reset points of interest" places new ones). Each point shows as Tibia's pink vortex (seen only by you) and on the map when you come near it, and is found the moment you come within 3 squares of it (checked on every step; the vortex bursts away); a white message at the bottom of the screen says when you enter or leave the subarea you are discovering (with how many points you found) and each time you find a point ("3 of 7"); no point is placed where you can already see it when you press the button; find 7 and the subarea is discovered for good (a treasure map shows). Points are the real Tibia spots players mapped (TibiaMaps.io), above and below ground, wherever our map can reach them, topped up with generated spots; a subarea covers every floor under its shape (188 can be selected). Since 2026-10-21 no point is inside a house or where only an NPC can stand (behind a shop counter), and points a character already had in such places move to other spots of the same subarea at the next login (found ones stay). An area's % is its discovered subareas: NPCs show on the map at 30%, passages at 70%. At 100%: the area's achievement (e.g. "Elven Woods"), its creatures on the map (silhouettes for creatures not yet in your Bestiary), raid warnings there (rare raids are announced 60 minutes ahead, then marked on the map while they last) and extra speed inside it (100 for one fully discovered area, +5 per further area, up to 195). Measuring Tibia quest log ("A Speck of Land" shows the progress of the subarea you are in). Charos (Adventurers' Guild: `hi`, `discovering`, `outfit`, `yes`, `ten`/`fifteen`/`twenty`) gives the Discoverer outfit for 10 fully discovered areas ("Go and find Charos" message when you reach 10, 15 and 20), its addons for 15 and 20; his old city attunement still works with `attune`. Titles Dedicated Entrepreneur (10) and Globetrotter (20). The Improved Respawn Rate donation is not implemented | `data\scripts\family\map_discovery.lua` (`FamilyDiscovery.enabled`, `automatic` (off), `oneAtATime`, `vortex`, `revealAll`, `pointsNeeded`, `speedBonus`, `raidWarnings`, `raidWarningMinutes`), data in `data\scripts\lib\family_map_discovery_data.lua` (rebuilt with `tools\family\map_discovery\`), raid announcements in `rare_creatures.lua` |
| Adventurer's stone | Since 2026-10-17: every temple NPC (Quentin, Alia, Isimov, Rahkem, Kasmir and 15 more) understands `hi`, `adventurer's stone`, `yes` (upstream only `adventurer stone`). The first stone of each day is free from any of them, further ones cost 30 gold (upstream: free once per NPC, ever). The day starts at the server save (06:00). An NPC still says "Keep your adventurer's stone well" while you carry one; no NPC file changed | `data\scripts\family\adventurer_stone.lua` (`Family.dailyFreeAdventurerStone`) |
| The Way of the Monk | Since 2026-10-17 the monk quest can be played from start to end. The Blue Valley NPCs stand on the map (upstream had their scripts but did not place them): Enpa-Deia Pema (healing, monk shop, `pilgrimage`), Enpa Rudra (spells, promotion), Dhar-Enpa Rahng, Dajcho the Monk, the gate guardians Saih and Chesa, and Ambassador Manop in Dawnport. Ways in: Manop (monks leaving Dawnport, `invitation`, `yes`, `seeker`, `yes`), the crystal sphere east of Thais and the one in the Adventurers' Guild next to the daily reward shrine (put there at startup; our map had none); the spheres near Pema bring you back where you came from. Any vocation can do the pilgrimage: say `pilgrimage` to Pema to start it, and again to hear what you have done and where the next shrine is. The 10 shrines are used in order, each from a level (6 to 275); monks get the Enlightenment items, Mystic Repulse, Forceful Uppercut and Focus Harmony, +5% fist damage at 5 of them, and (ours, as in Tibia) 2% less damage from melee attacks per shrine (20% with all ten); other vocations get the experience. The last shrine (Eternity) closes the quest log and gives the achievement Hope of the Merudri; monks also get +10 Wheel of Destiny points. Not possible with our server binary: the title Pensive Wanderer and the Wheel points for other vocations | `data\scripts\family\monk_pilgrimage.lua` (`Family.monkGuildSphere`, `Family.monkShrineMeleeProtection`), shrines in `data-otservbr-global\scripts\quests\the_way_of_the_monk\shrines.lua` |
| Monk equipment | Since 2026-10-17 the monk items Canary had but nothing gave are found as in Tibia (TibiaWiki): monk robe from tarantulas, bambus jo from Ratmiral Blackwhiskers, naga katar from Timira the Many-Headed, iks footwraps from the Mitmah Vanguard, gnomish footwraps from the three Dangerous Depth bosses (each as often as an item of the same rarity of that creature); the 20 weapon dealers (Sam, Hardek, Romella, Uzgod, Esrik...) and the trader hireling sell and buy pair of monk fists (270/90 gp), nunchaku (405/135) and sais (540/180); Cledwyn sells the leaf, energy and ice robes (100 silver tokens each, like the magma robe); Bakragore's bag you covet can hold grand sanguine claws; the Inquisition reward room has a tenth chest (east corner) with the merudri nanbando; the chest next to the Wrath of the Emperor reward stands holds the merudri scale mail; Maeryn (Grimvale) enchants the werewolf helmet for monks (`werewolf helmet`, `yes`, `monk`, then moonlight crystals). Still not obtainable (what gives them is not in our server): spirit bind (monk Spirit Sphere), norcferatu bonehood and fleshguards (Vladrukh), the rending, draining and siphoning inferniarch claws (Doomforging), genesis serenity armor and legs | `data\scripts\family\monk_gear.lua` (`Family.monkGear`) |
| Spell List | Since 2026-10-18 the client's Spell List shows as known only the spells the character has learned. Every spell must be bought from a spell teacher (`toggleLearnSpells = true`, as in Tibia), but the server's login packet marked every spell of the vocation as known, so unbought spells (e.g. Berserk) looked learned and casting them said "You need to learn this spell first." The list is sent again with the learned spells a second after login and right after learning or forgetting a spell, changing vocation or reloading, saving the wheel of destiny or changing a gem, when transcendence starts or ends, and (since 2026-10-20) when you come back after a death: clicking "Ok" on the death window brings back the same character without a login, and the server sends its full list again | `data\scripts\family\spell_list.lua` (`Family.knownSpellList`) |
| Vocation bonuses | Since 2026-10-18, after Rubinot's VIP bonuses: promoted vocations (Master Sorcerer, Elder Druid, Royal Paladin, Elite Knight, Exalted Monk) get +10 hit points and +20 mana every 3 seconds and +3% critical hit chance (5% → 8%); unpromoted vocations (Sorcerer, Druid, Paladin, Knight, Monk) half of it (+5 / +10 every 3 s, +1.5%); no vocation, nothing. The extra regeneration counts only while fed, like the normal one (and not in protection zones, as it); it is a separate effect like a ring of healing. The critical chance is always on and shows in the Skills window. Checked about once a second (login, promotion, food running out, eating) | `data\scripts\family\vocation_regen.lua` (`Family.vocationRegen`, `Family.vocationCritical`, `Family.vocationBonus`) |
| Tibiadrome | Since 2026-10-18 (phase 1: the fights; phase 2 on 2026-10-23: rotations, points and the reward exchange, next row) the arena behind the demon trophies works. Every trophy (Thais, Edron, Kazordoon, Rathleton, Ankrahmun) leads to the lobby in Thais (Xodet stays there); its exit leads back to the trophy you came from. The two portals at the north wall of the lobby open the arena: level 50+, 10-minute cooldown after leaving (Tibia: 60; lowered 2026-10-23; players with access ignore it), one party at a time; the party leader steps in and every member must be in the lobby. The party starts at its lowest Drome level (first wave = that level + 1). Waves of 2 minutes: 4 creatures for one player, 8 for two, 11/14/17 for three/four/five, +3 per further member, four of the five Drome creatures (Domestikion, Hoodinion, Mearidion, Murmillion, Scissorion; Tibia's looks and first-level hit points, no experience or loot). Killing them all clears the wave (Drome level = highest wave cleared) and the next comes 5 s later; when time runs out everyone goes back to the lobby. Each wave is 8% stronger than the first (linear; hit points and damage), and wave 1 follows the party's average level (level 100 = the creature files, 300 = three times, 50 or less = half). A living Domestikion makes the creatures within 5 squares hit 15% harder. No death in the arena (a deadly hit heals you and sends you to the lobby), no damage between players, and potions, runes and ammunition (also spears, throwing stars...) carried when entering are refilled every second. The corner portals of the arena are exits | `data\scripts\family\tibiadrome.lua` (`Family.tibiadrome`, values in `Family.drome`), `tibiadrome_monsters.lua` |
| Tibiadrome rewards | Since 2026-10-23. **Lorenzo** (new NPC in the east nook of the lobby, next to Xodet) trades Drome points: say `rewards`, then the name and `yes` (`phant`, `attires` as in Tibia). Prices from TibiaWiki BR: arena badge replica 250, brown/green/blue/black/red pit demon 400/750/1,500/3,000/6,000, drome cube 2,500, the five Drome plushies and the ogre rowdy and retching horror dolls 2,500 each, tournament accolade and sublime tournament accolade 5,000, Phant mount 8,000 (+ "Phantastic!"), complete Lion of War outfit 12,500. Also `points`, `rotation`, `ranking`, `concoctions`. **Rotations** of two weeks from Wednesday 2026-10-21 06:00 (server time). When one ends, everyone who cleared a wave gets **100 Drome points per Drome level** (Tibia 10) and a parcel in the inbox with a letter and concoctions: places 1-5 three, 6-10 two, 11-20 one, 20% of the rest one; the Drome level starts again and the next run starts 5 waves below the last level. Settled at the next login, arena entry, cleared wave, talk to Lorenzo or minute check, so a switched-off PC loses nothing; ranking kept in the global KV `family-drome-rotations`. Concoctions (upstream: 1 hour while online, 24 h per kind) never include Stamina Extension (stamina never goes down here); a drome cube gives one at random | `data\scripts\family\tibiadrome_rewards.lua` (`Family.tibiadromeRewards`, values in `Family.dromeRewards`), `data-otservbr-global\npc\lorenzo.lua` |
| NPC keywords | Since 2026-10-18 NPCs find their keywords as whole words first, then at the start of a word, and only then anywhere (as upstream); in each round the longest keyword wins. Before, a short keyword inside a longer word stole its answer ("crunor" and "norma" answered as "no", "tibianus" as "tibia", "uzgod" as "god", "intense healing" as "heal", "lesser front sweep" as "front sweep"), keywords with capitals or hyphens never answered (the Blue Valley monks, Kais, Kendra, Oswald, Sinatuki...), and a few NPC files needed two words where either should do (fixed below) | `data\scripts\family\npc_keywords.lua` (`Family.npcKeywordRounds`) |
| Boss coins | Since 2026-10-18 every boss (Bosstiary or reward chest) drops Tibia Coins, always, by its hit points: up to 10,000 → 1-2, to 50,000 → 2-4, to 150,000 → 4-8, to 500,000 → 8-15, more → 15-30 (one coin = 5,000 gold at the Coin Brokers). With a reward chest each helper gets his own. Boss parts and phases get none (creatures with no loot, helpers with no experience outside the Bosstiary). 292 bosses at the first start | `data\scripts\family\boss_coins.lua` (`Family.bossCoins`, `Family.bossCoinTiers`) |
| Loot from TibiaWiki | Since 2026-10-18 items TibiaWiki (BR) lists for a creature that our creature files lack are added at startup, with a chance by rarity (always 100%, common 33%, uncommon 10%, semi-rare 2.8%, rare 0.9%, very rare 0.2%); items already there keep their chances, items only we have are kept, event and raid drops left out. 910 creatures compared (all folders but raids, event creatures and nostalgia), 996 items added to 332 creatures; asterisk items ("Loot Divergente"), drops without a rarity and raid-only pages left out, reward-chest stackables get no quantity. Details in `tools\family\loot_audit\report.md`, not compared in `skipped.txt` | `data\scripts\family\loot_updates.lua` (`Family.lootUpdates`), data in `loot_updates_data.lua`, tool and report in `tools\family\loot_audit` |
| Market | Since 2026-10-18 the market always has offers: a hidden character ("Family Market", it cannot log in) keeps anonymous buy and sell offers for every tradable item, placed again at every server start (10,000 of every item since 2026-10-23, before 100 of non-stackable items; the client buys or sells at most 2,000 non-stackable items per transaction, repeat to take more). Prices from real Tibia worlds (median month average of 12 worlds, TibiaMarket; NPC prices when there is none): buy offers 10% below, sell offers 10% above. Sell offers only for items players can get again (creature loot, bosses included, or an NPC shop); quest, event and store items get buy offers only. Gold coins, Tibia Coins and silver/gold tokens are left out. No gold loops with NPCs: a sell offer is always above what an NPC pays, a buy offer always below what an NPC charges, and potions, runes, ammunition and other stackable supplies are never cheaper than at the NPCs. Creature products are not sold by NPCs any more (the city creature products traders and the Imbuement Assistant's packages and shop are off, `FAMILY_SALES` in `imbuement_assistant.lua`), so the market pays real prices for them (cyclops toe 510, sold at 630). Items sold to the market are destroyed at the next start. `priceScale` (1.0) scales all offers if gold comes too easily | `data\scripts\family\market_bot.lua` (`Family.marketBot`), prices in `market_bot_data.lua`, tool in `tools\family\market` |
| Soul War reward | The final chest gives another random Soul item after each new Megalomania kill, or once every 20 h | `solo_quests.lua` |
| Edron City Tasks | Since 2026-10-19 Daniel Steelsoul (Edron) has 13 hunting tasks with no level limits: the four of Tibia (100 trolls, 150 goblins, 300 rotworms, 500 cyclopes) and nine new ones on Edron's hunting grounds (300 orcs, 200 dwarves of Cormaya, 300 treelings/leaf golems, 200 wyverns, 500 undead, 400 lycanthropes, 300 renegade heroes, 300 dragons, 300 demons). Say `task`: he pays every finished task, shows the progress of the others and lists the rest; say a task's name and `yes` to take it. Any number at once, every task repeatable, `cancel` gives one up (its kills are lost). Reward: 3% to 25% of the experience your next level needs (trolls/goblins 3, rotworms/dwarves 5, orcs/treelings/wyverns 8, cyclopes 10, undead 12, lycanthropes/heroes/dragons 15, demons 25; never less than the Tibia reward, not multiplied by the rates) and base gold x level / 20. Quest log "Edron City Tasks": one entry per task, progress per creature while it runs, "(completed)" after the first time (also while repeating); the quest is completed when all 13 were done once, and the achievement "Champion of Edron" (secret, 5 points) is given. Kills of party members count; a kill can also count for Grizzly Adams. Characters with Daniel tasks from before keep them | `data-otservbr-global\scripts\family\edron_tasks.lua` (`FamilyEdronTasks.list`: kills, creatures, `share`, `exp`, `gold`), dialogue in `npc\daniel_steelsoul.lua`, quest log `lib\core\quests\catalog\053_edron_city_tasks.lua` |
| Sinatuki | Fixed 2026-10-20 (Phase 1 of the quest roadmap). The Chakoya girl in Grimlund eats green perches and rainbow trouts in any mix: say `nupi` and she takes what you carry, up to 100 in total (a message shows how many she has eaten). At the 100th she gives 5 shards and the secret achievement "Jamjam", once; after that she wants nothing more. Needs Barbarian Test 3 and Ice Islands 5 (to understand her). Upstream wanted 100 of one kind, gave the shards again every time and never gave Jamjam | `data-otservbr-global\npc\sinatuki.lua`, storage `Storage.Quest.FamilySinatuki.Fish` (48710) |
| Festive Outfits | Fixed 2026-10-20 (Phase 1). The First Dragon gives the outfit; Muriel in Thais gives the addons: say `addons`, `yes`, then `mask` (3 porcelain masks, first addon) or `feather` (50 colourful feathers, second addon). Both addons give the achievement "Reason to Celebrate" (also at login if you already have them). Upstream's dialogue could never be finished | `data-otservbr-global\scripts\family\festive_outfits.lua` (`FamilyFestive`), dialogue in `npc\muriel.lua` |
| Waterskin of Mead | Added 2026-10-20 (Phase 1). Once Lurik's Ice Islands mission "Formorgar Mines 1: The Mission" is accepted, the barrel in the Formorgar Mines (32202,31153,8, the only barrel there) gives a fur bag with a berserk potion, 82 gold and a waterskin of mead, once per character. The reward was missing on our map; TibiaWiki shows the barrel only on pictures | `data-otservbr-global\scripts\family\waterskin_of_mead.lua`, storage 48711 |
| The Spirit Will Get You | Added 2026-10-20 (Phase 1). The Cranky Lizard Crone (Spirittrails, north of Zao): `mission`, `yes` = find the three pages of a faded last will in the ruins around her house: the wagon at 33177,31020,5, the wagon at 33162,31056,4 and the stones at 33165,31056,6 (TibiaWiki's spots; a lost page can be found again). `mission`, `yes` with the three pages = 10,050 experience. Only then does she make the Wayfarer addons: `cape` (old cape, first addon) or `hat` (sedge hat, second addon), then `yes`. Quest log: Tibia Tales, "The Spirit Will Get You". Upstream only traded the addons, with no quest | `data-otservbr-global\scripts\family\spirit_will_get_you.lua` (`FamilySpirit`), dialogue in `npc\cranky_lizard_crone.lua`, storages 48712-48715 |
| Pilgrimage of Ashes | Added 2026-10-20 (Phase 1). Ask any guide NPC (Guide Luke in Thais and the others) about the `pilgrimage`, `yes`. Then say `mission` to Norf (south of Thais), Humphrey (north of Carlin), Edala (Sun Tower, Ab'Dendriel), Pydar (Kazordoon, after Kawill's part of the spark of the phoenix) and Eremo (near Cormaya): each gives his blessing for 1,000 gold less, once. With all five blessings a guide pays 20 platinum coins (`pilgrimage` again). In Tibia the gold is only for characters below level 25; here it is for everyone, and blessings you already had count. Quest log: Tibia Tales, "Pilgrimage of Ashes" | `data-otservbr-global\lib\others\family_pilgrimage.lua` (`FamilyPilgrimage`), one line in each guide and blessing NPC, storages 48716-48721 |
| Venore Daily Tasks | Added 2026-10-21 (Phase 1). Norman the Foreman (central production site in the Venore swamp, upstairs) gives three tasks, each paying 250 gold and 250 experience: `sabotage` (step on the hidden mud hole just south of the ropespot at the southern production site, 33029,32141, to drop into the charlatan cave and kill 5 Little Corym Charlatans; bring a rope to climb out), `maintenance` (use his can of oil on the saw, the crane and the wooden treadmill of the northern, central and southern production sites) and `pathfinder` (bring his grind stone to Scott the Scout in the northern swamp and his pathfinder kit to Frank the Plank at the southern site). Say the task's name, `yes`; say it again (or `report`) to get paid; `task` shows progress; `bonus`, `yes` pays 250 gold and 250 experience more when all three are reported the same day. Everything opens again at the 06:00 server save (Tibia: 20 h); a task taken keeps its progress over the reset. Quest log "Venore Daily Tasks". No time limit in the cave (Tibia: 5 minutes). Switch `Family.venoreDailyTasks` | `data-otservbr-global\lib\others\family_venore_tasks.lua` (tasks and dialogues), `data-otservbr-global\scripts\family\venore_tasks.lua` (hole, can of oil, kills), quest catalog `054_venore_daily_tasks.lua` |
| Braindeath Quest | Fixed 2026-10-21 (Phase 1). The coffin of The Undeath Stare (32546,31522,11, on the way from Beregar; red backpack with 13 platinum, potions, rope and shovel) had no guard: a Braindeath now spawns in the coffin room, as on TibiaWiki | `data-otservbr-global\world\otservbr-monster.xml` |
| Quest tracker | Fixed 2026-10-20 (reported by Rodrigo's father): the tracker window now follows progress while you play. Upstream sent it again only when a quest's own storage changed, so texts that show progress kept elsewhere (Edron City task kills, Grizzly Adams points...) only changed after opening the quest log. Now, after any storage change of a player who tracks missions, the tracked texts are rebuilt 0.3 s later and sent if one changed; a check every 5 s catches the rest. Switch `Family.questTrackerRefresh` | `data\scripts\family\quest_tracker_refresh.lua` |
| Skill bars after death | Fixed 2026-10-20 (reported by Rodrigo): after dying, skills showed a wrong percentage to the next level (sword and shielding at 100%). Nothing is lost (`deathLosePercent = 0` keeps every try), but Canary's death code divides the tries by the current level's requirement instead of the next one, so the bar showed the real progress times the skill multiplier (knight x1.1: 91% shown as 100%, above that 0%) until the next try or a full logout. The script compares every skill's bar with its tries at login and about once a second and rewrites a wrong one with the same level and tries. The shared melee skills now read this true percentage too, so a wrong bar is never copied to axe or club. Switch `Family.fixSkillPercents` | `data\scripts\family\skill_percent_fix.lua`, `melee_skills.lua` |
| Adventurer's stone anywhere | Since 2026-10-20 the stone works anywhere, not only in temples, as a fast trip to the Adventurers' Guild. Refused during a fight (battle icon) or PZ lock, on tiles where logging out is not allowed, and inside boss or encounter zones (boss and quest rooms). The guild's exit portal always leads to your home temple. Switches `Family.adventurerStoneAnywhere`, `Family.adventurerGuildExitHome` | `data\scripts\family\adventurer_stone.lua` (switches), `actions\adventurers_guild\adventurers_stone.lua`, `movements\teleport\adventurers_guild.lua` |
| Battle icon | Since 2026-10-20 the battle icon (in fight) ends as soon as no enemy is near: no hostile creature on your screen (same floor) and none attacking you; checked about once a second. Upstream it stays 60 s (`pzLocked`) after the last hit. A PZ lock is not touched. Switch `Family.shortFight` | `data\scripts\family\short_fight.lua` |
| Night creatures (Troll Sabotage) | Fixed 2026-10-21 (reported by Rodrigo's father): on the Troll Sabotage path north-east of Edron the two werebadgers and the werefox (mountain floors above the river vortex) appear only at night, as on TibiaWiki; our map had them all day. Night = Tibian 18:00 to 06:00 (the server's day/night light). At night each spot gets its creature, again 90 s after a kill; at daybreak the living ones disappear. Their three spawns were taken out of `world/otservbr-monster.xml` (a FAMILY comment marks each). Switch `Family.nightSpawns` | `data-otservbr-global\scripts\family\night_spawns.lua` |
| Mount terrain | Since 2026-10-19 every mount is faster on its own terrain: +30% of your base speed on its home terrain, +15% on a related one, never slower anywhere. Flying and floating mounts (41: carpets, owls, pegasi, ravens, gryphon, skulls...) get +30% under the open sky (the surface, nothing above). Terrains come from the ground you stand on: Water (shallow water, sea floor, 2 squares from the sea or a lake), Swamp (mud, slime, 2 squares from swamp water), Desert (sand, dry ground), Snow (snow, ice), Volcanic (lava ground, burnt soil, 2 squares from lava), Wild (grass, forest, jungle, dirt, rock), Caves (wild or town ground on floor 8 and deeper) and Town (roads, pavements, floors); a square can be two at once (a grass shore is Wild and Water). A white message says when your mount feels at home or likes the place (the same one at most every 30 s). The outfit window shows each mount's terrains in its name, home first: "Water Buffalo (Swamp/Water)", "Gryphon (Sky)"; `!mounts` lists your mounts and what you get where you stand. Speed is not walking speed: +30% speed is about +20% steps per second (Tibia's step formula) | `data\scripts\family\mount_terrain.lua` (`Family.mountTerrain`: `enabled`, `home`, `related`, `nearRadius`; the 236-mount table `Family.mountTerrainMounts`), grounds in `mount_terrain_data.lua`, tools in `tools\family\mount_terrain` |
| Stamina | Never goes down (since 2026-10-15): put back to 42:00 at login and about once a second, so the green +50% experience bonus is always on and orange/red stamina never happens. The stamina system stays on, so Prey and Hunting Task bonuses still count down while hunting | `data\scripts\family\stamina.lua` (`Family.staminaNeverDecreases`) |
| Logout in a fight | Logging out works while the battle icon is shown (since 2026-10-15): the logout request clears the in-fight state just before the server handles it. No-logout tiles (some quest and arena rooms) still refuse. Closing the client without logging out still leaves the character in game until the icon ends, as in Tibia | `data\scripts\family\logout_in_fight.lua` (`Family.logoutDuringFight`), module `data\modules\scripts\family\logout_in_fight.lua` |
| Coins | Looted gold goes to the backpack (`autoBank = false` since 2026-10-14; NPC sales also pay coins). Coins change up by themselves: 100 gold coins carried become 1 platinum coin, 100 platinum coins 1 crystal coin (checked about once a second, depot and house untouched; a full backpack never loses coins). Cyclopedia house purchases still take the bank balance: deposit at a bank NPC first (`hi`, `deposit all`, `yes`) | `data\scripts\family\coin_change.lua` (`Family.autoCoinChange`), `family\config.family.lua` |
| Familiars | Permanent (since 2026-10-14): the familiar spell (knight `utevo gran res eq`, paladin `utevo gran res sac`, druid `utevo gran res dru`, sorcerer `utevo gran res ven`, monk `utevo gran res tio`; level 200) calls the familiar until you say it again (free) or it dies; no 15-minute limit, no cooldown. Mana is charged only when it appears. It returns after logout or death until dismissed or killed. Familiars still cannot enter boss rooms | `data\scripts\family\familiar.lua`, switch in `data\scripts\lib\family_familiar.lua` |
| Grizzly Adams tasks | Killing in the Name Of without level ranges: every hunting task at any level (crocodiles to destroyers), points never capped by level, rank promotions, the full boss list and the special tasks open at any level. Still as upstream: 3 tasks at a time, each task 3 times, Demons only for Elite Hunters, the points needed per rank | `solo_quests.lua` (`Family.noTaskLevelCap`) |
| Potions | Checked 2026-10-22 against TibiaWiki BR and the 15.11 client data: every potion keeps Tibia's vocations and levels, except the great mana potion, which any vocation (knights included) drinks from level 80, as in Tibia since update 15.25 (16 Jun 2026). Kegs and casks already filled potions for anyone. Four bosses (The Dread Maiden, Megasylvan Yselda, Tentugly's Head, Ratmiral Blackwhiskers) dropped a transcendence potion with an id that is no potion in client 15.11; they now drop the real one (monks: +4 fist fighting for 10 minutes). The 15.25 superior and distilled mana potions do not exist in client 15.11 | `data\scripts\actions\items\potions.lua`, `data\items\items.xml` (look text), 4 monster files (see below) |
| Training weapons | Since 2026-10-22 (Rodrigo): the training weapons from the daily reward (day 6, among potions, runes and an XP boost since 2026-10-24; sword, axe, club, bow, rod, wand, shield, wraps; 50 charges) are no longer Store items, so they can be thrown in a dustbin, dropped or kept in the depot (upstream they could only leave the backpack inside your own house). They train exactly like exercise weapons (same skill per hit) and, as all training weapons here, never run out, so one per skill is enough. Weapons already owned are changed at login, and one taken out of the depot when moved. Store-bought exercise weapons are unchanged. Switch `Family.disposableTrainingWeapons` | `data\scripts\family\training_weapons.lua` |
| Store pictures | Since 2026-10-24: every Store offer, category and home banner has its picture. The client draws items, mounts and outfits itself but downloads the other pictures (beds, blessings, Premium Time, XP boost, Prey and charm offers, hireling services, name and sex change, category icons) from `coinImagesURL`, which upstream points at a web server on 127.0.0.1 that we do not run. The 75 pictures (from the opentibiabr store pack) are in `family\store-images` and GitHub serves them from this public repository, so the PCs need internet for them. If old empty pictures stay, close the client and restart it. After a Store catalog change: `python3 tools/family/store_images/check.py --pack <store folder>` | `family\config.family.lua` (`coinImagesURL`), `family\store-images`, `tools\family\store_images\check.py` |
| Hit sound | Found 2026-10-22 (Rodrigo): every hit that lands plays the Light Healing spell sound, even with every sound option off. Canary v3.6.1 bug: after each hit the server tries the Weapon Proficiency "life/mana gain on hit" even when the weapon gives none, and sends the healing sound as a global sound, which no client option controls (fixed in Canary after v3.6.1; not changeable in Lua). Workaround in the client: `family\client-mute-hit-sound.ps1` sets that one sound's volume to 0 (backup kept, `-Undo`). Side effect: the Light Healing spell (exura) is silent too | `family\client-mute-hit-sound.ps1` (client side) |
| Monk shrine names | Fixed 2026-10-22 (Rodrigo): Look at a monk shrine of The Way of the Monk (the four in Dawnport and the ten Merudri shrines) said "an item of type 50244": neither Canary nor client 15.11 names them. Now "an ancient shrine", the name TibiaWiki BR gives. Which shrine it is still shows in the message when you use it ("shrine of Guidance" and so on) | `data\items\items.xml` (items 50242-50245) |
| Ambassador Manop | Fixed 2026-10-22 (Rodrigo): several answers were silent. Now: {monk} answers like "monks"; purpose, legacy and role answer (our lines; TibiaWiki gives none) and point to **seeker**, the word that sends a monk to the Blue Valley; "yes" after the invitation answers also when you already spoke to him; non-monks and players without a Dawnport shrine are told why; "no" cancels. Going to the Blue Valley again (a monk back on Dawnport) does not give the starting gear twice and keeps the shrine progress | `data-otservbr-global\npc\ambassador_manop.lua` |
| Forgotten Knowledge portals | Fixed 2026-10-24 (reported by Rodrigo). Albinius: `ice portal` now says what is missing (the tomes, or The Ice Islands Quest up to "Formorgar Mines 1: The Mission" from Lurik in Svargrond, as TibiaWiki BR says) instead of "bring my tomes or do the quest"; an open portal says so instead of asking for the offering again; `fire portal` answers and points to Ivalisse. Ivalisse: `father` works right after `hi` and answers players who have not finished The New Frontier (needed for the Fire Portal) instead of staying silent | `npc/albinius.lua`, `npc/ivalisse.lua` |

To change a number, edit the file in the table and restart the server.

### Upstream files changed for solo play

Each edit is marked with a `FAMILY:` comment. Re-check these after merging a new Canary release.

| File | Change |
|---|---|
| `data-otservbr-global/scripts/quests/the_annihilator/lever.lua` | 1 to 4 players can start the quest (upstream requires exactly 4) |
| `data-otservbr-global/scripts/quests/the_annihilator/door.lua` | The reward room stays open until every chest was opened |
| `data-otservbr-global/scripts/quests/demon_helmet/movement-walls.lua` | One player on either tile opens the walls; they close 90 s after leaving the tile |
| `data-otservbr-global/scripts/quests/desert_dungeon_quest/actions_desert_dungeon_lever.lua` | 1 to 4 players of any vocation (all four sacrifices still needed) |
| `data-otservbr-global/scripts/quests/elemental_spheres/actions_lever.lua` | Lord of the Elements entrance: 1 to 4 players of any vocation, each with any rare item |
| `data-otservbr-global/scripts/quests/the_new_frontier/action_arena.lua` | Mission 9 arena: one or two players |
| `data/scripts/actions/items/exercise_training_weapons.lua` | Charges are not consumed; rods and wands count `Family.exerciseMagicManaPerHit` mana per hit (1,200 since 2026-10-23, upstream 600) |
| `data-otservbr-global/scripts/actions/system/quest_reward_common.lua` | "Choose one" chest groups: each chest opens once |
| `data-otservbr-global/scripts/quests/the_inquisition_quest/actions_rewards.lua` | Every reward chest opens once; a tenth chest (put in the room by `monk_gear.lua`) gives Tibia's monk reward, the merudri nanbando |
| `data-otservbr-global/scripts/quests/demon_oak/actions_demon_oak_chest.lua` | Every reward chest opens once |
| `data-otservbr-global/monster/vermins/rotworm.lua` | No legion helmet since 2026-10-23 (upstream 1.89%, x3 loot = about 6%); TibiaWiki BR: only Rottie the Rotworm and the Rotworm Queen drop it |
| `data-otservbr-global/npc/` Djinn NPCs: `bo_ques`, `gabel`, `umar`, `fa_hradin`, `haroun`, `nah_bob`, `ubaid`, `baa_leal`, `malor`, `alesar`, `yaman`, `kazzan`, `the_orc_king` | The other faction's allies are accepted; the Orc King gives one lamp per faction |
| `data-otservbr-global/scripts/quests/soul_war/action-reward_soul_war.lua` | Final reward chest repeats (see the balance table) |
| `data-otservbr-global/scripts/quests/soul_war/soul_war_mechanics.lua` | Counts each Megalomania kill for the reward chest |
| `data-otservbr-global/raids/raids.xml` | Every `margin` capped at 30 (minutes between two classic raids) |
| `data-otservbr-global/world/otservbr-monster.xml` | Every `spawntime` above 3600 set to 3600 (75 rare spawns: at most 1 hour with `rateSpawn = 1`) |
| `data-otservbr-global/scripts/world_changes/oriental_trader.lua` | Yasir (oriental trader) comes every day instead of 33% of days, in Ankrahmun, Carlin or Liberty Bay; city NPCs tell where (`news`) |
| `data-otservbr-global/scripts/raids/monsters/undead_cavebear.lua` | Own raid name (upstream reused the Draptor raid's name, so one of them never happened) |
| `data-otservbr-global/npc/` Secret Service NPCs: `chester_kahs`, `emma`, `uncle` | After finishing one agency, the next can be joined |
| `data/scripts/talkactions/player/buy_house.lua` | Registered while Cyclopedia auctions are on, no one-house limit, no-rent message, fixed an undefined variable; removes the furniture of a house for sale once the buyer can pay, before the empty-house check (2026-10-19, house_decor.lua) |
| `data/npclib/npc_system/bank_system.lua` | Bankers: `withdraw all` (or `all` when asked how much) withdraws the whole balance; an answer without a number when asked for an amount (withdraw, transfer) asks again instead of "There is not enough gold on your account" |
| `data-otservbr-global/npc/captain_bluebear.lua` | Sails to Rookgaard (100 gp) while `Family.rookgaardTravel` is on; Rookgaard added to his destination list |
| `data-otservbr-global/npc/the_oracle.lua` | A character with a vocation is offered the way back to its home town's temple, before the level checks |
| `data-otservbr-global/npc/chief_grarkharok.lua` | Troll Sabotage (2026-10-21, reported by Rodrigo's father): while he waits for the troll lady's name, his other words stay quiet ("saradoca" hit "do" and he sang instead); the name must be a female character of this server, as on TibiaWiki (otherwise he asks again), and he repeats that name, not the speaker's |
| `data-otservbr-global/npc/norman_the_foreman.lua`, `scott_the_scout.lua`, `frank_the_plank.lua` | They had no dialogue; one line each calls `FamilyVenoreTasks.setupNorman/setupScott/setupFrank` (Venore Daily Tasks, 2026-10-21) |
| `data-otservbr-global/npc/walter_jaeger.lua` | Hunting Task Points shop fixed (2026-10-21): his `falconer` and `antelope` answers now stay quiet while you choose an outfit or mount (they answered first, so the Falconer outfit, its addons and the Antelope could not be bought); the mount offer asks "Do you want it?"; not enough points gets an answer for outfits and mounts too; `spent` (offered in his greeting) answers, counted from now on |
| `data-otservbr-global/npc/eremo.lua` | Spells added (2026-10-24, reported by Rodrigo: `spell`/`spells` got no answer). Upstream's Eremo says he teaches spells but had no spell dialogue, and no other NPC teaches these, so they could not be learned. `spells` lists them: Challenge (elite knights, level 20, 2,000 gold), Conjure Wand of Darkness (sorcerers, level 41, 5,000) and Wild Growth Rune (druids, level 27, 2,000); prices from TibiaWiki EN, lines ours. Divine Dazzle is not sold: it comes from the Wheel of Destiny (TibiaWiki BR, and the server's Wheel code) |
| `data-otservbr-global/npc/albinius.lua`, `ivalisse.lua` | Forgotten Knowledge portals (2026-10-24): Albinius's five offering portals in one table (`FamilyAlbiniusPortals`) with clear refusals (tomes / Ice Islands up to Formorgar Mines 1), already-open answers and a `fire portal` answer; Ivalisse's `father` without the `temple`/`mission` topic, with answers before The New Frontier, after accepting and after the report |
| `data-otservbr-global/npc/imbuement_assistant.lua` | Imbuement packages and shop off since 2026-10-18 (`FAMILY_SALES = false`); greets and points to hunting and the market |
| `data-otservbr-global/npc/tamoril.lua`, `scripts/quests/the_first_dragon/` (treasure chest, Zorvorax secrets, entrance teleport) | The First Dragon (2026-10-18): the Treasure and Life counters are the number of dragon chests opened / sacred sites visited (upstream lost the first one opened before talking to Tamoril, so the counter stayed one short and the 20th chest gave no Treasure Hunter achievement); repaired at login; asking Tamoril again no longer resets the dragons hunted; Kalyassa needs 5 chests as in Tibia (upstream 4). Tamoril still talks about the quest only from January 14 to February 12, as in Tibia |
| `data/scripts/talkactions/god/house_owner.lua` | `/owner` removes the furniture before giving a house an owner and furnishes it again with `/owner none` |
| `data-otservbr-global/npc/santa_claus.lua` | One present per character per year (upstream: once ever); fixed upstream's reward roll, which failed for 10% of presents; no crash with a full backpack; greeting mentions the present |
| `data-otservbr-global/npc/captain_breezelda.lua` | Sails to Percht Island (100 gp) while the winter event runs |
| `data-otservbr-global/npc/` keyword fixes: `puffels`, `asrak`, `woblin`, `tom`, `muhad`, `maealil`, `padreia` | Alternatives that needed both words now work alone (Puffels job/disturbing and king/tibianus, Asrak king/tibianus and song/sing, Woblin dwarf/dwarves and trade/offer); Puffels also answers spell, beast and time (TibiaWiki); Tom's job answer was filed under name; Muhad's ankrahmun keyword had braces; Maealil's intense healing rune and Padreia's ultimate healing rune were filed under the spell's name, hiding the spell |
| `data-otservbr-global/npc/frosty.lua` | Sleigh mounts for 10 percht horns + 10 broken bells each (upstream: a percht skull from the Percht Queen, who is not implemented); free ride back to Svargrond; no error on a plain `yes` |
| `data/scripts/creaturescripts/player/offline_training.lua` | With `Family.offlineTrainingUnlimited` the whole time away counts (not 12 h), the offline training time is not used up, there is no 10-minute minimum and the cap is 365 days (the 32-bit addition is limited to 12 h); the message shows days; magic level counts `Family.statueMagicManaPerSecond` mana per second instead of the mana regeneration, and shielding is multiplied by `Family.offlineShieldMultiplier` (both since 2026-10-23) |
| `data-otservbr-global/lib/core/quests/catalog/010_in_service_of_yalahar.lua` | Quest log: "The Way to Yalahar" (Wyrdin and Timothy's research notes) and "Searoutes Around Yalahar" (special goods for Karith, 0-5 delivered) added as the first missions; the quest line now shows from that errand on (upstream only from Palimuth's first mission) |
| `data-otservbr-global/lib/core/quests/catalog/init.lua`, `data-otservbr-global/lib/core/storages.lua` | Quest log entry Measuring Tibia (`052_measuring_tibia.lua`, ours) and its storages 46280-46282 (map discovery); quest log entry Venore Daily Tasks (`054_venore_daily_tasks.lua`, ours) |
| `data-otservbr-global/npc/charos.lua` | As in Tibia since Measuring Tibia: no travel greeting, talks about `discovering`, gives the Discoverer outfit and addons (`outfit`, `yes`, `ten`/`fifteen`/`twenty`); the old city attunement still works with `attune` (limit 7); explains `Start Discovering` and the pink vortex |
| `data-otservbr-global/npc/oressa.lua` | Upstream bug fixed (2026-10-17): saying `knight` got no answer (the monk answer had been merged into the knight branch), so knight could only be chosen through `choose`, `close` |
| `data-otservbr-global/world/otservbr-npc.xml` | Spawns the seven Way of the Monk NPCs (Manop, Pema, Rudra, Rahng, Dajcho, Saih, Chesa) at their Tibia positions, and Lorenzo in the Tibiadrome lobby (32264,32204,11) |
| `data-otservbr-global/npc/ambassador_manop.lua` | Upstream bug fixed (as upstream #4063): the pilgrimage counter was written to a key that does not exist, so no Blue Valley shrine could be used; it is no longer reset when talking to him again. 2026-10-22: no silent answers (monk, purpose, legacy, role, yes when started, non-monks, no shrine, no); no second set of starting gear |
| `data-otservbr-global/npc/enpa-deia_pema.lua` | `heal` / `healing` heals as at the temples; `pilgrimage` starts the pilgrimage for anyone, names the shrine visited last and where the next one is (and its level), and closes the quest after the tenth; fixed upstream's Lua error on `pilgrimage` and its count, one shrine ahead |
| `data-otservbr-global/npc/enpa_rudra.lua` | `pilgrimage`: the right shrine count and where the next shrine is |
| `data-otservbr-global/npc/dahr-enpa_rahng.lua` | Named Dhar-Enpa Rahng, as in Tibia (was Dahr-Enpa) |
| `data-otservbr-global/scripts/quests/the_way_of_the_monk/shrines.lua` | Empathy and Power shrines on their real floors (13 and 15; as upstream #4063), a location hint for each shrine, the last shrine closes the quest log and gives Hope of the Merudri |
| `data-otservbr-global/npc/hireling.lua` | The trader hireling sells and buys pair of monk fists, nunchaku and sais, as the weapon dealers |
| `data-otservbr-global/npc/maeryn.lua`, `data-otservbr-global/scripts/actions/object/moonlight_crystals.lua` | The werewolf helmet can be enchanted for monks (fist fighting), as in Tibia |
| `data/scripts/talkactions/player/leave_house.lua`, `sell_house.lua` | Registered while Cyclopedia auctions are on |
| `data/scripts/actions/items/dolls.lua` | Using a golden newspaper that is a daily newspaper opens the edition (other golden newspapers keep their doll sounds) |
| `data-otservbr-global/scripts/world_changes/their_masters_voice.lua` | Sets `FamilyTheirMastersVoiceActive` when the world change triggers, for the newspaper |
| `data/scripts/talkactions/god/save.lua` | `/save` available to every character (group normal) |
| `data/modules/modules.xml` | Adds the Cyclopedia house packet module (byte 173) for instant purchases, the Cyclopedia map action module (byte 219, map discovery) and the logout module (byte 20) for logging out during a fight; the spell list module (bytes 98 and 231, wheel of destiny save and gem action; nothing is read, the server still handles them); the Hunting Task module (byte 186) for the x10 points |
| `data-otservbr-global/lib/quests/killing_in_the_name_of.lua` | Task level ranges ignored when `Family.noTaskLevelCap` is set |
| `data-otservbr-global/npc/grizzly_adams.lua` | No level ranges: full task list, no points cap, promotions, all bosses and special tasks at any level (same switch) |
| `data/scripts/spells/familiar/*.lua` (5 files) | Spell mana read through `FamilyFamiliarSpellMana` (0 with permanent familiars; the cost is charged by `familiar.lua`) |
| `data/scripts/eventcallbacks/player/on_look.lua` | Looking at a permanent familiar says it stays until dismissed (instead of a time left) |
| `data-otservbr-global/npc/daniel_steelsoul.lua` | Task dialogue replaced by the Edron City Tasks (choice, several at once, no level limits, `cancel`); the Spider Cult mission is unchanged |
| `data-otservbr-global/lib/core/quests/catalog/011_killing_in_the_name_of.lua`, `init.lua` | Edron City missions 84-87 moved to the new quest "Edron City Tasks" (`053_edron_city_tasks.lua`, ours) |
| `data-otservbr-global/world/otservbr-monster.xml` | Three Troll Sabotage spawns (Werebadger 33236,31768,3 and 33217,31767,4; Werefox 33237,31775,4) removed, now night-only via `scripts/family/night_spawns.lua` |
| `data-otservbr-global/world/otservbr-monster.xml` | A Braindeath spawn added in the coffin room of The Undeath Stare (32544,31520,11; Braindeath Quest, 2026-10-21) |
| `data-otservbr-global/scripts/actions/adventurers_guild/adventurers_stone.lua` | Usable anywhere except during a fight, on no-logout tiles and in boss/encounter zones (`Family.adventurerStoneAnywhere`) |
| `data-otservbr-global/scripts/movements/teleport/adventurers_guild.lua` | Exit portal always to the home temple (`Family.adventurerGuildExitHome`) |
| `data-otservbr-global/npc/guide_*.lua` (13), `norf.lua`, `humphrey.lua`, `edala.lua`, `pydar.lua`, `eremo.lua` | One line each: `FamilyPilgrimage.addGuide` / `addPriest` (Pilgrimage of Ashes keywords) |
| `data-otservbr-global/lib/others/load.lua` | Loads `family_pilgrimage.lua` and `family_venore_tasks.lua` (ours) |
| `data-otservbr-global/npc/cranky_lizard_crone.lua` | Addon trade replaced by the quest dialogue (mission, pages, then hat/cape) |
| `data-otservbr-global/lib/core/quests/catalog/031_tibia_tales.lua` | Missions 17 "The Spirit Will Get You" and 18 "Pilgrimage of Ashes" (ours) |
| `data-otservbr-global/npc/muriel.lua` | Festive addon dialogue rewritten (addons, yes, mask/feather; the trade is in `scripts/family/festive_outfits.lua`); the Bone Pit mission and spells are unchanged |
| `data-otservbr-global/npc/sinatuki.lua` | Fish exchange rewritten (any mix of the two fish, 100 in total, 5 shards and Jamjam once) and her Chakoya lines added |
| `data-otservbr-global/lib/core/storages.lua` | `Storage.Quest.FamilyEdronTasks`, `FamilySinatuki`, `FamilyWaterskinOfMead`, `FamilySpiritWillGetYou`, `FamilyPilgrimageOfAshes` and `FamilyVenoreTasks` (48722-48729), storages 48600-48799 |
| `data/scripts/lib/register_achievements.lua` | Achievement 9001 "Champion of Edron" (secret, because the client shows names from the server only for secret achievements) |
| `data/XML/mounts.xml` | Mount names carry their terrains, e.g. "Water Buffalo (Swamp/Water)" (written by `tools/family/mount_terrain/annotate.py`; `--strip` restores the names) |
| `data/scripts/lib/register_achievements.lua` (2026-10-20) | Soul Mender secret and "Heartbreaker!" as in Tibia (audit in `tools/family/achievements/report.md`) |
| `data-otservbr-global/scripts/quests/hero_of_rathleton/actions_reward.lua` | Gives "The Professor's Nut" (upstream asked for "The Professors Nut", which does not exist); earlier openers get it at login (`data/scripts/family/achievement_fixes.lua`) |
| `data/scripts/systems/custom_monster_loot.lua` | Upstream example loot disabled: every monster dropped 1-10 christmas tokens all year and dragons platinum coins. Tokens now drop in December only (winter event) |
| `data/scripts/actions/items/potions.lua`, `data/items/items.xml` (item 238), `data-otservbr-global/monster/quests/{feaster_of_souls/the_dread_maiden,adventures_of_galthen/megasylvan_yselda,a_pirates_tail_quest/tentuglys_head,a_pirates_tail_quest/ratmiral_blackwhiskers}.lua` | Great mana potion for every vocation (Tibia 15.25); boss loot transcendence potion 51302 -> 49271 (2026-10-22) |
| `data/items/items.xml` (items 50242-50245) | Monk shrines named "ancient shrine" (were nameless) (2026-10-22) |

If a Canary update conflicts in `raids.xml` or `otservbr-monster.xml`, take the upstream file and
apply the same caps again (margin above 30 becomes 30; spawntime above 3600 becomes 3600).

All exclusive-quest edits read `Family.unlockExclusiveQuests` (in `solo_quests.lua`); set it to
`false` to bring back the upstream "pick one" rules without touching the other files.

Not changed (yet): In Service of Yalahar (Palimuth or Azerus side), Paradox Tower reward,
Heart of Destruction final lever (needs 3 players).

Quests still to check when reached (party mechanics beyond the entry lever): Ferumbras' Ascension,
Heart of Destruction, Cults of Tibia, Oramond (Glooth Fairy), Dark Trails, The Order of the Lion,
The Dream Courts, Forgotten Knowledge, Grave Danger.

## City life (walking NPCs)

Added 2026-10-13 to make the world feel inhabited. About 190 NPCs that look like
players walk around 11 port cities, chat, give quest tips, and sometimes sail to
another city. Twelve of them are vendors.

| What | Details |
|---|---|
| Cities | Thais, Carlin, Venore, Ab'Dendriel, Edron, Darashia, Ankrahmun, Port Hope, Liberty Bay, Svargrond, Yalahar |
| Walkers | 16 per city (176), unique names, random player outfits and colours |
| Where they walk | Street level (floor 7) only. Never inside houses, never on stairs, holes or teleports. They pause at open spots, never in doorways |
| Travel | About 8% of trips end at the harbour: the NPC vanishes and appears at another city's harbour 2–5 minutes later. Venore has no ship stop (its harbour is 43 sqm from the nearest street they can reach) |
| Talking | Say `hi`, then `tip` (or `quest`), `news`, `job`, `name`, `bye`. They stand still while you talk |
| Random lines | Every 45–150 s, only when a player is within sight |
| Vendors | 6 food sellers and 6 potion and rune sellers (`vendorsPerKind`, raised from 2 on 2026-10-13). The 6 creature products traders were turned into plain walkers with tips and news on 2026-10-18 (`extraWalkers`): creature products are on the market now. Each sits near the center of a random city for the day; cities are filled evenly, so every city has 1 or 2 vendors and never two of the same kind. Ask any walker for `news`: one line lists the vendors in that city, another names a vendor elsewhere |
| Stock | New random stock each server start: 14 foods; all potions plus 16 runes |
| Prices | Food, potions and runes: the cheapest price any NPC in this datapack asks. Vendors only sell; they don't buy |
| Status | GOD command `/citylife`: NPCs per city, how many are at sea, where the vendors are |

### Quest tips

`tip` gives a quest that fits your level and that you haven't started yet (the
three closest to your level are picked from), or now and then a server tip
(training, death rules, bosses...). Locations come from the NPC positions in
`world/otservbr-npc.xml` (direction from the city temple) and the keywords from
the NPC scripts. Current tips:

| From level | Quest | Who / where | Say |
|---|---|---|---|
| 8 | What a Foolish Quest | Bozo, Thais castle (north-west of the temple) | `join` |
| 15 | The Postman Missions | Kevin, mountains south-west of Kazordoon, 1 floor up | `mission` |
| 15 | The Thieves Guild | Dorian, basement north-west of the Thais temple | `join`, `mission` |
| 20 | The Explorer Society | Angus, east of Port Hope | `join` |
| 20 | Djinn factions | Melchior, desert north-west of Ankrahmun | `word of greeting` |
| 20 | Barbarian Test | Sven, south-west of the Svargrond temple | `barbarian` |
| 25 | Killing in the Name of (tasks) | Grizzly Adams, east of Port Hope, 1 floor up | `join`, `task` |
| 30 | The Ice Islands | Iskan, north-east of Svargrond (after the Barbarian Test) | `mission` |
| 30 | Svargrond Arena | Halvar, north-east of the Svargrond temple | `arena` |
| 35 | To Appease the Mighty | Kazzan, palace north of the Darashia temple | `mission` |
| 40 | The Secret Service | Chester Kahs (Thais), Emma (Carlin), Uncle (Venore) | `join` |
| 40 | The Shattered Isles | Eleonore, north of the Liberty Bay temple, 2 floors up | `mission` |
| 50 | The Ape City | Hairycles, far north-east of Port Hope | `mission` |
| 50 | Hot Cuisine | Jean Pierre, south-west of Darashia, 1 floor up | `cook`, `apprentice` |
| 60 | Sea of Light | Spectulus, top of the Edron academy | `mission` |
| 60 | The Paradox Tower | Oldrak, tower south-west of Venore | `hugo`, `myth` |
| 100 | The Annihilator | Deep under the north of Edron | (lever) |
| 100 | The Inquisition | Henricus, basement south-west of the Thais temple | `mission` |
| 120 | The Demon Oak | Oldrak | `demon oak` |
| 250 | Soul War | Flickering Soul, deep underground south-east of Gray Beach | `task` |

To add a tip, copy one entry in `FamilyCityLife.tips` and set `minLevel`, `text`
and `started` (the quest's start storage, so the tip disappears once you begin it).

### Files and tuning

| File | Contents |
|---|---|
| `data-otservbr-global/scripts/lib/family_city_life_data.lua` | All settings and texts: on/off switch, walkers per city, travel chance and times, cities, names, outfits, chat lines, quest tips, vendor kinds and stock lists with prices |
| `data-otservbr-global/scripts/family/city_life.lua` | The engine: street-area search, walking (A* inside the street area), travel, conversation, vendor shops, `/citylife` |

Useful knobs in the data file: `enabled`, `walkersPerCity`, `vendorsPerKind`, `extraWalkers`,
`travelChance`, `travelMinutes`, `idleSeconds`, `chatterSeconds`, each city's
`radius`, and each vendor kind's `randomCount`. Restart the server after a change.
The server log lists, for every city, the street tiles found and whether ships
work there, and where each vendor is that day.

Known limits: they are NPCs (no fighting, trading items between players, parties,
or VIP list). In a crowded narrow street they may briefly stand in your way; they
step aside by picking another spot after a few seconds.

## Houses

Added 2026-10-13. Houses and guildhalls are paid once and kept forever.

| What | Details |
|---|---|
| Buy in Cyclopedia | Cyclopedia > Houses > town > house > Bid: the house is yours at once and the price is taken from the bank (any bid amount works; only the price is charged). How: a Lua module (`data\modules\scripts\family\cyclopedia_houses.lua`, in `data\modules\modules.xml`) sees the bid packet before the server, buys the house (`data\scripts\family\house_instant_buy.lua`) and turns the packet into a town-list request, so the list refreshes instead of an auction starting. Not enough money, a house with an owner or no vocation: the normal server answer. With `FAMILY_INSTANT_CYCLOPEDIA_HOUSES = false` the upstream auction comes back (ends at the server save, `daysToCloseBid = 0`, handed over at the next server start) |
| Buy at once | Face the house door and say `!buyhouse`; same price as Cyclopedia |
| Price | The house's rent from the map x `houseRentRate` 0.65, once: 16k to 520k for houses (median about 65k, about 2,000 gold per sqm), 162k to 3.25M for guildhalls (median 325k) |
| Rules | No rent (`houseRentPeriod = "never"`), never lost for inactivity, no level, no limit on houses per character, guildhalls without a guild (the server only blocks guild members who are not leaders; not checked in the client) |
| Commands | `!house` (guide), `!buyhouse`, `!leavehouse` (free at the next server start, no refund), `!sellhouse Name` (trade window; refused if that player already owns a house, engine rule) |
| House spells | `aleta sio` guests, `aleta som` subowners, `aleta grav` door list, `alana sio "Name` kick |
| Files | Settings in `family\config.family.lua` (Houses block); switches `FAMILY_HOUSE_COMMANDS`, `FAMILY_UNLIMITED_HOUSES` and `FAMILY_INSTANT_CYCLOPEDIA_HOUSES` in `data\scripts\lib\family_houses.lua`; instant purchase in `data\scripts\family\house_instant_buy.lua`; guide in `data\scripts\family\house_help.lua` |

## Newspaper

Added 2026-10-14. One "<City> Newspaper Seller" walks near the temple of each city in
`FamilyCityLife.cities` (the same 11 cities as the Coin Brokers).

| What | Details |
|---|---|
| Buy | `hi`, `newspaper`, `yes`: 1 gold coin (backpack first, then bank). Needs room in the backpack |
| Item | A golden newspaper renamed "newspaper", 1 oz; look shows the edition's date; use it to read |
| Edition | Written when bought and never changes. A new day starts at 06:00 (server save); an older paper shows its own date at the top. (Until 2026-10-15 an older paper also got an "OLD EDITION" notice, which piled up with every read; reading removes it.) |
| Contents | Boosted creature and boss; Rashid's city (from where the Rashid NPC stands), Yasir's city, travelling vendor cities; world changes (Fury Gate city, Nightmare Isle, Grimvale full moon on the 13th, Their Master's Voice); Lua raids seen today (time, still roaming) or possible today; regions of classic XML raids; active event rates; server notes |
| Settings | `FamilyNewspaper` at the top of `data-otservbr-global\scripts\family\newspaper.lua`: `title`, `price`, `itemId`, `weight`, `dayStartHour`, `enabled`. Raid display names: `raidNames` in the same file |

## Coin Brokers

Added 2026-10-13. Tibia Coins are earned with gold instead of being free.

| What | Details |
|---|---|
| Where | One NPC near the temple of each city in the city life list (Thais, Carlin, Venore, Ab'Dendriel, Edron, Darashia, Ankrahmun, Port Hope, Liberty Bay, Svargrond, Yalahar), named "<City> Coin Broker" |
| Talk | `hi`, `trade`: a trade window lists "Tibia coins"; pick any amount and Buy. Or `hi`, `coins`, an amount (any number from 1 to 10,000), `yes` |
| Trade window | The coins go to the Store balance; no item is given. The client still wants one free backpack slot (or "Ignore capacity" ticked) before it allows the purchase |
| Price | 5,000 gold per coin, taken from the backpack first, then the bank. Brokers never buy coins back |
| Coins | Transferable coins: they pay for every Store offer and can be sent to the other player |
| Reset | At the first start with this feature, every account's coins were set to 0, once (marked in the `server_config` table as `family_coin-reset-2026-10-13`) |
| Settings | `FamilyCoinBroker` at the top of `data-otservbr-global\scripts\family\coin_broker.lua`: `goldPerCoin`, `maxPerPurchase`, `startCoins`, `enabled` |

## Backups

```powershell
powershell -ExecutionPolicy Bypass -File family\backup-db.ps1
```

Always back up before updating; database migrations only move forward.
The database holds everything players own (accounts, characters, items, depots,
houses and their furniture, bank, quests); the rest is in Git, so a backup file
plus this repository rebuild the whole server. Keep copies off this PC (set
`BACKUP_DIR` in `family\local.env` to a cloud-synced folder, or copy the files).

To restore (server stopped):

```powershell
powershell -ExecutionPolicy Bypass -File family\restore-db.ps1
```

It lists the newest backups and asks which one (or pass `-File <path>`), asks you
to type `RESTORE`, backs up the current database first if it holds accounts, then
restores. After reinstalling Windows: install the programs, clone the repository,
recreate `family\local.env`, run `family\setup.ps1`, then `restore-db.ps1`
(full steps in the manual).

## Upstream fixes copied since v3.6.1

Canary's `main` keeps moving after a release. Our `canary.exe` is the v3.6.1
release, so only data fixes (Lua, XML, NPCs) that work with it are copied, one
by one with `git cherry-pick -x` (the commit message names the upstream
commit). Checked on 2026-10-19: of the 95 upstream commits after v3.6.1,
about half change C++ (they need a newer `canary.exe`) and most others are CI,
Docker or documentation. Copied (35):

- Daily reward: reward wall fix #4146 (see Daily reward above).
- Quests: Mortimer's pick and Explorer Society storages (#4047), Barbarian Test
  (#4025), Storkus (#4053), Inquisition holy water rollback (#4083) and Henricus
  (#4084), Cults of Tibia Barkless (#4074) and Gerimor (#4075), Sister of Jack
  (#4107), quest storages that did not exist (#4064), Rookie Guard energy
  barrier (#4110).
- NPCs: djinns accept a normal greeting once they know you (#4044), Zoltan's
  addon for male summoners (#4060), Brengus buys the tribal mask (#4061),
  Augustin's sales (#4062), Simon the Beggar's shovel price (#4066), spells sold
  under names that exist, familiar spells included (#4046, #4065), Cipfried and
  Dallheim cure burning (#4096, with the shared heal keyword #4099), missing
  dialogue of 28 Carlin and about 70 Thais NPCs (#4077, #4082, #4094, #4100).
- Other: `!autoloot all` (#4067), Prey Wildcard Store offers (#4045, #4095),
  death screenshot type (#4106), level-up saves debounced (#4119), guild war
  query handle (#4111), safe table unserialize (#4101), NPC say error (#4105),
  antiPush cleanup (#4103), monk's apparition race id (#4147), invalid item
  ranges in items.xml (from #4034).

Not copied on purpose: #4136 (a character that never claimed a daily reward
would lose the default streak bonuses it has now), #4116 (interval save, which
we keep off), #4063 (Way of the Monk, already in our own fix).
Adjusted after copying: Charos keeps our `discovering` answer (#4100 gave him
static `discovering`, `map` and `service` answers, which the NPC system answers
before our dialogue).

Release tags are single snapshot commits without history, so for the next
release compare the new tag with v3.6.1 (`git diff v3.6.1 vX.Y.Z`) instead of
expecting `git merge` to know what we already copied.

## Self-tests (Linux workspace)

Changes are tested on a Linux copy of the server before they are committed:
`tools/family/selftest.sh <test.lua> [timeout]` writes a temporary `config.lua`,
copies the test to `data/scripts/zz_selftest.lua`, starts the server, waits for
`[Selftest] DONE`, stops it, prints the results and deletes both files again.
It needs `CANARY_BIN` (the Linux build of the pinned v3.6.1) and MariaDB; the
test database is created on first use. Start from
`tools/family/selftest_template.lua`. Not used on the Windows server PC.

## Updating to a new Canary release

```powershell
powershell -ExecutionPolicy Bypass -File family\backup-db.ps1
git fetch upstream --tags
git checkout -b update-vX.Y.Z family
git merge vX.Y.Z
```

Then, on the update branch:

1. Update the pinned URLs and SHA256 values at the top of `family\lib.ps1`
   (and the map URL line, if `config.lua.dist` changed it).
2. Run `family\setup.ps1`. It notices the new versions and downloads them.
3. Start the server and run the smoke test with the GOD account: log in, walk, fight
   a monster, loot, use a depot, log out and back in, and confirm the character was saved.
4. Only then merge `update-vX.Y.Z` into `family`, and install the matching client on both PCs.
5. Workarounds to remove when the release contains the upstream fix:
   - Hit sound (2026-10-22): if `WeaponProficiency::applyOn` in
     `src/creatures/players/components/weapon_proficiency.cpp` skips a gain of 0 and no
     longer sets `SPELL_LIGHT_HEALING`, the server no longer plays the Light Healing sound
     on every hit. A new client replaces the sound file anyway; if the old client stays,
     run `family\client-mute-hit-sound.ps1 -Undo` on both PCs so exura has its sound
     again. If the release still has the bug, run the script (without `-Undo`) on both
     PCs after installing the new client.

The `upstream` remote is added once with:
`git remote add upstream https://github.com/opentibiabr/canary.git`

## Docker alternative (not used on the family PC)

`docker/.env.family` keeps a pinned Docker configuration (Canary 3.6.1,
login-server v1.1.3, MyAAC website). Docker on Windows needs WSL 2 and the
Windows hypervisor, so it is only for moving the server to a Linux machine or a
VPS later. Usage: copy it to `docker/.env`, fill the `CHANGE_ME` values, and run
`docker/up.sh` (or `up.ps1`).
