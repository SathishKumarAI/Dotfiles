#!/usr/bin/env bash
# install-automation-tools.sh
# Install the recommended automation tools: direnv, just, pre-commit.
# Distro-aware — Rocky/Fedora (dnf), Arch (pacman), Debian/Ubuntu (apt) — with
# pipx/cargo fallbacks. Idempotent.
#
# Docs: docs/automation/recommended.mdx
# Run yourself (uses sudo):  bash setup/install-automation-tools.sh

set -uo pipefail

step() { printf '\n\033[1;35m== %s ==\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Install one package by its (usually identical) name across managers.
pkg() {
    local name="$1"
    if   have dnf;    then sudo dnf install -y "$name"
    elif have pacman; then sudo pacman -S --needed --noconfirm "$name"
    elif have apt;    then sudo apt install -y "$name"
    else return 1; fi
}

step "direnv"
have direnv || pkg direnv || echo "  fallback: https://direnv.net/docs/installation.html"

step "just"
if ! have just; then
    # just is in dnf (Fedora/EPEL), pacman (Arch); cargo is the universal fallback.
    pkg just || { have cargo && { echo "+ cargo install just"; cargo install just; } \
                  || echo "  install via cargo or https://github.com/casey/just/releases"; }
fi

step "pre-commit"
if ! have pre-commit; then
    if have pipx; then pipx install pre-commit
    elif have pip;  then pip install --user pre-commit
    else sudo dnf install -y pre-commit || echo "  install via pipx/pip"
    fi
fi

step "Shell hook for direnv (manual step)"
cat <<'EOF'
  Add the direnv hook to your shell rc (chezmoi/dot_zshrc, dot_bashrc):
        eval "$(direnv hook zsh)"      # or bash
  Then in a project:
        echo 'export FOO=bar' > .envrc && direnv allow
EOF

step "Starter templates (copy into a project, don't overwrite)"
cat <<'EOF'
  justfile:
        default: test
        test:  pytest -q
        fmt:   ruff format .
        dev:   zellij --layout dev

  .pre-commit-config.yaml:
        repos:
          - repo: https://github.com/astral-sh/ruff-pre-commit
            rev: v0.6.0
            hooks: [{id: ruff}, {id: ruff-format}]
          - repo: https://github.com/gitleaks/gitleaks
            rev: v8.18.0
            hooks: [{id: gitleaks}]
    then:  pre-commit install
EOF

step "Result"
for t in direnv just pre-commit; do
    if have "$t"; then printf "  ✅ %s\n" "$t"; else printf "  ❌ %s (still missing)\n" "$t"; fi
done
