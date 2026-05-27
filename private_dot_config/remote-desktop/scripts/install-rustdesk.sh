#!/bin/bash
# Universal RustDesk installer — detects distro and runs the right script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            rocky|rhel|centos|almalinux)
                echo "rocky" ;;
            arch|manjaro|endeavouros)
                echo "arch" ;;
            ubuntu|debian|linuxmint|pop)
                echo "ubuntu" ;;
            fedora)
                echo "fedora" ;;
            *)
                case "$ID_LIKE" in
                    *rhel*|*centos*|*fedora*)  echo "rocky" ;;
                    *arch*)                     echo "arch" ;;
                    *debian*|*ubuntu*)          echo "ubuntu" ;;
                    *)                          echo "unknown" ;;
                esac
                ;;
        esac
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

echo "Detected distro family: ${DISTRO}"

case "$DISTRO" in
    rocky)   bash "$SCRIPT_DIR/install-rustdesk-rocky.sh" ;;
    arch)    bash "$SCRIPT_DIR/install-rustdesk-arch.sh" ;;
    ubuntu)  bash "$SCRIPT_DIR/install-rustdesk-ubuntu.sh" ;;
    fedora)  bash "$SCRIPT_DIR/install-rustdesk-fedora.sh" ;;
    *)
        echo "[!] Unsupported distro. Supported: Rocky/RHEL/CentOS, Arch, Ubuntu/Debian, Fedora"
        echo "    Set DISTRO manually: DISTRO=arch bash $0"
        exit 1
        ;;
esac
