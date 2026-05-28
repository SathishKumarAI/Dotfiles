# Remote Desktop Project — Task Board

## Project Overview
- **Goal**: Reliable, 24/7 GUI remote desktop access across all Linux machines
- **Tool**: RustDesk (open-source Chrome Remote Desktop alternative)
- **Primary Host**: Rocky Linux 10.1 (GNOME/Wayland) @ 192.168.1.157
- **Primary Client**: Arch Linux
- **Started**: 2026-05-26
- **Repo**: [SathishKumarAI/Dotfiles](https://github.com/SathishKumarAI/Dotfiles)

---

## Phase 1: Foundation (COMPLETED)

Initial setup — scripts, docs, and infrastructure.

- [x] Research remote desktop options for Rocky Linux 10 (Wayland/GNOME)
- [x] Evaluate Chrome Remote Desktop — determined unavailable for RPM distros (no .rpm, 404 on download)
- [x] Evaluate alternatives: RustDesk vs Tailscale+VNC vs Apache Guacamole
- [x] Select RustDesk 1.4.6 as primary tool
- [x] Download RustDesk 1.4.6 RPM and verify package integrity
- [x] Create install script for Rocky Linux / RHEL / CentOS (`install-rustdesk-rocky.sh`)
- [x] Create install script for Arch Linux / Manjaro (`install-rustdesk-arch.sh`)
- [x] Create install script for Ubuntu / Debian / Mint (`install-rustdesk-ubuntu.sh`)
- [x] Create install script for Fedora (`install-rustdesk-fedora.sh`)
- [x] Create universal auto-detect installer (`install-rustdesk.sh`)
- [x] Create client connection helper script (`connect-rustdesk.sh`)
- [x] Create uninstall script for all distros (`uninstall-rustdesk.sh`)
- [x] Configure systemd service: `enable`, `Restart=always`, `RestartSec=5`
- [x] Add firewall rules for ports 21115-21119/tcp, 21116/udp
- [x] Write README with quick start, architecture diagram, and comparison table
- [x] Write detailed setup guide with per-distro walkthroughs
- [x] Write connection guide for all platforms (Linux, Windows, macOS, Android, iOS)
- [x] Create directory structure in chezmoi dotfiles
- [x] Write task log and setup log
- [x] Initial push to GitHub (SathishKumarAI/Dotfiles)
- [x] Enhance all documentation with detailed guides and future roadmap
- [x] Push enhanced docs to GitHub

---

## Phase 2: Deployment (IN PROGRESS)

Actually installing and testing on real machines.

- [ ] **Run installer on Rocky Linux host**: `bash scripts/install-rustdesk-rocky.sh`
- [ ] **Verify systemd service**: `systemctl status rustdesk` → active (running)
- [ ] **Launch RustDesk GUI** and note the 9-digit Host ID
- [ ] **Set permanent password** (3 dots → "Set permanent password")
- [ ] **Test local access**: connect from another machine on the same LAN
- [ ] **Install RustDesk on Arch Linux client**: `yay -S rustdesk-bin`
- [ ] **Test Arch → Rocky connection** via relay (different network simulation)
- [ ] **Test Arch → Rocky connection** via direct IP (same LAN)
- [ ] **Test file transfer** between Arch and Rocky
- [ ] **Test clipboard sharing** between machines
- [ ] **Test connection persistence**: leave connected for 1+ hours, verify stability
- [ ] **Test reboot recovery**: reboot Rocky host, verify RustDesk auto-starts
- [ ] **Test crash recovery**: `sudo systemctl kill rustdesk`, verify auto-restart
- [ ] **Test Wayland screen sharing**: verify PipeWire portal works
- [ ] **Verify from mobile**: test Android/iOS connection
- [ ] **Document Host ID** in a safe place (not in the repo — it's a secret)

---

## Phase 3: Hardening (PLANNED)

Security and reliability improvements.

- [ ] **Whitelist trusted device IDs** in RustDesk security settings
- [ ] **Enable connection confirmation** for incoming connections
- [ ] **Enable lock-screen-on-disconnect** for security
- [ ] **Configure SELinux policy** if RustDesk gets blocked
- [ ] **Set up Wayland portal packages** (`xdg-desktop-portal`, `xdg-desktop-portal-gnome`)
- [ ] **Test headless access** — connect when no one is logged into the desktop
- [ ] **Configure auto-login** (if headless access needed)
- [ ] **Add RustDesk to fail2ban** or equivalent for brute-force protection
- [ ] **Audit firewall rules** — ensure only necessary ports are open
- [ ] **Set up log rotation** for RustDesk journal entries

---

## Phase 4: Multi-Machine (FUTURE)

Scale to all machines in the fleet.

- [ ] **Deploy on Arch Linux desktop** as both host and client
- [ ] **Deploy on Ubuntu/Debian server** (if applicable)
- [ ] **Deploy on Fedora workstation** (if applicable)
- [ ] **Create machine inventory**: document all Host IDs, IPs, and purposes
- [ ] **Set up address book** in RustDesk with all machines
- [ ] **Test cross-distro connections**: Arch↔Rocky, Ubuntu↔Arch, etc.
- [ ] **Create chezmoi template** for per-machine RustDesk config
- [ ] **Automate deployment** via chezmoi apply hooks

---

## Phase 5: Self-Hosted Relay (FUTURE)

Maximum privacy and control by running your own relay server.

- [ ] **Research self-hosted relay**: RustDesk hbbs (ID server) + hbbr (relay server)
- [ ] **Choose hosting**: VPS, home server, or Docker container
- [ ] **Deploy hbbs + hbbr** on a server
- [ ] **Configure DNS** for relay domain
- [ ] **Update all clients** to point to self-hosted relay
- [ ] **Write deploy script** for relay server (`deploy-relay.sh`)
- [ ] **Set up relay monitoring** (uptime, connection count)
- [ ] **Set up relay TLS** for secure signaling
- [ ] **Document relay architecture** and failover plan
- [ ] **Benchmark relay vs public relay** latency

---

## Phase 6: Monitoring and Automation (FUTURE)

Operational visibility and hands-off management.

- [ ] **Wake-on-LAN integration**: remotely power on machines before connecting
- [ ] **Write WoL script** (`wake-machine.sh <MAC_ADDRESS>`)
- [ ] **Set up connection health monitoring** — script to check if RustDesk is reachable
- [ ] **Create systemd timer** for periodic health checks
- [ ] **Set up alerts** (email/Slack/ntfy) when host goes offline
- [ ] **Automate RustDesk updates** — script to check GitHub releases and upgrade
- [ ] **Backup RustDesk config** across machines via chezmoi
- [ ] **Create dashboard** (simple HTML or Grafana) showing all machine statuses
- [ ] **Log connection history** for audit trail

---

## Phase 7: Advanced Features (FUTURE)

Nice-to-have improvements.

- [ ] **Set up RustDesk web client** via self-hosted relay (browser access from anywhere)
- [ ] **Tailscale integration**: use Tailscale as transport layer for zero-trust networking
- [ ] **Multi-monitor optimization**: test and document multi-monitor workflows
- [ ] **Custom key bindings**: configure keyboard shortcuts for remote sessions
- [ ] **Session recording**: enable session recording for security audit
- [ ] **Two-factor authentication**: add 2FA to RustDesk connections (if supported)
- [ ] **Group management**: organize machines into groups (home, work, servers)
- [ ] **iOS Shortcuts / Android automation**: one-tap connect to frequent machines
- [ ] **VNC/RDP fallback**: configure xrdp/tigervnc as backup if RustDesk has issues
- [ ] **Performance benchmarks**: document latency/bandwidth for each connection type

---

## Ideas Backlog

Unplanned ideas to revisit later:

- [ ] Compare RustDesk vs Sunshine/Moonlight for game streaming use case
- [ ] Explore Apache Guacamole as a web-only gateway alongside RustDesk
- [ ] Investigate RustDesk API for automation/scripting
- [ ] Create Ansible playbook for fleet-wide RustDesk deployment
- [ ] Write NixOS module for RustDesk (if switching to NixOS)
- [ ] Contribute to RustDesk — upstream fixes for Rocky/RHEL if needed
- [ ] Evaluate RustDesk Pro (commercial) features vs open-source
- [ ] Explore GPU passthrough for remote CUDA/ML workloads
- [ ] Set up remote development: VS Code Remote + RustDesk for GUI debugging
