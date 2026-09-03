#!/usr/bin/env bash
# panel-modern-style.sh — give the Dash-to-Panel taskbar a modern "floating dock"
# look: a detached, rounded, blurred bar at the top with centered app icons.
#
# What it sets:
#   • Position TOP, detached with side + top margins and rounded corners
#   • App icons CENTERED; clock + system menu kept on the right
#   • Dot running-indicators under icons, Catppuccin-mauve accent
#   • Semi-transparent Catppuccin Mocha background + blur-my-shell panel blur
#   • Intellihide (auto-hide; reveal by pushing the pointer to the top edge)
#
# Target: GNOME Shell 49 (Wayland), Dash-to-Panel v73 + blur-my-shell, Rocky 10.
# No sudo. Idempotent. Writes via dconf (D2P's gschema lives in the extension
# dir, so plain `gsettings` can't see it — "No such schema ...").
#
# Tunables (env vars):
#   SIZE=48           panel/dock height in px
#   SIDE_MARGIN=12    left/right gap from screen edge (bigger = shorter, more dock-like)
#   TB_MARGIN=8       top gap from screen edge
#   RADIUS=16         corner radius
#   OPACITY=0.15      panel background opacity (0=clear, 1=solid)
#   INTELLIHIDE=true  auto-hide the panel (set false to keep it always visible)
#   ALIGN=LEFT        app-icon alignment: LEFT (hug left edge, grow right with
#                     more apps — minimal wasted space), CENTER, or RIGHT
#
# NOTE: Dash-to-Panel's bar always spans the full monitor width; only the ICONS
# can hug content. For a bar that physically shrinks to its icons, use a
# content-sized Dash-to-Dock instead (see docs/desktop/gnome.mdx).
#
# Revert to a plain solid top bar:  bash setup/panel-position-top.sh   (position only)
# Fine-tune live:  open Dash-to-Panel preferences.

set -euo pipefail

# Talk to the live GNOME session bus even from a Flatpak/proxied shell (those
# export a DBus that can't reach GNOME's dconf — "Could not connect").
_bus="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus"
[ -S "$_bus" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$_bus"

# ---- tunables -------------------------------------------------------------
SIZE="${SIZE:-48}"
SIDE_MARGIN="${SIDE_MARGIN:-12}"
TB_MARGIN="${TB_MARGIN:-8}"
RADIUS="${RADIUS:-16}"
OPACITY="${OPACITY:-0.15}"
INTELLIHIDE="${INTELLIHIDE:-true}"
ALIGN="${ALIGN:-LEFT}"

case "$ALIGN" in
  LEFT)   TB_POS="stackedTL" ;;
  CENTER) TB_POS="centerMonitor" ;;
  RIGHT)  TB_POS="stackedBR" ;;
  *) echo "ALIGN must be LEFT/CENTER/RIGHT, got '$ALIGN'" >&2; exit 1 ;;
esac

# Catppuccin Mocha
BASE="#1e1e2e"     # panel background
MAUVE="#cba6f7"    # running-dot / highlight accent

D2P_EXT="dash-to-panel@jderose9.github.com"
BMS_EXT="blur-my-shell@aunetx"
D="/org/gnome/shell/extensions/dash-to-panel"
B="/org/gnome/shell/extensions/blur-my-shell"

# ---- preconditions --------------------------------------------------------
for ext in "$D2P_EXT" "$BMS_EXT"; do
  if [ ! -d "$HOME/.local/share/gnome-shell/extensions/$ext" ]; then
    echo "Missing extension: $ext" >&2; exit 1
  fi
  gnome-extensions list --enabled 2>/dev/null | grep -qx "$ext" \
    || { echo "Enabling $ext ..."; gnome-extensions enable "$ext" || true; }
done

# ---- monitor count (D2P JSON keys are monitor INDEX strings: "0","1",...) --
N=$(
  gdbus call --session --dest org.gnome.Mutter.DisplayConfig \
    --object-path /org/gnome/Mutter/DisplayConfig \
    --method org.gnome.Mutter.DisplayConfig.GetCurrentState 2>/dev/null \
    | grep -oE "'(eDP|DP|HDMI|HDMI-A|DVI|DVI-I|DVI-D|VGA|LVDS|DSI)-[0-9]+'" \
    | sort -u | wc -l
)
[ "$N" -ge 1 ] 2>/dev/null || N=1

# Element layout: hide the show-apps/activities/desktop buttons so nothing pads
# the left edge; place the taskbar (app icons) per $ALIGN — LEFT means icons hug
# the left edge and grow rightward as apps open (minimal wasted space). Clock +
# system menu stay stacked on the right.
ELEMENTS=$(jq -cn --arg tb "$TB_POS" '[
  {element:"showAppsButton",   visible:false, position:"stackedTL"},
  {element:"activitiesButton", visible:false, position:"stackedTL"},
  {element:"leftBox",          visible:true,  position:"stackedTL"},
  {element:"taskbar",          visible:true,  position:$tb},
  {element:"centerBox",        visible:true,  position:"stackedBR"},
  {element:"rightBox",         visible:true,  position:"stackedBR"},
  {element:"dateMenu",         visible:true,  position:"stackedBR"},
  {element:"systemMenu",       visible:true,  position:"stackedBR"},
  {element:"desktopButton",    visible:false, position:"stackedBR"}
]')

POS_JSON=$(jq -cn  --argjson n "$N"             '[range(0;$n)]|map({(tostring):"TOP"})|add|tostring')
SIZE_JSON=$(jq -cn --argjson n "$N" --argjson s "$SIZE" '[range(0;$n)]|map({(tostring):$s})|add|tostring')
ELEM_JSON=$(jq -cn --argjson n "$N" --argjson e "$ELEMENTS" '[range(0;$n)]|map({(tostring):$e})|add|tostring')

echo "Applying floating-dock style to $N monitor(s) ..."

# ---- Dash-to-Panel: geometry ---------------------------------------------
dconf write "$D/panel-positions"          "$POS_JSON"
dconf write "$D/panel-position"            "'TOP'"
dconf write "$D/panel-sizes"               "$SIZE_JSON"
dconf write "$D/panel-element-positions-monitors-sync" true
dconf write "$D/panel-element-positions"   "$ELEM_JSON"
dconf write "$D/panel-side-margins"        "$SIDE_MARGIN"
dconf write "$D/panel-top-bottom-margins"  "$TB_MARGIN"
dconf write "$D/global-border-radius"      "$RADIUS"

# ---- Dash-to-Panel: icons + indicators -----------------------------------
dconf write "$D/appicon-padding"           8
dconf write "$D/appicon-margin"            4
dconf write "$D/dot-position"              "'BOTTOM'"
dconf write "$D/dot-style-focused"         "'DOTS'"
dconf write "$D/dot-style-unfocused"       "'DOTS'"
dconf write "$D/dot-size"                  3
dconf write "$D/dot-color-override"        true
dconf write "$D/dot-color-1"               "'$MAUVE'"
dconf write "$D/animate-appicon-hover"     true
dconf write "$D/highlight-appicon-hover"   true
dconf write "$D/focus-highlight"           true
dconf write "$D/show-window-previews"      true

# ---- Dash-to-Panel: transparency (Catppuccin Mocha base) -----------------
dconf write "$D/trans-use-custom-bg"       true
dconf write "$D/trans-bg-color"            "'$BASE'"
dconf write "$D/trans-use-custom-opacity"  true
dconf write "$D/trans-panel-opacity"       "$OPACITY"
dconf write "$D/trans-use-dynamic-opacity" false

# ---- Dash-to-Panel: auto-hide (intellihide) ------------------------------
dconf write "$D/intellihide"               "$INTELLIHIDE"
dconf write "$D/intellihide-use-pointer"   true
dconf write "$D/intellihide-hide-from-windows" true

# ---- blur-my-shell: frost the floating panel -----------------------------
dconf write "$B/dash-to-panel/blur-original-panel" true
dconf write "$B/panel/customize"           true
dconf write "$B/panel/static-blur"         true
dconf write "$B/panel/sigma"               30
dconf write "$B/panel/brightness"          0.6

echo "Done. Floating-dock style applied."
echo "On Wayland, log out + back in if the panel doesn't restyle immediately."
echo "Tweak anything live in Dash-to-Panel preferences, or re-run with env vars"
echo "(e.g. SIDE_MARGIN=200 INTELLIHIDE=false bash setup/panel-modern-style.sh)."
