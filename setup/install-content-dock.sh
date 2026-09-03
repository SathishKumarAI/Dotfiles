#!/usr/bin/env bash
# install-content-dock.sh — add a content-sized "floating dock" for app icons.
#
# Dash-to-Panel's bar always spans the full monitor width; only its icons can
# hug content. For a dock whose BACKGROUND physically shrinks to its icons and
# grows/shrinks as apps open, you need Dash-to-Dock with extend-height=false.
# This script:
#   1. Installs Dash-to-Dock (direct zip from extensions.gnome.org, no sudo),
#      version-matched to the running GNOME Shell.
#   2. Configures it as a top, centered, AUTO-WIDTH, auto-hiding frosted dock
#      (Catppuccin Mocha) — width = number of running/pinned apps.
#   3. Hides Dash-to-Panel's app-icon (taskbar) element so apps live only in the
#      dock; the D2P bar keeps the clock, tray and system menu.
#
# Target: GNOME Shell 49 (Wayland), Rocky 10. No sudo. Idempotent.
# Revert: bash setup/install-content-dock.sh --revert
#
# Tunables (env vars):
#   ICON=48           max icon size (px); the dock height tracks this
#   OPACITY=0.15      dock background opacity (0=clear, 1=solid)
#   POSITION=TOP      TOP / BOTTOM / LEFT / RIGHT
#   AUTOHIDE=true     intellihide (dock hides under windows, reveals on hover)

set -euo pipefail

# Talk to the live GNOME session bus even from a Flatpak/proxied shell (those
# export a DBus that can't reach GNOME's dconf — "Could not connect").
_bus="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/bus"
[ -S "$_bus" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$_bus"

DTD="dash-to-dock@micxgx.gmail.com"
D2P="dash-to-panel@jderose9.github.com"
DD="/org/gnome/shell/extensions/dash-to-dock"
DP="/org/gnome/shell/extensions/dash-to-panel"

ICON="${ICON:-48}"
OPACITY="${OPACITY:-0.15}"
POSITION="${POSITION:-TOP}"
AUTOHIDE="${AUTOHIDE:-true}"
BASE="#1e1e2e"     # Catppuccin Mocha base
MAUVE="#cba6f7"    # accent for running dots

# ---------- monitor count (D2P element JSON is keyed by monitor index) -------
monitor_count() {
  local n
  n=$(gdbus call --session --dest org.gnome.Mutter.DisplayConfig \
        --object-path /org/gnome/Mutter/DisplayConfig \
        --method org.gnome.Mutter.DisplayConfig.GetCurrentState 2>/dev/null \
      | grep -oE "'(eDP|DP|HDMI|HDMI-A|DVI|DVI-I|DVI-D|VGA|LVDS|DSI)-[0-9]+'" \
      | sort -u | wc -l)
  [ "$n" -ge 1 ] 2>/dev/null && echo "$n" || echo 1
}

# ---------- D2P taskbar element: show or hide the app icons -------------------
# Rewrite panel-element-positions for every monitor with the taskbar element's
# visibility set to $1 (true|false). Other elements keep sensible placement.
set_d2p_taskbar() {
  local vis="$1" n; n=$(monitor_count)
  local elems
  elems=$(jq -cn --argjson v "$vis" '[
    {element:"showAppsButton",   visible:false, position:"stackedTL"},
    {element:"activitiesButton", visible:false, position:"stackedTL"},
    {element:"leftBox",          visible:true,  position:"stackedTL"},
    {element:"taskbar",          visible:$v,    position:"stackedTL"},
    {element:"centerBox",        visible:true,  position:"stackedBR"},
    {element:"rightBox",         visible:true,  position:"stackedBR"},
    {element:"dateMenu",         visible:true,  position:"stackedBR"},
    {element:"systemMenu",       visible:true,  position:"stackedBR"},
    {element:"desktopButton",    visible:false, position:"stackedBR"}
  ]')
  local json
  json=$(jq -cn --argjson n "$n" --argjson e "$elems" \
    '[range(0;$n)]|map({(tostring):$e})|add|tostring')
  dconf write "$DP/panel-element-positions-monitors-sync" true
  dconf write "$DP/panel-element-positions" "$json"
}

# ---------- revert -----------------------------------------------------------
if [ "${1:-}" = "--revert" ]; then
  echo "Reverting: disabling Dash-to-Dock, restoring app icons in Dash-to-Panel."
  gnome-extensions disable "$DTD" 2>/dev/null || true
  gnome-extensions list --enabled 2>/dev/null | grep -qx "$D2P" \
    && set_d2p_taskbar true
  echo "Done. Log out + back in."
  exit 0
fi

# ---------- 1. install Dash-to-Dock ------------------------------------------
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$DTD"
if [ ! -f "$EXT_DIR/metadata.json" ]; then
  SHELL_MAJOR=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
  echo "Fetching Dash-to-Dock for GNOME $SHELL_MAJOR ..."
  DLPATH=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${DTD}&shell_version=${SHELL_MAJOR}" | jq -r '.download_url')
  if [ -z "$DLPATH" ] || [ "$DLPATH" = "null" ]; then
    echo "No Dash-to-Dock build for GNOME $SHELL_MAJOR on extensions.gnome.org." >&2
    exit 1
  fi
  TMP=$(mktemp --suffix=.zip)
  curl -fsSL "https://extensions.gnome.org${DLPATH}" -o "$TMP"
  # Extract manually instead of `gnome-extensions install` — the latter needs a
  # live GNOME Shell D-Bus (absent in headless/sandboxed/SSH shells) and silently
  # no-ops there (exit 0, nothing installed). Unzip + compile schemas works
  # everywhere.
  mkdir -p "$EXT_DIR"
  unzip -oq "$TMP" -d "$EXT_DIR"
  rm -f "$TMP"
  [ -d "$EXT_DIR/schemas" ] && glib-compile-schemas "$EXT_DIR/schemas" || true
  echo "Installed to $EXT_DIR"
else
  echo "Dash-to-Dock already installed."
fi

# Enable it. On Wayland the running Shell hasn't scanned a freshly-extracted dir
# yet, so `gnome-extensions enable` fails with "does not exist" until the next
# login. We don't hand-edit enabled-extensions (a misread there would silently
# disable your other extensions), so finish enabling after relogin if needed.
if ! gnome-extensions enable "$DTD" 2>/dev/null; then
  NEED_ENABLE=1
fi

# ---------- 2. configure the content-sized floating dock ---------------------
echo "Configuring content-sized dock (position $POSITION, icon ${ICON}px) ..."
# extend-height=false is THE content-sizing switch: the dock width tracks the
# number of icons instead of filling the whole edge.
dconf write "$DD/extend-height"            false
dconf write "$DD/dock-position"            "'$POSITION'"
dconf write "$DD/dock-fixed"               false
dconf write "$DD/intellihide"              "$AUTOHIDE"
dconf write "$DD/autohide"                 "$AUTOHIDE"
dconf write "$DD/autohide-in-fullscreen"   true
dconf write "$DD/require-pressure-to-show" true
dconf write "$DD/dash-max-icon-size"       "$ICON"
dconf write "$DD/custom-theme-shrink"      true
dconf write "$DD/show-show-apps-button"    false
dconf write "$DD/show-apps-at-top"         false
dconf write "$DD/multi-monitor"            true
dconf write "$DD/isolate-workspaces"       false
dconf write "$DD/click-action"             "'minimize'"
dconf write "$DD/scroll-action"            "'cycle-windows'"
dconf write "$DD/running-indicator-style"  "'DOTS'"
# Frosted Catppuccin Mocha background
dconf write "$DD/apply-custom-theme"       false
dconf write "$DD/transparency-mode"        "'FIXED'"
dconf write "$DD/background-opacity"       "$OPACITY"
dconf write "$DD/custom-background-color"  true
dconf write "$DD/background-color"         "'$BASE'"
dconf write "$DD/unity-backlit-items"      false
# Accent the running dots (best-effort; key exists on recent Dash-to-Dock)
dconf write "$DD/custom-theme-customize-running-dots" true 2>/dev/null || true
dconf write "$DD/custom-theme-running-dots-color"     "'$MAUVE'" 2>/dev/null || true

# blur-my-shell frosts the dock too, if enabled
if gnome-extensions list --enabled 2>/dev/null | grep -qx "blur-my-shell@aunetx"; then
  dconf write /org/gnome/shell/extensions/blur-my-shell/dash-to-dock/blur-original-dash true 2>/dev/null || true
fi

# ---------- 3. (opt-in) hand app icons over to the dock ----------------------
# Off by default: hiding D2P's taskbar BEFORE the dock is actually running would
# leave you with no app icons anywhere until the dock loads. Once you've
# confirmed the dock works, re-run with HIDE_D2P_TASKBAR=true to de-duplicate.
if [ "${HIDE_D2P_TASKBAR:-false}" = "true" ]; then
  echo "Hiding Dash-to-Panel's app icons (kept: clock, tray, system menu)."
  set_d2p_taskbar false
else
  echo "Keeping Dash-to-Panel's app icons for now (no iconless gap)."
  echo "After the dock works, de-duplicate with:"
  echo "  HIDE_D2P_TASKBAR=true bash setup/install-content-dock.sh"
fi

echo
echo "Done. Dash-to-Dock files + settings are staged."
if [ "${NEED_ENABLE:-0}" = "1" ]; then
  echo "FINISH ENABLING (Wayland needs a relogin to see the new extension):"
  echo "  1. Log out + back in."
  echo "  2. Toggle 'Dash to Dock' on in the Extensions app,"
  echo "     or run:  gnome-extensions enable $DTD"
else
  echo "Enabled. Log out + back in to load the dock."
fi
echo "The dock auto-sizes to its icons and grows as you open apps."
echo "Revert with: bash setup/install-content-dock.sh --revert"
