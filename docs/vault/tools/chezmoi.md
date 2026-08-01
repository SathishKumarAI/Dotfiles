# chezmoi

> Obsidian note. Canonical doc: [`chezmoi.mdx`](../../automation/chezmoi.mdx) —
> update that first; this is the vault-side summary.

**What:** Dotfiles manager. Tracks config files in Git, deploys them across machines.
**Config source:** `~/.local/share/chezmoi/`

## Why We Use It
One command on a new machine pulls all your configs: shell, editor, git, terminal, prompt. Edit once, push, every machine stays in sync.

## Files We Track (10)
| File | Purpose |
|------|---------|
| `.bashrc` | Bash shell config |
| `.zshrc` | Zsh shell config |
| `.gitconfig` | Git settings + aliases |
| `.tmux.conf` | tmux config |
| `.wezterm.lua` | WezTerm terminal |
| `.config/starship.toml` | Starship prompt |
| `.config/zellij/config.kdl` | Zellij multiplexer |
| `.config/nvim/init.lua` | Neovim editor |
| `.config/lazygit/config.yml` | lazygit TUI |
| `.config/mise/config.toml` | Runtime versions |

## Common Commands
```bash
chezmoi managed              # list tracked files
chezmoi diff                 # see pending changes
chezmoi apply -v             # apply all configs
chezmoi edit ~/.bashrc       # edit + apply a file
chezmoi add ~/.config/X      # start tracking a new file
chezmoi cd                   # cd into source repo

# On a NEW machine:
chezmoi init --apply SathishKumarAI/Dotfiles
```

#tools #chezmoi #dotfiles
