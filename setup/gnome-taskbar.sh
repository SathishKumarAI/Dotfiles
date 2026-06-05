#!/usr/bin/env bash
# Show icons of open windows in the TOP-CENTER of the panel (like a taskbar),
# using the Dash to Panel GNOME extension.
#
#   Run:  bash setup/gnome-taskbar.sh
#   Then: log out and back in (Wayland can't reload the shell live).
#
# NOTE: GNOME 50 is very new; if the extension shows as "outdated", grab the
# latest from https://extensions.gnome.org/extension/1160/dash-to-panel/
# (or:  gext install dash-to-panel@jderose9.github.com).
set -euo pipefail

EXT="dash-to-panel@jderose9.github.com"

# 1. Install the extension (repo package on Arch).
if command -v pacman >/dev/null && ! pacman -Qi gnome-shell-extension-dash-to-panel >/dev/null 2>&1; then
    echo "==> installing dash-to-panel"
    sudo pacman -S --needed gnome-shell-extension-dash-to-panel
fi

# 2. Configure: thin panel on top, running-app icons CENTERED, clock left,
#    system tray right. Native GNOME elements kept.
#    NOTE: panel-* keys are GVariant *strings* (JSON), so they must be wrapped
#    in single quotes ("'$JSON'"); writing raw JSON makes dconf reject it.
D=/org/gnome/shell/extensions/dash-to-panel
dconf write $D/panel-positions    "{'0':'TOP'}"
dconf write $D/panel-sizes        "{'0':36}"
dconf write $D/appicon-margin     "'4'"
dconf write $D/show-favorites     false      # only OPEN windows, not pinned
dconf write $D/isolate-workspaces true       # icons = current desktop only
ELEMENTS='{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"dateMenu","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"centerMonitor"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"}]}'
dconf write $D/panel-element-positions "'$ELEMENTS'"

# 3. Enable (may need to run again after logout if the schema isn't loaded yet).
gnome-extensions enable "$EXT" 2>/dev/null \
    && echo "==> enabled $EXT" \
    || echo "==> couldn't enable yet; after logout run: gnome-extensions enable $EXT"

echo
echo "Done. LOG OUT and back in. Open windows on the current desktop will show"
echo "as centered icons in the top panel. Fine-tune via: dash-to-panel prefs"
echo "  (Extensions app -> Dash to Panel -> settings)."
