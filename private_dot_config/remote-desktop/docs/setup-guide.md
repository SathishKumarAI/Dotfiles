# RustDesk Setup Guide

## Prerequisites

- Linux with systemd (any modern distro)
- sudo access
- Internet connection (for download and relay servers)
- A desktop environment (GNOME, KDE, XFCE, etc.)

## Supported Distros

| Distro Family        | Package Method | Script                      |
|----------------------|----------------|-----------------------------|
| Rocky/RHEL/CentOS    | RPM (GitHub)   | `install-rustdesk-rocky.sh` |
| Arch/Manjaro         | AUR            | `install-rustdesk-arch.sh`  |
| Ubuntu/Debian/Mint   | DEB (GitHub)   | `install-rustdesk-ubuntu.sh`|
| Fedora               | RPM (GitHub)   | `install-rustdesk-fedora.sh`|

Or use `install-rustdesk.sh` which auto-detects your distro.

## What Gets Installed

1. **RustDesk binary** — the GUI application
2. **rustdesk systemd service** — keeps the daemon running 24/7
3. **Service override** — auto-restarts on crash (5s delay)
4. **Firewall rules** — ports 21115-21119/tcp, 21116/udp (if firewall detected)

## How It Works

- RustDesk uses **relay servers** for NAT traversal (like Chrome Remote Desktop)
- No port forwarding needed on your router
- Connections are **end-to-end encrypted**
- The systemd service keeps it running even when no one is logged into the desktop
- It survives reboots via `systemctl enable`

## After Installation

1. Open RustDesk from your application menu (or run `rustdesk`)
2. You'll see your **ID** (9 digits) and a **one-time password**
3. Set a **permanent password**: click the 3 dots next to the password → "Set permanent password"
4. Note the ID — this is what you'll use to connect from other devices

## Updating RustDesk

```bash
# Set the new version and re-run
RUSTDESK_VERSION=1.4.7 bash scripts/install-rustdesk.sh
```

On Arch, the AUR package updates normally via your AUR helper.

## Troubleshooting

### Service not running
```bash
sudo systemctl status rustdesk
sudo journalctl -u rustdesk -n 50
```

### Can't connect from remote
- Verify the service is running: `systemctl is-active rustdesk`
- Check firewall: `sudo firewall-cmd --list-all` or `sudo ufw status`
- Try restarting: `sudo systemctl restart rustdesk`

### Wayland issues
RustDesk works with Wayland via PipeWire screen capture. If screen sharing doesn't work:
- Ensure `xdg-desktop-portal` and `xdg-desktop-portal-gnome` (or your DE equivalent) are installed
- Try switching to X11 session at the login screen as a fallback

### Display not found after reboot
If connecting when no one is logged in at the desktop:
- Enable auto-login in GDM/SDDM settings, OR
- The RustDesk service creates a virtual display for headless access
