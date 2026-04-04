# ============================================================
# PowerShell Profile — Windows Power Dev Environment
# Loads: Starship · zoxide · Conda integration · useful aliases
#
# Deploy: copy this file to the path printed by: $PROFILE
# Or run: env_setup.ps1 to configure automatically
# ============================================================

# ── Starship Prompt ──────────────────────────────────────────
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# ── zoxide (smart cd / z command) ───────────────────────────
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell) })
}

# ── Conda ────────────────────────────────────────────────────
# (conda init powershell injects its own block here automatically)
# If conda is missing, run: conda init powershell

# ── Aliases ──────────────────────────────────────────────────
Set-Alias grep   Select-String
Set-Alias which  Get-Command

# fzf history search (Ctrl+R equivalent)
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
        $cmd = Get-History | ForEach-Object { $_.CommandLine } |
               Sort-Object -Unique | fzf --tac --no-sort
        if ($cmd) {
            [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($cmd)
        }
    }
}

# ── Git shortcuts ─────────────────────────────────────────────
function gs  { git status }
function ga  { git add @args }
function gc  { git commit -m @args }
function gp  { git push @args }
function gl  { git log --oneline --graph --decorate -20 }
function gd  { git diff @args }
function gco { git checkout @args }
function gbr { git branch @args }

# ── Useful utilities ──────────────────────────────────────────
function mkcd([string]$dir) { New-Item -ItemType Directory -Force $dir | Out-Null; Set-Location $dir }
function touch([string]$file) { New-Item -ItemType File -Force $file | Out-Null }
function path { $env:PATH -split ";" | Sort-Object | Where-Object { $_ } }
function reload { . $PROFILE }

# ── Welcome line ──────────────────────────────────────────────
# Uncomment to show a quick status on shell open:
# Write-Host "PS $(($PSVersionTable.PSVersion.ToString())) | zoxide $(zoxide --version 2>$null) | $(starship --version 2>$null)" -ForegroundColor DarkGray
