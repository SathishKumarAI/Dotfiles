Below is the **auto-detect USER-PATH script** you asked for: it **finds tools by EXE**, adds only the **correct parent folders**, **no duplicates**, **backs up first**, and supports **Dry-Run**.

Save as: **`update_user_path_autodetect_suryadeva.ps1`**

```powershell
<#
update_user_path_autodetect_suryadeva.ps1
USER PATH ONLY (SuryaDeva) — Auto-detect by EXE and add parent folders.

Features:
- User PATH only (no System vars)
- Backup before changes
- Dedupe + case-insensitive compare
- Adds only if folder exists + not already present
- Auto-detect via where.exe first, then common install locations
- -DryRun shows actions without changing PATH
#>

param(
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-UserPathEntries {
  $p = [Environment]::GetEnvironmentVariable("Path","User")
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
      # choose first hit
      return (Split-Path -Parent ($w | Select-Object -First 1))
    }
  } catch { }

  # 2) Search common install locations
  foreach ($p in $fallbackPaths) {
    if (Test-Path -LiteralPath $p) { return (Split-Path -Parent $p) }
  }

  return $null
}

# --------- Run ----------
Backup-UserPath

# Always ensure WindowsApps (winget shims) in USER PATH
Add-UserPathEntry (Join-Path $env:USERPROFILE "AppData\Local\Microsoft\WindowsApps")

# Define tools to detect: exeName -> fallback exe locations (add parent folder)
$tools = @(
  @{ name="git.exe";      fallbacks=@("C:\Program Files\Git\cmd\git.exe", "C:\Program Files\Git\bin\git.exe") },
  @{ name="emacs.exe";    fallbacks=@("C:\Program Files\Emacs\bin\emacs.exe") },
  @{ name="runemacs.exe"; fallbacks=@("C:\Program Files\Emacs\bin\runemacs.exe") },
  @{ name="node.exe";     fallbacks=@("C:\Program Files\nodejs\node.exe") },
  @{ name="npm.cmd";      fallbacks=@("C:\Program Files\nodejs\npm.cmd") },
  @{ name="dotnet.exe";   fallbacks=@("C:\Program Files\dotnet\dotnet.exe") },
  @{ name="docker.exe";   fallbacks=@("C:\Program Files\Docker\Docker\resources\bin\docker.exe") },
  @{ name="gh.exe";       fallbacks=@("C:\Program Files\GitHub CLI\gh.exe") },
  @{ name="starship.exe"; fallbacks=@("C:\Program Files\starship\starship.exe") },
  @{ name="wezterm.exe";  fallbacks=@("C:\Program Files\WezTerm\wezterm.exe") },
  @{ name="tesseract.exe";fallbacks=@("C:\Program Files\Tesseract-OCR\tesseract.exe") },
  @{ name="psql.exe";     fallbacks=@() }, # handled by PostgreSQL auto-detect below
  @{ name="msbuild.exe";  fallbacks=@("C:\Program Files (x86)\MSBuild\Current\Bin\MSBuild.exe") },
  @{ name="signtool.exe"; fallbacks=@() }, # handled by Windows Kits auto-detect below
  @{ name="conda.exe";    fallbacks=@("C:\Users\SuryaDeva\anaconda3\Scripts\conda.exe") },
  @{ name="python.exe";   fallbacks=@("C:\Users\SuryaDeva\AppData\Local\Programs\Python\Python311\python.exe") },
  @{ name="zoxide.exe";   fallbacks=@() }  # should resolve after winget reinstall
)

# Tool-by-tool detection
foreach ($t in $tools) {
  $dir = Resolve-ExeDir $t.name $t.fallbacks
  if ($dir) { Add-UserPathEntry $dir } else { Write-Host "MISS:  $($t.name)" }
}

# PostgreSQL: pick latest under Program Files / (x86) and add \bin if psql.exe exists
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
$check = @("winget","git","python","conda","node","npm","dotnet","docker","gh","starship","emacs","psql","msbuild","signtool","zoxide")
foreach ($c in $check) {
  if (& where.exe $c 2>$null) { Write-Host "OK   $c" } else { Write-Host "MISS $c" }
}

Write-Host "`nDone. Close and reopen terminals."
```

### Run it

**Dry run (no changes):**

```powershell
powershell -ExecutionPolicy Bypass -File .\update_user_path_autodetect_suryadeva.ps1 -DryRun
```

**Apply changes:**

```powershell
powershell -ExecutionPolicy Bypass -File .\update_user_path_autodetect_suryadeva.ps1
```

If you want, I can also add an option like `-Only "git,python,zoxide"` to update just a subset.
