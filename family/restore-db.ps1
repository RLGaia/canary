# Restores the game database from a backup made by backup-db.ps1: accounts,
# characters, items, depots, houses and their furniture, bank, quests.
# Use it after reinstalling Windows (see the manual) or to undo a mistake.
#
# The server must be stopped. If the current database holds accounts, it is
# backed up first, so a wrong restore can be undone by restoring that file.
#
# Usage (PowerShell, from the repository folder):
#     powershell -ExecutionPolicy Bypass -File family\restore-db.ps1
#         lists the newest backups in the backup folder and asks which one
#     powershell -ExecutionPolicy Bypass -File family\restore-db.ps1 -File "D:\OT-backups\canary-20261014-180000.sql"
#         restores that file

param([string]$File)

. (Join-Path $PSScriptRoot 'lib.ps1')
$cfg = Read-LocalEnv

# ---------------------------------------------------------------------------
Write-Step 'Checks'
# ---------------------------------------------------------------------------
if (Get-Process -Name 'canary' -ErrorAction SilentlyContinue) {
	Stop-Family 'The game server is running. Stop it first (log out, Ctrl+C in its window, wait for "Server stopped."), then run this again.'
}
try {
	$null = Invoke-MariaDb -Cfg $cfg -Sql 'SELECT 1;'
} catch {
	Stop-Family "Cannot reach database '$($cfg['DB_NAME'])' as user '$($cfg['DB_USER'])'. Is the MariaDB service running? On a new installation, run family\setup.ps1 first: it creates the database and its user.`n$($_.Exception.Message)"
}
Write-Ok "database '$($cfg['DB_NAME'])' reachable, server stopped"

# ---------------------------------------------------------------------------
Write-Step 'Backup to restore'
# ---------------------------------------------------------------------------
$dir = $cfg['BACKUP_DIR']
if (-not $dir) { $dir = Join-Path $env:USERPROFILE 'OT-backups' }

if (-not $File) {
	$list = @(Get-ChildItem -LiteralPath $dir -Filter "$($cfg['DB_NAME'])-*.sql" -ErrorAction SilentlyContinue |
		Sort-Object Name -Descending | Select-Object -First 10)
	if ($list.Count -eq 0) {
		Stop-Family "No backups found in $dir. Copy your backup files there, or give the file directly: -File ""C:\path\to\file.sql"""
	}
	Write-Host "    Newest backups in ${dir}:"
	for ($i = 0; $i -lt $list.Count; $i++) {
		Write-Host ("    {0,2}. {1}   {2}   {3:N1} MB" -f ($i + 1), $list[$i].Name, $list[$i].LastWriteTime.ToString('yyyy-MM-dd HH:mm'), ($list[$i].Length / 1MB))
	}
	$answer = (Read-Host -Prompt 'Number of the backup to restore (Enter = 1, the newest)').Trim()
	if ($answer -eq '') { $answer = '1' }
	$n = 0
	if (-not [int]::TryParse($answer, [ref]$n) -or $n -lt 1 -or $n -gt $list.Count) { Stop-Family "Not a number from the list: $answer" }
	$File = $list[$n - 1].FullName
}

if (-not (Test-Path -LiteralPath $File -PathType Leaf)) { Stop-Family "File not found: $File" }
$File = (Resolve-Path -LiteralPath $File).Path
$item = Get-Item -LiteralPath $File
$head = (Get-Content -LiteralPath $File -TotalCount 5) -join "`n"
if ($item.Length -lt 1024 -or $head -notmatch '(MariaDB|MySQL) dump') {
	Stop-Family "$File does not look like a backup made by backup-db.ps1."
}
if (-not (Select-String -LiteralPath $File -Pattern 'CREATE TABLE `server_config`' -SimpleMatch -Quiet)) {
	Stop-Family "$File does not contain the game tables (server_config is missing)."
}
Write-Ok ("{0} ({1:N1} MB, {2})" -f $item.Name, ($item.Length / 1MB), $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))

# ---------------------------------------------------------------------------
Write-Step 'Confirm'
# ---------------------------------------------------------------------------
Write-Host "    Everything in database '$($cfg['DB_NAME'])' will be replaced by this backup:"
Write-Host '    accounts, characters, items, houses, bank balances and quest progress.'
$confirm = (Read-Host -Prompt 'Type RESTORE to continue').Trim()
if ($confirm -cne 'RESTORE') { Stop-Family 'Cancelled. Nothing was changed.' }

# ---------------------------------------------------------------------------
Write-Step 'Safety backup of the current database'
# ---------------------------------------------------------------------------
$currentAccounts = 0
if (Test-DatabaseReady $cfg) {
	$currentAccounts = [int](Get-SqlScalar $cfg "SELECT COUNT(*) FROM accounts WHERE name <> 'god';")
}
if ($currentAccounts -gt 0) {
	& (Join-Path $PSScriptRoot 'backup-db.ps1')
	if ($LASTEXITCODE -ne 0) { Stop-Family 'The safety backup failed, so nothing was restored.' }
} else {
	Write-Ok 'the current database holds no accounts; nothing to keep'
}

# ---------------------------------------------------------------------------
Write-Step 'Restoring (this can take a minute)'
# ---------------------------------------------------------------------------
try {
	$null = Invoke-MariaDb -Cfg $cfg -SqlFile $File
} catch {
	Stop-Family "The restore stopped with an error. Run this script again with the same file; if it fails again, restore the safety backup made above.`n$($_.Exception.Message)"
}
if (-not (Test-DatabaseReady $cfg)) { Stop-Family 'The restore finished, but the server_config table is missing.' }
$accounts = Get-SqlScalar $cfg "SELECT COUNT(*) FROM accounts WHERE name <> 'god';"
$players = Get-SqlScalar $cfg 'SELECT COUNT(*) FROM players;'
$houses = Get-SqlScalar $cfg 'SELECT COUNT(*) FROM houses WHERE owner > 0;'
Write-Ok "restored: $accounts account(s), $players character(s), $houses house(s) with an owner"

Write-Host ''
Write-Host 'Restore complete. Start the server as usual:' -ForegroundColor Green
Write-Host '  powershell -ExecutionPolicy Bypass -File family\start-server.ps1'
Write-Host 'Passwords (including @god) are the ones that were in use when the backup was made.'
