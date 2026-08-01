<#
powershell-profile.ps1 - sample PowerShell 7 profile for this dotfiles setup.

The Windows counterpart of the `eval "$(zoxide init bash)"` block in
dotfiles/bash/.bashrc. scoop installs the binaries; nothing initialises them,
so `z`, the starship prompt and the mise shims never exist until this file is
in place.

Installed by setup-windows.ps1 to:
  $HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1
It is copied only when no profile exists - an existing profile is never
overwritten. Copy it by hand with:
  Copy-Item assets\powershell-profile.ps1 $PROFILE

Every block is guarded, so a missing tool is skipped instead of erroring.
#>

function Test-HasCommand([string]$Name) {
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# zoxide - smart cd. Provides `z` (jump) and `zi` (interactive, needs fzf).
# NOTE: zoxide's PowerShell hook shadows `cd` with its own function by default;
# --cmd cd is the documented way to opt into that. Left as plain `z` here so
# `cd` keeps its normal behaviour.
if (Test-HasCommand zoxide) {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# starship prompt
if (Test-HasCommand starship) {
  Invoke-Expression (&starship init powershell)
}

# mise - runtime version manager (python/node/go/rust).
# Its directory-change hook needs pwsh 7; on Windows PowerShell 5.1 it still
# activates, it just warns once. Silence the warning rather than skip mise.
if (Test-HasCommand mise) {
  if ($PSVersionTable.PSVersion.Major -lt 7) { $env:MISE_PWSH_CHPWD_WARNING = "0" }
  Invoke-Expression (& { (mise activate pwsh | Out-String) })
}

# fzf - Ctrl+R history search, Ctrl+T file picker (needs PSFzf module)
if ((Test-HasCommand fzf) -and (Get-Module -ListAvailable PSFzf -ErrorAction SilentlyContinue)) {
  Import-Module PSFzf -ErrorAction SilentlyContinue
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# PSReadLine - history-aware completion, bash-like keys.
# Only in a real interactive console: PredictionSource throws when stdout is
# redirected (script/CI runs), which would abort the rest of the profile.
if ((Get-Module -ListAvailable PSReadLine -ErrorAction SilentlyContinue) -and
    $Host.UI.SupportsVirtualTerminal -and -not [Console]::IsOutputRedirected) {
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -EditMode Windows
  Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# Modern CLI aliases - same names the bash config uses
if (Test-HasCommand eza) {
  function ll { eza -l --icons --git @args }
  function la { eza -la --icons --git @args }
  function lt { eza --tree --level=2 --icons @args }
}
if (Test-HasCommand bat) {
  function cat { bat --paging=never @args }
}
if (Test-HasCommand lazygit) {
  function lg { lazygit @args }
}

# Repo shortcuts - the Windows stand-in for scripts/w.sh
$env:CODING = "$HOME\Documents\coding"
function ws { Set-Location "$env:CODING\workspace" }
function dot { Set-Location "$env:CODING\workspace\dotfiles" }

# ML venv built by setup/install-ml-windows.ps1
function ml {
  $activate = "$HOME\.venvs\ml\Scripts\Activate.ps1"
  if (Test-Path -LiteralPath $activate) { & $activate }
  else { Write-Host "no ML venv - run setup\install-ml-windows.ps1" -ForegroundColor Yellow }
}
