<#
env_setup.ps1
Post-installation environment setup for Windows Power Developer environment.

Configures:
  - PowerShell execution policy
  - Starship prompt initialization
  - zoxide (z) initialization
  - Conda shell integration
  - Git Bash shell initialization (.bashrc)

Rules:
  - Asks permission before every change
  - Never overwrites existing config lines (only appends)
  - Never modifies System environment variables
  - Safe to re-run (idempotent)

Usage:
  powershell -ExecutionPolicy Bypass -File .\env_setup.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -------- Helper: Confirm-Action --------
function Confirm-Action([string]$description) {
  $ans = Read-Host "$description `n  Proceed? [y/N]"
  return $ans -match "^[Yy]$"
}

# -------- Helper: Append to file if line not already present --------
function Add-LineIfMissing([string]$filePath, [string]$line, [string]$context) {
  if (-not (Test-Path $filePath)) {
    New-Item -ItemType File -Force -Path $filePath | Out-Null
    Write-Host "  Created: $filePath"
  }
  $content = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
  if ($content -and $content.Contains($line)) {
    Write-Host "  Already configured: $context"
    return
  }
  Add-Content -Path $filePath -Value "`n# $context`n$line"
  Write-Host "  Added: $context -> $filePath"
}

Write-Host "=== Windows Power Dev Environment Setup ===`n"
Write-Host "This script configures your shell environment after tool installation."
Write-Host "You will be asked before each change. No System vars will be touched.`n"

# =====================================================
# 1. PowerShell Execution Policy
# =====================================================
Write-Host "--- Step 1: PowerShell Execution Policy ---"
$current = Get-ExecutionPolicy -Scope CurrentUser
Write-Host "  Current (CurrentUser): $current"

if ($current -ne "RemoteSigned" -and $current -ne "Unrestricted") {
  if (Confirm-Action "Set ExecutionPolicy to RemoteSigned for CurrentUser (allows local scripts to run).") {
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    Write-Host "  ExecutionPolicy set to RemoteSigned."
  } else {
    Write-Host "  Skipped. Note: local scripts may not run without this."
  }
} else {
  Write-Host "  Already set correctly: $current"
}

# =====================================================
# 2. PowerShell Profile: Starship
# =====================================================
Write-Host "`n--- Step 2: Starship Prompt (PowerShell) ---"
$starshipInstalled = & where.exe starship 2>$null
if (-not ($LASTEXITCODE -eq 0 -and $starshipInstalled)) {
  Write-Host "  starship.exe not found. Install first: winget install Starship.Starship"
} else {
  if (Confirm-Action "Add Starship initialization to your PowerShell profile ($PROFILE).") {
    Add-LineIfMissing $PROFILE 'Invoke-Expression (&starship init powershell)' "Starship prompt"
  } else {
    Write-Host "  Skipped."
  }
}

# =====================================================
# 3. PowerShell Profile: zoxide
# =====================================================
Write-Host "`n--- Step 3: zoxide Navigation (PowerShell) ---"
$zoxideInstalled = & where.exe zoxide 2>$null
if (-not ($LASTEXITCODE -eq 0 -and $zoxideInstalled)) {
  Write-Host "  zoxide.exe not found. Install first: winget install ajeetdsouza.zoxide"
} else {
  if (Confirm-Action "Add zoxide initialization to your PowerShell profile ($PROFILE).`n  This enables the 'z' command for fast directory jumping.") {
    $zoxideLine = 'if (Get-Command zoxide -ErrorAction SilentlyContinue) { Invoke-Expression (& { (zoxide init powershell) }) }'
    Add-LineIfMissing $PROFILE $zoxideLine "zoxide (z command)"
  } else {
    Write-Host "  Skipped."
  }
}

# =====================================================
# 4. Conda Shell Integration (PowerShell)
# =====================================================
Write-Host "`n--- Step 4: Conda Shell Integration (PowerShell) ---"
$condaInstalled = & where.exe conda 2>$null
if (-not ($LASTEXITCODE -eq 0 -and $condaInstalled)) {
  Write-Host "  conda not found in PATH. Install Anaconda/Miniconda first."
  Write-Host "  Miniconda: winget install Anaconda.Miniconda3"
  Write-Host "  Anaconda:  winget install Anaconda.Anaconda3"
} else {
  if (Confirm-Action "Run 'conda init powershell' to enable 'conda activate' in PowerShell.") {
    Write-Host "  Running: conda init powershell"
    & conda init powershell
    Write-Host "  Done. Restart PowerShell to activate Conda integration."
  } else {
    Write-Host "  Skipped."
  }
}

# =====================================================
# 5. Starship Config: Scan Timeout (optional)
# =====================================================
Write-Host "`n--- Step 5: Starship Config (scan_timeout) ---"
$starshipConfig = Join-Path $env:USERPROFILE ".config\starship.toml"
if (Confirm-Action "Add scan_timeout=50 and add_newline=false to Starship config ($starshipConfig).`n  This prevents slow prompts in large repos.") {
  if (-not (Test-Path $starshipConfig)) {
    New-Item -ItemType File -Force -Path $starshipConfig | Out-Null
    Write-Host "  Created: $starshipConfig"
  }
  $cfg = Get-Content $starshipConfig -Raw -ErrorAction SilentlyContinue
  if (-not ($cfg -and $cfg.Contains("scan_timeout"))) {
    Add-Content -Path $starshipConfig -Value "`nscan_timeout = 50`nadd_newline = false"
    Write-Host "  Added scan_timeout and add_newline settings."
  } else {
    Write-Host "  Already configured."
  }
} else {
  Write-Host "  Skipped."
}

# =====================================================
# 6. Git Bash: Starship + zoxide (.bashrc)
# =====================================================
Write-Host "`n--- Step 6: Git Bash Shell Setup (.bashrc) ---"
$bashrc = Join-Path $env:USERPROFILE ".bashrc"

$gitBashExists = Test-Path "C:\Program Files\Git\bin\bash.exe"
if (-not $gitBashExists) {
  Write-Host "  Git Bash not found. Install: winget install Git.Git"
} else {
  # Starship in Git Bash
  if (Confirm-Action "Add Starship initialization to Git Bash (~/.bashrc).") {
    Add-LineIfMissing $bashrc 'eval "$(starship init bash)"' "Starship prompt"
  } else {
    Write-Host "  Skipped Starship for Git Bash."
  }

  # zoxide in Git Bash
  if (Confirm-Action "Add zoxide initialization to Git Bash (~/.bashrc). Enables 'z' command.") {
    Add-LineIfMissing $bashrc 'eval "$(zoxide init bash)"' "zoxide (z command)"
  } else {
    Write-Host "  Skipped zoxide for Git Bash."
  }

  # Conda in Git Bash
  if ($condaInstalled) {
    if (Confirm-Action "Run 'conda init bash' for Git Bash support.") {
      Write-Host "  Running: conda init bash"
      & conda init bash
      Write-Host "  Done. Restart Git Bash to activate."
    } else {
      Write-Host "  Skipped Conda for Git Bash."
    }
  }
}

# =====================================================
# Summary
# =====================================================
Write-Host "`n=== Setup Complete ===`n"
Write-Host "Next steps:"
Write-Host "  1. Close and reopen all terminals (PowerShell and Git Bash)"
Write-Host "  2. Run: z --help        (test zoxide)"
Write-Host "  3. Run: starship --version  (test Starship)"
Write-Host "  4. Run: conda --version     (test Conda)"
Write-Host ""
Write-Host "Health check commands:"
Write-Host "  where winget; where git; where python; where conda; where zoxide; where starship"
