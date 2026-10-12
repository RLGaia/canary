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
7. **Game client 15.11**: download it from the release page above and follow its
   notes (extract `Qt6WebEngineCore.rar` into `bin`, then run `bin\client.exe`).
   It already points to `http://127.0.0.1/login.php`, which is where the login server listens.

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
