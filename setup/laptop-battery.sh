#!/usr/bin/env bash
# Battery-saver setup for this laptop (Intel Skylake ultrabook).
# Installs the TLP drop-in config + powertop, makes sure no conflicting
# power daemon runs, and applies it. Run as your normal user (sudo inside).
#
#   bash setup/laptop-battery.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DROPIN="$HERE/tlp/01-battery-saver.conf"

# 1. Packages: TLP + powertop (diagnostics) + thermald (Intel thermal mgmt).
echo "==> installing tlp, powertop, thermald"
sudo pacman -S --needed --noconfirm tlp powertop thermald

# 2. Avoid conflicts: power-profiles-daemon fights TLP. Mask it if present.
if systemctl list-unit-files power-profiles-daemon.service >/dev/null 2>&1; then
    echo "==> masking power-profiles-daemon (conflicts with TLP)"
    sudo systemctl mask --now power-profiles-daemon.service 2>/dev/null || true
fi

# 3. Install the battery-saver drop-in.
echo "==> installing /etc/tlp.d/01-battery-saver.conf"
sudo install -Dm644 "$DROPIN" /etc/tlp.d/01-battery-saver.conf

# 4. Enable + (re)start TLP. thermald helps keep the CPU cool/efficient.
echo "==> enabling tlp + thermald"
sudo systemctl enable --now tlp.service
sudo systemctl enable --now thermald.service
sudo tlp start

echo
echo "Done. Verify with:"
echo "  tlp-stat -s      # status + mode (AC vs BAT)"
echo "  tlp-stat -p      # CPU/processor power settings in effect"
echo "  powertop         # live power draw + tunables (run on battery)"
echo
echo "Charge thresholds (stop at 80% for battery health) are DISABLED by"
echo "default in the drop-in — uncomment them there if you want longevity."
