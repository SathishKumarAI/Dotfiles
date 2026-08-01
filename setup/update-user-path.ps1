<#
update-user-path.ps1
USER PATH ONLY - Auto-detect tools by EXE and add their parent folders.

Features:
- User PATH only (no System vars)
- Backup before changes
- Dedupe + case-insensitive compare
- Adds only if folder exists + not already present
- Auto-detect via where.exe first, then common install locations
- -DryRun shows actions without changing PATH

Run:
    powershell -ExecutionPolicy Bypass -File .\update-user-path.ps1 -DryRun
    powershell -ExecutionPolicy Bypass -File .\update-user-path.ps1
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
  # 1) Prefer existing PATH resolution.
  #    Get-Command, not `where.exe ... 2>$null`: on Windows PowerShell 5.1,
  #    redirecting a native command's stderr wraps it in a NativeCommandError,
  #    which throws under $ErrorActionPreference = "Stop".
  #    -CommandType Application: a loaded profile can shadow a tool's name with
  #    a function (mise does), and a function has no .Source to take a folder from.
  $cmd = Get-Command $exeName -CommandType Application -ErrorAction SilentlyContinue |
         Select-Object -First 1
  if ($cmd -and $cmd.Source) { return (Split-Path -Parent $cmd.Source) }

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
# scoop shims, if scoop is used
Add-UserPathEntry (Join-Path $env:USERPROFILE "scoop\shims")

# Tools to detect: exeName -> fallback exe locations (parent folder gets added)
$tools = @(
  @{ name="git.exe";      fallbacks=@("C:\Program Files\Git\cmd\git.exe", "C:\Program Files\Git\bin\git.exe") },
  @{ name="node.exe";     fallbacks=@("C:\Program Files\nodejs\node.exe") },
  @{ name="npm.cmd";      fallbacks=@("C:\Program Files\nodejs\npm.cmd") },
  @{ name="dotnet.exe";   fallbacks=@("C:\Program Files\dotnet\dotnet.exe") },
  @{ name="docker.exe";   fallbacks=@("C:\Program Files\Docker\Docker\resources\bin\docker.exe") },
  @{ name="gh.exe";       fallbacks=@("C:\Program Files\GitHub CLI\gh.exe") },
  @{ name="starship.exe"; fallbacks=@("C:\Program Files\starship\starship.exe") },
  @{ name="wezterm.exe";  fallbacks=@("C:\Program Files\WezTerm\wezterm.exe") },
  @{ name="nvim.exe";     fallbacks=@("C:\Program Files\Neovim\bin\nvim.exe") },
  @{ name="mise.exe";     fallbacks=@() },
  @{ name="chezmoi.exe";  fallbacks=@() },
  @{ name="conda.exe";    fallbacks=@("$env:USERPROFILE\miniforge3\Scripts\conda.exe", "$env:USERPROFILE\anaconda3\Scripts\conda.exe") },
  @{ name="python.exe";   fallbacks=@() },
  @{ name="zoxide.exe";   fallbacks=@() },
  # Tesseract's installer does not touch PATH, so `tesseract` stays unresolvable
  # after a successful winget install unless this adds it.
  @{ name="tesseract.exe"; fallbacks=@("C:\Program Files\Tesseract-OCR\tesseract.exe", "C:\Program Files (x86)\Tesseract-OCR\tesseract.exe") },
  # GNU.Wget2 ships the binary as wget2.exe - there is no `wget` on this box.
  @{ name="wget2.exe";    fallbacks=@() }
)

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

# Final validation
Write-Host "`nValidation:"
$check = @("winget","scoop","git","python","conda","node","npm","docker","gh","starship","wezterm","nvim","mise","chezmoi","zoxide","uv","pandoc","tesseract","wget2")
foreach ($c in $check) {
  # Same reason as Resolve-ExeDir: never redirect a native command's stderr here.
  if (Get-Command $c -ErrorAction SilentlyContinue) { Write-Host "OK   $c" } else { Write-Host "MISS $c" }
}

Write-Host "`nDone. Close and reopen terminals."
