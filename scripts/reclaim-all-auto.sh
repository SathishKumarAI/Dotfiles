#!/usr/bin/env bash
# Auto reclaim: remove duplicate rpm VS Code (keep Flatpak), prune docker+podman unused,
# flatpak unused runtimes, dnf orphans + cache. No per-step prompts. One sudo password.
# Removes ONLY unused images/cache/orphans + the rpm 'code'. Volumes NOT touched.
# Run:  bash ~/coding/scripts/reclaim-all-auto.sh
set -uo pipefail   # not -e: keep going if one step fails

LOGFILE="/home/deva/coding/scripts/reclaim-all-auto.log"
: > "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1
log(){ printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

sudo -v
log "BEFORE df /"; df -hT /

log "Remove duplicate rpm VS Code (keeping Flatpak com.visualstudio.code)"
if rpm -q code >/dev/null 2>&1; then
  sudo dnf remove -y code
else echo "no rpm 'code' installed"; fi

log "Flatpak: uninstall unused runtimes"
flatpak uninstall --unused -y || true

log "Docker: df before"
sudo docker system df 2>/dev/null || echo "(docker n/a)"
log "Docker: prune unused images + build cache (NOT volumes)"
sudo docker system prune -af || true

log "Podman: prune unused"
sudo podman system prune -af 2>/dev/null || echo "(podman n/a)"

log "dnf autoremove orphans"
sudo dnf autoremove -y || true

log "dnf clean all"
sudo dnf clean all || true

log "AFTER df /"; df -hT /
echo "DONE."
