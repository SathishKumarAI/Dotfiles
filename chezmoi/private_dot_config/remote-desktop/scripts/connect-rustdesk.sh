#!/bin/bash
# Connect to a remote RustDesk host
# Usage: ./connect-rustdesk.sh <RUSTDESK_ID>
set -euo pipefail

if ! command -v rustdesk &>/dev/null; then
    echo "[!] RustDesk is not installed."
    echo "    Run install-rustdesk.sh first, or on Arch: yay -S rustdesk-bin"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: $0 <RUSTDESK_ID>"
    echo ""
    echo "  RUSTDESK_ID  The 9-digit ID shown in the RustDesk window on the host machine"
    echo ""
    echo "Example: $0 123456789"
    exit 1
fi

RUSTDESK_ID="$1"
echo "[*] Connecting to RustDesk host: ${RUSTDESK_ID}..."
rustdesk --connect "$RUSTDESK_ID"
