#!/usr/bin/env bash
# setup-zram.sh — fix swap-thrash lag on the no-SSD box (Rocky 10).
#
# Problem: this machine has 16 GB RAM and NO SSD — swap is a partition on the
# 7200rpm HDD (sda). When Chrome (10+ GB across dozens of procs) overflows RAM,
# pages spill to that disk and every tab switch stalls on disk I/O (load spikes
# while CPU sits idle = iowait). swappiness is already low; the issue is WHERE
# swap lives, not how eager it is.
#
# Fix (two parts, both reversible):
#   1. zram   — a compressed RAM-backed swap device (lz4). Swapping now happens
#               in RAM at ~3:1 compression instead of hitting the HDD. Given it
#               higher priority than the disk swap so the kernel uses it first.
#   2. oomd   — enable systemd-oomd so a runaway hog gets killed BEFORE the whole
#               desktop thrashes to a halt.
#
# Run as your normal user; it uses sudo only where needed:
#   bash setup/setup-zram.sh
#   bash setup/setup-zram.sh --status   # show current zram + swap
#   bash setup/setup-zram.sh --revert   # remove zram config, re-mask oomd
#
# Takes effect on next boot (or `sudo systemctl start systemd-zram-setup@zram0`).

set -euo pipefail

CONF=/etc/systemd/zram-generator.conf

status() {
  echo "=== swap devices (PRIO: higher = used first) ==="; swapon --show || cat /proc/swaps
  echo "=== zram ==="; zramctl 2>/dev/null || echo "no zram active"
  echo "=== systemd-oomd ==="; systemctl is-active systemd-oomd 2>/dev/null || true
  echo "=== swappiness ==="; cat /proc/sys/vm/swappiness
}

case "${1:-}" in
  --status) status; exit 0 ;;
  --revert)
    echo "==> Removing zram config + reverting oomd"
    sudo rm -f "$CONF"
    sudo systemctl stop systemd-zram-setup@zram0.service 2>/dev/null || true
    sudo swapoff /dev/zram0 2>/dev/null || true
    sudo systemctl disable --now systemd-oomd 2>/dev/null || true
    echo "Done. Disk swap remains. Reboot for a fully clean state."
    exit 0 ;;
  "") : ;;
  *) echo "unknown arg: $1" >&2; exit 2 ;;
esac

# 1. Install the generator (Rocky/Fedora package name).
if ! rpm -q zram-generator >/dev/null 2>&1; then
  echo "==> Installing zram-generator"
  sudo dnf install -y zram-generator zram-generator-defaults 2>/dev/null \
    || sudo dnf install -y zram-generator
fi

# 2. Configure: zram size = half of RAM (compresses ~3x, so effective is more),
#    capped at 8 GB. lz4 = fast. zram-fraction handles the sizing dynamically.
echo "==> Writing $CONF"
sudo tee "$CONF" >/dev/null <<'EOF'
# Compressed RAM swap so the box stops swapping to the spinning HDD.
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = lz4
# Higher priority than the HDD swap partition so the kernel fills zram first.
swap-priority = 100
EOF

# 3. zram works best with a swap-leaning policy ONCE swap is fast (RAM-backed).
#    Bump swappiness so the kernel prefers compressing cold pages into zram over
#    evicting file cache. Persist it.
echo "==> Setting vm.swappiness=100 (safe now that swap is RAM-backed zram)"
echo 'vm.swappiness=100' | sudo tee /etc/sysctl.d/99-zram-swappiness.conf >/dev/null
sudo sysctl -w vm.swappiness=100 >/dev/null

# 4. OOM guard so a hog dies before the desktop locks up.
echo "==> Enabling systemd-oomd"
sudo systemctl enable --now systemd-oomd 2>/dev/null || echo "   (systemd-oomd unavailable — skipping)"

# 5. Start zram now (also auto-starts at boot via the generator).
echo "==> Activating zram0"
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service 2>/dev/null || true

echo
status
echo
cat <<'EOF'
==> Done. zram0 should show in the swap list at PRIO 100 (used before the HDD).
    Reboot for the cleanest result. Revert any time: setup/setup-zram.sh --revert

    This treats the symptom. The structural fix is an SSD — moving / and /home
    off the 7200rpm HDD removes the bottleneck entirely. Until then, the biggest
    live win is fewer Chrome tabs (it was using ~10.6 GB across 68 processes).
EOF
