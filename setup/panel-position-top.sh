#!/usr/bin/env bash
# panel-position-top.sh — move the Dash-to-Panel taskbar to the TOP of the screen.
#
# GNOME ships only a top bar; the Windows-style taskbar (window buttons, app
# launchers, system tray) comes from the Dash-to-Panel extension, which defaults
# to the BOTTOM edge. This script flips it to the TOP for every connected
# monitor and makes sure the extension is enabled.
#
# Target: GNOME Shell 49 (Wayland), Dash-to-Panel v73+ on Rocky Linux 10.
# No sudo needed — all per-user gsettings/dconf. Re-runnable (idempotent).
#
# Usage:
#   bash setup/panel-position-top.sh           # move to TOP (default)
#   POSITION=BOTTOM bash setup/panel-position-top.sh   # move back to BOTTOM
#
# After running, the panel jumps immediately. If it doesn't, log out/in
# (Wayland can't hot-reload shell extensions like X11 could).

set -euo pipefail

# Talk to the live GNOME session bus even from a Flatpak/proxied shell (those
# export a DBus that can't reach GNOME's dconf — "Could not connect").
_bus="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus"
[ -S "$_bus" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$_bus"

POSITION="${POSITION:-TOP}"
EXT="dash-to-panel@jderose9.github.com"
SCHEMA="org.gnome.shell.extensions.dash-to-panel"
DCONF="/org/gnome/shell/extensions/dash-to-panel"

case "$POSITION" in
  TOP|BOTTOM|LEFT|RIGHT) ;;
  *) echo "POSITION must be TOP/BOTTOM/LEFT/RIGHT, got '$POSITION'" >&2; exit 1 ;;
esac

# 1. Sanity: extension present?
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT"
if [ ! -d "$EXT_DIR" ]; then
  echo "Dash-to-Panel not installed at $EXT_DIR" >&2
  echo "Install it first: gnome-extensions install (or via extensions.gnome.org)" >&2
  exit 1
fi

# 2. Enable the extension if it isn't already.
if ! gnome-extensions list --enabled 2>/dev/null | grep -qx "$EXT"; then
  echo "Enabling $EXT ..."
  gnome-extensions enable "$EXT" || true
fi

# 3. Count connected monitors. Dash-to-Panel stores positions in the
#    panel-positions JSON keyed by monitor INDEX as a string ("0","1",...),
#    matching Mutter's monitor.index — NOT the connector name.
N=$(
  gdbus call --session \
    --dest org.gnome.Mutter.DisplayConfig \
    --object-path /org/gnome/Mutter/DisplayConfig \
    --method org.gnome.Mutter.DisplayConfig.GetCurrentState 2>/dev/null \
    | grep -oE "'(eDP|DP|HDMI|HDMI-A|DVI|DVI-I|DVI-D|VGA|LVDS|DSI)-[0-9]+'" \
    | sort -u | wc -l
)
[ "$N" -ge 1 ] 2>/dev/null || N=1   # assume at least the primary monitor

# 4. Build panel-positions = {"0":"TOP","1":"TOP",...} for every monitor index.
JSON=$(jq -cn --argjson n "$N" --arg pos "$POSITION" \
  '[range(0;$n)] | map({(tostring): $pos}) | add | tostring')
echo "Setting panel-positions = ${JSON} (${N} monitor(s))"

# 5. Write via dconf, NOT gsettings. Dash-to-Panel ships its gschema inside the
#    extension dir, so `gsettings` ("No such schema ...") can't see it; dconf
#    writes the raw key with no schema lookup. Values are GVariant string
#    literals — $JSON is already a quoted JSON string, $POSITION needs quoting.
dconf write "$DCONF/panel-positions" "$JSON"
# Legacy single-monitor fallback for any monitor missing from panel-positions.
dconf write "$DCONF/panel-position" "'$POSITION'"

echo "Done. Taskbar position -> $POSITION."
echo "If the panel didn't move, log out and back in (Wayland)."
