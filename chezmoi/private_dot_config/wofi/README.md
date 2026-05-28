# Wofi App Launcher (Wayland)

> Wayland-native application launcher for GNOME on Wayland, replacing rofi which cannot run on Wayland without the layer-shell protocol. Catppuccin Mocha themed to match the rest of the setup.

| Feature | Details |
|---------|---------|
| **Tool** | [wofi](https://hg.sr.ht/~scoopta/wofi) (jgmdev fork for active maintenance) |
| **License** | GPL-3.0 (open-source) |
| **Backend** | GTK3 + `gtk-layer-shell` (Wayland layer-shell protocol) |
| **Theme** | Catppuccin Mocha (matches rofi `config.rasi`) |
| **Launch key** | `Super + Space` |
| **Install prefix** | `/usr/local` |

## Why wofi instead of rofi?

Rocky 10 ships mainline **rofi**, which is X11/XCB only. Under GNOME Wayland it fails with:

```
Wayland-ERROR: Rofi on wayland requires support for the layer shell protocol
Trace/breakpoint trap (core dumped)
```

| Criteria | rofi (mainline) | rofi-wayland fork | wofi |
|----------|-----------------|-------------------|------|
| Runs on Wayland natively | No | Yes | Yes |
| Packaged for Rocky 10 | Yes (X11 only) | No (build from source) | No (build from source) |
| Config format | `.rasi` | `.rasi` | GTK CSS + INI |
| Built for wlroots/GNOME | XCB | Both | Layer-shell (wlroots-first) |
| Maintenance | Active | Active fork | Active fork (jgmdev) |

Both wayland options require a source build on Rocky 10. wofi was chosen as the lighter, Wayland-first launcher; its `gtk-layer-shell` dependency also isn't packaged, so the install script builds that too. See [logs/setup-log.md](logs/setup-log.md) for the full rationale.

## Quick Start

```bash
# 1. Build + install wofi and gtk-layer-shell from source
bash scripts/install-wofi.sh

# 2. Bind Super+Space to the launcher
bash scripts/setup-wofi-keybind.sh

# 3. Try it
wofi --show drun
```

The install script:
- Installs build deps (`gtk3-devel`, `wayland-devel`, `meson`, `ninja-build`, `vala`, ...)
- Builds and installs `gtk-layer-shell` to `/usr/local`
- Builds and installs `wofi` to `/usr/local`
- Cleans up all cloned sources (temp dir, removed on exit)

## Usage

| Command | Mode |
|---------|------|
| `wofi --show drun` | Desktop applications (icons) — the default |
| `wofi --show run` | Run any binary on `$PATH` |
| `wofi --show window` | Switch windows (wlroots compositors) |
| `wofi --dmenu` | Pipe a list in, get the selection out (scripting) |

Config and theme live in `~/.config/wofi/` (`config`, `style.css`).

## Directory Structure

Lives at `chezmoi/private_dot_config/wofi/` in the repo (under the chezmoi
source root), applied to `~/.config/wofi/`.

```
wofi/
├── README.md                     # This file — overview and quick start
├── config                        # wofi runtime config  -> ~/.config/wofi/config
├── style.css                     # Catppuccin Mocha theme -> ~/.config/wofi/style.css
├── scripts/
│   ├── install-wofi.sh           # Build + install wofi and gtk-layer-shell from source
│   ├── setup-wofi-keybind.sh     # Bind Super+Space to the launcher (GNOME gsettings)
│   └── uninstall-wofi.sh         # Remove wofi and gtk-layer-shell from /usr/local
├── docs/
│   ├── finish-on-this-machine.md # Remaining step + chezmoi fixes that were made
│   └── setup-guide.md            # Detailed build steps, troubleshooting, customization
└── logs/
    ├── tasks.md                  # Project board: done / in-progress / future
    └── setup-log.md              # Decision log: why wofi, environment, timeline
```

## Reproducing on a New Machine

### Via chezmoi (recommended)
```bash
# 1. Pull dotfiles
chezmoi init SathishKumarAI/Dotfiles
chezmoi apply

# 2. Build + install and bind the key
bash ~/.config/wofi/scripts/install-wofi.sh
bash ~/.config/wofi/scripts/setup-wofi-keybind.sh
```

### Manual (without chezmoi)
```bash
git clone https://github.com/SathishKumarAI/Dotfiles.git
cd Dotfiles/chezmoi/private_dot_config/wofi
bash scripts/install-wofi.sh
bash scripts/setup-wofi-keybind.sh
```

## Uninstall

```bash
bash scripts/uninstall-wofi.sh
```

Removes wofi and gtk-layer-shell from `/usr/local`. Leaves `~/.config/wofi/` and the GNOME keybind in place (instructions printed for clearing them).

## Documentation

| Document | Description |
|----------|-------------|
| [Finish on This Machine](docs/finish-on-this-machine.md) | Remaining step + the chezmoi/source-of-truth fixes that were made |
| [Setup Guide](docs/setup-guide.md) | Build walkthrough, dependencies, theming, troubleshooting |
| [Task Log](logs/tasks.md) | Project board with completed and pending work |
| [Setup Log](logs/setup-log.md) | Decision rationale, environment, session history |
