# Shared helpers for the family server scripts. Dot-sourced by the other scripts.
# Compatible with Windows PowerShell 5.1 and PowerShell 7.

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Pinned versions. Change them only when updating to a new Canary release,
# together with the matching game client (see FAMILY.md).
# ---------------------------------------------------------------------------
$Script:CanaryVersion      = 'v3.6.1'
$Script:CanaryZipUrl       = 'https://github.com/opentibiabr/canary/releases/download/v3.6.1/canary-windows-cmake-release.zip'
$Script:CanaryZipSha256    = '7A7A7985D2042C834488A8769991109074484A79FAF11F131436DBCDADFA34E8'
# Login server: our fork's build (upstream main of May 2026 + world PvP type),
# because no official release answers the login screen's boosted creature and
# event schedule requests yet. Official v1.1.3 was:
#   https://github.com/opentibiabr/login-server/releases/download/v1.1.3/login-server-v1.1.3-windows-amd64.zip
#   C4D727EC933E84B1A92308FC4B21380912FC9554BB20219D18C29A6D9ECD2A5B
$Script:LoginServerVersion = 'family-1'
$Script:LoginServerZipUrl  = 'https://github.com/RLGaia/login-server/releases/download/family-1/login-server-family-1-windows-amd64.zip'
$Script:LoginServerSha256  = 'C717940CF9535C9A20C4BB0E46C1C7E6C82ACE7C3977F8209F111346B2B5644E'
$Script:ClientVersion      = '15.11.c9d1cf'

$Script:FamilyDir  = $PSScriptRoot
$Script:RepoRoot   = Split-Path -Parent $PSScriptRoot
$Script:BinDir     = Join-Path $FamilyDir 'bin'
$Script:CanaryExe  = Join-Path $RepoRoot 'canary.exe'
$Script:LoginExe   = Join-Path $BinDir 'login-server.exe'
$Script:LocalEnv   = Join-Path $FamilyDir 'local.env'

function Write-Step([string]$Text) { Write-Host "==> $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text)   { Write-Host "    OK  $Text" -ForegroundColor Green }
function Write-Warn([string]$Text) { Write-Host "    !!  $Text" -ForegroundColor Yellow }
function Stop-Family([string]$Text) { Write-Host "ERROR: $Text" -ForegroundColor Red; exit 1 }

function Read-LocalEnv {
	if (-not (Test-Path -LiteralPath $LocalEnv)) {
		Copy-Item -LiteralPath (Join-Path $FamilyDir 'local.env.example') -Destination $LocalEnv
		Stop-Family "Created family\local.env from the example. Open it, set DB_PASSWORD (and review the rest), then run this script again."
	}
	$cfg = @{}
	foreach ($line in Get-Content -LiteralPath $LocalEnv) {
		$t = $line.Trim()
		if ($t -eq '' -or $t.StartsWith('#')) { continue }
		$i = $t.IndexOf('=')
		if ($i -lt 1) { continue }
		$cfg[$t.Substring(0, $i).Trim()] = $t.Substring($i + 1).Trim()
	}
	foreach ($k in 'DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'SERVER_IP', 'SERVER_NAME', 'LOGIN_HTTP_PORT') {
		if (-not $cfg.ContainsKey($k) -or $cfg[$k] -eq '') { Stop-Family "family\local.env is missing a value for $k." }
	}
	if ($cfg['DB_PASSWORD'] -eq 'CHANGE_ME') { Stop-Family "Set DB_PASSWORD in family\local.env (it is still CHANGE_ME)." }
	if ($cfg['DB_NAME'] -notmatch '^[A-Za-z0-9_]+$') { Stop-Family "DB_NAME may only contain letters, digits and underscore." }
	if ($cfg['DB_USER'] -notmatch '^[A-Za-z0-9_]+$') { Stop-Family "DB_USER may only contain letters, digits and underscore." }
	return $cfg
}

function Get-MariaDbTool([hashtable]$Cfg, [string]$Name) {
	$dirs = @()
	if ($Cfg['MARIADB_BIN']) { $dirs += $Cfg['MARIADB_BIN'] }
	$dirs += Get-ChildItem -Path "$env:ProgramFiles\MariaDB *\bin" -Directory -ErrorAction SilentlyContinue |
		Sort-Object FullName -Descending | ForEach-Object { $_.FullName }
	foreach ($d in $dirs) {
		$p = Join-Path $d "$Name.exe"
		if (Test-Path -LiteralPath $p) { return $p }
	}
	$cmd = Get-Command $Name -ErrorAction SilentlyContinue
	if ($cmd) { return $cmd.Source }
	Stop-Family "$Name.exe not found. Install MariaDB 11.4 (see FAMILY.md) or set MARIADB_BIN in family\local.env."
}

# Runs SQL with the mariadb client and returns the result rows (tab separated,
# no headers). The SQL is sent on standard input, not on the command line:
# in that mode the client stops at the first failing statement and exits with
# an error code (with "source" or --execute it may report success anyway), and
# warnings on stderr can never be mistaken for result rows.
function Invoke-MariaDb {
	param(
		[hashtable]$Cfg,
		[string]$Sql,
		[string]$SqlFile,
		[string]$User = $Cfg['DB_USER'],
		[string]$Password = $Cfg['DB_PASSWORD'],
		[switch]$NoDatabase
	)
	$exe = Get-MariaDbTool $Cfg 'mariadb'
	$cliArgs = @("--host=$($Cfg['DB_HOST'])", "--port=$($Cfg['DB_PORT'])", "--user=$User", '--batch', '--skip-column-names', '--default-character-set=utf8mb4')
	if (-not $NoDatabase) { $cliArgs += "--database=$($Cfg['DB_NAME'])" }
	if ($SqlFile) { $Sql = [System.IO.File]::ReadAllText($SqlFile) }

	$psi = New-Object System.Diagnostics.ProcessStartInfo
	$psi.FileName = $exe
	$psi.Arguments = ($cliArgs | ForEach-Object { '"' + $_ + '"' }) -join ' '
	$psi.UseShellExecute = $false
	$psi.RedirectStandardInput = $true
	$psi.RedirectStandardOutput = $true
	$psi.RedirectStandardError = $true
	$psi.CreateNoWindow = $true
	$psi.EnvironmentVariables['MYSQL_PWD'] = $Password

	$p = [System.Diagnostics.Process]::Start($psi)
	$outTask = $p.StandardOutput.ReadToEndAsync()
	$errTask = $p.StandardError.ReadToEndAsync()
	# Write UTF-8 bytes directly (Windows PowerShell 5.1 would otherwise use the console code page).
	$bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($Sql + "`n")
	try {
		$p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
		$p.StandardInput.BaseStream.Flush()
	} catch { }  # the client may exit early on a connection error; reported below
	$p.StandardInput.Close()
	$p.WaitForExit()
	$stdout = $outTask.Result
	$stderr = $errTask.Result.Trim()
	if ($p.ExitCode -ne 0) {
		# Show MariaDB's ERROR line(s); the client also echoes the whole failed statement.
		$errLines = @($stderr -split "`r?`n" | Where-Object { $_ -match '^ERROR' })
		if ($errLines.Count -gt 0) { $stderr = $errLines -join "`n" }
		if (-not $stderr) { $stderr = "exit code $($p.ExitCode)" }
		throw "MariaDB said: $stderr"
	}
	return @($stdout -split "`r?`n" | Where-Object { $_ -ne '' })
}

# Runs a query and returns the first value of the first row as a trimmed
# string, or '' when the query returns no rows.
function Get-SqlScalar([hashtable]$Cfg, [string]$Sql) {
	$rows = @(Invoke-MariaDb -Cfg $Cfg -Sql $Sql)
	if ($rows.Count -eq 0 -or $null -eq $rows[0]) { return '' }
	return ([string]$rows[0]).Split("`t")[0].Trim()
}

# Escapes a value for a single-quoted SQL string literal.
function ConvertTo-SqlString([string]$Value) {
	return "'" + $Value.Replace('\', '\\').Replace("'", "''") + "'"
}

# Escapes a value for a double-quoted Lua string literal.
function ConvertTo-LuaString([string]$Value) {
	return '"' + $Value.Replace('\', '\\').Replace('"', '\"') + '"'
}

function Get-Sha1Hex([string]$Text) {
	$sha = [System.Security.Cryptography.SHA1]::Create()
	try {
		$bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Text))
	} finally { $sha.Dispose() }
	return -join ($bytes | ForEach-Object { $_.ToString('x2') })
}

function ConvertFrom-Secure([System.Security.SecureString]$Secure) {
	$ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
	try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
	finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
}

function Read-NewPassword([string]$Prompt) {
	while ($true) {
		$a = Read-Host -Prompt $Prompt -AsSecureString
		$b = Read-Host -Prompt 'Type it again' -AsSecureString
		$pa = ConvertFrom-Secure $a
		$pb = ConvertFrom-Secure $b
		if ($pa -ne $pb) { Write-Warn 'The passwords do not match. Try again.'; continue }
		if ($pa.Length -lt 6) { Write-Warn 'Use at least 6 characters.'; continue }
		return $pa
	}
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
	[System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

function Test-DatabaseReady([hashtable]$Cfg) {
	try {
		return (Get-SqlScalar $Cfg "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'server_config';") -eq '1'
	} catch {
		return $false
	}
}
