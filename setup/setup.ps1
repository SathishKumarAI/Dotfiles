<#
setup.ps1 - main Windows entry point (the PowerShell counterpart of setup.sh).
Ensures the package managers (winget + scoop) are present, then runs the
Windows orchestrator (setup-windows.ps1).

Usage:
  powershell -ExecutionPolicy Bypass -File .\setup.ps1            # ensure pkg mgrs + run
  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DryRun    # preview, change nothing
  powershell -ExecutionPolicy Bypass -File .\setup.ps1 -SkipScoop # don't auto-install scoop

On Linux/macOS use setup.sh instead (it dispatches to setup-rocky.sh / setup-arch.sh).
#>

param(
  [switch]$DryRun,
  [switch]$SkipScoop
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# A shell holds the PATH it was launched with. When these scripts run from a
# long-lived session (or from pipeline-windows-ml.ps1), tools installed earlier
# in the same session look missing - which made this script reinstall scoop and
# skip every tool that depended on it. Re-read the real PATH from the registry.
function Sync-PathFromRegistry {
  $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
              [Environment]::GetEnvironmentVariable("Path","User")
}
Sync-PathFromRegistry


# $IsWindows only exists in PowerShell 6+. Under Windows PowerShell 5.1 a bare
# reference to it throws with Set-StrictMode -Version Latest, so probe safely.
$onWindows = $true
if ($PSVersionTable.PSVersion.Major -ge 6) {
  $onWindows = [bool](Get-Variable -Name IsWindows -ValueOnly -ErrorAction SilentlyContinue)
}
if (-not $onWindows) {
  Write-Host "This is the Windows entry point. On Linux/macOS run: bash setup/setup.sh"
  exit 1
}

Write-Host "Windows setup - ensuring package managers ..."

# winget ships with modern Windows; we don't auto-install it.
if (Have winget) { Write-Host "  winget: found" }
else { Write-Host "  winget: NOT found - install 'App Installer' from the Microsoft Store, then re-run" }

# scoop is the user-space manager for the CLI dev tools; offer to install it.
if (Have scoop) {
  Write-Host "  scoop:  found"
} elseif ($SkipScoop) {
  Write-Host "  scoop:  not found (--SkipScoop set; CLI-tool steps will be skipped)"
} elseif ($DryRun) {
  Write-Host "  scoop:  not found ([DryRun] would install via the official one-liner)"
} else {
  Write-Host "  scoop:  not found - installing (user-scope, no admin) ..."
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
  Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}

$orchestrator = Join-Path $Here "setup-windows.ps1"
if (-not (Test-Path -LiteralPath $orchestrator)) {
  Write-Host "missing orchestrator: $orchestrator"
  exit 1
}

if ($DryRun) {
  Write-Host "`n[dry-run] would run: $orchestrator -DryRun"
  & $orchestrator -DryRun
} else {
  Write-Host "`nRunning $orchestrator ..."
  & $orchestrator
}
