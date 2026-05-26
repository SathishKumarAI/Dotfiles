# Rocky Linux Dev Setup Script — Full Breakdown

## What This Script Does

A single `sudo bash rocky-dev-setup-custom.sh` turns a bare Rocky Linux install into a full developer workstation. The custom version uses two core tools:

- **mise** — manages all language runtimes (Python, Node, Go, and 500+ more) from a single config file
- **chezmoi** — manages dotfiles (shell config, starship, zellij, wezterm) across machines

### Original vs Custom Script

| Feature | `rocky-dev-setup.sh` | `rocky-dev-setup-custom.sh` |
|---------|---------------------|----------------------------|
| Language mgmt | Manual installs (NodeSource, Go tarball, dnf python3) | **mise** (single tool for all) |
| Dotfiles | None | **chezmoi** (pulls from GitHub) |
| Python versions | System only | mise + Miniforge (conda) |
| Go version | Hardcoded 1.22.3 | mise (always latest) |
| Shell tools | None | Starship, Zellij, zoxide, fzf |
| Rocky 10 | Untested | Fully supported |
| Idempotent | No | Yes (safe to re-run) |

---

## Section-by-Section Explanation

### Preamble: Safety & Logging (lines 1–30)

```bash
set -e
```

**What:** Stops the entire script if any command fails (returns non-zero exit).
**Why:** Prevents cascading failures — if `dnf update` breaks, you don't want it to blindly continue installing Docker on a half-updated system.

The color-coded logging functions (`log_info`, `log_success`, `log_warn`, `log_error`) give clear visual feedback so you can spot failures in a wall of terminal output.

The root check (`$EUID -ne 0`) ensures `dnf` and `systemctl` calls have the permissions they need.

---

### Step 1: System Update

```bash
dnf update -y
dnf install -y epel-release
dnf config-manager --set-enabled crb
```

**What:**
- Updates all existing packages to latest versions
- Installs **EPEL** (Extra Packages for Enterprise Linux) — a community repo with tools not in the base repos (htop, ripgrep, etc.)
- Enables **CRB** (CodeReady Builder) on Rocky 9 or **PowerTools** on Rocky 8 — needed for `-devel` packages

**Why:** Without EPEL and CRB, half the packages in later steps would fail with "No match found."

---

### Step 2: Core Development Tools

```bash
dnf groupinstall -y "Development Tools"
```

**What:** Installs gcc, g++, make, autoconf, automake, libtool, pkgconfig, and more. This is the equivalent of `build-essential` on Debian/Ubuntu.

The individual packages after that fall into two groups:
- **CLI essentials:** git, curl, wget, vim, nano, tmux, htop, tree, jq, bash-completion
- **Build dependencies:** openssl-devel, libffi-devel, zlib-devel, etc. — these are needed to compile Python from source, build C extensions, and install native Node modules

---

### Step 3: Python

```bash
dnf install -y python3 python3-pip python3-devel python3-virtualenv
pip3 install --upgrade pip setuptools wheel
```

**What:** Installs the system Python 3 (3.9 on Rocky 9, 3.6 on Rocky 8), plus pip, C-extension headers, and virtualenv. Then upgrades pip itself.

**Why:** Rocky ships old pip versions. Upgrading ensures modern dependency resolution and wheel support.

---

### Step 4: Node.js

```bash
curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
```

**What:** Pipes NodeSource's setup script into bash to add their RPM repo, then installs the latest LTS Node.js. Also installs yarn, pnpm, and updates npm globally.

**Why:** Rocky's default Node.js (via AppStream) is often outdated. NodeSource provides current LTS versions.

---

### Step 5: Java (OpenJDK 17)

```bash
dnf install -y java-17-openjdk java-17-openjdk-devel maven
```

**What:** Installs the JRE, JDK (for compiling), and Maven (build tool).

**Why:** Java 17 is the current long-term-support version. The `-devel` package provides `javac`.

---

### Step 6: Go

```bash
GO_VERSION="1.22.3"
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
```

**What:** Downloads a specific Go binary release, extracts to `/usr/local/go`, and adds it to `$PATH` via `/etc/profile.d/go.sh` (so it persists across logins for all users).

**Why:** Rocky doesn't ship Go in its repos. The official tarball is the standard install method.

---

### Step 7: Docker

```bash
dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
```

**What:** Adds Docker's official CentOS repo (compatible with Rocky), installs Docker CE, the CLI, containerd, BuildKit, and the Compose plugin. Enables Docker to start on boot. Adds the sudo user to the `docker` group.

**Why:** `docker` group membership lets you run `docker` without `sudo` (requires re-login).

---

### Step 8: Database Clients

```bash
dnf install -y postgresql sqlite mariadb
```

**What:** Installs CLI clients for PostgreSQL (`psql`), SQLite (`sqlite3`), and MySQL/MariaDB (`mysql`). These are **clients only** — no database servers are started.

**Why:** For connecting to remote databases or local Docker-hosted DBs during development.

---

### Step 9: VS Code

**What:** Imports Microsoft's GPG key, creates a yum repo file, and installs the `code` package.

**Why:** VS Code is the most popular dev editor. The repo approach means `dnf update` will keep it current.

---

### Step 10: CLI Utilities

**What:** Installs networking tools (nmap, traceroute, bind-utils for `dig`/`nslookup`), modern search tools (ripgrep, fd-find), and the GitHub CLI (`gh`).

**Why:** These are the "I always need this and it's never installed" category.

---

### Step 11: Firewall

```bash
firewall-cmd --permanent --add-port=3000/tcp
```

**What:** Opens common dev server ports (3000, 5000, 8000, 8080) in firewalld. Only runs if firewalld is active.

**Why:** Without this, your dev server runs fine but you can't access it from another machine or browser on the network.

---

### Summary Section

Prints installed versions of everything so you can verify at a glance that nothing silently failed.

---

## Flags: Risky, Outdated, or Problematic Items

### CRITICAL: Rocky Linux 10 Compatibility

Your machine is **Rocky Linux 10.1** but this script targets **8.x/9.x**. Key differences:

| Issue | Impact |
|-------|--------|
| `epel-release` | EPEL for Rocky 10 may not be available yet or may need `epel-next-release` |
| `crb` / `powertools` | Rocky 10 may use a different repo name |
| `python3` defaults | Rocky 10 likely ships Python 3.12+, not 3.9 |
| `java-17-openjdk` | May need `java-21-openjdk` on Rocky 10 (21 is the newer LTS) |
| Docker CentOS repo | Uses `centos` repo — may need `rhel` or `rocky` specific URL for v10 |
| NodeSource script | May not yet support Rocky 10 / RHEL 10 |

### Hardcoded Go Version

```bash
GO_VERSION="1.22.3"  # Released May 2024
```

Go 1.24.x is current as of early 2026. Version 1.22.3 is **nearly 2 years old** and missing security patches. Should use the latest stable.

### Piping Curl to Bash (NodeSource)

```bash
curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
```

This is a common but risky pattern — you're executing a remote script as root without inspecting it. If NodeSource's CDN were compromised, this would be a supply chain attack vector. Consider downloading first, reviewing, then executing.

### Docker Group = Root Equivalent

Adding a user to the `docker` group gives them **effective root access** to the host. Anyone in the docker group can mount the host filesystem via `docker run -v /:/host`. This is fine for a personal dev machine, but a security concern on shared servers.

### Firewall Opens Ports to All Interfaces

```bash
firewall-cmd --permanent --add-port=3000/tcp
```

This opens ports on **all network interfaces**, not just localhost. On a machine connected to a public network, this exposes your dev servers. Consider binding to a specific zone or using `--zone=trusted` with a loopback-only approach.

### pip3 install --upgrade as Root

Running `pip3 install --upgrade pip` as root modifies the **system Python**. This can break system tools that depend on specific pip/setuptools versions (like `dnf` on some RHEL systems). Safer to use `pip3 install --user` or work in virtualenvs.

### fd-find Availability

`fd-find` may not be in EPEL for all Rocky versions. The `2>/dev/null || true` suppresses the error, but you silently miss the install.

---

## Suggested Additions Based on Your Profile

Based on your GitHub repos (Python ML/AI, RAG pipelines, data science, Flutter/Dart, TypeScript), here are recommended additions:

### For Your AI/ML Work (RAG, Pickleball-Vision-LLM, Medical-Research)

```bash
# Python data science / ML stack
pip3 install numpy pandas scikit-learn matplotlib seaborn jupyter
pip3 install torch torchvision  # or tensorflow
pip3 install langchain openai chromadb faiss-cpu
pip3 install transformers datasets accelerate

# Conda/Mamba (better for ML dependency management)
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3-Linux-x86_64.sh -b -p /opt/miniforge3
```

### For Your Flutter/Dart Work (Pediatrics app)

```bash
# Flutter SDK
git clone https://github.com/flutter/flutter.git /opt/flutter
echo 'export PATH=$PATH:/opt/flutter/bin' > /etc/profile.d/flutter.sh

# Android SDK (if needed)
dnf install -y android-tools
```

### For DevOps / Infrastructure

```bash
# Terraform
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
dnf install -y terraform

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# AWS CLI (for your Bedrock work)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp && /tmp/aws/install

# Ansible
dnf install -y ansible-core
```

### For Better Shell Experience (matching your Dotfiles repo)

```bash
# zsh + oh-my-zsh
dnf install -y zsh
chsh -s $(which zsh) "$SUDO_USER"

# fzf (fuzzy finder)
git clone --depth 1 https://github.com/junegunn/fzf.git /opt/fzf
/opt/fzf/install --all

# zoxide (you already use this per your Dotfiles)
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# lazygit
dnf copr enable atim/lazygit -y && dnf install -y lazygit

# neovim (your Dotfiles are Lua-based)
dnf install -y neovim
```

---

## How to Test Safely Before Running on Your Real Machine

### Option 1: Docker Container (fastest, 2 minutes)

```bash
# Spin up a Rocky Linux container
docker run -it --name rocky-test rockylinux:9 bash

# Inside the container, paste or copy the script and run it
# Note: systemctl won't work in a container (no systemd)
# Docker-in-Docker won't work either
# But you can test all dnf installs and verify package availability
```

### Option 2: Podman (rootless, no Docker needed)

```bash
podman run -it --name rocky-test rockylinux:9 bash
```

### Option 3: Vagrant VM (full test, ~10 minutes)

```bash
# Install Vagrant + VirtualBox/libvirt first
mkdir rocky-test && cd rocky-test

cat > Vagrantfile <<'EOF'
Vagrant.configure("2") do |config|
  config.vm.box = "rockylinux/9"
  config.vm.provider "libvirt" do |v|
    v.memory = 4096
    v.cpus = 2
  end
  config.vm.provision "shell", path: "rocky-dev-setup.sh"
end
EOF

cp /path/to/rocky-dev-setup.sh .
vagrant up    # builds VM and runs script
vagrant ssh   # log in and verify
vagrant destroy -f  # clean up
```

### Option 4: Cloud VM (realistic, ~$0.05)

```bash
# AWS
aws ec2 run-instances --image-id ami-ROCKY9 --instance-type t3.medium \
  --key-name mykey --user-data file://rocky-dev-setup.sh

# Or use any cloud provider's Rocky Linux 9 image
# Run the script, verify, then terminate
```

### Dry-Run Approach (no VM needed)

Replace all `dnf install` with `dnf install --assumeno` to see what **would** be installed without actually doing it:

```bash
sed 's/dnf install -y/dnf install --assumeno/g' rocky-dev-setup.sh | sudo bash
```

This will fail at each step (because nothing installs), but you'll see if packages resolve correctly.
