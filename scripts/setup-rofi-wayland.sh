#!/bin/bash
# Setup script for rofi-wayland on Rocky Linux 10
# Run with: bash setup-rofi-wayland.sh

set -euo pipefail

echo "=== Step 1: Install build dependencies ==="
sudo dnf install -y \
    meson ninja-build cmake gcc gcc-c++ pkg-config \
    cairo-devel pango-devel glib2-devel \
    wayland-devel wayland-protocols-devel \
    libxkbcommon-devel libxcb-devel xcb-util-devel \
    xcb-util-wm-devel xcb-util-cursor-devel \
    startup-notification-devel \
    flex bison check-devel \
    gdk-pixbuf2-devel librsvg2-devel \
    xcb-util-keysyms-devel \
    libdrm-devel

echo ""
echo "=== Step 2: Clone rofi-wayland ==="
BUILD_DIR="$HOME/coding/rofi-wayland-build"
if [ -d "$BUILD_DIR" ]; then
    echo "Build directory exists, pulling latest..."
    cd "$BUILD_DIR"
    git pull
else
    git clone https://github.com/lbonn/rofi.git "$BUILD_DIR"
    cd "$BUILD_DIR"
fi

git submodule update --init

echo ""
echo "=== Step 3: Build rofi-wayland ==="
meson setup build --prefix=/usr/local -Dwayland=enabled -Dxcb=disabled
ninja -C build

echo ""
echo "=== Step 4: Install ==="
sudo ninja -C build install

echo ""
echo "=== Step 5: Verify installation ==="
echo "Installed rofi version:"
/usr/local/bin/rofi -version

echo ""
echo "=== Done! ==="
echo "rofi-wayland installed to /usr/local/bin/rofi"
echo ""
echo "Next steps:"
echo "  1. Test it:  rofi -show drun -show-icons"
echo "  2. A keyboard shortcut will be set up by the config script"
