#!/usr/bin/env bash
# install-modern-cli.sh
# Install the modern CLI baseline: ripgrep, fd, bat, eza, delta, fzf.
# Distro-aware — Rocky/Fedora (dnf), Arch (pacman), Debian/Ubuntu (apt) — with a
# cargo/binary fallback for whatever isn't packaged.
# Idempotent: re-running skips already-installed tools.
#
# Docs: docs/modern-cli/index.mdx
# Run yourself (uses sudo):  bash setup/install-modern-cli.sh

set -uo pipefail

step() { printf '\n\033[1;35m== %s ==\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Install a list of packages with whatever package manager this OS has.
# Package names differ per distro, so callers pass them per-manager.
pkg_install() {
    # usage: pkg_install <dnf-names> | <pacman-names> | <apt-names>  (||-separated)
    local dnf="$1" pac="$2" apt="$3"
    if   have dnf;    then [ -n "$dnf" ] && { echo "+ dnf $dnf";   sudo dnf install -y $dnf; }
    elif have pacman; then [ -n "$pac" ] && { echo "+ pacman $pac"; sudo pacman -S --needed --noconfirm $pac; }
    elif have apt;    then [ -n "$apt" ] && { echo "+ apt $apt";   sudo apt install -y $apt; }
    else echo "  no dnf/pacman/apt — will rely on cargo fallback"; fi
}

# --- 1. Distro packages for the commonly-packaged ones ---------------------
step "System packages (ripgrep, fd, bat, fzf)"
have rg                 || pkg_install "ripgrep" "ripgrep" "ripgrep"
have fd || have fdfind  || pkg_install "fd-find" "fd"      "fd-find"
have bat                || pkg_install "bat"     "bat"     "bat"
have fzf                || pkg_install "fzf"     "fzf"     "fzf"
# Arch packages eza + delta in the official repos; grab them here too.
if have pacman; then
    have eza   || { echo "+ pacman eza";       sudo pacman -S --needed --noconfirm eza; }
    have delta || { echo "+ pacman git-delta"; sudo pacman -S --needed --noconfirm git-delta; }
fi

# Some distros name the fd binary 'fdfind'; symlink to 'fd' in ~/.local/bin.
if ! have fd && have fdfind; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "  linked fdfind -> ~/.local/bin/fd"
fi

# --- 2. cargo fallback for eza + delta (rarely packaged on Rocky) ----------
step "cargo fallback (eza, delta)"
if have cargo; then
    have eza   || { echo "+ cargo install eza";       cargo install eza; }
    have delta || { echo "+ cargo install git-delta"; cargo install git-delta; }
else
    echo "  cargo not found — install Rust via mise ('mise use rust@latest') then re-run,"
    echo "  or grab prebuilt binaries:"
    echo "    eza:   https://github.com/eza-community/eza/releases"
    echo "    delta: https://github.com/dandavison/delta/releases"
fi

# --- 3. Report -------------------------------------------------------------
step "Result"
for t in rg fd bat eza delta fzf; do
    if have "$t"; then printf "  ✅ %s\n" "$t"; else printf "  ❌ %s (still missing)\n" "$t"; fi
done

cat <<'EOF'

Next:
  • zsh already aliases ls->eza and cat->bat when present (chezmoi/dot_zshrc),
    so a new shell will pick them up automatically.
  • To use delta as the git pager, add to ~/.gitconfig (or via chezmoi edit):
        [core]
            pager = delta
        [delta]
            navigate = true
            line-numbers = true
EOF
