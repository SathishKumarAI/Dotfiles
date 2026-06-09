#!/usr/bin/env bash
# setup.sh — main entry point. Detects the OS and runs the matching per-OS
# orchestrator in this directory:
#     Rocky / Fedora / RHEL  -> setup-rocky.sh
#     Arch / Manjaro         -> setup-arch.sh
#
# Usage:
#     bash setup/setup.sh              # detect this machine + run
#     bash setup/setup.sh --dry-run    # show the steps, change nothing
#     bash setup/setup.sh --os arch    # force a target (rocky|arch)
#
# The per-OS scripts only call sub-scripts that are safe for that distro
# (e.g. dnf steps on Rocky, pacman/yay steps on Arch). The dual-OS installers
# (install-modern-cli.sh, install-automation-tools.sh, install-extras.sh) run on
# both. Each step continues on error so one failure won't abort the whole run.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY=0; FORCE_OS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --os)      FORCE_OS="${2:-}"; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)"; exit 2 ;;
  esac; shift
done

detect_os() {
  [ -n "$FORCE_OS" ] && { echo "$FORCE_OS"; return; }
  # shellcheck disable=SC1091
  . /etc/os-release 2>/dev/null || true
  case " ${ID:-} ${ID_LIKE:-} " in
    *arch*|*manjaro*)                 echo arch ;;
    *rocky*|*rhel*|*fedora*|*centos*) echo rocky ;;
    *debian*|*ubuntu*)                echo debian ;;
    *)                                echo unknown ;;
  esac
}

OS="$(detect_os)"
echo "Detected OS family: $OS   (override with: --os rocky|arch)"

case "$OS" in
  rocky|arch) ;;
  debian)
    echo "No dedicated Debian/Ubuntu orchestrator yet — but the dual-OS"
    echo "installers still work: bash setup/install-modern-cli.sh ; bash setup/install-automation-tools.sh"
    exit 1 ;;
  *)
    echo "Unsupported/unknown OS. Force one with: bash setup/setup.sh --os rocky|arch"
    exit 1 ;;
esac

target="$HERE/setup-$OS.sh"
[ -f "$target" ] || { echo "missing orchestrator: $target"; exit 1; }

if [ "$DRY" = 1 ]; then
  echo "[dry-run] would run: bash $target"
  echo "--- its steps ---"
  grep -E '^\s*run ' "$target" | sed -E 's/^[[:space:]]*run /  - /'
  exit 0
fi

echo "Running $target ..."
exec bash "$target"
