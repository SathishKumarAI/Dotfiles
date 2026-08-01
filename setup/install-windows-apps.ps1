<#
install-windows-apps.ps1 - restore the full Windows application set.

setup-windows.ps1 installs the *shared cross-platform* toolset (the same tools
the Rocky/Arch scripts install). This script covers everything else that lived
on the previous Windows box but has no Linux counterpart, reconstructed from
the machine inventory in dotfiles/misc/all_programs.txt (123 programs).

  !! THIS SCRIPT NEVER INSTALLS, UPDATES, OR MODIFIES GPU DRIVERS. !!
  No vendor driver packages (NVIDIA/Intel/Realtek/Dell) are included. Drivers
  and OEM utilities from the old inventory are deliberately omitted - they are
  machine-specific and are yours to manage.

Groups (pick with -Groups, default is Desktop,Dev,Docs):
  Desktop  GlazeWM + Zebar tiling, PowerToys, ExplorerPatcher, WizTree
  Dev      Build Tools, Node, jq, wget, Postman, PostgreSQL, minikube, Docker
  Docs     Obsidian, Pandoc, MiKTeX, Tesseract OCR, LibreOffice
  AI       LM Studio, Claude Code
  Media    OBS Studio
  Browsers Brave, Zen Browser
  All      everything above

Usage:
  powershell -ExecutionPolicy Bypass -File .\install-windows-apps.ps1 -DryRun
  powershell -ExecutionPolicy Bypass -File .\install-windows-apps.ps1
  powershell -ExecutionPolicy Bypass -File .\install-windows-apps.ps1 -Groups Desktop,AI
  powershell -ExecutionPolicy Bypass -File .\install-windows-apps.ps1 -Groups All
#>

param(
  [switch]$DryRun,
  # No [ValidateSet] here on purpose: powershell.exe -File passes "-Groups a,b"
  # as ONE string, which ValidateSet rejects before the script can split it.
  # Split first, then validate by hand (below) so both call styles work.
  [string[]]$Groups = @("Desktop","Dev","Docs")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$global:LASTEXITCODE = 0
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($msg) { Write-Host "`n== $msg ==" -ForegroundColor Magenta }
function Note($msg) { Write-Host "   $msg" -ForegroundColor DarkGray }
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


function Winget-Install([string]$id, [string]$why) {
  if ($DryRun) { Write-Host ("[DryRun] winget install {0,-42} # {1}" -f $id, $why); return }
  if (-not (Have winget)) { Note "winget missing - skip $id"; return }
  Write-Host "+ $id  ($why)"
  winget install --id $id -e --accept-source-agreements --accept-package-agreements `
    --silent --disable-interactivity 2>$null
  if ($LASTEXITCODE -ne 0) { Note "  (failed or already installed - continuing)" }
}

$ValidGroups = @("Desktop","Dev","Docs","AI","Media","Browsers","All")
$Groups = @($Groups | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
$bad = @($Groups | Where-Object { $ValidGroups -notcontains $_ })
if ($bad.Count -gt 0) {
  Write-Host "Unknown group(s): $($bad -join ', ')" -ForegroundColor Red
  Write-Host "Valid groups: $($ValidGroups -join ', ')"
  exit 2
}

$all = $Groups -contains "All"
function Want($g) { return ($all -or ($Groups -contains $g)) }

Write-Host "=== Windows application restore ===" -ForegroundColor Cyan
Note "Groups: $($Groups -join ', ')"
Note "Source inventory: dotfiles/misc/all_programs.txt"
Note "Drivers and OEM utilities are intentionally excluded."

# ---------------------------------------------------------------------------
if (Want "Desktop") {
  Step "Desktop - tiling WM, system utilities"
  # GlazeWM is the Windows answer to the tiling setup the Linux side gets from
  # GNOME + extensions. A ready config lives at assets/glazewm-sample-config.yaml.
  Winget-Install "glzr-io.glazewm"          "tiling window manager"
  Winget-Install "glzr-io.zebar"            "status bar for GlazeWM"
  Winget-Install "Microsoft.PowerToys"      "FancyZones, Run, PowerRename, Awake"
  Winget-Install "valinet.ExplorerPatcher"  "restore classic taskbar behaviour"
  Winget-Install "AntibodySoftware.WizTree" "disk usage analyser (NTFS MFT, very fast)"
}

if (Want "Dev") {
  Step "Dev - toolchain, data, containers"
  # MSVC build tools: needed to compile any Python package without a prebuilt
  # wheel, and by several CUDA/C++ extensions. The old box had full Visual
  # Studio Community; Build Tools is the lean equivalent.
  Winget-Install "Microsoft.VisualStudio.2022.BuildTools" "MSVC compiler for native Python pkgs"
  Winget-Install "OpenJS.NodeJS.LTS"        "Node.js LTS"
  Winget-Install "jqlang.jq"                "JSON processor"
  Winget-Install "GNU.Wget2"                "wget"
  Winget-Install "Postman.Postman"          "API client"
  Winget-Install "PostgreSQL.PostgreSQL.17" "PostgreSQL 17 + psql"
  Winget-Install "Kubernetes.minikube"      "local Kubernetes"
  Winget-Install "Docker.DockerDesktop"     "containers (WSL2 backend)"
  Note "Docker Desktop needs a reboot and WSL2 - see install-wsl-ubuntu.ps1"
}

if (Want "Docs") {
  Step "Docs - notes, publishing, OCR"
  Winget-Install "Obsidian.Obsidian"        "notes - this repo ships a vault/ + .obsidian/"
  Winget-Install "JohnMacFarlane.Pandoc"    "doc conversion (used by build-keybindings-pdf.sh)"
  Winget-Install "MiKTeX.MiKTeX"            "LaTeX - Pandoc PDF backend"
  Winget-Install "UB-Mannheim.TesseractOCR" "OCR engine"
  Winget-Install "TheDocumentFoundation.LibreOffice" "office suite"
}

if (Want "AI") {
  Step "AI - local models, agents"
  # 16 GB VRAM runs quantised 13B-30B models comfortably.
  Winget-Install "ElementLabs.LMStudio"     "local LLM runner (GGUF, GPU offload)"
  Winget-Install "Anthropic.ClaudeCode"     "Claude Code CLI"
  Note "For ML libraries and CUDA-matched PyTorch, run install-ml-windows.ps1"
}

if (Want "Media")    { Step "Media";    Winget-Install "OBSProject.OBSStudio" "screen recording / streaming" }
if (Want "Browsers") { Step "Browsers"; Winget-Install "Brave.Brave" "browser"; Winget-Install "Zen-Team.Zen-Browser" "browser" }

# ---------------------------------------------------------------------------
Step "GlazeWM config"
$glazeSrc = Join-Path (Split-Path -Parent $Here) "assets\glazewm-sample-config.yaml"
$glazeDst = Join-Path $env:USERPROFILE ".glzr\glazewm\config.yaml"
if (-not (Test-Path -LiteralPath $glazeSrc)) {
  Note "no sample config in assets/ - skipping"
} elseif (Test-Path -LiteralPath $glazeDst) {
  Note "config already exists, not overwriting: $glazeDst"
  Note "compare with: $glazeSrc"
} elseif ($DryRun) {
  Write-Host "[DryRun] copy $glazeSrc -> $glazeDst"
} else {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $glazeDst) | Out-Null
  Copy-Item -LiteralPath $glazeSrc -Destination $glazeDst
  Note "installed: $glazeDst"
}

Step "Repair USER PATH"
$pathScript = Join-Path $Here "update-user-path.ps1"
if (Test-Path -LiteralPath $pathScript) {
  if ($DryRun) { & $pathScript -DryRun } else { & $pathScript }
} else {
  Note "skip (missing): update-user-path.ps1"
}

Write-Host "`n== Done ==" -ForegroundColor Green
@"
Not covered here (install by hand - account-bound, licensed, or OEM):
  * Visual Studio Community 2022   (winget: Microsoft.VisualStudio.2022.Community)
  * Zoom, iCloud, OneDrive, Dell SupportAssist, AVG
  * Chrome Remote Desktop  - this repo prefers RustDesk, see
    chezmoi/private_dot_config/remote-desktop/
  * JDownloader 2, Stirling-PDF, ONLYOFFICE

Reminder: no GPU driver was installed or modified by this script.
Close and reopen your terminal so PATH changes take effect.
"@ | Write-Host
