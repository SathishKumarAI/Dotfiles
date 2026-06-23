#!/usr/bin/env bash
# install-tiling.sh — niri-style scrollable tiling + a better app switcher for
# GNOME Shell on Wayland (Rocky Linux 10, GNOME 49). Run as your normal user:
#
#   bash setup/install-tiling.sh
#
# Installs (no sudo — straight into ~/.local/share/gnome-shell/extensions):
#   PaperWM  — niri-like scrollable tiling: windows live in horizontally
#              scrollable columns instead of fixed tiles.
#   AATWS    — Advanced Alt-Tab Window Switcher: type-to-search app/window
#              switching, far better than GNOME's default Alt+Tab.
#
# Neither ships in dnf, so we pull the GNOME-Shell-version-matched build straight
# from extensions.gnome.org. Idempotent: re-running skips anything present.
# On Wayland the shell can't hot-reload — LOG OUT and back in to activate.
set -euo pipefail

EXTS=(
    "paperwm@paperwm.github.com"            # niri-like scrollable tiling
    "advanced-alt-tab@G-dH.github.com"      # AATWS — better app switcher
)

API="https://extensions.gnome.org"
SHELL_VER="$(gnome-shell --version | grep -oP '[0-9]+' | head -1)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "==> GNOME Shell $SHELL_VER — installing ${#EXTS[@]} extensions from EGO"

install_ext() {
    local uuid="$1" info dl
    if gnome-extensions list 2>/dev/null | grep -qx "$uuid"; then
        echo "    = $uuid already installed"
    else
        info="$(curl -fsSL --max-time 15 "$API/extension-info/?uuid=$uuid&shell_version=$SHELL_VER")" \
            || { echo "    ! $uuid: no build for GNOME $SHELL_VER — skipped"; return 0; }
        dl="$(printf '%s' "$info" | grep -oP '"download_url":\s*"\K[^"]+')"
        [ -n "$dl" ] || { echo "    ! $uuid: no download_url in API response — skipped"; return 0; }
        echo "    v downloading $uuid"
        curl -fsSL --max-time 60 -o "$tmp/$uuid.zip" "$API$dl"
        gnome-extensions install --force "$tmp/$uuid.zip"
    fi
    if gnome-extensions enable "$uuid" 2>/dev/null; then
        echo "    + enabled $uuid"
    else
        echo "    . $uuid installed; enables after next login (Wayland)"
    fi
}

for u in "${EXTS[@]}"; do install_ext "$u"; done

# PaperWM's scrollable layout can fight edge-tiling from Tiling Assistant (both
# want to place windows). Left enabled here; disable it if windows jump around:
if gnome-extensions list 2>/dev/null | grep -qx "tiling-assistant@leleat-on-github"; then
    echo
    echo "note: Tiling Assistant is enabled. If it conflicts with PaperWM, run:"
    echo "      gnome-extensions disable tiling-assistant@leleat-on-github"
fi

cat <<'EOF'

==> Done. On Wayland you must LOG OUT and back in to load new extensions.

After re-login:
  PaperWM (scrollable tiling, niri-like)
    Super+Left / Right        focus column left / right (scroll the strip)
    Super+Up / Down           focus window within a column
    Super+Shift+Left/Right    move the focused window between columns
    Super+Return              new window in the current column
    Configure: gnome-extensions prefs paperwm@paperwm.github.com

  AATWS (app switcher)
    Alt+Tab                   switch windows; just start typing to filter
    Super+Tab                 switch apps
    Configure: gnome-extensions prefs advanced-alt-tab@G-dH.github.com
EOF
