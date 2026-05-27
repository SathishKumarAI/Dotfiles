#!/bin/bash
# RustDesk host setup for Ubuntu / Debian / Mint
set -euo pipefail

RUSTDESK_VERSION="${RUSTDESK_VERSION:-1.4.6}"
DEB_URL="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-x86_64.deb"

echo "[*] Installing RustDesk ${RUSTDESK_VERSION} on Ubuntu/Debian..."

if dpkg -l rustdesk 2>/dev/null | grep -q '^ii'; then
    echo "[!] RustDesk already installed: $(dpkg -l rustdesk | grep '^ii' | awk '{print $3}')"
    read -rp "Reinstall? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

TMP_DEB=$(mktemp /tmp/rustdesk-XXXXX.deb)
echo "[*] Downloading from ${DEB_URL}..."
curl -L -o "$TMP_DEB" "$DEB_URL"

echo "[*] Installing..."
sudo apt-get install -y "$TMP_DEB"
rm -f "$TMP_DEB"

echo "[*] Enabling RustDesk service (24/7, survives reboot)..."
sudo systemctl enable --now rustdesk

echo "[*] Configuring auto-restart on crash..."
sudo mkdir -p /etc/systemd/system/rustdesk.service.d
sudo tee /etc/systemd/system/rustdesk.service.d/override.conf > /dev/null <<'EOF'
[Service]
Restart=always
RestartSec=5
EOF
sudo systemctl daemon-reload
sudo systemctl restart rustdesk

echo "[*] Opening firewall ports..."
if command -v ufw &>/dev/null; then
    sudo ufw allow 21115:21119/tcp 2>/dev/null || true
    sudo ufw allow 21116/udp 2>/dev/null || true
fi

echo "[*] Verifying..."
sudo systemctl status rustdesk --no-pager

echo ""
echo "=== DONE ==="
echo "Launch 'rustdesk' from your desktop to get your ID and password."
echo "The service runs 24/7 and auto-starts on boot."
