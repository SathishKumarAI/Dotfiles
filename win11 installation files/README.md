# Dev & AI Engineer App Manager — Windows Setup Tool

A visual, one-command setup tool for fresh Windows 11 installs.  
Select your apps, click **Install**, and walk away. Everything happens automatically.

---

## Why does this exist?

Setting up a fresh Windows machine as a developer is painful:

- You forget half the tools you need until you try to use them
- Installing one-by-one through browser downloads takes hours
- You end up with mismatched versions across machines
- Every time you reinstall Windows, you start from zero

This tool solves all of that. It knows every app you need, checks what's already installed, and installs the rest — all from one screen.

---

## Quick Start (3 steps)

### Step 1 — Install Python (if you don't have it)
Download from: https://www.python.org/downloads/  
Make sure to check **"Add Python to PATH"** during install.

### Step 2 — Install dependencies (one time only)
Open a terminal in this folder and run:
```
pip install requests rich textual
```

### Step 3 — Run the app
```
python run.py
```

That's it. The visual interface opens and you can start selecting and installing.

---

## What the Screen Looks Like

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  Dev & AI App Manager                                            12:34:56    │
├─────────────────────────────────┬──────────────────┬───────────┬─────────────┤
│  🔍 Search apps…                │ 👤 Default       │ ⚙ Settings│ ➕ Add  📋  │
├────────────────────────────────────────────────────┬────────────────────────┤
│  All Apps │ ★ Essential │ ◆ Recommended │ 🤖 AI … │  📋 Activity Log  ◀ ▶ ×│
│ ─────────────────────────────────────────────────  │──────────────────────── │
│ ☐ ★ VS Code          Editors      ✓ 1.88    OK    │ 12:34 Welcome!          │
│ ☑ ★ Git              Version Ctrl ✗ —       Miss  │ 12:34 Selected: Git     │
│ ☐ ◆ Docker Desktop   DevOps       ✓ 4.29    OK    │ 12:35 ⟳ Checking...    │
│ ☐ ◆ Cursor (AI ed.)  Editors      ✗ —       Miss  │ 12:35  [1/4] VS Code    │
│ ☐ ◇ Neovim           Editors      ✗ —       Miss  │ 12:35  ✓ Installed      │
│ …                                                  │ 12:35  [2/4] Git        │
│                                                    │ 12:35  ✓ Installed      │
├────────────────────────────────────────────────────│                         │
│  ☑ Select All  ☐ Clear Selection  🔴 Select Missing│  Installed: 31          │
│  1 app selected · I install · E clear              │  Missing:    6          │
├────────────────────────────────────────────────────│  Updates:    2          │
│  ▶ Install Selected  🔴 Install Missing  🗂 By Cat │  Free disk: 142.3 GB   │
│  ◉ Install by Profile                             │ ─────────────────────── │
├───────────────────────────────────────────────────┤  ⊘ Clear Log            │
│  ⟳ Check Installed  ⬆ Check Updates  🌐 Website  │                         │
│  📊 Disk Audit                                    │                         │
├────────────────────────────────────────────────────┴─────────────────────────┤
│  Profile: Default  │  47 apps  │  Installed: 31  │  Missing: 6  │  Free: 142G│
└──────────────────────────────────────────────────────────────────────────────┘
  i Install  m Missing  c Check  u Updates  o Website  Space Select  a All  q Quit
```

---

## All the Buttons Explained

### Top Bar
| Button | What it does |
|--------|-------------|
| 🔍 Search | Type to filter apps by name, category, or note |
| 👤 Profile | Switch between install profiles (minimal, full, AI, etc.) |
| ⚙ Settings | Toggle preferences (confirm before install, show skip tier…) |
| ➕ Add App | Add your own custom app to the list |
| 📋 Log | Show or hide the activity sidebar |

### Install Actions (Row 1)
| Button | What it does |
|--------|-------------|
| ▶ Install Selected | Installs only the apps you have ticked (☑) |
| 🔴 Install Missing | Finds every app with ✗ Not Installed and installs them all |
| 🗂 Install by Category | Pick a category (Dev Tools, Databases…) and install everything in it |
| ◉ Install by Profile | Install all apps in the active profile's tiers at once |

### Check / Info Actions (Row 2)
| Button | What it does |
|--------|-------------|
| ⟳ Check Installed | Scans your machine — shows what's installed and what's missing |
| ⬆ Check for Updates | Goes online and compares your versions to the latest releases |
| 🌐 Open Download Page | Opens the official download page for the focused app |
| 📊 Disk Audit | Estimates how much disk space each tier of apps uses |

### Selection Bar
| Button | What it does |
|--------|-------------|
| ☑ Select All | Ticks all apps visible in the current tab |
| ☐ Clear Selection | Unticks everything |
| 🔴 Select Missing | Automatically ticks every app that isn't installed yet |

---

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` or click | Select / deselect the focused app |
| `A` | Select all apps in the current tab |
| `E` | Clear all selections |
| `I` | Install selected apps |
| `M` | Install all missing apps |
| `C` | Check what's installed on this machine |
| `U` | Check for updates online |
| `O` | Open the download page for the focused app |
| `P` | Switch profile |
| `Ctrl + B` | Toggle activity log sidebar on/off |
| `Ctrl + ←` | Shrink the activity log sidebar |
| `Ctrl + →` | Expand the activity log sidebar |
| `Q` | Quit |

---

## The Activity Log Sidebar

The sidebar on the right shows **everything that's happening in real time**:

- Which app is currently being checked or installed
- Install progress: `[3/12] Docker Desktop… ✓ Installed (4.29)`
- Version comparison results when checking for updates
- Selection changes
- Disk usage breakdown

**Resizing the sidebar:**
- Click `▶` in the sidebar header to make it wider
- Click `◀` to shrink it
- Click `×` or press `Ctrl+B` to hide it completely
- Press `Ctrl+B` again to bring it back

---

## App Tiers — What Gets Installed

Apps are grouped into 4 priority levels:

| Symbol | Tier | Meaning |
|--------|------|---------|
| ★ | **Essential** | Must-have tools. Every machine needs these. |
| ◆ | **Recommended** | Strongly suggested. Most developers need these. |
| ◇ | **Optional** | Install if your stack requires them. |
| ○ | **Skip** | Not recommended — listed for awareness only. |

### Categories
Apps are also grouped by category:

- **Editors & IDEs** — VS Code, Cursor, Neovim, Visual Studio
- **Version Control & API** — Git, GitHub CLI, lazygit, Postman, Bruno
- **DevOps & Containers** — Docker Desktop, WSL, kubectl, Terraform, AWS CLI
- **Databases** — DBeaver, PostgreSQL, MongoDB, Redis, vector DBs (Qdrant, Chroma)
- **Runtimes & Languages** — Node.js, Python, Bun, pnpm, Go, Rust
- **AI & LLM Tools** — Claude Code, Ollama, LM Studio, Continue, Cursor
- **Terminal & Shell** — Windows Terminal, Starship, fzf, zoxide, lazygit, ripgrep
- **Productivity** — Obsidian, PowerToys, Everything, Flow Launcher
- **Communication** — Slack, Discord, Zoom

---

## Install Profiles

Profiles let you install the right set of apps for a specific machine or use case without manually picking apps each time.

| Profile | Apps included | Best for |
|---------|--------------|---------|
| **Default** | Essential + Recommended | Most developer machines |
| **Minimal** | Essential only | Lightweight setup or low-disk machines |
| **Full Stack** | All tiers | Complete workstation setup |
| **AI Engineer** | Essential + Recommended + AI tag | AI/ML development focus |
| **Machine 1** | machine1-tagged apps | Your home laptop config |
| **Machine 2** | machine2-tagged apps | Your work desktop config |

Switch profiles with `P` or the **👤 Profile** button.

---

## Adding Your Own Apps

1. Click **➕ Add App** in the top bar
2. Fill in:
   - **App name** — what you want to call it
   - **Category** — which group it belongs to
   - **winget ID** — the package ID from `winget search <name>` (optional)
   - **Version check command** — e.g. `mytool --version` (optional)
   - **Download page URL** — where to get it if winget fails
   - **Note** — why you need it
3. Click **💾 Save**

Custom apps appear in the **📦 Custom** tab and are saved to:
```
~/.dev-manager/custom_apps.json
```
You can edit that file directly too.

---

## How it Makes Fresh Installs Easy

### The Old Way (without this tool)
1. Fresh Windows install — blank machine
2. Open browser, search "download VS Code", install it
3. Repeat for Git, Docker, Node, Python, GitHub CLI, …
4. Forget half the tools you need
5. Realise 3 days later you're missing zoxide / fzf / starship
6. Version mismatches between machines

### The New Way (with this tool)
1. Fresh Windows install
2. `pip install requests rich textual`
3. `python run.py`
4. Press `C` to check what's missing
5. Press `M` to install everything missing, or `◉` to install by profile
6. Walk away. Come back to a fully set up machine.

### Local Deployment Use Case

This tool is designed to work **completely offline-installable** once the packages are on the machine, and **without admin rights** for most apps (via winget).

For a team or repeated fresh installs:
1. Keep this folder (`win11 installation files/`) on a USB drive or shared folder
2. On a new machine: copy the folder, run `pip install requests rich textual`, then `python run.py`
3. Select your profile and install

The app stores your preferences and custom apps in `~/.dev-manager/` which you can back up and restore across machines by copying that folder.

---

## Command-Line Mode (no visual UI)

If you prefer the terminal or are running headlessly:

```bash
# Check what's installed
python run.py --check

# Install essential + recommended apps
python run.py --install

# Install only AI tools
python run.py --ai

# Check for updates online
python run.py --update

# List all apps with tiers
python run.py --list

# Target a specific app
python run.py --install --app "Docker Desktop"

# Target by tier
python run.py --install --tier essential

# Disk usage audit
python run.py --audit
```

---

## File Structure

```
win11 installation files/
│
├── run.py          ← Entry point. Run this.
│
├── files/
│   ├── run.py      ← CLI + TUI launcher (main logic)
│   ├── tui.py      ← Visual interface (Textual TUI)
│   ├── data.py     ← App registry (all 47+ apps defined here)
│   ├── core.py     ← Install, version-check, winget wrappers
│   └── config.py   ← Profiles, preferences, custom apps
│
└── README.md       ← This file
```

### Key files explained

**`data.py`** — The master app list. Each app entry has:
- `name`, `category`, `tier` — display info
- `winget_id` — used for automatic install and version check
- `check_cmd` — command to detect if it's installed
- `version_url` — GitHub/other API endpoint for update checks
- `web_url` — fallback download page
- `approx_mb` — used for disk audit
- `tags` — e.g. `["ai", "machine1"]` for filtering
- `note` — why this app is (or isn't) recommended

**`core.py`** — All the system calls: runs `winget install`, reads registry, checks versions.

**`config.py`** — Reads/writes `~/.dev-manager/config.json`. Handles profiles, preferences, disabled/pinned apps, and custom app storage.

**`tui.py`** — The full Textual-powered visual interface with resizable sidebar, live activity log, and all the action buttons.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `ModuleNotFoundError: textual` | Run `pip install textual` |
| `ModuleNotFoundError: requests` | Run `pip install requests rich` |
| winget not found | Install from Microsoft Store: search "App Installer" |
| App shows "Not installed" but it is | Check `check_cmd` in `data.py` — command might be named differently on your system |
| Install fails for a specific app | The `🌐 Open Download Page` button opens the official site to install manually |
| Sidebar text is cut off | Click `▶` in the sidebar header or press `Ctrl+→` to widen it |
| App not in the list | Use `➕ Add App` to add it as a custom app |

---

## Requirements

- Windows 10 or Windows 11
- Python 3.10 or newer
- winget (comes with Windows 11; install "App Installer" from the Store on Win10)
- Internet connection for update checks and downloads (not required just to view/check)

---

*Part of the Dotfiles repository — keeps developer machines consistent and quick to set up.*
