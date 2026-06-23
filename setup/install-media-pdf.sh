#!/usr/bin/env bash
# Install media + PDF + iPhone-photo support on Rocky Linux 10.
# Safe to re-run (idempotent). Needs sudo for the dnf parts.
#
#   Run:  bash setup/install-media-pdf.sh
#
# What you get
#   Video/Audio   mp4, mkv, mov, mp3, aac, flac ... full codec support
#                 VLC (Flatpak) + mpv + system ffmpeg codecs
#   iPhone        - Photos over USB: GNOME Files auto-mounts the phone
#                   (gvfs-afc + libimobiledevice + usbmuxd + ifuse)
#                 - HEIC/HEIF thumbnails + open in image viewer (heif loaders)
#                 - heif-convert CLI to batch-convert .heic -> .jpg
#   PDF           Read:   Papers/Evince (GNOME) + Okular
#                 Edit:   Xournal++ (annotate/sign), PDF Arranger (merge/split/
#                         reorder/rotate), LibreOffice Draw (full edit)
#                 CLI:    poppler-utils (pdftotext/pdfimages), qpdf
#
# Strategy: system codecs + phone/HEIC plumbing via dnf (EPEL + RPM Fusion);
# the heavy GUI apps via Flatpak/Flathub (current versions, sandboxed, no repo
# churn on RHEL). Flathub is already configured on this machine.
set -uo pipefail

log()  { printf '\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!!  %s\033[0m\n' "$*"; }

if ! command -v dnf >/dev/null; then
    warn "This script targets Rocky/RHEL (dnf). Aborting."
    exit 1
fi

# ---------------------------------------------------------------------------
# 1. Repos: EPEL + CRB + RPM Fusion (free) — needed for codecs/HEIC/iPhone libs
# ---------------------------------------------------------------------------
log "Enabling EPEL + CRB repos"
sudo dnf install -y epel-release || warn "epel-release may already be present"
sudo dnf config-manager --set-enabled crb 2>/dev/null \
  || sudo /usr/bin/crb enable 2>/dev/null || true

if ! dnf repolist 2>/dev/null | grep -qi rpmfusion-free; then
    log "Enabling RPM Fusion (free) for el10"
    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-10.noarch.rpm" \
      || warn "RPM Fusion install failed — codecs/VLC-dnf may be unavailable; Flatpak VLC still covers playback"
fi

# ---------------------------------------------------------------------------
# 2. System codecs (mp4/mp3/...) + mpv
# ---------------------------------------------------------------------------
log "Installing ffmpeg codecs + mpv"
sudo dnf install -y ffmpeg ffmpeg-libs mpv \
  || sudo dnf install -y ffmpeg-free mpv \
  || warn "codec/mpv install partial — check RPM Fusion is enabled"

# GStreamer plugins so GNOME apps (Files preview, Videos) decode mp4/mp3 too
sudo dnf install -y \
    gstreamer1-plugins-good gstreamer1-plugins-bad-free \
    gstreamer1-plugins-ugly-free gstreamer1-libav 2>/dev/null \
  || warn "some gstreamer plugins skipped (need RPM Fusion for -ugly/libav)"

# ---------------------------------------------------------------------------
# 3. iPhone over USB: auto-mount in Files + HEIC photo support
# ---------------------------------------------------------------------------
log "Installing iPhone USB mount + HEIC support"
sudo dnf install -y \
    usbmuxd libimobiledevice libimobiledevice-utils ifuse gvfs-afc \
  || warn "iPhone USB stack partial"
sudo systemctl enable --now usbmuxd 2>/dev/null || true

# HEIC/HEIF: decode lib + gdk-pixbuf loader (thumbnails/viewer) + CLI converter
sudo dnf install -y libheif libheif-tools heif-pixbuf-loader \
  || warn "HEIC support partial — thumbnails may not render"

# ---------------------------------------------------------------------------
# 4. PDF read/edit (system pieces)
# ---------------------------------------------------------------------------
log "Installing PDF readers + CLI tools"
# Papers is GNOME 49's reader (replaces Evince); fall back to evince/okular.
sudo dnf install -y papers || sudo dnf install -y evince || true
sudo dnf install -y okular poppler-utils qpdf || warn "some PDF tools skipped"

# LibreOffice Draw = full PDF editing (import PDF, edit text/images, re-export)
if ! command -v libreoffice >/dev/null; then
    sudo dnf install -y libreoffice-draw || warn "libreoffice-draw skipped"
fi

# ---------------------------------------------------------------------------
# 5. GUI apps via Flatpak (current versions, sandboxed)
# ---------------------------------------------------------------------------
if command -v flatpak >/dev/null; then
    log "Installing GUI apps from Flathub"
    flatpak remote-add --user --if-not-exists flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    # --user avoids the "remote exists in system AND user" prompt and needs no sudo
    for app in \
        org.videolan.VLC \
        com.github.xournalpp.xournalpp \
        com.github.jeromerobert.pdfarranger ; do
        flatpak install -y --user --noninteractive flathub "$app" \
          || warn "flatpak install failed: $app"
    done
else
    warn "flatpak missing — VLC/Xournal++/PDF Arranger not installed. Install flatpak then re-run."
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo
log "Done. Summary:"
cat <<'EOF'
  Video/Audio   VLC (flatpak run org.videolan.VLC) + mpv + system codecs
  iPhone        Plug in over USB -> unlock -> tap "Trust" -> phone shows in
                Files (Nautilus) sidebar. Drag photos off. HEIC opens in viewer.
                Batch convert: heif-convert photo.heic photo.jpg
  PDF read      Papers/Evince, Okular
  PDF edit      Xournal++ (annotate/sign), PDF Arranger (merge/split/reorder),
                LibreOffice Draw (full text/image edit)

  Tip: if a Flatpak app isn't in the GNOME grid yet, log out/in once.
EOF
