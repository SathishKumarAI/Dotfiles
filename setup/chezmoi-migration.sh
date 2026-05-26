#!/bin/bash
#==============================================================================
# Migrate existing Dotfiles repo → chezmoi format
#
# This script converts your SathishKumarAI/Dotfiles repo into a chezmoi-managed
# source directory, then pushes to GitHub so any machine can do:
#   chezmoi init --apply SathishKumarAI/Dotfiles
#
# Run as your normal user (NOT root):
#   bash chezmoi-migration.sh
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[  OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}[FAIL]${NC} Do NOT run this as root. Run as your normal user."
    exit 1
fi

# Check prerequisites
for cmd in chezmoi git; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}[FAIL]${NC} $cmd not found. Install it first."
        exit 1
    fi
done

#==============================================================================
# Step 1: Initialize chezmoi (if not already done)
#==============================================================================
log_info "Initializing chezmoi..."

if [ ! -d "$HOME/.local/share/chezmoi" ]; then
    chezmoi init
fi

CHEZMOI_DIR="$HOME/.local/share/chezmoi"
log_success "chezmoi source dir: $CHEZMOI_DIR"

#==============================================================================
# Step 2: Create chezmoi config file
#==============================================================================
log_info "Creating chezmoi config..."

mkdir -p "$HOME/.config/chezmoi"

cat > "$HOME/.config/chezmoi/chezmoi.toml" <<'EOF'
[data]
    name = "Sathish Kumar"
    email = "sathishkumar786.ml@gmail.com"
    github_user = "SathishKumarAI"

[git]
    autoCommit = false
    autoPush = false
EOF

log_success "chezmoi config created at ~/.config/chezmoi/chezmoi.toml"

#==============================================================================
# Step 3: Add dotfiles to chezmoi source
#
# chezmoi uses a naming convention:
#   dot_bashrc          → ~/.bashrc
#   dot_config/         → ~/.config/
#   private_dot_ssh/    → ~/.ssh/ (with restricted perms)
#==============================================================================
log_info "Adding dotfiles to chezmoi..."

# Starship config → ~/.config/starship.toml
mkdir -p "$CHEZMOI_DIR/dot_config"
if [ -f "$HOME/.config/starship.toml" ]; then
    chezmoi add "$HOME/.config/starship.toml"
    log_success "Added: ~/.config/starship.toml"
else
    # Copy from the old Dotfiles repo if not yet deployed
    DOTFILES_REPO="$HOME/coding/SathishKumarAI/Dotfiles"
    if [ -f "$DOTFILES_REPO/dotfiles/starship/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        cp "$DOTFILES_REPO/dotfiles/starship/starship.toml" "$HOME/.config/starship.toml"
        chezmoi add "$HOME/.config/starship.toml"
        log_success "Added: ~/.config/starship.toml (from Dotfiles repo)"
    fi
fi

# Zellij config → ~/.config/zellij/config.kdl
if [ -f "$HOME/.config/zellij/config.kdl" ]; then
    chezmoi add "$HOME/.config/zellij/config.kdl"
    log_success "Added: ~/.config/zellij/config.kdl"
else
    DOTFILES_REPO="$HOME/coding/SathishKumarAI/Dotfiles"
    if [ -f "$DOTFILES_REPO/dotfiles/Zellij/config.kdl" ]; then
        mkdir -p "$HOME/.config/zellij"
        cp "$DOTFILES_REPO/dotfiles/Zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
        chezmoi add "$HOME/.config/zellij/config.kdl"
        log_success "Added: ~/.config/zellij/config.kdl (from Dotfiles repo)"
    fi
fi

# WezTerm config → ~/.wezterm.lua
if [ -f "$HOME/.wezterm.lua" ]; then
    chezmoi add "$HOME/.wezterm.lua"
    log_success "Added: ~/.wezterm.lua"
else
    DOTFILES_REPO="$HOME/coding/SathishKumarAI/Dotfiles"
    if [ -f "$DOTFILES_REPO/dotfiles/wizterm/.wezterm.lua" ]; then
        cp "$DOTFILES_REPO/dotfiles/wizterm/.wezterm.lua" "$HOME/.wezterm.lua"
        chezmoi add "$HOME/.wezterm.lua"
        log_success "Added: ~/.wezterm.lua (from Dotfiles repo)"
    fi
fi

# mise global config → ~/.config/mise/config.toml
if [ -f "$HOME/.config/mise/config.toml" ]; then
    chezmoi add "$HOME/.config/mise/config.toml"
    log_success "Added: ~/.config/mise/config.toml"
fi

# Git config (if exists)
if [ -f "$HOME/.gitconfig" ]; then
    chezmoi add "$HOME/.gitconfig"
    log_success "Added: ~/.gitconfig"
fi

#==============================================================================
# Step 4: Create a run_once script for first-time tool installs
#
# chezmoi's run_once_ scripts execute once per machine (tracked by checksum).
# This installs mise + starship + zellij on fresh machines automatically.
#==============================================================================
log_info "Creating run_once bootstrap script..."

cat > "$CHEZMOI_DIR/run_once_install-tools.sh" <<'BOOTSTRAP'
#!/bin/bash
# chezmoi run_once script — installs tools on first apply

set -e

echo "[chezmoi] Installing tools..."

# mise
if ! command -v mise &>/dev/null && [ ! -f "$HOME/.local/bin/mise" ]; then
    echo "[chezmoi] Installing mise..."
    curl -fsSL https://mise.run | sh
    eval "$($HOME/.local/bin/mise activate bash)"
    mise install --yes
fi

# Starship
if ! command -v starship &>/dev/null; then
    echo "[chezmoi] Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# zoxide
if ! command -v zoxide &>/dev/null; then
    echo "[chezmoi] Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

echo "[chezmoi] Tool install complete!"
BOOTSTRAP

chmod +x "$CHEZMOI_DIR/run_once_install-tools.sh"
log_success "Created run_once_install-tools.sh (auto-installs mise, starship, zoxide)"

#==============================================================================
# Step 5: Create shell rc templates
#
# chezmoi templates use {{ .variable }} syntax (Go templates).
# These generate personalized .bashrc / .zshrc on each machine.
#==============================================================================
log_info "Creating shell config templates..."

cat > "$CHEZMOI_DIR/dot_bashrc.tmpl" <<'BASHRC_TMPL'
# .bashrc — managed by chezmoi
# edit with: chezmoi edit ~/.bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Path
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# mise — language version manager
if [ -f "$HOME/.local/bin/mise" ]; then
    eval "$($HOME/.local/bin/mise activate bash)"
fi

# Starship prompt
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# zoxide (smart cd)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init bash)"
fi

# fzf
if command -v fzf &>/dev/null; then
    eval "$(fzf --bash 2>/dev/null)" || true
fi

# Conda (only if installed)
if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniforge3/etc/profile.d/conda.sh"
fi

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lg='lazygit'
alias v='nvim'
alias g='git'
alias dc='docker compose'

# bashrc.d drop-in
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
BASHRC_TMPL

log_success "Created .bashrc template"

#==============================================================================
# Step 6: Create .chezmoi.toml.tmpl for machine-specific config
#==============================================================================

cat > "$CHEZMOI_DIR/.chezmoi.toml.tmpl" <<'CHEZMOI_TMPL'
[data]
    name = "{{ .name }}"
    email = "{{ .email }}"
    github_user = "{{ .github_user }}"
CHEZMOI_TMPL

log_success "Created .chezmoi.toml.tmpl"

#==============================================================================
# Step 7: Show status
#==============================================================================
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
log_success "chezmoi migration complete!"
echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Source directory: $CHEZMOI_DIR"
echo ""
echo "Files managed by chezmoi:"
chezmoi managed 2>/dev/null || ls -1 "$CHEZMOI_DIR"
echo ""
echo "Next steps:"
echo "  1. Review:    chezmoi diff"
echo "  2. Apply:     chezmoi apply -v"
echo "  3. Commit:    chezmoi cd && git add -A && git commit -m 'migrate to chezmoi'"
echo "  4. Push:      git push"
echo ""
echo "On a NEW machine, just run:"
echo "  chezmoi init --apply SathishKumarAI/Dotfiles"
echo ""
