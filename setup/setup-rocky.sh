#!/usr/bin/env bash
# setup-rocky.sh — full setup for Rocky Linux / Fedora / RHEL.
# Orchestrates the modular scripts in this dir in a safe order. Run directly or
# via:  bash setup/setup.sh   (which auto-detects and calls this).
#
# Only calls scripts safe on dnf-based systems + the dual-OS installers.
# (The pacman/yay GNOME-extension scripts live in setup-arch.sh instead.)
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { printf '\n\033[1;35m== %s ==\033[0m\n' "$1"; }
run() {                       # run <script> [args...] — skip if absent, continue on error
  local name="$1"; local s="$HERE/$name"; shift || true
  [ -f "$s" ] || { echo "  skip (missing): $name"; return 0; }
  echo "+ bash $name $*"
  bash "$s" "$@" || echo "  (step failed — continuing)"
}

echo "=== Rocky Linux setup ==="

step "Base developer environment (dnf)"
run rocky-dev-setup-custom.sh

step "Terminal — WezTerm"
run install-wezterm.sh

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

step "Validate install (health check + log)"
run validate-install.sh

cat <<'EOF'

== Done ✓ ==
Next (run yourself — these touch $HOME / need decisions):
  • chezmoi:  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply SathishKumarAI/Dotfiles
  • runtimes: mise install
  • launcher: this host uses wofi — bash ~/.config/wofi/scripts/install-wofi.sh
  • Log out and back in for GNOME changes to take effect.
EOF
