# Connecting to Your Remote Desktop

## From Arch Linux

### Install RustDesk client
```bash
# Using yay
yay -S rustdesk-bin

# Or using paru
paru -S rustdesk-bin

# Or use the provided script
bash ~/.config/remote-desktop/scripts/install-rustdesk-arch.sh
```

### Connect
```bash
# Via GUI — open RustDesk, enter the host ID, click Connect
rustdesk

# Via CLI
rustdesk --connect <HOST_ID>

# Or use the helper script
bash ~/.config/remote-desktop/scripts/connect-rustdesk.sh <HOST_ID>
```

## From Ubuntu/Debian

```bash
# Download and install
RUSTDESK_VERSION=1.4.6
curl -L -o /tmp/rustdesk.deb "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-x86_64.deb"
sudo apt install -y /tmp/rustdesk.deb

# Connect
rustdesk --connect <HOST_ID>
```

## From Fedora / Rocky

```bash
RUSTDESK_VERSION=1.4.6
curl -L -o /tmp/rustdesk.rpm "https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-0.x86_64.rpm"
sudo dnf install -y /tmp/rustdesk.rpm

rustdesk --connect <HOST_ID>
```

## From Windows

1. Download RustDesk from https://rustdesk.com/
2. Run the installer
3. Open RustDesk, enter the host ID, click Connect
4. Enter the password

## From macOS

1. Download RustDesk from https://rustdesk.com/
2. Open the .dmg, drag to Applications
3. Open RustDesk, enter the host ID, click Connect

## From Android / iOS

1. Install "RustDesk" from Play Store / App Store
2. Enter the host ID, tap Connect
3. Enter the password

## Connection Tips

- **First time**: You'll be prompted for the password shown in the host's RustDesk window
- **Permanent password**: Set one on the host so it doesn't change on restart
- **Performance**: RustDesk auto-adjusts quality based on bandwidth
- **File transfer**: Use the file transfer tab in the connection window
- **Clipboard**: Shared automatically between host and client
- **Multiple monitors**: Switch between monitors using the toolbar

## Security

- All connections are end-to-end encrypted (Ed25519 + AES-256)
- The 9-digit ID + password are required to connect
- You can whitelist specific IDs in RustDesk settings
- Connections use RustDesk's public relay servers by default (free)
- For maximum privacy, you can self-host a relay server
