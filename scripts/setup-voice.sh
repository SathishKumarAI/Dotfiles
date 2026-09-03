#!/usr/bin/env bash
# Finish voice dictation: type-at-cursor speech-to-text on GNOME Wayland.
# Already done (by Claude, no sudo): vosk venv, VOSK model, nerd-dictation clone, ~/.local/bin/voice-toggle.
# This installs the OS pieces that need sudo, then sets the GNOME hotkey (as your user).
#
# RUN AS YOUR USER (NOT sudo):   bash ~/coding/scripts/setup-voice.sh
#   - it calls sudo itself for the elevated parts
#   - gsettings/systemctl --user must run as you, so do NOT prefix with sudo
set -euo pipefail
log(){ printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

sudo -v
( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) & KA=$!
trap 'kill "$KA" 2>/dev/null || true' EXIT

# 1. recorder (nerd-dictation uses parec) + build deps for ydotool
log "1. install deps (parec + build tools)"
sudo dnf install -y pulseaudio-utils gcc-c++ make cmake git scdoc || \
  sudo dnf install -y pulseaudio-utils gcc-c++ make cmake git   # scdoc optional

# 2. build + install ydotool (not packaged for Rocky 10)
log "2. build ydotool from source"
if command -v ydotool >/dev/null && command -v ydotoold >/dev/null; then
  echo "ydotool already installed: $(ydotool --version 2>&1 | head -1)"
else
  SRC=/tmp/ydotool-build
  rm -rf "$SRC"; git clone --depth 1 https://github.com/ReimuNotMoe/ydotool "$SRC"
  cmake -S "$SRC" -B "$SRC/build" -DCMAKE_BUILD_TYPE=Release
  make -C "$SRC/build" -j"$(nproc)"
  sudo make -C "$SRC/build" install
  sudo ldconfig
  echo "installed: $(command -v ydotool)"
fi

# 3. uinput permission (so ydotoold runs as your user, no root daemon)
log "3. uinput udev rule + input group"
echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' | \
  sudo tee /etc/udev/rules.d/60-ydotool.rules >/dev/null
sudo udevadm control --reload-rules && sudo udevadm trigger /dev/uinput || true
sudo usermod -aG input "$USER"    # takes effect next login; newgrp used below for this session

# 4. ydotoold as a user service
log "4. ydotoold user service"
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/ydotoold.service" <<EOF
[Unit]
Description=ydotool daemon (virtual input for Wayland)
[Service]
ExecStart=/usr/local/bin/ydotoold -p %t/.ydotool_socket -P 0660
Restart=always
[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now ydotoold || echo "start ydotoold after next login (input group)"

# 5. persist YDOTOOL_SOCKET for interactive shells
log "5. env"
LINE='export YDOTOOL_SOCKET="/run/user/$(id -u)/.ydotool_socket"'
grep -qF "YDOTOOL_SOCKET" "$HOME/.bashrc" || echo "$LINE" >> "$HOME/.bashrc"

# 6. GNOME hotkey: Super+backslash -> voice-toggle (runs as your user = has D-Bus)
log "6. GNOME hotkey (Super + \\)"
B="org.gnome.settings-daemon.plugins.media-keys"
P="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/voice-dictation/"
cur=$(gsettings get $B custom-keybindings)
if ! echo "$cur" | grep -q voice-dictation; then
  if echo "$cur" | grep -q "@as \[\]"; then nu="['$P']"; else nu=$(echo "$cur" | sed "s/]$/, '$P']/"); fi
  gsettings set $B custom-keybindings "$nu"
fi
gsettings set "$B.custom-keybinding:$P" name 'Voice Dictation Toggle'
gsettings set "$B.custom-keybinding:$P" command "$HOME/.local/bin/voice-toggle"
gsettings set "$B.custom-keybinding:$P" binding '<Super>backslash'

log "DONE"
cat <<EOF
Voice ready. If ydotoold didn't start (input group is new this session):
    LOG OUT and back in once, then:  systemctl --user start ydotoold
Test:  press  Super + \\  , speak, press again to stop. Text types at cursor.
Manual test without hotkey:  ~/.local/bin/voice-toggle   (run twice: start / stop)
EOF
