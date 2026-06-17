#!/usr/bin/env bash
# personalize.sh — post-install "make this machine mine" step.
#
# Run this AFTER the installers (setup/setup.sh) have put the tools on disk.
# It deploys the dotfiles and applies the personal config that the installers
# don't: shell config, default shell, history import, and desktop tweaks.
#
# Safe to re-run (idempotent). Each step continues on error so one failure
# won't abort the rest. The only interactive step is `chsh` (asks your password).
#
# Usage:
#     bash setup/personalize.sh            # run all steps
#     bash setup/personalize.sh --dry-run  # print steps, change nothing
#     bash setup/personalize.sh --no-chsh  # skip the default-shell change
set -uo pipefail

DRY=0; DO_CHSH=1
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --no-chsh) DO_CHSH=0 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)"; exit 2 ;;
  esac; shift
done

step() { echo; echo "==> $*"; }
run()  { if [ "$DRY" = 1 ]; then echo "  [dry-run] $*"; else eval "$*"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }

# 1. Deploy dotfiles from the chezmoi source to $HOME.
step "chezmoi apply (deploy dotfiles)"
if have chezmoi; then
  run "chezmoi apply"
else
  echo "  chezmoi not installed — run setup/setup.sh first"
fi

# 2. Make zsh the default login shell (so GNOME terminal / SSH / cron use it too;
#    WezTerm already forces zsh). Interactive: asks your password.
step "default shell -> zsh"
if [ "$DO_CHSH" = 0 ]; then
  echo "  skipped (--no-chsh)"
elif have zsh; then
  current="$(getent passwd "$USER" | cut -d: -f7)"
  zsh_path="$(command -v zsh)"
  if [ "$current" = "$zsh_path" ]; then
    echo "  already zsh ($current)"
  else
    run "chsh -s \"$zsh_path\""
    echo "  (log out and back in for it to take effect)"
  fi
else
  echo "  zsh not installed — skipping"
fi

# 3. Import existing shell history into atuin (Ctrl-R search). Idempotent.
step "atuin: import shell history"
if have atuin; then
  run "atuin import auto"
  run "atuin import zsh"
else
  echo "  atuin not installed — skipping"
fi

# 4. GNOME: snappier key-repeat for editor/vim navigation.
step "GNOME key-repeat tuning"
if have gsettings && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
  run "gsettings set org.gnome.desktop.peripherals.keyboard delay 250"
  run "gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 20"
else
  echo "  no GNOME session / gsettings — skipping"
fi

# 5. Validate the result.
step "validate install"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$HERE/validate-install.sh" ]; then
  run "bash \"$HERE/validate-install.sh\""
else
  echo "  validate-install.sh not found — skipping"
fi

echo; echo "Done. Open a new terminal (or log out/in) to pick up shell changes."
