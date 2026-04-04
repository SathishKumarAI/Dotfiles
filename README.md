# Windows Power Developer Environment

**GlazeWM · WezTerm · Starship · Zellij · PowerToys · Conda · Git · WinGet · zoxide**

---

## 1. Overview

This document defines a **modern, keyboard-first Windows developer environment** designed for:

* Long coding sessions
* Multi-project workflows
* Minimal mouse usage
* Predictable layouts
* Reproducible machine setup

The environment combines **tiling window management**, **GPU-accelerated terminals**, **fast prompts**, **session multiplexing**, and **OS-level productivity tools** into a single cohesive workflow.

---

## 2. High-Level Architecture

```text
Windows 10 / 11
├── GlazeWM              → Tiling window manager
├── PowerToys            → OS productivity utilities
├── WezTerm              → Terminal emulator
│    └── Shells
│         ├── PowerShell
│         ├── Git Bash
│         ├── WSL (optional)
│         └── CMD (legacy)
│
│         ├── Starship   → Prompt
│         ├── Conda      → Python environments
│         ├── zoxide     → Fast directory navigation (z)
│         └── Zellij     → Panes & sessions
│
└── Git                  → Version control
```

---

## 3. Core Tooling Stack

| Category             | Tool      |
| -------------------- | --------- |
| Window Manager       | GlazeWM   |
| Terminal Emulator    | WezTerm   |
| Prompt Engine        | Starship  |
| Terminal Multiplexer | Zellij    |
| Directory Navigation | zoxide    |
| OS Productivity      | PowerToys |
| Package Manager      | WinGet    |
| Python Environments  | Conda     |
| Version Control      | Git       |

---

## 4. GlazeWM (Tiling Window Manager)

### Role

* Provides **tiling layouts and workspaces** on Windows
* Enables **keyboard-driven window navigation**

### Key Concepts

* Workspaces (1–9)
* Directional focus & movement
* Window rules per application

### Best Practices

* Launch WezTerm in a dedicated workspace
* Disable conflicting Windows snap shortcuts
* Keep configuration minimal for stability

### References

* [https://blog.markvincze.com/switching-to-the-glazewm-tiling-window-manager-on-windows/](https://blog.markvincze.com/switching-to-the-glazewm-tiling-window-manager-on-windows/)
* [https://github.com/glzr-io/glazewm/blob/main/resources/assets/cheatsheet.png](https://github.com/glzr-io/glazewm/blob/main/resources/assets/cheatsheet.png)

---

## 5. WezTerm (Terminal Emulator)

### Role

* Primary terminal UI
* Hosts all shells consistently
* Launch point for Zellij sessions

### Why WezTerm

* GPU-accelerated rendering
* Lua-based configuration
* Excellent Windows stability
* Strong pane & tab handling

### Responsibilities

* Font rendering
* Clipboard handling
* Pane & tab lifecycle
* Shell launching

### References

* [https://github.com/hendrikmi/dotfiles/tree/main/wezterm](https://github.com/hendrikmi/dotfiles/tree/main/wezterm)
* [https://github.com/josean-dev/dev-environment-files](https://github.com/josean-dev/dev-environment-files)

---

## 6. Starship (Prompt Engine)

### Role

* Unified, fast shell prompt across all shells

### Why Starship

* Rust-based (very fast)
* Single config file
* Cross-shell consistency

### Config Location

```text
~/.config/starship.toml
```

### Notes from This Setup

* Tune `scan_timeout` to avoid slow directory scans
* Disable heavy modules in large repos
* Works cleanly inside Zellij panes

### Prompt Displays

* Git status
* Conda environment
* Execution time
* Directory context

---

## 7. Zellij (Terminal Multiplexer)

### Role

* Manages **panes, tabs, and long-running sessions**
* tmux alternative with better Windows UX

### Why Zellij

* Built-in layouts
* Session persistence
* Keyboard-first workflow

### Usage Pattern

* One session per project
* Tabs for services (API, DB, logs)
* Panes for parallel tasks

### Important Notes

* Exit warnings are informational
* `exit_behavior` controls close behavior
* Do not nest tmux inside Zellij

---

## 8. Conda (Python Environment Management)

### Role

* Manages isolated Python environments

### Integration

* Initialized inside PowerShell and Git Bash
* Displayed in Starship prompt

### Prompt Example

```text
(dice_outreach) user@machine ~/project
```

### Best Practices

* One Conda environment per project
* Activate Conda before launching Zellij
* Avoid mixing Conda with system Python

---

## 9. zoxide (Directory Navigation)

### Role

* Replaces `cd` with a **learning, frequency-weighted jump command**
* Remembers directories you visit and jumps to the best match

### Why zoxide

* No manual bookmarks — adapts to your usage
* Works in PowerShell and Git Bash
* Zero config needed after shell init

### Install

```powershell
winget install ajeetdsouza.zoxide
```

### Shell Initialization

**PowerShell** (`$PROFILE`):

```powershell
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  Invoke-Expression (& { (zoxide init powershell) })
}
```

**Git Bash** (`~/.bashrc`):

```bash
eval "$(zoxide init bash)"
```

### Core Commands

```bash
z project        # jump to best match for "project"
z -              # jump to previous directory
z -l project     # list matches for "project"
```

### Database Location

```text
~/.local/share/zoxide/db.zo
```

---

## 10. PowerToys (OS-Level Productivity)

### Role

Adds native Windows productivity features that **complement GlazeWM**.

### PowerToys Modules Used

**FancyZones**

* Advanced snapping
* Backup layout system

**PowerToys Run (`Alt + Space`)**

* Fast app, file, and command launcher

**Keyboard Manager**

* Remap keys
* Disable conflicting shortcuts

**Always On Top**

* Pin windows (`Win + Ctrl + T`)

**Text Extractor**

* OCR text from screen

**Mouse Utilities**

* Cursor highlighting
* Multi-monitor visibility

**File Locksmith**

* Identify locked files

> Disable unused modules to reduce background load.

---

## 11. WinGet (Package Management)

### Role

* Native Windows package manager
* Enables reproducible installs

### Core Install Commands

```powershell
winget install Microsoft.PowerToys
winget install wez.wezterm
winget install Starship.Starship
winget install Zellij.Zellij
winget install Git.Git
winget install Anaconda.Anaconda3
winget install ajeetdsouza.zoxide
```

### Optional Tools

```powershell
winget install Microsoft.VisualStudioCode
winget install Docker.DockerDesktop
winget install Neovim.Neovim
```

---

## 12. Terminal vs Shell (Critical Concept)

| Component         | Meaning             |
| ----------------- | ------------------- |
| Terminal Emulator | UI application      |
| Shell             | Command interpreter |

Example:

```text
WezTerm → PowerShell → Starship → Conda → Zellij
```

---

## 13. All Terminals & Shells on Windows

### Terminal Emulators

* WezTerm (primary)
* Windows Terminal (secondary)

### Shells

* PowerShell (primary)
* Git Bash
* Conda Prompt (optional)
* Command Prompt (legacy)
* WSL shells (optional)

---

## 14. Git Tooling

### Git Core

```powershell
winget install Git.Git
```

### Git Bash vs PowerShell

| Feature         | Git Bash    | PowerShell |
| --------------- | ----------- | ---------- |
| Unix commands   | Yes         | Limited    |
| Windows tooling | Limited     | Full       |
| Recommended     | Git scripts | Daily work |

---

## 15. Recommended Default Flow

```text
System Boot
 ├── PowerToys
 ├── GlazeWM
 ├── WezTerm
 │    └── PowerShell
 │         ├── Starship
 │         ├── Conda
 │         └── Zellij
```

---

## 16. Dotfiles Structure (Actual)

```text
Dotfiles/
├── scripts/
│   └── bootstrap.ps1                                  ← ONE-SHOT SETUP — run this first
│
├── dotfiles/
│   ├── glazewm/config.yaml                            ← GlazeWM personal config
│   ├── starship/starship.toml                         ← Starship (Catppuccin Mocha powerline)
│   ├── Zellij/
│   │   ├── config.kdl                                 ← Zellij config (Ctrl+a prefix, theme)
│   │   └── layouts/dev.kdl                            ← Dev session layout (3 tabs)
│   ├── wizterm/.wezterm.lua                           ← WezTerm config (Lua)
│   ├── powershell/
│   │   └── Microsoft.PowerShell_profile.ps1           ← PowerShell profile (Starship+zoxide+aliases)
│   ├── bash/
│   │   └── .bashrc                                    ← Git Bash profile (Starship+zoxide)
│   └── windows_setup/
│       ├── env_setup.ps1                              ← Shell env setup (with permission prompts)
│       ├── conda/setup.md                             ← Conda setup guide
│       └── env_path/
│           ├── update_user_path_autodetect_suryadeva.ps1  ← User PATH fix script
│           └── update_user_path_autodetect_suryadeva.md   ← Script documentation
│
├── win11 installation files/                          ← TUI App Manager (see §22)
│   ├── run.py                                         ← Entry point
│   └── files/ core.py · data.py · tui.py · config.py
│
├── md files/
│   ├── zoxide.md                                      ← zoxide deep-dive
│   └── path_fix.md                                    ← PATH recovery guide
│
└── tools/
    └── fetch_env_refs.py                              ← Regenerates TOOLS_LINKS.md
```

---

## 17. Performance & Stability Guidelines

* Tune Starship `scan_timeout`
* Disable unused PowerToys modules
* Avoid overlapping keybindings
* Keep Zellij sessions project-scoped
* Keep WezTerm config modular

---

## 18. Fresh Machine Setup (Bootstrap)

One command sets up everything on a new machine:

```powershell
# Clone the repo first, then from repo root:
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1
```

`bootstrap.ps1` runs 4 steps **with permission prompts at every step**:

| Step | Script | Action |
| ---- | ------ | ------ |
| 1 | (inline) | Install core tools via `winget` |
| 2 | `env_path/update_user_path_autodetect_suryadeva.ps1` | Fix User PATH |
| 3 | `windows_setup/env_setup.ps1` | Configure shells (Starship, zoxide, Conda) |
| 4 | (inline) | Deploy dotfiles to correct locations with backups |

```powershell
# Dry run — see what would happen, no changes:
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -DryRun

# Skip individual steps if already done:
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -SkipApps -SkipPath
```

### Manual env setup only

```powershell
powershell -ExecutionPolicy Bypass -File .\dotfiles\windows_setup\env_setup.ps1
```

### Fix User PATH only

```powershell
# Dry run:
powershell -ExecutionPolicy Bypass -File .\dotfiles\windows_setup\env_path\update_user_path_autodetect_suryadeva.ps1 -DryRun
# Apply:
powershell -ExecutionPolicy Bypass -File .\dotfiles\windows_setup\env_path\update_user_path_autodetect_suryadeva.ps1
```

---

## 19. TUI App Manager (`win11 installation files/`)

A full visual terminal app for managing your dev tools on Windows — installs, version checks, update detection, and disk audit.

### Quick Start

```bash
pip install requests rich textual
python "win11 installation files/run.py"
```

### What It Does

| Action | How |
| ------ | --- |
| Visual TUI with live sidebar | `python run.py` |
| Check installed versions | `python run.py --check` |
| Check for updates online | `python run.py --update` |
| Install all essential + recommended | `python run.py --install` |
| Install AI tools only | `python run.py --ai` |
| Disk usage audit by tier | `python run.py --audit` |

### App Tiers

| Symbol | Tier | Meaning |
| ------ | ---- | ------- |
| ★ | Essential | Must-have — every machine |
| ◆ | Recommended | Strongly suggested |
| ◇ | Optional | Install if your stack needs it |
| ○ | Skip | Listed for awareness only |

### Install Profiles

| Profile | Includes |
| ------- | -------- |
| Default | Essential + Recommended |
| Minimal | Essential only |
| Full Stack | All tiers |
| AI Engineer | Essential + Recommended + AI-tagged apps |
| Machine 1 / 2 | Per-machine tag filtering |

### Categories Covered

Editors & IDEs · Version Control · DevOps/Containers · Databases (incl. vector DBs) · Runtimes · **AI & LLM tools** (Claude Code, Ollama, LM Studio, Aider, Open WebUI) · Terminal/CLI · Productivity · Communication

> See `win11 installation files/README.md` for full documentation.

---

## 20. Reference Links

* WezTerm configs
  [https://github.com/hendrikmi/dotfiles/tree/main/wezterm](https://github.com/hendrikmi/dotfiles/tree/main/wezterm)

* Dev environment files
  [https://github.com/josean-dev/dev-environment-files](https://github.com/josean-dev/dev-environment-files)

* GlazeWM cheatsheet
  [https://github.com/glzr-io/glazewm/blob/main/resources/assets/cheatsheet.png](https://github.com/glzr-io/glazewm/blob/main/resources/assets/cheatsheet.png)

* GlazeWM deep dive
  [https://blog.markvincze.com/switching-to-the-glazewm-tiling-window-manager-on-windows/](https://blog.markvincze.com/switching-to-the-glazewm-tiling-window-manager-on-windows/)

* zoxide GitHub
  [https://github.com/ajeetdsouza/zoxide](https://github.com/ajeetdsouza/zoxide)

---

## 21. What This Setup Achieves

* Keyboard-first development
* Clean separation of responsibilities
* Fast terminal experience
* Predictable layouts
* Easy machine rebuilds
* Reduced cognitive load

---

## 22. Cons of Using This Setup

- **Steep learning curve**  
  GlazeWM, Zellij, and heavy keyboard usage require time to build muscle memory and can slow productivity initially.

- **Windows-specific quirks**  
  Some applications don’t tile cleanly, OS updates may break keybindings, and focus issues can occur with certain apps.

- **Higher maintenance overhead**  
  Multiple tools (WezTerm, Starship, Conda, Zellij) mean more configuration files to manage and troubleshoot.

- **Performance edge cases**  
  Large repositories can slow Starship prompts, and misconfigured plugins or scans may add terminal latency.

- **Toolchain fragility**  
  Version mismatches or breaking changes in upstream tools can impact stability without pinned versions.

- **Reduced portability**  
  This setup may not translate well to teammates’ machines or restricted corporate environments.

- **Debugging complexity**  
  When issues occur, it’s harder to isolate whether the cause is the terminal, shell, prompt, or window manager.

- **Over-optimization risk**  
  Time spent tuning the environment can outweigh productivity gains if not kept minimal and intentional.
