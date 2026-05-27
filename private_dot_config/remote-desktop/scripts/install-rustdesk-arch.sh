#!/bin/bash
# RustDesk host/client setup for Arch Linux
set -euo pipefail

echo "[*] Installing RustDesk on Arch Linux..."

if pacman -Qi rustdesk-bin &>/dev/null; then
    echo "[!] RustDesk already installed: $(pacman -Q rustdesk-bin)"
    read -rp "Reinstall? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

if ! command -v yay &>/dev/null && ! command -v paru &>/dev/null; then
    echo "[!] No AUR helper found. Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel
    TMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay-bin.git "$TMP_DIR/yay-bin"
    (cd "$TMP_DIR/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$TMP_DIR"
fi

AUR_HELPER="yay"
command -v paru &>/dev/null && AUR_HELPER="paru"

echo "[*] Installing rustdesk-bin from AUR..."
$AUR_HELPER -S --noconfirm rustdesk-bin

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
elif command -v firewall-cmd &>/dev/null; then
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
