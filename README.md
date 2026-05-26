# Dotfiles — Cross-Platform Dev Environment

**mise + chezmoi + starship + zellij + neovim**

One repo for all configs, setup scripts, and dev knowledge. Works on Rocky Linux, Fedora, RHEL, and Windows.

---

## Quick Start (New Machine)

```bash
# 1. Install chezmoi + apply all configs
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply SathishKumarAI/Dotfiles

# 2. Install mise + all runtimes
curl https://mise.run | sh
mise install

# 3. Full system setup (Rocky Linux)
sudo bash setup/rocky-dev-setup-custom.sh

# Done.
```

---

## Repo Structure

```
Dotfiles/
│
├── chezmoi/                    # Dotfile source (chezmoi format)
│   ├── dot_bashrc              # → ~/.bashrc
│   ├── dot_zshrc               # → ~/.zshrc
│   ├── dot_gitconfig           # → ~/.gitconfig
│   ├── dot_tmux.conf           # → ~/.tmux.conf
│   ├── dot_wezterm.lua         # → ~/.wezterm.lua
│   └── private_dot_config/
│       ├── starship.toml       # → ~/.config/starship.toml
│       ├── zellij/config.kdl   # → ~/.config/zellij/config.kdl
│       ├── nvim/init.lua       # → ~/.config/nvim/init.lua
│       ├── lazygit/config.yml  # → ~/.config/lazygit/config.yml
│       └── mise/config.toml    # → ~/.config/mise/config.toml
│
├── setup/                      # Machine setup scripts + docs
│   ├── rocky-dev-setup.sh      # Original setup script
│   ├── rocky-dev-setup-custom.sh  # Customized (mise + chezmoi)
│   ├── chezmoi-migration.sh    # Migrate existing configs to chezmoi
│   ├── .mise.toml              # Project runtime versions
│   ├── SCRIPT_EXPLAINED.md     # Setup script deep-dive
│   ├── TOOLS_GUIDE.md          # All tools: why, how, usage
│   ├── CLAUDE_TOOLS_GUIDE.md   # Claude Code + SDK setup
│   ├── APPS_GUIDE.md           # GUI apps (Obsidian, VS Code, etc.)
│   └── OPEN_SOURCE_TOOLS.md    # 30+ tools compared
│
├── vault/                      # Obsidian knowledge base
│   ├── Home.md                 # Dashboard
│   ├── tools/                  # Tool documentation
│   ├── projects/               # Project notes
│   ├── daily/                  # Daily dev logs
│   └── templates/              # Note templates
│
├── dotfiles/                   # Legacy configs (Windows)
│   ├── starship/starship.toml
│   ├── wizterm/.wezterm.lua
│   ├── Zellij/config.kdl
│   └── windows_setup/
│
├── assets/                     # Images, cheatsheets
├── tools/                      # Helper scripts
└── TOOLS_LINKS.md              # Official tool links
```

---

## What's Managed

### Runtimes (via mise)
| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.12 | AI/ML, data science, scripts |
| Node.js | LTS | Web dev, TypeScript |
| Go | latest | CLI tools |

### Dotfiles (via chezmoi)
| Config | Theme | Purpose |
|--------|-------|---------|
| `.bashrc` | — | Shell: mise, starship, zoxide, conda, aliases |
| `.zshrc` | — | Zsh: same + completion + history |
| `.gitconfig` | — | Git: aliases, rebase pull, diff3 merge |
| `starship.toml` | Catppuccin Mocha | Prompt: git, python, conda, OS icon |
| `zellij/config.kdl` | — | Multiplexer: Ctrl+a prefix |
| `.tmux.conf` | Catppuccin Mocha | Fallback multiplexer |
| `.wezterm.lua` | Catppuccin Mocha | Terminal: GPU, splits, launch menu |
| `nvim/init.lua` | — | Editor: space leader, vim keymaps |
| `lazygit/config.yml` | Catppuccin Mocha | Git TUI |
| `mise/config.toml` | — | Runtime versions |

### Apps (Flatpak)
Obsidian, VS Code, DBeaver, Postman, Podman Desktop, Logseq, draw.io

---

## Documentation

| Guide | What's In It |
|-------|-------------|
| [setup/TOOLS_GUIDE.md](setup/TOOLS_GUIDE.md) | Every tool: why it's here, how to use it, config reference |
| [setup/SCRIPT_EXPLAINED.md](setup/SCRIPT_EXPLAINED.md) | Setup script breakdown, risk flags, safe testing |
| [setup/CLAUDE_TOOLS_GUIDE.md](setup/CLAUDE_TOOLS_GUIDE.md) | Claude Code, SDKs, token-saving, permissions, memory |
| [setup/APPS_GUIDE.md](setup/APPS_GUIDE.md) | GUI apps: what, why, how to launch |
| [setup/OPEN_SOURCE_TOOLS.md](setup/OPEN_SOURCE_TOOLS.md) | 30+ open-source alternatives compared |

---

## Theme

**Catppuccin Mocha** everywhere: starship, wezterm, lazygit, tmux.
Consistent dark palette across all tools.
