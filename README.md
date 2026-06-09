# Dotfiles — Cross-Platform Dev Environment

**mise + chezmoi + starship + zellij + neovim + GNOME**

One repo. All configs, setup scripts, desktop theming, and dev knowledge. Drop onto any Rocky Linux / Fedora / RHEL machine and have a fully configured development environment in minutes.

📚 **Full documentation:** [`docs/`](docs/index.mdx) — a browsable, no-gaps reference for every tool, feature, customization, keybinding, AI/agent workflow, and a prompt library. Start at [`docs/index.mdx`](docs/index.mdx); the live status of every feature is in [`docs/feature-catalog.mdx`](docs/feature-catalog.mdx).

---

## Quick Start (New Machine)

```bash
# 1. Install chezmoi + pull all configs
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply SathishKumarAI/Dotfiles

# 2. Install mise + all language runtimes
curl https://mise.run | sh
mise install

# 3. One-command system setup — auto-detects the OS and runs the right steps
bash setup/setup.sh                # Rocky/Fedora -> setup-rocky.sh, Arch -> setup-arch.sh
bash setup/setup.sh --dry-run      # preview the steps first, change nothing
bash setup/setup.sh --os arch      # force a target if detection is wrong

# Done. Log out and back in.
```

### Windows

```powershell
# From the repo's setup/ folder, in PowerShell:
powershell -ExecutionPolicy Bypass -File .\setup.ps1 -DryRun   # preview, change nothing
powershell -ExecutionPolicy Bypass -File .\setup.ps1           # ensure winget+scoop, then install

# then:
chezmoi init --apply SathishKumarAI/Dotfiles
mise install
```

> **Per-OS scripts:** the main entry detects the OS and runs the matching
> orchestrator — all in [`setup/`](setup/):
>
> | OS | Entry | Orchestrator | Package managers |
> |----|-------|--------------|------------------|
> | Rocky / Fedora / RHEL | `setup.sh` | `setup-rocky.sh` | dnf + WezTerm + GNOME theme |
> | Arch / Manjaro | `setup.sh` | `setup-arch.sh` | pacman/yay + GNOME extensions + TLP |
> | Windows 10/11 | `setup.ps1` | `setup-windows.ps1` | winget + scoop (+ `update-user-path.ps1`) |
>
> All three orchestrators install the same toolset (modern CLI, starship,
> zellij, mise, neovim, lazygit, WezTerm, chezmoi). The Linux pair shares the
> dual-OS installers (`install-modern-cli.sh`, `install-automation-tools.sh`,
> `install-extras.sh`). See [`docs/index.mdx`](docs/index.mdx) for the full
> reference and `dotfiles/windows_setup/` for the conda + PATH notes.

---

## What's New (2026-06-08)

| Change | Where | Why |
|--------|-------|-----|
| **Wofi launcher** added to this machine | `chezmoi/private_dot_config/wofi/` | Mainline rofi can't run on GNOME Wayland (no layer-shell support). Wofi is a Wayland-native GTK launcher with the same Catppuccin Mocha look. Bound to `Super+Space`. |
| **chezmoi source root fixed** | `.chezmoiroot` (=`chezmoi`) | Repo had no `.chezmoiroot`; chezmoi was about to scatter repo docs into `$HOME`. The marker scopes the source tree to `chezmoi/` only. |
| **Feature dirs consolidated** under `chezmoi/` | `chezmoi/private_dot_config/{remote-desktop,rofi,wofi}/` | Single source root, single edit path. The old root-level `private_dot_config/` is gone. |
| **Single source of truth** for chezmoi | `~/.config/chezmoi/chezmoi.toml` | `sourceDir = ~/coding/Dotfiles` — edits no longer have to be mirrored into `~/.local/share/chezmoi`. |
| **Aggregated roadmap** | [`ROADMAP.md`](ROADMAP.md) | Every pending action + per-feature future tasks + cross-cutting work in one place. |

Detail and reasoning: [`chezmoi/private_dot_config/wofi/docs/finish-on-this-machine.md`](chezmoi/private_dot_config/wofi/docs/finish-on-this-machine.md).

---

## Repository Structure

```
Dotfiles/
│
├── README.md                           # You are here
├── ROADMAP.md                          # Aggregated future tasks across all features
├── TOOLS_LINKS.md                      # Official URLs for every tool
├── .chezmoiroot                        # Scopes chezmoi's source to the chezmoi/ subdir
│
├── chezmoi/                            # Single chezmoi source root (per .chezmoiroot)
│   ├── dot_bashrc                      #   → ~/.bashrc
│   ├── dot_zshrc                       #   → ~/.zshrc
│   ├── dot_gitconfig                   #   → ~/.gitconfig
│   ├── dot_tmux.conf                   #   → ~/.tmux.conf
│   ├── dot_wezterm.lua                 #   → ~/.wezterm.lua
│   └── private_dot_config/
│       ├── starship.toml               #   → ~/.config/starship.toml
│       ├── zellij/config.kdl           #   → ~/.config/zellij/config.kdl
│       ├── nvim/init.lua               #   → ~/.config/nvim/init.lua
│       ├── lazygit/config.yml          #   → ~/.config/lazygit/config.yml
│       ├── mise/config.toml            #   → ~/.config/mise/config.toml
│       ├── remote-desktop/             #   → ~/.config/remote-desktop/ (RustDesk feature)
│       ├── rofi/                       #   → ~/.config/rofi/ (X11/XWayland launcher — laptop)
│       └── wofi/                       #   → ~/.config/wofi/ (Wayland launcher — this host, NEW)
│
├── setup/                              # Machine provisioning scripts + docs
│   ├── rocky-dev-setup.sh              #   Original setup script (reference)
│   ├── rocky-dev-setup-custom.sh       #   Main setup: mise + chezmoi + Docker
│   ├── gnome-desktop-setup.sh          #   Desktop UI/UX: theme, fonts, extensions
│   ├── chezmoi-migration.sh            #   Migrate existing dotfiles → chezmoi
│   ├── .mise.toml                      #   Project-level runtime versions
│   ├── .gitignore                      #   Ignore build artifacts
│   ├── TOOLS_GUIDE.md                  #   Every tool: why, how, usage
│   ├── FULL_TOOLS_INVENTORY.md         #   60+ tools with versions and install methods
│   ├── APPS_GUIDE.md                   #   GUI apps: Obsidian, VS Code, DBeaver, etc.
│   ├── CLAUDE_TOOLS_GUIDE.md           #   Claude Code, Anthropic SDKs, token-saving
│   ├── SCRIPT_EXPLAINED.md             #   Setup script deep-dive + risk flags
│   └── OPEN_SOURCE_TOOLS.md            #   30+ open-source alternatives compared
│
├── vault/                              # Obsidian knowledge base
│   ├── Home.md                         #   Dashboard / landing page
│   ├── tools/                          #   Tool documentation notes
│   │   ├── Tool Index.md               #     Master tool list
│   │   ├── mise.md                     #     mise usage guide
│   │   ├── chezmoi.md                  #     chezmoi usage guide
│   │   └── Obsidian.md                 #     Obsidian setup + plugins
│   ├── projects/                       #   Project notes
│   │   └── Project Index.md            #     All 32 GitHub repos listed
│   ├── templates/                      #   Note templates
│   │   ├── Daily Note.md               #     Daily dev log template
│   │   └── Project Note.md             #     Per-project note template
│   └── daily/                          #   Daily dev logs (empty, user-filled)
│
├── dotfiles/                           # Legacy configs (Windows origin)
│   ├── starship/starship.toml          #   Original starship config
│   ├── wizterm/.wezterm.lua            #   Original WezTerm config (Windows)
│   ├── Zellij/config.kdl               #   Original Zellij config
│   └── windows_setup/                  #   Windows-specific setup docs
│       ├── conda/setup.md
│       └── env_path/
│
├── assets/                             # Images and cheatsheets
│   ├── glazewm-cheatsheet.png
│   └── glazewm-sample-config.yaml
│
├── tools/                              # Helper scripts
│   └── fetch_env_refs.py               #   Environment reference fetcher
│
└── md files/                           # Miscellaneous guides
    ├── path_fix.md
    └── zoxide.md
```

---

## What's Inside — Detailed Breakdown

### `chezmoi/` — Dotfile Configs (10 files)

These are the actual config files deployed to your home directory via [chezmoi](https://chezmoi.io). Edit with `chezmoi edit <path>`, push with `chezmoi cd && git push`.

| File | Deploys To | What It Configures |
|------|-----------|-------------------|
| `dot_bashrc` | `~/.bashrc` | Bash shell: loads mise, starship, zoxide, fzf, conda. Aliases: `lg`, `v`, `g`, `gs`, `dc`, `gl` |
| `dot_zshrc` | `~/.zshrc` | Zsh shell: same tools + case-insensitive completion, shared history (10k lines), emacs keybindings |
| `dot_gitconfig` | `~/.gitconfig` | Git: user name/email, `main` as default branch, nvim editor, rebase on pull, diff3 merge, aliases (`st`, `co`, `br`, `lg`) |
| `dot_tmux.conf` | `~/.tmux.conf` | tmux: Ctrl+a prefix (matches Zellij), vim-style pane nav, mouse support, Catppuccin Mocha status bar |
| `dot_wezterm.lua` | `~/.wezterm.lua` | WezTerm: GPU rendering, Catppuccin Mocha, JetBrainsMono font, 53% opacity, tab bar at bottom, launch menu for shells |
| `starship.toml` | `~/.config/starship.toml` | Starship prompt: OS icon, git branch/status, Python/Node/Go versions, conda env, Catppuccin Mocha palette |
| `zellij/config.kdl` | `~/.config/zellij/config.kdl` | Zellij: Ctrl+a prefix, vim-style pane navigation |
| `nvim/init.lua` | `~/.config/nvim/init.lua` | Neovim: space leader, relative line numbers, system clipboard, window nav (Ctrl+h/j/k/l), centered scrolling |
| `lazygit/config.yml` | `~/.config/lazygit/config.yml` | lazygit: Catppuccin Mocha theme, Nerd Fonts v3, nvim as editor |
| `mise/config.toml` | `~/.config/mise/config.toml` | mise: Python 3.12, Node LTS, Go latest |

### `setup/` — Machine Setup Scripts & Documentation

**Scripts** — run these to provision a new machine:

| Script | Run As | What It Does |
|--------|--------|-------------|
| `rocky-dev-setup-custom.sh` | `sudo` | **Main script.** Installs mise, chezmoi, Docker, database clients, VS Code, CLI tools, Miniforge, AWS CLI. Rocky 9/10 compatible. |
| `gnome-desktop-setup.sh` | user | Installs Nerd Fonts, Catppuccin Mocha GTK theme + cursors + Papirus icons, 6 GNOME extensions, keyboard shortcuts, Nautilus large icon view + thumbnails. |
| `gnome-taskbar.sh` | user | Enables + configures Dash to Panel: top panel with clock **right** (seconds + date), open-window icons centered, numeric battery %, system tray + system menu right. |
| `gnome-extra-extensions.sh` | user | Installs + enables AppIndicator (tray), Tiling Assistant (window tiling), Just Perfection (UI tweaks) via `yay`. |
| `gnome-panel-extras.sh` | user | Installs + enables Caffeine (keep-awake toggle) + Media Controls (play/pause + track in panel) via `yay` + `gext`. |
| `laptop-battery.sh` | user | Battery saver: installs TLP drop-in (`tlp/01-battery-saver.conf`) + powertop + thermald, masks power-profiles-daemon, applies. Turbo off / governor powersave / Wi-Fi+audio power save on battery. |
| `rocky-dev-setup.sh` | `sudo` | Original reference script (before mise/chezmoi customization). Kept for comparison. |
| `chezmoi-migration.sh` | user | Migrates existing dotfiles into chezmoi format. One-time use. |

**Documentation** — detailed guides for every aspect:

| Guide | What's Covered |
|-------|---------------|
| [TOOLS_GUIDE.md](setup/TOOLS_GUIDE.md) | Every tool explained: architecture diagram, why it's installed, config reference, per-project usage, new machine setup flow |
| [FULL_TOOLS_INVENTORY.md](setup/FULL_TOOLS_INVENTORY.md) | 60+ tools listed with versions, install methods, and quick-start commands. Frontend, backend, databases, containers, DevOps, CLI |
| [APPS_GUIDE.md](setup/APPS_GUIDE.md) | 8 Flatpak GUI apps: Obsidian, VS Code, DBeaver, Postman, Podman Desktop, Logseq, draw.io, Anki. Purpose and first-launch setup |
| [CLAUDE_TOOLS_GUIDE.md](setup/CLAUDE_TOOLS_GUIDE.md) | Claude Code CLI, Anthropic Python/Node SDKs, CLAUDE.md workspace files, permission settings, memory system, token-saving strategies |
| [SCRIPT_EXPLAINED.md](setup/SCRIPT_EXPLAINED.md) | Section-by-section breakdown of setup scripts, Rocky 10 compatibility table (tested), risk flags, safe testing methods (Docker/Vagrant/cloud) |
| [OPEN_SOURCE_TOOLS.md](setup/OPEN_SOURCE_TOOLS.md) | 30+ open-source tools compared: mise vs asdf, chezmoi vs dotbot vs YADM, Devbox, Nix + home-manager, Omakub. With star counts and Rocky support |

### `vault/` — Obsidian Knowledge Base

Open this directory as a vault in Obsidian (`~/coding/Dotfiles/vault/` or `~/coding/DevVault/`).

| File | Purpose |
|------|---------|
| `Home.md` | Dashboard with quick links to all sections |
| `tools/Tool Index.md` | Master list of all installed tools with versions |
| `tools/mise.md` | mise commands, per-project config, version switching |
| `tools/chezmoi.md` | chezmoi workflow: add, edit, apply, push |
| `tools/Obsidian.md` | Obsidian vault setup, recommended plugins, keyboard shortcuts |
| `projects/Project Index.md` | All 32 GitHub repos organized by category (AI/ML, web, data science, tools) |
| `templates/Daily Note.md` | Template for daily dev logs |
| `templates/Project Note.md` | Template for per-project documentation |

### `dotfiles/` — Legacy Windows Configs

Original configs from the Windows setup (GlazeWM + WezTerm + Starship + Zellij). Kept for reference. The `chezmoi/` directory contains the current cross-platform versions.

### `chezmoi/private_dot_config/` — Feature directories

Self-contained feature dirs that follow a consistent layout
(`README.md` + `scripts/` + `docs/` + `logs/`). Each one is chezmoi-applied
to `~/.config/<name>/`.

#### `remote-desktop/` — RustDesk
Multi-distro RustDesk remote desktop scripts (Rocky, Fedora, Ubuntu, Arch)
with connection guides and setup documentation. See
[`remote-desktop/README.md`](chezmoi/private_dot_config/remote-desktop/README.md).

#### `wofi/` — Wayland app launcher (NEW)
Wayland-native replacement for rofi on GNOME Wayland. Builds wofi +
gtk-layer-shell from source (neither is packaged on Rocky 10), Catppuccin
Mocha themed, bound to `Super+Space`. See
[`wofi/README.md`](chezmoi/private_dot_config/wofi/README.md) and
[`wofi/docs/finish-on-this-machine.md`](chezmoi/private_dot_config/wofi/docs/finish-on-this-machine.md).

#### `rofi/` — XWayland launcher (laptop)
`.rasi` config + Catppuccin Mocha theme with fuzzy matching, MRU sort, and a
custom modes list. Used on the Dell laptop where Super is unavailable —
bound to `Ctrl+Alt+Space`, runs under XWayland. On Wayland-only hosts (this
one) wofi takes its place.

---

## Theme — Catppuccin Mocha Everywhere

Every tool uses the [Catppuccin Mocha](https://github.com/catppuccin/catppuccin) color palette for a consistent dark theme:

| Tool | Theme Applied Via |
|------|------------------|
| Starship prompt | `starship.toml` palette section |
| WezTerm | `color_scheme = "Catppuccin Mocha"` |
| lazygit | Custom theme colors in `config.yml` |
| tmux | Status bar colors in `.tmux.conf` |
| GTK / GNOME | `catppuccin-mocha-blue-standard+default` theme |
| Cursors | `catppuccin-mocha-dark-cursors` |
| Icons | Papirus Dark (complementary dark icons) |

---

## GNOME Desktop Setup

| Component | What's Applied |
|-----------|---------------|
| **Theme** | Catppuccin Mocha GTK + dark mode |
| **Icons** | Papirus Dark |
| **Cursors** | Catppuccin Mocha Dark |
| **Fonts** | JetBrainsMono + FiraCode Nerd Fonts |
| **Extensions** | Dash to Panel, CopyQ Clipboard, AppIndicator, Tiling Assistant, Just Perfection, Caffeine, Media Controls (+ Blur my Shell, Vitals via desktop-setup) |
| **Panel** | `gnome-taskbar.sh` — clock **right** (seconds+date), window icons centered, numeric battery %, tray + system menu right |
| **Files** | Nautilus large icon view + image thumbnails (`gnome-desktop-setup.sh`) |
| **Battery** | TLP drop-in (`laptop-battery.sh`): turbo off / powersave / Wi-Fi+audio save on battery, performance on AC; + powertop + thermald |
| **Power idle** | blank 3 min, suspend 10 min (battery) / 30 min (AC), dim before blank, auto power-save when low (`gnome-desktop-setup.sh`) |

> Per-extension daily usage + keybindings: [`md files/KEYBOARD-SHORTCUTS.md`](md%20files/KEYBOARD-SHORTCUTS.md) → "GNOME — Extensions".

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Super+T` | Open terminal (Ptyxis) |
| `Super+E` | Open file manager |
| `Super+B` | Open browser (Brave) |
| `Super+C` | Open VS Code |
| `Super+Space` | Wofi app launcher (Wayland-native; was rofi, which crashes on Wayland) |
| `Super+Q` | Close window |
| `Super+Up` | Maximize window |
| `Super+Down` | Minimize window |
| `Super+[` | Previous workspace |
| `Super+]` | Next workspace |
| `Shift+Super+[` | Move window to previous workspace |
| `Shift+Super+]` | Move window to next workspace |
| `Alt+Tab` | Switch windows |

---

## Runtimes (via mise)

All language runtimes managed by [mise](https://mise.jdx.dev) — one tool replaces pyenv, nvm, goenv, and more.

| Runtime | Version | Purpose |
|---------|---------|---------|
| Python | 3.12 | AI/ML, data science, FastAPI, Django, Flask |
| Node.js | LTS (24.x) | Web dev, TypeScript, Next.js, Vite |
| Go | latest (1.26.x) | CLI tools, infrastructure |
| Rust | 1.95 | High-performance tools (eza, hyperfine, etc.) |

Per-project versions: drop a `.mise.toml` in any directory.

---

## 60+ Installed Tools (Summary)

| Category | Tools |
|----------|-------|
| **Frontend** | Node.js, npm, yarn, pnpm, Bun, Vite, Storybook, Playwright, create-next-app |
| **Backend Python** | FastAPI, Flask, Django, uvicorn, Celery, Poetry, Ruff, httpie |
| **Backend Node** | tsx, Prisma |
| **Databases** | psql, sqlite3, mysql, mongosh, DBeaver (GUI) |
| **Containers** | Docker, Podman, lazydocker, ctop, dive, Podman Desktop |
| **DevOps** | Terraform, kubectl, k9s, Ansible, ngrok, Caddy, AWS CLI |
| **Editors** | Neovim, VS Code, lazygit |
| **Shell** | starship, zellij, tmux, zoxide, fzf, bat, eza, ripgrep, fd |
| **AI/ML** | Claude Code, Anthropic Python SDK, Anthropic Node SDK, Miniforge (conda) |
| **Apps** | Obsidian, Anki, Logseq, draw.io, Postman |

Full details: [setup/FULL_TOOLS_INVENTORY.md](setup/FULL_TOOLS_INVENTORY.md)

---

## Documentation Index

| Guide | Description | Audience |
|-------|-------------|----------|
| [setup/TOOLS_GUIDE.md](setup/TOOLS_GUIDE.md) | Architecture, tool-by-tool reference, dotfile-by-dotfile breakdown | Developers setting up or understanding the environment |
| [setup/FULL_TOOLS_INVENTORY.md](setup/FULL_TOOLS_INVENTORY.md) | 60+ tools: versions, install methods, quick-start snippets | Quick reference / lookup |
| [setup/APPS_GUIDE.md](setup/APPS_GUIDE.md) | GUI applications: what, why, how to launch, first-time setup | Desktop users |
| [setup/CLAUDE_TOOLS_GUIDE.md](setup/CLAUDE_TOOLS_GUIDE.md) | Claude Code, SDKs, CLAUDE.md, permissions, memory, token-saving | AI-assisted development |
| [setup/SCRIPT_EXPLAINED.md](setup/SCRIPT_EXPLAINED.md) | Setup script deep-dive, Rocky 10 compatibility, risk flags | Sysadmins / anyone auditing the scripts |
| [setup/OPEN_SOURCE_TOOLS.md](setup/OPEN_SOURCE_TOOLS.md) | 30+ alternatives compared: mise, chezmoi, Devbox, Nix, Omakub | Decision-makers choosing tools |
| [TOOLS_LINKS.md](TOOLS_LINKS.md) | Official URLs for every tool | Quick reference |
| [ROADMAP.md](ROADMAP.md) | Aggregated future tasks (per-feature + cross-cutting) with subtasks | Planning / picking next work |
| [wofi/README.md](chezmoi/private_dot_config/wofi/README.md) | Wayland app launcher: install, theme, troubleshoot | Anyone running Wayland |
| [wofi/docs/finish-on-this-machine.md](chezmoi/private_dot_config/wofi/docs/finish-on-this-machine.md) | What's done on this host, what's left, the chezmoi-root fix | This-machine reference |
| [remote-desktop/README.md](chezmoi/private_dot_config/remote-desktop/README.md) | RustDesk overview + per-distro quick start | Anyone setting up remote desktop |

---

## TODO — Future Improvements

### High Priority
- [ ] **Neovim plugin manager** — Add [lazy.nvim](https://github.com/folke/lazy.nvim) with LSP (pyright, ts_ls, gopls), Treesitter, Telescope, and Catppuccin theme
- [ ] **Docker setup** — Run `sudo bash install-system-packages.sh` to install Docker CE + database clients + Redis container
- [ ] **chezmoi templates** — Convert dotfiles to `.tmpl` files with machine-specific variables (hostname, email, work vs personal)
- [ ] **VS Code extensions** — Script to auto-install: Python, Pylance, ESLint, Prettier, GitLens, Docker, Catppuccin theme
- [ ] **Catppuccin for Firefox** — Install [catppuccin/firefox](https://github.com/catppuccin/firefox) theme

### Medium Priority
- [ ] **Obsidian Git plugin** — Auto-commit vault to GitHub for cross-machine sync
- [ ] **Obsidian Spaced Repetition** — Flashcard plugin for coding study (Python, system design, ML concepts)
- [ ] **SSH config** — Managed `~/.ssh/config` for common hosts (via chezmoi with encryption)
- [ ] **Conda environments** — Pre-built `environment.yml` files for AI/ML projects (torch, transformers, langchain)
- [ ] **Hyprland config** — Alternative to GNOME for tiling WM enthusiasts (Wayland-native)
- [ ] **GNOME dconf backup** — Export full `dconf dump /` as a restorable file in chezmoi

### Low Priority
- [ ] **Wallpaper collection** — Catppuccin-themed wallpapers from [catppuccin/wallpapers](https://github.com/catppuccin/wallpapers)
- [ ] **Alacritty config** — Alternative terminal (lighter than WezTerm)
- [ ] **bat theme** — Catppuccin theme for `bat` (cat replacement)
- [ ] **fzf Catppuccin** — Color scheme for fuzzy finder
- [ ] **btop** — Replace htop with btop (better visuals, Catppuccin support)
- [ ] **Automated testing** — CI/CD pipeline to test setup script in a Rocky Linux container
- [ ] **Ansible playbook** — Convert setup scripts to Ansible roles for enterprise use
- [ ] **WezTerm Linux config** — Fork the Windows `.wezterm.lua` into a Linux-specific version (remove PowerShell/WSL paths)

### In Progress
- [ ] **Log out / back in** — apply latest GNOME changes (clock-right, Caffeine, Media Controls). Wayland can't hot-reload the shell.
- [ ] **Run `setup/laptop-battery.sh`** — applies TLP battery-saver drop-in + powertop + thermald (needs sudo).
- [ ] **GNOME dconf backup** — `dconf dump /` into chezmoi so the whole desktop is restorable.

### Completed
- [x] Extra GNOME extensions — AppIndicator + Tiling Assistant + Just Perfection installed + enabled via `gnome-extra-extensions.sh`
- [x] Panel features — clock moved to **right** with seconds + date, numeric battery % (`gnome-taskbar.sh`)
- [x] Panel extras — Caffeine (keep-awake) + Media Controls installed via `gnome-panel-extras.sh`
- [x] Nautilus — large icon view + image thumbnails (`gnome-desktop-setup.sh`)
- [x] System tuning notes — `md files/SYSTEM-TUNING.md` (boot/runtime/disk cleanup for this box)
- [x] GNOME panel — Dash to Panel enabled + configured via `gnome-taskbar.sh`; fixed `panel-positions`/`panel-sizes` GVariant-string bug
- [x] CopyQ Clipboard extension enabled (top-right clipboard history)
- [x] Removed accessibility icon from top bar (disabled all a11y features)
- [x] GNOME extension docs — per-extension daily usage + keybindings in `md files/KEYBOARD-SHORTCUTS.md`
- [x] mise — manages Python 3.12, Node 24 LTS, Go 1.26, Rust 1.95
- [x] chezmoi — 10 dotfiles tracked and deployable
- [x] Catppuccin Mocha — applied to starship, wezterm, lazygit, tmux, GTK, cursors
- [x] GNOME extensions — Blur my Shell, Just Perfection, AppIndicator, Clipboard Indicator, Vitals, Tiling Assistant
- [x] Nerd Fonts — JetBrainsMono + FiraCode installed
- [x] 60+ dev tools — frontend, backend, databases, containers, DevOps, CLI
- [x] 8 Flatpak apps — Obsidian, VS Code, DBeaver, Postman, Podman Desktop, Logseq, draw.io, Anki
- [x] Obsidian vault — tool docs, project index, templates
- [x] Claude Code — SDKs, CLAUDE.md, permissions, memory system
- [x] GNOME keyboard shortcuts — Super+T/E/B/C/Q, workspaces, tiling
- [x] 6 documentation guides — covering every tool, app, and setup decision
- [x] RustDesk — multi-distro remote desktop scripts
- [x] **Wofi** — Wayland app launcher (2026-05-27): builds wofi + gtk-layer-shell from source, Catppuccin Mocha themed, bound to Super+Space
- [x] **chezmoi source root fixed** (2026-05-27): added `.chezmoiroot`, moved feature dirs under `chezmoi/`, single source of truth via `sourceDir = ~/coding/Dotfiles`
- [x] **ROADMAP.md** added (2026-06-08): single aggregated view of every pending and future task with subtasks

---

## License

Personal dotfiles — use freely, attribution appreciated.
