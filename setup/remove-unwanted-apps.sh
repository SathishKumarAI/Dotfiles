#!/usr/bin/env bash
# Remove unwanted/redundant apps. Reviewed & confirmed 2026-06-16.
# Flatpak app data in ~/.var/app/ is KEPT (no --delete-data). Add the flag if you want it gone.
set -euo pipefail

echo "==> Flatpak removals (no sudo)"
for id in com.logseq.Logseq net.cozic.joplin_desktop org.onlyoffice.desktopeditors; do
  if flatpak info "$id" &>/dev/null; then
    echo "  removing $id"
    flatpak uninstall -y "$id"
  else
    echo "  $id not installed, skip"
  fi
done

echo "==> Prune unused flatpak runtimes"
flatpak uninstall --unused -y || true

echo "==> dnf removal (sudo): brave-browser-nightly"
if rpm -q brave-browser-nightly &>/dev/null; then
  sudo dnf remove -y brave-browser-nightly
else
  echo "  brave-browser-nightly not installed, skip"
fi

echo "==> Done. Freed roughly 2.5 GB."
