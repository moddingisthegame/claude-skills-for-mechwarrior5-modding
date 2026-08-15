<#
.SYNOPSIS
  Snapshot of a running MW5 Mercs Mod Editor session. Written for Claude to
  read, not for a human dashboard: terse key=value lines, no decoration.

.DESCRIPTION
  Answers, in one call: is the editor up, is it still busy compiling, what
  map is loaded, does a mod plugin exist yet, and has anything gone wrong
  since the last check.

  Repeat runs report only NEW log lines. A state file records how far the
  log was read last time; a shrunken log (editor restarted) resets it
  automatically. This makes the script safe to run on a /loop interval
  without re-reporting the same warnings every time.

  Known-benign log noise is SUPPRESSED by design -- see $Benign below. The
  suppression list is the point of the script: without it every run buries
  a real problem under dozens of known-harmless missing-VFX warnings. When
  a warning family is investigated and cleared, add it to $Benign so it
  stops consuming attention.

.PARAMETER Full
  Ignore saved state; report against the whole log.

.PARAMETER Reset
  Re-baseline to the current end of log and exit without reporting.

.PARAMETER ShowBenign
  Include suppressed lines in the output (for triaging the filter itself).

.PARAMETER EditorRoot
  Mod Editor install root. Defaults to the standard Epic Games Launcher
  location under Program Files. Epic Games lets you install to any drive, so
  pass -EditorRoot explicitly if yours isn't there.
#>
[CmdletBinding()]
param(
    [switch]$Full,
    [switch]$Reset,
    [switch]$ShowBenign,
    [string]$EditorRoot = (Join-Path ${env:ProgramFiles} 'Epic Games\MechWarrior5Editor')
)

$ErrorActionPreference = 'Stop'

# --- Known-benign log noise -------------------------------------------------
# Regexes matched against whole log lines. Anything matching is counted but
# not shown. Each entry MUST carry a note saying why it was cleared, so a
# future session can tell "investigated, harmless" from "someone silenced a
# real bug".
$Benign = @(
    @{ Pattern = 'ExplosionsMegaPack'
       Why     = 'Stock VFX content pack absent from the editor install. Footstep/impact/debris assets reference it and log "Can''t find file". Cosmetic; does not block work or packaging.' }

    @{ Pattern = 'Device ShareSet not found in Init bank'
       Why     = 'Wwise audio-device complaint at editor startup. Routine in-editor; audio still authorable.' }

    @{ Pattern = 'EditorValidator_Localization did not include a pass or fail state|ValidatorPair\.Value->IsValidationStateSet'
       Why     = 'Engine DataValidation ensure in stock UE4.23 EditorValidatorSubsystem.cpp:164. Handled (non-fatal), fires on asset save, nothing to do with mod content. Named specifically so OTHER ensures still surface.' }

    @{ Pattern = '\[Callstack\] 0x|LogOutputDevice: Error:\s*$|LogOutputDevice: Error: Stack:|LogOutputDevice: Error: === Handled ensure: ==='
       Why     = 'Scaffolding lines of a handled-ensure block: blank line, "Stack:", and callstack frames. Carry no information alone and flood the snapshot (~70 lines per ensure). The meaningful "Ensure condition failed: <cond>" line is NOT suppressed, so a new ensure still shows up.' }

    @{ Pattern = 'derived data cache for the texture .* was invalid'
       Why     = 'Cold/stale DDC. The editor rebuilds the texture automatically and moves on. Expect a burst after first launch or a DDC wipe; self-healing.' }

    @{ Pattern = '/Wwise/Wwise(Tree|Types)/'
       Why     = 'Missing Wwise plugin editor-UI resources (toolbar icons, AkAcousticTexture/AkAuxBus/spatial-audio type thumbnails). Cosmetic only -- the Wwise integration itself works; these are Content Browser icons. Does NOT cover soundbank or AkEvent load failures, which would be real.' }
)

# Stock plugins shipped with the editor. Anything in Plugins/ NOT on this
# list is a user mod -- that is the signal we actually want.
$StockPlugins = @(
    'ChromaSDKPlugin','VictoryPlugin','UE4Duino','OnlineSubsystemEpic',
    'OceanPlugin','MWShaders','LowEntryJson','ImpostorBaker-master',
    'Igor','DialoguePlugin'
)

$LogPath   = Join-Path $env:LOCALAPPDATA 'MW5Mercs\Saved\Logs\MW5Mercs.log'
$StatePath = Join-Path $env:TEMP 'mw5-editor-status.state'
$out       = [System.Collections.Generic.List[string]]::new()
function Emit([string]$k, [string]$v) { $out.Add(("{0,-9}{1}" -f $k, $v)) }

# --- Editor process ---------------------------------------------------------
$proc = Get-Process -Name 'UE4Editor' -ErrorAction SilentlyContinue |
        Sort-Object StartTime | Select-Object -First 1

if ($proc) {
    $up = (Get-Date) - $proc.StartTime
    Emit 'EDITOR' ("running  pid={0}  up={1}h{2:d2}m  ram={3}MB" -f `
        $proc.Id, [int]$up.TotalHours, $up.Minutes, [int]($proc.WorkingSet64 / 1MB))
} else {
    Emit 'EDITOR' 'NOT RUNNING'
}

# --- Log presence and freshness ---------------------------------------------
if (-not (Test-Path $LogPath)) {
    Emit 'LOG' "MISSING at $LogPath"
    $out -join "`n"
    return
}

$logInfo = Get-Item $LogPath
$ageSec  = [int]((Get-Date) - $logInfo.LastWriteTime).TotalSeconds
$state   = if ($ageSec -lt 15) { 'ACTIVE' } elseif ($ageSec -lt 120) { 'settling' } else { 'idle' }
Emit 'LOG' ("{0}KB  updated {1}s ago  ({2})" -f [int]($logInfo.Length / 1KB), $ageSec, $state)

$lines = Get-Content $LogPath
$total = $lines.Count

# --- State / baseline -------------------------------------------------------
$last = 0
if (Test-Path $StatePath) {
    $saved = Get-Content $StatePath -Raw | ConvertFrom-Json
    if ($saved.total -le $total) { $last = [int]$saved.total }  # shrank => restart => reset
}
if ($Full) { $last = 0 }

if ($Reset) {
    @{ total = $total } | ConvertTo-Json | Set-Content $StatePath
    "BASELINE set at $total lines"
    return
}

# Order matters: $last -ge $total means nothing new (NOT "report everything").
$new = if ($last -ge $total)  { @() }
       elseif ($last -gt 0)   { $lines | Select-Object -Skip $last }
       else                   { $lines }
Emit 'NEW' ("+{0} lines since last check (log total {1})" -f $new.Count, $total)

# --- Busy state -------------------------------------------------------------
$shader = $lines | Select-String 'shaders left to compile (\d+)' | Select-Object -Last 1
$busy = @()
if ($shader) { $busy += "shaders_left=$($shader.Matches[0].Groups[1].Value)" }
if ($lines | Select-Object -Last 40 | Select-String 'LogTexture: Display: Building textures') {
    $busy += 'building_textures'
}
Emit 'BUSY' $(if ($busy) { $busy -join '  ' } else { 'idle' })

# --- Loaded map -------------------------------------------------------------
$map = $lines | Select-String "Loading map '([^']+)' took ([\d.]+)" | Select-Object -Last 1
if ($map) {
    Emit 'MAP' ("{0}  (load {1}s)" -f $map.Matches[0].Groups[1].Value, $map.Matches[0].Groups[2].Value)
} else {
    Emit 'MAP' 'none loaded yet'
}

# --- Mod state --------------------------------------------------------------
$pluginDir = Join-Path $EditorRoot 'MW5Mercs\Plugins'
$modPlugins = @()
if (Test-Path $pluginDir) {
    $modPlugins = (Get-ChildItem $pluginDir -Directory).Name | Where-Object { $_ -notin $StockPlugins }
}
$modText = if ($modPlugins) { "plugins: $($modPlugins -join ', ')" } else { 'plugins: none (stock only)' }

$modListPath = Join-Path $EditorRoot 'MW5Mercs\Mods\modlist.json'
if (Test-Path $modListPath) {
    $ml = Get-Content $modListPath -Raw | ConvertFrom-Json
    $enabled = @($ml.modStatus.PSObject.Properties).Count
    $modText += "   modlist: $enabled entries  gameVersion=$($ml.gameVersion)"
}
Emit 'MODS' $modText

# --- Errors and warnings ----------------------------------------------------
function Split-Benign([object[]]$candidates) {
    $keep = @(); $hid = 0
    foreach ($c in $candidates) {
        $line = "$c"
        if ($Benign | Where-Object { $line -match $_.Pattern }) {
            if ($ShowBenign) { $keep += $line } else { $hid++ }
        } else { $keep += $line }
    }
    @{ Keep = $keep; Hidden = $hid }
}

foreach ($sev in @('Error', 'Warning')) {
    $newHits   = Split-Benign ($new   | Select-String ": ${sev}:")
    $totalHits = Split-Benign ($lines | Select-String ": ${sev}:")

    Emit $sev.ToUpper() ("{0} new / {1} total  ({2} known-benign suppressed)" -f `
        $newHits.Keep.Count, $totalHits.Keep.Count, $totalHits.Hidden)

    # Distinct so one repeated failure does not flood the snapshot.
    foreach ($l in ($newHits.Keep | Select-Object -Unique | Select-Object -First 8)) {
        $out.Add('  | ' + ($l -replace '^\[[^\]]+\]\[[^\]]+\]', '').Trim())
    }
}

@{ total = $total } | ConvertTo-Json | Set-Content $StatePath
$out -join "`n"
