#!/usr/bin/env bash
# setup-rocky.sh — full setup for Rocky Linux / Fedora / RHEL.
# Orchestrates the modular scripts in this dir in a safe order. Run directly or
# via:  bash setup/setup.sh   (which auto-detects and calls this).
#
# Steps are tagged sudo (system packages via dnf — need root) or user (installs
# into $HOME / ~/.local / gsettings — no root). Modes:
#     bash setup/setup-rocky.sh                # everything (prompts for sudo)
#     bash setup/setup-rocky.sh --user-only    # only the no-sudo steps
#     bash setup/setup-rocky.sh --sudo-only    # only the system (dnf) steps
#
# Only calls scripts safe on dnf-based systems + the dual-OS installers. GNOME
# extensions are pulled from extensions.gnome.org (no pacman), so they're safe
# here and run in the user phase.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MODE="all"   # all | user | sudo
while [ "$#" -gt 0 ]; do
  case "$1" in
    --user-only|--no-sudo) MODE="user" ;;
    --sudo-only)           MODE="sudo" ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)"; exit 2 ;;
  esac; shift
done

step() { printf '\n\033[1;35m== %s ==\033[0m\n' "$1"; }

# run <phase> <script> [args...] — phase is "sudo" or "user". Skips when the
# selected MODE excludes that phase, skips silently if the script is absent,
# and continues on error so one failure never aborts the whole run.
run() {
  local phase="$1" name="$2"; shift 2 || true
  case "$MODE" in
    user) [ "$phase" = "user" ] || { echo "  skip ($phase): $name"; return 0; } ;;
    sudo) [ "$phase" = "sudo" ] || { echo "  skip ($phase): $name"; return 0; } ;;
  esac
  local s="$HERE/$name"
  [ -f "$s" ] || { echo "  skip (missing): $name"; return 0; }
  echo "+ [$phase] bash $name $*"
  bash "$s" "$@" || echo "  (step failed — continuing)"
}

echo "=== Rocky Linux setup  (mode: $MODE) ==="

# ---- system phase (needs sudo: dnf package installs) -----------------------
step "Base developer environment (dnf)"
run sudo rocky-dev-setup-custom.sh

step "Modern CLI tools (ripgrep/fd/bat/eza/delta/fzf)"
run sudo install-modern-cli.sh

step "Automation tools (direnv/just/pre-commit)"
run sudo install-automation-tools.sh

step "Launcher menu tools (clipboard/emoji/calc)"
run sudo install-extras.sh

step "Productivity apps (LibreOffice/ONLYOFFICE/Pomodoro/…)"
run sudo install-productivity.sh

step "Workflow CLI tools (zoxide/fzf/delta/uv/ruff/…)"
run sudo install-workflow-tools.sh

# ---- user phase (no sudo: $HOME / ~/.local / gsettings) --------------------
step "Terminal — WezTerm (Flatpak --user)"
run user install-wezterm.sh

step "GNOME desktop — theme / fonts / keybindings"
run user gnome-desktop-setup.sh

step "GNOME tiling — PaperWM (niri-like scrollable) + AATWS app switcher"
run user install-tiling.sh

step "GNOME hover taskbar — Dash to Panel + intellihide"
run user install-hover-taskbar.sh

step "Validate install (health check + log)"
run user validate-install.sh

cat <<'EOF'

== Done ✓ ==
Next (run yourself — these touch $HOME / need decisions):
  • chezmoi:  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply SathishKumarAI/Dotfiles
  • runtimes: mise install
  • launcher: this host uses wofi — bash ~/.config/wofi/scripts/install-wofi.sh
  • Log out and back in for GNOME changes (extensions/theme) to take effect.
EOF
