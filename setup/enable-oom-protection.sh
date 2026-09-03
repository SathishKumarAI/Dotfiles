#!/usr/bin/env bash
# enable-oom-protection.sh — stop a runaway app (Chrome, a build) from HARD-FREEZING
# the desktop. This box has 15G RAM + DISK swap (LVM /dev/dm-1) + swappiness=10 and
# NO userspace OOM daemon: under real memory pressure the kernel thrashes the disk
# swap and the whole session locks up instead of killing the offender.
#
# What this does (idempotent, reversible):
#   1. Enables systemd-oomd — kills the greediest cgroup BEFORE the box freezes.
#   2. Turns on swap-based pressure kill for the user session slice.
#   3. Bumps swappiness a touch (10 -> 30): swap a bit earlier so pressure builds
#      gradually instead of hitting a wall. Persisted via sysctl drop-in.
#
# Run:  sudo bash setup/enable-oom-protection.sh
# Undo: sudo systemctl disable --now systemd-oomd; sudo rm /etc/sysctl.d/90-swappiness.conf \
#         /etc/systemd/system/user@.service.d/oomd.conf
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run with sudo"; exit 1; }

echo "==> enabling systemd-oomd"
systemctl enable --now systemd-oomd

echo "==> swap-pressure kill on the user session slice"
install -d /etc/systemd/system/user@.service.d
cat > /etc/systemd/system/user@.service.d/oomd.conf <<'EOF'
[Service]
ManagedOOMSwap=kill
ManagedOOMMemoryPressure=kill
ManagedOOMMemoryPressureLimit=80%
EOF

echo "==> swappiness 10 -> 30 (persisted)"
echo 'vm.swappiness=30' > /etc/sysctl.d/90-swappiness.conf
sysctl -p /etc/sysctl.d/90-swappiness.conf

systemctl daemon-reload
echo
echo "done. systemd-oomd active: $(systemctl is-active systemd-oomd)"
echo "swappiness now: $(cat /proc/sys/vm/swappiness)"
echo "A greedy Chrome will now be killed instead of freezing the desktop."
