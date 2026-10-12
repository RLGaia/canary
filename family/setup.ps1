# One-time setup (safe to run again): downloads the pinned server programs,
# creates the database and its user, imports the schema and secures the
# default GOD account.
#
# Usage (PowerShell, from the repository folder):
#     powershell -ExecutionPolicy Bypass -File family\setup.ps1

. (Join-Path $PSScriptRoot 'lib.ps1')
$ProgressPreference = 'SilentlyContinue'   # makes downloads much faster on PowerShell 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$cfg = Read-LocalEnv

# ---------------------------------------------------------------------------
Write-Step "Server programs (Canary $CanaryVersion, login-server $LoginServerVersion)"
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
$versionsFile = Join-Path $BinDir 'versions.txt'
$wanted = "canary=$CanaryVersion`r`nlogin-server=$LoginServerVersion"
$current = ''
if (Test-Path -LiteralPath $versionsFile) { $current = (Get-Content -LiteralPath $versionsFile -Raw).Trim() }

function Install-PinnedExe([string]$Url, [string]$Sha256, [string]$ExeName, [string]$Destination) {
	$tmp = Join-Path ([IO.Path]::GetTempPath()) ("family-" + [Guid]::NewGuid().ToString('N'))
	New-Item -ItemType Directory -Path $tmp | Out-Null
	try {
		$zip = Join-Path $tmp 'download.zip'
		Write-Host "    downloading $Url"
		Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing
		$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zip).Hash
		if ($hash -ne $Sha256) { Stop-Family "Checksum mismatch for $Url (got $hash). The file was not installed." }
		Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force
		Copy-Item -LiteralPath (Join-Path $tmp $ExeName) -Destination $Destination -Force
	} finally {
		Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
	}
}

if ($current -eq $wanted -and (Test-Path -LiteralPath $CanaryExe) -and (Test-Path -LiteralPath $LoginExe)) {
	Write-Ok 'already installed'
} else {
	Install-PinnedExe $CanaryZipUrl $CanaryZipSha256 'canary.exe' $CanaryExe
	Write-Ok "canary.exe -> $CanaryExe"
	Install-PinnedExe $LoginServerZipUrl $LoginServerSha256 'login-server.exe' $LoginExe
	Write-Ok "login-server.exe -> $LoginExe"
	Write-Utf8NoBom $versionsFile $wanted
}

# ---------------------------------------------------------------------------
Write-Step 'Database and user'
# ---------------------------------------------------------------------------
$null = Get-MariaDbTool $cfg 'mariadb'
$db = $cfg['DB_NAME']; $user = $cfg['DB_USER']
$pw = ConvertTo-SqlString $cfg['DB_PASSWORD']

$appUserWorks = $false
try { $null = Invoke-MariaDb -Cfg $cfg -Sql 'SELECT 1;'; $appUserWorks = $true } catch { }

if ($appUserWorks) {
	Write-Ok "user '$user' can already reach database '$db'"
} else {
	Write-Host '    The MariaDB root password is the one you chose in the MariaDB installer.'
	$root = ConvertFrom-Secure (Read-Host -Prompt 'MariaDB root password' -AsSecureString)
	$sql = @"
CREATE DATABASE IF NOT EXISTS ``$db``;
CREATE USER IF NOT EXISTS '$user'@'localhost' IDENTIFIED BY $pw;
CREATE USER IF NOT EXISTS '$user'@'127.0.0.1' IDENTIFIED BY $pw;
ALTER USER '$user'@'localhost' IDENTIFIED BY $pw;
ALTER USER '$user'@'127.0.0.1' IDENTIFIED BY $pw;
GRANT ALL PRIVILEGES ON ``$db``.* TO '$user'@'localhost';
GRANT ALL PRIVILEGES ON ``$db``.* TO '$user'@'127.0.0.1';
FLUSH PRIVILEGES;
"@
	try {
		$null = Invoke-MariaDb -Cfg $cfg -Sql $sql -User 'root' -Password $root -NoDatabase
	} catch {
		Stop-Family "Could not create the database/user as root. Check the root password and that the MariaDB service is running.`n$($_.Exception.Message)"
	}
	$null = Invoke-MariaDb -Cfg $cfg -Sql 'SELECT 1;'
	Write-Ok "database '$db' and user '$user' ready"
}

# ---------------------------------------------------------------------------
Write-Step 'Database schema'
# ---------------------------------------------------------------------------
function Reset-EmptyDatabase {
	$null = Invoke-MariaDb -Cfg $cfg -NoDatabase -Sql "DROP DATABASE IF EXISTS ``$db``; CREATE DATABASE ``$db``;"
}

if (Test-DatabaseReady $cfg) {
	Write-Ok 'schema already imported'
} else {
	$tables = [int](Get-SqlScalar $cfg 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE();')
	if ($tables -gt 0) {
		# Leftover from an earlier, incomplete import. Only reset it when it holds
		# no game accounts besides the built-in GOD account.
		$hasAccounts = Get-SqlScalar $cfg "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'accounts';"
		if ($hasAccounts -eq '1') {
			$realAccounts = [int](Get-SqlScalar $cfg "SELECT COUNT(*) FROM accounts WHERE name <> 'god';")
			if ($realAccounts -gt 0) {
				Stop-Family "Database '$db' is incomplete but already has $realAccounts account(s). Not resetting it automatically; ask for help before continuing."
			}
		}
		Write-Warn "found $tables table(s) from an incomplete import; recreating the empty database"
		Reset-EmptyDatabase
	}
	try {
		$null = Invoke-MariaDb -Cfg $cfg -SqlFile (Join-Path $RepoRoot 'schema.sql')
	} catch {
		$why = $_.Exception.Message
		Reset-EmptyDatabase
		Stop-Family "schema.sql import failed; the database was left empty so you can simply run setup again.`n$why"
	}
	if (-not (Test-DatabaseReady $cfg)) { Stop-Family 'schema.sql ran without errors, but the server_config table is missing.' }
	Write-Ok ('schema.sql imported ({0} tables)' -f (Get-SqlScalar $cfg 'SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE();'))
}

# ---------------------------------------------------------------------------
Write-Step 'Default GOD account (@god)'
# ---------------------------------------------------------------------------
$godDefault = Get-Sha1Hex 'god'
$godHash = Get-SqlScalar $cfg "SELECT password FROM accounts WHERE name = 'god';"
if ($godHash -ne $godDefault) {
	Write-Ok 'password already changed from the public default'
} else {
	Write-Host '    The GOD account still has the public password "god". Choose a new one.'
	$new = Read-NewPassword 'New password for @god'
	$null = Invoke-MariaDb -Cfg $cfg -Sql ("UPDATE accounts SET password = " + (ConvertTo-SqlString (Get-Sha1Hex $new)) + " WHERE name = 'god';")
	Write-Ok 'GOD password changed (log in with email @god and your new password)'
}

Write-Host ''
Write-Host 'Setup complete. Next:' -ForegroundColor Green
Write-Host '  1. Create your accounts:  powershell -ExecutionPolicy Bypass -File family\new-account.ps1'
Write-Host '  2. Start the server:      powershell -ExecutionPolicy Bypass -File family\start-server.ps1'
Write-Host "  3. Game client:           $ClientVersion (see FAMILY.md)"
