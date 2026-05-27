# Keyboard Shortcuts Reference

> Rocky Linux 10.1 | GNOME 47 Wayland | WezTerm | Zellij | Rofi

---

## GNOME — App Launchers (Custom)

| Shortcut | Action |
|----------|--------|
| `Super + T` | Terminal (Ptyxis) |
| `Super + E` | Files (Nautilus) |
| `Super + B` | Browser (Brave) |
| `Super + C` | VS Code |
| `Super + Space` | Rofi App Launcher |

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

## Rofi — App Launcher

> Triggered by `Super + Space`

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
| `Ctrl + Shift + U` | Scroll up half page |
| `Ctrl + Shift + D` | Scroll down half page |
| `Ctrl + +` | Increase font size |
| `Ctrl + -` | Decrease font size |
| `Ctrl + 0` | Reset font size |
| `F11` | Toggle fullscreen |
| `Ctrl + Shift + P` | Launch menu (profiles) |
| `Ctrl + Shift + Alt + P` | Command palette |
| `Ctrl + Shift + Z` | Open Zellij in new tab |
| `Ctrl + Click` | Open link under cursor |

## WezTerm — Launch Menu Profiles

> Triggered by `Ctrl + Shift + P`

| Profile | Description |
|---------|-------------|
| Bash | Default login shell |
| Zsh | Alternative shell |
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

## Quick Reference Card

```
╔══════════════════════════════════════════════════════════════╗
║  LAUNCH             WINDOWS            WORKSPACES           ║
║  Super+Space  Rofi  Super+Q    Close   Super+[  Prev WS    ║
║  Super+T  Terminal  Super+Up   Max     Super+]  Next WS    ║
║  Super+B  Browser   Super+Down Min     Super+Home First    ║
║  Super+E  Files     Super+←/→  Snap    Super+End  Last     ║
║  Super+C  VS Code   Alt+Tab    Switch                      ║
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
