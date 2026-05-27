# Setup Log

## 2026-05-26 — Initial Setup

### Environment
- Host: Rocky Linux 10.1 (Red Quartz)
- Desktop: GNOME on Wayland
- Display Manager: GDM
- IP: 192.168.1.157

### Decision: Chrome Remote Desktop → RustDesk
- Chrome Remote Desktop does NOT support RPM-based Linux distros
- Google only ships a .deb package (Debian/Ubuntu only)
- Direct download URL returns 404 for RPM: `https://dl.google.com/linux/direct/chrome-remote-desktop_current_x86_64.rpm`
- Selected RustDesk 1.4.6 as replacement
  - Open-source (GPL-3.0)
  - Native RPM support
  - No port forwarding needed (uses relay servers)
  - End-to-end encrypted
  - Cross-platform clients (Linux, Windows, macOS, Android, iOS)

### Files Created
- `scripts/install-rustdesk.sh` — Universal installer (auto-detects distro)
- `scripts/install-rustdesk-rocky.sh` — Rocky/RHEL/CentOS
- `scripts/install-rustdesk-arch.sh` — Arch/Manjaro
- `scripts/install-rustdesk-ubuntu.sh` — Ubuntu/Debian
- `scripts/install-rustdesk-fedora.sh` — Fedora
- `scripts/connect-rustdesk.sh` — Client connection helper
- `scripts/uninstall-rustdesk.sh` — Clean removal
- `docs/setup-guide.md` — Detailed setup instructions
- `docs/connection-guide.md` — Multi-platform connection guide
- `logs/tasks.md` — Task tracking
- `logs/setup-log.md` — This file

### Service Configuration
- systemd service: `rustdesk` (enabled, 24/7)
- Auto-restart: `Restart=always`, `RestartSec=5`
- Firewall ports: 21115-21119/tcp, 21116/udp

### Next Steps
1. Run install script on Rocky host: `bash scripts/install-rustdesk-rocky.sh`
2. Set permanent password in RustDesk GUI
3. Install on Arch client and test connection
