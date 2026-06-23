#!/usr/bin/env bash
# speedup-boot.sh — trim the slowest boot units on Rocky 10. Needs root:
#
#   sudo bash setup/speedup-boot.sh
#
# Boot was ~4m40s of userspace. The fixable offenders (from systemd-analyze):
#   docker.service       17s  — started eagerly at boot even when unused
#   containerd.service   13s  — pulled in by docker.service
#   plocate-updatedb     16s  — the `locate` DB rebuild, runs via a timer
# We switch Docker to socket-activation (starts on first `docker` use instead of
# at boot) and stop the plocate timer. Everything reversible (printed at the end).
# We do NOT touch plymouth-quit-wait (30s) — that's the boot splash waiting on
# the display, harmless to leave.
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo: sudo bash setup/speedup-boot.sh"; exit 1; }

echo "==> Docker: boot-start -> socket activation"
if systemctl is-enabled docker.service >/dev/null 2>&1; then
    systemctl disable docker.service
    systemctl enable docker.socket
    echo "    + docker now starts on first use (docker.socket), not at boot"
    echo "      containerd.service follows docker, so it stops booting eagerly too"
else
    echo "    . docker.service already not boot-enabled — skipped"
fi

echo "==> plocate: stop the updatedb timer"
if systemctl is-enabled plocate-updatedb.timer >/dev/null 2>&1; then
    systemctl disable --now plocate-updatedb.timer
    echo "    + plocate-updatedb.timer disabled (run 'updatedb' by hand if you use 'locate')"
else
    echo "    . plocate-updatedb.timer already disabled — skipped"
fi

cat <<'EOF'

==> Done. Effect shows on the NEXT reboot. Re-check with: systemd-analyze blame

   Revert anytime:
       sudo systemctl enable --now docker.service
       sudo systemctl disable docker.socket
       sudo systemctl enable --now plocate-updatedb.timer
EOF
