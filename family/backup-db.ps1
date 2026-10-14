# Backs up the game database to a timestamped .sql file and keeps the newest 30.
# Safe to run while the server is up. Take one before every update.
#
# Usage (PowerShell, from the repository folder):
#     powershell -ExecutionPolicy Bypass -File family\backup-db.ps1
#
# Restore (server stopped): family\restore-db.ps1 (see the manual for a
# restore after reinstalling Windows).

. (Join-Path $PSScriptRoot 'lib.ps1')
$cfg = Read-LocalEnv
$dump = Get-MariaDbTool $cfg 'mariadb-dump'

$dir = $cfg['BACKUP_DIR']
if (-not $dir) { $dir = Join-Path $env:USERPROFILE 'OT-backups' }
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$file = Join-Path $dir ("{0}-{1}.sql" -f $cfg['DB_NAME'], (Get-Date -Format 'yyyyMMdd-HHmmss'))

Write-Step "Backing up '$($cfg['DB_NAME'])' to $file"
$old = $env:MYSQL_PWD
$oldPref = $ErrorActionPreference
$env:MYSQL_PWD = $cfg['DB_PASSWORD']
$ErrorActionPreference = 'Continue'
try {
	$out = & $dump "--host=$($cfg['DB_HOST'])" "--port=$($cfg['DB_PORT'])" "--user=$($cfg['DB_USER'])" `
		--single-transaction --no-tablespaces --routines --triggers --default-character-set=utf8mb4 `
		"--result-file=$file" $cfg['DB_NAME'] 2>&1 | ForEach-Object { "$_" }
	$code = $LASTEXITCODE
} finally {
	$env:MYSQL_PWD = $old
	$ErrorActionPreference = $oldPref
}
if ($code -ne 0 -or -not (Test-Path -LiteralPath $file) -or (Get-Item -LiteralPath $file).Length -lt 1024) {
	Stop-Family "Backup failed: $($out | Out-String)"
}
Write-Ok ("{0:N1} MB written" -f ((Get-Item -LiteralPath $file).Length / 1MB))

$pattern = "$($cfg['DB_NAME'])-*.sql"
Get-ChildItem -LiteralPath $dir -Filter $pattern | Sort-Object Name -Descending | Select-Object -Skip 30 |
	ForEach-Object { Remove-Item -LiteralPath $_.FullName; Write-Host "    removed old backup $($_.Name)" }
