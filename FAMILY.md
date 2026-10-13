# Gaia Family Server

Private Canary server for two players (Rodrigo and his father).
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
| Login server | v1.1.3 (`login-server.exe`) | release zip, downloaded and checksum-verified by `family\setup.ps1` |
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
| `start-server.ps1` | Builds `config.lua`, starts the login server and Canary |
| `backup-db.ps1` | Dumps the database to `%USERPROFILE%\OT-backups`, keeps the newest 30 |

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
6. **Accounts**, once for you and once for Dad:
   ```powershell
   powershell -ExecutionPolicy Bypass -File family\new-account.ps1
   ```
   Logins look like an email (`rodrigo@family`); they don't need to be real.
   New characters start like real Tibia: no vocation, on the Dawnport tutorial island.
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
For local play you can cancel. To play with Dad, allow `canary.exe` and
`login-server.exe` (see below).

## Playing together (Tailscale)

1. Install Tailscale on both PCs and sign in to the same tailnet (free Personal plan).
2. In `family\local.env`, set `SERVER_IP` to this PC's Tailscale IP (`100.x.y.z`).
3. Restart the server.
4. On **both** PCs, edit the client's `conf\config.ini`:
   ```ini
   loginWebService=http://100.x.y.z/login.php
   clientWebService=http://100.x.y.z/login.php
   ```
5. If Dad cannot connect, allow `canary.exe` and `login-server.exe` in Windows Firewall
   for the network Tailscale uses (ports 80, 7171, 7172).

Never forward router ports. Nothing needs to be exposed to the internet.

## Game balance (solo / duo)

Chosen on 2026-10-12. The server log confirms it on every start with two `[Family]` lines.

| Area | Setting | Where |
|---|---|---|
| Premium | Every account is always premium | `family\config.family.lua` (`freePremium`) |
| PvP | No PvP (`no-pvp`) | `family\config.family.lua` |
| Experience | 10x up to level 50, 7x to 100, 5x to 200, 3x after | `data\scripts\family\solo_balance.lua` |
| Skills | 10x up to skill 60, 7x to 80, 5x to 100, 3x after | same |
| Magic level | 10x up to ML 30, 7x to 60, 5x to 90, 3x after | same |
| Loot | 2x, rarest items first | `family\config.family.lua` |
| Bosses | 50% health, 70% damage (Bosstiary bosses only) | `family\config.family.lua` |
| Boss cooldown | 4 hours, also for levers that set their own longer cooldown | both files |
| Boss levers | One player is always enough (all 66 standard levers, Soul War included) | `solo_balance.lua` |
| Tibia Coins | Topped up to 10,000,000 on login whenever below 1,000,000 | `solo_balance.lua` |
| Conveniences | Auto-loot, auto-bank, free third Prey and Hunting Task slots | `family\config.family.lua` |
| Death | No experience, skill or item loss: you only wake up in the temple. Everyone always has full blessings | `family\config.family.lua`, `solo_balance.lua` |
| Training | Exercise weapons never run out (buy one in the Store with the free coins); exercise and offline training 2x faster | both files |
| Respawn | 2x faster (classic hunts: 90 s to 45 s) | `family\config.family.lua` |
| Party quests | One player can do the quests in the table below | the files listed there |
| Exclusive quests | Both Djinn factions; all three Secret Service agencies, one after another; every chest of a "choose one reward" room | `data\scripts\family\solo_quests.lua` |
| Soul War reward | The final chest gives another random Soul item after each new Megalomania kill, or once every 20 h | `solo_quests.lua` |

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
| `data-otservbr-global/scripts/quests/the_inquisition_quest/actions_rewards.lua` | Every reward chest opens once |
| `data-otservbr-global/scripts/quests/demon_oak/actions_demon_oak_chest.lua` | Every reward chest opens once |
| `data-otservbr-global/npc/` Djinn NPCs: `bo_ques`, `gabel`, `umar`, `fa_hradin`, `haroun`, `nah_bob`, `ubaid`, `baa_leal`, `malor`, `alesar`, `yaman`, `kazzan`, `the_orc_king` | The other faction's allies are accepted; the Orc King gives one lamp per faction |
| `data-otservbr-global/scripts/quests/soul_war/action-reward_soul_war.lua` | Final reward chest repeats (see the balance table) |
| `data-otservbr-global/scripts/quests/soul_war/soul_war_mechanics.lua` | Counts each Megalomania kill for the reward chest |
| `data-otservbr-global/npc/` Secret Service NPCs: `chester_kahs`, `emma`, `uncle` | After finishing one agency, the next can be joined |

All exclusive-quest edits read `Family.unlockExclusiveQuests` (in `solo_quests.lua`); set it to
`false` to bring back the upstream "pick one" rules without touching the other files.

Not changed (yet): In Service of Yalahar (Palimuth or Azerus side), Paradox Tower reward,
Heart of Destruction final lever (needs 3 players).

Quests still to check when reached (party mechanics beyond the entry lever): Ferumbras' Ascension,
Heart of Destruction, Cults of Tibia, Oramond (Glooth Fairy), Dark Trails, The Order of the Lion,
The Dream Courts, Forgotten Knowledge, Grave Danger.

## Backups

```powershell
powershell -ExecutionPolicy Bypass -File family\backup-db.ps1
```

Always back up before updating; database migrations only move forward.
To restore (server stopped), see the comment at the top of `family\backup-db.ps1`.

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
