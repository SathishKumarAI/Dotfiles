#!/bin/bash
#==============================================================================
# Rocky Linux Developer Environment Auto-Installer
# Compatible with: Rocky Linux 8.x / 9.x
# Run as: sudo bash rocky-dev-setup.sh
#==============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Detect Rocky Linux version
if [ -f /etc/rocky-release ]; then
    ROCKY_VERSION=$(rpm -E %rhel)
    log_info "Detected Rocky Linux $ROCKY_VERSION"
else
    log_warn "This script is designed for Rocky Linux. Continuing anyway..."
    ROCKY_VERSION=9
fi

#==============================================================================
# STEP 1: System Update
#==============================================================================
log_info "Updating system packages..."
dnf update -y
dnf install -y epel-release
dnf config-manager --set-enabled crb 2>/dev/null || dnf config-manager --set-enabled powertools 2>/dev/null || true
log_success "System updated"

#==============================================================================
# STEP 2: Core Development Tools
#==============================================================================
log_info "Installing core development tools..."
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
    ca-certificates
log_success "Core tools installed"

#==============================================================================
# STEP 3: Python (latest + pip + venv)
#==============================================================================
log_info "Installing Python..."
dnf install -y python3 python3-pip python3-devel python3-virtualenv
pip3 install --upgrade pip setuptools wheel
log_success "Python $(python3 --version) installed"

#==============================================================================
# STEP 4: Node.js (via NodeSource - latest LTS)
#==============================================================================
log_info "Installing Node.js LTS..."
curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
dnf install -y nodejs
npm install -g yarn pnpm npm@latest
log_success "Node.js $(node --version) installed"

#==============================================================================
# STEP 5: Java (OpenJDK)
#==============================================================================
log_info "Installing Java (OpenJDK 17)..."
dnf install -y java-17-openjdk java-17-openjdk-devel maven
log_success "Java installed"

#==============================================================================
# STEP 6: Go
#==============================================================================
log_info "Installing Go..."
GO_VERSION="1.22.3"
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
log_success "Go installed"

#==============================================================================
# STEP 7: Docker & Docker Compose
#==============================================================================
log_info "Installing Docker..."
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
# Add the original user to docker group (when run via sudo)
if [ -n "$SUDO_USER" ]; then
    usermod -aG docker "$SUDO_USER"
    log_info "Added $SUDO_USER to docker group (re-login required)"
fi
log_success "Docker installed"

#==============================================================================
# STEP 8: Database Clients
#==============================================================================
log_info "Installing database clients..."
dnf install -y postgresql sqlite
# MySQL client
dnf install -y mariadb
log_success "Database clients installed"

#==============================================================================
# STEP 9: VS Code (Microsoft repo)
#==============================================================================
log_info "Installing VS Code..."
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

#==============================================================================
# STEP 10: Useful CLI Tools
#==============================================================================
log_info "Installing additional CLI utilities..."
dnf install -y \
    net-tools \
    bind-utils \
    nmap \
    telnet \
    traceroute \
    rsync \
    screen \
    ripgrep \
    fd-find 2>/dev/null || true

# GitHub CLI
dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
dnf install -y gh
log_success "CLI utilities installed"

#==============================================================================
# STEP 11: Firewall basic configuration (optional)
#==============================================================================
log_info "Configuring firewall for common dev ports..."
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-port=3000/tcp  # Node.js
    firewall-cmd --permanent --add-port=5000/tcp  # Flask
    firewall-cmd --permanent --add-port=8000/tcp  # Django
    firewall-cmd --permanent --add-port=8080/tcp  # General
    firewall-cmd --reload
    log_success "Firewall configured"
else
    log_warn "firewalld not active; skipping firewall config"
fi

#==============================================================================
# Summary
#==============================================================================
echo ""
echo "=============================================================="
log_success "Installation complete!"
echo "=============================================================="
echo ""
echo "Installed versions:"
echo "  - Git:     $(git --version)"
echo "  - Python:  $(python3 --version)"
echo "  - Node:    $(node --version)"
echo "  - npm:     $(npm --version)"
echo "  - Java:    $(java -version 2>&1 | head -n1)"
echo "  - Go:      $(/usr/local/go/bin/go version)"
echo "  - Docker:  $(docker --version)"
echo "  - VS Code: $(code --version 2>/dev/null | head -n1 || echo 'installed')"
echo ""
log_warn "Please log out and log back in for group changes (docker) to take effect."
log_info "Source /etc/profile.d/go.sh or restart shell to use Go."
echo ""
