#!/usr/bin/env bash
# install-hover-taskbar.sh — system-wide auto-hiding taskbar that reveals on
# mouse hover, for GNOME Shell on Wayland (Rocky Linux 10, GNOME 49).
#
#   bash setup/install-hover-taskbar.sh
#
# Installs Dash to Panel (Windows-style panel with window buttons / "tabs") and
# turns on intellihide: the panel hides while a window overlaps it and slides
# back the moment you move the mouse to that screen edge — i.e. hover-to-reveal
# for the whole desktop, not just one app.
#
# No sudo (installs into ~/.local/share/gnome-shell/extensions). Dash to Panel
# isn't in dnf, so we pull the GNOME-version-matched build from EGO. Idempotent.
# On Wayland: LOG OUT and back in to load it. The hover settings apply on load.
set -euo pipefail

UUID="dash-to-panel@jderose9.github.com"
API="https://extensions.gnome.org"
SHELL_VER="$(gnome-shell --version | grep -oP '[0-9]+' | head -1)"
DCONF="/org/gnome/shell/extensions/dash-to-panel"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

echo "==> GNOME Shell $SHELL_VER — installing Dash to Panel (hover taskbar)"

if gnome-extensions list 2>/dev/null | grep -qx "$UUID"; then
    echo "    = $UUID already installed"
else
    info="$(curl -fsSL --max-time 15 "$API/extension-info/?uuid=$UUID&shell_version=$SHELL_VER")" \
        || { echo "    ! no build for GNOME $SHELL_VER — aborting"; exit 1; }
    dl="$(printf '%s' "$info" | grep -oP '"download_url":\s*"\K[^"]+')"
    [ -n "$dl" ] || { echo "    ! no download_url from EGO — aborting"; exit 1; }
    echo "    v downloading $UUID"
    curl -fsSL --max-time 60 -o "$tmp/dtp.zip" "$API$dl"
    gnome-extensions install --force "$tmp/dtp.zip"
fi
gnome-extensions enable "$UUID" 2>/dev/null \
    && echo "    + enabled" \
    || echo "    . installed; enables after next login (Wayland)"

# Hover-reveal config (written via dconf so it works before the schema is on the
# gsettings path). intellihide = auto-hide; pressure OFF = reveal on plain hover.
echo "==> configuring intellihide (hover to reveal)"
dconf write "$DCONF/intellihide"                 true
dconf write "$DCONF/intellihide-use-pressure"    false          # hover, not push
dconf write "$DCONF/intellihide-hide-from-windows" true
dconf write "$DCONF/intellihide-behaviour"       "'ALL_WINDOWS'"
dconf write "$DCONF/intellihide-show-in-fullscreen" false
dconf write "$DCONF/intellihide-only-secondary"  false
dconf write "$DCONF/animation-time"              0.2
dconf write "$DCONF/show-showdesktop-hover"      true

cat <<'EOF'

==> Done. LOG OUT and back in (Wayland) to load the taskbar.

The panel auto-hides under maximized/overlapping windows and slides back when you
move the mouse to its screen edge. Tune it live in:
    gnome-extensions prefs dash-to-panel@jderose9.github.com
  Behavior tab → Intellihide (toggle "Require pressure to show" off = pure hover).

Coexists with PaperWM. If you'd rather only the GNOME *top* bar hover-reveal
(no window buttons), use Hide Top Bar instead: hidetopbar@mathieu.bidon.ca.
EOF
