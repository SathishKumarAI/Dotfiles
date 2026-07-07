#!/usr/bin/env bash
# Relocate large app dirs from root (/) to /home via bind mounts. Paths stay identical.
# Reversible: originals kept as <dir>.old until you verify + delete. SELinux xattrs preserved.
# Run:  bash ~/coding/scripts/disk-relocate-all.sh
set -euo pipefail

LOGFILE="/home/deva/coding/scripts/disk-relocate-all.log"
: > "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

BASE=/home/.system            # relocation target root, lives on the big /home LV
log(){ printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

sudo -v

log "BEFORE df /"
df -hT /

log "Sizes of relocation candidates"
for d in /var/lib/flatpak /var/lib/docker /var/lib/containerd /usr/local/lib/ollama /usr/share/ollama; do
  [ -e "$d" ] && sudo du -sh "$d" 2>/dev/null || true
done

# relocate_dir <path> : rsync to $BASE/<path>, backup original, bind mount, fstab, restorecon
relocate_dir(){
  local SRC="$1" DST="$BASE$1"
  if [ ! -d "$SRC" ]; then echo "skip $SRC (absent)"; return 0; fi
  if mountpoint -q "$SRC"; then echo "skip $SRC (already relocated)"; return 0; fi
  log "Relocating $SRC -> $DST"
  sudo mkdir -p "$DST"
  sudo rsync -aHAX --info=progress2 "$SRC"/ "$DST"/
  sudo mv "$SRC" "${SRC}.old"
  sudo mkdir -p "$SRC"
  grep -qF "$DST  $SRC" /etc/fstab || echo "$DST  $SRC  none  bind  0 0" | sudo tee -a /etc/fstab >/dev/null
  sudo mount --bind "$DST" "$SRC"
  sudo restorecon -R "$SRC" 2>/dev/null || true
  echo "done: $SRC now bind-mounted from $DST"
}

# ---------- FLATPAK (no daemon; just close apps) ----------
log "FLATPAK section"
read -rp "Close all Flatpak apps (VS Code etc). Relocate flatpak? yes/skip: " a
[ "$a" = yes ] && relocate_dir /var/lib/flatpak || echo "skipped flatpak"

# ---------- CONTAINERS (stop daemons first) ----------
log "CONTAINER section (docker + containerd)"
read -rp "Stop docker+containerd and relocate their stores? yes/skip: " a
if [ "$a" = yes ]; then
  echo "stopping daemons..."
  sudo systemctl stop docker.socket 2>/dev/null || true
  sudo systemctl stop docker 2>/dev/null || true
  sudo systemctl stop containerd 2>/dev/null || true
  relocate_dir /var/lib/docker
  relocate_dir /var/lib/containerd
  echo "restarting daemons..."
  sudo systemctl start containerd 2>/dev/null || true
  sudo systemctl start docker 2>/dev/null || true
  docker info >/dev/null 2>&1 && echo "docker OK" || echo "WARN verify docker manually"
else echo "skipped containers"; fi

# (ollama removed via uninstall-ollama.sh, not relocated)

# ---------- /opt (browsers etc; close them first) ----------
log "OPT section (brave, chrome, google)"
read -rp "Close browsers (Brave/Chrome). Relocate /opt? yes/skip: " a
[ "$a" = yes ] && relocate_dir /opt || echo "skipped /opt"

log "AFTER df /"
df -hT /
log "Relocated targets (.old backups kept)"
find /var/lib /usr/local/lib /usr/share -maxdepth 3 -name '*.old' -maxdepth 4 2>/dev/null | grep '\.old$' || true

cat <<'EOF'

DONE. Each moved dir has a <dir>.old backup on ROOT still taking space.
VERIFY everything works (open VS Code, `docker run hello-world`, `ollama list`),
THEN reclaim the backups:
    sudo rm -rf /var/lib/flatpak.old /var/lib/docker.old /var/lib/containerd.old \
                /usr/local/lib/ollama.old /usr/share/ollama.old /opt.old
UNDO one: umount the path, rm the empty dir, mv the .old back, remove its /etc/fstab bind line.
EOF
