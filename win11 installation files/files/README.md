# Dev & AI Engineer App Manager  v3

A full-featured app manager for Windows developers and AI engineers.

## Setup

```bash
pip install requests rich textual
python run.py
```

## Files

| File | What it does |
|---|---|
| `run.py` | Entry point — launches TUI or CLI |
| `data.py` | All 80+ app definitions with tiers/notes |
| `core.py` | Install, version check, website logic |
| `config.py` | Profiles, custom apps, preferences |
| `tui.py` | Full Textual TUI interface |

Config is saved to `~/.dev-manager/config.json`  
Custom apps go in `~/.dev-manager/custom_apps.json`

## TUI Keybindings

| Key | Action |
|---|---|
| `Space` | Select / deselect app |
| `i` | Install selected apps |
| `c` | Check installed versions |
| `u` | Fetch latest versions online |
| `o` | Open download website |
| `p` | Switch profile |
| `a` | Select all |
| `e` | Deselect all |
| `Ctrl+S` | Settings |
| `q` | Quit |

## CLI Usage

```bash
python run.py                         # TUI (default)
python run.py --cli                   # Force CLI mode
python run.py --list                  # List all apps with tiers
python run.py --check                 # Check installed versions
python run.py --update                # Fetch latest from internet
python run.py --install               # Install by active profile
python run.py --install --tier essential   # Essential only
python run.py --install --all         # Install everything
python run.py --audit                 # Disk space breakdown
python run.py --ai                    # AI tools only
python run.py --app "Docker"          # Single app
python run.py --category "Database"   # By category
```

## Profiles

Switch profiles with `p` in the TUI or by editing `~/.dev-manager/config.json`:

| Profile | What installs |
|---|---|
| Default | Essential + Recommended |
| Machine 1 | M1-tagged apps |
| Machine 2 | M2-tagged apps |
| Minimal | Essential only |
| Full Stack | Essential + Recommended + Optional |
| AI Engineer | AI-tagged apps |

## Adding Custom Apps

Edit `~/.dev-manager/custom_apps.json` or press `+` in the TUI:

```json
[
  {
    "name": "My Tool",
    "category": "Dev Tools",
    "tier": "optional",
    "winget_id": "Publisher.MyTool",
    "check_cmd": ["mytool", "--version"],
    "version_url": null,
    "web_url": "https://example.com",
    "approx_mb": 50,
    "tags": ["custom"],
    "note": "Why I need this"
  }
]
```

## Tier System

- **★ Essential** — Install on every machine, always
- **◆ Recommended** — Great to have, install on most machines  
- **◇ Optional** — Situational, install when needed
- **○ Skip** — Heavy, redundant, or rarely needed
