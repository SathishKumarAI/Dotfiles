#!/usr/bin/env bash
# Install the optional tools that power the rofi menus + shell QoL added to this
# dotfiles repo. Safe to re-run. Arch / Fedora autodetected.
#
#   Run:  bash setup/install-extras.sh
#
# Provides:
#   wl-clipboard  -> wl-copy/wl-paste (clipboard menu, emoji copy)
#   cliphist      -> clipboard history store (Super+Shift+V)
#   libqalculate  -> qalc, the calculator engine (Super+=)
#   rofi-calc     -> rofi calc modi
#   rofimoji      -> emoji/unicode picker (Super+.)
# (fzf, eza, bat, zoxide, lazygit are assumed already installed.)
set -euo pipefail

if command -v pacman >/dev/null; then
    echo "==> Arch: pacman packages"
    sudo pacman -S --needed wl-clipboard cliphist libqalculate

    if command -v yay >/dev/null; then
        echo "==> Arch: AUR packages (yay)"
        yay -S --needed rofi-calc rofimoji
    else
        echo "!! yay not found. Install AUR pkgs manually: rofi-calc rofimoji"
    fi
elif command -v dnf >/dev/null; then
    echo "==> Fedora/RHEL: dnf packages"
    sudo dnf install -y wl-clipboard cliphist qalculate rofi-calc rofimoji \
        || echo "!! some pkgs may be in COPR/EPEL; install manually if missing"
else
    echo "Unsupported distro. Install manually: wl-clipboard cliphist libqalculate rofi-calc rofimoji"
    exit 1
fi

echo "==> Starting cliphist clipboard daemon now (also autostarts at login)"
pkill -f "wl-paste --watch cliphist" 2>/dev/null || true
if [ -n "${WAYLAND_DISPLAY:-}" ]; then
    ( wl-paste --watch cliphist store >/dev/null 2>&1 & ) || true
    echo "   daemon running."
else
    echo "   not in a Wayland session; it will start at next login."
fi

echo
echo "Done. New shortcuts (after 'chezmoi apply' which you've already run):"
echo "  Ctrl+Space      app launcher        Super+W   window switcher"
echo "  Super+Shift+V   clipboard history   Super+.   emoji picker"
echo "  Super+=         calculator          Super+\\   ssh menu"
echo "  Super+Escape    power menu          Super+Return  wezterm"
