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
| Boss cooldown | None (since 2026-10-17; 1 hour before, upstream 20 h): every boss can be fought again right away, also those whose lever, portal or quest sets its own wait (Grimvale, Feaster of Souls, Prince Drazzak, Grave Danger, Forgotten Knowledge, Dream Courts, Brokul, First Dragon, Dangerous Depths warzones). An occupied boss room still stays closed until the fight is over | `family\config.family.lua` (`bossDefaultTimeToFightAgain = 0`), `solo_balance.lua`, `data-otservbr-global\scripts\family\boss_cooldown.lua` (`Family.noBossCooldown`) |
| Boss levers | One player is always enough (all 66 standard levers, Soul War included) | `solo_balance.lua` |
| Tibia Coins | Not free (since 2026-10-13): a Coin Broker near the temple of each port city sells transferable Tibia Coins for 5,000 gold each (buy only). All balances were reset to 0 once | `data-otservbr-global\scripts\family\coin_broker.lua` |
| Conveniences | Auto-loot, free third Prey and Hunting Task slots. The config only applies to slots created at a character's first login, so at every start `data\scripts\family\prey_slots.lua` also opens third slots saved as locked (Prey: empty slot, Hunting Tasks: empty list, both with a free reroll) | `family\config.family.lua`, `prey_slots.lua` |
| Death | No experience, skill or item loss: you only wake up in the temple. Everyone always has full blessings | `family\config.family.lua`, `solo_balance.lua` |
| Training | Exercise weapons never run out (one from the Store costs 25 coins; NPCs also sell them for gold); exercise and offline training 2x faster | both files |
| Respawn | 2x faster (classic hunts: 90 s to 45 s) | `family\config.family.lua` |
| Rare creatures | Rare raid creatures and bosses (Midnight Panther, Draptor, Undead Cavebear, Yeti, The Old Widow, Tyrn..., plus the Thais rat plague) take turns: one starts at a time, at least 15 min after the previous one (`Family.rareRaidGapMinutes`; since 2026-10-17 each is announced 60 min before it starts, for the map discovery raid warnings), picked at random among the raids that are ready (one player online, 30 min since that raid's last run, its previous creatures dead). Classic raids: at most 30 min between raids. Rare map spawns: at most 30 min | `data\scripts\family\rare_creatures.lua` and the files below |
| Party quests | One player can do the quests in the table below | the files listed there |
| Exclusive quests | Both Djinn factions; all three Secret Service agencies, one after another; every chest of a "choose one reward" room | `data\scripts\family\solo_quests.lua` |
| City life | About 190 walking NPCs in 11 cities with quest tips, ship travel and 18 vendors (see "City life" below) | `data-otservbr-global\scripts\family\city_life.lua` |
| Houses | Bought at once in Cyclopedia > Houses > Bid, or with `!buyhouse` at the door. Price = the house's rent x 0.65, paid once; no rent, never lost, no level, no limit; guildhalls without a guild. `!house` in game shows a guide (see "Houses" below) | `family\config.family.lua`, `data\scripts\lib\family_houses.lua` |
| Saving | The whole server saves every 15 minutes (`data\scripts\family\auto_save.lua`; the map is not cleaned, so items on the ground stay). Any character can type `/save` (or `/save 5` for 5 minutes from now). Upstream's interval save never ran with `globalServerSaveTime = "06:00:00"` (it expects HH:MM), so `toggleSaveInterval = false` | `family\config.family.lua`, `auto_save.lua` |
| Newspaper | A newspaper seller near the temple of each of the 11 city-life cities sells today's *Gaia Times* for 1 gp (`hi`, `newspaper`, `yes`). Using it shows boosted creature and boss, Rashid, Yasir and vendor cities, world changes, rare creatures seen or possible today, raid regions, events and server notes, with the edition's date at the top. New edition at 06:00 (see "Newspaper" below) | `data-otservbr-global\scripts\family\newspaper.lua` |
| Daily reward | The streak never expires: missing days costs no joker tokens and keeps the streak bonuses. A new reward day starts at 06:00 even if the server was off then (upstream, the day only advanced while the server ran at 06:00). After a claim the Reward Wall shows a countdown instead of upstream's "expired" / "You did not claim your daily reward in time", and a message says the items are in the Store inbox | `data\scripts\family\daily_reward.lua` (`Family.dailyRewardNeverExpires`, `Family.dailyRewardWallCountdown`) |
| Rookgaard | Mainland characters can visit (since 2026-10-15): Captain Bluebear in Thais sails there for 100 gp (`hi`, `rookgaard`, `yes`, arriving at the Rookgaard temple). The Oracle, above the Rookgaard academy, sends a character with a vocation back to its home town's temple for free (`hi`, `yes`; Thais if the home town is a beginner island). Characters without a vocation still choose town and vocation as upstream. Rookgaard quests such as the Present Box (Legion Helmet from Seymour) and Dragon Corpse work once per character | `data-otservbr-global\scripts\family\rookgaard_travel.lua` (`Family.rookgaardTravel`) |
| Winter event | December only (since 2026-10-15): monsters drop christmas tokens (1.5% x rateLoot = 4.5% per kill; Ruprecht on Vega trades them all year, reached with Nielson north of Carlin: `hi`, `vega`, `yes`); Santa Claus in the Thais temple gives one present per character per year (`hi`, `present`); Grynch Clan goblins raid a random big city at most every 90 min (harmless, drop christmas present bags); Captain Breezelda in Svargrond sails to Percht Island (`hi`, `percht`, `yes`, 100 gp), where Frosty trades the three Percht sleigh mounts for 10 percht horns + 10 broken bells each and sails back to Svargrond all year. The Percht Queen fight is not implemented. The newspaper lists the event | `data-otservbr-global\scripts\family\winter_event.lua` (`FamilyWinter`) |
| Temple healing | Since 2026-10-16: temple NPCs who offer to `heal` (28 of them, e.g. Isimov, Quentin, Pydar) restore full health and mana and cure poison, burning and other damage conditions whenever something is missing (upstream: only below 40 HP, up to 40). No NPC file changed; the healers are recognised by their upstream answer | `data\scripts\family\temple_healing.lua` (`Family.templeFullHeal`, `Family.templeRestoreMana`) |
| Offline training | Since 2026-10-17: logging out on a training statue trains for the whole time away, up to 365 days (upstream 21; `Family.offlineTrainingMaxDays`), also while the server is off (measured from logout to the next login; upstream at most 12 hours). The offline training time (12:00 in the client) is never used up: it is full after every login. No 10-minute minimum: every full minute away counts. The skill stages apply as for normal training, times 2 from `rateOfflineTrainingSpeed`. House beds (premium; headboard + footboard from Ukea near Ab'Dendriel, 40 gp each, or Store beds) open the same skill choice and train the same way; waking up in a bed restores full health, mana and soul (upstream: only while food regeneration lasts, and 1 soul per 15 minutes) | `data\scripts\family\offline_training.lua` (`Family.offlineTrainingUnlimited`, `Family.bedFullRest`) |
| Melee skills | Since 2026-10-17: sword, axe and club fighting are one shared skill: when one goes up (hunting, exercise weapons, statues, offline training), the other two are raised to the same level and progress; the highest always wins, nothing is lowered. Fist, distance, shielding and magic level stay separate | `data\scripts\family\melee_skills.lua` (`Family.sharedMeleeSkills`) |
| Party | Since 2026-10-17: shared experience (switched on in the party menu) works at any level difference, at any distance and without the 2-minute activity rule. The level rule is a config value; when the server still refuses sharing for distance or inactivity, a script shares each kill the same way (party bonus, divided by party size, each member's own bonuses). The party icons may still show members as far away or inactive | `family\config.family.lua` (`partyShareRangeMultiplier = 10000`; upstream 1.5), `data\scripts\family\party_share.lua` (`Family.partyShareAnywhere`) |
| Corpses | Since 2026-10-17: monster corpses can be moved right away (upstream they are locked to the floor for their first 10 seconds). The corpse turns into its next, movable look as soon as the loot is in it: same loot, same rotting time (10 s shorter), loot message and auto-loot as before, and for the first 10 seconds only the killer and his party can open it. Boss reward corpses and quest corpses are not changed. Rotworm, spider, dog, rabbit and bear corpses keep the 10-second lock (their movable look is not a corpse for the client: it would lose the loot sparkle, auto-loot and quick loot; fixed 2026-10-17) | `data\scripts\family\movable_corpses.lua` (`Family.movableFreshCorpses`) |
| Map discovery | Since 2026-10-17: Cyclopedia > Map works as in Tibia. Select a subarea in the Cyclopedia map and press "Start Discovering" to place its 10 points of interest; one subarea at a time (starting another drops the points of the previous one; "Reset points of interest" places new ones). Each point shows as Tibia's pink vortex (seen only by you) and on the map when you come near it, and is found when you walk next to it (treasure map effect); find 7 and the subarea is discovered for good (pink beam). Points are the real Tibia spots players mapped (TibiaMaps.io), above and below ground, wherever our map can reach them, topped up with generated spots; a subarea covers every floor under its shape (189 can be selected). An area's % is its discovered subareas: NPCs show on the map at 30%, passages at 70%. At 100%: the area's achievement (e.g. "Elven Woods"), its creatures on the map (silhouettes for creatures not yet in your Bestiary), raid warnings there (rare raids are announced 60 minutes ahead, then marked on the map while they last) and extra speed inside it (100 for one fully discovered area, +5 per further area, up to 195). Measuring Tibia quest log ("A Speck of Land" shows the progress of the subarea you are in). Charos (Adventurers' Guild: `hi`, `discovering`, `outfit`, `yes`, `ten`/`fifteen`/`twenty`) gives the Discoverer outfit for 10 fully discovered areas ("Go and find Charos" message when you reach 10, 15 and 20), its addons for 15 and 20; his old city attunement still works with `attune`. Titles Dedicated Entrepreneur (10) and Globetrotter (20). The Improved Respawn Rate donation is not implemented | `data\scripts\family\map_discovery.lua` (`FamilyDiscovery.enabled`, `automatic` (off), `oneAtATime`, `vortex`, `revealAll`, `pointsNeeded`, `speedBonus`, `raidWarnings`, `raidWarningMinutes`), data in `data\scripts\lib\family_map_discovery_data.lua` (rebuilt with `tools\family\map_discovery\`), raid announcements in `rare_creatures.lua` |
| Adventurer's stone | Since 2026-10-17: every temple NPC (Quentin, Alia, Isimov, Rahkem, Kasmir and 15 more) understands `hi`, `adventurer's stone`, `yes` (upstream only `adventurer stone`). The first stone of each day is free from any of them, further ones cost 30 gold (upstream: free once per NPC, ever). The day starts at the server save (06:00). An NPC still says "Keep your adventurer's stone well" while you carry one; no NPC file changed | `data\scripts\family\adventurer_stone.lua` (`Family.dailyFreeAdventurerStone`) |
| The Way of the Monk | Since 2026-10-17 the monk quest can be played from start to end. The Blue Valley NPCs stand on the map (upstream had their scripts but did not place them): Enpa-Deia Pema (healing, monk shop, `pilgrimage`), Enpa Rudra (spells, promotion), Dhar-Enpa Rahng, Dajcho the Monk, the gate guardians Saih and Chesa, and Ambassador Manop in Dawnport. Ways in: Manop (monks leaving Dawnport, `invitation`, `yes`, `seeker`, `yes`), the crystal sphere east of Thais and the one in the Adventurers' Guild next to the daily reward shrine (put there at startup; our map had none); the spheres near Pema bring you back where you came from. Any vocation can do the pilgrimage: say `pilgrimage` to Pema to start it, and again to hear what you have done and where the next shrine is. The 10 shrines are used in order, each from a level (6 to 275); monks get the Enlightenment items, Mystic Repulse, Forceful Uppercut and Focus Harmony, +5% fist damage at 5 of them, and (ours, as in Tibia) 2% less damage from melee attacks per shrine (20% with all ten); other vocations get the experience. The last shrine (Eternity) closes the quest log and gives the achievement Hope of the Merudri; monks also get +10 Wheel of Destiny points. Not possible with our server binary: the title Pensive Wanderer and the Wheel points for other vocations | `data\scripts\family\monk_pilgrimage.lua` (`Family.monkGuildSphere`, `Family.monkShrineMeleeProtection`), shrines in `data-otservbr-global\scripts\quests\the_way_of_the_monk\shrines.lua` |
| Monk equipment | Since 2026-10-17 the monk items Canary had but nothing gave are found as in Tibia (TibiaWiki): monk robe from tarantulas, bambus jo from Ratmiral Blackwhiskers, naga katar from Timira the Many-Headed, iks footwraps from the Mitmah Vanguard, gnomish footwraps from the three Dangerous Depth bosses (each as often as an item of the same rarity of that creature); the 20 weapon dealers (Sam, Hardek, Romella, Uzgod, Esrik...) and the trader hireling sell and buy pair of monk fists (270/90 gp), nunchaku (405/135) and sais (540/180); Cledwyn sells the leaf, energy and ice robes (100 silver tokens each, like the magma robe); Bakragore's bag you covet can hold grand sanguine claws; the Inquisition reward room has a tenth chest (east corner) with the merudri nanbando; the chest next to the Wrath of the Emperor reward stands holds the merudri scale mail; Maeryn (Grimvale) enchants the werewolf helmet for monks (`werewolf helmet`, `yes`, `monk`, then moonlight crystals). Still not obtainable (what gives them is not in our server): spirit bind (monk Spirit Sphere), norcferatu bonehood and fleshguards (Vladrukh), the rending, draining and siphoning inferniarch claws (Doomforging), genesis serenity armor and legs | `data\scripts\family\monk_gear.lua` (`Family.monkGear`) |
| Soul War reward | The final chest gives another random Soul item after each new Megalomania kill, or once every 20 h | `solo_quests.lua` |
| Stamina | Never goes down (since 2026-10-15): put back to 42:00 at login and about once a second, so the green +50% experience bonus is always on and orange/red stamina never happens. The stamina system stays on, so Prey and Hunting Task bonuses still count down while hunting | `data\scripts\family\stamina.lua` (`Family.staminaNeverDecreases`) |
| Logout in a fight | Logging out works while the battle icon is shown (since 2026-10-15): the logout request clears the in-fight state just before the server handles it. No-logout tiles (some quest and arena rooms) still refuse. Closing the client without logging out still leaves the character in game until the icon ends, as in Tibia | `data\scripts\family\logout_in_fight.lua` (`Family.logoutDuringFight`), module `data\modules\scripts\family\logout_in_fight.lua` |
| Coins | Looted gold goes to the backpack (`autoBank = false` since 2026-10-14; NPC sales also pay coins). Coins change up by themselves: 100 gold coins carried become 1 platinum coin, 100 platinum coins 1 crystal coin (checked about once a second, depot and house untouched; a full backpack never loses coins). Cyclopedia house purchases still take the bank balance: deposit at a bank NPC first (`hi`, `deposit all`, `yes`) | `data\scripts\family\coin_change.lua` (`Family.autoCoinChange`), `family\config.family.lua` |
| Familiars | Permanent (since 2026-10-14): the familiar spell (knight `utevo gran res eq`, paladin `utevo gran res sac`, druid `utevo gran res dru`, sorcerer `utevo gran res ven`, monk `utevo gran res tio`; level 200) calls the familiar until you say it again (free) or it dies; no 15-minute limit, no cooldown. Mana is charged only when it appears. It returns after logout or death until dismissed or killed. Familiars still cannot enter boss rooms | `data\scripts\family\familiar.lua`, switch in `data\scripts\lib\family_familiar.lua` |
| Grizzly Adams tasks | Killing in the Name Of without level ranges: every hunting task at any level (crocodiles to destroyers), points never capped by level, rank promotions, the full boss list and the special tasks open at any level. Still as upstream: 3 tasks at a time, each task 3 times, Demons only for Elite Hunters, the points needed per rank | `solo_quests.lua` (`Family.noTaskLevelCap`) |

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
| `data/scripts/actions/items/exercise_training_weapons.lua` | Charges are not consumed |
| `data-otservbr-global/scripts/actions/system/quest_reward_common.lua` | "Choose one" chest groups: each chest opens once |
| `data-otservbr-global/scripts/quests/the_inquisition_quest/actions_rewards.lua` | Every reward chest opens once; a tenth chest (put in the room by `monk_gear.lua`) gives Tibia's monk reward, the merudri nanbando |
| `data-otservbr-global/scripts/quests/demon_oak/actions_demon_oak_chest.lua` | Every reward chest opens once |
| `data-otservbr-global/npc/` Djinn NPCs: `bo_ques`, `gabel`, `umar`, `fa_hradin`, `haroun`, `nah_bob`, `ubaid`, `baa_leal`, `malor`, `alesar`, `yaman`, `kazzan`, `the_orc_king` | The other faction's allies are accepted; the Orc King gives one lamp per faction |
| `data-otservbr-global/scripts/quests/soul_war/action-reward_soul_war.lua` | Final reward chest repeats (see the balance table) |
| `data-otservbr-global/scripts/quests/soul_war/soul_war_mechanics.lua` | Counts each Megalomania kill for the reward chest |
| `data-otservbr-global/raids/raids.xml` | Every `margin` capped at 30 (minutes between two classic raids) |
| `data-otservbr-global/world/otservbr-monster.xml` | Every `spawntime` above 3600 set to 3600 (75 rare spawns; with `rateSpawn = 2` that is 30 min) |
| `data-otservbr-global/scripts/world_changes/oriental_trader.lua` | Yasir (oriental trader) comes every day instead of 33% of days, in Ankrahmun, Carlin or Liberty Bay; city NPCs tell where (`news`) |
| `data-otservbr-global/scripts/raids/monsters/undead_cavebear.lua` | Own raid name (upstream reused the Draptor raid's name, so one of them never happened) |
| `data-otservbr-global/npc/` Secret Service NPCs: `chester_kahs`, `emma`, `uncle` | After finishing one agency, the next can be joined |
| `data/scripts/talkactions/player/buy_house.lua` | Registered while Cyclopedia auctions are on, no one-house limit, no-rent message, fixed an undefined variable |
| `data/npclib/npc_system/bank_system.lua` | Bankers: `withdraw all` (or `all` when asked how much) withdraws the whole balance; an answer without a number when asked for an amount (withdraw, transfer) asks again instead of "There is not enough gold on your account" |
| `data-otservbr-global/npc/captain_bluebear.lua` | Sails to Rookgaard (100 gp) while `Family.rookgaardTravel` is on; Rookgaard added to his destination list |
| `data-otservbr-global/npc/the_oracle.lua` | A character with a vocation is offered the way back to its home town's temple, before the level checks |
| `data-otservbr-global/npc/santa_claus.lua` | One present per character per year (upstream: once ever); fixed upstream's reward roll, which failed for 10% of presents; no crash with a full backpack; greeting mentions the present |
| `data-otservbr-global/npc/captain_breezelda.lua` | Sails to Percht Island (100 gp) while the winter event runs |
| `data-otservbr-global/npc/frosty.lua` | Sleigh mounts for 10 percht horns + 10 broken bells each (upstream: a percht skull from the Percht Queen, who is not implemented); free ride back to Svargrond; no error on a plain `yes` |
| `data/scripts/creaturescripts/player/offline_training.lua` | With `Family.offlineTrainingUnlimited` the whole time away counts (not 12 h), the offline training time is not used up, there is no 10-minute minimum and the cap is 365 days (the 32-bit addition is limited to 12 h); the message shows days |
| `data-otservbr-global/lib/core/quests/catalog/010_in_service_of_yalahar.lua` | Quest log: "The Way to Yalahar" (Wyrdin and Timothy's research notes) and "Searoutes Around Yalahar" (special goods for Karith, 0-5 delivered) added as the first missions; the quest line now shows from that errand on (upstream only from Palimuth's first mission) |
| `data-otservbr-global/lib/core/quests/catalog/init.lua`, `data-otservbr-global/lib/core/storages.lua` | Quest log entry Measuring Tibia (`052_measuring_tibia.lua`, ours) and its storages 46280-46282 (map discovery) |
| `data-otservbr-global/npc/charos.lua` | As in Tibia since Measuring Tibia: no travel greeting, talks about `discovering`, gives the Discoverer outfit and addons (`outfit`, `yes`, `ten`/`fifteen`/`twenty`); the old city attunement still works with `attune` (limit 7); explains `Start Discovering` and the pink vortex |
| `data-otservbr-global/npc/oressa.lua` | Upstream bug fixed (2026-10-17): saying `knight` got no answer (the monk answer had been merged into the knight branch), so knight could only be chosen through `choose`, `close` |
| `data-otservbr-global/world/otservbr-npc.xml` | Spawns the seven Way of the Monk NPCs (Manop, Pema, Rudra, Rahng, Dajcho, Saih, Chesa) at their Tibia positions |
| `data-otservbr-global/npc/ambassador_manop.lua` | Upstream bug fixed (as upstream #4063): the pilgrimage counter was written to a key that does not exist, so no Blue Valley shrine could be used; it is no longer reset when talking to him again |
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
| `data/modules/modules.xml` | Adds the Cyclopedia house packet module (byte 173) for instant purchases, the Cyclopedia map action module (byte 219, map discovery) and the logout module (byte 20) for logging out during a fight |
| `data-otservbr-global/lib/quests/killing_in_the_name_of.lua` | Task level ranges ignored when `Family.noTaskLevelCap` is set |
| `data-otservbr-global/npc/grizzly_adams.lua` | No level ranges: full task list, no points cap, promotions, all bosses and special tasks at any level (same switch) |
| `data/scripts/spells/familiar/*.lua` (5 files) | Spell mana read through `FamilyFamiliarSpellMana` (0 with permanent familiars; the cost is charged by `familiar.lua`) |
| `data/scripts/eventcallbacks/player/on_look.lua` | Looking at a permanent familiar says it stays until dismissed (instead of a time left) |
| `data/scripts/systems/custom_monster_loot.lua` | Upstream example loot disabled: every monster dropped 1-10 christmas tokens all year and dragons platinum coins. Tokens now drop in December only (winter event) |

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
another city. Eighteen of them are vendors.

| What | Details |
|---|---|
| Cities | Thais, Carlin, Venore, Ab'Dendriel, Edron, Darashia, Ankrahmun, Port Hope, Liberty Bay, Svargrond, Yalahar |
| Walkers | 16 per city (176), unique names, random player outfits and colours |
| Where they walk | Street level (floor 7) only. Never inside houses, never on stairs, holes or teleports. They pause at open spots, never in doorways |
| Travel | About 8% of trips end at the harbour: the NPC vanishes and appears at another city's harbour 2–5 minutes later. Venore has no ship stop (its harbour is 43 sqm from the nearest street they can reach) |
| Talking | Say `hi`, then `tip` (or `quest`), `news`, `job`, `name`, `bye`. They stand still while you talk |
| Random lines | Every 45–150 s, only when a player is within sight |
| Vendors | 6 food sellers, 6 potion and rune sellers, 6 creature products traders (`vendorsPerKind`, raised from 2 on 2026-10-13). Each sits near the center of a random city for the day; cities are filled evenly, so every city has 1 or 2 vendors and never two of the same kind. Ask any walker for `news`: one line lists the vendors in that city, another names a vendor elsewhere |
| Stock | New random stock each server start: 14 foods; all potions plus 16 runes; 30 creature products |
| Prices | Food, potions and runes: the cheapest price any NPC in this datapack asks. Creature products: 1.5x the best price NPCs pay for them (so hunting still pays). Vendors only sell; they don't buy |
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

Useful knobs in the data file: `enabled`, `walkersPerCity`, `vendorsPerKind`,
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

The `upstream` remote is added once with:
`git remote add upstream https://github.com/opentibiabr/canary.git`

## Docker alternative (not used on the family PC)

`docker/.env.family` keeps a pinned Docker configuration (Canary 3.6.1,
login-server v1.1.3, MyAAC website). Docker on Windows needs WSL 2 and the
Windows hypervisor, so it is only for moving the server to a Linux machine or a
VPS later. Usage: copy it to `docker/.env`, fill the `CHANGE_ME` values, and run
`docker/up.sh` (or `up.ps1`).
