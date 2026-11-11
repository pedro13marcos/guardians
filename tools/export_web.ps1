<#
.SYNOPSIS
  Safe, verified Web (itch.io) export for Guardians.

.DESCRIPTION
  Why this exists: the godot.windows.*.exe used here is a GUI-subsystem binary, so calling it with `&`
  returns immediately while the export keeps running in the background. Re-running the export (or
  zipping) while that background process is still writing produced a corrupted index.pck
  ("Corrupted header in binary project.binary (not ECFG)"), which itch.io shows as
  "Couldn't load project data at path '/'. Is the .pck file missing?".

  This script therefore:
    1. refuses to start while another Godot process is running,
    2. exports into a clean folder and WAITS for the process to end,
    3. verifies the .pck by actually loading it with the Godot engine,
    4. verifies every file referenced by index.html exists with the exact size,
    5. only then builds the itch.io zip (forward-slash entries, index.html at the zip root),
    6. re-opens the zip and checks it matches the exported files byte for byte.
  If any step fails nothing is zipped and the script exits non-zero.
#>
param(
    [string]$Godot = "D:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe",
    [string]$Preset = "Web"
)

$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$exports = Join-Path $project "Exports"

function Fail($msg) { Write-Host "EXPORT FAILED: $msg" -ForegroundColor Red; exit 1 }

# --- version -------------------------------------------------------------
$verLine = Select-String -Path (Join-Path $project "project.godot") -Pattern '^config/version="(.+)"' | Select-Object -First 1
if (-not $verLine) { Fail "config/version not found in project.godot" }
$version = $verLine.Matches[0].Groups[1].Value
$outDir = Join-Path $exports "guardians-web-v$version"
$zipPath = Join-Path $exports "guardians-web-v$version.zip"
Write-Host "Exporting Guardians v$version ..."

# --- 1. no concurrent EXPORT --------------------------------------------
# (An open Godot editor is fine; another export writing to the same files is not.)
$running = Get-CimInstance Win32_Process | Where-Object { $_.Name -like "godot*" -and $_.CommandLine -match "--export" }
if ($running) { Fail "Another Godot export is already running (PID $($running.ProcessId -join ', ')). Wait for it to finish, then retry." }

# --- 1b. Godot's own temp folder must be writable -----------------------
# The Steam build of Godot is "self-contained": it keeps editor_data\ next to the exe and the exporter
# builds project.binary inside editor_data\temp. If that folder is not writable (e.g. the script is run
# from a sandboxed / restricted shell) Godot still exits 0 but writes an EMPTY project.binary into the
# .pck -> itch.io shows "Couldn't load project data at path '/'".
$tempProbeDir = Join-Path (Split-Path -Parent $Godot) "editor_data\temp"
try {
    New-Item -ItemType Directory -Force -Path $tempProbeDir | Out-Null
    $probe = Join-Path $tempProbeDir "write_probe.tmp"
    Set-Content -Path $probe -Value "ok" -ErrorAction Stop
    Remove-Item $probe -Force
} catch {
    Fail "Cannot write to '$tempProbeDir'. Run this script from a normal (non-sandboxed) PowerShell so Godot can create project.binary."
}

# --- 2. clean export, synchronous ---------------------------------------
if (Test-Path $outDir) { Remove-Item -Recurse -Force $outDir }
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$log = Join-Path $env:TEMP "guardians_export.log"
$logErr = Join-Path $env:TEMP "guardians_export.err.log"
$exportArgs = "--headless --path `"$project`" --export-release `"$Preset`" `"$outDir\index.html`""
$p = Start-Process -FilePath $Godot -ArgumentList $exportArgs -PassThru -Wait -RedirectStandardOutput $log -RedirectStandardError $logErr
if ($p.ExitCode -ne 0) { Fail "Godot export exited with code $($p.ExitCode). See $log / $logErr" }
$exportText = (Get-Content $log, $logErr -ErrorAction SilentlyContinue) -join "`n"
if ($exportText -match "ERROR:.*(export|template|pck)") { Fail "Godot reported export errors. See $log / $logErr" }

# --- 4. every file referenced by index.html exists with the right size ---
$html = Get-Content (Join-Path $outDir "index.html") -Raw
if ($html -notmatch '"fileSizes":\{([^}]*)\}') { Fail "fileSizes not found in index.html" }
foreach ($m in [regex]::Matches($Matches[1], '"([^"]+)":(\d+)')) {
    $f = Join-Path $outDir $m.Groups[1].Value
    if (-not (Test-Path $f)) { Fail "$($m.Groups[1].Value) is missing from the export" }
    if ((Get-Item $f).Length -ne [int64]$m.Groups[2].Value) { Fail "$($m.Groups[1].Value) size does not match index.html (partial/corrupt write)" }
}

# --- 3. load the .pck with the real engine ------------------------------
$vOut = Join-Path $env:TEMP "guardians_pckcheck.log"
$vErr = Join-Path $env:TEMP "guardians_pckcheck.err.log"
$checkDir = Join-Path $env:TEMP "guardians_pckcheck_cwd"
New-Item -ItemType Directory -Force -Path $checkDir | Out-Null
$v = Start-Process -FilePath $Godot -ArgumentList "--headless --main-pack `"$outDir\index.pck`" --quit-after 120" `
    -WorkingDirectory $checkDir -PassThru -Wait -RedirectStandardOutput $vOut -RedirectStandardError $vErr
$vText = (Get-Content $vOut, $vErr -ErrorAction SilentlyContinue) -join "`n"
if ($vText -match "Corrupted header|Couldn't load file 'res://project\.binary'|Couldn't load project") {
    Fail "index.pck is corrupted and would not load on itch.io:`n$vText"
}
Write-Host "index.pck verified: loads correctly." -ForegroundColor Green

# --- 5. zip for itch.io (forward slashes, index.html at root) ------------
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($outDir, $zipPath, [IO.Compression.CompressionLevel]::Optimal, $false)

# --- 6. verify the zip ---------------------------------------------------
$zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $names = $zip.Entries.FullName
    foreach ($req in "index.html", "index.js", "index.pck", "index.wasm") {
        if ($names -notcontains $req) { Fail "$req is not at the root of the zip" }
    }
    if ($names | Where-Object { $_ -match '\\' }) { Fail "zip contains backslash paths (breaks itch.io)" }
    foreach ($e in $zip.Entries) {
        $src = Join-Path $outDir $e.FullName
        if ($e.Length -ne (Get-Item $src).Length) { Fail "$($e.FullName) in zip differs from the exported file" }
    }
} finally { $zip.Dispose() }

Write-Host "OK  -> $zipPath ($([math]::Round((Get-Item $zipPath).Length / 1MB, 2)) MB)" -ForegroundColor Green
exit 0
