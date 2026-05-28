#!/usr/bin/env bash
# Install wofi (Wayland-native app launcher) on Rocky Linux 10.
#
# Neither wofi nor its gtk-layer-shell dependency are packaged for Rocky 10,
# so both are built from source. Sources are cloned into a temp dir that is
# removed on exit — nothing is left lying around in your home directory.
#
# Run with: bash install-wofi.sh
set -euo pipefail

PREFIX="/usr/local"
BUILD_DIR="$(mktemp -d)"
trap 'rm -rf "$BUILD_DIR"' EXIT

echo "=== Step 1: Install build dependencies ==="
sudo dnf install -y \
    gtk3-devel \
    wayland-devel \
    wayland-protocols-devel \
    meson \
    ninja-build \
    gcc \
    gobject-introspection-devel \
    vala \
    pkg-config \
    git

echo ""
echo "=== Step 2: Build gtk-layer-shell (wofi dependency) ==="
cd "$BUILD_DIR"
git clone --depth 1 https://github.com/wmww/gtk-layer-shell.git
cd gtk-layer-shell
meson setup build \
    --prefix="$PREFIX" \
    -Dexamples=false \
    -Ddocs=false \
    -Dtests=false
ninja -C build
sudo ninja -C build install

echo ""
echo "=== Step 3: Build wofi ==="
cd "$BUILD_DIR"
git clone --depth 1 https://github.com/jgmdev/wofi.git
cd wofi
export PKG_CONFIG_PATH="${PREFIX}/lib64/pkgconfig:${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
meson setup build --prefix="$PREFIX"
ninja -C build
sudo ninja -C build install

# Make the freshly installed shared library discoverable.
sudo ldconfig

echo ""
echo "=== Step 4: Verify installation ==="
"${PREFIX}/bin/wofi" --version

echo ""
echo "=== Done! ==="
echo "wofi installed to ${PREFIX}/bin/wofi"
echo ""
echo "Config lives in ~/.config/wofi/ (config + style.css, applied via chezmoi)."
echo ""
echo "Next steps:"
echo "  1. Test it:  wofi --show drun"
echo "  2. Bind a key: bash setup-wofi-keybind.sh"
