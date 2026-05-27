# Remote Desktop Setup (RustDesk)

> GUI-based remote desktop access using [RustDesk](https://rustdesk.com/) — an open-source, cross-platform alternative to Chrome Remote Desktop. Access your machines from anywhere, anytime, with no port forwarding required.

| Feature | Details |
|---------|---------|
| **Tool** | [RustDesk](https://rustdesk.com/) v1.4.6 |
| **License** | GPL-3.0 (open-source) |
| **Encryption** | End-to-end (Ed25519 + AES-256-GCM) |
| **NAT Traversal** | Built-in relay servers (no port forwarding) |
| **Platforms** | Linux, Windows, macOS, Android, iOS, Web |
| **Service Mode** | 24/7 systemd with auto-restart |

## Why RustDesk over Chrome Remote Desktop?

| Criteria | Chrome Remote Desktop | RustDesk |
|----------|----------------------|----------|
| RPM distro support (Rocky/RHEL/Fedora) | Not available (DEB only) | Native RPM + AUR |
| Open source | No | Yes (GPL-3.0) |
| Self-hostable relay | No | Yes |
| Port forwarding needed | No | No |
| Browser-based access | Yes | Partial (web client available) |
| Mobile apps | Yes | Yes |
| File transfer | No | Yes |
| Clipboard sync | Yes | Yes |
| Multi-monitor | Limited | Yes |

Chrome Remote Desktop was the initial choice but Google does **not** provide an RPM package and the download URL returns 404 for non-Debian systems. See [logs/setup-log.md](logs/setup-log.md) for the full decision rationale.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  YOUR NETWORK                        │
│                                                      │
│  ┌─────────────────┐       ┌─────────────────────┐  │
│  │  Rocky Linux     │       │  Arch Linux Client  │  │
│  │  (Host/Server)   │       │  (or any device)    │  │
│  │                  │       │                     │  │
│  │  rustdesk daemon │       │  rustdesk client    │  │
│  │  (systemd 24/7)  │       │                     │  │
│  └────────┬─────────┘       └──────────┬──────────┘  │
│           │                            │             │
└───────────┼────────────────────────────┼─────────────┘
            │                            │
            │   ┌──────────────────┐     │
            └──►│  RustDesk Relay  │◄────┘
                │  (Public/Free)   │
                │  NAT Traversal   │
                │  E2E Encrypted   │
                └──────────────────┘
                         ▲
                         │
              ┌──────────┴──────────┐
              │  Remote Access      │
              │  (Phone/Laptop/PC)  │
              │  From Anywhere      │
              └─────────────────────┘
```

## Quick Start

### Host Machine (the machine you want to access remotely)

```bash
# Auto-detects your distro and installs + configures RustDesk
bash scripts/install-rustdesk.sh
```

This will:
- Install RustDesk
- Enable it as a 24/7 systemd service (survives reboots)
- Configure auto-restart on crash (5 second delay)
- Open firewall ports if applicable (21115-21119/tcp, 21116/udp)

After install, launch `rustdesk` from your desktop and note the **ID** and **password**.

### Client Machine (the machine you're connecting FROM)

```bash
# Install RustDesk client (same script works)
bash scripts/install-rustdesk.sh

# Connect to the host
bash scripts/connect-rustdesk.sh <HOST_ID>
```

Or just open RustDesk, enter the host's ID, and type the password.

## Supported Distros

| Distro Family | Package Method | Script | Tested |
|---------------|----------------|--------|--------|
| Rocky/RHEL/CentOS/AlmaLinux | RPM (GitHub release) | `install-rustdesk-rocky.sh` | Rocky 10.1 |
| Arch/Manjaro/EndeavourOS | AUR (`rustdesk-bin`) | `install-rustdesk-arch.sh` | Planned |
| Ubuntu/Debian/Mint/Pop!_OS | DEB (GitHub release) | `install-rustdesk-ubuntu.sh` | Planned |
| Fedora | RPM (GitHub release) | `install-rustdesk-fedora.sh` | Planned |

Use `install-rustdesk.sh` to auto-detect your distro and run the right script.

## Directory Structure

```
remote-desktop/
├── README.md                          # This file — project overview and quick start
├── scripts/
│   ├── install-rustdesk.sh            # Universal installer (auto-detects distro)
│   ├── install-rustdesk-rocky.sh      # Rocky/RHEL/CentOS/AlmaLinux
│   ├── install-rustdesk-arch.sh       # Arch/Manjaro/EndeavourOS
│   ├── install-rustdesk-ubuntu.sh     # Ubuntu/Debian/Mint/Pop!_OS
│   ├── install-rustdesk-fedora.sh     # Fedora
│   ├── connect-rustdesk.sh            # Client connection helper (CLI)
│   └── uninstall-rustdesk.sh          # Clean removal for all distros
├── docs/
│   ├── setup-guide.md                 # Detailed setup: prerequisites, per-distro walkthrough, verification, advanced config
│   └── connection-guide.md            # Connect from any device: Linux, Windows, macOS, Android, iOS + performance tuning
└── logs/
    ├── tasks.md                       # Project board: completed, in-progress, and future tasks
    └── setup-log.md                   # Decision log, timeline, environment details, session history
```

## Reproducing on a New Machine

### Via chezmoi (recommended)
```bash
# 1. Install chezmoi and pull dotfiles
chezmoi init SathishKumarAI/Dotfiles

# 2. Apply all dotfiles (including remote-desktop scripts)
chezmoi apply

# 3. Run the installer
bash ~/.config/remote-desktop/scripts/install-rustdesk.sh
```

### Manual (without chezmoi)
```bash
# 1. Clone the repo
git clone https://github.com/SathishKumarAI/Dotfiles.git
cd Dotfiles/private_dot_config/remote-desktop

# 2. Run the installer
bash scripts/install-rustdesk.sh
```

Three commands to get remote desktop on any new Linux box.

## Updating RustDesk

```bash
# Specify a newer version
RUSTDESK_VERSION=1.4.7 bash scripts/install-rustdesk.sh

# On Arch, just update via AUR
yay -Syu rustdesk-bin
```

## Uninstall

```bash
bash scripts/uninstall-rustdesk.sh
```

Removes the package, disables the service, cleans up systemd overrides and config.

## Documentation

| Document | Description |
|----------|-------------|
| [Setup Guide](docs/setup-guide.md) | Full walkthrough: prerequisites, per-distro steps, verification, Wayland config, advanced settings |
| [Connection Guide](docs/connection-guide.md) | How to connect from every platform, performance tuning, file transfer, security hardening |
| [Task Log](logs/tasks.md) | Project board with completed work, pending actions, and future roadmap |
| [Setup Log](logs/setup-log.md) | Decision rationale, environment details, timeline, and session history |

## Project Status and Roadmap

See [logs/tasks.md](logs/tasks.md) for the full task board. Key highlights:

### Done
- Multi-distro install scripts (Rocky, Arch, Ubuntu, Fedora)
- 24/7 systemd service with auto-restart
- Full documentation suite
- Pushed to chezmoi dotfiles on GitHub

### Next Up
- Run installer on Rocky Linux host
- Test Arch Linux client connection
- Set permanent password and whitelist devices

### Future
- Self-hosted relay server for maximum privacy
- Wake-on-LAN integration for remote power-on
- Monitoring dashboard for connection health
- Automated backup of RustDesk config across machines
