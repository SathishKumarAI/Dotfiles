#!/bin/bash
#==============================================================================
# GNOME Desktop UI/UX Setup — Catppuccin Mocha + Nerd Fonts + Keybindings
# Run as your normal user (NOT root): bash gnome-desktop-setup.sh
#==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[  OK]${NC} $1"; }

log_info "Setting up GNOME desktop..."

#--- Nerd Fonts ---
log_info "Installing JetBrainsMono + FiraCode Nerd Fonts..."
mkdir -p "$HOME/.local/share/fonts"
curl -Lo /tmp/jetbrains.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
curl -Lo /tmp/firacode.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip"
unzip -o /tmp/jetbrains.zip -d "$HOME/.local/share/fonts/JetBrainsMono/"
unzip -o /tmp/firacode.zip -d "$HOME/.local/share/fonts/FiraCode/"
fc-cache -fv "$HOME/.local/share/fonts/"
log_success "Nerd Fonts installed"

#--- Catppuccin GTK Theme ---
log_info "Installing Catppuccin Mocha GTK theme..."
mkdir -p "$HOME/.themes"
curl -Lo /tmp/catppuccin-gtk.zip "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-blue-standard+default.zip"
unzip -o /tmp/catppuccin-gtk.zip -d "$HOME/.themes/"
log_success "Catppuccin GTK theme installed"

#--- Catppuccin Cursors ---
log_info "Installing Catppuccin Mocha cursors..."
mkdir -p "$HOME/.local/share/icons"
curl -Lo /tmp/catppuccin-cursors.zip "https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-dark-cursors.zip"
unzip -o /tmp/catppuccin-cursors.zip -d "$HOME/.local/share/icons/"
log_success "Cursors installed"

#--- Papirus Icons ---
log_info "Installing Papirus Dark icons..."
curl -Lo /tmp/papirus-install.sh "https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh"
DESTDIR="$HOME/.local/share/icons" bash /tmp/papirus-install.sh
log_success "Papirus icons installed"

#--- GNOME Settings ---
log_info "Applying GNOME settings..."

# Theme
gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-blue-standard+default'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-dark-cursors'
gsettings set org.gnome.desktop.interface cursor-size 24

# Fonts
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Cantarell Bold 11'

# Clock
gsettings set org.gnome.desktop.interface clock-show-weekday true
gsettings set org.gnome.desktop.interface clock-format '12h'

# Touchpad
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true

# Windows
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.mutter center-new-windows true

#--- Keyboard Shortcuts ---
log_info "Setting keyboard shortcuts..."

# Window management
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "['<Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings minimize "['<Super>Down']"
gsettings set org.gnome.desktop.wm.keybindings close "['<Super>q']"

# Workspaces
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "['<Super>bracketleft']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>bracketright']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Shift><Super>bracketleft']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Shift><Super>bracketright']"

# App launchers
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings \
  "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', \
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', \
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', \
    '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']"

for i in name command binding; do
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Terminal'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'ptyxis'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>t'

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Files'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'nautilus'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Super>e'

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Browser'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'brave-browser'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Super>b'

  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name 'VS Code'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command 'flatpak run com.visualstudio.code'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding '<Super>c'
  break
done

# Nautilus (Files): large icon view + image thumbnails, Windows-style big tiles.
gsettings set org.gnome.nautilus.icon-view  default-zoom-level   'large'
gsettings set org.gnome.nautilus.preferences default-folder-viewer 'icon-view'
gsettings set org.gnome.nautilus.preferences show-image-thumbnails 'always'

# Power / idle: dim+blank quickly, suspend sooner on battery than on AC.
PW=org.gnome.settings-daemon.plugins.power
gsettings set org.gnome.desktop.session idle-delay 180          # blank screen after 3 min
gsettings set $PW idle-dim true                                  # dim before blanking
gsettings set $PW sleep-inactive-battery-type 'suspend'
gsettings set $PW sleep-inactive-battery-timeout 600             # suspend 10 min on battery
gsettings set $PW sleep-inactive-ac-type 'suspend'
gsettings set $PW sleep-inactive-ac-timeout 1800                 # suspend 30 min on AC
gsettings set $PW power-saver-profile-on-low-battery true        # auto power-save when low

#--- GNOME Extensions ---
log_info "Installing GNOME extensions..."

pip install gnome-extensions-cli 2>/dev/null

EXTENSIONS=(
  "blur-my-shell@aunetx"
  "just-perfection-desktop@just-perfection"
  "appindicatorsupport@rgcjonas.gmail.com"
  "clipboard-indicator@tudmotu.com"
  "Vitals@CoreCoding.com"
  "tiling-assistant@leleat-on-github"
)

for ext in "${EXTENSIONS[@]}"; do
  log_info "  Installing $ext..."
  gext install "$ext" 2>/dev/null || log_warn "  Failed: $ext (install manually from extensions.gnome.org)"
done

log_success "GNOME extensions installed"

#--- Summary ---
echo ""
log_success "Desktop setup complete!"
echo ""
echo "Theme:      Catppuccin Mocha (GTK + cursors + Papirus Dark icons)"
echo "Fonts:      JetBrainsMono + FiraCode Nerd Fonts"
echo ""
echo "Extensions:"
echo "  - Blur my Shell     (blurred panel & overview)"
echo "  - Just Perfection   (fine-tune UI elements)"
echo "  - AppIndicator      (system tray icons)"
echo "  - Clipboard Indicator (clipboard history)"
echo "  - Vitals            (CPU/RAM/temp in top bar)"
echo "  - Tiling Assistant  (quarter tiling & layouts)"
echo ""
echo "Keyboard shortcuts:"
echo "  Super+T  → Terminal"
echo "  Super+E  → Files"
echo "  Super+B  → Browser"
echo "  Super+C  → VS Code"
echo "  Super+Q  → Close window"
echo "  Super+Up → Maximize"
echo "  Super+[  → Previous workspace"
echo "  Super+]  → Next workspace"
echo "  Alt+Tab  → Switch windows"
echo ""
echo "YouTube references:"
echo "  - GNOME 47 on Fedora: https://www.youtube.com/watch?v=bV6qNfxIXkE"
echo "  - Catppuccin GNOME:   https://m.youtube.com/watch?v=TwIz9WNxP5w"
echo "  - Ultimate GNOME 2026: https://www.youtube.com/watch?v=Eox-YemFC1U"
