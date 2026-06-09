<#
setup-windows.ps1 — full setup for Windows 10/11.
The Windows counterpart of setup-rocky.sh / setup-arch.sh. Run directly or via
setup.ps1 (which ensures winget/scoop first, then calls this).

Strategy:
  • winget  -> base + GUI apps (Git, WezTerm, VS Code, PowerShell 7, Neovim, gh, Miniforge)
  • scoop   -> modern CLI cluster (starship, zellij, mise, fzf, ripgrep, fd, bat, eza, delta, lazygit, zoxide, chezmoi)
Each step continues on error so one failure won't abort the run.

Usage:
  powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1 -DryRun
  powershell -ExecutionPolicy Bypass -File .\setup-windows.ps1
#>

param(
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Step($msg) { Write-Host "`n== $msg ==" -ForegroundColor Magenta }
function Have($cmd) { return [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

function Winget-Install([string]$id) {
  if ($DryRun) { Write-Host "[DryRun] winget install $id"; return }
  if (-not (Have winget)) { Write-Host "  winget missing — skip $id"; return }
  Write-Host "+ winget install $id"
  winget install --id $id -e --accept-source-agreements --accept-package-agreements `
    --silent --disable-interactivity 2>$null
  if ($LASTEXITCODE -ne 0) { Write-Host "  (winget $id failed/already installed — continuing)" }
}

function Scoop-Install([string[]]$pkgs) {
  if ($DryRun) { Write-Host "[DryRun] scoop install $($pkgs -join ' ')"; return }
  if (-not (Have scoop)) { Write-Host "  scoop missing — skip $($pkgs -join ' ')"; return }
  foreach ($p in $pkgs) {
    Write-Host "+ scoop install $p"
    scoop install $p 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host "  (scoop $p failed/already installed — continuing)" }
  }
}

Write-Host "=== Windows setup ==="

Step "Scoop buckets (extras + nerd-fonts)"
if (-not $DryRun -and (Have scoop)) {
  scoop bucket add extras 2>$null
  scoop bucket add nerd-fonts 2>$null
}

Step "Base + GUI apps (winget)"
Winget-Install "Git.Git"
Winget-Install "wez.wezterm"
Winget-Install "Microsoft.VisualStudioCode"
Winget-Install "Microsoft.PowerShell"
Winget-Install "Neovim.Neovim"
Winget-Install "GitHub.cli"
Winget-Install "CondaForge.Miniforge3"

Step "Modern CLI tools (scoop)"
Scoop-Install @("ripgrep","fd","bat","fzf","zoxide")
Scoop-Install @("starship","zellij","lazygit","delta","eza")

Step "Runtime + dotfile managers (scoop)"
Scoop-Install @("mise","chezmoi")

Step "Nerd Font (terminal glyphs)"
Scoop-Install @("JetBrainsMono-NF")

Step "Fix USER PATH (auto-detect installed tools)"
$pathScript = Join-Path $Here "update-user-path.ps1"
if (Test-Path -LiteralPath $pathScript) {
  if ($DryRun) { & $pathScript -DryRun } else { & $pathScript }
} else {
  Write-Host "  skip (missing): update-user-path.ps1"
}

Write-Host "`n== Done ==" -ForegroundColor Green
@"
Next (run yourself):
  • chezmoi:  chezmoi init --apply SathishKumarAI/Dotfiles
  • runtimes: mise install
  • conda:    see dotfiles/windows_setup/conda/setup.md (do NOT add conda to PATH)
  • Close and reopen your terminal so PATH changes take effect.
"@ | Write-Host
