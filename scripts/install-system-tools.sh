#!/usr/bin/env bash
# install-system-tools.sh — RAM/OOM protection for Rocky Linux 10.
# Prevents the "everything swaps and thrashes" slowdown. Idempotent — safe to re-run.
# Run:  bash ~/coding/scripts/install-system-tools.sh
set -euo pipefail
[[ $EUID -eq 0 ]] && { echo "run as your user (script calls sudo itself)"; exit 1; }

echo "==> 1/4  zram — compressed RAM swap (replaces slow disk-swap thrash)"
sudo dnf install -y zram-generator zram-generator-defaults 2>/dev/null || sudo dnf install -y zram-generator
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
# Compressed swap in RAM. Used before the disk swap partition, so far less thrash.
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
EOF
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service
echo "    zram now:"; zramctl || true

echo "==> 2/4  systemd-oomd — native early-OOM killer (kills worst hog before freeze)"
sudo dnf install -y systemd-oomd-defaults 2>/dev/null || true
sudo systemctl enable --now systemd-oomd
# act when swap is mostly full or a cgroup is under heavy memory pressure
sudo mkdir -p /etc/systemd/oomd.conf.d
sudo tee /etc/systemd/oomd.conf.d/override.conf >/dev/null <<'EOF'
[OOM]
SwapUsedLimit=85%
DefaultMemoryPressureLimit=60%
DefaultMemoryPressureDurationSec=20s
EOF
sudo systemctl restart systemd-oomd
echo "    systemd-oomd: $(systemctl is-active systemd-oomd)"

echo "==> 3/4  earlyoom — simple userspace backup OOM killer (optional; enable if you prefer it over oomd)"
sudo dnf install -y earlyoom
# not enabled by default to avoid double-killing with systemd-oomd.
# to use earlyoom instead of oomd:  sudo systemctl disable --now systemd-oomd && sudo systemctl enable --now earlyoom
echo "    earlyoom installed (disabled). See comment above to switch."

echo "==> 4/4  reduce swappiness — prefer keeping pages in RAM"
echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf

echo
echo "DONE. Monitors already present: btop, htop, lazydocker, ctop, glances."
echo "Verify:  swapon --show   (zram0 should appear with higher PRIO than the disk partition)"
