# Dotfiles Roadmap

Single aggregated view of every pending and future task across the repo,
with subtasks. Per-feature detail lives in each feature's
`logs/tasks.md`; this file rolls them up so you can see everything at once.

Last refreshed: **2026-06-08**

---

## Status snapshot

| Layer | State |
|-------|-------|
| Git working tree | Clean, in sync with `origin/main` |
| chezmoi source root | Fixed (`.chezmoiroot=chezmoi`); sourceDir points to `~/coding/Dotfiles` |
| Single source of truth | `~/coding/Dotfiles` (orphaned `~/.local/share/chezmoi` still on disk) |
| Wofi launcher | Feature shipped + config staged + key rebound; **binary not yet built** |
| RustDesk remote desktop | Phase 1 (Foundation) done; Phase 2 (Deployment) not yet started |
| Diverged live configs | 3 files: `mise/config.toml`, `starship.toml`, `zellij/config.kdl` |

---

## Action items — pending right now (act on these next)

### A1. Build wofi on this host (sudo)
- [ ] Run `bash ~/coding/Dotfiles/chezmoi/private_dot_config/wofi/scripts/install-wofi.sh`
- [ ] Verify launch: `wofi --show drun`
- [ ] Verify keybind: press `Super+Space` (already rebound to wofi)
- [ ] Tick off the "In Progress" row in [wofi/logs/tasks.md](chezmoi/private_dot_config/wofi/logs/tasks.md)

### A2. Reconcile the 3 diverged configs
Three live files differ from the repo. Decide per-file which side wins.
- [ ] **`~/.config/mise/config.toml`** — `chezmoi diff ~/.config/mise/config.toml`
  - If live wins: `chezmoi add ~/.config/mise/config.toml`, commit, push
  - If repo wins: `chezmoi apply ~/.config/mise/config.toml`
- [ ] **`~/.config/starship.toml`** — same workflow
- [ ] **`~/.config/zellij/config.kdl`** — same workflow

### A3. WORKLOG follow-ups (from 2026-05-27 entry)
- [ ] Run `bash ~/coding/scripts/install-claude-skills.sh` to install the vetted Claude Code skill set
- [ ] Reconcile `~/.claude/settings.json` with chezmoi so the new `Stop` hook is tracked
- [ ] Decide whether to track `~/.claude/skills/document/` and `~/.claude/hooks/worklog-reminder.sh` in chezmoi for cross-machine replication

### A4. Optional cleanup (blocked by deny list — user runs)
- [ ] `rm -rf ~/.local/share/chezmoi` — orphaned second clone (chezmoi now reads `~/coding/Dotfiles`)
- [ ] `rm -rf ~/coding/rofi-wayland-build` — abandoned source clone if retiring rofi-wayland
- [ ] Retire X11 rofi: decide on `setup/setup-rofi-wayland.sh`, `setup/setup-rofi-keybind.sh`, `~/.config/rofi/`
  - Keep rofi-wayland as a fallback launcher, **or**
  - Delete the scripts + drop the rofi feature dir + clear `~/.config/rofi/`

---

## Feature roadmaps

### Wofi — [`chezmoi/private_dot_config/wofi/logs/tasks.md`](chezmoi/private_dot_config/wofi/logs/tasks.md)

- [ ] **Pin wofi/gtk-layer-shell to specific tags** for reproducible builds
  - [ ] Pick a tag from each upstream, update `install-wofi.sh` (`git clone --branch <tag>`)
  - [ ] Record the version in `setup-log.md`
- [ ] **Add extra launcher modes** with their own styles
  - [ ] Window switcher (wlroots compositors) — `wofi --show window`
  - [ ] Clipboard manager (e.g. `cliphist | wofi --dmenu`)
  - [ ] Power menu (lock/logout/reboot/poweroff) wrapper script
  - [ ] Per-mode style overrides under `~/.config/wofi/`
- [ ] **Share the Catppuccin style upstream / cross-launcher**
  - [ ] Adapt the palette for fuzzel, anyrun, walker
  - [ ] Open a PR or theme repo with the wofi CSS

### Remote Desktop (RustDesk) — [`chezmoi/private_dot_config/remote-desktop/logs/tasks.md`](chezmoi/private_dot_config/remote-desktop/logs/tasks.md)

Full Phase 1–7 plan lives in that file. Top-level rollup with subtasks:

- **Phase 2 — Deployment** (16 subtasks)
  - [ ] Install on Rocky host, verify systemd, note Host ID, set permanent password
  - [ ] Install on Arch client; test relay + direct-IP connections
  - [ ] Test file transfer, clipboard sharing, persistence (1h+), reboot recovery, crash recovery
  - [ ] Verify Wayland screen sharing (PipeWire portal) and mobile clients
  - [ ] Stash Host ID outside the repo
- **Phase 3 — Hardening** (10 subtasks)
  - [ ] Whitelist trusted IDs, require connection confirmation, lock on disconnect
  - [ ] SELinux policy, Wayland portal packages, headless access, auto-login
  - [ ] fail2ban for brute-force, firewall audit, log rotation
- **Phase 4 — Multi-machine fleet** (8 subtasks)
  - [ ] Deploy on Arch desktop, Ubuntu, Fedora as applicable
  - [ ] Build a machine inventory + address book; cross-distro connection matrix
  - [ ] chezmoi template for per-machine RustDesk config + apply hooks
- **Phase 5 — Self-hosted relay** (10 subtasks)
  - [ ] Stand up `hbbs` + `hbbr` on a VPS/home server, DNS, TLS
  - [ ] Repoint clients; benchmark vs public relay
  - [ ] Write deploy + monitoring scripts; document failover
- **Phase 6 — Monitoring & automation** (9 subtasks)
  - [ ] Wake-on-LAN, health checks via systemd timer, alerting (email/Slack/ntfy)
  - [ ] Auto-update script, config backup via chezmoi, status dashboard, audit log
- **Phase 7 — Advanced features** (10 subtasks)
  - [ ] Web client, Tailscale transport, multi-monitor, custom shortcuts
  - [ ] Session recording, 2FA, group management
  - [ ] iOS Shortcuts / Android automation, VNC/RDP fallback, perf benchmarks
- **Ideas backlog** (9 items) — Sunshine/Moonlight comparison, Apache Guacamole, RustDesk API, Ansible playbook, NixOS module, upstream contributions, RustDesk Pro eval, GPU passthrough, VS Code Remote pairing

### Rofi (X11 launcher) — `chezmoi/private_dot_config/rofi/`

- [ ] **Decide its future** (see A4 above): keep as X11 fallback, or retire entirely

### Other chezmoi-managed configs (no task lists yet)

- [ ] **mise** — review `chezmoi/private_dot_config/mise/config.toml` divergence (see A2)
- [ ] **starship** — same (see A2)
- [ ] **zellij** — same (see A2)
- [ ] **nvim** — currently a single `init.lua`; consider growing into a structured config (plugins, LSP, formatting)
- [ ] **lazygit** — review keybinds vs your git workflow; document custom commands if any

---

## Cross-cutting / repo-wide future work

- [ ] **CI for the repo**
  - [ ] GitHub Actions: shellcheck on `*.sh`
  - [ ] markdownlint on `*.md`
  - [ ] `chezmoi verify` against a known-good fixture
- [ ] **chezmoi templating** for machine-specific values (hostname, IPs, user)
  - [ ] Introduce `.chezmoi.toml.tmpl` with prompts
  - [ ] Template rustdesk config and any host-specific scripts
- [ ] **Cross-machine replication test**
  - [ ] Reproduce setup on a clean VM (Rocky, Arch, Ubuntu)
  - [ ] Time the from-zero workflow and document gaps
- [ ] **Top-level README index**
  - [ ] Add a "Features" table linking each `chezmoi/private_dot_config/<name>/README.md`
  - [ ] Add a "Status" column wired to the feature task boards
- [ ] **Worklog hygiene** (from CLAUDE.md)
  - [ ] Run `/document` after every meaningful session (Stop hook reminds you)
- [ ] **Secrets handling**
  - [ ] Decide on `pass`, `age` (via chezmoi), or `gopass` for any credentials referenced by scripts

---

## Backlog / ideas to revisit

- [ ] Move `dotfiles/` (legacy starship/zellij/wezterm/windows_setup) into `chezmoi/` or archive it
- [ ] Decide what `vault/` is for; either populate it or remove it
- [ ] Decide what `tools/fetch_env_refs.py` is for; either document it or remove it
- [ ] Rename `md files/` directory to remove the space (annoying in shells)
- [ ] Audit `setup/*.md` (APPS_GUIDE, CLAUDE_TOOLS_GUIDE, FULL_TOOLS_INVENTORY, OPEN_SOURCE_TOOLS, SCRIPT_EXPLAINED, TOOLS_GUIDE) for staleness vs current setup
- [ ] Consolidate the two `chezmoi-migration.sh`-style setup scripts (`rocky-dev-setup.sh`, `rocky-dev-setup-custom.sh`) into a single canonical script
- [ ] Add a wezterm feature dir (config currently at `chezmoi/dot_wezterm.lua` and unmanaged elsewhere)

---

## How this file stays useful

- Add an action item the moment a follow-up surfaces in any feature's
  `logs/tasks.md` or in `docs/WORKLOG.md`.
- Tick boxes here as you complete them; mirror the changes to the feature's
  `logs/tasks.md` so the source of truth stays consistent.
- Re-refresh the **Status snapshot** table when feature state changes.
