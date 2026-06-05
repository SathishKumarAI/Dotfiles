#!/bin/bash
# Set up keyboard shortcut for rofi app launcher
# Binds Super+Space to launch rofi (app search)
# Run with: bash setup-rofi-keybind.sh
#
# NOTE: The canonical, chezmoi-managed launcher is
#   chezmoi/.chezmoiscripts/run_onchange_after_gnome-launcher.sh
# which binds Ctrl+Alt+Space (Super absent on some Dell kbds). This script is a
# standalone Super+Space alternative; running both gives you two launch keys.
#
# Both must wrap rofi in `env -u WAYLAND_DISPLAY`: GNOME/Mutter does not
# implement wlr-layer-shell, so native-Wayland rofi aborts with
# "Rofi on wayland requires support for the layer shell protocol".
# Dropping WAYLAND_DISPLAY forces rofi onto its X11 (XWayland) backend.

set -euo pipefail

KEYBIND_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

# Find the next available custom keybinding slot
EXISTING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
echo "Current custom keybindings: $EXISTING"

# Determine next slot number
NEXT_SLOT=0
while echo "$EXISTING" | grep -q "custom${NEXT_SLOT}"; do
    NEXT_SLOT=$((NEXT_SLOT + 1))
done

SLOT_PATH="${KEYBIND_PATH}/custom${NEXT_SLOT}/"
echo "Using slot: custom${NEXT_SLOT}"

# Check if rofi shortcut already exists
for i in $(seq 0 $((NEXT_SLOT - 1))); do
    EXISTING_CMD=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KEYBIND_PATH}/custom${i}/ command 2>/dev/null || true)
    if echo "$EXISTING_CMD" | grep -q "rofi"; then
        echo "Rofi keybinding already exists at custom${i}, updating it..."
        SLOT_PATH="${KEYBIND_PATH}/custom${i}/"
        NEXT_SLOT=$i
        break
    fi
done

# Set the keybinding
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH} \
    name "Rofi App Launcher"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH} \
    command "env -u WAYLAND_DISPLAY rofi -show drun -show-icons"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH} \
    binding "<Super>space"

# Register the slot in the custom keybindings list (if new)
if ! echo "$EXISTING" | grep -q "custom${NEXT_SLOT}"; then
    # Build new list including our slot
    if [ "$EXISTING" = "@as []" ]; then
        NEW_LIST="['${SLOT_PATH}']"
    else
        NEW_LIST="${EXISTING%]}, '${SLOT_PATH}']"
    fi
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
fi

echo ""
echo "=== Rofi keyboard shortcut configured ==="
echo "  Shortcut: Super + Space  →  rofi app launcher"
echo ""
echo "Other useful rofi shortcuts you can add manually:"
echo "  rofi -show window -show-icons    → switch windows"
echo "  rofi -show filebrowser           → browse files"
echo "  rofi -show run                   → run commands"
echo ""
echo "Test it now: press Super+Space"
