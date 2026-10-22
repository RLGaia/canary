# Mutes the "Light Healing" sound that plays on every hit (client 15.11).
#
# Why: the pinned Canary v3.6.1 server tries "life/mana gain on hit" (Weapon
# Proficiency) after every hit that lands, even when the weapon gives none,
# and each try sends the Light Healing spell sound as a global sound, which
# no sound option in the client can mute. Canary fixed this after v3.6.1
# (WeaponProficiency::applyOn now skips a zero gain and sends no sound), but
# our server program is pinned, so the sound is silenced in the client.
#
# What it changes: in the client's sound data file, the volume of sound
# effect 1001 (Light Healing) becomes 0. Side effect: casting Light Healing
# (exura) is silent too. Nothing else changes. The original file is kept as
# <file>.family-original and -Undo puts it back.
#
# This script needs nothing else from the repository, so it can be copied
# alone to another PC (e.g. a second player's) and run there.
#
# Usage (PowerShell, game client closed):
#     powershell -ExecutionPolicy Bypass -File client-mute-hit-sound.ps1
#     powershell -ExecutionPolicy Bypass -File client-mute-hit-sound.ps1 -ClientPath "D:\Tibia\tibia-client-15.11"
#     powershell -ExecutionPolicy Bypass -File client-mute-hit-sound.ps1 -Undo
#
# After a client update the sound file may be replaced; run it again.

param(
	[string]$ClientPath = '',
	[switch]$Undo
)

$ErrorActionPreference = 'Stop'
$SoundId = 1001  # SOUND_EFFECT_TYPE_SPELL_LIGHT_HEALING

function Write-Step([string]$Text) { Write-Host "==> $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text) { Write-Host "    OK  $Text" -ForegroundColor Green }
function Stop-Script([string]$Text) { Write-Host "ERROR: $Text" -ForegroundColor Red; exit 1 }

# --- find the client's sound data file ---------------------------------------
if (-not $ClientPath) {
	# Where the clients are on the family PCs (Rodrigo's since 2026-10-22), else the manual's default
	foreach ($candidate in @('C:\Games\tibia-client-15.11.c9d1cf\tibia-client-15.11.c9d1cf', 'C:\Games\tibia-client-15.11')) {
		if (Test-Path -LiteralPath ([System.IO.Path]::Combine($candidate, 'sounds', 'catalog-sound.json'))) { $ClientPath = $candidate; break }
	}
	if (-not $ClientPath) { $ClientPath = 'C:\Games\tibia-client-15.11' }
}
while (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($ClientPath, 'sounds', 'catalog-sound.json')))) {
	Write-Host "No game client found in '$ClientPath' (expected a 'sounds' folder with catalog-sound.json)."
	$ClientPath = Read-Host 'Folder of the game client (empty = cancel)'
	if (-not $ClientPath) { exit 1 }
}
$soundsDir = Join-Path $ClientPath 'sounds'
$catalog = Get-Content -Raw -LiteralPath (Join-Path $soundsDir 'catalog-sound.json') | ConvertFrom-Json
$entry = @($catalog | Where-Object { $_.type -eq 'sounds' })[0]
if (-not $entry) { Stop-Script 'catalog-sound.json lists no sound data file.' }
$file = Join-Path $soundsDir $entry.file
if (-not (Test-Path -LiteralPath $file)) { Stop-Script "Sound data file missing: $file" }
$backup = "$file.family-original"

if (Get-Process -Name 'client' -ErrorAction SilentlyContinue) {
	Write-Host '    !!  A program named "client" is running. Close the game client first, then run this again.' -ForegroundColor Yellow
	exit 1
}

# --- undo ---------------------------------------------------------------------
if ($Undo) {
	Write-Step 'Restoring the original sound data'
	if (-not (Test-Path -LiteralPath $backup)) { Stop-Script "No backup found ($backup); nothing to undo." }
	Copy-Item -LiteralPath $backup -Destination $file -Force
	Write-Ok 'Original restored. The Light Healing sound plays again (also on every hit).'
	exit 0
}

# --- protobuf helpers ---------------------------------------------------------
function Read-Varint([byte[]]$B, [ref]$Pos) {
	[uint64]$result = 0
	$shift = 0
	while ($true) {
		$c = $B[$Pos.Value]
		$Pos.Value++
		$result = $result -bor ([uint64]($c -band 0x7F) -shl $shift)
		if ($c -lt 0x80) { return $result }
		$shift += 7
	}
}

# Walks the fields of B[Start..End) and returns @{ Field; Wire; Value; Start; Len }
# (Start/Len = payload of length-delimited and fixed fields).
function Get-Fields([byte[]]$B, [int]$Start, [int]$End) {
	$list = New-Object System.Collections.ArrayList
	$p = $Start
	while ($p -lt $End) {
		$key = Read-Varint $B ([ref]$p)
		$field = [int]($key -shr 3)
		$wire = [int]($key -band 7)
		$item = @{ Field = $field; Wire = $wire; Value = $null; Start = 0; Len = 0 }
		switch ($wire) {
			0 { $item.Value = Read-Varint $B ([ref]$p) }
			1 { $item.Start = $p; $item.Len = 8; $p += 8 }
			2 { $len = [int](Read-Varint $B ([ref]$p)); $item.Start = $p; $item.Len = $len; $p += $len }
			5 { $item.Start = $p; $item.Len = 4; $p += 4 }
			default { throw "Unexpected protobuf wire type $wire at byte $p" }
		}
		[void]$list.Add($item)
	}
	return , $list
}

# --- patch ----------------------------------------------------------------------
Write-Step "Muting sound effect $SoundId (Light Healing) in $($entry.file)"
[byte[]]$bytes = [System.IO.File]::ReadAllBytes($file)

$volumeFloats = $null
$topFields = Get-Fields $bytes 0 $bytes.Length
foreach ($top in $topFields) {
	if ($top.Field -ne 2 -or $top.Wire -ne 2) { continue }  # numeric sound effects
	$inner = Get-Fields $bytes $top.Start ($top.Start + $top.Len)
	$idField = @($inner | Where-Object { $_.Field -eq 1 -and $_.Wire -eq 0 })[0]
	if (-not $idField -or $idField.Value -ne $SoundId) { continue }
	$volume = @($inner | Where-Object { $_.Field -eq 4 -and $_.Wire -eq 2 })[0]
	if (-not $volume) { Stop-Script "Sound effect $SoundId has no volume range; client data not as expected." }
	$volumeFields = Get-Fields $bytes $volume.Start ($volume.Start + $volume.Len)
	$volumeFloats = @($volumeFields | Where-Object { $_.Wire -eq 5 })
	break
}
if (-not $volumeFloats -or $volumeFloats.Count -eq 0) { Stop-Script "Sound effect $SoundId not found; is this client 15.11?" }

$alreadyMuted = $true
foreach ($f in $volumeFloats) {
	if ([System.BitConverter]::ToSingle($bytes, $f.Start) -ne 0) { $alreadyMuted = $false }
}
if ($alreadyMuted) {
	Write-Ok 'Already muted; nothing to do.'
	exit 0
}

if (-not (Test-Path -LiteralPath $backup)) {
	Copy-Item -LiteralPath $file -Destination $backup
	Write-Ok "Original kept as $(Split-Path -Leaf $backup)"
}
foreach ($f in $volumeFloats) {
	for ($i = 0; $i -lt 4; $i++) { $bytes[$f.Start + $i] = 0 }
}
[System.IO.File]::WriteAllBytes($file, $bytes)
Write-Ok 'Muted. Start the game client: hits no longer play the Light Healing sound.'
Write-Host '    If the client refuses to start or complains about its files, run this script with -Undo.'
