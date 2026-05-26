#!/bin/bash
#==============================================================================
# Rocky Linux Developer Environment Auto-Installer
# Compatible with: Rocky Linux 9.x / 10.x
# Core tools: mise (all language runtimes) + chezmoi (dotfiles)
# Run as: sudo bash rocky-dev-setup-custom.sh
#==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[  OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $1"; }
log_section() { echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}  $1${NC}\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

SCRIPT_START=$(date +%s)

if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

ACTUAL_USER="${SUDO_USER:-$USER}"
ACTUAL_HOME=$(eval echo "~$ACTUAL_USER")
ARCH=$(uname -m)

if [ -f /etc/rocky-release ]; then
    ROCKY_VERSION=$(rpm -E %rhel)
    log_info "Detected Rocky Linux $ROCKY_VERSION ($(cat /etc/rocky-release))"
else
    log_warn "Not Rocky Linux — script may still work on RHEL/CentOS/Alma"
    ROCKY_VERSION=$(rpm -E %rhel 2>/dev/null || echo 10)
fi

log_info "Architecture: $ARCH | User: $ACTUAL_USER | Home: $ACTUAL_HOME"

#==============================================================================
# STEP 1: System Update & Repos
#==============================================================================
log_section "STEP 1: System Update & Repositories"

dnf update -y

if ! rpm -q epel-release &>/dev/null; then
    dnf install -y epel-release
fi

if [[ "$ROCKY_VERSION" -ge 9 ]]; then
    dnf config-manager --set-enabled crb 2>/dev/null || true
else
    dnf config-manager --set-enabled powertools 2>/dev/null || true
fi

log_success "System updated, EPEL + CRB enabled"

#==============================================================================
# STEP 2: Core Development Tools & Build Dependencies
#==============================================================================
log_section "STEP 2: Core Development Tools"

dnf groupinstall -y "Development Tools"

dnf install -y \
    git \
    curl \
    wget \
    vim \
    nano \
    tmux \
    htop \
    tree \
    unzip \
    zip \
    tar \
    jq \
    which \
    bash-completion \
    zsh \
    openssl-devel \
    bzip2-devel \
    libffi-devel \
    zlib-devel \
    readline-devel \
    sqlite-devel \
    xz-devel \
    ncurses-devel \
    gdbm-devel \
    nss-devel \
    ca-certificates \
    make \
    cmake \
    pkg-config

log_success "Core tools + build deps installed"

#==============================================================================
# STEP 3: mise — Single Tool for All Language Runtimes
#
# mise replaces: nvm, pyenv, goenv, sdkman, rustup version management
# Config lives in ~/.config/mise/config.toml (managed by chezmoi later)
#==============================================================================
log_section "STEP 3: mise (Language Version Manager)"

if ! sudo -u "$ACTUAL_USER" bash -c 'command -v mise' &>/dev/null && \
   [ ! -f "$ACTUAL_HOME/.local/bin/mise" ]; then

    log_info "Installing mise..."
    sudo -u "$ACTUAL_USER" bash -c 'curl -fsSL https://mise.run | sh'

    # Activate mise in bash
    if ! grep -q 'mise activate bash' "$ACTUAL_HOME/.bashrc" 2>/dev/null; then
        cat >> "$ACTUAL_HOME/.bashrc" <<'EOF'

# mise — language version manager
eval "$($HOME/.local/bin/mise activate bash)"
EOF
    fi

    # Activate mise in zsh
    if [ -f "$ACTUAL_HOME/.zshrc" ] && ! grep -q 'mise activate zsh' "$ACTUAL_HOME/.zshrc" 2>/dev/null; then
        cat >> "$ACTUAL_HOME/.zshrc" <<'EOF'

# mise — language version manager
eval "$($HOME/.local/bin/mise activate zsh)"
EOF
    fi

    log_success "mise installed"
else
    log_info "mise already installed"
fi

# Create global mise config with desired tool versions
MISE_CONFIG_DIR="$ACTUAL_HOME/.config/mise"
mkdir -p "$MISE_CONFIG_DIR"

cat > "$MISE_CONFIG_DIR/config.toml" <<'MISE_CONF'
[tools]
python = "3.12"
node = "lts"
go = "latest"

[settings]
experimental = true
MISE_CONF

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$MISE_CONFIG_DIR"

# Install all tools defined in the config
log_info "Installing runtimes via mise (Python 3.12, Node LTS, Go latest)..."
sudo -u "$ACTUAL_USER" bash -c "export PATH=$ACTUAL_HOME/.local/bin:\$PATH && mise install --yes" || {
    log_warn "mise install had issues — you can run 'mise install' manually after login"
}

# Install global npm packages via mise-managed Node
sudo -u "$ACTUAL_USER" bash -c "export PATH=$ACTUAL_HOME/.local/bin:\$PATH && eval \"\$(mise activate bash)\" && npm install -g yarn pnpm" 2>/dev/null || true

log_success "mise configured: Python 3.12 + Node LTS + Go latest"

#==============================================================================
# STEP 4: chezmoi — Dotfiles Manager
#
# chezmoi manages: shell config, starship, wezterm, zellij, git config, etc.
# Source repo: github.com/SathishKumarAI/Dotfiles
#==============================================================================
log_section "STEP 4: chezmoi (Dotfiles Manager)"

if ! command -v chezmoi &>/dev/null; then
    log_info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
    log_success "chezmoi installed to /usr/local/bin/chezmoi"
else
    log_info "chezmoi already installed"
fi

# Initialize chezmoi with the user's dotfiles repo (if not already done)
if [ ! -d "$ACTUAL_HOME/.local/share/chezmoi" ]; then
    log_info "Initializing chezmoi with SathishKumarAI/Dotfiles..."
    sudo -u "$ACTUAL_USER" chezmoi init https://github.com/SathishKumarAI/Dotfiles.git || {
        log_warn "chezmoi init failed — you can run 'chezmoi init SathishKumarAI/Dotfiles' manually"
    }
    log_success "chezmoi initialized"
else
    log_info "chezmoi already initialized"
fi

log_info "To apply dotfiles: chezmoi apply -v"
log_info "To see what would change: chezmoi diff"

#==============================================================================
# STEP 5: Starship Prompt + Zellij + WezTerm
#
# These are the tools referenced in your Dotfiles repo.
# chezmoi will manage their configs; we just need the binaries.
#==============================================================================
log_section "STEP 5: Shell Tools (Starship, Zellij, WezTerm)"

# Starship prompt
if ! command -v starship &>/dev/null; then
    log_info "Installing Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
    log_success "Starship installed"
else
    log_info "Starship already installed"
fi

# Zellij terminal multiplexer
if ! command -v zellij &>/dev/null; then
    log_info "Installing Zellij..."
    ZELLIJ_VERSION=$(curl -sL "https://api.github.com/repos/zellij-org/zellij/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' 2>/dev/null || echo "0.41.2")
    curl -Lo /tmp/zellij.tar.gz "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-x86_64-unknown-linux-musl.tar.gz"
    tar -C /usr/local/bin -xzf /tmp/zellij.tar.gz
    chmod +x /usr/local/bin/zellij
    rm /tmp/zellij.tar.gz
    log_success "Zellij $ZELLIJ_VERSION installed"
else
    log_info "Zellij already installed"
fi

# WezTerm (only on desktop systems, skip on headless)
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    if ! command -v wezterm &>/dev/null; then
        log_info "Installing WezTerm..."
        dnf copr enable wezfurlong/wezterm-nightly -y 2>/dev/null || true
        dnf install -y wezterm 2>/dev/null || {
            log_warn "WezTerm not available via dnf — install manually from https://wezfurlong.org/wezterm/"
        }
    else
        log_info "WezTerm already installed"
    fi
else
    log_info "No display detected — skipping WezTerm (headless mode)"
fi

# Activate starship in shells (chezmoi will override these later)
if ! grep -q 'starship init bash' "$ACTUAL_HOME/.bashrc" 2>/dev/null; then
    cat >> "$ACTUAL_HOME/.bashrc" <<'EOF'

# Starship prompt
eval "$(starship init bash)"
EOF
fi

if [ -f "$ACTUAL_HOME/.zshrc" ] && ! grep -q 'starship init zsh' "$ACTUAL_HOME/.zshrc" 2>/dev/null; then
    cat >> "$ACTUAL_HOME/.zshrc" <<'EOF'

# Starship prompt
eval "$(starship init zsh)"
EOF
fi

log_success "Shell tools ready"

#==============================================================================
# STEP 6: Docker & Docker Compose
#==============================================================================
log_section "STEP 6: Docker"

if ! command -v docker &>/dev/null; then
    DOCKER_REPO_URL="https://download.docker.com/linux/centos/docker-ce.repo"
    if [[ "$ROCKY_VERSION" -ge 10 ]]; then
        DOCKER_REPO_URL="https://download.docker.com/linux/rhel/docker-ce.repo"
    fi

    dnf config-manager --add-repo="$DOCKER_REPO_URL"
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker

    if [ -n "$ACTUAL_USER" ] && [ "$ACTUAL_USER" != "root" ]; then
        usermod -aG docker "$ACTUAL_USER"
        log_info "Added $ACTUAL_USER to docker group (re-login required)"
    fi

    log_success "Docker installed"
else
    log_info "Docker already installed: $(docker --version)"
fi

#==============================================================================
# STEP 7: Database Clients
#==============================================================================
log_section "STEP 7: Database Clients"

dnf install -y postgresql sqlite mariadb
log_success "Database clients installed (psql, sqlite3, mysql)"

#==============================================================================
# STEP 8: VS Code
#==============================================================================
log_section "STEP 8: VS Code"

if ! command -v code &>/dev/null; then
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    dnf install -y code
    log_success "VS Code installed"
else
    log_info "VS Code already installed"
fi

#==============================================================================
# STEP 9: CLI Utilities
#==============================================================================
log_section "STEP 9: CLI Utilities"

dnf install -y \
    net-tools \
    bind-utils \
    nmap \
    traceroute \
    rsync \
    screen \
    ripgrep \
    fd-find \
    bat \
    fzf \
    ShellCheck 2>/dev/null || true

# zoxide (smart cd, used in your Dotfiles)
if ! command -v zoxide &>/dev/null; then
    sudo -u "$ACTUAL_USER" bash -c 'curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'
    if ! grep -q 'zoxide init' "$ACTUAL_HOME/.bashrc" 2>/dev/null; then
        echo 'eval "$(zoxide init bash)"' >> "$ACTUAL_HOME/.bashrc"
    fi
    if [ -f "$ACTUAL_HOME/.zshrc" ] && ! grep -q 'zoxide init' "$ACTUAL_HOME/.zshrc" 2>/dev/null; then
        echo 'eval "$(zoxide init zsh)"' >> "$ACTUAL_HOME/.zshrc"
    fi
    log_success "zoxide installed"
fi

# GitHub CLI
if ! command -v gh &>/dev/null; then
    dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 2>/dev/null || true
    dnf install -y gh 2>/dev/null || true
fi

# lazygit
if ! command -v lazygit &>/dev/null; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*' 2>/dev/null || echo "0.44.1")
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar -C /usr/local/bin -xzf /tmp/lazygit.tar.gz lazygit
    rm /tmp/lazygit.tar.gz
    log_success "lazygit installed"
fi

# Neovim
if ! command -v nvim &>/dev/null; then
    dnf install -y neovim 2>/dev/null || {
        curl -Lo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
        tar -C /opt -xzf /tmp/nvim.tar.gz
        ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
        rm /tmp/nvim.tar.gz
    }
    log_success "Neovim installed"
fi

log_success "CLI utilities installed"

#==============================================================================
# STEP 10: Miniforge (conda-forge for AI/ML)
#==============================================================================
log_section "STEP 10: Miniforge (conda for AI/ML)"

if [ ! -d "$ACTUAL_HOME/miniforge3" ]; then
    log_info "Installing Miniforge..."
    MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${ARCH}.sh"
    sudo -u "$ACTUAL_USER" bash -c "wget -q '$MINIFORGE_URL' -O /tmp/miniforge.sh && bash /tmp/miniforge.sh -b -p $ACTUAL_HOME/miniforge3"
    rm -f /tmp/miniforge.sh

    sudo -u "$ACTUAL_USER" bash -c "$ACTUAL_HOME/miniforge3/bin/conda init bash"
    sudo -u "$ACTUAL_USER" bash -c "$ACTUAL_HOME/miniforge3/bin/conda init zsh" 2>/dev/null || true

    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_HOME/miniforge3"
    log_success "Miniforge installed"
else
    log_info "Miniforge already installed"
fi

#==============================================================================
# STEP 11: AWS CLI
#==============================================================================
log_section "STEP 11: AWS CLI"

if ! command -v aws &>/dev/null; then
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o /tmp/awscliv2.zip
    unzip -qo /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
    log_success "AWS CLI installed"
else
    log_info "AWS CLI already installed"
fi

#==============================================================================
# STEP 12: Firewall (dev ports)
#==============================================================================
log_section "STEP 12: Firewall"

if systemctl is-active --quiet firewalld; then
    for port in 3000 5000 8000 8080 8888; do
        firewall-cmd --permanent --add-port=${port}/tcp 2>/dev/null || true
    done
    firewall-cmd --reload
    log_success "Firewall: opened ports 3000,5000,8000,8080,8888"
    log_warn "Ports are open on ALL interfaces — bind dev servers to 127.0.0.1 on shared networks"
else
    log_warn "firewalld not active; skipping"
fi

#==============================================================================
# Summary
#==============================================================================
SCRIPT_END=$(date +%s)
ELAPSED=$(( SCRIPT_END - SCRIPT_START ))

echo ""
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
log_success "Installation complete! (${ELAPSED}s)"
echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Installed versions:"
echo "  - OS:        $(cat /etc/rocky-release 2>/dev/null || echo 'unknown')"
echo "  - Git:       $(git --version 2>/dev/null | awk '{print $3}')"
echo "  - mise:      $(sudo -u "$ACTUAL_USER" bash -c "\$HOME/.local/bin/mise --version 2>/dev/null" || echo 'installed')"
echo "  - chezmoi:   $(chezmoi --version 2>/dev/null || echo 'installed')"
echo "  - Python:    $(sudo -u "$ACTUAL_USER" bash -c "PATH=\$HOME/.local/bin:\$PATH && eval \"\$(mise activate bash)\" && python3 --version 2>/dev/null" || echo 'via mise')"
echo "  - Node:      $(sudo -u "$ACTUAL_USER" bash -c "PATH=\$HOME/.local/bin:\$PATH && eval \"\$(mise activate bash)\" && node --version 2>/dev/null" || echo 'via mise')"
echo "  - Go:        $(sudo -u "$ACTUAL_USER" bash -c "PATH=\$HOME/.local/bin:\$PATH && eval \"\$(mise activate bash)\" && go version 2>/dev/null" || echo 'via mise')"
echo "  - Docker:    $(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
echo "  - Starship:  $(starship --version 2>/dev/null | head -1 || echo 'installed')"
echo "  - Zellij:    $(zellij --version 2>/dev/null || echo 'installed')"
echo "  - Neovim:    $(nvim --version 2>/dev/null | head -1 || echo 'installed')"
echo "  - Conda:     $(sudo -u "$ACTUAL_USER" bash -c "\$HOME/miniforge3/bin/conda --version 2>/dev/null" || echo 'installed')"
echo "  - AWS CLI:   $(aws --version 2>&1 | awk '{print $1}' || echo 'installed')"
echo "  - gh:        $(gh --version 2>/dev/null | head -1 || echo 'installed')"
echo "  - lazygit:   $(lazygit --version 2>/dev/null | head -1 || echo 'installed')"
echo ""
echo -e "${CYAN}Tool management:${NC}"
echo "  mise manages:   Python, Node.js, Go (and 500+ more)"
echo "  chezmoi manages: dotfiles (starship, zellij, wezterm, shell configs)"
echo ""
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo "  1. Log out and back in (docker group + shell changes)"
echo "  2. Apply your dotfiles:   chezmoi apply -v"
echo "  3. Auth GitHub:           gh auth login"
echo "  4. Auth AWS:              aws configure"
echo "  5. Add mise tools:        mise use --global rust@latest"
echo "  6. Edit dotfiles:         chezmoi edit ~/.config/starship.toml"
echo "     Then push changes:     chezmoi cd && git add -A && git commit && git push"
echo ""
