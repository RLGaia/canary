# Gaia Family Server

Private Canary server for two players (Rodrigo and his father).
This fork follows [opentibiabr/canary](https://github.com/opentibiabr/canary);
all family changes live on the `family` branch.

## Pinned versions

| Piece | Version | Where it comes from |
|---|---|---|
| Canary server | v3.6.1 (`ghcr.io/opentibiabr/canary:3.6.1`) | branch `family` starts at tag `v3.6.1` |
| Game client | 15.11 (`15.11.c9d1cf`) | <https://github.com/dudantas/tibia-client/releases/tag/15.11.c9d1cf> |
| Login server | `opentibiabr/login-server:v1.1.3` | Docker Hub |
| Website (MyAAC) | commit `309bf48` of `slawkens/myaac` develop | built by Docker |
| Database | `mariadb:11.4` | Docker Hub |
| Map | `otservbr.otbm` from release v3.6.1 | downloaded on first start |

All of these are set in `docker/.env.family`. The server version and the client
version must always match.

## Golden rules

- Never commit `docker/.env`, database backups, the game client, or Docker image archives.
- Keep backups outside this folder (for example `%USERPROFILE%\OT-backups`).
- Add new files instead of editing upstream files whenever possible, which keeps updates painless.
- Commit email: use the GitHub noreply address (`RLGaia@users.noreply.github.com`).

## First run (Windows, server PC)

Requires Docker Desktop with WSL 2 ("Engine running").

```powershell
git clone https://github.com/RLGaia/canary.git
cd canary
git checkout family
cd docker
Copy-Item .env.family .env
notepad .env      # replace every CHANGE_ME before continuing
.\up.ps1
```

The first start downloads the images and the map and builds the website, so it
can take a while. Follow it with `docker compose logs -f server`.

- Website: <http://localhost:8080>
- Client login URL: `http://localhost:8088/login`

### Secure it right after the first start

The database schema always creates a GOD account (`@god` / `god`). Change its
password (you will be asked for `CANARY_DB_PASSWORD`):

```powershell
docker compose exec db mariadb -u canary -p canary -e "UPDATE accounts SET password = SHA1('NEW_PASSWORD_HERE') WHERE name = 'god';"
```

Then create the two player accounts on the website.

## Playing together (Tailscale)

1. Install Tailscale on both PCs and join the same tailnet (free Personal plan).
2. In `docker/.env`, set `CANARY_SERVER_IP` to the server PC's Tailscale IP (`100.x.y.z`).
3. Restart: `docker compose up -d`.
4. On both PCs, the client login URL becomes `http://<tailscale-ip>:8088/login`.

Do not forward router ports. Nothing needs to be exposed to the internet.

## Database backup (manual, until the backup script exists)

```powershell
cd docker
docker compose exec db sh -c 'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" canary > /tmp/canary-backup.sql'
docker compose cp db:/tmp/canary-backup.sql "$env:USERPROFILE\OT-backups\canary-$(Get-Date -Format yyyyMMdd-HHmm).sql"
```

Always take a backup before updating. Database migrations only move forward.

## Updating to a new Canary release

```powershell
git fetch upstream --tags
git checkout -b update-vX.Y.Z family
git merge vX.Y.Z
# resolve conflicts, update the pinned versions in docker/.env.family and here
```

Then back up the database, start the new version, run the smoke test, and only
then merge `update-vX.Y.Z` into `family`. Download the matching client on both PCs.

Smoke test (GOD account): log in, walk, fight a monster, loot, use a depot,
log out and back in, and confirm the character was saved.

The `upstream` remote is added once with:
`git remote add upstream https://github.com/opentibiabr/canary.git`
