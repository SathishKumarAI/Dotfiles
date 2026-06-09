#!/usr/bin/env bash
# setup-arch.sh — full setup for Arch / Manjaro (the laptop).
# Orchestrates the modular scripts in this dir in a safe order. Run directly or
# via:  bash setup/setup.sh   (which auto-detects and calls this).
#
# Uses pacman for the base + WezTerm, the dual-OS installers for tools, and the
# pacman/yay GNOME-extension scripts + TLP that are Arch-native.
# Tip: install an AUR helper (yay) first so the GNOME-extension steps can fetch
# AUR packages:  sudo pacman -S --needed base-devel git && (build yay from AUR).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { printf '\n\033[1;35m== %s ==\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
pac()  { sudo pacman -S --needed --noconfirm "$@" || echo "  (pacman step failed — continuing)"; }
run() {                       # run <script> [args...] — skip if absent, continue on error
  local s="$HERE/$1"; shift || true
  [ -f "$s" ] || { echo "  skip (missing): $1"; return 0; }
  echo "+ bash $1 $*"
  bash "$s" "$@" || echo "  (step failed — continuing)"
}

echo "=== Arch Linux setup ==="

step "Base developer tools (pacman)"
pac base-devel git curl wget unzip neovim zsh tmux docker

step "Terminal — WezTerm (pacman)"
have wezterm || pac wezterm

step "Modern CLI tools (ripgrep/fd/bat/eza/delta/fzf)"
run install-modern-cli.sh

step "Automation tools (direnv/just/pre-commit)"
run install-automation-tools.sh

step "Launcher menu tools (clipboard/emoji/calc)"
run install-extras.sh

step "Workflow CLI tools (zoxide/fzf/delta/uv/ruff/…)"
run install-workflow-tools.sh

step "Productivity apps (LibreOffice/ONLYOFFICE/Pomodoro/…)"
run install-productivity.sh

step "GNOME desktop — theme / fonts / keybindings"
run gnome-desktop-setup.sh

step "GNOME taskbar (Dash-to-Panel)"
run gnome-taskbar.sh

step "GNOME panel extras"
run gnome-panel-extras.sh

step "GNOME extra extensions"
run gnome-extra-extensions.sh

step "Laptop battery saver (TLP)"
run laptop-battery.sh

step "Validate install (health check + log)"
run validate-install.sh

cat <<'EOF'

== Done ✓ ==
Next (run yourself — these touch $HOME / need decisions):
  • chezmoi:  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply SathishKumarAI/Dotfiles
  • runtimes: mise install
  • launcher: this host uses rofi (Ctrl+Alt+Space) — already configured via chezmoi
  • Log out and back in for GNOME changes to take effect.
EOF
