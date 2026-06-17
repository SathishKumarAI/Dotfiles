#!/usr/bin/env bash
# install-workflow-tools.sh — 20 CLI tools for a smoother dev workflow.
# OS-independent: detects the system package manager (dnf/pacman/apt/zypper/brew)
# and falls back to language installers (cargo/uv/go/gh) that work on any distro.
#
# Usage:
#     bash setup/install-workflow-tools.sh            # install everything
#     bash setup/install-workflow-tools.sh --dry-run  # show plan, change nothing
#
# Idempotent: skips any tool already on PATH. Each tool installs independently —
# one failure won't abort the rest. System-package steps use sudo.
set -uo pipefail

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

have() { command -v "$1" >/dev/null 2>&1; }
step() { printf '\n\033[1;35m== %s ==\033[0m\n' "$1"; }
note() { printf '  %s\n' "$1"; }

# Delegate to a sibling installer (single source of truth — no duplicated logic).
delegate() { local s="$HERE/$1"; [ -f "$s" ] && bash "$s" || note "skip (missing): $1"; }

# ---- detect system package manager -----------------------------------------
PM=""; PM_INSTALL=""
if   have dnf;     then PM=dnf;     PM_INSTALL="sudo dnf install -y"
elif have pacman;  then PM=pacman;  PM_INSTALL="sudo pacman -S --needed --noconfirm"
elif have apt;     then PM=apt;     PM_INSTALL="sudo apt-get install -y"
elif have zypper;  then PM=zypper;  PM_INSTALL="sudo zypper install -y"
elif have brew;    then PM=brew;    PM_INSTALL="brew install"
fi
note "Detected package manager: ${PM:-none}"

# Backend runners. Each returns non-zero on failure (caller continues).
pm_get()    { [ -n "$PM" ] || return 1; $PM_INSTALL "$@"; }
cargo_get() { have cargo || return 1; cargo install --locked "$@"; }
uv_get()    { have uv    || return 1; uv tool install "$@"; }
go_get()    { have go    || return 1; go install "$@"; }

# Fetch a prebuilt release archive from GitHub and drop named binaries into
# ~/.local/bin — no compiler, no sudo. Works on any glibc x86_64 Linux.
#   gh_release_bin <owner/repo> <asset-substring> <bin1> [bin2] ...
gh_release_bin() {
  local repo="$1" asset="$2"; shift 2
  command -v curl >/dev/null 2>&1 || return 1
  local url
  url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null \
        | grep -oE '"browser_download_url": *"[^"]*'"$asset"'[^"]*"' \
        | head -1 | grep -oE 'https://[^"]*') || return 1
  [ -n "$url" ] || return 1
  local tmp; tmp=$(mktemp -d) || return 1
  local f="$tmp/${url##*/}"
  curl -fsSL -o "$f" "$url" || { rm -rf "$tmp"; return 1; }
  case "$f" in
    *.zip)         ( cd "$tmp" && unzip -qo "$f" ) ;;
    *.tar.gz|*.tgz) tar -xzf "$f" -C "$tmp" ;;
    *.tar.xz)      tar -xJf "$f" -C "$tmp" ;;
  esac
  mkdir -p "$HOME/.local/bin"
  local b src
  for b in "$@"; do
    src=$(find "$tmp" -type f -name "$b" | head -1) || true
    [ -n "$src" ] && install -m755 "$src" "$HOME/.local/bin/$b"
  done
  rm -rf "$tmp"
  have "$1"   # success iff the first requested binary is now on PATH
}

# install <bin-to-check> <method1> [method2] ...
# Tries each method (a quoted shell snippet) until one succeeds.
install() {
  local bin="$1"; shift
  if have "$bin"; then note "already installed: $bin"; return 0; fi
  if [ "$DRY" = 1 ]; then note "[dry-run] would install: $bin  (via: $1)"; return 0; fi
  local m
  for m in "$@"; do
    echo "+ $bin  ->  $m"
    if eval "$m"; then note "ok: $bin"; return 0; fi
  done
  note "FAILED: $bin (all methods exhausted — continuing)"
}

# ---- bootstrap language installers we rely on -------------------------------
# uv (Astral) — used for Python tools; OS-independent official installer.
if ! have uv && [ "$DRY" != 1 ]; then
  step "Bootstrapping uv (Python tool installer)"
  curl -LsSf https://astral.sh/uv/install.sh | sh || note "uv bootstrap failed — Python tools may be skipped"
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
fi
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# ---- prerequisites owned by sibling installers (NOT duplicated here) --------
# delta + fzf live in install-modern-cli.sh; direnv + just + pre-commit live in
# install-automation-tools.sh. setup.sh runs those first, so these checks are a
# no-op there; for a standalone run we delegate (only if something's missing).
step "Prerequisite CLI (delegated — single source of truth)"
if [ "$DRY" = 1 ]; then
  note "[dry-run] would ensure (via siblings): delta, fzf, direnv, just, pre-commit"
else
  { have delta && have fzf; }                       || delegate install-modern-cli.sh
  { have direnv && have just && have pre-commit; }  || delegate install-automation-tools.sh
fi

step "Shell & navigation"
install zoxide   "pm_get zoxide"            "cargo_get zoxide"
install atuin    "cargo_get atuin"          "pm_get atuin"
# yazi-fm/yazi-cli on crates.io now panic under `cargo install` (upstream
# packaging change), so prefer the prebuilt binary; cargo path is the fallback.
install yazi     "gh_release_bin sxyazi/yazi x86_64-unknown-linux-gnu.zip yazi ya" \
                 "pm_get yazi"
install tldr     "cargo_get tealdeer"       "pm_get tealdeer"

step "Git & dev loop"
install lazydocker "go_get github.com/jesseduffield/lazydocker@latest"
install entr     "pm_get entr"

step "GitHub dashboard (gh extension)"
if have gh && ! gh extension list 2>/dev/null | grep -q gh-dash; then
  [ "$DRY" = 1 ] && note "[dry-run] would install: gh-dash (gh extension)" \
                 || gh extension install dlvhdr/gh-dash || note "gh-dash failed"
else
  note "gh-dash present or gh missing — skipped"
fi

step "Data & API"
install jq       "pm_get jq"
install yq       "go_get github.com/mikefarah/yq/v4@latest" "pm_get yq"
install xh       "cargo_get xh"             "pm_get xh"
install ruff     "uv_get ruff"              "cargo_get ruff"

step "System & misc"
install btop     "pm_get btop"
install dust     "cargo_get du-dust"        "pm_get dust"
install hyperfine "pm_get hyperfine"        "cargo_get hyperfine"
install procs    "cargo_get procs"          "pm_get procs"
install duf      "go_get github.com/muesli/duf@latest" "pm_get duf"

# ---- Tier 2 — data, local AI & extras --------------------------------------
step "Data science"
install vd       "uv_get visidata"                       # visidata -> `vd`
install csvlens  "cargo_get csvlens"
install duckdb   "pm_get duckdb"            "curl https://install.duckdb.org | sh"
install mlr      "pm_get miller"            "go_get github.com/johnkerl/miller/v6/cmd/mlr@latest"

step "Local AI / LLM"
install ollama   "curl -fsSL https://ollama.com/install.sh | sh"
install llm      "uv_get llm"
install nvtop    "pm_get nvtop"             # GPU monitor (Linux + GPU only)

step "Terminal UX extras"
install glow     "go_get github.com/charmbracelet/glow@latest"   "pm_get glow"
install gum      "go_get github.com/charmbracelet/gum@latest"    "pm_get gum"
install navi     "cargo_get navi"
install watchexec "cargo_get watchexec-cli"  "pm_get watchexec"
install git-cliff "cargo_get git-cliff"
install croc     "go_get github.com/schollz/croc/v10@latest"     "pm_get croc"

[ "$DRY" = 1 ] && exit 0

cat <<'EOF'

== Done ✓ ==
Shell wiring to add to your bashrc/zshrc (chezmoi-managed):
  eval "$(zoxide init bash)"       # z / zi
  eval "$(atuin init bash)"        # better Ctrl-R
  eval "$(direnv hook bash)"       # auto .envrc
  # delta: set in ~/.gitconfig  ->  [core] pager = delta
Make sure ~/.local/bin and ~/.cargo/bin are on PATH (mise/chezmoi usually handle this).
EOF
