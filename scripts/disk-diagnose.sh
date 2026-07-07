#!/usr/bin/env bash
# Diagnose what fills root (/) filesystem. READ-ONLY. Safe.
set -euo pipefail

LOGFILE="/home/deva/coding/scripts/disk-diagnose.log"
: > "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

echo "===== df root ====="
df -hT /

echo
echo "===== top dirs on / (root-owned included) ====="
sudo du -xhd1 / 2>/dev/null | sort -rh | head -20

echo
echo "===== top dirs in /var ====="
sudo du -xhd1 /var 2>/dev/null | sort -rh | head -15

echo
echo "===== top dirs in /usr ====="
sudo du -xhd1 /usr 2>/dev/null | sort -rh | head -10

echo
echo "===== biggest single files on / ====="
sudo find / -xdev -type f -size +200M 2>/dev/null -exec du -h {} + | sort -rh | head -20

echo
echo "===== journal / dnf / flatpak reclaimable ====="
journalctl --disk-usage 2>/dev/null || true
echo "flatpak unused runtimes:"
flatpak uninstall --unused --assumeno 2>/dev/null || echo "  (none or flatpak not user-visible under sudo)"

echo
echo "===== old kernels (keep newest 1-2) ====="
rpm -q kernel 2>/dev/null
echo "running: $(uname -r)"
