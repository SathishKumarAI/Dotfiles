#!/bin/bash
# Install WezTerm on Rocky Linux 10
# Run with: bash install-wezterm.sh

set -euo pipefail

echo "=== Installing WezTerm via Flatpak ==="
flatpak install -y flathub org.wezfurlong.wezterm

echo ""
echo "=== Creating wrapper script ==="
# Flatpak WezTerm needs a wrapper so it can read ~/.wezterm.lua
mkdir -p ~/.local/bin

cat > ~/.local/bin/wezterm << 'WRAPPER'
#!/bin/bash
exec flatpak run org.wezfurlong.wezterm "$@"
WRAPPER
chmod +x ~/.local/bin/wezterm

echo ""
echo "=== Setting WezTerm as default terminal ==="
gsettings set org.gnome.desktop.default-applications.terminal exec 'wezterm'
gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''

echo ""
echo "=== Verifying ==="
flatpak info org.wezfurlong.wezterm | head -5

echo ""
echo "=== Done! ==="
echo "Launch with: wezterm"
echo "Or find 'WezTerm' in your app launcher"
echo ""
echo "Key shortcuts (see ~/.wezterm.lua):"
echo "  Ctrl+Shift+D     Split pane horizontal"
echo "  Ctrl+Shift+E     Split pane vertical"
echo "  Ctrl+Shift+HJKL  Navigate panes (vim-style)"
echo "  Ctrl+Shift+T     New tab"
echo "  Ctrl+Shift+Z     Toggle zoom pane"
echo "  Ctrl+Shift+P     Launch menu (bash/zellij/python)"
echo "  Ctrl+Tab         Next tab"
echo "  Ctrl+Shift+Space Fuzzy switcher (apps/tabs/workspaces/commands)"
echo ""
echo "Power-user (Leader = Ctrl+a, then key):"
echo "  Ctrl+a |   -   Split horizontal / vertical"
echo "  Ctrl+a r       Resize mode (then hjkl, Esc to exit)"
echo "  Ctrl+a w / n   Switch / create workspace"
echo "  Ctrl+a Tab     Next workspace"
echo "  Ctrl+a p       Visual pane picker"
echo "  Ctrl+a [ / Spc Copy mode / quick-select"
echo "  Ctrl+a b       Toggle tab bar"
echo ""
echo "Window: Super+Left/Right snap half, Super+Up max, Super+Down restore,"
echo "        Super+Enter / F11 fullscreen, Ctrl+a c center"
