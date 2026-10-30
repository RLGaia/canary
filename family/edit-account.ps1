# Changes an existing account or its characters, free of charge:
#   - the account login
#   - the account password (also for the @god account)
#   - a character's name
#   - a character's sex (the character gets the basic outfit of the new sex,
#     as with the Store's sex change; outfits already earned are kept)
#   - delete a character (2026-10-30): everything it owns goes with it (items,
#     depot, quests, skills, market offers); a house it owned is emptied and
#     free again; a guild it leads is deleted. To confirm, type its name.
# For the first four, levels, items, houses, guild and VIP lists stay as they are.
#
# The server must be stopped. The database is backed up (backup-db.ps1)
# before the first change.
#
# Usage (PowerShell, from the repository folder):
#     powershell -ExecutionPolicy Bypass -File family\edit-account.ps1

. (Join-Path $PSScriptRoot 'lib.ps1')
$cfg = Read-LocalEnv

$loginPattern = '^[a-z0-9._%+-]+@[a-z0-9.-]+$'
$namePattern = '^[A-Z][a-z]+( [A-Z][a-z]+){0,2}$'

function Confirm-Change([string]$Text) {
	Write-Host "    $Text"
	return ((Read-Host -Prompt 'Apply this change? (Y/N)').Trim().ToUpperInvariant() -eq 'Y')
}

$script:backupDone = $false
function Invoke-BackupOnce {
	if ($script:backupDone) { return }
	& (Join-Path $PSScriptRoot 'backup-db.ps1')
	if ($LASTEXITCODE -ne 0) { Stop-Family 'The backup failed, so nothing was changed.' }
	$script:backupDone = $true
}

function Get-Characters([int]$AccountId) {
	$rows = @(Invoke-MariaDb -Cfg $cfg -Sql "SELECT id, name, level, sex FROM players WHERE account_id = $AccountId ORDER BY name;")
	$list = @()
	foreach ($r in $rows) {
		$f = $r.Split("`t")
		$list += [pscustomobject]@{ Id = [int]$f[0]; Name = $f[1]; Level = [int]$f[2]; Sex = [int]$f[3] }
	}
	return $list
}

function Show-Characters($Chars) {
	if ($Chars.Count -eq 0) { Write-Host '    (no characters)'; return }
	for ($i = 0; $i -lt $Chars.Count; $i++) {
		$sexText = if ($Chars[$i].Sex -eq 1) { 'male' } else { 'female' }
		Write-Host ("    {0}. {1} (level {2}, {3})" -f ($i + 1), $Chars[$i].Name, $Chars[$i].Level, $sexText)
	}
}

function Select-Character($Chars) {
	if ($Chars.Count -eq 0) { Write-Warn 'This account has no characters.'; return $null }
	Show-Characters $Chars
	$answer = (Read-Host -Prompt 'Number of the character').Trim()
	$n = 0
	if (-not [int]::TryParse($answer, [ref]$n) -or $n -lt 1 -or $n -gt $Chars.Count) {
		Write-Warn "Not a number from the list: $answer"
		return $null
	}
	return $Chars[$n - 1]
}

# ---------------------------------------------------------------------------
Write-Step 'Checks'
# ---------------------------------------------------------------------------
if (Get-Process -Name 'canary' -ErrorAction SilentlyContinue) {
	Stop-Family 'The game server is running. Stop it first (log out, Ctrl+C in its window, wait for "Server stopped."), then run this again.'
}
if (-not (Test-DatabaseReady $cfg)) { Stop-Family 'The database is not reachable or not set up. Is the MariaDB service running? Otherwise run family\setup.ps1.' }
Write-Ok 'server stopped, database reachable'

# ---------------------------------------------------------------------------
Write-Step 'Account'
# ---------------------------------------------------------------------------
$login = (Read-Host -Prompt 'Current account login (e.g. player1@server, or @god)').Trim().ToLowerInvariant()
$accountId = Get-SqlScalar $cfg ("SELECT id FROM accounts WHERE email = " + (ConvertTo-SqlString $login) + ";")
if (-not $accountId) { Stop-Family "No account with login $login." }
$accountId = [int]$accountId
Write-Ok "account found: $login"
Show-Characters (Get-Characters $accountId)

while ($true) {
	Write-Host ''
	Write-Host '    What do you want to change?'
	Write-Host '    1. Account login'
	Write-Host '    2. Account password'
	Write-Host "    3. A character's name"
	Write-Host "    4. A character's sex"
	Write-Host '    5. Delete a character'
	Write-Host '    0. Nothing more (finish)'
	$choice = (Read-Host -Prompt 'Choice').Trim()

	switch ($choice) {
		'1' {
			$new = (Read-Host -Prompt 'New login (email-like, does not need to be real)').Trim().ToLowerInvariant()
			if ($new -notmatch $loginPattern -or $new.Length -gt 255) { Write-Warn 'Use an email-like login with letters, digits and @.'; break }
			if ($new -eq $login) { Write-Warn 'That is already the login.'; break }
			if (Get-SqlScalar $cfg ("SELECT id FROM accounts WHERE email = " + (ConvertTo-SqlString $new) + ";")) { Write-Warn "Another account already uses $new."; break }
			if (-not (Confirm-Change "Login: $login -> $new")) { Write-Warn 'Not changed.'; break }
			Invoke-BackupOnce
			$null = Invoke-MariaDb -Cfg $cfg -Sql ("UPDATE accounts SET email = " + (ConvertTo-SqlString $new) + " WHERE id = $accountId;")
			$login = $new
			Write-Ok "login changed. From now on log in with: $login"
		}
		'2' {
			$password = Read-NewPassword 'New password'
			if (-not (Confirm-Change "Password of $login will be replaced.")) { Write-Warn 'Not changed.'; break }
			Invoke-BackupOnce
			$hash = ConvertTo-SqlString (Get-Sha1Hex $password)
			$null = Invoke-MariaDb -Cfg $cfg -Sql "UPDATE accounts SET password = $hash WHERE id = $accountId;"
			Write-Ok 'password changed'
		}
		'3' {
			$char = Select-Character (Get-Characters $accountId)
			if (-not $char) { break }
			$new = (Read-Host -Prompt 'New name (e.g. Ana Silva)').Trim() -replace '\s+', ' '
			if ($new -cnotmatch $namePattern -or $new.Length -lt 3 -or $new.Length -gt 25) {
				Write-Warn 'Use 1-3 words, each starting with a capital letter followed by lowercase letters (3-25 characters).'
				break
			}
			$taken = Get-SqlScalar $cfg ("SELECT id FROM players WHERE name = " + (ConvertTo-SqlString $new) + " AND id <> $($char.Id);")
			if ($taken) { Write-Warn "A character named $new already exists."; break }
			if (-not (Confirm-Change "Name: $($char.Name) -> $new")) { Write-Warn 'Not changed.'; break }
			Invoke-BackupOnce
			$null = Invoke-MariaDb -Cfg $cfg -Sql ("UPDATE players SET name = " + (ConvertTo-SqlString $new) + " WHERE id = $($char.Id);")
			Write-Ok "renamed to $new (if the old name was on a house guest or door list, add the new name there)"
		}
		'4' {
			$char = Select-Character (Get-Characters $accountId)
			if (-not $char) { break }
			if ($char.Sex -eq 1) { $newSex = 0; $lookType = 136; $text = 'male -> female' } else { $newSex = 1; $lookType = 128; $text = 'female -> male' }
			if (-not (Confirm-Change "$($char.Name): $text (basic outfit of the new sex; earned outfits are kept)")) { Write-Warn 'Not changed.'; break }
			Invoke-BackupOnce
			$null = Invoke-MariaDb -Cfg $cfg -Sql "UPDATE players SET sex = $newSex, looktype = $lookType, lookaddons = 0 WHERE id = $($char.Id);"
			Write-Ok "$($char.Name) is now $($text.Split(' ')[-1])"
		}
		'0' {
			Write-Host ''
			Write-Host 'Done. Start the server as usual:' -ForegroundColor Green
			Write-Host '  powershell -ExecutionPolicy Bypass -File family\start-server.ps1'
			Write-Host "Account login: $login"
			Show-Characters (Get-Characters $accountId)
			exit 0
		}
		'5' {
			$char = Select-Character (Get-Characters $accountId)
			if (-not $char) { break }
			$id = $char.Id
			$houses = @(Invoke-MariaDb -Cfg $cfg -Sql "SELECT name FROM houses WHERE owner = $id ORDER BY name;")
			$guild = Get-SqlScalar $cfg "SELECT name FROM guilds WHERE ownerid = $id;"
			Write-Host ''
			Write-Host "    $($char.Name) (level $($char.Level)) will be deleted for good, with its items, depot," -ForegroundColor Yellow
			Write-Host '    quests, skills and market offers. The other characters of this account stay.' -ForegroundColor Yellow
			foreach ($h in $houses) { Write-Host "    House $h will be emptied (the items inside are lost) and become free." -ForegroundColor Yellow }
			if ($guild) { Write-Host "    It leads the guild $guild, which will be deleted too." -ForegroundColor Yellow }
			Write-Host '    The backup made before the first change can bring it back (family\restore-db.ps1).'
			$typed = (Read-Host -Prompt "Type the name $($char.Name) to delete it, or press Enter to cancel").Trim()
			if ($typed -cne $char.Name) { Write-Warn 'Not deleted.'; break }
			Invoke-BackupOnce
			# One transaction: the client stops at the first failing statement and the
			# open transaction is rolled back. Upstream's ondelete_players trigger also
			# sets houses.owner = 0; the cascades remove items, storages, skills, VIP
			# lists, market offers and a guild it owns.
			$houseIds = "SELECT id FROM houses WHERE owner = $id"
			$sql = @(
				'START TRANSACTION;',
				"DELETE FROM tile_store WHERE house_id IN ($houseIds);",
				"DELETE FROM house_lists WHERE house_id IN ($houseIds);",
				"UPDATE houses SET owner = 0, new_owner = -1, paid = 0, warnings = 0, transfer_status = 0 WHERE owner = $id;",
				"UPDATE houses SET new_owner = -1, transfer_status = 0 WHERE new_owner = $id;",
				"UPDATE houses SET bidder = 0, bidder_name = '', highest_bid = 0, internal_bid = 0, bid_end_date = 0, state = 0 WHERE bidder = $id;",
				"DELETE FROM players WHERE id = $id;",
				'COMMIT;'
			) -join "`n"
			try { $null = Invoke-MariaDb -Cfg $cfg -Sql $sql }
			catch { Stop-Family "Nothing was deleted. $($_.Exception.Message)" }
			if (Get-SqlScalar $cfg "SELECT id FROM players WHERE id = $id;") { Stop-Family "$($char.Name) is still there; nothing was deleted." }
			Write-Ok "$($char.Name) deleted"
			Show-Characters (Get-Characters $accountId)
		}
		default { Write-Warn "Type 1, 2, 3, 4, 5 or 0." }
	}
}
