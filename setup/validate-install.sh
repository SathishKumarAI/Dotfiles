#!/usr/bin/env bash
# validate-install.sh — post-install health check for the Dotfiles setup.
# Verifies every tool/app the installers are supposed to provide, logs the
# result, and (optionally) re-runs the idempotent installers to fix gaps.
#
# Usage:
#     bash setup/validate-install.sh           # check + log, exit 1 if anything failed
#     bash setup/validate-install.sh --fix      # check; if failures, re-run installers + re-check
#     bash setup/validate-install.sh --quiet     # only summary + log file path
#
# Read-only by default (no sudo). --fix invokes the installers, which use sudo.
# Logs to setup/logs/validate-<timestamp>.log
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FIX=0; QUIET=0
for a in "$@"; do
  case "$a" in
    --fix)   FIX=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

# Tools land in these dirs — make sure they're visible before we test.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.duckdb/cli/latest:$PATH"

LOG_DIR="$HERE/logs"; mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/validate-$TS.log"

# colours (terminal only; log file stays plain)
c_g=$'\033[1;32m'; c_r=$'\033[1;31m'; c_y=$'\033[1;33m'; c_b=$'\033[1;35m'; c_x=$'\033[0m'

emit() { # emit <plain-line> <colored-line>
  [ "$QUIET" = 1 ] || printf '%s\n' "$2"
  printf '%s\n' "$1" >>"$LOG"
}
section() { emit "== $1 ==" "${c_b}== $1 ==${c_x}"; }

PASS=0; FAIL=0; WARN=0
FAILED_ITEMS=()

# check <kind> <id> <label> [optional]
#   kind: cmd | flatpak | ghext
check() {
  local kind="$1" id="$2" label="$3" optional="${4:-}"
  local ok=1
  case "$kind" in
    cmd)     command -v "$id" >/dev/null 2>&1 || ok=0 ;;
    flatpak) flatpak info "$id" >/dev/null 2>&1 || ok=0 ;;
    ghext)   { command -v gh >/dev/null 2>&1 && gh extension list 2>/dev/null | grep -q "$id"; } || ok=0 ;;
  esac
  if [ "$ok" = 1 ]; then
    PASS=$((PASS+1)); emit "  PASS  $label ($id)" "  ${c_g}PASS${c_x}  $label"
  elif [ -n "$optional" ]; then
    WARN=$((WARN+1)); emit "  WARN  $label ($id) — optional/hardware-dependent, skipped" \
                            "  ${c_y}WARN${c_x}  $label ${c_y}(optional)${c_x}"
  else
    FAIL=$((FAIL+1)); FAILED_ITEMS+=("$label")
    emit "  FAIL  $label ($id)" "  ${c_r}FAIL${c_x}  $label"
  fi
}

run_checks() {
  PASS=0; FAIL=0; WARN=0; FAILED_ITEMS=()

  section "Modern CLI"
  for t in rg fd bat eza fzf delta; do check cmd "$t" "$t"; done

  section "Shell & navigation"
  check cmd zoxide zoxide; check cmd atuin atuin; check cmd yazi yazi; check cmd tldr "tealdeer (tldr)"

  section "Git & dev loop"
  for t in direnv just pre-commit lazydocker entr; do check cmd "$t" "$t"; done
  check ghext gh-dash "gh-dash (gh extension)"

  section "Data & API"
  check cmd jq jq; check cmd yq yq; check cmd xh xh
  check cmd uv uv; check cmd ruff ruff

  section "System & misc"
  for t in btop dust hyperfine procs duf; do check cmd "$t" "$t"; done

  section "Data science (Tier 2)"
  check cmd vd "visidata (vd)"; check cmd csvlens csvlens
  check cmd duckdb duckdb; check cmd mlr "miller (mlr)"

  section "Local AI / LLM (Tier 2)"
  check cmd ollama ollama; check cmd llm llm
  check cmd nvtop "nvtop (GPU)" optional

  section "Terminal UX extras (Tier 2)"
  for t in glow gum navi watchexec git-cliff croc; do check cmd "$t" "$t"; done

  section "Productivity apps (Flatpak)"
  check flatpak org.libreoffice.LibreOffice  LibreOffice
  check flatpak org.onlyoffice.desktopeditors ONLYOFFICE
  check flatpak com.calibre_ebook.calibre    Calibre
  check flatpak org.gnome.Solanum            "Solanum (Pomodoro)"
  check flatpak org.flameshot.Flameshot      Flameshot
  check flatpak net.cozic.joplin_desktop     Joplin
}

summary() {
  local total=$((PASS+FAIL+WARN))
  emit "" ""
  emit "-- Summary: $PASS passed, $FAIL failed, $WARN warn (of $total) --" \
       "${c_b}-- Summary: ${c_g}$PASS passed${c_x}, ${c_r}$FAIL failed${c_x}, ${c_y}$WARN warn${c_x} (of $total) --${c_b}${c_x}"
  if [ "$FAIL" -gt 0 ]; then
    emit "Missing:" "${c_r}Missing:${c_x}"
    for i in "${FAILED_ITEMS[@]}"; do emit "  - $i" "  - $i"; done
  fi
}

# ---- run -------------------------------------------------------------------
emit "validate-install $TS  (host: $(hostname), PATH-checked)" "Logging to: $LOG"
run_checks
summary

if [ "$FAIL" -gt 0 ] && [ "$FIX" = 1 ]; then
  section "FIX — re-running idempotent installers"
  for s in install-modern-cli.sh install-workflow-tools.sh install-productivity.sh; do
    [ -f "$HERE/$s" ] || continue
    emit "+ bash $s" "${c_y}+ bash $s${c_x}"
    bash "$HERE/$s" 2>&1 | tee -a "$LOG" || emit "  ($s exited non-zero — continuing)" "  ($s failed — continuing)"
  done
  section "RE-VALIDATE"
  run_checks
  summary
fi

emit "" ""
emit "Log saved: $LOG" "${c_b}Log saved:${c_x} $LOG"
[ "$FAIL" -eq 0 ]   # exit 0 only if nothing failed
