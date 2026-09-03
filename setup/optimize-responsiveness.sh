#!/usr/bin/env bash
# optimize-responsiveness.sh — fix GNOME lag on the spinning-HDD machine
# (Rocky 10 / GNOME 49 Wayland). Run as your normal user, NO sudo:
#
#   bash setup/optimize-responsiveness.sh
#
# Root cause of the post-install lag is NOT the tiling extensions — the whole
# system (/ and /home) lives on one 7200rpm spinning HDD (WD10EZEX), so the box
# is I/O-bound, not CPU-bound (12 cores sit near-idle). Two things made it worse:
#   1. tracker3 file-indexer crawling the 37 GB ~/Documents tree at throttle 0.
#   2. A pile of shell extensions, two of them heavy (blur-my-shell, Vitals).
#
# This script (everything reversible, no files deleted):
#   - Throttles + narrows tracker indexing so it stops thrashing the disk.
#   - DISABLES (not uninstalls) the heavy + tiling extensions to measure the
#     responsiveness win. Files stay in ~/.local/share/gnome-shell/extensions.
# Re-enable any of them later with a single `gnome-extensions enable <uuid>`.
# On Wayland the shell can't hot-reload extension state cleanly — LOG OUT and
# back in after running for a clean result.
set -euo pipefail

echo "==> 1/3  Taming tracker3 file indexer (the HDD thrash)"
# Narrow what gets indexed (drops the 37 GB ~/Documents + Music/Videos trees).
# This needs the live GNOME session's dconf — it is a no-op if run outside it,
# which is why the mask below is the real workhorse.
SCHEMA="org.freedesktop.Tracker3.Miner.Files"
if gsettings list-schemas | grep -qx "$SCHEMA"; then
    gsettings set "$SCHEMA" throttle 15 2>/dev/null || true
    gsettings set "$SCHEMA" index-recursive-directories "['&DESKTOP', '&PICTURES']" 2>/dev/null || true
    echo "    + (if in-session) throttle=15, index trimmed to Desktop+Pictures"
fi
# Reliable stop: mask the miner so it can't D-Bus-reactivate and crawl the HDD.
# Reversal: systemctl --user unmask --now tracker-miner-fs-3.service tracker-extract-3.service
systemctl --user mask --now tracker-miner-fs-3.service tracker-extract-3.service 2>/dev/null \
    && echo "    + masked tracker-miner-fs-3 + tracker-extract-3 (crawl can't restart)" \
    || echo "    . could not mask tracker units (run inside your GNOME session)"

echo "==> 2/3  Disabling HEAVY extensions (blur-my-shell, Vitals)"
for uuid in blur-my-shell@aunetx Vitals@CoreCoding.com; do
    if gnome-extensions list 2>/dev/null | grep -qx "$uuid"; then
        gnome-extensions disable "$uuid" 2>/dev/null \
            && echo "    - disabled $uuid" \
            || echo "    . $uuid disables after next login (Wayland)"
    fi
done

echo "==> 3/3  Disabling TILING stack (kept on disk — easy to flip back on)"
for uuid in tiling-assistant@leleat-on-github \
            advanced-alt-tab@G-dH.github.com \
            paperwm@paperwm.github.com; do
    if gnome-extensions list 2>/dev/null | grep -qx "$uuid"; then
        gnome-extensions disable "$uuid" 2>/dev/null \
            && echo "    - disabled $uuid" \
            || echo "    . $uuid disables after next login (Wayland)"
    fi
done

cat <<'EOF'

==> Done. LOG OUT and back in for a clean shell, then judge responsiveness.

   You liked PaperWM — turn JUST the tiling back on anytime with:
       gnome-extensions enable paperwm@paperwm.github.com
       gnome-extensions enable advanced-alt-tab@G-dH.github.com

   Re-enable the rest if you want them:
       gnome-extensions enable blur-my-shell@aunetx     # (heaviest — leave off on a HDD)
       gnome-extensions enable Vitals@CoreCoding.com
       gnome-extensions enable tiling-assistant@leleat-on-github  # conflicts w/ PaperWM

   Restore full file indexing:
       systemctl --user unmask --now tracker-miner-fs-3.service tracker-extract-3.service
       gsettings reset org.freedesktop.Tracker3.Miner.Files throttle
       gsettings reset org.freedesktop.Tracker3.Miner.Files index-recursive-directories

   The real fix is hardware: this machine has NO SSD. Moving / and /home to an
   SSD removes the bottleneck entirely.
EOF
