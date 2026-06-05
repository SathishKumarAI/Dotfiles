#!/usr/bin/env bash
# Add extra top-right panel features: Caffeine (keep-awake toggle) and
# Media Controls (play/pause + track for Spotify/browser).
#
#   bash setup/gnome-panel-extras.sh
#   Then: LOG OUT and back in (Wayland can't reload the shell live).
#
# NOTE: GNOME 50 is very new. Caffeine (AUR, -git) tracks rolling GNOME.
# Media Controls comes from extensions.gnome.org via gext; if EGO has no
# GNOME-50 build yet it will say so — re-run later when it's published.
set -euo pipefail

# --- Caffeine: AUR package, canonical id caffeine@patapon.info ---
echo "==> installing Caffeine (AUR)"
yay -S --needed --noconfirm gnome-shell-extension-caffeine-git

# --- Media Controls: not in AUR, install from extensions.gnome.org ---
# gext = gnome-extensions-cli (AUR). Installs EGO extensions by id.
if ! command -v gext >/dev/null 2>&1; then
    echo "==> installing gnome-extensions-cli (gext)"
    yay -S --needed --noconfirm gnome-extensions-cli
fi
echo "==> installing Media Controls from extensions.gnome.org"
gext install mediacontrols@cliffniff.github.com \
    || echo "    !! no GNOME-50 build on EGO yet — re-run later"

# --- Enable everything ---
EXTS=(
    caffeine@patapon.info
    mediacontrols@cliffniff.github.com
)
echo "==> enabling"
for ext in "${EXTS[@]}"; do
    if gnome-extensions enable "$ext" 2>/dev/null; then
        echo "    enabled $ext"
    else
        echo "    couldn't enable $ext yet — run again after logout"
    fi
done

echo
echo "Done. LOG OUT and back in. Configure via Extensions app:"
echo "  - Caffeine:       toggle in top-right; auto-keep-awake for apps in prefs"
echo "  - Media Controls: prefs let you pick position, label width, sources"
