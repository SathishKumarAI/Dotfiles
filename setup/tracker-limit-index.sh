#!/usr/bin/env bash
# tracker-limit-index.sh — stop GNOME's file indexer (Tracker3 / tracker-miners)
# from crawling the whole home dir at login.
#
# Why: tracker-miner-fs crawls every indexed directory on session start. With
# $HOME + Music/Pictures/Videos/Documents/Desktop in scope it can thrash CPU/IO
# right when you log in -> the machine "lags at start". This restricts indexing
# to just ~/Downloads and ~/coding (recursively). Hidden files/dirs (dotfiles)
# are already skipped by Tracker by default.
#
# Everything here is user-level gsettings (no sudo) and fully reversible:
#   ./tracker-limit-index.sh            # apply the restricted scope
#   ./tracker-limit-index.sh --reset    # restore GNOME defaults
#   ./tracker-limit-index.sh --status   # show current scope + daemon status
#   ./tracker-limit-index.sh --dry-run  # print what would change, change nothing
#
# After applying, the miner is restarted so the new scope takes effect.
#
# IMPORTANT: run this from a REAL GNOME session terminal (GNOME Console / TTY),
# NOT from inside a sandboxed app (e.g. the WezTerm Flatpak) — a sandbox can't
# commit dconf to the host session bus, so the gsettings writes silently no-op.
#
# Relation to optimize-responsiveness.sh: that script MASKS tracker (fully off).
# This script is the lighter alternative — keep indexing ON but scoped to two
# dirs. Applying here unmasks the miner if it was masked.

set -euo pipefail

SCHEMA="org.freedesktop.Tracker3.Miner.Files"
DRY=0
MODE="apply"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    --reset)   MODE="reset" ;;
    --status)  MODE="status" ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

if ! command -v gsettings >/dev/null 2>&1; then
  echo "gsettings not found — this needs GNOME / glib." >&2; exit 1
fi
if ! gsettings list-schemas 2>/dev/null | grep -qx "$SCHEMA"; then
  echo "Schema $SCHEMA not present — is tracker-miners installed?" >&2; exit 1
fi

run() { if [ "$DRY" = 1 ]; then echo "DRY: $*"; else "$@"; fi; }

show() {
  echo "  recursive : $(gsettings get $SCHEMA index-recursive-directories)"
  echo "  single    : $(gsettings get $SCHEMA index-single-directories)"
}

restart_miner() {
  if command -v tracker3 >/dev/null 2>&1; then
    run tracker3 daemon -t >/dev/null 2>&1 || true   # terminate; D-Bus restarts it with new scope
    echo "Miner restarted. Drop stale entries with: tracker3 reset --filesystem"
  fi
}

case "$MODE" in
  status)
    echo "Current Tracker index scope:"; show
    command -v tracker3 >/dev/null 2>&1 && { echo; tracker3 status 2>/dev/null | head -5; }
    exit 0 ;;

  reset)
    echo "Restoring GNOME default index scope..."
    run gsettings reset $SCHEMA index-recursive-directories
    run gsettings reset $SCHEMA index-single-directories
    echo "After:"; show
    restart_miner
    exit 0 ;;

  apply)
    echo "Before:"; show
    # Recursive: only the two working trees. &DOWNLOAD is the XDG alias for ~/Downloads.
    run gsettings set $SCHEMA index-recursive-directories "['&DOWNLOAD', '$HOME/coding']"
    # Single (non-recursive) dirs: none — drops the broad $HOME entry.
    run gsettings set $SCHEMA index-single-directories "[]"
    echo "After:"; show
    # optimize-responsiveness.sh may have MASKED the miner (fully off). Scoped
    # indexing can't run while masked, so unmask it here.
    if systemctl --user is-enabled tracker-miner-fs-3.service 2>/dev/null | grep -qx masked; then
      echo "Unmasking tracker miner (was fully off via optimize-responsiveness.sh)..."
      run systemctl --user unmask tracker-miner-fs-3.service tracker-extract-3.service
    fi
    restart_miner
    echo
    echo "Scope now limited to ~/Downloads and ~/coding (hidden files skipped by default)."
    echo "Revert any time: $0 --reset"
    exit 0 ;;
esac
