> **ARCHIVED 2026-08-01 — not the canonical doc.**
> Merged into [`KEYBOARD-SHORTCUTS.md`](../../terminal/KEYBOARD-SHORTCUTS.md); edit that one. Kept here for the
> original wording only. See [archive README](../README.md).

# Keyboard Shortcuts Reference

> GNOME (Wayland) | WezTerm | Zellij | Rofi
> Targets Rocky/Fedora/RHEL; also runs on Arch.

![Cheatsheet](../assets/wezterm-cheatsheet.png)

> Printable one-page version: [`assets/wezterm-cheatsheet.png`](../assets/wezterm-cheatsheet.png)

---

## GNOME — Custom Shortcuts (this repo)

Set by `chezmoi/.chezmoiscripts/run_onchange_after_gnome-launcher.sh`.
Rofi menus need `setup/install-extras.sh` (clipboard/emoji/calc tools).

| Shortcut | Action |
|----------|--------|
| `Ctrl + Space` | Rofi app launcher |
| `Super + W` | Window switcher (rofi) |
| `Super + Escape` | Power menu (lock/logout/suspend/reboot/shutdown) |
| `Super + Shift + V` | Clipboard history (cliphist) |
| `Super + .` | Emoji / unicode picker (rofimoji) |
| `Super + =` | Calculator (rofi-calc / qalc) |
| `Super + \` | SSH menu (opens host in wezterm) |
| `Super + Return` | WezTerm |
| `Super + E` | Files (Nautilus) |
| `Super + B` | Browser (auto-detected) |
| `Super + Shift + S` | Screenshot (region → clipboard) |

## GNOME — Window Management

| Shortcut | Action |
|----------|--------|
| `Super + Q` | Close window |
| `Super + Up` | Toggle maximize |
| `Super + Down` | Minimize |
| `Super + Left` | Snap window left |
| `Super + Right` | Snap window right |
| `Alt + Tab` | Switch windows |
| `Super + Tab` | Switch applications |
| `Alt + F7` | Move window (drag) |
| `Alt + F8` | Resize window |
| `Alt + Space` | Window menu |
| `Alt + F4` | Close window (alt) |

## GNOME — Workspaces

| Shortcut | Action |
|----------|--------|
| `Super + [` | Previous workspace |
| `Super + ]` | Next workspace |
| `Super + Shift + [` | Move window to prev workspace |
| `Super + Shift + ]` | Move window to next workspace |
| `Super + Home` | First workspace |
| `Super + End` | Last workspace |
| `Ctrl + Alt + Up` | Workspace up |
| `Ctrl + Alt + Down` | Workspace down |

## GNOME — Multi-Monitor

| Shortcut | Action |
|----------|--------|
| `Super + Shift + Left` | Move window to left monitor |
| `Super + Shift + Right` | Move window to right monitor |
| `Super + Shift + Up` | Move window to upper monitor |
| `Super + Shift + Down` | Move window to lower monitor |
| `Super + P` | Switch display mode |

## GNOME — Taskbar Apps

| Shortcut | Action |
|----------|--------|
| `Super + 1..9` | Switch to pinned app 1–9 |
| `Super + Ctrl + 1..9` | Open new window of app 1–9 |

## GNOME — System

| Shortcut | Action |
|----------|--------|
| `Super + A` | Show all applications |
| `Super + V` / `Super + M` | Toggle message tray / notifications |
| `Super + S` | Quick settings panel |
| `Super + N` | Focus notification |
| `Super + L` | Lock screen |
| `Ctrl + Alt + Delete` | Log out |
| `Print` | Screenshot UI |
| `Shift + Print` | Screenshot (full) |
| `Alt + Print` | Screenshot (window) |
| `Ctrl + Shift + Alt + R` | Screen recording |
| `Alt + F2` | Run dialog |

---

## GNOME — Extensions (installed by this repo)

Enabled via `setup/gnome-taskbar.sh` and `setup/gnome-extra-extensions.sh`.
After install you must **log out + back in** (Wayland can't hot-reload the shell).
Manage all of them in the **Extensions** app (`gnome-extensions-app`) or
`gnome-extensions list --enabled`.

### Dash to Panel — `dash-to-panel@jderose9.github.com`
Turns the top bar into a taskbar: clock left, open-window icons centered,
system tray + system menu on the right.

| Shortcut / Action | What it does |
|-------------------|--------------|
| `Super + 1..9` | Focus open window N in the panel |
| `Super + Ctrl + 1..9` | New window of app N |
| Middle-click panel icon | Open new window of that app |
| Right-click panel | Dash-to-Panel settings |

Daily: glance at the centered icons for what's open on the current desktop
(only current desktop — `isolate-workspaces` is on). Tune via
**settings → Position/Style/Behavior**.

### CopyQ Clipboard — `copyq-clipboard@hluk.github.com`
Clipboard-history icon in the top-right; needs the `copyq` app (installed).

| Shortcut / Action | What it does |
|-------------------|--------------|
| Click top-bar icon | Open clipboard history menu |
| `Ctrl + Shift + V` (in CopyQ) | Show CopyQ main window |
| Pick an entry | Copies it back to the clipboard |

Daily: copy as normal, then click the icon (or `Super + Shift + V` cliphist
if you prefer the rofi flow) to paste an older item. Configure shortcut in
`copyq` → Preferences → Shortcuts.

### AppIndicator / KStatusNotifier — `appindicatorsupport@rgcjonas.gmail.com`
Restores legacy system-tray icons (Discord, Steam, Telegram, Nextcloud, …)
in the top-right. No keybindings — apps just appear there.

| Action | What it does |
|--------|--------------|
| Left-click tray icon | App's primary action / show window |
| Right-click tray icon | App's tray menu |

### Tiling Assistant — `tiling-assistant@leleat-on-github`
Keyboard + drag window tiling with a "fill the other half" popup.

| Shortcut | Action |
|----------|--------|
| `Super + Up` | Maximize / restore |
| `Super + Left` / `Right` | Tile to left / right half |
| `Super + Down` | Tile to bottom / un-tile |
| Drag to screen edge | Tile half |
| Drag to a corner | Tile quarter |
| After tiling | Tiling popup shows other windows to fill the rest |
| `Super + KP_1..9` | Tile to that screen region (numpad, if enabled) |

Daily: tile one window with `Super + ←`, then pick the other side from the
popup. Layouts + all keys are editable in **settings → Keybindings**.
(These reuse the native `Super + arrow` snap keys already in this repo.)

### Just Perfection — `just-perfection-desktop@just-perfection`
UI tweaker — no shortcuts, all GUI. Open its settings to:

- Hide/show panel, dash, activities button, app menu, clock, etc.
- Adjust animation speed, startup behavior, workspace switcher
- Quick "Profiles" (Default / Minimal / Super Minimal) on the first tab

Daily: set-and-forget. Revisit settings only when you want to hide an element.

### Caffeine — `caffeine@patapon.info`
Keep-awake toggle (inhibits screen blank + auto-suspend). Top-right icon: empty
cup = normal, full cup = caffeinated. No default shortcut — click the icon.
Settings: auto-enable for specific apps (e.g. fullscreen video), or bind a key
via Settings → Keyboard → Custom Shortcuts to its toggle if wanted.

### Media Controls — `mediacontrols@cliffniff.github.com`
Shows current track + play/pause/skip in the panel for any MPRIS player
(Spotify, browser video, etc.). No keybindings — click the controls. Prefs let
you set panel position, label width, and which sources to show.

---

## GNOME Files (Nautilus)

Large icon view + image thumbnails are the default (Windows-style big tiles).

| Key | Action |
|-----|--------|
| `Ctrl + +` / `Ctrl + -` | Zoom icons bigger / smaller (per folder) |
| `Ctrl + 0` | Reset zoom |
| `Ctrl + 1` / `Ctrl + 2` | Switch to list / grid view |
| `Ctrl + H` | Toggle hidden files |
| `F2` | Rename · `Delete` | Trash |

---

## Power & Battery (TLP)

No keybindings — managed by TLP + GNOME idle settings. Useful commands:

| Command | Shows |
|---------|-------|
| `tlp-stat -s` | TLP status + current mode (AC vs BAT) |
| `tlp-stat -p` | CPU / processor power settings in effect |
| `tlp-stat -b` | battery info + charge thresholds |
| `powertop` | live power draw + extra tunables (run on battery) |
| `sudo tlp start` | re-apply config after editing `/etc/tlp.d/` |

Config drop-in: `setup/tlp/01-battery-saver.conf`. On battery: turbo off,
governor powersave, Wi-Fi/audio power save. On AC: full performance. GNOME
blanks the screen at 3 min and suspends at 10 min (battery) / 30 min (AC).

---

## Rofi — App Launcher

> Triggered by `Ctrl + Space`

| Key | Action |
|-----|--------|
| `Type...` | Fuzzy search apps |
| `Enter` | Launch selected |
| `Up / Down` | Navigate results |
| `Tab` | Switch mode (drun → run → window → files) |
| `Escape` | Dismiss |
| `Ctrl + F` | Search within rofi |

---

## WezTerm — Pane Management

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + D` | Split pane horizontal (side by side) |
| `Ctrl + Shift + E` | Split pane vertical (top/bottom) |
| `Ctrl + Shift + X` | Close current pane |
| `Ctrl + Shift + Enter` | Toggle zoom (fullscreen pane) |

## WezTerm — Pane Navigation (Vim-style)

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + H` | Focus pane left |
| `Ctrl + Shift + J` | Focus pane down |
| `Ctrl + Shift + K` | Focus pane up |
| `Ctrl + Shift + L` | Focus pane right |

## WezTerm — Pane Resize

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + Alt + H` | Resize pane left |
| `Ctrl + Shift + Alt + J` | Resize pane down |
| `Ctrl + Shift + Alt + K` | Resize pane up |
| `Ctrl + Shift + Alt + L` | Resize pane right |

## WezTerm — Tabs

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + T` | New tab |
| `Ctrl + Shift + W` | Close tab |
| `Ctrl + Tab` | Next tab |
| `Ctrl + Shift + Tab` | Previous tab |
| `Alt + 1..9` | Jump to tab 1–9 |

## WezTerm — General

| Shortcut | Action |
|----------|--------|
| `Ctrl + Shift + C` | Copy to clipboard |
| `Ctrl + Shift + V` | Paste from clipboard |
| `Ctrl + Shift + F` | Search in terminal |
| `Ctrl + Shift + PageUp` | Scroll up half page |
| `Ctrl + Shift + PageDown` | Scroll down half page |
| `Ctrl + =` (or `Ctrl + +`) | Increase font size |
| `Ctrl + -` | Decrease font size |
| `Ctrl + 0` | Reset font size |
| `F11` | Toggle fullscreen (borderless) |
| `Ctrl + Shift + P` | Launch menu (profiles) |
| `Ctrl + Shift + Alt + P` | Command palette |
| `Ctrl + Shift + Z` | Open Zellij in new tab |
| `Ctrl + Click` | Open link under cursor |

> WezTerm **starts maximized** (fills the screen) on every launch. Use `F11`
> for borderless fullscreen, `Super + Up` to un-maximize back to a window.

## WezTerm — Launch Menu Profiles

> Triggered by `Ctrl + Shift + P`. The default shell is **Zsh** (`default_prog`),
> so a plain new tab/window opens Zsh; this menu picks any of the others.

| Profile | Description |
|---------|-------------|
| Zsh | Default login shell (autosuggestions, syntax highlighting) |
| Bash | Alternative login shell |
| Zellij | Terminal multiplexer session |
| Zellij (new) | Named zellij session "work" |
| Python REPL | Python 3.12 interactive |
| Node REPL | Node 24 interactive |
| btop | System monitor |

---

## Zellij — Terminal Multiplexer

> Prefix key: `Ctrl + A` (then release and press the action key)

| Shortcut | Action |
|----------|--------|
| `Ctrl + A` | Enter command mode |
| `Ctrl + A → H/J/K/L` | Navigate panes (vim-style) |
| `Ctrl + A → N` | Next tab |
| `Ctrl + A → P` | Previous tab |
| `Ctrl + A → C` | New pane |
| `Ctrl + A → X` | Close pane |
| `Ctrl + A → D` | Detach session |
| `Ctrl + A → [` | Enter scroll mode |
| `Ctrl + A → Ctrl + A` | Lock/unlock |

---

## Zsh — Shell (autosuggestions, fuzzy find)

> Configured in `~/.zshrc` (chezmoi `dot_zshrc`). Active in every terminal that
> launches zsh — WezTerm now defaults to zsh, kitty/alacritty/ghostty inherit the
> login shell. Needs pkgs `zsh-autosuggestions` + `zsh-syntax-highlighting`.

| Shortcut | Action |
|----------|--------|
| (type) → grey ghost text | Inline suggestion from history (fish/Warp-style) |
| `→` / `End` | Accept the whole suggestion |
| `Ctrl + Space` | Accept suggestion — **but** GNOME grabs `Ctrl+Space` globally for rofi, so it fires the launcher first. Use `→`/`End`, or rebind rofi to `Super+Space`. |
| `Ctrl + T` | Fuzzy file search (fzf + fd, bat preview) |
| `Ctrl + R` | Fuzzy history search |
| `Alt + C` | Fuzzy `cd` into a subdirectory |
| `Tab` | Menu completion (arrow-select) |
| valid cmd = green / bad = red | Live syntax highlighting as you type |

---

## Quick Reference Card

```
╔══════════════════════════════════════════════════════════════╗
║  LAUNCH             WINDOWS            WORKSPACES           ║
║  Ctrl+Space  Rofi   Super+Q    Close   Super+[  Prev WS    ║
║  Super+Ret Terminal Super+Up   Max     Super+]  Next WS    ║
║  Super+B  Browser   Super+Down Min     Super+Home First    ║
║  Super+E  Files     Super+←/→  Snap    Super+End  Last     ║
║  Super+\  SSH menu  Alt+Tab    Switch                      ║
║                                                             ║
║  WEZTERM PANES      WEZTERM TABS       ZELLIJ              ║
║  C+S+D  Split H     C+S+T  New tab    Ctrl+A  Prefix      ║
║  C+S+E  Split V     C+S+W  Close tab  +H/J/K/L Navigate   ║
║  C+S+HJKL Navigate  C+Tab  Next tab   +N/P  Next/Prev tab ║
║  C+S+Enter Zoom     Alt+#  Jump to #  +C  New pane        ║
║  C+S+X  Close pane  C+S+P  Profiles   +X  Close pane      ║
╚══════════════════════════════════════════════════════════════╝
  C+S = Ctrl+Shift  |  Super = Windows key  |  # = number key
```

---

## Known Quirks — GNOME Wayland (why XWayland)

GNOME's compositor (Mutter) does **not** implement the `wlr-layer-shell`
protocol and ships an **explicit-sync** path that older app builds mishandle.
Two apps therefore run on **XWayland** instead of native Wayland:

| App | Native-Wayland failure | Fix in repo |
|-----|------------------------|-------------|
| **rofi** | `Rofi on wayland requires support for the layer shell protocol` (aborts) | `env -u WAYLAND_DISPLAY` → X11 backend |
| **rofi** | opens but `Esc`/typing dead — Mutter won't focus an XWayland override-redirect popup (mouse-click still works) | add `-normal-window` so it's a managed window that gets keyboard focus |
| **wezterm** | `wp_linux_drm_syncobj_surface_v1 ... Protocol error (os error 71)` crash on launch | `config.enable_wayland = false` in `dot_wezterm.lua` → XWayland |

Both are applied automatically by `chezmoi apply`. Trade-off: XWayland loses
native fractional-scaling/HiDPI niceties, but the apps actually start.

---

## Memorize in This Order (frequency tiers)

Learn top-down. Each tier is the ~5 keys you'll hit most before the next.

**Tier 1 — daily, every session**

| Key | Action |
|-----|--------|
| `Ctrl + Space` | Open app launcher (rofi) |
| `Ctrl + Shift + D` / `E` | Split pane H / V |
| `Ctrl + Shift + H/J/K/L` | Move between panes |
| `Ctrl + Shift + T` / `W` | New / close tab |
| `Ctrl + Shift + C` / `V` | Copy / paste |

**Tier 2 — many times a day**

| Key | Action |
|-----|--------|
| `Ctrl + Tab` / `Ctrl + Shift + Tab` | Next / prev tab |
| `Alt + 1..9` | Jump to tab N |
| `Ctrl + Shift + Enter` | Zoom (maximize) pane |
| `Ctrl + Shift + X` | Close pane |
| `Super + [` / `]` | Prev / next workspace |

**Tier 3 — handy, weekly**

| Key | Action |
|-----|--------|
| `Ctrl + Shift + P` | Launch-menu profiles (Bash/Zsh/Zellij/REPLs) |
| `Ctrl + Shift + Z` | Zellij in new tab |
| `Ctrl + Shift + F` | Search scrollback |
| `Ctrl + Shift + Alt + H/J/K/L` | Resize pane |
| `Ctrl + + / - / 0` | Font bigger / smaller / reset |

**Tier 4 — occasional**

| Key | Action |
|-----|--------|
| `Ctrl + Shift + Alt + P` | Command palette |
| `Ctrl + Shift + PageUp/PageDown` | Scroll half page |
| `F11` | Fullscreen |
| `Ctrl + Click` | Open link under cursor |
| `Super + Q` | Close window (GNOME) |

