# RustDesk Setup Guide

Complete walkthrough for setting up RustDesk as a 24/7 remote desktop server on any supported Linux distro.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Supported Distros](#supported-distros)
- [What Gets Installed](#what-gets-installed)
- [How It Works](#how-it-works)
- [Step-by-Step: Rocky Linux / RHEL / CentOS](#step-by-step-rocky-linux--rhel--centos)
- [Step-by-Step: Arch Linux / Manjaro](#step-by-step-arch-linux--manjaro)
- [Step-by-Step: Ubuntu / Debian](#step-by-step-ubuntu--debian)
- [Step-by-Step: Fedora](#step-by-step-fedora)
- [Post-Install Configuration](#post-install-configuration)
- [Wayland Configuration](#wayland-configuration)
- [Headless / Unattended Access](#headless--unattended-access)
- [Advanced Configuration](#advanced-configuration)
- [Updating RustDesk](#updating-rustdesk)
- [Uninstalling](#uninstalling)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **OS** | Any Linux with systemd (kernel 5.x+) |
| **Access** | sudo / root privileges |
| **Network** | Internet connection (for download and relay servers) |
| **Desktop** | GNOME, KDE, XFCE, Hyprland, Sway, or any DE/WM |
| **Display** | X11 or Wayland (both supported; Wayland needs PipeWire) |
| **Disk** | ~80 MB for RustDesk binary |

### Optional but Recommended
- `curl` or `wget` for downloading (installed by default on most distros)
- `firewall-cmd` or `ufw` if you have a firewall active
- `xdg-desktop-portal` + portal backend for Wayland screen sharing

---

## Supported Distros

| Distro Family | Package Source | Install Script | Notes |
|---------------|---------------|----------------|-------|
| Rocky/RHEL/CentOS/AlmaLinux | RPM from GitHub releases | `install-rustdesk-rocky.sh` | Tested on Rocky 10.1 |
| Arch/Manjaro/EndeavourOS | AUR (`rustdesk-bin`) | `install-rustdesk-arch.sh` | Needs AUR helper (yay/paru) |
| Ubuntu/Debian/Mint/Pop!_OS | DEB from GitHub releases | `install-rustdesk-ubuntu.sh` | Works on 20.04+ |
| Fedora | RPM from GitHub releases | `install-rustdesk-fedora.sh` | Works on Fedora 38+ |

**Universal installer:** `install-rustdesk.sh` auto-detects your distro via `/etc/os-release` and runs the appropriate script.

---

## What Gets Installed

1. **RustDesk binary** (`/usr/bin/rustdesk`) — the GUI application and daemon
2. **rustdesk systemd service** (`/usr/lib/systemd/system/rustdesk.service`) — keeps the daemon running 24/7
3. **Service override** (`/etc/systemd/system/rustdesk.service.d/override.conf`) — auto-restarts on crash with 5s delay
4. **Firewall rules** — ports 21115-21119/tcp and 21116/udp (only if firewalld or ufw is detected)

### Ports Used

| Port | Protocol | Purpose |
|------|----------|---------|
| 21115 | TCP | NAT type test |
| 21116 | TCP/UDP | Hole punching / relay |
| 21117 | TCP | Relay |
| 21118 | TCP | WebSocket for web client |
| 21119 | TCP | WebSocket for web client |

These ports are only needed if you self-host a relay server. When using the public relay, no ports need to be opened on the client side.

---

## How It Works

```
1. RustDesk daemon starts → registers with relay server
2. Client enters Host ID → relay server brokers the connection
3. Direct P2P connection established (UDP hole punching)
4. If P2P fails → traffic relayed through relay server
5. All traffic is end-to-end encrypted regardless of path
```

- **NAT traversal**: RustDesk's relay servers handle hole punching so you never need to configure port forwarding on your router
- **Encryption**: Ed25519 key exchange + AES-256-GCM for all data in transit
- **Persistence**: The systemd service keeps the daemon running even when no one is logged into the desktop GUI
- **Resilience**: The override config restarts the service automatically if it ever crashes

---

## Step-by-Step: Rocky Linux / RHEL / CentOS

This is the primary target distro (tested on Rocky Linux 10.1 with GNOME/Wayland).

### 1. Run the install script
```bash
bash ~/.config/remote-desktop/scripts/install-rustdesk-rocky.sh
```

Or manually:
```bash
# Download the RPM
RUSTDESK_VERSION=1.4.6
curl -L -o /tmp/rustdesk.rpm \
  "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-0.x86_64.rpm"

# Install
sudo dnf install -y /tmp/rustdesk.rpm

# Enable 24/7 service
sudo systemctl enable --now rustdesk

# Configure auto-restart
sudo mkdir -p /etc/systemd/system/rustdesk.service.d
sudo tee /etc/systemd/system/rustdesk.service.d/override.conf > /dev/null <<'EOF'
[Service]
Restart=always
RestartSec=5
EOF
sudo systemctl daemon-reload
sudo systemctl restart rustdesk
```

### 2. Verify the service
```bash
sudo systemctl status rustdesk
# Expected: Active: active (running)

sudo journalctl -u rustdesk -n 20 --no-pager
# Check for any errors
```

### 3. Open firewall (if active)
```bash
sudo firewall-cmd --permanent --add-port=21115-21119/tcp
sudo firewall-cmd --permanent --add-port=21116/udp
sudo firewall-cmd --reload
sudo firewall-cmd --list-all  # verify
```

### 4. Get your ID and password
```bash
# Launch the GUI
rustdesk
# Note the 9-digit ID and password displayed in the window
```

---

## Step-by-Step: Arch Linux / Manjaro

### 1. Run the install script
```bash
bash ~/.config/remote-desktop/scripts/install-rustdesk-arch.sh
```

Or manually:
```bash
# Install from AUR (using yay)
yay -S --noconfirm rustdesk-bin

# Or using paru
paru -S --noconfirm rustdesk-bin

# Enable 24/7 service
sudo systemctl enable --now rustdesk

# Configure auto-restart
sudo mkdir -p /etc/systemd/system/rustdesk.service.d
sudo tee /etc/systemd/system/rustdesk.service.d/override.conf > /dev/null <<'EOF'
[Service]
Restart=always
RestartSec=5
EOF
sudo systemctl daemon-reload
sudo systemctl restart rustdesk
```

### 2. Verify
```bash
sudo systemctl status rustdesk
rustdesk  # launch GUI to get ID
```

### 3. Firewall (if using ufw)
```bash
sudo ufw allow 21115:21119/tcp
sudo ufw allow 21116/udp
sudo ufw status
```

---

## Step-by-Step: Ubuntu / Debian

### 1. Run the install script
```bash
bash ~/.config/remote-desktop/scripts/install-rustdesk-ubuntu.sh
```

Or manually:
```bash
RUSTDESK_VERSION=1.4.6
curl -L -o /tmp/rustdesk.deb \
  "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-x86_64.deb"

sudo apt-get install -y /tmp/rustdesk.deb

sudo systemctl enable --now rustdesk

sudo mkdir -p /etc/systemd/system/rustdesk.service.d
sudo tee /etc/systemd/system/rustdesk.service.d/override.conf > /dev/null <<'EOF'
[Service]
Restart=always
RestartSec=5
EOF
sudo systemctl daemon-reload
sudo systemctl restart rustdesk
```

### 2. Verify
```bash
sudo systemctl status rustdesk
rustdesk
```

---

## Step-by-Step: Fedora

### 1. Run the install script
```bash
bash ~/.config/remote-desktop/scripts/install-rustdesk-fedora.sh
```

Or manually — same as Rocky Linux steps above (both use `dnf`).

---

## Post-Install Configuration

### Set a Permanent Password
By default, RustDesk generates a one-time password that changes on restart. Set a permanent one:

1. Open RustDesk GUI (`rustdesk`)
2. Click the **three dots (...)** next to the password field
3. Select **"Set permanent password"**
4. Enter your desired password
5. This password persists across restarts

### Whitelist Trusted Devices
For extra security, only allow specific RustDesk IDs to connect:

1. Open RustDesk → Settings (gear icon)
2. Go to **Security** tab
3. Enable **"Only allow connections from whitelisted IDs"**
4. Add the IDs of your trusted devices

### Enable Direct IP Access (LAN only)
If both machines are on the same network:

1. Open RustDesk → Settings → Network
2. Enable **"Allow direct IP access"**
3. Enter the host's LAN IP (e.g., `192.168.1.157`)
4. On the client, connect using the IP instead of the ID

---

## Wayland Configuration

RustDesk supports Wayland via PipeWire screen capture. If you're on GNOME/Wayland (like Rocky 10.1):

### Required packages
```bash
# Rocky/Fedora
sudo dnf install -y xdg-desktop-portal xdg-desktop-portal-gnome pipewire

# Arch
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-gnome pipewire

# Ubuntu
sudo apt install -y xdg-desktop-portal xdg-desktop-portal-gnome pipewire
```

### Screen sharing permission
On first connection, GNOME will show a dialog asking to share your screen. Click **"Allow"** — this is the PipeWire portal at work.

### Fallback to X11
If Wayland screen sharing doesn't work:
1. Log out
2. At the GDM/SDDM login screen, click the gear icon
3. Select **"GNOME on Xorg"** (or "Plasma (X11)")
4. Log in — RustDesk will work with X11 without any extra config

---

## Headless / Unattended Access

To access the machine when no one is logged in at the desktop:

### Option 1: Auto-login (recommended for dedicated servers)
```bash
# GNOME/GDM — edit /etc/gdm/custom.conf
sudo tee -a /etc/gdm/custom.conf > /dev/null <<'EOF'
[daemon]
AutomaticLoginEnable=True
AutomaticLogin=your_username
EOF
sudo systemctl restart gdm
```

### Option 2: Virtual display (truly headless)
RustDesk's service mode creates a virtual display when no physical display is available. The systemd service handles this automatically — no extra config needed.

### Option 3: Lock screen access
RustDesk can connect even when the screen is locked. The remote user will see the lock screen and can enter the password to unlock.

---

## Advanced Configuration

### RustDesk config file location
```
~/.config/rustdesk/RustDesk2.toml    # user config
/root/.config/rustdesk/RustDesk2.toml # service config (when running as root)
```

### Custom relay server
If you self-host a RustDesk relay (see future TODOs):
1. Open RustDesk → Settings → Network
2. Set **"ID Server"** to your relay IP/domain
3. Set **"Relay Server"** to the same
4. Set **"API Server"** if using hbbr with API

### Bandwidth settings
- RustDesk auto-adjusts quality based on available bandwidth
- For slow connections: Settings → Display → set **"Image Quality"** to "Low"
- For LAN connections: set to "Best" for near-native quality

### Keyboard mapping
- RustDesk supports custom key mapping for different keyboard layouts
- Settings → Input → configure modifier keys if they mismatch between client/host

---

## Updating RustDesk

```bash
# Set the new version and re-run the installer
RUSTDESK_VERSION=1.4.7 bash scripts/install-rustdesk.sh

# On Arch, just update via AUR
yay -Syu rustdesk-bin
```

The service will automatically restart after the update.

---

## Uninstalling

```bash
bash scripts/uninstall-rustdesk.sh
```

This removes:
- The RustDesk package
- The systemd service and override
- User config (`~/.config/rustdesk`)

---

## Troubleshooting

### Service not running
```bash
sudo systemctl status rustdesk
sudo journalctl -u rustdesk -n 50 --no-pager

# Restart manually
sudo systemctl restart rustdesk
```

### Connection refused / timeout
1. **Check service**: `systemctl is-active rustdesk` → should say "active"
2. **Check firewall**: `sudo firewall-cmd --list-all` or `sudo ufw status`
3. **Check network**: ensure the machine has internet access (`ping 8.8.8.8`)
4. **Check relay**: RustDesk status bar shows "Ready" when connected to relay
5. **Try direct IP**: if on same LAN, connect via IP instead of ID

### Black screen after connecting
- Wayland issue: install `xdg-desktop-portal` + DE-specific portal
- PipeWire not running: `systemctl --user status pipewire`
- Try X11 session as fallback

### Password keeps changing
- Set a permanent password (see [Post-Install Configuration](#post-install-configuration))
- The one-time password changes each service restart by design

### High latency / poor quality
- Check bandwidth: `speedtest-cli` on both machines
- Lower image quality in RustDesk settings
- Use direct IP on LAN for best performance
- Disable desktop effects / compositor for better performance

### SELinux blocking (Rocky/RHEL)
```bash
# Check for denials
sudo ausearch -m avc -ts recent | grep rustdesk

# If blocked, create a policy
sudo audit2allow -a -M rustdesk-local
sudo semodule -i rustdesk-local.pp
sudo systemctl restart rustdesk
```

### Can't install on Arch (AUR build fails)
```bash
# Make sure base-devel is installed
sudo pacman -S --needed base-devel

# Clear AUR cache and retry
yay -Scc
yay -S rustdesk-bin
```
