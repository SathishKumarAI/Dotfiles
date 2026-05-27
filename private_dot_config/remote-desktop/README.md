# Remote Desktop Setup (RustDesk)

GUI-based remote desktop access using [RustDesk](https://rustdesk.com/) — an open-source, cross-platform alternative to Chrome Remote Desktop.

Works on: Rocky/RHEL/CentOS, Arch, Ubuntu/Debian, Fedora.

## Quick Start

### Host Machine (the machine you want to access remotely)

```bash
# Auto-detects your distro and installs + configures RustDesk
bash scripts/install-rustdesk.sh
```

This will:
- Install RustDesk
- Enable it as a 24/7 systemd service (survives reboots)
- Configure auto-restart on crash
- Open firewall ports if applicable

After install, launch `rustdesk` from your desktop and note the **ID** and **password**.

### Client Machine (the machine you're connecting FROM)

```bash
# Install RustDesk client (same script works)
bash scripts/install-rustdesk.sh

# Connect to the host
bash scripts/connect-rustdesk.sh <HOST_ID>
```

Or just open RustDesk, enter the host's ID, and type the password.

## Directory Structure

```
remote-desktop/
├── README.md              # This file
├── scripts/
│   ├── install-rustdesk.sh        # Universal installer (auto-detects distro)
│   ├── install-rustdesk-rocky.sh  # Rocky/RHEL/CentOS
│   ├── install-rustdesk-arch.sh   # Arch/Manjaro/EndeavourOS
│   ├── install-rustdesk-ubuntu.sh # Ubuntu/Debian/Mint
│   ├── install-rustdesk-fedora.sh # Fedora
│   ├── connect-rustdesk.sh        # Client connection helper
│   └── uninstall-rustdesk.sh      # Clean removal
├── docs/
│   ├── setup-guide.md             # Detailed setup instructions
│   └── connection-guide.md        # How to connect from any device
└── logs/
    ├── tasks.md                   # Task tracking
    └── setup-log.md               # Setup history and notes
```

## Reproducing on a New Machine

1. Clone your dotfiles: `chezmoi init <your-github-user>`
2. Apply: `chezmoi apply`
3. Run: `bash ~/.config/remote-desktop/scripts/install-rustdesk.sh`

That's it — 3 commands to get remote desktop on any new Linux box.

## Uninstall

```bash
bash scripts/uninstall-rustdesk.sh
```
