#!/usr/bin/env bash
# Extra root reclaim WITHOUT relocating: prune unused flatpak runtimes, docker/podman
# images, dnf orphans. Each step gated + measured. Safe (removes only unused/cache).
# Run:  bash ~/coding/scripts/reclaim-more.sh
set -euo pipefail

LOGFILE="/home/deva/coding/scripts/reclaim-more.log"
: > "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1
log(){ printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
ask(){ read -rp "$1 [y/N]: " r; [ "$r" = y ]; }

sudo -v
log "BEFORE df /"; df -hT /

log "Flatpak unused runtimes"
flatpak list --runtime --columns=application,version 2>/dev/null || true
if ask "Remove unused flatpak runtimes?"; then
  flatpak uninstall --unused -y || true
fi

log "Docker disk usage"
sudo docker system df 2>/dev/null || echo "(docker n/a)"
if ask "docker system prune -af (unused images + build cache, NOT volumes)?"; then
  sudo docker system prune -af || true
fi

log "Podman disk usage"
sudo podman system df 2>/dev/null || echo "(podman n/a)"
if ask "podman system prune -af (unused images/containers)?"; then
  sudo podman system prune -af || true
fi

log "dnf autoremove (orphaned deps)"
sudo dnf autoremove --assumeno 2>/dev/null | tail -20 || true
if ask "Run dnf autoremove for real?"; then
  sudo dnf autoremove -y || true
fi

log "Duplicate VS Code check"
rpm -q code 2>/dev/null && echo "rpm 'code' present" || echo "no rpm code"
flatpak info com.visualstudio.code >/dev/null 2>&1 && echo "flatpak VS Code present" || echo "no flatpak VS Code"
echo "You run BOTH. To drop the rpm one:  sudo dnf remove -y code"
echo "Or drop flatpak one:  flatpak uninstall -y com.visualstudio.code"
echo "(not auto-removing — pick which you keep)"

log "dnf clean all"
sudo dnf clean all || true

log "AFTER df /"; df -hT /
echo "DONE."
