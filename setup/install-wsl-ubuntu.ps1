<#
install-wsl-ubuntu.ps1 - WSL2 + Ubuntu, so every Linux script in this repo runs
natively on the Windows box, with GPU passthrough for ML work.

  !! THIS SCRIPT NEVER INSTALLS, UPDATES, OR MODIFIES GPU DRIVERS. !!
  This is also NVIDIA's own rule for WSL2: the Windows driver already projects
  the GPU into the distro via /usr/lib/wsl/lib. Installing a Linux NVIDIA
  driver *inside* Ubuntu overwrites those stubs and breaks CUDA. If you later
  add the CUDA toolkit in WSL, use the 'wsl-ubuntu' repo variant, which ships
  the toolkit WITHOUT a driver. Nothing here touches any of that.

Requires: an elevated PowerShell for the WSL feature install (Windows will say
so if it needs it). Everything after that is user-scope.

Usage:
  powershell -ExecutionPolicy Bypass -File .\install-wsl-ubuntu.ps1 -DryRun
  powershell -ExecutionPolicy Bypass -File .\install-wsl-ubuntu.ps1
  powershell -ExecutionPolicy Bypass -File .\install-wsl-ubuntu.ps1 -Distro Ubuntu-24.04
#>

param(
  [switch]$DryRun,
  [string]$Distro = "Ubuntu"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$global:LASTEXITCODE = 0
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($msg) { Write-Host "`n== $msg ==" -ForegroundColor Magenta }
function Note($msg) { Write-Host "   $msg" -ForegroundColor DarkGray }
function Warn($msg) { Write-Host "   ! $msg" -ForegroundColor Yellow }

function Test-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Host "=== WSL2 + $Distro ===" -ForegroundColor Cyan

Step "Preconditions"
if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
  Warn "wsl.exe not found - this needs Windows 10 2004+ / Windows 11."
  exit 1
}
Note "wsl.exe: present"
if (Test-Admin) { Note "elevated: yes" } else { Warn "not elevated - 'wsl --install' may prompt or fail; re-run as Administrator if so" }

Step "Virtualization preconditions"
# wsl --status says "virtualization is not enabled on this machine" for BOTH
# causes: firmware SVM/VT-x off, AND the Windows optional component missing.
# They need completely different fixes, so distinguish them here rather than
# sending anyone into their UEFI unnecessarily.
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$firmwareOk = [bool]$cpu.VirtualizationFirmwareEnabled
if ($firmwareOk) {
  Note "firmware virtualization (SVM / VT-x): enabled"
} else {
  Warn "firmware virtualization is DISABLED in your BIOS/UEFI."
  Warn "Reboot into firmware setup and enable 'SVM Mode' (AMD) or 'Intel VT-x'."
  Warn "No amount of elevation fixes this one - it is a firmware switch."
  exit 1
}
$wslStatus = (& wsl.exe --status 2>&1 | Out-String) -replace "`0",""
if ($wslStatus -match "not enabled|optional component") {
  Warn "The Windows 'Virtual Machine Platform' component is not enabled yet."
  Warn "Firmware is fine - this is a Windows feature and needs ADMIN + a reboot:"
  Write-Host "     wsl --install --no-distribution" -ForegroundColor Cyan
  Warn "Run that in an elevated PowerShell, reboot, then re-run this script."
  exit 1
}

Step "Existing distributions"
$existing = & wsl.exe --list --quiet 2>$null
if ($LASTEXITCODE -eq 0 -and $existing) {
  # wsl.exe emits UTF-16; strip nulls so the match works.
  $clean = ($existing -join "`n") -replace "`0", ""
  Note "installed: $(($clean -split "`n" | Where-Object { $_.Trim() }) -join ', ')"
  if ($clean -match [regex]::Escape($Distro)) {
    Note "$Distro already installed - skipping install, continuing to config."
    $alreadyThere = $true
  } else { $alreadyThere = $false }
} else {
  Note "no distributions installed yet"
  $alreadyThere = $false
}

Step "WSL2 default version"
if ($DryRun) { Write-Host "[DryRun] wsl --set-default-version 2" }
else { & wsl.exe --set-default-version 2 2>$null | Out-Null; Note "default version -> 2" }

Step "Install $Distro"
if ($alreadyThere) {
  Note "already present"
} elseif ($DryRun) {
  Write-Host "[DryRun] wsl --install -d $Distro"
} else {
  Note "Installing with --no-launch so this stays non-interactive."
  Note "Afterwards run: wsl -d $Distro   to create your UNIX user."
  & wsl.exe --install -d $Distro --no-launch
  if ($LASTEXITCODE -ne 0) {
    Warn "wsl --install returned $LASTEXITCODE"
    Warn "If it asked for a reboot, reboot and re-run this script."
    exit $LASTEXITCODE
  }
}

Step "Bootstrap script for inside the distro"
$bootstrap = Join-Path $Here "wsl\bootstrap-wsl.sh"
if (Test-Path -LiteralPath $bootstrap) {
  # \\wsl$ paths work, but running from the Windows-mounted path is simplest.
  $wslPath = (& wsl.exe wslpath -a ($bootstrap -replace '\\','/') 2>$null)
  Note "run this INSIDE Ubuntu once your user exists:"
  if ($wslPath) { Write-Host "     bash $wslPath" -ForegroundColor Cyan }
  else { Write-Host "     bash setup/wsl/bootstrap-wsl.sh   (from the repo, inside WSL)" -ForegroundColor Cyan }
} else {
  Warn "missing: $bootstrap"
}

Write-Host "`n== Done ==" -ForegroundColor Green
@"
What you get:
  * Every Linux script in setup/ runs natively (setup.sh, install-modern-cli.sh, ...)
  * CUDA passthrough to the RTX GPU with NO driver install inside Ubuntu
  * Docker Desktop can use the WSL2 backend

Verify GPU passthrough after bootstrap:
  wsl -d $Distro -- nvidia-smi

Repo files live at /mnt/c/... inside WSL, but git is much faster on the Linux
filesystem - clone a second copy into ~/ if you plan to work in WSL daily.

Reminder: no GPU driver was installed or modified by this script, on either
side of the WSL boundary. That is intentional and required.
"@ | Write-Host
