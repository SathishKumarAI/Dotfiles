#!/bin/bash
# Uninstall RustDesk and clean up service config
set -euo pipefail

echo "[*] Stopping and disabling RustDesk service..."
sudo systemctl stop rustdesk 2>/dev/null || true
sudo systemctl disable rustdesk 2>/dev/null || true
sudo rm -rf /etc/systemd/system/rustdesk.service.d
sudo systemctl daemon-reload

echo "[*] Removing RustDesk package..."
if command -v dnf &>/dev/null; then
    sudo dnf remove -y rustdesk 2>/dev/null || true
elif command -v apt-get &>/dev/null; then
    sudo apt-get remove -y rustdesk 2>/dev/null || true
elif command -v pacman &>/dev/null; then
    sudo pacman -Rns --noconfirm rustdesk-bin 2>/dev/null || true
fi

echo "[*] Cleaning up config..."
rm -rf ~/.config/rustdesk 2>/dev/null || true

echo "=== RustDesk uninstalled ==="
