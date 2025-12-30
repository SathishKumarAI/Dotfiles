Below is a cleaner, future-proof **README.md** version of your doc, with better structure, less repetition, and a single “source of truth” script section.

---

# 🪟 Windows 11 Dev Shell Setup (SuryaDeva – User PATH Only)

This guide documents how we recovered a broken PATH on Windows 11 and set up a stable dev shell with **Starship** + **zoxide (`z`)**, while **never touching System variables**.

---

## Goals

* ✅ Modify **User PATH only** (SuryaDeva)
* ✅ No overwrite, no duplicates, safe appends
* ✅ Backups + rollback
* ✅ Works with PowerShell + Git Bash + Starship + zoxide
* ❌ No `setx` and no System PATH edits

---

## What Went Wrong (Root Cause)

Running:

```powershell
setx PATH "$env:PATH;..."
```

can **rewrite/truncate** your User PATH. After that:

* Commands disappeared (`winget`, `git`, `zoxide`, etc.)
* `winget list zoxide` showed installed, but `zoxide.exe` shim wasn’t available in PATH until reinstall.

---

## Golden Rules

### ✅ Do

* Use **User scope only**: `[Environment]::SetEnvironmentVariable(..., "User")`
* Backup before changes
* Add only folders that exist
* Restart terminals after changes

### ❌ Don’t

* Never use `setx PATH "$env:PATH;..."` (risk of truncation)
* Avoid touching System PATH unless you truly must

---

## PowerShell Script Execution Setup (One-time)

Allow running local scripts for your user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Verify:

```powershell
Get-ExecutionPolicy -List
```

---

## Quick Health Check Commands

Run anytime:

```powershell
where winget
where git
where python
where conda
where zoxide
z --help
```

---

## Starship Setup

### Enable in PowerShell profile

```powershell
notepad $PROFILE
```

Add:

```powershell
Invoke-Expression (&starship init powershell)
```

### Optional config to avoid scan timeout warnings

```powershell
notepad $env:USERPROFILE\.config\starship.toml
```

Add:

```toml
scan_timeout = 50
add_newline = false
```

---

## zoxide (`z`) Setup

### Install / Repair (this fixed the missing shim)

```powershell
winget uninstall --id ajeetdsouza.zoxide -e
winget install --id ajeetdsouza.zoxide -e
```

Verify:

```powershell
where.exe zoxide
zoxide --version
```

### Enable `z` in PowerShell profile (guarded)

```powershell
notepad $PROFILE
```

Add:

```powershell
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell) })
}
```

Restart PowerShell:

```powershell
z --help
```

---

# ✅ Single Source of Truth: `update_user_path_suryadeva.ps1`

Save this file in a safe folder (example):

```
C:\Users\SuryaDeva\Scripts\update_user_path_suryadeva.ps1
```

## What it does

* Backs up current **User PATH**
* Adds tool paths only if:

  * folder exists
  * not already present
* Auto-picks latest PostgreSQL versions
* Validates with `where.exe`
* Touches **User PATH only** (no System vars)

---

## ✅ Script: `update_user_path_suryadeva.ps1`

```powershell
# =========================================================
# update_user_path_suryadeva.ps1
# USER PATH ONLY – SuryaDeva
# Safe: no overwrite, no duplicates, backup included
# =========================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-UserPath {
    $p = [Environment]::GetEnvironmentVariable("Path", "User")
    if ([string]::IsNullOrWhiteSpace($p)) { return @() }
    return $p -split ";" | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique
}

function Set-UserPath([string[]]$entries) {
    $clean = $entries | Where-Object { $_ } | Select-Object -Unique
    [Environment]::SetEnvironmentVariable("Path", ($clean -join ";"), "User")
}

function Add-UserPath([string]$path) {
    if (-not (Test-Path $path)) {
        Write-Host "Skip (missing): $path"
        return
    }
    $current = Get-UserPath

    # case-insensitive contains check
    $exists = $false
    foreach ($x in $current) {
        if ($x.Equals($path, [System.StringComparison]::OrdinalIgnoreCase)) { $exists = $true; break }
    }

    if (-not $exists) {
        $current += $path
        Set-UserPath $current
        Write-Host "Added: $path"
    } else {
        Write-Host "Exists: $path"
    }
}

function Add-LatestBin($root) {
    if (Test-Path $root) {
        $latest = Get-ChildItem $root -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($latest) { Add-UserPath (Join-Path $latest.FullName "bin") }
    }
}

# -------- Backup USER PATH --------
$backupDir = "$env:USERPROFILE\path_backup"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
(Get-UserPath) -join ";" | Out-File "$backupDir\user_path_$ts.txt"
Write-Host "Backup saved to $backupDir"

# -------- REQUIRED (User scope only) --------
Add-UserPath "$env:USERPROFILE\AppData\Local\Microsoft\WindowsApps"

# -------- Program Files --------
Add-UserPath "C:\Program Files\Git\cmd"
Add-UserPath "C:\Program Files\Emacs\bin"
Add-UserPath "C:\Program Files\nodejs"
Add-UserPath "C:\Program Files\dotnet"
Add-UserPath "C:\Program Files\Docker\Docker\resources\bin"
Add-UserPath "C:\Program Files\GitHub CLI"
Add-UserPath "C:\Program Files\WezTerm"
Add-UserPath "C:\Program Files\Tesseract-OCR"
Add-UserPath "C:\Program Files\Obsidian"
Add-UserPath "C:\Program Files\cursor"
Add-UserPath "C:\Program Files\starship"

# PostgreSQL (64-bit)
Add-LatestBin "C:\Program Files\PostgreSQL"

# -------- Program Files (x86) --------
Add-UserPath "C:\Program Files (x86)\MSBuild\Current\Bin"
Add-UserPath "C:\Program Files (x86)\Microsoft Visual Studio\Installer"

# Windows Kits (x64 tools)
$kits = "C:\Program Files (x86)\Windows Kits\10\bin"
if (Test-Path $kits) {
    $v = Get-ChildItem $kits -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($v) { Add-UserPath (Join-Path $v.FullName "x64") }
}

# PostgreSQL (x86, if any)
Add-LatestBin "C:\Program Files (x86)\PostgreSQL"

# -------- User installs --------
Add-UserPath "C:\Users\SuryaDeva\anaconda3"
Add-UserPath "C:\Users\SuryaDeva\anaconda3\Scripts"
Add-UserPath "C:\Users\SuryaDeva\anaconda3\Library\bin"

Add-UserPath "C:\Users\SuryaDeva\AppData\Local\Programs\Python\Python311"
Add-UserPath "C:\Users\SuryaDeva\AppData\Local\Programs\Python\Python311\Scripts"

# -------- Validation --------
Write-Host "`nValidation:"
$cmds = "winget","git","python","conda","node","npm","dotnet","docker","emacs","psql","msbuild","zoxide"
foreach ($c in $cmds) {
    if (where.exe $c 2>$null) { Write-Host "OK   $c" } else { Write-Host "MISS $c" }
}

Write-Host "`nDone. Close and reopen terminals."
```

---

## Run the Script

From the folder where you saved it:

```powershell
powershell -ExecutionPolicy Bypass -File .\update_user_path_suryadeva.ps1
```

---

## Recommended Folder Layout (for future)

```
C:\Users\SuryaDeva\Scripts\
  ├─ update_user_path_suryadeva.ps1
  ├─ README_windows_shell_setup.md
  └─ path_backup\
```

---

