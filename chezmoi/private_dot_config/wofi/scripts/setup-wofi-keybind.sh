#!/usr/bin/env bash
# Set up a keyboard shortcut for the wofi app launcher.
# Binds Super+Space to launch wofi (drun / app search).
# Run with: bash setup-wofi-keybind.sh
set -euo pipefail

KEYBIND_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
LAUNCH_CMD="wofi --show drun"
BINDING="<Super>space"

EXISTING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
echo "Current custom keybindings: $EXISTING"

# Find the next free custom slot.
NEXT_SLOT=0
while echo "$EXISTING" | grep -q "custom${NEXT_SLOT}"; do
    NEXT_SLOT=$((NEXT_SLOT + 1))
done

SLOT_PATH="${KEYBIND_PATH}/custom${NEXT_SLOT}/"
echo "Using slot: custom${NEXT_SLOT}"

# Reuse an existing slot if one already holds wofi OR is bound to our target key
# (e.g. a leftover rofi binding on Super+Space) so we don't create a duplicate.
for i in $(seq 0 $((NEXT_SLOT - 1))); do
    SLOT="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${KEYBIND_PATH}/custom${i}/"
    EXISTING_CMD=$(gsettings get "$SLOT" command 2>/dev/null || true)
    EXISTING_BIND=$(gsettings get "$SLOT" binding 2>/dev/null || true)
    if echo "$EXISTING_CMD" | grep -q "wofi" || [ "$EXISTING_BIND" = "'${BINDING}'" ]; then
        echo "Reusing custom${i} (was: cmd=${EXISTING_CMD} binding=${EXISTING_BIND})"
        SLOT_PATH="${KEYBIND_PATH}/custom${i}/"
        NEXT_SLOT=$i
        break
    fi
done

gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH}" \
    name "Wofi App Launcher"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH}" \
    command "$LAUNCH_CMD"
gsettings set "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${SLOT_PATH}" \
    binding "$BINDING"

# Register the slot in the list if it is new.
if ! echo "$EXISTING" | grep -q "custom${NEXT_SLOT}"; then
    if [ "$EXISTING" = "@as []" ]; then
        NEW_LIST="['${SLOT_PATH}']"
    else
        NEW_LIST="${EXISTING%]}, '${SLOT_PATH}']"
    fi
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW_LIST"
fi

echo ""
echo "=== Wofi keyboard shortcut configured ==="
echo "  Shortcut: Super + Space  ->  wofi app launcher"
echo ""
echo "Other useful wofi modes you can bind:"
echo "  wofi --show run      -> run a command"
echo "  wofi --show window   -> switch windows (sway/wlroots compositors)"
echo ""
echo "Test it now: press Super + Space"
