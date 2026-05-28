#!/usr/bin/env bash
# Remove wofi and gtk-layer-shell installed under /usr/local by install-wofi.sh.
# Run with: bash uninstall-wofi.sh
set -euo pipefail

PREFIX="/usr/local"

echo "=== Removing wofi ==="
sudo rm -f "${PREFIX}/bin/wofi"

echo "=== Removing gtk-layer-shell ==="
# Library, headers, vapi, gir, typelib and pkg-config files.
sudo rm -f  "${PREFIX}"/lib64/libgtk-layer-shell* "${PREFIX}"/lib/libgtk-layer-shell*
sudo rm -rf "${PREFIX}"/include/gtk-layer-shell*
sudo rm -f  "${PREFIX}"/lib64/pkgconfig/gtk-layer-shell-0.pc "${PREFIX}"/lib/pkgconfig/gtk-layer-shell-0.pc
sudo rm -f  "${PREFIX}"/share/vala/vapi/gtk-layer-shell-0.* 2>/dev/null || true
sudo rm -f  "${PREFIX}"/share/gir-1.0/GtkLayerShell-0.1.gir 2>/dev/null || true
sudo rm -f  "${PREFIX}"/lib64/girepository-1.0/GtkLayerShell-0.1.typelib "${PREFIX}"/lib/girepository-1.0/GtkLayerShell-0.1.typelib 2>/dev/null || true

sudo ldconfig

echo ""
echo "=== Done ==="
echo "wofi and gtk-layer-shell removed from ${PREFIX}."
echo "Config in ~/.config/wofi/ was left in place. Remove it manually if you want."
echo "To drop the Super+Space keybind, clear it in GNOME Settings > Keyboard > Custom Shortcuts."
