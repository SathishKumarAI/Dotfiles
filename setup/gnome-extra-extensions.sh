#!/usr/bin/env bash
# Install + enable extra GNOME extensions (AppIndicator, Tiling Assistant,
# Just Perfection). Run as your normal user (it will sudo when needed):
#
#   bash setup/gnome-extra-extensions.sh
#
# Then LOG OUT and back in (Wayland can't reload the shell live).
set -euo pipefail

PKGS=(
    gnome-shell-extension-appindicator                 # tray icons (top-right)
    gnome-shell-extension-tiling-assistant             # quarter/half tiling
    gnome-shell-extension-just-perfection-desktop      # hide/tweak UI elements
)

EXTS=(
    appindicatorsupport@rgcjonas.gmail.com
    tiling-assistant@leleat-on-github
    just-perfection-desktop@just-perfection
)

echo "==> installing packages"
yay -S --needed --noconfirm "${PKGS[@]}"

echo "==> enabling extensions"
for ext in "${EXTS[@]}"; do
    if gnome-extensions enable "$ext" 2>/dev/null; then
        echo "    enabled $ext"
    else
        echo "    couldn't enable $ext yet — run again after logout"
    fi
done

echo
echo "Done. LOG OUT and back in to load the extensions."
echo "Currently enabled:"
gnome-extensions list --enabled | sed 's/^/    /'
