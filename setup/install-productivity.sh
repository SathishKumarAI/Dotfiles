#!/usr/bin/env bash
# install-productivity.sh — office + deep-work productivity apps (Flatpak/Flathub).
# Matches the existing GUI-app pattern in this repo: all system Flatpaks from flathub.
#
# Usage:
#     bash setup/install-productivity.sh            # install everything below
#     bash setup/install-productivity.sh --dry-run  # list apps, install nothing
#
# Needs sudo for system-scope flatpak installs. Each app installs independently;
# one failure won't abort the rest.
set -uo pipefail

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

# id|name|category
APPS=(
  "org.libreoffice.LibreOffice|LibreOffice|Office suite"
  "org.onlyoffice.desktopeditors|ONLYOFFICE|Office suite (MS Office fidelity)"
  "com.calibre_ebook.calibre|Calibre|E-book library + conversion"
  "org.gnome.Solanum|Solanum|Pomodoro timer (deep work)"
  "org.flameshot.Flameshot|Flameshot|Screenshot + annotation"
  "net.cozic.joplin_desktop|Joplin|Markdown notes"
)

step() { printf '\n\033[1;35m== %s ==\033[0m\n' "$1"; }

# Ensure flathub remote exists (idempotent).
if ! flatpak remotes 2>/dev/null | grep -q '^flathub'; then
  step "Adding flathub remote"
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

step "Installing productivity apps"
for entry in "${APPS[@]}"; do
  IFS='|' read -r id name desc <<<"$entry"
  if flatpak list --app --columns=application 2>/dev/null | grep -qx "$id"; then
    echo "  already installed: $name ($id)"
    continue
  fi
  if [ "$DRY" = 1 ]; then
    echo "  [dry-run] would install: $name — $desc ($id)"
    continue
  fi
  echo "+ $name — $desc"
  sudo flatpak install -y --system flathub "$id" || echo "  (failed: $id — continuing)"
done

[ "$DRY" = 1 ] && exit 0

cat <<'EOF'

== Done ✓ ==
Launch from the app menu, or:
  flatpak run org.libreoffice.LibreOffice
  flatpak run org.onlyoffice.desktopeditors
  flatpak run com.calibre_ebook.calibre
  flatpak run org.gnome.Solanum          # Pomodoro
  flatpak run org.flameshot.Flameshot
  flatpak run net.cozic.joplin_desktop
EOF
