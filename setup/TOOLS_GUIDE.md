# Developer Tools Guide — Why, How, and Usage

Everything installed on this machine, why it's here, how it works, and how we use it in our projects.

**Machine:** Rocky Linux 10.1 (x86_64)
**Date:** 2026-05-26

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    YOUR DEV MACHINE                          │
│                                                              │
│  chezmoi ──── manages ────► All dotfiles (configs below)     │
│  mise ─────── manages ────► All language runtimes            │
│                                                              │
│  ┌─── Shell Layer ──────────────────────────────────────┐   │
│  │  .bashrc / .zshrc                                     │   │
│  │    ├── mise activate (loads Python/Node/Go)           │   │
│  │    ├── starship init (prompt)                         │   │
│  │    ├── zoxide init (smart cd)                         │   │
│  │    ├── fzf (fuzzy finder)                             │   │
│  │    └── conda init (ML environments)                   │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─── Terminal Layer ───────────────────────────────────┐   │
│  │  WezTerm (terminal emulator)                          │   │
│  │    └── Zellij (multiplexer) OR tmux (fallback)        │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─── Editor Layer ─────────────────────────────────────┐   │
│  │  Neovim (code editing)                                │   │
│  │  VS Code (IDE)                                        │   │
│  │  lazygit (git TUI)                                    │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─── Runtime Layer (all via mise) ─────────────────────┐   │
│  │  Python 3.12  │  Node 24 LTS  │  Go 1.26             │   │
│  │  yarn, pnpm   │  pip           │                      │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Tools (The Two Pillars)

### 1. mise — Language Version Manager

**What:** Single tool that manages Python, Node.js, Go, and 500+ other runtimes.
**Why:** Replaces pyenv, nvm, goenv, sdkman, and manual tarball installs. One config file defines all your tool versions. Switch between project-specific versions automatically.
**Config:** `~/.config/mise/config.toml`

```toml
[tools]
python = "3.12"
node = "lts"
go = "latest"
```

**How we use it in projects:**

```bash
# Check what's installed
mise ls

# Install a new tool globally
mise use --global rust@latest

# Use a different Python version for one project
cd my-project
mise use python@3.11       # creates .mise.toml in project dir
mise install               # installs that version

# See all available versions
mise ls-remote python

# Update everything
mise upgrade
```

**Per-project config:** Drop a `.mise.toml` in any project directory. When you `cd` into it, mise auto-switches versions:

```toml
# my-project/.mise.toml
[tools]
python = "3.11"
node = "22"
```

**Installed versions on this machine:**
- Python 3.12.13
- Node.js v24.16.0 (LTS)
- Go 1.26.3
- yarn 1.22.22
- pnpm 11.3.0

---

### 2. chezmoi — Dotfiles Manager

**What:** Manages all your config files across machines from a single Git repo.
**Why:** When you set up a new machine, one command pulls all your configs. Edit a config, push it, and every machine stays in sync. Supports templates for machine-specific differences.
**Config:** `~/.local/share/chezmoi/` (source directory)

**How we use it in projects:**

```bash
# See what chezmoi manages
chezmoi managed

# See what would change
chezmoi diff

# Apply all configs
chezmoi apply -v

# Edit a config file (edits the source, then applies)
chezmoi edit ~/.config/starship.toml

# Add a new config to tracking
chezmoi add ~/.config/some-tool/config.yml

# Push changes to GitHub
chezmoi cd    # cd into source dir
git add -A && git commit -m "update starship config"
git push

# ON A NEW MACHINE — one command sets everything up:
chezmoi init --apply SathishKumarAI/Dotfiles
```

**Files managed by chezmoi on this machine:**

| Source (chezmoi) | Target (actual path) |
|------------------|---------------------|
| `dot_bashrc` | `~/.bashrc` |
| `dot_zshrc` | `~/.zshrc` |
| `dot_gitconfig` | `~/.gitconfig` |
| `dot_tmux.conf` | `~/.tmux.conf` |
| `dot_wezterm.lua` | `~/.wezterm.lua` |
| `private_dot_config/starship.toml` | `~/.config/starship.toml` |
| `private_dot_config/zellij/config.kdl` | `~/.config/zellij/config.kdl` |
| `private_dot_config/nvim/init.lua` | `~/.config/nvim/init.lua` |
| `private_dot_config/lazygit/config.yml` | `~/.config/lazygit/config.yml` |
| `private_dot_config/mise/config.toml` | `~/.config/mise/config.toml` |

---

## Shell & Terminal Tools

### 3. Starship — Cross-Shell Prompt

**What:** Blazing-fast prompt written in Rust. Shows git branch, Python version, Node version, conda env, command duration, and more.
**Why:** Works in bash AND zsh (same config). Beautiful, fast, informative. Your config uses Catppuccin Mocha theme.
**Config:** `~/.config/starship.toml`

**How it works in your setup:**
- `.bashrc` and `.zshrc` both call `eval "$(starship init <shell>)"`
- The prompt auto-detects your current directory's language and shows relevant version info
- Catppuccin Mocha color palette is defined in the config

**Key features in your config:**
- OS icon detection (shows Rocky/Fedora/Ubuntu icon)
- Git branch + status in yellow
- Python version + virtualenv name in green
- Conda environment in sapphire blue
- Command duration tracking (notifies after 45s commands)

---

### 4. Zellij — Terminal Multiplexer

**What:** Modern terminal multiplexer (like tmux but with a better UX). Split panes, tabs, sessions.
**Why:** Work on multiple terminal tasks side-by-side. Detach/reattach sessions. Better default keybindings than tmux.
**Config:** `~/.config/zellij/config.kdl`

**How we use it in projects:**

```bash
# Start a new session
zellij

# Start a named session (e.g., for a specific project)
zellij -s rag-project

# List sessions
zellij list-sessions

# Attach to an existing session
zellij attach rag-project

# Key bindings (your config uses Ctrl+a prefix):
#   Ctrl+a then h/j/k/l  → navigate panes
#   Ctrl+a then n/p       → next/prev tab
#   Ctrl+a then c         → new pane
#   Ctrl+a then x         → close pane
#   Ctrl+a then d         → detach
```

---

### 5. tmux — Terminal Multiplexer (Fallback)

**What:** The classic terminal multiplexer. Included as a fallback since it's available everywhere.
**Why:** Some remote servers don't have Zellij. tmux is ubiquitous. Our config mirrors Zellij's Ctrl+a prefix for muscle memory.
**Config:** `~/.tmux.conf`

**Key features in your config:**
- Ctrl+a prefix (matches Zellij)
- Vim-style pane navigation (h/j/k/l)
- Split with `|` (horizontal) and `-` (vertical)
- Mouse support enabled
- Catppuccin Mocha-inspired status bar

---

### 6. WezTerm — Terminal Emulator

**What:** GPU-accelerated terminal emulator written in Rust. Config is Lua (not YAML).
**Why:** Fast rendering, built-in multiplexing, cross-platform (your config handles Windows/WSL/Linux).
**Config:** `~/.wezterm.lua`

**Key features in your config:**
- Catppuccin Mocha color scheme
- JetBrainsMono Nerd Font with fallbacks
- Semi-transparent window (53% opacity)
- Launch menu: Git Bash, WSL, PowerShell, Conda, Zellij
- Vim-style pane navigation (Ctrl+Shift+h/j/k/l)
- Tab bar at bottom, hidden when single tab

---

### 7. zoxide — Smart `cd`

**What:** Remembers directories you visit. Type `z project` and it jumps to `/home/deva/coding/SathishKumarAI/project`.
**Why:** Faster than `cd ../../../some/deep/path`. Learns your habits over time.
**No config file** — it's activated in `.bashrc` and `.zshrc`.

**How we use it:**

```bash
z coding          # jumps to /home/deva/coding
z rag             # jumps to most-visited dir matching "rag"
z dotfiles        # jumps to the Dotfiles repo
zi                # interactive picker with fzf
```

---

## Editor & Git Tools

### 8. Neovim — Text Editor

**What:** Modern Vim. Lua-based config, LSP support, fast startup.
**Why:** Terminal-native editing, works over SSH, highly extensible. Used as the default editor for git commits, lazygit, etc.
**Config:** `~/.config/nvim/init.lua`

**Key features in your config:**
- Space as leader key
- Relative line numbers
- System clipboard integration
- `<Space>w` to save, `<Space>q` to quit, `<Space>e` for file explorer
- Ctrl+h/j/k/l for window navigation
- Visual mode J/K to move lines up/down
- Centered scrolling (Ctrl+d/u stay centered)

**How we use it:**

```bash
nvim file.py         # edit a file
v file.py            # alias for nvim
```

---

### 9. lazygit — Git TUI

**What:** Terminal UI for git. Staging, committing, branching, rebasing — all with keyboard shortcuts.
**Why:** Faster than typing git commands for complex operations. Visual diff, interactive rebase, cherry-pick.
**Config:** `~/.config/lazygit/config.yml`

**Key features in your config:**
- Catppuccin Mocha theme
- Nerd Fonts v3 icons
- Neovim as editor
- File tree view enabled

**How we use it:**

```bash
lg                   # alias for lazygit
# Then:
#   Space     → stage/unstage file
#   c         → commit
#   P         → push
#   p         → pull
#   b         → branches
#   s         → stash
```

---

### 10. GitHub CLI (`gh`)

**What:** GitHub's official CLI. Create PRs, manage issues, auth, clone repos.
**Why:** Already authenticated on this machine. Used for cloning private repos, creating PRs from the terminal.

**How we use it:**

```bash
gh repo clone SathishKumarAI/RAG     # clone a repo
gh pr create                          # create a PR
gh pr list                            # list PRs
gh issue list                         # list issues
gh auth status                        # check auth
```

---

## Dotfile-by-Dotfile Reference

### `.bashrc` — Bash Shell Config

**Location:** `~/.bashrc`
**Loads:** mise, starship, zoxide, fzf, conda

| Section | What | Why |
|---------|------|-----|
| `mise activate bash` | Loads Python/Node/Go into PATH | So `python3`, `node`, `go` resolve to mise-managed versions |
| `starship init bash` | Activates the fancy prompt | Shows git, python version, conda env |
| `zoxide init bash` | Enables `z` command | Smart directory jumping |
| `fzf --bash` | Fuzzy finder keybindings | Ctrl+R for fuzzy history search |
| `conda.sh` | Conda activation | `conda activate myenv` for ML work |
| Aliases | `lg`, `v`, `g`, `dc`, `gs`, `gl`, etc. | Less typing for common commands |

---

### `.zshrc` — Zsh Shell Config

**Location:** `~/.zshrc`
**Same tools as `.bashrc` plus:**

| Section | What | Why |
|---------|------|-----|
| History config | 10k lines, dedup, shared across sessions | Never lose a command |
| Emacs keybindings | Arrow keys search history | Type `git` then up-arrow to find recent git commands |
| Completion | Case-insensitive, menu-select | Tab completion with visual menu |

---

### `.gitconfig` — Git Configuration

**Location:** `~/.gitconfig`

| Section | What | Why |
|---------|------|-----|
| `[user]` | Name + email | Identifies you in commits |
| `defaultBranch = main` | New repos start with `main` | Modern default |
| `editor = nvim` | Neovim for commit messages | Consistent with our editor choice |
| `pull.rebase = true` | Rebase on pull instead of merge | Cleaner git history |
| `push.autoSetupRemote = true` | Auto-track remote branch | No more `git push -u origin branch` |
| `merge.conflictstyle = diff3` | Show base in merge conflicts | Easier conflict resolution |
| `[alias]` | `st`, `co`, `br`, `lg`, etc. | Common shortcuts |
| `[credential]` | gh auth git-credential | GitHub auth via `gh` CLI |

---

### `.config/mise/config.toml` — Runtime Versions

**Location:** `~/.config/mise/config.toml`

```toml
[tools]
python = "3.12"    # For RAG, ML projects, scripts
node = "lts"       # For Personal-Portfolio (TypeScript), web tools
go = "latest"      # For CLI tools, infrastructure work
```

**Why these versions:**
- Python 3.12: Latest stable, used by all your AI/ML repos (RAG, Pickleball-Vision-LLM, Medical-Research)
- Node LTS: Stable for your TypeScript portfolio and web projects
- Go latest: For building CLI tools and any Go projects

---

### `.config/starship.toml` — Prompt Config

**Location:** `~/.config/starship.toml`
**Theme:** Catppuccin Mocha

Shows: OS icon > username > directory > git branch/status > language version > conda env > time > command duration

---

### `.config/zellij/config.kdl` — Zellij Config

**Location:** `~/.config/zellij/config.kdl`
**Prefix:** Ctrl+a (changed from default Ctrl+b to avoid Vim conflicts)

---

### `.config/nvim/init.lua` — Neovim Config

**Location:** `~/.config/nvim/init.lua`
**Leader:** Space

Minimal but functional config. No plugin manager yet — add lazy.nvim when you're ready for plugins.

---

### `.config/lazygit/config.yml` — lazygit Config

**Location:** `~/.config/lazygit/config.yml`
**Theme:** Catppuccin Mocha (matches starship, wezterm, tmux)

---

### `.tmux.conf` — tmux Config

**Location:** `~/.tmux.conf`
**Prefix:** Ctrl+a (matches Zellij for muscle memory)
**Theme:** Catppuccin Mocha-inspired status bar

---

### `.wezterm.lua` — WezTerm Config

**Location:** `~/.wezterm.lua`
**Theme:** Catppuccin Mocha
**Font:** JetBrainsMono Nerd Font (with fallbacks)

Cross-platform config — auto-detects Git Bash, WSL, PowerShell on Windows; works natively on Linux.

---

## How It All Connects to Your Projects

### For AI/ML Work (RAG, Pickleball-Vision-LLM, Medical-Research)

```bash
cd ~/coding/SathishKumarAI/RAG
# mise auto-loads Python 3.12 (from global config)
# Add project-specific .mise.toml if needed:
# mise use python@3.11

python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
```

### For Web Dev (Personal-Portfolio)

```bash
cd ~/coding/SathishKumarAI/Personal-Portfolio
# mise auto-loads Node LTS
npm install && npm run dev
```

### For Any New Project

```bash
mkdir new-project && cd new-project
git init
mise use python@3.12 node@22    # creates .mise.toml
# chezmoi already has your git config, editor, prompt working
```

---

## New Machine Setup (Complete Flow)

```bash
# 1. Install the two pillars
curl https://mise.run | sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# 2. Pull all dotfiles + auto-install tools
chezmoi init --apply SathishKumarAI/Dotfiles

# 3. Install runtimes
mise install

# 4. Auth
gh auth login
aws configure

# Done. Everything is configured.
```

---

## Installed Versions Summary

| Tool | Version | Managed By | Purpose |
|------|---------|------------|---------|
| mise | 2026.5.15 | self-update | Language version manager |
| chezmoi | 2.70.4 | self-update | Dotfiles manager |
| Python | 3.12.13 | mise | AI/ML, scripts, data science |
| Node.js | 24.16.0 | mise | Web dev, TypeScript |
| Go | 1.26.3 | mise | CLI tools, infrastructure |
| npm | 11.13.0 | mise (via Node) | Node package manager |
| yarn | 1.22.22 | npm global | Alt Node package manager |
| pnpm | 11.3.0 | npm global | Fast Node package manager |
| Starship | 1.25.1 | binary | Shell prompt |
| Zellij | 0.44.3 | binary | Terminal multiplexer |
| zoxide | 0.9.9 | binary | Smart cd |
| lazygit | 0.61.1 | binary | Git TUI |
| git | 2.47.3 | dnf | Version control |
| gh | 2.87.3 | dnf | GitHub CLI |
| zsh | 5.9 | dnf | Shell |
| tmux | 3.4 | dnf | Terminal multiplexer (fallback) |
| vim | 9.1 | dnf | Text editor (fallback) |
