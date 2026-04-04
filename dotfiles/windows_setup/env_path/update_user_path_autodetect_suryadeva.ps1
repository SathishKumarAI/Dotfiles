<#
update_user_path_autodetect_suryadeva.ps1
USER PATH ONLY — Auto-detect by EXE and add parent folders.

Features:
- User PATH only (no System vars)
- Backup before changes
- Dedupe + case-insensitive compare
- Adds only if folder exists + not already present
- Auto-detect via where.exe first, then common install locations
- -DryRun shows actions without changing PATH
- Asks permission before applying changes
#>

param(
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------- Permission Prompt --------
if (-not $DryRun) {
  $answer = Read-Host "This script will modify your User PATH (no System vars touched). Continue? [y/N]"
  if ($answer -notmatch "^[Yy]$") {
    Write-Host "Aborted. No changes made."
    exit 0
  }
}

function Get-UserPathEntries {
  $p = [Environment]::GetEnvironmentVariable("Path", "User")
  if ([string]::IsNullOrWhiteSpace($p)) { return @() }
  return ($p -split ";") | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique
}

function Set-UserPathEntries([string[]]$entries) {
  $clean = $entries | Where-Object { $_ } | Select-Object -Unique
  if ($DryRun) {
    Write-Host "[DryRun] Would set User PATH with $($clean.Count) entries."
    return
  }
  [Environment]::SetEnvironmentVariable("Path", ($clean -join ";"), "User")
}

function Add-UserPathEntry([string]$dir) {
  if ([string]::IsNullOrWhiteSpace($dir)) { return }
  if (-not (Test-Path -LiteralPath $dir)) {
    Write-Host "Skip (missing dir): $dir"
    return
  }

  $entries = Get-UserPathEntries
  $exists = $false
  foreach ($e in $entries) {
    if ($e.Equals($dir, [System.StringComparison]::OrdinalIgnoreCase)) { $exists = $true; break }
  }

  if ($exists) {
    Write-Host "Exists: $dir"
    return
  }

  Write-Host "Add:    $dir"
  $entries += $dir
  Set-UserPathEntries $entries
}

function Backup-UserPath {
  $backupDir = Join-Path $env:USERPROFILE "path_backup"
  New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $file = Join-Path $backupDir "user_path_$ts.txt"
  (Get-UserPathEntries) -join ";" | Out-File -Encoding UTF8 $file
  Write-Host "Backup: $file"
}

function Resolve-ExeDir([string]$exeName, [string[]]$fallbackPaths) {
  # 1) Prefer existing PATH resolution
  try {
    $w = & where.exe $exeName 2>$null
    if ($LASTEXITCODE -eq 0 -and $w) {
      return (Split-Path -Parent ($w | Select-Object -First 1))
    }
  } catch { }

  # 2) Search common install locations
  foreach ($p in $fallbackPaths) {
    # Expand $env:USERPROFILE in fallback paths
    $expanded = [System.Environment]::ExpandEnvironmentVariables($p)
    if (Test-Path -LiteralPath $expanded) { return (Split-Path -Parent $expanded) }
  }

  return $null
}

# --------- Run ----------
Backup-UserPath

# Always ensure WindowsApps (winget shims) in USER PATH
Add-UserPathEntry (Join-Path $env:USERPROFILE "AppData\Local\Microsoft\WindowsApps")

# Define tools: exeName -> fallback exe locations (uses %USERPROFILE% so it's username-independent)
$tools = @(
  @{ name="git.exe";       fallbacks=@("C:\Program Files\Git\cmd\git.exe", "C:\Program Files\Git\bin\git.exe") },
  @{ name="emacs.exe";     fallbacks=@("C:\Program Files\Emacs\bin\emacs.exe") },
  @{ name="runemacs.exe";  fallbacks=@("C:\Program Files\Emacs\bin\runemacs.exe") },
  @{ name="node.exe";      fallbacks=@("C:\Program Files\nodejs\node.exe") },
  @{ name="npm.cmd";       fallbacks=@("C:\Program Files\nodejs\npm.cmd") },
  @{ name="dotnet.exe";    fallbacks=@("C:\Program Files\dotnet\dotnet.exe") },
  @{ name="docker.exe";    fallbacks=@("C:\Program Files\Docker\Docker\resources\bin\docker.exe") },
  @{ name="gh.exe";        fallbacks=@("C:\Program Files\GitHub CLI\gh.exe") },
  @{ name="starship.exe";  fallbacks=@("C:\Program Files\starship\starship.exe", "%USERPROFILE%\.cargo\bin\starship.exe") },
  @{ name="wezterm.exe";   fallbacks=@("C:\Program Files\WezTerm\wezterm.exe") },
  @{ name="tesseract.exe"; fallbacks=@("C:\Program Files\Tesseract-OCR\tesseract.exe") },
  @{ name="zoxide.exe";    fallbacks=@("%USERPROFILE%\AppData\Local\Microsoft\WindowsApps\zoxide.exe") },
  @{ name="msbuild.exe";   fallbacks=@("C:\Program Files (x86)\MSBuild\Current\Bin\MSBuild.exe") },
  @{ name="conda.exe";     fallbacks=@("%USERPROFILE%\anaconda3\Scripts\conda.exe", "%USERPROFILE%\miniconda3\Scripts\conda.exe") },
  @{ name="python.exe";    fallbacks=@("%USERPROFILE%\AppData\Local\Programs\Python\Python311\python.exe",
                                       "%USERPROFILE%\AppData\Local\Programs\Python\Python312\python.exe") },
  @{ name="psql.exe";      fallbacks=@() },   # handled by PostgreSQL auto-detect below
  @{ name="signtool.exe";  fallbacks=@() }    # handled by Windows Kits auto-detect below
)

foreach ($t in $tools) {
  $dir = Resolve-ExeDir $t.name $t.fallbacks
  if ($dir) { Add-UserPathEntry $dir } else { Write-Host "MISS:  $($t.name)" }
}

# Conda Library\bin (needed for DLL loading)
$condaRoot = $null
foreach ($candidate in @("%USERPROFILE%\anaconda3", "%USERPROFILE%\miniconda3")) {
  $expanded = [System.Environment]::ExpandEnvironmentVariables($candidate)
  if (Test-Path -LiteralPath $expanded) { $condaRoot = $expanded; break }
}
if ($condaRoot) {
  Add-UserPathEntry (Join-Path $condaRoot "Library\bin")
  Add-UserPathEntry $condaRoot
}

# PostgreSQL: pick latest under Program Files and add \bin if psql.exe exists
function Add-LatestPostgresBin([string]$root) {
  if (-not (Test-Path -LiteralPath $root)) { return }
  $latest = Get-ChildItem -LiteralPath $root -Directory | Sort-Object Name -Descending | Select-Object -First 1
  if ($latest) {
    $bin = Join-Path $latest.FullName "bin"
    $psql = Join-Path $bin "psql.exe"
    if (Test-Path -LiteralPath $psql) { Add-UserPathEntry $bin }
  }
}
Add-LatestPostgresBin "C:\Program Files\PostgreSQL"
Add-LatestPostgresBin "C:\Program Files (x86)\PostgreSQL"

# Windows Kits: pick newest version and add x64 if signtool.exe exists
$kits = "C:\Program Files (x86)\Windows Kits\10\bin"
if (Test-Path -LiteralPath $kits) {
  $ver = Get-ChildItem -LiteralPath $kits -Directory | Sort-Object Name -Descending | Select-Object -First 1
  if ($ver) {
    $x64 = Join-Path $ver.FullName "x64"
    $signtool = Join-Path $x64 "signtool.exe"
    if (Test-Path -LiteralPath $signtool) { Add-UserPathEntry $x64 }
  }
}

# Final validation
Write-Host "`nValidation:"
$check = @("winget","git","python","conda","node","npm","dotnet","docker","gh","starship","wezterm","psql","msbuild","zoxide")
foreach ($c in $check) {
  $found = & where.exe $c 2>$null
  if ($LASTEXITCODE -eq 0 -and $found) { Write-Host "OK   $c" } else { Write-Host "MISS $c" }
}

Write-Host "`nDone. Close and reopen all terminals for PATH changes to take effect."
