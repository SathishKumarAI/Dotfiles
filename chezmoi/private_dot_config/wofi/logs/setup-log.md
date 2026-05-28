# Wofi — Setup Log

## Environment
- **OS**: Rocky Linux 10.1 x86_64
- **Desktop**: GNOME 47, Wayland session
- **Install prefix**: `/usr/local`
- **Runtime mgmt**: mise; **dotfiles**: chezmoi
- **Theme**: Catppuccin Mocha (shared across the setup)

## Decision: wofi over rofi / rofi-wayland

### The trigger
Launching rofi under GNOME Wayland crashed:
```
Wayland-ERROR: Rofi on wayland requires support for the layer shell protocol
Trace/breakpoint trap (core dumped)
```
Mainline rofi (the version Rocky ships) is X11/XCB only and has no Wayland layer-shell backend.

### Options considered
1. **rofi-wayland** (lbonn fork) — keeps `.rasi` configs, but not packaged for Rocky 10; needs a source build. A `setup-rofi-wayland.sh` for this already exists under `setup/`.
2. **wofi** — Wayland-first GTK launcher; also not packaged, also a source build. Lighter and purpose-built for Wayland.
3. **XWayland fallback** (`GDK_BACKEND=x11 rofi`) — works but defeats the point of running Wayland.

### Choice
Went with **wofi** (option 2). Both Wayland options require building from source on Rocky 10, so the deciding factor was that wofi is Wayland-native and lighter. Its `gtk-layer-shell` dependency is also unpackaged, so the install script builds that first.

### Repo placement
Organized as a self-contained **feature directory** under `private_dot_config/wofi/`, mirroring the existing `remote-desktop/` feature (README + scripts/ + docs/ + logs/). No separate clone repo: build sources are cloned into a temp dir and removed on exit. chezmoi applies `config` and `style.css` to `~/.config/wofi/`.

## Verification (commands available, not yet executed)
- `dnf search wofi` → no match (confirms not packaged)
- `dnf search gtk-layer-shell` → no match (confirms not packaged)
- `dnf list available gtk3-devel` → available in appstream
- `rpm -q meson ninja-build` → both installed

## Timeline
- **2026-05-27** — rofi Wayland crash diagnosed; wofi selected; feature dir scaffolded under `private_dot_config/wofi/` with install/keybind/uninstall scripts, Catppuccin Mocha config, and docs. Build not yet run on the host.
- **2026-05-27** — Audited the machine before finishing. Findings below. Staged config to `~/.config/wofi/` via plain `cp` (chezmoi apply unsafe). Fixed keybind script to repoint an existing Super+Space slot. See [finish-on-this-machine.md](../docs/finish-on-this-machine.md).

## Machine audit findings (2026-05-27)
- **Two repo clones**: `~/coding/Dotfiles` (editing copy, HEAD 7b6b0ee, has wofi uncommitted) vs `~/.local/share/chezmoi` (chezmoi source, HEAD d9404bf, no wofi/rofi). They have diverged; coding is 1 commit ahead. Edits aren't visible to chezmoi until pushed + pulled.
- **chezmoi root misconfigured**: no `.chezmoiroot`, so repo root is the source. `chezmoi managed` would apply `README.md`→`~/README.md`, `chezmoi/.bashrc`→`~/chezmoi/.bashrc`, `dotfiles/`→`~/dotfiles/`, etc. The intended root is the `chezmoi/` subdir (proper `dot_*` names). `chezmoi apply` has never run here (no artifacts in $HOME), so nothing is broken yet — but applying as-is would scatter files. **Do not run `chezmoi apply` until consolidated.**
- **Live configs placed manually**: `~/.config/rofi` and `~/.bashrc` exist but are not chezmoi-managed at their target paths.
- **Keybind conflict**: `custom4` binds `Super+Space` to the dead `rofi` command. Keybind script updated to reuse that slot instead of creating a duplicate.
- **Env confirmed**: `XDG_SESSION_TYPE=wayland`; `wofi` and `gtk-layer-shell` absent; `meson`/`ninja-build` present; `gtk3-devel` available in appstream.

## Resolution (2026-05-27, decisions made on user's delegation)
- **chezmoi root fixed**: added `.chezmoiroot` (=`chezmoi`) at the repo root and moved `remote-desktop`, `rofi`, `wofi` from root `private_dot_config/` into `chezmoi/private_dot_config/`. `chezmoi managed` now maps cleanly to `~/.config/...` and dotfile targets with no `$HOME` scaffolding junk.
- **Single source of truth**: created `~/.config/chezmoi/chezmoi.toml` with `sourceDir = /home/deva/coding/Dotfiles`. The `~/.local/share/chezmoi` clone is now orphaned.
- **Did NOT run blanket `chezmoi apply`**: `chezmoi status` shows it would overwrite three diverged live configs — `~/.config/mise/config.toml`, `~/.config/starship.toml`, `~/.config/zellij/config.kdl`. Left for the user to reconcile (`chezmoi diff` / `chezmoi add` / targeted `chezmoi apply`). wofi config already matches the repo, so no apply needed for wofi.
- **Committed + pushed** the feature and the chezmoi reorg to `SathishKumarAI/Dotfiles`.
- **Remaining**: only the sudo build (`install-wofi.sh`).

## Open questions / follow-ups
- Whether to retire the X11 rofi scripts (`setup/setup-rofi-wayland.sh`, `setup/setup-rofi-keybind.sh`) and the `~/coding/rofi-wayland-build/` clone now that wofi is the chosen path. Left untouched pending confirmation (no deletes without asking).
