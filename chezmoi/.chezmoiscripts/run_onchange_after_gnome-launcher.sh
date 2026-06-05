#!/usr/bin/env bash
# Configure GNOME (Wayland) keyboard shortcuts: rofi launcher + menus and quick
# app launches. Idempotent; safe to run repeatedly. No-ops outside GNOME.
# chezmoi re-runs this whenever the body below changes.
#
# Two GNOME/Mutter quirks shape every rofi command here:
#   env -u WAYLAND_DISPLAY : Mutter has no wlr-layer-shell, so native-Wayland
#     rofi aborts. Clearing it forces the X11/XWayland backend.
#   -normal-window         : Mutter won't give keyboard focus to an XWayland
#     override-redirect popup, so Esc/typing die. A normal window gets focus.
set -euo pipefail

command -v gsettings >/dev/null 2>&1 || { echo "gsettings missing, skip"; exit 0; }
case "${XDG_CURRENT_DESKTOP:-}" in
  *GNOME*) ;;
  *) echo "not GNOME (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unset}), skip"; exit 0 ;;
esac

BIN="${HOME}/.local/bin"
ROFI="env -u WAYLAND_DISPLAY rofi -normal-window"

# --- Default terminal = wezterm ---
if command -v wezterm >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.default-applications.terminal exec 'wezterm'
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg 'start --'
fi

# Detect a browser for the Super+B shortcut.
BROWSER_CMD=""
for b in brave google-chrome-stable firefox chromium; do
  command -v "$b" >/dev/null 2>&1 && { BROWSER_CMD="$b"; break; }
done

# --- Custom keybindings table: name | binding | command ---------------------
# Edit freely; the list is rebuilt from these rows each run.
declare -a ROWS=(
  "rofi|Rofi App Launcher|<Control>space|${ROFI} -show drun -show-icons"
  "window|Rofi Window Switcher|<Super>w|${ROFI} -show window -show-icons"
  "power|Power Menu|<Super>Escape|${BIN}/rofi-power"
  "clip|Clipboard History|<Super><Shift>v|${BIN}/rofi-clip"
  "emoji|Emoji Picker|<Super>period|${BIN}/rofi-emoji"
  "calc|Calculator|<Super>equal|${BIN}/rofi-calc-menu"
  "ssh|SSH Menu|<Super>backslash|${BIN}/rofi-ssh"
  "term|WezTerm|<Super>Return|wezterm start --"
  "files|Files|<Super>e|nautilus"
)
[ -n "$BROWSER_CMD" ] && ROWS+=("browser|Browser|<Super>b|${BROWSER_CMD}")

KB="org.gnome.settings-daemon.plugins.media-keys"
BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
paths=""
for row in "${ROWS[@]}"; do
  IFS='|' read -r slot name binding cmd <<<"$row"
  p="${BASE}/${slot}/"
  paths="${paths:+$paths, }'$p'"
  gsettings set "${KB}.custom-keybinding:${p}" name "$name"
  gsettings set "${KB}.custom-keybinding:${p}" command "$cmd"
  gsettings set "${KB}.custom-keybinding:${p}" binding "$binding"
done
gsettings set "$KB" custom-keybindings "[$paths]"

# --- Native screenshot UI also on Super+Shift+S (keeps Print too) ---
gsettings set org.gnome.shell.keybindings show-screenshot-ui "['Print', '<Super><Shift>s']" 2>/dev/null || true

# --- Hide the accessibility (universal-access) icon in the top bar ---
gsettings set org.gnome.desktop.a11y always-show-universal-access-status false 2>/dev/null || true

echo "GNOME launcher + shortcuts applied."
