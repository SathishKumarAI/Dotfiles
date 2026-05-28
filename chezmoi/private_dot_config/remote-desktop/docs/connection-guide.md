# Connecting to Your Remote Desktop

Complete guide to connecting to a RustDesk host from any device, with platform-specific instructions, performance tuning, and advanced features.

## Table of Contents

- [Connection Overview](#connection-overview)
- [From Arch Linux](#from-arch-linux)
- [From Rocky / Fedora / RHEL](#from-rocky--fedora--rhel)
- [From Ubuntu / Debian](#from-ubuntu--debian)
- [From Windows](#from-windows)
- [From macOS](#from-macOS)
- [From Android](#from-android)
- [From iOS / iPadOS](#from-ios--ipados)
- [From a Web Browser](#from-a-web-browser)
- [Connection Methods](#connection-methods)
- [Performance Tuning](#performance-tuning)
- [File Transfer](#file-transfer)
- [Clipboard Sharing](#clipboard-sharing)
- [Multi-Monitor Support](#multi-monitor-support)
- [Keyboard and Input](#keyboard-and-input)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting Connections](#troubleshooting-connections)

---

## Connection Overview

To connect to a RustDesk host, you need:
1. **RustDesk client** installed on your device
2. **Host ID** — the 9-digit number shown in the host's RustDesk window
3. **Password** — either the one-time or permanent password set on the host

```
Client Device                    Host Machine
┌──────────┐                     ┌──────────────┐
│ RustDesk  │ ─── Enter ID ───►  │ RustDesk     │
│ Client    │ ─── Password ───►  │ Daemon (24/7)│
│           │ ◄── Screen ──────  │              │
│           │ ─── Input ───────► │              │
└──────────┘                     └──────────────┘
```

---

## From Arch Linux

This is the primary client scenario — connecting from an Arch Linux device to the Rocky Linux host.

### Install RustDesk

**Option A: Using the provided script (recommended)**
```bash
bash ~/.config/remote-desktop/scripts/install-rustdesk-arch.sh
```

**Option B: Manual AUR install**
```bash
# Using yay
yay -S rustdesk-bin

# Or using paru
paru -S rustdesk-bin

# Or without an AUR helper
git clone https://aur.archlinux.org/rustdesk-bin.git
cd rustdesk-bin
makepkg -si
```

### Connect via GUI
```bash
rustdesk
```
1. Enter the **Host ID** (9-digit number) in the field
2. Click **"Connect"**
3. Enter the **password** when prompted
4. You're in — full GUI access to the host machine

### Connect via CLI
```bash
# Direct connection
rustdesk --connect <HOST_ID>

# Using the helper script
bash ~/.config/remote-desktop/scripts/connect-rustdesk.sh <HOST_ID>
```

### Connect via Direct IP (same LAN)
If both machines are on the same network (e.g., both on 192.168.1.x):
```bash
rustdesk --connect 192.168.1.157
```
This bypasses the relay server for lowest latency.

---

## From Rocky / Fedora / RHEL

```bash
# Install
RUSTDESK_VERSION=1.4.6
curl -L -o /tmp/rustdesk.rpm \
  "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-0.x86_64.rpm"
sudo dnf install -y /tmp/rustdesk.rpm

# Connect
rustdesk --connect <HOST_ID>
```

Or use the provided script:
```bash
bash ~/.config/remote-desktop/scripts/install-rustdesk-rocky.sh  # or fedora variant
bash ~/.config/remote-desktop/scripts/connect-rustdesk.sh <HOST_ID>
```

---

## From Ubuntu / Debian

```bash
# Install
RUSTDESK_VERSION=1.4.6
curl -L -o /tmp/rustdesk.deb \
  "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-x86_64.deb"
sudo apt install -y /tmp/rustdesk.deb

# Connect
rustdesk --connect <HOST_ID>
```

Or use the provided script:
```bash
bash ~/.config/remote-desktop/scripts/install-rustdesk-ubuntu.sh
bash ~/.config/remote-desktop/scripts/connect-rustdesk.sh <HOST_ID>
```

---

## From Windows

### Install
1. Go to https://rustdesk.com/ → Download → Windows
2. Run the `.exe` installer
3. Allow through Windows Defender / firewall if prompted

### Connect
1. Open RustDesk
2. Enter the **Host ID** in the connection field
3. Click **"Connect"**
4. Enter the password
5. Full remote desktop access

### Portable Mode
Download the portable `.exe` — no installation needed. Run from USB drive for on-the-go access.

---

## From macOS

### Install
1. Go to https://rustdesk.com/ → Download → macOS
2. Open the `.dmg` file
3. Drag RustDesk to **Applications**
4. First launch: System Settings → Privacy & Security → allow RustDesk
5. Grant **Accessibility** and **Screen Recording** permissions if prompted

### Connect
1. Open RustDesk from Applications
2. Enter the Host ID, click Connect
3. Enter the password

---

## From Android

### Install
1. Open **Google Play Store**
2. Search "RustDesk Remote Desktop"
3. Install the official RustDesk app

### Connect
1. Open RustDesk
2. Tap the connection field, enter the **Host ID**
3. Tap **"Connect"**
4. Enter the password
5. Use touch gestures:
   - **Tap** = left click
   - **Long press** = right click
   - **Two-finger drag** = scroll
   - **Pinch** = zoom
   - **Three-finger tap** = open toolbar (keyboard, shortcuts, etc.)

---

## From iOS / iPadOS

### Install
1. Open the **App Store**
2. Search "RustDesk"
3. Install the official app

### Connect
Same as Android — enter Host ID, password, and use touch gestures.

iPadOS tip: Use an external keyboard and mouse/trackpad for a desktop-like experience.

---

## From a Web Browser

RustDesk has an experimental web client:

1. Navigate to `http://<relay-server-ip>:21118` (if self-hosting a relay)
2. Enter the Host ID and password
3. Access via browser without installing anything

Note: The web client requires a self-hosted relay server. The public relay does not expose a web interface.

---

## Connection Methods

| Method | When to Use | Latency | Setup |
|--------|-------------|---------|-------|
| **Relay (default)** | Different networks, mobile data | Medium | None — works out of the box |
| **Direct IP** | Same LAN | Lowest | Enable in settings, use LAN IP |
| **P2P (auto)** | RustDesk auto-tries this first | Low | Automatic via UDP hole punching |
| **Self-hosted relay** | Privacy-critical, corporate | Medium | Requires running hbbs/hbbr |

### How NAT traversal works
```
1. Both client and host register with relay server
2. Relay tells each side the other's public IP + port
3. Both sides send UDP packets to each other (hole punching)
4. If direct P2P succeeds → data flows directly
5. If P2P fails (strict NAT) → relay forwards the data
6. All paths are E2E encrypted — relay cannot see content
```

---

## Performance Tuning

### For slow connections (mobile data, remote locations)
- RustDesk → Settings → Display → **Image Quality: Low**
- Disable cursor animations
- Close unnecessary desktop effects on the host
- Use a lightweight DE (XFCE) if possible

### For LAN connections
- RustDesk → Settings → Display → **Image Quality: Best**
- Enable **"Direct IP access"** to bypass relay entirely
- Connect using the LAN IP instead of the ID
- Expected: near-native responsiveness at 60fps

### Bandwidth estimates

| Quality Setting | Bandwidth Needed | Best For |
|----------------|------------------|----------|
| Low | 0.5-1 Mbps | Mobile data, slow WiFi |
| Balanced (default) | 2-5 Mbps | Normal remote work |
| Best | 5-20 Mbps | LAN, creative work, multi-monitor |

---

## File Transfer

RustDesk includes a built-in file transfer feature:

1. Connect to the host
2. Click the **"File Transfer"** tab in the toolbar (or press the shortcut)
3. Browse files on both machines side by side
4. Drag and drop or use the transfer buttons
5. Progress bar shows transfer status

Alternatively, use the CLI:
```bash
rustdesk --file-transfer <HOST_ID>
```

---

## Clipboard Sharing

Clipboard is shared automatically between client and host:
- **Text**: copy on one side, paste on the other
- **Images**: supported on most platforms
- **Files**: use the file transfer feature instead

To disable clipboard sharing: Settings → Security → uncheck "Enable clipboard"

---

## Multi-Monitor Support

If the host has multiple monitors:
1. Connect normally
2. Use the **monitor selector** in the toolbar to switch between displays
3. Or select **"All monitors"** to see them in a tiled layout

Keyboard shortcut to cycle monitors: check RustDesk toolbar for the hotkey.

---

## Keyboard and Input

### Key mapping
- Most keys map directly between client and host
- Special keys (Super/Windows, modifier combos) work via the toolbar
- If keys don't map correctly: Settings → Input → configure key mapping

### Keyboard shortcuts while connected
| Shortcut | Action |
|----------|--------|
| Toolbar button | Toggle fullscreen |
| Toolbar button | Switch monitors |
| Toolbar button | Open virtual keyboard (mobile) |
| Toolbar button | Ctrl+Alt+Del |
| Toolbar button | Toggle clipboard sync |

### Input mode (mobile)
- **Touch mode**: tap = click, drag = drag
- **Mouse mode**: finger controls a virtual cursor (more precise)
- Switch via the toolbar

---

## Security Best Practices

### Authentication
- **Always set a permanent password** — one-time passwords change on restart, which is annoying but not more secure for always-on hosts
- **Use a strong password** — minimum 12 characters, mix of letters/numbers/symbols
- **Whitelist trusted IDs** — Settings → Security → only allow specific device IDs

### Network
- **E2E encryption** is always on (Ed25519 + AES-256-GCM) — even the relay server cannot decrypt your traffic
- **Self-host the relay** for maximum privacy (see future TODOs in [tasks.md](../logs/tasks.md))
- **Use Tailscale/WireGuard** as an additional layer for corporate setups

### Access control
- **Lock screen on disconnect** — Settings → Security → "Lock screen after session ends"
- **Require confirmation** — Settings → Security → "Require user confirmation for incoming connections"
- **Disable unattended access** if you want to approve each connection manually

### Monitoring
```bash
# Check who's connected
sudo journalctl -u rustdesk -n 100 | grep -i "connect"

# Check service uptime
systemctl status rustdesk
```

---

## Troubleshooting Connections

### "Connection timed out"
1. Host service running? `systemctl is-active rustdesk`
2. Host has internet? `ping 8.8.8.8`
3. Firewall blocking? Check firewall rules
4. Try from a different network to rule out client-side NAT issues

### "Wrong password"
1. Verify you're using the correct password (permanent vs. one-time)
2. Check if someone changed the password
3. If locked out: on the host, open RustDesk → reset password

### "Black screen" after connecting
1. Wayland? Install `xdg-desktop-portal` + portal backend
2. PipeWire running? `systemctl --user status pipewire`
3. Try X11 session as fallback
4. Check RustDesk logs: `journalctl -u rustdesk -n 50`

### Laggy / choppy
1. Check bandwidth on both sides
2. Lower image quality setting
3. Disable desktop effects on host
4. Try direct IP if on same LAN
5. Check if other apps are consuming bandwidth

### Connection drops frequently
1. Check host internet stability
2. Increase keepalive: the systemd override already ensures auto-restart
3. Check `journalctl -u rustdesk` for crash patterns
4. Update to latest RustDesk version
