#!/usr/bin/env bash
# Safe, staged disk reclaim for rl-root:
#   Stage 1  prune docker build cache + dangling images   (safe, ~10G, keeps active images/volumes)
#   Stage 2  relocate docker + containerd stores root->home via bind mount (sudo keep-alive; no data loss)
#   Stage 3  remove the 9.1G orphan left by the failed Jun 30 attempt (after you verify)
# Each stage prompts. Nothing destructive to ACTIVE images, containers, or volumes.
# Run:  bash ~/coding/scripts/disk-cleanup-and-relocate.sh
set -euo pipefail

LOG="/home/deva/coding/scripts/disk-cleanup-and-relocate.log"
: > "$LOG"; exec > >(tee -a "$LOG") 2>&1
BASE=/home/.system
log(){ printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

log "BEFORE"; df -hT / /home

# --- sudo + keep-alive (this is what the old script lacked: creds never expire mid-rsync) ---
sudo -v
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
KEEPALIVE=$!
trap 'kill "$KEEPALIVE" 2>/dev/null || true' EXIT

# ============================ STAGE 1 — PRUNE (safe) ============================
log "STAGE 1: docker prune (build cache + dangling images only)"
docker system df || true
read -rp "Prune build cache + dangling images? Keeps all active images + volumes. yes/skip: " a
if [ "$a" = yes ]; then
  docker builder prune -f
  docker image prune -f          # dangling (untagged) only — NOT -a
  docker container prune -f       # exited containers only
  echo "Stage 1 done."; docker system df
else echo "skipped stage 1"; fi

# ============================ STAGE 2 — RELOCATE ============================
# rsync to home, rename original to .old (instant, same fs, no space doubling), bind mount, fstab.
relocate_dir(){
  local SRC="$1" DST="$BASE$1"
  [ -d "$SRC" ] || { echo "skip $SRC (absent)"; return 0; }
  mountpoint -q "$SRC" && { echo "skip $SRC (already relocated)"; return 0; }
  log "Relocating $SRC -> $DST"
  sudo mkdir -p "$DST"
  sudo rsync -aHAX --info=progress2 "$SRC"/ "$DST"/
  sudo mv "$SRC" "${SRC}.old"          # rename = free, original kept as backup
  sudo mkdir -p "$SRC"
  grep -qF "$DST  $SRC" /etc/fstab || echo "$DST  $SRC  none  bind  0 0" | sudo tee -a /etc/fstab >/dev/null
  sudo mount --bind "$DST" "$SRC"
  sudo restorecon -R "$SRC" 2>/dev/null || true
  echo "done: $SRC bind-mounted from $DST (.old backup kept on root)"
}

log "STAGE 2: relocate docker + containerd (stops docker first)"
read -rp "Stop docker+containerd and relocate their stores to /home? yes/skip: " a
if [ "$a" = yes ]; then
  # the failed Jun 30 partial would corrupt a fresh rsync — remove it first
  if [ -d "$BASE/var/lib/docker" ] && ! mountpoint -q /var/lib/docker; then
    echo "removing stale Jun-30 docker partial at $BASE/var/lib/docker"
    sudo rm -rf "$BASE/var/lib/docker"
  fi
  sudo systemctl stop docker.socket 2>/dev/null || true
  sudo systemctl stop docker 2>/dev/null || true
  sudo systemctl stop containerd 2>/dev/null || true
  relocate_dir /var/lib/containerd
  relocate_dir /var/lib/docker
  sudo systemctl start containerd 2>/dev/null || true
  sudo systemctl start docker 2>/dev/null || true
  sleep 3
  if docker info >/dev/null 2>&1 && [ "$(docker images -q | wc -l)" -gt 0 ]; then
    echo "docker OK, images intact"
  else
    echo "WARN: verify docker manually before Stage 3"
  fi
else echo "skipped stage 2"; fi

# ============================ STAGE 3 — RECLAIM BACKUPS ============================
log "STAGE 3: delete .old backups on root (ONLY after you verified docker works)"
df -hT /
echo "Backups still consuming root space:"
sudo find /var/lib -maxdepth 1 -name '*.old' 2>/dev/null || true
read -rp "Docker verified working? Delete .old backups to reclaim root space? yes/skip: " a
if [ "$a" = yes ]; then
  sudo rm -rf /var/lib/docker.old /var/lib/containerd.old
  echo "backups removed."
else echo "skipped stage 3 — reclaim later with: sudo rm -rf /var/lib/{docker,containerd}.old"; fi

log "AFTER"; df -hT / /home
echo "DONE."
