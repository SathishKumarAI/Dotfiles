# Machine Cheatsheet — Rocky Linux 10 / GNOME 49 Wayland

Daily commands for this workstation. Tools verified present 2026-06-18.
See also: [DEV-WORKFLOW](DEV-WORKFLOW.md) · [CLAUDE-CODE-GUIDE](CLAUDE-CODE-GUIDE.md) · [TROUBLESHOOTING](TROUBLESHOOTING.md).

## Hardware reality (read first)
- **Single 7200rpm spinning HDD** (`/sys/block/sda/queue/rotational = 1`), no SSD. The machine is **I/O-bound**, not CPU/RAM-bound (12 cores, 15Gi RAM mostly idle).
- Cleaning disk does NOT speed it up (852G `/home`, 741G free). The real fix is an SSD.
- Boot fixes + GNOME responsiveness fixes live in `Dotfiles/setup/speedup-boot.sh` and `optimize-responsiveness.sh`.

## mise — runtime versions
```sh
mise ls                  # show configured runtimes + status
mise install             # install everything in ~/.config/mise/config.toml
mise use python@3.12     # pin a tool for this project (writes .mise.toml)
mise use -g node@lts     # set global default
mise exec -- python -V   # run inside the mise env
mise upgrade             # bump to newest allowed versions
```
⚠️ Note: mise config lists python/node/go but they show **(missing)** — the active
`python` is **miniforge** (`~/miniforge3/bin`) and `node` is **system** (`/usr/bin`).
Run `mise install` if you want mise to own them, or leave as-is. See TROUBLESHOOTING.

## chezmoi — dotfiles
```sh
chezmoi status                  # what would change
chezmoi diff                    # preview changes
chezmoi apply --force           # apply repo state to $HOME
chezmoi edit ~/.bashrc          # edit the SOURCE of a managed file
chezmoi cd                      # jump to the source dir
chezmoi managed                 # list tracked files
```
⚠️ The live `~/.local/share/chezmoi` source has diverged/broken (`managed` returns
empty). Canonical source = `~/coding/Dotfiles/chezmoi/`. Edit BOTH repo + live rc
until repaired. See TROUBLESHOOTING.

## Packages
```sh
# system (dnf)
sudo dnf install <pkg>
sudo dnf upgrade
sudo dnf clean all              # reclaim ~/var/cache/dnf
# GUI apps (flatpak — sandboxed, auto-update)
flatpak install flathub <app-id>
flatpak update
flatpak list --app
# containers (Podman preferred on Rocky; docker also present)
podman ps -a
```

## systemd / services
```sh
systemctl --user status <unit>          # user services (tracker, etc.)
systemctl --failed                       # what's broken
systemd-analyze blame | head             # slowest boot units
systemd-analyze critical-chain
journalctl --disk-usage
journalctl -u <unit> -b                   # logs this boot
```

## Disk / cleanup (space, not speed)
```sh
du -h --max-depth=1 ~ 2>/dev/null | sort -rh | head    # biggest dirs
ncdu ~                                                  # interactive (install: dnf install ncdu)
npm cache clean --force                                 # ~3G
rm -rf ~/.cache/*                                        # ~6.5G, regenerates
```

## GNOME / Wayland
```sh
gnome-extensions list
gnome-extensions disable <uuid>          # e.g. tiling-assistant@leleat-on-github
gsettings set org.gnome.desktop.peripherals.keyboard delay 250
gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 20
```
Tiling stack: PaperWM + AATWS (advanced-alt-tab). Taskbar: Dash to Panel intellihide.

## Modern CLI replacements (all installed)
| Old | New | |
|-----|-----|--|
| `ls` | `eza` | icons/git-aware |
| `cat` | `bat` | syntax highlight |
| `find` | `fd` | |
| `grep` | `rg` (ripgrep) | |
| `cd` | `zoxide` (`z`) | frecency jump |
| `du` | `ncdu` / `dust` | |
| history | `atuin` | searchable, synced |
| `top` | `btop` | |
| man | `tldr` | examples |
| file mgr | `yazi` | TUI |
| terminal | `wezterm` | leader `Ctrl+a` |
| multiplexer | `zellij` | |
| prompt | `starship` | |
