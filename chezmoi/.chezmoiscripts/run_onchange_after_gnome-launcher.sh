#!/usr/bin/env bash
# Configure GNOME (Wayland) keyboard launching:
#  - Ctrl+Alt+Space         -> rofi app launcher (drun)
#  - default terminal       -> wezterm
# Idempotent; safe to run repeatedly. No-ops outside GNOME.
# chezmoi re-runs this whenever the body below changes.
set -euo pipefail

# Only meaningful under GNOME with gsettings present.
command -v gsettings >/dev/null 2>&1 || { echo "gsettings missing, skip"; exit 0; }
case "${XDG_CURRENT_DESKTOP:-}" in
  *GNOME*) ;;
  *) echo "not GNOME (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unset}), skip"; exit 0 ;;
esac

# --- Default terminal = wezterm ---
if command -v wezterm >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.default-applications.terminal exec 'wezterm'
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg 'start --'
fi

# --- Ctrl+Alt+Space -> rofi launcher (Super key absent on some Dell kbds) ---
if command -v rofi >/dev/null 2>&1; then
  KB="org.gnome.settings-daemon.plugins.media-keys"
  P="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/rofi/"
  gsettings set "$KB" custom-keybindings "['$P']"
  gsettings set "${KB}.custom-keybinding:${P}" name 'Rofi App Launcher'
  gsettings set "${KB}.custom-keybinding:${P}" command 'rofi -show drun'
  gsettings set "${KB}.custom-keybinding:${P}" binding '<Control><Alt>space'
fi

echo "GNOME launcher settings applied."
