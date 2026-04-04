# ============================================================
# .bashrc — Git Bash on Windows (Power Dev Environment)
# Loads: Starship · zoxide · Conda · useful aliases
#
# Deploy: copy to ~/.bashrc  (C:\Users\<username>\.bashrc)
# Or run: env_setup.ps1 to configure automatically
# ============================================================

# ── Guard: skip if not interactive ───────────────────────────
[[ $- != *i* ]] && return

# ── Starship Prompt ──────────────────────────────────────────
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# ── zoxide (smart cd / z command) ───────────────────────────
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# ── Conda ────────────────────────────────────────────────────
# Run once to enable: conda init bash
# Then restart Git Bash

# ── History settings ─────────────────────────────────────────
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups
shopt -s histappend

# ── Aliases ──────────────────────────────────────────────────
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'
alias gco='git checkout'
alias gbr='git branch'

# fzf history search (Ctrl+R)
if command -v fzf &>/dev/null; then
    bind '"\C-r": "\C-x1\e^\er"'
    alias fh='eval $(history | fzf --tac | sed "s/ *[0-9]* *//")'
fi

# ── Useful utilities ─────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }
path() { echo "$PATH" | tr ':' '\n' | sort | uniq; }
