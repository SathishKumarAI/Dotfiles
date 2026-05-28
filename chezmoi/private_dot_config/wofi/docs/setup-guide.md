# Wofi Setup Guide

Detailed build, configuration, and troubleshooting reference for wofi on Rocky Linux 10 (GNOME 47, Wayland).

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Rocky Linux 10 (or RHEL 10 family) | Other RPM distros work with the same script |
| `sudo` access | Needed to `dnf install` deps and write to `/usr/local` |
| Internet access | Sources are cloned from GitHub at build time |
| GNOME on Wayland | Confirm with `echo $XDG_SESSION_TYPE` → `wayland` |

## Build Dependencies

Installed automatically by `scripts/install-wofi.sh`:

| Package | Purpose |
|---------|---------|
| `gtk3-devel` | wofi is a GTK3 app |
| `wayland-devel`, `wayland-protocols-devel` | Wayland client + protocol definitions |
| `meson`, `ninja-build` | Build system for both projects |
| `gcc` | C compiler |
| `gobject-introspection-devel`, `vala` | gtk-layer-shell bindings generation |
| `pkg-config` | Dependency discovery |
| `git` | Clone sources |

Neither `wofi` nor `gtk-layer-shell` is in Rocky's repos (verified: `dnf search wofi` / `dnf search gtk-layer-shell` return nothing), which is why both are built from source.

## Build Steps (what the script does)

```bash
# gtk-layer-shell — the Wayland layer-shell binding wofi needs
git clone --depth 1 https://github.com/wmww/gtk-layer-shell.git
cd gtk-layer-shell
meson setup build --prefix=/usr/local -Dexamples=false -Ddocs=false -Dtests=false
ninja -C build && sudo ninja -C build install

# wofi
git clone --depth 1 https://github.com/jgmdev/wofi.git
cd wofi
export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig
meson setup build --prefix=/usr/local
ninja -C build && sudo ninja -C build install

sudo ldconfig   # so the new libgtk-layer-shell is found at runtime
```

All clones happen inside a `mktemp -d` directory that is deleted on exit, so nothing is left in the home directory.

## Configuration

Two files in `~/.config/wofi/` (managed in the repo, applied by chezmoi):

### `config` (INI)
Defaults for every launch: `drun` mode, 600×420, centered, case-insensitive, icons on. Override per-call on the command line.

### `style.css` (GTK CSS)
Catppuccin Mocha palette, matching the rofi theme:

| Token | Hex | Role |
|-------|-----|------|
| base | `#1e1e2e` | window background |
| surface | `#313244` | input bar |
| text | `#cdd6f4` | foreground |
| blue | `#89b4fa` | accent / border / selection text |
| overlay | `#45475a` | selected row |

Common wofi CSS selectors: `window`, `#input`, `#outer-box`, `#scroll`, `#inner-box`, `#entry`, `#entry:selected`, `#text`, `#img`.

## Keybinding

`scripts/setup-wofi-keybind.sh` binds `Super+Space` to `wofi --show drun` via GNOME custom keybindings (`gsettings`). It finds the next free `customN` slot, reuses an existing wofi slot if present, and registers it. No manual GNOME Settings clicking required.

To change the key, edit `BINDING` / `LAUNCH_CMD` at the top of the script and re-run it.

## Verification

```bash
wofi --version                 # confirms the binary installed
echo $XDG_SESSION_TYPE         # should print: wayland
wofi --show drun               # launcher should appear, themed dark/blue
```

Press `Super+Space` after running the keybind script to confirm the shortcut.

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `error while loading shared libraries: libgtk-layer-shell.so` | `sudo ldconfig` (the install script already does this) |
| `meson: command not found` | `sudo dnf install meson ninja-build` |
| gtk-layer-shell meson fails on `valac` | `sudo dnf install vala gobject-introspection-devel` |
| `Package gtk+-3.0 was not found` | `sudo dnf install gtk3-devel` |
| wofi build can't find gtk-layer-shell | Ensure `PKG_CONFIG_PATH` includes `/usr/local/lib64/pkgconfig` |
| Launcher appears unstyled | Confirm `~/.config/wofi/style.css` exists (`chezmoi apply`) |
| Nothing happens on Super+Space | Re-run `setup-wofi-keybind.sh`; check GNOME Settings → Keyboard → Custom Shortcuts |

## Customization Cheatsheet

```bash
# Run mode (binaries on PATH) instead of desktop entries
wofi --show run

# Use as a dmenu replacement in scripts
printf '%s\n' one two three | wofi --dmenu

# Different size for a one-off
wofi --show drun --width 800 --height 500
```
