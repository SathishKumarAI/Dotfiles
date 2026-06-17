#!/usr/bin/env bash
# verify-keyboard.sh — confirm the external keyboard emits correct modifier keycodes.
# Why: "shortcuts dead in all apps" with a clean system usually means the keyboard
# sends wrong/missing modifier events. This captures raw libinput events so we see
# exactly what each key produces, independent of any app.
#
# Usage:  sudo bash setup/verify-keyboard.sh
# Then press, one at a time, watching the keycode column:
#   Left Ctrl   -> expect  KEY_LEFTCTRL   (+1 press / 0 release)
#   Left Shift  -> expect  KEY_LEFTSHIFT
#   Left Alt    -> expect  KEY_LEFTALT
#   d           -> expect  KEY_D
#   Ctrl+Shift+d (hold all three) -> expect 3 separate +1 lines
# Ctrl-C to stop.

set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Need root to read input devices. Re-run: sudo bash setup/verify-keyboard.sh" >&2
  exit 1
fi

echo "=== Detected keyboards ==="
grep -iB1 -A4 'kbd' /proc/bus/input/devices | grep -iE 'Name=|Handlers=' || true
echo
echo "=== Live key events (press the combos above; Ctrl-C to quit) ==="
echo "Look at the KEY_* names and the +1 (press) / 0 (release) values."
echo
exec libinput debug-events --show-keycodes
