#!/bin/bash
# RustDesk host setup for Rocky Linux / RHEL / CentOS
set -euo pipefail

RUSTDESK_VERSION="${RUSTDESK_VERSION:-1.4.6}"
RPM_URL="https://github.com/rustdesk/rustdesk/releases/download/${RUSTDESK_VERSION}/rustdesk-${RUSTDESK_VERSION}-0.x86_64.rpm"

echo "[*] Installing RustDesk ${RUSTDESK_VERSION} on Rocky/RHEL/CentOS..."

if rpm -q rustdesk &>/dev/null; then
    echo "[!] RustDesk already installed: $(rpm -q rustdesk)"
    read -rp "Reinstall? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

TMP_RPM=$(mktemp /tmp/rustdesk-XXXXX.rpm)
echo "[*] Downloading from ${RPM_URL}..."
curl -L -o "$TMP_RPM" "$RPM_URL"

echo "[*] Installing..."
sudo dnf install -y "$TMP_RPM"
rm -f "$TMP_RPM"

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

echo "[*] Opening firewall ports (21115-21119/tcp, 21116/udp)..."
if command -v firewall-cmd &>/dev/null; then
    sudo firewall-cmd --permanent --add-port=21115-21119/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --add-port=21116/udp 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
fi

echo "[*] Verifying..."
sudo systemctl status rustdesk --no-pager

echo ""
echo "=== DONE ==="
echo "Launch 'rustdesk' from your desktop to get your ID and password."
echo "The service runs 24/7 and auto-starts on boot."
