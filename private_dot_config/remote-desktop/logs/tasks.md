# Remote Desktop Setup — Task Log

## Completed

- [x] Research remote desktop options for Rocky Linux 10 (Wayland/GNOME)
- [x] Determine Chrome Remote Desktop unavailable for RPM distros (no official RPM, 404 on download)
- [x] Select RustDesk as alternative (open-source, cross-platform, no port forwarding)
- [x] Download RustDesk 1.4.6 RPM to /tmp/rustdesk.rpm
- [x] Create setup script for Rocky Linux host (install-rustdesk-rocky.sh)
- [x] Create setup script for Arch Linux (install-rustdesk-arch.sh)
- [x] Create setup script for Ubuntu/Debian (install-rustdesk-ubuntu.sh)
- [x] Create setup script for Fedora (install-rustdesk-fedora.sh)
- [x] Create universal auto-detect installer (install-rustdesk.sh)
- [x] Create client connection helper script (connect-rustdesk.sh)
- [x] Create uninstall script (uninstall-rustdesk.sh)
- [x] Write README with quick start guide
- [x] Write detailed setup guide (docs/setup-guide.md)
- [x] Write connection guide for all platforms (docs/connection-guide.md)
- [x] Create directory structure in chezmoi dotfiles
- [x] Push to GitHub dotfiles repo

## Pending (User Action Required)

- [ ] Run `sudo bash ~/.config/remote-desktop/scripts/install-rustdesk-rocky.sh` on this Rocky Linux host
- [ ] Launch RustDesk GUI and note the ID + set permanent password
- [ ] Install RustDesk on Arch Linux client device
- [ ] Test connection from Arch → Rocky
