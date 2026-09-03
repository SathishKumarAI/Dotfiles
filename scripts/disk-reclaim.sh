#!/usr/bin/env bash
# Reclaim root (/) space WITHOUT touching LVM. Option C: relocate + safe cleanup.
# - Shows full disk picture (reveals hidden root-owned space)
# - Safe reclaim: dnf cache, old kernels (keep 2), journal vacuum
# - Relocates /var/lib/flatpak (13G) to /home via bind mount (reversible, keeps backup)
# Run:  bash ~/coding/scripts/disk-reclaim.sh
set -euo pipefail

# Log everything to a file Claude can Read (interactive prompts still show on terminal)
LOGFILE="/home/deva/coding/scripts/disk-reclaim.log"
: > "$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

log(){ printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }
need_sudo(){ sudo -v; }

need_sudo

log "BEFORE: df /"
df -hT /

log "Full picture: top dirs on / (root-owned)"
sudo du -xhd1 / 2>/dev/null | sort -rh | head -20
log "Top dirs in /var"
sudo du -xhd1 /var 2>/dev/null | sort -rh | head -15
log "Files >200M on /"
sudo find / -xdev -type f -size +200M 2>/dev/null -exec du -h {} + | sort -rh | head -20

# ---------- SAFE CLEANUP (no data loss) ----------
log "dnf clean all"
sudo dnf clean all || true

log "journal vacuum to 200M"
sudo journalctl --vacuum-size=200M || true

log "Remove old kernels (keep 2 newest)"
sudo dnf install -y dnf-plugins-core >/dev/null 2>&1 || true
sudo dnf remove -y --oldinstallonly --setopt installonly_limit=2 kernel 2>/dev/null || \
  echo "  (nothing to remove or plugin missing; skip)"

# ---------- RELOCATE FLATPAK -> /home (bind mount) ----------
SRC=/var/lib/flatpak
DST=/home/.system/flatpak
if mountpoint -q "$SRC"; then
  echo "$SRC already a mountpoint (already relocated). Skipping."
else
  log "Relocate $SRC (13G) -> $DST via bind mount"
  echo "IMPORTANT: close all Flatpak apps (VS Code, etc.) before continuing."
  read -rp "Flatpak apps closed? type yes to proceed: " ok
  [ "$ok" = "yes" ] || { echo "Aborted by user."; exit 1; }

  sudo mkdir -p "$DST"
  echo "Copying (preserves perms + SELinux xattrs)..."
  sudo rsync -aHAX --info=progress2 "$SRC"/ "$DST"/

  # keep original as backup until verified
  sudo mv "$SRC" "${SRC}.old"
  sudo mkdir -p "$SRC"

  # persistent bind mount
  FSTAB_LINE="$DST  $SRC  none  bind  0 0"
  if ! grep -qF "$DST  $SRC" /etc/fstab; then
    echo "$FSTAB_LINE" | sudo tee -a /etc/fstab >/dev/null
  fi
  sudo mount --bind "$DST" "$SRC"
  sudo restorecon -Rv "$SRC" >/dev/null 2>&1 || true

  echo "Bind mount active. Verifying flatpak..."
  flatpak list >/dev/null 2>&1 && echo "flatpak OK" || echo "WARN: verify flatpak manually"
fi

log "AFTER: df /"
df -hT /

cat <<'EOF'

DONE (safe steps). Backup kept at /var/lib/flatpak.old
Verify apps work (open VS Code etc.), then reclaim the backup:
    sudo rm -rf /var/lib/flatpak.old
To UNDO relocation: remove the fstab bind line, `sudo umount /var/lib/flatpak`,
    `sudo rm -rf /var/lib/flatpak && sudo mv /var/lib/flatpak.old /var/lib/flatpak`
EOF
