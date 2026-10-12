# Creates a game account and its first character, without needing a website.
# The character is a copy of the server's "Rook Sample" (no vocation, Dawnport
# tutorial island), the same template the MyAAC website uses for new players.
#
# Usage (PowerShell, from the repository folder):
#     powershell -ExecutionPolicy Bypass -File family\new-account.ps1
# Add a character to an existing account:
#     powershell -ExecutionPolicy Bypass -File family\new-account.ps1 -AddCharacter

param([switch]$AddCharacter)

. (Join-Path $PSScriptRoot 'lib.ps1')
$cfg = Read-LocalEnv
if (-not (Test-DatabaseReady $cfg)) { Stop-Family 'The database is not set up yet. Run family\setup.ps1 first.' }

# --- account -----------------------------------------------------------------
$email = (Read-Host -Prompt 'Account login (email, e.g. rodrigo@family)').Trim().ToLowerInvariant()
if ($email -notmatch '^[a-z0-9._%+-]+@[a-z0-9.-]+$' -or $email.Length -gt 255) {
	Stop-Family 'Use an email-like login with letters, digits and @ (it does not need to be a real email).'
}
$emailSql = ConvertTo-SqlString $email
$existing = Get-SqlScalar $cfg "SELECT id FROM accounts WHERE email = $emailSql;"

if ($AddCharacter) {
	if (-not $existing) { Stop-Family "No account with login $email." }
	$accountId = [int]$existing
} else {
	if ($existing) { Stop-Family "An account with login $email already exists. Use -AddCharacter to add a character to it." }
	$password = Read-NewPassword 'Account password'
	$hash = ConvertTo-SqlString (Get-Sha1Hex $password)
	# accounts.name must be unique and at most 32 characters; derive it from the login.
	$name = $email.Split('@')[0]
	if ($name.Length -gt 24) { $name = $name.Substring(0, 24) }
	$name = $name + '_' + ([Guid]::NewGuid().ToString('N').Substring(0, 6))
	$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
	$null = Invoke-MariaDb -Cfg $cfg -Sql ("INSERT INTO accounts (name, email, password, type, creation) VALUES (" + (ConvertTo-SqlString $name) + ", $emailSql, $hash, 1, $now);")
	$accountId = [int](Get-SqlScalar $cfg "SELECT id FROM accounts WHERE email = $emailSql;")
	Write-Ok "account created (login: $email)"
}

# --- character ---------------------------------------------------------------
$charName = (Read-Host -Prompt 'Character name (e.g. Rodrigo Gaia)').Trim() -replace '\s+', ' '
if ($charName -cnotmatch '^[A-Z][a-z]+( [A-Z][a-z]+){0,2}$' -or $charName.Length -lt 3 -or $charName.Length -gt 25) {
	Stop-Family 'Use 1-3 words, each starting with a capital letter followed by lowercase letters (3-25 characters).'
}
$charSql = ConvertTo-SqlString $charName
if (Get-SqlScalar $cfg "SELECT id FROM players WHERE name = $charSql;") {
	Stop-Family "A character named $charName already exists."
}
$sexAnswer = (Read-Host -Prompt 'Sex: (M)ale or (F)emale').Trim().ToUpperInvariant()
if ($sexAnswer -eq 'F') { $sex = 0; $lookType = 136 } elseif ($sexAnswer -eq 'M') { $sex = 1; $lookType = 128 } else { Stop-Family 'Answer M or F.' }

$copyCols = 'group_id, level, vocation, health, healthmax, experience, lookbody, lookfeet, lookhead, looklegs, maglevel, mana, manamax, manaspent, town_id, conditions, cap, skill_club, skill_club_tries, skill_sword, skill_sword_tries, skill_axe, skill_axe_tries, skill_dist, skill_dist_tries'
$sql = "INSERT INTO players (name, account_id, sex, looktype, $copyCols) SELECT $charSql, $accountId, $sex, $lookType, $copyCols FROM players WHERE name = 'Rook Sample' LIMIT 1;"
$null = Invoke-MariaDb -Cfg $cfg -Sql $sql
if (-not (Get-SqlScalar $cfg "SELECT id FROM players WHERE name = $charSql;")) {
	Stop-Family 'Character was not created (the "Rook Sample" template is missing from the database).'
}
Write-Ok "character '$charName' created on Dawnport tutorial island"
Write-Host "Log in with: $email + your password." -ForegroundColor Green
