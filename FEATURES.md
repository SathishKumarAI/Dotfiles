> **Moved:** the canonical, always-current feature reference now lives in the
> docs tree → [`docs/feature-catalog.mdx`](docs/feature-catalog.mdx) (with a doc
> per feature under [`docs/`](docs/index.mdx)). This file is kept as the original
> per-machine bring-up checklist with the fast-path commands.

# Feature Parity Checklist — Bring This Machine Up to Full Setup

Every feature tracked in this dotfiles repo, and whether it's **live on this
machine yet**. Goal: nothing missing vs. the full Arch/laptop setup.

- **Host:** Rocky Linux 10.1 · GNOME 47 · Wayland
- **Last checked:** 2026-06-08
- Status legend: ✅ done · ⚠️ diverged (live ≠ repo, decide which wins) · ⏳ pending (in repo, not applied here) · ❌ missing (needs install/build)

---

## 1. Shell & prompt

| Feature | Status | Action to finish |
|---------|--------|------------------|
| `bash` config (`~/.bashrc`) | ✅ live, matches repo | — |
| `zsh` config (`~/.zshrc`) | ⚠️ diverged | `chezmoi diff ~/.zshrc` → apply or `chezmoi add` |
| `starship` prompt | ⚠️ diverged | `chezmoi diff ~/.config/starship.toml` → reconcile |
| `zoxide` (smart `cd`) | ✅ installed | — |
| `fzf` (fuzzy finder) | ❌ not installed | `sudo dnf install fzf` (or build) |

## 2. Terminal & multiplexer

| Feature | Status | Action to finish |
|---------|--------|------------------|
| `wezterm` terminal | ⚠️ diverged (`~/.wezterm.lua`) | `chezmoi diff ~/.wezterm.lua` → reconcile |
| `xdg-terminals.list` (default terminal) | ⏳ pending | `chezmoi apply ~/.config/xdg-terminals.list` |
| `tmux` config | ✅ live, matches repo | — |
| `zellij` config | ⚠️ diverged | `chezmoi diff ~/.config/zellij/config.kdl` → reconcile |
| `zellij` dev layout | ⏳ pending | `chezmoi apply ~/.config/zellij/layouts/dev.kdl` |

## 3. Editor & git

| Feature | Status | Action to finish |
|---------|--------|------------------|
| `nvim` (`init.lua`) | ✅ live | — |
| `git` config | ✅ live | — |
| `lazygit` TUI + config | ✅ live | — |

## 4. App launcher (per-machine: wofi here, rofi on laptop)

| Feature | Status | Action to finish |
|---------|--------|------------------|
| `wofi` launcher (Wayland) | ❌ binary not built | `bash ~/.config/wofi/scripts/install-wofi.sh` (sudo) |
| `wofi` config + Catppuccin style | ✅ staged | — |
| `Super+Space` → wofi keybind | ✅ rebound | verify after build: press `Super+Space` |
| `rofi` config + theme | ⚠️ diverged | laptop uses rofi (`Ctrl+Alt+Space`); reconcile if keeping here |

## 5. Custom launcher scripts (`~/.local/bin`) — ALL pending here ⏳

These are your handy menu commands — none are on this machine yet.
Apply all at once: `chezmoi apply ~/.local/bin`

| Script | Purpose |
|--------|---------|
| `rofi-calc-menu` | Calculator menu |
| `rofi-clip` | Clipboard history picker |
| `rofi-emoji` | Emoji picker |
| `rofi-power` | Power menu (lock/logout/reboot/poweroff) |
| `rofi-ssh` | SSH host picker |
| `zellij-pick` | Zellij session picker |
| `update-all` | One-shot system/tool updater |

## 6. Clipboard

| Feature | Status | Action to finish |
|---------|--------|------------------|
| `cliphist` autostart | ⏳ pending | `chezmoi apply ~/.config/autostart/cliphist.desktop` (ensure `cliphist` installed) |

## 7. Remote desktop (RustDesk)

| Feature | Status | Action to finish |
|---------|--------|------------------|
| `rustdesk` binary | ✅ installed | — |
| Scripts + docs in `~/.config/remote-desktop/` | ⏳ pending | `chezmoi apply ~/.config/remote-desktop` |
| Phase 2 deployment (systemd, Host ID, password) | ⏳ not started | see `remote-desktop/logs/tasks.md` |

## 8. Runtime / version manager

| Feature | Status | Action to finish |
|---------|--------|------------------|
| `mise` installed | ✅ | — |
| `mise` config | ⚠️ diverged | `chezmoi diff ~/.config/mise/config.toml` → reconcile |

## 9. GNOME desktop environment

| Feature | Status | Action to finish |
|---------|--------|------------------|
| Desktop tweaks (idle/suspend, panel, taskbar) | run scripts | `bash setup/gnome-desktop-setup.sh`, `gnome-panel-extras.sh`, `gnome-taskbar.sh` |
| Extra extensions | run script | `bash setup/gnome-extra-extensions.sh` |
| Enabled extensions (live) | ✅ blur-my-shell, clipboard-indicator, just-perfection, tiling-assistant, appindicator, Vitals | — |
| `gnome-launcher` run-once hook | ⏳ pending (chezmoi run script) | runs on next `chezmoi apply` |

## 10. Laptop-only (Dell) — skip on this desktop host

| Feature | Status | Action |
|---------|--------|--------|
| `tlp` battery saver | ❌ not installed | laptop only: `bash setup/laptop-battery.sh` |

---

## The fast path — finish this machine in order

```bash
# 1. Build the Wayland launcher (only real blocker; needs sudo)
bash ~/.config/wofi/scripts/install-wofi.sh

# 2. Pull in everything that's purely additive (safe — adds new files only)
chezmoi apply ~/.local/bin                       # custom launcher scripts
chezmoi apply ~/.config/remote-desktop           # rustdesk scripts/docs
chezmoi apply ~/.config/wofi                      # wofi scripts/docs
chezmoi apply ~/.config/autostart                 # cliphist autostart
chezmoi apply ~/.config/xdg-terminals.list        # default terminal
chezmoi apply ~/.config/zellij/layouts            # dev layout

# 3. Reconcile the diverged configs ONE BY ONE (decide repo vs live each)
for f in ~/.zshrc ~/.wezterm.lua ~/.config/starship.toml \
         ~/.config/mise/config.toml ~/.config/zellij/config.kdl \
         ~/.config/rofi/config.rasi; do
  chezmoi diff "$f"          # then: chezmoi apply "$f"  (repo wins)
done                          #   or: chezmoi add  "$f"  (live wins)

# 4. Install the small missing tools
sudo dnf install -y fzf

# Laptop only:
# bash ~/coding/Dotfiles/setup/laptop-battery.sh
```

> ⚠️ Do **not** run a blanket `chezmoi apply`. The 6 diverged configs in step 3
> must be decided per-file so you don't clobber local tweaks.
