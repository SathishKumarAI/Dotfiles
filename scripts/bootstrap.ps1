<#
bootstrap.ps1 — One-shot fresh machine setup
Windows Power Dev Environment

What this does (with permission prompts):
  1. Checks winget is available
  2. Installs all core tools via winget
  3. Fixes User PATH (runs update_user_path_autodetect_suryadeva.ps1)
  4. Configures shell environment (runs env_setup.ps1)
  5. Deploys dotfiles (copies configs to correct locations)

Usage (run from repo root):
  powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1

Flags:
  -DryRun     Show what would happen without making changes
  -SkipApps   Skip the winget install step
  -SkipPath   Skip the PATH fix step
  -SkipEnv    Skip the shell environment setup step
  -SkipDots   Skip deploying dotfiles
#>

param(
    [switch]$DryRun,
    [switch]$SkipApps,
    [switch]$SkipPath,
    [switch]$SkipEnv,
    [switch]$SkipDots
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Write-Step([string]$title) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
}

function Confirm-Step([string]$description) {
    $ans = Read-Host "$description  Proceed? [y/N]"
    return $ans -match "^[Yy]$"
}

function Install-WingetApp([string]$id, [string]$name) {
    Write-Host "  Installing $name ($id)..." -NoNewline
    if ($DryRun) { Write-Host " [DryRun]" -ForegroundColor Yellow; return }
    $result = winget install --id $id --exact --accept-package-agreements --accept-source-agreements 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " MISS (check manually)" -ForegroundColor Yellow
    }
}

# ── Banner ────────────────────────────────────────────────────
Write-Host ""
Write-Host "  Windows Power Dev Environment — Bootstrap" -ForegroundColor Cyan
Write-Host "  GlazeWM · WezTerm · Starship · Zellij · zoxide · Conda · Git" -ForegroundColor DarkGray
if ($DryRun) { Write-Host "  [DRY RUN — no changes will be made]" -ForegroundColor Yellow }
Write-Host ""

# ── Prereq: winget ────────────────────────────────────────────
Write-Step "Checking prerequisites"
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "  ERROR: winget not found." -ForegroundColor Red
    Write-Host "  Install 'App Installer' from the Microsoft Store, then re-run." -ForegroundColor Yellow
    exit 1
}
Write-Host "  winget: OK" -ForegroundColor Green

# ── Step 1: Install core tools ────────────────────────────────
Write-Step "Step 1 of 4 — Install Core Tools"
if ($SkipApps) {
    Write-Host "  Skipped (--SkipApps)"
} elseif (Confirm-Step "Install essential dev tools via winget (GlazeWM, WezTerm, Starship, Zellij, zoxide, Git, Conda).") {
    $apps = @(
        @{ id="Git.Git";               name="Git" },
        @{ id="wez.wezterm";           name="WezTerm" },
        @{ id="Starship.Starship";     name="Starship" },
        @{ id="Zellij.Zellij";         name="Zellij" },
        @{ id="ajeetdsouza.zoxide";    name="zoxide" },
        @{ id="junegunn.fzf";          name="fzf" },
        @{ id="BurntSushi.ripgrep.MSVC"; name="ripgrep" },
        @{ id="sharkdp.fd";            name="fd" },
        @{ id="jqlang.jq";             name="jq" },
        @{ id="JesseDuffield.lazygit"; name="lazygit" },
        @{ id="GitHub.cli";            name="GitHub CLI" },
        @{ id="Microsoft.PowerToys";   name="PowerToys" },
        @{ id="OpenJS.NodeJS.LTS";     name="Node.js LTS" }
    )
    foreach ($app in $apps) {
        Install-WingetApp $app.id $app.name
    }

    # Optional: Conda
    $conda = Read-Host "`n  Install Anaconda3 (~3.5 GB)? [y/N]"
    if ($conda -match "^[Yy]$") {
        Install-WingetApp "Anaconda.Anaconda3" "Anaconda3"
    } else {
        $miniconda = Read-Host "  Install Miniconda3 (lightweight, ~400 MB)? [y/N]"
        if ($miniconda -match "^[Yy]$") {
            Install-WingetApp "Anaconda.Miniconda3" "Miniconda3"
        }
    }
} else {
    Write-Host "  Skipped."
}

# ── Step 2: Fix User PATH ─────────────────────────────────────
Write-Step "Step 2 of 4 — Fix User PATH"
$pathScript = Join-Path $RepoRoot "dotfiles\windows_setup\env_path\update_user_path_autodetect_suryadeva.ps1"
if ($SkipPath) {
    Write-Host "  Skipped (--SkipPath)"
} elseif (Test-Path $pathScript) {
    if (Confirm-Step "Run PATH auto-detect script to add all tool folders to User PATH.") {
        if ($DryRun) {
            Write-Host "  [DryRun] Would run: $pathScript -DryRun"
        } else {
            & $pathScript
        }
    } else {
        Write-Host "  Skipped."
    }
} else {
    Write-Host "  PATH script not found: $pathScript" -ForegroundColor Yellow
}

# ── Step 3: Configure shell environment ──────────────────────
Write-Step "Step 3 of 4 — Shell Environment Setup"
$envScript = Join-Path $RepoRoot "dotfiles\windows_setup\env_setup.ps1"
if ($SkipEnv) {
    Write-Host "  Skipped (--SkipEnv)"
} elseif (Test-Path $envScript) {
    if (Confirm-Step "Run env_setup.ps1 to configure Starship, zoxide, Conda in PowerShell and Git Bash.") {
        if ($DryRun) {
            Write-Host "  [DryRun] Would run: $envScript"
        } else {
            & $envScript
        }
    } else {
        Write-Host "  Skipped."
    }
} else {
    Write-Host "  env_setup.ps1 not found: $envScript" -ForegroundColor Yellow
}

# ── Step 4: Deploy dotfiles ───────────────────────────────────
Write-Step "Step 4 of 4 — Deploy Dotfiles"

$dotfiles = @(
    @{
        src  = Join-Path $RepoRoot "dotfiles\powershell\Microsoft.PowerShell_profile.ps1"
        dst  = $PROFILE
        name = "PowerShell profile"
    },
    @{
        src  = Join-Path $RepoRoot "dotfiles\bash\.bashrc"
        dst  = Join-Path $env:USERPROFILE ".bashrc"
        name = "Git Bash .bashrc"
    },
    @{
        src  = Join-Path $RepoRoot "dotfiles\starship\starship.toml"
        dst  = Join-Path $env:USERPROFILE ".config\starship.toml"
        name = "Starship config"
    },
    @{
        src  = Join-Path $RepoRoot "dotfiles\Zellij\config.kdl"
        dst  = Join-Path $env:USERPROFILE "AppData\Roaming\zellij\config.kdl"
        name = "Zellij config"
    },
    @{
        src  = Join-Path $RepoRoot "dotfiles\glazewm\config.yaml"
        dst  = Join-Path $env:USERPROFILE ".glzr\glazewm\config.yaml"
        name = "GlazeWM config"
    },
    @{
        src  = Join-Path $RepoRoot "dotfiles\wizterm\.wezterm.lua"
        dst  = Join-Path $env:USERPROFILE ".wezterm.lua"
        name = "WezTerm config"
    }
)

if ($SkipDots) {
    Write-Host "  Skipped (--SkipDots)"
} else {
    foreach ($df in $dotfiles) {
        if (-not (Test-Path $df.src)) {
            Write-Host "  SKIP (src missing): $($df.name)" -ForegroundColor DarkGray
            continue
        }

        $exists = Test-Path $df.dst
        $prompt = if ($exists) {
            "Deploy $($df.name) (will backup existing)."
        } else {
            "Deploy $($df.name) (new file)."
        }

        if (Confirm-Step $prompt) {
            if ($DryRun) {
                Write-Host "  [DryRun] $($df.src) -> $($df.dst)"
                continue
            }
            # Backup if file already exists
            if ($exists) {
                $backup = "$($df.dst).bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                Copy-Item $df.dst $backup
                Write-Host "  Backup: $backup" -ForegroundColor DarkGray
            }
            $dstDir = Split-Path $df.dst
            if (-not (Test-Path $dstDir)) {
                New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
            }
            Copy-Item $df.src $df.dst -Force
            Write-Host "  Deployed: $($df.name)" -ForegroundColor Green
        } else {
            Write-Host "  Skipped: $($df.name)"
        }
    }

    # Also deploy Zellij layouts
    $zellijLayoutSrc = Join-Path $RepoRoot "dotfiles\Zellij\layouts"
    $zellijLayoutDst = Join-Path $env:USERPROFILE "AppData\Roaming\zellij\layouts"
    if (Test-Path $zellijLayoutSrc) {
        if (Confirm-Step "Deploy Zellij layouts (dev.kdl) to $zellijLayoutDst.") {
            if (-not $DryRun) {
                New-Item -ItemType Directory -Force -Path $zellijLayoutDst | Out-Null
                Copy-Item "$zellijLayoutSrc\*" $zellijLayoutDst -Recurse -Force
                Write-Host "  Deployed Zellij layouts." -ForegroundColor Green
            } else {
                Write-Host "  [DryRun] Would deploy layouts to $zellijLayoutDst"
            }
        }
    }
}

# ── Done ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host "  Bootstrap complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart all terminals"
Write-Host "  2. Launch GlazeWM (config deployed to ~/.glzr/glazewm/config.yaml)"
Write-Host "  3. Open WezTerm — Starship + zoxide should be active"
Write-Host "  4. Run: z --help    (test zoxide)"
Write-Host "  5. Run: starship --version"
Write-Host ""
Write-Host "To install more apps, run:" -ForegroundColor DarkGray
Write-Host "  python '$RepoRoot\win11 installation files\run.py'" -ForegroundColor DarkGray
